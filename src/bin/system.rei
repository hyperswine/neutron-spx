// maybe have a list of object {name, path}
const SPX_IMG_BASE_PATH = "/sys/spx/"
const SPX_IMG = ["fs" "graphics" "mem" "arc"]

/*
    core::types::Align4K pads the rest with 0s

    @align(4096) Align4K[T]: T
*/

main: () -> Status {
    // maybe its possible to create pending_requests as a static variable on the stack
    // its basically just a circ buffer
    // maybe wrap it in an MemoryInterface or IPC
    // to let the kernel map that buffer into other addr spaces
    // maybe compile sparx so that static mut pending_requests
    // or @state pending_requests gets loaded into an aligned 4K

    // NOTE: all defaults should be "empty"

    mut pending_requests = Align4K(CircularBuffer(Request()))

    // startup the other sparx
    
    /*
        scheduler allows userspace processes to use the ABI to scheduler threads on active cores
        cores should already be activated by arcboot or neutron but probably idle
    */

    // allow a sparx to be restarted
    let active_spx = SPX_IMG.map(spx => spawn(path=SPX_IMG_BASE_PATH+spx))

    loop {
        // the system sparx doesnt actually much itself. Its mostly a nice way to manage other sparx in userspace and shut everything down
        while let Ok(req) = pending_requests.first() {
            match req {
                Shutdown => {
                    // send a stop signal to child sparx
                    // NOTE: the sparx API should have a kill method that sends a request to it in this manner
                    // or an OS signal to ensure they shutdown as soon as possible
                    active_spx.for_each(spx => spx.kill())
                    return Ok()
                }
            }
        }

        // ? theres prob some way to directly yield to the cpu scheduler?
        // spx:system should have started from the scheduler

        // if a sparx goes inactive, (handle is Err), restart it
        // NOTE: sparx all have set pids? so we can do this easier? Uhh
        // THIS IS DIFFERENT TO A SPARX THAT IS BG'd or yielded
        active_spx.find(s => !s).for_each(s => spawn(s.path()))

        yield
    }
}

Request: enum {
    Shutdown
}

use neutronapi::sparx::*

// priorities are u8 (0-255)
Priority: u8
const MED = 255 / 2

Pid: u8

// @derive(new)
// All types can have "constructors". A function's constructor simply evals to anything it wants it to be
Process: {
    pid: Pid
    priority: Priority
}

// defined in core::
// NOTE: .len() for arrays (not array slices?) are actually const/lazily evald or cached maybe
CBuffer: [T, S] {
    head: Size
    _data: [T; S]
}

CBuffer: extend {
    // fn (as an object) could be locked
    first: (&mut self) -> T? {
        // and_then only proc's when the prev fn
        self._data.get(head).and_then(res => {
            self.head += 1
            self.head %= _data.len()
            res
        })
    }
}

// expose this as a locked memory buffer accessible via API/ABI
mut pending_requests = Mutex[CBuffer[Request]]()

// the kernel should pass the CPU info to the scheduler at launch. CPU info should not change, though it is possible, e.g. VM. Hence why mut. If changes, the kernel or other process would a send a request to update system info
main: (cpus: mut Cpus) {
    // stores a "local state" of processes as Vec::new()
    mut processes = []

    let new_process = (priority=MED) => {
        // note the +=operator is implemented for Vec for appending a new value or vec
        processes += Process(pid, priority)
    }

    // note there actually isnt really a server per se. Just a loop that keeps checking whether there's something in the buffer. If not, it just calls sleep() until interrupted by the scheduler or wake()'d by a request
    loop {
        while let Ok(req) = pending_requests.first() {
            match req {
                NewProcess => {
                    new_process()
                }
                Reschedule => {
                    let res = processes.random(distribution={p => p.priority}, k=cpus.len())
                    cpus.for_each(
                        // pick a random thread based on priorities, and queue it to the cpu
                        (cpu, i) => cpu.queue(res[i])
                    )
                }
            }
        }
        
        // on core::, this actually calls sleep() or maybe back to the cpu runner
        yield
    }
}

// NOTE:
// defined in core::
// asm: annotation(type=Phantasm) {}

// would be defined in kernel mode
// and be linked (exported as a lib and included in the kernel)
@interrupt_handler(LocalCoreTimer)
export cpu_dequeue: () {
    // would not be on the stack
    let exec: (thread) => @asm{
        x0 = thread.x0
        ...
        f0 = thread.f0
        ...

        j thread.entry
    }

    // lazily constructs Queue at compile time
    static mut local_queue = Queue()

    let thread = queue.pop()
    exec(res)
}

InterruptType: enum {
    LocalCoreTimer
}

// local core timer interrupt
// if already registered, will complain (cant overload the same hash key)
interrupt_handler: annotation (int: InterruptType) {
    // register the handler in the global interrupt table at compile time

    // cases
    (f: Fn) => {
        // note register() takes in a () -> () fn
        GIT.register(int, f)
    }
}

// process sections
// Code: Bytes
// Data: Bytes

Request: enum {
    NewProcess: {
        // move them into the process for checks and direct writes?
        // wait no, basically, just the entire ELF on the stack before parsing
        elf_program: ElfProgram
    }
    KillProcess
    // Kind of like Kthreads that back up each Uthread and queued in a CPU that is most local to the process's workspace/memory allocations
    NewThread
    KillThread
    Reschedule
}

// extend objects can only be in modules and non enum objects? hmm well I guess maybe you can but like prob not a good idea
Request: extend {}

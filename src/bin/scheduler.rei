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
        if let Ok(req) = pending_requests.first() {
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

            pending_requests.empty()? sleep(): continue
        }
    }
}

// NOTE:
// defined in core::
// asm: annotation(type=Phantasm) {}

// would be defined in kernel mode
@interrupt_handler(LocalCoreTimer)
cpu_dequeue: () {
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

Request: enum {
    NewProcess: complex {}
    KillProcess
    // Kind of like Kthreads that back up each Uthread and queued in a CPU that is most local to the process's workspace/memory allocations
    NewThread
    KillThread
    Reschedule
}

Request: extend {}

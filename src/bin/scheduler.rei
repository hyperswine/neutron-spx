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

// the kernel should pass the CPU info to the scheduler at launch. CPU info should not change, though it is possible, e.g. VM. Hence why mut. If changes, the kernel or other process would a send a request to update system info
main: (cpus: mut Cpus) {
    // stores a "local state" of processes
    // as Vec::new()
    mut processes = []
    mut pending_requests = []

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
                        cpu, i => cpu.queue(res[i])
                    )
                }
            }

            pending_requests.empty()? sleep(): continue
        }
    }
}

// would be defined in kernel mode
cpu_dequeue: () {
    // would not be on the stack
    let exec: (thread) => @asm{
        x0 = thread.x0
        ...
        f0 = thread.f0
        ...

        j thread.entry
    }

    let thread = queue.pop()
    exec(res)
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

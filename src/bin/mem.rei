#*
    Memory Management Sparx
*#
@!signals = Default

// we need domains
Domain: enum {
    Compute: {
        closest_memory: &Memory
    }
    Memory: {
        id: Id
        addr_range: Range<Size>
    }
}

// maybe make that a thing?
mut pending_requests = Mutex[CBuffer[Request]]()

// all sparx should have its own signal handlers
/*
    signal: annotation(type: SignalType) {
        (f:Fn) => {
            SIGNALS.register(type, f)
        }
    }
*/

// by default, when you @!signals = Default
// @signal()
// kill: () {
//     exit(KILL)
// }

MemoryDomain: {
    addr_range: Range<Size>
}

main: (page_size: Size, page_tables: &[PageTable], domains: &[MemoryDomain]) {
    // setup free pages and stuff for each compute domain
    mut free_pages = Stack[Page]()
    let compute_nodes = domains.filter(d.variant() == Compute)
    let memory_nodes = domains.filter(d.variant() == Memory)

    loop {
        while let Ok(req) = pending_requests.first() {
            // do what you need to do to alloc, dealloc, realloc, etc
            match req {
                Alloc{pid, referred_node, size} => {
                    // if memory is available at NUMA domain or compute node, then immediately alloc, otherwise choose some other domain (thats near the preferred domain?)
                    // wait I think we should be using NUMA domains in perspective of NUMA instead of CPUs
                    let pages_to_pop = size / page_size
                    let pages = free_pages.pop(pages_to_pop)
                    // allocate page table entries, otherwise create a new table
                    let pt = page_tables.get(pid)?: page_tables.push()
                    pt.alloc(pages)
                }
            }
        }
    }
}

Descriptor: BlockDescriptor | PageDescriptor

BlockDescriptor: complex {

}

PageDescriptor: complex {
    alloc: (&mut self) {
        
    }
}

// main object def
PageTable: [Descriptor; PAGE_SIZE]

// extension obj
PageTable: extend {
    // alloc "recursively calls itself"
    alloc: (&mut self) {
        
    }
}

// allocate requests for more or less memory

// NOTE: page faults are handled by the kernel

// alignment should be defined by kernel lib and imported

# Size in bytes
SizeBytes: Size

Request: enum {
    Alloc: {
        pid: Pid
        preferred_node: MemoryDomain
        size: SizeBytes
    }
    Dealloc
    Realloc
}

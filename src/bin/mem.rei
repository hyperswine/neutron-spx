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

// bitfield (ident: Ident ":" range: Range)

PageField: @bitfield {
    addr_space_id: 63..48
    l4: 47..39
    l3: 38..30
    l2: 29..21
    l1: 20..12
    offset: 11..0
}

MemoryDomain: {
    addr_range: Range<Size>
}

# Page Number
// Note T: S allows T to be "casted" to S (statically)
Page: u64

Page: extend {
    // its possible to just pass it in I guess
    start_addr: (&self) -> u64 {
        // dynamic caching possible? maybe inline all these or make the compiler reuse the results
        // yea I like that idea
        self * PAGE_SIZE
    }

    impl From<PageField>(field: PageField) -> Self {
        ...
    }

    l1: (&self) -> u64 {
        // convert to start address (vaddr)
        // implicit casts are good, the compiler always chooses the shortest path to the result type
        // maybe have a cast hierarchy and traverse it
        let vaddr = l1(self.start_addr())
    }
}

// bitfields l1
// l1: () -> u64 {}

// Once Cell
mut PAGE_SIZE = Once<Size>()

main: (page_size: Size, page_tables: &[PageTable], domains: &[MemoryDomain]) {
    // setup free pages and stuff for each compute domain
    mut free_pages = Stack[Page]()
    let compute_nodes = domains.filter(d.variant() == Compute)
    let memory_nodes = domains.filter(d.variant() == Memory)

    // can only be set here (operator=)
    PAGE_SIZE = page_size

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
    // Optional params do not need to be specified, its just None by default
    alloc: (&mut self, index: Index, properties: Properties?) {
        // the default keyword is good
        self._data[index] = Index(set=true, properties?:default)
    }
}

PageDescriptor: @bitfield {
    
}

PageDescriptor: extend {
    alloc: (&mut self, index: Index, properties: Properties?) {
        self._data[index] = Index(set=true, properties?:default)
    }

    # Address
    addr: (&self) -> u64 {}

    set_next_level: (&mut self, page: Page) -> u64 {
        self.mapped = true
        // kinda complicated cause if exists, you just call that and it returns...?
        // self.output_block_addr = 
    }

    set_mapped: (self) -> Self {
        self.mapped = true
        self
    }
}

// main object def
PageTable: [Descriptor; PAGE_SIZE]

// always assume 4 levels

// Uhh the page table itself should actually hold descriptors

// extension obj
PageTable: extend {
    // alloc "recursively calls itself"
    // overload 0
    alloc: (&mut self, pages: &[Page]) {
        pages.for_each(
            p => {
                // compute L1
                // get the next level's addr from calling the Descriptor fn
                self[p.l1].set_mapped().set_next_level(p)
            }
        )
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

// COMMUNICATION PRIMITIVES

# Mostly for one way communication between process -> service
ReqBuffer: {
    requests: Size = 0
    frame_numbers: Vec<FrameNumber>
}

ReqBuffer: extend {
    new: (size: Size) -> Self {
        // ask system for pages
        let frame_numbers = alloc_pages_shared(size)

        // NOTE: initialiser structs must have direct mappings between names unless default value
        Self{frame_numbers}
    }

    // map the pages of the buffer into the process' address space, usually at a known location (defined in neutronapi or std)
    // for a specific spx
    map_to: (&self, vrange: Range, process_addr_space: &mut AddressSpace) {
        // the process should be able to write requests to the buffer now
        process_addr_space.map(vrange, self)
    }
}

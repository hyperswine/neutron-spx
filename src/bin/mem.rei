#*
    Memory Management Sparx
*#
@!signals = Default

use neutronapi::memory

loop {
    while let Ok(req) = pending_requests.first() {
        // do what you need to do to alloc, dealloc, realloc, etc
        match req {
            Alloc{pid, referred_node, size} => {
                // if memory is available at NUMA domain or compute node, then immediately alloc, otherwise choosesome other domain (thats near the preferred domain?)
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

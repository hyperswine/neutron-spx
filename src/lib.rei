#*
    Neutron Sparx
*#

// primitives for in memory data structures that can be directly written to
// NOTE: I dunno if write-only is possible? another problem is what if a process overwrites the requests with a bunch of junk?
// so maybe it has to gain permissions to be able to read/write to that location first
// I mean, a malicious program is gonna do what its gonna do anyway

// either that or you create a shared Rw buffer between the spx and a process in the process' own address space
// and only those pages are known
// the sparx simply checks all known buffers for any data each time its scheduled

Channel[T]: Mutex[T]

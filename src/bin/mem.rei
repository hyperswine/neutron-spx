#*
    Memory Management Sparx
*#

main: () {
    loop {
        
    }
}

// allocate requests for more or less memory

// NOTE: page faults are handled by the kernel

Request: enum {
    Alloc
    Dealloc
    Realloc
}

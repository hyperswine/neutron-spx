#*
    Filesystem Sparx
*#

// sparx are kinda like HTTP servers except on local machines they can be interacted with as a stream out on a port/channel

use neutronapi::log::{logger, Timestamp}
use neutronapi::sparx::*

mut pending_requests = Mutex([])

# spx_fs <opts>
# CLI args are literally heap alloc'd in other langs. In rei, they are stack variables
main: (output_dir: String) {
    logger.config(verbose=true, timestamps=Full).output_file(output_dir + "fs").start()

    // on core:: and neutronapi, info() should be assigned to logs to /sys/logs/...
    
    info("spx:fs started!")

    // setup a service loop using registered handlers
    // warning: unused result, T casted to ()
    loop {
        while let Ok(req) = pending_requests.pop() {
            match request_type {
                Read(file) => {
                    let res = neutronapi::read(file)? {
                        
                    }
                }
            }
        }
    }
}

Request: enum {
    Read: File
    Write: File
    Open: String
    Close: File
}

export FSError: SString

// if two annotations on the same line with the stuff, make them on new line
// annotations must be separated by commas or +
// caching policies can be easily implemented in this program and runs as a separate thing rather than built into the stdlib
// and reliant on an ABI (kernel)

#*
    Filesystem Sparx
*#

use neutronapi::log::{logger, OUTPUT_DIR, Timestamp}
use neutronapi::sparx::*

# spx_fs <opts>
main: () {
    logger.config(verbose=true, timestamps=Full).output_file(OUTPUT_DIR + "fs").start()

    // on core:: and neutronapi, info() should be assigned to logs to /sys/logs/...
    
    info("spx:fs started!")

    // setup a service loop using registered handlers
    // warning: unused result, T casted to ()
    service.listen()
}

RequestType: enum {
    Read(File) Write(File) Open(String) Close(File)
}

export FSError: SString

// sparx are kinda like HTTP servers except on local machines they can be interacted with as a stream out on a port/channel
@GET get: (request_type: RequestType) -> Data | FSError {
    match request_type {
        Read(file) => {
            read(file)
        }
    }
}

// if two annotations on the same line with the stuff, make them on new line
// annotations must be separated by commas or +
// caching policies can be easily implemented in this program and runs as a separate thing rather than built into the stdlib
// and reliant on an ABI (kernel)

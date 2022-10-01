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

/*
    NeutronFS (Passthrough)
*/

// instead of syscalls, the primary method of authentication is asymmetric encryption
// every process has their own private key stored in their own file (read only by them)
// and the "server" aka spx:fs has its own public key and priv key pair
// every few days (changeable), the server and processes update their keys (neutron prompts them to)

// so at first, you need a syscall to generate keys I think, but when done, you hardly need calls

# Each file has a "Block table". New levels are allocated on disk on demand. As long as a file isnt too big, it should be fine. Each block table occupies exactly 4K (a single block), and its entries point to other block tables until one gets to a table that just points to page descriptor
# Since there isnt any hardware support for file permissions and stuff, they are all handled by spx:fs
BlockTable: [Descriptor; 512]

@derive(Copy, Clone)
Descriptor: BlockDescriptor | PageDescriptor

LogicalBlockNumber: u64

# A block descriptor simply points to the next block table entry (address)
BlockDescriptor: LogicalBlockNumber

# A page descriptor actually points to a 4K block of data
PageDescriptor: LogicalBlockNumber

BlockTable: extend {
    new: () -> Self {
        [Descriptor(); 512]
    }

    add_blocks: (block_ids: ) {}

    remove_blocks: () {}
}

mut ramfs = Filesystem::load("/sys/fs/.nefs")

new_file: (path: Path) -> Status {
    // check in memory structure if path already exists

    // the 'in' operator is overloaded to use an efficient search (binary search)
    if !ramfs.add_file(path) {
        return "File already exists in path!"
    }

    // if does not exist, ramfs should add a block table and push a write req to the buffer cache
}

// pure data objects mean you can only define pure data fields
// enum data objects mean you can only define variant fields (not key: val)
// whats the problem... why even have complex actually?

// maybe a good idea is to have an array tree
// insertion, deletion, etc could be kinda slow though
// yea basically just bulk read and write and as long as not too many stuff are open, caching should be fine

// nothing, data or enum maybe...

Filesystem: complex {
    // the = Tree[File]() is implicit to the default new constructor
    // NOTE: the tree in use is actually a cache friendly tree
    files: Tree[File]

    add_file: (&mut self, path: Path) -> Status {
        // create a new block table
        let block_table = BlockTable()
        // add to the file in question
        files.add(path).add_block_table(block_table)
    }

    write_file: (&mut self, path: Path, diff: Diff) -> Status {}

    # offset is always absolute from 0
    write_file: (&mut self, path: Path, bytes: Bytes, offset: Offset) -> Status {
        // find the file's block table
        // search the blocks of interest corresponding to the offset + bytes
        // push a write req to those blocks
    }

    // writes dont have to be written to disk just yet, even if multiple processes are viewing it
    // we use CoW and repointing to update the in memory view

    // reads should generally be done asap
}

File: {
    # read the entire file to a string (based on the metadata encoding, usually utf-8)
    read: (&mut self, file: _) -> String {
        // fetch all known blocks from disk from the in memory block table (given that its not dirty)
        let blocks: Vec<LogicalBlockNumber> = self.block_table.fetch_all()
        // push read requests for those blocks
        let raw_data = blocks.map(b => DiskReader::read_block(b)).accumulate(acc, bytes => acc + bytes)
        // parse the encoding or get from in memory data store
        parse(self.encoding, raw_data)
    }
}

Block: [u8; 4096]

DiskReader: {
    read_block: async (block_number: LogicalBlockNumber) -> Block {
        // the driver
        disk_driver.dma_from_disk(block_number).await
    }
}

// ramfs bulk writer

/*
    BUFFER CACHE (FOR WRITES)
*/

const TIME: Time = 10ms

DiskWriter: {
    write_block: (&mut self, block_number: LogicalBlockNumber, block: Block) {
        // push block to queue
        self.queue_write(block_number, block)
    }

    queue_write: (&mut self, block_number: LogicalBlockNumber, block: Block) {
        self.queue.push(block_number, block)
    }

    # should be called every now and then (maybe a loop)
    write_bulk: (&mut self) {
        if self.queue.is_full() or self.time_elasped > TIME {
            self.time_elasped = 0
            self.queue.map(block_number, block => disk_driver.dma_to_disk(block_number, block))
        }
        else {
            self.time_elasped += curr_time()
        }
    }
}

# Neutron Sparx

Sparx framework for neutron (Rei). There is no default recovery strategy for now. Assume the sparx should just work and wont crash. If crash, I guess `spx:system` should restart it. Wait so maybe get a handle on each started sparx? And if one of them returns early or unexpectedly, try to restart it?

NOTE: name conflicts are usually resolved with explicit aliases `X as Y`.

Other things such as mouse and keyboard could be handled by spx:system? And the drivers directly mapped into their addr space? By default those permissions should already exist. At least listening/polling the mouse, keyboard, speakers, usb devices (maybe). No mic or any other potentially problematic devices.

Should `spx:system` also check for permissions? Probably. Sparx mostly are required to do asynchronous processing in the background every now and then. Such as flushing the buffer cache, request certain permissions before allowing drivers to be mapped in to their address space and etc. Maybe we dont even need extra sparx? Just `spx:system`? Which we could just call `sys`?

Yea if thats an exokernel way of doing things. Though I guess some other bg services for checking the condition of the system, like data analytics, logging, etc. Could be all put into `spx:system`. But system is pinned to NUMA 0 and may potentially have to do a lot of extra, maybe even useless iterations and checks.

## Asynchronous

Neutron is built to be asyncally computed and rendered from the ground up. Given the system isnt under too much load and the threads are yielding properly, it should be very responsive. Otherwise you'd have to wait 25ms for something to happen? Most sparx are pinned to NUMA 0. But I guess its possible to sprread them out to NUMA 1 or 2 or 3. Or any random domain.

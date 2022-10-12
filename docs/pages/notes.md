---
layout: default
title: Notes
---

## Boot Process

After arcboot has been loaded by the bios, which then loads neutron. Neutron's main job is to ensure all the devices are in working condition/do tests on them, as well as loading device interrupt handlers and service handlers. All subsequent sparx can request a redirection of interrupts and syscalls to their own code (I think its possible??)...

The last thing neutron does is setup userspace and spawn `spx:system` into userspace vmemory. On ARM this would be TTBR0. After that, `spx:system` spawns other sparx.

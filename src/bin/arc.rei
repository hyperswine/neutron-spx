#*
    Starts up Arc Runtime and Arc Desktop
*#

main: () -> Status {
    // startup arc desktop
    spawn("/apps/ArcDesktop")?

    loop {
        while let Ok(req) = pending_requests.first() {
            match req {}
        }
        // yield in any sparx should yield to the scheduler
        // the problem is though that it might yield to spx:system
        // maybe spx:system can then run the scheduler on that core?
        yield
    }
}

Requests: enum {}

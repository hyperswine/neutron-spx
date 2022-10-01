#*
    Process Authentication
*#

Authorizer: {
    // allow a process to authenticate itself (and display its authorities so it may communicate with the sparx and/or have the driver code mapped to their address space)
    authenticate: (&self, process: Process, key: Key) -> Status {
        // get the executable id of the process
        let executable_id = process.executable_id

        // ask the process to hash a random string and verify that the hash is correct
        let hashed_string = process.request_hash(random_string())
        verify(hashed_string, process.public_key, self.private_key)?

        // check its permissions (in memory or on disk)
        let permissions = self.permissions.get(executable_id)
    }

    // whenever a process attempts to access a service through the API, this fn is called to see if it has the permissions
    authorise: (&self, service: Service) -> Status {
        self.permissions.authorise(service)
    }
}

# Architecture
Scaning machine consists of server and client parts, server uses Yara rules.

## Server
Server is written in Haskell. It receives file and maybe an email address.
After that server calls Yara executable on this file.
Yara applies set of predefined rules to this file and returns result to server.
Server sends a responce to client and maybe sends an email.
Responce contains "Everything is OK!" or "Danger" with type of danger if file is clean or not, respecively.

### Server-part libraries:
Happstack-lite for server, smtp-mail for mail service

## Client
Client is written in Vue-js. Allows user to select a file and send it for scaning.
Color of leaf corresponds to the result of scaning: positive - green, negative - red.
Between attachment of file and receiving a responce leaf is yellow.
Scaning result is also present as alert message on top of page, its color is equal to color of leaf in corresponding cases.


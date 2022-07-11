add-content -path c:/users/user/.ssh/config -value @'

Host ${hostname}
 HostName ${hostname}
 User ${user}
 IdentityFile ${identityfile}

'@ 
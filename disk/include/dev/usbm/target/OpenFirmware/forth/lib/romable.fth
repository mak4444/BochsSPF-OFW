
\ Warns about stores into the dictionary to help catch non-ROMable code.
forth definitions
: variable   nuser  ;
: 2variable  2 /n* ualloc user  ;
: lvariable  /l ualloc user  ;
: shared-variable  nuser  ;



decimal

user-size-t constant user-size

\ Initial user number


nuser link       \ link to next task
nuser entry      \ entry address for this task
nuser saved-ip
nuser saved-rp
nuser saved-sp
\ next 2 user variables are used for booting
nuser up0     \ initial up
nuser #user   \ next available user location
nuser sp0          \ initial parameter stack
nuser rp0          \ initial return stack

\ This is the beginning of the initialization chain
: init  ( -- )  up@ link !  ;	\ Initially, only one task is active

/n constant #ualign
: ualigned  ( n -- n' )  #ualign round-up  ;



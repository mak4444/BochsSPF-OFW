\ Display and modify the saved state of the machine.
\
\ This code is highly machine-dependent.  This version is for the x86
\
\ Defines:
\
\ %eax %ebx %ecx %edx %ebp %esp %esi %edi %cs %ds %es %fs %gs %eflags

hex

only forth hidden also forth also definitions

headerless

3 actions
action:  @ >state  le-@  ;
action:  @ >state  le-!  ; ( to )
action:  @ >state        ; ( addr )
: register  \ name  ( -- )
   create /n alloc-reg ,
   use-actions
;
action-adr-t to doregister
3 actions
action:  @ >state  le-w@  ;
action:  @ >state  le-w!  ; ( to )
action:  @ >state      ; ( addr )
: wregister  \ name  ( -- )
   create /n alloc-reg ,
   use-actions
;
headers

\ The following register save layout mimics the format of a
\ Task State Segment

wregister %tlink
register %esp0   wregister %ss0
register %esp1   wregister %ss1
register %esp2   wregister %ss2
register %cr3
register %eip
register %eflags

register %eax  register %ecx  register %edx  register %ebx
register %esp  register %ebp  register %esi  register %edi

wregister %es  wregister %cs  wregister %ss  wregister %ds
wregister %fs  wregister %gs
wregister %ldt
register  %tio

\ The following registers are not present in a Task State Segment

register int#
register %error

alias rup %edi  alias rip %esi  alias rrp %ebp  alias rsp %esp
alias rpc %eip  alias %pc %eip

\ System registers, not visible to most application programs
\ wregister %ldtr   wregister %tr  register %gdtr  register %idtr

\ State information needed by the firmware; not machine registers
register watchdog        register %state-valid   register %restartable?
register %saved-my-self  register sig#

\ Following words defined here to satisfy the
\ references to these "variables" anywhere else
: saved-my-self ( -- addr )  addr %saved-my-self  ;
: state-valid   ( -- addr )  addr %state-valid    ;
: restartable?  ( -- addr )  addr %restartable?   ;

: offset-of  \ reg-name  ( -- offset )
   ' >body @
;
decimal

only forth also definitions

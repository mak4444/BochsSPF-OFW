purpose: Timing functions using model-specific time-stamp-counter register

\ One way to read the time-stamp counter is to use the
\ "read model-specific register" instruction with the value 0x10 in CX, e.g.:
\  h# 10 # cx mov		\ Timestamp counter code
\  h# f c,  h# 32 c,		\ Read Model-Specific Register
\ RDMSR works only in supervisor state

code tsc@  ( -- low high )
   \ This version of the instruction can also be used from User state
   \ if bit 2 in the CR4 register is 0.
   h# f c,  h# 31 c,		\ Read Time-Stamp Counter
   ax push   dx push
c;
code spins  ( count -- )
   bx pop
   h# f c,  h# 31 c,		\ Read Time-Stamp Counter   
   ax bx add			\ bx: target time
   begin
      h# f c,  h# 31 c,		\ Read Time-Stamp Counter into dx,ax
      bx ax sub
   0>= until
c;

d# 10 to ms/tick
d# 262000 value ms-factor
d# 262 value us-factor

0 value tick-msecs	\ To make isatick.fth happy

: (get-msecs)  ( -- )  tsc@ ms-factor um/mod  nip  ;
' (get-msecs) to get-msecs

: 1ms  ( -- )  ms-factor spins  ;
: (us)  ( #microseconds -- )  us-factor * spins  ;
' (us) to us

[ifdef] use-timestamp-counter
: (ms)  ( #ms -- )  0  ?do  1ms  loop  ;
' (ms) to ms
[then]

[ifdef] use-tsc-timing   \ These are precise but inaccurate, as the TSC varies with clock throttling
\ Timing tools
2variable timestamp
: t-update ;
: t(  ( -- )  tsc@ timestamp 2! ;
: ))t  ( -- d.ticks )  tsc@  timestamp 2@  d-  ;
: ))t-usecs  ( -- usecs )  ))t us-factor um/mod nip  ;
: )t  ( -- )
   ))t-usecs  ( microseconds )
   push-decimal
   <#  u# u# u#  [char] , hold  u# u#s u#>  type  ."  uS "
   pop-base
;
: t-sec(  ( -- )  t(  ;
: )t-sec  ( -- )
   ))t  us-factor d# 1,000,000 *  um/mod nip  ( seconds )
   push-decimal
   <# u# u#s u#>  type  ." S "
   pop-base
;
: .hms  ( seconds -- )
   d# 60 /mod   d# 60 /mod    ( sec min hrs )
   push-decimal
   <# u# u#s u#> type ." :" <# u# u# u#> type ." :" <# u# u# u#>  type
   pop-base
;
: t-hms(  ( -- )  t(  ;
: )t-hms
   ))t  us-factor d# 1,000,000 *  um/mod nip  ( seconds )
   .hms
;
[then]


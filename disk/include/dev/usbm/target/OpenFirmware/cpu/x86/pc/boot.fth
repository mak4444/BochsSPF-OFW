purpose: Stand-alone boot code for running ix86 version Forth

\ create debug-startup

\ Boot code (cold and warm start).  The cold start code is executed
\ when Forth is initially started.  Its job is to initialize the Forth
\ virtual machine registers.  The warm start code is executed when Forth
\ is re-entered, perhaps as a result of an exception.

[ifdef] debug-startup
: ascii-chars " 0123456789abcdef" drop ;
: hdot  ( n -- )
   7 0 do  0 h# 10 um/mod  loop  8 0 do  ascii-chars + c@ emit  loop  space
;
[then]

hex
warning @  warning off 
: stand-init-io  ( -- )
   stand-init-io
   dict-limit to limit
   inituarts install-uart-io
   ['] noop          ['] bye    (is
   ['] RAMbase       is lo-segment-base
   ['] here          is lo-segment-limit
   ['] here          is hi-segment-base
   ['] here          is hi-segment-limit

   ['] reset-all     is bye
   true is flat?
   ['] 2drop         is sync-cache
;
warning !

[ifdef] debug-startup
\ diagnostic macros
\ Assembler macro to assemble code to send the character "char" to COM1
: wait-tx-ready  ( -- )
[ifdef] mem-uart-base   
   " begin   h# 20 #  mem-uart-base 5 + #) byte test  0<> until" evaluate
[else]
   " begin   h# 3fd # dx mov   dx al in  h# 20 # al and   0<> until" evaluate
[then]
;
: report  ( char -- )
   wait-tx-ready
[ifdef] mem-uart-base
   ( char )  " # mem-uart-base #) byte mov" evaluate
[else]
   ( char )  " # al mov  h# 3f8 # dx mov  al dx out" evaluate
[then]
   wait-tx-ready
;
: nreport  ( -- )  \ print 4-bit value in bl
   wait-tx-ready
[ifdef] mem-uart-base
   " bl al mov  h# 0f # ax and  h# 30 # ax add  al mem-uart-base #) mov" evaluate
[else]
   " bl al mov  h# 0f # ax and  h# 30 # ax add  h# 3f8 # dx mov  al dx out" evaluate
[then]
;
: dotbyte   ( - )     \ print byte in bl
   "  bx 4 # ror " eval  nreport
   "  bx 4 # rol " eval  nreport
   h# 20 nreport
;

label putchar  ( al:char -- )
   dx push  bx push
[ifdef] mem-uart-base
   wait-tx-ready
   al  mem-uart-base #) mov
[else]
   al bl mov
   wait-tx-ready
   bl al mov  h# 3f8 # dx mov  al dx out
[then]
   wait-tx-ready

   bx pop  dx pop
   ret
end-code

label puthexit  ( ax:nibble -- )
   h# f #  ax  and
   9 # ax cmp  > if
      char a d# 10 - #  ax  add
   else
      char 0 #  ax  add
   then
   putchar #) call
   ret
end-code

label dot  ( ax:value -- )
   bx push  cx push
   ax bx mov
   8 # cx mov
   begin
      bx 4 # rol
      bx ax mov
      puthexit #) call
      cx dec
   0= until
   h# 20 # ax mov
   putchar #) call
   cx pop bx pop
   ret
end-code

\ *** NOTE: dot is too big to be put inside a control structure ***
: mdot   ( reg - )     \ print 32-bit value in reg
   " ax push   bx push   cx push   dx push" eval
   " bx mov" eval	\ trashes ax,bx,cx,dx
\   " 0 # cx mov begin" eval
   8 0 do
      "  bx 4 # rol " eval  nreport
   loop
\ XXX doesn't cx need to be decremented?
\   " d# 8 # cx cmp >= until" eval
   h# 20 report
   " dx pop   cx pop   bx pop   ax pop" eval
;

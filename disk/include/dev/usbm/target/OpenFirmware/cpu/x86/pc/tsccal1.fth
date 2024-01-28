purpose: Calibrate Time Stamp Counter against ISA timer - without interrupts

\ This code works only for processors that have a Time Stamp Counter register

code calibrate-loop  ( -- tscdelta )
   \ setup timer 0 to interrupt when the count goes to 0

   \ TTRR.MMMB Timer 0, r/w=lsb,msb, mode 0, binary
   h# 30 #  al  mov   al  h# 43 #  out	\ Start setting timer

   d# 11932 wbsplit swap     ( tick-cnt-high tick-cnt-low )
   #  al  mov   al  h# 40 #  out	\ Set tick limit low  ( tick-cnt-high )
					\ The timer should now be stopped

   h# f c,  h# 31 c,	\ Get time-stamp counter value into DX,AX
   ax cx mov		\ Save the low part in CX; the high part is not needed

   #  al  mov   al  h# 40 #  out	\ Set tick limit high to start timer

   begin
      ax ax xor  al  h# 43 #  out	\ Latch timer
      h# 40 # al in
      al ah mov
      h# 40 # al in
      al ah xchg
      \ The number 10 below gives a sufficient window to ensure that a count
      \ value in the range from 0 to 9 is seen.  The process of latching the
      \ timer and reading the value is time-consuming because I/O port access
      \ is slow, comparable to the clock that drives the ticker.  For many
      \ systems, a value of 5 is enough, but I have seen systems that need 8.
      d# 10 #  ax  cmp
   < until
   
   h# f c,  h# 31 c,	\ Get time-stamp counter value into DX,AX
   cx ax sub		\ Subtract the low parts
   
   ax push
c;


\needs ms-factor -1 value ms-factor
\needs us-factor -1 value us-factor
: calibrate-ms  ( -- )
\ mmo   disable-interrupts
   calibrate-loop   dup d# 10 / to ms-factor  ( count-value )
   d# 10000 / to us-factor   \ Divide by 1000 with rounding
;
stand-init: Calibrating millisecond timer
   calibrate-ms
;


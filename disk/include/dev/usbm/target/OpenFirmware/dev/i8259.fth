\ See license at end of file
purpose: Driver for cascaded Intel 8259 interrupt controllers

internal
: ctl0!   ( -- )  h# 20 pc!  ;
: data0!  ( -- )  h# 21 pc!  ;
: ctl1!   ( -- )  h# a0 pc!  ;
: data1!  ( -- )  h# a1 pc!  ;

h# 08 value vector-base0
h# 70 value vector-base1
h# 11 value int-mode	\ Change to h# 19 for level-triggered

external

: init  ( -- )
   \ init-code   vector-base          cascade    mode
   int-mode  ctl0!  vector-base0 data0!  4 data0!  1 data0!
   int-mode  ctl1!  vector-base1 data1!  2 data1!  1 data1!

   \ Turn off all interrupts
   h# ff  data1!
   h# fb  data0!	\ Enable cascade
;
[ifdef] tokenizing  init  [then]

\ It is okay to acknowledge an unspecific interrupt because the
\ interrupt controller only issues one interrupt at a time.
: iack  ( -- )  h# 20 ctl1!  h# 20 ctl0!  ;

internal
: >mask  ( irq# -- port old-value mask )
   dup 7 and 1 swap lshift   ( irq# mask )
   swap 8 and  if  h# a1  else  h# 21  then  ( mask port )
   dup pc@  rot
;

external
: enable-irq   ( irq# -- )  >mask  invert and  swap pc!  ;
: disable-irq  ( irq# -- )  >mask  or          swap pc!  ;

: ocw3@  ( cmd 20|a0 -- result )  tuck pc!  pc@  ;

\ Write bits in 20/a0 register:
\ 0a means set the mode for subsequent reads of the 20/a0 register
\ 01 bit = 0  means set it to read the IRR
\ 01 bit = 1  means set it to read the ISR
\ 04 bit = 1  means "poll mode", i.e. ISR reads are treated like
\   interrupt acknowledge cycles, instead of using the INTA* input pin.
\
\ In poll mode, the high (80) bit of the returned ISR value is 0 if
\ no interrupt is pending, 1 otherwise.

\ isr@ returns a number encoded as follows:
\ v00lllll where "v" is 1 if an interrupt is pending, 0 otherwise.
\ If v is 1, lllll is a binary number from 0-15, indicating which interrupt
\ is being serviced.
: polled-iack  ( -- valid/level )
   h# f h# 20  ocw3@  dup h# 82 =  if       ( low-code )
      \ The interrupt came from the cascade channel, so we read the
      \ ISR from the high bank and add 8 to its interrupt level.
      drop  h# f h# a0 ocw3@                ( high-code )
      dup h# 80 and swap                    ( 80-bit high-code )
      7 and  8 +  or                        ( n )
   then
;
: irr@  ( -- w )
   h# a h# 20 ocw3@  dup 4 and  if   h# a h# a0 ocw3@  bwjoin  then
;

: isr@  ( -- w )
   h# b h# 20 ocw3@  dup 4 and  if   h# b h# a0 ocw3@  bwjoin  then
;

\ This is only needed when operating in rotating priority mode
\ : iack#  ( irq# -- )
\    dup 7 and  h# 60 or  swap 8 and  if  h# a0  else  h# 20  then  pc!
\ ;

code this-interrupt
   ax ax xor
   h# f # al mov
   al h# 20 # out
   h# 20 # in
   h# 80 # al test  0=  if
      ax ax xor
      ax push
      next
   then
   h# 7 # al and
   h# 2 # al cmp  <>  if   \ Not cascaded
      ax push
      ax ax xor  ax dec  ax push
      next
   then
   h# f # al mov
   al h# a0 # out
   h# a0 # in
   h# 80 # al test  0=  if
      ax ax xor  ax push
      next
   then
   h# 7 # al and
   h# 8 # al add
   ax push
   ax ax xor  ax dec  ax push
c;
code eoi
   h# b # al mov
   al h# 20 # out
   h# 20 # in
   h# 04 # al test \ Test slave bit
   h# 20 # al mov
   al h# 20 # out  \ EOI to master
   0<>  if
      al h# a0 # out  \ EOI to cascaded slave
   then
c;
alias interrupt-done eoi
\ XXX we really should map the registers
: open  ( -- flag? )  true  ;
: close  ( -- )  ;

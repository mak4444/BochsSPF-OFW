purpose: Driver for UHCI USB Controller

hex
headers

defer end-extra			' noop to end-extra

true value first-open?
0 value open-count
0 value uhci-reg

: map-regs  ( -- )  /regs my-map-in to uhci-reg  ;

: unmap-regs  ( -- )
   uhci-reg  /regs  my-map-out  0 to uhci-reg
;

: uhci-b@  ( idx -- data )  uhci-reg + rb@  ;
: uhci-b!  ( data idx -- )  uhci-reg + rb!  ;
: uhci-w@  ( idx -- data )  uhci-reg + rw@  ;
: uhci-w!  ( data idx -- )  uhci-reg + rw!  ;
: uhci-l@  ( idx -- data )  uhci-reg + rl@  ;
: uhci-l!  ( data idx -- )  uhci-reg + rl!  ;

: usbcmd@     ( -- data )   0 uhci-w@  ;
: usbcmd!     ( data -- )   0 uhci-w!  ;
: usbsts@     ( -- data )   2 uhci-w@  ;
: usbsts!     ( data -- )   2 uhci-w!  ;
: usbintr@    ( -- data )   4 uhci-w@  ;
: usbintr!    ( data -- )   4 uhci-w!  ;
: frnum@      ( -- data )   6 uhci-w@  ;
: frnum!      ( data -- )   6 uhci-w!  ;
: flbaseadd@  ( -- data )   8 uhci-l@  ;
: flbaseadd!  ( data -- )   8 uhci-l!  ;
: sof@        ( -- data )   c uhci-b@  ;
: sof!        ( data -- )   c uhci-b!  ;
: portsc@     ( port -- data )  2* 10 + uhci-w@  ;
: portsc!     ( data port -- )  2* 10 + uhci-w!  ;

\ We mustn't wait more than 3 ms between releasing the reset and enabling
\ the port to begin the SOF stream, otherwise some devices (e.g. pl2303)
\ will go into suspend state and then not respond to set-address.
: reset-port  ( port -- )
   dup >r  portsc@ h# 20e invert and    ( value r: port )  \ Clear reset, enable, status
   dup h# 200 or  r@ portsc!	        ( value r: port )  \ Reset port
   d# 30 ms                             ( value r: port )  \ > 10 ms - reset time
   dup r@ portsc!                       ( value r: port )  \ Release reset
   1 ms                                 ( value r: port )  \ > 5.3 uS - reconnect time
   h# e or  r> portsc!	                ( )  \ Enable port and clear status
;

: reset-usb  ( -- )
   uhci-reg dup 0=  if  map-regs  then
   4 usbcmd!			\ Global reset
   50 ms
   0 usbcmd!
   10 ms

   2 usbcmd!			\ Host reset
   d# 10 0  do
      usbcmd@ 2 and  0=  ?leave
      1 ms
   loop
   0=  if  unmap-regs  then
;

: (process-hc-status)  ( -- )
   usbsts@ dup h# 3e and usbsts!	\ Clear errors and interrupts
   38 and ?dup  if
      usbcmd@ 1 or usbcmd!		\ Exit halted state
      dup 20 and  if  " Host controller halted"  USB_ERR_HCHALTED set-usb-error  then
      dup 10 and  if  " Host controller process error"  USB_ERR_HCERROR set-usb-error  then
           8 and  if  " Host system error"  USB_ERR_HOSTERROR set-usb-error  then
   then
;
' (process-hc-status) to process-hc-status

external
\ Kick the USB controller into operation mode.
: start-usb     ( -- )
   0 frnum!			\ Start at frame 0
   framelist-phys flbaseadd!
   h# c1 usbcmd!		\ Run, Config, Max Packet=64
;
: stop-usb  ( -- )  h# c0 usbcmd!  ;
: suspend-usb   ( -- )  ;

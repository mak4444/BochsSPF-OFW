purpose: USB device driver common routines

hex

\ fl d:include\dev\usbm\error.fth			\ USB error definitions
\ fl d:include\dev\usbm\pkt-data.fth		\ Packet data definitions
hcdcallfth  \ ( ) fl d:include\dev\usbm\hcd\hcd-call.fth		\ HCD interface

0 value device
0 value configuration

0 value bulk-in-pipe
0 value bulk-out-pipe
0 value /bulk-in-pipe
0 value /bulk-out-pipe

0 value intr-in-pipe
0 value intr-out-pipe
0 value intr-in-interval
0 value intr-out-interval
0 value /intr-in-pipe
0 value /intr-out-pipe

0 value iso-in-pipe
0 value iso-out-pipe
0 value iso-in-interval
0 value iso-out-interval
0 value /iso-in-pipe
0 value /iso-out-pipe

false instance value debug?

: debug-on  ( -- )  true to debug?  ;

: get-int-property  ( name$ -- n )
  get-my-property  if  0  else  decode-int nip nip  then
;

\ This needs to be called every time that the device could have changed
: set-device  ( -- )  " assigned-address"  get-int-property  to device  ;
: set-device?  ( -- error?  )  set-device  device -1 =  ;


: init  ( -- )
   set-device
   " configuration#"    get-int-property  to configuration
   " bulk-in-pipe"      get-int-property  to bulk-in-pipe
   " bulk-out-pipe"     get-int-property  to bulk-out-pipe
   " bulk-in-size"      get-int-property  to /bulk-in-pipe
   " bulk-out-size"     get-int-property  to /bulk-out-pipe
   " iso-in-pipe"       get-int-property  to iso-in-pipe
   " iso-out-pipe"      get-int-property  to iso-out-pipe
   " iso-in-size"       get-int-property  to /iso-in-pipe
   " iso-out-size"      get-int-property  to /iso-out-pipe
   " iso-in-interval"   get-int-property  to iso-in-interval
   " iso-out-interval"  get-int-property  to iso-out-interval
   " intr-in-pipe"      get-int-property  to intr-in-pipe
   " intr-out-pipe"     get-int-property  to intr-out-pipe
   " intr-in-size"      get-int-property  to /intr-in-pipe
   " intr-out-size"     get-int-property  to /intr-out-pipe
   " intr-in-interval"  get-int-property  to intr-in-interval
   " intr-out-interval" get-int-property  to intr-out-interval
;
\ debug init


purpose: USB device driver common routines


\ fl d:include\dev\usbm\error.fth			\ USB error definitions
\ fl d:include\dev\usbm\pkt-data.fth		\ Packet data definitions
\ hcdcallfth  \ ( ) fl d:include\dev\usbm\hcd\hcd-call.fth		\ HCD interface
: commonfth
hex
hcdcallfth
S" 0 value device" eval
S" 0 value configuration" eval
S" 0 value bulk-in-pipe" eval
S" 0 value bulk-out-pipe" eval
S" 0 value /bulk-in-pipe" eval
S" 0 value /bulk-out-pipe" eval
S" 0 value intr-in-pipe" eval
S" 0 value intr-out-pipe" eval
S" 0 value intr-in-interval" eval
S" 0 value intr-out-interval" eval
S" 0 value /intr-in-pipe" eval
S" 0 value /intr-out-pipe" eval
S" 0 value iso-in-pipe" eval
S" 0 value iso-out-pipe" eval
S" 0 value iso-in-interval" eval
S" 0 value iso-out-interval" eval
S" 0 value /iso-in-pipe" eval
S" 0 value /iso-out-pipe" eval

S" false instance value debug?" eval

S" : debug-on  ( -- )  true to debug?  ;" eval

S" : get-int-property" eval  ( name$ -- n )
S"  get-my-property  if  0  else  decode-int nip nip  then ;" eval

\ This needs to be called every time that the device could have changed
 " : set-device  ( -- ) "" assigned-address""  get-int-property  to device  ;" eval
S" : set-device?  ( -- error?  )  set-device  device -1 =  ;" eval


S" : init  ( -- ) set-device" eval
 "  "" configuration#""    get-int-property  to configuration" eval
 "  "" bulk-in-pipe""      get-int-property  to bulk-in-pipe" eval
 "  "" bulk-out-pipe""     get-int-property  to bulk-out-pipe" eval
 "  "" bulk-in-size""      get-int-property  to /bulk-in-pipe" eval
 "  "" bulk-out-size""     get-int-property  to /bulk-out-pipe" eval
 "  "" iso-in-pipe""       get-int-property  to iso-in-pipe" eval
 "  "" iso-out-pipe""      get-int-property  to iso-out-pipe" eval
 "  "" iso-in-size""       get-int-property  to /iso-in-pipe" eval
 "  "" iso-out-size""      get-int-property  to /iso-out-pipe" eval
 "  "" iso-in-interval""   get-int-property  to iso-in-interval" eval
 "  "" iso-out-interval""  get-int-property  to iso-out-interval" eval
 "  "" intr-in-pipe""      get-int-property  to intr-in-pipe" eval
 "  "" intr-out-pipe""     get-int-property  to intr-out-pipe" eval
 "  "" intr-in-size""      get-int-property  to /intr-in-pipe" eval
 "  "" intr-out-size""     get-int-property  to /intr-out-pipe" eval
 "  "" intr-in-interval""  get-int-property  to intr-in-interval" eval
 "  "" intr-out-interval"" get-int-property  to intr-out-interval ;" eval
;


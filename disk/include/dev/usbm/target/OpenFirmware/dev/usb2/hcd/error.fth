purpose: Internal USB error codes for use by USB HCD drivers

headers
hex

\ fl d:include\dev\usbm\error.fth

0 value usb-error

: clear-usb-error  ( -- )  0 to usb-error  ;
: set-usb-error  ( $ err -- )
   usb-error or to usb-error
   debug?  if  type cr  else  2drop  then
;



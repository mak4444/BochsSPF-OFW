purpose: USB elaborations for the BIOS loaded OFW

0 value usb-delay  \ Milliseconds to wait before set-address

devalias u    /usb/disk

\ Like $show-devs, but ignores pagination keystrokes
: $nopage-show-devs  ( nodename$ -- )
   ['] exit? behavior >r  ['] false to exit?
   $show-devs
   r> to exit?
;

: (probe-usb2)  ( -- )
   " device_type" get-property  if  exit  then
[ifdef] use-usb-debug-port
   \ I haven't figured out how to turn on the EHCI cleanly
   \ when the Debug Port is running
   dbgp-off
[then]
   get-encoded-string  " ehci" $=  if
      pwd$ open-dev  ?dup  if  close-dev  then
   then
;
: (show-usb2)  ( -- )
   " device_type" get-property  if  exit  then
   get-encoded-string  " ehci" $=  if
      pwd$ $nopage-show-devs
   then
;
: (probe-usb1)  ( -- )
   " device_type" get-property  if  exit  then
   get-encoded-string  2dup " uhci" $= >r  " ohci" $= r> or  if
      pwd$ open-dev  ?dup  if  close-dev  then
   then
;
: (show-usb1)  ( -- )
   " device_type" get-property  if  exit  then
   get-encoded-string  2dup " uhci" $= >r  " ohci" $= r> or  if
      pwd$ $nopage-show-devs
   then
;
: probe-usb  ( -- )
   ." USB2 devices:" cr
   " /" ['] (probe-usb2) scan-subtree
   " /" ['] (show-usb2) scan-subtree
 exit
   ." USB1 devices:" cr
   " /" ['] (probe-usb1) scan-subtree
   " /" ['] (show-usb1) scan-subtree
;
alias p2 probe-usb
[ifdef] mmo
: ?usb-keyboard  ( -- )
   " keyboard" expand-alias  if   ( devspec$ )
      drop " /usb"  comp  0=  if  ( )
         red-letters  ." Using USB keyboard." cr  cancel
         " keyboard" input
         exit
      then
   then
   " /usb/serial" open-dev  ?dup  if
      red-letters  ." Using USB serial console." cr  cancel
      dup set-stdin set-stdout
   then
;
[then]

\ Unlink every node whose phys.hi component matches port
: port-match?  ( port -- flag )
   get-unit  if  drop false exit  then
   get-encoded-int =
;

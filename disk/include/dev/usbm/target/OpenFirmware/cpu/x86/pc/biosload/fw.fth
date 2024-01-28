true to stand-init-debug?

hex
\ stand-init-debug?  [if]
warning @  warning off 
: init
\ initial-heap add-memory
   init

\  cr0@ h# 9fff.ffff and cr0!	\ enable L1 and L2 caches
;
warning !
\ [then]

: (.firmware)  ( -- )
   ." Open Firmware  "  .built  cr
   ." Copyright 1999 FirmWorks  All Rights Reserved" cr
;
' (.firmware) to .firmware


: probe-all  ( -- )
   ." report-disk" HERE .H  cr   report-disk
   ." probe-pci"  HERE .H cr   probe-pci

;

\ This reduces processor use when waiting for a key.  It helps
\ a lot when running on an emulator.
\ mmo : c1-idle  ( -- )  interrupts-enabled?  if  halt  then  ;
\ mmo ' c1-idle to stdin-idle

: startup  ( -- )
   standalone?  0=  if  exit  then
   ." calibrate-ms"  cr
   calibrate-ms

    ." nvramrc"  HERE .H cr

      install-mux-io

   auto-banner?  if
      " Probing" type  HERE .H  probe-all
   ." install-mux-io"  cr

\ mmo      ?usb-keyboard
   then

   hex
   warning on
   only forth also definitions

   ." Installing alarms" cr
\ mmo   install-alarm

   #line off

   ." Open Firmware demonstration version by FirmWorks (info@firmworks.com)" cr

s" c:autoexec.4" included
   quit
;
\ : zz s" u:autoexec.4" included ;

alias crcgen drop  ( crc byte -- crc' )

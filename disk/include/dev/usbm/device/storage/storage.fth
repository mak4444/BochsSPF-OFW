
headers
hex

" usb-storage" device-type
0 encode-int " #size-cells"    property
1 encode-int " #address-cells" property


external

: decode-unit  ( addr len -- lun )  push-hex  $number  if  0  then  pop-base  ;
: encode-unit  ( lun -- adr len )   push-hex (u.) pop-base  ;

\ These routines may be called by the children of this device.
\ This card has no local buffer memory for the ATAPI device, so it
\ depends on its parent to supply DMA memory.  For a device with
\ local buffer memory, these routines would probably allocate from
\ that local memory.

h#  800 constant low-speed-max
h# 2000 constant full-speed-max
h# 4000 constant high-speed-max
: my-max  ( -- n )
   " low-speed"  get-my-property 0=  if  2drop low-speed-max  exit  then
   " full-speed" get-my-property 0=  if  2drop full-speed-max exit  then
   high-speed-max
;
: max-transfer ( -- n )
   " max-transfer" ['] $call-parent catch if
      2drop my-max
   then
   my-max min
;

commonfth \ fl d:include\dev\usbm\device\common.fth		\ USB device driver common routines
scsifth  \ fl d:include\dev\usbm\device\storage\scsi.fth	\ High level SCSI routines
atapifth \ fl d:include\dev\usbm\device\storage\atapi.fth	\ ATAPI interface support
hacomfth \ fl d:include\dev\usbm\device\storage\hacom.fth	\ Basic SCSI routines

new-device
   " disk" device-name
scsidiskfth \ fl d:include\dev\usbm\device\storage\scsidisk.fth
finish-device
cr .( my-self=) my-self .h

 init

\ rstrace


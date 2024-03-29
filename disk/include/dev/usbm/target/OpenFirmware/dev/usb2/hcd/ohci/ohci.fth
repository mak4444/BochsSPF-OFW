purpose: Driver for OHCI USB Controller

hex
headers

defer end-extra				' noop to end-extra

1 constant potpgt			\ PowerONToPowerGoodTime

true value first-open?
0 value open-count
0 value ohci-reg

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;

: map-regs  ( -- )
   4 my-w@  h# 16 or  4 my-w!
   0 0 my-space h# 02000010 + 1000  " map-in" $call-parent to ohci-reg
;

: unmap-regs  ( -- )
   ohci-reg  1000  " map-out" $call-parent  0 to ohci-reg
;

: ohci-reg@  ( idx -- data )  ohci-reg + rl@  ;
: ohci-reg!  ( data idx -- )  ohci-reg + rl!  ;

: hc-cntl@  ( -- data )   4 ohci-reg@  ;
: hc-cntl!  ( data -- )   4 ohci-reg!  ;
: hc-stat@  ( -- data )   8 ohci-reg@  ;
: hc-cmd!   ( data -- )   8 ohci-reg!  ;
: hc-intr@  ( -- data )   c ohci-reg@  ;
: hc-intr!  ( data -- )   c ohci-reg!  ;
: hc-hcca@  ( -- data )  18 ohci-reg@  ;
: hc-hcca!  ( data -- )  18 ohci-reg!  ;

: hc-rh-desA@  ( -- data )  48 ohci-reg@  ;
: hc-rh-desA!  ( data -- )  48 ohci-reg!  ;
: hc-rh-desB@  ( -- data )  4c ohci-reg@  ;
: hc-rh-desB!  ( data -- )  4c ohci-reg!  ;
: hc-rh-stat@  ( -- data )  50 ohci-reg@  ;
: hc-rh-stat!  ( data -- )  50 ohci-reg!  ;

: hc-rh-psta@  ( port -- data )  4 * 54 + ohci-reg@  ;
: hc-rh-psta!  ( data port -- )  4 * 54 + ohci-reg!  ;

: hc-cntl-clr  ( bit-mask -- )  hc-cntl@ swap invert and hc-cntl!  ;
: hc-cntl-set  ( bit-mask -- )  hc-cntl@ swap or hc-cntl!  ;

: reset-port  ( port -- )
   >r
   h# 10002 r@ hc-rh-psta!		\ enable port
   h# 10 r@ hc-rh-psta!			\ reset port
   r@ d# 10 0  do
      d# 10 ms
      dup hc-rh-psta@ 100000 and  ?leave
   loop  drop
   r@ hc-rh-psta@ 100000 and 0=  if  abort  then
   h# 1f0000 r> hc-rh-psta!		\ clear status change bits
   d# 256 ms
;

: reset-usb  ( -- )
   ohci-reg dup 0=  if  map-regs  then
   1 hc-rh-stat!		\ power-off root hub
   1 hc-cmd!			\ reset usb host controller
   d# 10 ms
   0= if  unmap-regs  then
;

: init-ohci-regs  ( -- )
   hcca-phys hc-hcca!		\ physical address of hcca

   81 hc-cntl!			\ USB operational, 2:1 ControlBulkServiceRatio
   d# 10 ms

   a668.2edf 34 ohci-reg!	\ HcFmInterval
   2580 40 ohci-reg!		\ HcPeriodicStart
;

: (process-hc-status)  ( -- )
   hc-intr@ dup hc-intr!
   h# 10 and  if  " Unrecoverable error" USB_ERR_HCHALTED set-usb-error  then
;
' (process-hc-status) to process-hc-status

: wait-for-frame  ( -- )  begin  hc-intr@ 4 and  until  ;
: next-frame      ( -- )  4 hc-intr!  wait-for-frame    ;

external
\ Kick the USB controller into operation mode.
: start-usb     ( -- )  c0 hc-cntl-clr 80 hc-cntl-set  ;
: suspend-usb   ( -- )  c0 hc-cntl-set  ;

headers

[ifndef] tokenizing
also forth definitions
warning @  warning off
: beep  ( -- )  " /isa/timer" " ring-bell" execute-device-method drop  ;
warning !

stand-init: ISA
   " /isa"                 " init"  execute-device-method drop
\ mmo   " /isa/interrupt-controller"  " init"  execute-device-method drop
   " /isa/timer"           " init"  execute-device-method drop
   " /isa/dma-controller"  " init"  execute-device-method drop
;
previous definitions
[then]

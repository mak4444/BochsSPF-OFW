
new-device  0 0  " i40" set-args
   " timer" device-name
   " timer" device-type

   " pnpPNP,100" " compatible" string-property

   40 1 4 encode-reg  61 1 1 encode-reg encode+  " reg" property
[ifdef] PREP
   0 encode-int  " interrupts" property
[else]   
   0 encode-int  3 encode-int encode+  " interrupts"  property
[then]

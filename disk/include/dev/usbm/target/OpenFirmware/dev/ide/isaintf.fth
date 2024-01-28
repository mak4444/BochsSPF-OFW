purpose: IDE bus package implementing a "ide" device-type interface.


cr .( my-#adr-cells=) .s .( |) here origin - .h .( |)  my-#adr-cells . cr 

hex

create include-secondary-ide \ mmo

\ Map the device into virtual address space
: (map)  ( -- pri-chip-base pri-dor sec-chip-base sec-dor )
   my-address my-space 8 " map-in" $call-parent
   h# 3f6     my-space 1 " map-in" $call-parent
[ifdef] include-secondary-ide
   h# 170     my-space 8 " map-in" $call-parent
   h# 376     my-space 1 " map-in" $call-parent
[else]
   0 0
[then]
;

\ Release the mapping resources used by the device
: (unmap)  ( pri-chip-base pri-dor sec-chip-base sec-dor -- )
[ifdef] include-secondary-ide
   8  " map-out" $call-parent
   1  " map-out" $call-parent
[else]
   2drop
[then]
   8  " map-out" $call-parent
   1  " map-out" $call-parent
;

: int+  ( adr len n -- adr' len' )  encode-int encode+  ;

0 0 encode-bytes
cr .( encode-bytes=) .s .( |) here origin - .h .( |)  my-#adr-cells . cr 
h# 1f0 1  encode-phys
cr .( encode-1f0=) .s .( |) here origin - .h cr 
  encode+
cr .( encode-1f0+=) .s .( |) here origin - .h cr 
  8 int+
cr .( encode-8=) .s .( |) here origin - .h cr 

h# 3f6 1  encode-phys  encode+
cr .( encode-3f6=) .s cr
  2 int+
[ifdef] include-secondary-ide
h# 170 1  encode-phys  encode+  8 int+
h# 376 1  encode-phys  encode+  2 int+
[then]
" reg" property

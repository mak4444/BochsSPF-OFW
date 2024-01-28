\ IDE disk package implementing a "block" device-type interface.
\
\

hex

" disk" device-name
" block" device-type

headers

0 instance value /block

0 instance value deblocker
: init-deblocker  ( -- okay? )
   " "  " deblocker"  $open-package  to deblocker
   deblocker if
      true
   else
      ." Can't open deblocker package"  cr  false
   then
;

0 instance value offset-low     \ Offset to start of partition
0 instance value offset-high

0 instance value label-package

\ Sets offset-low and offset-high, reflecting the starting location of the
\ partition specified by the "my-args" string.

: init-label-package  ( -- okay? )
   0 to offset-high  0 to offset-low
   my-args  " disk-label"  $open-package to label-package
   label-package  if
      0 0  " offset" label-package $call-method to offset-high to offset-low
      true
   else
      ." Can't open disk label package"  cr  false
   then
;

\ The IDE disk package needs to export dma-alloc and dma-free
\ methods so the deblocker can allocate DMA-capable buffer memory.

external
: dma-alloc  ( n -- vaddr )  " dma-alloc" $call-parent  ;
: dma-free   ( vaddr n -- )  " dma-free"  $call-parent  ;

\ Return device block size; cache it the first time we find the information
\ This method is called by the deblocker
: block-size  ( -- n )
   /block  if  /block exit  then        \ Don't ask if we already know
   " block-size"  $call-parent   dup to /block
;
   
: #blocks  ( -- n )  " #blocks"  $call-parent  ;

\ These three methods are called by the deblocker.

: max-transfer  ( -- n )  " max-transfer"  $call-parent  ;
: read-blocks   ( addr block# #blocks -- #read )  " read-blocks" $call-parent  ;
: write-blocks  ( addr block# #blocks -- #written )  " write-blocks" $call-parent  ;

\ Stub implementation of asynchronous write interface
0 instance value #written
: write-blocks-start  ( addr block# #blocks -- )
   " write-blocks" $call-parent to #written
;
: write-blocks-finish  ( -- #written )  #written  ;


\ Methods used by external clients

: open  ( -- flag )
   my-unit dup 3 >  if  2drop false exit  then
   " set-address" $call-parent

   " ide-inquiry" $call-parent  if  drop  else  false exit  then  ( )

   block-size ?dup 0=  if  false exit  then  to /block

   #blocks  0=  if  false exit  then

   init-deblocker  0=  if  false exit  then

   init-label-package  0=  if
      deblocker close-package false exit
   then

   true
;

: close  ( -- )
   label-package close-package
   deblocker close-package
;

: seek  ( offset.low offset.high -- okay? )
   offset-low offset-high  d+  " seek"   deblocker $call-method
;

: read  ( addr len -- actual-len )  " read"  deblocker $call-method  ;
: write ( addr len -- actual-len )  " write" deblocker $call-method  ;
: load  ( addr     -- size )        " load"  label-package $call-method  ;

: size  ( -- d.size )               " size"  label-package $call-method  ;

finish-device
end-package

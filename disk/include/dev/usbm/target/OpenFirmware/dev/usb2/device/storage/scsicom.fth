purpose: words which are useful for both SCSI disk and SCSI tape device drivers.

: scsicomfth 
hex
\ The SCSI disk and SCSI tape packages need to export dma-alloc and dma-free
\ methods so the deblocker can allocate DMA-capable buffer memory.

 " : dma-alloc  ( n -- vaddr )  "" dma-alloc"" $call-parent  ;" eval
 " : dma-free   ( vaddr n -- )  "" dma-free""  $call-parent  ;" eval
 " : parent-max-transfer  ( -- n )  "" max-transfer""  $call-parent  ;" eval
 " : parent-set-address  ( lun -- )  "" set-address"" $call-parent  ;" eval


\ Calls the parent device's "retry-command?" method.  The parent device is
\ assumed to be a driver for a SCSI host adapter (device-type = "scsi")

s" : retry-command?" eval  ( dma-addr dma-len dma-dir cmd-addr cmd-len #retries -- actual errcode )
 "    "" retry-command?"" $call-parent ;" eval


\ Simplified command execution routines for common simple command forms

 " : no-data-command  ( cmdbuf -- error? )  "" no-data-command"" $call-parent  ;" eval

s" : short-data-command" eval  ( data-len cmdbuf cmdlen #retries -- true | buffer len false )
 "    "" short-data-command"" $call-parent ;" eval


\ Some tools for reading and writing 2, 3, and 4 byte numbers to and from
\ SCSI command and data buffers.  The ones defined below are used both in
\ the SCSI disk and the SCSI tape packages.  Other variations that are
\ used only by one of the packages are defined in the package where they
\ are used.

s" : +c!  ( n addr -- addr' )  tuck c! 1+  ;" eval
s" : 3c!  ( n addr -- )  >r lbsplit drop  r> +c! +c! c!  ;" eval
s" : -c@  ( addr -- n addr' )  dup c@  swap 1-  ;" eval
s" : 3c@  ( addr -- n )  2 +  -c@ -c@  c@       0  bljoin  ;" eval
s" : 4c@  ( addr -- n )  3 +  -c@ -c@ -c@  c@      bljoin  ;" eval


\ "Scratch" command buffer useful for construction of read and write commands

s" d# 10 constant /cmdbuf" eval
s" create cmdbuf  0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c," eval
s" : cb!  ( byte index -- )  cmdbuf + c!  ;" eval        \ Write byte to command buffer

s" create eject-cmd  h# 1b c, 1 c, 0 c, 0 c, 2 c, 0 c," eval

s" : device-present?" eval  ( lun -- present? )  
s"    parent-set-address" eval
 "    "" inquiry""  $call-parent  0= ;" eval
s" : eject ( -- )" eval
s"    my-unit device-present?  if" eval
s"       eject-cmd no-data-command  drop" eval
s"    then ;" eval
 
\ The deblocker converts a block/record-oriented interface to a byte-oriented
\ interface, using internal buffering.  Disk and tape devices are usually
\ block or record oriented, but the OBP external interface is byte-oriented,
\ in order to be independent of particular device block sizes.

s" 0 value deblocker" eval
s" : init-deblocker  ( -- okay? )" eval
 "    "" ""  "" deblocker""  $open-package  to deblocker" eval
s"    deblocker if" eval
s"       true" eval
s"    else" eval
 "       ."" Can't open deblocker package""  cr  false" eval
s"    then ;" eval

\ headerless
\ : selftest  ( -- )
\       my-unit " set-address" $call-parent
\       " diagnose" $call-parent
\ ;
;


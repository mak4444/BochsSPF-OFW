purpose: SCSI disk package implementing a "block" device-type interface.


: scsidiskfth 
hex

" block" device-type
" disk"  encode-string  " compatible" property
" usbdisk" " iconname" string-property

scsicomfth \ fload d:include\dev\usbm\device\storage\scsicom.fth	\ Utility routines for SCSI commands

hex

\ 0 means no timeout
 " : set-timeout  ( msecs -- )  "" set-timeout"" $call-parent  ;" eval

s" 0 instance value offset-low" eval     \ Offset to start of partition
s" 0 instance value offset-high" eval

external
s" 0 instance value label-package" eval
s" true value report-failure" eval
headers

\ Sets offset-low and offset-high, reflecting the starting location of the
\ partition specified by the "my-args" string.

s" : init-label-package" eval  ( -- okay? )
s"    0 to offset-high  0 to offset-low" eval
 "    my-args  "" disk-label""  $open-package to label-package" eval
s"    label-package dup  if" eval
 "       0 0  "" offset"" label-package $call-method to offset-high to offset-low" eval
s"    else" eval
s"       report-failure  if" eval
 "          ."" Can't open disk label package""  cr" eval
s"       then" eval
s"    then ;" eval

\ Checks to see if a device is ready

s" : unit-ready?" eval  ( -- ready? )
 "    "" ""(00 00 00 00 00 00)"" drop  no-data-command  0= ;" eval

\ Some devices require a second TEST UNIT READY, despite returning
\ CHECK CONDITION, with sense NOT READY and MEDIUM NOT PRESENT.

s" : retry-unit-ready?" eval  ( -- ready? )
s"    unit-ready?  ?dup  if  exit  then" eval
s"    unit-ready? ;" eval

\ Ensures that the disk is spinning, but doesn't wait forever

s" create sstart-cmd  h# 1b c, 0 c, 0 c, 0 c, 1 c, 0 c," eval

s" : timed-spin" eval  ( -- error? )
s"    0 0 true  sstart-cmd 6  -1 retry-command?  nip  ?dup  if" eval  ( error-code )
      \ true on top of the stack indicates a hardware error.
      \ We don't treat "illegal request" as an error because some drives
      \ don't support the start command.  Everything else other than
      \ success is considered an error.
s"       5 <>" eval                                       ( error? )
s"    else      false" eval                                      ( false )
s"    then" eval                                          ( error? )
s"    0 set-timeout ;" eval

s" create read-capacity-cmd h# 25 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c," eval

s" : get-capacity" eval  ( -- false | block-size #blocks false true )
s"    8  read-capacity-cmd 0a  0  short-data-command  if  false" eval
s"    else" eval                                        ( adr len )
s"       8 <>  if  drop false exit  then" eval          ( adr )
s"       dup 4 + 4c@  swap 4c@  1+  false true" eval
s"    then ;" eval

s" notdef" $find ?dup
if
\ This is a "read for nothing", discarding the result.  It's a
\ workaround for a problem with the "Silicon Motion SMI331" controller
\ as used in the "Transcend TS2GUSD-S3" USB / MicroSD reader.  That
\ device stalls "read capacity" commands until you do the first block
\ read. The first block read stalls too, but afterwards everything works. 
s" : nonce-read" eval  ( -- )
s"    d# 512 dma-alloc  >r" eval
 "    r@ d# 512 true  "" ""(28 00 00 00 00 00 00 00 01 00)"" " eval ( data$ in? cmd$ )
s"    0  retry-command? 2drop" eval
s"    r> d# 512 dma-free ;" eval
then 2drop

s" : read-block-extent" eval  ( -- true | block-size #blocks false )
   \ Try "read capacity" a few times.  Support for that command is
   \ mandatory, but some devices aren't ready for it immediately.
s"    d# 20  0  do" eval
s"       get-capacity  if  unloop exit  then" eval  ( )
s"       d# 200 ms" eval
s"    loop" eval

s" notdef" $find ?dup
if
   \ At least one device stalls read-capacity until the first block read
s"    nonce-read" eval

   \ Retry it a few more times
s"    d# 18  0  do" eval
s"       get-capacity  if  unloop exit  then" eval
s"       d# 200 ms" eval
s"    loop" eval
then 2drop

   \ If it fails, we just guess.  Some devices violate the spec and
   \ fail to implement read_capacity
s"    d# 512  h# ffffffff  false ;" eval

s" report-geometry" $find ?dup
if
s" create mode-sense-geometry    h# 1a c, 0 c, 4 c, 0 c, d# 36 c, 0 c," eval

\ The sector/track value reported below is an average, because modern SCSI
\ disks often have variable geometry - fewer sectors on the inner cylinders
\ and spare sectors and tracks located at various places on the disk.
\ If you multiply the sectors/track number obtained from the format info
\ mode sense code page by the heads and cylinders obtained from the geometry
\ page, the number of blocks thus calculated usually exceeds the number of
\ logical blocks reported in the mode sense block descriptor, often by a
\ factor of about 25%.

\ Return true for error, otherwise disk geometry and false
s" : geometry" eval  ( -- true | sectors/track #heads #cylinders false )
s"    d# 36  mode-sense-geometry  6  2" eval  ( len cmd$ #retries )
s"    short-data-command  if  true exit  then" eval   ( adr len )
s"    d# 36 <>  if  drop true exit  then" eval        ( adr )
s"    >r" eval                                ( r: adr )
s"    r@ d# 17 + c@   r@ d# 14 + 3c@" eval   ( heads cylinders )
s"    2dup *  r> d# 4 + 4c@" eval             ( heads cylinders heads*cylinders #blocks )
s"    swap /  -rot" eval                      ( sectors/track heads cylinders )
s"    false ;" eval
then 2drop

\ This method is called by the deblocker

s" 0 value #blocks" eval
s" 0 value block-size" eval

headers

\ Read or write "#blks" blocks starting at "block#" into memory at "addr"
\ Input? is true for reading or false for writing.
\ command is  8  for reading or  h# a  for writing
\ We use the 6-byte forms of the disk read and write commands where possible.

s" : 2c!  ( n addr -- )  >r lbsplit 2drop  r> +c!         c!  ;" eval
s" : 4c!  ( n addr -- )  >r lbsplit        r> +c! +c! +c! c!  ;" eval

s" : r/w-blocks" eval  ( addr block# #blks input? command -- actual# )
s"    cmdbuf /cmdbuf erase" eval
s" use-short-form" $find ?dup
if
s"    2over  h# 100 u>  swap h# 200000 u>=  or  if" eval  ( addr block# #blks dir cmd )
then 2drop
      \ Use 10-byte form
s"       h# 20 or  0 cb!" eval  \ 28 (read) or 2a (write)  ( addr block# #blks dir )
s"       -rot swap" eval                                   ( addr dir #blks block# )
s"       cmdbuf 2 + 4c!" eval                              ( addr dir #blks )
s"       dup cmdbuf 7 + 2c!" eval                          ( addr dir #blks )
s"       d# 10" eval                                       ( addr dir #blks cmdlen )
s" use-short-form" $find ?dup
if
s"    else" eval                                           ( addr block# #blks dir cmd )
      \ Use 6-byte form
s"       0 cb!" eval                                       ( addr block# #blks dir )
s"       -rot swap" eval                                   ( addr dir #blks block# )
s"       cmdbuf 1+ 3c!" eval                               ( addr dir #blks )
s"       dup 4 cb!" eval                                   ( addr dir #blks )
s"       6" eval                                           ( addr dir #blks cmdlen )
s"    then" eval
then 2drop
s"    swap" eval                                           ( addr dir cmdlen #blks )
s"    dup >r" eval                                         ( addr input? cmdlen #blks )
s"    block-size *  -rot  cmdbuf swap  -1" eval  ( data-adr,len in? cmd-adr,len #retries )
s"    retry-command?  nip  if" eval                        ( r: #blks )
s"       r> drop 0" eval
s"    else" eval
s"       r>" eval
s"    then ;" eval   ( actual# )

\ These three methods are called by the deblocker.

s" : max-transfer  ( -- n )   parent-max-transfer  ;" eval
s" : read-blocks   ( addr block# #blocks -- #read )   true  d# 8  r/w-blocks  ;" eval
s" : write-blocks  ( addr block# #blocks -- #written )  false d# 10 r/w-blocks  ;" eval

\ Methods used by external clients

s" 0 value open-count" eval

s" : open" eval  ( -- flag )
s"    my-unit parent-set-address" eval
s"    open-count  if" eval
s"       d# 2000 set-timeout" eval
s"    else" eval

      \ Set timeout to 45 sec: some large (>1GB) drives take
      \ up to 30 secs to spin up.
s"       d# 45 d# 1000 *  set-timeout" eval

s"       retry-unit-ready?  0=  if  false  exit  then" eval

      \ It might be a good idea to do an inquiry here to determine the
      \ device configuration, checking the result to see if the device
      \ really is a disk.

      \ Make sure the disk is spinning

s"       timed-spin  if  false exit  then" eval

s"       read-block-extent  if  false exit  then" eval  ( block-size #blocks )
s"       to #blocks  to block-size" eval

s"       d# 2000 set-timeout" eval
s"       init-deblocker  0=  if  false exit  then" eval
s"    then" eval

s"    init-label-package  0=  if" eval
s"       open-count 0=  if" eval
s"          deblocker close-package" eval
s"       then" eval
s"       false exit" eval
s"    then" eval
s"    open-count 1+ to open-count" eval

s"    true ;" eval
s" : close" eval  ( -- )
s"    open-count dup  1- 0 max to open-count" eval  ( old-open-count )
s"    label-package close-package" eval             ( old-open-count )
s"    1 =  if" eval
s"       deblocker close-package" eval
s"    then ;" eval

s" : seek" eval  ( offset.low offset.high -- okay? )
 "    offset-low offset-high d+  "" seek""   deblocker $call-method ;" eval

 " : read  ( addr len -- actual-len )  "" read""  deblocker $call-method  ;" eval
 " : write ( addr len -- actual-len )  "" write"" deblocker $call-method  ;" eval
 " : load  ( addr -- size )            "" load""  label-package $call-method  ;" eval
 " : size  ( -- d.size )  "" size"" label-package $call-method  ;" eval
;

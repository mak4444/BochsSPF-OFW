\ Common code for SCSI host adapter drivers.

\ The following code is intended to be independent of the details of the
\ SCSI hardware implementation.  It is loaded after the hardware-dependent
\ file that defines execute-command, set-address, open-hardware, etc.

: hacomfth 
s" -1 value inq-buf" eval                  \ Address of inquiry data buffer
s" -1 value sense-buf" eval                \ holds extended error information


s" 0 value #retries" eval  ( -- n )        \ number of times to retry SCSI transaction

\ Classifies the sense condition as either okay (0), retryable (1),
\ or non-retryable (-1)
s" : classify-sense" eval  ( -- 0 | 1 | -1 )
s"    debug?  if" eval
s"       base @ >r hex" eval
 "       ."" Sense:  "" sense-buf 11 bounds  do  i c@ 3 u.r  loop  .""  ..."" cr" eval
s"       r> base !" eval
s"    then        " eval
s"    sense-buf   " eval

   \ Make sure we understand the error class code
s"    dup c@  h# 7f and h# 70 <>  if  drop -1 exit  then" eval

   \ Check for filemark, end-of-media, or illegal block length
s"    dup 2+ c@  h# e0  and  if  drop -1 exit  then" eval

s"    2 + c@  h# f and" eval   ( sense-key )

   \ no_sense(0) and recoverable(1) are okay
s"    dup 1 <=  if  drop 0 exit  then" eval   ( sense-key )

   \ not-ready(2) may be retryable
s"    dup 2 =  if" eval
      \ check (tapes, especially) for MEDIA NOT PRESENT: if the
      \ media's not there the command is not retryable
s"       drop" eval
s"       sense-buf h# c + c@  h# 3a =  sense-buf h# d + c@ 0=  and" eval  ( not-present? )
s"       if  -1  else  1  then  exit" eval
s"    then" eval

   \ Media-error(3) is not retryable
s"    dup 3 =  if  drop -1 exit  then" eval

   \ Attention(6), and target aborted (b) are retryable.
s"    dup 6 =  swap 0b =  or if  1  else  -1  then ;" eval

s" 0 value open-count" eval

s" : open" eval  ( -- flag )
 "    my-args  "" debug"" $=  if  debug-on  then" eval
s"    open-count  if" eval
s"       reopen-hardware  dup  if  open-count 1+ to open-count  then" eval
s"       exit" eval
s"    else" eval
s"       open-hardware  dup  if" eval
s"          1 to open-count" eval
s"          100 dma-alloc to sense-buf" eval
s"          100 dma-alloc to inq-buf" eval
s"       then" eval
s"    then ;" eval
s" : close" eval  ( -- )
s"    open-count 1- to open-count" eval
s"    open-count  if" eval
s"       reclose-hardware" eval
s"    else" eval
s"       close-hardware" eval
s"       inq-buf   100 dma-free" eval
s"       sense-buf 100 dma-free" eval
s"    then ;" eval
s" create sense-cmd  3 c, 0 c, 0 c, 0 c, ff c, 0 c," eval
s" : get-sense" eval  ( -- failed? )     \ Issue REQUEST SENSE
s"    sense-buf ff  true  sense-cmd 6  execute-command" eval  ( actual cswStatus )
s"   if  drop true  else  8 <  then ;" eval

\ Give the device a little time to recover before retrying the command.
s" : delay-retry  ( -- )   1 ms  ;" eval

\ RETRY-COMMAND executes a SCSI command.  If a check condition is indicated,
\ performs a "get-sense" command.  If the sense bytes indicate a non-fatal
\ condition (e.g. power-on reset occurred, not ready yet, or recoverable
\ error), the command is retried until the condition either goes away or
\ changes to a fatal error.
\
\ The command is retried until:
\ a) The command succeeds, or
\ b) The select fails, or dma fails, or
\ c) The sense bytes indicate an error that we can't retry at this level
\ d) The number of retries is exceeded.

\ #retries is number of times to retry (0: don't retry, -1: retry forever)
\
\ dma-dir is necessary because it is not always possible to infer the DMA
\ direction from the command.

\ Local variables used by retry-command?

s" 0 instance value dbuf" eval             \ Data transfer buffer
s" 0 instance value dlen" eval             \ Expected length of data transfer
s" 0 instance value direction-in" eval     \ Direction for data transfer
s" -1 instance value cbuf" eval            \ Command base address
s"  0 instance value clen" eval            \ Actual length of this command

external

\ errcode values:  0: okay   -1: phase error  otherwise: sense-key

s" : retry-command?" eval  ( dma-buf dma-len dma-dir cmdbuf cmdlen #retries -- actual errcode )
s"    to #retries   to clen  to cbuf  to direction-in  to dlen  to dbuf" eval
s"    begin" eval
s"       dbuf dlen  direction-in  cbuf clen  execute-command" eval  ( actual cswStatus )
s"       dup 0=   if  drop  0 exit  then" eval   \ Exit reporting success
s"       dup 2 >  if  drop -1 exit  then" eval   \ Exit reporting invalid CSW result code

s"      1 =  if" eval                              ( actual )
         \ Do gs"et-sense to determine what to do next
s"          get-sense  if" eval                     ( actual )
            \ Treat a gets"-sense failure like a phase error; just retry the command
s"            -1" eval                             ( actual errcode )
s"          else" eval                              ( actual )
s"            classify-sense  case" eval   ( actual -1|0|1 )
               \ If the sense information says "no sense", return "no-error"
s"               0  of  0 exit  endof" eval

               \ If the error is fatal, return the sense-key
s"                -1  of  sense-buf 2+ c@  exit  endof" eval
s"             endcase" eval
s"             sense-buf 2+ c@" eval                ( actual errcode )
s"          then" eval
s"       else" eval                                 ( actual )
s"          -1" eval     \ Was phase error          ( actual errcode )
s"       then" eval                                 ( actual errcode )

      \ If we get here, the command is retryable - either a phase error
      \ or a non-fatal sense code

s"       #retries 1- dup  to #retries" eval         ( actual errcode #retries )
s"    while" eval                                   ( actual errcode )
s"       2drop" eval                                ( )
s"       delay-retry" eval
s"    repeat ;" eval                                  ( actual errcode )

\ Simplified routine for commands with no data transfer phase
\ and simple error checking requirements.

s" : no-data-command" eval  ( cmdbuf -- error? )
s"    >r  0 0 true  r> 6  -1  retry-command?  nip ;" eval

\ short-data-command executes a command with the following characteristics:
\  a) The data direction is incoming
\  b) The data length is less than 256 bytes

\ The host adapter driver is responsible for supplying the DMA data
\ buffer; if the command succeeds, the buffer address is returned.
\ The buffer contents become invalid when another SCSI command is
\ executed, or when the driver is closed.

s" : short-data-command" eval  ( data-len cmdbuf cmdlen #retries -- true | buffer len false )
s"    >r >r >r  inq-buf swap  true  r> r> r>  retry-command?" eval   ( actual error-code )
s"    if  drop true  else  inq-buf swap false  then ;" eval

\ Here begins the implementation of "show-children", a word that
\ is intended to be executed interactively, showing the user the
\ devices that are attached to the SCSI bus.

\ Tool for storing a big-endian 24-bit number at an unaligned address

s" : 3c!  ( n addr -- )  >r lbsplit drop  r@ c!  r@ 1+ c!  r> 2+ c!  ;" eval


\ Command block template for Inquiry command

s" create inquiry-cmd  h# 12 c, 0 c, 0 c, 0 c, ff c, 0 c," eval

s" : inquiry" eval  ( -- error? )
   \ 8 retries should be more than enough; inquiry commands aren't
   \ supposed to respond with "check condition".
   \ However, empirically, on MC2 EVT1, 8 proves insufficient.

s"    inq-buf ff  true  inquiry-cmd 6  10  retry-command?  nip ;" eval

\ Reads the indicated byte from the Inquiry data buffer

s" : inq@  ( offset -- value )  inq-buf +  c@  ;" eval

s" : .scsi1-inquiry  ( -- )  inq-buf 5 ca+  4 inq@  fa min  type  ;" eval
s" : .scsi2-inquiry  ( -- )  inq-buf 8 ca+  d# 28 type    ;" eval

\ Displays the results of an Inquiry command to the indicated device

s" : show-lun" eval  ( unit -- )
s"    dup  set-address" eval                               ( unit )
s"    inquiry  if  drop exit  then" eval                   ( unit )
s"    0 inq@  h# 60 and  if  drop exit  then" eval         ( unit )
 "    .""   Unit "" . .""   "" " eval                          ( )
 "    1 inq@  h# 80 and  if  ."" Removable ""  then" eval
s"    0 inq@  case" eval

 "       0 of  ."" Disk ""              endof" eval
 "       1 of  ."" Tape ""              endof" eval
 "       2 of  ."" Printer ""           endof" eval
 "       3 of  ."" Processor ""         endof" eval
 "       4 of  ."" WORM ""              endof" eval
 "       5 of  ."" Read Only device""   endof" eval
 "       ( default ) ."" Device type "" dup .h" eval
s"    endcase" eval

s"    4 spaces" eval
s"    3 inq@ 0f and  2 =  if  .scsi2-inquiry  else  .scsi1-inquiry  then" eval
s"    cr ;" eval

\ Searches for devices on the SCSI bus, displaying the Inquiry information
\ for each device that responds.

s" : show-children" eval  ( -- )
 "    open  0=  if  ."" Can't open SCSI host adapter"" cr  exit  then" eval
s"    max-lun 1+ 0  do  i show-lun  loop" eval
s"    close ;" eval

\ Inquire into the specified scsi device type and return the scsi
\ type and true if the device at the specified scsi address is found.

s" : get-scsi-type" eval  ( lun -- false | type true )
s"    open  0=  if  2drop false exit  then" eval
s"    set-address inquiry" eval
s"    if  false  else  0 inq@ dup 7f =  if  drop false  else  true  then  then" eval
s"   close ;" eval

\ The diagnose command is useful for generic SCSI devices.
\ It executes both the "test-unit-ready" and "send-diagnostic"
\ commands, decoding the error status information they return.

s" create test-unit-rdy-cmd        0 c, 0 c, 0 c, 0 c, 0 c, 0 c," eval
s" create send-diagnostic-cmd  h# 1d c, 4 c, 0 c, 0 c, 0 c, 0 c," eval
s" : send-diagnostic ( -- error? )  send-diagnostic-cmd  no-data-command  ;" eval
s" : diagnose" eval  ( -- flag )
s"    0 0 true  test-unit-rdy-cmd 6   -1 " eval  ( dma$ dir cmd$ #retries )
s"    retry-command?  ?dup  if " eval  ( actual error-code )
s"       nip " eval  ( error-code )
 "       ."" Test unit ready failed - "" " eval    ( error-code )
s"       dup -1  if " eval   ( error-code )
 "          ."" phase error "" . cr" eval     ( )
s"       else" eval   ( error-code )
 "          ."" Sense code "" . " eval
 "          ."" extended status = "" cr " eval
s"          base @ >r  hex " eval
s"          sense-buf 8 bounds ?do  i 3 u.r  loop cr " eval
s"          r> base !" eval
s"       then" eval
s"       true" eval
s"    else " eval                 ( actual )
s"       drop" eval                 ( )
s"       send-diagnostic" eval                 ( fail? )
s"    then ; " eval
;

headers


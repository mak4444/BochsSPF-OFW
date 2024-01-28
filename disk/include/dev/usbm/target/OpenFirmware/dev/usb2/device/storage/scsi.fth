purpose: USB Mass Storage Device Driver

: scsifth 
hex
s" 0          value max-lun" eval
s" 0 instance value lun" eval

s" USB_ERR_STALL constant bus-reset" eval

s" defer execute-command-hook  ' noop to execute-command-hook" eval
s" defer init-execute-command  ' noop to init-execute-command" eval


\ Class specific >dr-request constants
s" h# ff constant DEV_RESET" eval
s" h# fe constant GET_MAX_LUN" eval

\ Command Block Wrapper
s" struct" eval
s"     4 field >cbw-sig" eval
s"     4 field >cbw-tag" eval
s"     4 field >cbw-dlen" eval
s"     1 field >cbw-flag" eval
s"     1 field >cbw-lun" eval
s"     1 field >cbw-cblen" eval
s" h# 10 field >cbw-cb" eval
s" constant /cbw" eval

\ >cbw-flag definitions
s" 80 constant cbw-flag-in" eval
s" 00 constant cbw-flag-out" eval

\ Command Status Wrapper
s" struct" eval
s"    4 field >csw-sig" eval
s"    4 field >csw-tag" eval
s"    4 field >csw-dlen" eval
s"    1 field >csw-stat" eval
s" constant /csw" eval

s" h# 43425355 constant cbw-signature" eval	\ little-endian (USBC)
s" h# 53425355 constant csw-signature" eval	\ little-endian (USBS)

s" 0 value cbw-tag" eval
s" 0 value cbw" eval
s" 0 value csw" eval
s" : init-cbw  ( -- )" eval
s"    cbw /cbw erase" eval
s"    cbw-signature cbw >cbw-sig le-l!" eval
s"    cbw-tag 1+ to cbw-tag" eval
s"    cbw-tag cbw >cbw-tag le-l! ;" eval
s" : alloc-bulk  ( -- )" eval
s"    cbw 0=  if  /cbw dma-alloc to cbw  then" eval
s"    csw 0=  if  /csw dma-alloc to csw  then ;" eval
s" : free-bulk  ( -- )" eval
s"    cbw  if  cbw /cbw dma-free  0 to cbw  then" eval
s"   csw  if  csw /csw dma-free  0 to csw  then ;" eval
s" 1 buffer: max-lun-buf" eval

s" : get-max-lun  ( -- )" eval
s"    max-lun-buf 1 my-address ( interface ) 0 DR_IN DR_CLASS DR_INTERFACE or or" eval
s"    GET_MAX_LUN control-get  if			" eval ( actual usberr )
s"       drop 0" eval
s"    else" eval
s"       ( actual )  if  max-lun-buf c@  else  0  then" eval
s"    then" eval
s"    to max-lun ;" eval

s" : init  ( -- )" eval
s"    init" eval
s"    init-execute-command" eval
s"    alloc-bulk" eval
s"    device set-target" eval
s"    get-max-lun" eval
s"    free-bulk ;" eval
s" : transport-reset" eval  ( -- )
s"    0 0 my-address ( interface ) 0 DR_OUT DR_CLASS DR_INTERFACE or or" eval
s"    DEV_RESET control-set-nostat  drop" eval
    \ XXX Wait until devices does not NAK anymore
s"    bulk-in-pipe  h# 80 or unstall-pipe" eval
s"    bulk-out-pipe          unstall-pipe ;" eval

s" : wrap-cbw" eval  ( data-len dir cmd-adr,len -- cbw-adr,len )
s"    init-cbw" eval				( data-len dir cmd-adr,len )
s"    cbw >r" eval				( data-len dir cmd-adr,len )  ( R: cbw )
s"    dup r@ >cbw-cblen c!" eval			( data-len dir cmd-adr,len )  ( R: cbw )
s"    r@ >cbw-cb swap move" eval			( data-len dir )  ( R: cbw )
s"    if  cbw-flag-in  else  cbw-flag-out  then" eval	( data-len cbw-flag )  ( R: cbw )
s"    r@ >cbw-flag c!" eval			( data-len )  ( R: cbw )
s"    r@ >cbw-dlen le-l!" eval			( )  ( R: cbw )
s"    lun r@ >cbw-lun c!" eval			( )  ( R: cbw )
s"    r> /cbw ;" eval				( cbw-adr,len )

s" : (get-csw)  ( -- len usberr )  csw /csw erase  csw /csw bulk-in-pipe bulk-in  ;" eval
s" : get-csw" eval  ( -- len usberr )
s"    (get-csw) dup  if  2drop (get-csw)  then ;" eval

\ This used to be 15 seconds but I shortened it so timeouts can be
\ retried without having to wait too long.
s" d# 2000 constant bulk-timeout" eval

s" : (execute-command)" eval  ( data-adr,len dir cbw-adr,len -- actual-len cswStatus  )
s"    debug?  if" eval
 "       2dup "" dump"" evaluate cr" eval
s"    then" eval
s"    bulk-out-pipe bulk-out" eval		( data-adr,len dir usberr )
s"    USB_ERR_CRC invert and  if" eval		( data-adr,len dir )
s"       transport-reset  3drop 0 2 exit" eval   ( actual=0 status=retry )
s"    then" eval                                 ( data-adr,len dir )
s"    over  if" eval                             ( data-adr,len dir )
s"       if" eval				( data-adr,len )
s"          bulk-in-pipe bulk-in" eval           ( actual usberror )
s"       else" eval				( data-adr,len )
s"          tuck bulk-out-pipe bulk-out" eval    ( len usberror )
s"          dup  if  nip 0 swap  then" eval      ( len' usberror )
s"       then" eval				( usberror )
s"    else" eval					( data-adr,len dir )
s"       drop nip  0" eval			( len usberror )
s"    then" eval					( actual usberror )
s"    get-csw" eval				( actual usberror csw-len csw-usberror )
s"    rot  drop" eval				( actual csw-len csw-usberror )
s"    ?dup  if" eval                             ( actual csw-len csw-usberror )
s"       nip" eval                               ( actual csw-usberror )
s"       dup h# 10000000 =  if" eval             ( actual csw-usberror )
s" notdef" $find ?dup
if
\ This is for testing the problem described in OLPC trac #9423
\ The problem has been worked around so users no longer see it,
\ apart from a short delay when it happens, but for testing you
\ can enable this code to report the problem and count occurrences.
 " cr 7 emit ."" TIMEOUT "" 7 emit" eval
 " h# 72 cmos@ 1+ dup .d h# 72 cmos!" postpone eval
  postpone cr
then 2drop
s"          2drop 0 2" eval                      ( 0 2 )  \ Convert timeout error to a retry
s"       then" eval				( actual usberror )
s"       exit" eval
s"    then" eval					( actual csw-len csw-usberror )
s"    drop" eval                                 ( actual )

s"    debug?  if" eval
 "       csw /csw "" dump"" evaluate cr" eval
s"    then" eval

s"    csw >csw-stat c@" eval		        ( actual cswStatus )
s"    dup 2 =  if  transport-reset  then" eval   ( actual cswStatus )
   \ Values are:
   \  0: No error - command is finished
   \  1: Error - do get-sense and possibly retry
   \  2: Phase error - retry after transport-reset
   \  else: Invalid status code - abort command
postpone ;

s" : execute-command" eval  ( data-adr,len dir cmd-adr,len -- actual cswStatus )
s"    execute-command-hook" eval                         ( data$ dir cmd$ )
s"    over c@ h# 1b =" eval                              ( data$ dir cmd$ flag )
s"    2 pick 4 + c@  1 =  and  >r" eval	                ( data$ dir cmd$ r: Start-command? )
s"    2over 2swap wrap-cbw" eval				( data-adr,len dir cbw-adr,len )
s"    (execute-command)" eval                            ( actual cswStatus )
s"    r>  if  drop 0  then ;" eval \ Fake ok if it's a start commmand
s" : set-address" eval  ( lun -- )
s"    0 max max-lun min  to lun" eval
s"    reset?  if" eval
s"       configuration set-config  if" eval
 "          ."" USB storage scsi layer: Failed to set configuration"" cr" eval
s"       then" eval
s"       bulk-in-pipe bulk-out-pipe reset-bulk-toggles" eval
s"    then ;" eval
s" : set-timeout  ( n -- )  bulk-timeout max set-bulk-in-timeout  ;" eval
s" : reopen-hardware" eval   ( -- ok? )
s"    set-device?  if  false exit  then" eval  \ The device number may have changed if we recycled the node
s"    device set-target" eval
s"    true ;" eval
s" : open-hardware     ( -- ok? )  alloc-bulk  reopen-hardware  ;" eval
s" : reclose-hardware  ( -- )	;" eval
s" : close-hardware    ( -- )      free-bulk  ;" eval
s" : reset  ( -- )  transport-reset  ;" eval
s" : selftest  ( -- 0 | error-code )  0  ;" eval
;

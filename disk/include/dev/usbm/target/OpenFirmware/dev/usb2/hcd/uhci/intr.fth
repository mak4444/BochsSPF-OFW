purpose: UHCI USB Controller interrupt pipes transaction processing


: intrfth hex
S" d# 500 instance value intr-in-timeout" eval

S" 0 instance value intr-in-pipe" eval
S" 0 instance value intr-in-interval" eval

S" 0 instance value intr-in-qh" eval
S" 0 instance value intr-in-td" eval

S" : intr-in-data@   ( -- n )  intr-in-pipe  target di-in-data@  di-data>td-data  ;" eval
S" : intr-in-data!   ( n -- )  td-data>di-data intr-in-pipe  target di-in-data!   ;" eval
S" : toggle-intr-in-data   ( -- )  intr-in-pipe  target di-in-data-toggle   ;" eval

\ Fix up data toggle bit if error OR partially finished Q context.
S" : fixup-intr-in-data" eval  ( td #td -- )
S"    usb-error USB_ERR_STALL and  if" eval
S"       2drop intr-in-pipe h# 80 or unstall-pipe" eval
S"       0 intr-in-data!" eval
S"       exit" eval
S"    then" eval
S"    0  ?do" eval
S"       dup >hctd-stat le-l@ TD_STAT_ACTIVE  and  if" eval
S"          dup >hctd-token le-l@  intr-in-data!" eval
S"          leave" eval
S"       then" eval
S"       >td-next @" eval
S"   loop  drop ;" eval

S" : process-intr-args  ( buf len pipe timeout -- )  process-bulk-args  ;" eval
S" : alloc-intr-qhtds   ( -- qh td )  alloc-bulk-qhtds  ;" eval

S" : fill-intr-io-tds" eval  ( dir td -- )
S"    /my-buf over >td-/buf-all l!" eval			( dir td )
S"    my-#tds 0  ?do" eval				( dir td )
S"      TD_STAT_ACTIVE TD_CTRL_C_ERR3 or" eval		( dir td stat )
S"       TD_CTRL_SPD or my-speed or" eval		( dir td stat' )
S"       over >td-next l@ 0=  if  TD_CTRL_IOC or  then" eval	( dir td stat' )
S"       over >hctd-stat le-l!" eval			( dir td )
S"       /my-buf my-maxpayload min dup 1- d# 21 <<" eval	( dir td /buf token )
S"       intr-in-data@  toggle-intr-in-data or" eval	( dir td /buf token' )
S"       3 pick or my-dev/pipe or" eval			( dir td /buf token' )
S"       2 pick >hctd-token le-l!" eval			( dir td /buf )
S"       my-buf-phys 2 pick 2dup >hctd-buf le-l!" eval	( dir td /buf pbuf td )
S"       >td-pbuf l!" eval				( dir td /buf )
S"       my-buf 2 pick >td-buf l!" eval			( dir td /buf )
S"       my-buf++" eval					( dir td )
S"       >td-next l@" eval				( dir td' )
S"    loop  2drop ;" eval

S" : begin-intr-in" eval  ( buf len pipe interval -- )
 "    debug?  if  ."" begin-intr-in"" cr  then" eval
S"    intr-in-qh  if  4drop exit  then" eval		\ Already started

S"    lock" eval
S"    to intr-in-interval" eval
S"    dup to intr-in-pipe" eval
S"    intr-in-timeout process-intr-args" eval
S"    alloc-intr-qhtds  to intr-in-td  to intr-in-qh" eval

   \ IN TDs
S"    TD_PID_IN intr-in-td fill-intr-io-tds" eval

   \ Start intr in transaction
S"    intr-in-qh intr-in-interval insert-intr-qh" eval
S"    unlock ;" eval

S" : intr-in?" eval  ( -- actual usberr )
S"    intr-in-qh 0=  if  0 USB_ERR_INV_OP exit  then" eval
S"    lock" eval
S"    clear-usb-error" eval
S"    process-hc-status" eval
S"    intr-in-qh dup pull-qhtds" eval
S"    qh-done?  if" eval
S"       intr-in-td intr-in-qh >qh-#tds l@ get-actual" eval	( actual )
S"       usb-error" eval						( actual usberr )
S"       intr-in-td dup >td-buf l@ swap >td-pbuf l@ 2 pick dma-pull" eval
S"       intr-in-td intr-in-qh >qh-#tds l@ fixup-intr-in-data" eval
S"    else" eval
S"       0 usb-error" eval					( actual usberr )
S"    then" eval
S"    unlock ;" eval

S" : restart-intr-in-td" eval  ( td -- )
S"    begin  ?dup  while" eval
S"       dup >hctd-token dup le-l@ TD_TOKEN_DATA1 invert and" eval
S"       intr-in-data@  toggle-intr-in-data  or  swap le-l!" eval
S"       dup >hctd-stat dup le-l@" eval
S"       TD_STAT_ANY_ERROR TD_ACTUAL_MASK or invert and" eval
S"       TD_STAT_ACTIVE or swap le-l!" eval
S"       >td-next l@" eval
S"    repeat ;" eval

S" : restart-intr-in" eval  ( -- )
 "    debug?  if  ."" restart-intr-in"" cr  then" eval
S"    intr-in-qh 0=  if  exit  then" eval
S" 
S"    lock" eval
S"    \ Setup TD again
S"    intr-in-td restart-intr-in-td" eval
S" 
S"    \ Setup QH again
S"    intr-in-td >td-phys l@ intr-in-qh >hcqh-elem le-l!" eval
S"    intr-in-qh push-qhtds" eval
S"    unlock ;" eval

S" : end-intr-in" eval  ( -- )
 "    debug?  if  ."" end-intr-in"" cr  then" eval
S"    intr-in-qh 0=  if  exit  then" eval

S"    lock" eval
S"    intr-in-td intr-in-qh >qh-#tds l@ fixup-intr-in-data" eval
S"    intr-in-td map-out-buf" eval
S"    intr-in-qh dup  remove-qh  free-qhtds" eval
S"    0 to intr-in-qh  0 to intr-in-td" eval
S"    unlock ;" eval

S" : (end-extra)  ( -- )  (end-extra) end-intr-in  ;" eval
S" ' (end-extra) to end-extra" eval
;

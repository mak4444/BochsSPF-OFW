purpose: UHCI USB Controller bulk pipes transaction processing

: bulkfth
hex

s" d# 500 instance value bulk-in-timeout" eval
s" d# 500 constant bulk-out-timeout" eval

s" 0 instance value bulk-in-pipe" eval
s" 0 instance value bulk-out-pipe" eval

s" 0 instance value bulk-in-qh" eval
s" 0 instance value bulk-in-td" eval

s" : bulk-in-data@   ( -- n )  bulk-in-pipe  target di-in-data@  di-data>td-data  ;" eval
s" : bulk-out-data@  ( -- n )  bulk-out-pipe target di-out-data@ di-data>td-data  ;" eval
s" : bulk-in-data!   ( n -- )  td-data>di-data bulk-in-pipe  target di-in-data!   ;" eval
s" : bulk-out-data!  ( n -- )  td-data>di-data bulk-out-pipe target di-out-data!  ;" eval
s" : toggle-bulk-in-data   ( -- )  bulk-in-pipe  target di-in-data-toggle   ;" eval
s" : toggle-bulk-out-data  ( -- )  bulk-out-pipe target di-out-data-toggle  ;" eval

\ Fix up data toggle bit if error OR partially finished Q context.
s" : fixup-bulk-in-data" eval  ( td #td -- )
s"    usb-error USB_ERR_STALL and  if" eval
s"      2drop bulk-in-pipe h# 80 or unstall-pipe" eval
s"      0 bulk-in-data!" eval
s"      exit" eval
s"    then" eval
s"    0  ?do" eval
s"       dup >hctd-stat le-l@ TD_STAT_ACTIVE  and  if" eval
s"          dup >hctd-token le-l@  bulk-in-data!" eval
s"          leave" eval
s"       then" eval
s"       >td-next @" eval
s"    loop  drop ;" eval

s" : fixup-bulk-out-data" eval  ( td #td -- )
s"    usb-error USB_ERR_STALL and  if" eval
s"      2drop bulk-out-pipe unstall-pipe" eval
s"      0 bulk-out-data!" eval
s"      exit" eval
s"    then" eval
s"    0  ?do" eval
s"       dup >hctd-stat le-l@ TD_STAT_ACTIVE  and  if" eval
s"          dup >hctd-token le-l@  bulk-out-data!" eval
s"          leave" eval
s"       then" eval
s"       >td-next @" eval
s"    loop  drop ;" eval

s" : process-bulk-args" eval  ( buf len pipe timeout -- )
s"    to timeout" eval
s"    clear-usb-error" eval
s"    set-my-dev" eval
s"    ( pipe ) set-my-char" eval
s"    2dup hcd-map-in  to my-buf-phys to /my-buf to my-buf ;" eval

s" : alloc-bulk-qhtds" eval  ( -- qh td )
s"    my-maxpayload /my-buf over round-up swap / dup to my-#tds" eval
s"    alloc-qhtds ;" eval

s" : fill-bulk-io-tds" eval  ( dir td -- )
s"    /my-buf over >td-/buf-all l!" eval			( dir td )
s"    my-#tds 0  ?do" eval				( dir td )
s"       TD_STAT_ACTIVE TD_CTRL_C_ERR3 or" eval		( dir td stat )
s"       TD_CTRL_SPD or my-speed or" eval		( dir td stat' )
s"       over >td-next l@ 0=  if  TD_CTRL_IOC or  then" eval	( dir td stat' )
s"       over >hctd-stat le-l!" eval			( dir td )
s"       /my-buf my-maxpayload min dup 1- d# 21 <<" eval	( dir td /buf token )
s"       3 pick TD_PID_IN =  if" eval
s"          bulk-in-data@  toggle-bulk-in-data" eval	( dir td /buf token' )
s"       else" eval
s"          bulk-out-data@ toggle-bulk-out-data" eval	( dir td /buf token' )
s"       then  or" eval
s"       3 pick or my-dev/pipe or" eval			( dir td /buf token' )
s"       2 pick >hctd-token le-l!" eval			( dir td /buf )
s"       my-buf-phys 2 pick 2dup >hctd-buf le-l!" eval	( dir td /buf pbuf td )
s"       >td-pbuf l!" eval				( dir td /buf )
s"       my-buf 2 pick >td-buf l!" eval			( dir td /buf )
s"       my-buf++" eval					( dir td )
s"       >td-next l@" eval				( dir td' )
s"    loop  2drop ;" eval

s" : set-bulk-in-timeout  ( t -- )  ?dup  if  to bulk-in-timeout  then  ;" eval

s" : begin-bulk-in" eval  ( buf len pipe -- )
 "    debug?  if  ."" begin-bulk-in"" cr  then" eval
s"    bulk-in-qh  if  3drop exit  then" eval		\ Already started

s"    dup to bulk-in-pipe" eval
s"    bulk-in-timeout process-bulk-args" eval
s"    alloc-bulk-qhtds  to bulk-in-td  to bulk-in-qh" eval

   \ IN TDs
s"    TD_PID_IN bulk-in-td fill-bulk-io-tds" eval

   \ Start bulk in transaction
s"    bulk-in-qh my-speed insert-bulk-qh ;" eval

s" : bulk-in-actual" eval  ( -- actual usberr )
s"    bulk-in-td bulk-in-qh >qh-#tds l@ get-actual" eval	( actual )
s"    usb-error" eval						( actual usberr )
s"    bulk-in-td bulk-in-qh >qh-#tds l@ fixup-bulk-in-data ;" eval

s" : bulk-in?" eval  ( -- actual usberr )
s"    bulk-in-qh 0=  if  0 USB_ERR_INV_OP exit  then" eval
s"    lock" eval
s"    clear-usb-error" eval
s"    process-hc-status" eval
s"    bulk-in-qh dup pull-qhtds" eval                            ( bulk-in-qh )
s"    qh-done?  if" eval
s"       bulk-in-actual" eval                                    ( actual usberr )
s"    else" eval
s"       bulk-in-qh dup >hcqh-elem le-l@" eval			( qh elem )
s"       1 ms  over pull-qhtds" eval				( qh elem )
s"       swap >hcqh-elem le-l@ =  if" eval			\ No movement in the past ms
s"          bulk-in-actual" eval                                 ( actual usberr )
s"          bulk-in-td bulk-in-qh >qh-#tds l@ fixup-bulk-in-data" eval
s"       else" eval						\ It may not be done yet
s"          0 usb-error" eval					( actual usberr )
s"       then" eval
s"    then" eval
s"    over  if" eval
s"       bulk-in-td dup >td-buf l@ swap >td-pbuf l@ 2 pick dma-pull" eval
s"    then" eval
s"    unlock ;" eval

s" : restart-bulk-in-td" eval  ( td -- )
s"    begin  ?dup  while" eval                                 ( td )
s"       toggle-bulk-in-data" eval                             ( td )
s"       dup >hctd-token" eval                                 ( td &token )
s"       dup le-l@  TD_TOKEN_DATA1 invert and" eval            ( td &token value )
s"       bulk-in-data@ or  swap le-l!" eval                    ( td )
s"       dup >hctd-stat dup le-l@" eval                        ( td &stat value )
s"       TD_STAT_ANY_ERROR TD_ACTUAL_MASK or invert and" eval  ( td &stat value' )
s"       TD_STAT_ACTIVE or swap le-l!" eval                    ( td )
s"       >td-next l@" eval                                     ( td' )
s"    repeat ;" eval

s" : restart-bulk-in" eval  ( -- )
 "    debug?  if  ."" restart-bulk-in"" cr  then" eval
s"    bulk-in-qh 0=  if  exit  then" eval

   \ Setup TD again
s"    bulk-in-td restart-bulk-in-td" eval

   \ Setup QH again
s"    bulk-in-td >td-phys l@ bulk-in-qh >hcqh-elem le-l!" eval
s"    bulk-in-qh push-qhtds ;" eval
s" : end-bulk-in" eval  ( -- )
 "    debug?  if  ."" end-bulk-in"" cr  then" eval
s"    bulk-in-qh 0=  if  exit  then" eval

s"    bulk-in-td bulk-in-qh >qh-#tds l@ fixup-bulk-in-data" eval
s"    bulk-in-td map-out-buf" eval
s"    bulk-in-qh dup  remove-qh  free-qhtds" eval
s"    0 to bulk-in-qh  0 to bulk-in-td ;" eval

s" : bulk-in" eval  ( buf len pipe -- actual usberr )
 "    debug?  if  ."" bulk-in"" cr  then" eval
s"    lock" eval
s"    dup to bulk-in-pipe" eval
s"    bulk-in-timeout process-bulk-args" eval
s"    alloc-bulk-qhtds  to my-td  to my-qh" eval

   \ IN TDs
s"   TD_PID_IN my-td fill-bulk-io-tds" eval

   \ Start bulk in transaction
s"   my-qh my-speed insert-bulk-qh" eval

   \ Process results
s"   my-qh done?  if   0" eval		( actual )	\ System error, timeout
s"   else" eval
s"      my-td error?  if 0" eval	( actual )	\ USB error
s"       else" eval
s"          my-td dup my-#tds get-actual" eval		( td actual )
s" 	 over >td-buf l@ rot >td-pbuf l@ 2 pick dma-pull" eval	( actual )
s"       then" eval
s"    then" eval

s"    usb-error" eval					( actual usberr )
s"    my-qh" eval					( actual usberr qh )
s"    my-td dup map-out-buf" eval			( actual usberr qh td )
s"    my-#tds fixup-bulk-in-data" eval			( actual usberr qh )
s"    dup  remove-qh  free-qhtds" eval			( actual usberr )
s"    unlock ;" eval

s" : bulk-out" eval  ( buf len pipe -- usberr )
 "    debug?  if  ."" bulk-out"" cr  then" eval
s"    lock" eval
s"    dup to bulk-out-pipe" eval
s"    bulk-out-timeout process-bulk-args" eval
s"    alloc-bulk-qhtds  to my-td  to my-qh" eval

   \ OUT TDs
s"   TD_PID_OUT my-td fill-bulk-io-tds" eval

   \ Start bulk out transaction
s"   my-qh my-speed insert-bulk-qh" eval

   \ Process results
s"   my-qh done? 0=  if  my-td error? drop  then" eval

s"    usb-error" eval					( actual usberr )
s"    my-qh" eval					( actual usberr qh )
s"    my-td dup map-out-buf" eval			( actual usberr qh td )
s"    my-#tds fixup-bulk-out-data" eval			( actual usberr qh )
s"    dup  remove-qh  free-qhtds" eval			( actual usberr )
s"    unlock ;" eval

s" : (end-extra)  ( -- )  end-bulk-in  ;" eval

;

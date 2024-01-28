purpose: EHCI USB Controller bulk pipes transaction processing

hex
: bulkfth
s" d# 500 instance value bulk-in-timeout" eval
s" d# 500 constant bulk-out-timeout" eval

s" 0 instance value bulk-in-pipe" eval
s" 0 instance value bulk-out-pipe" eval

s" 8 constant #bulk-qtd-max" eval		\ Preallocated qtds for bulk-qh
					\ Each qtd can transfer upto 0x5000 bytes
s" 0 instance value bulk-qh" eval		\ For bulk-in and bulk-out

s" 0 instance value bulk-in-qh" eval		\ For begin-bulk-in, bulk-in?,...
s" 0 instance value bulk-in-qtd" eval		\ For begin-bulk-in, bulk-in?,...

s" 0 instance value bulk-out-qh" eval		\ For begin-bulk-out-ring ...
s" 0 instance value bulk-out-qtd" eval		\ For begin-bulk-out-ring ...

s" 0 instance value my-bulk-qh" eval             \ Cannot use my-qh because unstall-pipe kills it
s" 0 instance value my-bulk-qtd" eval

s" : bulk-in-data@         ( -- n )  bulk-in-pipe  target di-in-data@   di-data>td-data  ;" eval
s" : bulk-out-data@        ( -- n )  bulk-out-pipe target di-out-data@  di-data>td-data  ;" eval
s" : bulk-in-data!         ( n -- )  td-data>di-data bulk-in-pipe  target di-in-data!   ;" eval
s" : bulk-out-data!        ( n -- )  td-data>di-data bulk-out-pipe target di-out-data!  ;" eval
s" : toggle-bulk-in-data   ( -- )    bulk-in-pipe  target di-in-data-toggle   ;" eval
s" : toggle-bulk-out-data  ( -- )    bulk-out-pipe target di-out-data-toggle  ;" eval

s" : qtd-fixup-bulk-in-data" eval  ( qtd -- )
s"    usb-error USB_ERR_STALL and  if" eval
s"       drop bulk-in-pipe h# 80 or unstall-pipe" eval
s"       TD_TOGGLE_DATA0" eval
s"    else" eval
s"       >hcqtd-token le-l@" eval
s"    then" eval
s"    bulk-in-data! ;" eval

s" : fixup-bulk-in-data    ( qh -- )  >hcqh-overlay qtd-fixup-bulk-in-data  ;" eval
s" : fixup-bulk-out-data" eval   ( qh -- )
s"    usb-error USB_ERR_STALL and  if" eval
s"       drop bulk-out-pipe unstall-pipe" eval
s"       TD_TOGGLE_DATA0" eval
s"    else" eval
s"       >hcqh-overlay >hcqtd-token le-l@" eval
s"    then" eval
s"    bulk-out-data! ;" eval
s" : set-bulk-vars" eval  ( pipe -- )
s"    clear-usb-error" eval      ( pipe )
s"    set-my-dev" eval           ( pipe )
s"    set-my-char ;" eval
 
s" : process-bulk-args" eval  ( buf len pipe -- )
s"    set-bulk-vars" eval	( buf len )
s"    2dup hcd-map-in  to my-buf-phys to /my-buf to my-buf ;" eval
s" : alloc-bulk-qhqtds" eval  ( -- qh qtd )
s"    my-buf-phys /my-buf cal-#qtd dup to my-#qtds" eval   ( #qtds )
s"    alloc-qhqtds ;" eval     ( qh qtd )
s" : ?alloc-bulk-qhqtds" eval  ( -- qh qtd )
s"    my-buf-phys /my-buf cal-#qtd dup to my-#qtds" eval   ( #qtds )
 "    dup #bulk-qtd-max >  if  ."" Requested bulk transfer is too big."" cr abort  then" eval  ( #qtds )

s"    bulk-qh 0=  if" eval                                 ( #qtds )
s"       #bulk-qtd-max alloc-qhqtds drop to bulk-qh" eval
s"    then" eval                                           ( #qtds )
s"    bulk-qh reuse-qhqtds ;" eval

s" : free-bulk-qh" eval  ( -- )
s"    bulk-qh ?dup  if" eval                     ( qh )
s"       free-qh" eval
s"       0 to bulk-qh" eval
s"    then ;" eval

s" : fill-bulk-io-qtds" eval  ( dir qtd -- )
s"    my-#qtds 0  do" eval				( dir qtd )
s"       my-buf my-buf-phys /my-buf 3 pick fill-qtd-bptrs" eval
						( dir qtd /bptr )
      \ Setup the token word
s"       2 pick over d# 16 << or" eval			( dir qtd /bptr token )
s"       TD_C_ERR3 or TD_STAT_ACTIVE or" eval		( dir qtd /bptr token' )
s"       3 pick TD_PID_IN =  if" eval			( dir qtd /bptr token' )
s"          bulk-in-data@  toggle-bulk-in-data" eval
s"       else" eval
s"          bulk-out-data@ toggle-bulk-out-data" eval
s"       then  or" eval					( dir qtd /bptr token' )
s"       2 pick >hcqtd-token le-l!" eval			( dir qtd /bptr )

s"       my-buf++" eval					( dir qtd )
s"       dup fixup-last-qtd" eval			( dir qtd )
s"       >qtd-next l@" eval				( dir qtd' )
s"    loop  2drop ;" eval

s" : more-qtds?" eval  ( qtd -- qtd flag )
s"    dup >hcqtd-next le-l@" eval		( qtd next )
s"    over >hcqtd-next-alt le-l@  <> ;" eval	( qtd more? )
s" : activate-in-ring" eval  ( qtd -- )
   \ Start with the second entry in the ring so the first entry
   \ is the last to be activated, thus deferring host controller
   \ activity until all qtds are active.
s"    >qtd-next l@  dup" eval				( qtd0 qtd )
s"    begin" eval					( qtd0 qtd )
s"       TD_C_ERR3 TD_PID_IN or TD_STAT_ACTIVE or" eval	( qtd0 qtd token )
s"       over >hcqtd-token le-w!" eval			( qtd0 qtd )
s"       >qtd-next l@" eval				( qtd0 qtd' )
s"    2dup = until" eval					( qtd0 qtd' )
s"    2drop ;" eval

s" : new-fill-bulk-io-qtds" eval  ( /buf qtd -- )
s"    swap to /my-buf" eval					( qtd )
s"    my-buf-phys /my-buf cal-#qtd to my-#qtds" eval		( /buf qtd )
s"    my-#qtds 0  do" eval					( qtd )
s"       >r" eval						( r: qtd )
s"       my-buf my-buf-phys /my-buf r@ fill-qtd-bptrs" eval	( /bptr r: qtd )
s"       dup r@ >hcqtd-token 2+ le-w!" eval			( /bptr r: qtd )
s"       my-buf++" eval						( r: qtd )
s"       r> >qtd-next l@" eval					( qtd' )
s"   loop  drop ;" eval

\ Attach the qtd transaction chain beginning at "qtd" to "successor-qtd".
s" : attach-qtds" eval  ( successor-qtd qtd -- )
s"    begin" eval				( succ qtd )
      \ Test before setting "next-alt"
s"       more-qtds? >r" eval			( succ qtd r: flag )

      \ Point each next-alt field to the successor
s"       over >qtd-phys l@" eval			( succ qtd succ-phys )
s"       over >hcqtd-next-alt le-l!" eval	( succ qtd r: flag )
s"    r>  while" eval				( succ qtd )
s"       >qtd-next l@" eval			( succ qtd' )
s"   repeat" eval				( succ last-qtd )

   \ Only the final qtd's next field points to the successor
s"   over >qtd-phys l@  over  >hcqtd-next le-l!" eval	( succ last-qtd )
s"   >qtd-next l! ;" eval

s" : alloc-ring-qhqtds" eval  ( buf-pa /buf #bufs -- qh qtd )
s"    0 swap  0 ?do" eval		( pa /buf #qtds )
s"       >r 2dup cal-#qtd >r" eval 	( pa /buf r: #qtds this-#qtds )
s"       tuck + swap" eval		( pa' /buf r: #qtds this-#qtds )
s"       r> r> +" eval			( pa' /buf #qtds' )
s"    loop" eval				( pa' /buf #qtds' )
s"    nip nip  alloc-qhqtds ;" eval	( qh qtd0 )


s" : unmap&free" eval  ( va pa len -- )
s"    >r" eval			( va pa r: len )
s"    over swap" eval		( va va pa r: len )
s"    r@ hcd-map-out" eval	( va r: len )
s"    r> dma-free ;" eval
s" : alloc&map" eval  ( len -- va pa )
s"    dup dma-alloc" eval	( totlen va )
s"    dup rot hcd-map-in ;" eval 	( va pa )
\ It would be better to put these fields in the qh extension
\ so we don't need separate ones for in and out.

s" : free-ring" eval  ( qh -- )
s"    >r  r@ >qh-buf l@  r@ >qh-buf-pa l@" eval
s"    r@ >qh-#bufs l@  r> >qh-/buf l@ *" eval
s"    unmap&free ;" eval

s" : set-bulk-in-timeout  ( ms -- )   to bulk-in-timeout  ;" eval

s" : alloc-ring-bufs" eval  ( /buf #bufs qh -- )
s"    >r" eval
s"    2dup  r@ >qh-#bufs l!  r@ >qh-/buf l!" eval	( /buf #bufs )
s"    * alloc&map  r@ >qh-buf-pa l!  r> >qh-buf l! ;" eval

s" : link-ring" eval  ( qh qtd -- )
s"    swap >r" eval				( qtd r: qh )
s"    r@ >qh-buf-pa l@ to my-buf-phys" eval      ( qtd r: qh )
s"    r@ >qh-buf    l@ to my-buf" eval		( qtd r: qh )
s"    r@ >qh-/buf   l@ swap" eval		( /buf qtd r: qh )
s"    r> >qh-#bufs  l@" eval			( /buf qtd #bufs )
s"    over >r" eval				( /buf qtd #bufs r: qtd0 )
s"    1-  0  ?do" eval				( /buf qtd )
s"       2dup new-fill-bulk-io-qtds" eval	( /buf qtd )
s"       dup  my-#qtds /qtd * +" eval		( /buf qtd next-qtd )
s"       dup rot attach-qtds" eval		( /buf next-qtd )
s"    loop" eval				( /buf qtd r: qtd0 )
s"    tuck new-fill-bulk-io-qtds" eval		( qtd  r: qtd0 )
s"    r> swap attach-qtds ;" eval
s" : make-ring" eval  ( /buf #bufs in? -- qh qtd )
s"    -rot" eval                                ( in? /buf #bufs )
s"    2dup * alloc&map" eval				( in? /buf #bufs va pa )
s"    dup  4 pick 4 pick  alloc-ring-qhqtds" eval	( in? /buf #bufs va pa qh qtd )
s"    >r >r" eval					( in? /buf #bufs va pa r: qtd qh )
s"    r@ >qh-buf-pa l!  r@ >qh-buf  l!" eval		( in? /buf #bufs )
s"    r@ >qh-#bufs  l!  r@ >qh-/buf l!" eval		( in? r: qtd qh )
s"    r@ pt-bulk fill-qh" eval				( in? r: qtd qh )
   \ Let the QH keep track of the data toggle on an ongoing basis ...
s"   r@ >hcqh-endp-char dup le-l@ QH_TD_TOGGLE invert and swap le-l!" eval

   \ But we have to initialize it here based on the last state
s"    r@ >hcqh-overlay >hcqtd-token" eval                ( in? token-adr r: qtd qh )
s"    dup le-l@" eval                                    ( in? token-adr token-val r: qtd qh )
s"    rot  if  bulk-in-data@  else  bulk-out-data@  then" eval   ( token-adr token-val toggle r: qtd qh )
s"    or" eval                                           ( token-adr token-val' r: qtd qh )
s"    TD_IOC or" eval                                    ( token-adr token-val' r: qtd qh )
s"    swap le-l!" eval                                   ( r: qtd qh )

s"    r> r>" eval					( qh qtd )
s"    2dup link-ring" eval				( qh qtd )
s"    over insert-qh ;" eval				( qh qtd )
\ Find the last qtd in a chain of qtds for the same transaction.
s" : transaction-last-qtd" eval  ( qtd -- qtd' )
s"    begin  more-qtds?  while  >qtd-next l@  repeat ;" eval	( qtd' )


s" : qtd-successor  ( qtd -- qtd' )  transaction-last-qtd >qtd-next l@  ;" eval

\ Insert the qtd transaction chain "new-qtd" in the circular list
\ after "qtd".  This is safe only if qtd is inactive.
s" : qtd-insert-after" eval  ( new-qtd qtd -- )
   \ First make qtd's successor new-qtd's successor
s"    2dup qtd-successor swap attach-qtds" eval	( new-qtd qtd )
   \ Then make new-qtd qtd's successor
s"    attach-qtds ;" eval

s" 0 value bulk-out-pending" eval
s" : activate-out" eval  ( qtd len -- )
s"    over to bulk-out-pending" eval	( qtd len )
s"    over >hcqtd-token" eval		( qtd len token-adr )
s"    tuck 2+ le-w!" eval		( qtd token-adr )
s"    TD_C_ERR3  TD_PID_OUT or  TD_STAT_PING or  TD_STAT_ACTIVE or   swap le-w!" eval  ( qtd )
s"   push-qtd ;" eval

s" : wait-out" eval  ( qtd -- error? )
s"    begin  dup qtd-done?  until" eval	( qtd )
s"    >hcqtd-token c@ h# fc and ;" eval

\ Possible enhancement: pass in a size argument so that a chain of qtds can be
\ allocated, with more total buffer space than can be represented by one qtd.
\ That can get complicated though - if the chain wraps around the ring, the
\ buffer space would be discontiguous.

s" : get-out-buffer" eval  ( -- qtd buf )
s"    bulk-out-qtd begin  dup qtd-done?  until" eval	( qtd )
s"    dup >qtd-next l@ to bulk-out-qtd" eval		( qtd )
s"   dup >qtd-buf	l@ ;" eval				( qtd buf )


s" : send-out" eval  ( adr len -- qtd )
s"    >r  get-out-buffer" eval				( adr qtd buf r: len )
s"    rot swap r@ move" eval				( qtd r: len )
s"    dup r> activate-out ;" eval

s" : begin-out-ring" eval  ( /buf #bufs pipe -- )
 "    debug?  if  ."" begin-out-ring"" cr  then" eval
s"   bulk-out-qh  if  3drop exit  then" eval		\ Already started

s"    dup to bulk-out-pipe" eval				( /buf #bufs pipe )
s"    set-bulk-vars" eval				( /buf #bufs )

s"    false make-ring" eval				( qh qtd )
s"    to bulk-out-qtd  to bulk-out-qh" eval
s"    bulk-out-timeout bulk-out-qh >qh-timeout l! ;" eval

s" : begin-in-ring" eval  ( /buf #bufs pipe -- )
 "    debug?  if  ."" begin-bulk-in-ring"" cr  then" eval
s"    bulk-in-qh  if  3drop exit  then" eval		\ Already started

s"    dup to bulk-in-pipe" eval				( /buf #bufs pipe )
s"    set-bulk-vars" eval				( /buf #bufs )

s"    true make-ring" eval				( qh qtd )
s"    dup activate-in-ring" eval				( qh qtd )
s"    to bulk-in-qtd  to bulk-in-qh" eval
s"    bulk-in-timeout bulk-in-qh >qh-timeout l!	;" eval

s" : bulk-in-ready?" eval  ( -- false | error true |  buf actual 0 true )
s"    clear-usb-error" eval
s"    bulk-in-qtd >r" eval
s"    r@ pull-qtd" eval
s"    r@ qtd-done?  if" eval
s"       r@  bulk-in-qh qtd-error? ?dup  0=  if" eval
s"          r@ >qtd-buf l@" eval				( buf actual )
s"          r@ qtd-get-actual" eval			( buf actual )
s"          2dup  r@ >qtd-pbuf l@  swap  dma-pull" eval	( buf actual )
s"          0" eval					( buf actual 0 )
s"       then" eval					( error | buf actual 0 )
s"       true" eval					( ... )
      \ Possibly unnecessary 
s"      r@ qtd-fixup-bulk-in-data" eval			( ... )

\ XXX Ethernet does not like process-hc-status!
\      process-hc-status
s"    else" eval
s"       false" eval				        ( false )
s"    then" eval						( ... )
s"    r> drop ;" eval

s" : recycle-one-qtd" eval  ( qtd -- )
   \ Clear "Current Offset" field in first buffer pointer
s"    dup >qtd-pbuf l@  over >hcqtd-bptr0 le-l!" eval  ( qtd )

   \ Reset the "token" word which contains various transfer control bits
s"    dup >qtd-/buf l@ d# 16 <<" eval                  ( qtd token_word )
s"    TD_STAT_ACTIVE or TD_C_ERR3 or TD_PID_IN or" eval     ( qtd token_word' )

   \ Not doing data toggles here!

s"    swap >hcqtd-token le-l! ;" eval

s" : recycle-bulk-in-qtd" eval  ( qtd -- )
s"    dup" eval
s"    begin  more-qtds?  while" eval	( qtd0 qtd )
s"       >qtd-next l@" eval		( qtd0 qtd' )
s"       dup recycle-one-qtd" eval	( qtd0 qtd )
s"    repeat" eval			( qtd0 qtd )

   \ Recycle the first qtd last so the transaction is atomic WRT the HC
s"    drop dup recycle-one-qtd" eval	( qtd0 )
s"    push-qtds ;" eval

\ Fixup the host-controller-writable fields in the chain of qTDs -
\ current offset, bytes_to_transfer, and status
s" : restart-bulk-in-qtd" eval  ( qtd -- )
s"    begin" eval					   ( qtd )
      \ Clear "Current Offset" field in first buffer pointer
s"       dup >hcqtd-bptr0 dup le-l@ h# fffff000 and swap le-l!" eval  ( qtd )

      \ Reset the "token" word which contains various transfer control bits
s"       dup >qtd-/buf l@ d# 16 <<" eval                    ( qtd token_word )
s"       TD_STAT_ACTIVE or TD_C_ERR3 or TD_PID_IN or" eval  ( qtd token_word' )

      \ We need not adjust the data toggle here, as the controller handles
      \ it automatically while the queue is active.  We set it initially
      \ when creating the the queue head, and save it for later after
      \ detaching the queue head.

s"       over >hcqtd-token le-l!" eval                      ( qtd )
s"    more-qtds?   while" eval				   ( qtd )
s"       >qtd-next l@" eval                              ( qtd' )
s"    repeat" eval					   ( qtd )
s"   drop ;" eval

\ Wait for the hardware next pointer to catch up with the software pointer.
s" : drain-bulk-out" eval  ( -- )
 "    debug?  if  ."" drain-bulk-out"" cr  then" eval
s"    bulk-out-qtd >qtd-phys l@" eval	( qtd-pa )
s"    bulk-out-qh >hcqh-overlay >hcqtd-next" eval	( qtd-pa 'qh-next )
s"    begin  2dup le-l@ =  until" eval   ( qtd-pa 'qh-next )
s"    2drop ;" eval

s" : end-out-ring" eval  ( -- )
 "    debug?  if  ."" end-out-ring"" cr  then" eval
s"    bulk-out-qh 0=  if  exit  then" eval
s"    drain-bulk-out" eval

s"    bulk-out-qh remove-qh" eval
s"    bulk-out-qh free-ring" eval
s"    bulk-out-qh free-qh" eval
s"    0 to bulk-out-qh  0 to bulk-out-qtd ;" eval

s" : end-bulk-in" eval  ( -- )
 "    debug?  if  ."" end-bulk-in"" cr  then" eval
s"    bulk-in-qh 0=  if  exit  then" eval
s"    bulk-in-qh remove-qh" eval
s"    bulk-in-qh fixup-bulk-in-data" eval
s"    bulk-in-qh free-ring" eval
s"    bulk-in-qh free-qh" eval
s"    0 to bulk-in-qh  0 to bulk-in-qtd ;" eval
s" 0 instance value app-buf" eval
s" : begin-bulk-in" eval  ( buf len pipe -- )
s"    rot to app-buf" eval
s"    h# 20 swap begin-in-ring ;" eval

s" : bulk-in?" eval  ( -- actual usberr )
s"    lock" eval
s"    bulk-in-ready?  if" eval		( usberr | buf actual 0 )
s"       ?dup  if" eval			( usberr )
s"          0 swap" eval			( actual usberr )
s"       else" eval			( buf actual )
s"          tuck" eval			( actual buf actual )
s"          app-buf swap move" eval	( actual )
s"          0" eval			( actual usberr )
s"       then" eval                      ( actual usberr )
s"    else" eval
s"       0 0" eval			( actual usberr )
s"    then" eval
s"    unlock ;" eval

s" : restart-bulk-in" eval  ( -- )
 "    debug?  if  ."" recycle buffer"" cr  then" eval
s"    bulk-in-qh 0=  if  exit  then" eval

   \ Setup qTD again
s"    bulk-in-qtd recycle-bulk-in-qtd" eval
s"    bulk-in-qtd qtd-successor to bulk-in-qtd ;" eval
s" : bulk-read?" eval  ( -- [ buf ] actual )
s"    bulk-in?  if  restart-bulk-in  -1 exit  then" eval    ( actual )
s"    dup 0=  if  drop -2 exit  then" eval                  ( actual )
s"    bulk-in-qtd >qtd-buf l@ swap ;" eval                  ( buf actual )


s" : recycle-buffer restart-bulk-in ;" eval

s" : start-bulk-transaction" eval  ( pid -- )
s"    my-bulk-qtd fill-bulk-io-qtds" eval
s"    my-bulk-qh pt-bulk fill-qh" eval
s"    my-bulk-qh interrupt-on-last-td" eval
s"    my-bulk-qh insert-qh ;" eval
s" : bulk-in" eval  ( buf len pipe -- actual usberr )
 "    debug?  if  ."" bulk-in"" cr  then" eval
s"    lock" eval
s"    dup to bulk-in-pipe" eval
s"    process-bulk-args" eval
s"    ?alloc-bulk-qhqtds  to my-bulk-qtd  to  my-bulk-qh" eval
s"    bulk-in-timeout my-bulk-qh >qh-timeout l!" eval

   \ IN qTDs
s"    TD_PID_IN start-bulk-transaction" eval

   \ Process results
s"    my-bulk-qh done-error?  if" eval			( )		\ System error, timeout, or USB error
s"       0" eval						( actual )	
s"    else" eval						( )
s"       my-bulk-qtd dup my-#qtds get-actual" eval	( qtd actual )
s"       over >qtd-buf l@ rot >qtd-pbuf l@ 2 pick dma-pull" eval	( actual )
s"    then" eval						( actual )

s"    usb-error" eval					( actual usberr )
s"    my-bulk-qtd map-out-bptrs" eval			( actual usberr )
s"    my-bulk-qh dup fixup-bulk-in-data" eval		( actual usberr qh )
s"    remove-qh" eval					( actual usberr )
s"    unlock ;" eval

s" 0 instance value bulk-out-busy?" eval
s" : done-bulk-out" eval  ( -- error? )
s"    lock" eval
    \ Process results
s"    my-bulk-qh done-error?" eval		( usberr )
s"    my-bulk-qtd map-out-bptrs" eval		( usberr )
s"    my-bulk-qh fixup-bulk-out-data" eval	( usberr )
s"    my-bulk-qh remove-qh" eval			( usberr )
s"    false to bulk-out-busy?" eval		( usberr )
s"    unlock ;" eval

s" : start-bulk-out" eval  ( buf len pipe -- usberr )
s"    bulk-out-busy?  if" eval			( buf len pipe )
s"       done-bulk-out  ?dup  if   nip nip nip exit  then" eval
s"    then" eval					( buf len pipe )

 "    debug?  if  ."" bulk-out"" cr  then" eval
s"    lock" eval
s"    dup to bulk-out-pipe" eval			( buf len pipe )
s"    process-bulk-args" eval
s"    ?alloc-bulk-qhqtds  to my-bulk-qtd  to my-bulk-qh" eval
s"    bulk-out-timeout my-bulk-qh >qh-timeout l!" eval
s"    my-bulk-qh >hcqh-overlay >hcqtd-token dup le-l@ TD_STAT_PING or swap le-l!" eval

   \ OUT qTDs
s"    TD_PID_OUT start-bulk-transaction" eval
s"    true to bulk-out-busy?" eval
s"    0" eval					( usberr )
s"    unlock ;" eval

s" : bulk-out" eval  ( buf len pipe -- usberr )
s"    start-bulk-out drop done-bulk-out ;" eval

s" : (end-extra)  ( -- )  end-bulk-in free-bulk-qh  ;" eval
;

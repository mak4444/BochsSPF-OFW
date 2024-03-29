purpose: Common USB control pipe API

hex

defer (control-get-m)
defer (control-set-m)
defer (control-set-nostat-m)
defer set-my-dev
defer set-real-dev-m


: setup-buf-arg  ( -- sbuf sphy slen )  setup-buf setup-buf-phys /dr  ;
: cfg-buf-arg    ( -- cbuf cphy )       cfg-buf cfg-buf-phys  ;

: fill-setup-buf  ( len idx value rtype req -- )
   setup-buf dup /dr  erase			( len idx value rtype req vpcbp )
   tuck >dr-request c!				( len idx value rtype vpcbp )
   tuck >dr-rtype c!				( len idx value vpcbp )
   tuck >dr-value le-w!				( len idx vpcbp )
   tuck >dr-index le-w!				( len vpcbp )
   >dr-len le-w!				( )
   setup-buf setup-buf-phys /dr dma-push	( )
;

external
: control-get  ( adr len idx value rtype req -- actual usberr )
   4 pick >r					( adr len idx value rtype req )  ( R: len )
   fill-setup-buf				( adr )  ( R: len )
   setup-buf-arg cfg-buf-arg r@  (control-get-m)	( adr actual usberr )  ( R: len )
   dup  if
      r> drop nip nip 0 swap			( actual usberr )
   else
      -rot r> min tuck cfg-buf -rot move swap	( actual usberr )
   then
;

: control-set  ( adr len idx value rtype req -- usberr )
   5 pick ?dup  if  cfg-buf 6 pick move	 then	( adr len idx value rtype req )
   4 pick >r					( adr )  ( R: len )
   fill-setup-buf drop				( )  ( R: len )
   setup-buf-arg cfg-buf-arg r>  (control-set-m) 	( usberr )
;

: control-set-nostat  ( adr len idx value rtype req -- usberr )
   5 pick ?dup  if  cfg-buf 6 pick move	 then	( adr len idx value rtype req )
   4 pick >r					( adr )  ( R: len )
   fill-setup-buf drop				( )  ( R: len )
   setup-buf-arg cfg-buf-arg r>  (control-set-nostat-m)	( usberr )
;

headers

: set-address  ( dev -- usberr )
   " usb-delay" ['] eval catch  if  2drop  else  ms  then

   \ To get the right characteristics for dev in control-set, then normal
   \ set-my-dev is nooped.  We set my-dev and my-real-dev here instead.
   ['] set-my-dev behavior swap			( xt dev )	\ Save set-my-dev
   ['] noop to set-my-dev			( xt dev )	\ Make it noop
   dup >r					( xt dev )  ( R: dev )
   0 set-real-dev-m				( xt )  ( R: dev )

   0 0 0 r@ DR_OUT DR_DEVICE or SET_ADDRESS control-set  if
      ." Failed to set device address: " r> u. cr
   else
      r> drop
      d# 10 ms        				\ Let the SET_ADDRESS settle
   then						( xt )

   to set-my-dev				\ Restore set-my-dev
   usb-error
;

external

: get-desc  ( adr len lang didx dtype rtype -- actual usberr )
   -rot bwjoin swap DR_IN or GET_DESCRIPTOR control-get
;

: get-status  ( adr len intf/endp rtype -- actual usberr )
   0 swap DR_IN or GET_STATUS control-get
;

: set-config-m  ( cfg -- usberr )
   >r 0 0 0 r> DR_DEVICE DR_OUT or SET_CONFIGURATION control-set 
;


: set-interface  ( intf alt -- usberr )
   0 0 2swap DR_INTERFACE DR_OUT or SET_INTERFACE control-set
;

: clear-feature  ( intf/endp feature rtype -- usberr )
   >r 0 0 2swap r> DR_OUT or CLEAR_FEATURE control-set
;
: set-feature  ( intf/endp feature rtype -- usberr )
   >r 0 0 2swap r> DR_OUT or SET_FEATURE control-set
;

headers


: (unstall-pipe)  ( pipe -- )  0 DR_ENDPOINT clear-feature drop  ;

external
: get-cfg-desc  ( adr idx -- actual )
   swap >r					( idx )  ( R: adr )
   r@ 9 0 3 pick CONFIGURATION DR_DEVICE get-desc nip 0=  if
      r> dup 2 + le-w@ rot 0 swap CONFIGURATION DR_DEVICE get-desc drop	( actual )
   else
      r> 2drop 0				( actual )
   then
;
headers

: get-dev-desc  ( adr len -- actual )
   0 0 DEVICE DR_DEVICE get-desc drop		( actual )
;
: (get-str-desc)  ( adr len lang idx -- actual )
   STRING DR_DEVICE get-desc drop		( actual )
;
: get-str-desc  ( adr lang idx -- actual )
   3dup 2 -rot (get-str-desc) 0=  if  3drop 0 exit  then	\ Read the length
   >r 2dup r>					( adr lang adr lang idx )
   2 pick c@ -rot  (get-str-desc) 0=  if  2drop 0 exit  then	\ Then read the whole string
   						( adr lang )
   encoded$>ascii$				( )
;

headers
: controlfth

\ s" ' (unstall-pipe) to unstall-pipe" eval

s" alias set-config set-config-m" eval

\ Must be called after set-config for any device with bulk-in or
\ bulk-out pipes.  Pass in 0 if one of the pipes is nonexistent.
s" : reset-bulk-toggles" eval  ( bulk-in-pipe bulk-out-pipe -- )
s"    ?dup   if  0 swap  target  di-out-data!  then" eval
s"    ?dup   if  0 swap  target  di-in-data!   then ;" eval

s" : set-pipe-maxpayload" eval  ( size pipe -- )
s"    target di-maxpayload! ;" eval

\ Returns true the first time it is called for a given target device
\ after a reset of the USB subsystem.  Used for reinitializing hardware.

s" : reset?  ( -- flag )  target di-reset?  ;" eval


s" ' (control-get) is (control-get-m)" eval
s" ' (control-set) is (control-set-m)" eval
s" ' (control-set-nostat) is (control-set-nostat-m)" eval
s" ' set-real-dev is set-real-dev-m" eval
;

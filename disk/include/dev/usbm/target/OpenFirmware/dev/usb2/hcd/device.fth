
hex
headers

defer make-dev-property-hook  ( speed dev port -- )
' 3drop to make-dev-property-hook

\ Buffers for descriptor manipulation
0 value cfg-desc-buf			\ Configuration Descriptor
0 value dev-desc-buf			\ Device Descriptor
0 value d$-desc-buf			\ Device String Descriptor
0 value v$-desc-buf			\ Vendor String Descriptor
0 value s$-desc-buf			\ Serial Number String Descriptor

0 value /cfg-desc-buf			\ Length of data in cfg-desc-buf
0 value /dev-desc-buf			\ Length of data in dev-desc-buf
0 value /d$-desc-buf			\ Length of data in d$-desc-buf
0 value /v$-desc-buf			\ Length of data in v$-desc-buf
0 value /s$-desc-buf			\ Length of data in s$-desc-buf

: alloc-pkt-buf  ( -- )
   cfg-desc-buf 0=  if
      /cfg alloc-mem dup to cfg-desc-buf /cfg erase
      /cfg alloc-mem dup to dev-desc-buf /cfg erase
      /str alloc-mem dup to d$-desc-buf /str erase
      /str alloc-mem dup to v$-desc-buf /str erase
      /str alloc-mem dup to s$-desc-buf /str erase
   then
;
: free-pkt-buf  ( -- )
   cfg-desc-buf ?dup  if  /cfg free-mem  0 to cfg-desc-buf  then
   dev-desc-buf ?dup  if  /cfg free-mem  0 to dev-desc-buf  then
   d$-desc-buf  ?dup  if  /str free-mem  0 to d$-desc-buf   then
   v$-desc-buf  ?dup  if  /str free-mem  0 to v$-desc-buf   then
   s$-desc-buf  ?dup  if  /str free-mem  0 to s$-desc-buf   then
;

: dev-desc@  ( index -- byte )  dev-desc-buf + c@  ;
: asso-class?  ( -- asso? )
   4 dev-desc@ h# ef =  5 dev-desc@ 2 =  and  6 dev-desc@ 1 =  and
;
: get-class  ( -- class subclass protocol )
   asso-class?  if
      \ Class is in interface association descriptor
      true to class-in-dev?
      cfg-desc-buf INTERFACE_ASSO find-desc	( intf-adr )
      >r  r@ 4 + c@  r@ 5 + c@   r> 6 + c@	( class subclass protocol )
   else
   4 dev-desc@ ?dup  if			        ( class )
      \ Class is in device descriptor
      true to class-in-dev?			( class )
      5 dev-desc@  6 dev-desc@			( class subclass protocol )
   else
      \ Class is in interface descriptor
      false to class-in-dev?
      cfg-desc-buf my-address find-intf-desc	( intf-adr )
      >r  r@ 5 + c@  r@ 6 + c@   r> 7 + c@	( class subclass protocol )
   then  then
;

: make-class-properties  ( -- )
   get-class  ( class subclass protocol )
   " protocol" int-property
   " subclass" int-property
   " class"    int-property
;

: make-name-property  ( -- )
   get-class-properties				( class subclass protocol )
   swap rot					( protocol subclass class )
   case
      1  of  2drop " audio"  endof		( name$ )
      2  of  2drop " network"  endof		( name$ )
      3  of  case
             1  of  case
                      1  of  " keyboard"  endof
                      2  of  " mouse"  endof
		      4  of  " joystick"  endof
		      5  of  " gamepad"  endof
		      39 of  " hatswitch"  endof
                      ( default )  " device" rot
                    endcase
                    endof
             ( default ) nip " hid" rot
             endcase
             endof
      7  of  2drop " printer"  endof		( name$ )
      8  of  case
             1  of  drop " flash"  endof
             2  of  drop " cdrom"  endof
             3  of  drop " tape"  endof
             4  of  drop " floppy"  endof
             5  of  drop " scsi"  endof		\ removable
             6  of  drop " scsi"  endof
             ( default ) nip " storage" rot
             endcase
             endof
      9  of  2drop " hub"  endof		( name$ )
      ( default )  nip nip " device" rot	( name$ )
   endcase
   device-name
;

: get-vid  ( adr -- vendor product rev )
   dev-desc-buf 8 + le-w@   dev-desc-buf d# 10 + le-w@  dev-desc-buf c + le-w@
;

: make-vendor-properties  ( -- )
   get-vid			( vendor product rev )
   " release"   int-property
   " device-id" int-property
   " vendor-id" int-property
;

\ A little tool so "make-compatible-property" reads better
0 value sadr
0 value slen
: +$  ( add$ -- )
   sadr slen 2swap encode-string encode+  to slen  to sadr
;
: usb,class#>     ( n -- )  " usb,class" $hold  0 u#> ;     \ Prepends: usb,class
: #usb,class#>    ( n -- )  u#s drop  usb,class#>  ;        \ Prepends: usb,classN
: usbif#>         ( n -- )  " usbif" $hold  0 u#> ;         \ Prepends: usbif
: #usbif#>        ( n -- )  u#s drop  usbif#>  ;            \ Prepends: usbifN
: usbif,class#>   ( n -- )  " usbif,class" $hold  0 u#> ;   \ Prepends: usbif,class
: #usbif,class#>  ( n -- )  u#s drop  usbif,class#>  ;      \ Prepends: usbif,classN
: #class,         ( n -- )  u#s drop " ,class" $hold  ;     \ Prepends: class,N

: make-compatible-property  ( -- )
   0 0 encode-bytes  to slen  to sadr		\ Initial empty string

   push-hex

   get-vendor-properties			( vendor product rev )
   3dup      <# #. #, #usb#>  +$		( v p r )	\ usbV,product.rev
   drop 2dup <#    #, #usb#>  +$		( v p )		\ usbV,product
   drop						( vendor )

   get-class-properties				( vendor class subclass protocol )
   2 pick 0<>  if       			( vendor class subclass protocol )
      class-in-dev?  if
         4dup          <# #. #. #class, #usb#>         +$  ( v c s p )  \ usbV,classC.S.P
         4dup  drop    <#    #. #class, #usb#>         +$  ( v c s p )  \ usbV,classC,S
         4dup 2drop    <#       #class, #usb#>         +$  ( v c s p )  \ usbV,classC
         3dup          <# #. #.         #usb,class#>   +$  ( v c s p )  \ usb,classC.S.P
         2 pick 2 pick <# #.            #usb,class#>   +$  ( v c s p )  \ usb,classC,S
         2 pick        <#               #usb,class#>   +$  ( v c s p )  \ usb,classC
      else
         4dup          <# #. #. #class, #usbif#>       +$  ( v c s p )  \ usbifV,classC.S.P
         4dup  drop    <#    #. #class, #usbif#>       +$  ( v c s p )  \ usbifV,classC,S
         4dup 2drop    <#       #class, #usbif#>       +$  ( v c s p )  \ usbifV,classC
         3dup          <# #. #.         #usbif,class#> +$  ( v c s p )  \ usbif,classC.S.P
         2 pick 2 pick <# #.            #usbif,class#> +$  ( v c s p )  \ usbif,classC,S
         2 pick        <#               #usbif,class#> +$  ( v c s p )  \ usbif,classC
      then
   then						( vendor class subclass protocol )
   4drop					( )
   " usb,device"  +$
   sadr slen  " compatible"  property
   pop-base
;

: make-string-properties  ( -- )
   v$-desc-buf /v$-desc-buf " vendor$" str-property
   d$-desc-buf /d$-desc-buf " device$" str-property
   s$-desc-buf /s$-desc-buf " serial$" str-property
;

: make-misc-properties  ( -- )
   cfg-desc-buf 5 + c@ " configuration#" int-property
;

: register-pipe  ( pipe size -- )
   swap h# 0f and 				( size pipe' )
   " assigned-address" get-my-property  0=  if
      decode-int nip nip di-maxpayload!		( )
   else
      2drop
   then
;

: make-ctrl-pipe-property  ( pipe size interval -- )
   drop					( pipe size )
   over h# f and rot h# 80 and  if	( size pipe )
      " control-in-pipe"  int-property
      " control-in-size"
   else
      " control-out-pipe" int-property
      " control-out-size"
   then  int-property
;
: make-iso-pipe-property  ( pipe size interval -- )
   drop					( pipe size )
   over h# 0f and rot h# 80 and  if	( size pipe )
      " iso-in-pipe"  int-property
      " iso-in-size"
   else
      " iso-out-pipe" int-property
      " iso-out-size"
   then  int-property
;
: make-bulk-pipe-property  ( pipe size interval -- )
   drop 				( pipe size )
   over h# f and rot h# 80 and  if	( size pipe )
      " bulk-in-pipe"  int-property
      " bulk-in-size"
   else
      " bulk-out-pipe" int-property
      " bulk-out-size" 
   then  int-property
;
: make-intr-pipe-property  ( pipe size interval -- )
   rot dup h# f and swap h# 80 and  if	( size interval pipe )
      " intr-in-pipe"      int-property
      " intr-in-interval"  int-property
      " intr-in-size"
   else
      " intr-out-pipe"     int-property
      " intr-out-interval" int-property
      " intr-out-size"
   then  int-property
;

: make-pipe-properties  ( adr -- )
   dup c@ over + swap 4 + c@ 		( adr' #endpoints )
   swap ENDPOINT find-desc swap 0  ?do	( adr' )
      dup 2 + c@			( adr pipe )
      over 4 + le-w@			( adr pipe size )
      2dup register-pipe		( adr pipe size )
      2 pick 6 + c@			( adr pipe size interval )
      3 pick 3 + c@ 3 and  case		( adr pipe size interval type )
         0  of  make-ctrl-pipe-property  endof
         1  of  make-iso-pipe-property   endof
         2  of  make-bulk-pipe-property  endof
         3  of  make-intr-pipe-property  endof
      endcase
      dup c@ +				( adr' )
   loop  drop
;

: make-descriptor-properties  ( -- )
   make-class-properties		\ Must make class properties first
   make-name-property
   make-vendor-properties
   make-compatible-property		\ Must come after vendor and class
   make-string-properties
   cfg-desc-buf my-address find-intf-desc make-pipe-properties
   make-misc-properties
;

: make-common-properties  ( dev -- )
   1 " #address-cells" int-property
   0 " #size-cells"    int-property
   my-address my-space encode-phys " reg" property	\ my-address=intf, my-space=port
   dup " assigned-address" int-property
   ( dev ) di-speed@  case
      speed-low  of  " low-speed"   endof
      speed-full of  " full-speed"  endof
      ( default )  " high-speed" rot
   endcase
   0 0 2swap str-property
;

\ Sets the di-maxpayload fields in the dev-info endpoint descriptor array
: reregister-pipes  ( dev intf -- )
   cfg-desc-buf swap find-intf-desc	( dev adr )
   dup c@  over +  swap 4 + c@ 		( dev adr' #endpoints )
   swap  ENDPOINT find-desc		( dev #endpoints adr' )
   swap 0  ?do				( dev adr' )
      over di-is-reset                  ( dev adr )
      dup 4 + le-w@			( dev adr size )
      over 2 + c@  h# f and		( dev adr size pipe )
      3 pick di-maxpayload!		( dev adr )
      dup c@ +				( dev adr' )
   loop  2drop				( )
;

: be-l!  ( n adr -- )
   >r lbsplit r@ c!  r@ 1+ c!  r@ 2+ c!  r> 3 + c!
;

: probe-hub-node  ( phandle -- )
   >r                                       ( r: phandle )
   " probe-hub" r@ find-method  if          ( xt r: phandle )
      r@ push-package                       ( xt r: phandle )
      " " new-instance                      ( xt r: phandle )
      set-default-unit                      ( xt r: phandle )
      execute                               ( r: phandle )
      destroy-instance                      ( r: phandle )
      pop-package                           ( r: phandle )
   then                                     ( r: phandle )
   r> drop
;
: reuse-node  ( dev intf port phandle -- )
   >r drop			  ( dev intf r: phandle )

   2dup reregister-pipes	  ( dev intf r: phandle )
   drop                           ( dev      r: phandle )

   \ Change the assigned-address property without leaking memory
   " assigned-address" r@ get-package-property  if  ( dev r: phandle )
      drop                                  ( r: phandle )
   else                                     ( dev adr len r: phandle )
      drop be-l!                            ( r: phandle )
   then                                     ( r: phandle )

   r> probe-hub-node
;
: id-match?  ( dev intf port phandle -- dev intf port phandle flag? )
   " vendor-id" 2 pick get-package-property  if  false exit  then
   decode-int nip nip   >r     ( dev intf port phandle r: vid )
   " device-id" 2 pick get-package-property  if  r> drop  false exit  then
   decode-int nip nip   >r     ( dev intf port phandle r: vid did )
   " release" 2 pick get-package-property  if  r> r> 2drop  false exit  then
   decode-int nip nip   >r     ( dev intf port phandle r: vid did rev )
   get-vid                     ( dev intf port phandle  vid1 did1 rev1 r: vid did rev )
   r> = -rot  r> = -rot  r> =  and and
;

: reuse-old-node?  ( dev intf port -- reused? )
   my-self ihandle>phandle child                 ( dev intf port phandle )
   begin  ?dup  while                            ( dev intf port phandle )
      " reg" 2 pick get-package-property 0=  if  ( dev intf port phandle adr len )
         decode-int                              ( dev intf port phandle adr len' port1 )
         4 pick  =  if                           ( dev intf port phandle adr len )
            decode-int nip nip                   ( dev intf port phandle intf1 )
            3 pick  =  if                        ( dev intf port phandle )
               id-match?  if                     ( dev intf port phandle )
                  reuse-node                     ( )
                  true exit                      ( -- true )
               then                              ( dev intf port phandle )
            then                                 ( dev intf port phandle )
         else                                    ( dev intf port phandle adr len )
            2drop                                ( dev intf port phandle )
         then                                    ( dev intf port phandle )
      then                                       ( dev intf port phandle )
      peer                                       ( dev intf port phandle' )
   repeat                                        ( dev intf port )
   3drop false
;

: disable-old-nodes  ( port -- )
   my-self ihandle>phandle child                 ( port phandle )
   begin  ?dup  while                            ( port phandle )
      " reg" 2 pick get-package-property 0=  if  ( port phandle adr len )
         decode-int  nip nip                     ( port phandle port1 )
         2 pick  =  if                           ( port phandle )
            " assigned-address"                  ( port phandle propname$ )
            2 pick  get-package-property 0=  if  ( port phandle adr len )
               drop -1 swap be-l!                ( port phandle )
            then                                 ( port phandle )
         then                                    ( port phandle )
      then                                       ( port phandle )
      peer                                       ( port phandle' )
   repeat                                        ( port )
   drop                                          ( )
;
\ cr .( disable-old-nodes=) '  disable-old-nodes .h

: find-port-node  ( port -- true | phandle false)
   my-self ihandle>phandle child                 ( port phandle )
   begin  ?dup  while                            ( port phandle )
      " reg" 2 pick get-package-property 0=  if  ( port phandle adr len )
         decode-int  nip nip                     ( port phandle port1 )
         2 pick  =  if                           ( port phandle )
            \ Check if the node has been disabled
            " assigned-address"                  ( port phandle propname$ )
            2 pick  get-package-property 0=  if  ( port phandle adr len )
               decode-int  nip nip               ( port phandle assigned-address )
               -1 <>  if                         ( port phandle )
                  nip false exit
               then
            then                                 ( port phandle )
         then                                    ( port phandle )
      then                                       ( port phandle )
      peer                                       ( port phandle' )
   repeat                                        ( port )
   drop                                          ( )
   true
;

: .phandle-property  ( phandle prop-name$ -- )
   rot get-package-property 0=  if    ( adr len )
      decode-string type  2drop
   then
;
: .usb-device  ( port -- )
   find-port-node  if
      ." Can't find device node for USB port!" cr abort
   else                                      ( phandle )
      dup " device_type" .phandle-property   ( phandle )
      ." ,"
      dup " vendor$" .phandle-property       ( phandle )
      ." ,"
      dup " device$" .phandle-property       ( phandle )
      drop                                   ( )
   then
;

: (make-device-node)  ( dev port intf -- )
   swap                              ( dev intf port )
   3dup  reuse-old-node?  if         ( dev intf port )
      3drop exit
   else
      \ As a possible improvement, the old child node could be linked to
      \ a retained list for possible reuse later
\ We don't do this because it can remove nodes we just created.
\   say we create  keyboard@3,0  then we try to create  hid@3,1
\   rm-obsolete-children will delete  keyboard@3,0
\     dup rm-obsolete-children       ( dev intf port )
   then
   dup >r encode-unit-m " " 2swap  new-device set-args		( dev )  ( R: port )
   dup dup di-speed@ swap r> make-dev-property-hook		( dev )
   make-common-properties			\ Make non-descriptor based properties
   make-descriptor-properties			\ Make descriptor based properties
   load-fcode-driver				\ Find and load fcode driver
   finish-device
;

\ Get all the descriptors we need in making properties now because target is
\ questionable in the child's context.  The descriptor buffers are not instance
\ data, so they can be accessed by code that is defined in the root hub node
\ but executing in a subordinate hub node context or a child node context.

h# 409 constant language  			\ Unicode id
\ Executed in root hub node context
: get-string ( lang idx adr -- actual )
   over 0=  if  3drop  0 exit  then		\ No string index
   -rot get-str-desc
;

\ Executed in root hub node context
: get-str-descriptors  ( -- )
   language					( lang )
   dup d# 14 dev-desc@ v$-desc-buf get-string to /v$-desc-buf
   dup d# 15 dev-desc@ d$-desc-buf get-string to /d$-desc-buf
       d# 16 dev-desc@ s$-desc-buf get-string to /s$-desc-buf
;



: get-initial-dev-desc  ( dev -- )
   dev-desc-buf d# 18 erase                     ( dev )

   \ Until we know the size of the control endpoint, we must be
   \ conservative about the transfer size.
   dev-desc-buf /pipe0 get-dev-desc  if		( dev )
      7 dev-desc@                               ( dev maxtransfer )
      tuck  0 rot di-maxpayload!	        ( maxtransfer )
      d# 18 >=  if                              ( )
         dev-desc-buf d# 18 get-dev-desc drop   ( )
      then                                      ( )
   else						( dev )
      drop					( )
   then						( )
;

: devicefth

\ Executed in root hub node context
s" : refresh-desc-bufs" eval  ( dev -- )
s"    set-target" eval
s"    dev-desc-buf d# 18 get-dev-desc to /dev-desc-buf" eval		\ Refresh dev-desc-buf
s"    cfg-desc-buf     0 get-cfg-desc to /cfg-desc-buf" eval		\ Refresh cfg-desc-buf
s"    get-str-descriptors ;" eval

\ \ \ \

\ Executed in root hub node context
s" : get-initial-descriptors" eval  ( dev -- )
s"    get-initial-dev-desc" eval                         ( )
s"    cfg-desc-buf 0 get-cfg-desc to /cfg-desc-buf	;" eval

\ Executed in hub node context (root hub or subordinate hub) - creates new child nodes via (make-device-node)
s" : make-device-node" eval  ( port dev -- )
 "    dup "" get-initial-descriptors"" my-self $call-method" eval	( port dev )
s"    /cfg-desc-buf 0=  if  2drop  exit  then" eval		( port dev )
s"    asso-class?  if  1  else  cfg-desc-buf 4 + c@  then" eval  ( port dev #intf )
s"    0  ?do" eval				                ( port dev )
 "       dup "" refresh-desc-bufs"" my-self $call-method" eval	( port dev )
s"       2dup swap i (make-device-node)" eval			( port dev )
s"    loop  2drop ;" eval


\ See hcd/ehci/probehub.fth for information about hub20-dev and hub20-port

s" : get-hub20-dev" eval  ( -- hub-dev )
 "    "" hub20-dev"" get-inherited-property 0=  if" eval   ( value$ )
s"       decode-int nip nip" eval                        ( hub-dev )
s"    else" eval                                         ( )
s"       1" eval                                         ( hub-dev )
s"    then ;" eval                                        ( hub-dev )

s" : get-hub20-port" eval  ( port -- port' )
 "    "" hub20-port"" get-inherited-property 0=  if" eval  ( port value$ )
s"       rot drop" eval				        ( value$ )
s"       decode-int nip nip" eval                        ( port' )
s"    then ;" eval                                         ( port )


\ Executed in the root hub node context
s" : setup-new-node" eval  ( port speed hub-port hub-dev -- true | port dev xt false )
  \ Allocate device number
s"   next-device#  if  2drop  exit  then" eval	( port speed hub-port hub-dev dev )

s"    tuck di-hub!" eval				( port speed hub-port dev )
s"    tuck di-port!" eval			( port speed dev )
s"    tuck di-speed!" eval			( port dev )

s"    0 set-target" eval				( port dev )	\ Address it as device 0

   \ Some devices (e.g. Lexar USB-to-SD and at least one USB FLASH drive) fail
   \ on set-address unless you first read the device descriptor from address 0.
   \ On other devices, this will fail, but it won't cause problems, and the
   \ descriptor will be re-read later by make-device-node
s"    dup get-initial-dev-desc" eval             ( port dev )

\  over reset-port                	( port dev )	\ Some devices want to be reset here

s"    dup set-address  if" eval			( port dev )	\ Assign it usb addr dev
 "       ."" Retrying with a delay"" cr" eval
s"       over reset-port  d# 5000 ms" eval
s"       dup set-address  if" eval		( port dev )	\ Assign it usb addr dev
         \ Recycle device number?
s"          2drop false exit" eval		( -- false )
s"       then" eval				( port dev )
s"    then" eval					( port dev )
 
s"    dup set-target" eval			( port dev )	\ Address it as device dev
s"    ['] make-device-node	 true	;" eval	( port dev xt )


\ Begins execution in a (root or subordinate) hub node context, creates an instance record
\ for the subordinate hub node "phandle", switches to that instance context, executes
\ "reprobe-hub" in that context, destroys the instance, and returns to the original context.
s" : reprobe-hub-node" eval  ( phandle -- )
s"    >r" eval                                       ( r: phandle )
 "    "" reprobe-hub"" r@ find-method  if" eval        ( xt r: phandle )
s"       r@ push-package" eval                       ( xt r: phandle )
 "       "" "" new-instance" eval                      ( xt r: phandle )
s"       set-default-unit" eval                      ( xt r: phandle )
s"       execute" eval                               ( r: phandle )
s"       destroy-instance" eval                      ( r: phandle )
s"       pop-package" eval                           ( r: phandle )
s"    then" eval                                     ( r: phandle )
s"    r> drop ;" eval

\ Returns true if there is a child hub node associated with port
s" : port-is-hub?" eval  ( port -- false | phandle true )
s"    my-self ihandle>phandle child" eval                       ( port phandle )
s"    begin  ?dup  while" eval                                  ( port phandle )
 "       "" name"" 2 pick get-package-property 0=  if" eval       ( port phandle adr len )
 "          1-  "" hub"" $=  if" eval                             ( port phandle )
 "             "" reg"" 2 pick get-package-property 0=  if" eval  ( port phandle adr len )
s"                decode-int nip nip" eval                      ( port phandle port1 )
s"                2 pick =  if" eval                            ( port phandle )
s"                   nip true exit" eval                        ( -- phandle true )
s"                then" eval                                    ( port phandle )
s"             then" eval                                       ( port phandle )
s"          then" eval                                          ( port phandle )
s"       then" eval                                             ( port phandle )
s"       peer" eval                                             ( port phandle' )
s"    repeat" eval                                              ( port )
s"    drop false ;" eval                                         ( false )


s" : probe-setup" eval  ( -- )
    \ Set active-package so device nodes can be added and removed
s"    my-self ihandle>phandle push-package" eval

s"    alloc-pkt-buf ;" eval

s" : probe-teardown" eval  ( -- )
s"    free-pkt-buf" eval
s"    pop-package ;" eval
;
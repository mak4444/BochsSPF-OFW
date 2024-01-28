purpose: Load USB device fcode driver

hex
headers

false value probemsg?	\ Optional probing messages

\ $load-driver executes an FCode driver that is stored somewhere
\ other than on the device itself.

: $load  ( name$ -- done? )  " $load-driver" evaluate  ;

\ Words to get my (as a child) properties

: get-int-property  ( name$ -- n )
   get-my-property 0=  if  decode-int nip nip  else  0  then
;
: get-class-properties  ( -- class subclass protocol )
   " class"    get-int-property
   " subclass" get-int-property
   " protocol" get-int-property
;
: get-vendor-properties  ( -- vendor product release )
   " vendor-id" get-int-property
   " device-id" get-int-property
   " release"   get-int-property
;

\ Some little pieces for easy formatting of USB name strings

: $hold  ( adr len -- )
   dup  if  bounds swap 1-  ?do  i c@ hold  -1 +loop  else  2drop  then
;

: usb#>   ( n -- )  " usb" $hold  0 u#> ;     \ Prepends: usb
: #usb#>  ( n -- )  u#s drop  usb#>  ;        \ Prepends: usbN
: #,      ( n -- )  u#s drop ascii , hold  ;  \ Prepends: ,N
: #.      ( n -- )  u#s drop ascii . hold  ;  \ Prepends: .N

: ?#,  ( n level test-level -- )   \ Prepends: ,N  if levels match
   >=  if  #,  else  drop  then
;

: device$  ( -- adr len )
   get-vendor-properties drop  		( vendor-id device-id )
   push-hex
   <# #, #usb#>
   pop-base
;

\ Return a string of the form usb,classC[,S[,P]] depending on level
\ Level: 0 -> C   1 -> C,S   2 -> C,S,P
: class$  ( level -- name$ )  
   >r  get-class-properties  r>	      ( class subclass protocol level )
   push-hex                           ( class subclass protocol level )
   <#                                 ( class subclass protocol level )
      tuck                            ( class subclass level protocol level )
      2 ?#,                           ( class subclass level )
      1 ?#,                           ( class )
      u#s " usb,class" $hold          ( )
   u#>
   pop-base
;

: usb-storage?  ( -- flag )
   get-class-properties			( class subclass protocol )
   h# 50 =  rot  8 =  and  if		( subclass )
      dup 2 =  if			\ atapi
         drop  " " " is-atapi" str-property   true
      else
         dup 5 = swap 6 = or		\ removable, scsi
      then
   else
      drop false
   then
;


: load-fcode-driver  ( -- )

   usb-storage?    if s" d:include\dev\usbm\device\storage\storage.fth" included then
;


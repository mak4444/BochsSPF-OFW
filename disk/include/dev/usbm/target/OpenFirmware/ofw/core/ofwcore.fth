\ From standini.fth
0 value stand-init-debug?

defer ?message-code  ( adr len -- adr len )  ' noop to ?message-code
: ?type  ( adr len -- )
;

only forth also hidden also forth definitions

\needs standalone?  false value standalone?

only forth also definitions
: stand-init-io  ( -- )  true to standalone?  ;	\ First definition
headers

\ From sysintf.fth
purpose: Interfaces to low-level system functions

\ Interfaces to system-dependent routines

headers
defer diag-key     ( -- char )  \ Used by dl, dlbin, dlfcode.
defer diag-key?    ( -- flag )  \ Used by dlbin.

\ (Approximately) millisecond-granularity timing
\ Typically implemented by a driver for a counter/timer device

d# 10 value ms/tick
defer get-msecs  ( -- n )  ' 0 is get-msecs
defer ms  ( n -- )   ' drop is ms
defer us  ( n -- )   ' drop is us


\ Enabling/disabling interrupts
\ Typically implemented by a driver for an interrupt controller

defer lock[    ( -- )   ' noop is lock[
defer ]unlock  ( -- )   ' noop is ]unlock
defer enable-interrupts   ( -- )  ' noop is enable-interrupts
defer disable-interrupts  ( -- )  ' noop is disable-interrupts


\ System-wide DMA memory allocation (used only by the deblocker)
\ Typically implemented by a MMU driver

headerless
: null-allocate-dma  ( #bytes -- 0 )  drop 0  ;

headers
defer allocate-dma  ' null-allocate-dma is allocate-dma

headerless
: null-free-dma  ( virt #bytes -- )  2drop  ;

headers
defer free-dma  ' null-free-dma is free-dma

\ Storage of reboot information across system resets
\ The reboot information is typically stored in some type of memory
\ that is not cleared by a system reset.  The information does not
\ necessary have to survive across power cycles.

false value reboot?	\ Usually set in machine-dependent startup code
			\ after testing a magic flag in physical memory

: null$  ( -- adr len )  " "  ;

headerless

defer save-reboot-info  ( arg$ cmd$ line# column# -- )
defer get-reboot-info  ( -- cmd+arg$ line# column# )

headerless
: null-save-reboot-info  ( arg$ cmd$ line# column# -- )  2drop 2drop 2drop  ;
' null-save-reboot-info is save-reboot-info
: null-get-reboot-info  ( -- cmd+arg$ line# column# )  null$ 0 0  ;
' null-get-reboot-info is get-reboot-info
headers

\ Force a system reset
\ Typically implemented by a driver for system-level special registers.

defer reset-all ( -- )  ' noop is reset-all


defer cleanup ' noop is cleanup	\ pkg/boot/go.fth

false value already-go?	\ sun4/reenter.fth

\ From reenter.fth
headerless
nuser aborted?      aborted? off
1 value allow-user-aborts?  \ Must be 0/1 instead of false/true because of the incrementing in the low-level handler
: enable-user-aborts  ( -- )  1 to allow-user-aborts?  ;
: disable-user-aborts  ( -- )  0 to allow-user-aborts?  ;

headers
: user-abort  ( -- )  allow-user-aborts? aborted? ! ;
headerless

\ System and version identification

\ System architecture name - used to locate the proper boot file
defer cpu-arch  ( -- adr len )   ' null$ is cpu-arch

defer idprom-valid?  ( -- flag )
' true  is idprom-valid?

3 value major-release  0 value minor-release
defer sub-release  ( -- adr len )   ' null$ is sub-release

defer serial#  ( -- n )   ' 0 is serial#


\ System-wide network address

\ system-mac-address is typically defined in some sort of ID PROM
defer system-mac-address  ( -- adr len )  ' null$ is system-mac-address


\ Device to use for console output if the preferred device is unavailable

headers
defer fallback-device  ( -- adr len )  ' null$ is fallback-device
headerless


\ Compatibility FCode support

defer sbus-intr>cpu   ( sbus-level -- cpu-level )  ' noop is sbus-intr>cpu

: no-memory  ( -- adr len )  0 0  ;

headers
\ OS callbacks
\ The real stack effect appears to be ( args vector -- )
\ defer callback-call  ( arg-array -- error? )  ' noop is callback-call


\ Default font
defer romfont  ( -- fontadr )  ' false is romfont


\ Logo dimensions.  These particular values are stipulated by IEEE 1275-1994
d# 64 constant logo-width
d# 64 constant logo-height

defer default-logo  ' null$ is default-logo

defer nv-c@
defer nv-c!

defer power-off  ( -- )

defer (init-program) ' noop is (init-program)

headers
variable cpu-node

\ From execbuf.fth
purpose: Chain of recognizers for image formats

defer interpret-string  ( adr len -- )  ' evaluate is interpret-string

: safe-include-buffer  ( adr len -- ? )
   dup alloc-mem          ( adr len adr1 )
   swap 2>r               ( adr r: adr1,len )
   2r@ move               ( r: adr1,len )
   2r@ include-buffer     ( ? r: adr1,len )
   2r> free-mem           ( ? )
;
: execute-buffer  ( adr len -- )  true abort" Unrecognized program format"  ;
: execute-buffer    ( adr len -- )              \ Try Forth
   " \ "         2over substring?  if  safe-include-buffer exit  then   ( adr len )
   " purpose: "  2over substring?  if  safe-include-buffer exit  then   ( adr len )
   " id: "       2over substring?  if  safe-include-buffer exit  then   ( adr len )

   execute-buffer
;
: 'execute-buffer  ( -- xt )
   " execute-buffer" ['] forth  search-wordlist  drop
;

headers


\ From diagmode.fth

headers
defer (diagnostic-mode?)  ' false is (diagnostic-mode?)
: diagnostic-mode?  ( -- flag )
   standalone?  if  (diagnostic-mode?)  else  false  then  
;

: diag-type ( adr,len -- )  diagnostic-mode?  if  type  else  2drop  then  ;
: diag-cr   ( -- )  diagnostic-mode?  if  cr  then  ;
: diag-.d   ( n -- ) diagnostic-mode?  if  .d  else  drop  then  ;   
: diag-type-cr ( adr,len -- )  diag-type diag-cr  ;

headers

\ interpolated from loaddevt.fth

\ Create the options vocabulary.  Later, it will become the property
\ list of "options" node in the device tree.

vocabulary options

\ Make the options vocabulary a permanent part of the search order.

only forth also root also definitions
: fw-search-order  ( -- )  root also options also  ;
' fw-search-order to minimum-search-order
only forth hidden also forth also definitions

\ end interpolation

\ From confact.fth

purpose: Generic framework for configuration options

\ Action names for configuration objects

headers

\ 0 action = value on stack  ( apf -- value )
\      call with: fieldname
\ 1 action = store value   ( value apf -- )
\      call with: value to fieldname
\ 2 action = adr on stack  ( apf -- adr )
\      call with: addr fieldname
\ 3 action = decode for display  ( apf -- adr len )
\      call with: decode fieldname
\ 4 action = encode for storage  ( adr len apf -- )
\      call with: encode fieldname
\ 5 action = default value  ( apf -- value )
\ "value" is either int, char, or ( adr len) for strings

: get  ( acf -- value )  0 perform-action  ;
: set  ( value acf -- )  1 perform-action  ;
: decode  ( value acf -- adr len )  3 perform-action  ;
: encode  ( adr len acf -- true | value false )
   4 ['] perform-action  catch  if
      2drop 2drop true
   else
      false
   then
;
: get-default  ( acf -- value )  5 perform-action  ;

defer config-rw  ( -- )  ' noop is config-rw
defer config-ro  ( -- )  ' noop is config-ro
headerless

: to-column:  \ name ( col# -- )  ( -- )
   create c,  does>  c@ to-column
;

d# 22 to-column: value-column
d# 53 to-column: default-column

: 3u.r ( u -- ) <# bl hold u# u#s u#> type  ;

: cdump  ( adr len -- )  push-hex  bounds ?do  i c@ 3u.r  loop  pop-base  ;
: -null  ( adr len -- adr len' )
   \ Remove last character if it's a null
   dup  if                             ( adr len )
      2dup + 1- c@  0=  if  1-  then   ( adr len' )
   then                                ( adr len' )
;
: text?  ( adr len -- flag )
   true -rot  bounds ?do                          ( true )
      i c@  bl h# 7e between  0=                  ( non-printable? )
      i c@  dup carret  =  swap linefeed  =  or   ( non-printable?  cr/nl? )
      0=  and  if  0= leave  then                 ( true )
   loop                            ( all-characters-printable? )
;
: (type-entry)  ( adr,len  -- )
   2dup text?  if
      bounds  ?do
	 i c@  dup  newline =  if
	    drop cr value-column  exit? ?leave
	 else
	    emit
	 then
      loop
   else
      cdump
   then
;
: $type-entry  ( adr len acf -- )
   decode -null                                   ( adr len )
   tuck 2dup text?  if  d# 28  else  d# 12  then  ( len adr len len' )
   min rot over                                   ( adr len' len len' )
   >  if  4 - (type-entry) ." ..."  else  (type-entry)  then  (  )
;
: $type-entry-long  ( adr len acf -- )  decode -null (type-entry)  ;

\ 0 action = value on stack  ( apf -- value )
\      call with: fieldname
\ 1 action = store value   ( value apf -- )
\      call with: value to fieldname
\ 2 action = adr on stack  ( apf -- adr )
\      call with: addr fieldname
\ 3 action = decode for display  ( apf -- adr len )
\ 4 action = encode for storage  ( adr len apf -- )
\ 5 action = default value  ( apf -- value )
\ "value" is either int, char, or ( adr len) for strings

\ XXX should be done using "string-property" or "driver" or something
\ create name " options" 1+ ",  does> count  ;  \ Include null byte in count

headerless

defer nodefault?  ' false is nodefault?

\ Copy default value to current value
: do-set-default  ( acf -- )
   dup >body nodefault?  if  drop  else  >r r@ get-default  r> set  then
;
: $find-option  ( adr len -- false | xt true )
   ['] options search-wordlist
;
: find-option  ( adr len -- false | xt true )
   2dup  $find-option  if            ( adr len xt )
      nip nip  true                  ( xt true )
   else                              ( adr len )
      ." Unknown option: " type cr   ( )
      false                          ( false )
   then
;
   
: show-config-entry  ( acf -- )
   >r
   r@ .name
   value-column     r@ get           r@ $type-entry
   r@ >body  nodefault?  if
      r> drop
   else
      default-column  r@ get-default   r> $type-entry
   then
   cr
;

: show-current-value ( acf -- )
   dup .name ." = "  value-column
   >r  r@ get  r> ( adr len acf )  $type-entry-long cr
;

\ Interfaces to the mechanism (if any) for user-created environment variables
\ Some of these interfaces are used in clientif.fth instead of in this file.

defer next-env-var  ( adr len -- adr' len' )
: no-next-env-var  ( adr len -- null$ )  2drop null$  ;
' no-next-env-var to next-env-var

defer put-env-var  ( value$ name$ -- len )
: no-put-env-var  ( value$ name$ -- len )  2drop 2drop -1  ;
' no-put-env-var to put-env-var

\ show-extra-env displays the values of environment variables
\ other than the ones explicitly known by Open Firmware.
defer show-extra-env-vars
' noop is show-extra-env-vars

defer show-extra-env-var  ( name$ -- )
: no-show-extra  ( name$ -- )  ." Unknown option: " type cr  ;
' no-show-extra to show-extra-env-var

defer put-extra-env-var  ( value$ name$ -- )
: no-put-extra  ( value$ name$ -- )  no-show-extra 2drop  ;
' no-put-extra to put-extra-env-var

defer get-env-var  ( name$ -- true | value$ false )
: no-get-env-var  ( name$ -- true )  2drop  true  ;
' no-get-env-var to get-env-var

defer erase-user-env-vars  ( -- )
' noop to erase-user-env-vars

: printenv-all  ( -- )
   ." Variable Name"  value-column  ." Value"
   default-column ." Default Value" cr cr

   ['] options  follow
   begin  another?  while
      exit?  if  drop exit  then
      dup name>string " name" $= if  \ Don't display the "name" property
         drop
      else
         name>  show-config-entry
      then
   repeat
   show-extra-env-vars
;

: (printenv)  ( adr len -- )
   2dup  $find-option  if
      nip nip show-current-value
   else
      show-extra-env-var
   then
;

headers

: set-default  \ name  ( -- )
   parse-word dup   if                              ( adr len )
      find-option  if  do-set-default  then         ( )
   else                                             ( adr len )
      2drop  ." Usage: set-default option-name" cr  ( )
   then                                             ( )
;
: set-defaults  ( -- )
   ." Setting configuration variables to default values."  cr
   config-rw
   erase-user-env-vars
   ['] options  follow
   begin  another?  while
      dup name>string  " name" $=  if  drop  else  name> do-set-default  then
   repeat
   config-ro
;

: ofw-$getenv  ( name$ -- true | value$ false )
   2dup  $find-option  if                 ( name$ xt )
      nip nip                             ( xt )
      >r  r@ get  r> decode -null false   ( prop$ false )
   else                                   ( name$ )
      get-env-var                         ( true | prop$ false )
   then
   \ Remove the trailing null if there is one; the result from this
   \ word is a Forth string, not a prop-encoded array
   if  true  else  -null false  then
;

: printenv  \ [ option-name ]  ( -- )
   parse-word dup  if  (printenv)  else  2drop printenv-all  then
;

: $setenv  ( value$ name$ -- )
   2dup $find-option  if                             ( value$ name$ xt )
      nip nip

      >r r@  encode  if
         r> drop  ." Invalid value; previous value retained." cr
         exit
      then                                              ( value )

      \ We've passed all the error checks, now set the option value.

      r@ set  r> show-current-value                           ( )
   else
      put-extra-env-var
   then
;
: setenv  \ name value  ( -- )
   parse-word -1 parse strip-blanks  2swap       ( value$ name$ )
   2 pick 0=  over 0=  or  if                    ( value$ name$ )
      2drop 2drop                                ( )
      ." Usage: setenv option-name value" cr     ( )
      exit                                       ( )
   then                                          ( value$ name$ )
   $setenv                                       ( )
;

defer $unsetenv  ( name$ -- )   ' 2drop to $unsetenv
: unsetenv  ( "name" -- )  safe-parse-word $unsetenv  ;

: show  \ name  ( -- )
   parse-word dup  if
      (printenv)
   else
      2drop ." Usage: show option-name" cr
   then
;
: list  ( addr count -- )  \ a version of "type" used for displaying nvramrc
   bounds  ?do
      i c@ newline =  if  cr  exit? ?leave  else  i c@ emit  then
   loop
;

headerless
h# 2000 constant /$edit-max
0 value $edit-buf
: .edit-msg  ( -- )   ." Type Enter or Return to finish editing" cr  ;
: $edit  ( default$ -- edited$ )
   $edit-buf  0=  if  /$edit-max alloc-mem to $edit-buf  then   ( default$ )
   $edit-buf /$edit-max erase           ( default$ )
   tuck  $edit-buf swap  move           ( len )
   $edit-buf swap /$edit-max edit-line  ( len' )
   $edit-buf swap   
;
: free-edit-buf  ( -- )
   $edit-buf  if  $edit-buf /$edit-max free-mem  0 to $edit-buf  then 
;
headers
: $editenv  ( name$ -- )
   2dup  $getenv  if  null$  then            ( name$ value$ )

   .edit-msg $edit                           ( name$ value$' )

   \ If the new value is empty and the variable can be deleted,
   \ offer the user the opportunity to do so.
   dup  0=  if                               ( name$ value$ )
      2over  $find-option  if                ( name$ value$ xt )
         drop                                ( name$ value$ )
      else                                   ( name$ value$ )
         " Delete variable"  confirmed?  if  ( name$ value$ )
            2drop  $unsetenv                 ( )
            free-edit-buf                    ( )
            exit
         then                                ( name$ value$ )
      then                                   ( name$ value$ )
   then                                      ( name$ value$ )

   " Update configuration variable" confirmed?  if  ( name$ value$ )
      2swap $setenv                                 ( )
   else                                             ( name$ value$ )
      4drop                                         ( )
   then                                             ( )

   free-edit-buf
;
: editenv  ( "name" -- )  safe-parse-word $editenv  ;


\ From propenc.fth
purpose: Property encoding and decoding primitives

\ External encoding and decoding for primitive data types

\ Encode integers into a byte array, suitable for passing to Unix.
\ Decode integers from a byte array.

decimal
headers
\ Merge two property-encoded arrays into a single array
\ Assumes that adr0+len0 == adr1
: encode+    ( adr0 len0 adr1 len1 -- adr0 len0+len1 )  nip +  ;


\ Copy a byte array into the dictionary.
: encode-bytes  ( adr len -- adr' len )
   here >r                      ( adr len )
   bounds  ?do  i c@ c,  loop   ( rs: start )
   r> here over -               ( adr' len )
;

: decode-bytes  ( adr1 len1  len2  -- adr1+len2 len1-len2  adr1 len2 )
   >r  over swap r@ /string  rot r>
;


\ Copy a string to the dictionary, and add a null byte at the end
: encode-string  ( adr len -- adr' len+1 )
   here >r                             ( adr len )
   bounds  ?do  i c@ c,  loop   0 c,   ( )  ( rs: start )
   r> here over -                      ( adr' len+1 )
;

\ adrb,lenb is the initial null-terminated string from the argument string.
\ lenb does not include the null.  adra lena is the remainder string.
: decode-string  ( adr len -- adra lena adrb lenb )
   0 left-parse-string
;
: get-encoded-string  ( adr len -- adr len-1 )  1-  ;

\ Copy an int as 4 bytes to the dictionary
: encode-int  ( i -- adr len )   here  swap be-l,  /l  ;

: decode-int  ( adr len -- adr' len' n )
   over be-l@ >r  /l /string  r> l->n
;
: get-encoded-int  ( adr len -- n )  drop be-l@  ;

: encode-cell  ( n -- adr len )   here  swap be-n,  /n  ;

: decode-cell  ( adr len -- adr' len' n )
   over be-x@ >r  /x /string  r>
;
: get-encoded-cell  ( adr len -- n )  drop be-n@  ;
headers

\ From devtree.fth
purpose: 

headers

defer voc>phandle ' noop to voc>phandle
defer phandle>voc ' noop to phandle>voc
defer dt-null     ' null to dt-null

\ : : :  lastacf .name cr ;

: rel-voc>phandle  ( voc -- ph )  origin -  ;  ' rel-voc>phandle to voc>phandle
: rel-phandle>voc  ( ph -- voc )  origin +  ;  ' rel-phandle>voc to phandle>voc
' 0 to dt-null

\ TODO
\ Don't use the system search order; use a private stack
\ $find searches through the private stack
\ Change names back from "regprop" to "reg", etc.
\ Either implement a true breadth-first search or don't specify it.

: cdev drop context token@  voc>phandle  ;
: devc drop phandle>voc  context token!  definitions  ;
2 actions
action: cdev ;
action: devc ;
create current-device  use-actions

action-adr-t to ^current-device

headerless
: ufield  \ name  ( offset size -- offset' )
   create  over ,   +
   does>  @  current-device  phandle>voc  >body >user +
;

\ Notes for a more abstract searching mechanism:
\ Instead of the child and peer links in the device node, packages
\ with children have "search", "create", and "enumerate" methods.
\ To search a level, call that package's search method.  Those
\ methods probably need to work from a phandle, not an ihandle.

: unaligned-ualloc  ( size -- user# )
   #user @  dup user-size > abort" User area used up!"  ( size user# )
   swap #user +!  ( user# )
;

struct  ( devnode )
/link #threads *  ufield  'threads	\ Package methods
dup				\ The following fields will be "ualloc"ed
   /token  ufield  'child	\ Pointer to first child
   /token  ufield  'peer	\ Pointer to next peer
   /token  ufield  'properties	\ Pointer to properties vocabulary
   /n      ufield  '#adr-cells	\ Size of a parent address
   /n      ufield  '#buffers
   /n      ufield  '#values
   /token  ufield  'values
( starting-offset ending-offset )  swap -  ( size-to-ualloc )
constant /devnode-extra

headers
: >parent  ( node -- parent-node )  phandle>voc >voc-link  a@ voc>phandle  ;
: parent-device  ( -- parent-node )  current-device >parent  ;

: (select-package)  ( phandle -- )  phandle>voc execute  ;
: (push-package)  ( phandle -- )  also (select-package)  ;
: (pop-package)  ( phandle -- )  previous  ;
: push-package  ( phandle -- )
   dup  0=  if  ." Attempting to push null package!!!" abort  then
   (push-package)  definitions
;
: pop-package  ( -- )  (pop-package) definitions  ;
: push-device  ( phandle -- )  to current-device  ;

: pop-device  ( -- )
   parent-device                     ( parent-phandle )
   dup dt-null <>  if  push-device  else  drop  then
\    non-null?  if  push-device  then
;

\ Each package instance has its own private data storage area.
\ The data creation words "value", "variable", and "buffer:",
\ when used during compilation of a package, allocate memory
\ relative to a base pointer.  The package definition includes the
\ initial values for the words created with "value" and "variable".
\ When a package instance is created, memory is allocated for the
\ package's data and the portion used for values and variables is
\ initialized from the values stored in the package definition.
\
\ While the package is being defined (i.e. its code is being compiled),
\ a "dummy" instance is created with space for data, so that
\ data words may be used as soon as they are created.  The "dummy"
\ instance data area is given a "generous" default size (for 100 * cellsize
\ bytes of initialized data, 700 * cellsize for buffers).
\ Hopefully this won't be exceeded.

headerless
variable package-level  package-level off
variable next-is-package  next-is-package off
variable next-is-instance  next-is-instance off
: instance?  ( -- flag )
   package-level @ 0<>  next-is-instance @  and
   next-is-instance off
;
: package?  ( -- flag )
   package-level @ 0<>  next-is-package @  and
   next-is-package off
;
headers
: instance  ( -- )  next-is-instance on  ;
: package  ( -- )  next-is-package on  ;
: global   ( -- )  next-is-package off  ;  \ The default, for now
headerless

\ Should be in machine code
: >instance-data  ( pfa -- adr )
   my-self  if  @ my-self + exit  then
   true abort" Tried to access instance-specific data with no current instance"
;

\ Sizes of the initialized and unitialized portions of the buffer that
\ is used as the instance data when the package is being created.
\ This allows variables, buffers, and values to be used while the
\ package is being created.

d# 100 /n* constant /value-area
d# 700 /n* constant /buffer-area

: value#,  ( size -- adr )
   '#values @  dup ,   ( size offset )
   tuck +              ( offset offset' )
   dup /value-area >= abort" Too many instance variables/values/defers"
   '#values !          ( offset )
   my-self +           ( adr )
;

headers
: value  \ name  ( initial-value -- )
   header noop   \  Will patch with (value)
;
headerless
3 actions
action:  >instance-data @  ;
action:  >instance-data !  ;
action:  >instance-data    ;
action-adr-t to ^instance
: instance-value  ( initial-value -- )
   create-cf use-actions  /n value#, !
;

\ Create fields which are present in every instance record.
\ "fixed instance value"

headers
transient
: fibuf:  \ name  ( offset -- offset' )
   create -1 na+ dup ,  ( offset' )
   use-actions
;
: fival:  \ name  ( offset -- offset' )
   create dup , na1+ ( offset' )
   use-actions
;
resident

headerless
: 2value  \ name  ( d.initial-value -- )
   header noop   \  Will patch with (2value)
;

3 actions
action:  >instance-data 2@  ;
action:  >instance-data 2!  ;
action:  >instance-data     ;

: instance-2value  ( d.initial-value -- )
   create-cf use-actions  /n 2* value#,  2!
;

action-adr-t to ^instance-2value

headers
: buffer:  \ name  ( size -- )
   header noop  \ Will patch with (buffer:)
;

3 actions
action:  >instance-data    ;
action:  >instance-data !  ;
action:  >instance-data    ;

headerless
: (buffer:)  ( #bytes -- )
   instance?  if
      create-cf
      '#buffers @ swap aligned -  dup  ,  ( offset' )
      dup negate /buffer-area > abort" Too many bytes of instance buffers"
      '#buffers !  use-actions
   else
      (buffer:)
   then
; patch (buffer:) noop buffer:

action-adr-t to ^instanceBUF

headers
: variable  \ name  ( -- )
   header  noop \ Will patch with (variable)
;

3 actions
action:  >instance-data    ;
action:  >instance-data !  ;
action:  >instance-data    ;

headerless
: (variable)  ( -- )
   instance?  if
      create-cf use-actions  0 /n value#,  else  user-cf  0 /n  user#,
   then
   !
; patch (variable) noop variable
action-adr-t to ^instance-VARIABLE 
headers
: defer  \ name  ( -- )
   header noop \ Will patch with (defer)
;
3 actions
action:  >instance-data token@ execute  ;
action:  >instance-data token!  ;
action:  >instance-data token@  ;

headerless
: instance-defer  ( -- )
   create-cf  ['] crash /token  ( value data-size )
   use-actions  value#,
;
: (defer)  ( -- )
   instance?  if
      instance-defer
   else
      defer-cf  ['] crash /token   ( value data-size )
      user#,
   then                            ( value adr )
   token!
; patch (defer) noop defer
action-adr-t to ^instance-defer

\ Extend debugger to handle instance defers
: (resolve-instance-defers)  ( xt -- xt' )
   begin
      dup defer?  if                             ( xt )
	 behavior                                ( xt' )
      else                                       ( xt )
         dup definer ['] instance-defer  =  if   ( xt )
            2 perform-action                     ( xt' )
	 else                                    ( xt )
	    exit
         then
      then
   again
;
' (resolve-instance-defers) to resolve-defers

\ Extend decompiler to handle instance defers
: .instance-defer  ( xt definer -- )
   .definer  ." is " cr   ( xt )
   2 perform-action       ( xt' )
   (see)
;
' instance-defer  ' .instance-defer  install-decomp-definer

headers
\ Instance values that are automatically created for every package instance.

0
fival: my-adr0		\ F: First component of device probe address
fival: my-adr1		\ F: Intermediate component of device probe address
fival: my-adr2		\ F: Intermediate component of device probe address
fival: my-space 	\ F: Last component of device probe address
fival: frame-buffer-adr \ F: Frame buffer address.  Strictly speaking, this
                        \ should not be in every package, but we put it
                        \ here as a work-around for some old CG6 FCode
                        \ drivers whose selftest routines use frame-buffer-adr
                        \ for diagnostics mappings.  If frame-buffer-adr is
                        \ global, that would cause dual-cg6 systems to break.
fival: my-termemu

headerless
constant #fixed-vals
headers

0
fibuf: my-voc           \ Package definition (code) for this instance
fibuf: my-parent        \ Current instance just before this one was created
fibuf: my-args-adr      \ Argument string - base address
fibuf: my-args-len      \ Argument string - length
fibuf: my-unit-3	\ Fourth component of device instance address
fibuf: my-unit-2	\ Third  component of device instance address
fibuf: my-unit-1	\ Second component of device instance address
fibuf: my-unit-low	\ First  component of device instance address

headerless
constant #fixed-bufs

: initial-values  ( -- adr )  'values token@  ;

\ Non-instance values defined inside packages are stored in the initial
\ value array that is used to initialize instance data, but unlike instance
\ values, they are accessed directly from the initial value array instead
\ of from the instance record.  This allows their values to be shared among
\ different instances, either simultaneously-active ones or ones that are
\ separated in time, and also allows different clones of that package to
\ have separate copies of that data.  The down side of this scheme, compared
\ to the previous technique of using the user area for non-instance values
\ is that it is not ROMable, because the initial value array must be writeable
\ (previously it was only written at package creation time, and read-only
\ thereafter).  One up side is that packages that use large numbers of non-
\ instance values no longer consume a lot of user area (a relative-limited
\ resource).  If we ever need to make this ROMable, we can implement copy-on-
\ write for initial values.

: initial-values'  ( -- adr )
   my-self  if	\ Use current instance's package if there is a current instance
      my-voc (push-package)  initial-values  (pop-package)
   else		\ Otherwise use the active package
      initial-values
   then
;

: >initial-value  ( pfa -- adr )  @  initial-values' +  ;

3 actions
action:  >initial-value @  ;
action:  >initial-value !  ;
action:  >initial-value    ;

: package-value  ( initial-value -- )
   create-cf use-actions  /n value#,  !
;
 action-adr-t to dopackage-value
: (value)  ( initial-value -- )
   instance?  if
      instance-value
   else
      package?  if  package-value  else  value-cf /n user#, !  then
   then
;
patch (value) noop value

3 actions
action:  >initial-value 2@  ;
action:  >initial-value 2!  ;
action:  >initial-value     ;

: package-2value  ( initial-value -- )
   create-cf use-actions  2 /n* value#,  2!
;

: (2value)  ( initial-value -- )
   instance?  if
      instance-2value
   else
     package?  if  package-2value  else  2value-cf  2 /n* user#, 2!  then
   then
;
patch (2value) noop 2value

headers
: my-args  ( -- adr len )  my-args-adr my-args-len  ;

headerless
: allocate-instance  ( value-size variable-size -- )
   \ Allocate instance record
   my-self >r                                 ( val-size var-size )
   tuck +  alloc-mem                          ( var-size base-adr )
   + is my-self                               ( )

   \ Set the fixed fields
   r> to my-parent                            ( )
   current-device  to my-voc                  ( )
   0 to my-args-len  0 to my-args-adr         ( )  \ May be changed later
;

\ Returns the address of the initial value of the named instance data.
: (initial-addr)  ( adr -- adr' )    my-self -  initial-values' +  ;
: initial-addr  \ name  ( -- addr )
   [compile] addr
   state @  if  compile (initial-addr)  else  (initial-addr)  then
; immediate

: copy-args  ( args-adr,len -- )
   dup  if
      dup alloc-mem to my-args-adr          ( args-adr,len )
      to my-args-len                        ( args-adr )
      my-args-adr my-args-len move          ( )
   else
      2drop
   then
;

: copy-instance-data  ( -- )
   initial-values  my-self  '#values @  move
;
\ my-self points to a position in the middle of the instance record.
\ Initialized data ("values") is at positive offsets from my-self,
\ and uninitialized data ("variables" and "buffers") is at negative offsets.
: new-instance  ( args-adr args-len -- )
   '#values @  '#buffers @ negate  allocate-instance  ( args-adr args-len )
   copy-instance-data                                 ( args-adr args-len )
   copy-args
;

: deallocate-instance  ( value-size variabled-size -- )
   my-args-len  if  my-args-adr my-args-len free-mem  then
   my-self  my-parent is my-self   ( val-size var-size self )
   over -                          ( val-size var-size base-adr )
   -rot  +  free-mem               ( )
;

\ Destroy instance has the side effect of setting my-self to the parent
\ of the node that is being destroyed.  This prevents my-self from referring
\ to a non-existent instance.

: destroy-instance  ( -- )
   my-voc (push-package)              ( )
   '#values @  '#buffers @  negate    ( value-size variable-size )
   (pop-package)                      ( value-size variable-size )
   deallocate-instance

;
\ When creating a package definition, we initialize the buffer
\ (uninitialized data) allocation pointer and the value (initialized data)
\ allocation pointer.

: prime-package  ( -- )
   next-is-instance off
   1 package-level +!  /value-area /buffer-area  allocate-instance
   my-self  'values token!
;
headers
: extend-package  ( -- )
   initial-values              ( 'values )
   prime-package               ( 'values )
   my-self  '#values @  move   \ Preserve the initial values
;
headerless

: allot-package-data  ( -- )
   acf-align here dup 'values token!  '#values @ dup allot  erase
;
: finish-package-data  ( -- )
   \ Copy the initialized data into the dictionary and set up the
   \ pointer to it.
   '#values @  if  allot-package-data  then
   my-self  initial-values  '#values @  move            ( )

   initial-addr frame-buffer-adr off
   initial-addr my-termemu       off

   /value-area /buffer-area deallocate-instance         ( )
   package-level @ 1- 0 max package-level !
;

\ Internal factor used to implement first-child and next-child
: set-child?  ( link-adr -- flag )
   get-token?  if  voc>phandle push-device true  else  false  then
;

\ Interface to searching code in breadth.fth:
: first-child  ( -- another? )  'child set-child?  ;
: next-child   ( -- another? )  'peer  pop-device  set-child?  ;

\ Removes the voc-link field from the most-recently-created vocabulary
: erase-voc-link  ( -- )
   voc-link  a@ >voc-link a@  voc-link a!
   /link na1+ negate allot
;

\ Creates an unnamed vocabulary
: (vocabulary)  ( -- )
   ['] acf-align is header
   vocabulary
   ['] (header) is header

   erase-voc-link
;

: allocate-node-record  ( -- )
   \ Allocate user (RAM) space for  properties, "last" field, children, peers
   /devnode-extra  unaligned-ualloc drop

   lastacf voc>phandle push-device           ( parent's-child-field )
;
: init-properties  ( -- )  (vocabulary)  lastacf 'properties token!  ;

: init-node  ( #address-cells -- )
   allocate-node-record

  '#adr-cells !
  'child      !null-token      \ No children yet
  'peer       !null-token      \ Null peer

   #fixed-vals  '#values    !  \ Initialize data sizes
   #fixed-bufs  '#buffers   !

   'values    !null-token      \ No initial data values yet

   init-properties
;

: current-properties  ( -- )  'properties token@  ;

headerless
: link-to-peer  ( parent's-child-field -- )
   dup token@ 'peer token!             ( parent's-child-field )
   current-device phandle>voc  swap token!         ( )
;
: device-node?  ( voc -- flag )
   voc-link  begin  another-link?  while        ( voc link )
      2dup voc>  =  if  2drop false exit  then  ( voc link )
      >voc-link
   repeat                                       ( voc )
   drop true
;

: $vexecute?  ( adr len voc-acf -- true | ??? false)
   (search-wordlist)  if  execute false  else  true  then
;
: $package-execute?  ( adr len phandle -- true | ??? false)
   phandle>voc (search-wordlist)  if  execute false  else  true  then
;
: $vexecute  ( adr len voc-acf -- ?? )  $vexecute? drop  ;

headers
\ Used during compilation (probing), when the search order includes
\ the current vocabulary as well as the parent vocabularies.
: get-property  ( name-adr,len -- true | value-adr,len false )
   current-properties (search-wordlist)  if  ( xt )
      >r r@ get  r> decode                   ( value-adr,len )
      false                                  ( value-adr,len false )
   else                                      ( )
      true                                   ( true )
   then
;

headerless
: #adr-cells  ( -- n )
   " #address-cells" get-property  if  2  else  get-encoded-int  then
;

headers
: new-node  ( -- )
   (vocabulary)  current-device phandle>voc a,  ( )  \ Up-link to parent device

   \ Save parent linkage address on stack for later use
   'child                              ( parent's-child-field )
   #adr-cells init-node                ( parent's-child-field )
   link-to-peer                        ( )
;

: (clone)  ( template-phandle parent-phandle -- )
   (vocabulary)  a,                 ( template )  \ Up-link

   \ Get pointers from template node
   push-package                        ( )
   current-properties >threads token@  ( props )
   'threads                            ( props record )
   pop-package                         ( props record )

   \ Inherit methods and initialized data
   allocate-node-record                ( props record )
   'threads /devnode-extra  /link #threads * +  move   ( props )

   \ Inherit properties
   init-properties                     ( props )
   current-properties >threads token!  ( )

   \ Don't inherit children
   'child      !null-token             ( )

   parent-device push-package          ( )
   #adr-cells 'child                   ( #adr-cells parent's-child-field )
   pop-package                         ( #adr-cells parent's-child-field )

   \ Attach the new node to its parent's list of children
   link-to-peer                        ( #adr-cells )

   \ Fix #adr-cells in case the template is under a node that doesn't have
   \ the right number of address cells (e.g. /templates).

   '#adr-cells !                       ( )

   extend-package                      ( )
;

\ Creates a copy of current-device, setting current-device to the new copy.
\ The new clone is located in the device tree as a peer of the package that
\ was copied.
\ See also "$clone-node" in instance.fth
: clone-node  ( -- )  current-device  parent-device  (clone)  ;

: new-device   ( -- )  new-node  prime-package  ;

: device-end   ( -- )  only forth also definitions  package-level off  ;
alias dend device-end

: my-#adr-cells  ( -- n )
   my-self  if	\ Use current instance's package if there is a current instance
      my-voc (push-package)  '#adr-cells @  (pop-package)
   else		\ Otherwise use the active package
      '#adr-cells @
   then
;

\ my-address applies to the current instance, regardless of whether or
\ not the active package corresponds to the current instance, thus it must
\ use my-#adr-cells, which explicitly refers to the current instance's
\ package.

: my-address  ( -- phys.lo .. )
   addr my-adr0  my-#adr-cells 1- 0 max /n* bounds  ?do  i @  /n +loop
;
: my-unit  ( -- phys.lo .. )
   addr my-unit-low  my-#adr-cells /n* bounds  ?do  i @  /n +loop
;

vocabulary root-node
 ' root-node TO LASTACFV \ MMO
   erase-voc-link  null ,   \ Root has no parent
   0 init-node
   allot-package-data
device-end
: root-phandle  ( -- ph )  ['] root-node voc>phandle  ;

: root-device  ( -- )  only forth also  root-phandle push-device  ;

: root-device?  ( -- flag )  parent-device dt-null =  ;

: finish-device  ( -- )  finish-package-data  pop-device  ;

: next-package  ( phandle -- phandle' )
   push-package 'peer a@ pop-package   ( phandle phandle' )
;
: previous-link  ( phandle -- link-adr )
   dup >r push-package             (                    R: phandle )
   root-device?  abort" Attempted to find the predecessor of the root package"
   pop-device                      (                    R: phandle )
   'child   begin                  ( link               R: phandle )
      dup a@                    ( link voc'          R: phandle )
      dup r@ phandle>voc <>        ( link voc'          flag R: phandle )
   while                           ( link phandle'      R: phandle )
      voc>phandle push-device      ( link               R: phandle)
      drop  'peer                  ( link'              R: phandle)
   repeat                          ( link phandle'      R: phandle )
   r> 2drop                        ( link )
   pop-package                     ( link )
;
: delete-package  ( phandle -- )
   dup next-package  swap previous-link a!
;

\ The magic-device-types vocabulary contains words whose names are the
\ same as the names of the device_type property values that we wish to
\ recognize as special cases.  "device_type" in the "magic-properties"
\ vocabulary searches this vocabulary every time that a "device_type"
\ property is created, and executes the corresponding word if a match
\ is found.  That word may look at the property name and value on the
\ stack, but it must not remove them.  However, it might wish to alter
\ the value!

vocabulary magic-device-types

\ The magic-properties vocabulary contains words whose names are the
\ same as the names of properties that we wish to recognize as special
\ cases.  "property" searches this vocabulary every time that an
\ property is created, and executes the corresponding word if a match
\ is found.  That word may look at the property name and value on the
\ stack, but it must not remove them.  However, it might wish to alter
\ either the name or the value!

headerless
false value autoloading?		\ Used to suppress probe reports
headers

vocabulary magic-properties

\ The parameter field of a property word contains:
\    offset size
\ Offset is the 32-bit positive distance from the beginning of the
\ property-encoded byte array to the parameter field address.  size is the
\ 16-bit size of the property value array.  This representation depends on
\ the fact that property-encoded arrays are stored in the dictionary.

: make-property-name  ( name-adr,len -- )
   current token@ >r current-properties current token!
   $create
   r> current token!
;

headerless
: change-property  ( value-adr,len property-acf -- )
   \ Make a safe copy of the property value string if necessary
   >r  over in-dictionary?  0=  if  encode-bytes  then  r>
   >body tuck na1+ !     ( value-adr property-apf )
   dup rot - swap !      ( )
;

headers
5 actions
action:  dup dup @ -  swap na1+ @  ;
action:  body> change-property  ;
action:  ;
action:  drop  ;
action:  drop  ;

action-adr-t dup h. to vproperty \ mmo

: (property)  ( value-adr,len  name-adr,len  -- )
   caps @ >r  caps off
   2dup  ['] magic-properties  $vexecute          ( value-str name-str )
   2dup current-properties (search-wordlist)  if  ( value-str name-str acf )
      nip nip change-property                     ( )
   else                                           ( value-str name-str )
      make-property-name                          ( value-str )
      here rot - , ,  align use-actions           ( )
   then                                           ( )
   r> caps !
;

: property  ( value-adr,len  name-adr,len  -- )
   my-self if
      context token@ >r my-voc (select-package)
      (property)
      r> context token!
   else
      (property)
   then
;

: delete-property  ( name-adr,len -- )
   current-properties (search-wordlist)  if
      >link current-properties  remove-word
   then
;
: forget  \ name  ( -- )
   current token@  device-node?  abort" Can't forget device methods"
   forget
;

: get-unit  ( -- true | adr len false )  " reg" get-property  ;

headerless
: unit-str>phys-  ( adr len -- phys.hi .. phys.lo )
   '#adr-cells @  0  ?do  decode-int -rot  loop  2drop   ( phys.hi .. phys.lo )
;

: reorder  ( xn .. x1 n -- x1 .. xn )  0  ?do  i roll  loop  ;

: unit-str>phys  ( adr len -- phys.lo .. phys.hi )
   unit-str>phys-           ( phys.hi .. phys.lo )
   '#adr-cells @  reorder   ( phys.lo .. phys.hi )
;
headers

\ From breadth.fth
purpose: 

\ Tree searching code:
\ This implements a funny-order search of an n-ary tree.
\ First, all the child nodes at this level are searched.
\ If not found, then the first child node is made the current node
\ and the process is repeated recursively.  If that fails, the second
\ child node is selected, and so on.
\ All the descendents of the first node will thus be searched before
\ any of the descendents of the second node.
\ This is not quite a breadth-first search.

\ Interface to code in devtree.fth:
\   first-child   ( -- another? )
\       If current-node has a first child, sets current-node to that
\	child and returns true.
\   next-child    ( -- another? )
\	If current-node has a next peer, sets current-node to that peer
\	and returns true, else sets current-node to the parent of
\	current-node and returns false.
\
\ This rather strange interface turns out to be extremely convenient
\ to use in a loop over all children; e.g.
\
\       first-child  begin while   XXX   next-child repeat
\
\ where XXX is the code to be executed for each child.

headerless

: error:  \ name  ( -- )
   create  does>
;

error: found      ," "
error: not-found  ," Device not found"

: (search-level)  ( ? acf -- ? acf )
   first-child  begin while                ( ? acf )

      dup catch  ?dup  if                  ( ? acf error )
         .error                            ( ? acf )
      else                                 ( ? acf found? )
         if  found throw  then             ( ? acf )
      then

   next-child repeat                       ( ? acf )
;

: (search-preorder)  ( ? acf -- ? acf )   recursive
   (search-level)

   first-child  begin while  (search-preorder)  next-child repeat
;

: invert-signal  ( ? acf -- ? acf )
   catch  case
      0     of     not-found throw    endof
      found of                        endof
      ( default )  throw
   endcase
;
: search-preorder  ( ? acf -- ? acf )  ['] (search-preorder)  invert-signal  ;
: search-level     ( ? acf -- ? acf )  ['] (search-level)     invert-signal  ;
headers

\ From finddev.fth
purpose: 

vocabulary aliases

4 /n* buffer: unit#

headerless
0 value unit#-valid?
: unit-bounds  ( -- end-adr start-adr )  unit#  '#adr-cells @ /n*  bounds  ;

: "name" ( -- adr,len )  " name"  ;  \ Space savings

\ True if "name$" matches the node's name
: name-match?  ( name$ -- name$ flag )
   "name" get-property  if                  ( name$ )
      false                                 ( name$ false )
   else                                     ( name$ adr' len' )
      1-    \ Omit null byte 		    ( name$ adr' len' )
      2over 2over  $=  if                   ( name$ adr' len' )
         2drop true                         ( name$ true )
      else                                  ( name$ adr' len' )
         \ Omit the manufacturer name and test again
         ascii , left-parse-string  2drop  2over  $=
      then
   then                                     ( name$ flag )
;

\ True if "unit-adr,space" matches the node's unit number
: unit-match?  ( -- flag )
   get-unit  if                 ( )
      false  	                ( flag )  \ No "reg" property
   else                         ( phys.lo .. phys.hi )
      true                      ( unit-adr,len )
      unit-bounds  ?do          ( unit-adr,len  flag )
         -rot  decode-int       ( flag  unit-adr,len' n )
	 i @ =  3 roll and      ( unit-adr,len' flag' )
      /n +loop                  ( unit-adr,len' flag )
      nip nip                   ( flag )
   then                         ( flag )
;

headerless
create bad-number ," Bad number syntax"
: safe->number  ( adr len -- n )  $number  if  bad-number throw  then  ;

headers
: package-execute  ( ?? adr len -- ?? )
   current-device $package-execute?  abort" Package method not found"
;
headerless

\ True if the node has no unit number and "name$" matches the node's name
: wildcard-match?  ( name$ acf -- name$ acf flag )
   >r
   dup  if
      name-match?  0=  if  r> false  exit  then
   then                                                   ( name$ )

   get-unit  0=  if  2drop  r> false  exit  then          ( name$ )

   dup 0=  unit#-valid? 0=  and  if  r> false  exit  then

   r> true
;

: exact-match?  ( name$ acf -- name$ acf flag )
   >r
   dup  if                              ( name$ )       \ Name present
      name-match?  0=  if  r> false  exit  then
   then                                 ( name$ )
   unit#-valid?  if                     ( name$ )       \ Unit present
      unit-match?  0=  if  r> false  exit  then
   then
   r> true
;

\ 1) Search direct children for an exact match
\ 2) Search direct children for a wildcard match
\ 3) Select each child node in turn and (recursively) repeat steps
\    (1), (2), and (3)

: (find-node)  ( unit$ name$ -- unit$ name$ )

   \ If the node has no children, then there is no point in searching it,
   \ and it doesn't matter if it has no decode-unit method
   first-child  0=  if  exit  then  pop-device

   unit#-valid?  if		\ Omit unit match test if no unit string
      2over " decode-unit"           ( unit$ name$  unit$ method$ )

      ['] package-execute catch  if  ( unit$ name$  x x x x )
         \ If decode-unit aborted, a match at this level is impossible 
         2drop 2drop exit
      then                           ( unit$ name$ phys.lo .. phys.hi )

      \ We can't use unit-bounds here
      unit# #adr-cells /n*  bounds  ?do  i !  /n +loop   ( unit$ name$ )
   then

   \ (search-level) will throw "found" to (find-device) if it succeeds
   ['] exact-match?     (search-level)  drop             ( unit$ name$ )
   ['] wildcard-match?  (search-level)  drop             ( unit$ name$ )
;

: (find-child-node)  ( unit$ name$ -- unit$ name$ ) recursive
   first-child  begin while   (find-node) (find-child-node)  next-child repeat
;

: find-component  ( component$ -- )
   \ Separate out arguments
   ascii : left-parse-string            ( args-str name.unit$ )

   \ Arguments only apply to "open", so discard them when searching
   2swap 2drop                              ( name.unit$ )

   \ Split name and unit
   ascii @  left-parse-string               ( unit$ name$ )

   2 pick is unit#-valid?                   ( unit$ name$ )

   ['] (find-node)  catch  ?dup  if         ( unit$ name$ error )
       dup found <>  if                     ( unit$ name$ error )
           dup .error throw
       then                                 ( unit$ name$ error )
       drop                                 ( unit$ name$ )
   else                                     ( unit$ name$ )
       ['] (find-child-node)  invert-signal ( unit$ name$ )
   then                                     ( unit$ name$ )

   2drop 2drop                              ( )
;
: (find-device)  ( str -- )

   0 to unit#-valid?

   \ If a search path is present, find the indicated subdirectory
   begin  dup  while        ( rem$ )

      \ Split the remaining string at the first backslash, if there is one
      ascii / left-parse-string            ( rem$' component$ )

      dup  if                              ( rem$ component$ )
         find-component                    ( rem$ )
      else                                 ( rem$ component$ )
         \ If the component name string is null, there was a double slash,
         \ indicating an interposed support package.  Skip it.
         2drop                             ( rem$ )
         ascii / left-parse-string  2drop  ( rem$' )
      then                                 ( rem$ )

   repeat                   ( rem$ )

   2drop
;

: not-alias?  ( str -- expansion$ false | true )
   \ Search the alias list.
   ['] aliases (search-wordlist)  if  execute false  else  true  then
;

headerless
\ Ultimately, we need a more robust way to manage the alias buffer.
\ One approach would be to use a two-entry ping-pong buffer.  In every
\ place where "?expand-alias" or "aliased?" is called, save the buffer
\ specification and allocate a new two-entry buffer.  When the buffer
\ is no longer needed, free the buffer and restore the previous one.
\ That will be a little tricky, since they are used in several places,
\ both in this directory and also in pkg/*/*th.
h# 800 buffer: (alias-buf)
0 value alias-buf-offset
: alias-buf  ( -- adr )  (alias-buf) alias-buf-offset +  ;
: switch-alias-buf  ( -- )
   alias-buf-offset  h# 100 +  h# 7ff and  to alias-buf-offset
;

\ Expands devaliases optionally overwriting the default argument
\ to the rightmost component of the expanded pathname
: expand-alias  ( devspec$ -- pathname$ flag )
   switch-alias-buf
   \ Extract the part of the pathname that can be an alias

   2dup  ascii /  split-before  ( devspec$ tail$ head$ )
   ascii :  split-before        ( devspec$ tail$ arg$ name$ )

   \ If the device-specifier is not an alias, return it unmodified.

   not-alias?  if               ( devspec$ tail$ arg$ )
      2drop 2drop false  exit   ( devspec$ )
   then                         ( devspec$ tail$ arg$ expansion$ )

   \ The device-specifier is an alias.

   \ If the aliased component of the device-specifier had explicit
   \ arguments, use them to override any arguments that were included
   \ in the alias expansion.

   2 pick  if                   ( devspec$ tail$ arg$ expansion$ )
      \ alias name has args
      ascii / split-after       ( devspec$ tail$ arg$ alias-tail$ alias-head$ )
      alias-buf place           ( devspec$ tail$ arg$ alias-tail$ )
      ascii : split-before      ( devspec$ tail$ arg$ $deadargs $alias-tail$' )
      alias-buf $cat            ( devspec$ tail$ arg$ $deadargs )
      2drop  alias-buf $cat     ( devspec$ tail$ )
   else                         ( devspec$ tail$ arg$ expansion$ )
      \ alias name does not have args
      alias-buf place           ( devspec$ tail$ arg$ )
      2drop                     ( devspec$ tail$ )
   then                         ( devspec$ tail$ )

   \ Append the tail of the device specifier to the expanded alias

   alias-buf $cat               ( devspec$ )
   2drop                        ( devspec$ )
   alias-buf count  true        ( pathname$ true )
;
: aliased?  ( name-str -- name-str false | alias-expansion-str true )
   \ The empty string is not an alias
   dup 0=  if  false exit  then               ( str )

   \ A pathname beginning with a slash is not an alias
   over c@  ascii / =  if  false exit  then   ( str )

   d# 100  0  do                              ( str )
      expand-alias  0=  if                    ( str )
         \ The result has been expanded if the first character
         \ is now a "/"
         over c@  [char] / =                  ( str flag )
         unloop exit
      then                                    ( str )
   loop
   true abort" Too many levels of aliasing"
;
: ?expand-alias  ( name-str -- name-str | alias-expansion-str )
   aliased? drop
;

: context-voc?  ( voc-acf -- flag )  context token@ =  ;
: device-context?  ( -- flag )  ['] context-voc? find-voc  0=  ;

: ?not-found  ( flag -- )  if  not-found throw  then  ;
: noalias-find-device  ( str -- )
   \ Throw if null string
   ?dup 0=  ?not-found                 ( str$ )

   \ The path starts at the root directory if the first character is "/";
   \ otherwise it starts at the current directory
   dup 1 >=  if                        ( str$ )
      over c@  ascii /  =  if  1 /string  root-phandle push-device  then
   then                                ( str$ )

   current-device dt-null =  ?not-found
   device-context?  0= ?not-found
   (find-device)
;
: aliased-find-device  ( str -- )  ?expand-alias noalias-find-device  ;
headers
5 actions
action: count  ;
action: 3drop  ;        \ No "store" method
action:        ;        \ Just return the address
action: drop $cstr cscount 1+  ;    \ Convert to string encoding
action: drop get-encoded-string  ;  \ Remove null byte
: $devalias  ( name-str expansion-str -- )
   also aliases definitions
   strip-blanks  2swap strip-blanks
   warning @ >r warning off $create r> warning !
   previous definitions
   ",
   use-actions
;

action-adr-t to dodevalias \ mmo

: locate-device  ( adr len -- true  |  phandle false )
   also
   ['] aliased-find-device catch  if
      2drop true
   else
      current-device false
   then
   previous definitions
;

headerless
: noa-find-device  ( adr len -- )
   current-device >r
   ['] noalias-find-device  catch  case
      0          of  r> drop                          endof
      not-found  of  r> push-device  not-found throw  endof
      ( default )    r> push-device  throw
   endcase
;
headers
: find-device  ( adr len -- )  ?expand-alias noa-find-device  ;

headerless
: $parent-execute  ( adr len -- )
   current-device >r  pop-device  package-execute  r> push-device
;
headers

\ From testdevt.fth
purpose: 

headerless
: (nh.) ( u -- adr,len )  push-hex   (u.)  pop-base  ;
: .nh  ( u -- )  (nh.) type  ;

: is-named? ( -- value-adr,len true | false )  " name" get-property 0=  ;
: get-node-name  ( -- adr,len )
   is-named?  if  get-encoded-string   else  " <Unnamed>"   then
;

: .node-name  ( -- )
   get-node-name  type
   get-unit  0=  if                           ( unit-str )
      ." @"
      unit-str>phys                           ( phys.lo .. phys.hi )
      " encode-unit"  parent-device           ( phys.lo .. phys.hi adr,len phandle )
      $package-execute?  if                   ( phys.lo .. phys.hi )
         '#adr-cells @  if  .nh  then         ( phys.lo .. phys.next )
	 '#adr-cells @ 1-  0 max  0  ?do  ." ,"  .nh  loop  ( )
      else
         type
      then
   then
;

: u.h   ( u -- )   push-hex u. pop-base  ;

: .nodeid  ( -- )  current-device u.h  .node-name  cr  ;

: 8.x  ( n -- )
   push-hex
   (.8) type space
   pop-base
;

: to-display-column  ( -- )  d# 25 to-column  ;

\ Displays the property value "adr,len" as a list of integer values,
\ showing '#ints/line' on each line.
: .ints  ( adr len #ints/line  -- )
   >r
   begin  dup 0>  while                  ( adr len )
      to-display-column
      r@  0  do  decode-int 8.x  loop    ( adr' len' )
      cr
      \ Pause before additional lines
      dup 0>  if  exit?  if  1 throw  then  then  ( adr' len' flag )
   repeat                                ( adr',len' )
   r> 3drop
;

: parent-#size-cells  ( -- #size-cells )
   \ Root node has no parent, therefore the size of its parent's address
   \ space is meaningless
   root-device?  if  0  exit  then
   current-device >r  pop-device
   " #size-cells" get-property  if  1  else  get-encoded-int  then
   r> push-device
;
: my-#size-cells  ( -- #size-cells )
   " #size-cells" get-property  if  1  else  get-encoded-int  then
;
: size+  ( #cells -- #cells+#size-cells )  parent-#size-cells +  ;

vocabulary known-int-properties
also known-int-properties definitions

headers
: intr             ( -- n )  2  ;
: available        ( -- n )  '#adr-cells @ size+  ;
: reg              ( -- n )  '#adr-cells @ size+  ;
: existing         ( -- n )  '#adr-cells @ size+  ;
: ranges           ( -- n )  '#adr-cells @  #adr-cells + my-#size-cells +  ;
: dma-ranges       ( -- n )  ranges  ;
: address          ( -- n )  1  ;
: interrupts       ( -- n )  1  ;
: clock-frequency  ( -- n )  1  ;
: #size-cells      ( -- n )  1  ;
: dma              ( -- n )  5  ;

previous definitions

headerless
: show-strings  ( adr,len -- )
   begin  dup  while  decode-string  to-display-column type cr  repeat
   2drop
;
: display  ( anf adr len -- )
   rot  name>string   ( adr,len  name,len )

   2dup  " compatible"  $=  if  2drop show-strings  exit  then

   ['] known-int-properties (search-wordlist)  if
       execute .ints  exit
   then  ( adr,len )

   \ Test for unprintable characters
   2dup -null text?  if   
      to-display-column  -null  type  exit  
   then   ( adr,len )

   dup /n =  if  1 .ints   exit  then                              ( adr,len )

   to-display-column  h# 10 min  cdump                             ( )
;

: (.parents)  ( -- )  recursive
   root-device?  0=  if
      current-device  pop-device  (.parents)  push-device
      ." /"  .node-name
   then
;

: .not-devtree ( -- )
   ." Not at a device tree node. Use 'dev <device-pathname>'."
;
: (.property)  ( anf xt -- )  dup .name >r r@ get r> decode display  ;
: options?  ( -- flag )  current-properties  ['] options  =  ;
headers
: .property  ( "name" -- )  ' (.property)  ;
: .properties  ( -- )
   device-context?  if
      current-properties follow
      begin
         ??cr
	 another?
      while
         exit?  if  drop exit  then
	 dup name>  ['] (.property)  catch  if  2drop exit  then
      repeat
      \ In the options node, also display user-created environment variables
      options?  if
         null$  begin                      ( adr len )
            next-env-var  dup              ( adr' len' len' )
         while                             ( adr len )
            exit?  if  2drop exit  then    ( adr len )
            2dup type  to-display-column   ( adr len )
            2dup get-env-var drop type cr  ( adr len )
         repeat                            ( adr len )
         2drop                             ( )
      then
   else
      .not-devtree
   then
;
: ls  ( -- )
   device-context?  if
      'child token@                   ( first-node-voc )
      begin  non-null?  while         ( node-voc )
	 voc>phandle push-device      ( )
	 .nodeid                      ( )
	 'peer token@                 ( node-voc' )
	 pop-device                   ( )
      repeat                          ( )
   else
      .not-devtree
   then
;
: delete-my-children  ( -- )
   device-context?  if
      'child token@                   ( first-node-voc )
      begin  non-null?  while         ( node-voc )
	 voc>phandle dup push-device  ( node-phandle )
	 'peer token@                 ( node-phandle peer-voc )
	 pop-device                   ( node-phandle peer-voc )
         swap delete-package          ( peer-voc )
      repeat                          ( )
   then
;

headers

: (pwd)  ( -- )
   root-device?  if  ." /"  else  (.parents)  then
;
: pwd  ( -- )
   device-context?  if  (pwd)  else  .not-devtree  then   cr  
;
: .voc-name   ( a -- )
   dup device-node? if
      current-device phandle>voc  swap context token! (pwd) space  
      context token!
   else
      .name
   then
;
: order   (s -- )
   ." context: "
   get-order  0  ?do  .voc-name  loop
   cr  ." current: "  get-current .voc-name
;

headerless
: shownode  ( -- false )  exit?  if  true  else  pwd false  then  ;
: optional-arg-or-/$ ( -- adr len )
   parse-word dup 0=  if  2drop " /"  then  ( adr len )
;
headers
: $show-devs  ( adr len -- )
   locate-device  if  not-found throw  then
   push-package
      ['] shownode  ['] (search-preorder) catch 2drop
   pop-package
;
: show-devs  ( ["path"] -- )  optional-arg-or-/$ $show-devs  ;

: dev  ( -- )
   optional-arg-or-/$            ( adr,len )
   ?expand-alias                 ( adr,len )
   2dup " .." $=  if             ( adr,len )
      2drop device-context?  if  (  )
	 pop-device              (  )
      else                       (  )
	 .not-devtree            (  )
      then                       (  )
   else                          ( adr,len )
      find-device                (  )
   then                          (  )
;

: show-props  ( -- )
   current-device >r
   optional-arg-or-/$           ( adr len )
   find-device  .properties  device-end
   r> push-device
;
headerless
: show-aliases  ( -- )
   also  " /aliases" find-device  .properties  (  )
   previous definitions                        (  )
;
: show-alias  ( adr len -- )
   2dup " name" $= 0=  if     ( adr,len )
      ['] aliases $vfind  if  ( xt )
	 dup >name swap  (.property) cr exit
      then                    ( adr,len )
   then                       ( adr,len )
   type ."  : no such alias"  (  )
;
headers
: devalias  \ name string  ( -- )
   parse-word  parse-word
   dup  if                        ( name$ path$ )
      $devalias  (  )
   else                           ( name$ path$ )
      2drop dup  if               ( name$ )
	 show-alias               (  )
      else                        ( name$ )
	 2drop show-aliases       (  )
      then                        (  )
   then                           (  )
;

\ From instance.fth
purpose: Create, destroy, and call package instances

\ Creation and destruction of device instances.  Also package interface words.

headerless
create no-proc  ," Unimplemented package interface procedure"

headers
defer fm-hook  ( adr len phandle -- adr len phandle )
' noop is fm-hook

: find-method  ( adr len phandle -- false | acf true )
   fm-hook  phandle>voc (search-wordlist)
;

headerless
2variable error-method
0 value error-instance
0 value error-package	\ Undefined if error-instance is 0
headers
: .method  ( -- )
   ." Method: " error-method 2@ type  ."  Instance: " error-instance u.
   error-instance  if
      ." Package: " error-package push-package (pwd) pop-package
   then
   cr
;

headerless
: "open"  " open"  ;

headers
: $call-self  ( adr len -- )
   my-self  if
      my-voc  fm-hook phandle>voc $find-word  if  execute  exit  then
   then
   my-self to error-instance
   error-instance  if  my-voc  to error-package  then
   error-method 2! no-proc throw
;

[ifndef] package(
: package(  ( ihandle -- )  r> my-self >r >r  is my-self  ;
: )package  ( -- )  r> r> is my-self >r  ;
[then]

: call-package  ( ??? acf ihandle -- ??? )      package( execute    )package  ;
: $call-method  ( ??? adr len ihandle -- ??? )  package( $call-self )package  ;
: $call-parent  ( adr len -- )  my-parent $call-method  ;
: ihandle>phandle  ( ihandle -- phandle )       package( my-voc     )package  ;

headerless
: activate  ( -- )
   my-self  if
      my-self ihandle>phandle
      ?dup  if  push-package  else  ." Current instance " my-self . ." has 0 phandle!"  cr  then
   then
;
: deactivate  ( -- )  my-self  if  pop-package  then  ;

[ifdef] bug
also bug
'   activate to   set-package
' deactivate to unset-package
previous
[then]

headers
: $call-static-method  ( ??? adr len phandle -- ??? )
   find-method  0=  if  no-proc throw  then  execute
;

\ set-args is executed only during probing, at which time the active package
\ corresponds to the current instance, thus '#adr-cells can be executed
\ directly.

: set-args  ( arg-str reg-str -- )
   " decode-unit" $call-parent  '#adr-cells @  ( arg-str phys .. #cells )
   dup  if  swap  to my-space  1-   then       ( arg-str phys .. #cells' )
   addr my-adr0  swap /n* bounds  ?do  i !  /n +loop   ( arg-str )
   copy-args
;

: get-package-property  ( adr len phandle -- true | adr' len' false )
   (push-package)  get-property  (pop-package)
;

\ XXX - I think this could be implemented by   (push-package) (property) (pop-package)
: set-package-property  ( value$ name$ phandle -- )
   current token@ >r  context token@ >r   (select-package)  ( value$ name$ )
   (property)
   r> context token!  r> current token!
;

\ Used when executing from an open package instance.  Finds a property
\ associated with the current package.
: get-my-property  ( adr len -- true | adr' len' false )
   my-voc get-package-property
;

headerless
0 value interposer	\ phandle of interposing package, if any
0 value ip-arg-adr	\ arguments for interposing package
0 value ip-arg-len

false value pkg-interpose?	\ phandle of interposing package, if any

: interposed?  ( -- false | arg$ phandle true )
   interposer  if
      false to pkg-interpose?
      ip-arg-adr ip-arg-len  interposer  0 to interposer  true
   else
      false
   then
;

\ 0 value pip-arg-adr	\ arguments for interposing package
\ 0 value pip-arg-len

: package-interposed?  ( -- false | arg$ phandle true )
   pkg-interpose?  if  interposed?  else  false  then
;

headers
: interpose  ( args$ phandle -- )
   false to pkg-interpose?
   to interposer  to ip-arg-len  to ip-arg-adr
;
: package-interpose  ( args$ phandle -- )
   interpose
   true to pkg-interpose?
;

headerless
\ Internal factor of get-inherited-property.  This factoring is necessary
\ because we use "exit" to make the control flow easier.
: (get-any)   ( adr len -- true | adr' len' false )
   begin  my-self   while            ( adr len )  \ Search up parent chain
      my-voc phandle>voc current token!         ( adr len )
      2dup get-my-property  0=  if   ( adr len adr' len' )
         2swap 2drop false exit      ( adr' len' false )   \ Found
      then                           ( adr len )
      my-parent is my-self           ( adr len )
   repeat                            ( adr len )
   2drop true                        ( true )              \ Not found
;

headers
\ Finds a property associated with the current package or with one of
\ its parents.
: get-inherited-property  ( adr len -- true | adr' len' false )
   current token@ >r   my-self >r
   (get-any)
   r> is my-self  r> current token!
;

headerless
: ?close  ( -- )  " close"  ['] $call-self  catch  if  2drop  then  ;
headers
\ Close all the instances up the chain from ihandle to my-self.
\ This assumes that close-package is called from the same instance
\ from which open-package was called.  The reason for closing a
\ chain, instead of just one instance, is because open-package
\ could have created a chain as a result of interposition.
: close-package  ( ihandle -- )
   my-self  swap to my-self             ( end-ihandle )
   begin                                ( end-ihandle )
      dup my-self <>  my-self 0<>  and  ( end-ihandle more? )
   while                                ( end-ihandle )
      ?close                            ( end-ihandle )
      destroy-instance                  ( end-ihandle )
      \ destroy-instance sets my-self to the parent ihandle
   repeat                               ( end-ihandle )
   to my-self                           ( ) \ In case we bailed on a 0 ihandle
;
headerless
: close-parents  ( -- )
   begin  my-self  while  ?close destroy-instance  repeat
;
: close-chain  ( -- )  destroy-instance  close-parents  ;
headers
: close-dev  ( ihandle -- )  package(  close-parents  )package  ;

: parse/  ( $ -- head$ tail$ )  ascii /  left-parse-string  ;
: parse:  ( $ -- head$ tail$ )  ascii :  left-parse-string  ;
\ Extract the next (leftmost) component from the path name, updating the
\ path variable to reflect the remainder of the path after the extracted
\ component.
: parse-component  ( path$ first? -- path$ args$ devname$ package? )
   >r                             ( path$' component$ r: first? )
   parse/                         ( path$' component$ r: first? )
   dup 0=  if                     ( path$' component$ r: first? )
      \ The first character was a slash, so it's either the root node
      \ or a support package
      2drop                       ( path$' r: first? )
      r@  if                      ( path$' r: first? )
         \ This is the first path component, so it could be either
         \ the root node or a support package
         dup  if
            \ The rest of the string is not empty, so it could be either ...
	    2dup parse/           ( path$' tail$ head$ r: first? )
	    nip  if               ( path$' tail$ r: first? )
	       \ The next character was not a slash, so it must be the root.
	       \ Undo the last parse and return the root node specification.
	       2drop              ( path$' r: first? )
	       " "  " /" false    ( path$' args$ devname$ package? r: first? )
	    else                  ( path$' tail$ r: first? )
	       \ The next character was a slash, so it's a support package.
	       \ tail$ is path$ minus that slash, i.e. the new path$
	       2nip               ( path$'' r: first? )
	       parse/             ( path$' component$ r: first? )
	       parse:  true       ( path$ args$ devname$ package? )
	    then
         else
            \ The rest of the string was empty, so it must be the root.
            " "  " /" false       ( path$' args$ devname$ package? r: first? )
         then
      else                        ( path$' r: first? )
         \ This is not the first path component, so it
         \ must be a support package
         parse/                   ( path$' component$ r: first? )
         parse:  true             ( path$ args$ devname$ package? )
      then
   else
      \ The first character was not a slash, so the component is an
      \ ordinary device node
      parse:  false               ( path$ args$ devname$ package? )
   then
   r> drop
;

: apply-method  ( adr len -- no-such-method? )
   my-voc fm-hook  ['] $package-execute?  catch  ?dup  if  ( x x x errno )
      \ executing method caused an error
      nip nip nip                                   ( errno )
   then                                             ( ??? false | true | errno )
;

headerless

d# 64 buffer: package-name-buf

headers
: open-package  ( args$ phandle -- ihandle )  recursive
   push-package                              ( args$ )
   new-instance                              ( )
   "open" apply-method  if  false  then  if  ( )
      package-interposed?  if                ( arg$ phandle )
         open-package                        ( ihandle|0 )
         dup  0=  if  destroy-instance  then ( )
      else                                   ( )
         my-self  my-parent is my-self       ( ihandle )
      then                                   ( )
   else                                      ( )
      destroy-instance  0                    ( 0 )
   then                                      ( ihandle )
   pop-package                               ( ihandle )
;

defer load-package  ( name$ -- false  |  phandle true )
: no-load-package   ( name$ -- false )  2drop false  ;
' no-load-package is load-package

: find-package  ( name$ -- false  |  phandle true )
   dup 0=  if  true  else  over c@  ascii / <>  then  ( name$ relative? )
   if                                                 ( name$ )
      " /packages/" package-name-buf pack  $cat       ( )
      package-name-buf count                          ( name$' )
   then                                               ( name$' )
   2dup locate-device  if                             ( name$ )
      load-package                                    ( false | phandle true )
   else                                               ( name$ phandle )
      nip nip true                                    ( phandle true )
   then                                               ( false | phandle true )
;

: $open-package  ( arg$ name$ -- ihandle )
   find-package  if  open-package  else  2drop 0  then
;

: $delete-package  ( adr len -- )
   locate-device abort" Can't find package" delete-package
;

headers

: my-unit-bounds  ( -- end-adr start-adr )
   addr my-unit-low  '#adr-cells @ /n*  bounds
;
: set-my-unit  ( phys.hi .. phys.lo -- )
   my-unit-bounds  ?do  i !  /n +loop
;

: set-default-unit  ( -- )
   get-unit  if                         ( )
      '#adr-cells @  0  ?do  0  loop    ( phys.. )
   else                                 ( adr len )
      unit-str>phys-                    ( phys.. )
   then                                 ( phys.. )
   set-my-unit                          ( )
;

\ Set the my-unit fields in the instance record:
\ If an address was given in path component, use it
\ If not, use address in "reg" property of package
\ Otherwise, use 0,0
: set-instance-address  ( -- )
   unit#-valid?  if
      unit-bounds  ?do  i @  /n +loop  set-my-unit
   else
      set-default-unit
   then
;

headerless
: (apply-method)  ( adr len -- ??? )
   apply-method  if  close-chain no-proc throw  then    ( )
;
: (open-node)  ( -- )
   "open"  (apply-method)  0=  if          ( okay? )
      close-chain  true abort" open failed" ( )
   then
;
: open-node  ( -- ) recursive
   (open-node)
   interposed?  if                              ( arg$ phandle )
      push-package  new-instance  ['] open-node catch  pop-package  ( error? )
      throw
   then
;

: open-parents  ( parent-phandle end-phandle -- )   recursive
   \ Exit at null "parent" of root node
   2dup =  if  2drop exit  then

   over >parent swap  open-parents  ( phandle )

   push-device                      (  )
   " "  new-instance                (  )
   set-default-unit                 (  )
   open-node                        (  )
;

\ Open packages between, but not including, "phandle" and the active package
: select-node  ( path$ first? -- path$' )
   current-device >r                        ( path$ first? )
   parse-component  if                      ( path$ args$ devname$ )
      \ The path component is a support package
      find-package 0= throw                 ( path$ args$ my-phandle )
      push-device                           ( path$ args$ )
      new-instance                          ( path$ )
      r> push-device                        ( path$ )
   else                                     ( path$ args$ devname$ )
      \ The path component is an ordinary device node or the root node
      ['] noa-find-device  catch  ?dup  if  ( path$ args$ x x throw-code )
         close-parents  throw
      then                                  ( path$ args$ )
      current-device  parent-device  r> open-parents ( path$ args$ my-phandle )
      push-device                           ( path$ args$ )
      new-instance                          ( path$ )
      set-instance-address                  ( path$ )
   then
;

: (open-path)  ( path$ -- )
   0 to interposer
   ?expand-alias  true select-node                          ( path$ )
   begin  dup  while  open-node false select-node  repeat   ( path$' )
   2drop                                                    ( )
;
\ Open pathname components until the last one, and then apply the indicated
\ method to the last component.
: open-path  ( path$ -- )
   ?dup  if                                              ( path$ )
      \ Establish the initial parent
      also						 ( path$ )	
      dt-null to current-device                          ( path$ )
      ['] (open-path) catch  dup  if  nip nip  then      ( error? )
      previous definitions                               ( error? )
      throw                                              ( )
   else                                                  ( adr )
      not-found throw                                    (  )
   then                                                  (  )
;

headers

: begin-open-dev  ( path$ -- ihandle )
   0 package(  current-device >r

      \ Since "catch/throw" saves and restores my-self,
      \ my-self will be 0 if a throw occurred.

      ['] open-path catch  if  2drop  then
      my-self                                   ( ihandle )

   r> push-device  )package                     ( ihandle )
;

headerless

: (open-dev)  ( path$ -- )  open-path  open-node  ;

headers

: open-dev  ( adr len -- ihandle | 0 )
   0 package(  current-device >r

      \ Since "catch/throw" saves and restores my-self,
      \ my-self will be 0 if a throw occurred.

      ['] (open-dev) catch  if  2drop  then
      my-self                                   ( ihandle )

   r> push-device  )package                     ( ihandle )
;

headerless

: (execute-method)  ( path$ method$ -- false | ??? true )
   2swap  open-path  (apply-method)
;

headers

: execute-device-method  ( path$ method$ -- false | ??? true )
   0 package(  current-device >r       ( path$ method$ )
      ['] (execute-method)  catch  if  ( x x x x )
         2drop 2drop  false            ( false )
      else                             ( ??? )
         close-chain  true             ( ??? true )
      then                             ( false | ??? true )
   r> push-device  )package            ( false | ??? true )
;

\ Easier to use version of execute-device-method
\
\ ex:  apply  selftest  net
\
: apply ( -- ??? ) \ method { devpath | alias }
   safe-parse-word  safe-parse-word  ( method$ devpath$ )
   2swap  execute-device-method      ( ??? success? )
   0= abort" apply failed."          ( ??? )
;


h# 10 circular-stack: istack

\ select-dev opens a package, sets my-self to that ihandle, pushes the
\ old my-self on the instance stack, and pushes that package's vocabulary
\ on the search order.  unselect-dev undoes select-dev .

: iselect  ( ihandle -- )
   dup 0= abort" Invalid ihandle"  ( ihandle )
   my-self istack push  is my-self
   also my-voc  push-device
;
: iunselect  ( -- )  previous definitions  istack pop is my-self  ;
: select-dev  ( adr,len -- )  open-dev  iselect  ;
: begin-select-dev  ( adr,len -- )   begin-open-dev  iselect  ;

: select  ( "name" -- )  safe-parse-word select-dev  ;
: begin-select  ( "name" -- )  safe-parse-word begin-select-dev  ;

: unselect-dev  ( -- )   my-self  iunselect  close-dev  ;
: unselect  ( -- )  unselect-dev  ;

: begin-package  ( arg-str reg-str parent-str -- )
   select-dev  new-device  set-args
;

: end-package  ( -- )  finish-device  unselect-dev  ;

: support-package:  ( "name" -- )
   " /packages" find-device
   new-device
   safe-parse-word encode-string " name" property
;

: end-support-package  ( -- )  finish-device device-end  ;

defer skip-test?  ( phandle -- flag )
: no-skip  ( phandle -- false )  drop false  ;
' no-skip  to skip-test?

: (test-dev)  ( name,len -- )
   2dup  locate-device  if  ( name,len )
      ??cr  ." Device " type  ."  not found." cr exit
   then   ( name,len  phandle )

   dup  skip-test?  if
      ." This implementation does not support selftest for plug-in devices." cr
      drop type ."  is a plug-in device." cr
   then

   drop 2dup >r >r                        ( name,len )         ( r: len,name )
   " selftest" execute-device-method  if  ( test-result-flag ) ( r: len,name )
      ?dup  if                            ( error-code )       ( r: len,name )
	 cr  r> r> type space             ( error-code )
	 ." selftest failed. Return code = " .d cr  ( )
       else                               (  ) ( r: len,name )
	  r> r> 2drop                     (  )
       then                               (  )
    else                                  (  ) ( r: len,name )
       ??cr ." No selftest method for " r> r> type space cr
    then  true throw
;
: test-dev ( name,len -- )  ['] (test-dev) catch  if  2drop  then  ;

: test   \ device-specifier  ( -- )
   \ Get device specifier string
   parse-word  ( adr len )
   dup 0=  if
      ??cr ." No device name specified."
   else
      test-dev
   then
;

headerless
\ XXX This really needs to append the stuff to a given string buffer
: .instance-name  ( -- )
   " name" get-my-property  0=  if  get-encoded-string type  then
   my-unit  ." @"  .nh  ." ,"  .nh
   my-args  ?dup  if  ." :" type  else  drop  then
;
headers
: .path  ( ihandle -- )  recursive
   ?dup  if
      package(
         my-parent  ?dup  if   .path  ." /"  .instance-name  then
      )package
   then
;

headerless

: (execute-phandle-method)  ( method-adr,len phandle -- ??? )
   0 to unit#-valid?              ( method-adr,len phandle )
   dup >parent dt-null open-parents  ( method-adr,len phandle )
   push-device                    ( method-adr,len )
   " "  new-instance              ( method-adr,len )
   set-default-unit               ( method-adr,len )
   (apply-method)                 ( ???? )
;

headers
: open-phandle  ( phandle -- ihandle | 0 )
   0 package(                   ( phandle )
      current-device >r         ( phandle )
      0 to unit#-valid?         ( phandle )
      dt-null ['] open-parents catch  if  ( x x )
         2drop  0               ( 0 )
      else                      (   )
         my-self                ( ihandle )
      then                      ( ihandle | 0 )
      r> push-device            ( ihandle | 0 )
   )package                     ( ihandle | 0 )
;

: execute-phandle-method  ( method-adr,len phandle -- false | ??? true )
   3dup find-method  if  drop  else  false exit  then
   0 package(                                  ( method-adr,len phandle )
      current-device >r                        ( method-adr,len phandle )
      ['] (execute-phandle-method)  catch  if  ( method-adr,len phandle err-code )
         3drop false                           ( false )
      else                                     ( ??? )
         close-chain true                      ( ??? true )
      then                                     ( false | ??? true )
      r> push-device                           ( false | ??? true )
   )package                                    ( false | ??? true )
;

\ Creates a copy of the named package, placing the new clone in the device
\ tree as a child of the package that was active when $clone-node was called,
\ and makes the new clone the current instance and the active package.
: $clone-node  ( name$ -- )
   find-package 0= abort" No such node"  current-device  (clone)
;
headers

\ From comprop.fth
purpose:

: encode-ints  ( nn .. n1 n -- adr len )
   0 0 encode-bytes   rot  0  ?do  rot encode-int encode+  loop
;
: decode-ints  ( adr len n -- nn .. n1 )
   dup begin  ?dup  while              ( adr len n cnt )     ( r: phys.hi.. )
      >r >r  decode-int r> r> rot >r   ( adr' len' n cnt )   ( r: phys.hi... )
      1-                               ( adr' len' n cnt-1 ) ( r: phys.hi... )
   repeat                              ( adr' len' n )       ( r: phys.hi..lo )
   begin  ?dup  while                  ( adr' len' cnt )     ( r: phys.hi.. )
      r> swap 1-                       ( adr' len' phys.lo.. cnt-1 )
   repeat                              ( adr' len' phys.lo..hi )
;
: encode-phys  ( phys.lo..hi -- addr len )  my-#adr-cells encode-ints  ;

: decode-phys  ( adr len -- adr' len' phys.lo..hi )
   my-#adr-cells decode-ints
;

: encode-reg  ( phys.lo..hi size -- adr len )
   >r  encode-phys  r> encode-int encode+
;

headerless
\ The IEEE standard restricts the use of encode-reg to buses
\ with #size-cells=1 .  Therefore, the generalized code that
\ immediately follows is not strictly necessary; the simplified
\ version above is sufficient for IEEE compliance.

: my-parent-#size-cells  ( -- #size-cells )
   \ Root node has no parent, therefore the size of its parent's address
   \ space is meaningless
   my-voc  root-phandle =  if  0  exit  then

   " #size-cells"    my-parent ihandle>phandle  ( adr len phandle )
   get-package-property  if  1  else  get-encoded-int  then
;

headers
[ifdef] notdef
: n>r  ( nn .. n1 n -- )
   dup r>  swap  begin  ?dup  while   ( nn .. nm n retadr cnt )
      3 pick >r  1-                   ( nn .. nm+1 n retadr cnt-1 ) ( r: .. )
   repeat                             ( n retadr )
   swap >r >r                         ( )
;

: nr>  ( -- nn .. n1 )
   r> r> swap                                ( retadr n )
   begin  ?dup  while  r> -rot  1-  repeat   ( retadr )
   >r
;

: encode-reg  ( phys.lo..hi size.lo..hi -- adr len )
   my-parent-#size-cells n>r              ( phys.lo..hi )
   encode-phys                            ( adr len )
   nr>                                    ( adr len size.lo..hi n )
   my-parent-#size-cells  encode-ints     ( adr len adr1 len1 )
   encode+                                ( adr len )
;
[then]

: string-property   ( value-adr,len name-adr,len -- )
   2swap encode-string 2swap  property
;
: integer-property ( value  name-adr,len -- )
   rot encode-int 2swap property
;
: device-name  ( adr len -- )  " name" string-property  ;
alias nameprop device-name

: driver  ( adr len -- )   \ string is of the form: manufacturer,name
   ascii , left-parse-string                          ( after-, before-, )
   2swap  dup  if                                     ( man.-str name-str )
      device-name
      " manufacturer" string-property
   else                                               ( null-str name-str )
      2drop  device-name
   then
;
: device-type  ( adr len -- )  " device_type" string-property  ;

\ This is a handy tool for amending "compatible" properties.
\ It prepends the string on the stack to the beginning of the existing
\ "compatible" property, or creates the property if it doesn't exist.
: +compatible  ( compat$ -- )
   encode-string                        ( prop$ )
   " compatible" get-property  0=  if   ( prop$ old-prop$ )
      encode-bytes encode+              ( prop$' )
   then                                 ( prop$ )
   " compatible" property
;

headerless

: modelprop        ( adr len -- )  " model"       string-property  ;
: addrprop  ( a -- )  encode-int  " address" property  ;
: regprop  ( address space size -- )
   >r  encode-phys  r> encode-int encode+  " reg"  property
;

headers
: parse-int  ( adr len -- n )  dup  if  safe->number  else  2drop 0  then  ;

: parse-2int  ( adr len -- address space )
   ascii , left-parse-string     ( after-str before-str )
   parse-int  >r                ( after-str )
   parse-int  r>                ( address space )
;
headerless
: encode-ranges ( offs bustype  phys offset size -- adr len )
   >r >r >r  encode-phys  r> r> r> encode-reg  encode+
;
headers
: encode-phandle  ( name$ -- adr len )
   locate-device abort" encode-phandle - Can't find package"  encode-int
;

\ From finddisp.fth
purpose: 

\ Creates an alias for the full path of a given device.

headerless
variable 'fb-node  origin 'fb-node token!
: encode-bytes+  ( adr1 len1  adr2 len2  --  adr1 len1+len2 )
   encode-bytes encode+
;
: encode-number+  ( u adr,len -- adr,len' )
   push-hex
   rot  (u.)  encode-bytes+
   pop-base
;

: encode-unit+  ( phys .. adr,len -- adr,len' )
   " decode-unit" parent-device find-method  if  drop  else
      \ Parent has no decode-unit--therefore we're done.
      2>r
      '#adr-cells @  0  ?do  drop  loop
      2r> exit
   then

   " @" encode-bytes+ 2>r	           ( phys .. )          ( R: $ )

   " encode-unit"  parent-device           ( phys .. adr,len phandle ) ( R: $ )
   $package-execute?  if                       ( phys .. )          ( R: $ )

      2r>                                      ( phys .. adr,len )  ( R: )
      '#adr-cells @  if  encode-number+  then  ( phys .  adr,len' )
      '#adr-cells @ 1-  0 max  0  ?do          ( phys .. adr,len )
         " ,"  encode-bytes+                   ( phys .. adr,len' )
         encode-number+                        ( phys .  adr,len' )
      loop                                     ( adr,len )
   else                                        ( unit-str )         ( R: $ )
      2r> 2swap encode-bytes+                  ( adr,len' )         ( R: )
   then
;

: (pwd$)  ( adr len -- adr len' )  recursive
   root-device? 0=  if
      current-device >r  pop-device (pwd$)  r> push-device
      " /" encode-bytes+
      " name" get-property  0=  if                 ( adr len name-adr1,len1 )
         get-encoded-string encode-bytes+          ( adr len' )
      then                                         ( adr len )
      get-unit  0=  if                             ( adr len unit-adr1,len1 )
         2swap 2>r  unit-str>phys                  ( phys.lo..hi )
	 2r>  encode-unit+                         ( adr len' )
      then                                         ( adr,len' )
   then
;

h# 100 buffer: pwd-buf
\ adr len is the full path string.
: pwd$  ( -- adr len )
   0 0  encode-bytes        ( adr,len )
   root-device?  if         ( adr,len )
      " /"  encode-bytes+   ( adr,len' )
   else                     ( adr,len )
      (pwd$)                ( adr,len" )
   then                     ( adr,len )

   \ Free the dictionary space
   \ used to collect the names
   over here -  allot    ( adr,len )

   pwd-buf pack count    ( adr',len )
;

: make-node-alias  ( voc name-str -- )
   current-device >r  ( nodeid name-str )
   rot voc>phandle push-device    ( name-str )
   pwd$               ( name-str expansion-str )
   r> push-device     ( name-str expansion-str )
   $devalias          (  )
;

: (ihandle>devname) ( adr,len -- adr,len' ) recursive
   my-parent  if
      current-device >r
      my-voc push-device
      my-parent  package( (ihandle>devname) )package
\     " support" get-my-property  0=  if  2drop  r> push-device  exit  then
      " /" encode-bytes+

      \ Display interposed package names with an extra leading /
      parent-device  my-parent ihandle>phandle <>  if  " /" encode-bytes+  then

      " name" get-my-property  if  " "  else  1-  then  encode-bytes+   ( $ )

      2>r                                                           ( R: $ )

      'child get-token?  if
	 \ Has children so it is not a leaf node.
	 drop get-unit 	0= dup  if		 ( unit-str has-regs? )
            drop				 ( unit-str )
            unit-str>phys			 ( phys.lo .. phys.hi )
	    true				 ( phys .. true )
	 then					 ( [ phys .. ] has-regs? )
      else					 ( )
	 my-unit  true				 ( [ phys .. ] true )
      then					 ( [ phys .. ] has-regs? )

      2r> rot  if				 ( phys .. adr,len )  ( R: )
         encode-unit+                            ( adr,len' )

	 my-args dup  if                         ( adr,len args,len )
	    2swap  " :" encode-bytes+            ( args,len adr,len )
	    2swap  encode-bytes+                 ( adr,len )
	 else                                    ( adr,len args,0 )
	    2drop                                ( adr,len )
	 then                                    ( adr,len )
      then                                       ( adr,len )
      r> push-device
   then
;

headers
: ihandle>devname ( ihandle -- adr,len )
   0 0 encode-bytes
   rot package( (ihandle>devname) )package
   over here - allot
   pwd-buf pack count    ( adr',len )
;

: phandle>devname ( phandle -- adr,len )
   current-device >r  ( phandle )  ( r: phandle' )
   push-device  pwd$  ( adr,len )  ( r: phandle' )
   r> push-device     ( adr,len )
;
: .ichain  ( -- )  my-self ihandle>devname type  ;

also magic-device-types definitions
: display  ( -- )
   'fb-node token@ origin =  if  current-device phandle>voc  'fb-node token!  then
;
previous definitions

\ From sysnodes.fth
purpose: 

defer client-services

\ Create the standard system nodes

hex
\ debug devc
root-device  HERE TO packages-device \ mmo
   new-device				\ Node for software "library" packages
      " packages" device-name

      new-device     current-device-t phandle>voc  to client-services \ mmo
         " client-services" device-name
      finish-device

   finish-device  here to chosen-device \ mmo
   new-device				\ Reports firmware run-time choices
      " chosen" device-name
   finish-device

   new-device				\ Node describing the firmware
      " openprom" device-name
      0 0 " relative-addressing" property
      0 0 " aligned-allocator"	 property
   finish-device

   new-device				\ Node for configuration options
      ' options 'properties token!	\ "options" voc is node's property list
      " options" device-name
\ only forth \eof   zzzzzzzzzzzzzz
   finish-device

   new-device				\ Node for configuration options
      ' aliases 'properties token!	\ "options" voc is node's property list
      " aliases" device-name
   finish-device
device-end

headerless
\ "chosen-variable" is a convenient way to report the contents of a
\ variable in a "/chosen" property.  Example: stdout " stdout" chosen-variable
5 actions
action:  token@ execute @ encode-cell over here - allot  ;   \ get
action:  token@ execute >r get-encoded-cell r> !   ;         \ set
action:  token@ execute  ;                                   \ addr
action:  drop  ;
action:  drop  ;

: chosen-variable  ( acf adr len -- )
   " /chosen" find-device
      make-property-name token, use-actions
   device-end
;
action-adr-t to dochosen-variable

\ "chosen-value" is like chosen-variable, but with value semantics
\ variable in a "/chosen" property.  Example: stdout " stdout" chosen-variable
5 actions
action:  token@ execute encode-cell over here - allot  ;     \ get
action:  token@ >r get-encoded-cell r> 1 perform-action  ;   \ set
action:  token@ 2 perform-action  ;                          \ addr
action:  drop  ;
action:  drop  ;

: chosen-value  ( acf adr len -- )
   " /chosen" find-device
      make-property-name token, use-actions
   device-end
;
action-adr-t to dochosen-value

5 actions
\ Add NULL at the end of the string to the length
action:  token@ execute cscount 1+ ( adr len )  ;          \ get
action:  token@ execute >r cscount r> place-cstr drop  ;   \ set
action:  token@ execute  ;                                 \ addr
action:  drop  ;
action:  drop  ;

: chosen-string  ( acf adr len -- )
   " /chosen" find-package drop  push-package
      make-property-name token, use-actions
   pop-package
;
action-adr-t to dochosen-string

headers

\ From console.fth
purpose: Implements console character I/O

\ Input and output selection mechanism

headers
nuser stdin   0 stdin !
nuser stdout  0 stdout !

headerless
nuser pending-char
nuser char-pending?

\ mmo defer stdin-idle  ' noop is stdin-idle  \ Hook for power savings

: "read"   ( -- adr len )  " read"   ;	\ Space savings
: "write"  ( -- adr len )  " write"  ;	\ Space savings
: stdin-getchar  ( -- okay? )
   pending-char 1  "read" stdin @ $call-method  1 =
;
: console-key?  ( -- flag )
   char-pending? @  if
      true
   else
      stdin-getchar dup  if  char-pending? on  then  ( flag )
   then
;
: console-key  ( -- char )
   char-pending? @  if
      pending-char c@  char-pending? off
   else
      begin
         stdin-getchar
\ mmo         dup 0=  if  stdin-idle  then
      until
      pending-char c@
   then
;
nuser temp-char
: console-type  ( adr len -- )  "write" stdout @ $call-method  drop  ;
: console-emit  ( char -- )  temp-char c!  temp-char 1 console-type  ;

\ close the device if it is not the stdout device.
: ?close  ( ihandle|0 -- )
   ?dup  if
      stdout @  over  <>  if  close-dev  else  drop  then
   then
;
: has-method?  ( method-adr,len phandle -- flag )
   find-method  dup  if  nip  then  ( flag )
;
: .missing  ( routine-adr,len type-adr,len -- )
   ." The selected " type ."  device has no " type  ."  routine" cr
;

: pihandle=  ( phandle ihandle -- flag )
   dup  if  ihandle>phandle =  else  2drop false  then
;

: chosen-cell-property  ( n name-str -- )
   " /chosen" find-device
   \ XXX this eats up some space every time it's called ...
   \ We really want "set-encoded-cell"
      rot encode-cell  2swap (property)
   device-end
;
: set-stdin  ( ihandle -- )
   stdin @  swap stdin !			( old-ihandle )
   stdin @  " stdin" chosen-cell-property

   " install-abort" stdin @ $call-method	( old-ihandle )
   ?dup  if 					( old-ihandle )
      " remove-abort" 2 pick $call-method	( old-ihandle )
      close-dev
   then
;
headers
: input  ( pathname-adr,len -- )
   2dup locate-device  if
      type ."  not found." cr  exit
   else				      ( pathname-adr,len phandle )
      dup stdin @ pihandle=  if  3drop exit  then  \ Same device?
      "read" rot has-method?  if      ( pathname-adr,len )
	 open-dev ?dup  if				( ihandle )
            set-stdin
	 else
	    ." Can't open input device." cr  exit
	 then
      else			      ( pathname-adr,len )
	 2drop  "read" " input" .missing  exit
      then
   then
;

variable stdout-#lines		\ For communication with client program

' stdout-#lines  " stdout-#lines" mmochosen-variable

variable termemu-#lines		\ For communication with terminal emulator

\ Set #lines in /chosen node for client programs to read
: report-#lines  ( -- )
   termemu-#lines @ -1 <>  if   ( #lines )
      \ The terminal emulator package set termemu-#lines
      termemu-#lines @		( #lines )
   else                         ( #lines )

      \ termemu-#lines was not set, so check for a "#lines" property
      \ in the output device's package.

      " #lines"  stdout @ ihandle>phandle  get-package-property  if  ( )
         \ No "#lines" property; report "unknown"
         -1			( unknown-#lines )
      else			( adr len )
         \ Report the value of the "#lines" property
         get-encoded-cell	( #lines )
      then                      ( #lines )
   then                         ( #lines )
   stdout-#lines  !
;
: set-stdout  ( ihandle -- )
   stdout @  swap stdout !	( old-ihandle )
   ?close
   stdout @  " stdout" chosen-cell-property
   report-#lines
;
: output  ( pathname-adr,len -- )
   2dup locate-device  if               ( pathname-adr,len )
      type ."  not found." cr  exit
   else					( pathname-adr,len phandle )
      dup stdout @ pihandle=  if  3drop exit  then   \ Same device?
      "write" rot has-method?  if	( pathname-adr,len )
         -1 termemu-#lines !	\ Set value for terminal emulator to change
         \ Set behavior of "light" to default value, remembering the old
         \ value so we can restore it if the open fails.
         ['] light behavior -rot        ( xt pathname-adr,len )
         ['] cancel to light            ( xt pathname-adr,len )
	 open-dev ?dup  if		( xt ihandle )
            \ If a different behavior for "light" is appropriate, it will
            \ have been established during "open-dev" (e.g. by fb8-install)
            nip                         ( ihandle )
	    set-stdout
	 else                           ( xt )
            to light                    ( )
	    ." Can't open output device." cr  exit
	 then
      else                             ( pathname-adr,len )
	 2drop  "write" " output" .missing  exit
      then
   then
;

: io  ( pathname-adr,len -- )
   2dup input
   output
; 

\ For compatibility with Campus PROMs; allows you to type, for instance,
\ "keyboard input"
: keyboard   ( -- adr len )  " keyboard"  ;
: screen     ( -- adr len )  " screen"  ;
: ttya       ( -- adr len )  " ttya"  ;
: ttyb       ( -- adr len )  " ttyb"  ;

: console-io  ( -- )
   stdin  @ 0<>
   stdout @ 0<>  and  if
      char-pending? off
      ['] console-key?  is key?
      ['] console-key   is (key
      ['] console-emit  is (emit
      ['] console-type  is (type
   then
;
: ks-io  ( -- )  keyboard input  screen output  ;
: use-ks  ( -- )
   " keyboard" " input-device" $setenv
   " screen" " output-device" $setenv
;

\ From execall.fth
purpose: 

headerless

defer the-action    ( phandle -- )
: execute-action  ( -- false )
   current-device >r  the-action  false  r> push-device
;

\ "action-acf" is executed for each device node in the subtree
\ rooted at dev-addr,len , with current-device set to the
\ node in question.  "action-acf" can perform arbitrary tests
\ on the node to determine if that node is appropriate for
\ the action that it wished to undertake.

: scan-subtree  ( dev-addr,len action-acf -- )
   current-device >r                ( dev-addr,len action-acf r: phandle )
   ['] the-action behavior >r       ( dev-addr,len action-acf r: phandle xt )
   is the-action                    ( dev-addr,len r: phandle xt )
   find-device                      ( r: phandle xt )
   ['] execute-action  ['] (search-preorder)  catch  2drop  ( r: phandle xt )
   r> is the-action r> push-device  ( )
;

headerless

2variable method-name

\ do-method? is an action routine for "scan-subtree" that is used
\ by execute-all-methods.  For each device node, excluding the current
\ output device, that has a method whose name is given by method-name ,
\ that method is executed.

false value verbose-do-method?

: do-method?  ( -- )
   method-name 2@  current-device phandle>voc (search-wordlist)  if  ( xt )
      drop  pwd$                               ( path-adr,len )
      verbose-do-method?  if  2dup type cr  then
      method-name 2@  execute-device-method drop cr  (  )
   then                                              (  )
;   

headers

: execute-all-methods  ( dev-addr,len method-adr,len -- )
   method-name 2!
   ['] do-method?  scan-subtree
;

: flush-keyboard  ( -- )  begin  key?  while  key drop  repeat  ;
defer pause-message ( decisecs -- decisecs' )  ' noop to pause-message
defer hold-message
: (hold-message)  ( ms -- exit? )
   flush-keyboard
   d# 100 /                                              ( decisecs )
   begin  dup  while                                     ( decisecs )
      dup d# 10 /mod  swap  if  drop  else  (cr .d  then ( decisecs )
      d# 100 ms   1-                                     ( decisecs' )
      pause-message                                      ( decisecs )
      key?  if                                           ( decisecs )
         key h# 1b =  if                                 ( decisecs )
	    cr ." Selftest stopped from keyboard" cr     ( decisecs )
	    drop true  exit                              ( -- true )
	 then                                            ( decisecs )
      then                                               ( decisecs )
   repeat                                                ( decisecs )
   drop  false                                           ( false )
;
' (hold-message) to hold-message

: most-tests  ( -- exit? )
   " selftest"  current-device phandle>voc (search-wordlist)  if   ( xt )

      drop                                              ( )

      \ We only want to execute the selftest routine if the device has
      \ a "reg" property.  This eliminates the execution of selftest
      \ routines for "wildcard" devices like st and sd.

      " reg"  get-property  if  false exit  then 2drop  ( )

      \ We sometimes want to skip the testing of certain devices.
      current-device skip-test?  if  false exit  then   ( )

      ??cr ." Testing "  pwd
      " selftest"  current-device                 ( method-adr,len phandle )
      execute-phandle-method  if                  ( result )
         ?dup  if
            red-letters
            ??cr ." Selftest failed. Return code = " .d cr
            cancel
            d# 10000                              ( delay-ms )
         else
            green-letters
            ." Okay" cr
            cancel
            d# 2000                               ( delay-ms )
         then                                     ( delay-ms )
      else
         red-letters
         ." Selftest failed due to abort"  cr
         cancel
         d# 10000                                 ( delay-ms )
      then                                        ( delay-ms )
      hold-message                                ( exit? )
   else
      false                                       ( exit? )
   then                                           ( exit? )
;

: test-subtree  ( dev-addr,len -- )
   current-device >r                ( dev-addr,len r: phandle )
   find-device                      ( r: phandle )
   ['] most-tests  ['] (search-preorder)  catch  2drop  ( r: phandle )
   r> push-device                   ( )
;

: test-all  ( -- )
   optional-arg-or-/$
   test-subtree
;

\ From siftdevs.fth
purpose: Sift through the device-tree, using the enhanced display format.

only forth also hidden also definitions

only forth also definitions

\ From malloc.fth
purpose: Heap memory allocator

\ Forth dynamic storage managment.
\
\ By Don Hopkins, University of Maryland
\ Modified by Mitch Bradley, Bradley Forthware
\ Public Domain
\
\ First fit storage allocation of blocks of varying size.
\ Blocks are prefixed with a usage flag and a length count.
\ Free blocks are collapsed downwards during free-memory and while
\ searching during allocate-memory.  Based on the algorithm described
\ in Knuth's _An_Introduction_To_Data_Structures_With_Applications_,
\ sections 5-6.2 and 5-6.3, pp. 501-511.
\
\ init-allocator  ( -- )
\     Initializes the allocator, with no memory.  Should be executed once,
\     before any other allocation operations are attempted.
\
\ add-memory  ( adr len -- )
\     Adds a region of memory to the allocation pool.  That memory will
\     be available for subsequent use by allocate-memory.  This may
\     be executed any number of times.
\
\ allocate-memory  ( size -- adr false  |  error true )
\     Tries to allocate a chunk of memory at least size bytes long.
\     Returns error code and true on failure, or the address of the
\     first byte of usable data and false on success.
\
\ free-memory  ( adr -- )
\     Frees a chunk of memory allocated by malloc.  adr should be an
\     address returned by allocate-memory.  Error if adr is not a
\     valid address.
\
\ memory-available  ( -- size )
\     Returns the size in bytes of the largest contiguous chunk of memory
\     that can be allocated by allocate-memory .

vocabulary allocator
also allocator also definitions

headerless
8 constant #dalign	\ Machine-dependent worst-case alignment boundary

2 base !
1110000000000111 constant *dbuf-free*
1111010101011111 constant *dbuf-used*
decimal

\ : field  \ name  ( offset size -- offset' )
\    create over , +  does> @ +
\ ;

struct
   /n field >dbuf-flag
   /n field >dbuf-size
aligned
   0  field >dbuf-data
   /n field >dbuf-suc
   /n field >dbuf-pred
constant dbuf-min

\ In a multitasking system, the memory allocator head node should
\ be located in a global area, instead in the per-task user area.

dbuf-min ualloc user dbuf-head

: dbuf-data>  ( adr -- 'dbuf )  0 >dbuf-data -  ;

: dbuf-flag!  ( flag 'dbuf -- )   >dbuf-flag !   ;
: dbuf-flag@  ( 'dbuf -- flag )   >dbuf-flag @   ;
: dbuf-size!  ( size 'dbuf -- )   >dbuf-size !   ;
: dbuf-size@  ( 'dbuf -- size )   >dbuf-size @   ;
: dbuf-suc!   ( suc 'dbuf -- )    >dbuf-suc  !   ;
: dbuf-suc@   ( 'dbuf -- 'dbuf )  >dbuf-suc  @   ;
: dbuf-pred!  ( pred 'dbuf -- )   >dbuf-pred !   ;
: dbuf-pred@  ( 'dbuf -- 'dbuf )  >dbuf-pred @   ;

: next-dbuf   ( 'dbuf -- 'next-dbuf )  dup dbuf-size@ +  ;

\ Insert new-node into doubly-linked list after old-node
: insert-after  ( new-node old-node -- )
   >r  r@ dbuf-suc@  over  dbuf-suc!	\ old's suc is now new's suc
   dup r@ dbuf-suc!			\ new is now old's suc
   r> over dbuf-pred!			\ old is now new's pred
   dup dbuf-suc@ dbuf-pred!		\ new is now new's suc's pred
;
: link-with-free  ( 'dbuf -- )
   *dbuf-free*  over  dbuf-flag!	\ Set node status to "free"
   dbuf-head insert-after		\ Insert in list after head node
;

\ Remove node from doubly-linked list

: remove-node  ( node -- )
   dup dbuf-pred@  over dbuf-suc@ dbuf-pred!
   dup dbuf-suc@   swap dbuf-pred@ dbuf-suc!
;

\ Collapse the next node into the current node

: merge-with-next  ( 'dbuf -- )
   dup next-dbuf dup remove-node  ( 'dbuf >next-dbuf )   \ Off of free list

   over dbuf-size@ swap dbuf-size@ +  rot dbuf-size!     \ Increase size
;

\ 'dbuf is a free node.  Merge all free nodes immediately following
\ into the node.

: merge-down  ( 'dbuf -- 'dbuf )
   begin
      dup next-dbuf dbuf-flag@  *dbuf-free*  =
   while
      dup merge-with-next
   repeat
;

forth definitions

: msize  ( adr -- count )  dbuf-data>  dbuf-size@  dbuf-data>  ;

: >dbuf-header  ( adr -- 'dbuf )
   dbuf-data>                ( 'dbuf )
   dup dbuf-flag@ case       ( 'dbuf )
      *dbuf-used* of  endof  ( 'dbuf )
      *dbuf-free* of
         true abort" Freeing or resizing already-free memory"
      endof
      true abort" bad heap address."
   endcase                   ( 'dbuf )
;
: free-memory  ( adr -- )
   >dbuf-header  merge-down link-with-free
;

: add-memory  ( adr len -- )
   \ Align the starting address to a "worst-case" boundary.  This helps
   \ guarantee that allocated data areas will be on a "worst-case"
   \ alignment boundary.

   swap dup  #dalign round-up      ( len adr adr' )
   dup rot -                       ( len adr' diff )
   rot swap -                      ( adr' len' )
   #dalign round-down              ( adr' len'' )

   \ Set size and flags fields for first piece

   \ Subtract off the size of one node header, because we carve out
   \ a node header from the end of the piece to use as a "stopper".
   \ That "stopper" is marked "used", and prevents merge-down from
   \ trying to merge past the end of the piece.

   dbuf-data>                      ( 'dbuf-first #dbuf-first )

   \ Ensure that the piece is big enough to be useable.
   \ A piece of size dbuf-min (after having subtracted off the "stopper"
   \ header) is barely useable, because the space used by the free list
   \ links can be used as the data space.  If it's too small, we just
   \ exit, wasting the (miniscule amount of) memory.

   dup dbuf-min <  if  2drop exit  then

   \ Set the size and flag for the new free piece

   *dbuf-free* 2 pick dbuf-flag!   ( 'dbuf-first #dbuf-first )
   2dup swap dbuf-size!            ( 'dbuf-first #dbuf-first )

   \ Create the "stopper" header

   \ XXX The stopper piece should be linked into a piece list,
   \ and the flags should be set to a different value.  The size
   \ field should indicate the total size for this piece.
   \ The piece list should be consulted when adding memory, and
   \ if there is a piece immediately following the new piece, they
   \ should be merged.

   over +                          ( 'dbuf-first 'dbuf-limit )
   *dbuf-used* swap dbuf-flag!     ( 'dbuf-first )

   link-with-free
;

: allocate-memory  ( size -- adr false  |  error-code true )
   \ Keep pieces aligned on "worst-case" hardware boundaries
   #dalign round-up                 ( size' )

   >dbuf-data dbuf-min max          ( size )

   \ Search for a sufficiently-large free piece
   dbuf-head                        ( size 'dbuf )
   begin                            ( size 'dbuf )
      dbuf-suc@                     ( size 'dbuf )
      dup dbuf-head =  if           \ Bail out if we've already been around
         2drop 1 true exit          ( error-code true )
      then                          ( size 'dbuf-suc )
      merge-down                    ( size 'dbuf )
      dup dbuf-size@                ( size 'dbuf dbuf-size )
      2 pick >=                     ( size 'dbuf big-enough? )
   until                            ( size 'dbuf )

   dup dbuf-size@ 2 pick -          ( size 'dbuf left-over )
   dup dbuf-min <=  if              \ Too small to fragment?

      \ The piece is too small to split, so we just remove the whole
      \ thing from the free list.

      drop nip                      ( 'dbuf )
      dup remove-node               ( 'dbuf )
   else                             ( size 'dbuf left-over )

      \ The piece is big enough to split up, so we make the free piece
      \ smaller and take the stuff after it as the allocated piece.

      2dup swap dbuf-size!          ( size 'dbuf left-over) \ Set frag size
      +                             ( size 'dbuf' )
      tuck dbuf-size!               ( 'dbuf' )
   then
   *dbuf-used* over dbuf-flag!      \ Mark as used
   >dbuf-data false                 ( adr false )
;

: memory-available  ( -- size )
   0 >dbuf-data                     ( current-largest-size )

   dbuf-head                        ( size 'dbuf )
   begin                            ( size 'dbuf )
      dbuf-suc@  dup dbuf-head <>   ( size 'dbuf more? )
   while                            \ Go once around the free list
      merge-down                    ( size 'dbuf )
      dup dbuf-size@                ( size 'dbuf dbuf-size )
      rot max swap                  ( size' 'dbuf )
   repeat
   drop  dbuf-data>                 ( largest-data-size )
;

\ Head node has 0 size, is not free, and is initially linked to itself

: init-allocator  ( -- )
   *dbuf-used* dbuf-head dbuf-flag!
   0 dbuf-head dbuf-size!	\ Must be 0 so the allocator won't find it.
   dbuf-head  dup  dbuf-suc!	\ Link to self
   dbuf-head  dup  dbuf-pred!
;

previous previous definitions

\ Tries to allocate, and if that fails, requests more memory from the system

also allocator also

defer more-memory  ( request-size -- adr actual-size false | error-code true )

headerless
: allocate-memory  ( size -- adr false  |  error-code true )
   dup allocate-memory  if	      ( size error-code )
      \ No more memory in the heap; try to get some more from the system
      drop                            ( size )
      dup #dalign + >dbuf-data >dbuf-data
      more-memory  if                 ( size error-code )
         nip true                     ( error-code true )
      else                            ( size adr actual )
         add-memory                   ( size )
	 allocate-memory              ( adr false  |  error-code true )
      then                            ( adr false  |  error-code true )
   else                               ( size adr )
      nip false                       ( adr false )
   then                               ( adr false  |  error-code true )
;

: adjust-piece  ( size 'dbuf -- actual-size )
   dup dbuf-size@ 2 pick -          ( size 'dbuf left-over )
   dup dbuf-min <=  if              ( size 'dbuf left-over )
      \ The piece is too small to split, so we just remove the whole
      \ thing from the free list.

      drop nip                      ( 'dbuf )
      dup remove-node               ( 'dbuf )
      dbuf-size@                    ( actual-size )
   else                             ( size 'dbuf left-over )

      \ The piece is big enough to split up, so we shrink the
      \ free part by moving the header up.

      \ Compute address of new header
      3dup drop +  >r               ( size 'dbuf left-over r: 'dbuf1 )

      \ Prepare the new header
      *dbuf-free*  r@ dbuf-flag!    ( size 'dbuf left-over 'dbuf1 )
      r@ dbuf-size!                 ( size 'dbuf )
      dup dbuf-suc@  r@ dbuf-suc!   ( size 'dbuf )
      dbuf-pred@  r@ dbuf-pred!     ( size )

      \ Fix the free list to point to the new header instead of the old one
      r@  dup dbuf-suc@  dbuf-pred! ( size 'dbuf1 )
      r>  dup dbuf-pred@ dbuf-suc!  ( size )
   then
;

\ Returns true if adr is the address of a free buffer header.
\ It is tempting to just look for a *dbuf-free* signature at adr, but
\ that could fail if adr is at the end of the heap area and is not mapped.
: dbuf-free?  ( adr -- free? )
   \ Search for a sufficiently-large free piece
   dbuf-head                        ( adr 'dbuf )
   begin                            ( adr 'dbuf )
      dbuf-suc@                     ( adr 'dbuf )
      dup dbuf-head =  if           \ Bail out if we've already been around
         2drop false exit           ( false )
      then                          ( adr 'dbuf-suc )
      merge-down                    ( adr 'dbuf )
      2dup =                        ( adr 'dbuf match? )
   until                            ( adr 'dbuf )
   2drop true                       ( true )
;

: resize-memory  ( adr newlen -- adr' ior )
   \ Keep pieces aligned on "worst-case" hardware boundaries
   #dalign round-up  dbuf-min max  ( adr newlen' )

   swap >dbuf-header  >r           ( newlen r: 'dbuf )
   r@ dbuf-size@                   ( newlen old-size r: 'dbuf )

   \ If the new size is smaller than the old, just return success.
   \ It might be nice to give back the unused piece, but we can
   \ implement that later if it turns out to be needed.
   dbuf-data> 2dup <=  if          ( newlen old-dsize r: 'dbuf )
      2drop r> >dbuf-data 0        ( adr ior )
      exit
   then                            ( newlen old-dsize r: 'dbuf )

   \ If there is a sufficiently-large free piece following the old
   \ piece, then we can just extend the old piece "in place".
   dup >dbuf-data  r@ +            ( newlen old-dsize 'dbuf1 r: 'dbuf )
   dup dbuf-free?  if              ( newlen old-dsize 'dbuf1 r: 'dbuf )
      >r                           ( newlen old-dsize r: 'dbuf 'dbuf1 )
      2dup -                       ( newlen old-dsize need-size r: .. )
      r@ dbuf-size@                ( newlen old-dsize need-size size1 r: .. )
      <=  if                       ( newlen old-dsize r: .. )
         \ The piece is large enough
         tuck -                    ( old-dsize need-size r: .. )
         r> adjust-piece           ( old-dsize got-size  r: 'dbuf )
         + >dbuf-data  r@ dbuf-size!  ( r: 'dbuf )
         r> >dbuf-data 0              ( adr ior )
         exit
      then                         ( newlen old-dsize r: 'dbuf 'dbuf1 )
      r>                           ( newlen old-dsize 'dbuf1 r: 'dbuf )
   then                            ( newlen old-dsize 'dbuf1 r: 'dbuf )

   drop                            ( newlen old-dsize r: 'dbuf )

   \ We can't extend the existing piece, so we must get a new one
   \ and copy in the old data
   swap allocate-memory  if        ( old-dsize error-code r: 'dbuf )
      2drop  r> >dbuf-data -1      ( adr ior )
      exit
   then                               ( old-dsize adr1 r: 'dbuf )

   dup rot  r@ >dbuf-data -rot move   ( adr1 r: 'dbuf )
   r> >dbuf-data free-memory          ( adr1 )
   0
;

\ [ifdef] debug-mallocator
\ .( Memory allocator debug words are included) cr
: .previous  ( adr -- )
   begin  /n -  dup @  *dbuf-used* =  until
   ." Preceding used heap node at " .x cr
;
: check-node  ( 'dbuf -- )
   dup dbuf-flag@ *dbuf-free* <>  if
      ." Bad heap node at " dup .x
      .previous
      abort
   else
      drop
   then
;
: check-heap  ( -- )
   dbuf-head
   begin  dbuf-suc@ dup  dbuf-head <>  while  dup check-node  repeat
   drop
;

: .node  ( 'dbuf -- )
   push-hex
   dup 8 u.r  3 spaces
   dup dbuf-flag@  5 u.r
   dup dbuf-size@  9 u.r
   dup dbuf-suc@   9 u.r
   dbuf-pred@      9 u.r
   cr
   pop-base
;

: .heap  ( -- )
   dbuf-head
   begin  dbuf-suc@ dup  dbuf-head <>  while  dup check-node  dup .node  repeat
   drop
;
\ [then] \  debug-mallocator

previous  previous

: heap-alloc-mem  ( bytes -- adr )
   allocate-memory abort" Out of memory"
;

: heap-free-mem  ( adr size -- )  drop free-memory  ;

init-allocator

headers
h# 100000 constant 1meg

\ From instmall.fth
purpose: 

\ Install heap memory allocator.

defer initial-heap  ' no-memory is initial-heap

headerless
: no-more-memory  ( request-size -- adr actual-size false | error true )
   drop 0 true
;

: stand-init-io  ( -- )
   stand-init-io
   init-allocator
   initial-heap add-memory
   ['] no-more-memory is more-memory
   ['] heap-alloc-mem is alloc-mem
   ['] heap-free-mem  is free-mem
   ['] resize-memory  is resize
   ['] ofw-$getenv    is $getenv
;
\ From alarm.fth
purpose: Alarm dispatcher
\ alarm function.
\ To install an alarm:  ['] forth-function #msecs alarm
\ To uninstall alarm:   ['] forth-function 0      alarm
\
headerless
list: alarm-list
listnode
   /n  field  >time-out
   /n  field  >time-remain
   /n  field  >acf
   /n  field  >ihandle
nodetype: alarm-node

0 alarm-node !          \ Initialize to empty at compile time
0 alarm-list !          \ Initialize to empty at compile time

: show-alarm  ( node -- flag )
   dup >acf @ .name  d# 20 to-column  dup >ihandle @ 9 u.r
   dup >time-out @ d# 7 u.r  >time-remain @ d# 10 u.r  cr
   false
;
headers
: .alarms  ( -- )
   ." Action                Ihandle  Interval  Remaining" cr
   alarm-list  ['] show-alarm  find-node  2drop
;
headerless

\ Return flag will be true if the acf of the give node is equal to
\ the given acf.
: target-node?  ( ihandle acf node -- ihandle acf flag )
   2dup >acf @  =                 ( ihandle acf node flag )
   3 pick rot >ihandle @  = and   ( ihandle acf flag )
;


\ If a node with "acf" is already in the alarm-list, then just set the
\ time-out and time-remain with the new value "n"; else allocate a
\ new node and set up all fields with the given info.
: set-alarm-node	( ihandle acf n -- )
   \ convert n miliseconds to #clock-ticks.
   ms/tick /mod  swap 0<>  if  1+  then		( ihandle acf #clock-ticks )

   >r alarm-list ['] target-node? find-node	( ihandle acf prev next|0 )
   ?dup if					( ihandle acf prev next )
      nip					( ihandle acf next )
   else						( ihandle acf last-node )
      alarm-node allocate-node  		( ihandle acf last-node node )
      tuck swap insert-after			( ihandle acf node )
   then						( ihandle acf node )
   tuck >acf !					( ihandle node )
   r@ over >time-out !				( ihandle node )
   r> over >time-remain !			( ihandle node )
   >ihandle !                                   ( )
;


\ Search thru alarm-list, if node is found, then zero out the time-out
\ and time-remain field; else print out error message.
: turn-off-alarm 	( ihandle acf -- )
   lock[	\ Lock out the alarm handler while modifying the list.
   alarm-list ['] target-node? find-node  if	    ( ihandle acf prev )
      delete-after alarm-node free-node             ( ihandle acf )
      2drop                                         ( )
   else                                             ( ihandle acf prev )
      drop  ." No alarm was installed for " .h  cr  ( ihandle )
      drop                                          ( )
   then
   ]unlock
;


\ First check to see if the alarm is on (time-out >0).  If it is,
\ then check to see if the time is expired (time-remain = 0).
\ If time is not expired, decrement the time-remain.

: run-alarm 	( node -- )
   dup  >time-remain @  1- dup 0<=  if  ( node time-remain )
      drop  dup >time-out @  over       ( node time-out node )
      dup >acf @  swap >ihandle @       ( node time-out acf ihandle )
      ['] call-package  catch  if       ( node time-out acf ihandle )
	 2drop                          ( node time-out )
      then                              ( node time-out )
   then  swap >time-remain !            ( )
;

headers
\ We do this manually instead of using find-node because we need
\ to do >next-node before calling time-expired? in case the alarm
\ routine uninstalls itself, which could cause a crash if the
\ pointer to the next node were overwritten while being freed.
: check-alarm  ( -- )
   alarm-list  >next-node      ( node )
   begin  ?dup  while          ( node )
      dup >next-node  swap     ( next node )
      run-alarm                ( next )
   repeat                      ( )
;

: alarm 	( acf n -- )
   my-self -rot                 ( ihandle acf n )
   ?dup if  set-alarm-node  else  turn-off-alarm  then
;

\ From clientif.fth
purpose: Client interface handler

headerless
only forth also definitions
\
\  Client Interface Handler
\

headers
forth also definitions

: setnode  ( nodeid | 0 -- )
   dup 0=  if  drop root-phandle then  (push-package)
;

false value canonical-properties?
d# 32 buffer: canon-prop
: $find-property  ( adr len -- adr len false | acf true )
   canonical-properties?  if  d# 31 min canon-prop $save 2dup lower  then
   2dup current-properties (search-wordlist)  dup  if  2swap 2drop  then
;
\
\ Generic Client Interface Services
\

only forth  ( also hidden  also forth )  also
  definitions
headers
caps @ caps off

: child  ( phandle -- phandle' )
   setnode                           ( )
   0  'child                         ( last-nodeid &next-nodeid )
   begin  get-token?  while          ( last-nodeid next-nodeid )
      nip  dup voc>phandle (select-package)      ( next-nodeid )
      'peer                          ( last-nodeid' &next-nodeid )
   repeat                            ( last-nodeid' )
   (pop-package)                     ( nodeid )
   dup  if  voc>phandle  then
;

: peer  ( phandle -- phandle' )
   dup 0=  if
      drop root-phandle exit
   then                              ( nodeid )

   dup  root-phandle  =  if
      drop 0  exit
   then                              ( nodeid )

   \ Select the first child of our parent
   dup >parent (push-package)        ( nodeid )
   'child token@ voc>phandle (select-package)    ( nodeid )

   dup current-device  =  if         ( nodeid )
      \ Argument node is first child of parent; return "no more nodes"
      drop 0                         ( 0 )
   else                              ( nodeid )
      \ Search for the node preceding the argument node
      begin                          ( nodeid )
         'peer token@ voc>phandle 2dup  <>       ( nodeid next-nodeid flag )
      while                          ( nodeid next-nodeid )
         push-device                 ( nodeid )
      repeat                         ( nodeid )
      2drop current-device           ( nodeid' )
   then                              ( nodeid | 0 )
   (pop-package)                     ( nodeid | 0 )
;

: instance-to-package  ( ihandle -- phandle )  ihandle>phandle  ;

: milliseconds ( -- )  get-msecs   ;

: execute-buffer ( adr len -- )  'execute-buffer execute  ;
caps !

also forth definitions
alias child child	\ Make visible outside the client-services package
alias peer peer		\ Make visible outside the client-services package

only forth also definitions


previous definitions

\ From deladdr.fth
purpose: Delete stale address properties for virtual addresses
copyright: Copyright 1990-1994 Sun Microsystems, Inc.  All Rights Reserved

\ When freeing virtual memory, if the address property of the current
\ device refers to that virtual memory, delete the address property.

headerless
: ?delete-address  ( adr len -- adr len )
   my-self  if                                       ( adr len )
      my-voc (push-package)                          ( adr len )
      " address" get-property  0=  if                ( adr len value-adr,len )
         get-encoded-cell  2 pick  =  if             ( adr len )
            " address" delete-property               ( adr len )
         then                                        ( adr len )
      then                                           ( adr len )
      (pop-package)                                  ( adr len )
   then                                              ( adr len )
;
headers
: free-virtual  ( adr len -- )  ?delete-address  " map-out" $call-parent  ;

also hidden
: method-call?  ( xt -- flag )
   dup (indirect-call?)  if  drop true exit  then  ( xt )
   dup ['] $call-self =  if  drop true exit  then  ( xt )
   dup ['] $call-method =  if  drop true exit  then  ( xt )
   dup ['] $call-parent =  if  drop true exit  then  ( xt )
   dup ['] call-package =  if  drop true exit  then  ( xt )
   dup ['] $vexecute    =  if  drop true exit  then  ( xt )
   dup ['] $vexecute?   =  if  drop true exit  then  ( xt )
   dup ['] $package-execute? =  if  drop true exit  then  ( xt )
   dup ['] package-execute   =  if  drop true exit  then  ( xt )
   dup ['] apply-method      =  if  drop true exit  then  ( xt )
   dup ['] (apply-method)    =  if  drop true exit  then  ( xt )
   dup ['] (execute-method)  =  if  drop true exit  then  ( xt )
   dup ['] execute-device-method  =  if  drop true exit  then  ( xt )
   drop false
;
' method-call? to indirect-call?
previous

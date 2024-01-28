\ From date.fth
purpose: Time and date decoding functions

variable clock-node  ' clock-node  " clock" chosen-variable

: ofw-time&date  ( -- s m h d m y )
   " get-date" clock-node @ ihandle>phandle find-method  if
      drop
      " get-time" clock-node @  $call-method  swap rot
      " get-date" clock-node @  $call-method  swap rot
   else
      " get-time" clock-node @  $call-method
   then
;
stand-init:
   ['] ofw-time&date to time&date
;

headerless
: 2.d  ( n -- )   push-decimal  (.2)  type  pop-base  ;
: 4.d  ( n -- )   push-decimal  <# u# u# u# u# u#>  type  pop-base  ;

headers
: .date  ( d m y -- )   4.d ." -" 2.d ." -" 2.d  ;
: .time  ( s m h -- )   2.d ." :" 2.d ." :" 2.d  ;

\ Interactive diagnostic
: watch-clock  ( -- )
   ." Watching the 'seconds' register of the real time clock chip."  cr
   ." It should be 'ticking' once a second." cr
   ." Type any key to stop."  cr
   -1
   begin    ( old-seconds )
      begin
         key?  if  key drop  drop exit  then
         now 2drop
      2dup =  while   ( old-seconds old-seconds )
         drop
      repeat          ( old-seconds new-seconds )
      nip (cr now .time
   again
   drop
;

: watch-rtc
   begin 
      time&date .date ."  " .time (cr 500 ms
   key? until
   key drop
;

\ From fwfileop.fth
purpose: File I/O interface using Open Firmware

headerless
\ Closes an open file, freeing its descriptor for reuse.

: _ofclose  ( file# -- )
   bfbase @  bflimit @ over -  free-mem   \ Hack!  Hack!
   close-dev
;

\ Writes "count" bytes from the buffer at address "adr" to a file.
\ Returns the number of bytes actually written.

: _ofwrite  ( adr #bytes file# -- #written )  " write" rot $call-method  ;

\ Reads at most "count" bytes into the buffer at address "adr" from a file.
\ Returns the number of bytes actually read.

: _ofread  ( adr #bytes file# -- #read )  " read" rot $call-method  ;

\ Positions to byte number "l.byte#" in a file

: _ofseek  ( d.byte# file# -- )  " seek" rot $call-method  drop  ;

\ Returns the current size "l.size" of a file

: _ofsize  ( file# -- d.size )  " size" rot $call-method  ;

\ Prepares a file for later access.  Name is the pathname of the file
\ and mode is the mode (0 read, 1 write, 2 modify).  If the operation
\ succeeds, returns the addresses of routines to perform I/O on the
\ open file and true.  If the operation fails, returns false.


defer _ofcreate
: null-create  ( name -- 0 )  2drop 0  ;
' null-create to _ofcreate

defer _ofdelete
' 2drop to _ofdelete

: _ofopen
   ( name mode -- [ fid mode sizeop alignop closeop writeop readop ] okay? )
   >r count                                     ( name$  r: mode )
   r@ create-flag and  if                       ( name$  r: mode )
      2dup ['] _ofdelete catch  if  2drop  then ( name$  r: mode )
   then                                         ( name$  r: mode )

   2dup open-dev  ?dup  0=  if                  ( name$    r: mode )
      r@ r/o =  if                              ( name$    r: mode )
         0                                      ( name$ 0  r: mode )
      else                                      ( name$    r: mode )
         2dup _ofcreate                         ( name$ ih r: mode )
      then                                      ( name$ ih r: mode )
      ?dup 0=  if  r> 3drop  false exit  then   ( name$ ih r: mode )
   then                                         ( name$ ih r: mode )
   nip nip                                      ( ih       r: mode )
   r@   ['] _ofsize   ['] _dfalign   ['] _ofclose   ['] _ofseek
   r@ r/o  =  if  ['] nullwrite  else  ['] _ofwrite  then
   r> w/o  =  if  ['] nullread   else  ['] _ofread   then
   true
;

headers

: stand-init  ( -- )  stand-init  ['] _ofopen to do-fopen  ;

CR .( stand-init0=)
' stand-init DUP H. to 'stand-init0

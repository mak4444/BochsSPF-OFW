purpose: USB Data Packet Manipulation

hex
headers

\ XXX This code assumes the device and configuration descriptors are ok.

false value class-in-dev?

: find-desc  ( adr type -- adr' )
   swap  begin  ?dup  while		( type adr )
      dup 1+ c@ 2 pick =  if  0  else  dup c@ +  then
					( type adr' )
   repeat  nip				( adr )
;

: find-intf-desc  ( adr intfidx -- adr )
   swap  begin				( intfidx adr )
      INTERFACE find-desc		( intfidx adr' )
   swap ?dup  while			( adr intfidx )
      1- swap				( intfidx' adr )
      dup c@ +				( intfidx adr' )
   repeat
;

: unicode$>ascii$  ( adr -- actual )
   dup c@ 2 - 2/ swap 2 + over 0  ?do	( actual adr' )
      dup i 2* 1+ + c@ 0=  if		\ ASCII
         dup i 2* + c@			( actual adr c )
      else				\ Non-ascii
         ascii ?			( actual adr c )
      then
      over 2 - i + c!			( actual adr )
   loop  drop
;

\ XXX In the future, maybe we can decode more languages.
: encoded$>ascii$  ( adr lang -- actual )
   drop unicode$>ascii$
;

headers


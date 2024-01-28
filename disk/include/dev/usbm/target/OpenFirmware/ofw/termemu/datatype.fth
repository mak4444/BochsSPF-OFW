id: @(#)datatype.fth 1.4 00/04/25
purpose: Defines terminal-emulator-specific data types

headers

d# 34 value screen-#rows       \ EEPROM parameter
d# 80 value screen-#columns    \ EEPROM parameter

\ Used to prevent re-entering the terminal emulator from a keyboard abort
variable terminal-locked?  terminal-locked? off

headerless
\ Will be initialized to (escape-state in fwritestr.fth
defer escape-state	\ Forward reference

: >termemu-data  ( pfa -- adr )  @  my-termemu +  ;
: forth-create  ( -- )
   also forth definitions  create  previous definitions
;

headers

3 actions
action:  >termemu-data token@ execute  ;
action:  >termemu-data token!  ;
action:  >termemu-data token@  ;

: termemu-defer  \ name  ( -- )
   forth-create
   ['] crash /token  ( value data-size )
   use-actions value#, ( value adr )
   token!
;  action-adr-t to  dotermemu-defer  \ mmo

3 actions
action:  >termemu-data @  ;
action:  >termemu-data !  ;
action:  >termemu-data    ;

: termemu-value  \ name  ( initial-value -- )
   forth-create
   /n  ( value data-size )
   use-actions  value#,  ( value adr )
   !
;
action-adr-t to dotermemu-value \ mmo

3 actions
action:  >termemu-data swap na+ @  ;  ( index -- value )
action:  >termemu-data swap na+ !  ;  ( value index -- )
action:  >termemu-data swap na+    ;  ( index -- adr )

: termemu-array  \ name  ( #entries -- )
   forth-create              ( #entries )
   use-actions  /n* value#,  ( adr )
   drop
;


headers


\ Adapted from the version published in the ANS Forth spec.
\ That version was originally developed by Mitch Bradley.

defer headerless
defer headers


: [else]  ( -- )
   1  begin						( level )
      begin  parse-word dup  while			( level adr len )
         $canonical               			( level adr len )
         2dup s" [if]"     $=        >r			( level adr len )
         2dup s" [ifdef]"  $=  r> or >r			( level adr len )
         2dup s" [ifndef]" $=  r> or     if		( level adr len )
	    2drop 1+					( level' )
         else						( level adr len )
	    2dup  s" [else]"  $=  if			( level adr len )
	       2drop 1- dup  if  1+  then		( level' )
	    else					( level adr len )
	       s" [then]"  $=  if  1-  then		( level')
            then					( level' )
	    ?dup 0=  if  exit  then			( level' )
         then						( level' )
      repeat						( level adr len )
      2drop						( level' )
   refill 0= until					( level' )
   drop
; immediate

: [if]  ( flag -- )  0=  if  postpone [else]  then  ; immediate

: [then]  ( -- )  ;  immediate

: [ifdef]   ( "name" -- )  defined?      postpone [if]  ; immediate
: [ifndef]  ( "name" -- )  defined?  0=  postpone [if]  ; immediate

: \+  ( "name" "rest of line" -- )  defined?  0=  if   postpone \  then  ; immediate
: \-  ( "name" "rest of line" -- )  defined?  if  postpone \  then  ; immediate


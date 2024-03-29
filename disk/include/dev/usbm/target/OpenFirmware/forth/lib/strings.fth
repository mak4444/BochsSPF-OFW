
\ Primitives to concatenate ( "cat ), and print ( ". ) strings.
decimal
headerless

d# 260 buffer: string2

headers
: $number  ( adr len -- true | n false )
   $dnumber?  case
      0 of  true        endof
      1 of  false       endof
      2 of  drop false  endof
   endcase
;

headerless

\ A single to double helper.
\ Sign extends the single if signed? is true
: ?n>d  ( n signed? -- d )   if  s>d  else  0  then  ;

headers
: $dnumber  ( signed adr len -- true | d false )
   $dnumber?       ( signed 0 | signed n 1 | signed d 2 )
   case
      0 of  drop        true     endof
      1 of  swap ?n>d   false    endof
      2 of  rot drop    false    endof
   endcase
;

headerless
: $hnumber  ( adr len -- true | n false )  push-hex  $number  pop-base  ;
headers

\ Here is a direct implementation of $number, except that it doesn't handle
\ DPL, and it allows , in addition to . for number punctuation
\ : $number  ( adr len -- n false | true )
\    1 0 2swap                    ( sign n adr len )
\    bounds  ?do                  ( sign n )
\       i c@  base @ digit  if    ( sign n digit )
\        swap base @ ul* +        ( sign n' )
\       else                      ( sign n char )
\          case                   ( sign n )
\             ascii -  of  swap negate swap  endof    ( -sign n )
\             ascii .  of                    endof    ( sign n )
\             ascii ,  of                    endof    ( sign n )
\           ( sign n char ) drop nip 0 swap leave     ( 0 n )
\          endcase
\       then
\    loop                         ( sign|0 n )
\    over  if                     ( sign n )
\       * false                   ( n' false )
\    else                         ( 0 n )
\       2drop true                ( true )
\    then
\ ;

: $cat2  ( $1 $2 -- $3 )
   2 pick over +  dup >r alloc-mem >r
   2swap tuck  r@ swap move           ( $2 $1-len )
   r@ + swap move                     ( )
   r> r>
;

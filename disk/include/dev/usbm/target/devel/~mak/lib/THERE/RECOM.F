
REQUIRE THERE? ~mak/lib/THERE/mthere.f 

WARNING @ WARNING 0!
: , ( x -- ) \ 94
\ Зарезервировать одну ячейку в области данных и поместить x в эту ячейку.
  DP
 M_@
 4
 ALLOT
 !
 ;

: ,_ ( x -- ) \ 94
\ Зарезервировать одну ячейку в области данных и поместить x в эту ячейку.
 F7_ED
  DP
 M_@
 4
 ALLOT
 !
 ;

: I, , ;

: TI, \ F7_ED
 , ;

: C, ( char -- ) \ 94
\ З резервиров ть место для символ  в обл сти д нных и поместить туд  char.
  DP M_@
 1 ALLOT
 C!
 ;

: C,_ ( char -- ) \ 94
\ З резервиров ть место для символ  в обл сти д нных и поместить туд  char.
 F7_ED
  DP M_@
 1 ALLOT
 C!
 ;

: W, ( word -- )
\ Зарезервировать место для word в области данных и поместить туда char.
\  F7_ED
  DP M_@ 2 ALLOT W! ;

: +! ( N ADDR -- )	DUP @ ROT + SWAP ! ;

: 1+! ( ADDR -- )	1 SWAP +! ;

: PTYPE
  0 DO DUP C@ >PRT EMIT 1+ LOOP DROP
;

: MDUMP ( addr u -- ) DUMP ;

: DUMP ( addr u -- ) \ 94 TOOLS
  DUP 0= IF 2DROP EXIT THEN
  BASE M_@ >R HEX
  15 + 16 U/ 0 DO
    CR DUP 4 .0 SPACE
    SPACE DUP 16 0
      DO I 4 MOD 0= IF SPACE THEN
        DUP
        C@
        2 .0 SPACE 1+
      LOOP SWAP 16  PTYPE
  LOOP DROP R> BASE M_!
;
: MCOUNT COUNT ;
: COUNT DUP 1+ SWAP C@ ;

: CMOVE ( c-addr1 c-addr2 u --- )
\ Copy u bytes starting at c-addr1 to c-addr2, proceeding in ascending
\ order.

   DUP IF  >R
   BEGIN
    OVER 
 C@
 SWAP DUP >R
 C!
 R> 1+ SWAP 1+ SWAP
    R>  1- DUP  >R 0=
   UNTIL
   R>
   THEN
   2DROP DROP
;

: OFF 0 SWAP ! ; 
: On -1 SWAP ! ; 

: $+!       ( addr len dest -- ) \ append string addr,len to counted
                                     \ string dest
                >R "CLIP" MAX$@  R@ C@ -  MIN R>
                                        \ clip total to MAXCOUNTED string
                2DUP 2>R
                COUNT CHARS + SWAP CMOVE
                2R> +! ;

: COMPARE ( addr1 u1 addr2 u2 --- diff )
\ Compare two strings. diff is negative if addr1 u1 is smaller, 0 if it
\ is equal and positive if it is greater than addr2 u2.

  ROT 2DUP - >R        
  MIN DUP IF
   >R
   BEGIN
    OVER C@ OVER C@ - IF
     SWAP C@ SWAP C@ -  RDROP RDROP  EXIT
    THEN 
    1+ SWAP 1+ SWAP
    R> 1- DUP >R 0=
   UNTIL R>
  THEN DROP
  DROP DROP R> NEGATE
;

WARNING !


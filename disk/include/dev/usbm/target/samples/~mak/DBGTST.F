REQUIRE Q-DBG samples\~mak\dbgwc.f 

<DBG> 

samples\~mak\YYY.F

: HASH4 ( addr u u1 -- u2 )
   2166136261 2SWAP
   OVER + SWAP 
   DO  16777619 * I C@ XOR
   LOOP
   SWAP ?DUP
   IF UMOD
   THEN   
;

: ZZZ 
  ['] + 1000 8  \ DBG-POINT
  HASH4 .
  6 ." Z"
 7  ." W"
 8  ." E"
  . . .
;

: XXX
CR ." F11 переход по форт-слову как по гиперссылке   F12 возврат" 
  77777
 ( Press F7)
 DROP
 ZZZ
 6 ." T"
 7 ." Y"
 8 ." U"
 . . .
  YYY
  6
  7
 8
 . . .
;

<\DBG>

:NONAME ( -- flag ) ?NO_DBG
 CR ." DBG " DUP H.
 DUP 77777 =
; Q-DBG

 XXX
E> +

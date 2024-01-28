
0x20000 VALUE T-ORG                \ Начальный целевой адрес области кода
0x21000 VALUE D-ORG                \ Начальный целевой адрес области данных
0x01000 VALUE CODE-SIZE            \ Размер области кода
0x01000 VALUE DATA-SIZE            \ Размер области данных
VARIABLE T-DP                 \ инструментальный указатель кода
VARIABLE D-DP                 \ целевой указатель данных

[IFNDEF] TC_?LIMIT
0 VALUE MAX_HERE

\ DIS-OPT

: [F] ALSO FORTH ; IMMEDIATE
: [P]  PREVIOUS ; IMMEDIATE

: TC_?LIMIT
   DUP 
 MAX_HERE
   U< 
 0= 
  ABORT" The code limit has reached!"
 ;
[THEN]

REQUIRE T_@ ~mak/lib/THERE/there.f

[UNDEFINED] T>
[IF] 

0 VALUE  TH_H-

\ : [>T] TH_H- + ; : [>T]  ; IMMEDIATE

: T> 
   TC_?LIMIT
 TH_H-
 -
  ;

[THEN]

: &T_C! ( c addr -- ) 
\ f7_ed
    T>
 C!
 ;

: &T_C@ (  addr -- c ) 
    T> C@ ;

: &T_! ( c addr -- ) 
    T> ! ;

: &T_+! ( c addr -- ) 
    T> +! ;

: &T_@ (  addr -- c ) 
    T> @ ;

: &T_2! ( c addr -- ) 
    T> 2! ;

: &T_2@ (  addr -- c ) 
    T> 2@ ;

: &T_W! ( c addr -- ) 
    T> W! ;

: &T_W@ (  addr -- c ) 
    T> W@ ;

: TREAD-FILE  2>R T> 2R> READ-FILE ;
: TWRITE-FILE 2>R T> 2R> WRITE-FILE ;

: T-INIT
\ 4 HERE 3 AND - ALLOT \ выравнивание на 4
\ F7_ED
 T-ORG
 CODE-SIZE DATA-SIZE +
 ALLOCATE
 THROW 
 - TO TH_H-
 T-ORG T-DP !
 D-ORG D-DP !
 T-ORG CODE-SIZE + TO MAX_HERE
 T-ORG T> CODE-SIZE 0xFF FILL
;

: RE-ORG ( taddr -- )
  DUP T-ORG T> - TO TH_H- TO T-ORG ;


0xFF CELLS CONSTANT TEB_SIZE

CREATE TEXEC_BUF ' ABORT DUP , , TEB_SIZE ALLOT
CREATE TEXEC_KEY       0 , 0 , TEB_SIZE ALLOT

: &T_EXECUTE
  F7_ED
  TEXEC_KEY CELL-
  BEGIN CELL+
 2DUP @ 
 2DUP U>
 ABORT" BAD TEXECUTE"
 =
 UNTIL
	NIP
	TEXEC_KEY -
	TEXEC_BUF 
+
 @
\ dup rest
EXECUTE
;

: MEM_MODE
['] &T_C! TO T_C!
['] &T_W! TO T_W!
['] &T_C@ TO T_C@
['] &T_W@ TO T_W@
['] &T_!  TO T_!
['] &T_@  TO T_@
['] &T_2! TO T_2!
['] &T_2@ TO T_2@
['] &T_EXECUTE TO T_EXECUTE
['] NOOP  TO MAIN_S
 ;

MEM_MODE

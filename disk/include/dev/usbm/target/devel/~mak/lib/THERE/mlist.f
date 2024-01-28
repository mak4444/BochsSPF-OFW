REQUIRE PLACE  ~mak/place.f 
REQUIRE [IF] ~mak/CompIF.f

C" STREAM-FILE" FIND NIP
[IF]
: FROM_SOURCE-ID SOURCE-ID  STREAM-FILE ;
: TO_SOURCE-ID FILE>RSTREAM TO SOURCE-ID ;
[ELSE]
: FROM_SOURCE-ID SOURCE-ID ;
: TO_SOURCE-ID TO SOURCE-ID ;
[THEN]

C" -CELL" FIND NIP 0=
[IF] -1 CELLS CONSTANT -CELL
[THEN]

[IFNDEF] HERE-TAB-CUR VARIABLE HERE-TAB-CUR
[THEN]

[IFNDEF] SHERE-TAB-CUR VARIABLE SHERE-TAB-CUR
[THEN]

[IFNDEF] H.
: H.           ( u -- )
                BASE @ >R HEX U.
                R> BASE ! ;
[THEN]

[IFNDEF] H.R
: H.R           ( n1 n2 -- )    \ display n1 as a hex number right
                                \ justified in a field of n2 characters
                BASE @ >R HEX >R
                0 <# #S #> R> OVER - 0 MAX SPACES TYPE
                R> BASE ! ;
[THEN]


[IFNDEF] MINST
: HH.+  DUP C@ 2 H.R ."  " 1+ ;
: INST.+
 HH.+ ;

: MINST ( ADDR1 ADDR2 --  ADDR1 ADDR1 )
\ F7_ED
  DUP H. 9 EMIT INST.+
	BEGIN  2DUP U> 
	WHILE  DUP 7 AND 0= IF CR DUP H. 9 EMIT THEN
                INST.+
	REPEAT ;
[THEN]

MODULE: AVRLIST

CREATE  FILE_NAME_L 120 ALLOT

CREATE   HERE-TAB  8000 CELLS ALLOT
HERE CELL-  CONSTANT HERE-TAB-MAX
HERE-TAB HERE-TAB-CUR !
VARIABLE S_STATE 

: HERE-TAB-CUR+
  HERE-TAB-CUR @  CELL+ HERE-TAB-MAX UMIN
  HERE-TAB-CUR
 !
\ [ .( XXXX) DIS-OPT KEY DROP ]
 ;

: HERE-TO-TAB \ F7_ED
 DP @
 HERE-TAB-CUR
 @
 !
 HERE-TAB-CUR+
 ;


CREATE   SHERE-TAB  700 CELLS ALLOT
HERE CELL-  CONSTANT SHERE-TAB-MAX
SHERE-TAB SHERE-TAB-CUR !

: SHERE-TAB-CUR+
  SHERE-TAB-CUR @  CELL+ SHERE-TAB-MAX UMIN
  SHERE-TAB-CUR ! ;

: SHERE-TO-TAB DP @ SHERE-TAB-CUR @ ! SHERE-TAB-CUR+ ;

80 VALUE DUMP_MAX 


: .LIST ( ADDR  ADDR1 -- ADDR1' ) 
\          CR H. EXIT
          S_STATE @ DROP 1
          IF
             SWAP
             BEGIN  2DUP U> 
             WHILE  MINST CR
             REPEAT  NIP
          ELSE
            TUCK   
            OVER - DUP
            IF   DUP DUMP_MAX U>

                IF  >R DUMP_MAX DUMP 
                    CR DUP U.  R> DUMP_MAX - U. ." bytes"
                ELSE  DUMP
                THEN CR
            ELSE 2DROP
            THEN
          THEN
;

VECT INCLUDED$

' INCLUDED TO INCLUDED$

EXPORT

: CON_EMIT
   H-STDOUT >R  [ H-STDOUT LIT, ] TO H-STDOUT EMIT
   R> TO H-STDOUT ;

 24000 VALUE NMEG

: STCR_
     SOURCE TYPE CR ; 

VECT STCR
' STCR_ TO STCR

HERE S" _AL" S", VALUE C"_AL"

0 VALUE INCL-HH

: INCLUDED_AL
 HERE TO INCL-HH
\ F7_ED
   ['] <PRE> >BODY @ >R
   ['] HERE-TO-TAB TO <PRE>
     HERE-TAB  HERE-TAB-CUR !
    SHERE-TAB SHERE-TAB-CUR ! 
  2DUP 2>R
  INCLUDED$ 
 2R>  R> TO <PRE>
 -1 SHERE-TAB-CUR @ !  SHERE-TAB-CUR+
    HERE-TO-TAB 
    HERE-TO-TAB       -CELL HERE-TAB-CUR +!
    HERE-TAB-CUR @ @  -CELL HERE-TAB-CUR +!
    BEGIN HERE-TAB-CUR @ HERE-TAB <>
    WHILE  HERE-TAB-CUR @ @ UMIN DUP HERE-TAB-CUR @ !
          -CELL HERE-TAB-CUR +!
    REPEAT DROP
    S_STATE 0!
    SHERE-TAB SHERE-TAB-CUR ! 

    2DUP FILE_NAME_L  PLACE
  C"_AL" COUNT FILE_NAME_L +PLACE  
\  S" _AL"  FILE_NAME_L +PLACE  
  R/O OPEN-FILE-SHARED  THROW
  FILE_NAME_L COUNT 2DUP + 0!
\   2DUP TYPE
  W/O CREATE-FILE-SHARED THROW

  TIB >R >IN M_@ >R #TIB M_@ >R SOURCE-ID >R BLK M_@ >R CURSTR M_@ >R
  H-STDOUT >R  BASE M_@ >R HEX
  C/L 2 + ALLOCATE THROW TO TIB  BLK 0!
\ DROP  F7_ED \
  TO H-STDOUT

  TO_SOURCE-ID
  CURSTR 0! HERE-TAB-CUR @ @
  BEGIN    REFILL
  WHILE \ [CHAR] * CON_EMIT
        STCR
        BEGIN  SHERE-TAB-CUR M_@ M_@ HERE-TAB-CUR M_@ CELL+ M_@ U<
        WHILE  SHERE-TAB-CUR M_@ M_@ .LIST   SHERE-TAB-CUR+
                 S_STATE @ INVERT S_STATE !
        REPEAT  HERE-TAB-CUR+ HERE-TAB-CUR @ @ .LIST
  REPEAT  DROP
  TIB FREE THROW
  FROM_SOURCE-ID
 CLOSE-FILE THROW ( ошибка закрытия файла )
   H-STDOUT CLOSE-FILE THROW ( ошибка закрытия файла )
  R> BASE M_! R> TO H-STDOUT
  R> CURSTR M_! R> BLK M_! R> TO SOURCE-ID R> #TIB M_! R> >IN M_! R> TO TIB
 CR FILE_NAME_L COUNT TYPE 9 EMIT HERE INCL-HH -
 DUP NMEG  U> IF ." MEG=" THEN
 . HERE  H.

;

: REQUIRED_AL ( waddr wu laddr lu -- )
  2SWAP SFIND
  IF DROP 2DROP EXIT
  ELSE 2DROP INCLUDED_AL THEN
;
: REQUIRE_AL ( "word" "libpath" -- )
  BL PSKIP BL PARSE
  BL PSKIP BL PARSE 2DUP + 0 SWAP C!
  REQUIRED_AL
;

;MODULE

\EOF
: : : SHERE-TO-TAB ;

: ; POSTPONE ; SHERE-TO-TAB ; IMMEDIATE

: SSSS
     HERE-TAB  HERE-TAB-CUR !
    SHERE-TAB SHERE-TAB-CUR ! 
;

\ Mihail Maksimov, forth@inbox.ru
REQUIRE F7_EDIT samples\~mak\WIN\EDIT\ed.f 

REQUIRE <DBG> ~mak\LIB\dbg.f 
REQUIRE CEQUAL-U lib\ext\caseins.f

[IFNDEF] .S  : .S ( -- )    DEPTH .SN ;
[THEN]

MODULE: DBG_MOD

' 2DROP VALUE DBG_DO_
CREATE debugTIB 80 CHARS ALLOT
: eval_debug_statements ( -- )
  \ A simple outer interpreter for interactive input at
  \ debugtime.
   BEGIN
     CR ." D>" debugTIB DUP 80 ACCEPT DUP
   WHILE
     ['] EVALUATE CATCH
     IF ." Oops!?" CR 2DROP
     THEN
   REPEAT
   2DROP ;

0 VALUE DBG_RP@
0 VALUE DBG_Y
CREATE DBG_FILE 200 ALLOT

0 VALUE NNNN

: F7_DO  ['] 2DROP TO DBG_DO
  RP@ TO DBG_RP@
  NEXT_F COUNT EDIT_FN!  EDIT
  >R
  BEGIN BEGIN BEGIN
      GUI-CONSOLE::clhwnd PUSH-WINDOW DROP
      CR \ NNNN NNNN . 1+ TO NNNN
      ." S=" .S CR \ KEY? DROP  \ 1000 PAUSE
      EdHWnd PUSH-WINDOW DROP
     EMyhwnd PUSH-WINDOW DROP

\      GUI-CONSOLE::FlushJetBuf
      R@  EDIT_Y_SET
      FALSE TO ED_WATE
      BEGIN 500 PAUSE ED_WATE UNTIL
      ED_WATE cmdABORT = IF -28 THROW THEN
      ED_WATE cmdHEX   = 
  WHILE  HEX    REPEAT
      ED_WATE cmdDEC   = 
  WHILE DECIMAL  REPEAT
      ED_WATE cmdFORTH = 
  WHILE
      GUI-CONSOLE::clhwnd PUSH-WINDOW DROP
      eval_debug_statements
  REPEAT 
  RDROP
  DBG_DO_ TO DBG_DO
;

: F8_DO  RP@ DBG_RP@  U< 
  IF 2DROP  EXIT THEN 
  ['] F7_DO >R ;

: F4_DO
  OVER DBG_Y <>
  IF 2DROP  EXIT THEN
  DUP COUNT 2DUP TYPE  SPACE
 DBG_FILE COUNT  2DUP TYPE
 CEQUAL-U 0=
  IF 2DROP  EXIT THEN
   ['] F7_DO >R
;

: F4_EDIT_  EDIT_Y_GET TO  DBG_Y
            EDIT_FN COUNT DBG_FILE $!
           ['] F4_DO TO DBG_DO_ ;
: F6_EDIT_ DBG_RP@ CELL+ TO DBG_RP@
           ['] F8_DO TO DBG_DO_ ;
: F7_EDIT_ ['] F7_DO TO DBG_DO_ ;
: F8_EDIT_ ['] F8_DO TO DBG_DO_ ;
: F9_EDIT_ ['] 2DROP TO DBG_DO_ ;

' F4_EDIT_ TO F4_EDIT  
' F6_EDIT_ TO F6_EDIT  
' F7_EDIT_ TO F7_EDIT  
' F8_EDIT_ TO F8_EDIT  
' F9_EDIT_ TO F9_EDIT  

0 VALUE V_DBG_RP@

EXPORT

: S_DBG_RP@ RP@ TO V_DBG_RP@ ;
: R_DBG_RP@ DBG_RP@ V_DBG_RP@ - RP@ + TO DBG_RP@ ;

0 VALUE MMMM

: DBG_POST DBG_COUNT @ 1 OR
  IF  POSTPONE POSTPONE
  ELSE  MMMM IF  ABORT THEN
         NextWord 2DROP
  THEN ; IMMEDIATE

: F4_ED  F4_EDIT DBG_DO_ TO DBG_DO ;
: F6_ED  F6_EDIT DBG_DO_ TO DBG_DO ;
: F7_ED  F7_EDIT DBG_DO_ TO DBG_DO ;
: F8_ED  F8_EDIT DBG_DO_ TO DBG_DO ;
: F9_ED  F9_EDIT DBG_DO_ TO DBG_DO ;

F9_ED

VECT Q-DBG-VECT

' FALSE TO Q-DBG-VECT

: Q-DBG_DO 
   COUNT DBG_FILE $!
   TO DBG_Y 
  ['] DBG_DO >BODY @ >R
  ['] 2DROP TO DBG_DO
  Q-DBG-VECT
  R> TO DBG_DO
  IF  F7_EDIT  F7_ED
  THEN  
;

: Q-DBG  ( cfa -- )
 TO  Q-DBG-VECT   ['] Q-DBG_DO TO DBG_DO ;

: DBG-POINT 
  CURSTR @ 1- 0 MAX TO DBG_Y
  DBG_CURFILE COUNT DBG_FILE $!
  ['] F4_DO TO DBG_DO
;  IMMEDIATE


: R>	DBG_POST S_DBG_RP@ POSTPONE R>
	DBG_POST R_DBG_RP@ ; IMMEDIATE

: >R	DBG_POST S_DBG_RP@ POSTPONE >R
	DBG_POST R_DBG_RP@ ; IMMEDIATE

: RDROP	DBG_POST S_DBG_RP@ POSTPONE RDROP
	DBG_POST R_DBG_RP@ ; IMMEDIATE

: {	DBG_POST S_DBG_RP@ POSTPONE {
	DBG_POST R_DBG_RP@ ; IMMEDIATE

: : : DBG_COUNT @ IF DBG_<PRE> THEN ;

;MODULE


: ZZZ ;


REQUIRE TC_?LIMIT ~mak/lib/THERE/STAT.f

[IFNDEF] BREAK : BREAK  POSTPONE EXIT POSTPONE THEN ; IMMEDIATE  [THEN]

: THERE?_
 IMAGE-BEGIN
 TlsIndex@
 UMIN
 TIB
 UMIN
 U< 
 ;

VECT THERE?
' THERE?_ TO THERE?

TlsIndex@ IMAGE-BEGIN U< CR .( TI=) DUP U. 0 AND
[IF] CREATE OPER
  USER-OFFS @ EXTRA-MEM @ CELL+ + ALLOT
  TlsIndex@ OPER USER-OFFS @ EXTRA-MEM @ CELL+ + CMOVE
  CONTEXT TlsIndex@ - OPER + ' CONTEXT >BODY @ OPER + !
  OPER TlsIndex!
  CR .( TIB=) TIB U.
[THEN]


VECT T_C!
VECT T_C@
VECT T_W!
VECT T_W@
VECT T_! 
VECT T_+!
VECT T_@	
VECT T_2!
VECT T_2@
VECT T_EXECUTE
VECT MAIN_S


WARNING @ WARNING 0!
 
: C! DUP THERE? IF T_C!	BREAK	C! ;
: C@ DUP THERE? IF T_C@	BREAK	C@ ;
: W! DUP THERE? IF T_W!	BREAK	W! ;
: W@ DUP THERE? IF T_W@	BREAK	W@ ;
:  ! DUP THERE? IF T_! 	BREAK	 ! ;
: +! DUP THERE? IF T_+! BREAK	+! ;
:  @ DUP THERE? IF T_@	BREAK	 @ ; 
: 2! DUP THERE? IF T_2! BREAK	2! ;
: 2@ DUP THERE? IF T_2@	BREAK	2@ ; 



: EXECUTE DUP THERE? IF T_EXECUTE BREAK EXECUTE ;

\ : READ-FILE 2>R DUP THERE? IF 2R> TREAD-FILE BREAK 2R> READ-FILE ;

WARNING !


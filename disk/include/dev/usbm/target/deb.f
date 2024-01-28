\ DIS-OPT

REQUIRE [DEFINED] ~mak/lib/ifdef.f
: ~DBG ;

REQUIRE WDS ~mak\wds.f 

\ [DEFINED] #define
1
[IF] samples\~mak\dbgwc.f
 <DBG>
[ELSE] : F7_ED ;
[THEN]  

0
[IF] <\DBG>
[THEN]  

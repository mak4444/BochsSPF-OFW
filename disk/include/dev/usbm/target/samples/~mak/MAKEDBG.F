REQUIRE Q-DBG samples\~mak\dbgwc.f 

: DBG_MAIN CONSOLE  EditRegisterClass 
  OpenDialog :new TO tt
 S" EDIT.LOG" W/O CREATE-FILE-SHARED THROW GUI-EDIT::TO EDIT.LOG
 ['] EDIT_ERROR TO ERROR
 ;

' DBG_MAIN MAINX !

S" spf4db.exe" S" samples\~mak\win\spfwc\spf4wc.FRES " devel\~af\lib\save.f

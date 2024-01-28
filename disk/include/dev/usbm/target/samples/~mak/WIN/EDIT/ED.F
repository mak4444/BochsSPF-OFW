\ Andrey Filatkin, af@forth.org.ru
\ Mihail Maksimov, forth@inbox.ru

MODULE: ~DAY
 REQUIRE OpenDialog ~mak/~day/joop\win\filedialogs.f
;MODULE
ALSO ~DAY

 lib\win\const.f

REQUIRE [UNDEFINED] lib\include\tools.f
REQUIRE { ~mak\locals4.f
REQUIRE CASE ~mak\case.f
REQUIRE cmdBYE samples\~mak\WIN\SPFWC\define.h 
REQUIRE $! ~mak\place.f

REQUIRE RSendMessageA ~mak\LIB\rwin.f 

0 VALUE ZZFF
1 VALUE ZFFF

CASE-INS @
CASE-INS OFF

TlsIndex@ VALUE OPER_E

CREATE VVV 0x100 ALLOT

0
4 FIELD .cpMin
4 FIELD .cpMax
4 FIELD .lpBuffer

CONSTANT FINDTEXT

CREATE FTTT FINDTEXT ALLOT 

CREATE TABBBB  9 C, 0 C,
CREATE BLBBBB BL C, 0 C,
CREATE CRBBBB 0xD C, 0 C,
VARIABLE VXY CELL ALLOT

: XXFND OPER_E TlsIndex! VVV COUNT CR ." X="  SFIND 0=   DUP .  ;

[UNDEFINED] 2RDROP
[IF] : 2RDROP POSTPONE RDROP  POSTPONE RDROP  ; IMMEDIATE
[THEN]

[UNDEFINED] USEARCH
[IF]
: USEARCH ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 flag )
\  df102002\src\compiler\df_def_proc.f
\ \ gforth\extend.fs 
    2>R 2DUP
    BEGIN
      DUP 1+ R@ > \ пока длины достаточно
    WHILE
      OVER 2R@ TUCK CEQUAL-U 0=
      IF 2RDROP 2SWAP 2DROP TRUE EXIT THEN
      1- SWAP 1+ SWAP
    REPEAT 2RDROP 2DROP 0
;
[THEN]

[UNDEFINED] /STRING
[IF] : /STRING DUP >R - SWAP R> + SWAP ;
[THEN]

FILTER: fTest

  NAME" all files" EXT" *.*"
  NAME" FORTH files" EXT" *.F"

;FILTER

OpenDialog :new VALUE tt

: title1
     S" Put on FPauk"
;

 fTest tt :setFilter
title1 tt :setTitle

\ WINAPI: SetWindowTextA       USER32.DLL

0x1001 CONSTANT cmdTst
0x1002 CONSTANT cmdRestore
0x1003 CONSTANT cmdGOTO
0x1004 CONSTANT cmdFORTH
0x1005 CONSTANT cmdABORT
0x1006 CONSTANT cmdFIND
0x1007 CONSTANT cmdHEX
0x1008 CONSTANT cmdDEC
0x1009 CONSTANT cmdDBG

#define cmdSave cmdDbgInclude
#define cmdSaveAs cmdRunScript

0 VALUE E?R/O

1 4 LSHIFT CONSTANT MAX#ED_FN

0 VALUE #ED_FN

CREATE EDIT_FN_B 0x101	 MAX#ED_FN * ALLOT
CREATE EDIT_SL_B 2 CELLS MAX#ED_FN * ALLOT

: EDIT_FN  EDIT_FN_B #ED_FN 200	    * + ;
: EDIT_SL  EDIT_SL_B #ED_FN 2 CELLS * + ;

: EDIT_FN!  ( ADDR LEN -- )
    EDIT_FN $!
    EDIT_FN COUNT + 0! ;

VARIABLE EDIT_XY  0 ,

: EDIT_XY!  EDIT_XY 2! ;

TRUE VALUE EDIT-END
TRUE VALUE ED_WATE
 0 VALUE EdHWnd
 0 VALUE EMyhwnd

: SendToEd ( lParam wParam Msg -- u )
\ EdHWnd MSendMessageA
  ROT >R SWAP >R >R  EdHWnd DUP>R  RSendMessageA
 ;


:  EDIT_SEL    (  bb ee -- )
   EM_SETSEL     SendToEd DROP
   0 0 EM_SCROLLCARET   SendToEd DROP
;

:  EDIT_SELEDIT_SEL    (  bb ee -- )
   EM_SETSEL     SendToEd DROP
   0 0 EM_SCROLLCARET   SendToEd DROP
;


: EDIT_SEL_GET { \ bb ee -- bb ee }
   ^ bb ^ ee  EM_GETSEL  SendToEd DROP
   bb ee
;

(
VARIABLE SELBUF CELL ALLOT

: EDIT_SEL_GET { \ bb ee -- bb ee }

    SELBUF  0 EM_EXGETSEL SendToEd DROP
    SELBUF  2@
   ;
)

: NEXT_F EDIT_SEL_GET EDIT_SL 2!
         #ED_FN 1+ MAX#ED_FN 1- AND TO #ED_FN ;
: LAST_F #ED_FN 1- MAX#ED_FN 1- AND TO #ED_FN ;

: PUSH-WINDOW ( hwnd -- prev-hwnd)
    DUP SetActiveWindow >R
    DUP SetFocus DROP
    DUP SetForegroundWindow DROP
        BringWindowToTop DROP
    R>
;

:  EDIT_SCROLL  { yy -- }
   0   yy 6 +
      0 0 EM_GETLINECOUNT SendToEd 1-  MIN
   EM_LINEINDEX   SendToEd DUP
   EDIT_SEL
;


: EDIT_XY_SET { xx yy -- }
   yy  EDIT_SCROLL
   0  yy  EM_LINEINDEX   SendToEd xx + DUP
   EM_SETSEL       SendToEd DROP
   0 0 EM_SCROLLCARET   SendToEd DROP
    EdHWnd PUSH-WINDOW DROP
;

: EDIT_Y_SET { yy -- }
   yy  EDIT_SCROLL
   0  yy    EM_LINEINDEX   SendToEd
   0  yy 1+ EM_LINEINDEX   SendToEd
   EM_SETSEL       SendToEd DROP
   EMyhwnd PUSH-WINDOW DROP
;

: EDIT_Y_GET
  0 -1 EM_LINEFROMCHAR SendToEd
;

\ 0 VALUE CCCC
0 VALUE Content
0 VALUE SizeEd

: EDLoad  ( -- )
 {  \  fid -- }
    EDIT_FN COUNT
    R/O OPEN-FILE-SHARED 0= IF \ ." FILE OK"
    DUP TO fid
    FILE-SIZE THROW DROP ?DUP IF
\      DUP 0xE1AA U> TO E?R/O
\      0xE1AA UMIN
      1+ DUP TO SizeEd
      ALLOCATE THROW DUP TO Content
      SizeEd 1-  fid READ-FILE 2DROP
      Content 0 WM_SETTEXT EdHWnd SendMessageA DROP
\ [UAD@] Content >R 0 >R WM_SETTEXT >R  EdHWnd DUP>R  RSendMessageA DROP [UAD!]
   0 0 WM_GETTEXTLENGTH SendToEd DROP
   0 0 WM_SETCURSOR     SendToEd DROP

    EDIT_FN 1+  EMyhwnd  SetWindowTextA DROP

      Content FREE THROW
    THEN
    fid CLOSE-FILE THROW
  ELSE ." FILE ERROR"
    DROP
  THEN
;

: EDIT_Load  ( -- )
 {  \  fid -- }
    EDIT_FN COUNT
    R/O OPEN-FILE-SHARED 0= IF \ ." FILE OK"
    DUP TO fid


    FILE-SIZE THROW DROP ?DUP IF
\      DUP 0xE1AA U> TO E?R/O
\      0xE1AA UMIN
      1+ DUP TO SizeEd
      ALLOCATE THROW DUP TO Content
      SizeEd 1-  fid READ-FILE 2DROP
      Content 0 WM_SETTEXT EdHWnd SendMessageA DROP
\ [UAD@] Content >R 0 >R WM_SETTEXT >R  EdHWnd DUP>R  RSendMessageA DROP [UAD!]
   0 0 WM_GETTEXTLENGTH SendToEd DROP
   0 0 WM_SETCURSOR     SendToEd DROP

    EDIT_FN 1+  EMyhwnd  SetWindowTextA DROP

      Content FREE THROW
    THEN
    fid CLOSE-FILE THROW
  ELSE ." FILE ERROR"
    DROP
  THEN
;

VECT F4_EDIT   ' NOOP TO F4_EDIT
VECT F6_EDIT   ' NOOP TO F6_EDIT
VECT F7_EDIT   ' NOOP TO F7_EDIT
VECT F8_EDIT   ' NOOP TO F8_EDIT
VECT F9_EDIT   ' NOOP TO F9_EDIT

0x00000001  CONSTANT FR_DOWN
0x00000004  CONSTANT FR_MATCHCASE
0x00010000  CONSTANT FR_HIDEWHOLEWORD

CREATE FindBuffer 0 C, 0x20 ALLOT

0 VALUE FindOwner
0 VALUE FdFlags

CREATE FindStruct

  0x28 ,                 \ Size
  HERE TO FindOwner
   0  ,                  \ Owner
   0  ,                  \ Instance
  HERE TO FdFlags
 FR_HIDEWHOLEWORD FR_DOWN + ,    \ Flags

  FindBuffer ,            \ FindWhat
   0 ,                    \ ReplaceWith
  0x20 ,                  \ Find Len & Repl Len
   0 ,
   0 ,
   0 ,


MODULE: GUI-EDIT \ -------------------------------------------

[UNDEFINED] /MSG
[IF]

0
4 -- MSG.hwnd
4 -- MSG.message
4 -- MSG.wParam
4 -- MSG.lParam
4 -- MSG.time
4 -- MSG.pt
4 -- MSG.ex
CONSTANT /MSG
[THEN]

[UNDEFINED] /LOGFONT
[IF]

0
  4 --  lfHeight
  4 --  lfWidth
  4 --  lfEscapement
  4 --  lfOrientation
  4 --  lfWeight
  1 --  lfItalic
  1 --  lfUnderline
  1 --  lfStrikeOut
  1 --  lfCharSet
  1 --  lfOutPrecision
  1 --  lfClipPrecision
  1 --  lfQuality
  1 --  lfPitchAndFamily
 48 --  lfFaceName
CONSTANT  /LOGFONT
[THEN]

[UNDEFINED] /WNDCLASS
[IF]

0
4 -- .style
4 -- .lpfnWndProc
4 -- .cbClsExtra
4 -- .cbWndExtra
4 -- .hInstance
4 -- .hIcon
4 -- .hCursor
4 -- .hbrBackground
4 -- .lpszMenuName
4 -- .lpszClassName
CONSTANT /WNDCLASS
[THEN]

DECIMAL
 TRUE VALUE JetOut
 0 VALUE EdWndProc
 0 VALUE StatusHwnd
 0 VALUE MAINHWND
 0 VALUE MainMenu
 0 VALUE JetBuf
 0 VALUE *JetBuf
TRUE VALUE ?in
 0 VALUE hFont
-18 VALUE console_font_height
 0  VALUE console_font_width  \ 0-proportional to console_font_height
 0x64 CONSTANT OBSIZE
0x100 VALUE    MAXLIN
 0 VALUE tib
 0 VALUE >in
 0 VALUE KEY_EVENT_GUI       \ event на KEY
 0 VALUE LastKey

  0 VALUE LruBuf              \ буфер history (last recently used)
  8 VALUE LruNum              \ число запоминаемых сообщений lru
255 VALUE LruLen              \ размер одной строки буфера lru

VARIABLE  CurrFromLru

: OBJECT_HA  ( length  -- begin addr )
  HERE DUP  0xF + 0xFFFFFFF0 AND SWAP - ALLOT
  HERE \ len here
  OVER \ len here len
  ALLOT \ len here
  DUP ROT  ERASE CONSTANT ;

 /MSG        OBJECT_HA MSG1
 /LOGFONT    OBJECT_HA logfont

204 logfont lfCharSet C!          \ RUSSIAN_CHARSET
console_font_height ( -14) logfont lfHeight !
console_font_width  ( -10) logfont lfWidth  !

: LOWORD ( lpar -- loword ) 0x0FFFF AND ;
: HIWORD ( lpar -- hiword ) 0x10000 /  ;

: 0SendToEd
  0 0 ROT EdHWnd SendMessageA DROP
\ 0 >R 0 >R >R  EdHWnd DUP>R  RSendMessageA DROP
 ;

: EDIT_Save  ( <filename> -- )
  { fna fnl \  fid  -- }
  E?R/O IF MB_OK MB_ICONSTOP OR MB_SYSTEMMODAL OR
           S" EDIT" DROP  S" The file is saveless" DROP  0 MessageBoxA DROP
 EXIT THEN
  \ получаем содержимое окна Script
  0 0 WM_GETTEXTLENGTH SendToEd 1+ DUP TO SizeEd

  ALLOCATE THROW DUP TO Content
  SizeEd WM_GETTEXT SendToEd DROP
  \ открываем файл
   fna fnl W/O CREATE-FILE THROW TO fid
  \ записываем код в файл
  Content SizeEd 1- fid WRITE-FILE THROW
  \ закрываем файл и буфер
  Content FREE THROW
  fid CLOSE-FILE THROW
  0 0 EM_SETMODIFY SendToEd DROP
 ;

180 CONSTANT DIR_SIZE

CREATE  DIR_STOR  DIR_SIZE ALLOT

: FileDLG
\  DIR_STOR DIR_SIZE GetCurrentDirectoryA DROP
   tt :execute DROP tt :fileName DUP
\  DIR_STOR  SetCurrentDirectoryA DROP
;

9  CONSTANT LANG_ENGLISH
3  CONSTANT MB_YESNOCANCEL

2  CONSTANT IDCANCEL
6  CONSTANT IDYES
7  CONSTANT IDNO
VARIABLE FindHWND

: ?SaveCng
       0 0 EM_GETMODIFY SendToEd 0=
       IF IDNO EXIT THEN
       LANG_ENGLISH
       MB_YESNOCANCEL
       Z" Warning"
       Z" Text was modified. Save changes?"
       EdHWnd
       MessageBoxExA
;

:   ?LoadDo  ( addr len -- )
    ?SaveCng
    DUP IDYES =
    IF  EDIT_FN COUNT ['] EDIT_Save CATCH DROP \ ." S=" .
    THEN
    IDCANCEL <>
    IF NEXT_F EDIT_FN! EDIT_Load
    ELSE 2DROP
    THEN
;

: DoCommand
    CASE
      cmdInclude  OF    FileDLG
                        IF   ?LoadDo
                        ELSE DROP
                        THEN
                  ENDOF

      cmdSaveAs   OF   FileDLG
                        IF   EDIT_Save
                        ELSE DROP
                        THEN
                  ENDOF

      cmdSave     OF   EDIT_FN COUNT ['] EDIT_Save CATCH DROP \ ." S=" .
                  ENDOF

      cmdRestore  OF   EDIT_Load
                  ENDOF

      cmdBYE      OF
 0 0 WM_CLOSE   EMyhwnd SendMessageA DROP
\ 0 >R 0 >R WM_CLOSE >R  EdHWnd DUP>R  RSendMessageA DROP

                  ENDOF
      cmdCUT      OF WM_CUT   0SendToEd ENDOF
      cmdCOPY     OF WM_COPY  0SendToEd ENDOF
      cmdPASTE    OF WM_PASTE 0SendToEd ENDOF
      cmdFIND     OF FindStruct FindTextA  FindHWND ! ENDOF

        cmdGOTO   OF F4_EDIT cmdDBG TO ED_WATE  ENDOF
        cmdOUT    OF F6_EDIT cmdDBG TO ED_WATE  ENDOF
        cmdSTEP   OF F7_EDIT cmdDBG TO ED_WATE  ENDOF
        cmdOVER   OF F8_EDIT cmdDBG TO ED_WATE  ENDOF
        cmdGO     OF F9_EDIT cmdDBG TO ED_WATE  ENDOF
        cmdFORTH  OF     cmdFORTH   TO ED_WATE  ENDOF
        cmdABORT  OF     cmdABORT   TO ED_WATE  ENDOF
        cmdHEX    OF     cmdHEX     TO ED_WATE  ENDOF
        cmdDEC    OF     cmdDEC     TO ED_WATE  ENDOF

      cmdTst      OF
   0  10  EM_LINEINDEX   SendToEd DUP
   EM_SETSEL       SendToEd DROP
    0 0 EM_SCROLLCARET   SendToEd DROP
 ENDOF
    ENDCASE
;

: LastLineChange ( addr -- )
   0    0 EM_GETLINECOUNT EdHWnd SendMessageA 1-
   0 SWAP EM_LINEINDEX    EdHWnd SendMessageA DUP
   0 SWAP EM_LINELENGTH   EdHWnd SendMessageA
   OVER + SWAP EM_SETSEL  EdHWnd SendMessageA DROP
       0  EM_REPLACESEL   EdHWnd SendMessageA DROP
\   0 >R 0 >R	EM_GETLINECOUNT	>R EdHWnd DUP>R RSendMessageA 1-
\   0 >R   >R	EM_LINEINDEX   	>R EdHWnd DUP>R RSendMessageA DUP
\   0 >R   >R	EM_LINELENGTH  	>R EdHWnd DUP>R RSendMessageA
\   OVER + >R >R EM_SETSEL 	>R EdHWnd DUP>R RSendMessageA DROP
\    >R  0 >R	EM_REPLACESEL  	>R EdHWnd DUP>R RSendMessageA DROP
 ;

 10000000 ALLOCATE THROW TO Content 

Content 44 DUMP

\ EM_GETSELTEXT

: FIND_DO_F11

  0 0 WM_GETTEXTLENGTH SendToEd 1+ TO SizeEd

  EDIT_SEL_GET 2>R

  R@   FTTT .cpMin !
\  SizeEd
  0 FTTT .cpMax !

  BLBBBB FTTT .lpBuffer !
  FTTT 0 EM_FINDTEXT SendToEd

  CRBBBB FTTT .lpBuffer !
  FTTT 0 EM_FINDTEXT SendToEd UMAX

 1+ DUP 30 +
    EDIT_SEL
 
  VVV 1+ 0 EM_GETSELTEXT SendToEd DROP

  VVV 1+
  BEGIN   DUP C@  BL >
  WHILE 1+
  REPEAT
  VVV 1+ - VVV C!
 
  2R> EDIT_SEL

  TlsIndex@ >R 
\  2DROP S" HEX" 
  XXFND
  R> TlsIndex!
  IF -321 THROW THEN (  -? )
  NEAR_NFA DROP ?DUP  DUP .
  IF 9 - DUP @ COUNT
 ?LoadDo CELL- @ 0 SWAP
 EDIT_XY_SET
  THEN

\  Content FREE THROW
;


    444 FTTT .cpMin !
     0 FTTT .cpMax !

: FIND_DO1
  EdHWnd SetFocus DROP
  FindBuffer  FTTT .lpBuffer !
  EDIT_SEL_GET MAX  FTTT .cpMin !
      -1 FTTT .cpMax !

    FTTT  ZFFF EM_FINDTEXT SendToEd TO ZZFF
   ZZFF 0 >
  IF   ZZFF DUP FindBuffer ASCIIZ> NIP +  EDIT_SEL
  THEN
;


\ *\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\***
\ **\\\\\ оконная функция \\\\\\\\\\\\\**
\ ***\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*

 S" EDIT.LOG" W/O CREATE-FILE-SHARED THROW CONSTANT EDIT.LOG

:NONAME   { lpar wpar msg hwnd -- }
\ EXIT
   H-STDOUT >R  EDIT.LOG TO H-STDOUT

  CR ." M=" HEX lpar . wpar . msg . hwnd .

 msg 0x100 =  \ VK_DOWN =
 IF
    wpar CASE
        VK_F2  OF  EDIT_FN COUNT ['] EDIT_Save CATCH DROP \ ." S=" .
               ENDOF
        VK_F3  OF ['] FIND_DO1 CATCH DROP	ENDOF
        VK_F4  OF F4_EDIT  cmdDBG TO ED_WATE	ENDOF
        VK_F6  OF F6_EDIT  cmdDBG TO ED_WATE	ENDOF
        VK_F7  OF F7_EDIT  cmdDBG TO ED_WATE	ENDOF
        VK_F8  OF F8_EDIT  cmdDBG TO ED_WATE	ENDOF
        VK_F9  OF F9_EDIT  cmdDBG TO ED_WATE	ENDOF
        VK_F11 OF ['] FIND_DO_F11 CATCH DROP	ENDOF
        VK_F12 OF LAST_F EDIT_Load  EDIT_SL 2@ EDIT_SEL ENDOF
        ENDCASE
 THEN
 msg 0x112 =
 IF   \     [CHAR] #   GUI-CONSOLE::conemit GUI-CONSOLE::FlushJetBuf
    wpar CASE
        0xF100  OF WM_UNDO  0SendToEd  ENDOF
        ENDCASE
 THEN

 msg 0xFF00 AND 0xC000 =  IF ['] FIND_DO1 CATCH DROP   THEN

lpar wpar msg hwnd EdWndProc CallWindowProcA

 R>   TO H-STDOUT

;

WNDPROC: MyEdWndProc

IMAGE-BASE CONSTANT HINST  \ Instance текущего приложения

  3 CONSTANT EdID

:NONAME    { lpar wpar msg hwnd  \ hdc hout -- }

       H-STDOUT TO hout  EDIT.LOG TO H-STDOUT

\ CR ." P=" HEX lpar . wpar . msg . hwnd .

   msg CASE

   WM_CREATE OF

  (( CreateWindowExA 0 , HINST , EdID , hwnd , 0 , 0 , 0 , 0 ,
   WS_CHILD WS_VISIBLE OR WS_VSCROLL OR ES_AUTOHSCROLL OR
   WS_HSCROLL OR  ES_MULTILINE OR ,
   0 , \ Z" EDIT"
 Z" RichEdit20a"
 , WS_EX_CLIENTEDGE ) DUP FindOwner ! TO EdHWnd

  (( SetWindowLongA ['] MyEdWndProc , GWL_WNDPROC , EdHWnd ) TO EdWndProc

      EdHWnd UpdateWindow  DROP
      SW_SHOW EdHWnd ShowWindow  DROP

      hwnd GetDC -> hdc
      logfont CreateFontIndirectA TO hFont
      1 hFont WM_SETFONT EdHWnd SendMessageA DROP
\ [UAD@]   1 >R hFont >R WM_SETFONT >R EdHWnd DUP>R RSendMessageA DROP [UAD!]
	[UAD@] 
	EdHWnd EM_EXLIMITTEXT 0 100000000
	 >R >R	  >R  DUP>R
	RSendMessageA  [UAD!] DROP

      hdc hwnd ReleaseDC DROP


      0
   ENDOF \ 1

   WM_SIZE OF
       1
       lpar HIWORD
       lpar LOWORD
       0 0
       EdHWnd
       MoveWindow DROP
    \   EMyhwnd UpdateWindow  DROP
      0
   ENDOF    \ 2

   WM_SETFOCUS OF
      EdHWnd SetFocus DROP
      0
   ENDOF   \ 3

(   WM_PAINT  OF
    EdHWnd UpdateWindow  DROP
    0
   ENDOF)

   WM_COMMAND  OF
      wpar DoCommand
      0
   ENDOF
(
   WM_DESTROY OF
      hwnd GetDC -> hdc
      hFont hdc DeleteObject  DROP
      hdc hwnd ReleaseDC DROP
      0 PostQuitMessage
\      BYE
   ENDOF )
    DUP WM_DESTROY = IF TRUE TO EDIT-END TRUE TO ED_WATE THEN
    DUP WM_CLOSE = IF   
                            ?SaveCng
                            DUP IDYES =
                            IF  EDIT_FN COUNT ['] EDIT_Save CATCH DROP \ ." S=" .
                            THEN
                            IDCANCEL =
                            IF  DROP  hout TO H-STDOUT  EXIT
                            THEN

\   EDIT_FN COUNT ['] EDIT_Save CATCH DROP \ ." S=" .

                   THEN

     \ default
     lpar wpar msg hwnd DefWindowProcA

     \ need for swap with case parameter
     \ and defwinproc parameter
     SWAP
 ENDCASE
 hout TO H-STDOUT

;

WNDPROC: EditWndProc

CREATE MSG  28 ALLOT

: MessageLoop
  BEGIN

    0 0 0 MSG1 GetMessageA

  WHILE
\    FindHWND @ DUP IF MSG  SWAP IsDialogMessageA DROP THEN

    MSG1 TranslateMessage DROP
    MSG1 DispatchMessageA DROP
    EDIT-END IF EXIT THEN

  REPEAT
;

: CreateMainMenu ( -- hmenu )
  CreatePopupMenu >R
  S" &Open"        DROP cmdInclude  MF_STRING R@ AppendMenuA DROP
  S" &Save\tF2"        DROP cmdSave     MF_STRING R@ AppendMenuA DROP
  S" Save &As"     DROP cmdSaveAs   MF_STRING R@ AppendMenuA DROP
  S" &Restore"     DROP cmdRestore  MF_STRING R@ AppendMenuA DROP
  S" E&xit"        DROP cmdBYE      MF_STRING R@ AppendMenuA DROP

 S" &File" DROP R> MF_POPUP CreateMenu DUP   >R AppendMenuA DROP

  CreatePopupMenu >R
  S" C&ut"         DROP cmdCUT      MF_STRING R@ AppendMenuA DROP
  S" &Copy"        DROP cmdCOPY     MF_STRING R@ AppendMenuA DROP
  S" &Paste"       DROP cmdPASTE    MF_STRING R@ AppendMenuA DROP

 S" &Edit" DROP R> MF_POPUP                  R@ AppendMenuA DROP

  CreatePopupMenu >R
  S" &Go\tF9  "       DROP cmdGO       MF_STRING R@ AppendMenuA DROP
  S" S&tep\tF7"       DROP cmdSTEP     MF_STRING R@ AppendMenuA DROP
  S" &Over\tF8"       DROP cmdOVER     MF_STRING R@ AppendMenuA DROP
  S" Go&to\tF4"       DROP cmdGOTO     MF_STRING R@ AppendMenuA DROP
  S" O&ut\tF6"        DROP cmdOUT      MF_STRING R@ AppendMenuA DROP
  S" &Forth"          DROP cmdFORTH    MF_STRING R@ AppendMenuA DROP
  S" &Abort"          DROP cmdABORT    MF_STRING R@ AppendMenuA DROP
  S" &HEX"            DROP cmdHEX      MF_STRING R@ AppendMenuA DROP
  S" &DECIMAL"        DROP cmdDEC      MF_STRING R@ AppendMenuA DROP

 S" &Debug" DROP R> MF_POPUP                  R@ AppendMenuA DROP

 S" &Search"        DROP cmdFIND     MF_STRING R@ AppendMenuA DROP

 S" &Tst"       DROP cmdTst    MF_STRING R@ AppendMenuA DROP

  R>
;

EXPORT \ ---------------------------------------

:  EditClassName   S" SP-FORTH EDIT" DROP ;

: EditRegisterClass
 \ fill the class structure

HERE   /WNDCLASS ALLOT

    CS_HREDRAW CS_VREDRAW OR    OVER .style         !
    ['] EditWndProc             OVER .lpfnWndProc   !
    0                           OVER .cbClsExtra    !
    0                           OVER .cbWndExtra    !
    HINST                       OVER .hInstance     !
    1 HINST LoadIconA           OVER .hIcon         !
    IDC_ARROW 0 LoadCursorA     OVER .hCursor       !
    WHITE_BRUSH GetStockObject  OVER .hbrBackground !
    0                           OVER .lpszMenuName  !
    EditClassName               OVER .lpszClassName !
    RegisterClassA
  0= ABORT" #Class was not registered!"

     /WNDCLASS NEGATE ALLOT
;

     EditRegisterClass

: TASK_EDIT
  EDIT_XY 2@ { xx yy -- }
  CreateMainMenu TO MainMenu
  MainMenu 0= ABORT" #Can't Create Menu!"

  0                             \ pointer to window-creation data
  HINST                         \ handle to application instance
  MainMenu                      \ handle to menu, or child-window identifier
  0                             \ handle to parent or owner window
  0 0                           \ window height, width
  0 0                           \ vertical, horizontal position
  WS_CAPTION  WS_SYSMENU OR WS_THICKFRAME OR WS_MINIMIZEBOX OR
  WS_MAXIMIZEBOX OR  WS_POPUP OR \ style
                                \ address of window name
  EditClassName  DUP            \ address of registered class name
  0                             \ extended window style

  CreateWindowExA
  DUP 0= ABORT" Window not created..."
  TO EMyhwnd

  0 400 640 0 0 EMyhwnd MoveWindow DROP

  EMyhwnd UpdateWindow  DROP
  5 EMyhwnd ShowWindow  DROP

  EdHWnd TO MAINHWND
  EDIT_FN C@ 0=
  IF     S" NONAME.F" EDIT_FN!
  THEN     EDIT_Load
   0  yy  EM_LINEINDEX   SendToEd xx + DUP
   EM_SETSEL       SendToEd DROP
   0 0 EM_SCROLLCARET   SendToEd DROP

  FALSE TO  EDIT-END

  MessageLoop

\  EdHWnd DestroyWindow DROP

;

: EDDD
 S" XXX.F" EDIT_FN!
 TASK_EDIT
;

VARIABLE CC_INIT CC_INIT 0! \ ®¤­®Єа в­ п Ё­ЁжЁ «Ё§ жЁп CommonControls
CREATE   CC_INITS 8 , 0xFFFF ,

: InitControls
  CC_INIT @ IF EXIT THEN
  CC_INITS InitCommonControlsEx DROP
  S" RICHED32.DLL" DROP LoadLibraryA DROP
\  S" RICHED20.DLL" DROP LoadLibraryA DROP
  TRUE CC_INIT !
;

InitControls


'  TASK_EDIT TASK:  START_EDITED

: EDIT
    TlsIndex@ TO OPER_E
    EDIT-END
    IF 0 START_EDITED START DROP
    ELSE EDIT_Load  EDIT_XY 2@ EDIT_XY_SET
    THEN 100 PAUSE ;

: EDIT_ERROR ( ERR-NUM -> ) \ показать расшифровку ошибки
  [ ' ERROR >BODY @ COMPILE, ]
  ERR-FILE NIP \ cmdDBG ED_WATE <> AND
  IF   NEXT_F  ERR-FILE EDIT_FN!
       ERR-IN# 2-  ERR-LINE# 1- EDIT_XY! EDIT
  THEN
;

' EDIT_ERROR TO ERROR

: E> ' NEAR_NFA DROP ?DUP 
  IF NEXT_F  9 - DUP @ COUNT EDIT_FN! CELL- @ 0 SWAP EDIT_XY! EDIT
  THEN
;

: OK EDIT_FN COUNT INCLUDED ;

;MODULE \ ---------------------------
CASE-INS !
PREVIOUS PREVIOUS

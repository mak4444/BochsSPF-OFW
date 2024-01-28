
purpose: Defining words for code definitions

only forth also assembler also forth definitions
: entercode  ( -- )
 !csp
 also
 assembler
  ;
: code   \ name  ( -- )
\ F7_ED
 >IN @
 PARSE-NAME
 current @
 wid>twid DUP @
 DROP
 $make-header
 >IN !
 HERE>EXEC
 HEADER
  here
 4 +
 , do-entercode
;

: label  \ name  ( -- adr )
   create  do-entercode
;
: use-postfix-assembler  ( -- )  ['] entercode is do-entercode  ;
use-postfix-assembler
0 value codetarget
: ;CODE
  S" (;code)" EVALUATE
 here to codetarget
 POSTPONE [
 entercode
; IMMEDIATE

assembler definitions
\ We redefine the Registers that FORTH uses to implement its
\ virtual machine.

ebp constant rp   [ebp] constant [rp]   \ Rreturn stack pointer
esi constant ip   [esi] constant [ip]   \ Interpreter pointer
eax constant w    [eax] constant [w]    \ Working register
edi constant up   [edi] constant [up]   \ User pointer

: next    up jmp   ;
: ainc   ( ptr -- )  /n # rot add  ;
: adec   ( ptr -- )
 f7_ed
  /n # rot sub  ;
: [apf]  ( -- mode )  4 [w]    ;
: 1push  ( -- )  ax push  ;
: 2push  ( -- )  dx push  ax push  ;
: end-code  ( -- ) 
 previous 
 ?csp  ;

: 'user#  \ name  ( -- n )
   ' >body @
;
: 'user   \ name  ( -- mode )
   'user# [up]
;
: 'body   \ name  ( -- adr )
   ' >body
;

\ for relocation, addresses must be word-aligned
\ make-even is used with two-byte op-codes
\ make-odd is used with one-byte op-codes

: make-even 	( -- )	\ pad code with noop to reach word boundary
   here 
   [ also forth ]
   1 and if
      h# 90 asm8,
   then 
   [ previous ]
;
   
: make-odd 	( -- )	\ pad code with noop to be between word boundaries 
   here 
   [ also forth ]
   1 and 0= if
      h# 90 asm8,
   then 
   [ previous ]
;

only forth also definitions

\ See license at end of file

\ Metacompiler source for Forth kernel code words.

also meta
hex
\ Allocate and clear the initial user area image
setup-user-area

extend-meta-assembler

\ ---- Assembler macros that reside in the host environment
\ and assemble code for the target environment

\ Forth Virtual Machine registers

:-h rp  bp ;-h   :-h [rp]  [bp] ;-h   \ return stack pointer
:-h ip  si ;-h   :-h [ip]  [si] ;-h   \ interpreter pointer
:-h w   ax ;-h   :-h [w]   [ax] ;-h   \ working register
:-h up  di ;-h   :-h [up]  [di] ;-h   \ user pointer

\ Macros:

:-h ainc  ( ptr -- )  /n # rot add  ;-h
:-h adec  ( ptr -- )
\ f7_ed
  /n # rot
 sub  ;-h

\ Get a token
:-h tget  ( src dst -- )
;-h
\ Get a branch offset
:-h bget  ( src dst -- )
;-h
:-h /cf  4  ;-h         \ X should be in target.fth
:-h [apf]  ( -- src )  /cf [w]  ;-h
:-h 1push  ax push  ;-h
:-h 2push  dx push  ax push  ;-h

:-h /n* /n * ;-h

\ assembler macro to assemble next
:-h next
   meta-asm[  up jmp  ]meta-asm
;-h

:-h c;
\ F7_ED 5 C,
    next
 end-code
  ;-h

:-h Zc;
 F7_ED \ 5 C,
    next
 end-code
  ;-h

\ assembler macro to swap bytes
:-h ?bswap-ax  ( -- )
[ifdef] big-endian-t
   meta-asm[
   \ The 486 can do this in 1 instruction (BSWAP), which the 386 doesn't have
   ax bx mov
   d# 16 # cl mov	\ shift count
   bh bl xchg		\ swap low bytes
   bx cl shl		\ move to high word
   ax cl shr		\ move high bytes to low word
   ah al xchg		\ swap them
   bx ax add		\ merge words
   ]meta-asm
[then]
;-h

:-h 'user#  \ name  ( -- user# )
    [ meta ]-h  '  ( acf-of-user-variable )
  >body-t
 @-t
;-h
:-h 'user  \ name  ( -- user-addressing-mode )
    [ assembler ]-h
   'user# 
[up]
;-h

:-h 'body  \ name  ( -- variable-apf )
    [ meta ]-h  ' >body-t fw-pa - ;-h
 
\ Create the code for "next" in the user area
\ compile-in-user-area

0 [IF]
here-t
mlabel >next  assembler
userarea-t dp-t !
   ax lods  0 [ax] jmp
   nop nop nop nop nop
end-code
dp-t !
\ restore-dictionary
[THEN]

d# 32 equ #user-init	\ Leaves space for the shared "next"

meta-compile

PREVIOUS DEFINITIONS   also

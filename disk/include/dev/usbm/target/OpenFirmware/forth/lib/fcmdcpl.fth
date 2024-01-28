
\ Command completion interface for the Forth line editor

only forth also hidden also command-completion definitions

headerless
: install-fcmd
   ['] end-of-word               is find-end
   ['] insert-character          is cinsert
   ['] erase-previous-character  is cerase
;
install-fcmd

only forth also command-completion also hidden also keys-forth definitions

headers
\ TAB expands, TAB-TAB shows completions
: ^i beforechar @ control i =  if do-show  else  expand-word then  ;	\ tab
: ^` expand-word ;	\ Control-space or control-back-tick
: ^| expand-word ;	\ Control-vertical-bar or control-backslash
: ^} do-show ;		\ Control-right-bracket
: ^? do-show ;		\ Control-question-mark
h# 7f last-t @ mmoname>string 
 mmodrop 1+
\ cr 2dup h. h. key drop
 c!   	\ Hack hack

only forth also definitions


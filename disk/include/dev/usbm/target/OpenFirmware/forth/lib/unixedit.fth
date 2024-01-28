
\ To make the line editor handle ^U and ^W just like Unix normally does

only forth hidden also forth also keys-forth definitions

: ^u beginning-of-line kill-to-end-of-line ;
: ^w erase-previous-word ;
: ^r retype-line ;
: del erase-previous-character ;

only forth also definitions

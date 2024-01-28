\ Machine/implementation-dependent definitions

decimal

only forth also hidden also definitions
headerless
: dictionary-base  ( -- adr )  origin 16 +  user-size +  ;

: ram/rom-in-dictionary?  ( adr flag -- )
   dup  #align 1- and  0=  if
	  dup  lo-segment-base lo-segment-limit  within
	  swap hi-segment-base hi-segment-limit  within  or
   else
	  drop false
   then
;

: reasonable-ip?  ( ip -- flag )  in-dictionary?  ;


\ Decompiler extension for 32-bit literals
: .llit      ( ip -- ip' )  ta1+ dup l@ n.  la1+  ;  
: skip-llit  ( ip -- ip' )  ta1+ la1+  ;  
\ ' (llit)  ' .llit  ' skip-llit  install-decomp

headers
only forth also definitions

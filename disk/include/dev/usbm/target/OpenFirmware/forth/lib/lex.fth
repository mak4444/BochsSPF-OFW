purpose: lexical analysis primitive

\ text$ means ( text-adr text-len )
0 value delim

\ lex scans text$ for each character in delim$
\ when one is found, lex splits text$ at that delimiter and leaves
: lex   ( text$ delim$ -- rem$ head$ delim true | text$ false )
   0 is delim
   2over bounds ?do				( text$ delim$ )
      2dup i c@ cindex if			( text$ delim$ [ index ] )
	 nip nip c@  dup is delim		( text$ delim )
	 left-parse-string  leave		( rem$ head$ )
      then					( text$ delim$ | rem$ head$ )
   loop						( text$ delim$ | rem$ head$ )
   delim if
      delim true
   else
      2drop false
   then
;

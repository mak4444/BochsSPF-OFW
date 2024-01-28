
headers

\ Splits a string into two halves before the first occurrence of
\ a delimiter character.
\ adra,lena is the string including and after the delimiter
\ adrb,lenb is the string before the delimiter
\ lena = 0 if there was no delimiter

: split-before  ( adr len delim -- adra lena  adrb lenb )
   split-string 2swap
;
alias $split left-parse-string

: cindex  ( adr len char -- [ index true ]  | false )
   false swap 2swap  bounds  ?do  ( false char )
      dup  i c@  =  if  nip i true rot  leave  then
   loop                           ( false char  |  index true char )
   drop
;

\ Splits a string into two halves after the last occurrence of
\ a delimiter character.
\ adra,lena is the string after the delimiter
\ adrb,lenb is the string before and including the delimiter
\ lenb = 0 if there was no delimiter

: right-split-string  ( $1 char -- tail$ head$|null$ )
   >r  2dup + 0           ( $1 null$ )
   begin  2 pick  while                   ( head$ tail$ )
      2over + 1- c@  r@  <>
   while                                  ( head$ tail$ )
      2swap 1-  2swap swap 1- swap 1+  
   repeat  then
   r> drop                                ( head$|null$ tail$ )
   2swap                                  ( tail$ head$|null$ )
;
alias split-after right-split-string
headers

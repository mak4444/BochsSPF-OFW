
forth definitions
headerless
: array  \ name  ( #elements -- )
\   create /n* allot   does>  swap na+	\ not ROMable
   /n* buffer:  does> do-buffer  swap na+    \ buffer: action plus  "swap na+"
;
headers

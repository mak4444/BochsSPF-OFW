\
: install-uart-io  ( -- )
   ['] lf-pstr          is newline-pstring
   ['] ukey?            is key?
   ['] ukey             is (key
   ['] uemit            is (emit
   ['] default-type     is (type
   ['] emit1            is emit
   ['] type1            is type
   ['] crlf             is cr
   ['] true             is (interactive?
   ['] cancel           is light
;

\ Set the defer words for dl, dlbin, dlfcode, etc.
[ifdef] diag-key
' ukey to diag-key
[then]
[ifdef] diag-key?
' ukey? to diag-key?
[then]

\
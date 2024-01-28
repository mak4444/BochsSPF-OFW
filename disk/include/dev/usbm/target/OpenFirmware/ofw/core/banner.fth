
hex
headerless
true value auto-banner?

headers
: suppress-banner  ( -- )  false to auto-banner?  ;

 false value oem-banner?
" "  d# 80  config-string oem-banner

false config-flag oem-logo?

headerless

d# 128 constant max-logo-width

defer .firmware  ' noop to .firmware

: memory-size ( -- #megs )
   " size" memory-node @ $call-method 1meg um/mod nip
;
: .memory  ( -- )
   memory-size dup d# 1024 / ?dup  if  ( mb gb )
      nip " GiB" rot                   ( gb$ gb )
   else                                ( mb )
      " MiB" rot                       ( mb$ mb )
   then                                ( m$ m )
   .d  type ."  memory installed"      ( )
;
: .serial  ( -- )
   push-decimal  ." Serial #"  serial# (.) type
   \   ." ."
   pop-base
;

variable logo?
: ?spaces  ( -- )
   logo? @  if  max-logo-width  stdout-char-width  / 2+  spaces  then
;


: display?  ( -- flag )
   stdout @  if
      " device_type"  stdout @  ihandle>phandle  get-package-property  0= if
         ( adr len )  get-encoded-string  " display"  $= exit
      then
   then
   false
;

: cpu-model  ( -- adr len )
   current-device >r  root-device
   " banner-name" get-property  if  " model" get-property  else  false  then
   r> push-device  if  " "  else  get-encoded-string  then
;


: .built  ( -- )
   " build-date" $find  if
      ." Built " execute type
   else
      2drop
   then
;
: .version  ( -- )
   " /openprom" find-package  if
      " model"  rot get-package-property  0=  if
         get-encoded-string  type cr
      then
   then
   .built cr
;

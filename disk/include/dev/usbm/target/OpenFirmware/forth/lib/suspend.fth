
\ Smart keyboard driven exit
\ Type q to abort the listing, anything else to pause it.
\ While it's paused, type q to abort, anything else to resume.

decimal

only forth also hidden also
hidden definitions

headerless
variable 1-more-line?  1-more-line? off
true value page-mode?

forth definitions
headers
: no-page    ( -- )  false is page-mode?  ;
: page-mode  ( -- )  true  is page-mode?  ;
headerless
: suspend-help  ( -- )
   ." Pager keys:" cr
   ."  <space>   Another page" cr
   ."  <cr>      Another line" cr
   ."  q         Quit" cr
   ."  c         Page Mode Off" cr
   ."  p         Page Mode On" cr
   ."  i         Interact" cr
   ."  d         Debug" cr
   ."  h or ?    Help (this message)" cr
;
: suspend-interact  ( -- )  ." Type 'resume' to continue" cr  interact  ;
defer suspend-debug  ( -- )   ' noop is suspend-debug
: (reset-page)  #line off  1-more-line? off  ;
' (reset-page)  is reset-page
: suspend  ( -- flag )
   #line off
   ??cr dark  ."  More [<space>,<cr>,q,c,p,i,d,h] ? "  light
   key  #out @  (cr  spaces  (cr  #out off
   dup  ascii q  =   if  drop true  exit  then
   dup  ascii n  =   if  drop true  exit  then
   dup  ascii p  =   if  drop page-mode  false  exit  then
   dup  ascii c  =   if  drop no-page  false  exit  then
   dup  ascii i  =   if  drop suspend-interact  false  exit  then
   dup  ascii d  =   if  drop suspend-debug  false  exit  then
   dup  ascii h  =   if  drop suspend-help   false  exit  then
   dup  ascii ?  =   if  drop suspend-help   false  exit  then
   dup  linefeed =  swap carret =  or  if  1-more-line? on  then
   false
;
d# 24 value default-#lines
headers

defer lines/page  ' default-#lines is lines/page

headerless
: (exit?)  ( -- flag )  \ True if the listing should be stopped
   interactive?  0=  if  false  exit  then

   \ In case we start with lines/page already too large, we clear it out
   page-mode?  if  #line @ lines/page u>=  if  suspend exit  then  then
   1-more-line? @  if  1-more-line? off  suspend  exit  then
   page-mode?  if  #line @ 1+  lines/page =  if  suspend exit  then  then
   key?  if
      key ascii q =  if   #line off  true  else  suspend  then
   else
      false
   then
;
headers
defer exit?
' (exit?) is exit?
only forth also definitions


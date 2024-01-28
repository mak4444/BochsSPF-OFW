purpose: Enumerate directory entries

\ mmo private

\ Convert DOS file attributes to the firmware encoding
\ see showdir.fth for a description of the firmware encoding
: >canonical-attrs  ( dos-attrs -- canon-attrs )
   >r
   \ Access permissions
   r@     1 and  if  o# 666  else  o# 777  then \ rwxrwxrwx

   \ Bits that are independent of one another
   r@     2 and  if  h# 10000 or  then		\ hidden
   r@     4 and  if  h# 20000 or  then		\ system
   r@ h# 20 and  if  h# 40000 or  then		\ archive

   \ Mutually-exclusive file types
   r@     8 and  if  h#  3000 or  then		\ Volume label
   r> h# 10 and  if  h#  4000 or  then		\ Subdirectory
   dup h# f000 and  0=  if  h# 8000 or  then	\ Ordinary file	
;

\ mmo public
: file-info  ( -- s m h d m y len attributes name$ )
   file-time  file-date  file-size  file-attributes >canonical-attrs
   file-name
;

: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   dup 0=  if  0 0 0 set-search  then  ( id )
   next-file  if                       ( id )
      1+  file-info  true
   else
      drop false
   then
;
: $create  ( adr len -- error? )  h# 20 dos-create  ;  \ Set archive bit

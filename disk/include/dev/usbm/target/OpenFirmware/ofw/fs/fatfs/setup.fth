purpose: Setup for FAT file system

support-package: fat-file-system

0 0  " support" property

transient
\ mmo : private  headerless  ;
\ mmo : internal headerless  ;
\ mmo : public   headers     ;
resident

\ mmo private
/fd instance buffer: dos-fd		\ Forthmacs file descriptor

: 1+!  1 swap +!  ;

create "cao ,"  Can't open "
create "cac ,"  Can't create "
create "car ,"  Can't read "
create "caw ,"  Can't write "
create "cad ,"  Can't delete "
create "cof ,"  Couldn't find "
create "dir ," directory "

[ifdef] dos-ui
alias \40 \
alias \20 \

\ Display management
: (dark ;  : (light ;


\ For floppy formatting

: 2ed-den ;	\ Select 2.88 MB density for formatting
: 2hd-den ;	\ Select 1.44 MB density for formatting
: init-floppy  ;
: track-format  ( track# -- )  ." Trying to format track " . (cr  ;
[then]

alias dos-lock   noop
alias dos-unlock noop
\
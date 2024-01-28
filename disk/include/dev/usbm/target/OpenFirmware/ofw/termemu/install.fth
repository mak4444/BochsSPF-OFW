
headers
\ Compatibility package to present a package-style interface for
\ old-style display drivers.

: $makealias  ( xt adr len -- )
   2dup my-voc find-method  if  ( xt adr len acf' )
      2drop 2drop
   else                         ( xt adr len )
      $create -1 setalias
   then
;

headerless
: disp-selftest ( -- failed? )
   my-self >r
   initial-addr my-termemu @  ( first-ihandle )
   ?dup  if  is  my-self  then (  )
   " disp-test" $call-self     ( failed? )
   r> is my-self               ( failed? )
;

: disp-close  ( -- )
   current-device >r  my-voc push-device
   \ Reset the my-termemu value in the instance record
   my-termemu  if
      initial-addr my-termemu       off
      initial-addr frame-buffer-adr off
      my-termemu " remove" $call-self    close-package
   then
   r> push-device
;
: disp-open   ( -- flag )
   \ If this device is already open
   \ then my-termemu will be initialized
   \ with the ihandle from the prev. open
   my-termemu ?dup  if  ( first-ihandle )
      close-chain    is my-self
   else
      \ Open an instance of the terminal emulator
      0 0  " terminal-emulator" $open-package  to my-termemu

      " install" $call-self
      install-terminal-emulator
      \ Save the ihandle in the instance record
      my-self           initial-addr my-termemu       !
      frame-buffer-adr  initial-addr frame-buffer-adr !
   then  true
;
: disp-write  ( adr len -- len )  tuck ansi-type  ;

: stdout-execute  ( xt -- )  stdout @ package( execute )package  ;
: stdout-termemu   ( -- flag )  ['] my-termemu stdout-execute   ;
: stdout-value  ( xt -- n )
   stdout-termemu  if  stdout-execute  else  drop 0  then
;

: stdout-line#      ( -- line# )    ['] line#      stdout-value  ;
: stdout-column#    ( -- column# )  ['] column#    stdout-value  ;
: stdout-char-width ( -- pixels )   ['] char-width stdout-value  ;
: stdout-draw-logo  ( -- )
   stdout-termemu  if  ['] draw-logo  stdout-execute  else  2drop  then
;

headers
: is-install   ( xt -- )
   ( xt )            " install"   $makealias
   ['] disp-open     " open"      $makealias
   ['] disp-write    " write"     $makealias
   ['] draw-logo     " draw-logo" $makealias
   ['] reset-screen  " restore"   $makealias
;
: is-remove    ( xt -- )
   ( xt )            " remove"    $makealias
   ['] disp-close    " close"     $makealias
;
: is-selftest  ( xt -- )
   ( xt )             " disp-test"  $makealias
   ['] disp-selftest  " selftest"   $makealias
;

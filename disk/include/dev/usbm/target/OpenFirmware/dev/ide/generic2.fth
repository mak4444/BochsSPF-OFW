
: le-w@  ( adr -- w )  dup c@ swap ca1+ c@ bwjoin  ;

: ide-get-drive-parms  ( -- found? )
   d# 512 /block!

   false  atapi-drive?!
   0      drive-type!

   wait-while-busy  if  false exit  then
   2 r-dor!             \ Turn off IRQ14

   0 drive r-head!

   h# ec r-csr!		\ Identify command

   scratchbuf d# 512 pio-rblock  if  false exit  then

   scratchbuf 1 wa+ le-w@ /cyls!
   scratchbuf 3 wa+ le-w@ /heads!
   scratchbuf 6 wa+ le-w@ /secs!

\   /cyls h# 3fff u>=  if
   scratchbuf d# 49 wa+ w@ h# 200 and  if  \ LBA
      scratchbuf d# 60 wa+ le-w@
      scratchbuf d# 61 wa+ le-w@
      wljoin /lba!
   then

   true
;

: get-drive-parms  ( -- found? )
   \ Reset this string (primary or secondary) on the first time through,
   \ in order to clear any errors that might be hanging around from uses
   \ of the drive by previous software.
   drive 0=  if  4 r-dor!  0 r-dor!  then

   wait-while-busy  if  false exit  then
   0 drive r-head!		\ select drive
   0 r-dor!			\ flush ISA bus
   6 reg@ h# a0 drive 4 lshift or  = if
      r-cyl@ eb14 =  if
         \ If H/W reset resets the IDE bus, there's no need for atapi-reset
	 \ Unfortunately, the vl-reset on the Shark does not seem to fully
	 \ reset the ATAPI drive, therefore, we are doing it here.
         atapi-reset		\ atapi soft reset
         atapi-get-drive-parms     ( found? )
      else
         r-csr@ 0<>  r-csr@ h# ff <>  and  if
            drive 0=  if
               wait-until-ready  if  false exit  then
            then	\ wait until spin-up
            r-csr@ h# f0 and h# 50 =  if
               ide-get-drive-parms                 ( found? )
            else
               false                               ( found? )
            then
         else
            false                                  ( found? )
         then
      then
   else
      false                                        ( found? )
   then
;

external

: block-size  ( -- n )  0 drive r-head!  /block@  ;
: #blocks  ( -- n )
   atapi-drive?@  if
     atapi-capacity
   else
     /lba ?dup  0=  if               ( )
        /cyls /secs /heads * *       ( #blocks )
     then                            ( #blocks )
   then                              ( #blocks )
;

: dma-alloc  ( n -- vaddr )  " dma-alloc" $call-parent  ;
: dma-free  ( vaddr n -- )  " dma-free" $call-parent  ;
: max-transfer  ( -- n )   d# 256 /block@ *  ;
: read-blocks   ( addr block# #blocks -- #read )
   atapi-drive?@  if  atapi-read  else  true  r/w-blocks  then
;
: write-blocks  ( addr block# #blocks -- #written )
   atapi-drive?@  if  atapi-write  else  false r/w-blocks  then
;
: ide-inquiry  ( -- false | drive-type true )
   /block@ 0=  if  false  else  drive-type@ true  then
;
: ide-drive-inquiry  ( log-drive -- false | drive-type true )
   dup max#drives >=  if  drop false  else  to log-drive  ide-inquiry  then
;

: set-address  ( dummy unit -- )
   \ units 0 and 1 are primary ide drives, 2 and 3 are secondary ide drives
   nip dup to log-drive 1 and to drive
   log-drive 2 <  if  pri-chip-base pri-dor  else  sec-chip-base sec-dor  then
   to dor to chip-base
;

\ For switching between programmed-I/O and DMA operational modes

0 instance value 'open-dma
0 instance value 'close-dma
0 instance value 'set-drive-cfg
defer close-dma  ' noop is close-dma
defer open-dma   ' noop to open-dma
defer set-drive-cfg  ' noop to set-drive-cfg
: save-dma-open  ( -- )
   ['] open-dma      behavior to 'open-dma
   ['] close-dma     behavior to 'close-dma
   ['] set-drive-cfg behavior to 'set-drive-cfg
;
: restore-open-dma  ( -- )
   'open-dma      ?dup  if  to open-dma       then
   'close-dma     ?dup  if  to close-dma      then
   'set-drive-cfg ?dup  if  to set-drive-cfg  then
;

: parse-args  ( -- flag )
   my-args  begin  dup  while       \ Execute mode modifiers
      ascii , left-parse-string            ( rem$ first$ )
      my-self ['] $call-method  catch  if  ( rem$ x x x )
         ." Unknown argument" cr
         3drop 2drop false exit
      then                                 ( rem$ )
   repeat                                  ( rem$ )
   2drop
   true
;

: open-hardware  ( -- flag )
   parse-args 0=  if  false exit  then
   (map)  to sec-dor  to sec-chip-base  to pri-dor  to pri-chip-base
   open-dma

   first-open?  if
      max#drives 0  do
         d# 80 ms
         0 i  set-address  get-drive-parms  if  set-drive-cfg  then  loop
      false to first-open?
   then

   0 0 set-address		\ Default

   \ should perform a quick "sanity check" selftest here,
   \ returning true iff the test succeeds.

   true
;
: reopen-hardware  ( -- flag )  parse-args  ;

: close-hardware  ( -- )
   close-dma   
   pri-chip-base pri-dor sec-chip-base sec-dor (unmap)
   restore-open-dma
;
: reclose-hardware  ( -- )  restore-open-dma  ;

: selftest  ( -- 0 | error-code )
   \ perform reasonably extensive selftest here, displaying
   \ a message if the test fails, and returning an error code if the
   \ test fails or 0 if the test succeeds.
   0
;

: open  ( -- flag )
   open-count  if
      reopen-hardware  dup  if  open-count 1+ to open-count  then
      exit
   else
      open-hardware  dup  if
         1 to open-count
      then
   then
;
: close  ( -- )
   open-count 1- to open-count
   open-count  if
      reclose-hardware
   else
      close-hardware
   then
;

: set-blk-w  ( w@-addr w!-addr -- )  to io-blk-w! to io-blk-w@  ;

[ifdef] notyet
: set-pio-mode  ( mode -- )
   3 r-features!
   8 or r-#secs!
   h# ef r-csr!
;
[then]

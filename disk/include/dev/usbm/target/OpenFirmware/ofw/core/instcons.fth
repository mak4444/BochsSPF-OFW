purpose: Select and install console I/O devices

headers
" keyboard" d# 32  config-string input-device
" screen"   d# 32  config-string output-device

variable prev-stdin

headerless
: report-fb  ( -- )
   'fb-node token@  origin <>  if            ( phandle )
      'fb-node token@  " screen" 2dup aliased?  if  ( phandle name$ alias$ )
	 \ There is already an alias called screen
	 2drop 3drop                                (  )
      else                                          ( phandle name$ alias$ )
	 2drop make-node-alias                      (  )
      then
   then
;

headers
: install-console  ( -- )
   report-fb

   \ Switch to romvec I/O and use ttya at first.
   fallback-device io  console-io

   \ Open NVRAM output-device as the output device
   output-device output

   \ Open NVRAM input-device as the input device
   stdin @  prev-stdin !  input-device  input

   prev-stdin @ stdin @  =   input-device " keyboard" $=   and  if
      \ NVRAM input-device was keyboard but could not open it.

      output-device " screen"   $=  stdout @ 0<>  and  if

         ." Keyboard not present.  Using "  fallback-device type
         ."  for input and output." cr

         \ Give the user time to see the message before the screen goes blank
         d# 4000 ms
      then
      fallback-device io
   then

   \ Fail-safe in case of bad input or output device
   stdin  @  0=  if  fallback-device input   then
   stdout @  0=  if  fallback-device output  then
;

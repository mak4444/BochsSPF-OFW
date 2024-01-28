purpose: Buffers for saving program state

headers
\ Data structures defining the CPU state saved by a breakpoint trap.
\ This must be loaded before either catchexc.fth or register.fth,
\ and is the complete interface between those 2 modules.

headers
\ A place to save the CPU registers when we take a trap
0 value cpu-state               \ Pointer to CPU state save area

headerless
: >state  ( offset -- adr )  cpu-state  +  ;

h# 40 constant ua-size

ps-size  buffer: pssave		\ A place to save the Forth data stack
rs-size  buffer: rssave		\ A place to save the Forth return stack
ua-size  buffer: uasave		\ A place to save part of the Forth user area
				\ we really want to save saved-rp and saved-sp

headers
defer .exception		\ Display the exception type
defer handle-breakpoint		\ What to do after saving the state

transient
variable next-reg
0 next-reg !

: alloc-reg  ( size -- offset )   next-reg @  swap next-reg +!  ;
resident

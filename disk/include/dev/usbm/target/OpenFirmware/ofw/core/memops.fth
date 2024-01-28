purpose: Internal interfaces to memory node operations

headers
variable memory-node   ' memory-node  " memory" chosen-variable

: $call-mem-method ( ??? method$ -- ???  )  memory-node @  $call-method  ;

: mem-claim  ( [ phys.. ] size align -- base.. )  " claim" $call-mem-method  ;
: mem-release  ( phys.. size -- )  " release" $call-mem-method  ;
: mem-mode  ( -- mode )  " mode" $call-mem-method  ;

\ get-memory can be used by init-program modules instead of mem-claim
\ to avoid the need to know system-specific details
: get-memory  ( adr len -- )
\ [ '#adr-cells @ 2 = ] [if]
\   0 swap  0 mem-claim 2drop
\ [else]
   0 mem-claim drop
\ [then]
;

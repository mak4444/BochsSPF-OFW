
headerless

nuser vector     0 vector !

\ Max#rets (6) + max#args (20) + service + n_args + n_returns
6 d# 20 + 3 + /n* buffer: cb-array

\ #rets (1) + #args (1) + service + n_args + n_returns
1 1 + 3 + /n* buffer: int-cb-array

/n negate constant -/n
: !+  ( n adr -- adr' )  tuck ! na1+  ;

headers

\ This version is for the special case where there is one argument, we
\ have already checked the vector, and we don't care about the result.
\ It uses a private copy of the callback array so it can be used for
\ timer tick callbacks, which may happen during the execution of other
\ callbacks.
: ($callback1)  ( arg1 adr len -- )
   vector @  0=  if  3drop exit  then
;



: ($callback)
   ( argn .. arg1 nargs adr len -- [ retn .. ret2 Nreturns-1 ] ret1  )
   vector @  0=  if
      2drop  0  ?do  drop  loop  true exit
   then
;
: $callback  ( argn .. arg1 nargs adr len -- retn .. ret2 Nreturns-1 )
   ($callback)  throw
;
: sync  ( -- )  0 " sync" $callback drop  ;
: callback  \ service-name  rest of line  ( -- )
   parse-word  -1 parse  dup over + 0 swap c!  ( adr len arg-adr )
   -rot 1 -rot  $callback
;

also client-services definitions
: interpret  ( arg-P .. arg1 cstr -- res-Q ... res-1 catch-result )
   cscount  ['] interpret-string  catch  dup  if  nip nip  then
;

: set-callback  ( newfunc -- oldfunc )
   vector @  swap vector !
   cb-array drop		\ Force allocation now
   int-cb-array drop
;
previous definitions

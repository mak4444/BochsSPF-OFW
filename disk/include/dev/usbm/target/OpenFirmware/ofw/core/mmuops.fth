purpose: Call MMU node methods

0 value pagesize
headerless
0 value pageshift

headers
variable mmu-node   ' mmu-node  " mmu" chosen-variable

: $call-mmu-method ( ??? method$ -- ???  )  mmu-node @  $call-method  ;

: mmu-translate  ( virt -- false | phys.. mode true )
   " translate" $call-mmu-method
;

: mmu-map  ( phys.. virt size mode -- )  " map" $call-mmu-method  ;
: mmu-claim  ( [ virt ] size align -- base )  " claim" $call-mmu-method  ;
: mmu-release  ( virt size -- )  " release" $call-mmu-method  ;
: mmu-unmap  ( virt size -- )  " unmap" $call-mmu-method  ;

: mmu-lowbits   ( adr1 -- lowbits  )  pagesize  1-     and  ;
: mmu-highbits  ( adr1 -- highbits )  pagesize  round-down  ;

: >physical  ( virt -- phys.. )
   >r r@ mmu-translate  if  drop r> drop  else  r>  then
;

defer memory?  ( phys.. -- flag )

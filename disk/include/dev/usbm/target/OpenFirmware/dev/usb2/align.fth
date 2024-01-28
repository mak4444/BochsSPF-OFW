purpose: Aligned dma aligned alloc and free

hex
headers

d# 256 constant /align256
d#  16 constant /align16
d#  32 constant /align32

: round-up  ( n align -- n' )  1- tuck + swap invert and  ;

external
: dma-push     ( virt phys size -- )         " dma-push" $call-parent     ;
: dma-pull     ( virt phys size -- )         " dma-pull" $call-parent     ;
: dma-alloc    ( size -- virt )              " dma-alloc" $call-parent    ;
: dma-free     ( virt size -- )              " dma-free" $call-parent     ;
: dma-map-in   ( virt size cache? -- phys )  " dma-map-in" $call-parent   ;
: dma-map-out  ( virt phys size -- )         " dma-map-out" $call-parent  ;

headers

: aligned-alloc  ( size align -- unaligned-virt aligned-virtual )
   dup >r + dma-alloc  dup r> round-up
;
: aligned-free  ( virtual size align -- )  + dma-free  ;

: aligned16-alloc  ( size -- unaligned-virt aligned-virtual )
   /align16 aligned-alloc
;
: aligned16-free  ( virtual size -- )
   /align16 aligned-free
;

: aligned16-alloc-map-in  ( size -- unaligned-virt aligned-virt phys )
   dup >r aligned16-alloc
   dup r> true dma-map-in
;
: aligned16-free-map-out  ( unaligned virt phys size -- )
   dup >r dma-map-out
   r> aligned16-free
;

: aligned32-alloc  ( size -- unaligned-virt aligned-virtual )
   /align32 aligned-alloc
;
: aligned32-free  ( virtual size -- )
   /align32 aligned-free
;

: aligned32-alloc-map-in  ( size -- unaligned-virt aligned-virt phys )
   dup >r aligned32-alloc
   dup r> true dma-map-in
;
: aligned32-free-map-out  ( unaligned virt phys size -- )
   dup >r dma-map-out
   r> aligned32-free
;

: aligned256-alloc  ( size -- unaligned-virt aligned-virtual )
   /align256 aligned-alloc
;
: aligned256-free  ( virtual size -- )
   /align256 aligned-free
;


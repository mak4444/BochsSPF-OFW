\ "Little-endian" memory operations.  The least-significant byte is
\ stored at the lowest address.  "Intel byte order".

\ mmo private

: lew@  ( adr -- w )  dup c@  swap 1+ c@  bwjoin  ;
: lew!  ( w adr -- )  2dup c!  swap 8 >> swap 1+ c!  ;
: lel@  ( adr -- l )  dup lew@ swap 2+ lew@ wljoin  ;
: lel!  ( l adr -- )  >r lwsplit r@ 2+ lew! r> lew!  ;

\ Fetches 3 consecutive bytes in Intel byte order - least significant
\ at the lowest address
: le24@  ( adr -- l )  >r  r@ c@  r@ 1+ c@  r> 2+ c@  0 bljoin  ;

\ Stores 3 consecutive bytes in Intel byte order - least significant
\ at the lowest address
: le24!  ( l adr -- )  >r lbsplit drop  r@ 2+ c!  r@ 1+ c!  r> c!  ;

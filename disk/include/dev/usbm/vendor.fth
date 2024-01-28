purpose: Vendor/product table manipulation

headers
hex

\ Each vendor/product table has two fields (each /w length).
\ XXX May consider expanding the table to include a name field for each
\ XXX entry so that we can support drastically different devices without
\ XXX resorting to a super driver.

/w 2* constant /vendor-product

: find-vendor-product?  ( vid pid list /list -- flag )
   >r >r 0 -rot r> r>  bounds  ?do
      over i w@ = 		( flag vid pid vid=? )
      over i wa1+ w@ = and	( flag vid pid flag' )
      if  rot drop true -rot leave  then	( flag vid pid )
   /vendor-product +loop 	( flag' vid pid )
   2drop
;


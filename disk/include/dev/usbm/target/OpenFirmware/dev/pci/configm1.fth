purpose: Configuration space access using "configuration mechanism 1"

\ Ostensibly this applies to the PCI bus and thus should be in the PCI node.
\ However, many of the host bridge registers are accessed via this mechanism,
\ so it is convenient to make the configuration access words globally-visible.
\ This mechanism works for several different PCI host bridges.

headerless

defer config-map
: config-map-m1  ( config-adr -- port )
   dup  3 invert and  h# 8000.0000 or  h# cf8 pl!  ( config-adr )
   3 and  h# cfc or  io-base +
;
' config-map-m1 to config-map

headers

: config-l@  ( config-addr -- l )  config-map rl@  ;
: config-l!  ( l config-addr -- )  config-map rl!  ;
: config-w@  ( config-addr -- w )  config-map rw@  ;
: config-w!  ( w config-addr -- )  config-map rw!  ;
: config-b@  ( config-addr -- c )  config-map rb@  ;
: config-b!  ( c config-addr -- )  config-map rb!  ;

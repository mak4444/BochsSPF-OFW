\ Cluster access

\ mmo private

: cl#>sector#  ( cluster# -- sector# )
   2 -  spc c@ *  cl-sector0 l@ +
;
: cl>sector  ( cluster# #clusters -- sector# #sectors )
   swap  cl#>sector#                ( #clusters sector# )
   swap  spc c@ *                   ( sector# #sectors )
;

: read-clusters  ( cluster# #clusters adr -- error? )
   >r  cl>sector  r>  read-sectors
;
: write-clusters  ( cluster# #clusters adr -- error? )
   >r  cl>sector  r>  write-sectors
;

\ initsave.fth 1.1 94/09/01

headers
: $find-name  ( name -- acf )
   $find  0= if  ." Can't find " type  cr  abort  then
;
headerless
: init-save  ( 'init-environment -- )
                 $find-name is init-environment
   " init"       $find-name is do-init
   " (cold-hook" $find-name is cold-hook

   here fence a!			\ Protect the dictionary
;
headers


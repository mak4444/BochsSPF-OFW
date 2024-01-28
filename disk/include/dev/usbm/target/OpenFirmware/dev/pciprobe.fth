purpose: PCI probing user interface commands

: probe-pci  ( -- )
   " /pci" open-dev  ?dup  if   ( ihandle )
      iselect
\      " pci-probe-list" eval
" 0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f,10,11,12,13,14,15,16,17,18,19,1a,1b,1c,1d,1e,1f"
 CR  ."  master-probe eval=" HERE .H
  " master-probe" eval
      unselect-dev

   then
;

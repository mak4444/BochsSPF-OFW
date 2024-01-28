\ Relocation table.  
\ Keeps a bitmap identifying longwords that need to be relocated
\ if they are saved to a file.

variable memtop

: max-image  ( -- #bytes )  memtop @  origin -  ;

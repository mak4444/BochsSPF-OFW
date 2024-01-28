\ .current-word  ( ip -- )	"ip" is an address which is presumed to
\				be within the body of some colon definition.
\				.current-word displays the name of that
\				definition.

\ .caller  ( ip -- )		Displays the colon definition name as in
\				.current-word, and also the address "ip"

decimal

only forth also hidden also forth definitions

headers
: .current-word  ( ip -- )  find-cfa  ( acf )  .name  ;

headerless 
: .caller  ( ip -- )
   td 18 to-column ." Called from "  dup .current-word
   td 56 to-column ." at "  9 u.r
;
headers 
only forth also definitions

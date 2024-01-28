purpose: Register access words

\ These versions of the "r" words treat addresses in the top 64K
\ as I/O addresses, performing I/O cycles instead of memory cycles.

\ Equivalent to:
\ : rb@  ( adr -- b )
\    dup h# ffff.0000 u>=  if  h# ffff and pc@  else  c@  then
\ ;

code rb@  ( adr -- b )
   dx pop
   ax  ax  xor
   h# ffff0000 #  dx  cmp
   u>=  if
      h# ffff #  dx  and
      dx  al  in
   else
      0 [dx]  al  mov
   then
   ax push
c;
code rw@  ( adr -- w )
   dx pop
   ax  ax  xor
   h# ffff0000 #  dx  cmp
   u>=  if
      h# ffff #  dx  and
      op:  dx  ax  in
   else
      op:  0 [dx]  ax  mov
   then
   ax push
c;
code rl@  ( adr -- l )
   dx pop
   h# ffff0000 #  dx  cmp
   u>=  if
      h# ffff #  dx  and
      dx  ax  in
   else
      0 [dx]  ax  mov
   then
   ax push
c;
code rb!  ( b adr -- )
   dx pop
   ax pop
   h# ffff0000 #  dx  cmp
   u>=  if
      h# ffff #  dx  and
      al  dx  out
   else
      al  0 [dx]  mov
   then
c;
code rw!  ( w adr -- )
   dx pop
   ax pop
   h# ffff0000 #  dx  cmp
   u>=  if
      h# ffff #  dx  and
      op:  ax  dx  out
   else
      op:  ax  0 [dx]  mov
   then
c;
code rl!  ( l adr -- )
   dx pop
   ax pop
   h# ffff0000 #  dx  cmp
   u>=  if
      h# ffff #  dx  and
      ax  dx  out
   else
      ax  0 [dx]  mov
   then
c;

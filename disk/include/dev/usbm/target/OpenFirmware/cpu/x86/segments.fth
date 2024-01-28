\ Access to alternate segments

code spacec@  ( adr space -- byte )
   ax pop   ax fs mov   bx pop   ax ax sub  fs: 0 [bx] al mov  1push
c;

code spacec!  ( byte adr space -- )
   ax pop   ax fs mov   bx pop   ax pop  fs: al 0 [bx] mov
c;

code spacel@  ( adr space -- byte )
   ax pop   ax fs mov   bx pop   fs: 0 [bx] ax mov  1push
c;

code spacel!  ( byte adr space -- )
   ax pop   ax fs mov   bx pop   ax pop  fs: ax 0 [bx] mov
c;

\ I/O space access via IN and OUT instructions

code pc@  ( b adr -- )  dx pop  ax ax xor      dx al in  ax push   c;
code pw@  ( adr -- w )  dx pop  ax ax xor  op: dx ax in  ax push  c;
code pl@  ( adr -- l )  dx pop                 dx ax in  ax push  c;
code pc!  ( adr -- b )  dx pop  ax pop         al dx out  c;
code pw!  ( w adr -- )  dx pop  ax pop     op: ax dx out  c;
code pl!  ( l adr -- )  dx pop  ax pop         ax dx out  c;

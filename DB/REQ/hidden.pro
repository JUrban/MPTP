formula(
forall([B1,B2],
  not( 
    and( r2_hidden(B1,B2),
      r2_hidden(B2,B1)))),
p8_r2_hidden).

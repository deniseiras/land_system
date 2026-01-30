/* endian.c */

#include "d4o.h"

int d4o_is_little_endian()
{
  /* Little/big-endian runtime auto-detection */
  const unsigned int ulbtest = 0x12345678;
  const unsigned char *clbtest = (const unsigned char *)&ulbtest;
  
  if (*clbtest == 0x78) { 
    /* We are on a little-endian machine */
    return 1;
  }
  else { 
    /* We are on a big-endian machine */
    return 0;
  }
}

int d4o_is_big_endian()
{
  return d4o_is_little_endian() ? 0 : 1;
}

/* Fortran interface */

int c_d4o_is_big_endian_()    { return d4o_is_big_endian();    }
int c_d4o_is_little_endian_() { return d4o_is_little_endian(); }


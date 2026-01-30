
/* This is NOT a shared memory thread-safe code */

#include <stdio.h>
#include <stdlib.h>

void numarg_error(int numargs, int low, int high, char *function_name)
{
  if (numargs < low || numargs > high) {
    fprintf(stderr,
	    "*** Error: Incorrect # of args (%d) passed to function '%s'\n",
	    numargs, function_name);
    exit(1); 
  }
}

void blacklist_error(const char *statid, int category)
{
  fprintf(stderr,
	  "*** Error: Wrong category (%d) passed to BLACKLIST-interface",
	  category);
  fprintf(stderr,
	  " while processing STATID=\"%s\"\n",statid);
  exit(1);
}

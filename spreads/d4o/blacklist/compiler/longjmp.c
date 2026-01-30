
/*  longjump.c  */

#include "bldefs.h"
#include <setjmp.h>

PRIVATE jmp_buf BL_jump_here;

int BL_eval_tree(int ntimes, 
		 void (*feedback_func)(int feedback[], int *nfeedback),
		 int feedback[], int nfeedback)
{
  int i=0;

  for (;;) {
    setjmp(BL_jump_here);
    i++;
    if (i>ntimes) break;
    BL_reset_all();
    BL_execute_cmd(BL_start_cmd(),NULL);
  }

  if (feedback_func && feedback) {
    feedback_func(feedback, &nfeedback);
  }

  return i-1;
}


void BL_do_long_jump()
{
  longjmp(BL_jump_here, 0);
}

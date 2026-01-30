
/* Built-in, single- and multiargument functions */

#include "bldefs.h"

extern int BL_debug;

static struct {
  char *name;	
  char *prototype;
  unsigned char referred;
  double (*func)(int numargs, const double *arg);
  int maxargs;
} func_list[] = {
  "@oneof", NULL, 0, BL_oneof, -1, 
  "fail", NULL, 0, BL_fail, -BLMAGIC, /* variable number of args ; even zero */
  "rad", "BL_rad", 0, BL_rad, 5,
  "dist", "BL_dist", 0, BL_dist, 5,
  "cputime", "BL_cputime", 0, BL_cputime, 0,
  "exp", "BL_exp", 0, BL_exp, 1,
  "ln", "BL_ln", 0, BL_log, 1,
  "log", "BL_log", 0, BL_log, 1,
  "log10", "BL_log10", 0, BL_log10, 1,
  "lg", NULL, 0, BL_log10, 1,
  "sqrt", "BL_sqrt", 0, BL_sqrt, 1,
  "xor", "BL_xor", 0, BL_xor, 2,
  "mod", "BL_mod", 0, BL_mod, 2,
  "max", "BL_max", 0, BL_max, -1, /* variable number of args, but always > 0 */
  "min", "BL_min", 0, BL_min, -1,
  "sum", "BL_sum", 0, BL_sum, -1,
  "prod", "BL_prod", 0, BL_prod, -1,
  "abs", "BL_abs", 0, BL_abs, 1,
  "sin", "BL_abs", 0, BL_sin, 1,
  "cos", "BL_cos", 0, BL_cos, 1,
  "tan",  "BL_tan", 0,  BL_tan , 1,
  "asin", "BL_asin", 0, BL_asin, 1,
  "acos", "BL_acos", 0, BL_acos, 1,
  "atan", "BL_atan", 0, BL_atan, -1,
  "sinh", "BL_sinh", 0, BL_sinh, 1,
  "cosh", "BL_cosh", 0, BL_cosh, 1,
  "tanh", "BL_tanh", 0, BL_tanh, 1,
  "int", "BL_int", 0, BL_int, 1,
  "round", "BL_round", 0, BL_round, 1,
  "ceil", "BL_ceil", 0, BL_ceil, 1,
  "floor", "BL_floor", 0, BL_floor, 1,
  "rand", "BL_rand", 0, BL_rand, 0,
  "srand", "BL_srand", 0, BL_srand, 1,
  "basetime", "BL_basetime", 0, BL_basetime, 2,
  "abort", NULL, 0, BL_abort, 0,
  NULL
};

void BL_write_function_prototypes(FILE *fp)
{
  int i;
  fprintf(fp,"#include <stdio.h>\n");
  fprintf(fp,"#include <stdlib.h>\n");
  fprintf(fp,"#include <string.h>\n");
  fprintf(fp,"#include <math.h>\n");
  fprintf(fp,"\n");
  fprintf(fp,"#define BL_VAR_ARGS , ...\n");
  for (i=0; func_list[i].name; i++) {
    if (func_list[i].referred && func_list[i].prototype) {
      fprintf(fp,
	      "extern double %s(int numargs, const double *arg BL_VAR_ARGS);\n",
	      func_list[i].prototype);
    }
  }
  fprintf(fp,"\n");
}

int BL_install_builtin(char *name)
{
  int i;
  int success = 0;

  for (i=0; func_list[i].name; i++) {
    if (strcmp(name,func_list[i].name) == 0) {
      int maxargs = func_list[i].maxargs;
      BL_store(BL_BLTIN,func_list[i].name,
	       0.0,NULL,
	       func_list[i].func, maxargs);
      
      func_list[i].referred = 1;

      if (BL_debug) {
	int j;
	printf("Installing ... %s(",func_list[i].name);
	if (maxargs > 0) {
	  for (j=1; j<=maxargs; j++) 
	    printf("arg%d%s",j,(j<maxargs)?",":"\0");
	} else if (maxargs < 0) {
	  printf("<varargs>");
	}
	printf(")\n");
      }

      success = 1;

      break;
    }
  }

  return success;
}

#include "funcs_bla.h"

double BL_oneof(int numargs, const double *arg)
{
  int i;
  int irc = 0;
  double ref = arg[0];

  for (i=1; !irc && i<numargs; i++) {
    irc = (arg[i] == ref);
  }

  return irc;
}



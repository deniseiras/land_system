
/* main.c */

#include "bldefs.h"

PUBLIC int BL_debug = 0;
PUBLIC int BL_print_symbol_table = 0;

#define setlinebuf(fp) setvbuf((fp),NULL,_IOLBF,MAXLINE)

/* 
   When IS_MAIN_PROG is not set, you must create before linking
   a tiny main program which calls bl95main() as follows:
   
   echo 'int main(int argc, char *argv[]) { return bl95main(argc, argv); }' > main.c

*/

int 
#ifdef IS_MAIN_PROG
main(int argc, char *argv[])
#else
bl95main(int argc, char *argv[])
#endif
{
  char *blfile=NULL;
  double t1, t2;
  int i, ntimes;
  int irc;

  setlinebuf(stdout);

  BL_debug      = getenv("BL_DEBUG") ? 1 : 0;
  BL_print_symbol_table = getenv("BL_PRINT_SYMBOL_TABLE") ? 1 : 0;

  /* BL_init_defaults(BL_load_constants); */
  BL_init_defaults(NULL);

  if (argc > 1) {
    blfile = argv[argc-1];

    if (argc > 2) {
      for (i=1; i<argc-1; i++) {
	char *var = argv[i];
	char *p = strchr(argv[i],'=');
	char *value = (p) ? p+1 : NULL;
	if (p) *p = '\0';
	if (value) {
	  int len_value = strlen(value);
	  if ((value[0] == '"' && value[len_value-1] == '"') ||
	      (value[0] == '\'' && value[len_value-1] == '\'')) {
	    /* in quotes i.e. BL_STRING */
	    value[len_value-1] = '\0';
	    BL_store(BL_EXTERNAL,var,0.0,++value,NULL,0);
	  }
	  else
	    BL_store(BL_EXTERNAL,var,atof(value),NULL,NULL,0);
	}
      } /* for (i=1, ... */
    } /* if (argc > 2) */
  } /* if (argc > 1) */
  else {
    fprintf(stderr,"Usage: %s [var1=value var2=value ...] blacklist_file\n",
	    argv[0]);
    exit(1);
  }

  irc = BL_compile(blfile);

  if (irc > 0) exit(irc);

  {
    char *p = getenv("BL_NTIMES");
    ntimes = (p) ? atoi(p) : 0;
    if (ntimes < 1) ntimes = 0;
    if (ntimes > 0) {
      printf("*** Executing instructions %d time%s ...\n",
	     ntimes, ntimes > 1 ? "s" : "");
      t1 = CPUtime();
      
      BL_eval_tree(ntimes, NULL, NULL, 0);
      
      t2 = CPUtime();
      printf("\n\tTime: %.4f sec, average = %.4f sec\n", 
	     t2-t1, (t2-t1)/ntimes);
    }
  }
  exit(0);
  return 0;
}


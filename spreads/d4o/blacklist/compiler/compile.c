#include "bldefs.h"

/* Author: Sami Saarinen, ECMWF, 1995-96 */

/* Last modified: 02-Dec-2004 by SS */

PRIVATE int max_error_count = 1;
PRIVATE int error_count = 0;

PUBLIC int BL_trial_eval = 0;
PUBLIC int BL_compile_all = 0;

extern int BL_lineno;
extern int BL_nifs;
extern int BL_nsymbols;
extern int BL_nnodes;
extern int BL_ncmds;
extern int BL_count_external;
extern int BL_count_external_char;
extern int BL_count_const;
extern int BL_count_special;
extern int BL_generate_c;
extern int BL_print_symbol_table;

extern FILE *yyin;
FILE *BL_aux_yyin;
char  BL_last_line[MAXLINE] = "" ;
char *BL_file = NULL;

extern char yytext[]; /* Remember to use "flex -l" due to this yytext[] i.e. enforce %array */

void handle_cppline()
{
  /* 
     Handles line produced by /lib/cpp (ran w/o -P option) i.e.:
     # 6 "./filename"
   */
  static char filename[MAXLINE];
  char *yytext_save = STRDUP(yytext);
  char *p = yytext_save;
  char *pf = filename;
  int nc = 0;

  /* skip first '#' and read line number */
  nc = sscanf(++p,"%d",&BL_lineno);
  if (nc != 1) goto finish;

  while ( *p != '"' ) p++;
  p++;
  if ( *p == '.' ) { /* Omit "./" if applicable */
    p++;
    if ( *p == '/' ) p++;
  }
  while ( *p != '\0' && *p != '"' ) { /* Grab filename i.e. chars before '"' */
    *pf++ = *p++;
  }
  *pf = '\0';

  BL_file = filename;
  fprintf(stderr,"\tCompiling \"%s\":%d ...\n",
	  BL_file, BL_lineno);

 finish:
  FREE(yytext_save);
}

void yyerror(char *errormsg) 
{ 
  if (strlen(yytext) == 0) return; /* Probably empty file etc. ==> not a real error */

  fprintf(stderr,
	  "*** Error: %s in file \"%s\" near line %d\n",
	  errormsg,BL_file,BL_lineno);

  if (strlen(BL_last_line) > 0) {
    char *p = BL_last_line;
    while ( *p != '\0' && *p != '\n' && *p != ';' ) {
      if ( *p == '\t' ) *p = ' '; /* Implicitly changes TAB to SPACE */
      fputc(*p, stderr);
      p++;
    }

    if ( *p == ';' ) fprintf(stderr,";\n");
    else             fputc('\n',stderr);

    p = strstr(BL_last_line, yytext);
    if (p) {
      int col;
      char *s;
      for (s=BL_last_line, col=1; s != p; s++) {
	fputc('-',stderr);
	col++;
      }
      fprintf(stderr,"^\n");
    }
  }
  
  if (++error_count >= max_error_count) {
    fprintf(stderr,"Too many errors. Exiting ...\n");
    exit(BL_lineno);
  }
}


int yywrap() { return 1; }


char *BL_lowercase(char *s)
{
  char *new_s = s ? STRDUP(s) : NULL;
  char *sp = new_s;
  if (sp) {
    do {
      if (isupper(*sp)) *sp = tolower(*sp);
    } while(*++sp);
  }
  return new_s;
}


/*
int is_eof(FILE *fp)
{
  int rc = feof(fp);
  if (!rc) {
    int ch = fgetc(fp);
    if (ch == EOF) rc = 1;
    else           { fputc(ch,fp); rc = 0; }
  }
  return rc;
}
*/

int BL_compile(char *blfile)
{
  double t1, t2;
  static char vers[] = "23.11";
  static char date_str[] = __DATE__;
  static char time_str[] = __TIME__;

#if defined(CRAY) && !defined(T3D)
#define SYSTEM_NAME "(CRAY PVP)"
#endif

#ifdef T3D
#define SYSTEM_NAME "(CRAY T3D)"
#endif

#ifdef SGI
#define SYSTEM_NAME "(Silicon Graphics)"
#endif

#ifdef RS6K
#define SYSTEM_NAME "(IBM RS/6000)"
#endif

#if defined(VPP) || defined(FUJITSU)
#define SYSTEM_NAME "(Fujitsu VPP)"
#endif

#ifndef SYSTEM_NAME
#define SYSTEM_NAME "(Linux)"
#endif

  static char system_name[] = SYSTEM_NAME;

  /* setlinebuf(stdout); */

  if (!blfile) blfile = getenv("BLACKLIST");

  yyin = blfile ? fopen(blfile,"r") : NULL;

  if (!yyin) {
    fprintf(stderr,"*** Error: Unable to open blacklist_file '%s'\n",
	    blfile);
    exit(1);
  }

  BL_file = STRDUP(blfile);

  BL_trial_eval = getenv("BL_TRIAL_EVAL") ? 1 : 0;

  BL_generate_c = getenv("BL_GEN_C") ? 1 : 0;

  BL_compile_all = getenv("BL_COMPILE_ALL") ? 1 : 0;

  {
    char *p = getenv("BL_MAX_ERROR_COUNT");
    max_error_count  = p ? atoi(p) : max_error_count;
  }

  error_count = 0;

  t1 = CPUtime();

  printf("\nHPCK Blacklist Compiler, Revision %s, %s, %s   %s\n",
	 vers, date_str, time_str,
	 system_name);
  printf("Copyleft (c) 1995-1998, 2002-2004 ECMWF, 2023 HPCK. \n\n");

  BL_aux_yyin = fopen(blfile,"r");
  AUX_GETS;

  {
    int success = 0;
    while (success == 0 && !feof(yyin)) {
      success = yyparse();
    }
  }

  fclose(yyin);
  fclose(BL_aux_yyin);

  if (error_count > 0) {
    fprintf(stderr,"\nThere were errors. Exiting ...\n");
    exit(BL_lineno);
  }

  BL_compress_symbol_table();
 
  if (BL_print_symbol_table) BL_print_sym_table();

  if (BL_generate_c) BL_generate_C_code(BL_lineno);

  t2 = CPUtime();

  printf("\n\t%d lines compiled in %.4f sec.\n", BL_lineno, t2-t1);
  printf("\tNumber of statements:\t%10d",BL_ncmds);
  printf(" (%d if-statements)\n",BL_nifs);
  printf("\t   -\"-   expressions:\t%10d\n",BL_nnodes);
  printf("\t   -\"-       symbols:\t%10d",BL_nsymbols);
  printf(" (incl. %d consts and %d externals [incl. %d strings] of which %d special)\n",
	 BL_count_const,
	 BL_count_external,
	 BL_count_external_char,
	 BL_count_special);
  /*
  {
    extern int number_noops();
    int noops = number_noops();
    printf("\t   -\"-       NO-OP's:\t%10d",noops);
  }
  */
  printf("\n\n");

  return error_count;
}

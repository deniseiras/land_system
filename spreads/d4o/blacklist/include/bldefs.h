
/* bldefs.h */

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <limits.h>
#include <signal.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/stat.h>

extern void yyerror(char *s);
extern int yylex();

#define BLMAGIC 2147483647 
#define WILDCARD '.'

#ifndef NCMD_STACK
#define NCMD_STACK 1024
#endif

#ifndef NARG_STACK
#define NARG_STACK 8192
#endif

#ifndef MAXLINE
#define MAXLINE    8192
#endif

#define BL_SCALE 10000

#define BL_GTGT  BL_GT * BL_SCALE + BL_GT
#define BL_GTGE  BL_GT * BL_SCALE + BL_GE
#define BL_GEGE  BL_GE * BL_SCALE + BL_GE
#define BL_GEGT  BL_GE * BL_SCALE + BL_GT

#define BL_LTLT  BL_LT * BL_SCALE + BL_LT
#define BL_LTLE  BL_LT * BL_SCALE + BL_LE
#define BL_LELE  BL_LE * BL_SCALE + BL_LE
#define BL_LELT  BL_LE * BL_SCALE + BL_LT

#define strequ(s1,s2)     ((const void *)(s1) && (const void *)(s2) && *(s1) == *(s2) && strcmp(s1,s2) == 0)
#define strnequ(s1,s2,n)  ((const void *)(s1) && (const void *)(s2) && *(s1) == *(s2) && strncmp(s1,s2,n) == 0)

#define PRIVATE static
#define PUBLIC
#define ALLOC(n, size)  malloc(((n) + 1) * (size))
#define FREE(x) { if ((x)) {free((x)); (x) = NULL;} }
#define STRDUP  strdup
#define BLMIN(a,b) ( (a) < (b) ? (a) : (b) )
#define BLMAX(a,b) ( (a) > (b) ? (a) : (b) )

#ifdef DEBUG
#define AUX_GETS { (void)fgets(BL_last_line,sizeof(BL_last_line),BL_aux_yyin); \
		     fprintf(stderr,"\r\t%d",BL_lineno); }
#else
#define AUX_GETS { extern int BL_debug; \
                   (void)fgets(BL_last_line,sizeof(BL_last_line),BL_aux_yyin);		\
                   if (BL_debug) fprintf(stderr,"%d: %s",BL_lineno,BL_last_line); } 
#endif

typedef struct _BL_Symbol_Table {
  char   *name;     /* Name of the symbol */
  int     flag;     /* BL_UNDEF, BL_VAR, BL_CONST or BL_FUNC */
  double  dval;     /* Current floating point value of the symbol */
  char   *str;      /* Current string value of the symbol */
  double (*func)(int numargs, const double *arg); /* Pointer to built-in func interface */
  int     maxargs;  /* Maximum number of arguments to be passed into the function */
  unsigned char special; /* Flag for variable being special */
  fd_set *if_flagged; /* appropriate flag set if symbol found in the if-condition */
  struct _BL_Symbol_Table *next;
} BL_Symbol_Table;

typedef struct _BL_Tree {
  int    type;      /* BL_NAME, BL_NUMBER, BL_STRING etc. or BL_ oper-types */
  double dval;      /* Direct numeric (floating point) value */
  char   *str;      /* Direct string value */
  int    is_wildcard; /* Set to one, if direct string value (str) contains a WILDCARD */
  int    argc;
  void **argv;
} BL_Tree;

typedef struct _BL_Cmd_List {
#ifdef DEBUG
  int cmd_number;       /* Source statement number */
  char *line_text;      /* BLACKLIST-source line */
#endif
  int lineno;           /* BLACKLIST-source line number */
  unsigned char active; /* == 1, If statement is active after special var. stripping */
  int numfuncs;         /* Number of functions found in a statement */
  BL_Tree *node;        /* Pointer to the next expression */
  struct _BL_Cmd_List *next; /* Pointer to the next statement */
} BL_Cmd_List;

extern void BL_zero_if_flag();
extern char *BL_output_if_flagged_variables();
extern int *BL_output_if_flagged_varidx(int *varidx_len);
extern char *BL_lowercase(char *s);
extern BL_Tree *BL_oper(int type, void *first, void *second, void *third);
extern BL_Cmd_List *BL_new_cmd(BL_Tree *node);
extern void BL_fix_cmd(BL_Cmd_List *a_cmd, 
		       void *first, void *second, void *third, void *fourth);
extern BL_Symbol_Table *BL_store(int type, char *name, 
				 double dval, char *str, 
				 double (*func)(int numargs, const double *arg), 
				 int maxargs);
extern double evaluate(BL_Tree *pnode);
extern BL_Tree *BL_pop_arg();
extern void BL_push_arg(BL_Tree *node);
extern void BL_write_function_prototypes(FILE *fp);
extern int BL_install_builtin(char *name);
extern void BL_print_sym_table();
extern char *BL_keymap(int type);
extern void BL_init_defaults(void (*init_func)());
extern void BL_load_constants();
extern int BL_compile(char *blfile);
extern int BL_eval_tree(int ntimes, 
			void (*feedback_func)(int feedback[], int *nfeedback),
			int feedback[], int nfeedback);
extern BL_Cmd_List *BL_start_cmd();
extern void BL_execute_cmd(BL_Cmd_List *start_cmd, BL_Cmd_List *stop_cmd);
extern void BL_reset_all();
extern void BL_reset_fail();
extern double CPUtime();
extern void BL_store_special(char *name_in);
extern void BL_compress_symbol_table(void);
extern void BL_generate_C_code(int numlines);

#ifndef THIS_IS_YACC_FILE
#include "y.tab.h"
#endif

extern int BL_number(char *s);

extern double BL_exp(int numargs, const double *arg);
extern double BL_log(int numargs, const double *arg);
extern double BL_log10(int numargs, const double *arg);
extern double BL_sqrt(int numargs, const double *arg);

extern double BL_mod(int numargs, const double *arg);
extern double BL_xor(int numargs, const double *arg);
extern double BL_max(int numargs, const double *arg);
extern double BL_min(int numargs, const double *arg);
extern double BL_sum(int numargs, const double *arg);
extern double BL_prod(int numargs, const double *arg);
extern double BL_abs(int numargs, const double *arg);

extern double BL_sin(int numargs, const double *arg);
extern double BL_asin(int numargs, const double *arg);
extern double BL_sinh(int numargs, const double *arg);

extern double BL_cos(int numargs, const double *arg);
extern double BL_acos(int numargs, const double *arg);
extern double BL_cosh(int numargs, const double *arg);

extern double BL_tan(int numargs, const double *arg);
extern double BL_atan(int numargs, const double *arg);
extern double BL_tanh(int numargs, const double *arg);

extern double BL_int(int numargs, const double *arg);
extern double BL_round(int numargs, const double *arg);
extern double BL_ceil(int numargs, const double *arg);
extern double BL_floor(int numargs, const double *arg);

extern double BL_srand(int numargs, const double *arg);
extern double BL_rand(int numargs, const double *arg);

extern double BL_rad(int numargs, const double *arg);
extern double BL_dist(int numargs, const double *arg);
extern double BL_basetime(int numargs, const double *arg);
extern double BL_cputime(int numargs, const double *arg);

extern double BL_fail(int numargs, const double *arg);
extern double BL_abort(int numargs, const double *arg);
extern double BL_oneof(int numargs, const double *arg);

#define MONTHLY      1 
#define CONSTANT     2
#define EXPERIMENTAL 3
#define USE_EMISKF_ONLY    4
#define ABORT_func   8
#define MDI_failure  9

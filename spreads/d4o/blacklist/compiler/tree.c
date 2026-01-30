
/* tree.c */

#include "bldefs.h"

PRIVATE char msg[MAXLINE];
#define SETMSG0(s) sprintf(msg,(s))
#define SETMSG1(s,var) sprintf(msg,(s),(var))
#define SETMSG2(s,var1,var2) sprintf(msg,(s),(var1),(var2))
#define SETMSG3(s,var1,var2,var3) sprintf(msg,(s),(var1),(var2),(var3))

PUBLIC int BL_nifs = 0;
PUBLIC int BL_nsymbols = 0;
PUBLIC int BL_nnodes = 0;
PUBLIC int BL_count_external = 0;
PUBLIC int BL_count_external_char = 0;
PUBLIC int BL_count_const = 0;
PUBLIC int BL_count_special = 0;
PUBLIC int BL_generate_c = 0;
PUBLIC int BL_maxargs = 0;

extern int BL_print_symbol_table;

PRIVATE int dont_add_symbols = 0;
PRIVATE BL_Symbol_Table *symbol = NULL;
PRIVATE BL_Symbol_Table *last_symbol = NULL;

PRIVATE struct {
  char *name;
  int   token_def;
} keyword[] = {
  "no-op",BL_NOOP,
  "number", BL_NUMBER,
  "string", BL_STRING,
  "symbol_name", BL_NAME,
  "undef", BL_UNDEF,
  "const", BL_CONST,
  "refconst", BL_REFCONST,
  "external", BL_EXTERNAL,
  "var",   BL_VAR,
  "referenced", BL_REF,
  "user_def_func", BL_FUNC,
  "built-in_func", BL_BLTIN,
  "if", BL_IF,
  "{ /* then */", BL_THEN,
  "else {", BL_ELSE,
  "else if", BL_ELIF,
  "} /* endif */", BL_ENDIF,
  "print", BL_PRINT,
  "=", BL_ASGN,
  "str-assign", BL_STRASGN,
  "+", BL_ADD,
  "-", BL_SUB,
  "*", BL_MUL,
  "/", BL_DIV,
  "**", BL_POWER,
  "^", BL_POWER,
  "", BL_UNARY_PLUS,
  "-", BL_UNARY_MINUS,
  "||", BL_OR,
  "&&", BL_AND,
  "!", BL_NOT,
  ">", BL_GT,
  ">=", BL_GE,
  "==", BL_EQ,
  "strcmp", BL_STRCMP,
  "<", BL_LT,
  "<=", BL_LE,
  "exit", BL_EXIT,
  "return", BL_EXIT,
  "in", BL_IN,
  "notin", BL_NOTIN,
  "!=", BL_NE,
  NULL
};

char *BL_keymap(int type)
{
  static char unknown[] = "<unknown>";
  int i;
  for (i=0; keyword[i].name != NULL; i++) {
    if (type == keyword[i].token_def) return keyword[i].name;
  }
  return unknown;
}

PUBLIC BL_Symbol_Table *BL_start_symbol() { return symbol; }

void BL_print_sym_table()
{
  int i=0;
  BL_Symbol_Table *psym;
  printf("List of symbols:\n");
  for (psym=symbol; psym != NULL; psym = psym->next) {
    printf("%d: name='%s', flag=%s, dval=%.15g, str='%s'",
	   ++i,psym->name,BL_keymap(psym->flag),
	   psym->dval,psym->str);
    if (psym->if_flagged) printf(" ; if_flagged");
    if (psym->special)    printf(" ; special variable");
    if (psym->func)  {
      printf(" ; also function%s, # of args",
	     psym->name[0] == '@' ? "(internal)" : "");
      if (psym->maxargs == -BLMAGIC) printf("=[0..%d]\n",NARG_STACK);
      else if (psym->maxargs < 0)    printf("=[1..%d]\n",NARG_STACK);
      else printf("=%d\n",psym->maxargs);
    }
    else
      printf("\n");
  }
}

PUBLIC void BL_compress_symbol_table()
{
  BL_Symbol_Table *psym;
  BL_Symbol_Table *prev = NULL;

  if (BL_generate_c) {
    dont_add_symbols = 1;
    return;
  }

  if (BL_print_symbol_table) {
    printf("Before compression:\n");
    BL_print_sym_table();
  }

  for (psym=symbol; psym != NULL; ) {
    if ( psym->flag == BL_REFCONST && !psym->func && 
	/* (!psym->if_flagged || psym->dval == BLMAGIC)) { */
	(psym->dval == BLMAGIC && psym->str == NULL)) {
      if (BL_print_symbol_table) {
	printf("\tConstant '%s' removed from the symbol table\n",psym->name);
      }
      if (psym->if_flagged) {
	FREE(psym->if_flagged);
	BL_count_external--;
      }
      else
	BL_count_const--;
      if (psym->special) BL_count_special--;
      if (!prev) { /* Start of the symbol table contains BL_REFCONST's */
	symbol = psym->next;
	FREE(psym);
	psym = symbol;
      }
      else {
	prev->next = psym->next;
	FREE(psym);
	psym = prev;
      }
      BL_nsymbols--;
    }
    else {
      prev = psym;
      psym = psym->next;
    }
  }

  if (BL_print_symbol_table) {
    printf("After compression:\n");
    BL_print_sym_table();
  }

  dont_add_symbols = 1;
}


PRIVATE BL_Symbol_Table *lookup(char *name)
{
  BL_Symbol_Table *psym;

  for (psym=symbol; psym != NULL; psym = psym->next) {
    if (strcmp(psym->name,name) == 0) return psym;
  }
  return NULL; /* Not found */
}


PRIVATE BL_Symbol_Table *get_symbol(char *name)
{
  BL_Symbol_Table *psym = lookup(name);

  if (!psym) {
    if (!dont_add_symbols) {
      psym = ALLOC(1, sizeof(*psym));
      if (symbol)  
	last_symbol->next = psym;
      else 
	symbol = psym;
      last_symbol = psym;
      
      psym->name = STRDUP(name);
      psym->flag = BL_UNDEF;
      psym->dval = 0;
      psym->str  = NULL;
      psym->func = NULL;
      psym->maxargs = 0;
      psym->if_flagged = NULL;
      psym->special = 0;
      psym->next = NULL;
      
      BL_nsymbols++;
    }
    else {
      extern void BL_runtime_error(char *message);
      SETMSG1("Symbol ('%s') can't be added after the compilation",name);
      BL_runtime_error(msg);
    }
  }
  return psym;
}


void BL_zero_if_flag()
{
  BL_Symbol_Table *psym;
  extern int BL_nested_ifs;
  extern int BL_check_if_flagging;

  if (BL_check_if_flagging) {
    for (psym=symbol; psym != NULL; psym = psym->next) {
      if (psym->if_flagged) {
	if (BL_nested_ifs >= 0) {
	  if (FD_ISSET(BL_nested_ifs, psym->if_flagged))
	    FD_CLR(BL_nested_ifs, psym->if_flagged);
	}
	else
	  FD_ZERO(psym->if_flagged);
      }
    }
  }
}



PUBLIC char BL_feedback_vars[MAXLINE];

char *BL_output_if_flagged_variables()
{
  int i, count = 0;
  BL_Symbol_Table *psym;
  extern int BL_nested_ifs;

  BL_feedback_vars[0] = '\0';

  for (psym=symbol; psym != NULL; psym = psym->next) {
    if (psym->if_flagged) {
      for (i=0; i<=BL_nested_ifs; i++) {
	if (FD_ISSET(i, psym->if_flagged)) {
	  if (++count == 1) {
	    /* printf("List of feedback variable(s):"); */
	    strcat(BL_feedback_vars,"/"); 
	  }
	  /* printf(" %s",psym->name); */
	  strcat(BL_feedback_vars,psym->name);
	  strcat(BL_feedback_vars,"/");
	  break; /* from for i ... */
	}
      } /* for i ... */
    } /* if (psym->if_flagged) */
  } /* for psym ... */

  return BL_feedback_vars;
}

int *BL_output_if_flagged_varidx(int *varidx_len)
{
  int *varidx = NULL;
  int jc, count = 0;
  BL_Symbol_Table *psym;
  extern int BL_nested_ifs;

  for (psym = BL_start_symbol(); psym != NULL; psym = psym->next) {
    if (psym->flag == BL_REFCONST && psym->if_flagged) {
      int i;
      for (i=0; i<=BL_nested_ifs; i++) {
	if (FD_ISSET(i, psym->if_flagged)) {
	  count++;
	  break;
	}
      } /* for (i=0; i<=BL_nested_ifs; i++) */
    } /* if (psym->flag == BL_REFCONST && psym->if_flagged) */
  } /* for (psym = BL_start_symbol(); psym != NULL; psym = psym->next) */


  varidx = ALLOC(count, sizeof(*varidx));
  if (varidx_len) *varidx_len = count;

  count = 0;
  jc = 0;
  for (psym = BL_start_symbol(); psym != NULL; psym = psym->next) {
    if (psym->flag == BL_REFCONST && psym->if_flagged) {
      int i, found = 0;
      for (i=0; i<=BL_nested_ifs; i++) {
	if (FD_ISSET(i, psym->if_flagged)) {
	  found = 1;
	  break;
	}
      } /* for (i=0; i<=BL_nested_ifs; i++) */
      if (found) varidx[count++] = jc;
      jc++;
    } /* if (psym->flag == BL_REFCONST && psym->if_flagged) */
  } /* for (psym = BL_start_symbol(); psym != NULL; psym = psym->next) */

  return varidx;
}

PRIVATE BL_Tree *new_node(int type)
{
  BL_Tree *pnode = ALLOC(1, sizeof(*pnode));

  pnode->type    = type;
  pnode->dval    = 0.0;
  pnode->str     = NULL;
  pnode->is_wildcard = 0;
  pnode->argc    = 0;
  pnode->argv    = NULL;

  BL_nnodes++;
  return pnode;
}


PRIVATE double dval_assign(double *dval) { return *dval; }

PRIVATE double ival_assign(int *ival) { return *ival; }

PRIVATE int narg_stack = 0;
PRIVATE BL_Tree *arg_stack[NARG_STACK];

BL_Tree *BL_pop_arg()
{
  return (narg_stack > 0) ? arg_stack[--narg_stack] : NULL;
}

void BL_push_arg(BL_Tree *node)
{
  if (narg_stack >= NARG_STACK) {
    SETMSG2("Too many arguments = %d >= NARG_STACK = %d",
	    narg_stack,NARG_STACK);
    yyerror(msg);
  }
  else
    arg_stack[narg_stack++] = node;
}


PRIVATE int trial_eval(BL_Tree *pnode, double *dval)
     /* For compile-time expression evalution only */
{
  extern int BL_trial_eval;
  int irc = 0;
  *dval = 0;

  if (!BL_trial_eval) return 0;

  /* if (BL_generate_c && !BL_trial_eval) return 0; */

  if (pnode) {
    switch (pnode->type) {

    case BL_NUMBER:
      *dval = pnode->dval;
      irc = 1;
      break;

    case BL_NAME:
      {
	BL_Symbol_Table *psym = pnode->argv[0];
	if (psym->flag == BL_REFCONST && !psym->func && !psym->if_flagged) {
	  *dval = psym->dval;
	  irc = 1;
	}
      }
      break;

    case BL_BLTIN:
      {
	BL_Symbol_Table *psym = pnode->argv[0];
	int i, numargs = pnode->argc - 1;

	if (numargs >= 0) {
	  double *arg = ALLOC(numargs , sizeof(*arg));

	  irc = 1;
	  for (i=0; irc && i<numargs; i++)
	    irc *= trial_eval(pnode->argv[i+1], &arg[i]);

	  if (irc) {
	    /* Exclude BL_fail() & BL_abort() from trial evaluations */
	    if (psym->func != BL_fail && psym->func != BL_abort)
	      *dval = psym->func(numargs, arg);
	    else 
	      irc = 0; /* Not possible */
	  }
	  FREE(arg);
	}
      }
      break;
     
    case BL_ADD: 
    case BL_SUB: 
    case BL_MUL: 
    case BL_DIV: 
    case BL_POWER:
    case BL_UNARY_PLUS:
    case BL_UNARY_MINUS:
      {
	double arg[2];
	int i, numargs = BLMIN(pnode->argc,2);

	if (numargs <= 0) {
	  SETMSG1("Zero number of args for operation '%s'",BL_keymap(pnode->type));
	  yyerror(msg);
	  break;
	}

	irc = 1;
	for (i=0; i<numargs; i++) {
	  irc *= trial_eval(pnode->argv[i], &arg[i]);
	}

	if (!irc) break;

	switch (pnode->type) {
	case BL_ADD: 
	  *dval = arg[0] + arg[1];
	  break;
	case BL_SUB: 
	  *dval = arg[0] - arg[1];
	  break;
	case BL_MUL: 
	  *dval = arg[0] * arg[1];
	  break;
	case BL_DIV: 
	  {
	    if (arg[1] != 0) 
	      *dval = arg[0] / arg[1];
	    else {
	      SETMSG0("Division by zero");
	      yyerror(msg);
	    }
	  }
	  break;
	case BL_POWER:
	  *dval = pow(arg[0],arg[1]);
	  break;

	case BL_UNARY_PLUS:
	  *dval = arg[0];
	  break;

	case BL_UNARY_MINUS:
	  *dval = -arg[0];
	  break;

	} /* switch (pnode->type) [inner] */
      }
      break;

    default:
      irc = 0;
      break;

    } /* switch (pnode->type) [outer] */
  } /* if (pnode) */

  return irc;
}

PUBLIC double evaluate(BL_Tree *pnode)
{
  extern int BL_trial_eval;
  int tmp_BL_trial_eval = BL_trial_eval;
  double dval = 0;

  BL_trial_eval = 1;

  if (!trial_eval(pnode, &dval)) {
    extern void BL_runtime_error(char *message);
    SETMSG0("Expression too complex");
    BL_runtime_error(msg);
  }

  BL_trial_eval = tmp_BL_trial_eval;
  return dval;
}

BL_Tree *BL_oper(int type, void *first, void *second, void *third)
{
  BL_Tree *pnode = new_node(type);
  BL_Symbol_Table *psym;
  extern int BL_undef_warning;
  extern int BL_nested_ifs;

  switch (type) {
  case BL_NOOP:
    break;

  case BL_NUMBER:
    pnode->dval = dval_assign(first);  /* "first" used to be a ptr to yylval.dval */
    break;

  case BL_STRING:
    pnode->str = STRDUP(first); /* "first" used to be yylval.str */
    pnode->is_wildcard = strchr(pnode->str,WILDCARD) ? 1 : 0;
    break;

  case BL_NAME:
    pnode->argc = 1;
    pnode->argv = ALLOC(1, sizeof(void *));
    pnode->argv[0] = psym = get_symbol(first); /* symbol table */
    if (BL_undef_warning && psym->flag == BL_UNDEF) {
      SETMSG1("Variable '%s' is uninitialized",(char *)first);
      yyerror(msg);
    }

    if (psym->flag == BL_REFCONST && psym->if_flagged && psym->dval == BLMAGIC) {
      psym->dval = 0;
    }

    if (!psym->func) {
      if (BL_install_builtin(first))
	pnode->argv[0] = psym = get_symbol(first); /* symbol table */
    }

    if (!psym->func) {
      extern int BL_lineno;
      double dval;
      if ( trial_eval(pnode, &dval) ) {
	pnode->type = BL_NUMBER;
	pnode->dval = dval;
	pnode->str  = psym->str;
	pnode->argc = 0;
	FREE(pnode->argv);
      }
    }
    break;

  case BL_BLTIN:
    { 
      int i, numargs = ival_assign(second);
      BL_maxargs = BLMAX(BL_maxargs, numargs);
      pnode->argc = numargs + 1;
      pnode->argv = ALLOC((numargs+1), sizeof(void *));
      pnode->argv[0] = psym = get_symbol(first); /* symbol table */
      if (!psym->func) {
	if (BL_install_builtin(first))
	  pnode->argv[0] = psym = get_symbol(first); /* symbol table */
      }
      if (!psym->func) {
	SETMSG1("Unrecognized function '%s'",psym->name);
	yyerror(msg);
      }
      if (psym->maxargs >= 0 && numargs != psym->maxargs) {
	SETMSG3("'%s' is designed to have %d args; given %d;",
		psym->name, psym->maxargs, numargs);
	yyerror(msg);
      } 
      else if (numargs == 0 &&
	       psym->maxargs != 0 && 
	       psym->maxargs != -BLMAGIC) {
	SETMSG2("'%s' is designed to have more than zero args; given %d;",
		psym->name, numargs);
	yyerror(msg);
      }
      else {
	extern int BL_lineno;
	double dval;
	for (i=numargs; i>0; i--) {    /* Note reverse ordering because of stack */
	  BL_Tree *expr = BL_pop_arg();
	  if (expr->type != BL_STRING) {
	    pnode->argv[i] = expr; /* Arguments (BL_Tree) from expr-stack */
	  }
	  else {
	    SETMSG2("Attempt to pass a string arg ('%s') to function '%s'",
		    expr->str, psym->name);
	    yyerror(msg);
	  }
	}

	if ( trial_eval(pnode, &dval) ) {
	  pnode->type = BL_NUMBER;
	  pnode->dval = dval;
	  pnode->str  = NULL;
	  pnode->argc = 0;
	  FREE(pnode->argv);
	}

      }
    }
    break;

  case BL_IN:
    {
      int i, numargs = ival_assign(second);
      pnode->argc = numargs;
      if (numargs <= 0) {
	SETMSG0("Empty OR-list");
	yyerror(msg);
      }
      else {
	int i;
	int all_dvals = (BL_generate_c) ? 0 : 1;
	int count_strcmp = 0;
	int got_wildcard = 0;
	BL_Tree **next_expr = ALLOC(numargs, sizeof(BL_Tree *));

	pnode->argv = ALLOC(numargs, sizeof(void *));
	for (i=numargs-1; i>=0; i--) {
	  next_expr[i] = BL_pop_arg();
	  if (next_expr[i]->type == BL_STRING) {
	    /* next_expr[i]->is_wildcard = strchr(next_expr[i]->str,WILDCARD) ? 1 : 0; */
	    got_wildcard |= next_expr[i]->is_wildcard;
	    pnode->argv[i] = BL_oper(BL_STRCMP, first, next_expr[i], NULL);
	    all_dvals = 0; /* Disables use of @oneof-func */
	    count_strcmp++;
	  }
	  else
	    pnode->argv[i] = BL_oper(BL_EQ, first, next_expr[i], NULL);
	}

	if (all_dvals) { /* VARIAB in (a,b,c) ==> @oneof(VARIAB,a,b,c) */
	  BL_push_arg(first);
	  for (i=0; i<numargs; i++) {
	    BL_push_arg(next_expr[i]);
	  }
	  numargs++;
	  FREE(pnode->argv);
	  FREE(pnode);
	  BL_nnodes--;
	  pnode = BL_oper(BL_BLTIN, "@oneof", &numargs, NULL);
	}
	else if (count_strcmp == numargs && got_wildcard) { 
	  /* All some sort of strcmp() with some of them requesting wildcard_strcmp() */
	  /* Pick them up so that the strcmp()'s will come first, the wildcard_strcmp()'s last */
	  for (i=0; i<numargs; i++) {
	    if (!next_expr[i]->is_wildcard) BL_push_arg(next_expr[i]);
	  }
	  for (i=0; i<numargs; i++) {
	    if (next_expr[i]->is_wildcard) BL_push_arg(next_expr[i]);
	  }
	  FREE(pnode->argv);
	  pnode->argv = ALLOC(numargs, sizeof(void *));
	  for (i=numargs-1; i>=0; i--) {
	    BL_Tree *rhs = BL_pop_arg();
	    pnode->argv[i] = BL_oper(BL_STRCMP, first, rhs, NULL);
	  }
	}

	FREE(next_expr);
      }
    }
    break;

  case BL_PRINT:
    {
      int i, numargs = ival_assign(first);
      pnode->argc = numargs;
      pnode->argv = ALLOC(numargs, sizeof(void *));
      for (i=numargs-1; i>=0; i--) {
	pnode->argv[i] = BL_pop_arg();
      }
    }
    break;

  case BL_ASGN:
    BL_undef_warning = 0;
    pnode->argc = 2;
    pnode->argv = ALLOC(2, sizeof(void *));
    pnode->argv[0] = psym = get_symbol(first);  /* symbol table */
    if (psym->flag == BL_REFCONST) {
      SETMSG1("Attempt to overwrite constant '%s'",(char *)first);
      yyerror(msg);
    }
    if (BL_nested_ifs >= 0 && psym->flag == BL_UNDEF) {
      fprintf(stderr,
	      "*** Warning: Variable '%s' is first time defined within an IF-block\n",
	      psym->name);
    }

    psym->flag = BL_REF;
    {
      extern int BL_lineno;
      double dval;
      if ( trial_eval(second, &dval) ) {
	pnode->argv[1] = BL_oper(BL_NUMBER, &dval, NULL, NULL);
      }
      else {
	pnode->argv[1] = second; /* expr */
      }
    }
    break;

  case BL_STRASGN:
    {
      BL_Tree *right = second;
      if (right->type == BL_STRING) {
	BL_undef_warning = 0;
	pnode->argc = 2;
	pnode->argv = ALLOC(2, sizeof(void *));
	pnode->argv[0] = psym = get_symbol(first);  /* symbol table */
	if (psym->flag == BL_REFCONST) {
	  SETMSG1("Attempt to overwrite constant '%s'",(char *)first);
	  yyerror(msg);
	}
	if (BL_nested_ifs >= 0 && psym->flag == BL_UNDEF) {
	  fprintf(stderr,
		  "*** Warning: Variable '%s' is first time defined within an IF-block\n",
		  psym->name);
	}
	psym->flag = BL_REF;
	if (!psym->str) psym->str  = "@dummy@";
	pnode->argv[1] = second; /* BL_STRING */
      }
      else
	yyerror("Invalid string assignment");
    }
    break;

  case BL_ADD:
  case BL_SUB:
  case BL_MUL:
  case BL_DIV:
  case BL_POWER:
  case BL_GT:
  case BL_GE:
  case BL_EQ:
  case BL_LE:
  case BL_LT:
  case BL_NE:
  case BL_AND:
  case BL_OR:
    pnode->argc = 2;
    pnode->argv = ALLOC(2, sizeof(void *));
    pnode->argv[0] = first;   /* left expr */
    pnode->argv[1] = second;  /* right expr */
    break;

  case BL_STRCMP:
    {
      BL_Tree *left  = first;
      BL_Tree *right = second;
      if (left->type == BL_NAME && (right->type == BL_STRING ||
				    right->type == BL_NUMBER) ) {
	pnode->argc = 2;
	pnode->argv = ALLOC(2, sizeof(void *));
	pnode->argv[0] = first;   /* left expr, which is now BL_NAME */
	if (right->type == BL_STRING) {
	  pnode->argv[1] = second;  /* right expr, which MUST be BL_STRING */
	}
	else {
	  pnode->type = BL_EQ;
	  pnode->argv[1] = second;  /* right expr, which is now BL_NUMBER */
	}
      }
      else
	yyerror("Invalid string comparison");
    }
    break;

  case BL_UNARY_PLUS: 
  case BL_UNARY_MINUS: 
  case BL_NOT: 
    pnode->argc = 1;
    pnode->argv = ALLOC(1, sizeof(void *));
    pnode->argv[0] = first;   /* expr */
    break;

  case BL_GTGT:
  case BL_GTGE:
  case BL_GEGE:
  case BL_GEGT:
  case BL_LTLT:
  case BL_LTLE:
  case BL_LELE:
  case BL_LELT:
    {
      int XX = type / BL_SCALE;
      int YY = type % BL_SCALE;
      pnode->argc = 2;
      pnode->argv = ALLOC(2, sizeof(void *));
      type = pnode->type = BL_AND;   /* Switch type to BL_AND */
      pnode->argv[0] = BL_oper(XX, first, second, NULL);  /* left & middle expr */
      pnode->argv[1] = BL_oper(YY, second, third, NULL);  /* middle & right expr */
    }
    break;   

  case BL_IF:
    pnode->argc = 4;
    pnode->argv = ALLOC(4, sizeof(void *));
    pnode->argv[0] = first;  /* condition (BL_Tree) */
    pnode->argv[1] = second; /* THEN-block (BL_Cmd_List) */
    pnode->argv[2] = third;  /* ELSE-block or NULL (BL_Cmd_list) */
    pnode->argv[3] = NULL;   /* resume point after IF i.e. ENDIF; 
				to be filled later in BL_fix_cmd() */
    BL_nifs++;
    break;

  case BL_ELIF:
    pnode->argc = 4;
    pnode->argv = ALLOC(4, sizeof(void *));
    pnode->argv[0] = first;  /* condition (BL_Tree) */
    pnode->argv[1] = second; /* THEN-block (BL_Cmd_List) */
    pnode->argv[2] = third;  /* ELSE-block or NULL (BL_Cmd_list) */
    pnode->argv[3] = NULL;   /* resume point after IF i.e. ENDIF; 
				to be filled later in BL_fix_cmd() */
    break;

  case BL_ELSE:  /* Marks end of IF-THEN -block */
    break;

  case BL_ENDIF: /* Marks end of IF-THEN-(ELSE) -block */
    break;

  case BL_EXIT: /* Quick exit from blacklist-file */
    break;

  default:
    {
      char str[80];
      snprintf(str,sizeof(str),"Invalid operation '%s'",BL_keymap(type));
      yyerror(str);
    }
    break;
  }

  return pnode;
}



BL_Symbol_Table *BL_store(int type, char *name_in, 
			  double dval, char *str, 
			  double (*func)(int numargs, const double *arg), int maxargs)
{
  extern void BL_runtime_error(char *message);
  char *name = BL_lowercase(name_in);
  BL_Symbol_Table *psym = get_symbol(name);

  switch (type) {

  case BL_EXTERNAL:
    if (!psym->if_flagged) {
      extern int BL_check_if_flagging;
      psym->if_flagged = ALLOC(1, sizeof(fd_set));
      FD_ZERO(psym->if_flagged);
      BL_check_if_flagging = 1;
      BL_count_external++;
      if (str) BL_count_external_char++;
    }

    /* no break here */

  case BL_CONST:
    if (psym->flag != BL_UNDEF) {
      SETMSG1("Attempt to overwrite constant '%s'",name);
      BL_runtime_error(msg);
    }
    psym->flag = BL_REFCONST;
    if (str) { psym->str  = STRDUP(str); psym->dval = BLMAGIC; }
    else     { psym->dval = dval; psym->str = NULL; }
    if (type == BL_CONST) BL_count_const++;
    break;

  case BL_VAR:
    if (psym->flag != BL_REF &&
	psym->flag != BL_VAR) {
      SETMSG1("Attempt to overwrite constant '%s'",name);
      BL_runtime_error(msg);
    }
    psym->flag = BL_VAR;
    if (str) { psym->str  = STRDUP(str); psym->dval = BLMAGIC; }
    else     { psym->dval = dval; psym->str = NULL; }
    break;

  case BL_BLTIN:
    if (psym->func) {
      SETMSG1("Attempt to overwrite already defined function '%s'",name);
      BL_runtime_error(msg);
    }
    psym->func = func;
    psym->maxargs = maxargs;
    BL_maxargs = BLMAX(BL_maxargs, maxargs);
    break;

  default:
    /* Invalid type ??? */
    SETMSG0("Programming error in BL_store");
    BL_runtime_error(msg);
  }

  FREE(name);

  return psym;
}


PUBLIC void BL_store_special(char *name_in)
{
  char *name = BL_lowercase(name_in);
  BL_Symbol_Table *psym = lookup(name);

  if (psym) {
    psym->special = 1;
    BL_count_special++;
  }

  FREE(name);
}


/* eval.c */

#include "bldefs.h"

PRIVATE char msg[MAXLINE];
#define SETMSG0(s) sprintf(msg,(s))
#define SETMSG1(s,var) sprintf(msg,(s),(var))
#define SETMSG2(s,var1,var2) sprintf(msg,(s),(var1),(var2))
#define SETMSG3(s,var1,var2,var3) sprintf(msg,(s),(var1),(var2),(var3))

PRIVATE BL_Cmd_List *cmd = NULL;
PRIVATE BL_Cmd_List *last_cmd = NULL;

PRIVATE int in_if_cond = 0;
PRIVATE int mask_oper = 0;
extern int BL_nested_ifs;
PUBLIC int BL_check_if_flagging = 0;
PUBLIC int BL_undef_warning = 1;
PUBLIC int BL_last_lineno = 0;
PUBLIC int BL_ncmds = 0;
PUBLIC int BL_nevals = 0;


PUBLIC void BL_runtime_error(char *message)
{
  if (BL_last_lineno > 0) {
    fprintf(stderr,"*** Runtime error near line %d\n",BL_last_lineno);
    fprintf(stderr,"    %s\n",message);
  }
  else
    yyerror(message);

  fprintf(stderr,"Exiting ...\n");
  exit(1);
}


BL_Cmd_List *BL_start_cmd() { return cmd; }

BL_Cmd_List *BL_new_cmd(BL_Tree *node)
{
#ifdef DEBUG
  extern char BL_last_line[];
#endif
  extern int BL_lineno;

  BL_Cmd_List *pcmd = NULL;

  if (last_cmd) {
    if (last_cmd->node->type == BL_NOOP) {
      FREE(last_cmd->node);
      pcmd = last_cmd;
    }
    else 
      pcmd = ALLOC(1,sizeof(*pcmd));
  }
  else
    pcmd = ALLOC(1,sizeof(*pcmd));

  if (cmd)  
    last_cmd->next = pcmd;
  else 
    cmd = pcmd;
  last_cmd = pcmd;

  pcmd->node = node;
  pcmd->next = NULL;
  pcmd->lineno = BL_lineno;
  pcmd->active = 1;
  pcmd->numfuncs = 0;

  BL_ncmds++;
#ifdef DEBUG
  pcmd->cmd_number = BL_ncmds;
  pcmd->line_text = STRDUP(BL_last_line);
  {
    char *p = strrchr(pcmd->line_text,'\n');
    if (p) *p = '\0';
  }
#endif

  BL_undef_warning = 1;
  return pcmd;
}


void BL_fix_cmd(BL_Cmd_List *a_cmd, void *first, void *second, void *third, void *fourth)
{
  BL_Tree *pnode = a_cmd->node;
  int i, argc = (pnode->argc > 4) ? 4 : pnode->argc;
  void *argv[4];

  argv[0] = first;
  argv[1] = second;
  argv[2] = third;
  argv[3] = fourth;
  for (i=0; i<argc; i++) pnode->argv[i] = argv[i];
}


PRIVATE int ncmd_stack = 0;
PRIVATE BL_Cmd_List *cont_cmd[NCMD_STACK];

PRIVATE BL_Cmd_List *pop_cmd()
{
  return (ncmd_stack > 0) ? cont_cmd[--ncmd_stack] : NULL;
}

PRIVATE void push_cmd(BL_Cmd_List *cmd_to_stack)
{  
  if (ncmd_stack >= NCMD_STACK) {
    SETMSG1("Too many nested commands. NCMD_STACK currently set to %d",
	    NCMD_STACK);
    BL_runtime_error(msg);
  }
  else
    cont_cmd[ncmd_stack++] = cmd_to_stack;
}


PRIVATE int BL_wildcard_strcmp(const char *left_str, const char *right_str)
{ 
  int irc;
  {
    const char *pleft_str = left_str;
    const char *pright_str = right_str;
    irc = 
      (strlen(pleft_str) == strlen(pright_str)); /* Strings have to have equal len */
    for ( ; irc && *pleft_str && *pright_str; pleft_str++, pright_str++) {
      if (*pright_str == WILDCARD) continue; /* A wildcard --> no need to compare */
      irc = (*pleft_str == *pright_str);
    }
    irc = irc ? 0 : 1; /* 0 = matched, 1 = no match */
  }
  return irc;
}



PRIVATE double eval(BL_Tree *pnode);

void BL_execute_cmd(BL_Cmd_List *start_cmd, BL_Cmd_List *stop_cmd)
{
  BL_Cmd_List *pcmd = start_cmd;
  while (pcmd != stop_cmd) {
    BL_last_lineno = pcmd->lineno;
    eval(pcmd->node);
    pcmd = (ncmd_stack == 0) ? pcmd->next : pop_cmd();
  } 
}



PRIVATE double eval(BL_Tree *pnode)
{
  double rc = 0.0;

  BL_nevals++;

  if (!pnode) {
    rc = 0.0;
  }
  else {
    switch (pnode->type) {

    case BL_AND:
      { /* A huge saving in computing resources ? */
	double left, right;

	left = eval(pnode->argv[0]); /* Left side of the AND-test */
	if (left) /* Evaluate also the right side of the AND-test */
	  rc = right = eval(pnode->argv[1]);
	else
	  rc = 0;
      }
      mask_oper = 0;
      break;

    case BL_OR:
      { /* A huge saving in computing resources ? */
	double left, right;

	left = eval(pnode->argv[0]); /* Left side of the OR-test */
	if (!left) /* Evaluate also the right side of the OR-test */
	  rc = right = eval(pnode->argv[1]);
	else
	  rc = 1;
      }
      mask_oper = 0;
      break;

    case BL_IN:
      {
	rc = 0;
	if (!mask_oper) {
	  int i, numargs = pnode->argc;
	  for (i=0; !rc && i<numargs; i++) {
	    rc = eval(pnode->argv[i]);
	  }
	}
	else {
	  mask_oper = 0;
	}
      }
      break;

    case BL_NUMBER: 
      rc = pnode->dval; 
      break;

    case BL_NAME:
      {
	BL_Symbol_Table *psym = pnode->argv[0];
	if (psym->flag == BL_REFCONST ||
	    psym->flag == BL_VAR) {

	  if (in_if_cond && psym->if_flagged) {
	    if (psym->dval < BLMAGIC)
	      FD_SET(BL_nested_ifs, psym->if_flagged);
	    else
	      mask_oper = 1;
	  }

	  rc = psym->dval;
	}
	else {
	  SETMSG1("Variable '%s' has no value",psym->name);
	  BL_runtime_error(msg);
	}
      }
      break;

    case BL_IF:
      {
	double cond;

	if (BL_check_if_flagging) {
	  in_if_cond = 1; 
	  BL_nested_ifs++;
	}
	else
	  in_if_cond = 0;

	cond = eval(pnode->argv[0]); /* evaluation of the condition */
	in_if_cond = 0;
	mask_oper = 0;

	if (cond) {
	  BL_Cmd_List *start_cmd = pnode->argv[1]; /* THEN-branch */
	  BL_Cmd_List *stop_cmd  = 
	    pnode->argv[2] ? pnode->argv[2] : pnode->argv[3]; /* end of THEN-branch */
	  BL_execute_cmd(start_cmd, stop_cmd);
	}
	else if (pnode->argv[2]) {
	  BL_Cmd_List *start_cmd = pnode->argv[2]; /* ELSE-branch */
	  BL_Cmd_List *stop_cmd  = pnode->argv[3]; /* end of ELSE-branch */
	  BL_execute_cmd(start_cmd, stop_cmd);
	}

	{
	  /* Important!!! Set resume point after ENDIF */
	  BL_Cmd_List *at_endif = pnode->argv[3];
	  push_cmd(at_endif->next);
	}

	rc = cond;
      }
      break;

    case BL_ELIF:
      {
       
	double cond;
    fprintf(stderr,"*** ELIF \n");

	if (BL_check_if_flagging) {
	  in_if_cond = 1; 
	}
	else
	  in_if_cond = 0;

	cond = eval(pnode->argv[0]); /* evaluation of the condition */
	in_if_cond = 0;
	mask_oper = 0;

	if (cond) {
	  BL_Cmd_List *start_cmd = pnode->argv[1]; /* THEN-branch */
	  BL_Cmd_List *stop_cmd  = 
	    pnode->argv[2] ? pnode->argv[2] : pnode->argv[3]; /* end of THEN-branch */
	  BL_execute_cmd(start_cmd, stop_cmd);
	}
	else if (pnode->argv[2]) {
	  BL_Cmd_List *start_cmd = pnode->argv[2]; /* ELSE-branch */
	  BL_Cmd_List *stop_cmd  = pnode->argv[3]; /* end of ELSE-branch */
	  BL_execute_cmd(start_cmd, stop_cmd);
	}

	{
	  /* Important!!! Set resume point after ENDIF */
	  BL_Cmd_List *at_endif = pnode->argv[3];
	  push_cmd(at_endif->next);
	}

	rc = cond;
      }
      break;

    case BL_ELSE:
    case BL_ENDIF:

      if (BL_check_if_flagging) {
	BL_zero_if_flag();
	BL_nested_ifs--;
      }
      rc = 0.0;
      break;

    case BL_EXIT:
      {
	extern void BL_do_long_jump();
	BL_do_long_jump();
      }
      break;

    case BL_STRCMP:
      {
	BL_Tree *left  = pnode->argv[0]; /* Is a BL_NAME */
	BL_Symbol_Table *psym = left->argv[0]; 

	if (psym->flag == BL_REFCONST ||
	    psym->flag == BL_VAR) {

	  /* Minimum requirement: the left BL_NAME really has some value */

	  char *left_str = psym->str;
	  int irc;

	  if (left_str) {
	    BL_Tree *right = pnode->argv[1]; /* Is a BL_STRING */
	    char *right_str = right->str;

	    irc = (strcmp(left_str,right_str) == 0) ? 1 : 0;

	    if (irc != 1 && strchr(right_str,WILDCARD)) { /* Wildcard comparison */
	      irc = BL_wildcard_strcmp(left_str, right_str);
	    }
	    if (in_if_cond && irc && psym->if_flagged)
	      FD_SET(BL_nested_ifs, psym->if_flagged);

	    rc = irc;
	  }
	  else
	    rc = 0;
	}
	else {
	  SETMSG1("Variable '%s' has no value",psym->name);
	  BL_runtime_error(msg);
	}

      }
      break;

    case BL_BLTIN:
      {
	BL_Symbol_Table *psym = pnode->argv[0];
	int i, numargs = pnode->argc - 1;
	if (numargs > 0) {
	  double *arg = ALLOC(numargs , sizeof(*arg));
	  for (i=0; i<numargs; i++)
	    arg[i] = eval(pnode->argv[i+1]);
	  rc = psym->func(numargs, arg);
	  FREE(arg);
	}
	else
	  rc = psym->func(0, NULL);
      }
      break;

    case BL_PRINT:
      {
	int i, numargs = pnode->argc;

	for (i=0; i<numargs; i++) {
	  BL_Tree *expr = pnode->argv[i];
	  int type = expr->type;

	  switch (type) {
	  case BL_NUMBER:
	    printf(" %.15g",expr->dval);
	    break;
	  case BL_STRING:
	    printf(" %s",expr->str);
	    break;
	  case BL_NAME:
	    {
	      BL_Symbol_Table *psym = expr->argv[0];
	      if (psym->flag == BL_REFCONST ||
		  psym->flag == BL_VAR) {
		if (psym->str) 
		  printf(" %s = \"%s\"",
			 psym->name, psym->str);
		else
		  printf(" %s = %.15g",
			 psym->name, psym->dval);
	      }
	      else {
		SETMSG1("Variable '%s' has no value",psym->name);
		BL_runtime_error(msg);
	      }
	    }
	    break;
	  default:
	    printf(" %.15g",eval(expr));
	    break;  
	  }
	}
	printf("\n");
      }
      break;

    case BL_ASGN:
      {
	BL_Symbol_Table *psym = pnode->argv[0];
	rc = eval(pnode->argv[1]);
	BL_store(BL_VAR, psym->name, rc, NULL, NULL, 0);
      }
      break;

    case BL_STRASGN:
      {
	BL_Symbol_Table *psym = pnode->argv[0];
	BL_Tree *right = pnode->argv[1]; /* Is a BL_STRING always */
	BL_store(BL_VAR, psym->name, 0.0, right->str, NULL, 0);
	rc = 0;
      }
      break;

    case BL_NOOP:
      rc = 0.0;
      break;

    default:
      if (mask_oper) {
	rc = 0;
      }
      else {
	double arg[2];
	int i, numargs = BLMIN(pnode->argc,2);

	if (numargs <= 0) {
	  SETMSG1("Zero number of args for operation '%s'",BL_keymap(pnode->type));
	  BL_runtime_error(msg);
	  break;
	}

	for (i=0; i<numargs; i++)
	  arg[i] = eval(pnode->argv[i]);

	switch (pnode->type) {
	case BL_ADD: 
	  rc = arg[0] + arg[1];
	  break;
	case BL_SUB: 
	  rc = arg[0] - arg[1];
	  break;
	case BL_MUL: 
	  rc = arg[0] * arg[1];
	  break;
	case BL_DIV: 
	  {
	    if (arg[1] != 0) 
	      rc = arg[0] / arg[1];
	    else {
	      SETMSG0("Division by zero");
	      BL_runtime_error(msg);
	    }
	  }
	  break;
	case BL_POWER:
	  rc = pow(arg[0],arg[1]);
	  break;
	case BL_GT: 
	  rc = (arg[0] > arg[1]);
	  break;
	case BL_GE: 
	  rc = (arg[0] >= arg[1]);
	  break;
	case BL_EQ: 
	  rc = (arg[0] == arg[1]); 
	  break;
	case BL_LE: 
	  rc = (arg[0] <= arg[1]);
	  break;
	case BL_LT: 
	  rc = (arg[0] < arg[1]);
	  break;
	case BL_NE:
	  rc = (arg[0] != arg[1]);
	  break;
	case BL_UNARY_PLUS:
	  rc = arg[0];
	  break;
	case BL_UNARY_MINUS:
	  rc = -arg[0];
	  break;
	case BL_NOT:
	  rc = !arg[0];
	  break;
	default:
	  SETMSG2("Operation '%s' (type=%d) not supported",
		  BL_keymap(pnode->type),pnode->type);
	  BL_runtime_error(msg);
	} /* switch (pnode->type) [inner] */

      } /* else */
      break;

    } /* switch (pnode->type) [outer] */

  } /* else */

  return rc;
}


void catch_signal(int signo)
{
  signal(signo,SIG_IGN);
  SETMSG1("Received SIGNAL#%d",signo);
  BL_runtime_error(msg);
}

PRIVATE double start_time = 0, end_time = 0;
PRIVATE void print_cputime()
{
  end_time = CPUtime();
  printf("\nTotal time for blacklisting: %.4f sec.\n",
	 end_time - start_time);
}


void BL_init_defaults(void (*init_func)())
{
  static int first_time = 1;
  
  if (first_time) {
    start_time = CPUtime();
    atexit(print_cputime);
#ifdef DEBUG
    atexit(BL_print_sym_table);
#endif
    signal(SIGSEGV,catch_signal);
    signal(SIGBUS,catch_signal);
    signal(SIGKILL,catch_signal);
    signal(SIGINT,catch_signal);
    signal(SIGQUIT,catch_signal);
    first_time = 0;
  }

  if (init_func) init_func();
}


void BL_reset_all()
{
  BL_nested_ifs = -1;       /* Put before the BL_zero_if_flag()-call */
  BL_zero_if_flag();
  ncmd_stack = 0;
  in_if_cond = 0;
  mask_oper = 0;
  BL_nevals = 0;
  BL_reset_fail();
}


int number_noops()
{
  int count=0;
  BL_Cmd_List *pcmd;
  for (pcmd = cmd; pcmd != NULL; pcmd = pcmd->next) {
    if (pcmd->node->type == BL_NOOP) count++;
  }
  return count;
}

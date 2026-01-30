%{
#define THIS_IS_YACC_FILE
#include "bldefs.h"
extern int BL_nested_ifs;
extern int BL_compile_all;
%}

%union {
  double   dval;
  char    *str;
  BL_Tree *node;
  BL_Cmd_List *cmd;
  int numargs;
};

%token <dval> BL_NUMBER
%token <str>  BL_NAME BL_STRING BL_BLTIN BL_FUNC
%type  <node> expr cond strexpr nam
%type  <cmd>  stmt stmtlist if then elif else endif ifpart
%type  <numargs> arglist namlist special external

%token BL_IF BL_THEN BL_ELIF BL_ELSE BL_ENDIF
%token BL_UNDEF BL_VAR BL_CONST BL_REFCONST BL_REF BL_EXTERNAL
%token BL_EXTERNAL_CHAR BL_CONST_CHAR BL_IS_SPECIAL
%token BL_PRINT BL_NOOP BL_EXIT
%token BL_STRCMP BL_STRASGN

%right BL_ASGN
%left  BL_OR
%left  BL_AND
%left  BL_IN BL_NOTIN
%left  BL_GE BL_LE BL_NE BL_EQ BL_GT BL_LT
%left  BL_ADD BL_SUB
%left  BL_MUL BL_DIV BL_MODULO
%left  BL_UNARY_MINUS BL_UNARY_PLUS BL_NOT
%right BL_POWER

%%

stmtlist: stmt ';' { $$ = $1; }
        | stmtlist stmt ';' { $$ = $1; }
	| error { yyclearin; yyerrok; }
        ;

stmt    : /* empty */ { $$ = BL_new_cmd(BL_oper(BL_NOOP,NULL,NULL,NULL)); }
        | expr { $$ = BL_new_cmd($1); }
	| BL_NAME BL_ASGN strexpr { $$ = BL_new_cmd(BL_oper(BL_STRASGN,$1,$3,NULL)); }
        | BL_PRINT arglist { $$ = BL_new_cmd(BL_oper(BL_PRINT,&$2,NULL,NULL)); }
	| BL_EXIT { 
	  { if (!BL_compile_all && BL_nested_ifs == -1) return 1; }
	  $$ = BL_new_cmd(BL_oper(BL_EXIT,NULL,NULL,NULL));
	}
        | if cond ifpart endif {
          BL_fix_cmd($1,$2,$3,NULL,$4);
	  $$ = $4; /* ENDIF ends this mess */
        }
        | if cond ifpart else stmtlist endif {
	  BL_fix_cmd($1,$2,$3,$4,$6);
	  $$ = $6; /* ENDIF ends this mess */
        }
	| external namlist special {
	  int i,numargs = $2;
	  BL_Tree **name = ALLOC(numargs, sizeof(BL_Tree *));
	  for (i=numargs-1; i>=0; i--) {
              name[i] = BL_pop_arg();
	  }	      
	  for (i=0; i<numargs; i++) {
	      char *two = name[i]->str;
	      BL_store(BL_EXTERNAL, two, BLMAGIC, $1 ? "extchar" : NULL, NULL, 0);
	      /* SPREADS simplification -- i.e. no need to specify "is SPECIAL"
	         if external starts with "body." or "ens." */
	      if ($3 || strnequ(two,"body.",5) || strnequ(two,"ens.",4)) BL_store_special(two);
	  }
	  FREE(name);
	  $$ = BL_new_cmd(BL_oper(BL_NOOP,NULL,NULL,NULL));
	}
	| BL_CONST BL_NAME BL_ASGN expr {
	  BL_store(BL_CONST, $2, evaluate($4), NULL, NULL, 0);
	  $$ = BL_new_cmd(BL_oper(BL_NOOP,NULL,NULL,NULL));
	}
	| BL_CONST_CHAR BL_NAME BL_ASGN BL_STRING {
	  BL_store(BL_CONST, $2, BLMAGIC, $4, NULL, 0);
	  $$ = BL_new_cmd(BL_oper(BL_NOOP,NULL,NULL,NULL));
	}
        ;

ifpart	: then stmtlist
        | then stmtlist elif cond ifpart {
          BL_fix_cmd($3,$4,NULL,NULL,NULL);
        }
        ;

if	: BL_IF { $$ = BL_new_cmd(BL_oper(BL_IF,NULL,NULL,NULL)); } 
	;

then	: BL_THEN { $$ = BL_new_cmd(BL_oper(BL_NOOP,NULL,NULL,NULL)); }
        ;

elif	: BL_ELIF { $$ = BL_new_cmd(BL_oper(BL_ELIF,NULL,NULL,NULL)); }
	;

else	: BL_ELSE { $$ = BL_new_cmd(BL_oper(BL_ELSE,NULL,NULL,NULL)); }
	;

endif	: BL_ENDIF { $$ = BL_new_cmd(BL_oper(BL_ENDIF,NULL,NULL,NULL)); }
	;

cond	: expr { $$ = $1; }
 	| '(' cond ')' { $$ = $2; }
        | BL_NOT cond { $$ = BL_oper(BL_NOT,$2,NULL,NULL); }
        | cond BL_AND cond { $$ = BL_oper(BL_AND,$1,$3,NULL); }
        | cond BL_OR  cond { $$ = BL_oper(BL_OR,$1,$3,NULL); }
        | expr BL_GT expr { $$ = BL_oper(BL_GT,$1,$3,NULL); }
        | expr BL_GE expr { $$ = BL_oper(BL_GE,$1,$3,NULL); }
        | expr BL_EQ expr { $$ = BL_oper(BL_EQ,$1,$3,NULL); }
        | expr BL_LE expr { $$ = BL_oper(BL_LE,$1,$3,NULL); }
        | expr BL_LT expr { $$ = BL_oper(BL_LT,$1,$3,NULL); }
        | expr BL_NE expr { $$ = BL_oper(BL_NE,$1,$3,NULL); }
        | expr BL_EQ strexpr { $$ = BL_oper(BL_STRCMP,$1,$3,NULL); }
        | expr BL_NE strexpr { $$ = BL_oper(BL_NOT, BL_oper(BL_STRCMP,$1,$3,NULL),NULL,NULL); }
        | expr BL_GT expr BL_GT expr { $$ = BL_oper(BL_GTGT,$1,$3,$5); }
        | expr BL_GT expr BL_GE expr { $$ = BL_oper(BL_GTGE,$1,$3,$5); }
        | expr BL_GE expr BL_GE expr { $$ = BL_oper(BL_GEGE,$1,$3,$5); }
        | expr BL_GE expr BL_GT expr { $$ = BL_oper(BL_GEGT,$1,$3,$5); }
        | expr BL_LT expr BL_LT expr { $$ = BL_oper(BL_LTLT,$1,$3,$5); }
        | expr BL_LT expr BL_LE expr { $$ = BL_oper(BL_LTLE,$1,$3,$5); }
        | expr BL_LE expr BL_LE expr { $$ = BL_oper(BL_LELE,$1,$3,$5); }
        | expr BL_LE expr BL_LT expr { $$ = BL_oper(BL_LELT,$1,$3,$5); }
	| expr BL_IN '(' arglist ')' { $$ = BL_oper(BL_IN,$1,&$4,NULL); }
	| expr BL_NOTIN '(' arglist ')' { 
	  $$ = BL_oper(BL_NOT, BL_oper(BL_IN,$1,&$4,NULL), NULL, NULL); 
	}
        ;

expr    : '(' expr ')'  { $$ = $2; }
	| BL_NUMBER     { $$ = BL_oper(BL_NUMBER,&$1,NULL,NULL); }
        | BL_NAME       { $$ = BL_oper(BL_NAME,$1,NULL,NULL); }
        | BL_NAME BL_ASGN expr { $$ = BL_oper(BL_ASGN,$1,$3,NULL); }
	| BL_NAME '(' arglist ')' { $$ = BL_oper(BL_BLTIN,$1,&$3,NULL); }
        | expr BL_ADD expr { $$ = BL_oper(BL_ADD,$1,$3,NULL); }
        | expr BL_SUB expr { $$ = BL_oper(BL_SUB,$1,$3,NULL); }
        | expr BL_MUL expr { $$ = BL_oper(BL_MUL,$1,$3,NULL); }
        | expr BL_DIV expr { $$ = BL_oper(BL_DIV,$1,$3,NULL); }
	| expr BL_MODULO expr { int numargs = 2;
				BL_push_arg($1); BL_push_arg($3);
				$$ = BL_oper(BL_BLTIN,"mod",&numargs,NULL);
			      }
        | expr BL_POWER expr { $$ = BL_oper(BL_POWER,$1,$3,NULL); }
        | BL_ADD expr %prec BL_UNARY_PLUS  { $$ = BL_oper(BL_UNARY_PLUS,$2,NULL,NULL); }
        | BL_SUB expr %prec BL_UNARY_MINUS { $$ = BL_oper(BL_UNARY_MINUS,$2,NULL,NULL); }
	;

strexpr : BL_STRING     { $$ = BL_oper(BL_STRING,$1,NULL,NULL); }
	;

arglist : /* empty */		{ $$ = 0; }
	| expr			{ BL_push_arg($1);   $$ = 1; }
	| strexpr		{ BL_push_arg($1);   $$ = 1; }
	| arglist ',' expr	{ BL_push_arg($3);   $$ = $1 + 1; }
	| arglist ',' strexpr	{ BL_push_arg($3);   $$ = $1 + 1; }
	;

namlist : nam			{ BL_push_arg($1); $$ = 1; }
	| namlist ',' nam	{ BL_push_arg($3); $$ = $1 + 1; }
	;

nam	: BL_NAME		{
	  BL_Tree *name = BL_oper(BL_NOOP,NULL,NULL,NULL);
	  name->str = STRDUP($1);
	  $$ = name;
	}

special : /* empty */           { $$ = 0; }
	| BL_IS_SPECIAL		{ $$ = 1; }
	;

external: BL_EXTERNAL           { $$ = 0; }
	| BL_EXTERNAL_CHAR	{ $$ = 1; }
	;
%%



%{
#include "bldefs.h"

#if defined(YYLMAX)
#undef YYLMAX
#define YYLMAX 65536
#endif

PRIVATE int first_time = 1;
int BL_nested_ifs = -1;
int BL_max_if_nesting = 0;
int BL_lineno = 1;

extern FILE *yyin;
extern FILE *BL_aux_yyin;
extern char BL_last_line[MAXLINE];
extern char *BL_file;
extern void handle_cppline();

PRIVATE int state[NCMD_STACK];
PRIVATE int *p_state = state;

#define DEBUG_PRINT(at) \
fprintf(stderr,"<@%s('%s'): p_state offset=%d ; value=%d>\n",at, yytext, \
     p_state - state, *p_state);
%}

Blank	[ \t]+
Number	(([0-9]+)|([0-9]*\.[0-9]+)|([0-9]+\.[0-9]*))
Exp	[eE][-+]?[0-9]+
Name	(([A-Za-z]+[.][_A-Za-z0-9]+)|([_A-Za-z][_A-Za-z0-9]*))
String	(\"[^"\n]*\")|(\'[^'\n]*\')
CPPLINE #[ \t]*[0-9]+[ \t]*\"[^"]*\".*[\n]
Comment	#.*[\n]?

/* Comment	(#.*[\n]?)|(!.*[\n]?) */

%s NORMAL
%s CONDBLK 
%s THENBLK
%s ELSEBLK
%s DEFBLK

%%

%{
	if (first_time) {
        /*
	  fprintf(stderr,"NORMAL=%d, CONDBLK=%d, THENBLK=%d, ELSEBLK=%d\n",
		  NORMAL, CONDBLK, THENBLK, ELSEBLK);
	  DEBUG_PRINT("Very begin");
         */
	  *p_state = NORMAL;
	  /* DEBUG_PRINT("First assignment"); */
	  BEGIN NORMAL;
	  first_time = 0;
	}

%}

\n		{ BL_lineno++; AUX_GETS; }

{Blank}		;

";"		{ 
		  if (*p_state == DEFBLK) { p_state--; BEGIN *p_state; } 
		  return yytext[0];
		}

{CPPLINE}	{ BL_lineno++; AUX_GETS; handle_cppline(); }

{Comment}       { BL_lineno++; AUX_GETS; }

<NORMAL>[eE][xX][tT][eE][rR][nN][aA][lL]	{
	BEGIN DEFBLK; *++p_state = DEFBLK; return BL_EXTERNAL; }
<NORMAL>[cC][oO][nN][sS][tT]	{
	BEGIN DEFBLK; *++p_state = DEFBLK; return BL_CONST; }
<NORMAL>[eE][xX][tT][eE][rR][nN][aA][lL]_[cC][hH][aA][rR]	{
	BEGIN DEFBLK; *++p_state = DEFBLK; return BL_EXTERNAL_CHAR; }
<NORMAL>[cC][oO][nN][sS][tT]_[cC][hH][aA][rR]	{
	BEGIN DEFBLK; *++p_state = DEFBLK; return BL_CONST_CHAR; }
<DEFBLK>[iI][sS][ \t]+[sS][pP][eE][cC][iI][aA][lL] {
	return BL_IS_SPECIAL; }

<NORMAL,THENBLK,ELSEBLK>[eE][xX][iI][tT] |
<NORMAL,THENBLK,ELSEBLK>[rR][eE][tT][uU][rR][nN] { return BL_EXIT; }

<NORMAL,THENBLK,ELSEBLK>[iI][fF]  { 
  *++p_state = CONDBLK;
  /*DEBUG_PRINT("IF nested: After CONDBLK"); */
  BEGIN CONDBLK; 
  BL_nested_ifs++;
  if (BL_nested_ifs + 1 > BL_max_if_nesting) BL_max_if_nesting = BL_nested_ifs + 1;
  return BL_IF; 
}

<CONDBLK>[tT][hH][eE][nN] { 
  *p_state = THENBLK;
  /* DEBUG_PRINT("After THENBLK"); */
  BEGIN THENBLK; 
  return BL_THEN; 
}

<THENBLK>[eE][lL][iI][fF]  { 
  *++p_state = CONDBLK;
  /* DEBUG_PRINT("IF NOT nested: After CONDBLK"); */ 
  BEGIN CONDBLK; 
  return BL_ELIF; 
}

<THENBLK>[eE][lL][sS][eE]	{
  *p_state = ELSEBLK;
  /* DEBUG_PRINT("After ELSEBLK"); */ 
  BEGIN ELSEBLK;
  return BL_ELSE;
}

<THENBLK,ELSEBLK>[eE][nN][dD][ \t]*[iI][fF] {
  if (--BL_nested_ifs == -1) {
    p_state = state;
    *p_state = NORMAL;
    /* DEBUG_PRINT("ENDIF Back to normal"); */
    BEGIN NORMAL;
  }
  else {
    p_state--;
    /*DEBUG_PRINT("In the nested"); */
    BEGIN *p_state;
  }
  return BL_ENDIF; 
}

<CONDBLK>[aA][nN][dD] | 
<CONDBLK>"&"          |
<CONDBLK>"&&"               return BL_AND;

<CONDBLK>[oO][rR] | 
<CONDBLK>"|"      |
<CONDBLK>"||"               return BL_OR;

<CONDBLK>"<>" | 
<CONDBLK>"!=" |
<CONDBLK>"/="               return BL_NE;

<CONDBLK>[nN][oO][tT] |
<CONDBLK>"!" 	            return BL_NOT;

<CONDBLK>"=" |
<CONDBLK>"=="  return BL_EQ;

<CONDBLK>">"   return BL_GT;
<CONDBLK>"<"   return BL_LT;
<CONDBLK>">="  return BL_GE;
<CONDBLK>"<="  return BL_LE;

<CONDBLK>[nN][oO][tT][ \t]*[iI][nN]  return BL_NOTIN;
<CONDBLK>[iI][nN]  return BL_IN;

[eE][xX][tT][eE][rR][nN][aA][lL] |
[cC][oO][nN][sS][tT] |
[eE][xX][tT][eE][rR][nN][aA][lL]_[cC][hH][aA][rR] |
[cC][oO][nN][sS][tT]_[cC][hH][aA][rR] |
[iI][sS][ \t]+[sS][pP][eE][cC][iI][aA][lL] |
[tT][hH][eE][nN] |
[eE][lL][sS][eE] |
[eE][lL][iI][fF] |
[eE][nN][dD][ \t]*[iI][fF] | 
[iI][nN] { 
   char error_msg[MAXLINE];
   sprintf(error_msg,"Reserved keyword '%s' used in a wrong context",
	yytext);
   yyerror(error_msg);
}

"="  return BL_ASGN;

"**" | 
"^"   return BL_POWER;

"+" return BL_ADD;
"-" return BL_SUB;
"*" return BL_MUL;
"/" return BL_DIV;
"%" return BL_MODULO;

<NORMAL,THENBLK,ELSEBLK>[pP][rR][iI][nN][tT] { return BL_PRINT; }

{String}	{ /* Either "string" or 'string' */
		  yylval.str = STRDUP(yytext+1); /* skip open quote */
		  if (	(yytext[0] == '"' && yytext[yyleng-1] != '"') ||
			(yytext[0] == '\'' && yytext[yyleng-1] != '\'') )
			yyerror("Unterminated string");
		  else  yylval.str[yyleng-2] = '\0';  /* remove close quote */
		  return BL_STRING;
		}

{Name}		{ /* Pure symbol */
		  yylval.str = BL_lowercase(yytext); /* will do the STRDUP() as well ! */
		  /*
		  {
			char *dot = strchr(yylval.str,'.');
			if (dot) *dot = '_';
		  }
		  */
		  return BL_NAME;
		}

{Number} |	
{Number}{Exp}	{ 
		  yylval.dval = atof(yytext);
		  return BL_NUMBER; 
		}

.		return yytext[0];

%%



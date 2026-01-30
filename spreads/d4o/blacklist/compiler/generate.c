/* generate.c */

/* cfptrash is a workaround by Eric Sevault and Ryad El Khatib 02-Mar-2007 */
/* after glibc reported error on LinuxPC & NEC TX leading to segmentation  */
/* violation before C_blacklist_header.h is made */

#include "bldefs.h"

extern BL_Cmd_List *BL_start_cmd();
extern BL_Symbol_Table *BL_start_symbol();
extern int BL_nested_ifs;
extern int BL_max_if_nesting;
extern int BL_maxargs;
extern int BL_count_external;
extern int BL_count_external_char;
extern char *BL_file;

PRIVATE FILE *cfp = NULL;
PRIVATE FILE *cfptrash[3];
PRIVATE int cfpcount = 0;
PRIVATE char *cfile = NULL;
PRIVATE void dump_c(BL_Tree *pnode);
PRIVATE int deactivate_statement(BL_Tree *pnode);
PRIVATE void get_numfuncs(BL_Tree *pnode, int *numfuncs);
PRIVATE int lineno = 0;
PRIVATE char *gen_main = NULL;
PRIVATE int newline_required = 1;
PRIVATE int next_funcno = 1;
PRIVATE int in_if_cond = 0;

#define TABS \
  { int i; fprintf(cfp,"   "); for (i=0; i<=BL_nested_ifs; i++) fprintf(cfp,"  "); }
/* #define STAR (psym->flag == BL_REFCONST && psym->if_flagged && !psym->str) ? "*" : "" */
#define STAR "*"
/* #define DBL  "DBL_" */

PRIVATE char *Undotify(const char *name)
{
  char *dot = NULL;
  static char Undotified_name[MAXLINE];

  strcpy(Undotified_name,name);
  dot = strchr(Undotified_name,'.');
  if (dot) *dot = '_';
  return Undotified_name;
}

PRIVATE char *Capitalize(const char *name)
{
  int ch;
  static char Capitalized_name[MAXLINE];

  strcpy(Capitalized_name,name);
  ch = Capitalized_name[0];
  Capitalized_name[0] = toupper(ch);
  return Capitalized_name;
}

PRIVATE void BL_close_all(void)
{
  int j;
  for (j=0; j<cfpcount; j++) {
    fclose(cfptrash[j]);
  }
  return;
}

PRIVATE FILE *BL_open_C_file(char *BL_cfile, char *mode)
{

  if (!BL_cfile) cfile = "C_code.c";
  else cfile = STRDUP(BL_cfile);

  printf("*** Writing C-code to %sfile \"%s\"\n",
         (strcmp(cfile,"C_code.c") == 0) ? "" : "include-",
         cfile);
  fflush(stdout);

  cfp = fopen(cfile,mode);
  cfptrash[cfpcount++] = cfp;

  return cfp;
}


PUBLIC void BL_generate_C_code(int numlines)
{
  BL_Symbol_Table *psym;
  char *marker = "\n";
  int j, jc;
  int ncategs = 2;
  int max_numfuncs = 0;

  char *category[] = 
    { "C_blacklist_body_entry",   "C_blacklist_header", NULL };
  char *category_file[] = 
    { "C_blacklist_body_entry.h", "C_blacklist_header.h", NULL };

  char blacklist_generic[] = "C_blacklist_generic";

  gen_main = getenv("BL_MAIN");

  BL_open_C_file("C_code.c", "w");

  if (gen_main) ncategs = 1;

  BL_write_function_prototypes(cfp);
  fprintf(cfp,"extern int C_fail(int reason, double seriousness,\n");
  fprintf(cfp,"                  const char *blfile, int lineno, const char *fdbk_vars,\n");
  fprintf(cfp,"                  const char *c_filename, int c_lineno, const char *reason_name,\n");
  fprintf(cfp,"                  int *last_reason, double *last_seriousness, int *last_lineno,\n");
  fprintf(cfp,"                  const int VARIDX[], int VARIDX_LEN,\n");
  fprintf(cfp,"                  const int NAME_INDEX[], int NAME_INDEX_LEN,\n");
  fprintf(cfp,"                  int KFEEDBACK[], int KFEEDBACK_SIZE, int ENABLE_fill_fbv, void *meta);\n\n");

  fprintf(cfp,"\n#define MIN(a,b) ((a) < (b) ? (a) : (b))\n");
  fprintf(cfp,"\n#define MAX(a,b) ((a) > (b) ? (a) : (b))\n");
  fprintf(cfp,"\n");
  fprintf(cfp,
          "#define DTOD(i)   (NAME_INDEX[i]>=0 && NAME_INDEX[i]<KDATA) ? &ZDATA[NAME_INDEX[i]] : NULL\n");
  fprintf(cfp,
          "#define DTOS(i)   (NAME_INDEX[i]>=0 && NAME_INDEX[i]<KDATA) ? dtos(&ZDATA[NAME_INDEX[i]]) : NULL\n");
  /*      "#define DTOS(i)   (NAME_INDEX[i]>=0 && NAME_INDEX[i]<KDATA) ? dtos(STR[i],&ZDATA[NAME_INDEX[i]]) : NULL\n"); */

  fprintf(cfp,"\n");
  fprintf(cfp,"extern int   wildcard_strcmp(const char *left_str, const char *right_str, const int is_8);\n");
  fprintf(cfp,"extern int   fast_strcmp(const unsigned long long int *left_str, const unsigned long long int *right_str);\n");
  fprintf(cfp,"\n");
  /* fprintf(cfp,"extern char *dtos(char s[], const double *dval);\n"); */
  fprintf(cfp,"extern const char *dtos(const double *dval);\n");
  fprintf(cfp,"extern char *dynamic_mditest(int no_of_external_symbols,\n");
  fprintf(cfp,"                             const unsigned char mask[],\n");
  fprintf(cfp,"                             int VARIDX[], int *VARIDX_LEN,\n");
  fprintf(cfp,"                             const int NAME_INDEX[], int NAME_INDEX_LEN,\n");
  fprintf(cfp,"                             const double ZDATA[], int KDATA);\n");

  fprintf(cfp,"\nextern int d4o_is_null(double value); /* borrowed from d4o.h */\n");

  fprintf(cfp,"\ntypedef struct _Symbol_Data {\n");
  fprintf(cfp,"  const char *symbol_name;\n");
  fprintf(cfp,"  const char *symbol_name2;\n");
  fprintf(cfp,"  const unsigned char char_flag;\n");
  fprintf(cfp,"  const unsigned char special_flag;\n");
  fprintf(cfp,"} Symbol_Data;\n\n");

  fprintf(cfp,"#ifndef ANDATE\n");
  fprintf(cfp,"#define ANDATE 19700101\n");
  fprintf(cfp,"#endif\n");
  fprintf(cfp,"#ifndef ANTIME\n");
  fprintf(cfp,"#define ANTIME   000000\n");
  fprintf(cfp,"#endif\n");

  fprintf(cfp,"\nstatic const char BL_file[] = \"%s\";\n",BL_file);
  fprintf(cfp,"\nint BL_numlines = %d; /* externally accessible */\n",numlines);
  
  fprintf(cfp,"\nvoid analysis_date_and_time(int *andate, int *antime)\n");
  fprintf(cfp,"{ extern int analysis_date(int), analysis_time(int);\n");
  fprintf(cfp,"  *andate = analysis_date(ANDATE); *antime = analysis_time(ANTIME); }\n");

  fprintf(cfp,"\nvoid compilation_date_and_time(int *compdate, int *comptime)\n");
  fprintf(cfp,"{ extern int CONV_date(const char *), CONV_time(const char *);\n");
  fprintf(cfp,"  *compdate = CONV_date(__DATE__); *comptime = CONV_time(__TIME__); }\n");

  fprintf(cfp,"\nint symbol_DATA_len = %d; /* Must be external symbols */\n",BL_count_external);

  fprintf(cfp,"\nSymbol_Data symbol_DATA[%d] = { /* Must be external symbols */\n",BL_count_external);

  jc = 0;
  for (psym = BL_start_symbol(); psym != NULL; psym = psym->next) {
    if (psym->flag == BL_REFCONST && psym->if_flagged) {
      fprintf(cfp,"  \"%s\", \"/%s/\", %d, %d,\n", 
              psym->name, psym->name, 
              psym->str ? 1 : 0, psym->special ? 1 : 0);
      jc++;
    }
  }

  fprintf(cfp,"};\n\n");

  if (gen_main) {
    fprintf(cfp,"static const char *Statid=NULL;\n");
    fprintf(cfp,"static int BL_fail(int line, ...)\n");
    fprintf(cfp,"static int BL_abort(int line, ...)\n");
    fprintf(cfp,
    "{ printf(\"Failed(%%s): Line=%%d\\n\",Statid,abs(line)); return 1;}\n");
  }

#if 0
  fprintf(cfp,"#if %d\n",(!BL_no_char_limit) ? 1 : 0); /* !BL_no_char_limit is the default */
  fprintf(cfp,"#define SC(s,str) (fast_strcmp((const unsigned long long int *)%s##s,(const unsigned long long int *)(str)) == 0)\n",DBL);
  fprintf(cfp,"#define WC(s,str) (wildcard_strcmp((s),(str),1) == 0)\n");
  fprintf(cfp,"#else\n");
#endif
  
  fprintf(cfp,"#define SC(s,str) (strcmp((s),(str)) == 0)\n");
  fprintf(cfp,"#define WC(s,str) (wildcard_strcmp((s),(str),0) == 0)\n");
  
  /* fprintf(cfp,"#endif\n"); */

  fprintf(cfp,"\n");
  fprintf(cfp,"/* Reserved keywords (constants) */\n");
  fprintf(cfp,"\n");
  fprintf(cfp,"#define ABORT_func ((double)8)\n");
  fprintf(cfp,"#define MDI_failure ((double)9)\n");
  for (psym = BL_start_symbol(); psym != NULL; psym = psym->next) {
    if (psym->flag == BL_REFCONST && !psym->if_flagged) {
      if (psym->str) {
        fprintf(cfp,"#define %s \"%s\"\n",
                Capitalize(psym->name),psym->str);
      }
      else {
        fprintf(cfp,"#define %s ((double)%.15g)\n",
                Capitalize(psym->name),psym->dval);
      }
    }
  }

  if (BL_maxargs > 0) {
    BL_Cmd_List *pcmd;
    
    for (pcmd = BL_start_cmd(); pcmd != NULL; pcmd = pcmd->next) {
      int numfuncs = 0;
      get_numfuncs(pcmd->node, &numfuncs);
      pcmd->numfuncs = numfuncs;
      max_numfuncs = BLMAX(max_numfuncs, numfuncs);
    }
  }
  
  for (j=0; j<ncategs; j++) {

    fprintf(cfp,"\n");

    if (gen_main) {
      fprintf(cfp,"int main()\n");
      fprintf(cfp,"{");
      marker = "\n";
      for (psym = BL_start_symbol(); psym != NULL; psym = psym->next) {
        if (psym->flag == BL_REFCONST && psym->if_flagged) {
          if (psym->str) {
            fprintf(cfp,"%s    const   char %s[%d+1] = \"%s\"",marker, 
                    Undotify(psym->name), 
                    (int) strlen(psym->str),
                    psym->str);
          }
          else {
            fprintf(cfp,"%s    const double %s = %.15g",marker,
                    Undotify(psym->name), psym->dval);
          }
          marker = ";\n";
        }
      }
      fprintf(cfp,"%s\nreturn\n",marker);

      fprintf(cfp,"%s(",blacklist_generic);
      marker = "\n";
      for (psym = BL_start_symbol(); psym != NULL; psym = psym->next) {
        if (psym->flag == BL_REFCONST && psym->if_flagged) {
          if (psym->str) fprintf(cfp,"%s\t%s",marker, Undotify(psym->name));
          else           fprintf(cfp,"%s\t&%s",marker,Undotify(psym->name));
          marker = ",\n";
        }
      }
      fprintf(cfp,");\n}\n");
      fprintf(cfp,"\nvoid %s(",blacklist_generic);
    }

    else { /* !gen_main */
      if (j==0) {
        fprintf(cfp,"#include \"%s\"\n\n", category_file[0]);
        fprintf(cfp,"#include \"%s\"\n\n", category_file[1]);
      }

      BL_open_C_file(category_file[j],"w");
      fprintf(cfp,"\nvoid %s(\n",category[j]);
    }
  
    if (!gen_main) {
      fprintf(cfp,"\tFILE  *fout,\n");
      fprintf(cfp,"\tint   *LR,    /* last_reason */\n");
      fprintf(cfp,"\tdouble *LS,   /* last_seriousness */\n");
      fprintf(cfp,"\tint   *LL,    /* last_lineno */\n");
      fprintf(cfp,"\tint KFEEDBACK[], int KFEEDBACK_SIZE, /* F.B.-vector */\n");
      fprintf(cfp,"\tint ENABLE_printing,\n");
      fprintf(cfp,"\tint ENABLE_mditesting,\n");
      fprintf(cfp,"\tint ENABLE_fill_fbv,\n");
      fprintf(cfp,"\tconst int NAME_INDEX[], int NAME_INDEX_LEN,\n");
      fprintf(cfp,"\tconst double ZDATA[], int KDATA,");
    }

    fprintf(cfp,"\n");
    TABS;
    fprintf(cfp,"\tint *retcode, void *meta)\n{\n");
    TABS;
    fprintf(cfp,"int RC=0;\n");
    TABS;

    if (BL_maxargs > 0 && max_numfuncs > 0) {
      int i;
      for (i=1; i<=max_numfuncs; i++) {
        fprintf(cfp,"double ARGS%d[%d];\n",i,BL_maxargs);
        TABS;
      }
    }
    else {
      fprintf(cfp,"double *ARGS1 = NULL;\n");
      TABS;
    }

    /*
    if (BL_count_external > 0) {
      fprintf(cfp,"char STR[%d][sizeof(double)+1];\n",BL_count_external);
      TABS;
    }
    */

    jc = 0;
    for (psym = BL_start_symbol(); psym != NULL; psym = psym->next) {
      if (psym->flag == BL_REFCONST && psym->if_flagged) {
        if (!(j==1 && psym->special)) {
          if (psym->str) {
            fprintf(cfp,
                    "const   char *%s = DTOS(%d);\n",
                    Undotify(psym->name),jc);
#if 0
            TABS;
            fprintf(cfp,
                    "const double %s%s%s = DTOD(%d);\n",
                    STAR,DBL,Undotify(psym->name),jc);
#endif
          }
          else           
            fprintf(cfp,
                    "const double %s%s = DTOD(%d);\n",
                    STAR,Undotify(psym->name),jc);
        }
        else {
          if (psym->str) 
            fprintf(cfp,"/* const   char *%s = NULL; */\n",Undotify(psym->name));
          else           
            fprintf(cfp,"/* const double %s%s = NULL; */\n",STAR,Undotify(psym->name));
        }
        jc++;
        TABS;
      }
    }

    if (BL_count_external > 0) {
      fprintf(cfp,"const unsigned char mask[%d] = { ",BL_count_external);

      jc = 0;
      for (psym = BL_start_symbol(); psym != NULL; psym = psym->next) {
        if (psym->flag == BL_REFCONST && psym->if_flagged) {
          if (!(j==1 && psym->special)) {
            fprintf(cfp,"1%c",(++jc<BL_count_external)?',':' ');
          }
          else {
            fprintf(cfp,"0%c",(++jc<BL_count_external)?',':' ');
          }
        }
      } 

      fprintf(cfp,"};\n");
      TABS;
    }

    fprintf(cfp,"int PrtAndReturn = 0;\n");
    TABS;
    for (psym = BL_start_symbol(); psym != NULL; psym = psym->next) {
      if (psym->flag == BL_REF) {
        if (psym->str) fprintf(cfp,"char  *%s;\n",Undotify(psym->name));
        else           fprintf(cfp,"double %s;\n",Undotify(psym->name));
        TABS;
      }
    }

    fprintf(cfp,"\n");
    TABS;

    if (gen_main) {
      fprintf(cfp,"Statid = statid;\n");
      TABS;
    }

    if (!gen_main) {
      int i=0;
      int ndiv = 8;

      fprintf(cfp,"again: if (ENABLE_printing && PrtAndReturn) {\n");
      BL_nested_ifs++;
      TABS;

      fprintf(cfp,"fprintf(fout,\"%s:  \");\n",
              (j==0) ? "Body entry" : "Header");
      TABS;

      fprintf(cfp,
      "fprintf(fout,\"NAME_INDEX_LEN=%%d, KDATA=%%d\\n\",NAME_INDEX_LEN,KDATA);\n");
      TABS;

      for (psym = BL_start_symbol(); psym != NULL; psym = psym->next) {
        if (psym->flag == BL_REFCONST && psym->if_flagged) {
          if (!(j==1 && psym->special)) {
            i++;
            if (psym->str) {
              fprintf(cfp,
                      "fprintf(fout,\" %s = \\\"%%s\\\";\",%s?%s:NULL);\n",
                      psym->name,
                      Undotify(psym->name),
                      Undotify(psym->name));
              // i = ndiv;
            }
            else {
              fprintf(cfp,
                      "if (%s && !d4o_is_null(%s%s)) fprintf(fout,\" %s = %%.15g;\",%s%s);\n",
                      Undotify(psym->name),
		      STAR,Undotify(psym->name),
                      psym->name,
                      STAR,Undotify(psym->name));
              TABS;
              fprintf(cfp,
                      "else fprintf(fout,\" %s = NULL;\");\n",
                      psym->name);
            }
            TABS;
            if (i%ndiv == 0) {
              fprintf(cfp,"fprintf(fout,\"\\n\");\n");
              TABS;
            }
          }
        }
      }
      if (i>0 && i%ndiv != 0) {
        fprintf(cfp,"fprintf(fout,\"\\n\");\n");
      }

      TABS;
      fprintf(cfp,"if (PrtAndReturn) return;\n");
      
      BL_nested_ifs--;
      TABS;
      fprintf(cfp,"}  /* if (ENABLE_printing && PrtAndReturn) */\n\n");

      TABS;
      fprintf(cfp,"if (ENABLE_mditesting) {\n");
      BL_nested_ifs++;

      TABS;
      fprintf(cfp,"int VARIDX_LEN = 0;\n");

      TABS;
      fprintf(cfp,"int *VARIDX = malloc((NAME_INDEX_LEN + 1) * sizeof(*VARIDX));\n");

      TABS;
      fprintf(cfp,
              "char *p = dynamic_mditest(MIN(%d,KDATA), mask, VARIDX, &VARIDX_LEN,\n",
              BL_count_external);

      TABS;
      TABS;
      fprintf(cfp,
              "NAME_INDEX, NAME_INDEX_LEN, ZDATA, KDATA);\n");

      TABS;
      fprintf(cfp,"if (p) {\n");
      BL_nested_ifs++;

      TABS;
      fprintf(cfp,"RC=C_fail(MDI_failure, 1.0, __FILE__, 0, p, __FILE__, __LINE__, \"MDI_failure\", LR, LS, LL, VARIDX, VARIDX_LEN,\n");

      TABS;
      TABS;
      fprintf(cfp,"NAME_INDEX, NAME_INDEX_LEN, KFEEDBACK, KFEEDBACK_SIZE, ENABLE_fill_fbv, meta);\n");

      BL_nested_ifs--;

      TABS;
      fprintf(cfp,"}  /* if (p) */\n");

      TABS;
      fprintf(cfp,"if (p) free(p);\n");
      TABS;
      fprintf(cfp,"if (VARIDX) free(VARIDX);\n");

      TABS;
      fprintf(cfp,"if (RC) goto return_RC;\n");

      BL_nested_ifs--;

      TABS;
      fprintf(cfp,"}  /* if (ENABLE_mditesting) */\n\n");

      TABS;
    }

    {
      BL_Cmd_List *pcmd;
      in_if_cond = 0;

      for (pcmd = BL_start_cmd(); pcmd != NULL; pcmd = pcmd->next) {
        lineno = pcmd->lineno;
        newline_required = 1;
        next_funcno = 1;

        if (pcmd->active) {
          dump_c(pcmd->node);
          if (newline_required) {
            fprintf(cfp,";\n");
            TABS;
          }
        }
      }
    }

    BL_nested_ifs = -1;
    fprintf(cfp,"\n");
    TABS;
    fprintf(cfp,"return_RC:\n");
    TABS;
    fprintf(cfp,"*retcode = RC;\n");
    TABS;
    fprintf(cfp,"if (ENABLE_printing && RC != 0) { PrtAndReturn = 1; goto again; }\n");
    TABS;
    fprintf(cfp,"return;\n}\n");

    /* fclose(cfp); */

    if (j == 0 && ncategs > 1) {
      BL_Cmd_List *pcmd;

      if (BL_max_if_nesting == 0) {
        for (pcmd = BL_start_cmd(); pcmd != NULL; pcmd = pcmd->next) {
          if (deactivate_statement(pcmd->node)) pcmd->active = 0;
        }
      }
      else {
        /* BL_Cmd_List **if_cmd = ALLOC(BL_max_if_nesting, sizeof(**if_cmd)); */
        BL_Cmd_List *if_cmd[NCMD_STACK];
        BL_nested_ifs = -1;
        in_if_cond = 0;

        for (pcmd = BL_start_cmd(); pcmd != NULL; pcmd = pcmd->next) {
          BL_Tree *pnode = pcmd->node;

          if (pnode) {
            int type = pnode->type;
            
            switch (type) {
            case BL_IF:
              BL_nested_ifs++;
              if_cmd[BL_nested_ifs] = pcmd;
              if (deactivate_statement(pnode)) pcmd->active = 0;
              break;

            case BL_ENDIF:
              {
                BL_Cmd_List *sub_pcmd = if_cmd[BL_nested_ifs];
                int rejected = (sub_pcmd->active == 0) ? 1 : 0;
                if (rejected) {
                  for ( ; sub_pcmd != pcmd; sub_pcmd = sub_pcmd->next) {
                    sub_pcmd->active = 0;
                  }
                  pcmd->active = 0;
                }
              }
              BL_nested_ifs--;
              break;
              
            default:
              if (deactivate_statement(pnode)) pcmd->active = 0;
              break;

            } /* switch (type) */
          } /* if (pnode) */

          /* FREE(if_cmd); */

        } /* for (pcmd = BL_start_cmd(); pcmd != NULL; pcmd = pcmd->next) */

      } /* if (BL_max_if_nesting == 0) */
    }

  } /* for (j=0; j<ncategs; j++) */

  BL_close_all();

  {
    char unix_cmd[MAXLINE];
    char *pcc = getenv("BL_CC");
    char *pflags = getenv("BL_CFLAGS");
    char *plib = getenv("BL_LIB");

    cfile = "C_code.c";
    printf("*** Compiling \"%s\"\n",cfile);

    remove(gen_main ? "./C_code.x" : "./C_code.o");
    snprintf(unix_cmd, sizeof(unix_cmd),
            "set -xeu ; pwd ; %s %s %s %s %s %s",
            pcc ? pcc : "cc", 
            gen_main ? "":"-c",
            pflags ? pflags : "",
            cfile,
            (gen_main && plib) ? plib : "",
            gen_main ? "-lm -o C_code.x && ./C_code.x":"");
    printf("\t%s\n",unix_cmd);
    fflush(stdout);
    (void) system(unix_cmd);

    { /* Check the outcome of the system command */
      struct stat buf; 
      char *complain_msg = NULL;

      if (gen_main) {
        if (stat("C_code.x", &buf) != 0) {
          complain_msg = "Unable to create executable 'C_code.x'";
        }
      }
      else {
        if (stat("C_code.o", &buf) != 0) {
          complain_msg = "Unable to create object file 'C_code.o'";
        }
      }

      if (complain_msg) {
        fprintf(stderr,"\n*** Error: %s\n",complain_msg);
        exit(95);
      }
    }

  }
}

PRIVATE void dump_c(BL_Tree *pnode)
{
  if (pnode) {
    int type = pnode->type;

    switch (type) {

    case BL_GT:
    case BL_GE:
    case BL_EQ:
    case BL_LE:
    case BL_LT:
    case BL_NE:
    case BL_AND:
    case BL_OR:
    case BL_ADD:
    case BL_SUB:
      fprintf(cfp,"(");
      dump_c(pnode->argv[0]);
      fprintf(cfp," %s ",BL_keymap(type));
      dump_c(pnode->argv[1]);
      fprintf(cfp,")");
      break;

    case BL_MUL:
    case BL_DIV:
      dump_c(pnode->argv[0]);
      fprintf(cfp," %s ",BL_keymap(type));
      dump_c(pnode->argv[1]);
      break;

    case BL_POWER:
      fprintf(cfp,"pow(");
      dump_c(pnode->argv[0]);
      fprintf(cfp,", ");
      dump_c(pnode->argv[1]);
      fprintf(cfp,")");
      break;

    case BL_UNARY_PLUS:
    case BL_UNARY_MINUS:
    case BL_NOT:
      fprintf(cfp,"(");
      fprintf(cfp,"%s",BL_keymap(type));
      dump_c(pnode->argv[0]);
      fprintf(cfp,")");
      break;

    case BL_NUMBER:
      fprintf(cfp,"%.15g",pnode->dval);
      break;

    case BL_STRING:
      fprintf(cfp,"\"%s\"",pnode->str);
      break;

    case BL_NAME:
      {
        BL_Symbol_Table *psym = pnode->argv[0];
        if (psym->flag == BL_REFCONST && psym->if_flagged)
          fprintf(cfp,"%s%s",STAR, Undotify(psym->name));
        else
          fprintf(cfp,"%s",
                  (psym->flag == BL_REFCONST && !psym->if_flagged) ? 
                  Capitalize(psym->name) : Undotify(psym->name));
        if (in_if_cond && psym->if_flagged) {
          FD_SET(BL_nested_ifs, psym->if_flagged);
        }
      }
      break;

    case BL_IF:
      fprintf(cfp,"if (");
      in_if_cond = 1;
      BL_nested_ifs++;
      dump_c(pnode->argv[0]);
      fprintf(cfp,") {\n");
      TABS;
      in_if_cond = 0;
      newline_required = 0;
      break;

    case BL_ELIF:
      fprintf(cfp,"} else if (");
      in_if_cond = 1;
      dump_c(pnode->argv[0]);
      fprintf(cfp,") {\n");
      TABS;
      in_if_cond = 0;
      newline_required = 0;
      break;
 
    case BL_ELSE:
      fprintf(cfp,"} else {\n");
      TABS;
      newline_required = 0;
      break;

    case BL_ENDIF:
      BL_zero_if_flag();
      BL_nested_ifs--;
      fprintf(cfp,"; }\n");
      TABS;
      newline_required = 0;
      break;

    case BL_EXIT:
      fprintf(cfp,"goto return_RC;\n");
      TABS;
      newline_required = 0;
      break;

    case BL_PRINT:
      {
        int i, numargs = pnode->argc;

        fprintf(cfp,"printf(\" \"); ");
        for (i=0; i<numargs; i++) {
          BL_Tree *expr = pnode->argv[i];
          int type = expr->type;

          switch (type) {
          case BL_NUMBER:
            fprintf(cfp,"printf(\"");
            dump_c(expr);
            fprintf(cfp," \"");
            break;
          case BL_STRING:
            fprintf(cfp,"printf(\"%%s \",");
            dump_c(expr);
            break;
          case BL_NAME:
            {
              BL_Symbol_Table *psym = expr->argv[0];
              fprintf(cfp,"printf(\"");
              if (psym->flag == BL_REFCONST || 
                  psym->flag == BL_VAR ||
                  psym->flag == BL_REF) {
                if (psym->str) {
                  fprintf(cfp,"%s = \\\"%%s\\\" \",%s",
                          (psym->flag == BL_REFCONST && !psym->if_flagged) ? 
                          Capitalize(psym->name) : psym->name,
                          (psym->flag == BL_REFCONST && !psym->if_flagged) ? 
                          Capitalize(psym->name) : Undotify(psym->name));
                }
                else {
                  fprintf(cfp,"%s = %%.15g \", %s%s",
                          (psym->flag == BL_REFCONST && !psym->if_flagged) ? 
                          Capitalize(psym->name) : psym->name,
                          psym->if_flagged ? "*" : "",
                          (psym->flag == BL_REFCONST && !psym->if_flagged) ? 
                          Capitalize(psym->name) : Undotify(psym->name));
                }
              }
              else {
                dump_c(expr);
                fprintf(cfp," = %%.15g \",(double)");
                dump_c(expr);
              }
            }
            break;
          default:
            fprintf(cfp,"printf(\"%%.15g \",(double)");
            dump_c(expr);
            break;  
          }
          fprintf(cfp,");\n");
          TABS;
        }
        fprintf(cfp,"printf(\"\\n\");\n");
        TABS;
        newline_required = 0;
      }
      break;

    case BL_IN:
      {
        int i, numargs = pnode->argc;
        fprintf(cfp,"(\n");
        TABS;
        for (i=0; i<numargs; i++) {
          if ( i>0 && i%4 == 0 ) {
            fprintf(cfp,"\n");
            TABS;
          }
          dump_c(pnode->argv[i]);
          if (i<numargs-1) fprintf(cfp," %s ",BL_keymap(BL_OR));
        }
        fprintf(cfp," ) ");
      }
      break;

    case BL_STRCMP:
      {
        BL_Tree *left  = pnode->argv[0]; 
        BL_Symbol_Table *psym = left->argv[0]; /* Always a BL_NAME   */
        BL_Tree *right = pnode->argv[1];       /* Always a BL_STRING */

        if (in_if_cond && psym->if_flagged) {
          FD_SET(BL_nested_ifs, psym->if_flagged);
        }

        fprintf(cfp,"%s%s,",
                right->is_wildcard ? "WC(" : "SC(",
                Undotify(psym->name));
        dump_c(right);
        fprintf(cfp,")");
      }
      break;

    case BL_ASGN:
      {
        BL_Symbol_Table *psym = pnode->argv[0];
        if (psym->flag == BL_REFCONST && psym->if_flagged)
          fprintf(cfp,"%s%s = ",STAR ,Undotify(psym->name));
        else
          fprintf(cfp,"%s = ",
                  (psym->flag == BL_REFCONST && !psym->if_flagged) ?
                  Capitalize(psym->name) : Undotify(psym->name));
        /* fprintf(cfp," %s ",BL_keymap(type)); */
        dump_c(pnode->argv[1]);
      }
      break;

    case BL_STRASGN:
      {
        BL_Symbol_Table *psym = pnode->argv[0];
        fprintf(cfp,"%s = ",
                (psym->flag == BL_REFCONST && !psym->if_flagged) ?
                Capitalize(psym->name) : Undotify(psym->name));
        dump_c(pnode->argv[1]);
      }
      break;

    case BL_BLTIN:
      {
        BL_Symbol_Table *psym = pnode->argv[0];
        int i, numargs = pnode->argc - 1;
        int is_fail = !gen_main && (strcmp(psym->name,"fail") == 0 || strcmp(psym->name,"abort") == 0);
        int is_abort = !gen_main && (strcmp(psym->name,"abort") == 0);
	int varidx_len = 0;

        if (is_fail) {
	  int *varidx = BL_output_if_flagged_varidx(&varidx_len);
          fprintf(cfp,"{ const int varidx_len = %d;\n",varidx_len);
	  TABS;
          fprintf(cfp,"  const int varidx[%d] = {",varidx_len);
	  for (i=0; i<varidx_len; i++) {
	    fprintf(cfp,"%s%d", (i>0) ? ", " : " ",varidx[i]);
	  }
          fprintf(cfp," };\n");
	  TABS;
          fprintf(cfp,"  RC=C_");
	  FREE(varidx);
        }
        else {
          fprintf(cfp,"BL_");
        }

        fprintf(cfp,"%s(",is_fail ? "fail" : Undotify(psym->name));

        if (is_fail) {
	  const char *first = NULL;
          extern char *BL_output_if_flagged_variables();
          char *p = BL_output_if_flagged_variables();
          if (numargs == 0)      {
	    if (is_abort) {
	      fprintf(cfp,"ABORT_func, 1.0");
	      first = "ABORT_func";
	    }
	    else {
	      //fprintf(cfp,"%s",Capitalize("monthly, 1.0"));
	      //first = "Monthly";
	      fprintf(cfp,"%s",Capitalize("constant, 1.0"));
	      first = "Constant";
	    }
          }
          else if (numargs == 1) {
	    BL_Tree *p1node = pnode->argv[1];
	    BL_Symbol_Table *p1sym = p1node->argv[0];
	    first = Capitalize(p1sym->name);
            dump_c(pnode->argv[1]);
            fprintf(cfp,", 1.0");
          }
          else {
	    BL_Tree *p1node = pnode->argv[1];
	    BL_Symbol_Table *p1sym = p1node->argv[0];
	    first = Capitalize(p1sym->name);
	    first = BL_keymap(p1node->type);
            fprintf(cfp,", ");
            dump_c(pnode->argv[2]);
            /* fprintf(cfp,""); */
          }
          fprintf(cfp,", BL_file, %d, \"%s\", __FILE__, __LINE__, \"%s\", LR, LS, LL, varidx, varidx_len,\n",lineno,p,first);
	  TABS;
	  TABS;
          fprintf(cfp,"NAME_INDEX, NAME_INDEX_LEN, KFEEDBACK, KFEEDBACK_SIZE, ENABLE_fill_fbv, meta);\n");
	  TABS;
          fprintf(cfp," if (RC) goto return_RC; }\n");

          TABS;
          newline_required = 0;
        }
        else {
          int this_funcno = next_funcno++;
          fprintf(cfp,"%d",numargs);
          fprintf(cfp,", ARGS%d",this_funcno); /* Pass in the address of the arg-list */
          for (i=0; i<numargs; i++) {
            /* What a trick with VARARGS (...) in prototype and not using them ! */
            fprintf(cfp,", ARGS%d[%d]=",this_funcno,i);
            dump_c(pnode->argv[i+1]);
          }
          fprintf(cfp,")");
        }
      }
      break;

    default:
      fprintf(cfp," /* N/I: '%s' (%d) */ ",
                   BL_keymap(type), type);
      fprintf(stderr,"@Line#%d: Key '%s' (%d) not implemented\n",
              lineno, BL_keymap(type), type);
      break;
    } /* switch (pnode->type) */
  }
}


PRIVATE int deactivate_statement(BL_Tree *pnode)
{
  int rejected = 0;

  if (pnode) {
    int type    = pnode->type;
    int numargs = pnode->argc;
    int i;

    switch (type) {

    case BL_GT:
    case BL_GE:
    case BL_EQ:
    case BL_LE:
    case BL_LT:
    case BL_NE:
    case BL_AND:
    case BL_OR:
    case BL_ADD:
    case BL_SUB:
    case BL_MUL:
    case BL_DIV:
    case BL_POWER:
    case BL_UNARY_PLUS:
    case BL_UNARY_MINUS:
    case BL_NOT:
    case BL_IN:
      for (i=0; !rejected && i<numargs; i++) {
        rejected = deactivate_statement(pnode->argv[i]);
      }
      break;

    case BL_NUMBER:
    case BL_STRING:
      break;

    case BL_NAME:
      {
        BL_Symbol_Table *psym = pnode->argv[0];
        rejected = psym->special;
      }
      break;

    case BL_IF:
      rejected = deactivate_statement(pnode->argv[0]);
      break;

    case BL_ELSE:
    case BL_ENDIF:
    case BL_EXIT:
      break;

    case BL_PRINT:
      {
        for (i=0; !rejected && i<numargs; i++) {
          BL_Tree *expr = pnode->argv[i];
          int type = expr->type;

          switch (type) {

          case BL_NUMBER:
          case BL_STRING:
            rejected = deactivate_statement(expr);
            break;

          case BL_NAME:
            {
              BL_Symbol_Table *psym = expr->argv[0];

              rejected = psym->special;
              if (!rejected) rejected = deactivate_statement(expr);
            }
            break;

          default:
            rejected = deactivate_statement(expr);
            break;  
          }
        }
      }
      break;

    case BL_STRCMP:
      {
        BL_Tree *left  = pnode->argv[0]; 
        BL_Symbol_Table *psym = left->argv[0]; /* Always a BL_NAME    */
        BL_Tree *right = pnode->argv[1];       /* Always a BL_STRING  */

        rejected = psym->special;

        if (!rejected) {
          rejected = deactivate_statement(left);
          if (!rejected) rejected = deactivate_statement(right);
        }
      }
      break;

    case BL_ASGN:
    case BL_STRASGN:
      {
        BL_Symbol_Table *psym = pnode->argv[0];

        rejected = psym->special;
        if (!rejected) rejected = deactivate_statement(pnode->argv[1]);
      }
      break;

    case BL_BLTIN:
      {
        BL_Symbol_Table *psym = pnode->argv[0];

        numargs  = pnode->argc - 1;
        rejected = psym->special;

        if (!rejected) {
          for (i=0; !rejected && i<numargs; i++) {
            rejected = deactivate_statement(pnode->argv[i+1]);
          }
        }
      }
      break;

    default:
      rejected = 0;
      break;
    } /* switch (pnode->type) */
  }

  return rejected;
}



PRIVATE void get_numfuncs(BL_Tree *pnode, int *numfuncs)
{
  if (pnode && numfuncs) {
    int type    = pnode->type;
    int numargs = pnode->argc;
    int i;

    switch (type) {

    case BL_IF:
      numargs = 1;
    case BL_PRINT:
    case BL_GT:
    case BL_GE:
    case BL_EQ:
    case BL_LE:
    case BL_LT:
    case BL_NE:
    case BL_AND:
    case BL_OR:
    case BL_ADD:
    case BL_SUB:
    case BL_MUL:
    case BL_DIV:
    case BL_UNARY_PLUS:
    case BL_UNARY_MINUS:
    case BL_NOT:
    case BL_IN:
      for (i=0; i<numargs; i++) {
        get_numfuncs(pnode->argv[i], numfuncs);
      }
      break;

    case BL_STRCMP:
      {
        BL_Tree *left  = pnode->argv[0]; 
        BL_Tree *right = pnode->argv[1];       /* Always a BL_STRING  */

        get_numfuncs(left, numfuncs);
        get_numfuncs(right, numfuncs);
      }
      break;

    case BL_ASGN:
    case BL_STRASGN:
      get_numfuncs(pnode->argv[1], numfuncs);
      break;

    case BL_BLTIN:
      {
        numargs = pnode->argc - 1;

        *numfuncs += 1; /* Itself */

        for (i=0; i<numargs; i++) { /* Nested funcs */
          get_numfuncs(pnode->argv[i+1], numfuncs);
        }
      }
      break;

    case BL_POWER:
      {
        *numfuncs += 1; /* Itself */
        for (i=0; i<numargs; i++) { /* Nested funcs */
          get_numfuncs(pnode->argv[i], numfuncs);
        }
      }
      break;

    default:
      break;
    } /* switch (pnode->type) */
    
  } /* if (pnode) */
}

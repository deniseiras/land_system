#ifndef STATIC_LINKING
#define STATIC_LINKING
#endif

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

typedef struct _Symbol_Data {
  const char *symbol_name;
  const char *symbol_name2;
  const unsigned char char_flag;
  const unsigned char special_flag;
} Symbol_Data;

#define FORTRAN_CALL

#ifdef NO_UNDERSCORE
#define dynamic_linking_ dynamic_linking
#endif

#ifdef CRAY
#define dynamic_linking_ DYNAMIC_LINKING
/* Cray does not support dynamic linking as far as I know */
#ifdef STATIC_LINKING
#undef STATIC_LINKING
#endif
#define STATIC_LINKING
#endif

#ifdef STATIC_LINKING

/* The following externals will be defined in the generated "C_code.c" */

extern void C_blacklist_header(int   *LR          /* last_reason */,
			       double *LS          /* last_seriousness */,
			       int   *LL          /* last_lineno */,
			       unsigned char ENABLE_printing,
			       unsigned char ENABLE_mditesting,
			       const int NAME_INDEX[], int NAME_INDEX_LEN,
			       int IWORK[],
			       const double ZDATA[], int KDATA,
			       int *retcode);

extern void C_blacklist_body_entry(int   *LR          /* last_reason */,
				   double *LS          /* last_seriousness */,
				   int   *LL          /* last_lineno */,
				   unsigned char ENABLE_printing,
				   unsigned char ENABLE_mditesting,
				   const int NAME_INDEX[], int NAME_INDEX_LEN,
				   int IWORK[],
				   const double ZDATA[], int KDATA,
				   int *retcode);

extern void analysis_date_and_time(int *andate, int *antime);

extern void compilation_date_and_time(int *compdate, int *comptime);

extern int symbol_DATA_len;

extern Symbol_Data symbol_DATA[];

#endif


void (*ptr_C_blacklist_header)(
			       int   *LR          /* last_reason */,
			       double *LS          /* last_seriousness */,
			       int   *LL          /* last_lineno */,
			       unsigned char ENABLE_printing,
			       unsigned char ENABLE_mditesting,
			       const int NAME_INDEX[], int NAME_INDEX_LEN,
			       int IWORK[],
			       const double ZDATA[], int KDATA,
			       int *retcode) = 
#ifdef STATIC_LINKING
     C_blacklist_header;
#else
     NULL;
#endif

void (*ptr_C_blacklist_body_entry)(
				   int   *LR          /* last_reason */,
				   double *LS          /* last_seriousness */,
				   int   *LL          /* last_lineno */,
				   unsigned char ENABLE_printing,
				   unsigned char ENABLE_mditesting,
				   const int NAME_INDEX[], int NAME_INDEX_LEN,
				   int IWORK[],
				   const double ZDATA[], int KDATA,
				   int *retcode) =
#ifdef STATIC_LINKING
     C_blacklist_body_entry;
#else
     NULL;
#endif
     
void (*ptr_analysis_date_and_time)(int *andate, int *antime) =
#ifdef STATIC_LINKING
     analysis_date_and_time;
#else
     NULL;
#endif

void (*ptr_compilation_date_and_time)(int *raw_compdate, int *comptime) =
#ifdef STATIC_LINKING
     compilation_date_and_time;
#else
     NULL;
#endif

int *ptr_symbol_DATA_len =
#ifdef STATIC_LINKING
     &symbol_DATA_len;
#else
     NULL;
#endif

Symbol_Data (*ptr_symbol_DATA)[] =
#ifdef STATIC_LINKING
     &symbol_DATA;
#else
     NULL;
#endif

typedef double Align;

typedef struct _Entry_Names {
  char *name;
  union {
    Align align;
    void *entry;
    void (*C_blacklist)(
			int   *LR          /* last_reason */,
			double *LS          /* last_seriousness */,
			int   *LL          /* last_lineno */,
			unsigned char ENABLE_printing,
			unsigned char ENABLE_mditesting,
			const int NAME_INDEX[], int NAME_INDEX_LEN,
			int IWORK[],
			const double ZDATA[], int KDATA,
			int *retcode);
    void (*date_and_time)(int *andate, int *antime);
  } u;
} Entry_Names;



#ifdef STATIC_LINKING

FORTRAN_CALL
void dynamic_linking_(int *RC)
{
  if (RC) *RC = 0;
}

#else

#include <errno.h>
#include <dlfcn.h>

#define SET_ERROR() { perror(dlerror()); if (RC) {*RC = errno; if (*RC == 0) *RC=1;} }

static Entry_Names entry_names[] = {
  "C_blacklist_header",        NULL,
  "C_blacklist_body_entry",    NULL,
  "analysis_date_and_time",    NULL,
  "compilation_date_and_time", NULL,
  "symbol_DATA_len",           NULL,
  "symbol_DATA",               NULL,
  NULL
};

FORTRAN_CALL
void dynamic_linking_(int *RC)
{
  Entry_Names *p;

  static unsigned char first_time = 1;
  void *handle = NULL;
  char *obj = getenv("BLACK_DYNLIB");
  
  if (RC) *RC = 0;
  if (!first_time) 
    return;
  else
    first_time = 0;

  if (!obj) {
    fprintf(stderr,
	    "Environment variable BLACK_DYNLIB pointing to the dynamic object is not defined\n");
    if (RC) *RC = 1;
    return;
  }

  handle = dlopen(obj, RTLD_NOW);
  if (!handle) {
    SET_ERROR();
    fprintf(stderr,
	    "Dynamic linking of object '%s' failed\n", obj);
    return;
  }

  for (p = entry_names; p->name != NULL; p++) {
    /* fprintf(stderr,"Resolving symbol '%s' ...",p->name); */

    p->u.entry = dlsym(handle, p->name);
    if (!p->u.entry) {
      SET_ERROR();
      fprintf(stderr,
	      "Unable to resolve symbol '%s' from object '%s'\n", 
	      p->name, obj);
      return;
    }

    /* fprintf(stderr," Addr=0x%8.8x ...",p->u.entry); */

    /* On-the-fly linking */

    if      (strcmp(p->name, "C_blacklist_header") == 0) 
      ptr_C_blacklist_header = p->u.C_blacklist;
    else if (strcmp(p->name, "C_blacklist_body_entry") == 0)
      ptr_C_blacklist_body_entry = p->u.C_blacklist;
    else if (strcmp(p->name, "analysis_date_and_time") == 0)
      ptr_analysis_date_and_time = p->u.date_and_time;
    else if (strcmp(p->name, "compilation_date_and_time") == 0)
      ptr_compilation_date_and_time = p->u.date_and_time;
    else if (strcmp(p->name, "symbol_DATA_len") == 0)
      ptr_symbol_DATA_len = (int *)p->u.entry;
    else if (strcmp(p->name, "symbol_DATA") == 0)
      ptr_symbol_DATA = (Symbol_Data (*)[])p->u.entry;
    else {
      if (RC) *RC = 1;
      fprintf(stderr,
	      "Unable to relate the symbol '%s' with its runtime entry\n",
	      p->name);
      return;
    }

    /* fprintf(stderr," OK!\n"); */
  }
  
  /* dlclose(handle); */
}

#endif


/* dynamic_symbols.c */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
/* #include "drhook.h" */

#include "d4o.h"
/*
extern double d4o_get_null();
extern double d4o_set_null(double newvalue);
extern int d4o_is_null(double value);
extern const void *d4o_get_text(const double *d, int *detected_coltype);
*/

#define PRIVATE static

/* For use by the genuine C-routines */

/* int MDI_value = 2147483647; */
/* int MDI_value = 888888; */

typedef struct _Symbol_Data {
  const char *symbol_name;
  const char *symbol_name2;
  const unsigned char char_flag;
  const unsigned char special_flag;
} Symbol_Data;

extern int *ptr_symbol_DATA_len;
extern Symbol_Data (*ptr_symbol_DATA)[];

int get_symbol_index(const char *name)
{
  Symbol_Data *p = (*ptr_symbol_DATA);
  int i, index = 2147483647;
  for (i=0; i<*ptr_symbol_DATA_len; i++) {
    if (strcmp(p[i].symbol_name,name) == 0) {
      index = i;
      break;
    }
  }
  return index;
}

const char *get_symbol_name(int i)
{
  return (*ptr_symbol_DATA)[i].symbol_name;
}

const char *get_symbol_name2(int i)
{
  return (*ptr_symbol_DATA)[i].symbol_name2;
}

#if 1
const char *dtos(const double *dval)
{
  return d4o_get_text(dval,NULL);
}
#else
char *dtos(char s[], const double *dval)
{
  /* DRHOOK_START(dtos); */
  memcpy(s,dval,sizeof(double));
  s[sizeof(double)]='\0';
  /* DRHOOK_END(0); */
  return s;
}
#endif

#define NIX    NAME_INDEX
#define DTOD(i) (NIX[i]>=0 && NIX[i]<KDATA) ? &ZDATA[NIX[i]] : NULL
#define MAXSIZE 8192

char *dynamic_mditest(int no_of_external_symbols,
		      const unsigned char mask[],
		      int VARIDX[], int *VARIDX_LEN,
		      const int NAME_INDEX[], int NAME_INDEX_LEN,
		      const double ZDATA[], int KDATA)
{
  char *ptr_to_return = NULL;
  /* DRHOOK_START(dynamic_mditest); */

  *VARIDX_LEN = 0;
  if (no_of_external_symbols > 0) {
    char *ptr = NULL;
    int i;

    for (i=0; i<NAME_INDEX_LEN; i++) {
      /* fprintf(stderr,"\tmask[%d]=%d",i,(int)mask[i]); */
      if (mask[i]) {
	const double *z = DTOD(i);

	/* fprintf(stderr,"  Value=%f (%s)\n",z ? *z : 1.997, z ? "def" : "notdef"); */
      
	if (!z) continue; /* Next index, please */

	if (d4o_is_null(*z)) { /* WAS: if (fabs(*z) == MDI_value) */
	  char *last_slash;
	  const char *p = get_symbol_name2(i);  /* A "/symbol_name/" */
	  /* fprintf(stderr,"'%s' : *z=%f\n",p,*z); */
	  if (!ptr) {
	    ptr = malloc(MAXSIZE * sizeof(*ptr));
	    ptr[0] = '\0';
	  }
	  strcat(ptr,p);
	  last_slash = strrchr(ptr,'/');
	  if (last_slash) *last_slash = '\0';
	  VARIDX[(*VARIDX_LEN)++] = i; /* Generated code makes sure the
					  VARIDX[] dimension is big enough */
	}
      } /* if (mask[i]) */
    } /* for (i=0; i<NAME_INDEX_LEN; i++) */
      
    if (ptr) {
      extern char *strdup(const char *s);
      if (ptr[strlen(ptr)-1] != '/') strcat(ptr,"/");
      /* fprintf(stderr,"dynamic_mditest='%s'\n",ptr); */
      ptr_to_return = strdup(ptr); /* Save a little bit of memory */
      free(ptr);
    } /* if (ptr) */
  }

  /* DRHOOK_END(0); */
  return ptr_to_return;
}

/* Routines to be called from FORTRAN */

#ifdef NO_UNDERSCORE
#define fput_mdi_              fput_mdi
#define fget_date_and_time_    fget_date_and_time 
#define fget_symbol_table_len_ fget_symbol_table_len
#define fget_symbol_info_      fget_symbol_info
#define fget_symbol_           fget_symbol
#endif

#ifdef CRAY
#include <fortran.h>
#define fput_mdi_              FPUT_MDI
#define fget_date_and_time_    FGET_DATE_AND_TIME 
#define fget_symbol_table_len_ FGET_SYMBOL_TABLE_LEN
#define fget_symbol_info_      FGET_SYMBOL_INFO
#define fget_symbol_           FGET_SYMBOL
#else
#define _fcd char *
#define _fcdtocp(x) x
#endif

#define FORTRAN_CALL


FORTRAN_CALL void fput_mdi_(const double *mdi_value)
{
  double oldval = d4o_set_null(*mdi_value);
}

int CONV_date(const char *date)
{
  static char *months[] = {
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    NULL
  };
  char month[10];
  int mon, day, year;

  sscanf(date,"%s %d %d",month,&day,&year);
  for (mon=1; mon<=12; mon++) {
    if (strcmp(months[mon-1],month)==0) break;
  }
  
  return year * 10000 + mon * 100 + day;
}

int CONV_time(const char *time)
{
  int hh, mm, ss;
  sscanf(time,"%d:%d:%d",&hh, &mm, &ss);
  return hh * 10000 + mm * 100 + ss;
}

int analysis_date(int defa) // an integer as YYYYMMDD
{
  char *env = getenv("NANDAT");
  return env ? atoi(env) : defa;
}

int analysis_time(int defa) // an integer as HHMMSS
{
  char *env = getenv("NANTIM");
  return env ? atoi(env) : defa;
}

FORTRAN_CALL void fget_date_and_time_(int *andate, int *antime,
				      int *compdate, int *comptime)
{
  extern void (*ptr_analysis_date_and_time)(int *andate, int *antime);
  extern void (*ptr_compilation_date_and_time)(int *raw_compdate, int *raw_comptime);

  ptr_analysis_date_and_time(andate, antime);
  ptr_compilation_date_and_time(compdate, comptime);
}

FORTRAN_CALL void fget_symbol_table_len_(int *NAME_INDEX_LEN)
{
  *NAME_INDEX_LEN = *ptr_symbol_DATA_len;
}

FORTRAN_CALL void fget_symbol_(int *jj, 
			       _fcd symbol,
			       int *is_char,
			       int *is_special
#ifndef CRAY
			      , int symbol_len
#endif
			      )
{
#ifdef CRAY
  int symbol_len = _fcdlen(symbol);
#endif
  int i = *jj;
  const char *s = get_symbol_name(i);

  strncpy(_fcdtocp(symbol),s,symbol_len);
  for (i=strlen(s); i<symbol_len; i++) {
    _fcdtocp(symbol)[i] = ' ';
  }
  i = *jj;
  *is_char    = (*ptr_symbol_DATA)[i].char_flag;
  *is_special = (*ptr_symbol_DATA)[i].special_flag;
}

FORTRAN_CALL void fget_symbol_info_(_fcd DATA_NAME, 
				    int *jj, 
				    int *is_char,
				    int *is_special
#ifndef CRAY
                                    , int DATA_NAME_len
#endif
                                    )
{
  char s[512];
  char *sp = s;
  int i;
#ifdef CRAY
  int DATA_NAME_len = _fcdlen(DATA_NAME);
#endif

  if (DATA_NAME_len > sizeof(s)) DATA_NAME_len = sizeof(s);
  strncpy(s,_fcdtocp(DATA_NAME),DATA_NAME_len);
  s[DATA_NAME_len] = '\0';

  do {
    if (isupper(*sp)) *sp = tolower(*sp);
  } while(*++sp);

  i = get_symbol_index(s);
  if (i>=0 && i< *ptr_symbol_DATA_len) {
    *is_char    = (*ptr_symbol_DATA)[i].char_flag;
    *is_special = (*ptr_symbol_DATA)[i].special_flag;
  }
  else {
    *is_char = *is_special = 2;
  }
  *jj = i;
}





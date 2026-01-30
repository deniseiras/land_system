// test.c

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "d4o.h"

#define FREE(x) if (x) { free(x); (x)=NULL; }

int main(int argc, char *argv[])
{
  char *dbname = (argc > 1) ? argv[1] : NULL;
  char *sql = (argc > 2) ? argv[2] : NULL;
  
  if (dbname && sql) {
    printf("dbname = %s\n",dbname);
    printf("SQL: %s\n",sql);
    int rc;
    int dbh = d4o_open(dbname,"r");
    while (sql) {
      char *tail = NULL;
      int k,ncols, nrows, nparcnt;
      int qh = d4o_prepare(dbh,sql,&ncols,&nparcnt,&tail,&rc);
      d4o_check_error(0,stdout,
		      rc,0,
		      dbh,dbname,
		      qh,sql,
		      __FUNCTION__,__FILE__,__LINE__,
		      "d4o_prepare(dbh=%d,sql='%s',&ncols=>%d,&nparcnt=>%d,&tail=>%s,&rc=%d) = %d",
		      dbh,sql,ncols,nparcnt,tail,rc,qh);
      for (k=3; k<argc; ++k) {
	const char *s = strchr(argv[k],'"');
	if (s) { // string
	  char *c = d4o_strdup(argv[k]+1);
	  char *x = strchr(c,'"');
	  if (x) *x = 0;
	  printf("?%d = %s (TEXT)\n",k-2,c);
	  rc = d4o_bind_text(qh,k-2,c);
	  c = d4o_free(c);
	}
	else { // double/int/NULL
	  printf("?%d = %s\n",k-2,argv[k]);
	  rc = d4o_bind_double(qh,k-2,atof(argv[k]));
	}
      }

      char *q = d4o_get_query(qh,1);
      rc = d4o_exec(dbh,q);
      d4o_check_error(0,stdout,
		      rc,0,
		      dbh,dbname,
		      -1,q,
		      __FUNCTION__,__FILE__,__LINE__,
		      "d4o_exec(%d,%s) = %d",dbh,q,rc);

      char *colnames[ncols];
      int types[ncols];
      char *q0 = d4o_get_query(qh,0);
      char *qq = NULL;
      double *d = NULL;
      
      rc = d4o_getdb(qh, &d, ncols, &nrows, colnames, types, &qq);
      d4o_check_error(0,stdout,
		      rc,0,
		      dbh,dbname,
		      qh,sql,
		      __FUNCTION__,__FILE__,__LINE__,
		      "d4o_getdb() : sql='%s'",qq);
      printf("q0=%s\nrc=%d : ncols=%d : nrows=%d : nparcnt=%d : d=%p : qq=%s\n",q0?q0:"<undef>",rc,ncols,nrows,nparcnt,d,qq?qq:"<undef>");
      
      qq = d4o_free(qq);
      q0 = d4o_free(q0);
      
      rc = d4o_destroy(qh,1); // after this d4o_get_query() does not work : stmt in-active/freed
      d4o_check_error(0,stdout,
		      rc,0,
		      dbh,dbname,
		      qh,sql,
		      __FUNCTION__,__FILE__,__LINE__,
		      "d4o_destroy(%d) = %d",qh,rc);
      
      d4o_array_fprintf(stdout,d,ncols,nrows,colnames,types,q,',');
      q = d4o_free(q);
      d = d4o_free(d);
      sql = tail;
    }
    (void) d4o_close(dbh);
  }
  return 0;
}

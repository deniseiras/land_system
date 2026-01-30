// update.c

#include <stdio.h>
#include "d4o.h"

#define FREE(x) if (x) { free(x); (x)=NULL; }

int main(int argc, char *argv[])
{
  int rc;
  char *dbname = "upd.db";
  int dbh = d4o_open(dbname,"NEW");
  double *d;
  int qh;
  int nrows, ncols, nparcnt, ntmp;
  char *sql;

  sql = "create table if not exists hdr (key int unique not null, value real, statid text)";
  rc = d4o_exec(dbh,sql);
  d4o_check_error(0,stdout,
		  rc,0,
		  dbh,dbname,
		  -1,sql,
		  __FUNCTION__,__FILE__,__LINE__,
		  "d4o_exec(%d,%s) = %d",dbh,sql,rc);
 
  sql = "insert into hdr values(1,3.14,'foo'),(2,6.28,'bar')";
  rc = d4o_exec(dbh,sql);
  d4o_check_error(0,stdout,
		  rc,0,
		  dbh,dbname,
		  -1,sql,
		  __FUNCTION__,__FILE__,__LINE__,
		  "d4o_exec(%d,%s) = %d",dbh,sql,rc);

  sql = "update hdr set value = value + 1 where key > 0";
  rc = d4o_exec(dbh,sql);
  d4o_check_error(0,stdout,
		  rc,0,
		  dbh,dbname,
		  -1,sql,
		  __FUNCTION__,__FILE__,__LINE__,
		  "d4o_exec(%d,%s) = %d",dbh,sql,rc);

  sql = "create temp view foobar as select * from hdr order by key desc";
  rc = d4o_exec(dbh,sql);
  d4o_check_error(0,stdout,
		  rc,0,
		  dbh,dbname,
		  -1,sql,
		  __FUNCTION__,__FILE__,__LINE__,
		  "d4o_exec(%d,%s) = %d",dbh,sql,rc);

  sql = "select value,key,statid from hdr order by key desc";
  qh = d4o_prepare(dbh,sql,&ncols,&nparcnt,NULL,&rc);
  d4o_check_error(0,stdout,
		  rc,0,
		  dbh,dbname,
		  qh,sql,
		  __FUNCTION__,__FILE__,__LINE__,
		  "d4o_prepare(dbh=%d,sql='%s',&ncols=>%d,&nparcnt=>%d,NULL,&rc=%d) = %d",
		  dbh,sql,ncols,nparcnt,rc,qh);
  
  char *colnames[ncols];
  int types[ncols];
  
  rc = d4o_getdb(qh,&d,ncols,&nrows,colnames,types,&sql);
  d4o_check_error(0,stdout,
		  rc,0,
		  dbh,dbname,
		  qh,sql,
		  __FUNCTION__,__FILE__,__LINE__,
		  "d4o_getdb(): sql='%s'",sql);
  
  (void) d4o_array_fprintf(stdout,d,ncols,nrows,colnames,types,sql,',');
  sql = d4o_free(sql);
  
  if (d) {
    // key := column 1
    // value := column 2
    // statid := column 3
    
    int *parnum = NULL;
    
    sql = "UPDATE hdr SET value = ?1, statid = ?2 WHERE key = ?4";
    qh = d4o_prepare(dbh,sql,&ntmp,&nparcnt,NULL,&rc);
    
    d4o_check_error(0,stdout,
		    rc,0,
		    dbh,dbname,
		    qh,sql,__FUNCTION__,__FILE__,__LINE__,
		    "d4o_prepare(dbh=%d,sql='%s',&ncols=>%d,&nparcnt=>%d,NULL,&rc=%d) = %d",
		    dbh,sql,ntmp,nparcnt,rc,qh);
    
    sql = d4o_get_query(qh,0);
    printf("ncols=%d nrows=%d nparcnt=%d: (unexpanded) Query in concern : %s\n",ncols,nrows,nparcnt,sql);
    
    parnum = d4o_alloc(nparcnt,sizeof(*parnum),1);
    
    parnum[0] = 2; // column 2 := value (?1 aka [0]+1)
    parnum[1] = 3; // column 3 := statid (?2 aka [1]+1)
    parnum[2] = 0; // ?3 aka [2]+1 unused
    parnum[3] = 1; // column 4 := key (?4 aka [3]+1)
    
    rc = d4o_putdb(qh, d, ncols, nrows, types, nparcnt, parnum);
    
    d4o_check_error(0,stdout,
		    (rc<0) ? -rc : 0,0,
		    dbh,dbname,
		    qh,sql,
		    __FUNCTION__,__FILE__,__LINE__,
		    "%d = d4o_putdb(): sql='%s'",rc,sql);
    
    sql = d4o_free(sql);
    
    parnum = d4o_free(parnum);
    
    sql = "INSERT INTO hdr (key,value,statid) VALUES (?1,?2,?3)";
    qh = d4o_prepare(dbh,sql,&ncols,&nparcnt,NULL,&rc);
    d4o_check_error(0,stdout,
		    rc,0,
		    dbh,dbname,
		    qh,sql,
		    __FUNCTION__,__FILE__,__LINE__,
		    "d4o_prepare(dbh=%d,sql='%s',&ncols=>%d,&nparcnt=>%d,NULL,&rc=>%d) = %d",
		    dbh,sql,ncols,nparcnt,rc,qh);
    
    // Add one row
    d[0] = 3;
    d[1] = d4o_get_null();
    d[2] = d4o_set_text("FooBaar.txt");
    
    types[0] = d4o_get_coltype("integer",NULL); // key aka ?1
    types[1] = d4o_get_coltype("real",NULL); // value aka ?2
    types[2] = d4o_get_coltype("text",NULL); // statid aka ?3
    
    ncols = 3;
    nrows = 1;
    
    sql = d4o_get_query(qh,0);
    printf("ncols=%d nrows=%d (nparcnt=%d): (unexpanded) Query in concern : %s\n",ncols,nrows,nparcnt,sql);
    
    rc = d4o_putdb(qh, d, ncols, nrows, types, 0, NULL);

    d4o_check_error(0,stdout,
		    (rc<0) ? -rc : 0,0,
		    dbh,dbname,
		    qh,sql,
		    __FUNCTION__,__FILE__,__LINE__,
		    "%d = d4o_putdb(): sql='%s'",rc,sql);
    
    sql = d4o_free(sql);

    sql = "select * from hdr";
    qh = d4o_prepare(dbh,sql,&ncols,&nparcnt,NULL,&rc);
    d4o_check_error(0,stdout,
		    rc,0,
		    dbh,dbname,
		    qh,sql,
		    __FUNCTION__,__FILE__,__LINE__,
		    "d4o_prepare(dbh=%d,sql='%s',&ncols=>%d,&nparcnt=>%d,NULL,&rc=%d) = %d",
		    dbh,sql,ncols,nparcnt,rc,qh);
    
    d4o_fprintf(stdout,qh,0);
    
    sql = "select * from foobar";
    d4o_query_fprintf(stdout,dbh,sql,','); // OK since exec() created temp view earlier on
    
    // NOT OK:
    //d4o_query_fprintf(stdout,fd,"begin transaction; create temp view barfoo as select * from hdr; end transaction; \tselect * from barfoo",'\t');
    //d4o_query_fprintf(stdout,fd,"pragma synchronize = on; create temp view barfoo as select * from hdr; select * from barfoo",0);
    
  }
    
  d = d4o_free(d);
  
  d4o_close(dbh);
  
  return 0;
}

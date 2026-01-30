
#include "d4o.h"

#include <string.h>
#include <strings.h>
#include <stddef.h>
#include <ctype.h>
#include <unistd.h>
#include <malloc.h>
#include <math.h>
#include <limits.h>
#include <sqlite3.h>
#include <execinfo.h>
#include <assert.h>
#include <regex.h>
#include <time.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/syscall.h>

#include <sched.h>
int sched_getcpu(void);

#include "cas.h"

static volatile sig_atomic_t prof_lock = 0;
static volatile sig_atomic_t text_lock = 0;
static volatile sig_atomic_t alloc_lock = 0;
static volatile sig_atomic_t openclose_lock = 0;

// Due to gcc -std=c99 we need explicit defs
extern char *strdup(const char *s);
extern int fileno(FILE *stream);
extern struct tm *localtime_r(const time_t *timep, struct tm *result);
extern long syscall(long number, ...);
extern char *strcasestr(const char *haystack, const char *needle);
// End of explicit defs

#ifndef SYS_gettid
#define SYS_gettid __NR_gettid
#endif

static long GETtid() {
  long tid = syscall(SYS_gettid);
  return tid;
}

static const char begin_deferred_transaction[] = "BEGIN DEFERRED TRANSACTION";
static const char end_transaction[] = "END TRANSACTION";
static const char rollback_transaction[] = "ROLLBACK TRANSACTION";

#define ABS(x) ((x) >= 0 ? (x) : -(x))
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#define MAX(a,b) ((a) > (b) ? (a) : (b))

static const char *undef = "<undef>";

static double mdi = -888888.0;

static double epoch_start = 0;

static int busy_timeout_ms = 0;
static int maxretries = 100;

static int debug_mode = 0;
static int debug_rank = 0;

static int thread_safety = -1;

static int myrank = -1;
static int numranks = -1;

static const int default_width = 25; // enables at most %25g with for doubles

static const char COLTYPE_INT[] = "integer";
static const char COLTYPE_REAL[] = "real";
static const char COLTYPE_TEXT[] = "text";
//static const char COLTYPE_NULL[] = "null";

//typedef struct _DB_t DB_t;
//typedef struct _Query_t Query_t;
  
typedef struct _Query_t {
  char *sql;
  sqlite3_stmt *stmt;
  struct _DB_t *DB;
  char **colname;
  int *coltype;
  long tid;
  int nrows, ncols, nparcnt;
  int inuse;
} Query_t; // Queries

typedef struct _DB_t {
  char *name;
  sqlite3 *h;
  char *mode;
  struct _Query_t *Q; // TBD: dynamic
  long tid;
  int nQ; // TBD: for now <= DBpool_maxq
  int nextQ;
  int nfreeQ;
  int flags;
} DB_t; // Databases

typedef struct _DB_pool_t {
  DB_t *DB;
} DB_pool_t;

static DB_pool_t *DBpool = NULL; // length is DBpool_maxdb
static int DBpool_maxdb = 0; // Max simultaneously opened DBs : export d4o_maxdb=<value>
static int DBpool_maxdb_pow10 = 0; // >= DBpool_maxdb -- next power of 10
static int DBpool_maxdb_default = 100; // default 
static int DBpool_maxdb_min = 10; // Min number simultaneously opened DBs (but respects lower values if export d4o_maxdb provided)
static int DBpool_maxdb_max = 9999; // Max allowed simultaneously opened DBs
static int DBpool_next = 0; // Next free index to DBpool[]
static int DBpool_inuse = 0; // How many simultaneously open databases right now
static int DBpool_maxq = 0; // Max queries per opened database connection, e.g. 20000 : export d4o_maxq=20000
static int DBpool_maxq_default = 10000; // default
static int DBpool_maxq_min = 10; // Min number of queries per opened database
static int DBpool_maxq_max = 0; // Max will be calculated so that DBpool_maxq_max * DBpool_maxdb_pow10 < 2^31-1

static int Valid_Handle(const int *qh_or_dbh)
{
  int handle = (qh_or_dbh && *qh_or_dbh >= 0) ? *qh_or_dbh : -1;
  return handle;
}

static DB_t *this_DB(int qh_or_dbh)
{
  DB_t *pDB = NULL;
  int dbh = (qh_or_dbh >= 0) ? qh_or_dbh % DBpool_maxdb_pow10 : -1;
  if (dbh >= 0 && dbh < DBpool_maxdb) pDB = DBpool[dbh].DB;
  return pDB;
}

static Query_t *this_Q(int qh)
{
  Query_t *pQ = NULL;
  DB_t *pDB = this_DB(qh);
  if (pDB) { // TBD : no locks here ok ?
    int nQ = pDB->nQ;
    qh /= DBpool_maxdb_pow10;
    if (qh >= 0 && qh < nQ) pQ = pDB->Q + qh;
  }
  return pQ;
}

static char *filter_these(const char *in)
{
  char *out = d4o_strdup(in);
  char *p = out;
  if (p) {
    while (*p) {
      if (isspace(*p)) *p = ' '; // e.g. '\t' and '\n' become blanks ' '
      ++p;
    }
  }
  return out;
}

static int new_Q(int dbh, const char *query, const char **tail, int *retcode)
{
  int rc = SQLITE_ERROR;
  int qh = 0;
  DB_t *pDB = this_DB(dbh);
  if (pDB && query) {
    Query_t *pQ = NULL;
    long tid = GETtid();
    int nQ, nextQ, nfreeQ;
    cas_lock(&alloc_lock);
    {
      nQ = pDB->nQ;
      if (nQ == 0) { // the very first time for this pDB
	nQ = pDB->nQ = DBpool_maxq;
	pDB->Q = d4o_alloc(nQ,sizeof(Query_t),1);
	nfreeQ = pDB->nfreeQ = nQ;
	nextQ = pDB->nextQ = 0;
      }
      else {
	nfreeQ = pDB->nfreeQ;
	nextQ = pDB->nextQ;
      }
      pQ = pDB->Q + nextQ;
      if (pQ->inuse) { // need another "nextQ"
	int j, found = 0;
	for (j=nextQ+1; j<nQ; ++j) {
	  Query_t *ppQ = pDB->Q + j;
	  if (!ppQ->inuse) {
	    nextQ = j;
	    found = 1;
	    break;
	  }
	}
	if (!found) {
	  for (j=0; j<nextQ; ++j) {
	    Query_t *ppQ = pDB->Q + j;
	    if (!ppQ->inuse) {
	      nextQ = j;
	      found = 1;
	      break;
	    }
	  }
	}
	// TBD : deal with !found -- "should not happen"
      }
      pQ = pDB->Q + nextQ;
      qh = nextQ * DBpool_maxdb_pow10 + dbh;
      pQ->inuse = 1;
      pDB->nfreeQ = --nfreeQ;
      ++nextQ;
      nextQ %= nQ;
      pDB->nextQ = nextQ;
    }
    cas_unlock(&alloc_lock);
    pQ->stmt = NULL;
    pQ->DB = pDB;
    pQ->tid = tid;
    pQ->sql = filter_these(query);
    rc = sqlite3_prepare_v2(pDB->h, pQ->sql, -1, &pQ->stmt, tail);
    pQ->nrows = 0;
    if (pQ->stmt) {
      pQ->ncols = sqlite3_column_count(pQ->stmt);
      pQ->nparcnt = sqlite3_bind_parameter_count(pQ->stmt);
      if (pQ->ncols > 0) {
	int j,ncols = pQ->ncols;
	pQ->colname = d4o_alloc(ncols,sizeof(*pQ->colname),1);
	pQ->coltype = d4o_alloc(ncols,sizeof(*pQ->coltype),0);
	for (j=0; j<ncols; ++j) {
	  const char *colname = sqlite3_column_name(pQ->stmt,j);
	  const char *decl_typename = sqlite3_column_decltype(pQ->stmt,j);
	  pQ->colname[j] = d4o_strdup(colname);
	  pQ->coltype[j] = d4o_get_coltype(decl_typename,colname);
	}
      }
    }
    else {
      pQ->ncols = 0;
      pQ->nparcnt = 0;
      pQ->inuse = 0; // TBD : not behind the lock ?
    }
    if (debug_mode >= 2) {
      char *dt = d4o_datetime(NULL);
      fprintf(stderr,
	      "[%d] %s: tid=%ld: [nQ=%d,nextQ=%d,nfreeQ=%d] %s(dbh=%d[pDB=%p];query=%s[stmt=%p];tail=%p[%s];&retcode=%p[rc=%d];ncols=%d;nparcnt=%d) = %d\n",
	      myrank,dt,tid,nQ,nextQ,nfreeQ,__FUNCTION__,dbh,pDB,pQ->sql,pQ->stmt,tail,(tail && *tail)?*tail:"",retcode,rc,pQ->ncols,pQ->nparcnt,qh);
    }
    else if (debug_mode >= 1) {
      char *dt = d4o_datetime(NULL);
      fprintf(stderr,"[%d] %s: %s() [rc=%d:ncols=%d:nparcnt=%d] : %s\n",myrank,dt,__FUNCTION__,rc,pQ->ncols,pQ->nparcnt,pQ->sql);
    }
  }
  if (retcode) *retcode = rc;
  return (rc == SQLITE_OK) ? qh : -ABS(rc);
}

static char *file2str(const char *filename, size_t *len)
{
  char *out = NULL;
  FILE *fp = fopen(filename,"r");
  if (len) *len = 0;
  if (fp) {
    int fd = fileno(fp);
    struct stat statbuf;
    if (fstat(fd,&statbuf) == 0) {
      size_t sz = statbuf.st_size;
      out = d4o_alloc(sz,sizeof(*out),0);
      if (fread(out,sz,sizeof(*out),fp) == sz) {
	if (len) *len = sz;
      }
    }
    fclose(fp);
  }
  return out;
}

static char *PackColnames(int ncols, char **colname)
{
  int j;
  char *s = NULL;
  if (colname) {
    int len = 0;
    for (j=0; j<ncols; ++j) len += strlen(colname[j]);
    s = d4o_alloc(len+ncols,sizeof(*s),0);
    *s = 0;
    for (j=0; j<ncols; ++j) {
      strcat(s,(j>0) ? "," : "");
      strcat(s,colname[j]);
    }
  }
  else
    s = d4o_strdup("");
  return s;
}

static char *PackColtypes(int ncols, const int coltype[ncols], int incl_typenames)
{
  int j;
  char s[ncols*3 + 10 + (incl_typenames ? ncols * 10 : 0)];
  *s = 0;
  if (coltype) {
    for (j=0; j<ncols; ++j) {
      char number[32];
      (void) snprintf(number,sizeof(number),"%d",coltype[j]);
      strcat(s,(j>0) ? "," : "");
      strcat(s,number);
      if (incl_typenames) {
	const char *typename = d4o_get_typename(coltype[j]);
	strcat(s,":");
	strcat(s,typename);
      }
    }
  }
  return d4o_strdup(s);
}

static Query_t *delete_Queries(Query_t *pQ, int nQ, int do_free)
{
  Query_t *pQ_saved = pQ;
  if (pQ) {
    int j;
    for (j=0; j<nQ; ++j) {
      if (pQ->sql && debug_mode >= 2) {
	char *packn = PackColnames(pQ->ncols,pQ->colname);
	char *packt = PackColtypes(pQ->ncols,pQ->coltype,0);
	char *dt = d4o_datetime(NULL);
	fprintf(stderr,
		"[%d] %s: %d|%d: %s(pQ=%p) [sql=%s;stmt=%p;DB=%p;nrows=%d;ncols=%d;colname={%s};coltype={%s};nparcnt=%d;inuse=%d;tid=%ld]\n",
		myrank,dt,j+1,nQ,__FUNCTION__,pQ,
		pQ->sql,pQ->stmt,pQ->DB,pQ->nrows,pQ->ncols,packn,packt,pQ->nparcnt,pQ->inuse,pQ->tid);
	packt = d4o_free(packt);
	packn = d4o_free(packn);
      }
      pQ->sql = d4o_free(pQ->sql);
      pQ->coltype = d4o_free(pQ->coltype);
      if (pQ->colname) {
	int j,ncols = pQ->ncols;
	for (j=0; j<ncols; ++j) pQ->colname[j] = d4o_free(pQ->colname[j]);
	pQ->colname = d4o_free(pQ->colname);
      }
      pQ->DB = NULL;
      if (pQ->stmt) {
	(void) sqlite3_finalize(pQ->stmt); // deferred destroy (only for prepared stmts)
	pQ->stmt = NULL;
      }
      pQ->inuse = 0;
      ++pQ;
    }
    if (do_free) pQ_saved = d4o_free(pQ_saved);
  }
  return pQ_saved;
}

static int delete_DB(int dbh)
{
  int rc = SQLITE_ERROR;
  DB_t *pDB = this_DB(dbh);
  if (pDB) {
    sqlite3 *h = pDB->h;
    if (h) {
      cas_lock(&openclose_lock);
      {
	if (debug_mode >= 2) {
	  char *dt = d4o_datetime(NULL);
	  fprintf(stderr,
		  "[%d] %s: %s(dbh=%d) pDB=%p->[name=%s;h=%p;mode=%s;Q=%p;nQ=%d;nfreeQ=%d;nextQ=%d;flags=%d;tid=%ld]\n",
		  myrank,dt,__FUNCTION__,dbh,pDB,
		  pDB->name,pDB->h,pDB->mode,pDB->Q,pDB->nQ,pDB->nfreeQ,pDB->nextQ,pDB->flags,pDB->tid);
	}

	rc = sqlite3_close_v2(h);
	pDB->h = NULL;
	pDB->name = d4o_free(pDB->name);
	pDB->mode = d4o_free(pDB->mode);
	pDB->Q = delete_Queries(pDB->Q,pDB->nQ,1);
	pDB = d4o_free(pDB);
      }
      dbh %= DBpool_maxdb_pow10;
      DBpool[dbh].DB = NULL;
      DBpool_next = dbh;
      --DBpool_inuse;
      cas_unlock(&openclose_lock);
    }
  }
  return rc;
}

static DB_t *new_DB(const char *dbname, const char *mode, int flags, int *retcode)
{
  int rc = SQLITE_ERROR;
  DB_t *pDB = d4o_alloc(1,sizeof(*pDB),1);
  if (pDB) {
    sqlite3 *h = NULL;
    rc = sqlite3_open_v2(dbname,&h,flags,NULL);
    if (rc == SQLITE_OK) {
      const char *db_fullpath = sqlite3_db_filename(h,NULL);
      pDB->h = h;
      pDB->name = d4o_strdup(db_fullpath);
      pDB->mode = d4o_strdup(mode);
      pDB->flags = flags;
      pDB->tid = GETtid();
      if (busy_timeout_ms > 0) {
	int iret = sqlite3_busy_timeout(h,busy_timeout_ms);
	if (iret != SQLITE_OK) {
	  char *dt = d4o_datetime(NULL);
	  fprintf(stderr,"[%d] %s: %s: Unable to set sqlite3_busy_timeout() of %dms for db=%s : rc=%d\n",
		  myrank,dt,__FUNCTION__,busy_timeout_ms,pDB->name,iret);
	  d4o_TraceBack(stderr,"sqlite3_busy_timeout()");
	  d4o_ErrExit(__FUNCTION__,"rc != SQLITE_OK",iret);
	}
      }
    }
  }
  if (retcode) *retcode = rc;
  return pDB;
}

#define KIND_NONE 0
#define KIND_CHAR 1
#define KIND_PTR 2

typedef union {
  void *ptr;
  long long int lli;
} alias_t;

//typedef struct _Node_t Node_t;
typedef struct _Node_t {
  void *str;
  struct _Node_t *right;
  struct _Node_t *left;
  size_t len;
  size_t refcount;
  int kind;
} Node_t;

typedef union {
  Node_t *p;
  double d;
} dblNode_t;

static Node_t *InsertBinTree(Node_t **node, const void *val, int kind);
static Node_t *SearchBinTree(Node_t **tree, const void *val, int kind);
static Node_t *DeleteBinTree(Node_t *tree);
static void PrintBinTree(FILE *fp, const Node_t *tree);

static Node_t *textpool = NULL;
static Node_t *ptrpool = NULL;

static const char *null = "NULL";

static FILE *fprof = NULL;
static char *fprofile = NULL;
static char *fprofsql = NULL;

static int init_done = 0;

static void D4O_init() __attribute__((constructor));
static void D4O_init()
{
  if (init_done) return;
  init_done = 1;
  {
    // Initialize possible MPI env w/o using MPI-calls
    d4o_mpirank(NULL); // myrank now >= 0
    d4o_mpisize(NULL); // numranks now >= 1
  }
  {
    int rc = sqlite3_initialize();
    if (rc != SQLITE_OK) {
      char *dt = d4o_datetime(NULL);
      fprintf(stderr,"[%d] %s: %s: Unable to sqlite3_initialize() : rc=%d\n",myrank,dt,__FUNCTION__,rc);
      d4o_TraceBack(stderr,"sqlite3_initialize()");
      d4o_ErrExit(__FUNCTION__,"rc != SQLITE_OK",rc);
    }
  }
  { // busy timeout ?
    char *env = getenv("d4o_busy_timeout_ms");
    if (!env) env = getenv("d4o_busy_timeout"); // Forgot "_ms" => ok -- still in "ms"
    if (env) {
      int timeout = atoi(env);
      if (timeout > 0) busy_timeout_ms = timeout;
    }
  }
  { // max re-tries in case of busy timeout occurred ?
    char *env = getenv("d4o_maxretries");
    if (!env) env = getenv("d4o_maxretrys"); // Spelling lenience
    if (env) {
      int n = atoi(env);
      if (n > 0) maxretries = n;
    }
  }
  { // debug mode ?
    // two formats : plain number 0 ... N => applies to all MPI-ranks
    //               syntax number:rank e.g. 1:5 => debug_mode = 1 for MPI-rank#5 only
    char *env = getenv("d4o_debug");
    if (env) {
      const char *colon = strchr(env,':');
      debug_mode = atoi(env);
      if (colon) {
	int target_rank = atoi(colon+1);
	if (myrank != target_rank) debug_mode = 0;
      }
      debug_rank = (debug_mode > 0) ? myrank : 0;
      debug_mode = (debug_mode > 0) ? debug_mode : 0;
    }
  }
  {
    char *env = getenv("d4o_profile");
    double ts = d4o_timestamp();
    double wt = ts - epoch_start;
    char *dt = d4o_datetime(&ts);
    int libversion_number = sqlite3_libversion_number();
    const char *source_id = sqlite3_sourceid(); // SELECT sqlite_source_id();
    const char *libversion = sqlite3_libversion(); // SELECT sqlite_version();
    if (libversion_number < SQLITE_VERSION_NUMBER) {
      d4o_ErrExit(__FUNCTION__,"libversion_number < SQLITE_VERSION_NUMBER",-1);
    }
    //assert( sqlite3_libversion_number()==SQLITE_VERSION_NUMBER );
    //assert( strncmp(sqlite3_sourceid(),SQLITE_SOURCE_ID,80)==0 );
    //assert( strcmp(sqlite3_libversion(),SQLITE_VERSION)==0 );
    (void) d4o_set_text(""); // warm up &textpool & ptrpool
    if (myrank == debug_rank) {
      fprintf(stderr,"[%d] %s: Starting %s() : SQLite %s (%d) -- %s : # of MPI-ranks = %d : busy_timeout_ms = %d\n",
	      myrank,dt,__FUNCTION__,
	      libversion,libversion_number,source_id,numranks,busy_timeout_ms);
    }
    if (!DBpool) {
      int ndigits;
      char *maxq = getenv("d4o_maxq");
      char *maxdb = getenv("d4o_maxdb");
      int value = maxdb ? atoi(maxdb) : 0;
      if (value < 0) value = 0;
      DBpool_maxdb = maxdb ? value : DBpool_maxdb_default;
      if (maxdb) DBpool_maxdb_min = 1; // env d4o_maxdb was indeed supplied and can now be anything >= 1
      value = DBpool_maxdb = MAX(DBpool_maxdb,DBpool_maxdb_min);
      ndigits = (int)(log10(DBpool_maxdb) + (double)1.5);
      DBpool_maxdb_pow10 = pow(10,ndigits);
      DBpool = d4o_alloc(DBpool_maxdb,sizeof(*DBpool),1);
      DBpool_next = 0;
      DBpool_inuse = 0;
      // DBpool_maxq_max * DBpool_maxdb < 2^31-1 aka INT_MAX=2147483647 from which:
      DBpool_maxq_max = INT_MAX / DBpool_maxdb_pow10;
      DBpool_maxq = maxq ? atoi(maxq) : DBpool_maxq_default;
      DBpool_maxq = MAX(DBpool_maxq,DBpool_maxq_min);
      DBpool_maxq = MIN(DBpool_maxq,DBpool_maxq_max);
      if (debug_mode >= 1) {
	fprintf(stderr,
		"[%d] %s: %s(): DBpool_maxdb{=%d,_pow10=%d,_default=%d,_min=%d,_max=%d} : DBpool_maxq{=%d,_default=%d,_min=%d,_max=%d}\n",
		myrank,dt,__FUNCTION__,
		DBpool_maxdb,DBpool_maxdb_pow10,DBpool_maxdb_default,DBpool_maxdb_min,DBpool_maxdb_max,
		DBpool_maxq,DBpool_maxq_default,DBpool_maxq_min,DBpool_maxq_max);
      }
    }
    if (env) {
      char *colon = strchr(env,':');
      if (colon) {
	int target_rank = atoi(colon+1);
	if (myrank != target_rank) env = NULL;
	if (env) *colon = 0;
      }
    }
    if (env) {
      int n = strlen(env);
      char profile[n+20];
      char *dot = strrchr(env,'.');
      if (dot) *dot = 0;
      if (numranks > 1) {
	snprintf(profile,sizeof(profile),"%s.%d.csv",env,myrank); // NB: per task
      }
      else {
	snprintf(profile,sizeof(profile),"%s.csv",env);
      }
      fprof = fopen(profile,"w");
      if (fprof) {
	fprofile = d4o_strdup(profile);
	fprintf(stderr,"[%d] %s: Profiling data goes to file '%s'\n",myrank,dt,fprofile);
	fprofile = d4o_free(fprofile);
	fprintf(fprof,"#text,integer,integer,integer,real,real,integer,integer,integer,integer,text,text\n");
	fprintf(fprof,"#function,rank,tid,coreid,cumul,delta,nrows,ncols,nparcnt,retcode,datetime,info\n");
	fprofsql="CREATE TABLE IF NOT EXISTS profdata"
	  " (function text"
	  ", rank integer"
	  ", tid integer"
	  ", coreid integer"
	  ", cumul real"
	  ", delta real"
	  ", nrows integer"
	  ", ncols integer"
	  ", nparcnt integer"
	  ", retcode integer"
	  ", datetime text"
	  ", dbh integer"
	  ", dbname text"
	  ", qh integer"
	  ", query text"
	  ", info text); "
	  "CREATE VIEW IF NOT EXISTS profout0 AS"
	  " SELECT function AS routine,sum(delta) AS time,count(*) AS ncalls"
	  " FROM profdata GROUP BY routine"
	  " HAVING time > 0"
	  " ORDER BY time DESC; "
	  "CREATE VIEW IF NOT EXISTS profout1 AS"
	  " SELECT function AS routine,rank,tid,coreid,sum(delta) AS time,count(*) AS ncalls"
	  " FROM profdata GROUP BY routine,rank,tid,coreid"
	  " HAVING time > 0"
	  " ORDER BY time DESC; "
	  "CREATE VIEW IF NOT EXISTS profout2 AS"
	  " SELECT function AS routine,rank,tid,coreid,sum(delta) AS time,count(*) AS ncalls"
	  ",CAST(printf(\"%.0f\",count(*)/sum(delta)) AS integer) AS 'calls/sec'"
	  ",CAST(printf(\"%.0f\",sum(nrows)/sum(delta)) AS integer) AS 'rows/sec'"
	  ",CAST(printf(\"%d\",sum(nrows*ncols)*8) AS integer) AS nbytes" 
	  ",CAST(printf(\"%.0f\",(sum(nrows*ncols)*8)/sum(delta)) AS integer) AS 'nbytes/sec'" 
	  ",query"
	  " FROM profdata GROUP BY routine,rank,tid,coreid,query"
	  " HAVING time > 0"
	  " ORDER BY time DESC; "
	  "CREATE VIEW IF NOT EXISTS alldata AS"
	  " SELECT * FROM profdata ORDER BY delta DESC"
	  ;
	{
	  long tid = GETtid();
	  int coreid = d4o_coreid();
	  const int types[3] = { SQLITE_INTEGER, SQLITE_FLOAT, SQLITE_TEXT };
	  char *packt = PackColtypes(sizeof(types)/sizeof(*types),types,1);
	  int default_type = d4o_get_coltype(NULL,NULL);
	  const char *typename = d4o_get_typename(default_type);
	  thread_safety = sqlite3_threadsafe();
	  if (myrank == debug_rank) {
	    char *dt = d4o_datetime(NULL);
	    fprintf(stderr,"[%d] %s: %s(): rank=%d:tid=%ld:coreid=%d:thread_safety=%d:supported_coltypes={%s}:default_type={%d:%s}\n",
		    myrank,dt,__FUNCTION__,myrank,tid,coreid,thread_safety,packt,default_type,typename);
	  }
	  d4o_profile(__FUNCTION__,d4o_wtime()-wt,
		      0,0,0,0,
		      -1,NULL,
		      0,NULL,
		      "BEGIN:rank=%d:tid=%ld:coreid=%d:thread_safety=%d:supported_coltypes={%s}:default_type={%d:%s}",
		      myrank,tid,coreid,thread_safety,packt,default_type,typename);
	  packt = d4o_free(packt);
	}
      }
    }
  }
}

static void D4O_fini() __attribute__((destructor));
static void D4O_fini()
{
  static int fini_done = 0;
  if (!init_done) return;
  if (fini_done) return;
  fini_done = 1;
  {
    double ts = d4o_timestamp();
    double wt = ts - epoch_start;
    char *dt = d4o_datetime(&ts);
    if (myrank == debug_rank) {
      fprintf(stderr,"[%d] %s: Ending %s()\n",myrank,dt,__FUNCTION__);
    }
    if (fprof) {
      int dbg_mode = debug_mode;
      int rc;
      d4o_profile(__FUNCTION__,d4o_wtime()-wt,
		  0,0,0,0,
		  -1,NULL,
		  -1,NULL,
		  "END");
      if (myrank == debug_rank) {
	fprintf(stderr,"[%d] %s: Closing profile '%s'\n",myrank,dt,fprofile);
      }
      rc = fclose(fprof);
      fprof = NULL; // profiling OFF
      debug_mode = 0; // debug mode OFF
      if (fprofsql) {
	int dbh;
	char *csvfile = d4o_strdup(fprofile);
	char *dbname = d4o_strdup(fprofile);
	char *dot = strrchr(dbname,'.');
	if (dot) *dot = 0;
	strcat(dbname,".db");
	dbh = d4o_opendb(dbname,"rwc");
	rc = (dbh >= 0) ? SQLITE_OK : -dbh;
	if (dbh >= 0) rc = d4o_exec(dbh,fprofsql);
	if (rc >= 0) rc = d4o_long_column_names(dbh,0);
	if (rc >= 0) {
	  char *sql;
	  int n = strlen(dbname) + strlen(csvfile);
	  char cmd[n + 256];
	  rc = snprintf(cmd,sizeof(cmd),
			"sqlite3 -batch -init /dev/null -nullvalue 'NULL' %s \".import --csv --skip 2 %s %s\"",
			dbname,csvfile,"profdata");
	  rc = system(cmd);
	  ts = d4o_timestamp();
	  dt = d4o_datetime(&ts);
	  sql = "UPDATE profdata SET info = NULL WHERE info = ''"
	    "; UPDATE profdata SET dbname = NULL WHERE dbname = ''"
	    "; UPDATE profdata SET query = NULL WHERE query = ''"
	    ;
	  rc = d4o_exec(dbh, sql);
	  if (myrank == debug_rank) {
	    fprintf(stderr,"[%d] %s: The most time consuming routines using the profile-database '%s':\n",myrank,dt,dbname);
	    sql = "SELECT * FROM profout0";
	    rc = d4o_query_fprintf(stderr, dbh, sql, 0);
	    sql = "SELECT * FROM profout1";
	    rc = d4o_query_fprintf(stderr, dbh, sql, 0);
	    sql = "SELECT * FROM alldata LIMIT 10";
	    rc = d4o_query_fprintf(stderr, dbh, sql, ',');
	  }
	  rc = d4o_closedb(dbh);
	}
	dbname = d4o_free(dbname);
	csvfile = d4o_free(csvfile);
      }
      debug_mode = dbg_mode; // restore debug mode (doubt, if any use after this)
    }
  }
  DBpool = d4o_free(DBpool);
  textpool = DeleteBinTree(textpool);
  ptrpool = DeleteBinTree(ptrpool);
  {
    int rc = sqlite3_shutdown();
    if (rc != SQLITE_OK) {
      char *dt = d4o_datetime(NULL);
      fprintf(stderr,"[%d] %s: %s: Unable to sqlite3_shutdown() : rc=%d\n",myrank,dt,__FUNCTION__,rc);
      d4o_TraceBack(stderr,"sqlite3_shutdown()");
      d4o_ErrExit(__FUNCTION__,"rc != SQLITE_OK",rc);
    }
  }
}

void d4o_finalize()
{
  D4O_init();
}

int d4o_coreid()
{
  return sched_getcpu();
}

void d4o_profile(const char *func, double delta,
		 int nrows, int ncols, int nparcnt, int rc,
		 int dbh, const char *dbname,
		 int qh, const char *query,
		 const char *fmt, ...)
{
  if (fprof) {
    char s[65536] = "";
    double cumul = d4o_wtime();
    double ts = d4o_timestamp();
    cas_lock(&prof_lock);
    {
      char *dt = d4o_datetime(&ts);
      if (fmt) {
	va_list ap;
	va_start(ap, fmt);
	vsnprintf(s, sizeof(s), fmt, ap);
	va_end(ap);
      }
      fprintf(fprof,"\"%s\",%d,%ld,%d,%.6f,%.6f,%d,%d,%d,%d,\"%s\",%d,\"%s\",%d,\"%s\",\"%s\"\n",
	      func,myrank,GETtid(),d4o_coreid(),cumul,delta,nrows,ncols,nparcnt,rc,dt,
	      dbh,dbname ? dbname : "",
	      qh,query ? query : "",
	      s);
    }
    cas_unlock(&prof_lock);
  }
}

double d4o_timestamp()
{
  static int done = 0;
  double key = 0;
#if defined(CLOCK_REALTIME)
  struct timespec tv;
  if (clock_gettime(CLOCK_REALTIME,&tv) == 0) {
    key = (double) tv.tv_sec + (double) tv.tv_nsec / 1000000000;
  }
#else
  struct timeval tv;
  if (gettimeofday(&tv, NULL) == 0) {
    key = (double) tv.tv_sec + (double) tv.tv_usec / 1000000;
  }
#endif
  if (!done) { // Once only
    char *env = getenv("d4o_epoch"); // export d4o_epoch=$(date +%s.%N)
    if (env) {
      double value;
      int nelem = sscanf(env,"%lf",&value);
      if (nelem == 1) key = value;
    }
    epoch_start = key;
    done = 1;
  }
  return key;
}

double d4o_wtime()
{
  double t = d4o_timestamp();
  return t - epoch_start;
}

char *d4o_datetime(const double *Epoch)
{
  static char s[256];
  struct tm *tm, TM;
  time_t t = Epoch ? (time_t)*Epoch : (time_t)d4o_timestamp();
  //tm = gmtime(&t);
  //tm = localtime(&t);
  tm = localtime_r(&t,&TM); // thread safe
  //strftime(s, sizeof(s), "%A, %Y-%m-%d %H:%M:%S %Z", tm);
  strftime(s, sizeof(s), "%Y-%m-%d %H:%M:%S", tm);
  //strftime(s, sizeof(s), "%Y-%m-%d %H:%M:%S", &TM);
  return s;
}

char *d4o_get_errmsg(int rc)
{
  const char *s = sqlite3_errstr(rc); // here: rc >= 0 i.e. >= SQLITE_OK
  int slen = s ? strlen(s) : 0;
  if (slen > 0) {
    char ss[slen+40];
    int n = snprintf(ss,sizeof(ss),"[%d] : %s",rc,s);
    return d4o_strdup(ss);
  }
  else {
    return d4o_strdup(s);
  }
}

double d4o_set_text(const char *s)
{
  double d = 0;
  if (s) {
    dblNode_t alias;
    cas_lock(&text_lock);
    alias.p = InsertBinTree(&textpool,s,KIND_CHAR);
    if (!SearchBinTree(&ptrpool,alias.p,KIND_PTR)) {
      Node_t *pn = InsertBinTree(&ptrpool,alias.p,KIND_PTR);
    }
    d = alias.d;
    cas_unlock(&text_lock);
  }
  return d;
}

const void *d4o_get_text(const double *d, int *detected_coltype)
{
  const void *s = NULL;
  int coltype = SQLITE_TEXT;
  cas_lock(&text_lock);
  if (!d) {
    coltype = SQLITE_NULL;
    s = &mdi;
  }
  else {
    dblNode_t alias;
    double tmp = *d;
    alias.d = tmp;
    if (SearchBinTree(&ptrpool,alias.p,KIND_PTR)) {
      s = alias.p->str;
    }
    else if (detected_coltype) {
      if (d4o_is_null(tmp)) {
	coltype = SQLITE_NULL;
      }
      else if ((long long int)tmp == tmp) {
	coltype = SQLITE_INTEGER;
      }
      else {
	coltype = SQLITE_FLOAT;
      }
      s = d;
    }
  }
  cas_unlock(&text_lock);
  if (detected_coltype) *detected_coltype = coltype;
  return s;
}

int d4o_get_textlen(double d)
{
  int len;
  dblNode_t alias;
  cas_lock(&text_lock);
  alias.d = d;
  if (SearchBinTree(&ptrpool,alias.p,KIND_PTR)) {
    len = alias.p->len;
  }
  else {
    char flpnum[80];
    if (d4o_is_null(d)) {
      len = 4; // strlen of ("NULL") == 4
    }
    else if ((long long int)d == d) {
      (void) snprintf(flpnum,sizeof(flpnum),"%lld",(long long int)d);
      len = strlen(flpnum);
    }
    else {
      char *pflpnum = flpnum;
      (void) snprintf(flpnum,sizeof(flpnum),"%*g",default_width,d);
      while (*pflpnum == ' ') ++pflpnum; // remove leading blanks
      len = strlen(pflpnum);
    }
  }
  cas_unlock(&text_lock);
  return len;
}

int d4o_get_debug()
{
  return debug_mode;
}

int d4o_set_debug(int newvalue)
{
  int oldvalue = debug_mode;
  debug_mode = (newvalue > 0) ? newvalue : 0;
  return oldvalue;
}

double d4o_get_null()
{
  return mdi;
}

double d4o_set_null(double newvalue)
{
  double oldvalue = mdi;
  mdi = newvalue;
  return oldvalue;
}

int d4o_is_null(double value)
{
  // NB: the value is NaN or Inf => set to NULL as well as if being == mdi
  return (!isfinite(value) || value == mdi) ? 1 : 0;
}

void *d4o_free(void *x)
{
  if (x) free(x);
  return NULL;
}

char *d4o_strdup(const char *s)
{
  return s ? strdup(s) : NULL;
}

void *d4o_alloc(size_t nmemb, size_t size, int initzero)
{
  //  void *p = initzero ? calloc(nmemb,size) : malloc(nmemb*size);
  const size_t alignment = sizeof(void *);
  size_t totsize = nmemb*size;
  void *p = memalign(alignment,totsize);
  if (p && initzero) memset(p,0,totsize);
  return p;
}

int d4o_maxdb()
{
  return DBpool_maxdb;
}

int d4o_get_dbh(int qh)
{
  return qh % DBpool_maxdb_pow10;
}

char *d4o_get_dbname(int dbh)
{
  DB_t *pDB = this_DB(dbh);
  const char *dbname = pDB ? pDB->name : NULL;
  return d4o_strdup(dbname);
}

int d4o_check_error(int do_abort, FILE *fp,
		    int rc, int expected,
		    int dbh, const char *DBname,
		    int qh, const char *Sql,
		    const char *func, const char *filename, int lineno,
		    const char *fmt, ...)
{
  if (rc != expected) {
    char *dbname = d4o_strdup(DBname);
    if (!dbname) dbname = d4o_get_dbname(dbh);
    if (!dbname) dbname = d4o_strdup(undef);
    if (!fp) fp = stderr;
    {
      char *dt = d4o_datetime(NULL);
      char *sql = d4o_get_query(qh,0); // original, un-expanded SQL, if any
      if (!sql && Sql) sql = d4o_strdup(Sql);
      fprintf(fp,"\n[%d] %s: %s : %s in %s() at %s:%d : rc=%d : expected=%d [='%s']\n",
	      myrank, dt, dbname,
	      do_abort ? "Error" : "Warning",
	      func ? func : undef,
	      filename ? filename : undef,
              lineno,
	      rc, expected, sqlite3_errstr(expected));
      
      fprintf(fp,"[%d] %s: %s : rc=%d [='%s'] in qh=%d : %s\n",
	      myrank,dt,dbname,rc,sqlite3_errstr(rc),
	      qh,sql?sql:undef);
      sql = d4o_free(sql);
      
      if (fmt) {
	fprintf(fp,"[%d] %s: %s : ",myrank,dt,dbname);
	{
	  va_list ap;
	  va_start(ap, fmt);
	  vfprintf(fp, fmt, ap);
	  va_end(ap);
	}
	fprintf(fp,"\n");
      }
      d4o_TraceBack(fp,dbname);
      fprintf(fp,"\n");
    }
    dbname = d4o_free(dbname);
    if (do_abort) {
      d4o_ErrExit(__FUNCTION__,"rc != expected",rc);
    }
  }
  return rc;
}
				 
int d4o_opendb(const char *dbname, const char *mode)
{
  int dbh;
  double dwt = 0;
  double wt = fprof ? d4o_wtime() : 0; 
  DB_t *pDB = NULL;
  int rc, flags = 0, db_exists = -1;
  char *p_dbname = NULL;
  if (!mode) mode = "readonly";
  if (!dbname) {
    dbname = p_dbname = d4o_strdup(":memory:");
  }
  else if (strlen(dbname) > 1 && *dbname == '$') {
    char *env = getenv(dbname+1);
    if (env) dbname = p_dbname = d4o_strdup(env);
  }
  if (strcasecmp(dbname,":memory:") == 0) {
    flags = SQLITE_OPEN_MEMORY; // automatically read-write-create as well
  }
  else {
    db_exists = (access(dbname,F_OK) == 0) ? 1 : 0;
    //int db_create = 0;
    if (strcasecmp(mode,"r") == 0 ||
	strcasecmp(mode,"r/o") == 0 ||
	strcasecmp(mode,"read") == 0 ||
	strcasecmp(mode,"readonly") == 0) {
      flags = SQLITE_OPEN_READONLY;
    }
    else if (strcasecmp(mode,"create") == 0 ||
	     strcasecmp(mode,"new") == 0 ||
	     strcasecmp(mode,"rwc") == 0) {
      if (db_exists) (void) unlink(dbname);
      flags = SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE;
      //db_create = 1;
    }
    else if (strcasecmp(mode,"rw") == 0 ||
	     strcasecmp(mode,"r/w") == 0 ||
	     strcasecmp(mode,"w") == 0 ||
	     strcasecmp(mode,"write") == 0 ||
	     strcasecmp(mode,"readwrite") == 0 ||
	     strcasecmp(mode,"unknown") == 0) {
      flags = SQLITE_OPEN_READWRITE;
      if (!db_exists) {
	flags |= SQLITE_OPEN_CREATE;
	//db_create = 1;
      }
    }
    else if (strcasecmp(mode,"old") == 0 ||
	     strcasecmp(mode,"update") == 0 ||
	     strcasecmp(mode,"updatable") == 0) {
      flags = SQLITE_OPEN_READWRITE;
      if (!db_exists) {
	// We must abort, since database MUST exist
	// SQLITE_OPEN_READWRITE checks that is exists and acts accordingly if not
      }
    }
  }
  pDB = new_DB(dbname,mode,flags,&rc);
  if (!pDB) { // Report error & continue
    (void) d4o_check_error(0,NULL,
			   rc,SQLITE_OK,
			   -1,dbname,
			   0,NULL,
			   __FUNCTION__,__FILE__,__LINE__,
			   "new_DB(dbname=%s,mode=%s,flags=%d,&rc=%d) = %p : db_exists=%d",
			   dbname,mode,flags,rc,pDB,db_exists);
  }
  
  if (rc == SQLITE_OK) {
    cas_lock(&openclose_lock);
    // TBD : sanity checking is missing
    if (DBpool_inuse < DBpool_maxdb) {
      int k,j = DBpool_next;
      DBpool[j].DB = pDB;
      dbh = j;
      if (fprof) dwt = d4o_wtime();
      // Enable full column names (this info NOT stored in database thus ok for R/O)
      (void) d4o_long_column_names(dbh,1); // calls d4o_exec()
      if (fprof) dwt = d4o_wtime()-dwt;
      DBpool_next = -1;
      ++DBpool_inuse;
      if (DBpool_inuse < DBpool_maxdb) {
	for (k=0; k<DBpool_maxdb; ++k) {
	  if (k != j && !DBpool[k].DB) {
	    DBpool_next = k;
	    break;
	  }
	}
      }
      // TBD : what if DBpool_next is still == -1 ?
    }
    cas_unlock(&openclose_lock);
  }
  else
    dbh = -rc; // a negative number

  if (debug_mode >= 1) {
    char *dt = d4o_datetime(NULL);
    fprintf(stderr,"[%d] %s: d4o_opendb(%s,%s) => dbh=%d : flags=%d : db_exists=%d\n",myrank,dt,dbname,mode,dbh,flags,db_exists);
  }
  
  if (fprof) {
    d4o_profile(__FUNCTION__,d4o_wtime()-wt-dwt,
		0,0,0,rc,
		dbh,pDB ? pDB->name : dbname,
		-1,NULL,
		"mode=%s;flags=%d",mode,flags);
  }
  (void) d4o_free(p_dbname);
  return dbh;
}

int d4o_cascade(int dbh, int onoff)
{
  int rc;
  char query[256];
  int n = snprintf(query,sizeof(query),
		   "PRAGMA foreign_keys = %s",
		   onoff ? "ON" : "OFF");
  rc = d4o_exec(dbh,query);
  return rc;
}

int d4o_long_column_names(int dbh, int onoff)
{
  int rc;
  char query[256];
  int n = snprintf(query,sizeof(query),
		   "PRAGMA full_column_names = %s; PRAGMA short_column_names = %s",
		   onoff ? "ON" : "OFF",
		   onoff ? "OFF" : "ON");
  rc = d4o_exec(dbh,query);
  return rc;
}

int d4o_closedb(int dbh)
{
  int rc = SQLITE_ERROR;
  double wt = fprof ? d4o_wtime() : 0;
  DB_t *pDB = this_DB(dbh);
  char *dbname = pDB ? d4o_strdup(pDB->name) : NULL;
  char *dbmode = pDB ? d4o_strdup(pDB->mode) : NULL;
  rc = delete_DB(dbh);
  if (debug_mode >= 1) {
    char *dt = d4o_datetime(NULL);
    fprintf(stderr,"[%d] %s: d4o_closedb(dbh=%d [dbname=%s,mode=%s]) => rc=%d\n",
	    myrank,dt,dbh,
	    dbname ? dbname : undef,
	    dbmode ? dbmode : undef,
	    rc);
  }
  // Report error & continue
  (void) d4o_check_error(0,NULL,
			 rc,SQLITE_OK,
			 dbh,dbname,
			 0,NULL,
			 __FUNCTION__,__FILE__,__LINE__,
			 "delete_DB(dbh=%d) = %d",dbh,rc);
  if (fprof) d4o_profile(__FUNCTION__,d4o_wtime()-wt,
			 0,0,0,rc,
			 dbh,dbname,
			 -1,NULL,
			 NULL);
  dbname = d4o_free(dbname);
  dbmode = d4o_free(dbmode);
  return rc;
}

int d4o_execfile(int dbh, const char *sqlfile)
{
  char *query = file2str(sqlfile,NULL);
  int rc = d4o_exec(dbh,query);
  query = d4o_free(query);
  return rc;
}

int d4o_exec(int dbh, const char *query)
{
  double wt = fprof ? d4o_wtime() : 0;
  DB_t *pDB = this_DB(dbh);
  if (query && debug_mode >= 1) {
    const char *quote = strchr(query,'"') ? "'" : "\"";
    char *dt = d4o_datetime(NULL);
    fprintf(stderr,"[%d] %s: d4o_exec(dbh=%d,query=%s%s%s)\n",
	    myrank,dt,dbh,quote,query,quote);
  }
  int rc = sqlite3_exec(pDB ? pDB->h : NULL,query,NULL,NULL,NULL);
  if (fprof) {
    char *f = filter_these(query);
    d4o_profile(__FUNCTION__,d4o_wtime()-wt,
		0,0,0,rc,
		dbh,NULL,
		-1,f,
		NULL);
    f = d4o_free(f);
  }
  return rc;
}

int d4o_get_ncols(int qh)
{
  Query_t *pQ = this_Q(qh);
  return pQ ? pQ->ncols : 0;
}

int d4o_get_nparcnt(int qh)
{
  Query_t *pQ = this_Q(qh);
  return pQ ? pQ->nparcnt : 0;
}

char *d4o_get_query(int qh, int expanded)
{
  Query_t *pQ = this_Q(qh);
  char *sql = NULL;
  if (pQ) {
    if (expanded) {
      char *s = sqlite3_expanded_sql(pQ->stmt);
      char *tmp = d4o_strdup(s);
      sqlite3_free(s);
      sql = filter_these(tmp);
      tmp = d4o_free(tmp);
    }
    else {
      sql = filter_these(pQ->sql);
    }
  }
  return sql;
}

int d4o_prepare(int dbh, const char *query, int *Ncols, int *Nparcnt, char **Tail, int *Errcode)
{
  double wt = fprof ? d4o_wtime() : 0;
  int rc;
  const char *tail = NULL;
  int qh = new_Q(dbh,query,&tail,&rc);
  if (rc == SQLITE_OK) {
    if (Ncols) *Ncols = d4o_get_ncols(qh);
    if (Nparcnt) *Nparcnt = d4o_get_nparcnt(qh);
    if (Tail) {
      *Tail = NULL;
      if (tail) {
	while (*tail) {
	  if (!isspace(*tail)) break;
	  ++tail;
	}
	if (strlen(tail) > 0) *Tail = d4o_strdup(tail);
      }
    }
  }
  else {
    qh = -ABS(rc);
    if (Ncols) *Ncols = 0;
    if (Nparcnt) *Nparcnt = 0;
    if (Tail) *Tail = NULL;
  }
  if (fprof) {
    char *f = filter_these(query);
    char *tf = (Tail && *Tail) ? filter_these(*Tail) : NULL;
    d4o_profile(__FUNCTION__,d4o_wtime()-wt,
		0,Ncols?*Ncols:0,Nparcnt?*Nparcnt:0,rc,
		dbh,NULL,
		qh,f,
		tf ? "tail=%s" : "",
		tf ? tf : "");
    tf = d4o_free(tf);
    f = d4o_free(f);
  }
  if (Errcode) *Errcode = rc; // (rc == SQLITE_OK) ? rc : qh;
  return qh;
}

int d4o_destroy(int qh, int enforce) // i.e. a kind of "un-prepare"
{
  int rc = SQLITE_OK;
  Query_t *pQ = this_Q(qh);
  int dbh = d4o_get_dbh(qh);
  if (pQ) {
    double wt = fprof ? d4o_wtime() : 0;
    if (enforce && pQ->stmt) {
      rc = sqlite3_finalize(pQ->stmt);
      pQ->stmt = NULL;
    }
    
    // TBD : *must* have locks around !!! beware recursion alloc_lock that is
    pQ->inuse = 0;
    
    if (fprof) {
      char *query = fprof ? pQ->sql : NULL;
      d4o_profile(__FUNCTION__,d4o_wtime()-wt,
		  0,0,0,rc,
		  dbh,NULL,
		  qh,query,
		  NULL);
    }
  }
  return rc;
}

int d4o_bind_double(int qh, int parnum, double value)
{
  int rc = SQLITE_ERROR;
  Query_t *pQ = this_Q(qh);
  if (pQ) {
    int count = pQ->nparcnt;
    if (parnum >= 1 && parnum <= count) {
      if (d4o_is_null(value)) { // the value is a NULL (incl. being NaN or Inf)
	rc = sqlite3_bind_null(pQ->stmt, parnum);
      }
      else if (fmod(value,1) == 0.0) { // the value is an integer
	long long int ival = value;
	rc = sqlite3_bind_int64(pQ->stmt, parnum, ival);
      }
      else {
	rc = sqlite3_bind_double(pQ->stmt, parnum, value);
      }
    }
  }
  return rc;
}

int d4o_bind_int8(int qh, int parnum, long long int value)
{
  int rc = SQLITE_ERROR;
  Query_t *pQ = this_Q(qh);
  if (pQ) {
    int count = pQ->nparcnt;
    if (parnum >= 1 && parnum <= count) {
      if (d4o_is_null(value)) { // the value is a NULL                                                                                                                                                                                   
        rc = sqlite3_bind_null(pQ->stmt, parnum);
      }
      else {
	rc = sqlite3_bind_int64(pQ->stmt, parnum, value);
      }
    }
  }
  return rc;
}

int d4o_bind_text(int qh, int parnum, const char *s)
{
  int rc = SQLITE_ERROR;
  Query_t *pQ = this_Q(qh);
  if (pQ) {
    int count = pQ->nparcnt;
    if (parnum >= 1 && parnum <= count) {
      if (s) {
	rc = sqlite3_bind_text(pQ->stmt, parnum, s, strlen(s), SQLITE_TRANSIENT);
      }
      else { // NULL value
	rc = sqlite3_bind_null(pQ->stmt, parnum);
      }
    }
  }
  return rc;
}

int d4o_bind_null(int qh, int parnum)
{
  int rc = SQLITE_ERROR;
  Query_t *pQ = this_Q(qh);
  if (pQ) {
    int count = pQ->nparcnt;
    if (parnum >= 1 && parnum <= count) {
      rc = sqlite3_bind_null(pQ->stmt, parnum);
    }
  }
  return rc;
}

const char *d4o_get_typename(int coltype)
{
  const char *typename;
  switch (coltype) {
  case SQLITE_INTEGER:
    typename = COLTYPE_INT;
    break;
  case SQLITE_FLOAT:
    typename = COLTYPE_REAL;
    break;
  default:
    typename = COLTYPE_TEXT;
    break;
  }
  return typename;
}

int d4o_get_coltype(const char *typename, const char *opt_colname)
{
  int coltype = SQLITE_TEXT;
  if (typename) {
    if (strcasecmp(typename,COLTYPE_INT) == 0 ||
	strcasestr(typename,"int")) coltype = SQLITE_INTEGER;
    else if (strcasecmp(typename,COLTYPE_REAL) == 0 ||
	     strcasestr(typename,"char")) coltype = SQLITE_FLOAT;
  }
  else if (opt_colname) { // TBD
    if (strcasecmp(opt_colname,"count(*)") == 0) coltype = SQLITE_INTEGER;
    //else if (strncasecmp(opt_colname,"sum(",4) == 0) coltype = SQLITE_FLOAT;
    // etc.
  }
  return coltype;
}

int d4o_getdb(int qh, double **Dout, int ncols, int *Nrows,
	      char *colnames[ncols], int types[ncols], char **sql)
{
  double wt = fprof ? d4o_wtime() : 0;
  int rc = SQLITE_ERROR;
  Query_t *pQ = this_Q(qh);
  DB_t *pDB = this_DB(qh);
  int dbh = d4o_get_dbh(qh);
  int nrows = 0;
  size_t nalloc = 0;
  double *d = NULL;
  if (pDB && pQ && Dout && Nrows && ncols > 0) {
    int j;
    size_t offset = 0;
    const int incmult = 2;
    nalloc = 1 * ncols * incmult;
    d = (double *)d4o_alloc(nalloc, sizeof(*d), 0);
    if (sql) *sql = d4o_get_query(qh,1);

    if (colnames) {
      for (j=0; j<ncols; ++j) colnames[j] = d4o_strdup(pQ->colname[j]);
    }
    if (types) {
      for (j=0; j<ncols; ++j) types[j] = pQ->coltype[j];
    }

    while ((rc = sqlite3_step(pQ->stmt)) == SQLITE_ROW) {
      int nmore = ncols;
      if (nalloc < ++nrows * nmore) {
	if (nalloc > 0) {
	  nalloc *= incmult;
	  d = (double *)realloc(d, nalloc * sizeof(*d));
	}
      }
      for (j=0; j<ncols; ++j) {
	double *dd = &d[offset + j];
	int runtime_coltype = sqlite3_column_type(pQ->stmt,j);
	switch(runtime_coltype) {
	case SQLITE_INTEGER:
	  {
	    long long int ires = sqlite3_column_int64(pQ->stmt,j);
	    *dd = ires;
	  }
	  break;
	case SQLITE_FLOAT:
	  {
	    double fres = sqlite3_column_double(pQ->stmt,j);
	    *dd = fres;
	  }
	  break;
	case SQLITE_TEXT:
	  {
	    const char *c = (const char *)sqlite3_column_text(pQ->stmt,j);
	    char *tmpc = d4o_strdup(c ? c : "");
	    *dd = d4o_set_text(tmpc); // empty strings ok (and not NULL)
	    tmpc = d4o_free(tmpc);
	  }
	  break;
	default:
	  *dd = d4o_get_null(); // Missing Data Indicator
	  break;
	}
      }
      offset += nmore;
    } // while ((rc = sqlite3_step(pQ->stmt)) == SQLITE_ROW)
    
    if (rc != SQLITE_DONE) { // Serious issue => abort
      rc = d4o_check_error(1,NULL,
			   rc,SQLITE_DONE,
			   dbh,NULL,
			   qh,sql ? *sql : NULL,
			   __FUNCTION__,__FILE__,__LINE__,
			   "%s: sqlite3_step(pQ->stmt) = %d : ncols = %d, nrows = %d, offset=%ld, d=%p",
			   sql ? *sql : undef,rc,ncols,nrows,(long)offset,d);
      goto errlabel;
    }
    
    *Nrows = nrows;
    pQ->nrows += nrows;
    *Dout = d; // always allocated at least one row
    rc = sqlite3_reset(pQ->stmt);
  }
 errlabel:
  if (fprof) d4o_profile(__FUNCTION__,d4o_wtime()-wt,
			 nrows,ncols,0,rc,
			 dbh,NULL,
			 qh,(sql && *sql) ? *sql : NULL,
			 "d=%p;nalloc=%ld",
			 d,(long)nalloc);
  return rc;
}

int d4o_putdb(int qh, const double *d, int ncols, int nrows,
	      const int types[ncols], int nparcnt, const int Parnum[nparcnt])
{
  double dwt1 = 0;
  double dwt2 = 0;
  double wt = fprof ? d4o_wtime() : 0;
  int rc = SQLITE_ERROR;
  int rollback = 0;
  int nretries = 0;
  Query_t *pQ = this_Q(qh);
  DB_t *pDB = this_DB(qh);
  int dbh = d4o_get_dbh(qh);
  char *sql = d4o_get_query(qh,0);
  int affected_rows = sqlite3_total_changes(pDB->h); // TBD: NOT thread safe !!!
  int actual_parcnt = d4o_get_nparcnt(qh);
  const int *parnum = Parnum;
  if (!parnum) nparcnt = 0;
  if (nparcnt <= 0) { nparcnt = 0; parnum = NULL; }
  if (pDB && pQ && pQ->stmt && d && types && ncols > 0 && nrows > 0) {
    int got_timeout = 0;
    const char *er;

    if (debug_mode >= 1) {
      char *dt = d4o_datetime(NULL);
      fprintf(stderr,"[%d] %s: %s: %s\n",myrank,dt,__FUNCTION__,sql);
    }

  retry:
    affected_rows = sqlite3_total_changes(pDB->h); // most up to date value
    got_timeout = 0;
    er = end_transaction;
    
    if (fprof) dwt1 = d4o_wtime();
    rc = d4o_exec(dbh,begin_deferred_transaction);
    if (fprof) dwt1 = d4o_wtime()-dwt1;
    
    if (rc != SQLITE_OK) { // Report error & return rc as is
      rc = d4o_check_error(0,NULL,
			   rc,SQLITE_OK,
			   dbh,pDB->name,
			   qh,sql,
			   __FUNCTION__,__FILE__,__LINE__,
			   "%s: %s => rc = %d",sql,begin_deferred_transaction,rc);
      goto errlabel;
    }

    { // Bulk updates i.e. one row at a time, e.g. :
      //
      // Suppose we have parameters ?1,?2, ?3 and ?4 i.e. nparcnt = 4
      // And we have the following UPDATE-stmt, where we update columns (a,b,c) in the "table" as follows
      //
      // UPDATE table SET a = ?1, b = ?2 + ?4, c = NULL WHERE d > ?3
      //
      // We are feeding data from "d", that has columns 1..ncols -- let ncols be 20
      // We want to substitute ?1 from column 1 data "d", ?2 from 12, ?3 from 7 and ?7 from 19
      // We then must have initialized parnum[nparcnt] as follows (all in Fortran indexing, one-offset, not zero-offset):
      //
      // ?1 aka PARNUM(1) =  1 = parnum[0]
      // ?2 aka PARNUM(2) = 12 = parnum[1]
      // ?3 aka PARNUM(3) =  7 = parnum[2]
      // ?4 aka PARNUM(4) = 19 = parnum[3]
      //
      // Similarly we could perform record insertion to table
      // Please note that nparcnt is still 5 (not 2) and yet only ?3 and ?5 are being used
      // Thus nparcnt is the max index i.e. ?<nparcnt>
      // These are fetched from "d" columns 13 and 15, respectively (assuming the same ncols = 20 as before):
      //
      // INSERT INTO table (g,f) VALUES (?3,?5)
      //
      // We should set the unused to 0 (< 1)
      //
      // ?1 aka PARNUM(1) =  0 ! Unused entry
      // ?2 aka PARNUM(2) =  0 ! Unused entry
      // ?3 aka PARNUM(3) = 13
      // ?4 aka PARNUM(4) =  0 ! Unused entry
      // ?5 aka PARNUM(5) = 15
      //
      
      size_t offset = 0;
      int *pack = NULL;
      int i,j,k,kk,kmax = 0;
      int changes_executed = 0;
      
      if (nparcnt > 0) {
	pack = d4o_alloc(nparcnt,sizeof(*pack),1); // alloc & make inactive (=0) by default
	for (k=0; k<nparcnt; ++k) { // for ?<k+1>
	  j = parnum[k] - 1; // C-indexing
	  if (j >= 0 && j < ncols) pack[kmax++] = k;
	}
      }
      else {
	nparcnt = MIN(ncols,actual_parcnt); // could be zero
	pack = d4o_alloc(ncols,sizeof(*pack),0); // just alloc
	for (j=0; j<nparcnt; ++j) { // for ?<k+1>
	  pack[kmax++] = j; // column by column
	}
      }

      if (debug_mode >= 3) {
	fprintf(stderr,"kmax=%d : %s\n",kmax,sql);
	for (kk=0; kk<kmax; ++kk) {
	  fprintf(stderr,"\tkk=%d : ?%d\n",kk,pack[kk]+1);
	}
      }
      
      for (i=0; i<nrows; ++i) {
	
	for (kk=0; kk<kmax; ++kk) {
	  k = pack[kk]; // for ?<k+1>
	  j = parnum ? parnum[k] - 1 : k;
	  {
	    double dd = d[offset+j];
	    //int suggested_coltype = d4o_is_null(dd) ? SQLITE_NULL : types[j];
	    int suggested_coltype = types[j];
	    if (suggested_coltype == SQLITE_INTEGER || suggested_coltype == SQLITE_FLOAT) {
	      if (d4o_is_null(dd)) suggested_coltype = SQLITE_NULL;
	    }
	  again:
	    switch (suggested_coltype) {
	    case SQLITE_INTEGER:
	      {
		long long int ires = dd;
		(void) d4o_bind_int8(qh,k+1,ires);
	      }
	      break;
	    case SQLITE_FLOAT:
	      {
		double fres = dd;
		(void) d4o_bind_double(qh,k+1,fres);
	      }
	      break;
	    case SQLITE_TEXT:
	      {
		double fres = dd;
		int coltype = suggested_coltype;
		const char *s = d4o_get_text(&fres,&coltype);
		if (coltype == SQLITE_TEXT) {
		  (void) d4o_bind_text(qh,k+1,s);
		}
		else {
		  suggested_coltype = coltype;
		  goto again;
		}
	      }
	      break;
	    case SQLITE_NULL:
	    default: // NULL i.e. missing data indicator
	      (void) d4o_bind_null(qh,k+1);
	      break;
	    } // switch (coltype)
	  }
	} // for (kk=0; kk<kmax; ++kk)

	if (debug_mode >= 3) {
	  char *xsql = d4o_get_query(qh,1);
	  fprintf(stderr,"row#%d (offset=%ld) : %s\n",i+1,offset,xsql);
	  xsql = d4o_free(xsql);
	}
	  
	rc = sqlite3_step(pQ->stmt);

	if (rc != SQLITE_DONE) { // Serious issue => trigger rollback & return
	  char *xsql = d4o_get_query(qh,1);
	  (void) d4o_check_error(0,NULL,
				 rc,SQLITE_DONE,
				 dbh,NULL,
				 qh,xsql,
				 __FUNCTION__,__FILE__,__LINE__,
				 "%s: sqlite3_step(pQ->stmt) = %d at row#%d\n\t"
				 "=> recovering & rolling back from %s(pQ->stmt=%p,d=%p,ncols=%d,nrows=%d,...)",
				 xsql,rc,i+1,__FUNCTION__,pQ->stmt,d,ncols,nrows);
	  got_timeout = (rc == SQLITE_BUSY || rc == SQLITE_LOCKED) ? 1 : 0;
	  rollback = got_timeout ? 0 : rc;
	  er = rollback_transaction;
	  xsql = d4o_free(xsql);
	  //(void) sqlite3_reset(pQ->stmt);
	  break;
	}

	//if (kmax > 0 || i == nrows - 1) (void) sqlite3_reset(pQ->stmt);
	(void) sqlite3_reset(pQ->stmt); // a must, otherwise ?#'s not updated

	++changes_executed;
	if (actual_parcnt == 0 && changes_executed == 1) break; // nothing more to (be allowed to) do when no params (?#) present
	
	offset += ncols;
      } // for (i=0; i<nrows; ++i)

      affected_rows = sqlite3_total_changes(pDB->h) - affected_rows; // TBD: NOT thread safe !!!
	
      (void) sqlite3_reset(pQ->stmt);
      
      pack = d4o_free(pack);

      if (fprof) dwt2 = d4o_wtime();
      rc = d4o_exec(dbh,er);
      if (fprof) dwt2 = d4o_wtime()-dwt2;
      
      if (rc != SQLITE_OK) { // Report error & return
	rc = d4o_check_error(0,NULL,
			     rc,SQLITE_OK,
			     dbh,pDB->name,
			     qh,sql,
			     __FUNCTION__,__FILE__,__LINE__,
			     "%s: %s => rc = %d",sql,er,rc);
	goto errlabel;
      }
    } // Bulk updates
    if (got_timeout && ++nretries <= maxretries) {
      goto retry; // redo the whole lot 
    }
  }
 errlabel:
  if (fprof) d4o_profile(__FUNCTION__,d4o_wtime()-wt-dwt1-dwt2,
			 nrows,ncols,nparcnt,rc,
			 dbh,NULL,
			 qh,sql ? sql : NULL,
			 "d=%p;rollback=%d;affected_rows=%d;nretries=%d/%d;timeout=%dms",
			 d,rollback,affected_rows,nretries,maxretries,busy_timeout_ms);
  sql = d4o_free(sql);
  return (rollback > 0) ? -rollback : affected_rows;
}

int d4o_query_fprintf(FILE *fp, int dbh, const char *query, int separator)
{
  int nout = 0;
  DB_t *pDB = this_DB(dbh);
  if (fp && pDB && query) {
    char *tail = d4o_strdup(query);
    while (tail) {
      char *saved_tail = tail;
      int ncols = 0;
      int nparcnt = 0;
      int rc;
      int qh = d4o_prepare(dbh,tail,&ncols,&nparcnt,&tail,&rc);
      if (qh >= 0 && ncols > 0 && rc == SQLITE_OK) nout += d4o_fprintf(fp,qh,separator);
      if (qh >= 0) (void) d4o_destroy(qh,1);
      saved_tail = d4o_free(saved_tail);
    }
  }
  return nout;
}

int d4o_fprintf(FILE *fp, int qh, int separator)
{
  int nout = 0;
  if (fp && qh) {
    Query_t *pQ = this_Q(qh);
    int ncols = pQ ? pQ->ncols : 0; // d4o_get_ncols(qh);
    if (ncols > 0) {
      int nrows = 0;
      char *colnames[ncols];
      int types[ncols];
      char *sql = NULL;
      double *d = NULL;
      int rc = d4o_getdb(qh,&d,ncols,&nrows,colnames,types,&sql);
      if (rc == SQLITE_OK) {
	nout = d4o_array_fprintf(fp, d, ncols, nrows, colnames, types, sql, separator);
      }
      d = d4o_free(d);
      sql = d4o_free(sql);
    }
  }
  return nout;
}

int d4o_colidx(int qh, const char *key)
{
  int value = d4o_get_null();
  if (key) {
    Query_t *pQ = this_Q(qh);
    int j, ncols = pQ ? pQ->ncols : 0; // d4o_get_ncols(qh); 
    if (ncols > 0 && pQ && pQ->stmt && pQ->colname) {
      int has_dot = strchr(key,'.') ? 1 : 0;
      for (j=0; j<ncols; ++j) {
	const char *col = pQ->colname[j];
	if (has_dot) { // fully qualified name e.g. "table.column_name"
	  if (strcasecmp(col,key) == 0) return j;
	}
	else { // track "column_name" after "table." i.e. after the "."
	  const char *p = strcasestr(col,key);
	  if (p) {
	    const char *pdot = strchr(col,'.');
	    if (pdot && strcasecmp(pdot+1,key) == 0) return j;
	    if (strcasecmp(col,key) == 0) return j; // last resort
	  }
	}
      }
    }
  }
  return value;
}

int d4o_array_fprintf(FILE *fp, const double *d, int ncols, int nrows,
		      char *colnames[ncols], const int types[ncols], const char *sql, int separator)
{
  int nout = 0;
  if (fp && d && ncols > 0 && nrows > 0 && colnames && types) {
    size_t offset;
    char sep = (!separator) ? ' ' : (char)separator;
    char hash;
    int rowlen = 8;
    int defwidth = 0; // (sep == ' ') ? default_width : 0;
    int i,j;
    int fmtlen[ncols];
    
    for (j=0; j<ncols; ++j) fmtlen[j] = defwidth;

    if (sep == ' ') {
      for (j=0; j<ncols; ++j) {
	int len = strlen(colnames[j]);
	if (fmtlen[j] < len) fmtlen[j] = len;
      }
      for (j=0; j<ncols; ++j) {
	int len = strlen(d4o_get_typename(types[j]));
	if (fmtlen[j] < len) fmtlen[j] = len;
      }
      offset = 0;
      for (i=0; i<nrows; ++i) {
	for (j=0; j<ncols; ++j) {
	  double dd = d[offset + j];
	  int len = d4o_get_textlen(dd);
	  if (fmtlen[j] < len) fmtlen[j] = len;
	} // for (j=0; j<ncols; ++j)
	offset += ncols;
      } // for (i=0; i<nrows; ++i)
    }

    hash = '#';
    if (sql) fprintf(fp,"\n%c %s\n",hash,sql);

    fprintf(fp,"\n");
    hash = '#';
    if (sep == ' ') fprintf(fp,"%*s",rowlen,""), hash = sep;
    for (j=0; j<ncols; ++j) {
      fprintf(fp,"%c%*s",hash,fmtlen[j],d4o_get_typename(types[j]));
      hash = sep;
    }

    fprintf(fp,"\n");
    hash = '#';
    if (sep == ' ') fprintf(fp,"%*s",rowlen,""), hash = sep;
    for (j=0; j<ncols; ++j) {
      fprintf(fp,"%c%*s",hash,fmtlen[j],colnames[j]);
      hash = sep;
    }

    if (sep == ' ') {
      fprintf(fp,"\n");
      hash = '#';
      if (sep == ' ') fprintf(fp,"%*s",rowlen,""), hash = sep;
      for (j=0; j<ncols; ++j) {
	fprintf(fp,"%c[%*.*d]",hash,fmtlen[j]-2,fmtlen[j]-2,j+1);
	hash = sep;
      }
    }

    offset = 0;
    for (i=0; i<nrows; ++i) {
      hash = '\n';
      if (sep == ' ') fprintf(fp,"%c[%*.*d]",hash,rowlen-2,rowlen-2,i+1), hash = sep;
      for (j=0; j<ncols; ++j) {
	double dd = d[offset + j];
	int suggested_coltype = types[j];
	if (suggested_coltype == SQLITE_INTEGER || suggested_coltype == SQLITE_FLOAT) {
	  if (d4o_is_null(dd)) suggested_coltype = SQLITE_NULL;
	}
      again:
	if (suggested_coltype == SQLITE_INTEGER) {
	  fprintf(fp,"%c%*lld",hash,fmtlen[j],(long long int)dd);
	}
	else if (suggested_coltype == SQLITE_FLOAT) {
	  fprintf(fp,"%c%*g",hash,fmtlen[j],dd);
	}
	else if (suggested_coltype == SQLITE_TEXT) {
	  int coltype = suggested_coltype;
	  const char *s = d4o_get_text(&dd,&coltype);
	  if (coltype == SQLITE_TEXT) {
	    fprintf(fp,"%c%*s",hash,fmtlen[j],s);
	  }
	  else {
	    suggested_coltype = coltype;
	    goto again;
	  }
	}
	else {
	  fprintf(fp,"%c%*s",hash,fmtlen[j],null);
	}
	hash = sep;
      }
      offset += ncols;
      ++nout;
    }
    fprintf(fp,"\n");
    fflush(fp);
  }
  return nout;
}

extern void fd4o_exit_(const char *s, const int *errcode, const int *do_exit, const int slen);

void d4o_ErrExit(const char *func, const char *msg, int rc)
{
  int do_exit = 1;
  int len = strlen(func) +strlen(msg) + 10;
  char s[len];
  snprintf(s,sizeof(s),"%s: %s",func,msg);
  rc = -ABS(rc);
  fd4o_exit_(s,&rc,&do_exit,strlen(s));
}

void d4o_TraceBack(FILE *fp, const char *at)
{
  if (!fp) {
    int rc = 0;
    int do_exit = 0;
    fd4o_exit_(at ? at : "",&rc,&do_exit,at ? strlen(at) : 0);
  }
  else {
#define BT_BUF_SIZE 256
    void *buffer[BT_BUF_SIZE];
    int nptrs = backtrace(buffer, BT_BUF_SIZE);
    if (!fp) fp = stderr;
    char *dt = d4o_datetime(NULL);
    fprintf(fp,"[%d] %s: %s : backtrace() returned %d addresses\n",myrank,dt,at?at:undef,nptrs);
    fflush(fp);
    backtrace_symbols_fd(buffer,nptrs,fileno(fp));
  }
}

#if 0
// TBD : https://github.com/ErwanLegrand/libbacktrace
void backtrace(void)
{
    int r;
    unw_cursor_t cursor; unw_context_t uc; 
    unw_word_t ip, sp; 
    char symname[100];

    unw_getcontext(&uc);
    unw_init_local(&cursor, &uc);
    while (unw_step(&cursor) > 0) {
        r = unw_get_reg(&cursor, UNW_REG_IP, &ip);
        assert(r == 0);
        r = unw_get_reg(&cursor, UNW_REG_SP, &sp);
        assert(r == 0);
        r = unw_get_proc_name(&cursor, symname, sizeof(symname), NULL);
        assert(r == 0);
        fprintf(stderr, "%s: ip: %lx, sp: %lx\n", symname, (long) ip, (long) sp);
    }   
}
#endif

static int Compare(const void *lhs, const void *rhs, size_t len, int kind)
{
  int rc;
  if (kind == KIND_CHAR) {
    rc = (len > 0) ? strncmp(lhs,rhs,len) : strcmp(lhs,rhs);
  }
  else { // KIND_PTR
    alias_t a,b;
    a.ptr = (void *)lhs;
    b.ptr = (void *)rhs;
    rc = (a.lli < b.lli) ? -1 : (a.lli > b.lli) ? +1 : 0;
  }
  return rc;
}

static Node_t *InsertBinTree(Node_t **tree, const void *val, int kind)
{
  int found = 0;
  Node_t *temp = NULL;
  if (!(*tree)) {
    temp = (Node_t *)d4o_alloc(1,sizeof(Node_t),0);
    temp->left = temp->right = NULL;
    temp->str = (kind == KIND_CHAR) ? d4o_strdup(val) : (char *)val;
    temp->len = (kind == KIND_CHAR) ? strlen(temp->str) : 0;
    temp->refcount = 0;
    temp->kind = kind;
    *tree = temp;
    found = 1;
  }
  else {
    size_t len = (kind == KIND_CHAR && val) ? strlen(val) : 0;
    int cmp = Compare(val,(*tree)->str,len,kind);
    if (cmp < 0) {
      temp = InsertBinTree(&(*tree)->left, val, kind);
    }
    else if (cmp > 0) {
      temp = InsertBinTree(&(*tree)->right, val, kind);
    }
    else { // cmp == 0
      temp = *tree;
      found = 1;
    }
  }
  if (temp && found) ++temp->refcount;
  return temp;
}

static Node_t *SearchBinTree(Node_t **tree, const void *val, int kind)
{
  Node_t *temp = NULL;
  if (tree && *tree) {
    size_t len = (kind == KIND_CHAR && val) ? strlen(val) : 0;
    int cmp = Compare(val,(*tree)->str,len,kind);
    if (cmp < 0) {
      temp = SearchBinTree(&(*tree)->left, val, kind);
    }
    else if (cmp > 0) {
      temp = SearchBinTree(&(*tree)->right, val, kind);
    }
    else { // cmp == 0  
      temp = *tree;
    }
  }
  return temp;
}

static void PrintThis(FILE *fp, const char *where, const Node_t *tree)
{
  if (fp && where && tree) {
    char *dt = d4o_datetime(NULL);
    if (tree->kind == KIND_CHAR) {
      fprintf(fp,"[%d] %s: %s(tree[KIND_PTR]=%p) : KIND_CHAR='%s' (len=%ld) : refcount=%ld\n",
	      myrank,dt,where,tree,
	      tree->str ? (char *)tree->str : "",
	      (long)tree->len,(long)tree->refcount);
    }
    else {
      dblNode_t alias;
      alias.p = tree->str;
#if 1
      fprintf(fp,"[%d] %s: %s(tree=%p) : KIND_PTR=%p (%.16g) : refcount=%ld\n",
	      myrank,dt,where,tree,tree->str,alias.d,(long)tree->refcount); // less volatile ?
#else
      fprintf(fp,"[%d] %s: %s(tree=%p) : KIND_PTR=%p (%.16g) (=> KIND_CHAR='%s') : refcount=%ld\n",
	      myrank,dt,where,tree,tree->str,alias.d,(char *)alias.p->str,(long)tree->refcount); // volatile
#endif
    }
  }
}

static Node_t *DeleteBinTree(Node_t *tree)
{
  if (tree) {
    int kind;
    tree->left = DeleteBinTree(tree->left);
    tree->right = DeleteBinTree(tree->right);
#if 0
    PrintThis(stderr,__FUNCTION__,tree);
#endif
    kind = tree->kind;
    tree->kind = KIND_NONE;
    tree->refcount = 0;
    tree->len = 0;
    tree->str = (kind == KIND_CHAR && tree->str) ? d4o_free(tree->str) : NULL;
    tree = d4o_free(tree);
  }
  return tree;
}

static void PrintBinTree(FILE *fp, const Node_t *tree)
{
  if (fp && tree) {
    PrintThis(fp,__FUNCTION__,tree);
    PrintBinTree(fp,tree->left);
    PrintBinTree(fp,tree->right);
  }
}

// The C-layer to interface with Fortran

// NB: *retcode
//     >= 0 : all ok (or number of rows returned)
//     < 0  : usually SQLITE error code (which themselves are positive)

int c_d4o_coreid_()
{
  return d4o_coreid();
}

int c_d4o_maxdb_()
{
  return d4o_maxdb();
}

int c_d4o_opendb_(const char *dbname, const char *mode
		, long dbname_len
		, long mode_len
		)
{
  int dbh;
  char *p_dbname = dbname ? d4o_alloc(dbname_len+1,sizeof(*p_dbname),0) : NULL;
  char *p_mode = mode ? d4o_alloc(mode_len+1,sizeof(*p_mode),0) : NULL;
  if (dbname) {
    memcpy(p_dbname,dbname,dbname_len*sizeof(*p_dbname));
    p_dbname[dbname_len] = 0;
  }
  if (mode) {
    memcpy(p_mode,mode,mode_len*sizeof(*p_mode));
    p_mode[mode_len] = 0;
  }
  dbh = d4o_opendb(p_dbname,p_mode);
  p_dbname = d4o_free(p_dbname);
  p_mode = d4o_free(p_mode);
  return dbh;
}

int c_d4o_closedb_(int *dbh)
{
  int rc = d4o_closedb(Valid_Handle(dbh));
  return -rc;
}

int c_d4o_execfile_(int *dbh, const char *filename
		    , long filename_len
		    )
{
  int rc;
  char *p_filename = filename ? d4o_alloc(filename_len+1,sizeof(*p_filename),0) : NULL;
  if (filename) {
    memcpy(p_filename,filename,filename_len*sizeof(*p_filename));
    p_filename[filename_len] = 0;
  }
  rc = d4o_execfile(Valid_Handle(dbh),p_filename);
  p_filename = d4o_free(p_filename);
  return -rc;
}
  
int c_d4o_exec_(int *dbh, const char *query
		 , long query_len
		)
{
  int rc;
  char *p_query = query ? d4o_alloc(query_len+1,sizeof(*p_query),0) : NULL;
  if (query) {
    memcpy(p_query,query,query_len*sizeof(*p_query));
    p_query[query_len] = 0;
  }
  rc = d4o_exec(Valid_Handle(dbh),p_query);
  p_query = d4o_free(p_query);
  return -rc;
}

int c_d4o_prepare_(int *dbh, const char *query,
		   int *ncols, int *nparcnt
		   , long query_len
		   )
{
  int rc, qh;
  char *p_query = query ? d4o_alloc(query_len+1,sizeof(*p_query),0) : NULL;
  if (query) {
    memcpy(p_query,query,query_len*sizeof(*p_query));
    p_query[query_len] = 0;
  }
  qh = d4o_prepare(Valid_Handle(dbh), p_query, ncols, nparcnt, NULL, &rc); // TBD: tail ignored for now
  p_query = d4o_free(p_query);
  return (rc == SQLITE_OK) ? qh : -ABS(rc);
}

int c_d4o_destroy_(int *qh, const int *Enforce)
{
  int rc;
  int enforce = Enforce ? *Enforce : 0;
  rc = d4o_destroy(Valid_Handle(qh),enforce);
  return -rc;
}

long long int c_d4o_getdb_(int *qh,
			   const int *ncols, int *nrows,
			   long long int *colnames_ptr , int clen[],
			   int types[],
			   long long int *sql_ptr, int *sql_len)
{
  int rc;
  alias_t ta;
  double *d = NULL;
  int Ncols = *ncols;
  int Nrows = 0;
  char *Colnames[Ncols];
  char *sql = NULL;
  // int d4o_getdb(int qh, double **d, int ncols, int *nrows, char *colnames[ncols], int types[ncols], char **sql);
  if (colnames_ptr) *colnames_ptr = 0;
  if (sql_ptr) *sql_ptr = 0;
  if (sql_len) *sql_len = 0;
  rc = d4o_getdb(Valid_Handle(qh), &d, Ncols, &Nrows, Colnames, types, &sql);
  if (rc == 0 && colnames_ptr && clen) {
    alias_t ca;
    char *c;
    size_t len = 1;
    int j;
    for (j=0; j<Ncols; ++j) {
      clen[j] = strlen(Colnames[j]);
      len += clen[j];
    }
    c = d4o_alloc(len,sizeof(*c),0);
    *c = 0;
    for (j=0; j<Ncols; ++j) strcat(c,Colnames[j]);
    ca.ptr = c;
    *colnames_ptr = ca.lli;
    for (j=0; j<Ncols; ++j) {
      Colnames[j] = d4o_free(Colnames[j]);
    }
  }
  if (rc == 0 && sql && sql_ptr && sql_len) {
    alias_t qa;
    qa.ptr = d4o_strdup(sql);
    *sql_len = strlen(sql);
    *sql_ptr = qa.lli;
  }
  sql = d4o_free(sql);
  if (rc != 0 && d) d = d4o_free(d);
  ta.ptr = d;
  if (nrows) *nrows = (rc >= 0) ? Nrows : -rc;
  return ta.lli;
}

void c_d4o_ptr2array_(const long long int *ptr,
		      const int *ncols, const int *nrows,
		      const int *elemsize, void *d)
{
  alias_t ta;
  ta.lli = ptr ? *ptr : 0;
  if (ta.ptr && d && ncols && *ncols > 0 && nrows && *nrows > 0 && elemsize && *elemsize > 0) {
    size_t dsize = (*ncols) * (*nrows);
    memcpy(d,ta.ptr,dsize * (*elemsize));
  }
}

void c_d4o_ptr2str_(const long long int *ptr,
		    char *s
		    , const long s_len
		    )
{
  alias_t ta;
  ta.lli = ptr ? *ptr : 0;
  if (ta.ptr && s && s_len > 0) memcpy(s,ta.ptr,s_len * sizeof(*s));
}

void c_d4o_dealloc_(long long int *ptr)
{
  alias_t ta;
  ta.lli = ptr ? *ptr : 0;
  ta.ptr = d4o_free(ta.ptr);
}

int c_d4o_putdb_(int *qh,
		 const double *d, const int *ncols, const int *nrows,
		 const int types[], const int *nparcnt, const int parnum[])
{
  int rc;
  int Ncols = ncols ? *ncols : 0;
  int Nrows = nrows ? *nrows : 0;
  int Nparcnt = nparcnt ? *nparcnt : 0;
  // int d4o_putdb(int qh, const double *d, int ncols, int nrows, const int types[ncols], int nparcnt, const int parnum[nparcnt]);
  rc = d4o_putdb(Valid_Handle(qh), d, Ncols, Nrows, types, Nparcnt, (Nparcnt > 0) ? parnum : NULL);
  return rc;
}

long long int c_d4o_get_dbname_(int *dbh, int *len)
{
  alias_t db;
  db.ptr = d4o_get_dbname(Valid_Handle(dbh));
  if (len) *len = db.ptr ? strlen(db.ptr) : 0;
  return db.lli;
}

long long int c_d4o_get_query_(int *qh, const int *Expanded, int *len)
{
  int expanded = Expanded ? *Expanded : 0;
  alias_t qa;
  qa.ptr = d4o_get_query(Valid_Handle(qh),expanded);
  if (len) *len = qa.ptr ? strlen(qa.ptr) : 0;
  return qa.lli;
}

int c_d4o_get_dbh_(int *qh)
{
  return d4o_get_dbh(Valid_Handle(qh)); 
}

long long int c_d4o_get_typename_(const int *coltype, int *len)
{
  const char *s = d4o_get_typename(coltype ? *coltype : SQLITE_NULL);
  alias_t ta;
  ta.ptr = d4o_strdup(s);
  if (len) *len = ta.ptr ? strlen(ta.ptr) : 0;
  return ta.lli;
}

long long int c_d4o_get_errmsg_(const int *retcode, int *len)
{
  int rc = retcode ? ABS(*retcode) : 0;
  char *s = d4o_get_errmsg(rc);
  alias_t ta;
  ta.ptr = d4o_strdup(s);
  if (len) *len = ta.ptr ? strlen(ta.ptr) : 0;
  s = d4o_free(s);
  return ta.lli;
}

long long int c_d4o_get_text_(const double *d, int *len)
{
  int coltype = SQLITE_TEXT;
  const char *s = d4o_get_text(d,&coltype);
  alias_t ta;
  if (coltype == SQLITE_TEXT) {
    ta.ptr = d4o_strdup(s);
  }
  else if (d) {
    char flpnum[80];
    char *pflpnum = flpnum;
    double tmp = *d;
    if (d4o_is_null(tmp)) {
      strcpy(flpnum,null); // "NULL"
    }
    else if ((long long int)tmp == tmp) {
      (void) snprintf(flpnum,sizeof(flpnum),"%lld",(long long int)tmp);
    }
    else {
      (void) snprintf(flpnum,sizeof(flpnum),"%*g",default_width,tmp);
      while (*pflpnum == ' ') ++pflpnum; // removes leading blanks
    }
    ta.ptr = d4o_strdup(pflpnum);
  }
  else
    ta.ptr = 0;
  if (len) *len = ta.ptr ? strlen(ta.ptr) : 0;
  return ta.lli;
}

int c_d4o_get_textlen_(const double *d)
{
  return d4o_get_textlen(*d);
}

double c_d4o_set_text_(const char *s
		       , long s_len)
{
  double d;
  if (s) {
    char c[s_len+1];
    memcpy(c,s,s_len*sizeof(*c));
    c[s_len] = 0;
    d = d4o_set_text(c);
  }
  else {
    d = d4o_set_text(null);
  }
  return d;
}

void c_d4o_tsc_(const int *Csv, const int *Ncols,
		const int width[], const int types[],
		const double d[],
		char *cout, int *Len_cout
		, const long cout_len
		)
{
  int csv = Csv ? *Csv : 0;
  int j, ncols = Ncols ? *Ncols : 0;
  int lenout = 0;
  int maxw = 0;
  for (j=0; j<ncols; ++j) maxw = MAX(maxw,width[j]);
  if (ncols > 0 && width && types && d && cout && cout_len > (maxw+2)*ncols) {
    char c[maxw+3];
    *cout = 0;
    if (!csv) strcat(cout," ");
    for (j=0; j<ncols; ++j) {
      double dd = d[j];
      const char *s;
      int nc, coltype, suggested_coltype = types[j], w = width[j];
      if (suggested_coltype == SQLITE_INTEGER || suggested_coltype == SQLITE_FLOAT) {
	if (d4o_is_null(dd)) suggested_coltype = SQLITE_NULL;
      }
    again:
      switch (suggested_coltype) {
      case SQLITE_INTEGER:
	nc = csv ? snprintf(c,sizeof(c),"%lld",(long long int)dd) : snprintf(c,sizeof(c)," %*lld",w,(long long int)dd);
	break;
      case SQLITE_FLOAT:
	nc = csv ? snprintf(c,sizeof(c),"%g",dd) : snprintf(c,sizeof(c)," %*g",w,dd);
	break;
      case SQLITE_TEXT:
	coltype = suggested_coltype;
	s = d4o_get_text(&dd,&coltype);
	if (coltype == SQLITE_TEXT) {
	  nc = csv ? snprintf(c,sizeof(c),"\"%s\"",s) : snprintf(c,sizeof(c)," %*s",w,s);
	}
	else {
	  suggested_coltype = coltype;
	  goto again;
	}
	break;
      default:
	nc = csv ? snprintf(c,sizeof(c),"%s",null) : snprintf(c,sizeof(c)," %*s",w,null);
	break;
      }
      if (csv && j > 0) strcat(cout,",");
      strncat(cout,c,nc); // checks TBD
    }
    lenout = strlen(cout);
    // TBD : abort if lenout > cout_len
  }
  if (Len_cout) *Len_cout = lenout;
}

int c_d4o_get_coltype_(const char *typename
		       , const long typename_len
		       )
{
  int rc;
  char *p_typename = typename ? d4o_alloc(typename_len+1,sizeof(*p_typename),0) : NULL;
  if (typename) {
    memcpy(p_typename,typename,typename_len*sizeof(*p_typename));
    p_typename[typename_len] = 0;
  }
  rc = d4o_get_coltype(p_typename,NULL);
  p_typename = d4o_free(p_typename);
  return rc;
}

int c_d4o_get_debug_() { return d4o_get_debug(); }

int c_d4o_set_debug_(const int *newvalue)
{
  int oldvalue = newvalue ? d4o_set_debug(*newvalue) : d4o_get_debug();
  return oldvalue;
}

double c_d4o_get_null_() { return d4o_get_null(); }

double c_d4o_set_null_(const double *newvalue)
{
  double oldvalue = d4o_get_null();
  if (newvalue) oldvalue = d4o_set_null(*newvalue);
  return oldvalue;
}

int c_d4o_is_null_(const double *value)
{
  return (value && d4o_is_null(*value)) ? 1 : 0;
}

int c_d4o_cascade_(int *dbh, const int *onoff)
{
  int rc = SQLITE_OK;
  if (onoff) rc = d4o_cascade(Valid_Handle(dbh),*onoff);
  return (rc == SQLITE_OK) ? rc : -rc;
}

int c_d4o_long_column_names_(int *dbh, const int *onoff)
{
  int rc = SQLITE_OK;
  if (onoff) rc = d4o_long_column_names(Valid_Handle(dbh),*onoff);
  return (rc == SQLITE_OK) ? rc : -rc;
}

int c_d4o_get_nparcnt_(int *qh)
{
  return d4o_get_nparcnt(Valid_Handle(qh));
}

int c_d4o_get_ncols_(int *qh)
{
  return d4o_get_ncols(Valid_Handle(qh));
}

int c_d4o_bind_double_(int *qh, const int *parnum, const double *value)
{
  return -d4o_bind_double(qh ? *qh : -1, parnum ? *parnum : 0, value ? *value : 0);
}

int c_d4o_bind_int8_(int *qh, const int *parnum, const long long int *value)
{
  return -d4o_bind_int8(qh ? *qh : -1, parnum ? *parnum : 0, value ? *value : 0);
}

int c_d4o_bind_text_(int *qh, const int *parnum, const char *value
		     , const long value_len
		     )
{
  int rc;
  char *p_value = value ? d4o_alloc(value_len+1,sizeof(*p_value),0) : NULL;
  if (value) {
    memcpy(p_value,value,value_len*sizeof(*p_value));
    p_value[value_len] = 0;
  }
  rc = d4o_bind_text(qh ? *qh : -1, parnum ? *parnum : 0, p_value);
  p_value = d4o_free(p_value);
  return -rc;
}

int c_d4o_bind_null_(int *qh, const int *parnum)
{
  return d4o_bind_null(qh ? *qh : -1, parnum ? *parnum : 0);
}

int c_d4o_colidx_(const int *qh, const char *key
		  , const long key_len
		  )
{
  int rc;
  char *p_key = key ? d4o_alloc(key_len+1,sizeof(*p_key),0) : NULL;
  if (key) {
    memcpy(p_key,key,key_len*sizeof(*p_key));
    p_key[key_len] = 0;
  }
  rc = d4o_colidx(qh ? *qh : -1, p_key);
  p_key = d4o_free(p_key);
  return rc;
}

int d4o_mpirank(const int *fix)
{
  if (myrank < 0) {
    char *env_mpirank = getenv("d4o_mpi_rank");
    if (!env_mpirank) env_mpirank = getenv("PMI_FORK_RANK"); // Cray MPICH when invoked with PMI_NO_FORK=1
    if (!env_mpirank) env_mpirank = getenv("ALPS_APP_PE"); // Cray ALPS
    if (!env_mpirank) env_mpirank = getenv("PMIX_RANK"); // OpenMPI when using srun and SLURM_MPI_TYPE=pmix
    if (!env_mpirank) env_mpirank = getenv("PMI_RANK"); // MPICH (except Cray MPICH) -- also SLURM "srun" regardless of MPI
    if (!env_mpirank) env_mpirank = getenv("OMPI_COMM_WORLD_RANK"); // OpenMPI
    myrank = env_mpirank ? atoi(env_mpirank) : 0;
    if (myrank < 0) myrank = 0;
  }
  if (fix && *fix >= 0) myrank = *fix;
  return myrank;
}
int c_d4o_mpirank_(const int *fix) { return d4o_mpirank(fix); }

int d4o_mpisize(const int *fix)
{
  if (numranks < 0) {
    char *env_mpisize = getenv("d4o_mpi_size");
    if (!env_mpisize) env_mpisize = getenv("PMIX_SIZE"); // OpenMPI when using srun and SLURM_MPI_TYPE=pmix -- does not exist !!!
    if (!env_mpisize) env_mpisize = getenv("PMI_SIZE"); // MPICH (except Cray MPICH) -- also SLURM "srun" regardless of MPI
    if (!env_mpisize) env_mpisize = getenv("OMPI_COMM_WORLD_SIZE"); // OpenMPI
    if (!env_mpisize) env_mpisize = getenv("SLURM_NPROCS"); // If SLURM (--ntasks=value or -n value)
    numranks = env_mpisize ? atoi(env_mpisize) : 1;
    if (numranks < 1) numranks = 1;
  }
  if (fix && *fix >= 1) numranks = *fix;
  return numranks;
}
int c_d4o_mpisize_(const int *fix) { return d4o_mpisize(fix); }


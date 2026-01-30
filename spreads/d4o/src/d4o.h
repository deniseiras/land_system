// d4o.h

#include <stdio.h>
#include <stdlib.h>

typedef unsigned int  Uint32;
typedef unsigned long long int  Uint64;
typedef unsigned char Uchar;

// Backbone of the d4o-access

extern void d4o_finalize();

extern void d4o_TraceBack(FILE *fp, const char *at);
extern void d4o_ErrExit(const char *func, const char *msg, int rc);

extern int d4o_coreid();
extern int d4o_maxdb();
extern double d4o_timestamp();
extern double d4o_wtime();
extern char *d4o_datetime(const double *Epoch);
extern void d4o_profile(const char *func, double delta,
			int nrows, int ncols, int nparcnt, int rc,
			int dbh, const char *dbname,
			int qh, const char *query,
			const char *fmt, ...);

extern int d4o_check_error(int do_abort, FILE *fp,
			   int rc, int expected,
			   int dbh, const char *DBname,
			   int qh, const char *Sql,
			   const char *func, const char *filename, int lineno,
			   const char *fmt, ...);

extern int d4o_opendb(const char *dbname, const char *mode);
extern int d4o_closedb(int dbh);

extern int d4o_cascade(int dbh, int onoff);
extern int d4o_long_column_names(int dbh, int onoff);

extern int d4o_get_debug();
extern int d4o_set_debug(int newvalue);

extern double d4o_get_null();
extern double d4o_set_null(double newvalue);
extern int d4o_is_null(double value);

extern int d4o_exec(int dbh, const char *query);
extern int d4o_execfile(int dbh, const char *sqlfile);

extern int d4o_prepare(int dbh, const char *query, int *ncols, int *nparcnt, char **tail, int *errcode);
extern int d4o_destroy(int qh, int enforce);

extern int d4o_get_ncols(int qh);
extern int d4o_get_nparcnt(int qh);

extern const char *d4o_get_typename(int coltype);
extern int d4o_get_coltype(const char *typename, const char *opt_colname);

extern int d4o_getdb(int qh, double **d, int ncols, int *nrows, char *colnames[ncols], int types[ncols], char **sql);
extern int d4o_putdb(int qh, const double *d, int ncols, int nrows, const int types[ncols], int nparcnt, const int parnum[nparcnt]);

extern char *d4o_get_query(int qh, int expanded);
extern int d4o_get_dbh(int qh);
extern char *d4o_get_dbname(int dbh);

extern int d4o_bind_double(int qh, int parnum, double value);
extern int d4o_bind_int8(int qh, int parnum, long long int value);
extern int d4o_bind_text(int qh, int parnum, const char *s);
extern int d4o_bind_null(int qh, int parnum);

extern double d4o_set_text(const char *s);
extern const void *d4o_get_text(const double *d, int *detected_coltype);
extern int d4o_get_textlen(double d);

extern char *d4o_get_errmsg(int rc);

extern void *d4o_free(void *x);
extern char *d4o_strdup(const char *s);
extern void *d4o_alloc(size_t nmemb, size_t size, int initzero);

extern int d4o_fprintf(FILE *fp, int qh, int separator);
extern int d4o_query_fprintf(FILE *fp, int dbh, const char *query, int separator);
extern int d4o_array_fprintf(FILE *fp, const double *d, int ncols, int nrows,
			     char *colnames[ncols], const int types[ncols],
			     const char *sql, int separator);

extern int d4o_colidx(int qh, const char *key);
extern int d4o_mpirank(const int *fix);
extern int d4o_mpisize(const int *fix);

extern int d4o_is_little_endian(); // endian.c
extern int d4o_is_big_endian();    // endian.c

// The C-layer to interface with Fortran

extern int c_d4o_is_big_endian_();     // endian.c
extern int c_d4o_is_little_endian_();  // endian.c

extern int c_d4o_coreid_();

extern int c_d4o_maxdb_();

extern int c_d4o_opendb_(const char *dbname, const char *mode
		       , long dbname_len
		       , long mode_len
		       );

extern int c_d4o_closedb_(int *dbh);

extern int c_d4o_cascade_(int *dbh, const int *onoff);
extern int c_d4o_long_column_names_(int *dbh, const int *onoff);

extern int c_d4o_exec_(int *dbh, const char *query
		       , long query_len
		       );

extern int c_d4o_execfile_(int *dbh, const char *filename
			   , long filename_len
			   );

extern int c_d4o_prepare_(int *dbh, const char *query,
			  int *ncols, int *nparcnt
			  , long query_len
			  );

extern int c_d4o_destroy_(int *qh, const int *enforce);

extern long long int c_d4o_getdb_(int *qh,
				  const int *ncols, int *nrows,
				  long long int *colnames_ptr, int clen[],
				  int types[],
				  long long int *sql_ptr, int *sql_len);

extern void c_d4o_ptr2array_(const long long int *ptr,
			     const int *ncols, const int *nrows,
			     const int	*elemsize, void *d);

extern void c_d4o_ptr2str_(const long long int *ptr,
			   char *s
			   , const long s_len
			   );

extern void c_d4o_dealloc_(long long int *ptr);

extern int c_d4o_putdb_(int *qh,
			const double *d, const int *ncols, const int *nrows,
			const int types[], const int *nparcnt, const int parnum[]);

extern long long int c_d4o_get_dbname_(int *dbh, int *len);

extern long long int c_d4o_get_query_(int *qh, const int *Expanded, int *len);

extern int c_d4o_get_dbh_(int *qh);

extern long long int c_d4o_get_errmsg_(const int *retcode, int *len);

extern long long int c_d4o_get_text_(const double *d, int *len);

extern double c_d4o_set_text_(const char *s
			      , long s_len);

extern void c_f4o_tsc_(const int *Csv, const int *Ncols,
		       const int width[], const int types[],
		       const double d[],
		       char *cout, int *Len_cout
		       , const long cout_len
		       );


extern int c_d4o_get_coltype_(const char *typename
			      , const long typename_len
			      );

extern int c_d4o_get_debug_();
extern int c_d4o_set_debug_(const int *newvalue);

extern double c_d4o_get_null_();
extern double c_d4o_set_null_(const double *newvalue);
extern int c_d4o_is_null_(const double *value);

extern int c_d4o_get_ncols_(int *qh);
extern int c_d4o_get_nparcnt_(int *qh);

extern int c_d4o_bind_double_(int *qh, const int *parnum, const double *value);
extern int c_d4o_bind_int8_(int *qh, const int *parnum, const long long int *value);
extern int c_d4o_bind_text_(int *qh, const int *parnum, const char *value
			    , const long value_len
			    );
extern int c_d4o_bind_null_(int *qh, const int *parnum);

extern int c_d4o_colidx_(const int *qh, const char *key
			 , const long key_len
			 );

extern int c_d4o_mpirank_(const int *fix);
extern int c_d4o_mpisize_(const int *fix);

// Straight Fortran calls -- will not be found in fd4o_mod (for now at least)

extern void // rsort32.c
fd4o_rsort32_(const    int *Mode,
	      const    int *N,
	      const    int *Inc,
	      const    int *Start_addr,
	      Uint32        Data[],
	      int           index[],
	      const    int *Index_adj,
	      int *retc);

extern void // rsort64.c
fd4o_rsort64_(const    int *Mode,       /* if < 10, then index[] needs to be initialized ; method = modulo 10 */
	      const    int *N,          /* no. of 64-bit elements */
	      const    int *Inc,        /* stride in terms of 64-bit elements */
	      const    int *Start_addr, /* Fortran start address i.e. normally == 1 */
	      Uint64        Data[],     /* 64-bit elements to be sorted */
	      int           index[],    /* sorting index */
	      const    int *Index_adj,  /* 0=index[] is a C-index, 1=index[] is a Fortran-index (the usual case) */
	      int *retc);

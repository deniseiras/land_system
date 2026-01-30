/* meta.h */

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

typedef struct _Metadata_t
{
  int kategory;
  int rc;
  char blfile[PATH_MAX];
  int blfile_lineno;
  char cfile[PATH_MAX];
  int cfile_lineno;
  int reason;
  char *reason_name;
  double seriousness;
  char *fdbk_vars;
} Metadata_t;

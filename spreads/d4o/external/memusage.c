#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <math.h>

int memusage(double *VmSize, double *VmRSS, double *Shared, double *Private)
{
  /*
      /proc/[pid]/statm
              Provides information about memory usage, measured in pages.  The columns are:

                  size       (1) total program size
                             (same as VmSize in /proc/[pid]/status)
                  resident   (2) resident set size
                             (inaccurate; same as VmRSS in /proc/[pid]/status)
                  shared     (3) number of resident shared pages
                             (i.e., backed by a file)
                             (inaccurate; same as RssFile+RssShmem in
                             /proc/[pid]/status)
                  text       (4) text (code)
                  lib        (5) library (unused since Linux 2.6; always 0)
                  data       (6) data + stack
                  dt         (7) dirty pages (unused since Linux 2.6; always 0)
  */

  int rc = -1;
  if (VmSize && VmRSS && Shared && Private) {
    static double page_size_kb = 0;
    if (page_size_kb == 0) page_size_kb = sysconf(_SC_PAGE_SIZE) / 1024;
    *VmSize = 0;
    *VmRSS = 0;
    *Shared = 0;
    *Private = 0;
    {
      int size = 0, resident = 0, shared = 0;
      FILE *fp = fopen("/proc/self/statm","r");
      if (fp) {
	int n = fscanf(fp,"%d %d %d",&size,&resident,&shared);
	if (n == 3) {
	  *VmSize = size * page_size_kb * 1024;
	  *VmRSS = resident * page_size_kb * 1024;
	  *Shared = shared * page_size_kb * 1024;
	  *Private = *VmRSS - *Shared;
	  rc = 0;
	}
	fclose(fp);
      }
    }
  }
  return rc;
}

int main()
{
  double VmSize, VmRSS, Shared, Private;
  double VmSizePrev, VmRSSPrev, SharedPrev, PrivatePrev;
  long pid = getpid();
  char cmd[200];
  int rc, cnt = 7, maxcnt = 11;
  unsigned int nap = 20;
  
  //snprintf(cmd,sizeof(cmd),"cat /proc/%ld/status | egrep -i '(vm|rss|shmem|huge)'",pid);
  //system(cmd);
  
  snprintf(cmd,sizeof(cmd),"perl -ne 'if (m{^(\\S+):\\s+(\\d+)\\s+kB}) {printf(\"%%s=%%d \",$1,$2*1024)}' /proc/%ld/status; echo",pid);

  rc = memusage(&VmSize, &VmRSS, &Shared, &Private);
  printf("##### begin: VmSize=%.0f VmRSS=%.0f Shared=%.0f Private=%.0f\n",VmSize,VmRSS,Shared,Private);
  system(cmd);
  //printf("\n");

  while (cnt++ < maxcnt) {
    size_t size = pow(10,cnt);
    size_t nbytes = sizeof(char)*size;
    char *c = NULL;
    double VmSizeInc, VmRSSInc, SharedInc, PrivateInc;
    
    VmSizePrev = VmSize;
    VmRSSPrev = VmRSS;
    SharedPrev = Shared;
    PrivatePrev = Private;
    
    c = malloc(nbytes);
    if (!c) {
      printf("\nUnable to allocate %ld bytes\n",nbytes);
      exit(1);
    }
    rc = memusage(&VmSize, &VmRSS, &Shared, &Private);
    VmSizeInc = VmSize - VmSizePrev;
    VmRSSInc = VmRSS - VmRSSPrev;
    SharedInc = Shared - SharedPrev;
    PrivateInc = Private - PrivatePrev;
    printf("\n##### %d: after malloc of %ld bytes : VmSize=%.0f (%0.f) VmRSS=%.0f (%.0f) Shared=%.0f (%.0f) Private=%.0f (%.0f)\n",
	   cnt,nbytes,
	   VmSize,VmSizeInc,
	   VmRSS,VmRSSInc,
	   Shared,SharedInc,
	   Private,PrivateInc);
    system(cmd);

    VmSizePrev = VmSize;
    VmRSSPrev = VmRSS;
    SharedPrev = Shared;
    PrivatePrev = Private;
    
    memset(c,0,nbytes);
    rc = memusage(&VmSize, &VmRSS, &Shared, &Private);
    VmSizeInc = VmSize - VmSizePrev;
    VmRSSInc = VmRSS - VmRSSPrev;
    SharedInc = Shared - SharedPrev;
    PrivateInc = Private - PrivatePrev;
    
    printf("##### %d: after memset of %ld bytes : VmSize=%.0f (%0.f) VmRSS=%.0f (%.0f) Shared=%.0f (%.0f) Private=%.0f (%.0f)\n",
	   cnt,nbytes,
	   VmSize,VmSizeInc,
	   VmRSS,VmRSSInc,
	   Shared,SharedInc,
	   Private,PrivateInc);
    system(cmd);
    
    sleep(nap);
    free(c);
  }
  
  rc = memusage(&VmSize, &VmRSS, &Shared, &Private);
  printf("\n##### end: VmSize=%.0f VmRSS=%.0f Shared=%.0f Private=%.0f\n",VmSize,VmRSS,Shared,Private);
  system(cmd);
}


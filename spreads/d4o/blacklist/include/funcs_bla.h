
/* Built-in, single- and multiargument functions 
   This is meant to be shared memory thread-safe always */

#include <math.h>
#include <stdlib.h>

extern void numarg_error(int numargs, int low, int high, char *function_name);

#if defined(NO_TRUNC) || defined(VPP) || defined(NECSX)
/* For systems without trunc() -function [an extension of ANSI-C, but usually available] */
#define trunc(x) ((x) - fmod((x),1))
#else
extern double trunc(double d);
#endif


#define BL_PI180 0.01745329251994

#define BL_BIG_INT 2147483647
#ifndef BLMAGIC
#define BLMAGIC 2147483647 
#endif

#ifndef BL_VAR_ARGS
#define BL_VAR_ARGS
#endif

int BL_number(char *s)
{
  int rc = -1;

  while ( *s && *s == ' ' ) s++;

  if (*s > '0' && *s <= '9') {
    char *p = s;
    do {
      if( *s < '0' || *s > '9') return rc;
      s++;
    } while ( *s );
    rc = atoi(p);
  }
  return rc;
}

double BL_exp(int numargs, const double *arg BL_VAR_ARGS) { return exp(arg[0]); }

double BL_log(int numargs, const double *arg BL_VAR_ARGS) { return log(arg[0]); }

double BL_log10(int numargs, const double *arg BL_VAR_ARGS) { return log10(arg[0]); }

double BL_sqrt(int numargs, const double *arg BL_VAR_ARGS) { return sqrt(arg[0]); }

double BL_mod(int numargs, const double *arg BL_VAR_ARGS) 
{ return ((int) arg[0]) % ((int) arg[1]); }

double BL_xor(int numargs, const double *arg BL_VAR_ARGS) 
{ return ((int) arg[0]) ^ ((int) arg[1]); }

double BL_max(int numargs, const double *arg BL_VAR_ARGS)
{
  int i;
  double tmp, max = -BL_BIG_INT;
  numarg_error(numargs,1,BLMAGIC,"max");
  for (i=0; i<numargs; i++) {
    tmp = arg[i];
    if (tmp > max) max = tmp;
  }
  return max;
}

double BL_min(int numargs, const double *arg BL_VAR_ARGS)
{
  int i;
  double tmp, min = BL_BIG_INT;
  numarg_error(numargs,1,BLMAGIC,"min");
  for (i=0; i<numargs; i++) {
    tmp = arg[i];
    if (tmp < min) min = tmp;
  }
  return min;
}

double BL_sum(int numargs, const double *arg BL_VAR_ARGS)
{
  int i;
  double sum = 0;
  numarg_error(numargs,1,BLMAGIC,"sum");
  for (i=0; i<numargs; i++) {
    sum += arg[i];
  }
  return sum;
}

double BL_prod(int numargs, const double *arg BL_VAR_ARGS)
{
  int i;
  int minus_signs = 0;
  double prod, sum = 0;
  double tmp;

  numarg_error(numargs,1,BLMAGIC,"prod");
  for (i=0; i<numargs; i++) {
    tmp = arg[i];
    if (tmp == 0) 
      return 0; /* .. since the product would be zero anyway */
    else if (tmp < 0) {
      tmp = -tmp;
      minus_signs++;
    }
    sum += log(tmp);
  }
  prod = exp(sum);
  return (minus_signs % 2 == 0) ? prod : -prod;
}


double BL_abs(int numargs, const double *arg BL_VAR_ARGS) 
/* int abs() replaced by double fabs() !!
   on 14-Jan-1999 by Sami Saarinen on the top of CY19R2;
   Thanks to Tony McNally who regrettably had to suffer from this stupid bug */
{ return fabs(arg[0]); }

double BL_sin(int numargs, const double *arg BL_VAR_ARGS) 
{ return sin(BL_PI180*arg[0]); }
double BL_asin(int numargs, const double *arg BL_VAR_ARGS) 
{ return asin(arg[0])/BL_PI180; }
double BL_sinh(int numargs, const double *arg BL_VAR_ARGS) { return sinh(arg[0]); }

double BL_cos(int numargs, const double *arg BL_VAR_ARGS) 
{ return cos(BL_PI180*arg[0]); }
double BL_acos(int numargs, const double *arg BL_VAR_ARGS) 
{ return acos(arg[0])/BL_PI180; }
double BL_cosh(int numargs, const double *arg BL_VAR_ARGS) { return cosh(arg[0]); }

double BL_tan(int numargs, const double *arg BL_VAR_ARGS) 
{ return tan(BL_PI180*arg[0]); }
double BL_atan(int numargs, const double *arg BL_VAR_ARGS) 
{ 
  double retval = 0;
  switch (numargs) {
  case 1:
    retval = atan(arg[0])/BL_PI180; 
    break;
  case 2:
    retval = atan2(arg[0], arg[1])/BL_PI180;
    break;
  default:
    numarg_error(numargs,1,2,"atan");
  }
  return retval;
}
double BL_tanh(int numargs, const double *arg BL_VAR_ARGS) { return tanh(arg[0]); }

double BL_int(int numargs, const double *arg BL_VAR_ARGS) { return ((int) arg[0]); }
double BL_round(int numargs, const double *arg BL_VAR_ARGS) 
{ return arg[0] > 0 ? ((int) (arg[0] + 0.5)) : ((int) (arg[0] - 0.5)); }
double BL_ceil(int numargs, const double *arg BL_VAR_ARGS) { return ceil(arg[0]); }
double BL_floor(int numargs, const double *arg BL_VAR_ARGS) { return floor(arg[0]); }

/* Random number generators */

double BL_srand(int numargs, const double *arg BL_VAR_ARGS)
{ srand(arg[0]); return arg[0]; }

double BL_rand(int numargs, const double *arg BL_VAR_ARGS)
{ return rand(); }

/* Special for the observation handling */

double BL_rad(int numargs, const double *arg BL_VAR_ARGS) 
{ 
  double reflat = BL_PI180*arg[0]; 
  double reflon = BL_PI180*arg[1];
  double refdeg = BL_PI180*arg[2];
  double obslat = BL_PI180*arg[3];
  double obslon = BL_PI180*arg[4];
  double obsdeg = 
    acos( cos(reflat) * cos(obslat) * cos(obslon-reflon) + sin(reflat) * sin(obslat) );

  return (obsdeg <= refdeg); 
}

double BL_dist(int numargs, const double *arg BL_VAR_ARGS) 
{ 
  const double R_Earth_km = 6371e0;
  double reflat = BL_PI180*arg[0]; 
  double reflon = BL_PI180*arg[1];
  double refdist_km = arg[2];
  double obslat = BL_PI180*arg[3];
  double obslon = BL_PI180*arg[4];
  double obsdeg = 
    acos( cos(reflat) * cos(obslat) * cos(obslon-reflon) + sin(reflat) * sin(obslat) );

  return ((R_Earth_km * obsdeg) <= refdist_km); 
}

double BL_basetime(int numargs, const double *arg BL_VAR_ARGS)
{ /* Merge "YYYYMMDD" and "HHMMSS" into "YYYYMMDDHH" */
  double outstamp = -BLMAGIC; /* Missing data indicator : here indicates error */
  double indate = arg[0];
  double intime = arg[1];
  if (indate >= 0 && indate <= BLMAGIC &&
      intime >= 0 && intime <= 240000) {
    long long int lldate = (long long int)indate;
    long long int lltime = (long long int)intime;
    long long int tstamp = lldate * 1000000ll + (lltime/10000ll);
    outstamp = tstamp;
    outstamp = trunc(outstamp);
  }
  return outstamp;
}


/* CPU-timer */

/* Portable CPU-timer (User + Sys) */

#include <unistd.h>
#include <sys/types.h>
#include <sys/times.h>
#include <sys/param.h>

#ifdef CRAY
#include <time.h>
#endif

double CPUtime()
{
  static struct tms tbuf;
  extern clock_t times (struct tms *buffer);
  static double clock_ticks = 0;

  if (clock_ticks == 0) clock_ticks = sysconf(_SC_CLK_TCK);

  (void) times(&tbuf);

  return (tbuf.tms_utime + tbuf.tms_stime +
	  tbuf.tms_cutime + tbuf.tms_cstime) / clock_ticks; 
}

double BL_cputime(int numargs, const double *arg BL_VAR_ARGS)
{
  return CPUtime();
}


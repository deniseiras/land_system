
/* subs.c */


#define APPEND(varno) { strcat(s,var_search((varno))); strcat(s,", "); count++; }
#define CLEANUP       { char *p = strrchr(s,','); if (p) *p = '\0'; }
#define AARINEN       200

PRIVATE void test_obstyp(int obstyp, int recno)
{
  if (obstyp < 1 || obstyp > MAX_OBSTYP) {
    fprintf(stderr,
	    "*** Error: Invalid observation type '%d' in record#%d\n",
	      obstyp, recno);
    exit(1);
  }
}


PRIVATE void write_variab(FILE *output,
			  int obstyp,
			  int level0[], int levelN[],
			  char *prefix)
{
  char s[AARINEN];
  int count = 0;

  s[0] = '\0';

  switch (obstyp) {

  case synop:
    if (level0[0] == 3) { APPEND(1); APPEND(110); }
    if (level0[1] == 3)   APPEND(41);
    if (level0[2] == 3)   APPEND(42);
    /* 30-Apr-96: if (count == 4) count = 0; */ /* No variable-list needed */
    break;

  case airep:
    /* if (level0[0] == 3)   APPEND(110); */
    if (level0[1] == 3)   APPEND(3);
    if (level0[2] == 3)   APPEND(4);
    if (level0[3] == 3)   APPEND(2);
    /* if (level0[4] == 3)   APPEND(1); */
    if (count == 3) count = 0; /* 30-Apr-96: Alright *//* No variable-list needed */
    break;

  case satob:
    /* if (level0[0] == 3)   APPEND(11);
    if (level0[1] == 3 ||
	levelN[4] == 3 ||
	levelN[5] == 3)   APPEND(200); */

    if (levelN[1] == 3)   APPEND(3);
    if (levelN[2] == 3)   APPEND(4);
    /* if (levelN[3] == 3)   APPEND(112); */
    if (count == 2) count = 0; /* 30-Apr-96: Alright *//* No variable-list needed */
    break;

  case dribu:
    if (level0[0] == 3)   { APPEND(1); APPEND(110); }
    if (level0[1] == 3)     APPEND(3);
    if (level0[2] == 3)     APPEND(4);
    /* if (level0[3] == 3)   APPEND(39);
    if (level0[4] == 3)   APPEND(11); */
    /* 30-Apr-96: if (count == 4) count = 0; */ /* No variable-list needed */ 
    break;

  case temp:
    /* if (levelN[0] == 3)   APPEND(110); */
    if (levelN[1] == 3)   APPEND(3);
    if (levelN[2] == 3)   APPEND(4);
    /* if (levelN[3] == 3)   APPEND(2);
    if (levelN[4] == 3) { APPEND(7); APPEND(29); APPEND(59); } */
    if (levelN[5] == 3)   APPEND(1);
    /* 30-Apr-96: if (count == 3) count = 0; *//* No variable-list needed */
    break;

  case pilot:
    /* if (levelN[0] == 3)   APPEND(110); */
    if (levelN[1] == 3)   APPEND(3);
    if (levelN[2] == 3)   APPEND(4);
    if (levelN[3] == 3)   APPEND(1);
    if (count == 3) count = 0; /* 30-Apr-96: Alright *//* No variable-list needed */
    break;

  case satem:
    /* if (level0[0] == 3)   APPEND(11);
    if (level0[1] == 3 ||
	level0[2] == 3 ||
	level0[3] == 3 ||
	level0[4] == 3 ||
	levelN[1] == 3)   APPEND(200);

    if (levelN[0] == 3)   APPEND(110);
    if (levelN[2] == 3)   APPEND(2);
    if (levelN[3] == 3)   APPEND(9);
    if (levelN[4] == 3)   APPEND(57); */
    count = 0; /* 30-Apr-96: Alright *//* No variable-list needed */
    break;

  case paob:
  case scatt:
  /* case tovs: Removed on 29-Sep-96 */
  default:
    count = 0;
    break;
  }

  if (count > 0) {
    CLEANUP;
    if (count > 1) {
      fprintf(output,"   %s  VARIAB in ( %s )\n", prefix, s);
      if_done = 1;
    }
    else if (count == 1) {
      fprintf(output,"   %s (VARIAB = %s)\n", prefix, s);
      if_done = 1;
    }
  }
  else if (strstr(prefix,"if")) {
    fprintf(output,"   %s ",prefix);
    if_done = 0;
  }

}


PRIVATE void write_time(FILE *output, int time_present, int hours[])
{
  if (time_present) {
    char *p_and = (if_done) ? "and" : "";

    int t1 = hours[0];
    int t2 = hours[1];
    if (t1 < t2) {
      fprintf(output,"   %s ( %d0000 <= TIME <= %d0000 )\n", p_and, t1,t2);
      if_done = 1;
    }
    else if (t1 > t2)  /* PM --> AM */ {
      fprintf(output,"   %s ( TIME >= %d0000 or TIME <= %d0000 )\n", p_and, t1,t2);
      if_done = 1;
    }
    else if (t1 == t2) {
      fprintf(output,"   %s ( TIME = %d0000 )\n", p_and, t1);
      if_done = 1;
    }
  }
}


PRIVATE void write_area(FILE *output, int area_present, int lat[], int lon[])
{
  if (area_present) {
    if (lat[0] != lat[1] || lon[0] != lon[1]) {
      fprintf(output,"   ( ");
    }
    if (lat[0] != lat[1]) {
      char *p_or = (if_done) ? "or" : "";
      
      fprintf(output,"%s ( LAT < %d or LAT > %d )",
	      p_or,
	      lat[0], lat[1]);
      if_done = 1;
    }
    if (lon[0] != lon[1]) {
      char *p_or = (if_done) ? "or" : "";

      /* 
	 A bug fix on 26-Sep-1996: Thanks to Lars Isaksen who found it.
	 Please note that the INCLUSION area is
	 from lon[0] to lon[1], and that we have to express
	 this in terms of EXCLUSION area in the new blacklist.
	 The area of inclusion can also be wrapped around the
	 +-180 point, so we have to be careful 
      */

      if (lon[0] < lon[1]) {
	fprintf(output,"   %s ( LON < %d or LON > %d )",
		p_or,
		lon[0], lon[1]);
      }
      else {
	fprintf(output,"   %s ( %d < LON < %d )",
		p_or,
		lon[1], lon[0]);
      }
      if_done = 1;
    }
    if (lat[0] != lat[1] || lon[0] != lon[1]) {
      fprintf(output," )");
    }
    fprintf(output,"\n");
  }
}


PRIVATE void write_press(FILE *output, int levels_present, int press[])
{
  if (levels_present) {
    char *p_and = (if_done) ? "and" : "";

    if (press[0] != press[1])
      fprintf(output,"   %s ( %d >= PRESS >= %d )\n",
	      p_and,
	      press[0], press[1]);
    else
      fprintf(output,"   %s ( PRESS = %d )\n", 
	      p_and,
	      press[0]);
    if_done = 1;
  }
}




/* input.c */

#define COL(i) &line[(i)-1]
#define GETSTR(x,i,n) { strncpy((x),COL((i)),(n)); (x)[(n)] = '\0'; }
#define GETVAL(x,i,fmt) sscanf(COL((i)),(fmt),&(x));
#define GETARR(x,i,fmt,n) \
{ int j; for (j=0; j<(n); j++) \
    { int k = GETVAL((x)[j],(i+j),(fmt)); if (k<1) (x)[j] = 0; } }

int  obstyp;
char statid[8+1];
int  level0[8], sum_level0;
int  levelN[8], sum_levelN;
char tmpstr[4+1];
int  lat[2], lon[2], area_present;
int  press[2], levels_present;
int  hours[2], time_present;

void old_format(FILE *input, 
		FILE *output,
		FILE *exp_output,
		void (*write_func)(FILE *output, int recno,
				   char *statid, int obstyp,
				   int level0[], int sum_level0,
				   int levelN[], int sum_levelN,
				   int area_present, int lat[], int lon[],
				   int levels_present, int press[],
				   int time_present, int hours[]),
		void (*finish_func)(FILE *output))
{
#define MAXLINE 80
  static char line[MAXLINE];
  int recno = 0;

  for (;;) {
    char *s;
    int  i, ch;

    if ( (ch = fgetc(input)) == EOF) break;
    ungetc(ch,input);

    fgets(line,MAXLINE,input);   /* Reads a record which also includes the '\n' */
    recno++;

    s = strchr(line,'\n'); 
    if (s) *s='\0';

    i = strlen(line);
    memset(&line[i], ' ', MAXLINE-i);
    line[MAXLINE-1] = '\0';

    GETSTR(statid, 2,8);         /* Fields  2 -  9 : STATID */
    if (strcmp(statid,"        ") == 0) break;

    GETVAL(obstyp,11,"%2d");     /*   "    11 - 12 : OBSTYP */

    GETARR(level0,14,"%1d",8);   /*   "    14 - 21 : Level 0 flags */
    GETARR(levelN,23,"%1d",8);   /*   "    23 - 30 : Level N flags */
    sum_level0 = sum_levelN = 0;
    for (i=0; i<8; i++) {
      sum_level0 = sum_level0*10 + level0[i];
      sum_levelN = sum_levelN*10 + levelN[i];
    }

    GETSTR(tmpstr,33,4);         /*   "    33 - 36 : Lat (deg), southern bdry */
    area_present = (strcmp(tmpstr,"    ") != 0);
    if (area_present) {
      lat[0] = atoi(tmpstr);
      GETSTR(tmpstr,38,4);       /*   "    38 - 41 : Lat (deg), northern bdry */
      lat[1] = atoi(tmpstr);
      GETSTR(tmpstr,43,4);       /*   "    43 - 46 : Lon (deg), western bdry */
      lon[0] = atoi(tmpstr);
      GETSTR(tmpstr,48,4);       /*   "    48 - 51 : Lon (deg), eastern bdry */
      lon[1] = atoi(tmpstr);
    } else {
      lat[0] = lat[1] = lon[0] = lon[1] = 0;
    }

    GETSTR(tmpstr,54,4);         /*   "    54 - 57 : Begin vert. level range */
    levels_present = (strcmp(tmpstr,"    ") != 0);
    if (levels_present) {
      press[0] = atoi(tmpstr);
      GETSTR(tmpstr,59,4);       /*   "    59 - 62 : End vert. level range */
      press[1] = atoi(tmpstr);
    } else {
      press[0] = press[1] = 0;
    }

    GETSTR(tmpstr,65,2);         /*   "    65 - 66 : Begin time range */
    time_present = (strcmp(tmpstr,"  ") != 0);
    if (time_present) {
      hours[0] = atoi(tmpstr);
      GETSTR(tmpstr,68,2);       /*   "    68 - 69 : End time range */
      hours[1] = atoi(tmpstr);
    } else {
      hours[0] = hours[1] = 0;
    }

    if (exp_output) {
      expanded_output(exp_output,
		      statid, obstyp,
		      level0, levelN,
		      area_present, lat, lon,
		      levels_present, press,
		      time_present, hours);
    }

    if (output && write_func) {
      write_func(output, recno,
		 statid, obstyp,
		 level0, sum_level0,
		 levelN, sum_levelN,
		 area_present, lat, lon,
		 levels_present, press,
		 time_present, hours);
    }

  } /* for (;;) */

  if (output && finish_func) {
    finish_func(output);
  }
}


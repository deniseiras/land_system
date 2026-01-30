/* testgrid.c
**
**
*/

#include "tutils.h"
#include <stdio.h>
#include "mfhdf.h"
#include "HE2_config.h"
#include "HdfEosDef.h"

int main(int argc, char *argv[])
{
   int32 	index1 = 0;
   int32 	index2 = 0;
   /*int32 	rank = 2;*/
   /*int32 	dimsizes[2] = {100,40};*/
   int32	tiledims[2] = {15, 15};
   int32	tilecords[2];
   int32	tilerank, tilecode;
   /*int32	rowarr[2] = {10,11};*/
   /*int32	colarr[2] = {10,11};*/
   int32	rowval[5], colval[5];
   int32	regionID, regionID2;
   float32	utmhght[80];
   float32	hghtinit = 323.0;
   float64	range[2];
   float32 	utmray[60][80], ray3[25][80];
   /*float32	psray[360][90], gooderay[120][60],somray[359][321];*/
   float32	psray[360][90], gooderay[120][60],*somray;
   float32	lamazray[719][180], georay[60][80];
   /*float32	gooderay2[45][60], somray2[55][321];*/
   float32	gooderay2[45][60], *somray2;
   float32	lamazray2[65][180], georay2[85][80];
   float32	tileray[15][15];
   float32	tilebuffer[15][15];
   float32 	fillvalue = 1996.0;
   float32 	utmcnt = -799.0, ray3cnt = -19.5;
   float32	pscnt=-134.5, goodecnt=27.4, somcnt=-454.4;
   float32	lamazcnt=-299.5, geocnt=2001.0;
   float32	inqfill;
   float32	*buffer;

   int 		CLLoop, Verbosity;
   intn 	status, j, ii;
   intn		compparm[4];
   int32 	gdfid, gdfid2, GDid_utm, GDid2, i, zonecode;
   int32	attr[4] = {11,33,66,99}, attr2[5]={5,17,28,39,57};
   int32	gdfid3, GDid3, GDid_igoode;
   int32	gdid_polar_np, gdid_polar_sp;
   int32	GDid_geo, GDid_som, GDid_lamaz;
   int32	GDid_hom, GDid_lamcon, GDid_tm, GDid_poly, GDid_is;
   int32 	spherecode, xdim, ydim;
   int32 	start[2] = {10, 10};
   int32 	stride[2] = {1, 1};
   int32 	edge[2] = {10, 10};
   int32	tmpvar, tmpvar1, tmpvar2, tmpvar3, tmpvar4;
   int32	periodID;
   int32	compcode;
   int32	ray[8];
   int32	bufsiz;
   char		tmpstr[1024];
   char		*buffer1;
   char		*buffer2;

   int32	tempvar1[32], tempvar2[32], iattr[4];
   float64 	projparm[16], uplft[2], lowrgt[2], corlon[2], corlat[2];
   float64	iuplft[2], ilowrgt[2], iprojparm[16];
   float64	lonval[5], latval[5];
   float64	*datbuf;
   float64	utmtmeray[4800];
   float64	tmeinit = 35232487.2;
   float64	starttime,stoptime;
   float32	*datbuf2;

   FILE 	*fp;
   int32 	GDid_ease;
   /*float32	easeray[1383][586];*/
   float32	*easeray;
   float32	easecnt=2001.0;
   /*float32	easeray2[1383][586];*/
   float32	*easeray2;
   int32 	xdim_ease, ydim_ease;
   float64      rcord[4], scord[4];
   int32        npnts;
   int32        xdimsize,ydimsize;
   float64      longitude[4], latitude[4];

   Verbosity = 4;
   GDid2 = -1;

   for (CLLoop = 1; CLLoop < argc; CLLoop++)
   {
      if ((argc > CLLoop + 1) && ((HDstrcmp(argv[CLLoop], "-verbose") == 0) ||
                                 (HDstrcmp(argv[CLLoop], "-v") == 0)))
      {
         if (argv[CLLoop + 1][0] == 'l')
            Verbosity = 4;
         else if (argv[CLLoop + 1][0] == 'm')
            Verbosity = 6;
         else if (argv[CLLoop + 1][0] == 'h')
            Verbosity = 10;
         else
            Verbosity = atoi(argv[CLLoop + 1]);
      }  /* end if */
   }
/*
** This section of the program just fills some arrays with data that we will
** use later in the program
*/
   while(index1 < 60) {
      while(index2 < 80) {
         utmray[index1][index2] = utmcnt;
         georay[index1][index2] = geocnt;
         index2++;
         utmcnt = utmcnt + 0.4;
         geocnt = geocnt + 0.2;
      }
      index1++;
      index2 = 0;
   }

index1=0;
   while(index1 < 4800) {
      utmtmeray[index1] = tmeinit;
      index1++;
      tmeinit = tmeinit + 70.7;
      }

index1=0;
   while(index1 < 80) {
      utmhght[index1] = hghtinit;
      hghtinit = hghtinit + 2.75;
      index1++;
   }

index1=0;
index2=0;
   while(index1 < 85) {
      while(index2 < 80) {
         georay2[index1][index2] = geocnt;
         index2++;
         geocnt = geocnt - .9;
      }
      index1++;
      index2 = 0;
   }

index1=0;
index2=0;

   while(index1 < 25) {
      while(index2 < 80) {
         ray3[index1][index2] = ray3cnt;
         index2++;
         ray3cnt=ray3cnt + .1;
      }
      index1++;
      index2 = 0;
   }

index1=0;
index2=0;
   while(index1 < 360) {
      while(index2 < 90) {
         psray[index1][index2] = pscnt;
         index2++;
         pscnt = pscnt + .4;
      }
      index1++;
      index2 = 0;
   }

index1=0;
index2=0;
   while(index1 < 120) {
      while(index2 < 60) {
         gooderay[index1][index2] = goodecnt;
         index2++;
         goodecnt = goodecnt + .4;
      }
      index1++;
      index2 = 0;
   }
 
index1=0;
index2=0;
   while(index1 < 45) {
      while(index2 < 60) {
         gooderay2[index1][index2] = goodecnt;
         index2++;
         goodecnt = goodecnt - .4;
      }
      index1++;
      index2 = 0;
   }
 
/*index1=0;
index2=0;
   while(index1 < 359) {
      while(index2 < 321) {
         somray[index1][index2] = somcnt;
         index2++;
         somcnt = somcnt + .4;
      }
      index1++;
      index2 = 0;
   }

index1=0;
index2=0;
   while(index1 < 55) {
      while(index2 < 321) {
         somray2[index1][index2] = somcnt;
         index2++;
         somcnt = somcnt + .8;
      }
      index1++;
      index2 = 0;
      }*/

index1=0;
index2=0;
somray =  (float32 *) malloc(359 * 321 * sizeof(float32));
 for (index1=0; index1<359; index1++)
   { for (index2=0; index2<321; index2++)
       {
	 somray[index1+index2*359] = somcnt;
	 somcnt = somcnt + .4;
       }
   }

index1=0;
index2=0;
somray2 =  (float32 *) malloc(55 * 321 * sizeof(float32));
 for (index1=0; index1<55; index1++)
   { for (index2=0; index2<321; index2++)
       {
	 somray2[index1+index2*55] = somcnt;
	 somcnt = somcnt + .8;
       }
   }

index1=0;
index2=0;
   while(index1 < 719) {
      while(index2 < 180) {
         lamazray[index1][index2] = lamazcnt;
         index2++;
         lamazcnt = lamazcnt + .4;
      }
      index1++;
      index2 = 0;
   }

index1=0;
index2=0;
   while(index1 < 65) {
      while(index2 < 180) {
         lamazray2[index1][index2] = lamazcnt;
         index2++;
         lamazcnt = lamazcnt + .6;
      }
      index1++;
      index2 = 0;
   }


index1=0;
index2=0;
lamazcnt=1.0;
   while(index1 < 15) {
      while(index2 < 15) {
         tileray[index1][index2] = lamazcnt;
         index2++;
         lamazcnt = lamazcnt + .5;
      }
      index1++;
      index2 = 0;
   }

/*index1=0;
index2=0;
    xdim_ease =1383 ;
    ydim_ease = 586;

   while(index1 < xdim_ease) {
      while(index2 < ydim_ease) {
         easeray[index1][index2] = easecnt;
         index2++;
         easecnt = easecnt + 0.2;
      }
      index1++;
      index2 = 0;
   }

   index1=0;
   index2=0;

   while(index1 < xdim_ease) {
      while(index2 < ydim_ease) {
         easeray2[index1][index2] = easecnt;
         index2++;
         easecnt = easecnt - .9;
      }
      index1++;
      index2 = 0;
      }*/

index1=0;
index2=0;
xdim_ease =1383;
ydim_ease = 586;

   easeray =  (float32 *) malloc(1383 * 586 * sizeof(float32));

   for (index1=0; index1<xdim_ease; index1++)
     {
       for (index2=0; index2<ydim_ease; index2++)
	 {
	   easeray[index1+index2*xdim_ease] = easecnt;
	   easecnt = easecnt + 0.2;
	 }
     }

index1=0;
index2=0;
xdim_ease =1383;
ydim_ease = 586;
   easeray2 =  (float32 *) malloc(1383 * 586 * sizeof(float32));

   for (index1=0; index1<xdim_ease; index1++)
     {
       for (index2=0; index2<ydim_ease; index2++)
	 {
	   easeray2[index1+index2*xdim_ease] = easecnt;
	   easecnt = easecnt - 0.9;
	 }
     }

   MESSAGE(11,fp=fopen("testgridc.txtout", "w"););
  
/*
** Test Case -- GDopen
*/

   MESSAGE(4,printf("Testing Grid C interface \n"););
   MESSAGE(4,printf("=========================\n\n"););
   MESSAGE(11,fprintf(fp,"Testing Grid C interface \n"););
   MESSAGE(11,fprintf(fp,"=========================\n\n"););

   MESSAGE(4,printf("\tTesting GDopen... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDopen... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

#ifndef VISUAL_CPLUSPLUS
   system("rm Grid2.hdf");
#else
   system("del Grid2.hdf");
#endif

/*
** In this section of code we open a file in the read only mode
** this means that we cannot create or write anything into this file
** it will give a core dump or an error
*/
   MESSAGE(6,printf("\t\tCreating file with READ access\n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating file with READ access\n"););
   gdfid2 = GDopen("Grid2.hdf", DFACC_READ);
   if (gdfid2 == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
      MESSAGE(11,fprintf(fp,"\n"););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tgdfid2 = GDopen(\"Grid2.hdf\", DFACC_READ);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDopen %d\n\n", gdfid2););
      MESSAGE(11,fprintf(fp,"\t\tgdfid2 = GDopen(\"Grid2.hdf\", DFACC_READ);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDopen %d\n\n", gdfid2););
   }
#ifndef VISUAL_CPLUSPLUS
   system("rm Grid3.hdf");
#else
   system("del Grid3.hdf");
#endif

   MESSAGE(6,printf("\t\tTry creating file with RDWR access\n"););
   MESSAGE(11,fprintf(fp,"\t\tTry creating file with RDWR access\n"););
   gdfid3 = GDopen("Grid3.hdf", DFACC_RDWR);
   if (gdfid3 == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tgdfid3 = GDopen(\"Grid3.hdf\", DFACC_RDWR);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDopen %d\n\n", gdfid3););
      MESSAGE(11,fprintf(fp,"\t\tgdfid3 = Gdopen(\"Grid3.hdf\", DFACC_RDWR);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDopen %d\n\n", gdfid3););
   }

   MESSAGE(6,printf("\t\tOpening file Gridc_Test.hdf \n"););
   MESSAGE(11,fprintf(fp,"\t\tOpening file Gridc_Test.hdf \n"););
   gdfid = GDopen("Gridc_Test.hdf", DFACC_CREATE);
   if (gdfid == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tgdfid = GDopen(\"Gridc_Test.hdf\", DFACC_CREATE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDopen %d\n\n", gdfid););
      MESSAGE(11,fprintf(fp,"\t\tgdfid = GDopen(\"Gridc_Test.hdf\",DFACC_CREATE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle id returned from GDopen %d\n\n", gdfid););
   }


/* Test Case -- GDcreate
*/
   MESSAGE(4,printf("\f\tTesting GDcreate... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDcreate... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   xdim = 60;
   ydim = 80;
   uplft[0] = -512740.28306;
   uplft[1] = 2733747.62890;
   lowrgt[0] = -12584.57301;
   lowrgt[1] = 1946984.64021;
   MESSAGE(6,printf("\t\tCreating UTM grid \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating UTM grid \n"););
   GDid3 = GDcreate(gdfid3, "UTM3", xdim, ydim, uplft, lowrgt);
   if (GDid3 == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid3 = GDcreate(gdfid3, \"UTM3\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDcreate %d\n/n", GDid3););
      MESSAGE(11,fprintf(fp,"\t\tGDid3 = GDcreate(gdfid3, \"UTM3\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDcreate %d\n\n", GDid3););
   }

   MESSAGE(6,printf("\t\tCreating UTM grid \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating UTM grid \n"););
   GDid_utm = GDcreate(gdfid, "UTM", xdim, ydim, uplft, lowrgt);
   if (GDid_utm == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_utm = GDcreate(gdfid, \"UTM\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDcreate %d\n\n", GDid_utm););
      MESSAGE(11,fprintf(fp,"\t\tGDid_utm = GDcreate(gdfid, \"UTM\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDcreate %d\n\n", GDid_utm););
   }

   xdim = xdim_ease;
   ydim = ydim_ease;
   uplft[0] = EHconvAng(-180.0, HDFE_DEG_DMS);
   uplft[1] = EHconvAng(86.72, HDFE_DEG_DMS);
   lowrgt[0] = EHconvAng( 180.0,HDFE_DEG_DMS);
   lowrgt[1] = EHconvAng( -86.72,HDFE_DEG_DMS);
   MESSAGE(6,printf("\t\tCreating EASE grid \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating EASE grid \n"););
   GDid_ease = GDcreate(gdfid, "Ease", xdim, ydim, uplft, lowrgt);
   if (GDid_ease == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_ease = GDcreate(gdfid, \"Ease\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDcreate %d \n\n", GDid_ease););
      MESSAGE(11,fprintf(fp,"\t\tGDid_ease = GDcreate(gdfid, \"Ease\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDcreate %d\n\n", GDid_ease););
   }


   xdim = 60;
   ydim = 80;
   uplft[0] = -126000000.00;
   uplft[1] = -064000000.00;
   lowrgt[0] = -120000000.00;
   lowrgt[1] = -072000000.00;
   MESSAGE(6,printf("\t\tCreating Geographic grid \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating Geographic grid \n"););
   GDid_geo = GDcreate(gdfid, "Geo", xdim, ydim, uplft, lowrgt);
   if (GDid_geo == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_geo = GDcreate(gdfid, \"Geo\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDcreate %d \n\n", GDid_geo););
      MESSAGE(11,fprintf(fp,"\t\tGDid_geo = GDcreate(gdfid, \"Geo\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDcreate %d\n\n", GDid_geo););
   }

   xdim=360;
   ydim=90;
   uplft[0] = -10447125.82759;
   uplft[1] = 10447125.82759;
   lowrgt[0] = 10447125.82759;
   lowrgt[1] = -10447125.82759;
   MESSAGE(6,printf("\t\tCreating Polar Stereo. grid of north hemisphere\n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating Polar Stereo. grid of north hemisphere\n"););
   gdid_polar_np = GDcreate(gdfid, "Polar_np", xdim, ydim, uplft, lowrgt);
   if (gdid_polar_np == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tgdid_polar_np = GDcreate(gdfid, \"Polar_np\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDcreate %d \n\n", gdid_polar_np););
      MESSAGE(11,fprintf(fp,"\t\tgdid_polar_np = GDcreate(gdfid, \"Polar_np\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDcreate %d\n\n", gdid_polar_np););
   }

   xdim=360;
   ydim=90;
   uplft[0] = 10447125.82759;
   uplft[1] = -10447125.82759;
   lowrgt[0] = -10447125.82759;
   lowrgt[1] =  10447125.82759;
   MESSAGE(6,printf("\t\tCreating Polar Stereo. grid of south hemisphere\n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating Polar Stereo. grid of south hemisphere\n"););
   gdid_polar_sp = GDcreate(gdfid, "Polar_sp", xdim, ydim, uplft, lowrgt);
   if (gdid_polar_sp == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tgdid_polar_sp = GDcreate(gdfid, \"Polar_sp\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDcreate %d \n\n", gdid_polar_sp););
      MESSAGE(11,fprintf(fp,"\t\tgdid_polar_sp = GDcreate(gdfid, \"Polar_sp\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDcreate %d\n\n", gdid_polar_sp););
   }

   xdim=120;
   ydim=60;
   uplft[0] = -11119487.42844;
   uplft[1] = 8673539.24806;
   lowrgt[0] = 15567282.39984;
   lowrgt[1] = -8673539.24806;
   MESSAGE(6,printf("\t\tCreating Interrupted Goode grid \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating Interrupted Goode grid \n"););
   GDid_igoode = GDcreate(gdfid, "IGoode", xdim, ydim, uplft, lowrgt);
   if (GDid_igoode == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_igoode = GDcreate(gdfid, \"IGoode\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDcreate %d \n\n", GDid_igoode););
      MESSAGE(11,fprintf(fp,"\t\tGDid_igoode = GDcreate(gdfid, \"IGoode\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDcreate %d\n\n", GDid_igoode););
   }

   xdim=359;
   ydim=321;
   uplft[0] = 49844710.48057;
   uplft[1] = 884884.39883;
   lowrgt[0] = 30521379.68485;
   lowrgt[1] = 1152027.64253;
   MESSAGE(6,printf("\t\tCreating Space Oblique Mercator grid \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating Space Oblique Mercator grid \n"););
   GDid_som = GDcreate(gdfid, "SOM", xdim, ydim, uplft, lowrgt);
   if (GDid_som == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_som = GDcreate(gdfid, \"SOM\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDcreate %d \n\n", GDid_som););
      MESSAGE(11,fprintf(fp,"\t\tGDid_som = GDcreate(gdfid, \"SOM\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDcreate %d\n\n", GDid_som););
   }

   xdim=719;
   ydim=180;
   uplft[0] = 0.0000;
   uplft[1] = 9009950.36324;
   lowrgt[0] = 0.0000;
   lowrgt[1] = -9009950.36324;
   MESSAGE(6,printf("\t\tCreating Lambert Azimuthal grid \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating Lambert Azimuthal grid \n"););
   GDid_lamaz = GDcreate(gdfid, "Lamaz", xdim, ydim, uplft, lowrgt);
   if (GDid_lamaz == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_lamaz = GDcreate(gdfid, \"Lamaz\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDcreate %d \n\n", GDid_lamaz););
      MESSAGE(11,fprintf(fp,"\t\tGDid_lamaz = GDcreate(gdfid, \"Lamaz\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDcreate %d\n\n", GDid_lamaz););
   }

   
   xdim=200;
   ydim=90;
   uplft[0] = 3422259.57265;
   uplft[1] = 6824822.05796;
   lowrgt[0] = -17519429.48100;
   lowrgt[1] = 4994368.88166;
   MESSAGE(6,printf("\t\tCreating Hotin Oblique Mercator grid \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating Hotin Oblique Mercator grid \n"););
   GDid_hom = GDcreate(gdfid, "hom", xdim, ydim, uplft, lowrgt);
   if (GDid_hom == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_hom = GDcreate(gdfid, \"hom\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDcreate %d \n\n", GDid_hom););
      MESSAGE(11,fprintf(fp,"\t\tGDid_hom = GDcreate(gdfid, \"hom\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDcreate %d\n\n", GDid_hom););
   }


   xdim=351;
   ydim=171;
   uplft[0] = -2279109.37671;
   uplft[1] = 12358083.24054;
   lowrgt[0] = -56342817.96247;
   lowrgt[1] = -24776979.34092;
   MESSAGE(6,printf("\t\tCreating Lambert Conformal grid \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating Lambert Conformal grid \n"););
   GDid_lamcon = GDcreate(gdfid, "lamcon", xdim, ydim, uplft, lowrgt);
   if (GDid_lamcon == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_lamcon = GDcreate(gdfid, \"lamcon\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDcreate %d \n\n", GDid_lamcon););
      MESSAGE(11,fprintf(fp,"\t\tGDid_lamcon = GDcreate(gdfid, \"lamcon\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDcreate %d\n\n", GDid_lamcon););
   }


   xdim=181;
   ydim=171;
   uplft[0] = 4855670.77539;
   uplft[1] = 9458558.92483;
   lowrgt[0] = 5201746.43983;
   lowrgt[1] = -10466077.24942;
   MESSAGE(6,printf("\t\tCreating Transverse Mercator grid \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating Transverse Mercator grid \n"););
   GDid_tm = GDcreate(gdfid, "tm", xdim, ydim, uplft, lowrgt);
   if (GDid_tm == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_tm = GDcreate(gdfid, \"tm\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDcreate %d \n\n", GDid_tm););
      MESSAGE(11,fprintf(fp,"\t\tGDid_tm = GDcreate(gdfid, \"tm\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDcreate %d\n\n", GDid_tm););
   }


   xdim=161;
   ydim=171;
   uplft[0] = -250873.85859;
   uplft[1] = 12669051.66767;
   lowrgt[0] = 850873.85859;
   lowrgt[1] = -7137259.12615;
   MESSAGE(6,printf("\t\tCreating Polyconic grid \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating Polyconic grid \n"););
   GDid_poly = GDcreate(gdfid, "poly", xdim, ydim, uplft, lowrgt);
   if (GDid_poly == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_poly = GDcreate(gdfid, \"poly\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDcreate %d \n\n", GDid_poly););
      MESSAGE(11,fprintf(fp,"\t\tGDid_poly = GDcreate(gdfid, \"poly\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDcreate %d\n\n", GDid_poly););
   }


   xdim=351;
   ydim=171;
   uplft[0] = 1436267.12618;
   uplft[1] = 9451564.31420;
   lowrgt[0] = 1343604.73094;
   lowrgt[1] = -9451564.31420;
   MESSAGE(6,printf("\t\tCreating IS grid \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating IS grid \n"););
   GDid_is = GDcreate(gdfid, "is", xdim, ydim, uplft, lowrgt);
   if (GDid_is == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_is = GDcreate(gdfid, \"is\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDcreate %d \n\n", GDid_is););
      MESSAGE(11,fprintf(fp,"\t\tGDid_is = GDcreate(gdfid, \"is\", xdim, ydim, uplft, lowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDcreate %d\n\n", GDid_is););
   }


/* Test Case -- GDdefproj
*/
   MESSAGE(4,printf("\f\tTesting GDdefproj... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDdefproj... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   zonecode = -13;
   spherecode = 0;

   for(i=0; i < 16; i++)
   {
      projparm[i]=0.0;
   }
   MESSAGE(6,printf("\t\tDefining grid projection parameters\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining grid projection parameters\n"););
   status = GDdefproj(GDid_utm, GCTP_UTM, zonecode, spherecode, projparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefproj(GDid_utm, GCTP_UTM, zonecode, spherecode, projparm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefproj %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=GDdefproj(GDid_utm, GCTP_UTM, zonecode, spherecode, projparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdefproj %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining grid projection parameters\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining grid projection parameters\n"););
   status = GDdefproj(GDid3, GCTP_UTM, zonecode, spherecode, projparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefproj(GDid3, GCTP_UTM, zonecode, spherecode, projparm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefproj %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefproj(GDid3, 1, zonecode, spherecode, projparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdefproj %d\n\n", status););
   }
   status = GDdetach(GDid3);
   status= GDclose(gdfid3); /*Abe Taaheri added to avoid memory leaks */

   for(i=0; i < 16; i++)
   {
      projparm[i]=0.0;
   }
   spherecode = 0;
   projparm[5]=40000000.00;
   MESSAGE(6,printf("\t\tDefining polar stereographic grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining polar stereographic grid\n"););
   status=GDdefproj(gdid_polar_np, GCTP_PS, -1, spherecode, projparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=GDdefproj(gdid_polar_np, GCTP_PS, -1, spherecode, projparm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefproj %d\n\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=GDdefproj(gdid_polar_np, GCTP_PS, -1, spherecode, projparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdefproj %d\n\n",status););
   }

   for(i=0; i < 16; i++)
   {
      projparm[i]=0.0;
   }
   MESSAGE(6,printf("\t\tDefining Interrupted Goode grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining Interrupted Goode grid\n"););
   status=GDdefproj(GDid_igoode, GCTP_GOOD, -1, -1, projparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=GDdefproj(GDid_igoode, GCTP_GOOD, -1, -1, projparm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefproj %d\n\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=GDdefproj(GDid_igoode, GCTP_GOOD, -1, -1, projparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdefproj %d\n\n",status););
   }

   for(i=0; i < 16; i++)
   {
      projparm[i]=0.0;
   }
   MESSAGE(6,printf("\t\tDefining Lambert Azimuthal grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining Lambert Azimuthal grid\n"););
   status=GDdefproj(GDid_lamaz, GCTP_LAMAZ, -1, -1, projparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=GDdefproj(GDid_lamaz, GCTP_LAMAZ, -1, -1, projparm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefproj %d\n\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=GDdefproj(GDid_lamaz, GCTP_LAMAZ, -1, -1, projparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdefproj %d\n\n",status););
   }

   for(i=0; i < 16; i++)
   {
      projparm[i]=0.0;
   }
   projparm[2]=3;
   projparm[3]=150;
   projparm[12]=1;
   MESSAGE(6,printf("\t\tDefining Space Oblique Mercator grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining Space Oblique Mercator grid\n"););
   status=GDdefproj(GDid_som, GCTP_SOM, -1, -1, projparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=GDdefproj(GDid_som,GCTP_SOM,-1,-1,projparm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefproj %d\n\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=GDdefproj(GDid_som,GCTP_SOM,-1,-1,projparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdefproj %d\n\n",status););
   }

    
   for(i=0; i < 16; i++)
   {
      projparm[i]=0.0;
   }
   projparm[5]=30000000.00;
   MESSAGE(6,printf("\t\tDefining EASE grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining EASE grid\n"););
   status=GDdefproj(GDid_ease, GCTP_BCEA, -1, -1, projparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=GDdefproj(GDid_ease,GCTP_BCEA,-1,-1,projparm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefproj %d\n\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=GDdefproj(GDid_ease, GCTP_BCEA,-1,-1,projparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdefproj %d\n\n",status););
   }


   MESSAGE(6,printf("\t\tDefining Geographic grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining Geographic grid\n"););
   status=GDdefproj(GDid_geo, GCTP_GEO, -1, -1, NULL);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=GDdefproj(GDid_geo,GCTP_GEO,-1,-1,NULL);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefproj %d\n\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=GDdefproj(GDid_geo, GCTP_GEO,-1,-1,NULL);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdefproj %d\n\n",status););
   }

   for(i=0; i < 16; i++)
   {
      projparm[i]=0.0;
   }
   projparm[2] = 0.9996;
   projparm[5] = 20000000.00;
   projparm[8] = -75000000.00;
   projparm[9] = 10000000.00;
   projparm[10] = -95000000.00;
   projparm[11] = 30000000.00;
   MESSAGE(6,printf("\t\tDefining Hotin Oblique Mercator grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining Hotin Oblique Mercator grid\n"););
   status=GDdefproj(GDid_hom, GCTP_HOM, -1,-1, projparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=GDdefproj(GDid_hom, GCTP_HOM, -1, -1, projparm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefproj %d\n\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=GDdefproj(GDid_hom, GCTP_HOM, -1, -1, projparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdefproj %d\n\n",status););
   }

   for(i=0; i < 16; i++)
   {
      projparm[i]=0.0;
   }
   projparm[2] = 20000000.00;
   projparm[3] = 40000000.00;
   projparm[4] = -75000000.00;
   MESSAGE(6,printf("\t\tDefining Lambert Conformal grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining Lambert Conformal grid\n"););
   status=GDdefproj(GDid_lamcon, GCTP_LAMCC, -1, -1, projparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=GDdefproj(GDid_lamcon, GCTP_LAMCC, -1, -1, projparm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefproj %d\n\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=GDdefproj(GDid_lamcon, GCTP_LAMCC, -1, -1, projparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdefproj %d\n\n",status););
   }

   for(i=0; i < 16; i++)
   {
      projparm[i]=0.0;
   }
   projparm[2] = 0.9996;
   projparm[4] = -75000000.00;
   projparm[6] = 5000000.00;
   MESSAGE(6,printf("\t\tDefining Transverse Mercator grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining Transverse Mercator grid\n"););
   status=GDdefproj(GDid_tm, GCTP_TM, -1, -1, projparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=GDdefproj(GDid_m, GCTP_TM, -1, -1, projparm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefproj %d\n\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=GDdefproj(GDid_tm, GCTP_TM, -1, -1, projparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdefproj %d\n\n",status););
   }

   for(i=0; i < 16; i++)
   {
      projparm[i]=0.0;
   }
   projparm[4] = 75000000.00;
   projparm[5] = -25000000.00;
   projparm[6] = 300000.00;
   MESSAGE(6,printf("\t\tDefining Polyconic grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining Polyconic grid\n"););
   status=GDdefproj(GDid_poly, GCTP_POLYC, -1, -1, projparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=GDdefproj(GDid_poly, GCTP_POLYC, -1, -1, projparm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefproj %d\n\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=GDdefproj(GDid_poly, GCTP_POLYC, -1, -1, projparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdefproj %d\n\n",status););
   }

   for(i=0; i < 16; i++)
   {
      projparm[i]=0.0;
   }
   projparm[4] = 0.0;
   projparm[5] = 40000000.00;
   MESSAGE(6,printf("\t\tDefining IS grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining IS grid\n"););
   status=GDdefproj(GDid_is, GCTP_ISINUS, -1, -1, projparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=GDdefproj(GDid_is, GCTP_ISINUS, -1, -1, projparm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefproj %d\n\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=GDdefproj(GDid_is, GCTP_ISINUS, -1, -1, projparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdefproj %d\n\n",status););
   }



/* Test Case  -- GDdefpixreg
*/
   MESSAGE(4,printf("\f\tTesting GDdefpixreg... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDdefpixreg... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tDefining pixel registration in UTM grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining pixel registration in UTM grid\n"););
   status = GDdefpixreg(GDid_utm, HDFE_CORNER);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefpixreg(GDid_utm, HDFE_CORNER);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefpixreg %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tValue returned from GDdefpixreg %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefpixreg(GDid_utm, HDFE_CORNER);\n\n"););
   }

   MESSAGE(6,printf("\t\tDefining pixel registration in Polar grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining pixel registration in Polar grid\n"););
   status = GDdefpixreg(gdid_polar_np, HDFE_CORNER);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefpixreg(gdid_polar_np, HDFE_CORNER);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefpixreg %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tValue returned from GDdefpixreg %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefpixreg(gdid_polar_np, HDFE_CORNER);\n\n"););
   }

   MESSAGE(6,printf("\t\tDefining pixel registration in IGoode grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining pixel registration in IGoode grid\n"););
   status = GDdefpixreg(GDid_igoode, HDFE_CORNER);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefpixreg(GDid_igoode, HDFE_CORNER);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefpixreg %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tValue returned from GDdefpixreg %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefpixreg(GDid_igoode, HDFE_CORNER);\n\n"););
   }

   MESSAGE(6,printf("\t\tDefining pixel registration in SOM grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining pixel registration in SOM grid\n"););
   status = GDdefpixreg(GDid_som, HDFE_CORNER);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefpixreg(GDid_som, HDFE_CORNER);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefpixreg %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tValue returned from GDdefpixreg %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefpixreg(GDid_som, HDFE_CORNER);\n\n"););
   }

   MESSAGE(6,printf("\t\tDefining pixel registration in Lamaz grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining pixel registration in Lamaz grid\n"););
   status = GDdefpixreg(GDid_lamaz, HDFE_CORNER);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefpixreg(GDid_lamaz, HDFE_CORNER);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefpixreg %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tValue returned from GDdefpixreg %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefpixreg(GDid_lamaz, HDFE_CORNER);\n\n"););
   }

   MESSAGE(6,printf("\t\tDefining pixel registration in EASE grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining pixel registration in EASE grid\n"););
   status = GDdefpixreg(GDid_ease, HDFE_CORNER);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefpixreg(GDid_ease, HDFE_CORNER);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefpixreg %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tValue returned from GDdefpixreg %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefpixreg(GDid_ease, HDFE_CORNER);\n\n"););
   }

   MESSAGE(6,printf("\t\tDefining pixel registration in Geo grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining pixel registration in Geo grid\n"););
   status = GDdefpixreg(GDid_geo, HDFE_CORNER);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefpixreg(GDid_geo, HDFE_CORNER);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefpixreg %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tValue returned from GDdefpixreg %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefpixreg(GDid_geo, HDFE_CORNER);\n\n"););
   }

/* Test Case  -- GDdeforigin
*/
   MESSAGE(4,printf("\f\tTesting GDdeforigin... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDdeforigin... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tDefining origin of projection UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining origin of projection UTM\n"););
   status = GDdeforigin(GDid_utm, HDFE_GD_UL);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeforigin(GDid_utm, HDFE_GD_UL);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeforigin %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeforigin %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeforigin(GDid_utm, HDFE_GD_UL);\n\n"););
   }

   MESSAGE(11,fprintf(fp,"\t\tDefining origin of projection Polar\n"););
   MESSAGE(6,printf("\t\tDefining origin of projection Polar\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining origin of projection\n"););
   status = GDdeforigin(gdid_polar_np, HDFE_GD_UR);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeforigin(gdid_polar_np, HDFE_GD_UR);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeforigin %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeforigin %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeforigin(gdid_polar_np, HDFE_GD_UR);\n\n"););
   }

   MESSAGE(6,printf("\t\tDefining origin of projection IGoode\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining origin of projection IGoode \n"););
   status = GDdeforigin(GDid_igoode, HDFE_GD_LL);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeforigin(GDid_igoode, HDFE_GD_LL);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeforigin %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeforigin %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeforigin(GDid_igoode, HDFE_GD_LL);\n\n"););
   }

   MESSAGE(6,printf("\t\tDefining origin of projection SOM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining origin of projection SOM\n"););
   status = GDdeforigin(GDid_som, HDFE_GD_LR);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeforigin(GDid_som, HDFE_GD_LR);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeforigin %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeforigin %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeforigin(GDid_som, HDFE_GD_LR);\n\n"););
   }

   MESSAGE(6,printf("\t\tDefining origin of projection Lamaz\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining origin of projection Lamaz\n"););
   status = GDdeforigin(GDid_lamaz, HDFE_GD_UL);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeforigin(GDid_lamaz, HDFE_GD_UL);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeforigin %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeforigin %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeforigin(GDid_lamaz, HDFE_GD_UL);\n\n"););
   }

   MESSAGE(6,printf("\t\tDefining origin of projection EASE\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining origin of projection EASE\n"););
   status = GDdeforigin(GDid_ease, HDFE_GD_UL);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeforigin(GDid_ease, HDFE_GD_UL);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeforigin %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeforigin %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeforigin(GDid_ease, HDFE_GD_UL);\n\n"););
   }

   MESSAGE(6,printf("\t\tDefining origin of projection Geo\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining origin of projection Geo\n"););
   status = GDdeforigin(GDid_geo, HDFE_GD_UR);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeforigin(GDid_geo, HDFE_GD_UR);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeforigin %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeforigin %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeforigin(GDid_geo, HDFE_GD_UR);\n\n"););
   }

/* Test Case -- GDdefdim
*/
   MESSAGE(4,printf("\f\tTesting GDdefdim... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDdefdim... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tDefining dimension TestDim1\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension TestDim1\n"););
   status = GDdefdim(GDid2, "TestDim1", 40);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefdim(GDid2, \"TestDim1\", 40);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefdim %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefdim(GDid2, \"TestDim1\", 40);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdefdim %d\n\n", status););
   }
   MESSAGE(6,printf("\n\n"););
   MESSAGE(11,fprintf(fp,"\n\n"););

   MESSAGE(6,printf("\t\tDefining dimension TestDim2\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension TestDim2\n"););
   status = GDdefdim(GDid2, "TestDim2", 25);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefdim(GDid2, \"TestDim2\", 25);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefdim %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefdim(GDid2, \"TestDim2\", 25);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdefdim %d\n\n", status););
   }
   MESSAGE(6,printf("\n\n"););
   MESSAGE(11,fprintf(fp,"\n\n"););

   MESSAGE(6,printf("\t\tDefining dimension Conduction\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension Conduction\n"););
   status = GDdefdim(GDid_utm, "Conduction", 25);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefdim(GDid_utm, \"Conduction\", 25);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefdim %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefdim(GDid_utm, \"Conduction\", 25);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdefdim %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension Timedim\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension Timedim\n"););
   status = GDdefdim(GDid_utm, "Timedim", 4800);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefdim(GDid_utm, \"Timedim\", 4800);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefdim %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefdim(GDid_utm, \"Timedim\", 4800);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdefdim %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension Heightdim\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension Heightdim\n"););
   status = GDdefdim(GDid_utm, "Hghtdim", 80);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefdim(GDid_utm, \"Hghtdim\", 80);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefdim %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefdim(GDid_utm, \"Hghtdim\", 80);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned  from GDdefdim %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension Convection\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension Convection\n"););
   status = GDdefdim(gdid_polar_np, "Convection", 75);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefdim(gdid_polar_np, \"Convection\", 75);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefdim %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefdim(gdid_polar_np,\"Convection\",75);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdefdim %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension Radiant\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension Radiant\n"););
   status = GDdefdim(GDid_igoode, "Radiant", 45);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefdim(GDid_igoode, \"Radiant\", 45);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefdim %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefdim(GDid_igoode,\"Radiant\",45);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdefdim %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension Emission\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension Emission\n"););
   status = GDdefdim(GDid_som, "Emission", 55);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefdim(GDid_som, \"Emission\", 55);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefdim %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefdim(GDid_som, \"Emission\", 55);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdefdim %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension Flux\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension Flux\n"););
   status = GDdefdim(GDid_lamaz, "Flux", 65);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefdim(GDid_lamaz, \"Flux\", 65);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefdim %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefdim(GDid_lamaz, \"Flux\", 65);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdefdim %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension Width\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension Wdith\n"););
   status = GDdefdim(GDid_ease, "Width", xdim_ease);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefdim(GDid_ease, \"Width\", xdim_ease);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefdim %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefdim(GDid_ease, \"Width\", xdim_ease);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdefdim %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension Gradient\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension Gradient\n"););
   status = GDdefdim(GDid_geo, "Gradient", 85);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefdim(GDid_geo, \"Gradient\", 85);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdefdim %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefdim(GDid_geo, \"Gradient\", 85);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdefdim %d\n\n", status););
   }

/* Test Case -- GDdetach
*/
   MESSAGE(4,printf("\f\tTesting GDdetach... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDdetach... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tDetaching from grid UTM2\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid UTM2\n"););
   status = GDdetach(GDid2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid2);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdetach %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDetaching from grid UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid UTM\n"););
   status = GDdetach(GDid_utm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_utm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_utm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }
 
   MESSAGE(6,printf("\t\tDetaching from grid PolarGrid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid PolarGrid\n"););
   status = GDdetach(gdid_polar_np);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(gdid_polar_np);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(gdid_polar_np);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }
 
   MESSAGE(6,printf("\t\tDetaching from grid PolarGrid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid PolarGrid\n"););
   status = GDdetach(gdid_polar_sp);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(gdid_polar_sp);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(gdid_polar_sp);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }
 
   MESSAGE(6,printf("\t\tDetaching from grid IGoode\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid IGoode\n"););
   status = GDdetach(GDid_igoode);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_igoode);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\b", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_igoode);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }
 
   MESSAGE(6,printf("\t\tDetaching from grid SOM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid SOM\n"););
   status = GDdetach(GDid_som);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_som);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_som);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }
 
   MESSAGE(6,printf("\t\tDetaching from grid Lamaz\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid Lamaz\n"););
   status = GDdetach(GDid_lamaz);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_lamaz);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_lamaz);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }
  
   MESSAGE(6,printf("\t\tDetaching from grid EASE\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid EASE \n"););
   status = GDdetach(GDid_ease);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_ease);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_ease);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDetaching from grid Geo\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid Geo \n"););
   status = GDdetach(GDid_geo);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_geo);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_geo);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDetaching from grid Hom\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid Hom \n"););
   status = GDdetach(GDid_hom);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_hom);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_hom);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }
 
   MESSAGE(6,printf("\t\tDetaching from grid Lambert Conformal\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid Lambert Conformal \n"););
   status = GDdetach(GDid_lamcon);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_lamcon);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_lamcon);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }
 
   MESSAGE(6,printf("\t\tDetaching from grid Transverse Mercator\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid Transverse Mercator \n"););
   status = GDdetach(GDid_tm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_tm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_tm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }
 
   MESSAGE(6,printf("\t\tDetaching from grid Polyconic\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid Polyconic \n"););
   status = GDdetach(GDid_poly);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_poly);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_poly);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }
 
   MESSAGE(6,printf("\t\tDetaching from grid IS \n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid IS \n"););
   status = GDdetach(GDid_is);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_is);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_is);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }
 
 
/* Test Case -- GDattach
*/
   MESSAGE(4,printf("\f\tTesting GDattach... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDattach... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tAttaching to grid UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to grid UTM\n"););
   GDid_utm = GDattach(gdfid, "UTM");
   if (GDid_utm == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_utm = GDattach(gdfid, \"UTM\");\n"););
      MESSAGE(8,printf("\t\tValue returned by GDattach %d\n\n", GDid_utm););
      MESSAGE(11,fprintf(fp,"\t\tGDid_utm = GDattach(gdfid, \"UTM\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDattach %d\n\n", GDid_utm););
   }

   MESSAGE(6,printf("\t\tAttaching to grid IGoode\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to grid IGoode\n"););
   GDid_igoode = GDattach(gdfid, "IGoode");
   if (GDid_igoode == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_igoode = GDattach(gdfid, \"IGoode\");\n"););
      MESSAGE(8,printf("\t\tValue returned by GDattach %d\n\n", GDid_igoode););
      MESSAGE(11,fprintf(fp,"\t\tGDid_igoode = GDattach(gdfid, \"IGoode\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDattach %d\n\n", GDid_igoode););
   }

   MESSAGE(6,printf("\t\tAttaching to grid Lamaz\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to grid Lamaz\n"););
   GDid_lamaz = GDattach(gdfid, "Lamaz");
   if (GDid_lamaz == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_lamaz = GDattach(gdfid, \"Lamaz\");\n"););
      MESSAGE(8,printf("\t\tValue returned by GDattach %d\n\n", GDid_lamaz););
      MESSAGE(11,fprintf(fp,"\t\tGDid_lamaz = GDattach(gdfid, \"Lamaz\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDattach %d\n\n", GDid_lamaz););
   }

   MESSAGE(6,printf("\t\tAttaching to grid Polar\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to grid Polar\n"););
   gdid_polar_np = GDattach(gdfid, "Polar_np");
   if (gdid_polar_np == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tgdid_polar_np = GDattach(gdfid, \"Polar_np\");\n"););
      MESSAGE(8,printf("\t\tValue returned by GDattach %d\n\n", gdid_polar_np););
      MESSAGE(11,fprintf(fp,"\t\tgdid_polar_np = GDattach(gdfid, \"Polar_np\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDattach %d\n\n", gdid_polar_np););
   }

   MESSAGE(6,printf("\t\tAttaching to grid SOM\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to grid SOM\n"););
   GDid_som = GDattach(gdfid, "SOM");
   if (GDid_som == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_som = GDattach(gdfid, \"SOM\");\n"););
      MESSAGE(8,printf("\t\tValue returned by GDattach %d\n\n", GDid_som););
      MESSAGE(11,fprintf(fp,"\t\tGDid_som = GDattach(gdfid, \"SOM\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDattach %d\n\n", GDid_som););
   }

   MESSAGE(6,printf("\t\tAttaching to grid EASE\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to grid EASE\n"););
   GDid_ease = GDattach(gdfid, "Ease");
   if (GDid_ease == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_ease = GDattach(gdfid, \"Ease\");\n"););
      MESSAGE(8,printf("\t\tValue returned by GDattach %d\n\n", GDid_ease););
      MESSAGE(11,fprintf(fp,"\t\tGDid_ease = GDattach(gdfid, \"Ease\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDattach %d\n\n", GDid_ease););
   }

   MESSAGE(6,printf("\t\tAttaching to grid Geo\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to grid Geo\n"););
   GDid_geo = GDattach(gdfid, "Geo");
   if (GDid_geo == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_geo = GDattach(gdfid, \"Geo\");\n"););
      MESSAGE(8,printf("\t\tValue returned by GDattach %d\n\n", GDid_geo););
      MESSAGE(11,fprintf(fp,"\t\tGDid_geo = GDattach(gdfid, \"Geo\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDattach %d\n\n", GDid_geo););
   }

   MESSAGE(6,printf("\t\tAttaching to grid UTM2\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to grid UTM2\n"););
   GDid2 = GDattach(gdfid2, "UTM2");
   if (GDid2 == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid2 = GDattach(gdfid2, \"UTM2\");\n"););
      MESSAGE(8,printf("\t\tValue returned by GDattach %d\n\n", GDid2););
      MESSAGE(11,fprintf(fp,"\t\tGDid2 = GDattach(gdfid2, \"UTM2\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDattach %d\n\n", GDid2););
   }
   status= GDdetach(GDid_geo);  /*Abe Taaheri added to avoid memory leaks */

   MESSAGE(6,printf("\t\tAttaching to grid Geo\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to grid Geo\n"););
   GDid_geo = GDattach(gdfid, "Geo");
   if (GDid_geo == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_geo = GDattach(gdfid, \"Geo\");\n"););
      MESSAGE(8,printf("\t\tValue returned by GDattach %d\n\n", GDid_geo););
      MESSAGE(11,fprintf(fp,"\t\tGDid_geo = GDattach(gdfid, \"Geo\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDattach %d\n\n", GDid_geo););
   }

/* Test Case -- GDdeffield
*/
   MESSAGE(4,printf("\f\tTesting GDdeffield... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDdeffield... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tDefining field tempfield in grid UTM2\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field tempfield in grid UTM2\n"););
   status = GDdeffield(GDid2, "tempfield", "TestDim2,TestDim1", DFNT_FLOAT, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid2, \"tempfield\", \"TestDim2,TestDim1\", DFNT_FLOAT, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid2, \"tempfield\", \"TestDim2,TestDim1\", DFNT_FLOAT, HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeffield %d\n\n", status););
   }

/*   status = GDdetach(GDid2);
   MESSAGE(11,fprintf(fp,"status = GDdetach(GDid2);\n"););
   MESSAGE(11,fprintf(fp,"Value returned by GDdetach %d\n", status););  */

   MESSAGE(6,printf("\t\tDefining field Voltage in grid UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Voltage in grid UTM\n"););
   status = GDdeffield(GDid_utm, "Voltage", "XDim,YDim",DFNT_FLOAT32, HDFE_AUTOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_utm,\"Voltage\",\"XDim,YDim\",DFNT_FLOAT32,HDFE_AUTOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=GDdeffield(GDid_utm,\"Voltage\",\"XDim,YDim\",DFNT_FLOAT32,HDFE_AUTOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned from GDdeffield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining field Drift in grid UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Drift in grid UTM\n"););
   status = GDdeffield(GDid_utm, "Drift", "XDim,YDim",DFNT_FLOAT32, HDFE_AUTOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_utm,\"Drift\",\"XDim,YDim\",DFNT_FLOAT32, HDFE_AUTOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_utm, \"Drift\", \"XDim,YDim\",DFNT_FLOAT32, HDFE_AUTOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned from GDdeffield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining field Time in grid UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Time in grid UTM\n"););
   status = GDdeffield(GDid_utm, "Time", "Timedim",DFNT_FLOAT64, HDFE_AUTOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_utm,\"Time\",\"Timedim\",DFNT_FLOAT64, HDFE_AUTOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_utm, \"Time\", \"Timedim\",DFNT_FLOAT64, HDFE_AUTOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned from GDdeffield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining field Height in grid UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Height in grid UTM\n"););
   status = GDdeffield(GDid_utm, "Height", "Hghtdim",DFNT_FLOAT32, HDFE_AUTOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_utm,\"Height\",\"Hghtdim\",DFNT_FLOAT32, HDFE_AUTOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_utm, \"Height\", \"Hghtdim\",DFNT_FLOAT32, HDFE_AUTOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned from GDdeffield %d\n\n", status););
   }

/* Test Case -- GDdefcomp
*/
   MESSAGE(4,printf("\f\tTesting GDdefcomp... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDdefcomp... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   status = GDdefcomp(GDid_utm, HDFE_COMP_SKPHUFF, NULL);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefcomp(GDid_utm, HDFE_COMP_SKPHUFF, NULL);\n"););
      MESSAGE(8,printf("\t\tStatus returned by GDdefcomp %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefcomp(GDid_utm, HDFE_COMP_SKPHUFF, NULL);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by GDdefcomp %d\n", status););
   }
 
   MESSAGE(6,printf("\t\tDefining field Impedance in grid UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Impedance in grid UTM\n"););
   status = GDdeffield(GDid_utm, "Impedance", "XDim,YDim", DFNT_FLOAT32,HDFE_AUTOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_utm,\"Impedance\",\"XDim,YDim\",DFNT_FLOAT32,HDFE_AUTOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_utm, \"Impedance\", \"XDim,YDim\", DFNT_FLOAT32,HDFE_AUTOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned from GDdeffield %d\n\n", status););
   }

   compparm[0] = 2;     /* Pixels per block */
   compparm[1] = SZ_NN; /* Nearest Neighbour + Entropy Coding (EC) Method */

#ifdef HAVE_FILTER_SZIP_ENCODER
   status = GDdefcomp(GDid_utm, HDFE_COMP_SZIP, compparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed SZIP Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed SZIP Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefcomp(GDid_utm, HDFE_COMP_SZIP, compparm);\n"););
      MESSAGE(8,printf("\t\tStatus returned by GDdefcomp %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefcomp(GDid_utm, HDFE_COMP_SZIP, compparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by GDdefcomp %d\n", status););
   }
#else
   MESSAGE(4,printf("\t\t********Skip SZIP Test**********\n"););
   MESSAGE(11,fprintf(fp,"\t\t********Skip SZIP Test**********\n"););
   MESSAGE(4,printf("No szip encoder provided, the szip compression test is be skipped.\n"););
   MESSAGE(11,fprintf(fp,"No szip encoder provided, the szip compression test is be skipped.\n"););
#endif

   MESSAGE(6,printf("\t\tDefining field Grounding in grid UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Grounding in grid UTM\n"););
   status = GDdeffield(GDid_utm, "Grounding", "Conduction,YDim", DFNT_FLOAT, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_utm,\"Grounding\",\"Conduction,YDim\",DFNT_FLOAT, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_utm, \"Grounding\", \"Conduction,YDim\", DFNT_FLOAT, HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeffield %d\n\n", status););
   }


   status = GDdefcomp(GDid_utm, HDFE_COMP_NONE, NULL);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdefcomp(GDid_utm, HDFE_COMP_NONE, NULL);\n"););
      MESSAGE(8,printf("\t\tStatus returned by GDdefcomp %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdefcomp(GDid_utm, HDFE_COMP_NONE, NULL);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by GDdefcomp %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining field SensorG in grid IGoode\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field SensorG in grid IGoode\n"););
   status = GDdeffield(GDid_igoode, "SensorG", "XDim,YDim", DFNT_FLOAT, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_igoode,\"SensorG\",\"XDim,YDim\",DFNT_FLOAT, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_igoode, \"SensorG\", \"XDim,YDim\", DFNT_FLOAT, HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeffield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining field VoltageA in grid IGoode\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field VoltageA in grid IGoode\n"););
   status = GDdeffield(GDid_igoode, "VoltageA", "Radiant,YDim", DFNT_FLOAT, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_igoode,\"VoltageA\",\"Radiant,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_igoode,\"VoltageA\",\"Radiant,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeffield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining field Bypass in grid Polar\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Bypass in grid Polar\n"););
   status = GDdeffield(gdid_polar_np, "Bypass", "XDim,YDim", DFNT_FLOAT, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(gdid_polar_np,\"Bypass\",\"XDim,YDim\",DFNT_FLOAT, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(gdid_polar_np,\"Bypass\",\"XDim,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeffield %d\n\n", status););
   }

/* Test Case -- GDdeftile
*/
   MESSAGE(4,printf("\f\tTesting GDdeftile... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDdeftile... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   MESSAGE(6,printf("\t\tDefining Tiling parameters\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining Tiling parameters\n"););
   status = GDdeftile(gdid_polar_np, HDFE_TILE, 2, tiledims);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeftile(gdid_polar_np, HDFE_TILE, 2, tiledims);\n"););
      MESSAGE(8,printf("\t\tStatus of GDdeftile call %d \n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeftile(gdid_polar_np, HDFE_TILE, 2, tiledims);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus of GDdeftile call %d \n", status););
   }


   MESSAGE(6,printf("\t\tDefining field SideB in grid Polar\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field SideB in grid Polar\n"););
   status = GDdeffield(gdid_polar_np, "SideB", "Convection,YDim", DFNT_FLOAT, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(gdid_polar_np,\"SideB\",\"Convection,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(gdid_polar_np,\"SideB\",\"Convection,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeffield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tTurning off Tiling \n"););
   MESSAGE(11,fprintf(fp,"\t\tTurning off Tiling \n"););
   status = GDdeftile(gdid_polar_np, HDFE_NOTILE, 2, NULL);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeftile(gdid_polar_np, HDFE_NOTILE, 2, NULL);\n"););
      MESSAGE(8,printf("\t\tStatus of GDdeftile call %d \n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeftile(gdid_polar_np, HDFE_NOTILE, 2, NULL);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus of GDdeftile call %d \n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining field Counts in grid SOM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Counts in grid SOM\n"););
   status = GDdeffield(GDid_som, "Counts", "XDim,YDim", DFNT_FLOAT, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_som,\"Counts\",\"XDim,YDim\",DFNT_FLOAT, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_som,\"Counts\",\"XDim,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeffield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining field Load in grid SOM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Load in grid SOM\n"););
   status = GDdeffield(GDid_som, "Load", "Emission,YDim", DFNT_FLOAT, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_som,\"Load\",\"Emission,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_som,\"Load\",\"Emission,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeffield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining field Meters in grid Lamaz\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Meters in grid Lamaz\n"););
   status = GDdeffield(GDid_lamaz, "Meters", "XDim,YDim", DFNT_FLOAT, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_lamaz,\"Meters\",\"XDim,YDim\",DFNT_FLOAT, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_lamaz,\"Meters\",\"XDim,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeffield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining field Temperature in grid Lamaz\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Temperature in grid Lamaz\n"););
   status = GDdeffield(GDid_lamaz, "Temperature", "Flux,YDim", DFNT_FLOAT, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_lamaz,\"Temperature\",\"Flux,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_lamaz,\"Temperature\",\"Flux,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeffield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining field Intensity in grid EASE\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Intensity in grid EASE\n"););
   status = GDdeffield(GDid_ease, "Intensity", "XDim,YDim", DFNT_FLOAT, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_ease,\"Intensity\",\"XDim,YDim\",DFNT_FLOAT, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_ease,\"Intensity\",\"XDim,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeffield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining field Depth in grid Geo\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Depth in grid Geo\n"););
   status = GDdeffield(GDid_geo, "Depth", "XDim,YDim", DFNT_FLOAT, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_geo,\"Depth\",\"XDim,YDim\",DFNT_FLOAT, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_geo,\"Depth\",\"XDim,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeffield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining field Intervals in grid EASE\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Intervals in grid EASE\n"););
   status = GDdeffield(GDid_ease, "Intervals", "Width,YDim", DFNT_FLOAT, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_ease,\"Intervals\",\"Width,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_ease,\"Intervals\",\"Width,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeffield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tDefining field Interval in grid Geo\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining field Interval in grid Geo\n"););
   status = GDdeffield(GDid_geo, "Interval", "Gradient,YDim", DFNT_FLOAT, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdeffield(GDid_geo,\"Interval\",\"Gradient,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdeffield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdeffield(GDid_geo,\"Interval\",\"Gradient,YDim\",DFNT_FLOAT,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdeffield %d\n\n", status););
   }

/* Test Case -- GDsetfillvalue
*/
   MESSAGE(4,printf("\f\tTesting GDsetfillvalue... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDsetfillvalue... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tSetting fill value for field Voltage\n"););
   MESSAGE(11,fprintf(fp,"\t\tSetting fill value for field Voltage\n"););
   status = GDsetfillvalue(GDid_utm, "Voltage", &fillvalue);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDsetfillvalue(GDid_utm, \"Voltage\", &fillvalue);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDsetfillvalue %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDsetfillvalue(GDid_utm, \"Voltage\", &fillvalue);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDsetfillvalue %d\n", status););
   }

   MESSAGE(6,printf("\t\tDetaching from grid UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid UTM\n"););
   status = GDdetach(GDid_utm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_utm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d \n", status););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_utm);\n"););
   }

   MESSAGE(6,printf("\t\tAttach to grid UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttach to grid UTM\n"););
   GDid_utm = GDattach(gdfid, "UTM");
   if (GDid_utm == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_utm = GDattach(gdfid, \"UTM\");\n"););
      MESSAGE(8,printf("\t\tValue returned by GDattach %d\n", GDid_utm););
      MESSAGE(11,fprintf(fp,"\t\tGDid_utm = GDattach(gdfid, \"UTM\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDattach %d\n", GDid_utm););
   }

/* Test Case -- GDwritefield
*/
   MESSAGE(4,printf("\f\tTesting GDwritefield... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDwritefield... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tWriting field Voltage\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Voltage\n"););
   status = GDwritefield(GDid_utm, "Voltage", start, stride, edge, utmray);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_utm, \"Voltage\", start, stride, edge, utmray);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_utm, \"Voltage\",start,stride,edge,utmray);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwrietfield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tWriting field Drift\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Drift\n"););
   status = GDwritefield(GDid_utm, "Drift", NULL, NULL, NULL, utmray);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_utm, \"Drift\", NULL, NULL, NULL, utmray);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_utm, \"Drift\", NULL, NULL, NULL, utmray);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDwritefield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tWriting field Time\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Time\n"););
   status = GDwritefield(GDid_utm, "Time", NULL, NULL, NULL, utmtmeray);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_utm, \"Time\", NULL, NULL, NULL, utmtmeray);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_utm, \"Time\", NULL, NULL, NULL, utmtmeray);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDwritefield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tWriting field Height\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Height\n"););
   status = GDwritefield(GDid_utm, "Height", NULL, NULL, NULL, utmhght);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_utm, \"Height\", NULL, NULL, NULL, utmhght);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_utm, \"Height\", NULL, NULL, NULL, utmhght);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDwritefield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tWriting field Impedance\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Impedance\n"););
   status = GDwritefield(GDid_utm, "Impedance", NULL, NULL, NULL, utmray);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_utm, \"Impedance\", NULL, NULL, NULL, utmray);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_utm,\"Impedance\",NULL,NULL,NULL, utmray);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDwritefield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tWriting field Grounding\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Grounding\n"););
   status = GDwritefield(GDid_utm, "Grounding", NULL, NULL, NULL, ray3);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_utm, \"Grounding\", NULL, NULL, NULL, ray3);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_utm,\"Grounding\", NULL, NULL, NULL, ray3);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwritefield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tWriting field SensorG\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field SensorG\n"););
   status = GDwritefield(GDid_igoode, "SensorG", NULL, NULL, NULL, gooderay);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_igoode, \"SensorG\",NULL,NULL,NULL, gooderay);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_igoode,\"SensorG\",NULL,NULL,NULL,gooderay);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwritefield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tWriting field VoltageA\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field VoltageA\n"););
   status = GDwritefield(GDid_igoode, "VoltageA", NULL, NULL, NULL, gooderay2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_igoode, \"VoltageA\",NULL,NULL,NULL, gooderay2);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_igoode,\"VoltageA\",NULL,NULL,NULL,gooderay2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwritefield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tWriting field Bypass\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Bypass\n"););
   status = GDwritefield(gdid_polar_np, "Bypass", NULL, NULL, NULL, psray);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(gdid_polar_np, \"Bypass\", NULL, NULL, NULL, psray);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(gdid_polar_np,\"Bypass\", NULL, NULL, NULL, psray);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwritefield %d\n\n", status););
   }


/* Test Case -- GDsettilecache
*/
   MESSAGE(4,printf("\f\tTesting GDsettilecache... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDsettilecache... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   MESSAGE(6,printf("\t\tSetting the maximum cache for the tiling of field SiceB\n"););
   MESSAGE(11,fprintf(fp,"\t\tSetting the maximum cache for the tiling of field SideB\n"););
   status = GDsettilecache(gdid_polar_np,"SideB", 5, 0);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDsettilecache(gdid_polar_np, \"SideB\", 5, 0);\n"););
      MESSAGE(8,printf("\t\tStatus returned by call to GDsettilecache %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDsettilecache(gdid_polar_np, \"SideB\", 5, 0);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by call to GDsettilecache %d\n\n", status););
   }

 
/* Test Case -- GDwritetile
*/
   MESSAGE(4,printf("\f\tTesting GDwritetile... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDwritetile... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   index1 = 0;
   index2 = 0;
   tilecords[0] = 0;
   tilecords[1] = 0;
   while(index1 < 5) {
      while(index2 < 6) {
         MESSAGE(6,printf("\t\tWriting tiled field SideB\n"););
         MESSAGE(11,fprintf(fp,"\t\tWriting tiled field SideB\n"););
         status = GDwritetile(gdid_polar_np, "SideB", tilecords, tileray);
         if (status == -1)
         {
            MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
            MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
            MESSAGE(4,HEprint(stdout, 0););
            MESSAGE(11,HEprint(fp, 0););
         }
         else
         {
            MESSAGE(4,printf("\n"););
            MESSAGE(4,printf("\t\t********Passed Test**********\n"););
            MESSAGE(11,fprintf(fp,"\n"););
            MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
            MESSAGE(10,printf("\t\tstatus = GDwritetile(gdid_polar_np, \"SideB\", tilecords, tileray);\n"););
            MESSAGE(8,printf("\t\tValue returned by GDwritetile %d\n", status););
            MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritetile(gdid_polar_np,\"SideB\", tilecords, tileray);\n"););
            MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwritetile %d\n", status););
            MESSAGE(8,printf("\t\tWriting tile position %d  %d\n\n",tilecords[0],tilecords[1]););
            MESSAGE(11,fprintf(fp,"\t\tWriting tile position %d  %d\n\n",tilecords[0],tilecords[1]););
         }
         index2++;
         tilecords[1] = tilecords[1] + 1;
      }
      index2 = 0;
      index1++;
      tilecords[1] = 0;
      tilecords[0] = tilecords[0] + 1;
   }

   MESSAGE(6,printf("\t\tWriting field Counts\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Counts\n"););
   status = GDwritefield(GDid_som, "Counts", NULL, NULL, NULL, somray);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_som, \"Counts\", NULL, NULL, NULL, somray);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_som,\"Counts\", NULL, NULL, NULL, somray);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwritefield %d\n\n", status););
   }

   free(somray);

   MESSAGE(6,printf("\t\tWriting field Load\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Load\n"););
   status = GDwritefield(GDid_som, "Load", NULL, NULL, NULL, somray2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_som, \"Load\", NULL, NULL, NULL, somray2);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_som,\"Load\", NULL, NULL, NULL, somray2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwritefield %d\n\n", status););
   }

   free(somray2);

   MESSAGE(6,printf("\t\tWriting field Meters\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Meters\n"););
   status = GDwritefield(GDid_lamaz, "Meters", NULL, NULL, NULL, lamazray);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_lamaz, \"Meters\", NULL, NULL, NULL, lamazray);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_lamaz,\"Meters\",NULL,NULL,NULL,lamazray);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwritefield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tWriting field Temperature\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Temperature\n"););
   status = GDwritefield(GDid_lamaz, "Temperature", NULL, NULL, NULL, lamazray2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_lamaz, \"Temperature\", NULL, NULL, NULL, lamazray2);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_lamaz,\"Temperature\",NULL,NULL,NULL,lamazray2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwritefield %d\n\n", status););
   }


   MESSAGE(6,printf("\t\tWriting field Intensity\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Intensity\n"););
   status = GDwritefield(GDid_ease, "Intensity", NULL, NULL, NULL, easeray);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_ease, \"Intensity\", NULL, NULL, NULL, easeray);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_ease,\"Intensity\", NULL, NULL, NULL, easeray);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwritefield %d\n\n", status););
   }

   free(easeray);

   MESSAGE(6,printf("\t\tWriting field Intervals\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Intervals\n"););
   status = GDwritefield(GDid_ease, "Intervals", NULL, NULL, NULL, easeray2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_ease, \"Intervals\", NULL, NULL, NULL, easeray2);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_ease,\"Intervals\", NULL, NULL, NULL, easeray2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwritefield %d\n\n", status););
   }

   free(easeray2);

   MESSAGE(6,printf("\t\tWriting field Depth\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Depth\n"););
   status = GDwritefield(GDid_geo, "Depth", NULL, NULL, NULL, georay);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_geo, \"Depth\", NULL, NULL, NULL, georay);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_geo,\"Depth\",NULL,NULL,NULL,georay);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwritefield %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tWriting field Interval\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Interval\n"););
   status = GDwritefield(GDid_geo, "Interval", NULL, NULL, NULL, georay2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid_geo, \"Interval\", NULL, NULL, NULL, georay2);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid_geo,\"Interval\",NULL,NULL,NULL,georay2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwritefield %d\n\n", status););
   }

/*   printf("GDid2 = GDattach(gdfid2, \"UTM2\");\n");
   GDid2 = GDattach(gdfid2, "UTM2");
   fprintf(fp,"\t\tValue returned by GDattach %s\n", GDid2);
 
   MESSAGE(6,printf("\t\tWriting field tempfield\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field tempfield\n"););
   status = GDwritefield(GDid2, "tempfield", NULL, NULL, NULL, ray3);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwritefield(GDid2, \"tempfield\", NULL, NULL, NULL, ray3);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwritefield %d\n", status;);
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefield(GDid2, \"tempfield\", NULL, NULL, NULL, ray3);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDwritefield %d\n", status););
   }
*/

/* Test Case -- GDwriteattr
*/
   MESSAGE(4,printf("\f\tTesting GDwriteattr... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDwriteattr... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tWriting attribute Resistance\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting attribute Resistance\n"););
   status = GDwriteattr(GDid_utm, "Resistance", DFNT_INT32, 4, attr);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwriteattr(GDid_utm, \"Resistance\", DFNT_INT32, 4, attr);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwriteattr %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwriteattr(GDid_utm, \"Resistance\", DFNT_INT32, 4, attr);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDwriteattr %d\n", status););
   }

   MESSAGE(6,printf("\t\tWriting attribute Current\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting attribute Current\n"););
   status = GDwriteattr(GDid_utm, "Current", DFNT_INT32, 5, attr2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDwriteattr(GDid_utm, \"Current\", DFNT_INT32, 5, attr2);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDwriteattr %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwriteattr(GDid_utm, \"Current\", DFNT_INT32, 5, attr2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDwriteattr %d\n", status););
   }

   MESSAGE(6,printf("\t\tDetaching from grid UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid UTM\n"););
   status = GDdetach(GDid_utm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_utm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_utm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDdetach %d\n", status););
   }

   MESSAGE(6,printf("\t\tDetaching from grid Polar\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid Polar\n"););
   status = GDdetach(gdid_polar_np);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(gdid_polar_np);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(gdid_polar_np);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDdetach %d\n", status););
   }

   MESSAGE(6,printf("\t\tDetaching from grid IGoode\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid IGoode\n"););
   status = GDdetach(GDid_igoode);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_igoode);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_igoode);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDdetach %d\n", status););
   }

   MESSAGE(6,printf("\t\tDetaching from grid SOM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid SOM\n"););
   status = GDdetach(GDid_som);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_som);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_som);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDdetach %d\n", status););
   }

   MESSAGE(6,printf("\t\tDetaching from grid Lamaz\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid Lamaz\n"););
   status = GDdetach(GDid_lamaz);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_lamaz);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_lamaz);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDdetach %d\n", status););
   }

   MESSAGE(6,printf("\t\tDetaching from grid EASE\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid EASE\n"););
   status = GDdetach(GDid_ease);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_ease);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_ease);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDdetach %d\n", status););
   }

   MESSAGE(6,printf("\t\tDetaching from grid Geo\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid Geo\n"););
   status = GDdetach(GDid_geo);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_geo);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_geo);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDdetach %d\n", status););
   }

   MESSAGE(6,printf("\t\tDetaching from grid UTM2\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid UTM2\n"););
   status = GDdetach(GDid2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid2);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDdetach %d\n", status););
   }

/* Test Case -- GDclose
*/
   MESSAGE(4,printf("\f\tTesting GDclose... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDclose... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tClose grid UTM2 file\n"););
   MESSAGE(11,fprintf(fp,"\t\tClose grid UTM2 file\n"););
   status = GDclose(gdfid2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDclose(gdfid2);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDclose %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDclose(gdfid2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDclose %d\n", status););
   }

   MESSAGE(6,printf("\t\tClose grid UTM file\n"););
   MESSAGE(11,fprintf(fp,"\t\tClose grid UTM file\n"););
   status = GDclose(gdfid);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDclose(gdfid);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDclose %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDclose(gdfid);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDclose %d\n", status););
   }

   MESSAGE(6,printf("\t\tOpen Gridc_Test.hdf file\n"););
   MESSAGE(11,fprintf(fp,"\t\tOpen Gridc_Test.hdf file\n"););
   gdfid=GDopen("Gridc_Test.hdf", DFACC_RDWR);
   if (gdfid == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tgdfid=GDopen(\"Gridc_Test.hdf\", DFACC_RDWR);\n"););
      MESSAGE(8,printf("\t\tFile handle returned by GDopen %d\n", gdfid););
      MESSAGE(11,fprintf(fp,"\t\tgdfid=GDopen(\"Gridc_Test.hdf\", DFACC_RDWR);\n"););
      MESSAGE(11,fprintf(fp,"\t\tFile handle returned by GDopen %d\n", gdfid););
   }

   MESSAGE(6,printf("\t\tAttach to UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttach to UTM\n"););
   GDid_utm=GDattach(gdfid, "UTM");
   if (GDid_utm == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_utm=GDattach(gdfid, \"UTM\");\n"););
      MESSAGE(8,printf("\t\tGrid id returned by GDattach %d\n", GDid_utm););
      MESSAGE(11,fprintf(fp,"\t\tGDid_utm=GDattach(gdfid, \"UTM\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tGrid id returned by GDattach %d\n", GDid_utm););
   }

   MESSAGE(6,printf("\t\tAttach to Polar\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttach to Polar\n"););
   gdid_polar_np=GDattach(gdfid, "Polar_np");
   if (gdid_polar_np == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tgdid_polar_np=GDattach(gdfid, \"Polar_np\");\n"););
      MESSAGE(8,printf("\t\tGrid id returned by GDattach %d\n", gdid_polar_np););
      MESSAGE(11,fprintf(fp,"\t\tgdid_polar_np=GDattach(gdfid, \"Polar_np\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tGrid id returned by GDattach %d\n", gdid_polar_np););
   }

   MESSAGE(6,printf("\t\tAttach to UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttach to UTM\n"););
   status = GDdetach(GDid_utm); /* Abe Taaheri added to avoid memory leaks */
   GDid_utm=GDattach(gdfid, "UTM");
   if (GDid_utm == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_utm=GDattach(gdfid, \"UTM\");\n"););
      MESSAGE(8,printf("\t\tGrid id returned by GDattach %d\n", GDid_utm););
      MESSAGE(11,fprintf(fp,"\t\tGDid_utm=GDattach(gdfid, \"UTM\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tGrid id returned by GDattach %d\n", GDid_utm););
   }

/* Test Case -- GDinqgrid
*/
   MESSAGE(4,printf("\f\tTesting GDinqgrid... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDinqgrid... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   MESSAGE(6,printf("\t\tRetrieve information about grid file Gridc_Test.hdf\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve information about grid file Gridc_Test.hdf\n"););
   tmpvar=GDinqgrid("Gridc_Test.hdf", NULL, &tmpvar1);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDinqgrid(\"Gridc_Test.hdf\", NULL, &tmpvar1);\n"););
      MESSAGE(8,printf("\t\tNumber of objects in file Gridc_Test.hdf %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDinqgrid(\"Gridc_Test.hdf\", NULL, &tmpvar1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tNumber of objects in file Gridc_Test.hdf %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDinqgrid(\"Gridc_Test.hdf\", NULL, &tmpvar1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tSize of object list buffer Gridc_Test.hdf %d\n",tmpvar1););
   }
   
   buffer1=(char *)calloc(tmpvar1 + 1, 1);
   tmpvar=GDinqgrid("Gridc_Test.hdf", buffer1, &tmpvar1);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(8,printf("\t\tList of grids in file %s\n",buffer1););
      MESSAGE(11,fprintf(fp,"\t\tList of grids in file %s\n",buffer1););
   }

   free(buffer1);
   
/* Test Case -- GDcompinfo
*/
   MESSAGE(4,printf("\f\tTesting GDcompinfo... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDcompinfo... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   MESSAGE(6,printf("\t\tRetrieve compression information for field Impedance\n"););
   status = GDcompinfo(GDid_utm, "Impedance", &compcode, compparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDcompinfo(GDid_utm, \"Impedance\", &compcode, compparm);\n"););
      MESSAGE(8,printf("\t\tStatus returned by GDcompinfo %d\n",status););
      MESSAGE(8,printf("\t\tCompression code for field Impedance %d\n",compcode););
      MESSAGE(8,printf("\t\tCompression parameters for field Impedance %d %d %d\n",compparm[0],compparm[1],compparm[2]););
      MESSAGE(11,printf("\t\tstatus = GDcompinfo(GDid_utm, \"Impedance\", &compcode, compparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by GDcompinfo %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tCompression code for field Impedance %d\n",compcode););
      MESSAGE(11,fprintf(fp,"\t\tCompression parameters for field Impedance %d %d %d\n",compparm[0],compparm[1],compparm[2]););
   }

 
/* Test Case -- GDtileinfo
*/
   MESSAGE(4,printf("\f\tTesting GDtileinfo... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDtileinfo... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   MESSAGE(6,printf("\t\tRetrieve information on tiled field(s)\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve information on tiled field(s)\n"););
   status = GDtileinfo(gdid_polar_np, "SideB", &tilecode, &tilerank, tilecords);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDtileinfo(gdid_polar_np, \"SideB\", &tilecode, &tilerank, tilecords);\n"););
      MESSAGE(8,printf("\t\tStatus returned by call to GDtileinfo %d\n", status ););
      MESSAGE(8,printf("\t\tTile rank %d, Tile Code %d, tile dims %d %d\n",tilecode,tilerank,tilecords[0],tilecords[1]););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDtileinfo(gdid_polar_np, \"SideB\", &tilecode, &tilerank, tilecords);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by call to GDtileinfo %d\n", status ););
      MESSAGE(11,fprintf(fp,"\t\tTile rank %d, Tile Code %d, tile dims %d %d\n",tilecode,tilerank,tilecords[0],tilecords[1]););
   }

/* Test Case -- GDreadtile
*/
   MESSAGE(4,printf("\f\tTesting GDreadtile... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDreadtile... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   tilecords[0] = 3;
   tilecords[1] = 3;
   MESSAGE(6,printf("\t\tReading from tile field SideB\n"););
   MESSAGE(11,fprintf(fp,"\t\tReading from tile field SideB\n"););
   status = GDreadtile(gdid_polar_np, "SideB",tilecords,tilebuffer);

   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDreadtile(gdid_polar_np, \"SideB\",tilecords,tilebuffer);\n"););
      MESSAGE(8,printf("\t\tStatus returned by call to GDreadtile %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDreadtile(gdid_polar_np, \"SideB\",tilecords,tilebuffer);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by call to GDreadtile %d\n",status););
   for(ii=0;ii<15;ii++)
   {
      for(j=0;j<16;j++)
      {
         MESSAGE(8,printf("\t\tSideB value at %d %d = %f\n",ii,j,tilebuffer[ii][j]););
         MESSAGE(11,fprintf(fp,"\t\tSideB value at %d %d = %f\n",ii,j,tilebuffer[ii][j]););
      }
   }
   }
   


   MESSAGE(6,printf("\t\tDetaching from grid Polar\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid Polar\n"););
   status = GDdetach(gdid_polar_np);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(gdid_polar_np);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(gdid_polar_np);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by GDdetach %d\n", status););
   }

/* Test Case -- GDinqdims
*/
   MESSAGE(4,printf("\f\tTesting GDinqdims... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDinqdims... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tRetrieve information about dimensions in grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve information about dimensions in grid\n"););
   tmpvar=GDinqdims(GDid_utm, tmpstr,tempvar1);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDinqdims(GDid_utm, tmpstr,tempvar1);\n"););
      MESSAGE(8,printf("\t\tNumber of dimensions %d\n",tmpvar););
      MESSAGE(8,printf("\t\tDimension(s) in grid %s\n",tmpstr););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDinqdims(GDid_utm, tmpstr,tempvar1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tNumber of dimensions %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\tDimension(s) in grid %s\n",tmpstr););
   }
   

/* Test Case -- GDdiminfo
*/
   MESSAGE(4,printf("\f\tTesting GDdiminfo... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDdiminfo... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tRetrieve dimension information for field Conduction\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve dimension information for field Conduction\n"););
   tmpvar=GDdiminfo(GDid_utm, "Conduction");
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDdiminfo(GDid_utm, \"Conduction\");\n"););
      MESSAGE(8,printf("\t\tSize of dimension Conduction %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDdiminfo(GDid_utm, \"Conduction\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tSize of dimension Conduction %d\n",tmpvar););
   }


/* Test Case -- GDgridinfo
*/
   MESSAGE(4,printf("\f\tTesting GDgridinfo... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDgridinfo... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tRetrieve position and size of grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve position and size of grid\n"););
   tmpvar=GDgridinfo(GDid_utm, &tmpvar1,&tmpvar2,iuplft,ilowrgt);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDgridinfo(GDid_utm, &tmpvar1,&tmpvar2,iuplft,ilowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDgridinfo %d\n",tmpvar););
      MESSAGE(8,printf("\t\tXDim size %d  YDim size %d\n",tmpvar1,tmpvar2););
      MESSAGE(8,printf("\t\tUpper left point %f %f\n",iuplft[0],iuplft[1]););
      MESSAGE(8,printf("\t\tLower right point %f %f\n",ilowrgt[0],ilowrgt[1]););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDgridinfo(GDid_utm, &tmpvar1,&tmpvar2,iuplft,ilowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDgridinfo %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\tXDim size %d  YDim size %d\n",tmpvar1,tmpvar2););
      MESSAGE(11,fprintf(fp,"\t\tUpper left point %f %f\n",iuplft[0],iuplft[1]););
      MESSAGE(11,fprintf(fp,"\t\tLower right point %f %f\n",ilowrgt[0],ilowrgt[1]););
   }


/* Test Case -- GDprojinfo
*/
   MESSAGE(4,printf("\f\tTesting GDprojinfo... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDprojinfo... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tRetrieve projection,zone and spheroid codes and projection parameters\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve projection,zone and spheroid codes and projection parameters\n"););
   tmpvar=GDprojinfo(GDid_utm,&tmpvar1,&tmpvar2,&tmpvar3,iprojparm);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDprojinfo(GDid_utm,&tmpvar1,&tmpvar2,&tmpvar3,iprojparm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDprojinfo %d\n",tmpvar););
      MESSAGE(8,printf("\t\tprojcode, zcode and scode %d %d %d \n",tmpvar1,tmpvar2,tmpvar3););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDprojinfo(GDid_utm,&tmpvar1,&tmpvar2,&tmpvar3,iprojparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDprojinfo %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\tprojcode, zcode and scode %d %d %d \n",tmpvar1,tmpvar2,tmpvar3););
   }


/* Test Case -- GDorigininfo
*/
   MESSAGE(4,printf("\f\tTesting GDorigininfo... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDorigininfo... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
 
   MESSAGE(6,printf("\t\tRetrieve origin information\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve origin information\n"););
   tmpvar=GDorigininfo(GDid_utm, &tmpvar1);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDorigininfo(GDid_utm, &tmpvar1);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDorigininfo %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDorigininfo(GDid_utm, &tmpvar1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDorigininfo %d\n",tmpvar););
   }


/* Test Case -- GDpixreginfo
*/
   MESSAGE(4,printf("\f\tTesting GDpixreginfo... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDpixreginfo... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   MESSAGE(6,printf("\t\tRetrieve pixel registration code\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve pixel registration code\n"););
   tmpvar=GDpixreginfo(GDid_utm, &tmpvar1);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDpixreginfo(GDid_utm, &tmpvar1);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDpixreginfo %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDpixreginfo(GDid_utm, &tmpvar1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDpixreginfo %d\n",tmpvar););
   }

 
/* Test Case -- GDinqfields
*/
   MESSAGE(4,printf("\f\tTesting GDinqfields... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDinqfields... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   MESSAGE(6,printf("\t\tRetrieve information on data fields\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve information on data fields\n"););
   tmpvar=GDinqfields(GDid_utm, tmpstr, tempvar1, tempvar2);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDinqfields(GDid_utm, tmpstr, tempvar1, tempvar2);\n"););
      MESSAGE(8,printf("\t\tNumber of data fields in grid %d\n",tmpvar););
      MESSAGE(8,printf("\t\tList of fields in grid %s\n",tmpstr););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDinqfields(GDid_utm, tmpstr, tempvar1, tempvar2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tNumber of data fields in grid %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\tList of fields in grid %s\n",tmpstr););
   }


/* Test Case -- GDfieldinfo
*/
   MESSAGE(4,printf("\f\tTesting GDfieldinfo... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDfieldinfo... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   MESSAGE(6,printf("\t\tRetrieve information for field Drift\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve information for field Drift\n"););
   tmpvar=GDfieldinfo(GDid_utm, "Drift", &tmpvar1,ray,&tmpvar3,tmpstr);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDfieldinfo(GDid_utm, \"Drift\", &tmpvar1,ray,&tmpvar3,tmpstr);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDfieldinfo %d\n",tmpvar););
      MESSAGE(8,printf("\t\tRank %d, Dimensions %d %d\n",tmpvar1,ray[0], ray[1]););
      MESSAGE(8,printf("\t\tNumber type of field %d\n",tmpvar3););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDfieldinfo(GDid_utm, \"Drift\", tmpvar1,tmpvar2,tmpvar3,tmpstr);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDfieldinfo %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\tRank %d, Dimensions %d %d\n",tmpvar1,ray[0], ray[1]););
      MESSAGE(11,fprintf(fp,"\t\tNumber type of field %d\n",tmpvar3););
   }


/* Test Case -- GDreadfield
*/
   MESSAGE(4,printf("\f\tTesting GDreadfield... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDreadfield... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   MESSAGE(6,printf("\t\tRetrieve data values from field Drift\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve data values from field Drift\n"););
   tmpvar=GDreadfield(GDid_utm, "Drift", NULL,NULL,NULL,utmray);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDreadfield(GDid_utm, \"Drift\", NULL,NULL,NULL,utmray);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDreadfield %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDreadfield(GDid_utm, \"Drift\", NULL,NULL,NULL,utmray);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDreadfield %d\n",tmpvar););
      for(ii=10;ii<20;ii++)
      {
         for(j=10;j<15;j++)
         {
            MESSAGE(8,printf("\t\tDrift value at %d %d = %f\n",ii,j,utmray[ii][j]););
            MESSAGE(11,fprintf(fp,"\t\tDrift value at %d %d = %f\n",ii,j,utmray[ii][j]););
         }
      }
   }
 

/* Test Case -- GDnentries
*/
   MESSAGE(4,printf("\f\tTesting GDnentries... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDnentries... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   MESSAGE(6,printf("\t\tRetrieving dimension(s) in grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieving dimension(s) in grid\n"););
   tmpvar=GDnentries(GDid_utm, HDFE_NENTDIM, &tmpvar1);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDnentries(GDid_utm, HDFE_NENTDIM, &tmpvar1);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDnentries %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDnentries(GDid_utm, HDFE_NENTDIM, &tmpvar1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDnentries %d\n",tmpvar););
   }

   MESSAGE(6,printf("\t\tRetrieving Data Field(s) in grid\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieving Data Field(s) in grid\n"););
   tmpvar=GDnentries(GDid_utm, HDFE_NENTDFLD, &tmpvar1);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDnentries(GDid_utm, HDFE_NENTDFLD, &tmpvar1);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDnentries %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDnentries(GDid_utm, HDFE_NENTDFLD, &tmpvar1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDnentries %d\n",tmpvar););
   }


/* Test Case -- GDinqattrs
*/
   MESSAGE(4,printf("\f\tTesting GDinqattrs... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDinqattrs... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   MESSAGE(6,printf("\t\tRetrieve number of attributes\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve number of attributes\n"););
   tmpvar=GDinqattrs(GDid_utm, NULL, &tmpvar1);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDinqattrs(GDid_utm, NULL, &tmpvar1);\n"););
      MESSAGE(8,printf("\t\tNumber of objects in grid %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDinqattrs(GDid_utm, NULL, &tmpvar1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tNumber of objects in grid %d\n",tmpvar););
   }

   buffer2=(char *)calloc(tmpvar1 + 1, 1);
   MESSAGE(6,printf("\t\tRetrieve attributes information\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve attributes information\n"););
   tmpvar=GDinqattrs(GDid_utm, buffer2, &tmpvar1);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDinqattrs(GDid_utm, buffer2, &tmpvar1);\n"););
      MESSAGE(8,printf("\t\tAttributes in grid %s\n",buffer2););
      MESSAGE(8,printf("\t\tNumber of attributes in grid %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDinqattrs(GDid_utm, buffer2, &tmpvar1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tAttributes in grid %s\n",buffer2););
      MESSAGE(11,fprintf(fp,"\t\tNumber of attributes in grid %d\n",tmpvar););
   }
   free(buffer2);


/* Test Case -- GDattrinfo
*/
   MESSAGE(4,printf("\f\tTesting GDattrinfo... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDattrinfo... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   MESSAGE(6,printf("\t\tRetrieve information about attribute Resistance\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve information about attribute Resistance\n"););
   tmpvar=GDattrinfo(GDid_utm, "Resistance", &tmpvar1, &tmpvar2);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDattrinfo(GDid_utm, \"Resistance\", &tmpvar1, &tmpvar2);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDattrinfo %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDattrinfo(GDid_utm, \"Resistance\", &tmpvar1, &tmpvar2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDattrinfo %d\n",tmpvar););
   }


/* Test Case -- GDreadattr
*/
   MESSAGE(4,printf("\f\tTesting GDreadattr... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDreadattr... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   MESSAGE(6,printf("\t\tRetrieve data of attribute Resistance\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve data of attribute Resistance\n"););
   tmpvar=GDreadattr(GDid_utm, "Resistance", iattr);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDreadattr(GDid_utm, \"Resistance\", iattr);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDreadattr %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDreadattr(GDid_utm, \"Resistance\", iattr);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDreadattr %d\n",tmpvar););
      for(i=0;i<4;i++)
      {
         MESSAGE(8,printf("\t\tValue of attribute %d\n",iattr[i]););
         MESSAGE(11,fprintf(fp,"\t\tValue of attribute %d\n",iattr[i]););
      }
   }


/* Test Case -- GDgetfillvalue
*/
   MESSAGE(4,printf("\f\tTesting GDgetfillvalue... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDgetfillvalue... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   MESSAGE(6,printf("\t\tRetrieve fill value for field Voltage\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve fill value for field Voltage\n"););
   tmpvar=GDgetfillvalue(GDid_utm, "Voltage", &inqfill);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDgetfillvalue(GDid_utm, \"Voltage\", &inqfill);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDgetfillvalue %d\n",tmpvar););
      MESSAGE(8,printf("\t\tFill value in field Voltage %f\n",inqfill););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDgetfillvalue(GDid_utm, \"Voltage\", &inqfill);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDgetfillvalue %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\tFill value in field Voltage %f\n",inqfill););
   }


/* Test Case -- GDdefboxregion, GDregioninfo & GDextractregion
*/
   MESSAGE(4,printf("\f\tTesting GDdefboxregion, GDregioninfo & GDextractregion ... \n"););
   MESSAGE(4,printf("\t===========================================================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDdefboxregion, GDregioninfo & GDextractregion ... \n"););
   MESSAGE(11,fprintf(fp,"\t===========================================================\n"););

   corlon[0]=-123.5;
   corlon[1]=-121.5;
   corlat[0]=-67.0;
   corlat[1]=-70.0;

   MESSAGE(6,printf("\t\tDefine region to subset\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefine region to subset\n"););
   tmpvar=GDdefboxregion(GDid_utm,corlon, corlat);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDdefboxregion(GDid_utm,corlon, corlat);\n"););
      MESSAGE(8,printf("\t\tRegion id returned by GDdefboxregion %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDdefboxregion(GDid_utm,corlon, corlat);\n"););
      MESSAGE(11,fprintf(fp,"\t\tRegion id returned by GDdefboxregion %d\n",tmpvar););
   }


   MESSAGE(6,printf("\t\tRetrieve information about subset region\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve information about subset region\n"););
   tmpvar1=GDregioninfo(GDid_utm,tmpvar,"Impedance",&tmpvar2,&tmpvar3,tempvar1,&tmpvar4,iuplft,ilowrgt);
   if (tmpvar1 == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar1=GDregioninfo(GDid_utm,tmpvar,\"Impedance\",&tmpvar2,&tmpvar3,tempvar1,&tmpvar4,iuplft,ilowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDregioninfo %d\n",tmpvar1););
      MESSAGE(8,printf("\t\tNumber type of region %d rank of region %d\n",tmpvar2,tmpvar3););
      MESSAGE(8,printf("\t\tDimension of region %d %d Size of region in bytes %d\n",tempvar1[0],tempvar1[1],tmpvar4););
      MESSAGE(8,printf("\t\tUpper left point %f %f, Lower right point %f %f\n",iuplft[0],iuplft[1],ilowrgt[0],ilowrgt[1]););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar1=GDregioninfo(GDid_utm, tmpvar, \"Impedance\",&tmpvar2, &tmpvar3,tempvar1,&tmpvar4,iuplft,ilowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDregioninfo %d\n",tmpvar1););
      MESSAGE(11,fprintf(fp,"\t\tNumber type of region %d rank of region %d\n",tmpvar2,tmpvar3););
      MESSAGE(11,fprintf(fp,"\t\tDimension of region %d %d Size of region in bytes %d\n",tempvar1[0],tempvar1[1],tmpvar4););
      MESSAGE(11,fprintf(fp,"\t\tUpper left point %f %f, Lower right point %f %f\n",iuplft[0],iuplft[1],ilowrgt[0],ilowrgt[1]););
   }

   buffer=(float32 *)calloc(tmpvar4, 4);
   tmpvar1=GDextractregion(GDid_utm, tmpvar, "Impedance", buffer);
   if (tmpvar1 == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(8,printf("\t\tRegion id  returned by GDextractregion %d\n",tmpvar1););
      MESSAGE(11,fprintf(fp,"\t\tRegion id  returned by GDextractregion %d\n",tmpvar1););
      for(i=0;i<20; i++)
      {
         MESSAGE(8,printf("\t\tValue of buffer %f\n",buffer[i]););
         MESSAGE(11,fprintf(fp,"\t\tValue of buffer %f\n",buffer[i]););
      }
   }
   free(buffer);

/* Test Case -- GDdeftimeperiod
*/
   MESSAGE(4,printf("\f\tTesting GDdeftimeperiod... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDdeftimeperiod... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   starttime = 35233000.8;
   stoptime =  35435050.9;

   periodID = GDdeftimeperiod(GDid_utm,HDFE_NOPREVSUB, starttime, stoptime);
   if (periodID == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tperiodID = GDdeftimeperiod(GDid_utm,HDFE_NOPREVSUB, starttime, stoptime);\n"););
      MESSAGE(8,printf("\t\tPeriod ID returned by call to GDdeftimeperiod %d\n",periodID););
      MESSAGE(11,fprintf(fp,"\t\tPeriod ID returned by call to GDdeftimeperiod %d\n",periodID););
      MESSAGE(11,fprintf(fp,"\t\tperiodID = GDdeftimeperiod(GDid_utm,HDFE_NOPREVSUB, starttime, stoptime);\n"););
   }

/* Test Case -- GDdefvrtregion
*/
   MESSAGE(4,printf("\f\tTesting GDdefvrtregion... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDdefvrtregion... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   range[0] = 352.8;
   range[1] =  400.9;

   regionID = GDdefvrtregion(GDid_utm,HDFE_NOPREVSUB, "Height", range);
   if (regionID == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tregionID = GDdefvrtregion(GDid_utm,HDFE_NOPREVSUB, \"Height\", range);\n"););
      MESSAGE(8,printf("\t\tRegion ID returned by call to GDdefvrtregion %d\n",regionID););
      MESSAGE(11,fprintf(fp,"\t\tRegion ID returned by call to GDdefvrtregion %d\n",regionID););
      MESSAGE(11,fprintf(fp,"\t\tregionID = GDdefvrtregion(GDid_utm,HDFE_NOPREVSUB, \"Height\", range);\n"););
   }

/* Test Case -- GDdupregion
*/
   MESSAGE(4,printf("\f\tTesting GDdupregion... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDdupregion... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   regionID2 = GDdupregion(regionID);
   if (regionID2 == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tregionID2 = GDdupregion(regionID);\n"););
      MESSAGE(8,printf("\t\tRegion ID returned by call to GDdupregion %d\n",regionID2););
      MESSAGE(11,fprintf(fp,"\t\tRegion ID returned by call to GDdupregion %d\n",regionID2););
      MESSAGE(11,fprintf(fp,"\t\tregionID2 = GDdupregion(regionID);\n"););
   }


/* Test Case -- GDgetpixels
*/
   MESSAGE(4,printf("\f\tTesting GDgetpixels... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDgetpixels... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   lonval[0] = -122.0;
   latval[0] = -68.0;
   lonval[1] = -122.5;
   latval[1] = -68.0;
   lonval[2] = -123.0;
   latval[2] = -68.0;
   lonval[3] = -123.5;
   latval[3] = -68.0;
   lonval[4] = -124.0;
   latval[4] = -68.0;

   status = GDgetpixels(GDid_utm,5,lonval,latval,rowval,colval);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(8,printf("\t\tStatus returned by GDgetpixels call %d\n",status););
      MESSAGE(10,printf("\t\tstatus = GDgetpixels(GDid_utm,5,lonval,latval,rowval,colval);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by GDgetpixels call %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDgetpixels(GDid_utm,5,lonval,latval,rowval,colval);\n"););
      for(i=0;i<5;i++)
      {
         MESSAGE(10,printf("\t\tRow Column of pixel %d = %d %d\n",i,rowval[i],colval[i]););
         MESSAGE(11,fprintf(fp,"\t\tRow Column of pixel %d = %d %d\n",i,rowval[i],colval[i]););
      }
   }



/* Test Case -- GDgetpixvalues
*/
   MESSAGE(4,printf("\f\tTesting GDgetpixvalues... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDgetpixvalues... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   bufsiz = GDgetpixvalues(GDid_utm,5,rowval,colval,"Drift",NULL);
   if (bufsiz == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(8,printf("\t\tBuffer size returned by GDgetpixvalues %d\n",bufsiz););
      MESSAGE(11,fprintf(fp,"\t\tBuffer size returned by GDgetpixvalues %d\n",bufsiz););
   }

   datbuf2 = (float32 *)calloc(bufsiz,4);
   bufsiz = GDgetpixvalues(GDid_utm,5,rowval,colval,"Drift",datbuf2);
   if (bufsiz == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
     MESSAGE(8,printf("\t\tBuffer size returned by GDgetpixvalues %d\n",bufsiz););
      for(i=0;i<5;i++)
      {
         MESSAGE(8,printf("\t\tValue of getpixvalues buffer %f\n",datbuf2[i]););
         MESSAGE(11,fprintf(fp,"\t\tValue of getpixvalues buffer %f\n",datbuf2[i]););
      }
   }


   free(datbuf2);

/* Test Case -- GDinterpolate
*/
   MESSAGE(4,printf("\f\tTesting GDinterpolate... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDinterpolate... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   lonval[0] = -122.0;
   latval[0] = -68.0;
   lonval[1] = -122.5;
   latval[1] = -68.0;
   lonval[2] = -123.0;
   latval[2] = -68.0;
   lonval[3] = -123.5;
   latval[3] = -68.0;
   lonval[4] = -124.0;
   latval[4] = -68.0;

   bufsiz = GDinterpolate(GDid_utm,5,lonval,latval,"Drift",NULL);
   if (bufsiz == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tbufsiz = GDinterpolate(GDid_utm,5,lonval,latval,\"Drift\",NULL);\n"););
      MESSAGE(8,printf("\t\tBuffer size returned by GDinterpolate %d\n",bufsiz););
      MESSAGE(11,fprintf(fp,"\t\tbufsiz = GDinterpolate(GDid_utm,5,lonval,latval,\"Drift\",NULL);\n"););
      MESSAGE(11,fprintf(fp,"\t\tBuffer size returned by GDinterpolate %d\n",bufsiz););
   }

   datbuf = (float64 *)calloc(bufsiz,8);
   bufsiz = GDinterpolate(GDid_utm,5,lonval,latval,"Drift",datbuf);
   if (bufsiz == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tbufsiz = GDinterpolate(GDid_utm,5,lonval,latval,\"Drift\",datbuf);\n"););
      MESSAGE(8,printf("\t\tBuffer size returned by GDinterpolate %d\n",bufsiz););
      MESSAGE(11,fprintf(fp,"\t\tbufsiz = GDinterpolate(GDid_utm,5,lonval,latval,\"Drift\",datbuf);\n"););
      MESSAGE(11,fprintf(fp,"\t\tBuffer size returned by GDinterpolate %d\n",bufsiz););
      for(i=0;i<5;i++)
      {
         MESSAGE(8,printf("\t\tValue of interpolate buffer %f\n",(float32) datbuf[i]););
         MESSAGE(11,fprintf(fp,"\t\tValue of interpolate buffer %f\n",(float32) datbuf[i]););
      }
   }

   free(datbuf);

   printf("\n\n");

   lonval[0] = -125.0;
   latval[0] = -68.0;
   lonval[1] = -125.5;
   latval[1] = -68.0;
   lonval[2] = -126.0;
   latval[2] = -68.0;
   lonval[3] = -126.5;
   latval[3] = -68.0;
   lonval[4] = -127.0;
   latval[4] = -68.0;

   bufsiz = GDinterpolate(GDid_utm,5,lonval,latval,"Drift",NULL);
   if (bufsiz == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tbufsiz = GDinterpolate(GDid_utm,5,lonval,latval,\"Drift\",NULL);\n"););
      MESSAGE(8,printf("\t\tBuffer size returned by GDinterpolate %d\n",bufsiz););
      MESSAGE(11,fprintf(fp,"\t\tbufsiz = GDinterpolate(GDid_utm,5,lonval,latval,\"Drift\",NULL);\n"););
      MESSAGE(11,fprintf(fp,"\t\tBuffer size returned by GDinterpolate %d\n",bufsiz););
   }

   datbuf = (float64 *)calloc(bufsiz,8);
   bufsiz = GDinterpolate(GDid_utm,5,lonval,latval,"Drift",datbuf);
   if (bufsiz == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tbufsiz = GDinterpolate(GDid_utm,5,lonval,latval,\"Drift\",datbuf);\n"););
      MESSAGE(8,printf("\t\tBuffer size returned by GDinterpolate %d\n",bufsiz););
      MESSAGE(11,fprintf(fp,"\t\tbufsiz = GDinterpolate(GDid_utm,5,lonval,latval,\"Drift\",datbuf);\n"););
      MESSAGE(11,fprintf(fp,"\t\tBuffer size returned by GDinterpolate %d\n",bufsiz););
      for(i=0;i<5;i++)
      {
         MESSAGE(8,printf("\t\tValue of interpolate buffer %f\n",(float32) datbuf[i]););
         MESSAGE(11,fprintf(fp,"\t\tValue of interpolate buffer %f\n",(float32) datbuf[i]););
      }
   }

   free(datbuf);

   MESSAGE(6,printf("\t\tDetaching from grid UTM\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid UTM\n"););
   status = GDdetach(GDid_utm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_utm);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_utm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDdetach %d\n", status););
   }



   MESSAGE(11,fprintf(fp,"\f \n"););
   MESSAGE(6,printf("\t\tAttaching to grid Polar\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to grid Polar\n"););
   gdid_polar_np = GDattach(gdfid, "Polar_np");
   if (gdid_polar_np == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tgdid_polar_np = GDattach(gdfid, \"Polar_np\");\n"););
      MESSAGE(8,printf("\t\tValue returned by GDattach %d\n\n", gdid_polar_np););
      MESSAGE(11,fprintf(fp,"\t\tgdid_polar_np = GDattach(gdfid, \"Polar_np\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDattach %d\n\n", gdid_polar_np););
   }

   corlon[0]=-20.0;
   corlon[1]= 25.0;
   corlat[0]= 45.0;
   corlat[1]= 74.0;

   MESSAGE(6,printf("\t\tDefine region to subset\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefine region to subset\n"););
   tmpvar=GDdefboxregion(gdid_polar_np,corlon, corlat);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDdefboxregion(gdid_polar_np,corlon, corlat);\n"););
      MESSAGE(8,printf("\t\tRegion id returned by GDdefboxregion %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDdefboxregion(gdid_polar_np,corlon, corlat);\n"););
      MESSAGE(11,fprintf(fp,"\t\tRegion id returned by GDdefboxregion %d\n",tmpvar););
   }

   MESSAGE(6,printf("\t\tRetrieve information about subset region\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve information about subset region\n"););
   tmpvar1=GDregioninfo(gdid_polar_np,tmpvar,"Bypass",&tmpvar2,&tmpvar3,tempvar1,&tmpvar4,iuplft,ilowrgt);
   if (tmpvar1 == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar1=GDregioninfo(gdid_polar_np,tmpvar,\"Bypass\",&tmpvar2,&tmpvar3,tempvar1,&tmpvar4,iuplft,ilowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDregioninfo %d\n",tmpvar1););
      MESSAGE(8,printf("\t\tNumber type of region %d rank of region %d\n",tmpvar2,tmpvar3););
      MESSAGE(8,printf("\t\tDimension of region %d %d Size of region in bytes %d\n",tempvar1[0],tempvar1[1],tmpvar4););
      MESSAGE(8,printf("\t\tUpper left point %f %f, Lower right point %f %f\n",iuplft[0],iuplft[1],ilowrgt[0],ilowrgt[1]););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar1=GDregioninfo(gdid_polar_np, tmpvar, \"Bypass\",&tmpvar2, &tmpvar3,tempvar1,&tmpvar4,iuplft,ilowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDregioninfo %d\n",tmpvar1););
      MESSAGE(11,fprintf(fp,"\t\tNumber type of region %d rank of region %d\n",tmpvar2,tmpvar3););
      MESSAGE(11,fprintf(fp,"\t\tDimension of region %d %d Size of region in bytes %d\n",tempvar1[0],tempvar1[1],tmpvar4););
      MESSAGE(11,fprintf(fp,"\t\tUpper left point %f %f, Lower right point %f %f\n",iuplft[0],iuplft[1],ilowrgt[0],ilowrgt[1]););
   }

/* Test Case -- GDwritefieldmeta
*/
   MESSAGE(4,printf("\f\tTesting GDwritefieldmeta... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDwritefieldmeta... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

   status = GDwritefieldmeta(gdid_polar_np,"Externfield","XDim,YDim",DFNT_INT16);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(8,printf("\t\tStatus returned from call to GDwritefieldmeta %d\n",status););
      MESSAGE(10,printf("\t\tstatus = GDwritefieldmeta(gdid_polar_np,\"Externfield\",\"XDim,YDim\",DFNT_INT16);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned from call to GDwritefieldmeta %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDwritefieldmeta(gdid_polar_np,\"Externfield\",\"XDim,YDim\",DFNT_INT16);\n"););
   }


   MESSAGE(6,printf("\t\tDetaching from grid PolarGrid\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid PolarGrid\n"););
   status = GDdetach(gdid_polar_np);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(gdid_polar_np);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(gdid_polar_np);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }

   MESSAGE(6,printf("\t\tAttaching to grid EASE\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to grid EASE\n"););
   GDid_ease = GDattach(gdfid, "Ease");
   if (GDid_ease == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_ease = GDattach(gdfid, \"Ease\");\n"););
      MESSAGE(8,printf("\t\tValue returned by GDattach %d\n\n", GDid_ease););
      MESSAGE(11,fprintf(fp,"\t\tGDid_ease = GDattach(gdfid, \"Ease\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDattach %d\n\n", GDid_ease););
   }
   corlon[0]=-180.0;
   corlon[1]= 0.0;
   corlat[0]= 86.72;
   corlat[1]= 0.0;

   MESSAGE(6,printf("\t\tDefine region to subset\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefine region to subset\n"););
   tmpvar=GDdefboxregion(GDid_ease,corlon, corlat);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error Unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error Unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDdefboxregion(GDid_ease,corlon, corlat);\n"););
      MESSAGE(8,printf("\t\tRegion id returned by GDdefboxregion %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDdefboxregion(GDid_ease,corlon, corlat);\n"););
      MESSAGE(11,fprintf(fp,"\t\tRegion id returned by GDdefboxregion %d\n",tmpvar););
   }

   MESSAGE(6,printf("\t\tRetrieve information about subset region\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve information about subset region\n"););
   tmpvar1=GDregioninfo(GDid_ease,tmpvar,"Intensity",&tmpvar2,&tmpvar3,tempvar1,&tmpvar4,iuplft,ilowrgt);
   if (tmpvar1 == -1)
   {
      MESSAGE(4,printf("\t\t********Error Unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error Unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar1=GDregioninfo(GDid_ease,tmpvar,\"Intensity\",&tmpvar2,&tmpvar3,tempvar1,&tmpvar4,iuplft,ilowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDregioninfo %d\n",tmpvar1););
      MESSAGE(8,printf("\t\tNumber type of region %d rank of region %d\n",tmpvar2,tmpvar3););
      MESSAGE(8,printf("\t\tDimension of region %d %d Size of region in bytes %d\n",tempvar1[0],tempvar1[1],tmpvar4););
      MESSAGE(8,printf("\t\tUpper left point %f %f, Lower right point %f %f\n",iuplft[0],iuplft[1],ilowrgt[0],ilowrgt[1]););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar1=GDregioninfo(GDid_ease, tmpvar, \"Intensity\",&tmpvar2, &tmpvar3,tempvar1,&tmpvar4,iuplft,ilowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDregioninfo %d\n",tmpvar1););
      MESSAGE(11,fprintf(fp,"\t\tNumber type of region %d rank of region %d\n",tmpvar2,tmpvar3););
      MESSAGE(11,fprintf(fp,"\t\tDimension of region %d %d Size of region in bytes %d\n",tempvar1[0],tempvar1[1],tmpvar4););
   }


   MESSAGE(6,printf("\n\t\tAttaching to grid Geo\n"););
   MESSAGE(11,fprintf(fp,"\n\t\tAttaching to grid Geo\n"););
   GDid_geo = GDattach(gdfid, "Geo");
   if (GDid_geo == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tGDid_geo = GDattach(gdfid, \"Geo\");\n"););
      MESSAGE(8,printf("\t\tValue returned by GDattach %d\n\n", GDid_geo););
      MESSAGE(11,fprintf(fp,"\t\tGDid_geo = GDattach(gdfid, \"Geo\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tHandle returned from GDattach %d\n\n", GDid_geo););
   }

   corlon[0]=-123.5;
   corlon[1]=-121.5;
   corlat[0]=-67.0;
   corlat[1]=-70.0;

   MESSAGE(6,printf("\t\tDefine region to subset\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefine region to subset\n"););
   tmpvar=GDdefboxregion(GDid_geo,corlon, corlat);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error Unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error Unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=GDdefboxregion(GDid_geo,corlon, corlat);\n"););
      MESSAGE(8,printf("\t\tRegion id returned by GDdefboxregion %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=GDdefboxregion(GDid_geo,corlon, corlat);\n"););
      MESSAGE(11,fprintf(fp,"\t\tRegion id returned by GDdefboxregion %d\n",tmpvar););
   }

   MESSAGE(6,printf("\t\tRetrieve information about subset region\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve information about subset region\n"););
   tmpvar1=GDregioninfo(GDid_geo,tmpvar,"Depth",&tmpvar2,&tmpvar3,tempvar1,&tmpvar4,iuplft,ilowrgt);
   if (tmpvar1 == -1)
   {
      MESSAGE(4,printf("\t\t********Error Unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error Unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar1=GDregioninfo(GDid_geo,tmpvar,\"Depth\",&tmpvar2,&tmpvar3,tempvar1,&tmpvar4,iuplft,ilowrgt);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDregioninfo %d\n",tmpvar1););
      MESSAGE(8,printf("\t\tNumber type of region %d rank of region %d\n",tmpvar2,tmpvar3););
      MESSAGE(8,printf("\t\tDimension of region %d %d Size of region in bytes %d\n",tempvar1[0],tempvar1[1],tmpvar4););
      MESSAGE(8,printf("\t\tUpper left point %f %f, Lower right point %f %f\n",iuplft[0],iuplft[1],ilowrgt[0],ilowrgt[1]););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar1=GDregioninfo(GDid_geo, tmpvar, \"Depth\",&tmpvar2, &tmpvar3,tempvar1,&tmpvar4,iuplft,ilowrgt);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDregioninfo %d\n",tmpvar1););
      MESSAGE(11,fprintf(fp,"\t\tNumber type of region %d rank of region %d\n",tmpvar2,tmpvar3););
      MESSAGE(11,fprintf(fp,"\t\tDimension of region %d %d Size of region in bytes %d\n",tempvar1[0],tempvar1[1],tmpvar4););
   }

   MESSAGE(6,printf("\t\tDetaching from grid Geo\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from grid Geo \n"););
   status = GDdetach(GDid_geo);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDdetach(GDid_geo);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDdetach %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDdetach(GDid_geo);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned value from GDdetach %d\n\n", status););
   }
 
   MESSAGE(6,printf("\t\tClose grid file\n"););
   MESSAGE(11,fprintf(fp,"\t\tClose grid file\n"););
   status = GDdetach(GDid_ease);
   /*status = GDdetach(GDid3);*/ /* Abe Taaheri added to avoid memory leaks */
   status = GDclose(gdfid);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDclose(gdfid);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDclose %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = GDclose(gdfid);\n"););
      MESSAGE(11,fprintf(fp,"\t\tReturned from GDclose %d\n", status););
   }

/* Test Case -- GDrs2ll
*/
   uplft[0] = EHconvAng(-180.0, HDFE_DEG_DMS);
   uplft[1] = EHconvAng(86.72, HDFE_DEG_DMS);
   lowrgt[0] = EHconvAng( 180.0,HDFE_DEG_DMS);
   lowrgt[1] = EHconvAng( -86.72,HDFE_DEG_DMS);
   npnts = 4;
   rcord[0]=0.;
   scord[0]=0.;
   rcord[1]=0.; 
   scord[1]=293.;
   rcord[2]=691.5; 
   scord[2]=0.;
   rcord[3]=691.5; 
   scord[3]=293.;
   xdimsize = xdim_ease;   
   ydimsize = ydim_ease;
   MESSAGE(4,printf("\f\tTesting GDrs2ll for EASE grid... \n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting GDrs2ll for EASE grid... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););
   status = GDrs2ll(GCTP_BCEA, projparm,
		    xdimsize, ydimsize,
		    uplft, lowrgt,
		    npnts, rcord, scord,
		    longitude, latitude, HDFE_CORNER, HDFE_GD_UL);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout, 0););
      MESSAGE(11,HEprint(fp, 0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = GDrs2ll(GCTP_BCEA, projparm, xdimsize, ydimsize, npnts, scord, rcord, longitude, latitude, HDFE_CORNER, HDFE_GD_UL);\n"););
      MESSAGE(8,printf("\t\tValue returned by GDrs2ll %d\n\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus =GDrs2ll(GCTP_BCEA, projparm, xdimsize, ydimsize, npnts, scord, rcord, longitude, latitude, HDFE_CORNER, HDFE_GD_UL);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by GDrs2ll %d\n\n", status););
	 for(i=0; i<4; i++)
	 {
	     
	     MESSAGE(8,printf("\t\tr[%d]=%f s[%d]=%f lon[%d]=%f lat[%d]=%f\n", i, rcord[i], i, scord[i], i, longitude[i], i,
			      latitude[i]););
	     MESSAGE(11,printf("\t\tr[%d]=%f s[%d]=%f lon[%d]=%f lat[%d]=%f\n", i, rcord[i], i, scord[i], i, longitude[i], i,
			      latitude[i]););
	 }
   }



   MESSAGE(11,fclose(fp););

   return 0;

}

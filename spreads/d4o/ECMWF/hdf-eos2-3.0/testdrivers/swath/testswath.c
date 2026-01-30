/*
	FILE
	testswath.c
	EOS-HDF swath testing file

*/

#include "tutils.h"
#include <stdio.h>
#include "mfhdf.h"
#include "HE2_config.h"
#include "HdfEosDef.h"

int main(int argc, char *argv[])
{
   int32	index1 = 0;
   int32	index2 = 0;
   int32	rank = 2;
   int32	dimsizes[2] = {100,40};
   float32	ray1[100][40], ray2[100][40];
   float32	fillvalue = 16.0;
   float32	raycnt = -799.0;
   float32	inqfill;
   float32	*datbuf;
   int		CLLoop, Verbosity;
   intn		status,ii,j;
   int32	sd_id, sds1_id, sds2_id, dim_id, i,k;
   int32	swfidc_test, swfid_1, swfid_2;
   int32	SWid_simple, SWid_start, SWid_64, SWid_lat; 
   int32	SWid_co, SWid_oned, SWid_index;
   int32	attr[4] = {11,33,66,99};
   int32	start[2] = {10, 10};
   int32	stride[2] = {1, 1};
   int32	edge[2] = {90, 30};
   int32	tstart[2] = {0, 0};
   int32	tedge[2] = {100, 40};
   int32	inqstart[2]={0,0};
   int32	inqstride[2]={1,1};
   int32	inqedge[2]={100,40};
   int32	strbufsize;
   int32	tmpvar,tmpvar2,tmpvar3,var1,var2,var3;
   int32	regionID;
   int32	ray[8];
   int32	*tempvar1, *tempvar2, *tempvar3;
   int32	*update_index1, *update_index3;
   int32	idxmapsize;
   int32	indicies[2];	/* index array for function SWupdateidxmap */
   int32        *ind[8];   /* index array for function SWindexinfo  */

   float	tmpray[100][40];
   char		*buffer1;
   char		dimlist[128];

   int32	sd_start[2] = {0, 0};
   int32	sd_stride[2] = {1, 1};
   int32	sd_edge[2] = {100, 40};

   float	lat[50][40];
   float	colat[50][40];
   float	onedlat[50];
   float64	lat2[100][40];
   float	latcnt = 39.8;
   float	lon[50][40];
   float64	lon2[100][40];
   float	onedlon[50];
   float	loncnt = 78.0;
   int32	indexmap[30] = {1,2,3,4,6,7,8,9,11,12,13,14,16,17,18,19,21,22,23,24,26, 27,28,29,32,33,34,36,37,38};
   float	idxlat[30][30];
   float	idxlatcnt = 39.8;
   float	idxlon[30][30];
   float	idxloncnt = 78.0;

   float64	onedtime[100];
   float64	twodtime[50][40];
   float64	*timebuf;
   float64	tmcnt;
   float64	corlon[2],corlat[2];
   float64	starttime, stoptime;
   float64	range[2];
   int32	compcode;
   intn		compparm[5];

   FILE *fp;
   Verbosity = 4;
   tmcnt = 46353400.0;

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
 

   while(index1 < 100) {
      while(index2 < 40) {
         ray1[index1][index2] = raycnt;
         ray2[index1][index2] = raycnt + .1;
         lat2[index1][index2] = latcnt;
         lon2[index1][index2] = loncnt;
         index2++;
         raycnt = raycnt + .1;
         loncnt = loncnt - .1;
      }
      latcnt = latcnt - .1;
      onedtime[index1] = tmcnt;
      loncnt = 78.0;
      index1++;
      index2 = 0;
      tmcnt=tmcnt+5.0;
   }

   latcnt = 39.8;
   loncnt = 78.0;
   index1 = 0;
   index2 = 0;
   tmcnt = 46353400.0;
 
   while(index1 < 50) {
      while(index2 < 40) {
         lat[index1][index2] = latcnt;
         colat[index1][index2] = latcnt + 90.0;
         lon[index1][index2] = loncnt;
         twodtime[index1][index2] = tmcnt;
         loncnt = loncnt - .1;
         tmcnt = tmcnt + 5.0;
         index2++;
      }
      latcnt = latcnt - .1;
      loncnt = 78.0;
      index1++;
      index2 = 0;
   }
   index1 = 0;
   index2 = 0;
   latcnt = 39.8;
   loncnt = 78.0;
 
   while(index1 < 50) {
      onedlat[index1] = latcnt;
      onedlon[index1] = loncnt;
      latcnt = latcnt - .1;
      loncnt = loncnt - .1;
      index1++;
   }

   index1 = 0;
   index2 = 0;
   latcnt = 39.8;
   loncnt = 78.0;
 
   while (index1 < 30) {
      while ( index2 < 30) {
         idxlat[index1][index2] = idxlatcnt;
         idxlon[index1][index2] = idxloncnt;
         idxloncnt = idxloncnt - .1;
         index2++;
      }
      idxlatcnt = idxlatcnt - .1;
      idxloncnt = 78.0;
      index1++;
      index2 = 0;
   }
 
   MESSAGE(11,fp=fopen("testswathc.txt","w"););

   MESSAGE(4,printf("Testing Swath C interface \n"););
   MESSAGE(4,printf("=========================\n\n"););

   MESSAGE(11,fprintf(fp,"Testing Swath C interface \n"););
   MESSAGE(11,fprintf(fp,"=========================\n\n"););

/* Test Case -- SWopen
*/
   MESSAGE(4,printf("\tTesting SWopen... \n"););
   MESSAGE(4,printf("\t=================\n"););
#ifndef VISUAL_CPLUSPLUS
   system("rm Swath_1.hdf");
   system("rm Swath_2.hdf");
#else
   system("del Swath_1.hdf");
   system("del Swath_2.hdf");
#endif
   MESSAGE(11,fprintf(fp,"\tTesting SWopen... \n"););
   MESSAGE(11,fprintf(fp,"\t=================\n"););

/* This call should fail because we are opening a file in the read mode
** but the file has never been created.
*/
   MESSAGE(6,printf("\t\tOpening file Swath_1.hdf in DFACC_READ mode\n"););
   MESSAGE(11,fprintf(fp,"\t\tOpening file Swath_1.hdf in DFACC_READ mode\n"););
   swfid_1=SWopen("Swath_1.hdf", DFACC_READ);
   if (swfid_1 == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tswfid_1=SWopen(\"Swath_1.hdf\", DFACC_READ);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWopen %d\n",swfid_1););
      MESSAGE(11,fprintf(fp,"\t\tswfid_1=SWopen(\"Swath_1.hdf\", DFACC_READ);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWopen %d\n",swfid_1););
   }

   MESSAGE(6,printf("\t\tOpening file Swath_2.hdf in DFACC_RDWR mode\n"););
   MESSAGE(11,fprintf(fp,"\t\tOpening file Swath_2.hdf in DFACC_RDWR mode\n"););
   swfid_2=SWopen("Swath_2.hdf", DFACC_RDWR);
   if (swfid_2 == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tswfid_2=SWopen(\"Swath_2.hdf\", DFACC_RDWR);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWopen %d\n",swfid_2););
      MESSAGE(11,fprintf(fp,"\t\tswfid_2=SWopen(\"Swath_2.hdf\", DFACC_RDWR);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWopen %d\n",swfid_2););
   }

   MESSAGE(6,printf("\t\tOpening file Swathc_Test.hdf \n"););
   MESSAGE(11,fprintf(fp,"\t\tOpening file Swathc_Test.hdf \n"););
   swfidc_test = SWopen("Swathc_Test.hdf", DFACC_CREATE);
   if (swfidc_test == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tswfidc_test = SWopen(\"Swathc_Test.hdf\", DFACC_CREATE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWopen %d\n",swfidc_test););
      MESSAGE(11,fprintf(fp,"\t\tswfidc_test = SWopen(\"Swathc_Test.hdf\", DFACC_CREATE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWopen %d\n",swfidc_test););
   }

/* Test Case -- SWcreate
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWcreate... \n"););
   MESSAGE(4,printf("\t===================\n"););

   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWcreate... \n"););
   MESSAGE(11,fprintf(fp,"\t===================\n"););

   MESSAGE(6,printf("\t\tCreating swath Start\n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating swath Start\n"););
   SWid_start=SWcreate(swfid_2, "Start");
   if (SWid_start == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_start=SWcreate(swfid_2, \"Start\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWcreate %d\n\n",SWid_start););
      MESSAGE(11,fprintf(fp,"\t\tSWid_start=SWcreate(swfid_2, \"Start\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWcreate %d\n\n",SWid_start););
   }

   MESSAGE(6,printf("\t\tCreating swath Simple \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating swath Simple \n"););
   SWid_simple = SWcreate(swfidc_test, "Simple");
   if (SWid_simple == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_simple = SWcreate(swfidc_test, \"Simple\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWcreate %d\n\n",SWid_simple););
      MESSAGE(11,fprintf(fp,"\t\tSWid_simple = SWcreate(swfidc_test, \"Simple\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWcreate %d\n\n",SWid_simple););
   }

   MESSAGE(6,printf("\t\tCreating swath Swath64 \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating swath Swath64 \n"););
   SWid_64 = SWcreate(swfidc_test, "Swath64");
   if (SWid_64 == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_64 = SWcreate(swfidc_test, \"Swath64\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWcreate %d\n\n",SWid_64););
      MESSAGE(11,fprintf(fp,"\t\tSWid_64 = SWcreate(swfidc_test, \"Swath64\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWcreate %d\n\n",SWid_64););
   }

   MESSAGE(6,printf("\t\tCreating swath SwathLatonly \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating swath SwathLatonly \n"););
   SWid_lat = SWcreate(swfidc_test, "SwathLatonly");
   if (SWid_lat == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_lat = SWcreate(swfidc_test, \"SwathLatonly\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWcreate %d\n\n",SWid_lat););
      MESSAGE(11,fprintf(fp,"\t\tSWid_lat = SWcreate(swfidc_test, \"SwathLatonly\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWcreate %d\n\n",SWid_lat););
   }

   MESSAGE(6,printf("\t\tCreating swath Swathco \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating swath Swathco \n"););
   SWid_co = SWcreate(swfidc_test, "Swathco");
   if (SWid_co == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_co = SWcreate(swfidc_test, \"Swathco\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWcreate %d\n\n",SWid_co););
      MESSAGE(11,fprintf(fp,"\t\tSWid_co = SWcreate(swfidc_test, \"Swathco\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWcreate %d\n\n",SWid_co););
   }

   MESSAGE(6,printf("\t\tCreating swath OnedGeo \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating swath OnedGeo \n"););
   SWid_oned = SWcreate(swfidc_test, "OnedGeo");
   if (SWid_oned == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_oned = SWcreate(swfidc_test, \"OnedGeo\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWcreate %d\n\n",SWid_oned););
      MESSAGE(11,fprintf(fp,"\t\tSWid_oned = SWcreate(swfidc_test, \"OnedGeo\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWcreate %d\n\n",SWid_oned););
   }

   MESSAGE(6,printf("\t\tCreating swath Index \n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating swath Index \n"););
   SWid_index = SWcreate(swfidc_test, "Index");
   if (SWid_index == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_index = SWcreate(swfidc_test, \"Index\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWcreate %d\n\n",SWid_index););
      MESSAGE(11,fprintf(fp,"\t\tSWid_index = SWcreate(swfidc_test, \"Index\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWcreate %d\n\n",SWid_index););
   }

/* Test Case -- SWdefdim
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWdefdim... \n"););
   MESSAGE(4,printf("\t===================\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWdefdim... \n"););
   MESSAGE(11,fprintf(fp,"\t===================\n"););

   MESSAGE(6,printf("\t\tSetting up dimensions for swath Start \n"););
   MESSAGE(6,printf("\t\tDefining dimension test in swath Start \n"););
   MESSAGE(11,fprintf(fp,"\t\tSetting up dimensions for swath Start \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension test in swath Start \n"););
   status = SWdefdim(SWid_start, "test", -10);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_start, \"test\", -10);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_start, \"test\", -10);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tSetting up dimensions for swath Simple \n"););
   MESSAGE(6,printf("\t\tDefining dimension DataTrack in swath Simple \n"););
   MESSAGE(11,fprintf(fp,"\t\tSetting up dimensions for swath Simple \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension DataTrack in swath Simple \n"););
   status = SWdefdim(SWid_simple, "DataTrack", 100);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_simple, \"DataTrack\", 100);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_simple, \"DataTrack\", 100);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension DataXtrack in swath Simple \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension DataXtrack in swath Simple \n"););
   status = SWdefdim(SWid_simple, "DataXtrack", 40);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_simple, \"DataXtrack\", 40);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_simple, \"DataXtrack\", 40);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension GeoTrack for swath Simple \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension GeoTrack for swath Simple \n"););
   status = SWdefdim(SWid_simple, "GeoTrack", 50);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_simple, \"GeoTrack\", 50);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_simple, \"GeoTrack\", 50);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension GeoXtrack for swath Simple \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension GeoXtrack for swath Simple \n"););
   status = SWdefdim(SWid_simple, "GeoXtrack", 40);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_simple, \"GeoXtrack\", 40);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_simple, \"GeoXtrack\", 40);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tSetting up dimensions for swath Swath64 \n"););
   MESSAGE(6,printf("\t\tDefining dimension Track for swath Swath64 \n"););
   MESSAGE(11,fprintf(fp,"\t\tSetting up dimensions for swath Swath64 \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension Track for swath Swath64 \n"););
   status = SWdefdim(SWid_64, "Track", 100);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_64, \"Track\", 100);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_64, \"Track\", 100);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension Xtrack for swath Swath64 \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension Xtrack for swath Swath64 \n"););
   status = SWdefdim(SWid_64, "Xtrack", 40);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_64, \"Xtrack\", 40);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_64, \"Xtrack\", 40);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tSetting up dimensions for swath SwathLatonly \n"););
   MESSAGE(6,printf("\t\tDefining dimension DataTrack for swath SwathLatonly \n"););
   MESSAGE(11,fprintf(fp,"\t\tSetting up dimensions for swath SwathLatonly \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension DataTrack for swath SwathLatonly \n"););
   status = SWdefdim(SWid_lat, "DataTrack", 100);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_lat, \"DataTrack\", 100);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_lat, \"DataTrack\", 100);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension DataXtrack for swath SwathLatonly \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension DataXtrack for swath SwathLatonly \n"););
   status = SWdefdim(SWid_lat, "DataXtrack", 40);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_lat, \"DataXtrack\", 40);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_lat, \"DataXtrack\", 40);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension GeoTrack for swath SwathLatonly \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension GeoTrack for swath SwathLatonly \n"););
   status = SWdefdim(SWid_lat, "GeoTrack", 50);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_lat, \"GeoTrack\", 50);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_lat, \"GeoTrack\", 50);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension GeoXtrack for swath SwathLatonly \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension GeoXtrack for swath SwathLatonly \n"););
   status = SWdefdim(SWid_lat, "GeoXtrack", 40);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_lat, \"GeoXtrack\", 40);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_lat, \"GeoXtrack\", 40);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tSetting up dimensions for swath Swathco \n"););
   MESSAGE(6,printf("\t\tDefining dimension DataTrack for swath Swathco\n"););
   MESSAGE(11,fprintf(fp,"\t\tSetting up dimensions for swath Swathco \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension DataTrack for swath Swathco\n"););
   status = SWdefdim(SWid_co, "DataTrack", 100);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_co, \"DataTrack\", 100);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim  for DataTrack %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_co, \"DataTrack\", 100);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim  for DataTrack %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension DataXtrack for swath Swathco\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension DataXtrack for swath Swathco\n"););
   status = SWdefdim(SWid_co, "DataXtrack", 40);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_co, \"DataXtrack\", 40);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim for DataXtrack %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_co, \"DataXtrack\", 40);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim for DataXtrack %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension GeoTrack for swath Swathco\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension GeoTrack for swath Swathco\n"););
   status = SWdefdim(SWid_co, "GeoTrack", 50);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_co, \"GeoTrack\", 50);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim for GeoTrack %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_co, \"GeoTrack\", 50);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim for GeoTrack %d\n",status););
   }

   MESSAGE(6,printf("\t\tDefining dimension GeoXtrack for swath Swathco\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension GeoXtrack for swath Swathco\n"););
   status = SWdefdim(SWid_co, "GeoXtrack", 40);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_co, \"GeoXtrack\", 40);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_co, \"GeoXtrack\", 40);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tSetting up dimensions for swath OnedGeo \n"););
   MESSAGE(6,printf("\t\tDefining dimension DataTrack for swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tSetting up dimensions for swath OnedGeo \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension DataTrack for swath OnedGeo\n"););
   status = SWdefdim(SWid_oned, "DataTrack", 100);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_oned, \"DataTrack\", 100);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_oned, \"DataTrack\", 100);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension DataXtrack for swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension DataXtrack for swath OnedGeo\n"););
   status = SWdefdim(SWid_oned, "DataXtrack", 40);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_oned, \"DataXtrack\", 40);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_oned, \"DataXtrack\", 40);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension GeoDim for swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension GeoDim for swath OnedGeo\n"););
   status = SWdefdim(SWid_oned, "GeoDim", 50);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_oned, \"GeoDim\", 50);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_oned, \"GeoDim\", 50);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension GeoDim2 for swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension GeoDim2 for swath OnedGeo\n"););
   status = SWdefdim(SWid_oned, "GeoDim2", 100);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdim(SWid_oned, \"GeoDim2\", 100);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdim(SWid_oned, \"GeoDim2\", 100);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n", status););
   }

   MESSAGE(6,printf("\t\tSetting up dimensions for swath Index \n"););
   MESSAGE(6,printf("\t\tDefining dimension TrackDim for swath Index\n"););
   MESSAGE(11,fprintf(fp,"\t\tSetting up dimensions for swath Index \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension TrackDim for swath Index\n"););
   status=SWdefdim(SWid_index, "TrackDim",40);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefdim(SWid_index, \"TrackDim\",40);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefdim(SWid_index, \"TrackDim\",40);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n",status););
   }

   MESSAGE(6,printf("\t\tDefining dimension XtrackDim for swath Index\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension XtrackDim for swath Index\n"););
   status=SWdefdim(SWid_index, "XtrackDim",40);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefdim(SWid_index, \"XtrackDim\",40);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefdim(SWid_index, \"XtrackDim\",40);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n",status););
   }

   MESSAGE(6,printf("\t\tDefining dimension GeoTrack for swath Index\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension GeoTrack for swath Index\n"););
   status=SWdefdim(SWid_index, "GeoDim",30);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefdim(SWid_index, \"GeoDim\",40);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefdim(SWid_index, \"GeoDim\",40);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n",status););
   }

   MESSAGE(6,printf("\t\tDefining dimension GeoXtrack for swath Index\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension GeoXtrack for swath Index\n"););
   status=SWdefdim(SWid_index, "GeoXDim",30);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefdim(SWid_index, \"GeoXDim\",40);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdim %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefdim(SWid_index, \"GeoXDim\",40);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdim %d\n",status););
   }

/* Test Case -- SWdefdatafield
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWdefdatafield... \n"););
   MESSAGE(4,printf("\t========================= \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWdefdatafield... \n"););
   MESSAGE(11,fprintf(fp,"\t========================= \n"););

   MESSAGE(6,printf("\t\tDefining data fields for swath start\n"););
   MESSAGE(6,printf("\t\tDefining data field testfield\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data fields for swath start\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data field testfield\n"););
   status = SWdefdatafield(SWid_start, "testfield", "testdim,testdim", DFNT_FLOAT32, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefdatafield(SWid_start, \"testfield\",\"testdim,testdim\", DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdatafield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefdatafield(SWid_start,\"testfield\",\"testdim,testdim\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdatafield %d\n", status););
   }
 
   MESSAGE(6,printf("\t\tDefining data field testfield\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data field testfield\n"););
   status = SWdefdatafield(SWid_start, "testfield", "test,test", DFNT_FLOAT32, HDFE_AUTOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdatafield(SWid_start, \"testfield\", \"test,test\",DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdatafield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdatafield(SWid_start, \"testfield\", \"test,test\",DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdatafield %d\n", status););
   }

/* Test Case -- SWdefcomp
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWdefcomp... \n"););
   MESSAGE(4,printf("\t========================= \n"););
   MESSAGE(11,fprintf(fp,"\n"););
   MESSAGE(11,fprintf(fp,"\f\tTesting SWdefcomp... \n"););
   MESSAGE(11,fprintf(fp,"\t========================= \n"););
 
   MESSAGE(6,printf("\t\tDefining compression mode for swath Simple\n"););
   status=SWdefcomp(SWid_simple,HDFE_COMP_SKPHUFF, NULL);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefcomp(SWid_simple,HDFE_COMP_SKPHUFF, NULL);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefcomp %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefcomp(SWid_simple,HDFE_COMP_SKPHUFF, NULL);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefcomp %d\n",status););
   }

   MESSAGE(6,printf("\t\tDefining data fields for swath Simple  \n"););
   MESSAGE(6,printf("\t\tDefining data field Temperature\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data fields for swath Simple  \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data field Temperature\n"););
   status = SWdefdatafield(SWid_simple, "Temperature", "DataTrack,DataXtrack",DFNT_FLOAT32, HDFE_AUTOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefdatafield(SWid_simple,\"Temperature\",\"DataTrack,DataXtrack\",DFNT_FLOAT32,HDFE_AUTOMERGE);\n");)
      MESSAGE(8,printf("\t\tValue returned by SWdefdatafield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefdatafield(SWid_simple,\"Temperature\",\"DataTrack,DataXtrack\",DFNT_FLOAT32,HDFE_AUTOMERGE);\n");)
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdatafield %d\n", status););
   }

   compparm[0] = 2;     /* Pixels per block */
   compparm[1] = SZ_NN; /* Nearest Neighbour + Entropy Coding (EC) Method */

#ifdef HAVE_FILTER_SZIP_ENCODER
   MESSAGE(6,printf("\t\tDefining SZIP (NN) compression mode for swath Simple\n"););
   status=SWdefcomp(SWid_simple,HDFE_COMP_SZIP, compparm);
   MESSAGE(8,printf("\t\tValue returned by SWdefcomp %d\n",status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed SZIP Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed SZIP Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefcomp(SWid_simple,HDFE_COMP_SZIP, comparm);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefcomp %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefcomp(SWid_simple,HDFE_COMP_SZIP, compparm);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefcomp %d\n",status););

   }
#else
   MESSAGE(4,printf("\t\t********Skip SZIP Test**********\n"););
   MESSAGE(11,fprintf(fp,"\t\t********Skip SZIP Test**********\n"););
   MESSAGE(4,printf("No szip encoder provided, the szip compression test is be skipped.\n"););
   MESSAGE(11,fprintf(fp,"No szip encoder provided, the szip compression test is be skipped.\n"););
#endif

   MESSAGE(6,printf("\t\tDefining data field Conduction\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data field Conduction\n"););
   status = SWdefdatafield(SWid_simple, "Conduction", "DataTrack,DataXtrack",DFNT_FLOAT32, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefdatafield(SWid_simple,\"Conduction\",\"DataTrack,DataXtrack\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdatafield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefdatafield(SWid_simple,\"Conduction\",\"DataTrack,DataXtrack\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdatafield %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining compression mode for swath Simple\n"););
   status=SWdefcomp(SWid_simple,HDFE_COMP_NONE, NULL);
   MESSAGE(8,printf("\t\tValue returned by SWdefcomp %d\n",status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
   }

   MESSAGE(6,printf("\t\tDefining data fields for swath Swath64 \n"););
   MESSAGE(6,printf("\t\tDefining data field SensorA\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data fields for swath Swath64 \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data field SensorA\n"););
   status = SWdefdatafield(SWid_64, "SensorA", "Track,Xtrack", DFNT_FLOAT32,HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdatafield(SWid_64, \"SensorA\", \"Track,Xtrack\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdatafield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdatafield(SWid_64, \"SensorA\", \"Track,Xtrack\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdatafield %d\n", status););
   }
   MESSAGE(6,printf("\t\tDefining data fields for swath Swathlatonly \n"););
   MESSAGE(6,printf("\t\tDefining data field Gain\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data fields for swath Swathlatonly \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data field Gain\n"););
   status = SWdefdatafield(SWid_lat, "Gain", "DataTrack,DataXtrack", DFNT_FLOAT32, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdatafield(SWid_lat, \"Gain\", \"DataTrack,DataXtrack\",DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdatafield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefdatafield(SWid_lat,\"Gain\",\"DataTrack,DataXtrack\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdatafield %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining data fields for swath Swathco \n"););
   MESSAGE(6,printf("\t\tDefining data field BandC\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data fields for swath Swathco \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data field BandC\n"););
   status=SWdefdatafield(SWid_co,"BandC","DataTrack,DataXtrack",DFNT_FLOAT32,HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefdatafield(SWid_co,\"BandC\",\"DataTrack,DataXtrack\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdatafield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefdatafield(SWid_co,\"BandC\",\"DataTrack,DataXtrack\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdatafield %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining data fields for swath OnedGeo \n"););
   MESSAGE(6,printf("\t\tDefining data field CalA\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data fields for swath OnedGeo \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data field CalA\n"););
   status = SWdefdatafield(SWid_oned, "CalA", "DataTrack,DataXtrack", DFNT_FLOAT32, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefdatafield(SWid_oned, \"CalA\", \"DataTrack,DataXtrack\",DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdatafield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefdatafield(SWid_oned,\"CalA\",\"DataTrack,DataXtrack\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdatafield %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining data field CalB\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data field CalB\n"););
   status = SWdefdatafield(SWid_oned, "CalB", "DataTrack,DataXtrack", DFNT_FLOAT32, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus =SWdefdatafield(SWid_oned, \"CalB\", \"DataTrack,DataXtrack\",DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdatafield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefdatafield(SWid_oned,\"CalB\",\"DataTrack,DataXtrack\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdatafield %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining data field Fakedata\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining data field Fakedata\n"););
   status=SWdefdatafield(SWid_index, "Fakedata", "TrackDim,XtrackDim",DFNT_FLOAT32,HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefdatafield(SWid_index,\"Fakedata\", \"TrackDim,XtrackDim\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdatafield %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefdatafield(SWid_index,\"Fakedata\",\"TrackDim,XtrackDim\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdatafield %d\n",status););
   }

/* Test Case -- SWdefgeofield
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWdefgeofield.... \n"););
   MESSAGE(4,printf("\t========================= \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWdefgeofield.... \n"););
   MESSAGE(11,fprintf(fp,"\t========================= \n"););

   MESSAGE(6,printf("\t\tDefining geolocation fields for swath start\n"););
   MESSAGE(6,printf("\t\tDefining geolocation field Latitude\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation fields for swath start\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation field Latitude\n"););
   status = SWdefgeofield(SWid_start, "Latitude", "test,test", DFNT_FLOAT32, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefgeofield(SWid_start, \"Latitude\", \"test,test\", DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tStatus returned by SWdefgeofield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefgeofield(SWid_start, \"Latitude\", \"test,test\", DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by SWdefgeofield %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining geolocation fields for swath Simple\n"););
   MESSAGE(6,printf("\t\tDefining geolocation field Latitude\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation fields for swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation field Latitude\n"););
   status = SWdefgeofield(SWid_simple, "Latitude", "GeoTrack,GeoXtrack", DFNT_FLOAT32,HDFE_AUTOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefgeofield(SWid_simple,\"Latitude\",\"GeoTrack,GeoXtrack\",DFNT_FLOAT32,HDFE_AUTMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefgeofield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefgeofield(SWid_simple,\"Latitude\",\"GeoTrack,GeoXtrack\",DFNT_FLOAT32,HDFE_AUTMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefgeofield %d\n", status););
   }
 
   MESSAGE(6,printf("\t\tDefining geolocation field Longitude\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation field Longitude\n"););
   status = SWdefgeofield(SWid_simple, "Longitude", "GeoTrack,GeoXtrack", DFNT_FLOAT32,HDFE_AUTOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefgeofield(SWid_simple,\"Longitude\",\"GeoTrack,GeoXtrack\",DFNT_FLOAT32,HDFE_AUTOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefgeofield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefgeofield(SWid_simple,\"Longitude\",\"GeoTrack,GeoXtrack\",DFNT_FLOAT32,HDFE_AUTOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefgeofield %d\n", status););
   }


   MESSAGE(6,printf("\t\tDefining geolocation fields for swath Swath64\n"););
   MESSAGE(6,printf("\t\tDefining geolocation field Latitude\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation fields for swath Swath64\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation field Latitude\n"););
   status = SWdefgeofield(SWid_64, "Latitude", "Track,Xtrack", DFNT_FLOAT64, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefgeofield(SWid_64, \"Latitude\", \"Track,Xtrack\", DFNT_FLOAT64, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefgeofield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefgeofield(SWid_64, \"Latitude\", \"Track,Xtrack\", DFNT_FLOAT64, HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefgeofield %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining geolocation field Longitude\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation field Longitude\n"););
   status = SWdefgeofield(SWid_64, "Longitude", "Track,Xtrack", DFNT_FLOAT64, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefgeofield(SWid_64, \"Longitude\", \"Track,Xtrack\", DFNT_FLOAT64, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefgeofield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefgeofield(SWid_64, \"Longitude\", \"Track,Xtrack\", DFNT_FLOAT64, HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefgeofield %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining geolocation fields for swath SwathLatonly\n"););
   MESSAGE(6,printf("\t\tDefining geolocation field CoLatitude\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation fields for swath SwathLatonly\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation field CoLatitude\n"););
   status = SWdefgeofield(SWid_lat, "CoLatitude", "GeoTrack,GeoXtrack", DFNT_FLOAT32, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefgeofield(SWid_lat,\"CoLatitude\",\"GeoTrack,GeoXtrack\",DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefgeofield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefgeofield(SWid_lat,\"CoLatitude\",\"GeoTrack,GeoXtrack\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefgeofield %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining geolocation fields for swath Swathco\n"););
   MESSAGE(6,printf("\t\tDefining geolocation field CoLatitude\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation fields for swath Swathco\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation field CoLatitude\n"););
   status = SWdefgeofield(SWid_co, "CoLatitude", "GeoTrack,GeoXtrack", DFNT_FLOAT32, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefgeofield(SWid_co,\"CoLatitude\", \"GeoTrack,GeoXtrack\", DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefgeofield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefgeofield(SWid_co,\"CoLatitude\",\"GeoTrack,GeoXtrack\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefgeofield %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining geolocation field Longitude\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation field Longitude\n"););
   status = SWdefgeofield(SWid_co, "Longitude", "GeoTrack,GeoXtrack", DFNT_FLOAT32, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefgeofield(SWid_co, \"Longitude\", \"GeoTrack,GeoXtrack\", DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefgeofield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefgeofield(SWid_co,\"Longitude\",\"GeoTrack,GeoXtrack\",DFNT_FLOAT32,HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefgeofield %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining geolocation field Time\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation field Time\n"););
   status = SWdefgeofield(SWid_co, "Time", "GeoTrack,GeoXtrack", DFNT_FLOAT64, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefgeofield(SWid_co, \"Time\", \"GeoTrack,GeoXtrack\", DFNT_FLOAT64, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefgeofield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefgeofield(SWid_co, \"Time\", \"GeoTrack,GeoXtrack\", DFNT_FLOAT64, HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefgeofield %d\n", status););
   }


   MESSAGE(6,printf("\t\tDefining geolocation fields for swath OnedGeo\n"););
   MESSAGE(6,printf("\t\tDefining geolocation field Latitude\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation fields for swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation field Latitude\n"););
   status = SWdefgeofield(SWid_oned, "Latitude", "GeoDim", DFNT_FLOAT32, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefgeofield(SWid_oned, \"Latitude\", \"GeoDim\", DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefgeofield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefgeofield(SWid_oned, \"Latitude\", \"GeoDim\", DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefgeofield %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining geolocation field Longitude\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation field Longitude\n"););
   status = SWdefgeofield(SWid_oned, "Longitude", "GeoDim", DFNT_FLOAT32, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefgeofield(SWid_oned, \"Longitude\", \"GeoDim\", DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefgeofield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefgeofield(SWid_oned, \"Longitude\", \"GeoDim\", DFNT_FLOAT32, HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefgeofield %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining geolocation field Time\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation field Time\n"););
   status = SWdefgeofield(SWid_oned, "Time", "GeoDim2", DFNT_FLOAT64, HDFE_NOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefgeofield(SWid_oned, \"Time\", \"GeoDim2\", DFNT_FLOAT64, HDFE_NOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefgeofield %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefgeofield(SWid_oned, \"Time\", \"GeoDim2\", DFNT_FLOAT64, HDFE_NOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefgeofield %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining geolocation field Latitude\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation field Latitude\n"););
   status=SWdefgeofield(SWid_index,"Latitude","GeoDim,GeoXDim",DFNT_FLOAT32,HDFE_AUTOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefgeofield(SWid_index,\"Latitude\",\"GeoDim,GeoXDim\",DFNT_FLOAT32,HDFE_AUTOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefgeofield %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefgeofield(SWid_index,\"Latitude\",\"GeoDim,GeoXDim\",DFNT_FLOAT32,HDFE_AUTOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefgeofield %d\n",status););
   }

   MESSAGE(6,printf("\t\tDefining geolocation field Longitude\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining geolocation field Longitude\n"););
   status=SWdefgeofield(SWid_index,"Longitude","GeoDim,GeoXDim",DFNT_FLOAT32,HDFE_AUTOMERGE);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefgeofield(SWid_index,\"Latitude\",\"GeoDim,GeoXDim\",DFNT_FLOAT32,HDFE_AUTOMERGE);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefgeofield %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefgeofield(SWid_index,\"Latitude\",\"GeoDim,GeoXDim\",DFNT_FLOAT32,HDFE_AUTOMERGE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefgeofield %d\n",status););
   }

/* Test Case -- SWdefdimmap
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWdefdimmap... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWdefdimmap... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tDefining dimension maps for swath start \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension maps for swath start \n"););
   status = SWdefdimmap(SWid_start, "test", "test", 0, 0);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdimmap(SWid_start, \"test\", \"test\", 0, 0);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdimmap %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdimmap(SWid_start, \"test\", \"test\", 0, 0);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdimmap %d\n", status););
   }

   MESSAGE(6,printf("\t\tDefining dimension maps for swath Simple \n"););
   MESSAGE(6,printf("\t\tDefining track dimension mapping\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension maps for swath Simple \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining track dimension mapping\n"););
   status = SWdefdimmap(SWid_simple, "GeoTrack", "DataTrack", 0, 2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdimmap(SWid_simple, \"GeoTrack\", \"DataTrack\", 0, 2);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdimmap %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdimmap(SWid_simple, \"GeoTrack\", \"DataTrack\", 0, 2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdimmap %d\n",status););
   }

   MESSAGE(6,printf("\t\tDefining cross track dimension mapping\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining cross track dimension mapping\n"););
   status = SWdefdimmap(SWid_simple, "GeoXtrack", "DataXtrack", 0, 1);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdimmap(SWid_simple, \"GeoXtrack\", \"DataXtrack\", 0, 1);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdimmap %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdimmap(SWid_simple, \"GeoXtrack\", \"DataXtrack\", 0, 1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdimmap %d\n",status););
   }

   MESSAGE(6,printf("\t\tDefining dimension maps for swath Swathlatonly \n"););
   MESSAGE(6,printf("\t\tDefining track dimension mapping\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension maps for swath Swathlatonly \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining track dimension mapping\n"););
   status = SWdefdimmap(SWid_lat, "GeoTrack", "DataTrack", 0, 2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdimmap(SWid_lat, \"GeoTrack\", \"DataTrack\", 0, 2);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdimmap %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdimmap(SWid_lat, \"GeoTrack\", \"DataTrack\", 0, 2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdimmap %d\n",status););
   }

   MESSAGE(6,printf("\t\tDefining cross track dimension mapping\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining cross track dimension mapping\n"););
   status = SWdefdimmap(SWid_lat, "GeoXtrack", "DataXtrack", 0, 1);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdimmap(SWid_lat, \"GeoXtrack\", \"DataXtrack\", 0, 1);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdimmap %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdimmap(SWid_lat, \"GeoXtrack\", \"DataXtrack\", 0, 1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdimmap %d\n",status););
   }

   MESSAGE(6,printf("\t\tDefining dimension maps for swath Swathco \n"););
   MESSAGE(6,printf("\t\tDefining track dimension mapping\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension maps for swath Swathco \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining track dimension mapping\n"););
   status = SWdefdimmap(SWid_co, "GeoTrack", "DataTrack", 0, 2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdimmap(SWid_co, \"GeoTrack\", \"DataTrack\", 0, 2);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdimmap %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdimmap(SWid_co, \"GeoTrack\", \"DataTrack\", 0, 2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdimmap %d\n",status););
   }

   MESSAGE(6,printf("\t\tDefining cross track dimension mapping\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining cross track dimension mapping\n"););
   status = SWdefdimmap(SWid_co, "GeoXtrack", "DataXtrack", 0, 1);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdimmap(SWid_co, \"GeoXtrack\", \"DataXtrack\", 0, 1);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdimmap %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdimmap(SWid_co, \"GeoXtrack\", \"DataXtrack\", 0, 1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdimmap %d\n",status););
   }

   MESSAGE(6,printf("\t\tDefining dimension mapping for swath OnedGeo\n"););
   MESSAGE(6,printf("\t\tDefining track dimension mapping\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension mapping for swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining track dimension mapping\n"););
   status = SWdefdimmap(SWid_oned, "GeoDim", "DataTrack", 0, 2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdimmap(SWid_oned, \"GeoDim\", \"DataTrack\", 0, 2);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdimmap %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdimmap(SWid_oned, \"GeoDim\", \"DataTrack\", 0, 2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdimmap %d\n",status););
   }

   MESSAGE(6,printf("\t\tDefining dimension mapping for swath OnedGeo\n"););
   MESSAGE(6,printf("\t\tDefining track dimension mapping\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining dimension mapping for swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining track dimension mapping\n"););
   status = SWdefdimmap(SWid_oned, "GeoDim2", "DataTrack", 0, 1);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdefdimmap(SWid_oned, \"GeoDim2\", \"DataTrack\", 0, 1);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefdimmap %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdefdimmap(SWid_oned, \"GeoDim2\", \"DataTrack\", 0, 1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefdimmap %d\n",status););
   }

/* Test Case -- SWdefidxmap
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWdefidxmap... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWdefidxmap... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tDefining indexed mapping reltionships \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining indexed mapping reltionships \n"););
   status=SWdefidxmap(SWid_index, "GeoDim","TrackDim",indexmap);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefidxmap(SWid_index, \"GeoDim\",\"TrackDim\",indexmap);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefidxmap %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefidxmap(SWid_index, \"GeoDim\",\"TrackDim\",indexmap);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefidxmap %d\n",status););
   }

   MESSAGE(6,printf("\t\tDefining indexed mapping reltionships \n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining indexed mapping reltionships \n"););
   status=SWdefidxmap(SWid_index, "GeoXDim","XtrackDim",indexmap);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdefidxmap(SWid_index, \"GeoXDim\",\"XtrackDim\",indexmap);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefidxmap %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdefidxmap(SWid_index, \"GeoXDim\",\"XtrackDim\",indexmap);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefidxmap %d\n",status););
   }

/* Test Case -- SWsetfillvalue
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWsetfillvalue... \n"););
   MESSAGE(4,printf("\t========================= \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWsetfillvalue... \n"););
   MESSAGE(11,fprintf(fp,"\t========================= \n"););

   MESSAGE(6,printf("\t\tSetting fill value for field Conduction\n"););
   MESSAGE(11,fprintf(fp,"\t\tSetting fill value for field Conduction\n"););
   status = SWsetfillvalue(SWid_start, "Conduction", &fillvalue);
   if(status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWsetfillvalue(SWid_start, \"Conduction\", &fillvalue);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWsetfillvalue for field Conduction %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWsetfillvalue(SWid_start, \"Conduction\", &fillvalue);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWsetfillvalue for field Conduction %d\n",status););
   }


   MESSAGE(6,printf("\t\tSetting fill value for field Conduction in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tSetting fill value for field Conduction in swath Simple\n"););
   status = SWsetfillvalue(SWid_simple, "Conduction", &fillvalue);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWsetfillvalue(SWid_simple, \"Conduction\", &fillvalue);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWsetfillvalue for field Conduction %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWsetfillvalue(SWid_simple, \"Conduction\", &fillvalue);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWsetfillvalue for field Conduction %d\n",status););
   }

   MESSAGE(6,printf("\t\tSetting fill value for field Temperature in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tSetting fill value for field Temperature in swath Simple\n"););
   status = SWsetfillvalue(SWid_simple, "Temperature", &fillvalue);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWsetfillvalue(SWid_simple, \"Temperature\", &fillvalue);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWsetfillvalue for field Temperature %d\n", status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWsetfillvalue(SWid_simple, \"Temperature\", &fillvalue);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWsetfillvalue for field Temperature %d\n", status););
   }

/* Test Case -- SWdetach
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWdetach... \n"););
   MESSAGE(4,printf("\t=================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWdetach... \n"););
   MESSAGE(11,fprintf(fp,"\t=================== \n"););

   MESSAGE(6,printf("\t\tDetaching from swath start\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath start\n"););
   status = SWdetach(SWid_start);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_start);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath start %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_start);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath start %d\n",status););
   }

   MESSAGE(6,printf("\t\tDetaching from swath start\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath start\n"););
   status = SWdetach(SWid_start);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_start);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath start %d\n",status);)
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_start);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath start %d\n",status););
   }
 
   MESSAGE(6,printf("\t\tDetaching from swath Simple \n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath Simple \n"););
   status = SWdetach(SWid_simple);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_simple);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath Simple %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_simple);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath Simple %d\n",status););
   }
 
   MESSAGE(6,printf("\t\tDetaching from swath Swath64 \n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath Swath64 \n"););
   status = SWdetach(SWid_64);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_64);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath Swath64 %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_64);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath Swath64 %d\n",status););
   }

   MESSAGE(6,printf("\t\tDetaching from swath SwathLatonly \n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath SwathLatonly \n"););
   status = SWdetach(SWid_lat);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_lat);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath SwathLatonly %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_lat);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath SwathLatonly %d\n",status););
   }
 
   MESSAGE(6,printf("\t\tDetaching from swath Swathco \n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath Swathco \n"););
   status = SWdetach(SWid_co);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_co);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath Swathco %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_co);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath Swathco %d\n",status););
   }

   MESSAGE(6,printf("\t\tDetaching from swath OnedGeo \n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath OnedGeo \n"););
   status = SWdetach(SWid_oned);
   MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_oned);\n"););
   MESSAGE(8,printf("\t\tValue returned by SWdetach for swath OnedGeo %d\n",status););
   MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_oned);\n"););
   MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath OnedGeo %d\n",status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
   }

   MESSAGE(6,printf("\t\tDetaching from swath Index \n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath Index \n"););
   status = SWdetach(SWid_index);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_index);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath Index %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_index);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath Index %d\n",status););
   }

   MESSAGE(6,printf("\t\tClosing swath file Swathc_Test.hdf\n");); 
   MESSAGE(11,fprintf(fp,"\t\tClosing swath file Swathc_Test.hdf\n");); 
   status = SWclose(swfidc_test);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWclose(swfidc_test);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWclose for file Swathc_Test.hdf %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWclose(swfidc_test);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWclose for file Swathc_Test.hdf %d\n",status););
   }

   MESSAGE(6,printf("\t\tClosing swath file Swath_2.hdf\n");); 
   MESSAGE(11,fprintf(fp,"\t\tClosing swath file Swath_2.hdf\n");); 
   status = SWclose(swfid_2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWclose(swfid_2);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWclose for file Swath_2.hdf %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWclose(swfid_2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWclose for file Swath_2.hdf %d\n",status););
   }

   MESSAGE(6,printf("\t\tClosing swath file Swath_1.hdf\n");); 
   MESSAGE(11,fprintf(fp,"\t\tClosing swath file Swath_1.hdf\n");); 
   status = SWclose(swfid_1);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWclose(swfid_1);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWclose for file Swath_1.hdf %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWclose(swfid_1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWclose for file Swath_1.hdf %d\n",status););
   }

   MESSAGE(6,printf("\t\tOpening file Swathc_Test.hdf\n"););
   MESSAGE(11,fprintf(fp,"\t\tOpening file Swathc_Test.hdf\n"););
   swfidc_test = SWopen("Swathc_Test.hdf", DFACC_RDWR);
   if (swfidc_test == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tswfidc_test = SWopen(\"Swathc_Test.hdf\", DFACC_RDWR);\n"););
      MESSAGE(8,printf("\t\tValue retunred by SWopen on file Swathc_Test.hdf %d\n",swfidc_test););
      MESSAGE(11,fprintf(fp,"\t\tswfidc_test = SWopen(\"Swathc_Test.hdf\", DFACC_RDWR);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue retunred by SWopen on file Swathc_Test.hdf %d\n",swfidc_test););
   }

   MESSAGE(6,printf("\t\tOpening file Swath_1.hdf\n"););
   MESSAGE(11,fprintf(fp,"\t\tOpening file Swath_1.hdf\n"););
   swfid_2 = SWopen("Swath_2.hdf", DFACC_RDWR);
   if (swfid_2 == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tswfid_2 = SWopen(\"Swath_2.hdf\", DFACC_RDWR);\n"););
      MESSAGE(8,printf("\t\tValue retunred by SWopen on file Swath_2.hdf %d\n",swfid_2););
      MESSAGE(11,fprintf(fp,"\t\tswfid_2 = SWopen(\"Swath_2.hdf\", DFACC_RDWR);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue retunred by SWopen on file Swath_2.hdf %d\n",swfid_2););
   }


/* Test Case -- SWattach
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWattach... \n"););
   MESSAGE(4,printf("\t=================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWattach... \n"););
   MESSAGE(11,fprintf(fp,"\t=================== \n"););

   MESSAGE(6,printf("\t\tAttaching to swath First \n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to swath First \n"););
   SWid_start = SWattach(swfid_2, "First");
   if(SWid_start == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_start = SWattach(swfid_2, \"First\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattach on swath start %d\n",SWid_start););
      MESSAGE(11,fprintf(fp,"\t\tSWid_start = SWattach(swfid_2, \"First\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach on swath start %d\n",SWid_start););
   }

   MESSAGE(6,printf("\t\tAttaching to swath start \n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to swath start \n"););
   SWid_start = SWattach(swfid_2, "Start");
   if(SWid_start == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_start = SWattach(swfid_2, \"Start\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattach on swath start %d\n",SWid_start););
      MESSAGE(11,fprintf(fp,"\t\tSWid_start = SWattach(swfid_2, \"Start\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach on swath start %d\n",SWid_start););
   }
 

   MESSAGE(6,printf("\t\tAttaching to swath Simple \n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to swath Simple \n"););
   SWid_simple = SWattach(swfidc_test, "Simple");
   if (SWid_simple == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_simple = SWattach(swfidc_test, \"Simple\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattach on swath Simple %d\n",SWid_simple););
      MESSAGE(11,fprintf(fp,"\t\tSWid_simple = SWattach(swfidc_test, \"Simple\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach on swath Simple %d\n",SWid_simple););
   }

   MESSAGE(6,printf("\t\tAttaching to swath Swath64 \n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to swath Swath64 \n"););
   SWid_64 = SWattach(swfidc_test, "Swath64");
   if (SWid_64 == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_64 = SWattach(swfidc_test, \"Swath64\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattach on swath Swath64 %d\n",SWid_64););
      MESSAGE(11,fprintf(fp,"\t\tSWid_64 = SWattach(swfidc_test, \"Swath64\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach on swath Swath64 %d\n",SWid_64););
   }

   MESSAGE(6,printf("\t\tAttaching to swath SwathLatonly \n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to swath SwathLatonly \n"););
   SWid_lat = SWattach(swfidc_test, "SwathLatonly");
   if (SWid_lat == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_lat = SWattach(swfidc_test, \"SwathLatonly\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattach on swath SwathLatonly %d\n",SWid_lat););
      MESSAGE(11,fprintf(fp,"\t\tSWid_lat = SWattach(swfidc_test, \"SwathLatonly\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach on swath SwathLatonly %d\n",SWid_lat););
   }

   MESSAGE(6,printf("\t\tAttaching to swath Swathco \n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to swath Swathco \n"););
   SWid_co = SWattach(swfidc_test, "Swathco");
   if (SWid_co == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_co = SWattach(swfidc_test, \"Swathco\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattach on swath Swathco %d\n",SWid_co););
      MESSAGE(11,fprintf(fp,"\t\tSWid_co = SWattach(swfidc_test, \"Swathco\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach on swath Swathco %d\n",SWid_co););
   }

   MESSAGE(6,printf("\t\tAttaching to swath OnedGeo \n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to swath OnedGeo \n"););
   SWid_oned = SWattach(swfidc_test, "OnedGeo");
   if (SWid_oned == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_oned = SWattach(swfidc_test, \"OnedGeo\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattach on swath OnedGeo %d\n",SWid_oned););
      MESSAGE(11,fprintf(fp,"\t\tSWid_oned = SWattach(swfidc_test, \"OnedGeo\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach on swath OnedGeo %d\n",SWid_oned););
   }

   MESSAGE(6,printf("\t\tAttaching to swath Index \n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to swath Index \n"););
   SWid_index = SWattach(swfidc_test, "Index");
   if (SWid_index == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_index = SWattach(swfidc_test, \"Index\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattach on swath OnedGeo %d\n",SWid_index););
      MESSAGE(11,fprintf(fp,"\t\tSWid_index = SWattach(swfidc_test, \"Index\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach on swath OnedGeo %d\n",SWid_index););
   }

/* Test Case -- SWwritefield
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWwritefield... \n"););
   MESSAGE(4,printf("\t======================= \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWwritefield... \n"););
   MESSAGE(11,fprintf(fp,"\t======================= \n"););

   MESSAGE(6,printf("\t\tWriting field trythis in swath start\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field trythis in swath start\n"););
   status = SWwritefield(SWid_start, "trythis", NULL, NULL, NULL, ray1);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_start, \"trythis\", NULL,NULL,NULL, ray1);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_start, \"trythis\", NULL,NULL,NULL, ray1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield %d\n",status););
   }
   
   MESSAGE(6,printf("\t\tWriting field testfield in swath start\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field testfield in swath start\n"););
   status = SWwritefield(SWid_start, "testfield", NULL, NULL, NULL, ray2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWwritefield(SWid_start, \"testfield\", NULL,NULL,NULL, ray1);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWwritefield(SWid_start, \"testfield\", NULL,NULL,NULL, ray1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield %d\n",status););
   }


   MESSAGE(6,printf("\t\tWriting field Temperature in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Temperature in swath Simple\n"););
   status = SWwritefield(SWid_simple, "Temperature", tstart, stride, tedge, ray1);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_simple, \"Temperature\", tstart, stride, tedge, ray1);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_simple, \"Temperature\", tstart, stride, tedge, ray1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield %d\n",status););
   }
   
   MESSAGE(6,printf("\t\tWriting field Conduction in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Conduction in swath Simple\n"););
   status = SWwritefield(SWid_simple, "Conduction", tstart, stride, tedge, ray2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_simple, \"Conduction\", tstart, stride, tedge, ray2);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field Conduction in swath Simple %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_simple, \"Conduction\", tstart, stride, tedge, ray2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field Conduction in swath Simple %d\n",status););
   }
   
   MESSAGE(6,printf("\t\tWriting field Conduction in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Conduction in swath Simple\n"););
   status = SWwritefield(SWid_simple, "Conduction", start, stride, edge, ray2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_simple, \"Conduction\", start, stride, edge, ray2);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field Conduction in swath Simple %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_simple, \"Conduction\", start, stride, edge, ray2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field Conduction in swath Simple %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field Latitude in swath Simple \n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Latitude in swath Simple \n"););
   status = SWwritefield(SWid_simple, "Latitude", NULL, NULL, NULL, lat);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_simple, \"Latitude\", NULL, NULL, NULL, lat);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_simple, \"Latitude\", NULL, NULL, NULL, lat);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield %d\n",status););
   }
  
   MESSAGE(6,printf("\t\tWriting field Longitude in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Longitude in swath Simple\n"););
   status = SWwritefield(SWid_simple, "Longitude", NULL, NULL, NULL, lon);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_simple, \"Longitude\", NULL,NULL,NULL, lat);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field Longitude in swath Simple %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_simple, \"Longitude\", NULL,NULL,NULL, lat);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field Longitude in swath Simple %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field SensorA in swath Swath64\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field SensorA in swath Swath64\n"););
   status = SWwritefield(SWid_64, "SensorA", NULL, NULL, NULL, ray1);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_64, \"SensorA\", NULL, NULL, NULL, ray1);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field SensorA in swath Swath64 %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_64, \"SensorA\", NULL, NULL, NULL, ray1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field SensorA in swath Swath64 %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field Latitude for swath Swath64\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Latitude for swath Swath64\n"););
   status = SWwritefield(SWid_64, "Latitude", NULL, NULL, NULL, lat2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_64, \"Latitude\", NULL,NULL,NULL, ray1);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field Latitude in swath Swath64 %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_64, \"Latitude\", NULL,NULL,NULL, ray1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field Latitude in swath Swath64 %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field Longitude for swath Swath64\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Longitude for swath Swath64\n"););
   status = SWwritefield(SWid_64, "Longitude", NULL, NULL, NULL, lon2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_64, \"Longitude\", NULL, NULL, NULL, lon2);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field Longitude in swath Swath64 %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_64, \"Longitude\", NULL, NULL, NULL, lon2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field Longitude in swath Swath64 %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field Longitude for swath SwathLatonly\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Longitude for swath SwathLatonly\n"););
   status = SWwritefield(SWid_lat, "Gain", NULL, NULL, NULL, ray2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_lat, \"Gain\", NULL, NULL, NULL, ray2);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field Gain in swath SwathLatonly %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_lat, \"Gain\", NULL, NULL, NULL, ray2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field Gain in swath SwathLatonly %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field CoLatitude for swath SwathLatonly \n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field CoLatitude for swath SwathLatonly \n"););
   status = SWwritefield(SWid_lat, "CoLatitude", NULL, NULL, NULL, colat);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_lat, \"CoLatitude\", NULL, NULL, NULL, colat);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field CoLatitude in swath SwathLatonly %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_lat, \"CoLatitude\", NULL, NULL, NULL, colat);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field CoLatitude in swath SwathLatonly %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field BandC for swath Swathco\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field BandC for swath Swathco\n"););
   status = SWwritefield(SWid_co, "BandC", NULL, NULL, NULL, ray2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_co, \"BandC\", NULL, NULL, NULL, ray2);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field BandC in swath Swathco %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_co, \"BandC\", NULL, NULL, NULL, ray2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field BandC in swath Swathco %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field CoLatitude for swath Swathco\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field CoLatitude for swath Swathco\n"););
   status = SWwritefield(SWid_co, "CoLatitude", NULL, NULL, NULL, colat);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_co, \"CoLatitude\", NULL, NULL, NULL, colat);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field CoLatitude in swath Swathco %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_co, \"CoLatitude\", NULL, NULL, NULL, colat);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field CoLatitude in swath Swathco %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field Longitude for swath Swathco\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Longitude for swath Swathco\n"););
   status = SWwritefield(SWid_co, "Longitude", NULL, NULL, NULL, lon);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_co, \"Longitude\", NULL, NULL, NULL, lon);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field Longitude in swath Swathco %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_co, \"Longitude\", NULL, NULL, NULL, lon);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field Longitude in swath Swathco %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field Time for swath Swathco\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Time for swath Swathco\n"););
   status = SWwritefield(SWid_co, "Time", NULL, NULL, NULL, twodtime);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_co, \"Time\", NULL, NULL, NULL, twodtime);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field Time in swath Swathco %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_co, \"Time\", NULL, NULL, NULL, twodtime);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field Time in swath Swathco %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field CalA for swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field CalA for swath OnedGeo\n"););
   status = SWwritefield(SWid_oned, "CalA", NULL, NULL, NULL, ray1);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_oned, \"CalA\", NULL, NULL, NULL, ray1);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field CalA in swath OnedGeo %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_oned, \"CalA\", NULL, NULL, NULL, ray1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field CalA in swath OnedGeo %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field CalB for swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field CalB for swath OnedGeo\n"););
   status = SWwritefield(SWid_oned, "CalB", NULL, NULL, NULL, ray2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_oned, \"CalB\", NULL, NULL, NULL, ray2);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field CalB in swath OnedGeo %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_oned, \"CalB\", NULL, NULL, NULL, ray2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field CalB in swath OnedGeo %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field Latitude for swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Latitude for swath OnedGeo\n"););
   status = SWwritefield(SWid_oned, "Latitude", NULL, NULL, NULL, onedlat);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_oned, \"Latitude\", NULL, NULL, NULL, onedlat);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field Latitude in swath OnedGeo %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_oned, \"Latitude\", NULL, NULL, NULL, onedlat);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field Latitude in swath OnedGeo %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field Longitude for swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Longitude for swath OnedGeo\n"););
   status = SWwritefield(SWid_oned, "Longitude", NULL, NULL, NULL, onedlon);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_oned, \"Longitude\", NULL, NULL, NULL, onedlon);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field Longitude in swath OnedGeo %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_oned, \"Longitude\", NULL, NULL, NULL, onedlon);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field Longitude in swath OnedGeo %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field Time for swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Time for swath OnedGeo\n"););
   status = SWwritefield(SWid_oned, "Time", NULL, NULL, NULL, onedtime);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritefield(SWid_oned, \"Time\", NULL, NULL, NULL, onedtime);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield for field Time in swath OnedGeo %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritefield(SWid_oned, \"Time\", NULL, NULL, NULL, onedtime);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield for field Time in swath OnedGeo %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field Fakedata for swath Index\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Fakedata for swath Index\n"););
   status=SWwritefield(SWid_index, "Fakedata", NULL,NULL,NULL, ray1);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWwritefield(SWid_index, \"Fakedata\", NULL,NULL,NULL, ray1);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWwritefield(SWid_index, \"Fakedata\", NULL,NULL,NULL, ray1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field Latitude for swath Index\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Latitude for swath Index\n"););
   status=SWwritefield(SWid_index, "Latitude", NULL,NULL,NULL, idxlat);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWwritefield(SWid_index, \"Latitude\", NULL,NULL,NULL, idxlat);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWwritefield(SWid_index, \"Latitude\", NULL,NULL,NULL, idxlat);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting field Longitude for swath Index\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting field Longitude for swath Index\n"););
   status=SWwritefield(SWid_index, "Longitude", NULL,NULL,NULL, idxlon);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWwritefield(SWid_index, \"Longitude\", NULL,NULL,NULL, idxlon);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritefield %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWwritefield(SWid_index, \"Longitude\", NULL,NULL,NULL, idxlon);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritefield %d\n",status););
   }

/* Test Case -- SWwriteattr
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWwriteattr... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWwriteattr... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tWriting attribute Conduction in swath start\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting attribute Conduction in swath start\n"););
   status = SWwriteattr(SWid_start, "Conduction", DFNT_INT32, 4, attr);
   if(status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwriteattr(SWid_start, \"Conduction\", DFNT_INT32, 4, attr);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwriteattr %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwriteattr(SWid_start, \"Conduction\", DFNT_INT32, 4, attr);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwriteattr %d\n",status););
   }

   MESSAGE(6,printf("\t\tWriting attribute Drift in swath Simple \n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting attribute Drift in swath Simple \n"););
   status = SWwriteattr(SWid_simple, "Drift", DFNT_INT32, 4, attr);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwriteattr(SWid_simple, \"Drift\", DFNT_INT32, 4, attr);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwriteattr for attribute Drift in swath Simple %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwriteattr(SWid_simple, \"Drift\", DFNT_INT32, 4, attr);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwriteattr for attribute Drift in swath Simple %d\n",status););
   }

   MESSAGE(6,printf("\t\tDetaching from swath start\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath start\n"););
   status = SWdetach(SWid_start);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_start);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath start %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_start);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath start %d\n",status););
   }

   MESSAGE(6,printf("\t\tDetaching from swath Swath64 \n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath Swath64 \n"););
   status = SWdetach(SWid_64);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_64);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath Swath64 %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_64);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath Swath64 %d\n",status););
   }
   
   MESSAGE(6,printf("\t\tDetaching from swath SwathLatonly\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath SwathLatonly\n"););
   status = SWdetach(SWid_lat);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_lat);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath SwathLatonly %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_lat);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath SwathLatonly %d\n",status););
   }

   MESSAGE(6,printf("\t\tDetaching from swath Swathco\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath Swathco\n"););
   status = SWdetach(SWid_co);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_co);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath Swathco %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_co);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath Swathco %d\n",status););
   }

   MESSAGE(6,printf("\t\tDetaching from swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath OnedGeo\n"););
   status = SWdetach(SWid_oned);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_oned);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath OnedGeo %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_oned);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath OnedGeo %d\n",status););
   }

   MESSAGE(6,printf("\t\tDetaching from swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath Simple\n"););
   status = SWdetach(SWid_simple);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_simple);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath Simple %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_simple);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath Simple %d\n",status););
   }

   MESSAGE(6,printf("\t\tDetaching from swath Index\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath Index\n"););
   status = SWdetach(SWid_index);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_index);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath Index %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_index);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath Index %d\n",status););
   }

/* Test case -- SWclose
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWclose... \n"););
   MESSAGE(4,printf("\t================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWclose... \n"););
   MESSAGE(11,fprintf(fp,"\t================== \n"););

   MESSAGE(6,printf("\t\tClosing file Swathc_Test.hdf \n"););
   MESSAGE(11,fprintf(fp,"\t\tClosing file Swathc_Test.hdf \n"););
   status = SWclose(swfidc_test);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWclose(swfidc_test);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWclose for file Swathc_Test.hdf %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWclose(swfidc_test);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWclose for file Swathc_Test.hdf %d\n",status););
   }

   MESSAGE(6,printf("\t\tClosing file Swath_1.hdf \n"););
   MESSAGE(11,fprintf(fp,"\t\tClosing file Swath_1.hdf \n"););
   status = SWclose(swfid_2);
   if(status == -1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWclose(swfid_2);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWclose for file Swath_1.hdf %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWclose(swfid_2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWclose for file Swath_1.hdf %d\n",status););
   }

/* This section creates a SDS using the standard HDF SD interface
** this is here so two routines can be tested
*/
   MESSAGE(6,printf("\t\tCreating SDS to test a couple of functions\n"););
   MESSAGE(11,fprintf(fp,"\t\tCreating SDS to test a couple of functions\n"););
   sd_id = SDstart("Swathc_Test.hdf", DFACC_WRITE);
   if (sd_id == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tsd_id = SDstart(\"Swathc_Test.hdf\", DFACC_WRITE);\n"););
      MESSAGE(8,printf("\t\tSDS file id returned by SDstart %d\n",sd_id););
      MESSAGE(11,fprintf(fp,"\t\tsd_id = SDstart(\"Swathc_Test.hdf\", DFACC_WRITE);\n"););
      MESSAGE(11,fprintf(fp,"\t\tSDS file id returned by SDstart %d\n",sd_id););
   }

   sds1_id = SDcreate(sd_id, "DataOne", DFNT_FLOAT32, rank, dimsizes);
   if (sds1_id == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tsds1_id = SDcreate(sd_id, \"DataOne\", DFNT_FLOAT32, rank, dimsizes);\n"););
      MESSAGE(8,printf("\t\tSDS id returned by SDcreate %d\n",sds1_id););
      MESSAGE(11,fprintf(fp,"\t\tsds1_id = SDcreate(sd_id, \"DataOne\", DFNT_FLOAT32, rank, dimsizes);\n"););
      MESSAGE(11,fprintf(fp,"\t\tSDS id returned by SDcreate %d\n",sds1_id););
   }

   sds2_id = SDcreate(sd_id, "GeoOne", DFNT_FLOAT32, rank, dimsizes);
   if (sds2_id == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tsds2_id = SDcreate(sd_id, \"GeoOne\", DFNT_FLOAT32, rank, dimsizes);\n"););
      MESSAGE(8,printf("\t\tSDS id returned by SDcreate %d\n",sds2_id););
      MESSAGE(11,fprintf(fp,"\t\tsds2_id = SDcreate(sd_id, \"GeoOne\", DFNT_FLOAT32, rank, dimsizes);\n"););
      MESSAGE(11,fprintf(fp,"\t\tSDS id returned by SDcreate %d\n",sds2_id););
   }

   for (i = 0; i < 2; i++) {
      dim_id = SDgetdimid(sds1_id, i);
      if (dim_id == -1)
      {
         MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
         MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
         MESSAGE(4,HEprint(stdout,0););
         MESSAGE(11,HEprint(fp,0););
      }
      switch (i) {
         case 0: status=SDsetdimname(dim_id, "DataTrack");
                 if (status == -1)
                 {
                    MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
                    MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
                    MESSAGE(4,HEprint(stdout,0););
                    MESSAGE(11,HEprint(fp,0););
                 }
                 break;
         case 1: status=SDsetdimname(dim_id, "DataXtrack");
                 if (status == -1)
                 {
                    MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
                    MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
                    MESSAGE(4,HEprint(stdout,0););
                    MESSAGE(11,HEprint(fp,0););
                 }
                 break;
      }
   }
   
   for (i = 0; i < 2; i++) {
      dim_id = SDgetdimid(sds2_id, i);
      if (dim_id == -1)
      {
         MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
         MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
         MESSAGE(4,HEprint(stdout,0););
         MESSAGE(11,HEprint(fp,0););
      }
      switch (i) {
         case 0: status=SDsetdimname(dim_id, "GeoTrack");
                 if (status == -1)
                 {
                    MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
                    MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
                    MESSAGE(4,HEprint(stdout,0););
                    MESSAGE(11,HEprint(fp,0););
                 }
                 break;
         case 1: status=SDsetdimname(dim_id, "GeoXtrack");
                 if (status == -1)
                 {
                    MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
                    MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
                    MESSAGE(4,HEprint(stdout,0););
                    MESSAGE(11,HEprint(fp,0););
                 }
                 break;
      }
   }


   status = SDwritedata(sds1_id, sd_start, sd_stride, sd_edge, ray1);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SDwritedata(sds1_id, sd_start, sd_stride, sd_edge, ray1);\n"););
      MESSAGE(8,printf("\t\tValue returned by SDwritedata %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SDwritedata(sds1_id, sd_start, sd_stride, sd_edge, ray1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SDwritedata %d\n",status););
   }

   status = SDwritedata(sds2_id, sd_start, sd_stride, sd_edge, ray2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SDwritedata(sds2_id, sd_start, sd_stride, sd_edge, ray2);\n"););
      MESSAGE(8,printf("\t\tValue returned by SDwritedata %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SDwritedata(sds2_id, sd_start, sd_stride, sd_edge, ray2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SDwritedata %d\n",status););
   }

   status = SDendaccess(sds1_id);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SDendaccess(sds1_id);\n"););
      MESSAGE(8,printf("\t\tValue returned by SDendaccess %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SDendaccess(sds1_id);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SDendaccess %d\n",status););
   }

   status = SDendaccess(sds2_id);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SDendaccess(sds2_id);\n"););
      MESSAGE(8,printf("\t\tValue returned by SDendaccess %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SDendaccess(sds2_id);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SDendaccess %d\n",status););
   }

   status = SDend(sd_id);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SDend(sd_id);\n"););
      MESSAGE(8,printf("\t\tValue returned by SDend %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SDend(sd_id);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SDend %d\n",status););
   }

   swfidc_test = SWopen("Swathc_Test.hdf", DFACC_RDWR);
   if (swfidc_test == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tswfidc_test = SWopen(\"Swathc_Test.hdf\", DFACC_RDWR);\n"););
      MESSAGE(8,printf("\t\tSwath file id returned by SWopen %d\n",swfidc_test););
      MESSAGE(11,fprintf(fp,"\t\tswfidc_test = SWopen(\"Swathc_Test.hdf\", DFACC_RDWR);\n"););
      MESSAGE(11,fprintf(fp,"\t\tSwath file id returned by SWopen %d\n",swfidc_test););
   }

   SWid_simple = SWattach(swfidc_test, "Simple");
   if (SWid_simple == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_simple = SWattach(swfidc_test, \"Simple\");\n"););
      MESSAGE(8,printf("\t\tSwath id returned by SWattach %d\n",SWid_simple););
      MESSAGE(11,fprintf(fp,"\t\tSWid_simple = SWattach(swfidc_test, \"Simple\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tSwath id returned by SWattach %d\n",SWid_simple););
   }

/* Test Case -- SWwritedatameta & SWwritegeometa
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWwritedatameta... \n"););
   MESSAGE(4,printf("\t============================ \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWwritedatameta... \n"););
   MESSAGE(11,fprintf(fp,"\t============================ \n"););

   MESSAGE(6,printf("\t\tWriting metadata for field defined by SD interface\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting metadata for field defined by SD interface\n"););
   status = SWwritedatameta(SWid_simple, "DataOne", "DataTrack,DataXtrack", DFNT_FLOAT32);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritedatameta(SWid_simple, \"DataOne\", \"DataTrack,DataXtrack\", DFNT_FLOAT32);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritedatameta %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritedatameta(SWid_simple, \"DataOne\", \"DataTrack,DataXtrack\", DFNT_FLOAT32);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritedatameta %d\n",status););
   }

   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWwritegeometa... \n"););
   MESSAGE(4,printf("\t============================ \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWwritegeometa... \n"););
   MESSAGE(11,fprintf(fp,"\t============================ \n"););

   MESSAGE(6,printf("\t\tWriting metatdata for field defined by SD interface\n"););
   MESSAGE(11,fprintf(fp,"\t\tWriting metatdata for field defined by SD interface\n"););
   status = SWwritegeometa(SWid_simple, "GeoOne", "GeoTrack,GeoXtrack", DFNT_FLOAT32);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWwritegeometa(SWid_simple, \"GeoOne\", \"GeoTrack,GeoXtrack\", DFNT_FLOAT32);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWwritegeometa for field GeoOne %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWwritegeometa(SWid_simple, \"GeoOne\", \"GeoTrack,GeoXtrack\", DFNT_FLOAT32);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWwritegeometa for field GeoOne %d\n",status););
   }

   MESSAGE(6,printf("\t\tDetaching from swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath Simple\n"););
   status = SWdetach(SWid_simple);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWdetach(SWid_simple);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach for swath Simple %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWdetach(SWid_simple);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach for swath Simple %d\n",status););
   }

   MESSAGE(6,printf("\t\tClosing file Swathc_Test.hdf\n"););
   MESSAGE(11,fprintf(fp,"\t\tClosing file Swathc_Test.hdf\n"););
   status = SWclose(swfidc_test);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWclose(swfidc_test);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWclose from file Swathc_Test.hdf %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWclose(swfidc_test);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWclose from file Swathc_Test.hdf %d\n",status););
   }


   MESSAGE(6,printf("\t\tOpening file Swathc_test.hdf\n"););
   MESSAGE(11,fprintf(fp,"\t\tOpening file Swathc_test.hdf\n"););
   swfidc_test=SWopen("Swathc_Test.hdf",DFACC_READ);
   if (swfidc_test == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tswfidc_test=SWopen(\"Swathc_test.hdf\",DFACC_READ);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWopen %d\n",swfidc_test););
      MESSAGE(11,fprintf(fp,"\t\tswfidc_test=SWopen(\"Swathc_test.hdf\",DFACC_READ);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWopen %d\n",swfidc_test););
   }

/* Test Case -- SWinqswath
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWinqswath... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWinqswath... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tRetrieving general information about file\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieving general information about file\n"););
   tmpvar=SWinqswath("Swathc_Test.hdf", NULL, &strbufsize);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWinqswath(\"Swathc_Test.hdf\", NULL, &strbufsize);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWinqswath %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWinqswath(\"Swathc_Test.hdf\", NULL, &strbufsize);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWinqswath %d\n",tmpvar););
   }
   buffer1=(char *)malloc(strbufsize + 1);
   tmpvar=SWinqswath("Swathc_Test.hdf", buffer1, &strbufsize);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWinqswath(\"Swathc_Test.hdf\", buffer1, &strbufsize);\n"););
      MESSAGE(8,printf("\t\tList of swath objects %s\n",buffer1););
      MESSAGE(8,printf("\t\tValue returned by SWinqswath %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWinqswath(\"Swathc_Test.hdf\", buffer1, &strbufsize);\n"););
      MESSAGE(11,fprintf(fp,"\t\tList of swath objects %s\n",buffer1););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWinqswath %d\n",tmpvar););
   }
   free(buffer1);

   MESSAGE(6,printf("\t\tAttaching to swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to swath Simple\n"););
   SWid_simple=SWattach(swfidc_test,"Simple");
   if (SWid_simple == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_simple=SWattach(swfidc_test,\"Simple\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattach %d\n",SWid_simple););
      MESSAGE(11,fprintf(fp,"\t\tSWid_simple=SWattach(swfidc_test,\"Simple\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach %d\n",SWid_simple););
   }

   MESSAGE(6,printf("\t\tAttaching to swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to swath OnedGeo\n"););
   SWid_oned=SWattach(swfidc_test,"OnedGeo");
   if (SWid_oned == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_oned=SWattach(swfidc_test,\"OnedGeo\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattach %d\n",SWid_oned););
      MESSAGE(11,fprintf(fp,"\t\tSWid_oned=SWattach(swfidc_test,\"OnedGeo\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach %d\n",SWid_oned););
   }

/* Test Case -- SWgeomapinfo
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWgeomapinfo... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWgeomapinfo... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tAttaching to swath Swath64\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to swath Swath64\n"););
   SWid_64=SWattach(swfidc_test,"Swath64");
   if (SWid_64 == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_64=SWattach(swfidc_test,\"Swath64\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattach %d\n",SWid_64););
      MESSAGE(11,fprintf(fp,"\t\tSWid_64=SWattach(swfidc_test,\"Swath64\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach %d\n",SWid_64););
   }

   MESSAGE(6,printf("\t\tRetrieving mapping info for dimension GeoTrack\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieving mapping info for dimension GeoTrack\n"););
   status = SWgeomapinfo(SWid_64, "GeoTrack");
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWgeomapinfo(SWid_64, \"GeoTrack\");\n"););
      MESSAGE(8,printf("\t\tStatus returned by SWgeomapinfo %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWgeomapinfo(SWid_64, \"GeoTrack\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by SWgeomapinfo %d\n",status););
   }

   MESSAGE(6,printf("\t\tRetrieving mapping info for dimension GeoTrack\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieving mapping info for dimension GeoTrack\n"););
   status = SWgeomapinfo(SWid_simple, "GeoTrack");
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWgeomapinfo(SWid_simple, \"GeoTrack\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWgeomapinfo %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWgeomapinfo(SWid_simple, \"GeoTrack\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWgeomapinfo %d\n",status););
   }

   MESSAGE(6,printf("\t\tAttaching to swath Index\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to swath Index\n"););
   SWid_index=SWattach(swfidc_test,"Index");
   if (SWid_index == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_index=SWattach(swfidc_test,\"Index\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattach %d\n",SWid_index););
      MESSAGE(11,fprintf(fp,"\t\tSWid_index=SWattach(swfidc_test,\"Index\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach %d\n",SWid_index););
   }

   MESSAGE(6,printf("\t\tRetrieving mapping info for dimension GeoDim\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieving mapping info for dimension GeoDim\n"););
   status = SWgeomapinfo(SWid_index, "GeoDim");
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus = SWgeomapinfo(SWid_index, \"GeoDim\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWgeomapinfo %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus = SWgeomapinfo(SWid_index, \"GeoDim\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWgeomapinfo %d\n",status););
   }

   MESSAGE(6,printf("\t\tDetaching from swath Index\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath Index\n"););
   status=SWdetach(SWid_index);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdetach(SWid_index);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdetach(SWid_index);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach %d\n",status););
   }


   MESSAGE(6,printf("\t\tDetaching to swath Swath64\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching to swath Swath64\n"););
   status=SWdetach(SWid_64);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdetach(SWid_64);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach %d\n",SWid_64););
      MESSAGE(11,fprintf(fp,"\t\tSWid_64=SWdetach(SWid_64);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach %d\n",SWid_64););
   }




/* Test Case -- SWdefvrtregion
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWdefvrtregion... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWdefvrtregion... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   range[0]=46353450.0;
   range[1]=46500000.0;

   regionID = SWdefvrtregion(SWid_oned,HDFE_NOPREVSUB,"Time",range);
   if (regionID == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(8,printf("\t\tRegion id returned by SWdefvrtregion %d\n",regionID););
      MESSAGE(11,fprintf(fp,"\t\tRegion id returned by SWdefvrtregion %d\n",regionID););
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
   }


   MESSAGE(6,printf("\t\tDetach to swath OnedGeo\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetach to swath OnedGeo\n"););
   status=SWdetach(SWid_oned);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdetach(SWid_oned);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdetach(SWid_oned);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach %d\n",status););
   }


/* Test Case -- SWinqattrs
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWinqattrs... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWinqattrs... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   tmpvar=SWinqattrs(SWid_simple, NULL, &strbufsize);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWinqattrs(SWid_simple, NULL, &strbufsize);\n"););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWinqattrs(SWid_simple, NULL, &strbufsize);\n"););
      MESSAGE(8,printf("\t\tStatus returned by SWinqattrs %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by SWinqattrs %d\n",tmpvar););
   }
   buffer1=(char *)malloc(strbufsize + 1);
   tmpvar=SWinqattrs(SWid_simple, buffer1, &strbufsize);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWinqattrs(SWid_simple, buffer1, &strbufsize);\n"););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWinqattrs(SWid_simple, buffer1, &strbufsize);\n"););
      MESSAGE(8,printf("\t\tLength in bytes of attributes %d\n",strbufsize););
      MESSAGE(8,printf("\t\tAttributes in swath %s\n",buffer1););
      MESSAGE(8,printf("\t\tStatus returned by SWinqattr %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\tLength in bytes of attributes %d\n",strbufsize););
      MESSAGE(11,fprintf(fp,"\t\tAttributes in swath %s\n",buffer1););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by SWinqattr %d\n",tmpvar););
   }
   free(buffer1);
 
/* Test Case -- SWnentries
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWnentries... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWnentries... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););
 

   MESSAGE(6,printf("\t\tRetrieve number of dimensions in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve number of dimensions in swath Simple\n"););
   tmpvar=SWnentries(SWid_simple,0,&strbufsize);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWnentries(SWid_simple,0,&strbufsize);\n"););
      MESSAGE(8,printf("\t\tLength of dimensions in bytes %d\n",strbufsize););
      MESSAGE(8,printf("\t\tNumber of dimensions  %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWnentries(SWid_simple,0,&strbufsize);\n"););
      MESSAGE(11,fprintf(fp,"\t\tLength of dimensions in bytes %d\n",strbufsize););
      MESSAGE(11,fprintf(fp,"\t\tNumber of dimensions  %d\n",tmpvar););
   }
   tempvar1=(int32 *)calloc(tmpvar,4);
   buffer1=(char *)calloc(strbufsize+2,1);

/* Test Case -- SWinqdims
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWinqdims... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWinqdims... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););
 
   MESSAGE(6,printf("\t\tRetrieve the dimension list for swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve the dimension list for swath Simple\n"););
   tmpvar=SWinqdims(SWid_simple,buffer1,tempvar1);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWinqdims(SWid_simple,buffer1,tempvar1);\n"););
      MESSAGE(8,printf("\t\tDimension list for swath Simple %s\n",buffer1););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWinqdims(SWid_simple,buffer1,tempvar1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tDimension list for swath Simple %s\n",buffer1););
   }
   free(tempvar1);
   free(buffer1);

/* Test Case -- SWinqmaps
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWinqmaps... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWinqmaps... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););
 
   MESSAGE(6,printf("\t\tRetrieve dimension mappings in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve dimension mappings in swath Simple\n"););
   tmpvar=SWnentries(SWid_simple,1,&strbufsize);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWnentries(SWid_simple,1,&strbufsize);\n"););
      MESSAGE(8,printf("\t\tNumber of dimension mappings %d\n",tmpvar););
      MESSAGE(8,printf("\t\tLength of mappings in bytes %d\n",strbufsize););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWnentries(SWid_simple,1,&strbufsize);\n"););
      MESSAGE(11,fprintf(fp,"\t\tNumber of dimension mappings %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\tLength of mappings in bytes %d\n",strbufsize););
   }
   tempvar1=(int32 *)calloc(tmpvar,4);
   tempvar2=(int32 *)calloc(tmpvar,4);
   buffer1=(char *)calloc(strbufsize+2,1);

   MESSAGE(6,printf("\t\tRetrieve the geolocation relations for swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve the geolocation relations for swath Simple\n"););
   tmpvar=SWinqmaps(SWid_simple,buffer1,tempvar1,tempvar2);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWinqmaps(SWid_simple,buffer1,tempvar1,tempvar2);\n"););
      MESSAGE(8,printf("\t\tNumber of maps %d\n",tmpvar););
      MESSAGE(6,printf("\t\tGeolocation relations for swath Simple %s\n",buffer1););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWinqmaps(SWid_simple,buffer1,tempvar1,tempvar2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tNumber of maps %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\tGeolocation relations for swath Simple %s\n",buffer1););
   }
   free(tempvar1);
   free(tempvar2);
   free(buffer1);

   MESSAGE(6,printf("\t\tRetrieve the Index dimension mappings in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve the Index dimension mappings in swath Simple\n"););
   tmpvar=SWnentries(SWid_simple,2,&strbufsize);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWnentries(SWid_simple,2,&strbufsize);\n"););
      MESSAGE(8,printf("\t\tNumber of Indexed mappings %d\n",tmpvar););
      MESSAGE(8,printf("\t\tLength of mappings in bytes %d\n",strbufsize););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWnentries(SWid_simple,2,&strbufsize);\n"););
      MESSAGE(11,fprintf(fp,"\t\tNumber of Indexed mappings %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\tLength of mappings in bytes %d\n",strbufsize););
   }

/* Test Case -- SWinqgeofields
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWinqgeofields... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWinqgeofields... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););
 
   MESSAGE(6,printf("\t\tNumber of Geolocation fields in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tNumber of Geolocation fields in swath Simple\n"););
   tmpvar=SWnentries(SWid_simple,3,&strbufsize);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWnentries(SWid_simple,3,&strbufsize);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWnentries %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWnentries(SWid_simple,3,&strbufsize);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWnentries %d\n",tmpvar););
   }
   tempvar1=(int32 *)calloc(tmpvar,4);
   tempvar2=(int32 *)calloc(tmpvar,4);
   buffer1=(char *)calloc(strbufsize+2,1);

   MESSAGE(6,printf("\t\tRetrieve the Geolocation fields in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve the Geolocation fields in swath Simple\n"););
   tmpvar=SWinqgeofields(SWid_simple,buffer1,tempvar1,tempvar2);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWinqgeofields(SWid_simple,buffer1,tempvar1,tempvar2);\n"););
      MESSAGE(8,printf("\t\tGeolocation fields in swath Simple %s\n",buffer1););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWinqgeofields(SWid_simple,buffer1,tempvar1,tempvar2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tGeolocation fields in swath Simple %s\n",buffer1););
   }
   free(tempvar1);
   free(tempvar2);
   free(buffer1);

/* Test Case -- SWinqdatafields
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWinqdatafields... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWinqdatafields... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););
 
   MESSAGE(6,printf("\t\tNumber of Data fields in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tNumber of Data fields in swath Simple\n"););
   tmpvar=SWnentries(SWid_simple,4,&strbufsize);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWnentries(SWid_simple,4,&strbufsize);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWnentries %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWnentries(SWid_simple,4,&strbufsize);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWnentries %d\n",tmpvar););
   }
   tempvar1=(int32 *)calloc(tmpvar,4);
   tempvar2=(int32 *)calloc(tmpvar,4);
   buffer1=(char *)calloc(strbufsize+2,1);

   MESSAGE(6,printf("\t\tRetrieve the Data fields in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve the Data fields in swath Simple\n"););
   tmpvar=SWinqdatafields(SWid_simple,buffer1,tempvar1,tempvar2);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWinqdatafielda(SWid_simple,buffer1,tempvar1,tempvar2);\n"););
      MESSAGE(8,printf("\t\tData fields in swath Simple %s\n",buffer1););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWinqdatafielda(SWid_simple,buffer1,tempvar1,tempvar2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tData fields in swath Simple %s\n",buffer1););
   }
   free(tempvar1);
   free(tempvar2);
   free(buffer1);

/* Test Case -- SWdiminfo
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWdiminfo... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(6,printf("\t\tRetrieve size of dimension DataXtrack in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWdiminfo... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve size of dimension DataXtrack in swath Simple\n"););

   tmpvar=SWdiminfo(SWid_simple,"DataXtrack");
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWdiminfo(SWid_simple,\"DataXtrack\");\n"););
      MESSAGE(8,printf("\t\tSize of dimension DataXtrack in swath Simple %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWdiminfo(SWid_simple,\"DataXtrack\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tSize of dimension DataXtrack in swath Simple %d\n",tmpvar););
   }

/* Test Case -- SWreadfield
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWreadfield... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWreadfield... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););
   tmpvar=SWreadfield(SWid_simple,"Temperature",inqstart,inqstride,inqedge,tmpray);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWreadfield(SWid_simple,\"Temperature\",inqstart,inqstride,inqedge,tmpray);\n"););
      MESSAGE(8,printf("\t\tStatus return from call to SWreadfield %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWreadfield(SWid_simple,\"Temperature\",inqstart,inqstride,inqedge,tmpray);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus return from call to SWreadfield %d\n",tmpvar););
      for(ii=10;ii<20;ii++)
      {
         for(j=10;j<15;j++)
         {
            MESSAGE(8,printf("\t\tTemperature value at %d %d = %f\n",ii,j,tmpray[ii][j]););
            MESSAGE(11,fprintf(fp,"\t\tTemperature value at %d %d = %f\n",ii,j,tmpray[ii][j]););
         }
      }
   }

/* Test Case -- SWfieldinfo
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWfieldinfo... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWfieldinfo... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tRetrieve information for field Latitude in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve information for field Latitude in swath Simple\n"););
   tmpvar=SWfieldinfo(SWid_simple,"Latitude",&var1,ray,&var2,dimlist);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWfieldinfo(SWid_simple,\"Latitude\",&var1,ray,&var2,dimlist);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWfieldinfo %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWfieldinfo(SWid_simple,\"Latitude\",&var1,ray,&var2,dimlist);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWfieldinfo %d\n",tmpvar););
      MESSAGE(8,printf("\t\tRank of field %d Number type of field %d\n",var1,var2););
      MESSAGE(8,printf("\t\tDimension list of field %s\n",dimlist););
      MESSAGE(11,fprintf(fp,"\t\tRank of field %d Number type of field %d\n",var1,var2););
      MESSAGE(11,fprintf(fp,"\t\tDimension list of field %s\n",dimlist););
   }

/* Test Case -- SWmapinfo
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWmapinfo... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWmapinfo... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tRetrieve offset an increment of geolocation mapping\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve offset an increment of geolocation mapping\n"););
   tmpvar=SWmapinfo(SWid_simple,"GeoTrack","DataTrack",&var1,&var2);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWmapinfo(SWid_simple,\"GeoTrack\",\"DataTrack\",&var1,&var2);\n"););
       MESSAGE(8,printf("\t\tValue returned by SWmapinfo %d\n",tmpvar););
      MESSAGE(8,printf("\t\tOffset %d, Increment %d\n",var1,var2););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWmapinfo(SWid_simple,\"GeoTrack\",\"DataTrack\",&var1,&var2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWmapinfo %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\tOffset %d, Increment %d\n",var1,var2););
   }

/* Test Case -- SWattrinfo
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWattrinfo... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWattrinfo... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tRetrieve information about attribute Drift\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve information about attribute Drift\n"););
   status=SWattrinfo(SWid_simple,"Drift",&var1,&var2);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWattrinfo(SWid_simple,\"Drift\",&var1,&var2);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattrinfo %d\n",status););
      MESSAGE(6,printf("\t\tNumber type and count in bytes of attribute %d %d\n",var1,var2););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWattrinfo(SWid_simple,\"Drift\",&var1,&var2);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattrinfo %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tNumber type and count in bytes of attribute %d %d\n",var1,var2););
   }

/* Test Case -- SWreadattr
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWreadattr... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWreadattr... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tRead attribute info from swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tRead attribute info from swath Simple\n"););
   tmpvar=SWreadattr(SWid_simple,"Drift",ray);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWreadattr(SWid_simple,\"Drift\",ray);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWreadattr %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWreadattr(SWid_simple,\"Drift\",ray);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWreadattr %d\n",tmpvar););
      for(ii=0;ii<4;ii++)
      {
         MESSAGE(8,printf("\t\tValue of attribute %d\n",ray[ii]););
         MESSAGE(11,fprintf(fp,"\t\tValue of attribute %d\n",ray[ii]););
      }
   }

/* Test Case -- SWcompinfo
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWcompinfo... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWcompinfo... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tRetrieve Compression information for field Temperature\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve Compression information for field Temperature\n"););
   status = SWcompinfo(SWid_simple,"Temperature",&compcode,compparm);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(8,printf("\t\tCompression code %d, Compression Parameter %d\n",compcode,compparm[0]););
      MESSAGE(11,fprintf(fp,"\t\tCompression code %d, Compression Parameter %d\n",compcode,compparm[0]););
   }


/* Test Case -- SWgetfillvalue
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWgetfillvalue... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWgetfillvalue... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tGet fill value of field Conduction\n"););
   MESSAGE(11,fprintf(fp,"\t\tGet fill value of field Conduction\n"););
   tmpvar=SWgetfillvalue(SWid_simple,"Conduction",&inqfill);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWgetfillvalue(SWid_simple,\"Conduction\",&inqfill);\n"););
      MESSAGE(8,printf("\t\tStatus returned by SWgetfillvalue %d\n",tmpvar););
      MESSAGE(8,printf("\t\tFill value for field Conduction %f\n",inqfill););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWgetfillvalue(SWid_simple,\"Conduction\",&inqfill);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWgetfillvalue %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\tFill value for field Conduction %f\n",inqfill););
   }


   MESSAGE(6,printf("\t\tGet fill value of field X\n"););
   MESSAGE(11,fprintf(fp,"\t\tGet fill value of field X\n"););
   tmpvar=SWgetfillvalue(SWid_simple,"X",&inqfill);
   if (tmpvar==-1)
   {
      MESSAGE(4,printf("\t\t********Error expected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error expected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWgetfillvalue(SWid,\"X\",&inqfill);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWgetfillvalue %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWgetfillvalue(SWid,\"X\",&inqfill);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWgetfillvalue %d\n",tmpvar););
   }

   
   corlon[0]=75.5;
   corlat[0]=35.5;
   corlon[1]=77.5;
   corlat[1]=36.5;


/* Test Case -- SWdefboxregion
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWdefboxregion... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWdefboxregion... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tDefining region to extract\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining region to extract\n"););
   tmpvar=SWdefboxregion(SWid_simple,corlon,corlat,HDFE_MIDPOINT);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWdefboxregion(SWid_simple,corlon,corlat,HDFE_MIDPOINT);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdefboxregion %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWdefboxregion(SWid_simple,corlon,corlat,HDFE_MIDPOINT);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdefboxregion %d\n",tmpvar););
   }

/* Test Case -- SWindexinfo
*/
   for ( i = 0; i < 8; i++)
   {
       ind[i] = (int32 *) malloc(2*sizeof(int32));
   }

   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWindexinfo... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWindexinfo... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tRetrieve indices for field Longitude in swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieve indices for field Longitude in swath Simple\n"););
   tmpvar3=SWindexinfo(tmpvar,"Longitude",&rank,dimlist,ind);
   if (tmpvar3 == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar3=SWindexinfo(tmpvar,\"Longitude\",&rank ,dimlist,ind);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWindexinfo %d\n",tmpvar3););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar3=SWindexinfo(tmpvar,\"Longitude\",& rank,dimlist,ind);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWindexinfo %d\n",tmpvar3););
      MESSAGE(4,printf("\t\tRank of field %d\n",rank););
      MESSAGE(4,printf("\t\tDimension list of field %s\n",dimlist););
      MESSAGE(11,fprintf(fp,"\t\tRank of field %d\n",rank););
      MESSAGE(11,fprintf(fp,"\t\tDimension list of field %s\n",dimlist););
      for(i=0;i<rank;i++)
      {
         for(j=0;j<2;j++)
         {
            MESSAGE(4,printf("\t\tind[%d][%d]  %d\n",i,j,ind[i][j]););
            MESSAGE(11,fprintf(fp,"\t\tind[%d][%d]  %d\n",i,j,ind[i][j]););
         }
      }

   }

   for ( i = 0; i < 8; i++)
   {
       free(ind[i]);
   }
   
/* Test Case -- SWdupregion
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWdupregion... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWdupregion... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tDuplicate region id \n"););
   MESSAGE(11,fprintf(fp,"\t\tDuplicate region id \n"););
   regionID = SWdupregion(tmpvar);
   if (regionID == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tregionID = SWdupregion(tmpvar);\n"););
      MESSAGE(8,printf("\t\tRegion Id returned from call to SWdupregion %d\n",regionID););
      MESSAGE(11,fprintf(fp,"\t\tregionID = SWdupregion(tmpvar);\n"););
      MESSAGE(11,fprintf(fp,"\t\tRegion Id returned from call to SWdupregion %d\n",regionID););
   }



/* Test Case -- SWregioninfo
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWregioninfo... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWregioninfo... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tRetrieving information about region\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieving information about region\n"););
   tmpvar2=SWregioninfo(SWid_simple,tmpvar,"Temperature",&var1,&var2,ray,&var3);
   if (tmpvar2 == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar2=SWregioninfo(SWid_simple,tmpvar,\"Temperature\",&var1,&var2,ray,&var3);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWregioninfo %d\n",tmpvar2););
      MESSAGE(6,printf("\t\tNumber type of field %d\n",var1););
      MESSAGE(6,printf("\t\tRank of field %d\n",var2););
      MESSAGE(6,printf("\t\tDimensions of region information %d %d\n",ray[0],ray[1]););
      MESSAGE(6,printf("\t\tSize in bytes of region %d\n",var3););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar2=SWregioninfo(SWid_simple,tmpvar,\"Temperature\",&var1,&var2,ray,&var3);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWregioninfo %d\n",tmpvar2););
      MESSAGE(11,fprintf(fp,"\t\tNumber type of field %d\n",var1););
      MESSAGE(11,fprintf(fp,"\t\tRank of field %d\n",var2););
      MESSAGE(11,fprintf(fp,"\t\tDimensions of region information %d %d\n",ray[0],ray[1]););
      MESSAGE(11,fprintf(fp,"\t\tSize in bytes of region %d\n",var3););
   }


/* Test Case -- SWextractregion
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWextractregion... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWextractregion... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tExtracting data from region\n"););
   MESSAGE(11,fprintf(fp,"\t\tExtracting data from region\n"););
   datbuf=(float32 *)malloc(var3);
   tmpvar2=SWextractregion(SWid_simple,tmpvar,"Temperature",HDFE_INTERNAL,datbuf);
   if (tmpvar2 == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar2=SWextractregion(SWid_simple,tmpvar,\"Temperature\",HDFE_INTERNAL,datbuf);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWextractregion %d\n",tmpvar2););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar2=SWextractregion(SWid_simple,tmpvar,\"Temperature\",HDFE_INTERNAL,datbuf);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWextractregion %d\n",tmpvar2););
      k=0;
      for(i=0;i<10;i++)
      {
         for(j=0;j<5;j++)
         {
            MESSAGE(6,printf("\t\t%d  %d  %f\n",i,j,datbuf[k]););
            MESSAGE(11,fprintf(fp,"\t\t%d  %d  %f\n",i,j,datbuf[k]););
            k++;
         }
      }
   }
   free(datbuf);

   MESSAGE(6,printf("\t\tRetrieving information about region\n"););
   MESSAGE(11,fprintf(fp,"\t\tRetrieving information about region\n"););
   tmpvar2=SWregioninfo(SWid_simple,tmpvar,"Latitude",&var1,&var2,ray,&var3);
   if (tmpvar2 == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar2=SWregioninfo(SWid_simple,tmpvar,\"Latitude\",&var1,&var2,ray,&var3);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWregioninfo %d\n",tmpvar2););
      MESSAGE(6,printf("\t\tNumber type of field %d\n",var1););
      MESSAGE(6,printf("\t\tRank of field %d\n",var2););
      MESSAGE(6,printf("\t\tDimensions of region information %d %d\n",ray[0],ray[1]););
      MESSAGE(6,printf("\t\tSize in bytes of region %d\n",var3););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar2=SWregioninfo(SWid_simple,tmpvar,\"Latitude\",&var1,&var2,ray,&var3);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWregioninfo %d\n",tmpvar2););
      MESSAGE(11,fprintf(fp,"\t\tNumber type of field %d\n",var1););
      MESSAGE(11,fprintf(fp,"\t\tRank of field %d\n",var2););
      MESSAGE(11,fprintf(fp,"\t\tDimensions of region information %d %d\n",ray[0],ray[1]););
      MESSAGE(11,fprintf(fp,"\t\tSize in bytes of region %d\n",var3););
   }

   MESSAGE(6,printf("\t\tExtracting data from region\n"););
   MESSAGE(11,fprintf(fp,"\t\tExtracting data from region\n"););
   datbuf=(float32 *)malloc(var3);
   tmpvar2=SWextractregion(SWid_simple,tmpvar,"Latitude",HDFE_INTERNAL,datbuf);
   if (tmpvar2 == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar2=SWextractregion(SWid_simple,tmpvar,\"Latitude\",HDFE_INTERNAL,datbuf);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWextractregion %d\n",tmpvar2););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar2=SWextractregion(SWid_simple,tmpvar,\"Latitude\",HDFE_INTERNAL,datbuf);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWextractregion %d\n",tmpvar2););
      k=0;
      for(i=0;i<10;i++)
      {
         for(j=0;j<5;j++)
         {
            MESSAGE(6,printf("\t\t%d  %d  %f\n",i,j,datbuf[k]););
            MESSAGE(11,fprintf(fp,"\t\t%d  %d  %f\n",i,j,datbuf[k]););
            k++;
         }
      }
   }
   free(datbuf);

   MESSAGE(6,printf("\t\tDetaching from swath Simple\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath Simple\n"););
   status=SWdetach(SWid_simple);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdetach(SWid_simple);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdetach(SWid_simple);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach %d\n",status););
   }

   MESSAGE(6,printf("\t\tAttaching to swath Swathco\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to swath Swathco\n"););
   SWid_co=SWattach(swfidc_test,"Swathco");
   if (SWid_co == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_co=SWattach(swfidc_test,\"Swathco\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattach %d\n",SWid_co););
      MESSAGE(11,fprintf(fp,"\t\tSWid_co=SWattach(swfidc_test,\"Swathco\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach %d\n",SWid_co););
   }


/* Test Case -- SWdeftimeperiod
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWdeftimeperiod... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWdeftimeperiod... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   starttime=46353450.0;
   stoptime=46500000.0;
   MESSAGE(6,printf("\t\tDefining time period for extraction\n"););
   MESSAGE(11,fprintf(fp,"\t\tDefining time period for extraction\n"););
   tmpvar=SWdeftimeperiod(SWid_co,starttime,stoptime,HDFE_MIDPOINT);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWdeftimeperiod(SWid_co,starttime,stoptime,HDFE_MIDPOINT);\n"););
      MESSAGE(8,printf("\t\tRegion id returned by SWdeftimeperiod %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWdeftimeperiod(SWid_co,starttime,stoptime,HDFE_MIDPOINT);\n"););
      MESSAGE(11,fprintf(fp,"\t\tRegion id returned by SWdeftimeperiod %d\n",tmpvar););
   }

/* Test Case -- SWperiodinfo
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWperiodinfo... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWperiodinfo... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   status=SWperiodinfo(SWid_co,tmpvar,"BandC",&var1,&var2,ray,&var3);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWperiodinfo(SWid_co,tmpvar,\"BandC\",&var1,&var2,ray,&var3);\n"););
      MESSAGE(8,printf("\t\tStatus returned by SWperiodinfo %d\n",status););
      MESSAGE(6,printf("\t\tNumber type of region %d, Rank of region %d\n",var1,var2););
      MESSAGE(6,printf("\t\tDimensions of region %d %d\n",ray[0],ray[1]););
      MESSAGE(6,printf("\t\tSize of region in bytes %d\n",var3););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWperiodinfo(SWid_co,tmpvar,\"BandC\",&var1,&var2,ray,&var3);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by SWperiodinfo %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tNumber type of region %d, Rank of region %d\n",var1,var2););
      MESSAGE(11,fprintf(fp,"\t\tDimensions of region %d %d\n",ray[0],ray[1]););
      MESSAGE(11,fprintf(fp,"\t\tSize of region in bytes %d\n",var3););
   }

   status=SWperiodinfo(SWid_co,tmpvar,"Time",&var1,&var2,ray,&var3);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWperiodinfo(SWid_co,tmpvar,\"Time\",&var1,&var2,ray,&var3);\n"););
      MESSAGE(8,printf("\t\tStatus returned by SWperiodinfo %d\n",status););
      MESSAGE(6,printf("\t\tNumber type of region %d, Rank of region %d\n",var1,var2););
      MESSAGE(6,printf("\t\tDimensions of region %d %d\n",ray[0],ray[1]););
      MESSAGE(6,printf("\t\tSize of region in bytes %d\n",var3););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWperiodinfo(SWid_co,tmpvar,\"Time\",&var1,&var2,ray,&var3);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by SWperiodinfo %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tNumber type of region %d, Rank of region %d\n",var1,var2););
      MESSAGE(11,fprintf(fp,"\t\tDimensions of region %d %d\n",ray[0],ray[1]););
      MESSAGE(11,fprintf(fp,"\t\tSize of region in bytes %d\n",var3););
   }

/* Test Case -- SWextractperiod
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWextractperiod... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWextractperiod... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   timebuf=(float64 *)malloc(var3);
   status=SWextractperiod(SWid_co,tmpvar,"Time",HDFE_INTERNAL,timebuf);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWextractperiod(SWid_co,tmpvar,\"Time\",HDFE_INTERNAL,timebuf);\n"););
      MESSAGE(8,printf("\t\tStatus returned by SWextractperiod %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWextractperiod(SWid_co,tmpvar,\"Time\",HDFE_INTERNAL,timebuf);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by SWextractperiod %d\n",status););
      k=0;
      for(i=0;i<10;i++)
      {
         for(j=0;j<5;j++)
         {
            MESSAGE(6,printf("\t\t%d  %d  %f\n",i,j,timebuf[k]););
            MESSAGE(11,fprintf(fp,"\t\t%d  %d  %f\n",i,j,timebuf[k]););
            k++;
         }
      }
   }
   free(timebuf);


   MESSAGE(6,printf("\t\tDetaching from swath Swathco\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath Swathco\n"););
   status=SWdetach(SWid_co);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdetach(SWid_co);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdetach(SWid_co);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach %d\n",status););
   }

   MESSAGE(6,printf("\t\tAttaching to swath Index\n"););
   MESSAGE(11,fprintf(fp,"\t\tAttaching to swath Index\n"););
   SWid_index=SWattach(swfidc_test, "Index");
   if (SWid_index == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tSWid_index=SWattach(swfidc_test, \"Index\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWattach %d\n",SWid_index););
      MESSAGE(11,fprintf(fp,"\t\tSWid_index=SWattach(swfidc_test, \"Index\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWattach %d\n",SWid_index););
   }

   MESSAGE(6,printf("\t\tmappings in swath Index\n"););
   MESSAGE(11,fprintf(fp,"\t\tmappings in swath Index\n"););
   tmpvar=SWnentries(SWid_index, 2, &strbufsize);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWnentries(SWid_index, 2, &strbufsize);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWnentries %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWnentries(SWid_index, 2, &strbufsize);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWnentries %d\n",tmpvar););
   }

/* Test Case -- SWinqidxmaps
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWinqidxmaps... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWinqidxmaps... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   tempvar1=(int32 *)calloc(tmpvar, 4);
   buffer1=(char *)calloc(strbufsize+2,1);
   tmpvar=SWinqidxmaps(SWid_index, buffer1, tempvar1);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWinqidxmaps(SWid_index, buffer1, tempvar1);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWinqidxmaps %d\n",tmpvar););
      MESSAGE(8,printf("\t\tIndexed Maps %s\n",buffer1););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWinqidxmaps(SWid_index, buffer1, tempvar1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWinqidxmaps %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\tIndexed Maps %s\n",buffer1););
      for(i=0;i<tmpvar;i++)
      {
         MESSAGE(6,printf("\t\tDimension map %d\n", tempvar1[i]););
         MESSAGE(11,fprintf(fp,"\t\tDimension map %d\n", tempvar1[i]););
      }
   }

   free(tempvar1);
   free(buffer1);

   tmpvar=SWdiminfo(SWid_index, "GeoDim");
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWdiminfo(SWid_index, \"GeoDim\");\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdiminfo %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWdiminfo(SWid_index, \"GeoDim\");\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdiminfo %d\n",tmpvar););
   }

/* Test Case -- SWidxmapinfo
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWidxmapinfo... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWidxmapinfo... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   tempvar1=(int32 *)calloc(tmpvar, 4);
   tempvar3=(int32 *)calloc(tmpvar, 4);

   tmpvar=SWidxmapinfo(SWid_index, "GeoDim", "TrackDim",tempvar1);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWidxmapinfo(SWid_index, \"GeoDim\", \"TrackDim\",tempvar1);\n"););
      MESSAGE(8,printf("\t\tNumber of indexed map entries %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWidxmapinfo(SWid_index, \"GeoDim\", \"TrackDim\",tempvar1);\n"););
      MESSAGE(11,fprintf(fp,"\t\tNumber of indexed map entries %d\n",tmpvar););
      for(i=0;i<tmpvar;i++)
      {
         MESSAGE(6,printf("\t\tIndex mapping entry %d = %d\n",i,tempvar1[i]););
         MESSAGE(11,fprintf(fp,"\t\tIndex mapping entry %d = %d\n",i,tempvar1[i]););
      }
   }

   tmpvar=SWidxmapinfo(SWid_index, "GeoXDim", "XtrackDim",tempvar3);
   if (tmpvar == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\ttmpvar=SWidxmapinfo(SWid_index, \"GeoXDim\", \"XtrackDim\",tempvar3);\n"););
      MESSAGE(8,printf("\t\tNumber of indexed map entries %d\n",tmpvar););
      MESSAGE(11,fprintf(fp,"\t\ttmpvar=SWidxmapinfo(SWid_index, \"GeoXDim\", \"XtrackDim\",tempvar3);\n"););
      MESSAGE(11,fprintf(fp,"\t\tNumber of indexed map entries %d\n",tmpvar););
      for(i=0;i<tmpvar;i++)
      {
         MESSAGE(6,printf("\t\tIndex mapping entry %d = %d\n",i,tempvar3[i]););
         MESSAGE(11,fprintf(fp,"\t\tIndex mapping entry %d = %d\n",i,tempvar3[i]););
      }
   }

   corlat[0]=37.0;
   corlat[1]=38.5;
   corlon[0]=76.0;
   corlon[1]=77.5;

   regionID=SWdefboxregion(SWid_index,corlon,corlat,HDFE_MIDPOINT);
   if (regionID == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tregionID=SWdefboxregion(SWid_index,corlon,corlat,HDFE_MIDPOINT);\n"););
      MESSAGE(8,printf("\t\tRegion ID returned by SWdefboxregion %d\n",regionID););
      MESSAGE(11,fprintf(fp,"\t\tregionID=SWdefboxregion(SWid_index,corlon,corlat,HDFE_MIDPOINT);\n"););
      MESSAGE(11,fprintf(fp,"\t\tRegion ID returned by SWdefboxregion %d\n",regionID););
   }

   status=SWregioninfo(SWid_index,regionID,"Fakedata",&var1,&var2,ray,&var3);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWregioninfo(SWid_index,regionID,\"Fakedata\",&var1,&var2,ray,&var3);\n"););
      MESSAGE(8,printf("\t\tStatus returned by SWregioninfo %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWregioninfo(SWid_index,regionID,\"Fakedata\",&var1,&var2,ray,&var3);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by SWregioninfo %d\n",status););
      MESSAGE(6,printf("\t\tNumber type of field %d\n",var1););
      MESSAGE(6,printf("\t\tRank of field %d\n",var2););
      MESSAGE(6,printf("\t\tDimensions of region information %d %d\n",ray[0],ray[1]););
      MESSAGE(6,printf("\t\tSize in bytes of region %d\n",var3););
      MESSAGE(11,fprintf(fp,"\t\tNumber type of field %d\n",var1););
      MESSAGE(11,fprintf(fp,"\t\tRank of field %d\n",var2););
      MESSAGE(11,fprintf(fp,"\t\tDimensions of region information %d %d\n",ray[0],ray[1]););
      MESSAGE(11,fprintf(fp,"\t\tSize in bytes of region %d\n",var3););
   }


   MESSAGE(6,printf("\t\tExtracting data from Fakedata\n"););
   MESSAGE(11,fprintf(fp,"\t\tExtracting data from Fakedata\n"););
   datbuf=(float32 *)malloc(var3);
   status=SWextractregion(SWid_index,regionID,"Fakedata",HDFE_INTERNAL,datbuf);
   if (tmpvar2 == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWextractregion(SWid_index,regionID,\"Fakedata\",HDFE_INTERNAL,datbuf);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWextractregion %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWextractregion(SWid_index,regionID,\"Fakedata\",HDFE_INTERNAL,datbuf);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWextractregion %d\n",status););
      k=0;
      for(i=0;i<10;i++)
      {
         MESSAGE(6,printf("\t\t%d  %f\n",i,datbuf[k]););
         MESSAGE(11,fprintf(fp,"\t\t%d  %f\n",i,datbuf[k]););
         k++;
      }
   }
   free(datbuf);

/* Test Case -- SWupdateidxmap
*/
   MESSAGE(4,printf("\n"););
   MESSAGE(4,printf("\tTesting SWupdateidxmap... \n"););
   MESSAGE(4,printf("\t====================== \n"););
   MESSAGE(11,fprintf(fp,"\f\n"););
   MESSAGE(11,fprintf(fp,"\tTesting SWupdateidxmap... \n"););
   MESSAGE(11,fprintf(fp,"\t====================== \n"););

   MESSAGE(6,printf("\t\tUpdate index mapping for subsetted swath\n"););
   MESSAGE(11,fprintf(fp,"\t\tUpdate index mapping for subsetted swath\n"););
   idxmapsize=SWupdateidxmap(SWid_index,regionID,tempvar1,NULL,indicies);
   if (idxmapsize == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tidxmapsize=SWupdateidxmap(SWid_index,regionID,tempvar1,NULL,indicies);\n"););
      MESSAGE(8,printf("\t\tSize of updated mapping %d\n",idxmapsize););
      MESSAGE(11,fprintf(fp,"\t\tidxmapsize=SWupdateidxmap(SWid_index,regionID,tempvar1,NULL,indicies);\n"););
      MESSAGE(11,fprintf(fp,"\t\tSize of updated mapping %d\n",idxmapsize););
   }
   

   update_index1=(int32 *)calloc(idxmapsize,4);
   idxmapsize=SWupdateidxmap(SWid_index,regionID,tempvar1,update_index1,indicies);
   if(idxmapsize == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tidxmapsize=SWupdateidxmap(SWid_index,regionID,tempvar1,update_index1,indicies);\n"););
      MESSAGE(8,printf("\t\tSize of updated mapping %d\n",idxmapsize););
      MESSAGE(11,fprintf(fp,"\t\tidxmapsize=SWupdateidxmap(SWid_index,regionID,tempvar1,update_index1,indicies);\n"););
      MESSAGE(11,fprintf(fp,"\t\tSize of updated mapping %d\n",idxmapsize););
      for(i=0;i<idxmapsize;i++)
      {
         MESSAGE(6,printf("\t\t%d  %d\n",i,update_index1[i]););
         MESSAGE(11,fprintf(fp,"\t\t%d  %d\n",i,update_index1[i]););
      }
   }


   update_index3=(int32 *)calloc(idxmapsize,4);
   idxmapsize=SWupdateidxmap(SWid_index,regionID,tempvar3,update_index3,indicies);
   if(idxmapsize == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tidxmapsize=SWupdateidxmap(SWid_index,regionID,tempvar3,update_index3,indicies);\n"););
      MESSAGE(8,printf("\t\tSize of updated mapping %d\n",idxmapsize););
      MESSAGE(11,fprintf(fp,"\t\tidxmapsize=SWupdateidxmap(SWid_index,regionID,tempvar3,update_index3,indicies);\n"););
      MESSAGE(11,fprintf(fp,"\t\tSize of updated mapping %d\n",idxmapsize););
      for(i=0;i<idxmapsize;i++)
      {
         MESSAGE(6,printf("\t\t%d  %d\n",i,update_index3[i]););
         MESSAGE(11,fprintf(fp,"\t\t%d  %d\n",i,update_index3[i]););
      }
   }



   free(update_index1);
   free(update_index3);
   free(tempvar1);
   free(tempvar3);

   MESSAGE(6,printf("\t\tDetaching from swath Index\n"););
   MESSAGE(11,fprintf(fp,"\t\tDetaching from swath Index\n"););
   status=SWdetach(SWid_index);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWdetach(SWid_index);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWdetach %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWdetach(SWid_index);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWdetach %d\n",status););
   }


   MESSAGE(6,printf("\t\tClosing file Swathc_test.hdf\n"););
   MESSAGE(11,fprintf(fp,"\t\tClosing file Swathc_test.hdf\n"););
   status=SWclose(swfidc_test);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp,0););
   }
   else
   {
      MESSAGE(4,printf("\n"););
      MESSAGE(4,printf("\t\t********Passed Test**********\n"););
      MESSAGE(11,fprintf(fp,"\n"););
      MESSAGE(11,fprintf(fp,"\t\t********Passed Test**********\n"););
      MESSAGE(10,printf("\t\tstatus=SWclose(swfidc_test);\n"););
      MESSAGE(8,printf("\t\tValue returned by SWclose %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tstatus=SWclose(swfidc_test);\n"););
      MESSAGE(11,fprintf(fp,"\t\tValue returned by SWclose %d\n",status););
   }

   MESSAGE(11,fclose(fp););
   return 0;
}

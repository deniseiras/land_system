/* testpoint.c
*/

#include <stdio.h>
#include "tutils.h"
#include <string.h>
#include "mfhdf.h"
#include "hdf.h"
#include "HdfEosDef.h"

int main(int argc, char *argv[])
{

   intn		status, i, numlev;
   int		CLLoop, Verbosity;
   int16	wgt;
   int32	ptfid, PTid_fixed, PTid_simple, PTid_float, n, date, fldsz;
   int32	level;
   int32	fldlevels[32];
   int32	fieldtype[8], fieldorder[8], fldtype[32], fldorder[32];
   int32	recs[128], dum, wrattr[4] = {11,33,66,99}, rdattr[4];
   int32	size, numtype, strbufsize, inLevel, outLevel, nrec;
   int32	nrecs;
   int32	outNrec, outRecs[32];
   int32	numofpts, numattrs, regionID, periodID;
   char 	fldbuf[255];
   char		linkfield, datbuf[1024];
   char		desc[16], id[2], buffer[10000], *pntr, *buffer2, spc[8];
   char		*strbuf;
   float32	rain, temp, conc[4];
   float32	*datbuf32;
   float32	*datbuff32;
   float64	*datbuf64;
   float64	lon, lat, time, f64;
   float64	corlon[2], corlat[2];
   float64	startt, stopt;
   float64	range[2];


   FILE		*fp, *fp2;


   Verbosity = 4;


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

printf("Size of Float32 %d\n",sizeof(float32));
printf("Size of Float64 %d\n",sizeof(float64));
   MESSAGE(11,fp2=fopen("testpointc.txt","w"););

   MESSAGE(4,printf("Testing Point C interface\n"););
   MESSAGE(4,printf("=========================\n"););
   MESSAGE(11,fprintf(fp2,"Testing Point C interface\n"););
   MESSAGE(11,fprintf(fp2,"=========================\n"););

/*
**	Test Case -- PTopen
*/
   MESSAGE(4,printf("\tTesting PTopen...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTopen...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   MESSAGE(6,printf("\t\tCreating file Pointc_Test.hdf\n"););
   MESSAGE(11,fprintf(fp2,"\t\tCreating file Pointc_Test.hdf\n"););
   ptfid = PTopen("Pointc_Test.hdf", DFACC_CREATE);
   MESSAGE(10,printf("\t\tptfid = PTopen(\"Pointc_Test.hdf\", DFACC_CREATE);\n"););
   MESSAGE(8,printf("\t\tFile id returned by PTopen %d\n", ptfid););
   MESSAGE(11,fprintf(fp2,"\t\tptfid = PTopen(\"Pointc_Test.hdf\", DFACC_CREATE);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tFile id returned by PTopen %d\n", ptfid););
   if (ptfid == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

/*
**	Test Case -- PTcreate
*/
   MESSAGE(4,printf("\tTesting PTcreate...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\f"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTcreate...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   MESSAGE(6,printf("\t\tCreate Point object FixedBuoy Point\n"););
   MESSAGE(11,fprintf(fp2,"\t\tCreate Point object FixedBuoy Point\n"););
   PTid_fixed = PTcreate(ptfid, "FixedBuoy_Point");
   MESSAGE(10,printf("\t\tPTid_fixed = PTcreate(ptfid, \"FixedBuoy Point\");\n"););
   MESSAGE(8,printf("\t\tValue returned by PTcreate %d\n", PTid_fixed););
   MESSAGE(11,fprintf(fp2,"\t\tPTid_fixed = PTcreate(ptfid, \"FixedBuoy Point\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTcreate %d\n", PTid_fixed););
   if (PTid_fixed == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(6,printf("\t\tCreate Point object Simple Point\n"););
   MESSAGE(11,fprintf(fp2,"\t\tCreate Point object Simple Point\n"););
   PTid_simple = PTcreate(ptfid, "Simple_Point");
   MESSAGE(10,printf("\t\tPTid_simple = PTcreate(ptfid, \"Simple Point\");\n"););
   MESSAGE(8,printf("\t\tValue returned by PTcreate %d\n", PTid_simple););
   MESSAGE(11,fprintf(fp2,"\t\tPTid_simple = PTcreate(ptfid, \"Simple Point\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTcreate %d\n", PTid_simple););
   if (PTid_simple == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(6,printf("\t\tCreate Point object FloatBuoy Point\n"););
   MESSAGE(11,fprintf(fp2,"\t\tCreate Point object FloatBuoy Point\n"););
   PTid_float = PTcreate(ptfid, "FloatBuoy_Point");
   MESSAGE(10,printf("\t\tPTid_float = PTcreate(ptfid, \"FloatBuoy Point\");\n"););
   MESSAGE(8,printf("\t\tValue returned by PTcreate %d\n", PTid_float););
   MESSAGE(11,fprintf(fp2,"\t\tPTid_float = PTcreate(ptfid, \"FloatBuoy Point\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTcreate %d\n", PTid_float););
   if (PTid_float == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   strcpy(fldbuf, "Time,Concentration,Species");

   fieldtype[0] = DFNT_FLOAT64;
   fieldtype[1] = DFNT_FLOAT32;
   fieldtype[2] = DFNT_CHAR8;

   fieldorder[0] = 1;
   fieldorder[1] = 4;
   fieldorder[2] = 4;

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTdeflevel
*/
   MESSAGE(4,printf("\tTesting PTdeflevel...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTdeflevel...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   MESSAGE(6,printf("\t\tDefine level Sensor\n"););
   MESSAGE(11,fprintf(fp2,"\t\tDefine level Sensor\n"););
   status = PTdeflevel(PTid_simple, "Sensor", fldbuf, fieldtype, fieldorder);
   MESSAGE(10,printf("\t\tstatus = PTdeflevel(PTid_simple, \"Sensor\", fldbuf, fieldtype, fieldorder);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdeflevel %d\n",status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTdeflevel(PTid_simple, \"Sensor\", fldbuf, fieldtype, fieldorder);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdeflevel %d\n",status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }


   strcpy(fldbuf, "Label,Longitude,Latitude,DeployDate,ID");

   fieldtype[0] = DFNT_CHAR8;
   fieldtype[1] = DFNT_FLOAT64;
   fieldtype[2] = DFNT_FLOAT64;
   fieldtype[3] = DFNT_INT32;
   fieldtype[4] = DFNT_CHAR8;

   fieldorder[0] = 8;
   fieldorder[1] = 0;
   fieldorder[2] = 0;
   fieldorder[3] = 0;
   fieldorder[4] = 1;

   MESSAGE(6,printf("\t\tDefine level DescLoc\n"););
   MESSAGE(11,fprintf(fp2,"\t\tDefine level DescLoc\n"););
   status = PTdeflevel(PTid_fixed, "DescLoc", fldbuf, fieldtype, fieldorder);
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTdeflevel(PTid_fixed, \"DescLoc\", fldbuf, fieldtype, fieldorder);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdeflevel %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   strcpy(fldbuf, "Time,Rainfall,Temperature,ID");

   fieldtype[0] = DFNT_FLOAT64;
   fieldtype[1] = DFNT_FLOAT32;
   fieldtype[2] = DFNT_FLOAT32;
   fieldtype[3] = DFNT_CHAR8;

   fieldorder[0] = 0;
   fieldorder[1] = 0;
   fieldorder[2] = 0;
   fieldorder[3] = 1;

   MESSAGE(6,printf("\t\tDefine level Observations\n"););
   MESSAGE(11,fprintf(fp2,"\t\tDefine level Observations\n"););
   status = PTdeflevel(PTid_fixed, "Observations", fldbuf, fieldtype, fieldorder);
   MESSAGE(10,printf("\t\tstatus=PTdeflevel(PTid_fixed,\"Observations\",fldbuf,fieldtype,fieldorder);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdeflevel %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus=PTdeflevel(PTid_fixed,\"Observations\",fldbuf,fieldtype,fieldorder);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdeflevel %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTdeflinkage
*/
   MESSAGE(4,printf("\tTesting PTdeflinkage...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTdeflinkage...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   MESSAGE(6,printf("\t\tDefine linkage between levels Desc-Loc & Observations\n"););
   MESSAGE(11,fprintf(fp2,"\t\tDefine linkage between levels Desc-Loc & Observations\n"););
   status = PTdeflinkage(PTid_fixed, "DescLoc", "Observations", "ID");
   MESSAGE(10,printf("\t\tstatus = PTdeflinkage(PTid_fixed, \"DescLoc\", \"Observations\", \"ID\");\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdeflinkage %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTdeflinkage(PTid_fixed, \"DescLoc\", \"Observations\", \"ID\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdeflinkage %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   strcpy(fldbuf, "Label,DeployDate,Weight,ID");

   fieldtype[0] = DFNT_CHAR8;
   fieldtype[1] = DFNT_INT32;
   fieldtype[2] = DFNT_INT16;
   fieldtype[3] = DFNT_CHAR8;

   fieldorder[0] = 8;
   fieldorder[1] = 0;
   fieldorder[2] = 0;
   fieldorder[3] = 1;

   MESSAGE(6,printf("\t\tDefine level Description\n"););
   MESSAGE(11,fprintf(fp2,"\t\tDefine level Description\n"););
   status = PTdeflevel(PTid_float, "Description", fldbuf,fieldtype, fieldorder);
   MESSAGE(10,printf("\t\tstatus=PTdeflevel(PTid_float,\"Description\",fldbuf,fieldtype, fieldorder);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdeflevel %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus=PTdeflevel(PTid_float,\"Description\",fldbuf,fieldtype, fieldorder);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdeflevel %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   strcpy(fldbuf, "Time,Longitude,Latitude,Rainfall,Temperature,ID");

   fieldtype[0] = DFNT_FLOAT64;
   fieldtype[1] = DFNT_FLOAT64;
   fieldtype[2] = DFNT_FLOAT64;
   fieldtype[3] = DFNT_FLOAT32;
   fieldtype[4] = DFNT_FLOAT32;
   fieldtype[5] = DFNT_CHAR8;

   fieldorder[0] = 0;
   fieldorder[1] = 0;
   fieldorder[2] = 0;
   fieldorder[3] = 0;
   fieldorder[4] = 0;
   fieldorder[5] = 1;

   MESSAGE(6,printf("\t\tDefine level Measurements\n"););
   MESSAGE(11,fprintf(fp2,"\t\tDefine level Measurements\n"););
   status = PTdeflevel(PTid_float, "Measurements", fldbuf,fieldtype, fieldorder);
   MESSAGE(10,printf("\t\tstatus=PTdeflevel(PTid, \"Measurements\", fldbuf,fieldtype, fieldorder);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdeflevel %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus=PTdeflevel(PTid, \"Measurements\", fldbuf,fieldtype, fieldorder);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdeflevel %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(6,printf("\t\tDefine linkage between levels Description & Measurements\n"););
   MESSAGE(11,fprintf(fp2,"\t\tDefine linkage between levels Description & Measurements\n"););
   status = PTdeflinkage(PTid_float, "Description", "Measurements", "ID");
   MESSAGE(10,printf("\t\tstatus = PTdeflinkage(PTid, \"Description\", \"Measurements\", \"ID\");\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdeflinkage %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTdeflinkage(PTid, \"Description\", \"Measurements\", \"ID\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdeflinkage %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTdetach
*/
   MESSAGE(4,printf("\tTesting PTdetach...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTdetach...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   MESSAGE(6,printf("\t\tDetach from FixedBuoy\n"););
   MESSAGE(11,fprintf(fp2,"\t\tDetach from FixedBuoy\n"););
   status = PTdetach(PTid_fixed);
   MESSAGE(10,printf("\t\tstatus = PTdetach(PTid_fixed);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdetach %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTdetach(PTid_fixed);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdetach %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(6,printf("\t\tDetach from Simple\n"););
   MESSAGE(11,fprintf(fp2,"\t\tDetach from Simple\n"););
   status = PTdetach(PTid_simple);
   MESSAGE(10,printf("\t\tstatus = PTdetach(PTid_simple);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdetach %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTdetach(PTid_simple);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdetach %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(6,printf("\t\tDetach from FloatBuoy\n"););
   MESSAGE(11,fprintf(fp2,"\t\tDetach from FloatBuoy\n"););
   status = PTdetach(PTid_float);
   MESSAGE(10,printf("\t\tstatus = PTdetach(PTid_float);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdetach %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTdetach(PTid_float);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdetach %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(6,printf("\t\tClosing point file\n"););
   MESSAGE(11,fprintf(fp2,"\t\tClosing point file\n"););
   status = PTclose(ptfid);
   MESSAGE(10,printf("\t\tstatus = PTclose(ptfid);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTclose %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTclose(ptfid);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTclose %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(6,printf("\t\tOpen file Pointc_Test.hdf\n"););
   MESSAGE(11,fprintf(fp2,"\t\tOpen file Pointc_Test.hdf\n"););
   ptfid = PTopen("Pointc_Test.hdf", DFACC_RDWR);
   MESSAGE(10,printf("\t\tptfid = PTopen(\"Pointc_Test.hdf\", DFACC_RDWR);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTopen %d\n",ptfid););
   MESSAGE(11,fprintf(fp2,"\t\tptfid = PTopen(\"Pointc_Test.hdf\", DFACC_RDWR);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTopen %d\n",ptfid););
   if (ptfid == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTattach
*/
   MESSAGE(4,printf("\tTesting PTattach...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTattach...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   MESSAGE(6,printf("\t\tAttaching to point object FixedBuoy_Point\n"););
   MESSAGE(11,fprintf(fp2,"\t\tAttaching to point object FixedBuoy_Point\n"););
   PTid_fixed = PTattach(ptfid, "FixedBuoy_Point");
   MESSAGE(10,printf("\t\tPTid_fixed = PTattach(ptfid, \"FixedBuoy_Point\");\n"););
   MESSAGE(8,printf("\t\tValue returned by PTattach %d\n", PTid_fixed););
   MESSAGE(11,fprintf(fp2,"\t\tPTid_fixed = PTattach(ptfid, \"FixedBuoy_Point\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTattach %d\n", PTid_fixed););
   if (PTid_fixed == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   fp = fopen("fixedBuoy0.txt", "r");
   MESSAGE(10,printf("\t\tfp = fopen(\"fixedBuoy0.txt\", \"r\");\n"););
   MESSAGE(6,printf("\t\tValue of file pointer returned %p\n",fp););
   MESSAGE(11,fprintf(fp2,"\t\tfp = fopen(\"fixedBuoy0.txt\", \"r\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue of file pointer returned %p\n",fp););

   n = 0;
   pntr = buffer;
   while(fscanf(fp,"%s %lf %lf %d %s", desc,&lon,&lat,&date,id) != -1)
   {
      n++;
      memcpy(pntr, &desc, 8);
      pntr += 8;
      memcpy(pntr, &lon, 8);
      pntr += 8;
      memcpy(pntr, &lat, 8);
      pntr += 8;
      memcpy(pntr, &date, 4);
      pntr += 4;
      memcpy(pntr, &id, 1);
      pntr += 1;
   }
   status=fclose(fp);
   MESSAGE(10,printf("\t\tstatus=fclose(fp);\n"););
   MESSAGE(8,printf("\t\tValue returned by fclose %d\n",status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus=fclose(fp);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by fclose %d\n",status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTwritelevel
*/
   MESSAGE(4,printf("\tTesting PTwritelevel...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTwritelevel...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   level=0;
   MESSAGE(6,printf("\t\tWrining level 0\n"););
   MESSAGE(11,fprintf(fp2,"\t\tWrining level 0\n"););
   status = PTwritelevel(PTid_fixed, level, n, buffer);
   MESSAGE(10,printf("\t\tstatus = PTwritelevel(PTid_fixed, 0, n, buffer);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTwritelevel %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTwritelevel(PTid_fixed, 0, n, buffer);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTwritelevel %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   fp = fopen("fixedBuoy1.txt", "r");
   MESSAGE(10,printf("\t\tfp = fopen(\"fixedBuoy1.txt\", \"r\");\n"););
   MESSAGE(8,printf("\t\tValue of file pointer returned %p\n",fp););
   MESSAGE(11,fprintf(fp2,"\t\tfp = fopen(\"fixedBuoy1.txt\", \"r\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue of file pointer returned %p\n",fp););

   n = 0;
   pntr = buffer;
   while(fscanf(fp,"%lf %f %f %s", &time, &rain, &temp, id) != -1)
   {
      n++;
      memcpy(pntr, &time, 8);
      pntr += 8;
      memcpy(pntr, &rain, 4);
      pntr += 4;
      memcpy(pntr, &temp, 4);
      pntr += 4;
      memcpy(pntr, &id, 1);
      pntr += 1;
   }
   status=fclose(fp);
   printf("\t\tValue returned by fclose %d\n",status);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   level=1;
   MESSAGE(6,printf("\t\tValue of n %d\n",n););
   MESSAGE(11,fprintf(fp2,"\t\tValue of n %d\n",n););
   status = PTwritelevel(PTid_fixed, level, n, buffer);
   MESSAGE(10,printf("\t\tstatus = PTwritelevel(PTid_fixed, 1, n, buffer);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTwritelevel %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTwritelevel(PTid_fixed, 1, n, buffer);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTwritelevel %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }


   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTwriteattr
*/
   MESSAGE(4,printf("\tTesting PTwriteattr...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTwriteattr...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   status = PTwriteattr(PTid_fixed, "Viscosity", DFNT_INT32, 4, wrattr);
   MESSAGE(10,printf("\t\tstatus = PTwriteattr(PTid_fixed, \"Viscosity\", DFNT_INT32, 4, attr);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTwriteattr %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTwriteattr(PTid_fixed, \"Viscosity\", DFNT_INT32, 4, attr);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTwriteattr %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   PTid_simple = PTattach(ptfid, "Simple_Point");
   MESSAGE(10,printf("\t\tPTid_simple = PTattach(ptfid, \"Simple_Point\");\n"););
   MESSAGE(8,printf("\t\tValue returned by PTattach %d\n", PTid_simple););
   MESSAGE(11,fprintf(fp2,"\t\tPTid_simple = PTattach(ptfid, \"Simple_Point\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTattach %d\n", PTid_simple););
   if (PTid_simple == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   fp = fopen("simple.txt", "r");

   n = 0;
   pntr = buffer;
   while(fscanf(fp, "%lf %f %f %f %f %s", &time,&conc[0],&conc[1],&conc[2],&conc[3],spc) != -1)
   {
      n++;

      memcpy(pntr, &time, 8);
      pntr += 8;
      memcpy(pntr, conc, 4*4);
      pntr += 4*4;
      memcpy(pntr, &spc, 4);
      pntr += 4;
   }
   fclose(fp);

   status = PTwritelevel(PTid_simple, 0, n, buffer);
   MESSAGE(10,printf("\t\tstatus = PTwritelevel(PTid_simple, 0, n, buffer);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTwritelevel %d\n",status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTwritelevel(PTid_simple, 0, n, buffer);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTwritelevel %d\n",status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   PTid_float = PTattach(ptfid, "FloatBuoy_Point");
   MESSAGE(10,printf("\t\tPTid_float = PTattach(ptfid, \"FloatBuoy_Point\");\n"););
   MESSAGE(8,printf("\t\tValue returned by PTattach %d\n",PTid_float););
   MESSAGE(11,fprintf(fp2,"\t\tPTid_float = PTattach(ptfid, \"FloatBuoy_Point\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTattach %d\n",PTid_float););
   if (PTid_float == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   fp = fopen("floatBuoy0.txt", "r");

   n = 0;
   pntr = buffer;
   while(fscanf(fp, "%s %d %d %s", desc, &date, &dum, id) != -1)
   {
      n++;

      wgt = (int16) dum;

      memcpy(pntr, &desc, 8);
      pntr += 8;
      memcpy(pntr, &date, 4);
      pntr += 4;
      memcpy(pntr, &wgt, 2);
      pntr += 2;
      memcpy(pntr, &id, 1);
      pntr += 1;
   }
   fclose(fp);

   status = PTwritelevel(PTid_float, 0, n, buffer);
   MESSAGE(10,printf("\t\tstatus = PTwritelevel(PTid_float, 0, n, buffer);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTwritelevel %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTwritelevel(PTid_float, 0, n, buffer);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTwritelevel %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   
   fp = fopen("floatBuoy1.txt", "r");

   n = 0;
   pntr = buffer;
   while(fscanf(fp, "%lf %lf %lf %f %f %s", &time,&lon,&lat,&rain,&temp,id) != -1)
   {
      n++;

      memcpy(pntr, &time, 8);
      pntr += 8;
      memcpy(pntr, &lon, 8);
      pntr += 8;
      memcpy(pntr, &lat, 8);
      pntr += 8;
      memcpy(pntr, &rain, 4);
      pntr += 4;
      memcpy(pntr, &temp, 4);
      pntr += 4;
      memcpy(pntr, &id, 1);
      pntr += 1;
   }
   fclose(fp);

   status = PTwritelevel(PTid_float, 1, n, buffer);
   MESSAGE(10,printf("\t\tstatus = PTwritelevel(PTid_float, 1, n, buffer);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTwritelevel %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTwritelevel(PTid_float, 1, n, buffer);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTwritelevel %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   status = PTdetach(PTid_fixed);
   MESSAGE(10,printf("\t\tstatus = PTdetach(PTid_fixed);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdetach %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTdetach(PTid_fixed);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdetach %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   status = PTdetach(PTid_simple);
   MESSAGE(10,printf("\t\tstatus = PTdetach(PTid_simple);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdetach %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTdetach(PTid_simple);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdetach %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   status = PTdetach(PTid_float);
   MESSAGE(10,printf("\t\tstatus = PTdetach(PTid_float);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdetach %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTdetach(PTid_float);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdetach %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
 
   status = PTclose(ptfid);
   MESSAGE(10,printf("\t\tstatus = PTclose(ptfid);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTclose %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTclose(ptfid);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTclose %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   ptfid = PTopen("Pointc_Test.hdf", DFACC_RDWR);
   MESSAGE(10,printf("\t\tptfid = PTopen(\"Pointc_Test.hdf\", DFACC_RDWR);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTopen %d\n", ptfid););
   MESSAGE(11,fprintf(fp2,"\t\tptfid = PTopen(\"Pointc_Test.hdf\", DFACC_RDWR);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTopen %d\n", ptfid););
   if (ptfid == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTinqpoint
*/
   MESSAGE(4,printf("\tTesting PTinqpoint...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTinqpoint...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   numofpts = PTinqpoint("Pointc_Test.hdf", NULL, &strbufsize);
   MESSAGE(10,printf("\t\tnumofpts = PTinqpoint(\"Pointc_Test.hdf\", NULL, &strbufsize);\n"););
   MESSAGE(8,printf("\t\tNumber of point objects in file Pointc_Test.hdf %d\n",numofpts););
   MESSAGE(8,printf("\t\tLength of point object names %d\n",strbufsize););
   MESSAGE(11,fprintf(fp2,"\t\tnumofpts = PTinqpoint(\"Pointc_Test.hdf\", NULL, &strbufsize);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tNumber of point objects in file Pointc_Test.hdf %d\n",numofpts););
   MESSAGE(11,fprintf(fp2,"\t\tLength of point object names %d\n",strbufsize););
   if (numofpts == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   strbuf = (char *)malloc(strbufsize + 1);
   numofpts = PTinqpoint("Pointc_Test.hdf", strbuf,&strbufsize);
   MESSAGE(10,printf("\t\tnumofpts = PTinqpoint(\"Pointc_Test.hdf\", strbuf,&strbufsize);\n"););
   MESSAGE(8,printf("\t\tList of point objects %s\n",strbuf););
   MESSAGE(11,fprintf(fp2,"\t\tnumofpts = PTinqpoint(\"Pointc_Test.hdf\", strbuf,&strbufsize);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tList of point objects %s\n",strbuf););
   if (numofpts == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   free(strbuf);



   PTid_fixed = PTattach(ptfid, "FixedBuoy_Point");
   MESSAGE(10,printf("\t\tPTid_fixed = PTattach(ptfid, \"FixedBuoy_Point\");\n"););
   MESSAGE(8,printf("\t\tValue returned by PTattach %d\n", PTid_fixed););
   MESSAGE(11,fprintf(fp2,"\t\tPTid_fixed = PTattach(ptfid, \"FixedBuoy_Point\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTattach %d\n", PTid_fixed););
   if (PTid_fixed == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTbcklinkinfo
*/
   MESSAGE(4,printf("\tTesting PTbcklinkinfo...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTbcklinkinfo...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   status = PTbcklinkinfo(PTid_fixed, 1, &linkfield);
   MESSAGE(10,printf("\t\tstatus = PTbcklinkinfo(PTid_fixed, 1, linkfield);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTbcklinkinfo %d\n", status););
   MESSAGE(8,printf("\t\tField to link level 1 to 0 %s\n", &linkfield););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTbcklinkinfo(PTid_fixed, 1, linkfield);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTbcklinkinfo %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tField to link level 1 to 0 %s\n", &linkfield););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTfwdlinkinfo
*/
   MESSAGE(4,printf("\tTesting PTfwdlinkinfo...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTfwdlinkinfo...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   status = PTfwdlinkinfo(PTid_fixed, 0, &linkfield);
   MESSAGE(10,printf("\t\tstatus = PTfwdlinkinfo(PTid_fixed, 0 &linkfield);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTfwdlinkinfo %d\n", status););
   MESSAGE(8,printf("\t\tField to link level 0 to 1 %s\n", &linkfield););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTfwdlinkinfo(PTid_fixed, 0 &linkfield);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTfwdlinkinfo %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tField to link level 0 to 1 %s\n", &linkfield););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTlevelindx
*/
   MESSAGE(4,printf("\tTesting PTlevelindx...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTlevelindx...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   status = PTlevelindx(PTid_fixed, "DescLoc");
   MESSAGE(10,printf("\t\tstatus = PTlevelindx(PTid_fixed, \"DescLoc\");\n"););
   MESSAGE(8,printf("\t\tIndex of level %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTlevelindx(PTid_fixed, \"DescLoc\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tIndex of level %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   status = PTlevelindx(PTid_fixed, "Observations");
   MESSAGE(10,printf("\t\tstatus = PTlevelindx(PTid_fixed, \"Observations\");\n"););
   MESSAGE(8,printf("\t\tIndex of level %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTlevelindx(PTid_fixed, \"Observations\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tIndex of level %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTnlevels
*/
   MESSAGE(4,printf("\tTesting PTnlevels...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTnlevels...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   numlev = PTnlevels(PTid_fixed);
   MESSAGE(10,printf("\t\tnumlev = PTnlevels(PTid_fixed);\n"););
   MESSAGE(8,printf("\t\tNumber of levels in point %d\n", numlev););
   MESSAGE(11,fprintf(fp2,"\t\tnumlev = PTnlevels(PTid_fixed);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tNumber of levels in point %d\n", numlev););
   if (numlev == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTnfields
*/
   MESSAGE(4,printf("\tTesting PTnfields...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTnfields...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   status = PTnfields(PTid_fixed, 0, &strbufsize);
   MESSAGE(10,printf("\t\tstatus = PTnfields(PTid_fixed, 0, &strbufsize);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTnfields %d\n", status););
   MESSAGE(8,printf("\t\tValue of numfields %d\n", strbufsize););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTnfields(PTid_fixed, 0, &strbufsize);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTnfields %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tValue of numfields %d\n", strbufsize););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTinqattrs
*/
   MESSAGE(4,printf("\tTesting PTinqattrs...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTinqattrs...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   numattrs = PTinqattrs(PTid_fixed, NULL, &strbufsize);
   MESSAGE(10,printf("\t\tnumattrs = PTinqattrs(PTid_fixed, NULL, &strbufsize);\n"););
   MESSAGE(8,printf("\t\tNumber of attributes in point object fixed %d\n",numattrs););
   MESSAGE(8,printf("\t\tLength of attribute list %d\n",strbufsize););
   MESSAGE(11,fprintf(fp2,"\t\tnumattrs = PTinqattrs(PTid_fixed, NULL, &strbufsize);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tNumber of attributes in point object fixed %d\n",numattrs););
   MESSAGE(11,fprintf(fp2,"\t\tLength of attribute list %d\n",strbufsize););
   if (numattrs == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   strbuf = (char *)malloc(strbufsize + 1);
   numattrs = PTinqattrs(PTid_fixed, strbuf,&strbufsize);
   MESSAGE(10,printf("\t\tnumattrs = PTinqattrs(PTid_fixed, strbuf,&strbufsize);\n"););
   MESSAGE(8,printf("\t\tAttribute list %s\n",strbuf););
   MESSAGE(11,fprintf(fp2,"\t\tnumattrs = PTinqattrs(PTid_fixed, strbuf,&strbufsize);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tAttribute list %s\n",strbuf););
   if (numattrs == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   free(strbuf);

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTattrinfo
*/
   MESSAGE(4,printf("\tTesting PTattrinfo...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTattrinfo...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   status = PTattrinfo(PTid_fixed, "Viscosity", &numtype, &size);
   MESSAGE(10,printf("\t\tstatus = PTattrinfo(PTid_fixed, \"Viscosity\", &numtype, &size);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTattrinfo %d\n", status););
   MESSAGE(8,printf("\t\tNumber type %d  size %d\n", numtype, size););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTattrinfo(PTid_fixed, \"Viscosity\", &numtype, &size);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTattrinfo %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tNumber type %d  size %d\n", numtype, size););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTreadattr
*/
   MESSAGE(4,printf("\tTesting PTreadattr...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTreadattr...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   status = PTreadattr(PTid_fixed, "Viscosity", rdattr);
   MESSAGE(10,printf("\t\tstatus = PTreadattr(PTid_fixed, \"Viscosity\", rdattr);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTreadattr %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTreadattr(PTid_fixed, \"Viscosity\", rdattr);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTreadattr %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   for (i = 0; i < 4; i++) {
      MESSAGE(8,printf("\t\tAttribute number %d = %d\n", i+1, rdattr[i]););
      MESSAGE(11,fprintf(fp2,"\t\tAttribute number %d = %d\n", i+1, rdattr[i]););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTgetrecnums
*/
   MESSAGE(4,printf("\tTesting PTgetrecnums...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTgetrecnums...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   inLevel = 0;
   outLevel = 1;
   nrec = 1;
   recs[0] = 0;
   status = PTgetrecnums(PTid_fixed, inLevel, outLevel, nrec, recs, &outNrec, outRecs);
   MESSAGE(10,printf("\t\tstatus=PTgetrecnums(PTid_fixed,inLevel,outLevel,nrec,recs,&outNrec,outRecs);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTgetrecnums %d\n", status););
   MESSAGE(8,printf("\t\tNumber of records %d records %d\n", nrec, recs[0]););
   MESSAGE(8,printf("\t\tNumber of records %d records %d\n", outNrec, outRecs[0]););
   MESSAGE(11,fprintf(fp2,"\t\tstatus=PTgetrecnums(PTid_fixed,inLevel,outLevel,nrec,recs,&outNrec,outRecs);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTgetrecnums %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tNumber of records %d records %d\n", nrec, recs[0]););
   MESSAGE(11,fprintf(fp2,"\t\tNumber of records %d records %d\n", outNrec, outRecs[0]););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTlevelinfo
*/
   MESSAGE(4,printf("\tTesting PTlevelinfo...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTlevelinfo...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   status = PTlevelinfo(PTid_fixed, 0, fldbuf, fldtype, fldorder);
   MESSAGE(10,printf("\t\tstatus = PTlevelinfo(PTid_fixed, 0, fldbuf, fldtype, fldorder);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTlevelinfo %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTlevelinfo(PTid_fixed, 0, fldbuf, fldtype, fldorder);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTlevelinfo %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTsizeof
*/
   MESSAGE(4,printf("\tTesting PTsizeof...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTsizeof...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   fldsz = PTsizeof(PTid_fixed, fldbuf, fldlevels);
   MESSAGE(10,printf("\t\tfldsz = PTsizeof(PTid_fixed, fldbuf, fldlevels);\n"););
   MESSAGE(8,printf("\t\tSize of fields in level %d\n", fldsz););
   MESSAGE(11,fprintf(fp2,"\t\tfldsz = PTsizeof(PTid_fixed, fldbuf, fldlevels);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tSize of fields in level %d\n", fldsz););
   if (fldsz == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   n = 2;
   recs[0] = 0;
   recs[1] = 2;

   MESSAGE(11,fprintf(fp2,"\f"););

/*
**	Test Case -- PTreadlevel
*/
   MESSAGE(4,printf("\tTesting PTreadlevel...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTreadlevel...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   buffer2 = (char *) calloc(n * fldsz, 1);
   pntr = buffer2;
   status = PTreadlevel(PTid_fixed, 0, fldbuf, n, recs, buffer2);
   MESSAGE(10,printf("\t\tstatus = PTreadlevel(PTid_fixed, 0, fldbuf, n, recs, buffer2);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTreadlevel %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTreadlevel(PTid_fixed, 0, fldbuf, n, recs, buffer2);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTreadlevel %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   for (i=0; i<n; i++)
   {
      memcpy(&desc, pntr, 8);
      pntr += 8;
      memcpy(&lon, pntr, 8);
      pntr += 8;
      memcpy(&lat, pntr, 8);
      pntr += 8;
      memcpy(&date, pntr, 4);
      pntr += 4;
      memcpy(&id, pntr, 1);
      pntr += 1;
      MESSAGE(6,printf("\t\t%-10s %12.6f %12.6f %10d %-4s\n", desc,lon,lat,date,id););
      MESSAGE(11,fprintf(fp2,"\t\t%-10s %12.6f %12.6f %10d %-4s\n", desc,lon,lat,date,id););
   }
   free(buffer2);

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTupdatelevel
*/
   MESSAGE(4,printf("\tTesting PTupdatelevel...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTupdatelevel...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   f64 = -139.2520148;
   memcpy(datbuf, &f64, 8);
   recs[0] = 0;
   status = PTupdatelevel(PTid_fixed, 0, "Longitude", 1, recs, datbuf);
   MESSAGE(10,printf("\t\tstatus = PTupdatelevel(PTid_fixed, 0, \"Longitude\", 1, recs, datbuf);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTupdatelevel %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTupdatelevel(PTid_fixed, 0, \"Longitude\", 1, recs, datbuf);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTupdatelevel %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

/*
**	Test Case -- PTgetlevelname
*/
   MESSAGE(4,printf("\tTesting PTgetlevelname...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTgetlevelname...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   status = PTgetlevelname(PTid_fixed,0,fldbuf,&strbufsize);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   else
   {
      MESSAGE(10,printf("\t\tstatus = PTgetlevelname(PTid_fixed,0,fldbuf,&strbufsize);\n"););
      MESSAGE(8,printf("\t\tStatus returned by call to PTgetlevelname %d\n",status););
      MESSAGE(10,printf("\t\tLevel Name %s\n",fldbuf););
      MESSAGE(10,printf("\t\tSize of level name %d\n",strbufsize););
      MESSAGE(11,fprintf(fp,"\t\tstatus = PTgetlevelname(PTid_fixed,0,fldbuf,&strbufsize);\n"););
      MESSAGE(11,fprintf(fp,"\t\tStatus returned by call to PTgetlevelname %d\n",status););
      MESSAGE(11,fprintf(fp,"\t\tLevel Name %c\n",fldbuf););
      MESSAGE(11,fprintf(fp,"\t\tSize of level name %d\n",strbufsize););
   }

   status = PTdetach(PTid_fixed);
   MESSAGE(10,printf("\t\tstatus = PTdetach(PTid_fixed);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdetach %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTdetach(PTid_fixed);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdetach %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   status = PTclose(ptfid);
   MESSAGE(10,printf("\t\tstatus = PTclose(ptfid);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTclose %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTclose(ptfid);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTclose %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   ptfid = PTopen("Pointc_Test.hdf", DFACC_RDWR);
   MESSAGE(10,printf("\t\tptfid = PTopen(\"Pointc_Test.hdf\", DFACC_RDWR);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTopen %d\n", ptfid););
   MESSAGE(11,fprintf(fp2,"\t\tptfid = PTopen(\"Pointc_Test.hdf\", DFACC_RDWR);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTopen %d\n", ptfid););
   if (ptfid == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   PTid_fixed = PTattach(ptfid, "FixedBuoy_Point");
   MESSAGE(10,printf("\t\tPTid_fixed = PTattach(ptfid, \"FixedBuoy_Point\");\n"););
   MESSAGE(8,printf("\t\tValue returned by PTattach %d\n", PTid_fixed););
   MESSAGE(11,fprintf(fp2,"\t\tPTid_fixed = PTattach(ptfid, \"FixedBuoy_Point\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTattach %d\n", PTid_fixed););
   if (PTid_fixed == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
 

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTlevelinfo
*/
   MESSAGE(4,printf("\tTesting PTlevelinfo...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTlevelinfo...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   status = PTlevelinfo(PTid_fixed, 0, fldbuf, fldtype, fldorder);
   MESSAGE(10,printf("\t\tstatus = PTlevelinfo(PTid_fixed, 0, fldbuf, fldtype, fldorder);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTlevelinfo %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTlevelinfo(PTid_fixed, 0, fldbuf, fldtype, fldorder);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTlevelinfo %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTsizeof
*/
   MESSAGE(4,printf("\tTesting PTsizeof...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTsizeof...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   fldsz = PTsizeof(PTid_fixed, fldbuf, fldlevels);
   MESSAGE(10,printf("\t\tfldsz = PTsizeof(PTid_fixed, fldbuf, fldlevels);\n"););
   MESSAGE(8,printf("\t\tSize of fields in level %d\n", fldsz););
   MESSAGE(11,fprintf(fp2,"\t\tfldsz = PTsizeof(PTid_fixed, fldbuf, fldlevels);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tSize of fields in level %d\n", fldsz););
   if (fldsz == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   n = 2;
   recs[0] = 0;
   recs[1] = 2;
 
   buffer2 = (char *) calloc(n * fldsz, 1);
   pntr = buffer2;
   status = PTreadlevel(PTid_fixed, 0, fldbuf, n, recs, buffer2);
   MESSAGE(10,printf("\t\tstatus = PTreadlevel(PTid_fixed, 0, fldbuf, n, recs, buffer2\n"););
   MESSAGE(8,printf("\t\tValue returned by PTreadlevel %d\n",status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTreadlevel(PTid_fixed, 0, fldbuf, n, recs, buffer2\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTreadlevel %d\n",status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
 
   for (i=0; i<n; i++)
   {
      memcpy(&desc, pntr, 8);
      pntr += 8;
      memcpy(&lon, pntr, 8);
      pntr += 8;
      memcpy(&lat, pntr, 8);
      pntr += 8;
      memcpy(&date, pntr, 4);
      pntr += 4;
      memcpy(&id, pntr, 1);
      pntr += 1;
      MESSAGE(6,printf("\t\t%-10s %12.6f %12.6f %10d %-4s\n", desc,lon,lat,date,id););
      MESSAGE(11,fprintf(fp2,"\t\t%-10s %12.6f %12.6f %10d %-4s\n", desc,lon,lat,date,id););
   }
   free(buffer2);

   status = PTlevelinfo(PTid_fixed, 1, fldbuf,fldtype, fldorder);
   MESSAGE(10,printf("\t\tstatus = PTlevelinfo(PTid_fixed, 1, fldbuf,fldtype, fldorder);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTlevelinfo %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTlevelinfo(PTid_fixed, 1, fldbuf,fldtype, fldorder);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTlevelinfo %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   fldsz = PTsizeof(PTid_fixed, fldbuf, fldlevels);
   MESSAGE(10,printf("\t\tfldsz = PTsizeof(PTid_fixed, fldbuf, fldlevels);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTsizeof %d\n", fldsz););
   MESSAGE(11,fprintf(fp2,"\t\tfldsz = PTsizeof(PTid_fixed, fldbuf, fldlevels);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTsizeof %d\n", fldsz););
   if (fldsz == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTnrecs
*/
   MESSAGE(4,printf("\tTesting PTnrecs...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTnrecs...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   buffer2 = (char *) calloc(fldsz,1);
   n = PTnrecs(PTid_fixed, 1);
   MESSAGE(10,printf("\t\tn = PTnrecs(PTid_fixed, 1);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTnrecs %d\n", n););
   MESSAGE(11,fprintf(fp2,"\t\tn = PTnrecs(PTid_fixed, 1);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTnrecs %d\n", n););
   if (n == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   for (i=0; i<n; i++)
   {
      pntr = buffer2;
      recs[0] = i;
      status = PTreadlevel(PTid_fixed, 1, fldbuf, 1, recs, buffer2);

      memcpy(&time, pntr, 8);
      pntr += 8;
      memcpy(&rain, pntr, 4);
      pntr += 4;
      memcpy(&temp, pntr, 4);
      pntr += 4;
      memcpy(&id, pntr, 1);
      pntr += 1;
      MESSAGE(6,printf("\t\t%12.1f %6.2f %6.2f %s\n", time, rain, temp, id););
      MESSAGE(11,fprintf(fp2,"\t\t%12.1f %6.2f %6.2f %s\n", time, rain, temp, id););
   }
   free(buffer2);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   status = PTdetach(PTid_fixed);
   MESSAGE(10,printf("\t\tstatus = PTdetach(PTid_fixed);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdetach %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTdetach(PTid_fixed);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdetach %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }


   PTid_float = PTattach(ptfid, "FloatBuoy_Point");
   MESSAGE(10,printf("\t\tPTid_float = PTattach(ptfid, \"FloatBuoy_Point\");\n"););
   MESSAGE(8,printf("\t\tValue returned by PTattach %d\n",PTid_float););
   MESSAGE(11,fprintf(fp2,"\t\tPTid_float = PTattach(ptfid, \"FloatBuoy_Point\");\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTattach %d\n",PTid_float););
   if (PTid_float == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTdefboxregion
*/
   MESSAGE(4,printf("\tTesting PTdefboxregion...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTdefboxregion...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   corlon[0]=-75.0;
   corlon[1]=75.0;
   corlat[0]=-25.0;
   corlat[1]=25.0;

   regionID = PTdefboxregion(PTid_float, corlon, corlat);
   MESSAGE(10,printf("\t\tregionID = PTdefboxregion(PTid_float, corlon, corlat);\n"););
   MESSAGE(8,printf("\t\tRegion id returned by PTdefboxregion %d\n",regionID););
   MESSAGE(11,fprintf(fp2,"\t\tregionID = PTdefboxregion(PTid_float, corlon, corlat);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tRegion id returned by PTdefboxregion %d\n",regionID););
   if (regionID == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););

/*
**	Test Case -- PTregionrecs
*/
   MESSAGE(4,printf("\tTesting PTregionrecs...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTregionrecs...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   status = PTregionrecs(PTid_float,regionID,0,&nrecs,recs);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   else
   {
      MESSAGE(10,printf("\t\tstatus = PTregionrecs(PTid_float,regionID,0,&nrecs,recs);\n"););
      MESSAGE(8,printf("\t\tStatus returned by call to PTregionrecs %d\n",status););
      MESSAGE(10,printf("\t\tNumber of records in region %d\n",nrecs););
      MESSAGE(11,fprintf(fp2,"\t\tstatus = PTregionrecs(PTid_float,regionID,0,&nrecs,recs);\n"););
      MESSAGE(11,fprintf(fp2,"\t\tStatus returned by call to PTregionrecs %d\n",status););
      MESSAGE(11,fprintf(fp2,"\t\tNumber of records in region %d\n",nrecs););
      for (i=0;i<nrecs;i++){
         MESSAGE(10,printf("\t\tRecord number of subsetted records %d\n",recs[i]););
         MESSAGE(11,fprintf(fp2,"\t\tRecord number of subsetted records %d\n",recs[i]););
      }
   }

   status = PTregionrecs(PTid_float,regionID,1,&nrecs,recs);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   else
   {
      MESSAGE(10,printf("\t\tstatus = PTregionrecs(PTid_float,regionID,1,&nrecs,recs);\n"););
      MESSAGE(8,printf("\t\tStatus returned by call to PTregionrecs %d\n",status););
      MESSAGE(10,printf("\t\tNumber of records in region %d\n",nrecs););
      MESSAGE(11,fprintf(fp2,"\t\tstatus = PTregionrecs(PTid_float,regionID,1,&nrecs,recs);\n"););
      MESSAGE(11,fprintf(fp2,"\t\tStatus returned by call to PTregionrecs %d\n",status););
      MESSAGE(11,fprintf(fp2,"\t\tNumber of records in region %d\n",nrecs););
      for (i=0;i<nrecs;i++){
         MESSAGE(10,printf("\t\tRecord number of subsetted records %d\n",recs[i]););
         MESSAGE(11,fprintf(fp2,"\t\tRecord number of subsetted records %d\n",recs[i]););
      }
   }

/*
**	Test Case -- PTregioninfo
*/
   MESSAGE(4,printf("\tTesting PTregioninfo...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTregioninfo...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   status = PTregioninfo(PTid_float, regionID, 1, "Time", &size);
   MESSAGE(10,printf("\t\tstatus = PTregioninfo(PTid_float, regionID, 1, \"Time\", &size);\n"););
   MESSAGE(8,printf("\t\tSize of region in bytes %d\n",size););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTregioninfo(PTid_float, regionID, 1, \"Time\", &size);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tSize of region in bytes %d\n",size););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTextractregion
*/
   MESSAGE(4,printf("\tTesting PTextractregion...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTextractregion...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   datbuf64 = (float64 *)malloc(size);
   status = PTextractregion(PTid_float, regionID, 1, "Time", datbuf64);
   MESSAGE(10,printf("\t\tstatus = PTextractregion(PTid_float, regionID, 1, \"Time\", datbuf64);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTextractregion %d\n",status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTextractregion(PTid_float, regionID, 1, \"Time\", datbuf64);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTextractregion %d\n",status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   for(i=0;i<5; i++)
   {
      MESSAGE(8,printf("\t\t %f\n",datbuf64[i]););
      MESSAGE(11,fprintf(fp2,"\t\t %f\n",datbuf64[i]););
   }
   free(datbuf64);

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTdeftimeperiod
*/
   MESSAGE(4,printf("\tTesting PTdeftimeperiod...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTdeftimeperiod...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   startt = 35000000.0;
   stopt = 36500000.0;

   periodID = PTdeftimeperiod(PTid_float,startt,stopt);
   MESSAGE(10,printf("\t\tperiodID = PTdeftimeperiod(PTid_float,startt,stopt);\n"););
   MESSAGE(8,printf("\t\tPeriod id returned by PTdeftimeperiod %d\n",periodID););
   MESSAGE(11,fprintf(fp2,"\t\tperiodID = PTdeftimeperiod(PTid_float,startt,stopt);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tPeriod id returned by PTdeftimeperiod %d\n",periodID););
   if (periodID == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););

/*
**	Test Case -- PTperiodrecs
*/
   MESSAGE(4,printf("\tTesting PTperiodrecs...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTperiodrecs...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   status = PTperiodrecs(PTid_float,periodID,0,&nrecs,recs);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   else
   {
      MESSAGE(10,printf("\t\tstatus = PTperiodrecs(PTid_float,periodID,0,&nrecs,recs);\n"););
      MESSAGE(8,printf("\t\tStatus returned by call to PTperiodrecs %d\n",status););
      MESSAGE(10,printf("\t\tNumber of records in time period %d\n",nrecs););
      MESSAGE(11,fprintf(fp2,"\t\tstatus = PTperiodrecs(PTid_float,periodID,0,&nrecs,recs);\n"););
      MESSAGE(11,fprintf(fp2,"\t\tStatus returned by call to PTperiodrecs %d\n",status););
      MESSAGE(11,fprintf(fp2,"\t\tNumber of records in time period %d\n",nrecs););
      for (i=0;i<nrecs;i++){
         MESSAGE(10,printf("\t\tRecord number of subsetted records %d\n",recs[i]););
         MESSAGE(11,fprintf(fp2,"\t\tRecord number of subsetted records %d\n",recs[i]););
      }
   }

   status = PTperiodrecs(PTid_float,periodID,1,&nrecs,recs);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   else
   {
      MESSAGE(10,printf("\t\tstatus = PTperiodrecs(PTid_float,periodID,1,&nrecs,recs);\n"););
      MESSAGE(8,printf("\t\tStatus returned by call to PTperiodrecs %d\n",status););
      MESSAGE(10,printf("\t\tNumber of records in time period %d\n",nrecs););
      MESSAGE(11,fprintf(fp2,"\t\tstatus = PTperiodrecs(PTid_float,periodID,1,&nrecs,recs);\n"););
      MESSAGE(11,fprintf(fp2,"\t\tStatus returned by call to PTperiodrecs %d\n",status););
      MESSAGE(11,fprintf(fp2,"\t\tNumber of records in time period %d\n",nrecs););
      for (i=0;i<nrecs;i++){
         MESSAGE(10,printf("\t\tRecord number of subsetted records %d\n",recs[i]););
         MESSAGE(11,fprintf(fp2,"\t\tRecord number of subsetted records %d\n",recs[i]););
      }
   }

/*
**	Test Case -- PTperiodinfo
*/
   MESSAGE(4,printf("\tTesting PTperiodinfo...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTperiodinfo...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   status = PTperiodinfo(PTid_float, periodID, 1, "Temperature", &size);
   MESSAGE(10,printf("\t\tstatus = PTperiodinfo(PTid_float, periodID, 1, \"Temperature\", &size);\n"););
   MESSAGE(8,printf("\t\tValue of status from PTperiodinfo %d\n",status););
   MESSAGE(8,printf("\t\tSize of period in bytes %d\n",size););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTperiodinfo(PTid_float, periodID, 1, \"Temperature\", &size);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue of status from PTperiodinfo %d\n",status););
   MESSAGE(11,fprintf(fp2,"\t\tSize of period in bytes %d\n",size););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   MESSAGE(11,fprintf(fp2,"\f"););
/*
**	Test Case -- PTextractperiod
*/
   MESSAGE(4,printf("\tTesting PTextractperiod...\n"););
   MESSAGE(4,printf("\t=================\n"););
   MESSAGE(11,fprintf(fp2,"\tTesting PTextractperiod...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================\n"););

   datbuf32 = (float32 *)malloc(size);
   status = PTextractperiod(PTid_float, periodID, 1, "Temperature", datbuf32);
   MESSAGE(10,printf("\t\tstatus=PTextractperiod(PTid_float,periodID,1,\"Temperature\",datbuf32);\n"););
   MESSAGE(8,printf("\t\tStatus value returned by PTextractperiod %d\n",status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus=PTextractperiod(PTid_float,periodID,1,\"Temperature\",datbuf32);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tStatus value returned by PTextractperiod %d\n",status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   for(i=0;i<5; i++)
   {
      MESSAGE(8,printf("\t\t %f\n",datbuf32[i]););
      MESSAGE(11,fprintf(fp2,"\t\t %f\n",datbuf32[i]););
   }
   free(datbuf32);

   range[0]=0.0;
   range[1]=2.0;

 
/*
**  Test Case for NCRs 6598,8827
*/
   MESSAGE(4,printf("\tTest Case for NCRs 6598,8827 ...\n"););
   MESSAGE(4,printf("\t================================\n"););
   MESSAGE(11,fprintf(fp2,"\tTest Case for NCRs 6598,8827 ...\n"););
   MESSAGE(11,fprintf(fp2,"\t=================================\n"););

   regionID = PTdefvrtregion(PTid_float,HDFE_NOPREVSUB,"Rainfall",range);
   if (regionID == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   else
   {
      MESSAGE(8,printf("\t\tRegion ID returned by PTdefvrtregion %d\n",regionID););
      MESSAGE(11,fprintf(fp2,"\t\tRegion ID returned by PTdefvrtregion %d\n",regionID););
   }
 
   status = PTregioninfo(PTid_float,regionID,1,"Rainfall",&size);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   else
   {
      MESSAGE(8,printf("Returned value from PTregioninfo call %d\n",status););
      MESSAGE(8,printf("\t\tSize of region from PTregioninfo %d\n",size););
      MESSAGE(11,fprintf(fp2,"Returned value from PTregioninfo call %d\n",status););
      MESSAGE(11,fprintf(fp2,"\t\tSize of region from PTregioninfo %d\n",size););
   }
   datbuff32=(float32 *)calloc(size,4);
   status = PTextractregion(PTid_float,regionID,1,"Rainfall",datbuff32);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   else
   {
      MESSAGE(8,printf("Returned value from PTextractregion call %d\n",status););
      MESSAGE(11,fprintf(fp2,"Returned value from PTextractregion call %d\n",status););
      for(i=0;i<size/4;i++)
         MESSAGE(8,printf("\t\tData returned from extracted region %f\n",datbuff32[i]););
      for(i=0;i<size/4;i++)
         MESSAGE(11,fprintf(fp2,"\t\tData returned from extracted region %f\n",datbuff32[i]););
   }
   free(datbuff32);
 
   status = PTregioninfo(PTid_float,regionID,1,"Temperature",&size);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   else
   {
      MESSAGE(8,printf("Returned value from PTregioninfo call %d\n",status););
      MESSAGE(8,printf("\t\tSize of region from PTregioninfo %d\n",size););
      MESSAGE(11,fprintf(fp2,"Returned value from PTregioninfo call %d\n",status););
      MESSAGE(11,fprintf(fp2,"\t\tSize of region from PTregioninfo %d\n",size););
   }
   datbuff32=(float32 *)calloc(size,4);
   status = PTextractregion(PTid_float,regionID,1,"Temperature",datbuff32);
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }
   else
   {
      MESSAGE(8,printf("Returned value from PTextractregion call %d\n",status););
      MESSAGE(11,fprintf(fp2,"Returned value from PTextractregion call %d\n",status););
      for(i=0;i<size/4;i++)
         MESSAGE(8,printf("\t\tData returned from extracted region %f\n",datbuff32[i]););
      for(i=0;i<size/4;i++)
         MESSAGE(11,fprintf(fp2,"\t\tData returned from extracted region %f\n",datbuff32[i]););
   }
 
   free(datbuff32);

   status = PTdetach(PTid_float);
   MESSAGE(10,printf("\t\tstatus = PTdetach(PTid_float);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTdetach %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTdetach(PTid_float);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTdetach %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

   status = PTclose(ptfid);
   MESSAGE(10,printf("\t\tstatus = PTclose(ptfid);\n"););
   MESSAGE(8,printf("\t\tValue returned by PTclose %d\n", status););
   MESSAGE(11,fprintf(fp2,"\t\tstatus = PTclose(ptfid);\n"););
   MESSAGE(11,fprintf(fp2,"\t\tValue returned by PTclose %d\n", status););
   if (status == -1)
   {
      MESSAGE(4,printf("\t\t********Error unexpected**********\n"););
      MESSAGE(11,fprintf(fp2,"\t\t********Error unexpected**********\n"););
      MESSAGE(4,HEprint(stdout,0););
      MESSAGE(11,HEprint(fp2,0););
   }

  return 0;
}

#include "mfhdf.h"
#include <math.h>

/* WriteLevels */

main()
{
    intn            status, i, j;
    int16           wgt;
    int32           ptfid, PTid_fixed, PTid_simple, PTid_float, dum, n;
    int32           date, i32 = 9999;
    float32         rain, temp, conc[4], f32 = -7.5;
    float64         lon, lat, time;
    char            buffer[10000], spc[8];
    char           *desc, *id;
    FILE           *fp;
    char           *pntr;

    /*
     * Open the HDF swath file, "PointFile.hdf".
     */
    ptfid = PTopen("PointFile_created_with_hadeos_sample_file_writer_of_HDFEOS2_version_219_or_higher_release.hdf", DFACC_RDWR);
    if(ptfid == -1)
      {
	printf("\t\tError: Unable to open file PointFile.hdf\n");
	return -1;
      }


    /* Write to Simple Point */
    /* --------------------- */
    PTid_simple = PTattach(ptfid, "Simple Point");
    if (PTid_simple == -1)
      {
	printf("\t\tError: Cannot attach point \"Simple Point\"\n");
	return -1;
      }
    fp = fopen("simple.txt", "r");

    n = 0;

    pntr = buffer;
    while(fscanf(fp, "%lf %f %f %f %f %s", 
		 &time, &conc[0], &conc[1], &conc[2], &conc[3], spc) != -1)
    {
	n++;

	spc[strlen(spc)-1] = 0;
	
	memcpy(pntr, &time, 8);
	pntr += 8;
	memcpy(pntr, conc, 4*4);
	pntr += 4*4;
	memcpy(pntr, spc + 1, 4);
	pntr += 4;
    }
    fclose(fp);

    status = PTwritelevel(PTid_simple, 0, n, buffer);
    if (status == -1)
      {
	printf("\t\tError: Cannot write level 0 for point \"Simple Point\"\n");
	return -1;
      }
    PTdetach(PTid_simple);



    /* Write to Fixed Buoy Point */
    /* ------------------------- */
    PTid_fixed = PTattach(ptfid, "FixedBuoy Point");
    if (PTid_fixed == -1)
      {
	printf("\t\tError: Cannot attach point \"FixedBuoy Point\"\n");
	return -1;
      }

    /* Write First (0th) Level */
    /* ----------------------- */
    fp = fopen("fixedBuoy0.txt", "r");

    n = 0;

    strcpy(buffer,"");
    pntr = buffer;

    desc = (char *)malloc(16*sizeof(char));
    id = (char *)malloc(4*sizeof(char));

    while(fscanf(fp, "%s %lf %lf %d %s", desc, &lon, &lat, &date, id) != -1)
    {
	n++;

	desc[strlen(desc)-1] = 0; /* get rid of second single quote
				     read from the file with the string */
	id[strlen(id)-1] = 0; /* get rid of second single quote 
				 read from the file with the string */

	memcpy(pntr, desc + 1, 8); /* +1 is to ignore first single quote 
				     read from the file with the string */
	pntr += 8;
	memcpy(pntr, &lon, 8);
	pntr += 8;
	memcpy(pntr, &lat, 8);
	pntr += 8;
	memcpy(pntr, &date, 4);
	pntr += 4;
	memcpy(pntr, id + 1, 1); /* +1 is to ignore first single quote 
				     read from the file with the string */
	pntr += 1;
    }
    fclose(fp);
    
    status = PTwritelevel(PTid_fixed, 0, n, buffer);
    if (status == -1)
      {
	printf("\t\tError: Cannot write level 0 for point \"FixedBuoy Point\"\n");
	return -1;
      }

    /* Write Second (1th) Level */
    /* ------------------------ */
    fp = fopen("fixedBuoy1.txt", "r");

    n = 0;

    pntr = buffer;
    while(fscanf(fp, "%lf %f %f %s", &time, &rain, &temp, id) != -1)
    {
	n++;
	
	id[strlen(id)-1] = 0;

	memcpy(pntr, &time, 8);
	pntr += 8;
	memcpy(pntr, &rain, 4);
	pntr += 4;
	memcpy(pntr, &temp, 4);
	pntr += 4;
	memcpy(pntr, id + 1, 1);
	pntr += 1;
    }
    fclose(fp);
    
    status = PTwritelevel(PTid_fixed, 1, n, buffer);
    if (status == -1)
      {
	printf("\t\tError: Cannot write level 1 for point \"FixedBuoy Point\"\n");
	return -1;
      }
    status = PTwriteattr(PTid_fixed, "int32", DFNT_INT32, 1, &i32);
    if (status == -1)
      {
	printf("\t\tError: Cannot write attribute for \"FixedBuoy Point\"\n");
	return -1;
      }
    PTdetach(PTid_fixed);


    /* Write to Floating Buoy Point */
    /* ---------------------------- */
    PTid_float = PTattach(ptfid, "FloatBuoy Point");
    if (PTid_float == -1)
      {
	printf("\t\tError: Cannot attach point \"FloatBuoy Point\"\n");
	return -1;
      }

    /* Write First (0th) Level */
    /* ----------------------- */
    fp = fopen("floatBuoy0.txt", "r");

    n = 0;

    pntr = buffer;
    while(fscanf(fp, "%s %d %d %s", desc, &date, &dum, id) != -1)
    {
	n++;
	
	wgt = (int16) dum;
	
	desc[strlen(desc)-1] = 0;
	id[strlen(id)-1] = 0;

	memcpy(pntr, desc + 1, 8);
	pntr += 8;
	memcpy(pntr, &date, 4);
	pntr += 4;
	memcpy(pntr, &wgt, 2);
	pntr += 2;
	memcpy(pntr, id + 1, 1);
	pntr += 1;
    }
    fclose(fp);
    
    status = PTwritelevel(PTid_float, 0, n, buffer);
    if (status == -1)
      {
	printf("\t\tError: Cannot write level 0 for point \"FloatBuoy Point\"\n");
	return -1;
      }


    /* Write Second (1th) Level */
    /* ------------------------ */
    fp = fopen("floatBuoy1.txt", "r");

    n = 0;
    pntr = buffer;

    while(fscanf(fp, "%lf %lf %lf %f %f %s", 
		 &time, &lon, &lat, &rain, &temp, id) != -1)
    {
	n++;
	
	id[strlen(id)-1] = 0;

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
	memcpy(pntr, id + 1, 1);
	pntr += 1;
    }
    fclose(fp);
    
    status = PTwritelevel(PTid_float, 1, n, buffer);
    if (status == -1)
      {
	printf("\t\tError: Cannot write level 1 for point \"FloatBuoy Point\"\n");
	return -1;
      }

    status = PTwriteattr(PTid_float, "float32", DFNT_FLOAT32, 1, &f32);
    if (status == -1)
      {
	printf("\t\tError: Cannot write attribute for \"FloatBuoy Point\"\n");
	return -1;
      }
    PTdetach(PTid_float);
        
    PTclose(ptfid);
    free(id);
    free(desc);
    return 0;
}

#include "mfhdf.h"
#include <math.h>

/* ReadLevels */

main()
{
    intn            status, i, j;
    
    int32           ptfid, n, nt, sz;
    int32           PTid, date, i32;
    float32         rain, temp, conc[4];
    float64         lon, lat, time;
    int32           fldsz, fldlevels[32], nattr;
    int32           fldtype[32], fldorder[32], recs[128];
    
    char            *pntr, *buffer, id[2], desc[16], spc[8];
    char            fldlist[128], *attrnames;
    int32           strbufsize;


    /*
     * Open the HDF swath file, "PointFile.hdf".
     */

    ptfid = PTopen("PointFile_created_with_hadeos_sample_file_writer_of_HDFEOS2_version_219_or_higher_release.hdf", DFACC_READ);
    if(ptfid == -1)
      {
	printf("\t\tError: Unable to open file PointFile.hdf\n");
	return -1;
       }


    /* Read Simple Point */
    /* ----------------- */
    PTid = PTattach(ptfid, "Simple Point");
    if (PTid == -1)
      {
	printf("\t\tError: Cannot attach point \"Simple Point\"\n");
	return -1;
      }
    strcpy(fldlist,"");
    status = PTlevelinfo(PTid, 0, fldlist, fldtype, fldorder);
    if (status == -1)
      {
	printf("\t\tError: Cannot get level info for point \"Simple Point\"\n");
	return -1;
      }
    fldsz = PTsizeof(PTid, fldlist, fldlevels);
    if (fldsz == -1)
      {
	printf("\t\tError: Cannot get field size of \"Simple Point\"\n");
	return -1;
      }

    n = PTnrecs(PTid, 0);
    if (n == -1)
      {
	printf("\t\tError: point \"Simple Point\" has no records.\n");
	return -1;
      }
    if(fldsz == 0)
      {
	printf("\t\tError: Cannot allocate mamory for buffer;  fldsz == 0\n");
	return -1;
      }

    buffer = (char *) calloc(n * fldsz, 1);
    for (i=0; i<n; i++)
    {
	recs[i] = i;
    }
    
    status = PTreadlevel(PTid, 0, fldlist, n, recs, buffer);
    if (status == -1)
      {
	printf("\t\tError: Cannot read level for point \"Simple Point\"\n");
	return -1;
      }
    pntr = buffer;

    for (i=0; i<n; i++)
    {
	memcpy(&time, pntr, 8);
	pntr += 8;
	memcpy(conc, pntr, 4*4);
	pntr += 4*4;
	memcpy(spc, pntr, 4);
	pntr += 4;
	printf("%12.1f %6.2f %6.2f %6.2f %6.2f %s\n", 
	       time,conc[0],conc[1],conc[2],conc[3],spc);
    }
    
    free(buffer);
    PTdetach(PTid);
    


    /* Read Fixed Buoy Point */
    /* --------------------- */
    PTid = PTattach(ptfid, "FixedBuoy Point");
    if (status == -1)
      {
	printf("\t\tError: Cannot get level info for point \"FixedBuoy Point\"\n");
	return -1;
      }

    /* Read First (0th) Level */
    /* ----------------------- */
    strcpy(fldlist,"");
    status = PTlevelinfo(PTid, 0, fldlist, fldtype, fldorder);
    if (status == -1)
      {
	printf("\t\tError: Cannot get level info for point \"FixedBuoy Point\"\n");
	return -1;
      }

    fldsz = PTsizeof(PTid, fldlist, fldlevels);
    if (fldsz == -1)
      {
	printf("\t\tError: Cannot get field size of \"FixedBuoy Point\"\n");
	return -1;
      }

    n = PTnrecs(PTid, 0);
    if (n == -1)
      {
	printf("\t\tError: point \"Simple Point\" has no records.\n");
	return -1;
      }
    for (i=0; i<n; i++)
    {
	recs[i] = i;
    }

    if(fldsz == 0)
      {
	printf("\t\tError: Cannot allocate mamory for buffer;  fldsz == 0\n");
	return -1;
      }

    buffer = (char *) calloc(n * fldsz, 1);
    printf("\n");
    n=1;
    recs[0]=0;
    status = PTreadlevel(PTid, 0, fldlist, n, recs, buffer);
    if (status == -1)
      {
	printf("\t\tError: Cannot read level for point \"FixedBuoy Point\"\n");
	return -1;
      }
    pntr = buffer;
    for (i=0; i<n; i++)
    {
 	memcpy(desc, pntr, 8);
 	pntr += 8;
	desc[8] = 0;
	memcpy(&lon, pntr, 8);
	pntr += 8;
	memcpy(&lat, pntr, 8);
	pntr += 8;
	memcpy(&date, pntr, 4);
	pntr += 4;
	memcpy(id, pntr, 1);
	pntr += 1;
	id[1]=0;
	printf("%-10s %12.6lf %12.6lf %10d %-4s\n", desc,lon,lat,date,id);
    }
    printf("\n");
    free(buffer);


    /* Read Second (1th) Level */
    /* ------------------------ */
    strcpy(fldlist,"");
    status = PTlevelinfo(PTid, 1, fldlist, fldtype, fldorder);
    if (status == -1)
      {
	printf("\t\tError: Cannot get level info for point \"FixedBuoy Point\"\n");
	return -1;
      }

    fldsz = PTsizeof(PTid, fldlist, fldlevels);
    if (fldsz == -1)
      {
	printf("\t\tError: Cannot get field size of \"FixedBuoy Point\"\n");
	return -1;
      }


    n = PTnrecs(PTid, 1);

    if (n == -1)
      {
	printf("\t\tError: point \"FixedBuoy Point\" has no records.\n");
	return -1;
      }

    if(fldsz == 0)
      {
	printf("\t\tError: Cannot allocate mamory for buffer;  fldsz == 0\n");
	return -1;
      }

    buffer = (char *) calloc(fldsz, 1);

    for (i=0; i<n; i++)
    {
	pntr = buffer;
	recs[0] = i;
	
	status = PTreadlevel(PTid, 1, fldlist, 1, recs, buffer);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot read level for point \"FixedBuoy Point\"\n");
	    return -1;
	  }
	memcpy(&time, pntr, 8);
	pntr += 8;
	memcpy(&rain, pntr, 4);
	pntr += 4;
	memcpy(&temp, pntr, 4);
	pntr += 4;
	memcpy(id, pntr, 1);
	id[1]= 0;
	pntr += 1;
	printf("%12.1f %6.2f %6.2f %s\n", time,rain,temp,id);
    }

    free(buffer);

    nattr = PTinqattrs(PTid, NULL,&strbufsize);
    if (nattr == -1)
      {
	printf("\t\tError: Cannot inquire attributes for \"FixedBuoy Point\"\n");
	return -1;
      }
    attrnames = (char *)malloc((strbufsize+1)*sizeof(char));
    
    nattr = PTinqattrs(PTid, attrnames,&strbufsize);
    if (nattr == -1)
      {
	printf("\t\tError: Cannot inquire attributes for \"FixedBuoy Point\"\n");
	return -1;
      }

    status = PTreadattr(PTid, attrnames, &i32);
    if (status == -1)
      {
	printf("\t\tError: Cannot read attribute for \"FixedBuoy Point\"\n");
	return -1;
      }
    printf("\n");
    printf("Attribute value for %s =%d\n", attrnames, i32);
    status = PTattrinfo(PTid, "int32", &nt, &sz);
    printf("\n");
    if (status == -1)
      {
	printf("\t\tError: Cannot get attribute info for \"FixedBuoy Point\"\n");
	return -1;
      }
    printf("\n");
    PTdetach(PTid);
    free(attrnames);
    
    PTclose(ptfid);

    return 0;
}


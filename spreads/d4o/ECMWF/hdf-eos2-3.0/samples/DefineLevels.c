#include "mfhdf.h"

/* DefineLevels */

/*
 * In this example we will open the "PointFile" HDF file and define the point
 * levels.
 */


main()
{

    intn            status;
    int32           ptfid, PTid_fixed, PTid_float, PTid_simple,fieldtype[8], fieldorder[8];
    char            fldlist[255];


    /*
     * We first open the HDF swath file, "PointFile.hdf".  Because this file
     * already exist and we wish to write to it, we use the DFACC_RDWR access
     * code in the open statement.  The PTopen routine returns the point file
     * id, ptfid, which is used to identify the file in subsequent routines.
     */

    ptfid = PTopen("PointFile_created_with_hadeos_sample_file_writer_of_HDFEOS2_version_219_or_higher_release.hdf", DFACC_RDWR);
    if(ptfid == -1)
      {
	printf("\t\tError: Unable to open file PointFile.hdf\n");
	return -1;
       }


    if (ptfid != -1)
    {


	/* Simple Point */
	/* ------------ */
	PTid_simple = PTattach(ptfid, "Simple Point");
	if (PTid_simple == -1)
	  {
	    printf("\t\tError: Cannot attach point \"Simple Point\"\n");
	    return -1;
	  }
	strcpy(fldlist, "Time,Concentration,Species");

	fieldtype[0] = DFNT_FLOAT64;
	fieldtype[1] = DFNT_FLOAT32;
	fieldtype[2] = DFNT_CHAR8;
	
	fieldorder[0] = 1;
	fieldorder[1] = 4;
	fieldorder[2] = 4;
	
	status = PTdeflevel(PTid_simple, "Sensor", fldlist, fieldtype, fieldorder);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define level \"Sensor\"\n");
	    return -1;
	  }
	PTdetach(PTid_simple);
	/*
	goto skip;
	*/
	/* Fixed Buoy Point */
	/* ---------------- */
	PTid_fixed = PTattach(ptfid, "FixedBuoy Point");
	if (PTid_fixed == -1)
	  {
	    printf("\t\tError: Cannot attach point \"FixedBuoy Point\"\n");
	    return -1;
	  }

	/* Define Description/Location Level */
	strcpy(fldlist, "Label,Longitude,Latitude,DeployDate,ID");
	
	fieldtype[0] = DFNT_CHAR8;
	fieldtype[1] = DFNT_FLOAT64;
	fieldtype[2] = DFNT_FLOAT64;
	fieldtype[3] = DFNT_INT32;
	fieldtype[4] = DFNT_CHAR8;

	fieldorder[0] = 8;
	fieldorder[1] = 0;  /* Order 0 same as Order 1 for numeric scalars */
	fieldorder[2] = 0;
	fieldorder[3] = 0;
	fieldorder[4] = 1;

	status = PTdeflevel(PTid_fixed, "Desc-Loc", fldlist, 
			    fieldtype, fieldorder);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define level \"Desc-Loc\"\n");
	    return -1;
	  }

	/* Define Data Level */
	strcpy(fldlist, "Time,Rainfall,Temperature,ID");
	
	fieldtype[0] = DFNT_FLOAT64;
	fieldtype[1] = DFNT_FLOAT32;
	fieldtype[2] = DFNT_FLOAT32;
	fieldtype[3] = DFNT_CHAR8;

	fieldorder[0] = 0;
	fieldorder[1] = 0;
	fieldorder[2] = 0;
	fieldorder[3] = 1;

	status = PTdeflevel(PTid_fixed, "Observations", fldlist, 
			    fieldtype, fieldorder);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define level \"Observations\"\n");
	    return -1;
	  }
	printf("status from PTdeflevel: %d\n");
	
	status = PTdeflinkage(PTid_fixed, "Desc-Loc", "Observations", "ID");
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define linkage \"Desc-Loc\"\n");
	    return -1;
	  }
	printf("status from PTdeflinkage: %d\n");
	status = PTdetach(PTid_fixed);
	printf("status from PTdetach: %d\n");



	

	/* Floating Buoy Point */
	/* ------------------- */
	PTid_float = PTattach(ptfid, "FloatBuoy Point");
	if (PTid_float == -1)
	  {
	    printf("\t\tError: Cannot attach point \"FloatBuoy Point\"\n");
	    return -1;
	  }

	/* Define Description Level */
	strcpy(fldlist, "Label,DeployDate,Weight,ID");
	
	fieldtype[0] = DFNT_CHAR8;
	fieldtype[1] = DFNT_INT32;
	fieldtype[2] = DFNT_INT16;
	fieldtype[3] = DFNT_CHAR8;

	fieldorder[0] = 8;
	fieldorder[1] = 0;
	fieldorder[2] = 0;
	fieldorder[3] = 1;


	status = PTdeflevel(PTid_float, "Description", fldlist, 
			    fieldtype, fieldorder);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define level \"Description\"\n");
	    return -1;
	  }

	/* Define Data Level */
	strcpy(fldlist, "Time,Longitude,Latitude,Rainfall,Temperature,ID");

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

	status = PTdeflevel(PTid_float, "Measurements", fldlist, 
			    fieldtype, fieldorder);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define level \"Measurements\"\n");
	    return -1;
	  }

	status = PTdeflinkage(PTid_float, "Description", "Measurements", "ID");
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define linkage \"Description\"\n");
	    return -1;
	  }

	PTdetach(PTid_float);

      skip:
	PTclose(ptfid);
    }
    
    return 0;
}

#include "hdf.h"
#include "HdfEosDef.h"

/*
 * In this example we will (1) open the "GridFile" HDF file, (2) attach to
 * the "Grid1" grid, and (3) define the grid fields.
 */


main()
{

    intn            status, i, j;
    int32           gdfid, GDid1, GDid2, GDid3, nflds;
    int32           dims[8], start[8], count[8];
    
    float32         fillval1=-7.0, fillval2=-9999.0, f32;
    float32         datbuf[100000];
    
    char            fieldlist[255];
    

    /*
     * We first open the HDF grid file, "GridFile.hdf".  Because this file
     * already exist and we wish to write to it, we use the DFACC_RDWR access
     * code in the open statement.  The GDopen routine returns the grid file
     * id, gdfid, which is used to identify the file in subsequent routines.
     */

    gdfid = GDopen("GridFile_created_with_hadeos_sample_file_writer_of_HDFEOS2_version_219_or_higher_release.hdf", DFACC_RDWR);


    /*
     * If the grid file cannot be found, GDopen will return -1 for the file
     * handle (gdfid).  We there check that this is not the case before
     * proceeding with the other routines.
     * 
     * The GDattach routine returns the handle to the existing grid "Grid1",
     * GDid.  If the grid is not found, GDattach returns -1 for the handle.
     */

    if (gdfid != -1)
    {

	GDid1 = GDattach(gdfid, "UTMGrid");
	if (GDid1 == -1)
	  {
	    printf("\t\tError: Cannot attach to grid \"UTMGrid\"\n");
	    return -1;
	  }

	status = GDdeffield(GDid1, "Pollution", "Time,YDim,XDim",
			    DFNT_FLOAT32, HDFE_NOMERGE);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define field \"Pollution\"\n");
	    return -1;
	  }
	status = GDdeffield(GDid1, "Vegetation", "YDim,XDim",
			    DFNT_FLOAT32, HDFE_NOMERGE);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define field \"Vegetation\"\n");
	    return -1;
	  }
	status = GDwritefieldmeta(GDid1, "Extern", "YDim,XDim",
				  DFNT_FLOAT32);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define external field \"Extern\"\n");
	    return -1;
	  }
	status = GDsetfillvalue(GDid1, "Pollution", &fillval1);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot set fill value for \"Pollution\"\n");
	    return -1;
	  }

	

	GDid2 = GDattach(gdfid, "PolarGrid");
	if (GDid2 == -1)
	  {
	    printf("\t\tError: Cannot attach to grid \"PolarGrid\"\n");
	    return -1;
	  }
	status = GDdeffield(GDid2, "Temperature", "YDim,XDim",
			    DFNT_FLOAT32, HDFE_AUTOMERGE);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define field \"Temperature\"\n");
	    return -1;
	  }
	status = GDdeffield(GDid2, "Pressure", "YDim,XDim",
			    DFNT_FLOAT32, HDFE_AUTOMERGE);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define field \"Pressure\"\n");
	    return -1;
	  }
	status = GDdeffield(GDid2, "Soil Dryness", "YDim,XDim",
				DFNT_FLOAT32, HDFE_NOMERGE);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define field \"Soil Dryness\"\n");
	    return -1;
	  }
	status = GDdeffield(GDid2, "Spectra", "Bands,YDim,XDim",
			    DFNT_FLOAT64, HDFE_AUTOMERGE);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define field \"Spectra\"\n");
	    return -1;
	  }
	status = GDsetfillvalue(GDid2, "Pressure", &fillval2);
	if (status == -1)
	  {
	    printf("\t\tError: Cannot define fill value for field \"Pressure\"\n");
	    return -1;
	  }
    }

    GDdetach(GDid1);
    GDdetach(GDid2);

    GDid2 = GDattach(gdfid, "PolarGrid");
    if (GDid2 == -1)
      {
	printf("\t\tError: Cannot attach to grid \"PolarGrid\"\n");
	return -1;
      }
    status = GDreadfield(GDid2, "Pressure", NULL, NULL, NULL, datbuf);
    if (status == -1)
      {
	printf("\t\tError: Cannot read field \"Pressure\"\n");
	return -1;
      }
    GDdetach(GDid2);



    GDid3 = GDattach(gdfid, "GEOGrid");
    if (GDid3 == -1)
      {
	printf("\t\tError: Cannot attach to grid \"GEOGrid\"\n");
	return -1;
      }
    status = GDdeffield(GDid3, "GeoSpectra", "YDim,XDim",
			DFNT_FLOAT64, HDFE_AUTOMERGE);
    if (status == -1)
      {
	printf("\t\tError: Cannot define field \"GeoSpectra\"\n");
	return -1;
      }
    status = GDsetfillvalue(GDid3, "GeoSpectra", &fillval2);
    if (status == -1)
      {
	printf("\t\tError: Cannot define fill value for field \"Pressure\"\n");
	return -1;
      }

    GDdetach(GDid3);
    GDclose(gdfid);

    return 0;
}

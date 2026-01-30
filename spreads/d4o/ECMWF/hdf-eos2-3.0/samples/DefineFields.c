#include "hdf.h"
#include "HdfEosDef.h"

/*
 * In this example we will (1) open the "SwathFile" HDF file, (2) attach to
 * the "Swath1" swath, and (3) define the swath fields.
 */


main()
{

    intn            status, i, j;
    int32           swfid, SWid;


    /*
     * We first open the HDF swath file, "SwathFile.hdf".  Because this file
     * already exist and we wish to write to it, we use the DFACC_RDWR access
     * code in the open statement.  The SWopen routine returns the swath file
     * id, swfid, which is used to identify the file in subsequent routines.
     */

    swfid = SWopen("SwathFile_created_with_hadeos_sample_file_writer_of_HDFEOS2_version_219_or_higher_release.hdf", DFACC_RDWR);
    if (swfid == -1)
      {
	printf("\t\tError: Cannot open file \"SwathFile.hdf\"\n");
	return -1;
      }

    /*
     * If the swath file cannot be found, SWopen will return -1 for the file
     * handle (swfid).  We there check that this is not the case before
     * proceeding with the other routines.
     * 
     * The SWattach routine returns the handle to the existing swath "Swath1",
     * SWid.  If the swath is not found, SWattach returns -1 for the handle.
     */

    if (swfid != -1)
    {

	SWid = SWattach(swfid, "Swath1");
	if (SWid == -1)
	  {
	    printf("\t\tError: Cannot attach swath \"Swath1\"\n");
	    return -1;
	  }
	if (SWid != -1)
	{

	    /*
	     * We define seven fields.  The first three, "Time", "Longitude"
	     * and "Latitude" are geolocation fields and thus we use the
	     * geolocation dimensions "GeoTrack" and "GeoXtrack" in the field
	     * definitions.  We also must specify the data type using the
	     * standard HDF data type codes.  In this example the geolocation
	     * are 4-byte (32 bit) floating point numbers.
	     * 
	     * The next four fields are data fields.  Note that either
	     * geolocation or data dimensions can be used.  If an error
	     * occurs during the definition, such as a dimension that cannot
	     * be found, then the return status will be set to -1.
	     */

	    status = SWdefgeofield(SWid, "Time", "GeoTrack",
				   DFNT_FLOAT64, HDFE_NOMERGE);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot define geo field  \"Time\"\n");
		return -1;
	      }
	    status = SWdefgeofield(SWid, "Longitude", "GeoTrack,GeoXtrack",
				   DFNT_FLOAT32, HDFE_AUTOMERGE);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot define geo field  \"Longitude\"\n");
		return -1;
	      }
	    status = SWdefgeofield(SWid, "Latitude", "GeoTrack,GeoXtrack",
				   DFNT_FLOAT32, HDFE_AUTOMERGE);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot define geo field  \"Latitude\"\n");
		return -1;
	      }
	    status = SWdefdatafield(SWid, "Density", "GeoTrack",
				    DFNT_FLOAT32, HDFE_NOMERGE);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot define data field  \"Density\"\n");
		return -1;
	      }
	    status = SWdefdatafield(SWid, "Temperature", "GeoTrack,GeoXtrack",
				    DFNT_FLOAT32, HDFE_NOMERGE);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot define data field  \"Temperature\"\n");
		return -1;
	      }
	    status = SWdefdatafield(SWid, "Temperature_3D", "Bands,GeoTrack,GeoXtrack",
				    DFNT_FLOAT32, HDFE_NOMERGE);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot define data field  \"Temperature\"\n");
		return -1;
	      }
	    status = SWdefdatafield(SWid, "Pressure", "Res2tr,Res2xtr",
				    DFNT_FLOAT64, HDFE_NOMERGE);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot define data field  \"Pressure\"\n");
		return -1;
	      }
	    status = SWdefdatafield(SWid, "Spectra", "Bands,Res2tr,Res2xtr",
				    DFNT_FLOAT64, HDFE_NOMERGE);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot define data field  \"Spectra\"\n");
		return -1;
	      }

	    /* Define Appendable Field */
	    /* ----------------------- */
	    status = SWdefdatafield(SWid, "Count", "Unlim", DFNT_INT16,
				    HDFE_NOMERGE);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot define data field  \"Count\"\n");
		return -1;
	      }
	}
    }
    status = SWdetach(SWid);
    if (status == -1)
      {
	printf("\t\tError: Cannot detach SWid\n");
	return -1;
      }
    status = SWclose(swfid);
    if (status == -1)
      {
	printf("\t\tError: Cannot close hdf file.\n");
	return -1;
      }
    return 0;
}

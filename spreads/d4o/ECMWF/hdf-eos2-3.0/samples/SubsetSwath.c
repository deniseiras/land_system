#include "hdf.h"
#include "HdfEosDef.h"

/*
 * In this example we will (1) open the "SwathFile" HDF file, (2) attach to
 * the "UTMSwath", and (3) read data from the "Vegetation" field.
 */


main()
{

    intn            i, j, status;
    
    int32           swfid, SWid, regionID, size, periodID;
    int32           firstXtrk, LastXtrk, dims[8], rank, ntype;
    
    float64         cornerlon[2], cornerlat[2];
    float64        *datbuf;
    


    /*
     * Open the HDF swath file, "SwathFile.hdf".
     */

    swfid = SWopen("SwathFile_created_with_hadeos_sample_file_writer_of_HDFEOS2_version_219_or_higher_release.hdf", DFACC_RDWR);


    if (swfid != -1)
    {

	SWid = SWattach(swfid, "Swath1");

	if (SWid != -1)
	{
	    cornerlon[0] = 3.;
	    cornerlat[0] = 5.;
	    cornerlon[1] = 7.;
	    cornerlat[1] = 12.;

	    regionID = SWdefboxregion(SWid, cornerlon, cornerlat,
				      HDFE_MIDPOINT);
	    if (regionID == -1)
	      {
		printf("\t\tError: Cannot define subsetting region for swath \"Swath1\"\n");
		return -1;
	      }

	    status = SWregioninfo(SWid, regionID, "Longitude", &ntype,
				  &rank, dims, &size);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot get region info for field \"Spectra\" of swath \"Swath1\"\n");
		return -1;
	      }
	    status = SWregioninfo(SWid, regionID, "Spectra", &ntype,
				  &rank, dims, &size);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot get region info for field \"Spectra\" of swath \"Swath1\"\n");
		return -1;
	      }
	    datbuf = (float64 *) malloc(size);

	    status = SWextractregion(SWid, regionID, "Spectra", 
				     HDFE_INTERNAL, datbuf);
	    	    if (status == -1)
	      {
		printf("\t\tError: Cannot extract region for field \"Spectra\" of swath \"Swath1\"\n");
		return -1;
	      }
	    free(datbuf);



	    /* Time Subsetting */
	    periodID = SWdeftimeperiod(SWid, 35232487.2, 36609898.1,
				      HDFE_MIDPOINT);
	    if (periodID == -1)
	    {
	      printf("\t\tError: Cannot define time period for swath  \"Swath1\"\n");
	      return -1;
	    }
	    status = SWperiodinfo(SWid, periodID, "Time", &ntype,
				  &rank, dims, &size);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot get period info for swath \"Swath1\"\n");
		return -1;
	      }
	    datbuf = (float64 *) malloc(size);

	    status = SWextractperiod(SWid, periodID, "Time", 
				     HDFE_INTERNAL, datbuf);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot extract period for swath \"Swath1\"\n");
		return -1;
	      }
	    free(datbuf);
	}
    }

    SWdetach(SWid);

    SWclose(swfid);

    return 0;
}

#include "hdf.h"
#include <math.h>

/*
 * In this example we will (1) open the "GridFile" HDF file, (2) attach to
 * the "PolarGrid", and (3) subset data from the "Temperature" field.
 */


main()
{

    intn            i, j, status;
    
    int32           gdfid, GDid, regionID, size, dims[8], ntype, rank;

    float32        *datbuf32;
    
    float64         cornerlon[2], cornerlat[2];
    float64        *datbuf64, upleft[2], lowright[2];
    


    /*
     * Open the HDF grid file, "GridFile.hdf".
     */

    gdfid = GDopen("GridFile_created_with_hadeos_sample_file_writer_of_HDFEOS2_version_219_or_higher_release.hdf", DFACC_RDWR);


    if (gdfid != -1)
    {

	GDid = GDattach(gdfid, "PolarGrid");

	if (GDid != -1)
	{
	    cornerlon[0] = 57.;
	    cornerlat[0] = 23.;
	    cornerlon[1] = 59.;
	    cornerlat[1] = 35.;

	    cornerlon[0] = 10.;
	    cornerlat[0] = 80.;
	    cornerlon[1] = 80.;
	    cornerlat[1] = 10.;


	    regionID = GDdefboxregion(GDid, cornerlon, cornerlat);
	    if (regionID == -1)
	      {
		printf("\t\tError: Cannot define subsetting region for grid \"PolarGrid\"\n");
		return -1;
	      }
	    
	    status = GDregioninfo(GDid, regionID, "Temperature", &ntype,
				&rank, dims, &size, upleft, lowright);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot get region info for field \"Temperature\" of grid \"PolarGrid\"\n");
		return -1;
	      }
	    printf("size: %d\n",size);
	    
	    datbuf32 = (float32 *) calloc(size, 1);
	    
	    status = GDextractregion(GDid, regionID, "Temperature", 
				     datbuf32);
	    	    if (status == -1)
	      {
		printf("\t\tError: Cannot extract region info for field \"Temperature\" of grid \"PolarGrid\"\n");
		return -1;
	      }
	    free(datbuf32);
	}
    }

    GDdetach(GDid);

    GDclose(gdfid);

    return 0;
}

#include "hdf.h"


main()
{

    intn            i, status;
    
    int32           ptfid, PTid, regionID, periodID, size;
    int32           level;
    
    float64         cornerlon[2], cornerlat[2], starttime, stoptime;
    float64        *datbuf;
    


    /*
     * Open the HDF point file, "PointFile.hdf".
     */

    ptfid = PTopen("PointFile_created_with_hadeos_sample_file_writer_of_HDFEOS2_version_219_or_higher_release.hdf", DFACC_RDWR);
    if(ptfid == -1)
      {
	printf("\t\tError: Unable to open file PointFile.hdf\n");
	return -1;
       }


    if (ptfid != -1)
    {

	PTid = PTattach(ptfid, "FloatBuoy Point");
	if (PTid == -1)
	  {
	    printf("\t\tError: Cannot attach point \"FloatBuoy Point\"\n");
	    return -1;
	  }
	
	if (PTid != -1)
	{
	    cornerlon[0] = -145.;
	    cornerlat[0] = -15.;
	    cornerlon[1] = -135;
	    cornerlat[1] = -8.;

	    regionID = PTdefboxregion(PTid, cornerlon, cornerlat);
	    if (regionID == -1)
	      {
		printf("\t\tError: Cannot define subsetting region for point \"FloatBuoy Point\"\n");
		return -1;
	      }
	    level = 1;
	    status = PTregioninfo(PTid, regionID, level, 
				  "Longitude,Latitude", &size);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot get region info for point \"FloatBuoy Point\"\n");
		return -1;
	      }
	    datbuf = (float64 *) malloc(size);

	    status = PTextractregion(PTid, regionID, level, 
				  "Longitude,Latitude", (char *) datbuf);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot extract region for point \"FloatBuoy Point\"\n");
		return -1;
	      }
	    for (i=0; i<size/16; i++)
	    {
		printf("%d %lf %lf\n", i, datbuf[2*i], datbuf[2*i+1]);
	    }
	    
	    free(datbuf);


	    starttime = 35208757.6;
	    stoptime = 35984639.2;
	    
	    periodID = PTdeftimeperiod(PTid, starttime, stoptime);
	    if (periodID == -1)
	    {
	      printf("\t\tError: Cannot define time period for point \"FloatBuoy Point\"\n");
	      return -1;
	    }
	    level = 1;
	    status = PTperiodinfo(PTid, periodID, level, 
				  "Time", &size);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot get period info for point \"FloatBuoy Point\"\n");
		return -1;
	      }
	    datbuf = (float64 *) malloc(size);

	    status = PTextractperiod(PTid, periodID, level, 
				  "Time", datbuf);

	    if (status == -1)
	      {
		printf("\t\tError: Cannot extract period for point \"FloatBuoy Point\"\n");
		return -1;
	      }
	    for (i=0; i<size/8; i++)
	    {
		printf("%d %lf\n", i, datbuf[i]);
	    }

	    free(datbuf);
	    


	}
    }

    PTdetach(PTid);
    PTclose(ptfid);

    return 0;
}

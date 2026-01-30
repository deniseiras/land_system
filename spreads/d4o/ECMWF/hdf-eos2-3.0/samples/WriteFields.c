#include "hdf.h"


/*
 * In this example we will (1) open the "SwathFile" HDF file, (2) attach to
 * the "Swath1" swath, and (3) write data to the "Longitude", "Latitude",
 * and "Spectra" fields.
 */


main()
{

    intn            i, j, k, status, track, xtrack, start[3], count[3];

    int32           swfid, SWid, attr[4]={3, 5, 7, 11};

    float32         lng[10] = {0.0, 1.0, 2.0, 3.0, 4.0,
    5.0, 6.0, 7.0, 8.0, 9.0}, lat[10];
    /* Define longitude values along the cross track */

    float64         plane[40*20], tme[20];
    
    /*
     * Open the HDF swath file, "SwathFile.hdf".
     */

    swfid = SWopen("SwathFile_created_with_hadeos_sample_file_writer_of_HDFEOS2_version_219_or_higher_release.hdf", DFACC_RDWR);
    if (swfid == -1)
      {
	printf("\t\tError: Cannot open file \"SwathFile.hdf\"\n");
	return -1;
      }

    if (swfid != -1)
    {

	/*
	 * Attach the "Swath1" swath.
	 */

	SWid = SWattach(swfid, "Swath1");
	if (SWid == -1)
	  {
	    printf("\t\tError: Cannot attach swath \"Swath1\"\n");
	    return -1;
	  }
	if (SWid != -1)
	{

	    /* Write data starting at the beginning of each cross track */
	    start[1] = 0;
	    count[0] = 1;
	    count[1] = 10;
	    

	    /*
	     * Loop through all the tracks, incrementing the track starting
	     * position by one each time.
	     */

	    for (track = 0; track < 20; track++)
	    {
		start[0] = track;
		status = SWwritefield(SWid, "Longitude", start, NULL,
				      count, lng);
		if (status == -1)
		  {
		    printf("\t\tError: Cannot write field \"Longitude\"\n");
		    return -1;
		  }
                for (xtrack = 0; xtrack < 10; xtrack++)
                    lat[xtrack] = track;
		
                status = SWwritefield(SWid, "Latitude", start, NULL,
                                      count, lat);
		if (status == -1)
		  {
		    printf("\t\tError: Cannot write field \"Latitude\"\n");
		    return -1;
		  }
	    }



	    /*
	     *  Write Time Field 
             */
	    for (i=0;i<20;i++) tme[i] = 34574087.3 + 84893.2*i;
	    status = SWwritefield(SWid, "Time", NULL, NULL,
				  NULL, tme);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot write field \"Time\"\n");
		return -1;
	      }
	    

	    /*
	     * Write Spectra one plane at a time 
	     * Value is 100 * track index + band index
	     */

	    start[1] = 0;
	    start[2] = 0;
	    count[0] = 1;
	    count[1] = 40;
	    count[2] = 20;
	    for (i = 0; i < 15; i++)
	    {
		start[0] = i;
		for (j=0; j<40; j++)
		    for (k= 0; k<20; k++)
			plane[j*20+k] = j*100 + i;
		
		status = SWwritefield(SWid, "Spectra", start, NULL,
				      count, plane);
		if (status == -1)
		  {
		    printf("\t\tError: Cannot write field \"Spectra\"\n");
		    return -1;
		  }
	    }


	    /* Write User Attribute */
	    status = SWwriteattr(SWid, "TestAttr", DFNT_INT32, 4, attr);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot write attribute \"TestAttr\"\n");
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

#include "mfhdf.h"
/*
 * In this example we will (1) open an HDF file, (2) create the swath
 * interface within the file and (3) define the swath field dimensions.
 */


main()
{

    intn            status, i, j;
    int32           swfid, SWid, indx[12]={0,1,3,6,7,8,11,12,14,24,32,39};


    /*
     * We first open the HDF swath file, "SwathFile.hdf".  Because this file
     * does not already exist, we use the DFACC_CREATE access code in the
     * open statement.  The SWopen routine returns the swath file id, swfid,
     * which is used to identify the file in subsequent routines in the
     * library.
     */
    /* a long filename (> 80 characters) is used to test long file names ( > 80 characters) 
       that caused problem in version 2.18
    */

    swfid = SWopen("SwathFile_created_with_hadeos_sample_file_writer_of_HDFEOS2_version_219_or_higher_release.hdf", DFACC_CREATE);
    if (swfid == -1)
      {
	printf("\t\tError: Cannot open file \"SwathFile.hdf\"\n");
	return -1;
      }
   
    /*
     * The first of these, SWcreate, creates the swath, "Swath1", within the
     * file designated by the file id, swfid.  It returns the swath id, SWid,
     * which identifies the swath in subsequent routines.  We will show how
     * to define, write and read field swaths in later programs.
     */

    SWid = SWcreate(swfid, "Swath1");
    if (SWid == -1)
      {
	printf("\t\tError: Cannot create swath \"Swath1\"\n");
	return -1;
      }

    /*
     * Typically, many fields within a swath share the same dimension. The
     * swath interface therefore provides a way of defining dimensions that
     * will then be used to define swath fields.  A dimension is defined with
     * a name and a size and is connected to the particular swath through the
     * swath id.  In this example, we define the geolocation track and
     * cross track dimensions with size 20 and 10 respectively and two
     * dimensions corresponding to these but with twice the resolution.
     * We also define a dimension corresponding to a number of spectal
     * bands.
     */

    status = SWdefdim(SWid, "GeoTrack", 20);
    if (status == -1)
      {
	printf("\t\tError: Cannot define dim \"GeoTrack\"\n");
	return -1;
      }
    status = SWdefdim(SWid, "GeoXtrack", 10);
    if (status == -1)
      {
	printf("\t\tError: Cannot define dim \"GeoXtrack\"\n");
	return -1;
      }
    status = SWdefdim(SWid, "Res2tr", 40);
    if (status == -1)
      {
	printf("\t\tError: Cannot define dim \"Res2tr\"\n");
	return -1;
      }
    status = SWdefdim(SWid, "Res2xtr", 20);
    if (status == -1)
      {
	printf("\t\tError: Cannot define dim \"Res2xtr\"\n");
	return -1;
      }
    status = SWdefdim(SWid, "Bands", 15);
    if (status == -1)
      {
	printf("\t\tError: Cannot define dim \"Bands\"\n");
	return -1;
      }
    status = SWdefdim(SWid, "IndxTrack", 12);
    if (status == -1)
      {
	printf("\t\tError: Cannot define dim \"IndxTrack\"\n");
	return -1;
      }
    /* Define Unlimited Dimension */
    /* -------------------------- */
    status = SWdefdim(SWid, "Unlim", NC_UNLIMITED);
    if (status == -1)
      {
	printf("\t\tError: Cannot define dim \"Unlim\"\n");
	return -1;
      }

    /*
     * Once the dimensions are defined, the relationship (mapping) between the
     * geolocation dimensions, such as track and cross track, and the data
     * dimensions, must be established.  This is done through the SWdefdimmap
     * routine.  It takes as input the swath id, the names of the dimensions
     * designating the geolocation and data dimensions, respectively, and the
     * offset and increment defining the relation.
     * 
     * In the first example we relate the "GeoTrack" and "Res2tr" dimensions
     * with an offset of 0 and an increment of 2.  Thus the ith element of
     * "Geotrack" corresponds to the 2 * ith element of "Res2tr".
     * 
     * In the second example, the ith element of "GeoXtrack" corresponds to the
     * 2 * ith + 1 element of "Res2xtr".
     *
     * Note that there is no relationship between the geolocation dimensions
     * and the "Bands" dimension.
     */

    status = SWdefdimmap(SWid, "GeoTrack", "Res2tr", 0, 2);
    if (status == -1)
      {
	printf("\t\tError: Cannot define dim map batween \"GeoTrack\" and \"Res2tr\"\n");
	return -1;
      }
    status = SWdefdimmap(SWid, "GeoXtrack", "Res2xtr", 1, 2);
    if (status == -1)
      {
	printf("\t\tError: Cannot define dim map batween \"GeoXtrack\" and \"Res2xtr\"\n");
	return -1;
      }
    /* Define Indexed Mapping */
    status = SWdefidxmap(SWid, "IndxTrack", "Res2tr", indx);
    if (status == -1)
      {
	printf("\t\tError: Cannot define dim map batween \"IndxTrack\" and \"Res2tr\"\n");
	return -1;
      }
    /*
     * We now close the swath interface with the SWdetach routine.  This step
     * is necessary to properly store the swath information within the file.
     */

    status = SWdetach(SWid);
    if (status == -1)
      {
	printf("\t\tError: Cannot detach SWid\n");
	return -1;
      }

    /*
     * Finally, we close the swath file using the SWclose routine.  This will
     * release the swath file handles established by SWopen.
     */

    status = SWclose(swfid);
    if (status == -1)
      {
	printf("\t\tError: Cannot close hdf file.\n");
	return -1;
      }
    return 0;
}

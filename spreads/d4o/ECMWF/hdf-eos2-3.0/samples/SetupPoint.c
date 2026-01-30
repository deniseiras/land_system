#include "hdf.h"

/* SetupPoint */

main()
{

    intn            status;
    int32           ptfid, PTid1, PTid2, PTid3;

    /*
     * We first open the HDF point file, "PointFile.hdf".  Because this file
     * does not already exist, we use the DFACC_CREATE access code in the
     * open statement.  The PTopen routine returns the point file id, ptfid,
     * which is used to identify the file in subsequent routines in the
     * library.
     */
    /* a long filename (> 80 characters) is used to test long file names ( > 80 characters) 
       that caused problem in version 2.18
    */


	ptfid = PTopen("PointFile_created_with_hadeos_sample_file_writer_of_HDFEOS2_version_219_or_higher_release.hdf", DFACC_CREATE);
	if(ptfid == -1)
	  {
	    printf("\t\tError: Unable to open file PointFile.hdf\n");
	    return -1;
	  }
	
    PTid1 = PTcreate(ptfid, "Simple Point");
    if (PTid1 == -1)
   {
     printf("\t\tError: Cannot create point \"Simple Point\"\n");
     return -1;
   }

    PTid2 = PTcreate(ptfid, "FixedBuoy Point");
    if (PTid2 == -1)
   {
     printf("\t\tError: Cannot create point \"FixedBuoy Point\"\n");
     return -1;
   }

    PTid3 = PTcreate(ptfid, "FloatBuoy Point");
    if (PTid3 == -1)
   {
     printf("\t\tError: Cannot create point \"FloatBuoy Point\"\n");
     return -1;
   }

    /*
     * We now close the point interface with the PTdetach routine.  This step
     * is necessary to properly store the point information within the file.
     */

    status = PTdetach(PTid1);
   if (status == -1)
   {
     printf("\t\tError: Cannot detach point id \"PTid1\"\n");
     return -1;
   }
    status = PTdetach(PTid2);
   if (status == -1)
   {
     printf("\t\tError: Cannot detach point id \"PTid2\"\n");
     return -1;
   }
    status = PTdetach(PTid3);
   if (status == -1)
   {
     printf("\t\tError: Cannot detach point id \"PTid3\"\n");
     return -1;
   }
    HEprint(stdout,0);


    /*
     * Finally, we close the Point file using the PTclose routine.  This will
     * release the point file handles established by PTopen.
     */

    status = PTclose(ptfid);
   if (status == -1)
   {
     printf("\t\tError: Cannot close file id \"ptfid\"\n");
     return -1;
   }
    HEprint(stdout,0);

    return 0;
}



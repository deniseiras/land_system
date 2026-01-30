#include "hdf.h"

/*
 * In this example we will demonstrate the use of the unlimited dimension
 * in creating a field that can be appended to.
 */


main()
{

    intn            status, i;
    int16           inarray[5] = {1, 2, 3, 4, 5}, outarray[10];
    int32           swfid, SWid, rank, dims[1], ntype;
    int32           start[1], stride[1], count[1];
    

    swfid = SWopen("SwathFile_created_with_hadeos_sample_file_writer_of_HDFEOS2_version_219_or_higher_release.hdf", DFACC_RDWR);
    if (swfid == -1)
      {
	printf("\t\tError: Cannot open file \"SwathFile.hdf\"\n");
	return -1;
      }
    SWid = SWattach(swfid, "Swath1");
    if (SWid == -1)
      {
	printf("\t\tError: Cannot attach swath \"Swath1\"\n");
	return -1;
      }
    status = SWfieldinfo(SWid, "Count", &rank, dims, &ntype, NULL);
    if (status == -1)
      {
	printf("\t\tError: Cannot get field info for field  \"Count\"\n");
	return -1;
      }
    printf("Initial number of elements: %d\n",dims[0]);

    /* Write 5 records to field */
    /* ------------------------ */
    count[0] = 5;
    status = SWwritefield(SWid, "Count", NULL, NULL, count, inarray);
    if (status == -1)
      {
	printf("\t\tError: Cannot write field  \"Count\"\n");
	return -1;
      }

    status = SWfieldinfo(SWid, "Count", &rank, dims, &ntype, NULL);
    if (status == -1)
      {
	printf("\t\tError: Cannot writefield  \"Count\"\n");
	return -1;
      }
    printf("Number of elements after first write: %d\n",dims[0]);


    
    /* Append 1 record to field */
    /* ------------------------ */
    start[0] = dims[0];
    count[0] = 1;
    SWwritefield(SWid, "Count", start, NULL, count, inarray);
    if (status == -1)
      {
	printf("\t\tError: Cannot write field  \"Count\"\n");
	return -1;
      }

    status = SWfieldinfo(SWid, "Count", &rank, dims, &ntype, NULL);
    if (status == -1)
      {
	printf("\t\tError: Cannot write field  \"Count\"\n");
	return -1;
      }
    printf("Number of elements after append: %d\n",dims[0]);

    SWreadfield(SWid, "Count", NULL, NULL, dims, outarray);
    if (status == -1)
      {
	printf("\t\tError: Cannot write field  \"Count\"\n");
	return -1;
      }
    for (i=0; i<dims[0]; i++) printf("Data Element: %d\n",outarray[i]);
    
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

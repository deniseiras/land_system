#include "hdf.h"
#include "HdfEosDef.h"

/*
 * In this example we will retrieve (1) information about the dimensions, (2)
 * the dimension mappings (geolocation relations), and (3) the swath fields.
 */


main()
{

    intn            status, i;
    int32           swfid, SWid, ndims, nmaps, rk, nt, dim[8], nflds;
    int32          *dims, *off, *inc, *indx, *rank, *ntype;
    int32           n, strbufsize, dimsize, offset, incr, *sizes;

    char           *dimname, *dimmap, *fieldlist, dimlist[80];


    /*
     * Open the Swath File for read only access
     */

    swfid = SWopen("SwathFile_created_with_hadeos_sample_file_writer_of_HDFEOS2_version_219_or_higher_release.hdf", DFACC_READ);
    if (swfid == -1)
      {
	printf("\t\tError: Cannot open file \"SwathFile.hdf\"\n");
	return -1;
      }


    if (swfid != -1)
    {

	/* Attach the swath */

	SWid = SWattach(swfid, "Swath1");
	if (SWid == -1)
	  {
	    printf("\t\tError: Cannot attach swath \"Swath1\"\n");
	    return -1;
	  }

	if (SWid != -1)
	{
	    /* Inquire Dimensions */
	    ndims = SWnentries(SWid, HDFE_NENTDIM, &strbufsize);
	    if (ndims == -1)
	      {
		printf("\t\tError: Cannot get number of dims for swath \"Swath1\"\n");
		return -1;
	      }
	    dims = (int32 *) calloc(ndims, 4);
	    dimname = (char *) calloc(strbufsize + 1, 1);
	    
	    ndims = SWinqdims(SWid, dimname, dims);
	    if (ndims == -1)
	      {
		printf("\t\tError: Cannot get dims for swath \"Swath1\"\n");
		return -1;
	      }
	    printf("Dimension list: %s\n", dimname);
	    for (i = 0; i < ndims; i++)
		printf("dim size: %d\n", dims[i]);
	    
	    free(dims);
	    free(dimname);


	    /* Inquire Dimension Mappings */
	    nmaps = SWnentries(SWid, HDFE_NENTMAP, &strbufsize);
	    if (nmaps == -1)
	      {
		printf("\t\tError: Cannot get number of Dimension mappings for \"Swath1\"\n");
		return -1;
	      }
	    off = (int32 *) calloc(nmaps, 4);
	    inc = (int32 *) calloc(nmaps, 4);
	    dimmap = (char *) calloc(strbufsize + 1, 1);
	    
	    nmaps = SWinqmaps(SWid, dimmap, off, inc);
	    if (nmaps == -1)
	      {
		printf("\t\tError: Cannot get Dimension mappings for \"Swath1\"\n");
		return -1;
	      }
	    printf("Dimension map: %s\n", dimmap);
	    for (i = 0; i < nmaps; i++)
		printf("offset increment: %d %d\n",
		       off[i], inc[i]);
	    free(off);
	    free(inc);
	    free(dimmap);


	    /* Inquire Indexed Dimension Mappings */
	    nmaps = SWnentries(SWid, HDFE_NENTIMAP, &strbufsize);
	    if (nmaps == -1)
	      {
		printf("\t\tError: Cannot get number of Indexed mappings for \"Swath1\"\n");
		return -1;
	      }
	    sizes = (int32 *) calloc(nmaps, 4);
	    dimmap = (char *) calloc(strbufsize + 1, 1);
	    nmaps = SWinqidxmaps(SWid, dimmap, sizes);
	    if (nmaps == -1)
	      {
		printf("\t\tError: Cannot get Indexed mappings for \"Swath1\"\n");
		return -1;
	      }
	    printf("Index Dimension map: %s\n", dimmap);
	    for (i = 0; i < nmaps; i++)
		printf("sizes: %d\n", sizes[i]);

	    free(sizes);
	    free(dimmap);


	    /* Inquire Geolocation Fields */
	    nflds = SWnentries(SWid, HDFE_NENTGFLD, &strbufsize);
	    if (nflds == -1)
	      {
		printf("\t\tError: Cannot get number of geo fields for swath \"Swath1\"\n");
		return -1;
	      }
	    rank = (int32 *) calloc(nflds, 4);
	    ntype = (int32 *) calloc(nflds, 4);
	    fieldlist = (char *) calloc(strbufsize + 1, 1);
	    nflds = SWinqgeofields(SWid, fieldlist, rank, ntype);
	    if (nflds == -1)
	      {
		printf("\t\tError: Cannot get number of geo fields for swath \"Swath1\"\n");
		return -1;
	      }
	    printf("geo fields: %s\n", fieldlist);
	    for (i = 0; i < nflds; i++)
		printf("rank type: %d %d\n", rank[i], ntype[i]);

	    free(rank);
	    free(ntype);
	    free(fieldlist);



	    /* Inquire Data Fields */
	    nflds = SWnentries(SWid, HDFE_NENTDFLD, &strbufsize);
	    if (nflds == -1)
	      {
		printf("\t\tError: Cannot get number of data fields for swath \"Swath1\"\n");
		return -1;
	      }
	    rank = (int32 *) calloc(nflds, 4);
	    ntype = (int32 *) calloc(nflds, 4);
	    fieldlist = (char *) calloc(strbufsize + 1, 1);
	    nflds = SWinqdatafields(SWid, fieldlist, rank, ntype);
	    if (nflds == -1)
	      {
		printf("\t\tError: Cannot get number of data fields for swath \"Swath1\"\n");
		return -1;
	      }
	    printf("data fields: %s\n", fieldlist);
	    for (i = 0; i < nflds; i++)
		printf("rank type: %d %d\n", rank[i], ntype[i]);

	    free(rank);
	    free(ntype);
	    free(fieldlist);


	    /* Get info on "GeoTrack" dim */
	    dimsize = SWdiminfo(SWid, "GeoTrack");
	    if (dimsize == -1)
	      {
		printf("\t\tError: Cannot get size for dimension \"GeoTrack\"\n");
		return -1;
	      }
	    printf("Size of GeoTrack: %d\n", dimsize);


	    /* Get info on "GeoTrack/Res2tr" mapping */
	    status = SWmapinfo(SWid, "GeoTrack", "Res2tr", &offset, &incr);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot get map info between \"GeoTrack\" and \"Res2tr\"\n");
		return -1;
	      }
	    printf("Mapping Offset: %d\n", offset);
	    printf("Mapping Increment: %d\n", incr);


	    /* Get info on "IndxTrack/Res2tr" indexed mapping */
	    dimsize = SWdiminfo(SWid, "IndxTrack");
	    if (dimsize == -1)
	      {
		printf("\t\tError: Cannot get size for dimension \"IndxTrack\"\n");
		return -1;
	      }
	    indx = (int32 *) calloc(dimsize, 4);
	    n = SWidxmapinfo(SWid, "IndxTrack", "Res2tr", indx);
	    if (n == -1)
	      {
		printf("\t\tError: Cannot get index map info between \"IndxTrack\" and \"Res2tr\"\n");
		return -1;
	      }
	    for (i = 0; i < n; i++)
		printf("Index Mapping Entry %d: %d\n", i+1, indx[i]);
	    free(indx);


	    /* Get info on "Longitude" Field */
	    status = SWfieldinfo(SWid, "Longitude", &rk, dim, &nt, dimlist);
	    if (status == -1)
	      {
		printf("\t\tError: Cannot get field info for field  \"Longitude\"\n");
		return -1;
	      }
	    printf("Longitude Rank: %d\n", rk);
	    printf("Longitude NumberType: %d\n", nt);
	    printf("Longitude Dimension List: %s\n", dimlist);	    
	    for (i=0; i<rk; i++)
		printf("Dimension %d: %d\n",i+1,dim[i]);

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

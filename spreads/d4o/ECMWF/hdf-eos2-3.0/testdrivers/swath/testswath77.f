
c testswath.f
c In this program we create, define and write a simple swath hdfeos file
c using the swath interface
c
      program testswath

      integer index1, index2, swfid, swid, status
      integer swid2, rank, sd_id, sds1_id, sds2_id
      integer dim_id, strbufsize, nmaps, ndims, dimsize
      integer i, n, size
      integer start(2), stride(2), dataedge(2), geoedge(2)
      integer rdattr(4),geostart(2), attr(4)
      integer istart(2),iedge(2),dedge(2)
      integer dimsizes(2), compparm(5)
      integer sd_start(2), sd_stride(2), sd_edge(2)
      integer rd_start(2), rd_stride(2), rd_edge(2)
      integer*4 indexmap(30)
      integer*4	nattr, nswath, compcode, idxsz
      integer*4	tstart(1),tstride(1),tedge(1)

      integer swdefdim, swdetach, swdefgfld, swdefdfld
      integer swdefmap, swwrfld, swwrattr, swclose, sfsdmname
      integer sfwdata, sfendacc, sfend, swwrdmeta, swwrgmeta
      integer swfldinfo,swmapinfo, swattrinfo, swrdfld
      integer swrdattr, swgetfill, swsetfill, swdefimap
      integer swreginfo, swextreg, swperinfo, swextper
      integer swdefcomp, swcompinfo, swgmapinfo

      integer*4 swopen, swcreate, swattach, sfstart
      integer*4 swinqmaps, regionid, regionid2
      integer*4 sfcreate, sfdimid, swnentries, swinqimaps
      integer*4 swinqdims, swinqgflds, swinqdflds, swdiminfo
      integer*4 swdefboxreg, swdeftmeper, swimapinfo
      integer*4	swinqattrs, swinqswath, swdupreg
      integer*4 swdefvrtreg, swupimap
      integer*4 swidxinfo

      integer*4 offset, inc, nt, zero,status4
      integer*4 ndxmap(2), rnk(4), ntype(4), dims(5),latdims(2)
      integer*4 rnkd(4), ntyped(4)
      integer*4 idxmap(30), upidxmap(30)

      real*4 ray1(100,40), ray2(100,40)
      real*4 lat(40,50), lon(40,50)
      real*4 ray4(40,100)
      real*4 ray3(40,40), temp(100,40)
      real*4 idxlat(30,30), idxlon(30,30)
      real*4 latcnt, loncnt, raycnt, idxlatcnt, idxloncnt	
      real*4 fillvalue, rdfilval, tempbuf(13000)

      real*8 cornerlon(2), cornerlat(2)
      real*8 twodtime(40,50)
      real*8 onedtime(40)
      real*8 range(2)
      real*8 tmcnt,starttime, endtime
      integer indicies(2)
      integer*4 idx(8)

      character*(39) idxdimmap
      character*(72) dimmap, dimname, fieldlist, dimens
      character*(72) dimlist, attrlist, swathlist

      integer DFACC_CREATE
      parameter (DFACC_CREATE=4)
      integer DFACC_RDWR
      parameter (DFACC_RDWR=3)
      integer DFNT_FLOAT32
      parameter (DFNT_FLOAT32=5)
      integer DFNT_FLOAT64
      parameter (DFNT_FLOAT64=6)
      integer DFNT_INT32
      parameter (DFNT_INT32=24)
      integer HDFE_NOMERGE
      parameter (HDFE_NOMERGE=0)
      integer HDFE_AUTOMERGE
      parameter (HDFE_AUTOMERGE=1)
      integer HDFE_MIDPOINT
      parameter (HDFE_MIDPOINT=0)
      integer HDFE_ENDPOINT
      parameter (HDFE_ENDPOINT=1)
      integer HDFE_INTERNAL
      parameter (HDFE_INTERNAL=0)
      integer HDFE_COMP_SKPHUFF
      parameter (HDFE_COMP_SKPHUFF=3)
      integer HDFE_COMP_NONE
      parameter (HDFE_COMP_NONE=0)
      integer HDFE_NOPREVSUB
      parameter (HDFE_NOPREVSUB=-1)

      compparm(1) = 0
      compparm(2) = 0
      compparm(3) = 0
      compparm(4) = 0
      compparm(5) = 0
      raycnt=-799.0
      tmcnt=46353400.0d0
      starttime=46353450.0d0
      endtime=46500000.0d0
      range(1)=46353450.0d0
      range(2)=46500000.0d0
      latcnt=39.8
      loncnt=78.0
      attr(1)=11
      attr(2)=33
      attr(3)=66
      attr(4)=99
      start(1)=10
      start(2)=10
      tstart(1)=0
      tstride(1)=1
      tedge(1)=50
      geostart(1)=0
      geostart(2)=0
      stride(1)=1
      stride(2)=1
      sd_start(1)=0
      sd_start(2)=0
      sd_stride(1)=1
      sd_stride(2)=1
      sd_edge(1)=100
      sd_edge(2)=40
      rd_start(1)=0
      rd_start(2)=0
      rd_stride(1)=1
      rd_stride(2)=1
      rd_edge(1)=40
      rd_edge(2)=100
      dataedge(1)=20
      dataedge(2)=50
      geoedge(1)=40
      geoedge(2)=50
      idxlatcnt=39.8
      idxloncnt=78.0
      istart(1)=0
      istart(2)=0
      iedge(1)=30
      iedge(2)=30
      dedge(1)=40
      dedge(2)=40
      dimsizes(1)=100
      dimsizes(2)=40
      rank=2
      fillvalue=16.0
      cornerlon(1)=75.3
      cornerlon(2)=77.6
      cornerlat(1)=38.0
      cornerlat(2)=39.8
      indexmap(1)=1
      indexmap(2)=2
      indexmap(3)=3
      indexmap(4)=4
      indexmap(5)=6
      indexmap(6)=7
      indexmap(7)=8
      indexmap(8)=9
      indexmap(9)=11
      indexmap(10)=12
      indexmap(11)=13
      indexmap(12)=14
      indexmap(13)=16
      indexmap(14)=17
      indexmap(15)=18
      indexmap(16)=19
      indexmap(17)=21
      indexmap(18)=22
      indexmap(19)=23
      indexmap(20)=24
      indexmap(21)=26
      indexmap(22)=27
      indexmap(23)=28
      indexmap(24)=29
      indexmap(25)=31
      indexmap(26)=32
      indexmap(27)=33
      indexmap(28)=34
      indexmap(29)=36
      indexmap(30)=37
      zero = 0

c
c This section of the program just fills some arrays with data that will be
c used later in the program
c
      do 110 index1=1,100
         do 100 index2=1,40
            ray1(index1, index2)=raycnt
            ray2(index1, index2)=raycnt + 1.0
            ray4(index2,index1) = raycnt
            raycnt = raycnt +1.
  100    continue
  110 continue

      do 130 index1=1,40
         do 120 index2=1,50
            lat(index1, index2)=latcnt
            lon(index1, index2)=loncnt
            twodtime(index1,index2)=tmcnt
            loncnt=loncnt-.1
            tmcnt=tmcnt+5.0
  120    continue
         onedtime(index1)=tmcnt
         latcnt=latcnt-0.1
         loncnt = 78.0
  130 continue

      do 150 index1=1,30
         do 140 index2=1,30
            idxlat(index1, index2)=idxlatcnt
            idxlon(index1, index2)=idxloncnt
            idxloncnt=idxloncnt-.1
  140    continue
         idxlatcnt=idxlatcnt-.1
         idxloncnt=78.0
  150 continue


      do 170 index1=1,40
         do 160 index2=1,40
            ray3(index1, index2)=raycnt
            raycnt = raycnt+1.25
  160    continue
  170 continue


      do 987 index1=1,30
         idxmap(index1)=zero
         upidxmap(index1)=zero
  987 continue

      open(unit=1, file="testswath_f.txtout", status = "NEW")

      write(*,*)'Testing Swath FORTRAN 77 interface'
      write(*,*)'=================================='
      write(1,*)'Testing Swath FORTRAN 77 interface'
      write(1,*)'=================================='
      write(*,*)' '
      write(1,*)' '

c Test Case -- swopen
c
      write(*,*)'Testing swopen '
      write(*,*)'================='
      write(1,*)'Testing swopen '
      write(1,*)'================='
      swfid=swopen("Swathf_Test.hdf", DFACC_CREATE)
      if (swfid .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'	swfid=swopen("Swathf_Test.hdf", DFACC_CREATE)'
         write(*,*)'	Value returned by swopen ', swfid
         write(1,*)'	swfid=swopen("Swathf_Test.hdf", DFACC_CREATE)'
         write(1,*)'	Value returned by swopen ', swfid
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swcreate
c
      write(1,27)
      write(*,*)'Testing swcreate '
      write(*,*)'================='
      write(1,*)'Testing swcreate '
      write(1,*)'================='
      swid=swcreate(swfid, "Simplef")
      if (swid .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'	swid=swcreate(swfid, "Simplef")'
         write(*,*)'	Value returned by swcreate ', swid
         write(1,*)'	swid=swcreate(swfid, "Simplef")'
         write(1,*)'	Value returned by swcreate ', swid
      endif
      write(*,*)' '
      write(1,*)' '

      swid2=swcreate(swfid, "Indexedf")
      if (swid2 .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'	swid2=swcreate(swfid, "Indexedf")'
         write(*,*)'	Value returned by swcreate ', swid2
         write(1,*)'	swid2=swcreate(swfid, "Indexedf")'
         write(1,*)'	Value returned by swcreate ', swid2
      endif
      write(*,*)' '
      write(1,*)' '


c Test Case -- swdefdim
c
      write(1,27)
      write(*,*)'Testing swdefdim '
      write(*,*)'================='
      write(1,*)'Testing swdefdim '
      write(1,*)'================='
      status=swdefdim(swid, "DataTrack", 100)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'	status=swdefdim(swid, "DataTrack", 100)'
         write(*,*)'	Value returned by swdefdim ',status
         write(1,*)'	status=swdefdim(swid, "DataTrack", 100)'
         write(1,*)'	Value returned by swdefdim ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefdim(swid, "DataXtrack", 40)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'	status=swdefdim(swid, "DataXtrack", 40)'
         write(*,*)'	Value returned by swdefdim ',status
         write(1,*)'	status=swdefdim(swid, "DataXtrack", 40)'
         write(1,*)'	Value returned by swdefdim ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefdim(swid, "GeoTrack", 50) 
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'	status=swdefdim(swid, "GeoTrack", 50)'
         write(*,*)'	Value returned by swdefdim ',status
         write(1,*)'	status=swdefdim(swid, "GeoTrack", 50)'
         write(1,*)'	Value returned by swdefdim ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefdim(swid, "GeoXtrack", 40)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'	status=swdefdim(swid, "GeoXtrack", 40)'
         write(*,*)'	Value returned by swdefdim ',status
         write(1,*)'	status=swdefdim(swid, "GeoXtrack", 40)'
         write(1,*)'	Value returned by swdefdim ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefdim(swid2, "DataTrack", 40)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'	status=swdefdim(swid2, "DataTrack", 40)'
         write(*,*)'	Value returned by swdefdim ', status
         write(1,*)'	status=swdefdim(swid2, "DataTrack", 40)'
         write(1,*)'	Value returned by swdefdim ', status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefdim(swid2, "DataXtrack", 40)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'	status=swdefdim(swid2, "DataXtrack", 40)'
         write(*,*)'	Value returned by swdefdim ', status
         write(1,*)'	status=swdefdim(swid2, "DataXtrack", 40)'
         write(1,*)'	Value returned by swdefdim ', status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefdim(swid2, "GeoTrack", 30)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'	status=swdefdim(swid2, "GeoTrack", 30)'
         write(*,*)'	Value returned by swdefdim ', status
         write(1,*)'	status=swdefdim(swid2, "GeoTrack", 30)'
         write(1,*)'	Value returned by swdefdim ', status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefdim(swid2, "GeoXtrack", 30)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'	status=swdefdim(swid2, "GeoXtrack", 30)'
         write(*,*)'	Value returned by swdefdim ', status
         write(1,*)'	status=swdefdim(swid2, "GeoXtrack", 30)'
         write(1,*)'	Value returned by swdefdim ', status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefdim(swid2, "Timedim", 50)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Define dimension Timedim '
         write(*,*)'	Value returned by swdefdim ', status
         write(1,*)'Define dimension Timedim '
         write(1,*)'	Value returned by swdefdim ', status
      endif

      write(*,*)' '
      write(1,*)' '

c Test Case -- swdefgfld
c
      write(1,27)
      write(*,*)'Testing swdefgfld '
      write(*,*)'================='
      write(1,*)'Testing swdefgfld '
      write(1,*)'================='
      status=swdefgfld(swid, "Latitude","GeoXtrack,GeoTrack",                  &
     1DFNT_FLOAT32, HDFE_AUTOMERGE)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdefgfld(swid, "Latitude","GeoXtrack,GeoTrac       &
     1k", DFNT_FLOAT32, HDFE_AUTOMERGE)'
         write(1,*)'status=swdefgfld(swid, "Latitude","GeoXtrack,GeoTrac       &
     1k", DFNT_FLOAT32, HDFE_AUTOMERGE)'
         write(1,*)'Value returned by swdefgfld ',status
         write(*,*)'Value returned by swdefgfld ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefgfld(swid, "Longitude","GeoXtrack,GeoTrack",                 &
     1DFNT_FLOAT32,HDFE_AUTOMERGE)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Value returned by swdefgfld ',status
         write(1,*)'Value returned by swdefgfld ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefgfld(swid2, "Latitude", "GeoXtrack,GeoTrack",                &
     1DFNT_FLOAT32,HDFE_NOMERGE)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Value returned by swdefgfld ', status
         write(1,*)'Value returned by swdefgfld ', status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefgfld(swid2, "Longitude", "GeoXtrack,GeoTrack",               &
     1DFNT_FLOAT32,HDFE_NOMERGE)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Value returned by swdefgfld ', status
         write(1,*)'Value returned by swdefgfld ', status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefgfld(swid2,'Time','Timedim',DFNT_FLOAT64,HDFE_NOMERGE)       
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Define field Time for swath Indexedf '
         write(*,*)'Status returned from call to swdefgfld ',status
         write(1,*)'Define field Time for swath Indexedf '
         write(1,*)'Status returned from call to swdefgfld ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefgfld(swid, "Time", "GeoXtrack,GeoTrack",                     &
     1DFNT_FLOAT64, HDFE_NOMERGE)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdefgfld(swid, "Time","GeoXtrack,GeoTrack",D       &
     1FNT_FLOAT64, HDFE_NOMERGE)'
         write(*,*)'Value returned by swdefgfld ',status
         write(1,*)'status=swdefgfld(swid, "Time","GeoXtrack,GeoTrack",D       &
     1FNT_FLOAT64, HDFE_NOMERGE)'
         write(1,*)'Value returned by swdefgfld ',status
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swdefdfld
c
      write(1,27)
      write(*,*)'Testing swdefdfld '
      write(*,*)'================='
      write(1,*)'Testing swdefdfld '
      write(1,*)'================='

c Test Case -- swdefcomp
c
      write(1,27)
      write(*,*)'Testing swdefcomp '
      write(*,*)'================='
      write(1,*)'Testing swdefcomp '
      write(1,*)'================='

      status = swdefcomp(swid,HDFE_COMP_SKPHUFF,compparm)
      if (status .lt. zero) then
        write(*,*)'********Error unexpected**********'
        write(1,*)'********Error unexpected**********'
        call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Define compression '
         write(*,*)'Status returned by swdefcomp ',status
         write(1,*)'Define compression'
         write(1,*)'Status returned by swdefcomp ',status
         write(*,*)' '
         write(1,*)' '
      endif

      status=swdefdfld(swid, "SideA", "DataXtrack,DataTrack",                  &
     1DFNT_FLOAT32, HDFE_NOMERGE)
      if (status .lt. zero) then
        write(*,*)'********Error unexpected**********'
        write(1,*)'********Error unexpected**********'
        call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Define data field SideA '
         write(*,*)'Value returned by swdefdfld ',status
         write(1,*)'Define data field SideA '
         write(1,*)'Value returned by swdefdfld ',status
         write(*,*)' '
         write(1,*)' '
      endif

      status = swdefcomp(swid,HDFE_COMP_NONE,compparm)
      if (status .lt. zero) then
        write(*,*)'********Error unexpected**********'
        write(1,*)'********Error unexpected**********'
        call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Define compression '
         write(*,*)'Status returned by swdefcomp ',status
         write(1,*)'Define compression'
         write(1,*)'Status returned by swdefcomp ',status
         write(*,*)' '
         write(1,*)' '
      endif

      status=swdefdfld(swid, "Temperature", "DataXtrack,DataTrack",            &
     1DFNT_FLOAT32, HDFE_NOMERGE)
      if (status .lt. zero) then
        write(*,*)'********Error unexpected**********'
        write(1,*)'********Error unexpected**********'
        call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Define data field Temperature '
         write(*,*)'Value returned by swdefdfld ',status
         write(1,*)'Define data field Temperature '
         write(1,*)'Value returned by swdefdfld ',status
         write(*,*)' '
         write(1,*)' '
      endif

      status=swdefdfld(swid, "Conduction", "DataXtrack,DataTrack",             &
     1DFNT_FLOAT32, HDFE_NOMERGE)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdefdfld(swid,"Conduction","DataXtrack,DataT       &
     1rack",DFNT_FLOAT32, HDFE_NOMERGE)'
         write(*,*)'Value returned by swdefdfld ',status
         write(1,*)'status=swdefdfld(swid,"Conduction","DataXtrack,DataT       &
     1rack",DFNT_FLOAT32, HDFE_NOMERGE)'
         write(1,*)'Value returned by swdefdfld ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefdfld(swid2, "Sensor1", "DataXtrack,DataTrack",               &
     1DFNT_FLOAT32, HDFE_NOMERGE)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdefdfld(swid2, "Sensor1","DataTrack,DataXtr       &
     1ack",DFNT_FLOAT32, HDFE_NOMERGE)'
         write(*,*)'Value returned by swdefdfld ',status
         write(1,*)'status=swdefdfld(swid2, "Sensor1","DataTrack,DataXtr       &
     1ack",DFNT_FLOAT32, HDFE_NOMERGE)'
         write(1,*)'Value returned by swdefdfld ',status
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swdetach
c
      write(1,27)
      write(*,*)'Testing swdetach '
      write(*,*)'================='
      write(1,*)'Testing swdetach '
      write(1,*)'================='
      status=swdetach(swid)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdetach(swid)'
         write(*,*)'Value returned by swdetach ',status
         write(1,*)'status=swdetach(swid)'
         write(1,*)'Value returned by swdetach ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdetach(swid2)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdetach(swid2)'
         write(*,*)'Value returned by swdetach ',status
         write(1,*)'status=swdetach(swid2)'
         write(1,*)'Value returned by swdetach ',status
      endif
      write(*,*)' '
      write(1,*)' '

      swid=swattach(swfid, "Simplef")
      if (swid .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'swid=swattach(swfid, "Simplef")'
         write(*,*)'Value returned by swattach ',swid
         write(1,*)'swid=swattach(swfid, "Simplef")'
         write(1,*)'Value returned by swattach ',swid
      endif
      write(*,*)' '
      write(1,*)' '

      swid2=swattach(swfid, "Indexedf")
      if (swid2 .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'swid2=swattach(swfid, "Indexedf")'
         write(*,*)'Value returned by swattach ',swid2
         write(1,*)'swid2=swattach(swfid, "Indexedf")'
         write(1,*)'Value returned by swattach ',swid2
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swdefmap
c
      write(1,27)
      write(*,*)'Testing swdefmap '
      write(*,*)'================='
      write(1,*)'Testing swdefmap '
      write(1,*)'================='
      status=swdefmap(swid, "GeoTrack", "DataTrack", 0, 2)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdefmap(swid, "GeoTrack", "DataTrack", 0, 2)       &
     1'
         write(*,*)'Value returned by swdefmap ',status
         write(1,*)'status=swdefmap(swid, "GeoTrack", "DataTrack", 0, 2)       &
     1'
         write(1,*)'Value returned by swdefmap ',status
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swdefimap
c
      write(1,27)
      write(*,*)'Testing swdefimap '
      write(*,*)'================='
      write(1,*)'Testing swdefimap '
      write(1,*)'================='
      status=swdefimap(swid2, "GeoTrack", "DataTrack", indexmap)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdefimap(swid2, "GeoTrack", "DataTrack",inde       &
     1xmap)'
         write(*,*)'Value returned by swdefimap ',status
         write(1,*)'status=swdefimap(swid2, "GeoTrack", "DataTrack",inde       &
     1xmap)'
         write(1,*)'Value returned by swdefimap ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdefimap(swid2, "GeoXtrack", "DataXtrack", indexmap)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdefimap(swid2, "GeoXtrack", "DataXtrack",in       &
     1dexmap)'
         write(*,*)'Value returned by swdefimap ',status
         write(1,*)'status=swdefimap(swid2, "GeoXtrack", "DataXtrack",in       &
     1dexmap)'
         write(1,*)'Value returned by swdefimap ',status
      endif
      write(*,*)' '
      write(1,*)' '


c Test Case  -- swsetfill
c
      write(1,27)
      write(*,*)'Testing swsetfill '
      write(*,*)'================='
      write(1,*)'Testing swsetfill '
      write(1,*)'================='
      status=swsetfill(swid, "Temperature", fillvalue)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swsetfill(swid, "Temperature", fillvalue)'
         write(*,*)'Value returned by swsetfill ',status
         write(1,*)'status=swsetfill(swid, "Temperature", fillvalue)'
         write(1,*)'Value returned by swsetfill ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swsetfill(swid, "Conduction", fillvalue)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swsetfill(swid, "Conduction", fillvalue)'
         write(*,*)'Value returned by swsetfill ',status
         write(1,*)'status=swsetfill(swid, "Conduction", fillvalue)'
         write(1,*)'Value returned by swsetfill ',status
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swdetach
c
      write(1,27)
      write(*,*)'Testing swdetach '
      write(*,*)'================='
      write(1,*)'Testing swdetach '
      write(1,*)'================='
      status=swdetach(swid)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdetach(swid)'
         write(*,*)'Value returned by swdetach ',status
         write(1,*)'status=swdetach(swid)'
         write(1,*)'Value returned by swdetach ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdetach(swid2)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdetach(swid2)'
         write(*,*)'Value returned by swdetach ',status
         write(1,*)'status=swdetach(swid2)'
         write(1,*)'Value returned by swdetach ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swclose(swfid)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swclose(swfid)'
         write(*,*)'Value returned by swclose ',status
         write(1,*)'status=swclose(swfid)'
         write(1,*)'Value returned by swclose ',status
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swinqswath
c
      write(1,27)
      write(*,*)'Testing swinqswath '
      write(*,*)'================='
      write(1,*)'Testing swinqswath '
      write(1,*)'================='

      nswath=swinqswath('Swathf_Test.hdf', swathlist, strbufsize)
      if (swfid .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Retrieve information on swaths in file Swathf_Test.h       &
     1df'
         write(*,*)'Nunber of swaths in file ', nswath
         write(*,*)'List of swaths ',swathlist
         write(1,*)'Retrieve information on swaths in file Swathf_Test.h       &
     1df'
         write(1,*)'Nunber of swaths in file ', nswath
         write(1,*)'List of swaths ',swathlist
      endif
      write(*,*)' '
      write(1,*)' '

      swfid=swopen("Swathf_Test.hdf", DFACC_RDWR)
      if (swfid .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'swfid=swopen("Swathf_Test.hdf", DFACC_RDWR)'
         write(*,*)'Value returned by swopen ',swfid
         write(1,*)'swfid=swopen("Swathf_Test.hdf", DFACC_RDWR)'
         write(1,*)'Value returned by swopen ',swfid
      endif
      write(*,*)' '
      write(1,*)' '
 
c Test Case -- swattach
c
      write(1,27)
      write(*,*)'Testing swattach '
      write(*,*)'================='
      write(1,*)'Testing swattach '
      write(1,*)'================='

      swid=swattach(swfid, "Simplef")
      if (swid .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'swid=swattach(swfid, "Simplef")'
         write(*,*)'Value returned by swattach ',swid
         write(1,*)'swid=swattach(swfid, "Simplef")'
         write(1,*)'Value returned by swattach ',swid
      endif
      write(*,*)' '
      write(1,*)' '

      swid2=swattach(swfid, "Indexedf")
      if (swid2 .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'swid2=swattach(swfid, "Indexedf")'
         write(*,*)'Value returned by swattach ',swid2
         write(1,*)'swid2=swattach(swfid, "Indexedf")'
         write(1,*)'Value returned by swattach ',swid2
      endif
      write(*,*)' '
      write(1,*)' '


c Test Case -- swwrfld
c
      write(1,27)
      write(*,*)'Testing swwrfld '
      write(*,*)'================='
      write(1,*)'Testing swwrfld '
      write(1,*)'================='

      status=swwrfld(swid, "SideA", sd_start, stride, rd_edge, ray4)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Write data field SideA '
         write(*,*)'Value returned by swwrfld ',status
         write(1,*)'Write data field SideA '
         write(1,*)'Value returned by swwrfld ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swwrfld(swid, "Temperature", start, stride, dataedge, ray1)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swwrfld(swid, "Temperature", start, stride,da       &
     1taedge, ray1)'
         write(*,*)'Value returned by swwrfld ',status
         write(1,*)'status=swwrfld(swid, "Temperature", start, stride,da       &
     1taedge, ray1)'
         write(1,*)'Value returned by swwrfld ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swwrfld(swid, "Conduction", start, stride, dataedge, ray2)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swwrfld(swid, "Conduction", start, stride,dat       &
     1aedge, ray2)'
         write(*,*)'Value returned by swwrfld ',status
         write(1,*)'status=swwrfld(swid, "Conduction", start, stride,dat       &
     1aedge, ray2)'
         write(1,*)'Value returned by swwrfld ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swwrfld(swid, "Latitude", geostart, stride, geoedge, lat)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swwrfld(swid, "Latitude", geostart, stride, g       &
     1eoedge, lat)'
         write(*,*)'Value returned by swwrfld ',status
         write(1,*)'status=swwrfld(swid, "Latitude", geostart, stride, g       &
     1eoedge, lat)'
         write(1,*)'Value returned by swwrfld ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swwrfld(swid, "Longitude", geostart, stride, geoedge, lon)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swwrfld(swid, "Longitude", geostart, stride,        &
     1geoedge, lon)'
         write(*,*)'Value returned by swwrfld ',status
         write(1,*)'status=swwrfld(swid, "Longitude", geostart, stride,        &
     1geoedge, lon)'
         write(1,*)'Value returned by swwrfld ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swwrfld(swid,"Time",geostart,stride,geoedge,twodtime)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swwrfld(swid, "Time", geostart, stride, geoed       &
     1ge, twodtime)'
         write(*,*)'Value returned by swwrfld for Time ',status
         write(1,*)'status=swwrfld(swid, "Time", geostart, stride, geoed       &
     1ge, twodtime)'
         write(1,*)'Value returned by swwrfld for Time ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swwrfld(swid2, "Latitude", istart, stride, iedge, idxlat)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swwrfld(swid2, "Latitude", istart, stride, i        &
     1edge, idxlat)'
         write(*,*)'Value returned by swwrfld ',status
         write(1,*)'status=swwrfld(swid2, "Latitude", istart, stride, i        &
     1edge, idxlat)'
         write(1,*)'Value returned by swwrfld ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swwrfld(swid2, "Longitude", istart, stride, iedge, idxlon)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swwrfld(swid2, "Longitude", istart, stride, i       &
     1edge, idxlon)'
         write(*,*)'Value returned by swwrfld ',status
         write(1,*)'status=swwrfld(swid2, "Longitude", istart, stride, i       &
     1edge, idxlon)'
         write(1,*)'Value returned by swwrfld ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swwrfld(swid2,'Time',tstart,tstride,tedge,onedtime)
      if (status .lt. zero) then
        write(*,*)'********Error unexpected**********'
        write(1,*)'********Error unexpected**********'
        call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Write field Time '
         write(*,*)'Status returned by swwrfld ',status
         write(1,*)'Write field Time '
         write(1,*)'Status returned by swwrfld ',status
         write(*,*)' '
         write(1,*)' '
      endif

      status=swwrfld(swid2, "Sensor1", istart, stride, iedge, ray3)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swwrfld(swid2, "Sensor1", istart, stride, ied       &
     1ge, ray3)'
         write(*,*)'Value returned by swwrfld ',status
         write(1,*)'status=swwrfld(swid2, "Sensor1", istart, stride, ied       &
     1ge, ray3)'
         write(1,*)'Value returned by swwrfld ',status
      endif
      write(*,*)' '
      write(1,*)' '


c Test Case -- swwrattr
c
      write(1,27)
      write(*,*)'Testing swwrattr '
      write(*,*)'================='
      write(1,*)'Testing swwrattr '
      write(1,*)'================='
      status=swwrattr(swid, "Drift", DFNT_INT32, 4, attr)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swwrattr(swid, "Drift", DFNT_INT32, 4, attr)'
         write(*,*)'Value returned by swwrattr ',status
         write(1,*)'status=swwrattr(swid, "Drift", DFNT_INT32, 4, attr)'
         write(1,*)'Value returned by swwrattr ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdetach(swid)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
      write(*,*)'status=swdetach(swid)'
      write(*,*)'Value returned by swdetach ',status
      write(1,*)'status=swdetach(swid)'
      write(1,*)'Value returned by swdetach ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdetach(swid2)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdetach(swid2)'
         write(*,*)'Value returned by swdetach ',status
         write(1,*)'status=swdetach(swid2)'
         write(1,*)'Value returned by swdetach ',status
      endif
      write(*,*)' '
      write(1,*)' '


c Test Case -- swclose
c
      write(1,27)
      write(*,*)'Testing swclose '
      write(*,*)'================='
      write(1,*)'Testing swclose '
      write(1,*)'================='
      status=swclose(swfid)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Value returned by swclose ',status
         write(1,*)'status=swclose(swfid)'
         write(1,*)'Value returned by swclose ',status
      endif
      write(*,*)' '
      write(1,*)' '


      sd_id=sfstart("Swathf_Test.hdf", DFACC_RDWR)
      if (sd_id .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'sd_id=sfstart("Swathf_Test.hdf", DFACC_RDWR)'
         write(*,*)'Value returned by sfstart ',sd_id
         write(1,*)'sd_id=sfstart("Swathf_Test.hdf", DFACC_RDWR)'
         write(1,*)'Value returned by sfstart ',sd_id
      endif
      write(*,*)' '
      write(1,*)' '

      sds1_id=sfcreate(sd_id, "DataOne", DFNT_FLOAT32, rank,dimsizes)
      if (sds1_id .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'sds1_id=sfcreate(sd_id, "DataOne", DFNT_FLOAT32, ran       &
     1k, dimsizes)'
         write(*,*)'Value returned by sfcreate ',sds1_id
         write(1,*)'sds1_id=sfcreate(sd_id, "DataOne", DFNT_FLOAT32, ran       &
     1k, dimsizes)'
         write(1,*)'Value returned by sfcreate ',sds1_id
      endif
      write(*,*)' '
      write(1,*)' '

      sds2_id=sfcreate(sd_id, "GeoOne", DFNT_FLOAT32, rank,dimsizes)
      if (sds2_id .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'sds2_id=sfcreate(sd_id, "GeoOne", DFNT_FLOAT32, rank       &
     1, dimsizes)'
         write(*,*)'Value returned by sfcreate ',sds2_id
         write(1,*)'sds2_id=sfcreate(sd_id, "GeoOne", DFNT_FLOAT32, rank       &
     1, dimsizes)'
         write(1,*)'Value returned by sfcreate ',sds2_id
      endif
      write(*,*)' '
      write(1,*)' '

      dim_id=sfdimid(sds1_id, 0)
      if (dim_id .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'dim_id=sfdimid(sds1_id, 0)'
         write(*,*)'Value returned by sfdimid ',dim_id
         write(1,*)'dim_id=sfdimid(sds1_id, 0)'
         write(1,*)'Value returned by sfdimid ',dim_id
      endif
      write(*,*)' '
      write(1,*)' '

      status=sfsdmname(dim_id, "DataTrack")
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
      write(*,*)'status=sfsdmname(dim_id, "DataTrack")'
      write(*,*)'Value returned by sfsdmname ',status
      write(1,*)'status=sfsdmname(dim_id, "DataTrack")'
      write(1,*)'Value returned by sfsdmname ',status
      endif
      write(*,*)' '
      write(1,*)' '

      dim_id=sfdimid(sds1_id, 1)
      if (dim_id .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'dim_id=sfdimid(sds1_id, 1)'
         write(*,*)'Value returned by sfdimid ',dim_id
         write(1,*)'dim_id=sfdimid(sds1_id, 1)'
         write(1,*)'Value returned by sfdimid ',dim_id
      endif
      write(*,*)' '
      write(1,*)' '
 
      status=sfsdmname(dim_id, "DataXtrack")
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=sfsdmname(dim_id, "DataXtrack")'
         write(*,*)'Value returned by sfsdmname ',status
         write(1,*)'status=sfsdmname(dim_id, "DataXtrack")'
         write(1,*)'Value returned by sfsdmname ',status
      endif
      write(*,*)' '
      write(1,*)' '

      dim_id=sfdimid(sds2_id, 0)
      if (dim_id .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'dim_id=sfdimid(sds2_id, 0)'
         write(*,*)'Value returned by sfdimid ',dim_id
         write(1,*)'dim_id=sfdimid(sds2_id, 0)'
         write(1,*)'Value returned by sfdimid ',dim_id
      endif
      write(*,*)' '
      write(1,*)' '

      status=sfsdmname(dim_id, "GeoTrack")
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=sfsdmname(dim_id, "GeoTrack")'
         write(*,*)'Value returned by sfsdmname ',status
         write(1,*)'status=sfsdmname(dim_id, "GeoTrack")'
         write(1,*)'Value returned by sfsdmname ',status
      endif
      write(*,*)' '
      write(1,*)' '

      dim_id=sfdimid(sds2_id, 1)
      if (dim_id .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'dim_id=sfdimid(sds2_id, 1)'
         write(*,*)'Value returned by sfdimid ',dim_id
         write(1,*)'dim_id=sfdimid(sds2_id, 1)'
         write(1,*)'Value returned by sfdimid ',dim_id
      endif
      write(*,*)' '
      write(1,*)' '

      status=sfsdmname(dim_id, "GeoXtrack")
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=sfsdmname(dim_id, "GeoXtrack")'
         write(*,*)'Value returned by sfsdmname ',status
         write(1,*)'status=sfsdmname(dim_id, "GeoXtrack")'
         write(1,*)'Value returned by sfsdmname ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=sfwdata(sds1_id, sd_start, sd_stride, sd_edge, ray1)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=sfwdata(sds1_id, sd_start, sd_stride, sd_edge       &
     1, ray1)'
         write(*,*)'Value returned by sfwdata ',status
         write(1,*)'status=sfwdata(sds1_id, sd_start, sd_stride, sd_edge       &
     1, ray1)'
         write(1,*)'Value returned by sfwdata ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=sfwdata(sds2_id, sd_start, sd_stride, sd_edge, ray2)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=sfwdata(sds2_id, sd_start, sd_stride, sd_edge       &
     1, ray2)'
         write(*,*)'Value returned by sfwdata ',status
         write(1,*)'status=sfwdata(sds2_id, sd_start, sd_stride, sd_edge       &
     1, ray2)'
         write(1,*)'Value returned by sfwdata ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=sfendacc(sds1_id)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=sfendacc(sds1_id)'
         write(*,*)'Value returned by sfendacc ',status
         write(1,*)'status=sfendacc(sds1_id)'
         write(1,*)'Value returned by sfendacc ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=sfendacc(sds2_id)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=sfendacc(sds2_id)'
         write(*,*)'Value returned by sfendacc ',status
         write(1,*)'status=sfendacc(sds2_id)'
         write(1,*)'Value returned by sfendacc ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=sfend(sd_id)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=sfend(sd_id)'
         write(*,*)'Value returned by sfend ',status
         write(1,*)'status=sfend(sd_id)'
         write(1,*)'Value returned by sfend ',status
      endif
      write(*,*)' '
      write(1,*)' '

      swfid=swopen("Swathf_Test.hdf", DFACC_RDWR)
      if (swfid .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'swfid=swopen("Swathf_Test.hdf", DFACC_RDWR)'
         write(*,*)'Value returned by swopen ', swfid
         write(1,*)'swfid=swopen("Swathf_Test.hdf", DFACC_RDWR)'
         write(1,*)'Value returned by swopen ', swfid
      endif
      write(*,*)' '
      write(1,*)' '

      swid=swattach(swfid, "Simplef")
      if (swid .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'swid=swattach(swfid, "Simplef")'
         write(*,*)'Value returned by swattach ',swid
         write(1,*)'swid=swattach(swfid, "Simplef")'
         write(1,*)'Value returned by swattach ',swid
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swwrdmeta
c
      write(1,27)
      write(*,*)'Testing swwrdmeta '
      write(*,*)'================='
      write(1,*)'Testing swwrdmeta '
      write(1,*)'================='
      status=swwrdmeta(swid, "DataOne", "DataXtrack,DataTrack",                &
     1DFNT_FLOAT32)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swwrdmeta(swid, "DataOne", "DataXtrack,DataTr       &
     1ack",DFNT_FLOAT32)'
         write(*,*)'Value returned by swwrdmeta ',status
         write(1,*)'status=swwrdmeta(swid, "DataOne", "DataXtrack,DataTr       &
     1ack",DFNT_FLOAT32)'
         write(1,*)'Value returned by swwrdmeta ',status
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swwrgmeta
c
      write(1,27)
      write(*,*)'Testing swwrgmeta '
      write(*,*)'================='
      write(1,*)'Testing swwrgmeta '
      write(1,*)'================='
      status=swwrgmeta(swid, "GeoOne", "GeoXtrack,GeoTrack",                   &
     1DFNT_FLOAT32)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swwrgmeta(swid, "GeoOne", "GeoXtrack,GeoTrack       &
     1", DFNT_FLOAT32)'
         write(*,*)'Value returned by swwrdmeta ',status
         write(1,*)'status=swwrgmeta(swid, "GeoOne", "GeoXtrack,GeoTrack       &
     1", DFNT_FLOAT32)'
         write(1,*)'Value returned by swwrdmeta ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdetach(swid)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdetach(swid)'
         write(*,*)'Value returned by swdetach ',status
         write(1,*)'status=swdetach(swid)'
         write(1,*)'Value returned by swdetach ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swclose(swfid)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swclose(swfid)'
         write(*,*)'Value returned by swclose ',status
         write(1,*)'status=swclose(swfid)'
         write(1,*)'Value returned by swclose ',status
      endif
      write(*,*)' '
      write(1,*)' '


      swfid=swopen("Swathf_Test.hdf", DFACC_RDWR)
      if (swfid .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'swfid=swopen("Swathf_Test.hdf", DFACC_RDWR)'
         write(*,*)'Value returned by swopen ',swfid
         write(1,*)'swfid=swopen("Swathf_Test.hdf", DFACC_RDWR)'
         write(1,*)'Value returned by swopen ',swfid
      endif
      write(*,*)' '
      write(1,*)' '

      swid=swattach(swfid, "Simplef")
      if (swid .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'swid=swattach(swfid, "Simplef")'
         write(*,*)'Value returned by swattach ',swid
         write(1,*)'swid=swattach(swfid, "Simplef")'
         write(1,*)'Value returned by swattach ',swid
      endif
      write(*,*)' '
      write(1,*)' '

      swid2=swattach(swfid, "Indexedf")
      if (swid2 .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'swid2=swattach(swfid, "Indexedf")'
         write(*,*)'Value returned by swattach ',swid2
         write(1,*)'swid2=swattach(swfid, "Indexedf")'
         write(1,*)'Value returned by swattach ',swid2
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case --swdefvrtreg
c
      write(1,27)
      write(*,*)'Testing swdefvrtreg '
      write(*,*)'================='
      write(1,*)'Testing swdefvrtreg '
      write(1,*)'================='

      regionid=swdefvrtreg(swid2,HDFE_NOPREVSUB,'Time',range)
      if (regionid .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Define region id for field Time '
         write(*,*)'Region id returned by swdefvrtreg ',regionid
         write(1,*)'Define region id for field Time '
         write(1,*)'Region id returned by swdefvrtreg ',regionid
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swnentries
c
      write(1,27)
      write(*,*)'Testing swnentries '
      write(*,*)'================='
      write(1,*)'Testing swnentries '
      write(1,*)'================='

      nmaps=swnentries(swid, 1, strbufsize)
      if (nmaps .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'nmaps=swnentries(swid, 1, strbufsize)'
         write(*,*)'Number of dimension mappings ',nmaps
         write(*,*)'Size of strbufsize ',strbufsize
         write(1,*)'nmaps=swnentries(swid, 1, strbufsize)'
         write(1,*)'Number of dimension mappings ',nmaps
         write(1,*)'Size of strbufsize ',strbufsize
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swinqmaps
c
      write(1,27)
      write(*,*)'Testing swinqmaps '
      write(*,*)'================='
      write(1,*)'Testing swinqmaps '
      write(1,*)'================='
      nmaps=swinqmaps(swid, dimmap, offset, inc)
      if (nmaps .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'nmaps=swinqmaps(swid, dimmap, offset, inc)'
         write(*,*)'Dimension mappings ',dimmap
         write(*,*)'offset ',offset
         write(*,*)'increment ',inc
         write(1,*)'nmaps=swinqmaps(swid, dimmap, offset, inc)'
         write(1,*)'Dimension mappings ',dimmap
         write(1,*)'offset ',offset
         write(1,*)'increment ',inc
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swgmapinfo
c
      write(1,27)
      write(*,*)'Testing swgmapinfo '
      write(*,*)'================='
      write(1,*)'Testing swgmapinfo '
      write(1,*)'================='
      status = swgmapinfo(swid2, "GeoTrack")
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status = swgmapinfo(swid2, "GeoTrack")'
         write(1,*)'status = swgmapinfo(swid2, "GeoTrack")'
         write(*,*)'Status returned by swgmapinfo ',status
         write(1,*)'Status returned by swgmapinfo ',status
      endif

c Test Case -- swinqimaps
c
      write(1,27)
      write(*,*)'Testing swinqimaps '
      write(*,*)'================='
      write(1,*)'Testing swinqimaps '
      write(1,*)'================='
      nmaps=swinqimaps(swid2, idxdimmap, ndxmap)
      if (nmaps .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'nmaps=swinqimaps(swid2, idxdimmap, ndxmap)'
         write(*,*)'Number of indexed mappings ',nmaps
         write(*,*)'Indexed Dimension mappings ',idxdimmap
         write(*,*)'Index size ',ndxmap
         write(1,*)'nmaps=swinqimaps(swid2, idxdimmap, ndxmap)'
         write(1,*)'Number of indexed mappings ',nmaps
         write(1,*)'Indexed Dimension mappings ',idxdimmap
         write(1,*)'Index size ',ndxmap
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swinqdims
c
c initialize dims

      dims(1) = 0
      dims(2) = 0
      dims(3) = 0
      dims(4) = 0
      dims(5) = 0

      write(1,27)
      write(*,*)'Testing swinqdims '
      write(*,*)'================='
      write(1,*)'Testing swinqdims '
      write(1,*)'================='
      ndims=swinqdims(swid, dimname, dims)
      if (ndims .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'ndims=swinqdims(swid, dimname, dims)'
         write(*,*)'Number of dimesions ',ndims
         write(*,*)'Names of dimensions ',dimname
         write(*,*)'Size of dimensions ',dims
         write(1,*)'ndims=swinqdims(swid, dimname, dims)'
         write(1,*)'Number of dimesions ',ndims
         write(1,*)'Names of dimensions ',dimname
         write(1,*)'Size of dimensions ',dims
      endif
      write(*,*)' '
      write(1,*)' '


c initialize dims

      dims(1) = 0
      dims(2) = 0
      dims(3) = 0
      dims(4) = 0
      dims(5) = 0

      ndims=swinqdims(swid2, dimname, dims)
      if (ndims .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'ndims=swinqdims(swid2, dimname, dims)'
         write(*,*)'Number of dimesions ',ndims
         write(*,*)'Names of dimensions ',dimname
         write(*,*)'Size of dimensions ',dims
         write(1,*)'ndims=swinqdims(swid2, dimname, dims)'
         write(1,*)'Number of dimesions ',ndims
         write(1,*)'Names of dimensions ',dimname
         write(1,*)'Size of dimensions ',dims
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swinqgflds
c
      write(1,27)
      write(*,*)'Testing swinqgflds '
      write(*,*)'================='
      write(1,*)'Testing swinqgflds '
      write(1,*)'================='

      ndims=swinqdims(swid, dimname, dims)
      if (ndims .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
      endif

      nflds=swinqgflds(swid, fieldlist, rnk, ntype)
      if (nflds .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'nflds=swinqgflds(swid, fieldlist, rnk, ntype)'
         write(*,*)'Number of geolocation fields in swath ',nflds
         write(*,*)'Names of geolocation fields ',fieldlist
         write(*,*)'Rank of fields ',rnk
         write(*,*)'Number type of fields ',ntype
         write(1,*)'nflds=swinqgflds(swid, fieldlist, rnk, ntype)'
         write(1,*)'Number of geolocation fields in swath ',nflds
         write(1,*)'Names of geolocation fields ',fieldlist
         write(1,*)'Rank of fields ',rnk
         write(1,*)'Number type of fields ',ntype
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swinqdflds
c
      write(1,27)
      write(*,*)'Testing swinqdflds '
      write(*,*)'================='
      write(1,*)'Testing swinqdflds '
      write(1,*)'================='
      nflds=swinqdflds(swid, fieldlist, rnkd, ntyped)
      if (nflds .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'nflds=swinqdflds(swid, fieldlist, rnkd, ntyped)'
         write(*,*)'Number of data fields in swath ',nflds
         write(*,*)'Names of data fields ',fieldlist
         write(*,*)'Rank of fields ',rnkd
         write(*,*)'Number type of fields ',ntyped
         write(1,*)'nflds=swinqdflds(swid, fieldlist, rnkd, ntyped)'
         write(1,*)'Number of data fields in swath ',nflds
         write(1,*)'Names of data fields ',fieldlist
         write(1,*)'Rank of fields ',rnkd
         write(1,*)'Number type of fields ',ntyped
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swdiminfo
c
      write(1,27)
      write(*,*)'Testing swdiminfo '
      write(*,*)'================='
      write(1,*)'Testing swdiminfo '
      write(1,*)'================='
      dimsize=swdiminfo(swid, "DataTrack")
      if (dimsize .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'dimsize=swdiminfo(swid, "DataTrack")'
         write(*,*)'Size of dimension DataTrack ',dimsize
         write(1,*)'dimsize=swdiminfo(swid, "DataTrack")'
         write(1,*)'Size of dimension DataTrack ',dimsize
         write(*,*)' '
         write(1,*)' '
      endif

c Test Case -- swcompinfo
c
      write(1,27)
      write(*,*)'Testing swcompinfo '
      write(*,*)'================='
      write(1,*)'Testing swcompinfo '
      write(1,*)'================='

      status = swcompinfo(swid,'SideA',compcode,compparm)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Retrieve compression information for field SideA'
         write(*,*)'The compression code for field SideA = ',compcode          
         write(*,*)'The compression parameter is ',compparm(1)
         write(1,*)'Retrieve compression information for field SideA'
         write(1,*)'The compression code for field SideA = ',compcode          
         write(1,*)'The compression parameter is ',compparm(1)
         write(*,*)' '
         write(1,*)' '
      endif

c Test Case -- swrdfld
c
      write(1,27)
      write(*,*)'Testing swrdfld '
      write(*,*)'================='
      write(1,*)'Testing swrdfld '
      write(1,*)'================='

      status=swrdfld(swid, "Conduction", rd_start,rd_stride,                   &
     1rd_edge, temp)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Value returned by swrdfld ',status
         write(*,*)'status=swrdfld(swid, "Conduction", rd_start,rd_strid       &
     1e, rd_edge, temp)'
         write(1,*)'status=swrdfld(swid, "Conduction", rd_start,rd_strid       &
     1e, rd_edge, temp)'
         write(1,*)'Value returned by swrdfld ',status
         do 190 index1=10,15
            do 180 index2=10,15
               write(*,*)'value of conduction ',temp(index1, index2)
               write(1,*)'value of conduction ',temp(index1, index2)
  180       continue
  190    continue
      endif

      write(*,*)' '
      write(1,*)' '

c Test Case -- swfldinfo
C
      write(1,27)
      write(*,*)'Testing swfldinfo '
      write(*,*)'================='
      write(1,*)'Testing swfldinfo '
      write(1,*)'================='
      status=swfldinfo(swid, "Latitude", rank, latdims, nt, dimens)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swfldinfo(swid, "Latitude", rank, latdims, nt       &
     1, dimens)'
         write(*,*)'Value returned by swfldinfo ',status
         write(*,*)'Rank of field latitude ',rank
         write(*,*)'dimension list of field latitude ',dimens
         write(*,*)'Size of latitude dimensions ',latdims
         write(*,*)'number type of field latitude ',nt
         write(1,*)'status=swfldinfo(swid, "Latitude", rank, latdims, nt       &
     1, dimens)'
         write(1,*)'Value returned by swfldinfo ',status
         write(1,*)'Rank of field latitude ',rank
         write(1,*)'dimension list of field latitude ',dimens
         write(1,*)'Size of latitude dimensions ',latdims
         write(1,*)'number type of field latitude ',nt
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swmapinfo
c
      write(1,27)
      write(*,*)'Testing swmapinfo '
      write(*,*)'================='
      write(1,*)'Testing swmapinfo '
      write(1,*)'================='
      status=swmapinfo(swid, "GeoTrack", "DataTrack", offset, inc)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swmapinfo(swid, "GeoTrack", "DataTrack", offs       &
     1et, inc)'
         write(*,*)'Value returned by swmapinfo ',status
         write(*,*)'Offset ',offset,' Increment ',inc
         write(1,*)'status=swmapinfo(swid, "GeoTrack", "DataTrack", offs       &
     1et, inc)'
         write(1,*)'Value returned by swmapinfo ',status
         write(1,*)'Offset ',offset,' Increment ',inc
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swimapinfo
c
      write(1,27)
      write(*,*)'Testing swimapinfo '
      write(*,*)'================='
      write(1,*)'Testing swimapinfo '
      write(1,*)'================='
      status4=swimapinfo(swid2,"GeoXtrack","DataXtrack",idxmap)
      if (status4 .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status4=swimapinfo(swid2,"GeoXtrack","DataXtrack",         &
     1idxmap)'
         write(*,*)'Value returned by swimapinfo ',status4
         do 980 index1=1,30
            write(*,*)' Value of index array ',idxmap(index1)
            write(1,*)' Value of index array ',idxmap(index1)
  980    continue
         write(1,*)'status4=swimapinfo(swid2, "GeoXtrack", "DataXtrack",       &
     1idxmap)'
         write(1,*)'Value returned by swimapinfo ',status4
         write(*,*)'Indexed map values ',idxmap
         write(1,*)'Indexed map values ',idxmap
      endif
      write(*,*)' '
      write(1,*)' '
 
c Test Case -- swattrinfo
c
      write(1,27)
      write(*,*)'Testing swattrinfo '
      write(*,*)'================='
      write(1,*)'Testing swattrinfo '
      write(1,*)'================='
      status=swattrinfo(swid, "Drift", n, size)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swattrinfo(swid, "Drift", n, size)'
         write(*,*)'Value returned by swattrinfo ',status
         write(*,*)'Number of attributes ',n,' Size ',size
         write(1,*)'status=swattrinfo(swid, "Drift", n, size)'
         write(1,*)'Value returned by swattrinfo ',status
         write(1,*)'Number of attributes ',n,' Size ',size
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swinqattrs
c
      write(1,27)
      write(*,*)'Testing swinqattrs '
      write(*,*)'================='
      write(1,*)'Testing swinqattrs '
      write(1,*)'================='

      nattr = swinqattrs(swid,attrlist,strbufsize)
      if (nattr .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Number of attributres in swath ',nattr
         write(*,*)'Attribute list of swath ',attrlist
         write(1,*)'Number of attributres in swath ',nattr
         write(1,*)'Attribute list of swath ',attrlist
         write(*,*)' '
         write(1,*)' '
      endif


c Test Case -- swrdattr
c
      write(1,27)
      write(*,*)'Testing swrdattr '
      write(*,*)'================='
      write(1,*)'Testing swrdattr '
      write(1,*)'================='

      status=swrdattr(swid,"Drift", rdattr)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swrdattr(swid,"Drift", rdattr)'
         write(*,*)'Value returned by swrdattr ',status
         write(*,*)'attribute ',rdattr
         write(1,*)'status=swrdattr(swid,"Drift", rdattr)'
         write(1,*)'Value returned by swrdattr ',status
         write(1,*)'attribute ',rdattr
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swgetfill
c
      write(1,27)
      write(*,*)'Testing swgetfill '
      write(*,*)'================='
      write(1,*)'Testing swgetfill '
      write(1,*)'================='
      status=swgetfill(swid, "Conduction", rdfilval)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swgetfill(swid, "Conduction", rdfilval)'
         write(*,*)'Value returned by swgetfill ',status
         write(*,*)'Value of fill ',rdfilval
         write(1,*)'status=swgetfill(swid, "Conduction", rdfilval)'
         write(1,*)'Value returned by swgetfill ',status
         write(1,*)'Value of fill ',rdfilval
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swdefboxreg
c
      write(1,27)
      write(*,*)'Testing swdefboxreg '
      write(*,*)'================='
      write(1,*)'Testing swdefboxreg '
      write(1,*)'================='

      regionid=swdefboxreg(swid, cornerlon, cornerlat,HDFE_ENDPOINT)
      if (regionid .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'regionid=swdefboxreg(swid, cornerlon, cornerlat, HDF       &
     1E_ENDPOINT)'
         write(*,*)'Value returned by swdefboxreg ',regionid
         write(1,*)'regionid=swdefboxreg(swid, cornerlon, cornerlat, HDF       &
     1E_ENDPOINT)'
         write(1,*)'Value returned by swdefboxreg ',regionid
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swidxinfo
c
      write(1,27)
      write(*,*)'Testing swidxinfo '
      write(*,*)'================='
      write(1,*)'Testing swidxinfo '
      write(1,*)'================='

      status4=swidxinfo(regionid, "Longitude", rank, dimlist, idx)

      if (status4 .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status4=swidxinfo(regionid, "Longitude", rank, dimli       &
     1st, idx)'
         write(1,*)'status4=swidxinfo(regionid, "Longitude", rank, dimli       &
     1st, idx)'
         write(*,*)'Value returned by swidxinfo ',status4
         write(1,*)'Value returned by swidxinfo ',status4
         write(*,*)'Value of dimlist is ',dimlist
         write(1,*)'Value of dimlist is ',dimlist
         do 555 i=1,4
           write(*,535)i,idx(i)
           write(1,535)i,idx(i)
  535      format (' Value of idx(',I2,') is ', I2)
  555 continue
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swdefboxreg
c
      cornerlon(1)=75.0
      cornerlon(2)=78.0
      cornerlat(1)=38.0
      cornerlat(2)=39.8

      write(1,27)
      write(*,*)'Testing swdefboxreg '
      write(*,*)'================='
      write(1,*)'Testing swdefboxreg '
      write(1,*)'================='

      regionid=swdefboxreg(swid, cornerlon, cornerlat,HDFE_ENDPOINT)
      if (regionid .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'regionid=swdefboxreg(swid, cornerlon, cornerlat, HDF       &
     1E_ENDPOINT)'
         write(*,*)'Value returned by swdefboxreg ',regionid
         write(1,*)'regionid=swdefboxreg(swid, cornerlon, cornerlat, HDF       &
     1E_ENDPOINT)'
         write(1,*)'Value returned by swdefboxreg ',regionid
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swdupreg
c
      write(1,27)
      write(*,*)'Testing swdupreg '
      write(*,*)'================='
      write(1,*)'Testing swdupreg '
      write(1,*)'================='

      regionid2=swdupreg(regionid)
      if (regionid2 .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Duplicate region id information '
         write(*,*)'Region ID returned by swdupreg ',regionid2
         write(1,*)'Duplicate region id information '
         write(1,*)'Region ID returned by swdupreg ',regionid2
         write(*,*)' '
         write(1,*)' '
      endif

c Test Case -- swreginfo
c
      write(1,27)
      write(*,*)'Testing swreginfo '
      write(*,*)'================='
      write(1,*)'Testing swreginfo '
      write(1,*)'================='
      status = swreginfo(swid, regionid, "Temperature", nt, rank, dims,        &
     1size)      
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status = swreginfo(swid, regionid, "Temperature", nt       &
     1, rank, dims, size)'
         write(*,*)'Value returned by swreginfo ',status
         write(*,*)'Number type of region ',nt,' Rank of region ',rank
         write(*,*)'Dimensions of region ',dims(1),' ',dims(2)
         write(*,*)'Value of size ',size
         write(1,*)'status = swreginfo(swid, regionid, "Temperature", nt       &
     1, rank, dims, size)'
         write(1,*)'Value returned by swreginfo ',status
         write(1,*)'Number type of region ',nt,' Rank of region ',rank
         write(1,*)'Value of size ',size
         write(1,*)'Dimensions of region ',dims(1),' ',dims(2)
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swextreg
c
      write(1,27)
      write(*,*)'Testing swextreg '
      write(*,*)'================='
      write(1,*)'Testing swextreg '
      write(1,*)'================='
      status = swextreg(swid, regionid, "Temperature", HDFE_INTERNAL,          &
     1tempbuf) 
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status = swextreg(swid, regionid, "Temperature", HDF       &
     1E_INTERNAL, tempbuf)'
         write(*,*)'Value returned by swextreg ', status
         write(1,*)'status = swextreg(swid, regionid, "Temperature", HDF       &
     1E_INTERNAL,tempbuf)'
         write(1,*)'Value returned by swextreg ', status
         do 210 index1=10,15
            write(*,*)'region value at position ',tempbuf(index1)
            write(1,*)'region value at position ',tempbuf(index1)
  210    continue
      endif

      write(*,*)' '
      write(1,*)' '

c Test Case -- swdeftmeper
c
      write(1,27)
      write(*,*)'Testing swdeftmeper '
      write(*,*)'================='
      write(1,*)'Testing swdeftmeper '
      write(1,*)'================='
      regionid=swdeftmeper(swid, starttime, endtime,HDFE_ENDPOINT)
      if (regionid .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'regionid=swdeftmeper(swid, starttime, endtime, HDFE        &
     1_ENDPOINT)'
         write(*,*)'Value returned by swdeftmeper ',regionid
         write(1,*)'regionid=swdeftmeper(swid, starttime, endtime, HDFE        &
     1_ENDPOINT)'
         write(1,*)'Value returned by swdeftmeper ',regionid
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swperinfo
c
      write(1,27)
      write(*,*)'Testing swperinfo '
      write(*,*)'================='
      write(1,*)'Testing swperinfo '
      write(1,*)'================='
      status = swperinfo(swid, regionid, "Temperature", nt, rank,              &
     1dims,size)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status = swperinfo(swid, regionid, "Temperature", nt       &
     1, rank, dims, size)'
         write(*,*)'Value returned by swperinfo ',status
         write(*,*)'Rank of field ',rank,' Number type of region ',nt
         write(*,*)'Dimensions of region ',dims(1),' ',dims(2)
         write(1,*)'status = swperinfo(swid, regionid, "Temperature", nt       &
     1, rank, dims, size)'
         write(1,*)'Value returned by swperinfo ',status
         write(1,*)'Rank of field ',rank,' Number type of region ',nt
         write(1,*)'Dimensions of region ',dims(1),' ',dims(2)
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swextper
c
      write(1,27)
      write(*,*)'Testing swextper '
      write(*,*)'================='
      write(1,*)'Testing swextper '
      write(1,*)'================='
      status=swextper(swid, regionid, "Temperature",HDFE_INTERNAL,             &
     1tempbuf)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swextper(swid, regionid, "Temperature", HDFE_       &
     1INTERNAL, tempbuf)'
         write(*,*)'Value returned by swextper swath ',status
         write(1,*)'status=swextper(swid, regionid, "Temperature", HDFE_       &
     1INTERNAL, tempbuf) '
         write(1,*)'Value returned by swextper swath ',status
         do 220 index1=10,15
            write(*,*)'region value at position ',tempbuf(index1)
            write(1,*)'region value at position ',tempbuf(index1)
  220    continue
      endif
      write(*,*)' '
      write(1,*)' '

c Test Case -- swupimap
c

      write(1,27)
      write(*,*)'Testing swupimap '
      write(*,*)'================='
      write(1,*)'Testing swupimap '
      write(1,*)'================='
      regionid=swdefboxreg(swid2, cornerlon, cornerlat,HDFE_ENDPOINT)
      idxsz=swupimap(swid2,regionid,idxmap,upidxmap,indicies)
      if (idxsz .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'Size of index array in region ',idxsz
         write(1,*)'Size of index array in region ',idxsz
         do 380 index1=1,idxsz
            write(*,*)' Value of index array ',upidxmap(index1)
            write(1,*)' Value of index array ',upidxmap(index1)
  380    continue
      endif



      status=swdetach(swid)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdetach(swid)'
         write(*,*)'Value returned by swdetach ',status
         write(1,*)'status=swdetach(swid)'
         write(1,*)'Value returned by swdetach ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swdetach(swid2)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swdetach(swid2)'
         write(*,*)'Value returned by swdetach ',status
         write(1,*)'status=swdetach(swid2)'
         write(1,*)'Value returned by swdetach ',status
      endif
      write(*,*)' '
      write(1,*)' '

      status=swclose(swfid)
      if (status .lt. zero) then
         write(*,*)'********Error unexpected**********'
         write(1,*)'********Error unexpected**********'
         call heprnt(0)
      else
         write(*,*)'  '
         write(*,*)'    ***********Passed Test*********'
         write(1,*)'  '
         write(1,*)'    ***********Passed Test*********'
         write(*,*)'status=swclose(swfid)'
         write(*,*)'Value returned by swclose ',status
         write(1,*)'status=swclose(swfid)'
         write(1,*)'Value returned by swclose ',status
      endif
      write(*,*)' '
      write(1,*)' '

      close(unit=1)
   27 format('')
      stop
      end

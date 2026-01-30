c23456789012345678901234567890123456789012345678901234567890123456789012
c testgrid.f
c In this program we create, define and write a simple grid hdfeos file
c using the grid interface
c

      program testgrid
      
      integer*4		index1
      integer*4		index2
      integer*4		dimsizes(2)
      integer*4		regionid, regionid2
      integer*4		tiledims(2), tilecords(2)
      integer*4		tileray(16,15)
      integer*4		tilebuffer(240)
      integer*4		tilecode, tilerank
      integer*4		itiledims(2)
      integer*4		tileinit
      real*4		ray3(250)
      real*4		utmray(60,80), georay(60,80)
      real*4		utmray1010(10,10)
      real*4		utmhght(80)
      real*4		hghtinit
      real*8		utmtmeray(4800)
      real*8		tmeinit
      real*4		utmcnt, geocnt
      real*4		fillvalue, ifillv
      real*4		raycnt, ray3cnt
      real*4		tempray(60,80)
      real*4		datbuf(4800)
      
      integer   	status, i, ii
      integer		compparm(5)
      integer           compparm2(5)
      integer*4		lstatus, n, one
      integer*4 	gdfid, gdfid2, gdid_utm, gdid2
      integer*4 	zonecode, compcode
      integer*4		attr(4), iattr(4)
      integer*4 	spherecode, xdim, ydim, zero
      integer*4		tmpvar1, nt, rk, size, tmpvar2
      integer*4 	start(2)
      integer*4 	stride(2)
      integer*4 	edge(2)
      integer*4 	start1d, stride1d, edge1d
      integer*4		periodid
      real*8		starttime, stoptime
      real*8		range(2)
      real*8		projparm(16), pparm(16)
      real*8		uplft(2), lowrgt(2)
      real*8		iuplft(2), ilrgt(2)
      real*8		interval(5,2)
      real*8		lonval(5), latval(5)
      integer*4		rowval(5), colval(5)
      real*4		fldval(5)

      integer*4		lat(40,50)
      integer*4		latcnt
      integer*4		lon(40,50)
      integer*4		loncnt

      integer   	gddefproj, gddefdim, gddeffld, gddetach 
      integer		gdclose, gdgetfill, gdreginfo
      integer   	gdwrfld, gdwrattr, gdsetfill, gddeforigin
      integer		gdgridinfo, gdprojinfo,gdfldinfo
      integer		gdrdfld, gddefpreg,gdrdattr, gdextreg
      integer		gdattrinfo, gdwrmeta, gddefcomp
      integer		gdcompinfo, gddeftle, gdrdtle
      integer		gdsettleche, gdtleinfo, gdwrtle
      integer		gddupreg, gdgetpix
      integer*4 	gdopen, gdcreate, gdattach, gdinqgrid
      integer*4		gdinqdims, gddiminfo, gdinqflds
      integer*4		gdnentries, gdinqattrs, gddefboxreg
      integer*4		gdorginfo, gdpreginfo
      integer*4		gdinterpolate, gddeftmeper
      integer*4		gddefvrtreg, gdgetpixval

      integer*4		strbufsize, pcode,nflds
      integer		zcode, scode
      character*80	grdnames, dimname, fldlist, attrlist
      integer*4		dims(8), rnk(8), numtype(8)
      real*8		upleftpt(2), lowrtpt(2),corlon(2),corlat(2)
      integer*4		xdimsize, ydimsize
      
      integer DFACC_CREATE
      parameter (DFACC_CREATE=4)
      integer DFACC_RDWR
      parameter (DFACC_RDWR=3)
      integer DFACC_READ
      parameter (DFACC_READ=1)      
      integer GCTP_UTM
      parameter (GCTP_UTM=1)

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
      
      integer HDFE_CORNER
      parameter (HDFE_CORNER=1)
      integer HDFE_GD_UL
      parameter (HDFE_GD_UL=0)
      integer HDFE_NENTDIM
      parameter(HDFE_NENTDIM=0)
      integer HDFE_NENTDFLD
      parameter (HDFE_NENTDFLD=4)

      integer HDFE_COMP_SKPHUFF
      parameter (HDFE_COMP_SKPHUFF=3)
      integer HDFE_COMP_NONE
      parameter (HDFE_COMP_NONE=0)

      integer HDFE_NOPREVSUB
      parameter (HDFE_NOPREVSUB=-1)
 
      integer HDFE_NOTILE
      parameter (HDFE_NOTILE=0)
      integer HDFE_TILE
      parameter (HDFE_TILE=1)

      index1 = 0
      index2 = 0
      dimsizes(1) = 40
      dimsizes(2) = 100
      compparm(1) = 0
      compparm(2) = 0
      compparm(3) = 0
      compparm(4) = 0
      compparm(5) = 0
      compparm2(1) = 2
      compparm2(2) = 32
      compparm2(3) = 0
      compparm2(4) = 0
      compparm2(5) = 0
      fillvalue = 1996.0
      raycnt = -799.0
      ray3cnt = -19.5
      attr(1) = 11
      attr(2) = 33
      attr(3) = 66
      attr(4) = 99
      utmcnt=-799.0
      geocnt=2001.0
      hghtinit = 323.0
      tmeinit = 35232487.2d0
      starttime = 35233000.8d0
      stoptime = 35435050.9d0
      range(1) = 352.8d0
      range(2) = 400.9d0
      lonval(1) = -122.0d0
      latval(1) = -68.0d0
      lonval(2) = -122.5d0
      latval(2) = -68.0d0
      lonval(3) = -123.0d0
      latval(3) = -68.0d0
      lonval(4) = -123.5d0
      latval(4) = -68.0d0
      lonval(5) = -124.0d0
      latval(5) = -68.0d0
      tileinit = -299.5
      tiledims(1) = 16
      tiledims(2) = 15
      tilecords(1) = 0
      tilecords(2) = 0

      latcnt = 38.0
      loncnt = 78.0
      zero = 0
      one = 1
      
c
c This section of the program just fills some arrays with data that we will
c use later in the program
c
      do 70 index1=1,80
         do 80 index2=1,60
            utmray(index2,index1) = utmcnt
            georay(index2,index1) = geocnt
            utmcnt = utmcnt + .4
            geocnt = geocnt + .2
   80   continue
   70 continue
        do 700 index1=1,10
         do 800 index2=1,10
            utmray1010(index2,index1) = utmcnt
            utmcnt = utmcnt + .4
 800     continue
 700  continue
  
      
      do 30 index1=1,250
            ray3(index1) = ray3cnt
            ray3cnt = ray3cnt + .1
   30 continue
      
      do 32 index1=1,80
            utmhght(index1) = hghtinit
            hghtinit = hghtinit + 2.75
   32 continue

      do 34 index1=1,4800
            utmtmeray(index1) = tmeinit
            tmeinit = tmeinit + 70.7
   34 continue

      do 50 index1=1,50
         do 60 index2=1,40      
            lat(index2,index1) = latcnt
            lon(index2,index1) = loncnt
            loncnt = loncnt - 0.1
   60    continue
         latcnt = latcnt + 0.1
         loncnt = 78.0
   50 continue

      do 51 index1=1,16
         do 52 index2=1,15
            tileray(index1,index2) = tileinit
            tileinit = tileinit + 0.5
   52    continue
   51 continue
      
  230 format('********Error unexpected**********')
  231 format('********Error Expected************')
  240 format('***********Passed Test*********')


      open(unit=10, file='testgrid_f.txtout', status = "NEW")

      write(*,*)'Testing Grid FORTRAN 77 interface '
      write(*,*)'=================================='
      write(10,*)'Testing Grid FORTRAN 77 interface '
      write(10,*)'=================================='
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdopen
c
      write(10,*)'Testing gdopen... '
      write(10,*)'=================='
      write(*,*)'Testing gdopen... '
      write(*,*)'=================='
      write(*,*)'Opening non-existing file Gridf_Test2.hdf for reading'
      write(10,*)'Opening non-existing file Gridf_Test2.hdf for reading'
      gdfid2 = gdopen("Gridf_Test2sz.hdf", DFACC_READ)
      if (gdfid2 .lt. zero) then
         write(*,240)
         write(10,240)
         write(*,231)
         write(10,231)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'gdfid2 = gdopen("Gridf_Test2sz.hdf", DFACC_READ)'
         write(10,*)'Value returned by gdopen ', gdfid2
         write(*,*)'gdfid2 = gdopen("Gridf_Test2sz.hdf", DFACC_READ)'
         write(*,*)'Value returned by gdopen ', gdfid2
      endif
      write(*,*)' '
      write(10,*)' '

      gdfid = gdopen('Gridf_Test_sz.hdf', DFACC_CREATE)
      if (gdfid .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'Opening file Gridf_Test_szip.hdf'
         write(10,*)'Opening file Gridf_Test_szip.hdf'
         write(10,*) 'gdfid = gdopen("Gridf_Test_sz.hdf", DFACC_CREATE)'
         write(10,*) 'File id returned from gdopen ', gdfid
         write(*,*) 'gdfid = gdopen("Gridf_Test_sz.hdf", DFACC_CREATE)'
         write(*,*) 'File id returned from gdopen ', gdfid
      endif
      write(10,*)' '
      write(*,*)' '


c Test Case -- gdcreate
c
      write(10,27)
      write(10,*)'Testing gdcreate... '
      write(10,*)'=================='
      write(*,*)'Testing gdcreate... '
      write(*,*)'=================='

      xdim = 60
      ydim = 80
      uplft(1) = 353299.39125d0
      uplft(2) = -7100284.64348d0
      lowrgt(1) = 603434.52148d0
      lowrgt(2) = -7991341.17870d0


      gdid2 = gdcreate(gdfid2, 'UTMGrid2', xdim, ydim, uplft, lowrgt)
      if (gdid2 .lt. zero) then
         write(*,231)
         write(10,231)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*) 'Create UTMGrid2'
         write(*,*)'gdid2 = gdcreate(gdfid2, "UTMGrid2", xdim, ydim, upl       &
     1ft, lowrgt)'
         write(10,*) 'Value returned by gdcreate ', gdid2
         write(*,*) 'Create UTMGrid2'
         write(10,*)'gdid2 = gdcreate(gdfid2, "UTMGrid2", xdim, ydim, up       &
     1lft, lowrgt)'
         write(*,*) 'Value returned by gdcreate ', gdid2
      endif
      
    
      gdid_utm = gdcreate(gdfid, 'UTMGrid', xdim, ydim, uplft, lowrgt)
      if (gdid_utm .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'Creating UTMGrid'
         write(*,*)'Creating UTMGrid'
         write(*,*)'gdid_utm=gdcreate(gdfid,"UTMGrid",xdim,ydim,uplft,lo       &
     1wrgt)'
         write(10,*)'gdid_utm=gdcreate(gdfid,"UTMGrid",xdim,ydim,uplft,l       &
     1owrgt)'
         write(10,*)'UTM grid id returned from gdcreate ', gdid_utm
         write(*,*)'UTM grid id returned from gdcreate ', gdid_utm
      endif 
      write(10,*)' '
      write(*,*)' '

c Test Case -- gddefproj
c
      write(10,27)
      write(10,*)'Testing gddefproj... '
      write(10,*)'=================='
      write(*,*)'Testing gddefproj... '
      write(*,*)'=================='

      zonecode = 10
      spherecode = 0

      do 120 index1=1,16
         projparm(index1)=0
 120  continue
  
      status = gddefproj(gdid_utm,GCTP_UTM,zonecode,spherecode,projparm)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'Defining UTM projection'
         write(*,*)'Defining UTM projection'
         write(*,*)'status=gddefproj(gdid_utm,GCTP_UTM,zonecode,sphereco       &
     1de, projparm)'
         write(10,*)'status=gddefproj(gdid_utm,GCTP_UTM,zonecode,spherec       &
     1ode, projparm)'
         write(10,*)'Returned value from gddefproj ', status
         write(*,*)'Returned value from gddefproj ', status
      endif 
      write(10,*)' '
      write(*,*)' '

      status = gddefproj(gdid2,GCTP_UTM,zonecode,spherecode,projparm)
      if (status .lt. zero) then
         write(*,231)
         write(10,231)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'Defining UTM'
         write(10,*)'status = gddefproj(gdid2,GCTP_UTM,zonecode,sphereco       &
     1de,projparm)'
         write(10,*)'Value returned by gddefproj ', status
         write(*,*)'Defining UTM'
         write(*,*)'status = gddefproj(gdid2,GCTP_UTM,zonecode,spherecod       &
     1e,projparm)'
         write(*,*)'Value returned by gddefproj ', status
      endif
      write(10,*)' '
      write(*,*)' '


c Test Case -- gddefpreg
c
      write(10,27)
      write(10,*)'Testing gddefpreg... '
      write(10,*)'=================='
      write(*,*)'Testing gddefpreg... '
      write(*,*)'=================='
      status = gddefpreg(gdid_utm, HDFE_CORNER)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'status = gddefpreg(gdid_utm, HDFE_CORNER)'
         write(10,*)'status = gddefpreg(gdid_utm, HDFE_CORNER)'
         write(10,*)'Returned from gddefpreg ', status
         write(*,*)'Returned from gddefpreg ', status
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gddeforigin
c
      write(10,27)
      write(10,*)'Testing gddeforigin... '
      write(10,*)'=================='
      write(*,*)'Testing gddeforigin... '
      write(*,*)'=================='
      status = gddeforigin(gdid_utm, HDFE_GD_UL)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'status = gddeforigin(gdid_utm, HDFE_GD_UL)'
         write(*,*)'Value of status from gddeforigin ',status
         write(10,*)'status = gddeforigin(gdid_utm, HDFE_GD_UL)'
         write(10,*)'Value of status from gddeforigin ',status
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gddefdim
c
      write(10,27)
      write(10,*)'Testing gddefdim... '
      write(10,*)'=================='
      write(*,*)'Testing gddefdim... '
      write(*,*)'=================='
      status = gddefdim(gdid2, 'TestDim1', 40)
      if (status .lt. zero) then
         write(*,231)
         write(10,231)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status = gddefdim(gdid2, "TestDim1", 40)'
         write(10,*)'Value returned by gddefdim ', status
         write(*,*)'status = gddefdim(gdid2, "TestDim1", 40)'
         write(*,*)'Value returned by gddefdim ', status
      endif
      write(10,*)' '
      write(*,*)' '

      status = gddefdim(gdid2, 'TestDim2', 25)
      if (status .lt. zero) then
         write(*,231)
         write(10,231)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status = gddefdim(gdid2, "TestDim2", 25)'
         write(10,*)'Value returned by gddefdim ', status
         write(*,*)'status = gddefdim(gdid2, "TestDim2", 25)'
         write(*,*)'Value returned by gddefdim ', status
      endif
      write(10,*)' '
      write(*,*)' '


      status = gddefdim(gdid_utm, 'Conduction', 250)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status = gddefdim(gdid_utm, "Conduction", 250)'
         write(10,*)'Returned value from gddefdim ', status
         write(*,*)'status = gddefdim(gdid_utm, "Conduction", 250)'
         write(*,*)'Returned value from gddefdim ', status
      endif
      write(10,*)' '
      write(*,*)' '

      status = gddefdim(gdid_utm,'Timedim',4800)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status = gddefdim(gdid_utm,"Timedim",4800)'
         write(10,*)'Status returned by call to gddefdim ',status
         write(*,*)'status = gddefdim(gdid_utm,"Timedim",4800)'
         write(*,*)'Status returned by call to gddefdim ',status
      endif
      write(10,*)' '
      write(*,*)' '

      status = gddefdim(gdid_utm,'Hghtdim',80)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'status = gddefdim(gdid_utm,"Hghtdim",80)'
        write(10,*)'Status returned by call to gddefdim ',status
        write(*,*)'status = gddefdim(gdid_utm,"Hghtdim",80)'
        write(*,*)'Status returned by call to gddefdim ',status
      endif
      write(10,*)' '
      write(*,*)' '

      status = gddefdim(gdid_utm,'Convection',60)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Define dimension Convection '
        write(10,*)'status = gddefdim(gdid_utm,"Convection",60)'
        write(10,*)'Status returned by call to gddefdim ',status
        write(*,*)'Define dimension Convection '
        write(*,*)'status = gddefdim(gdid_utm,"Convection",60)'
        write(*,*)'Status returned by call to gddefdim ',status
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gddetach
c
      write(10,27)
      write(10,*)'Testing gddetach... '
      write(10,*)'=================='
      write(*,*)'Testing gddetach... '
      write(*,*)'=================='
      status = gddetach(gdid2)
      if(status .lt. zero) then
         write(*,231)
         write(10,231)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status = gddetach(gdid2)'
         write(10,*)'Value returned by gddetach ', status
         write(*,*)'status = gddetach(gdid2)'
         write(*,*)'Value returned by gddetach ', status
      endif
      write(10,*)' '
      write(*,*)' '

      status = gddetach(gdid_utm)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status = gddetach(gdid_utm)'
         write(10,*)'Returned value from gddetach ', status
         write(*,*)'status = gddetach(gdid_utm)'
         write(*,*)'Returned value from gddetach ', status
      endif
      write(10,*)' '
      write(*,*)' '
 
c Test Case -- gdattach
c
      write(10,27)
      write(10,*)'Testing gdattach... '
      write(10,*)'=================='
      write(*,*)'Testing gdattach... '
      write(*,*)'=================='
      gdid_utm = gdattach(gdfid, 'UTMGrid')
      if(gdid_utm .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'gdid_utm = gdattach(gdfid, "UTMGrid")'
         write(10,*)'Handle returned from gdattach ', gdid_utm
         write(*,*)'gdid_utm = gdattach(gdfid, "UTMGrid")'
         write(*,*)'Handle returned from gdattach ', gdid_utm
      endif
      write(10,*)' '
      write(*,*)' '

      gdid2 = gdattach(gdfid2, 'UTMGrid2')
      if(gdid_utm .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'gdid2 = gdattach(gdfid2, "UTMGrid2")'
         write(10,*)'Value returned by gdattach ', status
         write(*,*)'gdid2 = gdattach(gdfid2, "UTMGrid2")'
         write(*,*)'Value returned by gdattach ', status
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gddeffld
c
      write(10,27)
      write(10,*)'Testing gddeffld... '
      write(10,*)'=================='
      write(*,*)'Testing gddeffld... '
      write(*,*)'=================='

      status=gddeffld(gdid2,'tempfield','TestDim2,TestDim1',DFNT_FLOAT32       &
     1,HDFE_NOMERGE)
      if(status .lt. zero) then
         write(*,231)
         write(10,231)
        call heprnt(0)
      else 
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Define: "tempfield"'
        write(10,*)'status=gddeffld(gdid2,"tempfield","TestDim2,TestDim1       &
     1",DFNT_FLOAT32,HDFE_NOMERGE)'
        write(10,*)'Value returned by gddeffld ', status
        write(*,*)'Define: "tempfield"'
        write(*,*)'status=gddeffld(gdid2,"tempfield","TestDim2,TestDim1"       &
     1",DFNT_FLOAT32,HDFE_NOMERGE)'
        write(*,*)'Value returned by gddeffld ', status
      endif
      write(10,*)' '
      write(*,*)' '

      status=gddeffld(gdid_utm,'Time','Timedim',DFNT_FLOAT64,HDFE_NOMERG       &
     1E)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)' Define field Time'
        write(10,*)'status=gddeffld(gdid_utm,"Time","Timedim",DFNT_FLOAT       &
     164,HDFE_NOMERGE)'
        write(10,*)'Status returned by call to gddeffld ',status
        write(*,*)' Define field Time'
        write(*,*)'status=gddeffld(gdid_utm,"Time","Timedim",DFNT_FLOAT6       &
     14,HDFE_NOMERGE)'
        write(*,*)'Status returned by call to gddeffld ',status
      endif
      write(10,*)' '
      write(*,*)' '

c23456789012345678901234567890123456789012345678901234567890123456789012
      status=gddeffld(gdid_utm,'Height','Hghtdim',DFNT_FLOAT32,HDFE_NOME       &
     1RGE)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)' Define field Height'
        write(10,*)'status=gddeffld(gdid_utm,"Height","Hghtdim",DFNT_FLO       &
     1AT32,HDFE_NOMERGE)'
        write(10,*)'Status returned by call to gddeffld ',status
        write(*,*)' Define field Height'
        write(*,*)'status=gddeffld(gdid_utm,"Height","Hghtdim",DFNT_FLOA       &
     1T32,HDFE_NOMERGE)'
        write(*,*)'Status returned by call to gddeffld ',status
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gddeftle
c
      write(10,27)
      write(10,*)'Testing gddeftle... '
      write(10,*)'=================='
      write(*,*)'Testing gddeftle... '
      write(*,*)'=================='

      status = gddeftle(gdid_utm,HDFE_TILE,2,tiledims)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Define tiling dimensions '
        write(10,*)'status = gddeftle(gdid_utm,HDFE_TILE,2,tiledims)'
        write(10,*)'Status returned by call to gddeftle ',status
        write(*,*)'Status returned by call to gddeftle ',status
        write(*,*)'status = gddeftle(gdid_utm,HDFE_TILE,2,tiledims)'
        write(*,*)'Define tiling dimensions '
      endif
      write(10,*)' '
      write(*,*)' '

      status=gddeffld(gdid_utm,'SideB','YDim,Convection',DFNT_INT32,HDFE       &
     1_NOMERGE)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Define field that will be tiled '
        write(10,*)'status=gddeffld(gdid_utm,"SideB","YDim,Convection",D       &
     1FNT_INT32,HDFE_NOMERGE)'
        write(10,*)'Status returned by call to gddeffld ',status
        write(*,*)'Define field that will be tiled '
        write(*,*)'status=gddeffld(gdid_utm,"SideB","YDim,Convection",DF       &
     1NT_INT32,HDFE_NOMERGE)'
        write(*,*)'Status returned by call to gddeffld ',status
      endif
      write(10,*)' '
      write(*,*)' '

      status = gddeftle(gdid_utm,HDFE_NOTILE,0,tiledims)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Turn off tiling '
        write(10,*)'status = gddeftle(gdid_utm,HDFE_NOTILE,0,tiledims)'
        write(10,*)'Status returned by call to gddeftle ',status
        write(*,*)'Turn off tiling '
        write(*,*)'status = gddeftle(gdid_utm,HDFE_NOTILE,0,tiledims)'
        write(*,*)'Status returned by call to gddeftle ',status
      endif
      write(10,*)' '
      write(*,*)' '

      status = gddetach(gdid_utm)
      if (status .lt. zero) then 
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status = gddetach(gdid_utm)'
         write(10,*)'Returned value from gddetach ', status
         write(*,*)'status = gddetach(gdid_utm)'
         write(*,*)'Returned value from gddetach ', status
      endif
      write(10,*)' '
      write(*,*)' '

      gdid_utm = gdattach(gdfid, 'UTMGrid')
      if (gdid_utm .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status = gdattach(gdfid,"UTMGrid")'
         write(10,*)'Returned value from gdattach ', status
         write(*,*)'status = gddetach(gdfid,"UTMGrid")'
         write(*,*)'Returned value from gdattach ', status
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gddefcomp
c
      write(10,27)
      write(10,*)'Testing gddefcomp... '
      write(10,*)'=================='
      write(*,*)'Testing gddefcomp... '
      write(*,*)'=================='

      status = gddefcomp(gdid_utm,HDFE_COMP_SKPHUFF, compparm)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Setup compression mode'
        write(10,*)'status = gddefcomp(gdid_utm,HDFE_COMP_SKPHUFF, compp       &
     1arm)'
        write(10,*)'Status returned by call to gddefcomp ',status
        write(*,*)'Setup compression mode'
        write(*,*)'status = gddefcomp(gdid_utm,HDFE_COMP_SKPHUFF, comppa       &
     1rm)'
        write(*,*)'Status returned by call to gddefcomp ',status
      endif
      write(10,*)' '
      write(*,*)' '

      status = gddeffld(gdid_utm,'Voltage','XDim,YDim',DFNT_FLOAT32,HDFE       &
     1_AUTOMERGE)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Define: "Voltage"'
        write(10,*)'status = gddeffld(gdid_utm,"Voltage","XDim,YDim",DFN       &
     1T_FLOAT32,HDFE_AUTOMERGE)'
        write(10,*)'Value returned from gddeffld ', status
        write(*,*)'Define: "Voltage"'
        write(*,*)'status = gddeffld(gdid_utm,"Voltage","XDim,YDim",DFNT       &
     1_FLOAT32,HDFE_AUTOMERGE)'
        write(*,*)'Value returned from gddeffld ', status
      endif
      write(10,*)' '
      write(*,*)' '

      status = gddefcomp(gdid_utm,HDFE_COMP_SZIP, compparm2)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Setup compression mode'
        write(10,*)'status = gddefcomp(gdid_utm,HDFE_COMP_SZIP, compp          &
     1arm2)'
        write(10,*)'Status returned by call to gddefcomp ',status
        write(*,*)'Setup compression mode'
        write(*,*)'status = gddefcomp(gdid_utm,HDFE_COMP_SZIP, comppa          &
     1rm2)'
        write(*,*)'Status returned by call to gddefcomp ',status
      endif
      write(10,*)' '
      write(*,*)' '

      status=gddeffld(gdid_utm,'Drift','XDim,YDim',DFNT_FLOAT32,HDFE_AUT       &
     1OMERGE)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Define: "Drift"'      
        write(10,*)'status=gddeffld(gdid_utm,"Drift","XDim,YDim",DFNT_FL       &
     1OAT32,HDFE_AUTOMERGE)'
        write(10,*)'Value returned from gddeffld ', status
        write(*,*)'Define: "Drift"'      
        write(*,*)'status=gddeffld(gdid_utm,"Drift","XDim,YDim",DFNT_FLO       &
     1OAT32,HDFE_AUTOMERGE)'
        write(*,*)'Value returned from gddeffld ', status
      endif
      write(10,*)' '
      write(*,*)' '

      status = gddefcomp(gdid_utm,HDFE_COMP_NONE, compparm)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Turn off compression'
        write(10,*)'status=gddefcomp(gdid_utm,HDFE_COMP_NONE,compparm)'
        write(10,*)'Status returned by call to gddefcomp ',status
        write(*,*)'Turn off compression'
        write(*,*)'status=gddefcomp(gdid_utm,HDFE_COMP_NONE,compparm)'
        write(*,*)'Status returned by call to gddefcomp ',status
      endif
      write(10,*)' '
      write(*,*)' '

      status=gddeffld(gdid_utm,'Impedance','XDim,YDim',DFNT_FLOAT32,HDF       &
     1E_AUTOMERGE)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'Define: "Impedance"'            
         write(10,*)'status=gddeffld(gdid_utm,"Impedance","XDim,YDim",DF       &
     1NT_FLOAT32,HDFE_AUTOMERGE)'
         write(10,*)'Value returned from gddeffld ', status
         write(*,*)'Define: "Impedance"'            
         write(*,*)'status=gddeffld(gdid_utm,"Impedance","XDim,YDim",DFN       &
     1T_FLOAT32,HDFE_AUTOMERGE)'
         write(*,*)'Value returned from gddeffld ', status
      endif
      write(10,*)' '
      write(*,*)' '

      status=gddeffld(gdid_utm,'Grounding','Conduction',DFNT_FLOAT32,HDF       &
     1_NOMERGE)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'Define: "Grounding"'                  
         write(10,*)'status=gddeffld(gdid_utm,"Grounding","Conduction",D       &
     1FNT_FLOAT32,HDF_NOMERGE)'
         write(10,*)'Value returned by gddeffld ', status
         write(*,*)'Define: "Grounding"'                  
         write(*,*)'status=gddeffld(gdid_utm,"Grounding","Conduction",DF       &
     1NT_FLOAT32,HDF_NOMERGE)'
         write(*,*)'Value returned by gddeffld ', status
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdwrmeta
c
      write(10,27)
      write(10,*)'Testing gdwrmeta... '
      write(10,*)'=================='
      write(*,*)'Testing gdwrmeta... '
      write(*,*)'=================='

      status = gdwrmeta(gdid_utm,'Extern','XDim,YDim',DFNT_FLOAT32)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'status = gdwrmeta(gdid_utm,"Extern","XDim,YDim",DFNT       &
     1_FLOAT32)'
         write(*,*)'Value returned by gdwrmeta ',status
         write(10,*)'status = gdwrmeta(gdid_utm,"Extern","XDim,YDim",DFN       &
     1T_FLOAT32)'
         write(10,*)'Value returned by gdwrmeta ',status
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdsetfill
c
      write(10,27)
      write(10,*)'Testing gdsetfill... '
      write(10,*)'=================='
      write(*,*)'Testing gdsetfill... '
      write(*,*)'=================='

      status = gdsetfill(gdid_utm, 'Drift', fillvalue)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'Testing gdsetfill'
         write(10,*)'status = gdsetfill(gdid_utm, "Drift", fillvalue)'
         write(10,*)'Returned from gdsetfill ', status
         write(*,*)'Testing gdsetfill'
         write(*,*)'status = gdsetfill(gdid_utm, "Drift", fillvalue)'
         write(*,*)'Returned from gdsetfill ', status
      endif
      write(10,*)' '
      write(*,*)' '

      status = gddetach(gdid_utm)
      if(status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status = gddetach(gdid_utm)'
         write(*,*)'status = gddetach(gdid_utm)'
         write(10,*)'Returned value from gddetach ', status
         write(*,*)'Returned value from gddetach ', status
      endif
      write(10,*)' '
      write(*,*)' '

      gdid_utm = gdattach(gdfid, 'UTMGrid')
      if(gdid_utm .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'gdid_utm = gdattach(gdfid, "UTMGrid")'
         write(10,*)'Handle returned from gdattach ', gdid_utm
         write(*,*)'gdid_utm = gdattach(gdfid, "UTMGrid")'
         write(*,*)'Handle returned from gdattach ', gdid_utm
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdwrfld
c
      write(10,27)
      write(10,*)'Testing gdwrfld... '
      write(10,*)'=================='
      write(*,*)'Testing gdwrfld... '
      write(*,*)'=================='

      start(1) = 0
      start(2) = 0
      stride(1) = 1
      stride(2) = 1
      edge(1) = 60
      edge(2) = 80
      
      status = gdwrfld(gdid_utm, 'Voltage', start, stride, edge, utmray)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Write to field Voltage '
        write(10,*)'status=gdwrfld(gdid_utm,"Voltage",start,stride,edge,       &
     1utmray)'
        write(10,*)'Status returned by gdwrfield ', status
        write(*,*)'Write to field Voltage '
        write(*,*)'status=gdwrfld(gdid_utm,"Voltage",start,stride,edge,u       &
     1tmray)'
        write(*,*)'Status returned by gdwrfield ', status
      endif
      write(10,*)' '
      write(*,*)' '


      start(1) = 10
      start(2) = 10
      edge(1) = 10
      edge(2) = 10
      status = gdwrfld(gdid_utm, 'Drift', start,stride,edge,utmray1010)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Write to field Drift '
        write(10,*)'status = gdwrfld(gdid_utm,"Drift",start,stride,edge,       &
     1utmray)'
        write(10,*)'Status returned from gdwrfld ', status
        write(*,*)'Write to field Drift '
        write(*,*)'status = gdwrfld(gdid_utm,"Drift",start,stride,edge,u       &
     1tmray)'
        write(*,*)'Status returned from gdwrfld ', status
      endif
      write(10,*)' '
      write(*,*)' '

      start(1) = 0
      start(2) = 0
      edge(1) = 60
      edge(2) = 80
      status = gdwrfld(gdid_utm, 'Impedance', start,stride,edge,utmray)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Write to field Impedance '
        write(10,*)'status=gdwrfld(gdid_utm,"Impedance",start,stride,edg       &
     1e,utmray)'
        write(10,*)'Returned from gdwrfld ', status
        write(*,*)'Write to field Impedance '
        write(*,*)'status=gdwrfld(gdid_utm,"Impedance",start,stride,edge       &
     1,utmray)'
        write(*,*)'Returned from gdwrfld ', status
      endif
      write(10,*)' '
      write(*,*)' '

      start1d=0
      stride1d=1
      edge1d=4800
      status=gdwrfld(gdid_utm,'Time',start1d,stride1d,edge1d,utmtmeray)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Write to field Time '
        write(10,*)'status=gdwrfld(gdid_utm,"Time",start1d,stride1d,edge       &
     11d,utmtmeray)'
        write(10,*)'Status returned by call to gdwrfld ',status
        write(*,*)'Write to field Time '
        write(*,*)'status=gdwrfld(gdid_utm,"Time",start1d,stride1d,edge1       &
     1d,utmtmeray)'
        write(*,*)'Status returned by call to gdwrfld ',status
      endif
      write(10,*)' '
      write(*,*)' '

      start1d=0
      stride1d=1
      edge1d=80
      status=gdwrfld(gdid_utm,'Height',start1d,stride1d,edge1d,utmhght)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Write to field Height '
        write(10,*)'status=gdwrfld(gdid_utm,"Height",start1d,stride1d,ed       &
     1ge1d,utmhght)'
        write(10,*)'Status returned by call to gdwrfld ',status
        write(*,*)'Write to field Height '
        write(*,*)'status=gdwrfld(gdid_utm,"Height",start1d,stride1d,edg       &
     1e1d,utmhght)'
        write(*,*)'Status returned by call to gdwrfld ',status
      endif
      write(10,*)' '
      write(*,*)' '

      start1d=0
      stride1d=1
      edge1d=250
      status=gdwrfld(gdid_utm,'Grounding',start1d,stride1d,edge1d,ray3)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Write to field Grounding '
        write(10,*)'status=gdwrfld(gdid_utm,"Grounding",start1d,stride1d       &
     1,edge1d,ray3)'
        write(10,*)'Value returned by gdwrfld ', status
        write(*,*)'Write to field Grounding '
        write(*,*)'status=gdwrfld(gdid_utm,"Grounding",start1d,stride1d,       &
     1edge1d,ray3)'
        write(*,*)'Value returned by gdwrfld ', status
      endif
        write(10,*)' '
        write(*,*)' '

c Test Case -- gdsettleche
c
      write(10,27)
      write(10,*)'Testing gdsettleche... '
      write(10,*)'=================='
      write(*,*)'Testing gdsettleche... '
      write(*,*)'=================='

      status = gdsettleche(gdid_utm,'SideB',5,0)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'Set tile cache parameters '
        write(10,*)'status = gdsettleche(gdid_utm,"SideB",5,0)'
        write(10,*)'Status returned by call to gdsettleche ',status
        write(*,*)'Set tile cache parameters '
        write(*,*)'status = gdsettleche(gdid_utm,"SideB",5,0)'
        write(*,*)'Status returned by call to gdsettleche ',status
      endif
        write(10,*)' '
        write(*,*)' '

c Test Case -- gdwrtle
c
      write(10,27)
      write(10,*)'Testing gdwrtle... '
      write(10,*)'=================='
      write(*,*)'Testing gdwrtle... '
      write(*,*)'=================='

      do 53 ii=1,5
         do 54 i=1,4
            status = gdwrtle(gdid_utm,'SideB',tilecords,tileray)
            if (status .lt. zero) then
               write(*,230)
               write(10,230)
               call heprnt(0)
            else
               write(*,*)' '
               write(*,240)
               write(10,*)' '
               write(10,240)
              write(10,*)'Writing tiled field '
              write(10,*)'Writing tile section ',tilecords(1),' ',tileco       &
     1rds(2)
              write(*,*)'Writing tiled field '
              write(*,*)'Status returned by gdwrtle ',status
              write(*,*)'Writing tile section ',tilecords(1),' ',tilecor       &
     1ds(2)
            endif
            tilecords(2) = tilecords(2) + 1
   54    continue
         tilecords(2) = 0
         tilecords(1) = tilecords(1) + 1
   53 continue

      status = gddetach(gdid_utm)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status = gddetach(gdid_utm)'
         write(10,*)'Value of status returned by gddetach ',status
         write(*,*)'status = gddetach(gdid_utm)'
         write(*,*)'Value of status returned by gddetach ',status
      endif
      write(10,*)' '
      write(*,*)' '

      gdid_utm = gdattach(gdfid, 'UTMGrid')
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'gdid_utm = gdattach(gdfid, "UTMGrid")'
         write(10,*)'Grid id returned by gdattach ',gdid_utm
         write(*,*)'gdid_utm = gdattach(gdfid, "UTMGrid")'
         write(*,*)'Grid id returned by gdattach ',gdid_utm
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdwrattr
c
      write(10,27)
      write(10,*)'Testing gdwrattr... '
      write(10,*)'=================='
      write(*,*)'Testing gdwrattr... '
      write(*,*)'=================='

      status = gdwrattr(gdid_utm, 'Resistance', DFNT_INT32, 4, attr)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status=gdwrattr(gdid_utm,"Resistance",DFNT_INT32,4,       &
     1attr)'
         write(10,*)'Returned from gdwrattr ', status
         write(*,*)'status=gdwrattr(gdid_utm,"Resistance",DFNT_INT32,4,a       &
     1ttr)'
         write(*,*)'Returned from gdwrattr ', status
      endif
      write(10,*)' '
      write(*,*)' '

      status = gddetach(gdid_utm)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status = gddetach(gdid_utm)'
         write(10,*)'Returned from gddetach ', status
         write(*,*)'status = gddetach(gdid_utm)'
         write(*,*)'Returned from gddetach ', status
      endif
      write(10,*)' '
      write(*,*)' '

      status = gddetach(gdid2)
      if (status .lt. zero) then
         write(*,231)
         write(10,231)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status = gddetach(gdid2)'
         write(10,*)'Value returned by gddetach ', status
         write(*,*)'status = gddetach(gdid2)'
         write(*,*)'Value returned by gddetach ', status
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdclose
c
      write(10,27)
      write(10,*)'Testing gdclose... '
      write(10,*)'=================='
      write(*,*)'Testing gdclose... '
      write(*,*)'=================='

      status = gdclose(gdfid2)
      if (status .lt. zero) then
         write(*,231)
         write(10,231)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status = gdclose(gdfid2)'
         write(10,*)'Value returned by gdclose ', status
         write(*,*)'status = gdclose(gdfid2)'
         write(*,*)'Value returned by gdclose ', status
      endif
      write(10,*)' '
      write(*,*)' '

      status = gdclose(gdfid)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'status = gdclose(gdfid)'
         write(10,*)'Returned from gdclose ', status
         write(*,*)'status = gdclose(gdfid)'
         write(*,*)'Returned from gdclose ', status
      endif
      write(10,*)' '
      write(*,*)' '

      
      gdfid = gdopen('Gridf_Test_sz.hdf', DFACC_RDWR)
      if (gdfid .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'gdfid = gdopen("Gridf_Test_sz.hdf", DFACC_RDWR)'
         write(10,*)'gdfid = gdopen("Gridf_Test_sz.hdf", DFACC_RDWR)'
         write(*,*)'Grid file id returned by gdopen ',gdfid
         write(10,*)'Grid file id returned by gdopen ',gdfid
      endif
      write(10,*)' '
      write(*,*)' '

      gdid_utm = gdattach(gdfid, 'UTMGrid')
      if (gdid_utm .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'gdid_utm = gdattach(gdfid, "UTMGrid")'
         write(10,*)'gdid_utm = gdattach(gdfid, "UTMGrid")'
         write(*,*)'Grid id returned by gdattach ',gdid_utm
         write(10,*)'Grid id returned by gdattach ',gdid_utm
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdinqgrid
c
      write(10,27)
      write(10,*)'Testing gdinqgrid... '
      write(10,*)'=================='
      write(*,*)'Testing gdinqgrid... '
      write(*,*)'=================='

      lstatus = gdinqgrid('Gridf_Test_sz.hdf',grdnames,strbufsize)
      if (lstatus .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'lstatus = gdinqgrid("Gridf_Test_sz.hdf",grdnames,str        &
     1rbufsize)'
         write(*,*)'Names of grids ',grdnames
         write(*,*)'Number of grids ',lstatus
         write(*,*)'Size of names of grids ',strbufsize
         write(10,*)'lstatus = gdinqgrid("Gridf_Test_sz.hdf",grdnames,str       &
     1rbufsize)'
         write(10,*)'Names of grids ',grdnames
         write(10,*)'Number of grids ',lstatus
         write(10,*)'Size of names of grids ',strbufsize
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdorginfo
c
      write(10,27)
      write(10,*)'Testing gdorginfo... '
      write(10,*)'=================='
      write(*,*)'Testing gdorginfo... '
      write(*,*)'=================='

      lstatus = gdorginfo(gdid_utm, tmpvar1)
      if (lstatus .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'lstatus = gdorginfo(gdid_utm, tmpvar1)'
         write(10,*)'lstatus = gdorginfo(gdid_utm, tmpvar1)'
         write(*,*)'Value returned by gdorginfo ',lstatus
         write(10,*)'Value returned by gdorginfo ',lstatus
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdpreginfo
c
      write(10,27)
      write(10,*)'Testing gdpreginfo... '
      write(10,*)'=================='
      write(*,*)'Testing gdpreginfo... '
      write(*,*)'=================='

      lstatus = gdpreginfo(gdid_utm, tmpvar1)
      if (lstatus .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'lstatus = gdpreginfo(gdid_utm, tmpvar1)'
         write(10,*)'lstatus = gdpreginfo(gdid_utm, tmpvar1)'
         write(*,*)'Value returned by gdpreginfo ',lstatus
         write(10,*)'Value returned by gdpreginfo ',lstatus
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdinqdims
c
      write(10,27)
      write(10,*)'Testing gdinqdims... '
      write(10,*)'=================='
      write(*,*)'Testing gdinqdims... '
      write(*,*)'=================='

      lstatus = gdinqdims(gdid_utm, dimname, dims)
      if (lstatus .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'lstatus = gdinqdims(gdid_utm, dimname, dims)'
         write(*,*)'Number of dimensions ',lstatus
         write(*,*)'Dimensions in grid UTM ',dimname
         write(*,*)'Size of dimensions '
         write(10,*)'lstatus = gdinqdims(gdid_utm, dimname, dims)'
         write(10,*)'Number of dimensions ',lstatus
         write(10,*)'Dimensions in grid UTM ',dimname
         write(10,*)'Size of dimensions '
         do 130 i=1,lstatus
            write(*,*)' ',dims(i)
            write(10,*)' ',dims(i)
 130     continue
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gddiminfo
c
      write(10,27)
      write(10,*)'Testing gddiminfo... '
      write(10,*)'=================='
      write(*,*)'Testing gddiminfo... '
      write(*,*)'=================='

      lstatus = gddiminfo(gdid_utm, 'Conduction')
      if (lstatus .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'lstatus = gddiminfo(gdid_utm, "Conduction")'
         write(*,*)'Size of dimension Conduction ',lstatus
         write(10,*)'lstatus = gddiminfo(gdid_utm, "Conduction")'
         write(10,*)'Size of dimension Conduction ',lstatus
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdgridinfo
c
      write(10,27)
      write(10,*)'Testing gdgridinfo... '
      write(10,*)'=================='
      write(*,*)'Testing gdgridinfo... '
      write(*,*)'=================='

      status=gdgridinfo(gdid_utm,xdimsize,ydimsize,upleftpt,lowrtpt)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'status=gdgridinfo(gdid_utm,xdimsize,ydimsize,upleftp       &
     1t,lowrtpt)'
         write(*,*)'Status returned by gdgridinfo ',status
         write(*,11)'X dim size ',xdimsize, ' Y dim size ',ydimsize
         write(*,12)'Upper left pt ',upleftpt(1),' ',upleftpt(2)
         write(*,12)'Lower right pt ',lowrtpt(1),' ',lowrtpt(2)
         write(10,*)'status=gdgridinfo(gdid_utm,xdimsize,ydimsize,upleft       &
     1pt,lowrtpt)'
         write(10,*)'Value returned by gdgridinfo ',status
         write(10,*)'X dim size ',xdimsize, ' Y dim size ',ydimsize
         write(10,*)'Upper left pt ',upleftpt(1),upleftpt(2)
         write(10,*)'Lower right pt ',lowrtpt(1),lowrtpt(2)
      endif
      write(10,*)' '
      write(*,*)' '
   11 format(a,i2,a,i2)
   12 format(a,f14.5,a,f14.5)

c Test Case -- gdprojinfo
c
      write(10,27)
      write(10,*)'Testing gdprojinfo... '
      write(10,*)'=================='
      write(*,*)'Testing gdprojinfo... '
      write(*,*)'=================='

      status = gdprojinfo(gdid_utm,pcode,zcode,scode,pparm)
      if (status .lt. zero) then
         write(*,230)
         write(10,230)
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'status = gdprojinfo(gdid_utm,pcode,zcode,scode,pparm       &
     1)'
         write(*,*)'Status returned by gdprojinfo ',status
         write(*,*)'Projection code ',pcode, ' Zone code ',zcode
         write(*,*)'Sphere code ',scode
         write(10,*)'status = gdprojinfo(gdid_utm,pcode,zcode,scode,ppar       &
     1m)'
         write(10,*)'Value returned by gdprojinfo ',status
         write(10,*)'Projection code ',pcode, ' Zone code ',zcode
         write(10,*)'Sphere code ',scode
         do 140 i=1,16
            write(*,55)' ',pparm(i)
            write(10,55)' ',pparm(i)
 140     continue
      endif
   55 format(a,f5.2)
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdcompinfo
c
      write(10,27)
      write(10,*)'Testing gdcompinfo... '
      write(10,*)'=================='
      write(*,*)'Testing gdcompinfo... '
      write(*,*)'=================='

      status = gdcompinfo(gdid_utm,'Voltage',compcode,compparm)
      if (status .lt. zero) then
         call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'status = gdcompinfo(gdid_utm,"Voltage",compcode,comp       &
     1parm)'
        write(10,*)'Compression info for field Voltage'
        write(10,*)'Comp code ',compcode
        write(10,*)'Compression parameters ',compparm
        write(*,*)'status = gdcompinfo(gdid_utm,"Voltage",compcode,compp       &
     1arm)'
        write(*,*)'Compression info for field Voltage'
        write(*,*)'Comp code ',compcode
        write(*,*)'Compression parameters ',compparm
      endif

c Test Case -- gdtleinfo
c
      write(10,27)
      write(10,*)'Testing gdtleinfo... '
      write(10,*)'=================='
      write(*,*)'Testing gdtleinfo... '
      write(*,*)'=================='

      status = gdtleinfo(gdid_utm,'SideB',tilecode,tilerank,itiledims)
      if (status .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'status = gdtleinfo(gdid_utm,"SideB",tilecode,tileran       &
     1k,itiledims)'
        write(10,*)'Retrieve tile information '
        write(10,*)'Tile info for field SideB '
        write(10,*)'Tile code ',tilecode,' rank ',tilerank,' dims ',itil       &
     1edims(1),' ',itiledims(2)
        write(*,*)'status = gdtleinfo(gdid_utm,"SideB",tilecode,tilerank       &
     1,itiledims)'
        write(*,*)'Retrieve tile information '
        write(*,*)'Tile info for field SideB '
        write(*,*)'Tile code ',tilecode, ' rank ',tilerank,' dims ',itil       &
     1edims(1),' ',itiledims(2)
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdrdtle
c
      write(10,27)
      write(10,*)'Testing gdrdtle... '
      write(10,*)'=================='
      write(*,*)'Testing gdrdtle... '
      write(*,*)'=================='

      tilecords(1) = 0
      tilecords(2) = 0
      status = gdrdtle(gdid_utm,'SideB',tilecords,tilebuffer)
      if (status .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(10,*)'Read a tile from field SideB'
         write(*,*)'Read a tile from field SideB'
         write(*,*)'status = gdrdtle(gdid_utm,"SideB",tilecords,tilebuff       &
     1er)'
         write(10,*)'status = gdrdtle(gdid_utm,"SideB",tilecords,tilebuf       &
     1fer)'
        do 62 ii=1,6
           do 63 i=1,5
              write(10,*)'SideB value at ',ii,' ',i,'  ',tilebuffer(ii+i       &
     1)
              write(*,2)'SideB value at ',ii,' ',i,'  ',tilebuffer(ii+i)       &
   63      continue
   62   continue
      endif
    2 format(a,i2,a,i2,a,i4)
      write(10,*)' '
      write(*,*)' '
        

c Test Case -- gdinqflds
c
      write(10,27)
      write(10,*)'Testing gdinqflds... '
      write(10,*)'=================='
      write(*,*)'Testing gdinqflds... '
      write(*,*)'=================='

      nflds = gdinqflds(gdid_utm,fldlist,rnk,numtype)
      if (nflds .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'nflds = gdinqflds(gdid_utm,fldlist,rnk,numtype)'
         write(*,*)'Number of fields ',nflds
         write(10,*)'nflds = gdinqflds(gdid_utm,fldlist,rnk,numtype)'
         write(10,*)'Number of fields ',nflds
         if (nflds .ne. 0) then
            write(*,*)'Fields ',fldlist
            write(10,*)'Fields ',fldlist
            do 150 i=1,nflds
               write(*,*)'Rank and type ',rnk(i), ' ', numtype(i)
               write(10,*)'Rank and type ',rnk(i), ' ', numtype(i)
  150       continue
         endif
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdfldinfo
c
      write(10,27)
      write(10,*)'Testing gdfldinfo... '
      write(10,*)'=================='
      write(*,*)'Testing gdfldinfo... '
      write(*,*)'=================='

      status = gdfldinfo(gdid_utm,'Drift',rnk,dims,numtype,dimname)
      if (status .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'status = gdfldinfo(gdid_utm,"Drift",rnk,dims,numtype       &
     1,dimname)'
         write(*,*)'Value returned by gdfldinfo for field Drift ',status
         write(*,*)'Drift rank ',rnk(1)
         write(*,*)'Dimensions  ',dims(1),' ',dims(2)
         write(*,*)'Number type of field ',numtype(1)
         write(*,*)'Dimension names ',dimname
         write(10,*)'status = gdfldinfo(gdid_utm,"Drift",rnk,dims,numtyp       &
     1e,dimname)'
         write(10,*)'Value returned by gdfldinfo for field Drift ',statu       &     1s
         write(10,*)'Drift rank ',rnk(1)
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdrdfld
c
      write(10,27)
      write(10,*)'Testing gdrdfld... '
      write(10,*)'=================='
      write(*,*)'Testing gdrdfld... '
      write(*,*)'=================='

      start(1) = 0
      start(2) = 0
      stride(1) = 1
      stride(2) = 1
      edge(1) = 60
      edge(2) = 80
      status = gdrdfld(gdid_utm,'Drift',start,stride,edge,tempray)
      if (status .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'status = gdrdfld(gdid_utm,"Drift",start,stride,edge,       &
     1tempray)'
         write(*,*)'Value returned by gdrdfld ',status
         write(10,*)'status = gdrdfld(gdid_utm,"Drift",start,stride,edge       &
     1,tempray)'
         write(10,*)'Value returned by gdrdfld ',status
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdnentries
c
      write(10,27)
      write(10,*)'Testing gdnentries... '
      write(10,*)'=================='
      write(*,*)'Testing gdnentries... '
      write(*,*)'=================='

      n = gdnentries(gdid_utm, HDFE_NENTDIM, strbufsize)
      if (n .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'n = gdnentries(gdid_utm, HDFE_NENTDIM, strbufsize)'
         write(*,*)'Number of dimensions ', n
         write(*,*)'Size of Dimension string ',strbufsize
         write(10,*)'n = gdnentries(gdid_utm, HDFE_NENTDIM, strbufsize)'
         write(10,*)'Number of dimensions ', n
         write(10,*)'Size of Dimension string ',strbufsize
      endif

      n = gdnentries(gdid_utm,HDFE_NENTDFLD,strbufsize)
      if (n .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'n = gdnentries(gdid_utm,HDFE_NENTDFLD,strbufsize)'
         write(*,*)'Number of data fields ',n
         write(10,*)'n = gdnentries(gdid_utm,HDFE_NENTDFLD,strbufsize)'
         write(10,*)'Number of data fields ',n
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdattrinfo
c
      write(10,27)
      write(10,*)'Testing gdattrinfo... '
      write(10,*)'=================='
      write(*,*)'Testing gdattrinfo... '
      write(*,*)'=================='

      status = gdattrinfo(gdid_utm,'Resistance',tmpvar1,tmpvar2)
      if (status .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'status = gdattrinfo(gdid_utm,"Resistance",tmpvar1,tm       &
     1pvar2)'
         write(*,*)'Value returned by gdattrinfo ',status
         write(*,*)'Number type of attribute ',tmpvar1
         write(*,*)'Number of total bytes in attribute ',tmpvar2
         write(10,*)'status = gdattrinfo(gdid_utm,"Resistance",tmpvar1,t       &
     1mpvar2)'
         write(10,*)'Value returned by gdattrinfo ',status
         write(10,*)'Number type of attribute ',tmpvar1
         write(10,*)'Number of total bytes in attribute ',tmpvar2
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdrdattr
c
      write(10,27)
      write(10,*)'Testing gdrdattr... '
      write(10,*)'=================='
      write(*,*)'Testing gdrdattr... '
      write(*,*)'=================='

      status = gdrdattr(gdid_utm,'Resistance',iattr)
      if (status .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(*,*)'status = gdrdattr(gdid_utm,"Resistance",iattr)'
        write(*,*)'Value returned by gdrdattr ',status
        write(10,*)'status = gdrdattr(gdid_utm,"Resistance",iattr)'
        write(10,*)'Value returned by gdrdattr ',status
      endif
      write(10,*)' '
      write(*,*)' '
  
c Test Case -- gdinqattrs
c
      write(10,27)
      write(10,*)'Testing gdinqattrs... '
      write(10,*)'=================='
      write(*,*)'Testing gdinqattrs... '
      write(*,*)'=================='

      lstatus = gdinqattrs(gdid_utm, attrlist,tmpvar1)
      if (lstatus .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(*,*)'lstatus = gdinqattrs(gdid_utm, attrlist,tmpvar1)'
        write(*,*)'Value returned by gdinqattrs ',lstatus
        write(*,*)'List of attributes ',attrlist
        write(10,*)'lstatus = gdinqattrs(gdid_utm, attrlist,tmpvar1)'
        write(10,*)'Value returned by gdinqattrs ',lstatus
        write(10,*)'List of attributes ',attrlist
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdgetfill
c
      write(10,27)
      write(10,*)'Testing gdgetfill... '
      write(10,*)'=================='
      write(*,*)'Testing gdgetfill... '
      write(*,*)'=================='

      status = gdgetfill(gdid_utm,'Drift',ifillv)
      if (status .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'status = gdgetfill(gdid_utm,"Drift",ifillv)'
         write(*,*)'Value returned by gdgetfill ',status
         write(*,*)'Fill value ',ifillv
         write(10,*)'status = gdgetfill(gdid_utm,"Drift",ifillv)'
         write(10,*)'Value returned by gdgetfill ',status
         write(10,*)'Fill value ',ifillv
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gddefboxreg
c
      write(10,27)
      write(10,*)'Testing gddefboxreg... '
      write(10,*)'=================='
      write(*,*)'Testing gddefboxreg... '
      write(*,*)'=================='

      corlon(1)=-126.0
      corlon(2)=-121.5
      corlat(1)=-70.0
      corlat(2)=-65.0

      regionid = gddefboxreg(gdid_utm,corlon,corlat)
      if (regionid .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'regionid = gddefboxreg(gdid_utm,corlon,corlat)'
         write(*,*)'Region id returned by gddefboxreg ',regionid
         write(10,*)'regionid = gddefboxreg(gdid_utm,corlon,corlat)'
         write(10,*)'Region id returned by gddefboxreg ',regionid
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdreginfo
c
      write(10,27)
      write(10,*)'Testing gdreginfo... '
      write(10,*)'=================='
      write(*,*)'Testing gdreginfo... '
      write(*,*)'=================='

      status = gdreginfo(gdid_utm,regionid,'Impedance',nt,rk,dims,size,i       &
     1uplft,ilrgt)
      if (status .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'status = gdreginfo(gdid_utm,regionid,"Impedance",nt,       &
     1rk,dims,size,iuplft,ilrgt)'
         write(*,*)'Value returned by gdreginfo ',status
         write(*,*)'Number type of region ',nt
         write(*,*)'Rank of region ',rk
         write(*,*)'Size of region ',size
         write(*,11)'Dimensions of region',dims(1),' ',dims(2)
         write(*,12)'Upper left point of region ',iuplft(1),' ',iuplft(2       &
     1)
         write(*,12)'Lower right point of region ',ilrgt(1),' ',ilrgt(2)
         write(10,*)'status = gdreginfo(gdid_utm,regionid,"Impedance",nt       &
     1,rk,dims,size,iuplft,ilrgt)'
         write(10,*)'Value returned by gdreginfo ',status
         write(10,*)'Number type of region ',nt
         write(10,*)'Rank of region ',rk
         write(10,*)'Size of region ',size
         write(10,11)'Dimensions of region',dims(1),' ',dims(2)
         write(10,12)'Upper left point of region ',iuplft(1),' ',iuplft(       &
     12)
         write(10,12)'Lower right point of region ',ilrgt(1),' ',ilrgt(2       &
     1)
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdextreg
c
      write(10,27)
      write(10,*)'Testing gdextreg... '
      write(10,*)'=================='
      write(*,*)'Testing gdextreg... '
      write(*,*)'=================='

      status = gdextreg(gdid_utm,regionid,'Impedance',datbuf)
      if (status .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'status = gdextreg(gdid_utm,regionid,"Impedance",datb       &
     1uf)'
         write(*,*)'Value returned by gdextreg ',status
         write(10,*)'status = gdextreg(gdid_utm,regionid,"Impedance",dat       &
     1buf)'
         write(10,*)'Value returned by gdextreg ',status
         do 175 i=100,150
            write(*,*)'Value of region ',datbuf(i)
            write(10,*)'Value of region ',datbuf(i)
  175    continue
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gddeftmeper
c
      write(10,27)
      write(10,*)'Testing gddeftmeper... '
      write(10,*)'=================='
      write(*,*)'Testing gddeftmeper... '
      write(*,*)'=================='

      periodid = gddeftmeper(gdid_utm,HDFE_NOPREVSUB,starttime,stoptime)
      if (periodid .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'periodid = gddeftmeper(gdid_utm,HDFE_NOPREVSUB,start       &
     1time,stoptime)'
        write(10,*)'Define a time period '
        write(10,*)'Period id returned by gddeftmeper ',periodid
        write(*,*)'periodid = gddeftmeper(gdid_utm,HDFE_NOPREVSUB,startt       &
     1ime,stoptime)'
        write(*,*)'Define a time period '
        write(*,*)'Period id returned by gddeftmeper ',periodid
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gddefvrtreg
c
      write(10,27)
      write(10,*)'Testing gddefvrtreg... '
      write(10,*)'=================='
      write(*,*)'Testing gddefvrtreg... '
      write(*,*)'=================='

      regionid = gddefvrtreg(gdid_utm,HDFE_NOPREVSUB,'Height',range)
      if (regionid .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'regionid = gddefvrtreg(gdid_utm,HDFE_NOPREVSUB,"Heig       &
     1ht",range)'
        write(10,*)'Define a vertical region '
        write(10,*)'Region id returned by gddefvrtreg ',regionid
        write(*,*)'regionid = gddefvrtreg(gdid_utm,HDFE_NOPREVSUB,"Heigh       &
     1t",range)'
        write(*,*)'Define a vertical region '
        write(*,*)'Region id returned by gddefvrtreg ',regionid
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gddupreg
c
      write(10,27)
      write(10,*)'Testing gddupreg... '
      write(10,*)'=================='
      write(*,*)'Testing gddupreg... '
      write(*,*)'=================='

      regionid2 = gddupreg(regionid)
      if (regionid2 .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'regionid2 = gddupreg(regionid)'
        write(10,*)'Generate a new region id '
        write(10,*)'New region id ',regionid2
        write(*,*)'regionid2 = gddupreg(regionid)'
        write(*,*)'Generate a new region id '
        write(*,*)'New region id ',regionid2
      endif
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdgetpix
c
      write(10,27)
      write(10,*)'Testing gdgetpix... '
      write(10,*)'=================='
      write(*,*)'Testing gdgetpix... '
      write(*,*)'=================='

      status = gdgetpix(gdid_utm,5,lonval,latval,rowval,colval)             
      if (status .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'status = gdgetpix(gdid_utm,5,lonval,latval,rowval,co       &
     1lval)'
        write(10,*)'Retrieve pixel row. column values '
        write(*,*)'status = gdgetpix(gdid_utm,5,lonval,latval,rowval,col       &
     1val)'
        write(*,*)'Retrieve pixel row. column values '
        do 37 i=1,5
           write(10,5)'Pixel position lon lat ',lonval(i),' ',                 &
     1latval(i),' ','Row Column ',rowval(i),' ',colval(i) 
           write(*,5)'Pixel position lon lat ',lonval(i),' ',                  &
     1latval(i),' ','Row Column ',rowval(i),' ',colval(i) 
   37   continue
      endif
    5 format(a,f6.1,a,f6.1,a,a,i2,a,i2)
      write(10,*)' '
      write(*,*)' '

c Test Case -- gdgetpixval
c
      write(10,27)
      write(10,*)'Testing gdgetpixval... '
      write(10,*)'=================='
      write(*,*)'Testing gdgetpixval... '
      write(*,*)'=================='

      lstatus = gdgetpixval(gdid_utm,5,rowval,colval,"Voltage",fldval)
      if (lstatus .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'lstatus = gdgetpixval(gdid_utm,5,rowval,colval,"Volt       &
     1age",fldval)'
        write(10,*)'Retrieve pixel values for specific locations '
        write(*,*)'lstatus = gdgetpixval(gdid_utm,5,rowval,colval,"Volta       &
     1ge",fldval)'
        write(*,*)'Retrieve pixel values for specific locations '
        do 42 i=1,5
           write(10,17)'Row Col ',rowval(i),' ',colval(i),' ','Pixel Val       &
     1ue ',fldval(i)
           write(*,17)'Row Col ',rowval(i),' ',colval(i),' ','Pixel Valu       &
     1e ',fldval(i)
   42   continue
      endif
   17 format(a8,i2,a1,i2,a1,a12,f9.3)
      write(10,*)' '
      write(*,*)' '


c Test Case -- gdinterpolate
c
      write(10,27)
      write(10,*)'Testing gdinterpolate... '
      write(10,*)'=================='
      write(*,*)'Testing gdinterpolate... '
      write(*,*)'=================='

      lstatus=gdinterpolate(gdid_utm,5,lonval,latval,'Voltage',interval)
      if (lstatus .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
        write(10,*)'lstatus=gdinterpolate(gdid_utm,5,lonval,latval,"Volt       &
     1age",interval)'
        write(10,*)'Interpolate 5 values for field Voltage '
        write(*,*)'lstatus=gdinterpolate(gdid_utm,5,lonval,latval,"Volta       &
     1ge",interval)'
        write(*,*)'Interpolate 5 values for field Voltage '
        write(*,*)'Status returned by call to gdinterpolate ',lstatus
        do 38 index1=1,5
           write(*,4)'Interpolated value ',interval(index1,1)
           write(10,4)'Interpolated value ',interval(index1,1)
   38   continue
      endif
    4 format(a,f9.3)
      write(10,*)' '
      write(*,*)' '


      status = gddetach(gdid_utm)
      if (status .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'status = gddetach(gdid_utm)'
         write(*,*)'Value returned by gddetach ',status
         write(10,*)'status = gddetach(gdid_utm)'
         write(10,*)'Value returned by gddetach ',status
      endif

      status = gdclose(gdfid)
      if (status .lt. zero) then
        write(10,*)'**********Error unexpected***********'
        write(*,*)'**********Error unexpected***********'
        call heprnt(0)
      else
         write(*,*)' '
         write(*,240)
         write(10,*)' '
         write(10,240)
         write(*,*)'status = gdclose(gdfid)'
         write(*,*)'Returned from gdclose ', status
         write(10,*)'status = gdclose(gdfid)'
         write(10,*)'Returned from gdclose ', status
      endif

      close(unit=10)
  27  format('')
      stop
      end

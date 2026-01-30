c
 
      program testpoint
 
      integer*4       ptfid, ptid1, ptid2, ptid3, ptdetach, ptclose
      integer*4       ptopen, ptcreate
      integer         status
      integer*4       ptid, fldsz, nlevels, nflds, fldlevels(5)
      integer*4	      npoint
      integer*4       fieldtype(8), fieldorder(8)
      character*72    fldlist, ptlist
      character*30    attrlist
 
      integer*4       ptattach, ptinqpoint
      integer         ptdeflev, ptdeflink, ptwrattr
      integer         ptrdattr, ptattrinfo
      integer         i, j, k, pntr, strbufsize
      integer*4	      strbufsize2
      integer*2       wgt
      integer*4       n, date, nt, sz, zero
      integer*4	      strbuf, nrec
      integer*4	      regrec
      integer*4	      regrecs(20)
 
      real*4          rain, temp, conc(4), f32, b32 
      real*8          lon, lat, time
      real*8          range(2)
 
      character       buffer*10000, id*2, desc*8, spc*4
      character       linkfield*8
      character       ctime*8, cconc*16, clon*8, clat*8
      character       cdate*4, crain*4, ctemp*4, cwgt*2
      equivalence     (time,ctime), (conc,cconc), (lon,clon)
      equivalence     (lat,clat), (rain,crain), (temp,ctemp)
      equivalence     (date,cdate), (wgt,cwgt)

      integer         ptwrlev, ptperrecs, ptregrecs

      integer*4       recs(32)
      integer*4       fldtype(32), fldorder(32)
 
      integer         ptrdlev
      integer         ptlevinfo, ptblinkinfo, ptflinkinfo
      integer	      ptgetlevname
      integer*4       ptnrecs, ptnlevs, ptsizeof, ptnflds
      integer*4	      ptlevidx, ptinqattrs

      integer         ptuplev, ptgetrecnums
      integer*4       inlevel, outlevel, levndx
      integer*4       outrecs(32), outnrec
      real*8          f64
 
      character       datbuf*256, c8*8
      character*(72)  levname
      equivalence     (f64,c8)

      integer         ptextreg, ptreginfo
      integer         ptextper, ptperinfo
 
      integer*4       size, ptdefboxreg, ptdeftmeper
      integer*4       ptdefvrtreg
      integer*4       regionid, periodid
 
      real*4          dtbuff32(25)
      real*8          cornerlon(2), cornerlat(2)
      real*8          dtbuf(128)
      real*8          starttime
      real*8          stoptime
 
 
      integer DFACC_CREATE
      parameter (DFACC_CREATE=4)
 
      integer  DFACC_RDWR
      parameter (DFACC_RDWR=3)

      integer  DFNT_CHAR8, DFNT_INT16, DFNT_INT32
      parameter (DFNT_CHAR8=4)
      parameter (DFNT_INT16=22)
      parameter (DFNT_INT32=24)
 
      integer  DFNT_FLOAT32, DFNT_FLOAT64
      parameter (DFNT_FLOAT32=5)
      parameter (DFNT_FLOAT64=6)

      integer DFACC_READ
      parameter (DFACC_READ=1)

      integer HDFE_NOPREVSUB
      parameter (HDFE_NOPREVSUB=-1)

      zero = 0

      open(unit=3, file='testpoint_f.txtout', status = 'NEW')
 
      write(*,*)'Testing Point FORTRAN 77 interface'
      write(*,*)'=================================='
      write(3,*)'Testing Point FORTRAN 77 interface'
      write(3,*)'=================================='
      write(*,*)' '
      write(3,*)' '
 
c Test Case -- ptopen
c
      write(*,*)'Testing ptopen '
      write(*,*)'================='
      write(3,*)'Testing ptopen '
      write(3,*)'================='

      ptfid = ptopen("Pointf_Test.hdf", DFACC_CREATE)
      if (ptfid .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       ptfid = ptopen("Pointf_Test.hdf", DFACC_CREAT       &
     1E)'
         write(*,*)'       File id  returned by ptopen ', ptfid
         write(3,*)'       ptfid = ptopen("Pointf_Test.hdf", DFACC_CREAT       &
     1E)'
         write(3,*)'       File id returned by ptopen ', ptfid
         write(*,*)' '
         write(3,*)' '
      endif


 
c Test Case -- ptcreate
c
      write(*,*)'Testing ptcreate '
      write(*,*)'================='
      write(3,*)'Testing ptcreate '
      write(3,*)'================='

      ptid1 = ptcreate(ptfid, "Simple Point")
      if (ptid1 .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      ptid1 = ptcreate(ptfid, "Simple Point")'
         write(*,*)'      Point id returned by ptcreate ',ptid1
         write(3,*)'      ptid1 = ptcreate(ptfid, "Simple Point")'
         write(3,*)'      Point id returned by ptcreate ',ptid1
      endif

      ptid2 = ptcreate(ptfid, "FixedBuoy Point")
      if (ptid2 .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      ptid2 = ptcreate(ptfid, "FixedBuoy Point")'
         write(*,*)'      Point id returned by ptcreate ',ptid2
         write(3,*)'      ptid2 = ptcreate(ptfid, "FixedBuoy Point")'
         write(3,*)'      Point id returned by ptcreate ',ptid2
      endif

      ptid3 = ptcreate(ptfid, "FloatBuoy Point")
      if (ptid3 .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      ptid3 = ptcreate(ptfid, "FloatBuoy Point")'
         write(*,*)'      Point id returned by ptcreate ',ptid3
         write(3,*)'      ptid3 = ptcreate(ptfid, "FloatBuoy Point")'
         write(3,*)'      Point id returned by ptcreate ',ptid3
      endif
 
 
      write(*,*)' '
      write(3,*)' '
c Test Case -- ptdetach
c  
      write(3,27)
      write(*,*)'Testing ptdetach '
      write(*,*)'================='
      write(3,*)'Testing ptdetach '
      write(3,*)'================='

      status = ptdetach(ptid1)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptdetach(ptid1)'
         write(*,*)'      Status returned by ptdetach ',status
         write(3,*)'      status = ptdetach(ptid1)'
         write(3,*)'      Status returned by ptdetach ',status
      endif

      status = ptdetach(ptid2)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptdetach(ptid2)'
         write(*,*)'      Status returned by ptdetach ',status
         write(3,*)'      status = ptdetach(ptid2)'
         write(3,*)'      Status returned by ptdetach ',status
      endif

      status = ptdetach(ptid3)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptdetach(ptid3)'
         write(*,*)'      Status returned by ptdetach ',status
         write(3,*)'      status = ptdetach(ptid3)'
         write(3,*)'      Status returned by ptdetach ',status
      endif
 
 
      write(*,*)' '
      write(3,*)' '
c Test Case -- ptclose
c  
      write(3,27)
      write(*,*)'Testing ptclose '
      write(*,*)'================='
      write(3,*)'Testing ptclose '
      write(3,*)'================='

      status = ptclose(ptfid)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptclose(ptfid)'
         write(*,*)'      Status returned by ptclose ',status
         write(3,*)'      status = ptclose(ptfid)'
         write(3,*)'      Status returned by ptclose ',status
      endif

      ptfid = ptopen("Pointf_Test.hdf", DFACC_RDWR)
      if (ptfid .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      ptfid = ptopen("Pointf_Test.hdf", DFACC_RDWR)'
         write(*,*)'      Point file id returned by ptopen ',ptfid
         write(3,*)'      ptfid = ptopen("Pointf_Test.hdf", DFACC_RDWR)'
         write(3,*)'      Point file id returned by ptopen ',ptfid
      endif

 
      write(*,*)' '
      write(3,*)' '
c Test Case -- ptattach
c  
      write(3,27)
      write(*,*)'Testing ptattach '
      write(*,*)'================='
      write(3,*)'Testing ptattach '
      write(3,*)'================='

      ptid = ptattach(ptfid, "Simple Point")
      if (ptid .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      ptid = ptattach(ptfid, "Simple Point")'
         write(*,*)'      Point id returned by ptattach ',ptid
         write(3,*)'      ptid = ptattach(ptfid, "Simple Point")'
         write(3,*)'      Point id returned by ptattach ',ptid
      endif

      fldlist = "Time,Concentration,Species"
 
 
      fieldtype(1) = DFNT_FLOAT64
      fieldtype(2) = DFNT_FLOAT32
      fieldtype(3) = DFNT_CHAR8
 
      fieldorder(1) = 1
      fieldorder(2) = 4
      fieldorder(3) = 4
 
      write(*,*)' '
      write(3,*)' '
c Test Case -- ptdeflev
c  
      write(3,27)
      write(*,*)'Testing ptdeflev '
      write(*,*)'================='
      write(3,*)'Testing ptdeflev '
      write(3,*)'================='

      status = ptdeflev(ptid, "Sensor", fldlist, fieldtype, fieldorder         &
     1)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptdeflev(ptid, "Sensor", fldlist, f         &
     1ieldtype,fieldorder)'
         write(*,*)'      Status returned by ptdeflev ',status
         write(3,*)'      status = ptdeflev(ptid, "Sensor", fldlist, f         &
     1ieldtype,fieldorder)'
         write(3,*)'      Status returned by ptdeflev ',status
      endif
 
      status = ptdetach(ptid)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptdetach(ptid)'
         write(*,*)'      Status returned by ptdetach ',status
         write(3,*)'      status = ptdetach(ptid)'
         write(3,*)'      Status returned by ptdetach ',status
      endif
 
 
      ptid = ptattach(ptfid, "FixedBuoy Point")
      if (ptid .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      ptid = ptattach(ptfid, "FixedBuoy Point")'
         write(*,*)'      Point id returned by ptattach ',ptid
         write(3,*)'      ptid = ptattach(ptfid, "FixedBuoy Point")'
         write(3,*)'      Point id returned by ptattach ',ptid
      endif
 
 
 
      fldlist = "Label,Longitude,Latitude,DeployDate,ID"
 
      fieldtype(1) = DFNT_CHAR8
      fieldtype(2) = DFNT_FLOAT64
      fieldtype(3) = DFNT_FLOAT64
      fieldtype(4) = DFNT_INT32
      fieldtype(5) = DFNT_CHAR8
 
 
      fieldorder(1) = 8
      fieldorder(2) = 0
      fieldorder(3) = 0
      fieldorder(4) = 0
      fieldorder(5) = 1

      status = ptdeflev(ptid, "Desc-Loc", fldlist, fieldtype, fieldorde        &
     1r)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptdeflev(ptid, "Desc-Loc", fldlist,         &
     1fieldtype,fieldorder)'
         write(*,*)'      Status returned by ptdeflev ',status
         write(3,*)'      status = ptdeflev(ptid, "Desc-Loc", fldlist,         &
     1fieldtype,fieldorder)'
         write(3,*)'      Status returned by ptdeflev ',status
      endif
 
 
 
      fldlist = "Time,Rainfall,Temperature,ID"
 
      fieldtype(1) = DFNT_FLOAT64
      fieldtype(2) = DFNT_FLOAT32
      fieldtype(3) = DFNT_FLOAT32
      fieldtype(4) = DFNT_CHAR8
 
      fieldorder(1) = 0
      fieldorder(2) = 0
      fieldorder(3) = 0
      fieldorder(4) = 1
 
      status = ptdeflev(ptid, "Observations", fldlist,
     1fieldtype, fieldorder)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptdeflev(ptid, "Observations",             &
     1fldlist,fieldtype, fieldorder)'
         write(*,*)'       Status returned by ptdeflev ',status
         write(3,*)'       status = ptdeflev(ptid, "Observations",             &
     1fldlist,fieldtype, fieldorder)'
         write(3,*)'       Status returned by ptdeflev ',status
      endif
 
      write(*,*)' '
      write(3,*)' '
c Test Case -- ptdeflink
c
      write(3,27)
      write(*,*)'Testing ptdeflink '
      write(*,*)'================='
      write(3,*)'Testing ptdeflink '
      write(3,*)'================='

      status = ptdeflink(ptid, "Desc-Loc", "Observations", "ID")
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptdeflink(ptid, "Desc-Loc",                &
     1"Observations", "ID")'
         write(*,*)'       Status returned by ptdeflink ',status
         write(3,*)'       status = ptdeflink(ptid, "Desc-Loc",                &
     1"Observations", "ID")'
         write(3,*)'       Status returned by ptdeflink ',status
      endif

 
      status = ptdetach(ptid)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptdetach(ptid)'
         write(*,*)'       Status returned by ptdetach ',status
         write(3,*)'       status = ptdetach(ptid)'
         write(3,*)'       Status returned by ptdetach ',status
      endif
 

      ptid = ptattach(ptfid, "FloatBuoy Point")
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       ptid = ptattach(ptfid, "FloatBuoy Point")'
         write(*,*)'       Point id returned by ptattach ',ptid
         write(3,*)'       ptid = ptattach(ptfid, "FloatBuoy Point")'
         write(3,*)'       Point id returned by ptattach ',ptid
      endif
 
 
c      Define Description Level */
 
      fldlist = "Label,DeployDate,Weight,ID"

      fieldtype(1) = DFNT_CHAR8
      fieldtype(2) = DFNT_INT32
      fieldtype(3) = DFNT_INT16
      fieldtype(4) = DFNT_CHAR8

      fieldorder(1) = 8
      fieldorder(2) = 0
      fieldorder(3) = 0
      fieldorder(4) = 1

 
      status = ptdeflev(ptid, "Description", fldlist,
     1fieldtype, fieldorder)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptdeflev(ptid, "Description",              &
     1fldlist,fieldtype, fieldorder)'
         write(*,*)'       Status returned by ptdeflev ',status
         write(3,*)'       status = ptdeflev(ptid, "Description",              &
     1fldlist,fieldtype, fieldorder)'
         write(3,*)'       Status returned by ptdeflev ',status
      endif
 
 
c       Define Data Level
 
      fldlist = "Time,Longitude,Latitude,Rainfall,Temperature,ID"
 
      fieldtype(1) = DFNT_FLOAT64
      fieldtype(2) = DFNT_FLOAT64
      fieldtype(3) = DFNT_FLOAT64
      fieldtype(4) = DFNT_FLOAT32
      fieldtype(5) = DFNT_FLOAT32
      fieldtype(6) = DFNT_CHAR8
 
      fieldorder(1) = 0
      fieldorder(2) = 0
      fieldorder(3) = 0
      fieldorder(4) = 0
      fieldorder(5) = 0
      fieldorder(6) = 1
 
      status = ptdeflev(ptid, "Measurements", fldlist,
     1fieldtype, fieldorder)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptdeflev(ptid, "Measurements",             &
     1fldlist,fieldtype, fieldorder)'
         write(*,*)'       Status returned by ptdeflev ',status
         write(3,*)'       status = ptdeflev(ptid, "Measurements",             &
     1fldlist,fieldtype, fieldorder)'
         write(3,*)'       Status returned by ptdeflev ',status
      endif
 

      status = ptdeflink(ptid, "Description", "Measurements", "ID")
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptdeflink(ptid, "Description",                &
     1"Measurements", "ID")'
         write(*,*)'       Status returned by ptdeflink ',status
         write(3,*)'       status = ptdeflink(ptid, "Description",                &
     1"Measurements", "ID")'
         write(3,*)'       Status returned by ptdeflink ',status
      endif
 
      status = ptdetach(ptid)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptdetach(ptid)'
         write(*,*)'       Status returned by ptdetach ',status
         write(3,*)'       status = ptdetach(ptid)'
         write(3,*)'       Status returned by ptdetach ',status
      endif
 
 
      write(*,*)' '
      status = ptclose(ptfid)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptclose(ptfid)'
         write(*,*)'       Status returned by ptclose ',status
         write(3,*)'       status = ptclose(ptfid)'
         write(3,*)'       Status returned by ptclose ',status
      endif

 

 
      write(*,*)' '
      ptfid = ptopen("Pointf_Test.hdf", DFACC_RDWR)
      if (ptfid .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       ptfid = ptopen("Pointf_Test.hdf", DFACC_RDWR        &
     1)'
         write(*,*)'       Point file id returned by ptopen ',ptfid
         write(3,*)'       ptfid = ptopen("Pointf_Test.hdf", DFACC_RDWR        &
     1)'
         write(3,*)'       Point file id returned by ptopen ',ptfid
      endif
 
      write(*,*)' '
      ptid = ptattach(ptfid, "Simple Point")
      if (ptfid .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       ptid = ptattach(ptfid, "Simple Point")'
         write(*,*)'       Point id returned by ptattach ',ptid
         write(3,*)'       ptid = ptattach(ptfid, "Simple Point")'
         write(3,*)'       Point id returned by ptattach ',ptid
      endif

      open(unit=1, file='simple.txt',STATUS='OLD')
      n = 0
      pntr = 1
      do 10 i=1,1000

           read(1,32,end=100)time,conc(1),conc(2),conc(3),conc(4),spc
           
           n = n + 1
           buffer(pntr:pntr+8) = ctime
           pntr = pntr + 8
           buffer(pntr:pntr+4*4) = cconc
           pntr = pntr + 4*4
           buffer(pntr:pntr+4) = spc
           pntr = pntr + 4
10      continue
 
100     close(unit=1)
   32  format(3x,f10.1,2x,f4.2,2x,f4.2,2x,f4.2,2x,f4.2,1x,a) 

      write(*,*)' '
      write(3,*)' '
c Test Case -- ptwrlev
c
      write(3,27)
      write(*,*)'Testing ptwrlev '
      write(*,*)'================='
      write(3,*)'Testing ptwrlev '
      write(3,*)'================='

      status = ptwrlev(ptid, 0, n, buffer)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'         status = ptwrlev(ptid, 0, n, buffer)'
         write(*,*)'         Status returned by ptwrlev ',status
         write(3,*)'         status = ptwrlev(ptid, 0, n, buffer)'
         write(3,*)'         Status returned by ptwrlev ',status
      endif

      status = ptdetach(ptid)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'         status = ptdetach(ptid)'
         write(*,*)'         Status returned by ptdetach ',status
         write(3,*)'         status = ptdetach(ptid)'
         write(3,*)'         Status returned by ptdetach ',status
      endif
   
 
      ptid = ptattach(ptfid, "FixedBuoy Point")
      if (ptid .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'        ptid = ptattach(ptfid, "FixedBuoy Point")'
         write(*,*)'        Point id returned by ptattach ',ptid
         write(3,*)'        ptid = ptattach(ptfid, "FixedBuoy Point")'
         write(3,*)'        Point id returned by ptattach ',ptid
      endif

      open(unit=1, file='fixedBuoy0.txt', STATUS='OLD')
 
      n = 0
      pntr = 1
      do 20 i=1,1000
 
           read(1, 34, end=200)desc,lon,lat,date,id
           
           n = n + 1
           buffer(pntr:pntr+8) = desc
           pntr = pntr + 8
           buffer(pntr:pntr+8) = clon
           pntr = pntr + 8
           buffer(pntr:pntr+8) = clat
           pntr = pntr + 8
           buffer(pntr:pntr+4) = cdate
           pntr = pntr + 4
           buffer(pntr:pntr+1) = id
           pntr = pntr + 1
 20   continue
 
 200  close(unit=1)
   34 format(a8,1x,f12.7,1x,f12.7,1x,i6,1x,a)

      status = ptwrlev(ptid, 0, n, buffer)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'        status = ptwrlev(ptid, 0, n, buffer)'
         write(*,*)'        Status returned by ptwrlev ',status
         write(3,*)'        status = ptwrlev(ptid, 0, n, buffer)'
         write(3,*)'        Status returned by ptwrlev ',status
      endif
 
 
      open(unit=1, file='fixedBuoy1.txt', STATUS='OLD')
 
      n = 0
      pntr = 1
      do 30 i=1,1000

           read(1, 35, end=300) time, rain, temp, id
           
           n = n + 1
 
           buffer(pntr:pntr+8) = ctime
           pntr = pntr + 8
           buffer(pntr:pntr+4) = crain
           pntr = pntr + 4
           buffer(pntr:pntr+4) = ctemp
           pntr = pntr + 4
           buffer(pntr:pntr+1) = id
           pntr = pntr + 1
 30   continue
 
 300  close(unit=1)
  35  format(3x,f10.1,5x,f3.1,3x,f5.2,3x,a)
      status = ptwrlev(ptid, 1, n, buffer)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'          status = ptwrlev(ptid, 1, n, buffer)'
         write(*,*)'          Status returned by ptwrlev ',status
         write(3,*)'          status = ptwrlev(ptid, 1, n, buffer)'
         write(3,*)'          Status returned by ptwrlev ',status
      endif

      write(*,*)' '
      write(3,*)' '
c Test Case -- ptwrattr
c
      write(3,27)
      write(*,*)'Testing ptwrattr '
      write(*,*)'================='
      write(3,*)'Testing ptwrattr '
      write(3,*)'================='

      f32 = -7.5
      status = ptwrattr(ptid, "float32", 5, 1, f32)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'         status = ptwrattr(ptid, "float32", 5, 1,          &
     1f32)'
         write(*,*)'         Status returned by ptwrattr ', status
         write(3,*)'         status = ptwrattr(ptid, "float32", 5, 1,          &
     1f32)'
         write(3,*)'         Status returned by ptwrattr ', status
      endif
 
      status = ptdetach(ptid)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptdetach(ptid)'
         write(*,*)'       Status returned by ptdetach ',status
         write(3,*)'       status = ptdetach(ptid)'
         write(3,*)'       Status returned by ptdetach ',status
      endif
 
 
      ptid = ptattach(ptfid, "FloatBuoy Point")
      if (ptid .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      ptid = ptattach(ptfid, "FloatBuoy Point")'
         write(*,*)'      Point id returned by ptattach ',ptid
         write(3,*)'      ptid = ptattach(ptfid, "FloatBuoy Point")'
         write(3,*)'      Point id returned by ptattach ',ptid
      endif
 
      open(unit=1, file='floatBuoy0.txt', STATUS='OLD')
 
      n = 0
      pntr = 1
      do 40 i=1,1000
 
           read(1, 36, end=400)  desc, date, wgt, id
           
           n = n + 1
 
           buffer(pntr:pntr+8) = desc
           pntr = pntr + 8
           buffer(pntr:pntr+4) = cdate
           pntr = pntr + 4
           buffer(pntr:pntr+2) = cwgt
           pntr = pntr + 2
           buffer(pntr:pntr+1) = id
           pntr = pntr + 1
 40   continue
 
 400  close(unit=1)
   36 format(a8,2x,i6,3x,i4,2x,a)
   
      status = ptwrlev(ptid, 0, n, buffer)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptwrlev(ptid, 0, n, buffer)'
         write(*,*)'      Status returned by ptwrlev ',status
         write(3,*)'      status = ptwrlev(ptid, 0, n, buffer)'
         write(3,*)'      Status returned by ptwrlev ',status
      endif
 
      open(unit=1, file='floatBuoy1.txt', STATUS='OLD')
 
      n = 0
      pntr = 1
      do 50 i=1,1000
 
           read(1, 37, end=500)time,lon,lat,rain,temp,id
           
           n = n + 1
 
           buffer(pntr:pntr+8) = ctime
           pntr = pntr + 8
           buffer(pntr:pntr+8) = clon
           pntr = pntr + 8
           buffer(pntr:pntr+8) = clat
           pntr = pntr + 8
           buffer(pntr:pntr+4) = crain
           pntr = pntr + 4
           buffer(pntr:pntr+4) = ctemp
           pntr = pntr + 4
           buffer(pntr:pntr+1) = id
           pntr = pntr + 1
 50   continue
 
 500  close(unit=1)
   37 format(3x,f10.1,2x,f11.6,2x,f11.6,5x,f3.1,3x,f5.2,3x,a)
 
      status = ptwrlev(ptid, 1, n, buffer)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'        status = ptwrlev(ptid, 1, n, buffer)'
         write(*,*)'        Status returned by ptwrlev ',status
         write(3,*)'        status = ptwrlev(ptid, 1, n, buffer)'
         write(3,*)'        Status returned by ptwrlev ',status
      endif

      status = ptdetach(ptid)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptdetach(ptid)'
         write(*,*)'      Status returned by ptdetach ',status
         write(3,*)'       status = ptdetach(ptid)'
         write(3,*)'      Status returned by ptdetach ',status
      endif
 
 
      status = ptclose(ptfid)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptclose(ptfid)'
         write(*,*)'      Status returned by ptclose ',status
         write(3,*)'      status = ptclose(ptfid)'
         write(3,*)'      Status returned by ptclose ',status
      endif

 
      ptfid = ptopen("Pointf_Test.hdf", DFACC_READ)
      if (ptfid .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'        ptfid = ptopen("Pointf_Test.hdf", DFACC_REA        &
     1D)'
         write(*,*)'        Point id returned by ptopen ',ptfid
         write(3,*)'        ptfid = ptopen("Pointf_Test.hdf", DFACC_REA        &
     1D)'
         write(3,*)'        Point id returned by ptopen ',ptfid
      endif

      ptid = ptattach(ptfid, "Simple Point")
      if (ptid .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       ptid = ptattach(ptfid, "Simple Point")'
         write(*,*)'       Point id returned by ptattach ',ptid
         write(3,*)'       ptid = ptattach(ptfid, "Simple Point")'
         write(3,*)'       Point id returned by ptattach ',ptid
      endif
 
      write(*,*)' '
      write(3,*)' '
c Test Case -- ptlevidx
c
      write(3,27)
      write(*,*)'Testing ptlevidx '
      write(*,*)'================='
      write(3,*)'Testing ptlevidx '
      write(3,*)'================='

      levndx = ptlevidx(ptid, "Sensor")
      if (levndx .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'     levndx = ptlevidx(ptid, "Sensor")'
         write(*,*)'     Level index of Sensor ',levndx
         write(3,*)'     levndx = ptlevidx(ptid, "Sensor")'
         write(3,*)'     Level index of Sensor ',levndx
      endif

      write(*,*)' '
      write(3,*)' '
c Test Case -- ptlevinfo
c
      write(3,27)
      write(*,*)'Testing ptlevinfo '
      write(*,*)'================='
      write(3,*)'Testing ptlevinfo '
      write(3,*)'================='

      nlevels = ptlevinfo(ptid, 0, fldlist, fldtype, fldorder)
      if (nlevels .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      nlevels = ptlevinfo(ptid, 0, fldlist,                &
     1   fldtype, fldorder)'
         write(*,*)'      Number of fields in level 0 ',status
         write(*,*)'      List of fields in level 0 ',fldlist
         write(3,*)'      Number of fields in level 0 ',status
         write(3,*)'      List of fields in level 0 ',fldlist
         do 7 i=1,nlevels
            write(*,*)' Number type of field ',fldtype(i)
            write(*,*)' Order of field ', fldorder(i)
            write(3,*)' Number type of field ',fldtype(i)
            write(3,*)' Order of field ', fldorder(i)
 7       continue
         write(3,*)'      status = ptlevinfo(ptid, 0, fldlist,                 &
     1   fldtype, fldorder)'
         write(3,*)'      Status returned by ptlevinfo ',status
      endif

      write(*,*)' '
      write(3,*)' '
c Test Case -- ptnrecs
c
      write(3,27)
      write(*,*)'Testing ptnrecs '
      write(*,*)'================='
      write(3,*)'Testing ptnrecs '
      write(3,*)'================='

      n = ptnrecs(ptid, 0)
      if (n .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'     n = ptnrecs(ptid, 0)'
         write(*,*)'     Number of records in level ',n
         write(3,*)'     n = ptnrecs(ptid, 0)'
         write(3,*)'     Number of records in level ',n
      endif
 
      do 5 i=1,n
         recs(i) = i - 1
 5    continue
 
      write(*,*)' '
      write(3,*)' '
c Test Case -- ptrdlev
c
      write(3,27)
      write(*,*)'Testing ptrdlev '
      write(*,*)'================='
      write(3,*)'Testing ptrdlev '
      write(3,*)'================='

      status = ptrdlev(ptid, 0, fldlist, n, recs, buffer)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptrdlev(ptid,0,fldlist,n,recs,buffer        &
     1)'
         write(*,*)'      Status returned by ptrdlev ',status
         write(3,*)'      status = ptrdlev(ptid,0,fldlist,n,recs,buffer        &
     1)'
         write(3,*)'      Status returned by ptrdlev ',status
      endif

      pntr = 1
      do 11 i=1,n
           ctime = buffer(pntr:pntr+8)
           pntr = pntr + 8
           cconc = buffer(pntr:pntr+4*4)
           pntr = pntr + 4*4
           spc = buffer(pntr:pntr+4)
           pntr = pntr + 4
           write(*,*)time,conc(1),conc(2),conc(3),conc(4),' ',spc
           write(3,*)time,conc(1),conc(2),conc(3),conc(4),' ',spc
11    continue
 
      status = ptdetach(ptid)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptdetach(ptid)'
         write(*,*)'       Status returned by ptdetach ',status
         write(3,*)'       status = ptdetach(ptid)'
         write(3,*)'       Status returned by ptdetach ',status
      endif
 
      ptid = ptattach(ptfid, "FixedBuoy Point")
      if (ptid .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       ptid = ptattach(ptfid, "FixedBuoy Point")'
         write(*,*)'       Point id returned by ptattach ',ptid
         write(3,*)'       ptid = ptattach(ptfid, "FixedBuoy Point")'
         write(3,*)'       Point id returned by ptattach ',ptid
      endif
 
      status = ptlevinfo(ptid, 0, fldlist, fldtype, fldorder)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'    status = ptlevinfo(ptid, 0, fldlist,                   &
     1fldtype, fldorder)'
         write(*,*)'    Status returned by ptlevinfo ',status
         write(3,*)'    status = ptlevinfo(ptid, 0, fldlist,                   &
     1fldtype, fldorder)'
         write(3,*)'    Status returned by ptlevinfo ',status
      endif

      write(*,*)' '
      write(3,*)' '
c Test Case -- ptsizeof
c
      write(3,27)
      write(*,*)'Testing ptsizeof '
      write(*,*)'================='
      write(3,*)'Testing ptsizeof '
      write(3,*)'================='

      fldsz = ptsizeof(ptid, fldlist, fldlevels)
      if (fldsz .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       fldsz = ptsizeof(ptid, fldlist, fldlevels)'
         write(*,*)'       fieldsize ', fldsz
         write(*,*)'Field list'
         write(*,*)'  ',fldlist
         write(*,*)'       Field levels ',fldlevels
         write(3,*)'       fldsz = ptsizeof(ptid, fldlist, fldlevels)'
         write(3,*)'       fieldsize ', fldsz
         write(3,*)'Field list'
         write(3,*)'  ',fldlist
         write(3,*)'       Field levels ',fldlevels
      endif

      write(*,*)' '
      write(3,*)' '
c Test Case -- ptflinkinfo
c
      write(3,27)
      write(*,*)'Testing ptflinkinfo '
      write(*,*)'================='
      write(3,*)'Testing ptflinkinfo '
      write(3,*)'================='

      status = ptflinkinfo(ptid, 0, linkfield)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptflinkinfo(ptid, 0, linkfield)'
         write(*,*)'       Status returned by ptflinkinfo ', status
         write(*,57) linkfield
         write(3,*)'       status = ptflinkinfo(ptid, 0, linkfield)'
         write(3,*)'       Status returned by ptflinkinfo ', status
         write(3,57) linkfield
      endif
  57  format('        The link field to the following level is ',a8)

      write(*,*)' '
      write(3,*)' '
c Test Case -- ptblinkinfo
c
      write(3,27)
      write(*,*)'Testing ptblinkinfo '
      write(*,*)'================='
      write(3,*)'Testing ptblinkinfo '
      write(3,*)'================='

      status = ptblinkinfo(ptid, 1, linkfield)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptblinkinfo(ptid, 1, linkfield)'
         write(*,*)'       Status returned by ptblinkinfo ', status
         write(*,58) linkfield
         write(3,*)'       status = ptblinkinfo(ptid, 1, linkfield)'
         write(3,*)'       Status returned by ptblinkinfo ', status
         write(3,58) linkfield
      endif
   58 format('        The link field to the previous level ',a8)

      write(*,*)' '
      write(3,*)' '
c Test Case -- ptnlevs
c
      write(3,27)
      write(*,*)'Testing ptnlevs '
      write(*,*)'================='
      write(3,*)'Testing ptnlevs '
      write(3,*)'================='

      nlevels = ptnlevs(ptid)
      if (nlevels .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       nlevels = ptnlevs(ptid)'
         write(*,*)'       Number of levels ',nlevels
         write(3,*)'       nlevels = ptnlevs(ptid)'
         write(3,*)'       Number of levels ',nlevels
      endif

      write(*,*)' '
      write(3,*)' '
c Test Case -- ptnflds
c
      write(3,27)
      write(*,*)'Testing ptnflds '
      write(*,*)'================='
      write(3,*)'Testing ptnflds '
      write(3,*)'================='

      nflds = ptnflds(ptid,1, strbufsize)
      if (nflds .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       nflds = ptnflds(ptid,1, strbufsize)'
         write(*,*)'       Number of fields ',nflds
         write(*,*)'       Size in bytes of field list ',strbufsize
         write(3,*)'       nflds = ptnflds(ptid,1, strbufsize)'
         write(3,*)'       Number of fields ',nflds
         write(3,*)'       Size in bytes of field list ',strbufsize
       endif
  
      n = 2
      recs(1) = 0
      recs(2) = 2
 
      write(*,*)' '
      write(3,*)' '
c Test Case -- ptrdlev
c
      write(3,27)
      write(*,*)'Testing ptrdlev '
      write(*,*)'================='
      write(3,*)'Testing ptrdlev '
      write(3,*)'================='

      pntr = 1
      status = ptrdlev(ptid, 0, fldlist, n, recs, buffer)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'     status = ptrdlev(ptid, 0, fldlist,                    &
     1n, recs, buffer)'
         write(*,*)'     Status returned by ptrdlev ',status
         write(3,*)'     status = ptrdlev(ptid, 0, fldlist,                    &
     1n, recs, buffer)'
         write(3,*)'     Status returned by ptrdlev ',status
      endif
 
      do 21 i=1,n
           desc = buffer(pntr:pntr+8)
           pntr = pntr + 8
           clon = buffer(pntr:pntr+8)
           pntr = pntr + 8
           clat = buffer(pntr:pntr+8)
           pntr = pntr + 8
           cdate = buffer(pntr:pntr+4)
           pntr = pntr + 4
           id = buffer(pntr:pntr+1)
           pntr = pntr + 1
           write(*,*) desc, lon, lat, date, id(1:1)
           write(3,*) desc, lon, lat, date, id(1:1)
 21   continue

      status = ptlevinfo(ptid, 1, fldlist, fldtype, fldorder)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptlevinfo(ptid, 1, fldlist,                 &
     1fldtype, fldorder)'
         write(*,*)'      Status returned by ptlevinfo ',status
         write(3,*)'      status = ptlevinfo(ptid, 1, fldlist,                 &
     1fldtype, fldorder)'
         write(3,*)'      Status returned by ptlevinfo ',status
      endif

      n = ptnrecs(ptid, 1)
      if (n .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      n = ptnrecs(ptid, 1)'
         write(*,*)'      Number of records ',n
         write(3,*)'      n = ptnrecs(ptid, 1)'
         write(3,*)'      Number of records ',n
      endif
 
 
      do 31 i=1,n
 
           recs(1) = i - 1
           status = ptrdlev(ptid, 1, fldlist, 1, recs, buffer)
           if (status .lt. zero) then
              write(*,*)'********** Error unexpected **********'
              write(3,*)'********** Error unexpected **********'
              call heprnt(0)
           else
           endif
 
           pntr = 1
 
           ctime = buffer(pntr:pntr+8)
           pntr = pntr + 8
           crain = buffer(pntr:pntr+4)
           pntr = pntr + 4
           ctemp = buffer(pntr:pntr+4)
           pntr = pntr + 4
           id = buffer(pntr:pntr+1)
           pntr = pntr + 1
           write(*,*) time, rain, temp, '  ', id(1:1)
           write(3,*) time, rain, temp, '  ', id(1:1)
 31   continue

      write(*,*)' '
      write(3,*)' '
c Test Case -- ptinqattrs
c
      write(3,27)
      write(*,*)'Testing ptinqattrs '
      write(*,*)'================='
      write(3,*)'Testing ptinqattrs '
      write(3,*)'================='

      nmattrs = ptinqattrs(ptid, attrlist,strbufsize)
      if (nmattrs .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'   nmattrs = ptinqattrs(ptid, attrlist,strbufsize)'
         write(*,*)'   Number of attributes ',nmattrs
         write(*,*)'   Attribute list ',attrlist
         write(3,*)'   nmattrs = ptinqattrs(ptid, attrlist,strbufsize)'
         write(3,*)'   Number of attributes ',nmattrs
         write(3,*)'   Attribute list ',attrlist
      endif

c Test Case -- ptrdattr
c
      write(3,27)
      write(*,*)'Testing ptrdattr '
      write(*,*)'================='
      write(3,*)'Testing ptrdattr '
      write(3,*)'================='

      status = ptrdattr(ptid, "float32", b32)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptrdattr(ptid, "float32", b32)'
         write(*,*)'      Status returned by ptrdattr ',status
         write(*,*) 'b32 = ', b32
         write(3,*)'      status = ptrdattr(ptid, "float32", b32)'
         write(3,*)'      Status returned by ptrdattr ',status
         write(3,*) 'b32 = ', b32
      endif

c Test Case -- ptattrinfo
c
      write(3,27)
      write(*,*)'Testing ptattrinfo '
      write(*,*)'================='
      write(3,*)'Testing ptattrinfo '
      write(3,*)'================='

      status = ptattrinfo(ptid, "float32", nt, sz)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptattrinfo(ptid, "float32", nt, sz)'
         write(*,*)'      Status returned by ptattrinfo ',status
         write(*,*) 'nt = ', nt
         write(*,*) 'sz = ', sz
         write(3,*)'      status = ptattrinfo(ptid, "float32", nt, sz)'
         write(3,*)'      Status returned by ptattrinfo ',status
         write(3,*) 'nt = ', nt
         write(3,*) 'sz = ', sz
      endif
 
      status = ptdetach(ptid)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptdetach(ptid)'
         write(*,*)'       Status returned by ptdetach ',status
         write(3,*)'       status = ptdetach(ptid)'
         write(3,*)'       Status returned by ptdetach ',status
      endif

      status = ptclose(ptfid)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptclose(ptfid)'
         write(*,*)'       Status returned by ptclose ',status
         write(3,*)'       status = ptclose(ptfid)'
         write(3,*)'       Status returned by ptclose ',status
      endif


      ptfid = ptopen("Pointf_Test.hdf", DFACC_RDWR)
      if (ptfid .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'     ptfid = ptopen("Pointf_Test.hdf", DFACC_RDWR)'
         write(*,*)'     Point id returned by ptopen ',ptfid
         write(3,*)'     ptfid = ptopen("Pointf_Test.hdf", DFACC_RDWR)'
         write(3,*)'     Point id returned by ptopen ',ptfid
      endif

      ptid1 = ptattach(ptfid, "Simple Point")
      if (ptid1 .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      ptid1 = ptattach(ptfid, "Simple Point")'
         write(*,*)'      Point id returned by ptattach ',ptid1
         write(3,*)'      ptid1 = ptattach(ptfid, "Simple Point")'
         write(3,*)'      Point id returned by ptattach ',ptid1
      endif

      ptid2 = ptattach(ptfid, "FixedBuoy Point")
      if (ptid2 .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      ptid2 = ptattach(ptfid, "FixedBuoy Point")'
         write(*,*)'      Point id returned by ptattach ',ptid2
         write(3,*)'      ptid2 = ptattach(ptfid, "FixedBuoy Point")'
         write(3,*)'      Point id returned by ptattach ',ptid2
      endif

      f64 = 43.2
      datbuf(1:8) = c8
      recs(1) = 1

c Test Case -- ptuplev
c
      write(3,27)
      write(*,*)'Testing ptuplev '
      write(*,*)'================='
      write(3,*)'Testing ptuplev '
      write(3,*)'================='

      status = ptuplev(ptid2, 0, "Longitude", 1, recs, datbuf)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptuplev(ptid2, 0, "Longitude",              &
     11, recs, datbuf)'
         write(*,*)'      Status returned by ptuplev ',status
         write(3,*)'      status = ptuplev(ptid2, 0, "Longitude",              &
     11, recs, datbuf)'
         write(3,*)'      Status returned by ptuplev ',status
      endif

      datbuf(1:1) = 'F'
      recs(1) = 0
      status = ptuplev(ptid2, 0, "ID", 1, recs, datbuf)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'     status = ptuplev(ptid2, 0, "ID", 1,                   &
     1recs, datbuf)'
         write(*,*)'     Status returned by ptuplev ',status
         write(3,*)'     status = ptuplev(ptid2, 0, "ID", 1,                   &
     1recs, datbuf)'
         write(3,*)'     Status returned by ptuplev ',status
      endif

c Test Case -- ptgetrecnums
c
      write(3,27)
      write(*,*)'Testing ptgetrecnums '
      write(*,*)'================='
      write(3,*)'Testing ptgetrecnums '
      write(3,*)'================='

      inlevel = 0
      outlevel = 1
      nrec = 1
      status = ptgetrecnums(ptid2, inlevel, outlevel, nrec, recs, 
     1outnrec, outrecs)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'      status = ptgetrecnums(ptid2, inlevel, outlevel       &
     1,nrec, recs,outnrec, outrecs)'
         write(*,*)'      Status returned by ptgetrecnums ',status
         write(*,59) outnrec
         write(3,*)'      status = ptgetrecnums(ptid2, inlevel, outlevel       &
     1,nrec, recs,outnrec, outrecs)'
         write(3,*)'      Status returned by ptgetrecnums ',status
         write(3,59) outnrec
   59 format('      Number of related records in next level ',I4)

         do 71 i=1,outnrec
            datbuf(i:i) = 'F'
 71      continue
      endif

      status = ptuplev(ptid2, outlevel, "ID", outnrec, outrecs, 
     1datbuf)
      if (status .lt. zero) then
         write(*,*)'********** Error unexpected **********'
         write(3,*)'********** Error unexpected **********'
         call heprnt(0)
      else
         write(*,*)'       status = ptuplev(ptid2, outlevel, "ID",             &
     1outnrec, outrecs,datbuf)'
         write(*,*)'       Status returned by ptuplev ',status
         write(3,*)'       status = ptuplev(ptid2, outlevel, "ID",             &
     1outnrec, outrecs,datbuf)'
         write(3,*)'       Status returned by ptuplev ',status
      endif

c Test Case -- ptgetlevname
c
      write(3,27)
      write(*,*)'Testing ptgetlevname '
      write(*,*)'================='
      write(3,*)'Testing ptgetlevname '
      write(3,*)'================='

      status=ptgetlevname(ptid2,0,levname,strbuf)
      if (status .lt. zero) then
        write(*,*)'**********Error unexpected******'
        write(3,*)'**********Error unexpected******'
        call heprnt(0)
      else
        write(*,*)'Get level name '
        write(*,*)'Level name ',levname
        write(*,*)'Size of level name ',strbuf
        write(3,*)'Get level name '
        write(3,*)'Level name ',levname
        write(3,*)'Size of level name ',strbuf
        write(*,*)' '
        write(3,*)' '
      endif

      status = ptdetach(ptid1)
      if (status .lt. zero) then
        write(*,*)'**********Error unexpected******'
        write(3,*)'**********Error unexpected******'
        call heprnt(0)
      else
         write(*,*)'      status = ptdetach(ptid1)'
         write(*,*)'      Status returned by ptdetach ',status
         write(3,*)'      status = ptdetach(ptid1)'
         write(3,*)'      Status returned by ptdetach ',status
      endif

      status = ptdetach(ptid2)
      if (status .lt. zero) then
        write(*,*)'**********Error unexpected******'
        write(3,*)'**********Error unexpected******'
        call heprnt(0)
      else
         write(*,*)'      status = ptdetach(ptid2)'
         write(*,*)'      Status returned by ptdetach ',status
         write(3,*)'      status = ptdetach(ptid2)'
         write(3,*)'      Status returned by ptdetach ',status
      endif


      status = ptclose(ptfid)
      if (status .lt. zero) then
        write(*,*)'**********Error unexpected******'
        write(3,*)'**********Error unexpected******'
        call heprnt(0)
      else
         write(*,*)'      status = ptclose(ptfid)'
         write(*,*)'      Status returned by ptclose ',status
         write(3,*)'      status = ptclose(ptfid)'
         write(3,*)'      Status returned by ptclose ',status
      endif


      ptfid = ptopen("Pointf_Test.hdf", DFACC_READ)
      if (ptfid .lt. zero) then
        write(*,*)'**********Error unexpected******'
        write(3,*)'**********Error unexpected******'
        call heprnt(0)
      else
         write(*,*)'    ptfid = ptopen("Pointf_Test.hdf", DFACC_READ)'
         write(*,*)'    Point id returned by ptopen ',ptfid
         write(3,*)'    ptfid = ptopen("Pointf_Test.hdf", DFACC_READ)'
         write(3,*)'    Point id returned by ptopen ',ptfid
      endif

c Test Case -- ptinqpoint
c
      write(3,27)
      write(*,*)'Testing ptinqpoint '
      write(*,*)'================='
      write(3,*)'Testing ptinqpoint '
      write(3,*)'================='

      npoint = ptinqpoint("Pointf_Test.hdf",ptlist,strbufsize2)
      if (npoint .lt. zero) then
        write(*,*)'**********Error unexpected******'
        write(3,*)'**********Error unexpected******'
        call heprnt(0)
      else
         write(*,*)'  Number of points in file ',npoint
         write(*,*)'  List of points in file ',ptlist
         write(3,*)'  Number of points in file ',npoint
         write(3,*)'  List of points in file ',ptlist
      endif

      ptid = ptattach(ptfid, "FloatBuoy Point")
      if (ptid .lt. zero) then
        write(*,*)'**********Error unexpected******'
        write(3,*)'**********Error unexpected******'
        call heprnt(0)
      else
         write(*,*)'     ptid = ptattach(ptfid, "FloatBuoy Point")'
         write(*,*)'     Point id returned by ptattach ',ptid
         write(3,*)'     ptid = ptattach(ptfid, "FloatBuoy Point")'
         write(3,*)'     Point id returned by ptattach ',ptid
      endif

c Test Case -- ptdefboxreg
c
      write(3,27)
      write(*,*)'Testing ptdefboxreg '
      write(*,*)'===================='
      write(3,*)'Testing ptdefboxreg '
      write(3,*)'===================='

      cornerlon(1) = -75.0d0
      cornerlat(1) = -25.0d0
      cornerlon(2) = 75.0d0
      cornerlat(2) = 25.0d0

      regionid = ptdefboxreg(ptid, cornerlon, cornerlat)
      if (regionid .lt. zero) then
        write(*,*)'**********Error unexpected******'
        write(3,*)'**********Error unexpected******'
        call heprnt(0)
      else
         write(*,*)'      regionid = ptdefboxreg(ptid,cornerlon, cornerlat     &
     1)'
         write(*,*)'      Region id returned by ptdefboxreg ',regionid
         write(3,*)'      regionid = ptdefboxreg(ptid,cornerlon, cornerlat     &
     1)'
         write(3,*)'      Region id returned by ptdefboxreg ',regionid
      endif

c Test Case -- ptregrecs
c
      write(3,27)
      write(*,*)'Testing ptregrecs '
      write(*,*)'================='
      write(3,*)'Testing ptregrecs '
      write(3,*)'================='

      status=ptregrecs(ptid,regionid,0,regrec,regrecs)
      if (status .lt. zero) then
         write(*,*)'*********Error unexpected********'
         write(3,*)'*********Error unexpected********'
         call heprnt(0)
      else
        write(*,*)'status=ptregrecs(ptid,regionid,0,regrec,regrecs)'
        write(*,*)'Status returned by call to ptregrecs ',status
        write(*,38) regrec
        write(3,*)'status=ptregrecs(ptid,regionid,0,regrec,regrecs)'
        write(3,*)'Status returned by call to ptregrecs ',status
        write(3,38) regrec
        do 26 i=1,regrec
           write(*,*)'Record number of subsetted records ',regrecs(i)
           write(3,*)'Record number of subsetted records ',regrecs(i)
   26   continue
      endif
        write(*,*)' '
        write(3,*)' '
   38 format('Number of records in region ',I4)

      status=ptregrecs(ptid,regionid,1,regrec,regrecs)
      if (status .lt. zero) then
         write(*,*)'*********Error unexpected********'
         write(3,*)'*********Error unexpected********'
         call heprnt(0)
      else
        write(*,*)'status=ptregrecs(ptid,regionid,1,regrec,regrecs)'
        write(*,*)'Status returned by call to ptregrecs ',status
        write(*,38) regrec
        write(3,*)'status=ptregrecs(ptid,regionid,1,regrec,regrecs)'
        write(3,*)'Status returned by call to ptregrecs ',status
        write(3,38) regrec
        do 28 i=1,regrec
           write(*,*)'Record number of subsetted records ',regrecs(i)
           write(3,*)'Record number of subsetted records ',regrecs(i)
   28   continue
      endif
        write(*,*)' '
        write(3,*)' '

c Test Case -- ptreginfo
c
      write(3,27)
      write(*,*)'Testing ptreginfo '
      write(*,*)'================='
      write(3,*)'Testing ptreginfo '
      write(3,*)'================='

      level = 1
      status = ptreginfo(ptid, regionid, level, "Longitude,Latitude",          &
     1size)
      if (status .lt. zero) then
         write(*,*)'*********Error unexpected********'
         write(3,*)'*********Error unexpected********'
         call heprnt(0)
      else
         write(*,*)'       status = ptreginfo(ptid, regionid, level,           &
     1"Longitude,Latitude", size)'
         write(*,*)'       Status returned by ptreginfo ',status
         write(3,*)'       status = ptreginfo(ptid, regionid, level,           &
     1"Longitude,Latitude", size)'
         write(3,*)'       Status returned by ptreginfo ',status
      endif

c Test Case -- ptextreg
c
      write(3,27)
      write(*,*)'Testing ptextreg '
      write(*,*)'================='
      write(3,*)'Testing ptextreg '
      write(3,*)'================='

      call heprnt(0)
      status = ptextreg(ptid, regionid, level, "Longitude,Latitude", d         &
     1tbuf)
      if (status .lt. zero) then
         write(*,*)'*********Error unexpected********'
         write(3,*)'*********Error unexpected********'
         call heprnt(0)
      else
         write(*,*)'    status = ptextreg(ptid, regionid, level,               &
     1"Longitude,Latitude", dtbuf)'
         write(*,*)'    Status returned by ptextreg ',status
         write(3,*)'    status = ptextreg(ptid, regionid, level,               &
     1"Longitude,Latitude", dtbuf)'
         write(3,*)'    Status returned by ptextreg ',status

         do 81 j = 1,size/16
            write(*,17) j, dtbuf(2*j-1),dtbuf(2*j)
            write(3,17) j, dtbuf(2*j-1),dtbuf(2*j)
 81      continue
   17    format(i2,3x,f14.5,3x,f14.5)
      endif
      

c Test Case -- ptdeftmeper
c
      write(3,27)
      write(*,*)'Testing ptdeftmeper '
      write(*,*)'================='
      write(3,*)'Testing ptdeftmeper '
      write(3,*)'================='

      starttime=35000000.0d0
      stoptime=36500000.0d0
      write(*,*)' Start time ',starttime,  '  Stop time ',stoptime
    
      periodid = ptdeftmeper(ptid, starttime, stoptime)
      write(*,*)' Start time ',starttime,  '  Stop time ',stoptime
      if (periodid .lt. zero) then
         write(*,*)'*********Error unexpected********'
         write(3,*)'*********Error unexpected********'
         call heprnt(0)
      else
         write(*,*)'    periodid = ptdeftmeper(ptid, starttime, stoptim        &
     1e)'
         write(*,*)'    Period id returned by ptdeftmeper ',periodid
         write(3,*)'    periodid = ptdeftmeper(ptid, starttime, stoptim        &
     1e)'
         write(3,*)'    Period id returned by ptdeftmeper ',periodid
      endif

c Test Case -- ptperrecs
c
      write(3,27)
      write(*,*)'Testing ptperrecs '
      write(*,*)'================='
      write(3,*)'Testing ptperrecs '
      write(3,*)'================='

      status=ptperrecs(ptid,periodid,0,regrec,regrecs)
      if (status .lt. zero) then
         write(*,*)'*********Error unexpected********'
         write(3,*)'*********Error unexpected********'
         call heprnt(0)
      else
        write(*,*)'status=ptperrecs(ptid,periodid,0,regrec,regrecs)'
        write(*,*)'Status returned by call to ptperrecs ',status
        write(*,*)'Number of records in period ',regrec
        write(3,*)'status=ptperrecs(ptid,periodid,0,regrec,regrecs)'
        write(3,*)'Status returned by call to ptperrecs ',status
        write(3,*)'Number of records in period ',regrec
        do 22 i=1,regrec
           write(*,*)'Record number of subsetted records ',regrecs(i)
           write(3,*)'Record number of subsetted records ',regrecs(i)
   22   continue
      endif

      status=ptperrecs(ptid,periodid,1,regrec,regrecs)
      if (status .lt. zero) then
         write(*,*)'*********Error unexpected********'
         write(3,*)'*********Error unexpected********'
         call heprnt(0)
      else
        write(*,*)'status=ptperrecs(ptid,periodid,1,regrec,regrecs)'
        write(*,*)'Status returned by call to ptperrecs ',status
        write(*,*)'Number of records in period ',regrec
        write(3,*)'status=ptperrecs(ptid,periodid,1,regrec,regrecs)'
        write(3,*)'Status returned by call to ptperrecs ',status
        write(3,*)'Number of records in period ',regrec
        do 23 i=1,regrec
           write(*,*)'Record number of subsetted records ',regrecs(i)
           write(3,*)'Record number of subsetted records ',regrecs(i)
   23   continue
      endif
        write(*,*)' '
        write(3,*)' '

c Test Case -- ptperinfo
c
      write(3,27)
      write(*,*)'Testing ptperinfo '
      write(*,*)'================='
      write(3,*)'Testing ptperinfo '
      write(3,*)'================='

      level = 1
      status = ptperinfo(ptid, periodid, level, "Time", size)
      if (status .lt. zero) then
         write(*,*)'*********Error unexpected********'
         write(3,*)'*********Error unexpected********'
         call heprnt(0)
      else
         write(*,*)'    status = ptperinfo(ptid, periodid, level,              &
     1"Time", size)'
         write(*,*)'    Status returned by ptperinfo ',status
         write(*,*)'    Size of region in bytes ',size
         write(3,*)'    status = ptperinfo(ptid, periodid, level,              &
     1"Time", size)'
         write(3,*)'    Status returned by ptperinfo ',status
         write(3,*)'    Size of region in bytes ',size
      endif

c Test Case -- ptextper
c
      write(3,27)
      write(*,*)'Testing ptextper '
      write(*,*)'================='
      write(3,*)'Testing ptextper '
      write(3,*)'================='

      status = ptextper(ptid, periodid, level, "Time", dtbuf)
      if (status .lt. zero) then
         write(*,*)'*********Error unexpected********'
         write(3,*)'*********Error unexpected********'
         call heprnt(0)
      else
         write(*,*)'    status = ptextper(ptid, periodid, level,               &
     1"Time", dtbuf)'
         write(*,*)'    Status returned by ptextper ',status
         write(3,*)'    status = ptextper(ptid, periodid, level,               &
     1"Time", dtbuf)'
         write(3,*)'    Status returned by ptextper ',status
     
         do 91 k=1,size/8
            write(*,42) k, dtbuf(k)
            write(3,42) k, dtbuf(k)
   91    continue
   42    format(i2,3x,f10.1)
      endif
     
c Test Case -- ptdefvrtreg
c
      write(3,27)
      write(*,*)'Testing ptdefvrtreg and NCRs 6598 & 8827'
      write(*,*)'========================================='
      write(3,*)'Testing ptdefvrtreg and NCRs 6598 & 8827'
      write(3,*)'========================================='

      range(1)=0.0d0
      range(2)=2.0d0
      regionid=ptdefvrtreg(ptid,HDFE_NOPREVSUB,"Rainfall",range)
      if (regionid .lt. zero) then
         write(*,*)'*********Error unexpected********'
         write(3,*)'*********Error unexpected********'
         call heprnt(0)
      else
         write(*,*)'      regionid=ptdefvrtreg(ptid,HDFE_NOPREVSUB,"Rai        &
     1nfall",range)'
         write(*,*)'      Region ID  returned by ptdefvrtreg ',regionid
         write(3,*)'      regionid=ptdefvrtreg(ptid,HDFE_NOPREVSUB,"Rai        &
     1nfall",range)'
         write(3,*)'      Region ID  returned by ptdefvrtreg ',regionid
      endif

      status=ptreginfo(ptid,regionid,1,"Rainfall",size)
      if (status .lt. zero) then
         write(*,*)'*********Error unexpected********'
         write(3,*)'*********Error unexpected********'
         call heprnt(0)
      else
         write(*,*)'      status=ptreginfo(ptid,regionid,1,"Rainfall",si       &
     1ze)'
         write(*,*)'      Status returned by ptreginfo ',status
         write(*,*)'    Size of region ',size
         write(3,*)'      status=ptreginfo(ptid,regionid,1,"Rainfall",si       &
     1ze)'
         write(3,*)'      Status returned by ptreginfo ',status
         write(3,*)'    Size of region ',size
      endif

      status=ptextreg(ptid,regionid,1,"Rainfall",dtbuff32)
      if (status .lt. zero) then
         write(*,*)'*********Error unexpected********'
         write(3,*)'*********Error unexpected********'
         call heprnt(0)
      else
         write(*,*)'      status=ptextreg(ptid,regionid,1,"Rainfall",dtb       &
     1uff32)'
         write(*,*)'      Status returned by ptreginfo ',status
         write(*,*)'      status=ptextreg(ptid,regionid,1,"Rainfall",dtb       &
     1uff32)'
         write(3,*)'      Status returned by ptreginfo ',status
         write(*,*)'  Data from region'
         write(3,*)'  Data from region'
         do 92 k=1,size/4
            write(*,43) k, dtbuff32(k)
            write(3,43) k, dtbuff32(k)
   92    continue
   43    format(i2,3x,f10.1)
      endif


      status = ptdetach(ptid)
      if (status .lt. zero) then
         write(*,*)'*********Error unexpected********'
         write(3,*)'*********Error unexpected********'
         call heprnt(0)
      else
         write(*,*)'      status = ptdetach(ptid)'
         write(*,*)'      Status returned by ptdetach ',status
         write(3,*)'      status = ptdetach(ptid)'
         write(3,*)'      Status returned by ptdetach ',status
      endif

      status = ptclose(ptfid)
      if (status .lt. zero) then
         write(*,*)'*********Error unexpected********'
         write(3,*)'*********Error unexpected********'
         call heprnt(0)
      else
         write(*,*)'      status = ptclose(ptfid)'
         write(*,*)'      Status returned by ptclose ',status
         write(3,*)'      status = ptclose(ptfid)'
         write(3,*)'      Status returned by ptclose ',status
      endif


      close(unit=3)
   27 format('')
      stop
      end

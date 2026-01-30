;======================================================================
; ESMF_regrid_17.ncl
;
; Concepts illustrated:
;   - Interpolating from one grid to another using ESMF_regrid
;   - Interpolating data from ERA5 to CAM-FV grid 
;======================================================================
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;
; This file still has to be loaded manually
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
    
;--define time var
    year="2017" ;getenv("year")
    mon="01"    ;getenv("mon")
    day="15"    ;getenv("day")

    tunits     = "days since "+year+"-"+mon+"-"+day+" 00:00:00" ; "seconds/hours/days since ...."
                                                 ; do NOT use "months since ...."

    time       = cd_inv_calendar(tointeger(year),tointeger(mon),tointeger(day),0,0,0,tunits, 0)
    time!0="time"
    time&time=time
    time@calendar="gregorian"

    print(time)
    printVarSummary(time)

; now do vertical interpolation to 70lev of CAM keeping ERA5 horizontal grid

;destination grid TEMPLATE DESTINATION GRID
    filC ="/work/cmcc/gc02720/ic/template_H0.9_1.25_L70.nc"   ; getenv("templateL")    ; CAM
    fC=addfile(filC,"r")
    hyao=fC->hyam
    hybo=fC->hybm
    ps=101300
    plevs_cam=(hyao+hybo)*ps
    plevs_cam=(plevs_cam/100)

    print(plevs_cam)

;---Data file containing source grid
;    ERA5_file130  = "/work/cmcc/gc02720/ERA5/NETCDF/temp_jan2017_0000Z.nc" ;getenv("fvar130")
;    sfile130      = addfile(ERA5_file130,"r")
;    ERA5_file131  = "/work/cmcc/gc02720/ERA5/NETCDF/u_jan2017_0000Z.nc" ;getenv("fvar131")
;    sfile131      = addfile(ERA5_file131,"r")
;    ERA5_file132  = "/work/cmcc/gc02720/ERA5/NETCDF/v_jan2017_0000Z.nc" ;getenv("fvar132")
;    sfile132      = addfile(ERA5_file132,"r")
;    ERA5_file133  = "/work/cmcc/gc02720/ERA5/NETCDF/q_jan2017_0000Z.nc" ;getenv("fvar133")
;    sfile133      = addfile(ERA5_file133,"r")
;    ERA5_file134  = "/work/cmcc/gc02720/ERA5/NETCDF/ps_jan2017_0000Z.nc" ;getenv("fvar134")
;    sfile134      = addfile(ERA5_file134,"r")

;---CHANGE THE FILE NAME THAT MUST BE CONVERTED HERE
    ERAan  = "/work/cmcc/gc02720/ic/EDA/ECEDA3_20170115_00.nc"
    sfilean      = addfile(ERAan,"r")

;---Get coordinates of source grid
    src_lat  = sfilean->lat
    src_lon  = sfilean->lon
    src_lev  = sfilean->lev 
    hyaiE=sfilean->hyam
    hybiE=sfilean->hybm

    plevE=hyaiE+hybiE*ps
    print(plevE/100)
        
    var_name = "lnsp"    
    press   = sfilean->$var_name$(0,0,:,:)              ; (time,lev,lat,lon)
    press   = exp(press)
    ;print(press)
    ;printVarSummary(press)
    p0=100000
    var_name = "t"    
    T137   = sfilean->$var_name$(0,:,:,:)              ; (time,lev,lat,lon)
    T70=hyi2hyo(p0,hyaiE/100000,hybiE,press,T137,hyao,hybo,1)
    ;T70=pres2hybrid(src_lev,press,p0,T137,hyao,hybo,1)
    var_name = "q"    
    Q137   = sfilean->$var_name$(0,:,:,:)              ; (time,lev,lat,lon)
    ;Q70=pres2hybrid(src_lev,press,p0,Q137,hyao,hybo,1)
    Q70=hyi2hyo(p0,hyaiE/100000,hybiE,press,Q137,hyao,hybo,1)
    var_name = "u"    
    U137   = sfilean->$var_name$(0,:,:,:)              ; (time,lev,lat,lon)
    ;U70=pres2hybrid(src_lev,press,p0,U137,hyao,hybo,1)
    U70=hyi2hyo(p0,hyaiE/100000,hybiE,press,U137,hyao,hybo,1)
    var_name = "v"    
    V137   = sfilean->$var_name$(0,:,:,:)              ; (time,lev,lat,lon)
    ;V70=pres2hybrid(src_lev,press,p0,V137,hyao,hybo,1)
    V70=hyi2hyo(p0,hyaiE/100000,hybiE,press,U137,hyao,hybo,1)


;---Save intermediate fields with ERA5 lat-lon horizontal grid and
;    CAM 70 final vertical levels
;---open output file
    output="output_check.nc"  ;getenv("output_check")
    system("/bin/rm -f "+output)
    ncdf=addfile(output,"c")
    tmplev=fC->lev
    ncdf->lev=tmplev
    ncdf->lat=src_lat
    ncdf->lon=src_lon
    vaout=U70
    printVarSummary(U70)
    vaout!0="lev"    
    vaout!1="lat"
    vaout!2="lon"
    ncdf->U32=vaout
;    varin=U137
;    varin!0="src_lev"
;    ncdf->U137=varin
;    vaout=V32
;    vaout!0="lev"
;    vaout!1="lat"
;    vaout!2="lon"
;    ncdf->V32=vaout
;    varin=V137
;    varin!0="src_lev"
;    ncdf->V137=varin
;    vaout=T32
;    vaout!0="lev"
;    vaout!1="lat"
;    vaout!2="lon"
;    ncdf->T32=vaout
;    varin=T137
;    varin!0="src_lev"
;    ncdf->T137=varin
;    vaout=Q32
;    vaout!0="lev"
;    vaout!1="lat"
;    vaout!2="lon"
;    ncdf->Q32=vaout
;    varin=Q137
;    varin!0="src_lev"
;    ncdf->Q137=varin

print("PIPPOPAPPO")
    wgt_file ="w_0.9_1.25_L70.nc" ; getenv("wgt_file") ;"$DIR_STA/files4SPS3.5_SE/ERA5_to_CAMSE05.nc"
    wgt_file_slat="w_0.9_1.25_L70_stagLat.nc"
    wgt_file_slon="w_0.9_1.25_L70_stagLon.nc"

    print("------------------------------------------------------------")
    print("Will be regridding to the SE ne60np4 grid")
    print("------------------------------------------------------------")

;---Data file containing destination grid
    dst_lat = fC->lat
    dst_lon = fC->lon

    dst_slat= fC->slat
    dst_slon= fC->slon

;---Set up regridding options
    Opt                = True

    Opt@InterpMethod  = "bilinear"   ; "patch", "conserve"

    Opt@WgtFileName  = wgt_file

    Opt@SrcGridLat     = src_lat
    Opt@SrcGridLon     = src_lon
    Opt@SrcRegional    = False

    Opt@ForceOverwrite = True
    Opt@Debug          = True
    Opt@PrintTimings   = True

    OptUS=Opt
    OptVS=Opt

    Opt@DstGridLat = dst_lat
    Opt@DstGridLon = dst_lon
;    Opt@DstGridType ="unstructured"

    OptUS@DstGridLat = dst_slat
    OptUS@DstGridLon = dst_lon
    OptUS@WgtFileName  = wgt_file_slat

    OptVS@DstGridLat = dst_lat
    OptVS@DstGridLon = dst_slon
    OptVS@WgtFileName  = wgt_file_slon

;---Get variable to regrid   t
    var3d=T70
    nn=dimsizes(var3d)
    nlev=nn(0)
    nslat=dimsizes(dst_slat)
    nslon=dimsizes(dst_slon)
    nlat=dimsizes(dst_lat)
    nlon=dimsizes(dst_lon)
    PS=new((/1,nlat, nlon/),typeof(var3d))
    var_out=new((/1,nlev, nlat, nlon/),typeof(var3d))
    do k=0,nlev-1
       var_in=var3d(k,:,:)
;---Call the regridding function
       var_regrid = ESMF_regrid_with_weights(var_in,wgt_file,Opt)
       printVarSummary(var_regrid)
       var_out(0,k,:,:)=var_regrid
    end do
    var_out!0="time"
    var_out!1="lev"    
    var_out!2="lat"
    var_out!3="lon"
    ;delete(var_out@lev)
    ;delete(var_out@lat1d)
    ;delete(var_out@lon1d)
    ;delete(var_out@_FillValue)
    ;delete(var_out@missing_value)
    ;delete(var_out@mdims)
    ;delete(var_out@time)
    ;delete(var_out@remap)
    T=var_out

;---Get variable to regrid   q
    var3d   = Q70
    var_out=new((/1,nlev,nlat,nlon/),typeof(var3d))
    do k=0,nlev-1
       var_in=var3d(k,:,:)
;---Call the regridding function
       var_regrid = ESMF_regrid_with_weights(var_in,wgt_file,Opt)
       var_out(0,k,:,:)=var_regrid
    end do
    var_out!0="time"
    var_out!1="lev"
    var_out!2="lat"
    var_out!3="lon"
    ;delete(var_out@lev)
    ;delete(var_out@lat1d)
    ;delete(var_out@lon1d)
    ;delete(var_out@_FillValue)
    ;delete(var_out@missing_value)
    ;delete(var_out@mdims)
    ;delete(var_out@time)
    ;delete(var_out@remap)
    Q=var_out


;---Get variable to regrid   u
    var3d   = U70
    var_out=new((/1,nlev,nlat,nlon/),typeof(var3d))
    do k=0,nlev-1
       var_in=var3d(k,:,:)
;---Call the regridding function
       var_regrid = ESMF_regrid_with_weights(var_in,wgt_file,Opt)
       var_out(0,k,:,:)=var_regrid
    end do
    var_out!0="time"
    var_out!1="lev"
    var_out!2="lat"
    var_out!3="lon"
    ;delete(var_out@lev)
    ;delete(var_out@lat1d)
    ;delete(var_out@lon1d)
    ;delete(var_out@_FillValue)
    ;delete(var_out@missing_value)
    ;delete(var_out@mdims)
    ;delete(var_out@time)
    ;delete(var_out@remap)
    U=var_out
    delete(var_out)
;;;;;;;STAGGERED U

    var3d   = U70
    var_out=new((/1,nlev,nslat,nlon/),typeof(var3d))
    do k=0,nlev-1
       var_in=var3d(k,:,:)
;---Call the regridding function
       var_regridS = ESMF_regrid_with_weights(var_in,wgt_file_slat,OptUS)
       var_out(0,k,:,:)=var_regridS
    end do
    var_out!0="time"
    var_out!1="lev"
    var_out!2="slat"
    var_out!3="lon"
    ;delete(var_out@lev)
    ;delete(var_out@lat1d)
    ;delete(var_out@lon1d)
    ;delete(var_out@_FillValue)
    ;delete(var_out@missing_value)
    ;delete(var_out@mdims)
    ;delete(var_out@time)
    ;delete(var_out@remap)
    US=var_out
    delete(var_out)




;---Get variable to regrid   v
    var3d   = V70
    var_out=new((/1,nlev,nlat,nlon/),typeof(var3d))
    do k=0,nlev-1
       var_in=var3d(k,:,:)
;---Call the regridding function
       var_regrid = ESMF_regrid_with_weights(var_in,wgt_file,Opt)
       var_out(0,k,:,:)=var_regrid
    end do
    var_out!0="time"
    var_out!1="lev"
    var_out!2="lat"
    var_out!3="lon"
    ;delete(var_out@lev)
    ;delete(var_out@lat1d)
    ;delete(var_out@lon1d)
    ;delete(var_out@_FillValue)
    ;delete(var_out@missing_value)
    ;delete(var_out@mdims)
    ;delete(var_out@time)
    ;delete(var_out@remap)
    V=var_out
    delete(var_out)
;;;;;;;;;;;;;;;STAGGERED VS

;---Get variable to regrid   v
    var3d   = V70
    var_out=new((/1,nlev,nlat,nslon/),typeof(var3d))
    do k=0,nlev-1
       var_in=var3d(k,:,:)
;---Call the regridding function
       var_regridSS = ESMF_regrid_with_weights(var_in,wgt_file_slon,OptVS)
       var_out(0,k,:,:)=var_regridSS
    end do
    var_out!0="time"
    var_out!1="lev"
    var_out!2="lat"
    var_out!3="slon"
    ;delete(var_out@lev)
    ;delete(var_out@lat1d)
    ;delete(var_out@lon1d)
    ;delete(var_out@_FillValue)
    ;delete(var_out@missing_value)
    ;delete(var_out@mdims)
    ;delete(var_out@time)
    ;delete(var_out@remap)
    VS=var_out

;---Get variable to regrid  lnsp
    delete(var_out)
;    var_out=new((/1,nlat,nlon/),typeof(var_in))
;---Call the regridding function
;    var_regrid = ESMF_regrid_with_weights(var_in,wgt_file,Opt)

;----------------------------------------------------------------------
;---writing section
;
;---open output file
    output="caminit_mb_stag.nc"  ;getenv("output")
    system("/bin/rm -f "+output)
    ncdf=addfile(output,"c")
    ncdf->time=time
    P0=fC->P0
    ncdf->P0=P0

    hyai=fC->hyai
    hybi=fC->hybi
    ncdf->hyai=hyai
    ncdf->hybi=hybi

    ncdf->hyam=hyao
    ncdf->hybm=hybo

    lev=fC->lev
    ilev=fC->ilev
    ncdf->lev=lev
    ncdf->ilev=ilev
    
   date=fC->date
   datesec=fC->datesec
;    area=fC->area
    time_bnds=fC->time_bnds
    date_written=fC->date_written
    time_written=fC->time_written
    ndbase=fC->ndbase
    nsbase=fC->nsbase
    nbdate=fC->nbdate
    nbsec=fC->nbsec
    mdt=fC->mdt
    ndcur=fC->ndcur
    nscur=fC->nscur
    nsteph=fC->nsteph
    date=fC->date
    datesec=fC->datesec

    ncdf->lat=dst_lat
    ncdf->lon=dst_lon
    ncdf->slon=dst_slon
    ncdf->slat=dst_slat
    ncdf->time_bnds=time_bnds
    ncdf->date_written=date_written
    ncdf->time_written=time_written
    ncdf->ndbase=ndbase
    ncdf->nsbase=nsbase
    ncdf->nbdate=nbdate
    ncdf->nbsec=nbsec
    ncdf->mdt=mdt
    ncdf->ndcur=ndcur
    ncdf->nscur=nscur
    ncdf->nsteph=nsteph
    ncdf->date=date
    ncdf->datesec=datesec
;--now get 2d vars
    var_in=press
    var_regrid = ESMF_regrid_with_weights(var_in,wgt_file,Opt)
    delete_VarAtts(var_regrid,-1)
    PS(0,:,:)=var_regrid
    PS!0="time"
    PS!1="lat"
    PS!2="lon"
    PS&time=time
    PS&lat=dst_lat
    PS&lon=dst_lon
    PS@units="Pa"
    PS@long_name = "Surface Pressure"
    ncdf->PS=PS


    delete_VarAtts(T,-1)
    T@units="K"
    T@long_name = "Temperature"
    T&time=time
    T&lev=tmplev
    T&lat=dst_lat
    T&lon=dst_lon
    ncdf->T=T

    delete_VarAtts(Q,-1)
    Q@units="kg/kg"
    Q@long_name = "Specific humidity"
    Q&time=time
    Q&lev=tmplev
    Q&lat=dst_lat
    Q&lon=dst_lon
    ncdf->Q=Q

    delete_VarAtts(U,-1)
    U@units="m/s"
    U@long_name = "Zonal wind"
    U&time=time
    U&lev=tmplev
    U&lat=dst_lat
    U&lon=dst_lon
    ncdf->U=U

    delete_VarAtts(US,-1)
    US@units="m/s"
    US@long_name = "Zonal wind, staggered"
    US&time=time
    US&lev=tmplev
    US&slat=dst_slat
    US&lon=dst_lon
    ncdf->US=US


    delete_VarAtts(V,-1)
    V@units="m/s"
    V@long_name = "Meridional wind"
    V&time=time
    V&lev=tmplev
    V&lat=dst_lat
    V&lon=dst_lon

    ncdf->V=V
 
    delete_VarAtts(VS,-1)
    VS@units="m/s"
    VS@long_name = "Meridional wind, staggered"
    VS&time=time
    VS&lev=tmplev
    VS&lat=dst_lat
    VS&slon=dst_slon

    ncdf->VS=VS


    ;ncdf->time=time
    ;time@units=tunits
    ;printVarSummary(time)   
 
end

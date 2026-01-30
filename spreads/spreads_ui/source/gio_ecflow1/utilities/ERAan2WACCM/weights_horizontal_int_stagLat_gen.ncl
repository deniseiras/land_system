;======================================================================
; BASED on ESMF_all_1.ncl
;
; Concepts illustrated:
;   - Generate weigths for grid conversion
;   - Writing data to a NetCDF file using the easy but inefficient method
;======================================================================
; For more information about ESMF:
;
;        http://www.earthsystemmodeling.org/
;
; This script uses built-in functions that are only available in 
; NCL V6.1.0 and later.
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
    WRITE_RESULTS = True 
    INTERP_METHOD = "bilinear"

;---Input file
    srcFileName = "/work/cmcc/gc02720/ic/EDA/ECEDA1_20170115_00.nc"

;---Output (and input) files
    srcGridName = "src_SCRIP.nc"
    dstGridName = "dst_SCRIP.nc"
    wgtFileName = "w_0.9_1.25_L70_stagLat.nc"

;---Set to True if you want to skip any of these steps
    SKIP_SRC_SCRIP_GEN = False
    SKIP_DST_SCRIP_GEN = False
    SKIP_WGT_GEN       = False

;----------------------------------------------------------------------
; Step 1, part 1
;     Convert original NetCDF file to an SCRIP convention file.
;----------------------------------------------------------------------
    sfile = addfile(srcFileName,"r")
    temp  = sfile->t                 ; ( TIME, DEPTH, LAT, LON )

    if(.not.SKIP_SRC_SCRIP_GEN) then
;--- Convert to a SCRIP Convention file.
      Opt                = True
      Opt@ForceOverwrite = True
      Opt@PrintTimings   = True
      Opt@Title          = "Finite Volume 0.9 x 1.25 Grid"
      Opt@Mask2D         = where(ismissing(temp(0,0,:,:)),0,1)

      rectilinear_to_SCRIP(srcGridName,temp&lat,temp&lon,Opt)

;---Clean up
      delete(Opt)
   end if

;----------------------------------------------------------------------
; Step 1, part 2
;     Convert destination grid to a SCRIP convention file.
;----------------------------------------------------------------------
    if(.not.SKIP_DST_SCRIP_GEN) then
      Opt                = True
      Opt@LLCorner       = (/ -89.53d,   0.d/)
      Opt@URCorner       = (/  89.53d, 358.75d/)
      Opt@ForceOverwrite = True
      Opt@PrintTimings   = True
      


     ; latlon_to_SCRIP(dstGridName,"0.9x1.25",Opt)
      latlon_to_SCRIP(dstGridName,"0.94degx1.25deg",Opt)

;---Clean up
      delete(Opt)
    end if

;----------------------------------------------------------------------
; Step 2
;     Generate the weights that take you from the NCEP grid to a
;     5x5 degree grid.
;----------------------------------------------------------------------
    if(.not.SKIP_WGT_GEN) then
     
      Opt                  = True
      Opt@WgtFileName      = "weights_hist_0.9_1.25.nc"   ; default is "weights_file.nc"
      Opt@InterpMethod     = INTERP_METHOD      ; patch takes longer
      Opt@ForceOverwrite   = True
      Opt@PrintTimings     = True
      Opt@Debug            = True

      ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileName,Opt)

;---Clean up
      delete(Opt)
    end if


end


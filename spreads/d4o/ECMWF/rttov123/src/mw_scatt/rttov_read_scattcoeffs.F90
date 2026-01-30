! Description:
!> @file
!!   Read Mie coefficient file.
!
!> @brief
!!   Read Mie coefficient file.
!!
!! @details
!!   Read in the Mietable file corresponding to the RTTOV coefficients
!!   structure passed in.
!!
!!   You can optionally pass in the full path of the Mietable file you wish to
!!   open using the file_coef argument.
!!
!!   You can optionally open the Mietable file before calling this subroutine
!!   and pass the logical unit number in the file_id argument.
!!
!!   If you do not supply either the file_id or file_coef arguments the
!!   subroutine automatically determines the name of the Mietable
!!   file from the coef_rttov structure based on the platform and instrument
!!   names. In this case you should not rename Mietable files and, by default,
!!   the Mietable file (or a symbolic link to it) is assumed to be present in
!!   the current directory. However you can use the optional path argument to
!!   specify the directory containing the Mietable file.
!!
!!   In all cases the Mietable file can be in ASCII or binary format: RTTOV will
!!   determine the format automatically and read it correctly (if you supplied
!!   the file_id argument the file must be opened in the correct mode).
!!
!!
!! @param[out]     err          status on exit
!! @param[in]      opts_scatt   RTTOV-SCATT options
!! @param[in]      coef_rttov   RTTOV coefficients structure
!! @param[in,out]  coef_scatt   Mietable structure
!! @param[in]      file_id      logical unit for Mietable file, optional
!! @param[in]      file_coef    file name of Mietable file, optional
!! @param[in]      path         directory containing Mietable file (if file_id and file_coef are not supplied), optional
!
! Copyright:
!    This software was developed within the context of
!    the EUMETSAT Satellite Application Facility on
!    Numerical Weather Prediction (NWP SAF), under the
!    Cooperation Agreement dated 25 November 1998, between
!    EUMETSAT and the Met Office, UK, by one or more partners
!    within the NWP SAF. The partners in the NWP SAF are
!    the Met Office, ECMWF, KNMI and MeteoFrance.
!
!    Copyright 2015, EUMETSAT, All Rights Reserved.
!
Subroutine rttov_read_scattcoeffs  (&
      & err,           &! out
      & opts_scatt,    &! in
      & coef_rttov,    &! in
      & coef_scatt,    &! inout
      & file_id,       &! in
      & file_coef,     &! in
      & path)           ! in

  ! History:
  ! version   date        comment
  ! -------   ----        -------
  !   1.0    09/2002      RTTOV7 compatible  (ECMWF)
  !   1.1    05/2003      RTTOV7.3 compatible (ECMWF)
  !   1.2    10/2004      Change stop to return (J Cameron)
  !   1.3    10/2004      Make file_id optional in analogy with rttov_readcoeffs (J Cameron)
  !   1.4    11/2007      Merge with IFS version for RTTOV9 (A Geer)  
  !   1.5    03/2010      Stop adding 1 to nhydro (A Geer)
  !   1.6    04/2010      Add binary option (T Wilhelmsson)
  !   1.7    01/2011      Code cleaning (T Wilhelmsson)
!INTF_OFF
#include "throw.h"
!INTF_ON
  Use rttov_types, Only : &
       & rttov_options_scatt, &
       & rttov_coefs, &
       & rttov_scatt_coef 

  Use parkind1, Only : jpim
!INTF_OFF
  Use rttov_const, Only :   &
       & rttov_magic_string  ,     rttov_magic_number  ,&
       & inst_name           ,&
       & platform_name       ,&
       & errorstatus_success ,&
       & errorstatus_fatal   ,&
       & lensection

  Use parkind1, Only : jprb, jplm

  USE YOMHOOK   ,ONLY : LHOOK,   DR_HOOK
!INTF_ON
  Implicit None

  Integer(Kind=jpim),           Intent(out)   :: err
  Type(rttov_options_scatt),    Intent(in)    :: opts_scatt
  Type(rttov_coefs),            Intent(in)    :: coef_rttov
  Type(rttov_scatt_coef),       Intent(inout) :: coef_scatt
  Integer(Kind=jpim), Optional, Intent(in)    :: file_id
  Character(Len=*),   Optional, Intent(in)    :: file_coef
  Character(Len=*),   Optional, Intent(in)    :: path
!INTF_END

#include "rttov_errorreport.interface"
#include "rttov_findnextsection.interface"
#include "rttov_skipcommentline.interface"
#include "rttov_opencoeff.interface"
#include "rttov_nullify_scattcoeffs.interface"

  Integer(Kind=jpim)    :: file_lu, io_status, inst, platform, i, j, k
  Logical(Kind=jplm)    :: existence
  Logical(Kind=jplm)    :: file_toclose
  Logical(Kind=jplm)    :: file_open
  Logical(Kind=jplm)    :: file_binary
  Character (len=20)    :: file_form
  Character (len=16)    :: bin_check_string
  Real(Kind=jprb)       :: bin_check_number
  Real(Kind=jprb)       :: bin_check_value
  Character (len=300)   :: coeffname
  Character (len=lensection) :: section
  Real(kind=jprb)       :: zhook_handle

  !- End of header --------------------------------------------------------

  TRY

  If (lhook) Call dr_hook('RTTOV_READ_SCATTCOEFFS',0_jpim,zhook_handle)

  Call rttov_nullify_scattcoeffs(coef_scatt)

  If ( Present (file_id) ) Then
    ! Scatt coefficient file has been opened externally
    file_lu = file_id
    file_toclose = .False.
    
    Inquire( file_lu, OPENED = file_open )
    THROWM(.Not. file_open, "File is not open")

  Else
    ! Open the scatt coefficients internally
    file_lu = 0
    file_toclose = .True.

    If ( Present (file_coef) ) Then
      ! User supplied file name: check existence
      Inquire( FILE = file_coef, EXIST = existence )
      If ( existence ) Then
        IF (opts_scatt%config%verbose) INFO('Open Mie coefficient file '//Trim(file_coef))
        ! Try opening as binary file
        Call rttov_opencoeff (err, file_coef, file_lu, lbinary = .True._jplm)
        If ( err == 0 ) Then
          ! Check header string
          bin_check_string = ''
          Read(file_lu, iostat=err) bin_check_string, bin_check_number
          If (bin_check_string /= rttov_magic_string) Then
            ! Not a binary file: will try as ASCII below
            err = errorstatus_fatal
          Else
            ! This is a binary Mietable file: rewind so it's ready for code below
            Rewind file_lu
          Endif

          ! If there was an error close file so we can try again as ASCII
          If (err /= 0) Close ( unit = file_lu )
        Endif
        If (err /= 0) Then
          ! Binary open failed, try ASCII access
          Call rttov_opencoeff (err, file_coef, file_lu)
          THROWM(err /= errorstatus_success, 'Error opening file: '//Trim(file_coef))
        Endif
      Else
        err = errorstatus_fatal
        THROWM(err /= errorstatus_success, 'File does not exist: '//Trim(file_coef))
      Endif
    Else
      ! Construct filename from coef structure
      platform = coef_rttov % coef % id_platform
      inst     = coef_rttov % coef % id_inst
      ! Binary filename
      coeffname = 'mietable_'//Trim(platform_name(platform))//'_'//Trim(inst_name(inst))//'.bin'
      If (Present(path)) coeffname = Trim(path)//'/'//coeffname
      Inquire( FILE = coeffname, EXIST = existence )
      If ( existence ) Then
        IF (opts_scatt%config%verbose) INFO('Open binary Mie coefficient file '//Trim(coeffname))
        ! Open binary file
        Call rttov_opencoeff (err, coeffname, file_lu, lbinary = .True._jplm)
        If ( err /= 0 ) Then
          ! Binary open fails, try ASCII access
          coeffname = 'mietable_'//Trim(platform_name(platform))//'_'//Trim(inst_name(inst))//'.dat'
          If (Present(path)) coeffname = Trim(path)//'/'//coeffname
          Call rttov_opencoeff (err, coeffname, file_lu)
        Endif
      Else
        ! ASCII filename
        coeffname = 'mietable_'//Trim(platform_name(platform))//'_'//Trim(inst_name(inst))//'.dat'
        If (Present(path)) coeffname = Trim(path)//'/'//coeffname
        IF (opts_scatt%config%verbose) INFO('Open ASCII Mie coefficient file '//Trim(coeffname))
        Call rttov_opencoeff (err, coeffname, file_lu)
      Endif

      THROWM(err /= 0, 'Error opening file: '//Trim(coeffname))
    Endif
  Endif

  ! Find out if the file is ascii or binary
  ! The inquire should work even if the file was opened externally
  If (err == errorstatus_success ) Then
    Inquire(file_lu,FORM=file_form)
    If ( file_form == 'FORMATTED' ) Then
      file_binary = .False.
    Elseif ( file_form == 'UNFORMATTED' ) Then
      file_binary = .True.
    Else
      THROWM(.true., 'Unknown file format: '//file_form)
    Endif
  Endif

  If (file_binary) Then

    read_binary_file: Do
      Read(file_lu, iostat=err ) bin_check_string, bin_check_number
      THROWM(err /= 0,'io status while reading header')

      ! Verification of header string
      THROWM(bin_check_string /= rttov_magic_string, 'Wrong header string in file')

      ! Verification of single/double precision using a 5 digit number
      ! with exponent 12, which is always Ok for single precision
      bin_check_value = 1._JPRB - Abs ( bin_check_number - rttov_magic_number )
      if (bin_check_value > 1.01_JPRB .Or. bin_check_value < 0.99_JPRB) err = errorstatus_fatal
      THROWM(err /= 0,'File created with a different real precision (R4<->R8)')
      
      Read(file_lu, iostat=err) &
        & coef_scatt%mfreqm,      &
        & coef_scatt%mtype,       &
        & coef_scatt%mtemp,       &
        & coef_scatt%mwc        
      THROWM(err /= 0, 'io status while reading DIMENSIONS')

      THROWM(coef_scatt%mtype /= 5, 'Wrong no of hydrometeors in parameter file (should be 5)')
      ! liquid prec., solid prec., ice water, liquid water, total ice
      
      Allocate (coef_scatt % mie_freq(coef_scatt%mfreqm))
      Allocate (coef_scatt % ext(coef_scatt%mfreqm, coef_scatt%mtype, coef_scatt%mtemp, coef_scatt%mwc))
      Allocate (coef_scatt % ssa(coef_scatt%mfreqm, coef_scatt%mtype, coef_scatt%mtemp, coef_scatt%mwc))
      Allocate (coef_scatt % asp(coef_scatt%mfreqm, coef_scatt%mtype, coef_scatt%mtemp, coef_scatt%mwc))
      
      Read(file_lu, iostat=err) coef_scatt%mie_freq (:)
      THROWM(err /= 0, 'io status while reading FREQUENCIES')
      
      Read(file_lu, iostat=err)            &
        & coef_scatt%conv_rain(:),         &
        & coef_scatt%conv_sp(:),           &
        & coef_scatt%conv_liq(:),          &
        & coef_scatt%conv_ice(:),          &
        & coef_scatt%conv_totalice(:),     &
        & coef_scatt%offset_temp_rain,     &
        & coef_scatt%offset_temp_sp,       &
        & coef_scatt%offset_temp_liq,      &
        & coef_scatt%offset_temp_ice,      &
        & coef_scatt%offset_temp_totalice, &
        & coef_scatt%scale_water,          &
        & coef_scatt%offset_water
      THROWM(err /= 0, 'io status while reading CONVERSIONS')
      
      Read(file_lu, iostat=err) coef_scatt % ext(:,:,:,:)
      THROWM(err /= 0, 'io status while reading EXTINCTION')
      
      Read(file_lu, iostat=err) coef_scatt % ssa(:,:,:,:)
      THROWM(err /= 0, 'io status while reading ALBEDO')
      
      Read(file_lu, iostat=err) coef_scatt % asp(:,:,:,:)
      THROWM(err /= 0, 'io status while reading ASP')
      Exit read_binary_file
    Enddo read_binary_file
    
  Else
    
    read_ascii_file: Do
      Call rttov_findnextsection( file_lu, io_status, section )
      If ( io_status < 0 ) Exit !end-of-file
      
      ! error message if any problem when reading
      Call rttov_skipcommentline ( file_lu, err )
      THROWM(err /= 0, 'io status while reading section '//section)
      
      Select Case( Trim(section) )
        
      Case( 'IDENTIFICATION' )
        Read(file_lu,*)  ! platform instrument in id
        Read(file_lu,*)  ! platform instrument in letters
        Read(file_lu,*)  ! sensor type [ir,mw,hi]
        Read(file_lu,*)  ! RTTOV compatibility version
        Read(file_lu,*)  ! version
        Read(file_lu,*)  ! creation date
        
      Case( 'DIMENSIONS')
        
        Read(file_lu,*)  coef_scatt%mfreqm,  coef_scatt%mtype,  coef_scatt%mtemp,  coef_scatt%mwc 
        
        THROWM(coef_scatt%mtype /= 5,'Wrong no of hydrometeors in parameter file (should be 5)')
        ! liquid prec., solid prec., ice water, liquid water, total ice
        
        Allocate (coef_scatt % mie_freq(coef_scatt%mfreqm))
        Allocate (coef_scatt % ext(coef_scatt%mfreqm, coef_scatt%mtype, coef_scatt%mtemp, coef_scatt%mwc))
        Allocate (coef_scatt % ssa(coef_scatt%mfreqm, coef_scatt%mtype, coef_scatt%mtemp, coef_scatt%mwc))
        Allocate (coef_scatt % asp(coef_scatt%mfreqm, coef_scatt%mtype, coef_scatt%mtemp, coef_scatt%mwc))
        
      Case( 'FREQUENCIES')
        
        Read(file_lu,*)  coef_scatt%mie_freq (:)
        
      Case( 'HYDROMETEOR')
        
        Read(file_lu,*)  
        
      Case( 'CONVERSIONS')
        
        Read(file_lu,*) coef_scatt%conv_rain(:)
        Read(file_lu,*) coef_scatt%conv_sp  (:)
        Read(file_lu,*) coef_scatt%conv_liq(:)
        Read(file_lu,*) coef_scatt%conv_ice(:)
        Read(file_lu,*) coef_scatt%conv_totalice(:)
        Read(file_lu,*) 
        Read(file_lu,*) coef_scatt%offset_temp_rain
        Read(file_lu,*) coef_scatt%offset_temp_sp
        Read(file_lu,*) coef_scatt%offset_temp_liq
        Read(file_lu,*) coef_scatt%offset_temp_ice
        Read(file_lu,*) coef_scatt%offset_temp_totalice
        Read(file_lu,*)
        Read(file_lu,*) coef_scatt%scale_water, coef_scatt%offset_water
        
      Case( 'EXTINCTION')
        
        ! The loops should be inverted for better efficiency, 
        ! but generation program currently not appropriate
        Do i = 1, coef_scatt%mfreqm
          Do j = 1, coef_scatt%mtype
            Do k = 1, coef_scatt%mtemp
              Read(file_lu,'(5(1x,e23.16))') coef_scatt % ext(i,j,k,:)
            Enddo
          Enddo
        Enddo
        
      Case( 'ALBEDO')
        
        Do i = 1, coef_scatt%mfreqm
          Do j = 1, coef_scatt%mtype
            Do k = 1, coef_scatt%mtemp
              Read(file_lu,'(5(1x,e23.16))') coef_scatt % ssa(i,j,k,:)
            Enddo
          Enddo
        Enddo
        
      Case( 'ASYMMETRY')
        
        Do i = 1, coef_scatt%mfreqm
          Do j = 1, coef_scatt%mtype
            Do k = 1, coef_scatt%mtemp
              Read(file_lu,'(5(1x,e23.16))') coef_scatt % asp(i,j,k,:)
            Enddo
          Enddo
        Enddo
        
      Case default
        
        Cycle read_ascii_file
        
      End Select
    Enddo read_ascii_file
  Endif
  
  If ( file_toclose ) Then
    Close ( unit = file_lu )
  Endif
  
  THROW(err /= errorstatus_success)

  coef_scatt % nhydro = coef_scatt%mtype

  coef_scatt%conv_rain(:) = 1._JPRB/coef_scatt%conv_rain(:)
  coef_scatt%conv_sp  (:) = 1._JPRB/coef_scatt%conv_sp  (:)
  coef_scatt%scale_water = 1._JPRB/coef_scatt%scale_water
  coef_scatt%offset_water = - coef_scatt%offset_water
  coef_scatt%from_scale_water = 10**( 1._JPRB / coef_scatt%scale_water )
        
  If (lhook) Call dr_hook('RTTOV_READ_SCATTCOEFFS',1_jpim,zhook_handle)
  CATCH
  If (lhook) Call dr_hook('RTTOV_READ_SCATTCOEFFS',1_jpim,zhook_handle)
End Subroutine rttov_read_scattcoeffs

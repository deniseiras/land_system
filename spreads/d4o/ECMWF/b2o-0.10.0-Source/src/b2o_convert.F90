module b2o_convert

use b2o_internal

implicit none

#include "b2o_debug.h"

contains

subroutine b2o_convert_proc(handle, status)

    type(b2o_handle_t), intent(inout) :: handle
    integer(b2o_int), intent(out) :: status
#ifdef WMONUMB
    integer(b2o_int) :: bufrtype, subtype1, subtype2
#endif
    character(len=64) :: message
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_convert_proc"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    status = B2O_SUCCESS

#ifdef WMONUMB
    bufrtype = handle%ksec1(6)
    subtype1 = handle%subtype
    subtype2 = handle%ksec1(17)
    if (bufrtype == 4 .and. subtype1 == 255) handle%subtype=146 ! Wigos-AMDAR code (at least at DMI)
    if (bufrtype == 4 .and. subtype1 == 4)   handle%subtype=149
    if (bufrtype == 0 .and. subtype1 == 0)   handle%subtype=170
    if (bufrtype == 0 .and. subtype1 == 1)   handle%subtype=170
    if (bufrtype == 0 .and. subtype1 == 2)   handle%subtype=170
    if (bufrtype == 0 .and. (subtype1 == 150 .or. subtype1 == 151)) then ! erroneous French SYNOPs
        handle%subtype=170
    endif
    if (bufrtype == 0 .and. (subtype1 == 242)) then ! erroneous French SYNOPs
        handle%subtype=170
    endif
    if (bufrtype == 0 .and. (subtype1 == 180 .or. subtype1 == 181)) then ! erroneous French SYNOPs
        handle%subtype=170
    endif
    if (bufrtype == 0 .and. subtype1 == 255 .and. subtype2 >= 0 .and. subtype2 <= 2) then 
        handle%subtype=170
    endif
    if (bufrtype == 1 .and. subtype1 == 0)   handle%subtype=11
    if (bufrtype == 1 .and. subtype1 == 255 .and. subtype2 == 0) handle%subtype=11
    if (bufrtype == 1 .and. subtype1 == 25)  handle%subtype=21
    if (bufrtype == 31 .and. subtype1 == 3)  handle%subtype=21
    if (bufrtype == 1 .and. subtype1 == 255)   handle%subtype=21 ! bathy - not to be used
    if (bufrtype == 2 .and. subtype1 == 255) then
      if (subtype2 == 1)  handle%subtype=112  ! BUFR land pilot
      if (subtype2 == 2)  handle%subtype=113  ! BUFR ship pilot
      if (subtype2 == 4)  handle%subtype=109
      if (subtype2 == 5)  handle%subtype=111
      if (subtype2 == 6)  handle%subtype=111
    endif
    if (bufrtype == 2 .and. subtype1 == 0) then
      if (subtype2 == 1) handle%subtype=112 ! BUFR land pilot
      if (subtype2 == 2) handle%subtype=113 ! BUFR ship pilot
      if (subtype2 == 4) handle%subtype=109 !may be problematic if TAC-BUFR ?
      if (subtype2 == 5) handle%subtype=111 ! TEMP SHIP
    endif
    if (bufrtype == 2 .and. subtype1 == 1)  handle%subtype=112 ! BUFR land pilot
    if (bufrtype == 2 .and. subtype1 == 2)  handle%subtype=113 ! BUFR ship pilot
    if (bufrtype == 2 .and. subtype1 == 4)  handle%subtype=109 ! may be problematic if TAC-BUFR ?
    if (bufrtype == 2 .and. subtype1 == 5)  handle%subtype=111 ! TEMP SHIP
    if (bufrtype == 2 .and. subtype1 == 6)  handle%subtype=111 ! MOBILE TEMP
    if (bufrtype == 3 .and. subtype1 == 14 .and. subtype2 == 50)  handle%subtype=250 ! radio occultation data
    if (bufrtype == 5 .and. subtype1 == 10)  handle%subtype=87 ! Meteosat-10 AMV 
    if (bufrtype == 12.and. subtype1 == 122)  handle%subtype=139! ASCAT via KNMI ftp
    if (bufrtype == 21.and. subtype1 == 61)  handle%subtype=201! NPP ATMS (preprocessed by AAPP)
#endif
    select case (handle%subtype)
    case (0,2)     ; call b2o_convert_synop_land_tac(handle, status)
    case (1,3)     ; call b2o_convert_synop_land_tac(handle, status)
    case (9,11,13,19,21:23)
                     call b2o_convert_synop_ship_tac(handle, status)
    case (28)      ; call b2o_convert_snow(handle, status)
    case (49)      ; call b2o_convert_ssmis_1d(handle, status)
    case (54:55,211) ; call b2o_convert_atovs(handle, status)
    case (57)      ; call b2o_convert_airs(handle, status)
    case (59)      ; call b2o_convert_amsre_1d(handle, status)
    case (60)      ; call b2o_convert_amsr2_1d(handle, status)
#ifdef BOM
    case (60:61)   ; call b2o_convert_atovs(handle, status)
    case (84:86)   ; call b2o_convert_satob(handle, status)
#endif
    case (65:75)   ; call b2o_convert_satem(handle, status)
    case (82:83,87); call b2o_convert_satob(handle, status)
    case (89)      ; call b2o_convert_grad(handle, status)
    case (91:92)   ; call b2o_convert_pilot_tac(handle, status)
    case (95:96)   ; call b2o_convert_windprofiler(handle, status)
    case (101:106) ; call b2o_convert_temp_tac(handle, status)
    case (109)     ; call b2o_convert_temp_hires(handle, status)
    case (110)     ; call b2o_convert_pgps(handle, status)
    case (111)     ; call b2o_convert_temp_hires(handle, status)
    case (112,113) ; call b2o_convert_pilot(handle, status)
    case (122)     ; call b2o_convert_scat(handle, status)
    case (125)     ; call b2o_convert_rain_rates(handle, status)
    case (126)     ; call b2o_convert_rain_gauges(handle, status)
    case (127)     ; call b2o_convert_ssmi(handle, status)
    case (129)     ; call b2o_convert_tmi_1d(handle, status)
    case (135,138) ; call b2o_convert_oscat(handle, status)
    case (166,167) ; call b2o_convert_fscat(handle, status)
    case (137)     ; call b2o_convert_qscat(handle, status)
    case (139)     ; call b2o_convert_ascat(handle, status)
    case (140,147) ; call b2o_convert_metar(handle, status)
    case (142:144) ; call b2o_convert_airep(handle, status)
    case (146)     ; call b2o_convert_amdar_wigos(handle, status)
    case (148)     ; call b2o_convert_tamdar(handle, status)
    case (145,149) ; call b2o_convert_acars(handle, status)
    case (150)     ; call b2o_convert_modes(handle, status)
    case (151)     ; call b2o_convert_amdar_wigos(handle, status)
    case (153)     ; call b2o_convert_mwri_1d(handle, status)
    case (154)     ; call b2o_convert_fy3(handle, status)
    case (156)     ; call b2o_convert_windsat(handle, status)
    case (164)     ; call b2o_convert_paob(handle, status)
    case (165)     ; call b2o_convert_ims(handle, status)
    case (170,172) ; call b2o_convert_synop_land(handle, status)
    case (176,178) ; call b2o_convert_synop_land(handle, status)
    case (180)     ; call b2o_convert_synop_ship(handle, status)
    case (181)     ; call b2o_convert_buoy_moored(handle, status)
    case (182)     ; call b2o_convert_buoy_drifting(handle, status)
    case (189)     ; call b2o_convert_msg(handle, status)
    case (190)     ; call b2o_convert_asr(handle, status)
    case (201)     ; call b2o_convert_atms(handle, status)
    case (202)     ; call b2o_convert_cris(handle, status)
    case (241)     ; call b2o_convert_hiras(handle, status) ! TEMPORARY /Reima
    case (242)     ; call b2o_convert_ikfs2(handle, status) ! TEMPORARY /Reima
    case (203)     ; call b2o_convert_smos(handle, status)
    case (204)     ; call b2o_convert_smap(handle, status)
    case (206)     ; call b2o_convert_reo3(handle, status)
    case (207)     ; call b2o_convert_modisaer(handle, status)
    case (208)     ; call b2o_convert_gch1(handle, status)
    case (209)     ; call b2o_convert_gch2(handle, status)
    case (212)     ; call b2o_convert_meris(handle, status)
    case (215)     ; call b2o_convert_gch3(handle, status)
    case (219)     ; call b2o_convert_viirs_aot(handle, status)
    case (224)     ; call b2o_convert_gmi(handle, status)
    case (228)     ; call b2o_convert_gch4(handle, status)
    case (229)     ; call b2o_convert_gch5(handle, status)
    case (230,231) ; call b2o_convert_temp_hires(handle, status)
    case (222,240) ; call b2o_convert_iasi(handle, status)
#ifdef WMONUMB
    case (250)     ; call b2o_convert_radio(handle, status)
#else
    case (250)     ; call b2o_convert_radio_lat_long(handle, status)
#endif
    case (251)     ; call b2o_convert_aeolus(handle, status)
    case default   ; status = B2O_UNSUPPORTED_SUBTYPE
    end select 

    if (status == B2O_UNSUPPORTED_SUBTYPE) then
        write (message, "(a,i0)") "Unsupported subtype: ", handle%subtype
        call b2o_log(handle, B2O_WARNING, message)
        status = B2O_SKIP_MESSAGE
    end if

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end subroutine b2o_convert_proc

function b2o_convert_message_data(c_context, c_converter, c_data, data_size, c_frame, c_new_columns) result(status) bind(c)

    use, intrinsic :: iso_c_binding
    use b2o_frame
    use b2o_internal

    type(c_ptr), value :: c_context, c_converter, c_data, c_frame
    integer(c_size_t), value :: data_size
    logical(c_bool), intent(out) :: c_new_columns
    integer(c_int) :: status

    type(b2o_context_t), pointer :: context
    type(b2o_handle_t), pointer :: converter
    type(b2o_frame_t), pointer :: frame
    character(len=1), pointer :: data(:)
    integer(b2o_int) :: id

    call c_f_pointer(c_context, context)
    call c_f_pointer(c_converter, converter)
    call c_f_pointer(c_data, data, [data_size])
    call c_f_pointer(c_frame, frame)

    call codes_new_from_message(id, data)
    call b2o_convert_message_id(context, converter, id, status)
    call codes_release(id)

    c_new_columns = converter%new_columns

    if (status == B2O_SUCCESS) then
        call fill_frame(converter, frame, c_new_columns)
        converter%new_columns = .false. ! assuming the same columns in subsequent calls
        !converter%new_columns = c_new_columns
    end if

end function

subroutine b2o_convert_message_id(context, handle, id, status)

    use b2o_accessor, only : b2o_new_accessor
    use b2o_amend
    use b2o_internal
    use b2o_set

    type(b2o_context_t), intent(inout), target :: context
    type(b2o_handle_t), intent(inout) :: handle
    integer(b2o_int), intent(in) :: id
    integer(b2o_int), intent(out) :: status
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "b2o_convert_message_id"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    status = B2O_SKIP_MESSAGE

    context%message_number = context%message_number + 1
    call codes_get(id, "dataSubCategory", context%message_subtype)
    handle%context => context

    call unpack_message(handle, id, status)

    if (status == B2O_SUCCESS) then
        call b2o_new_accessor(id, handle%accessor)
        call b2o_convert_proc(handle, status)
    end if

    if (status == B2O_SUCCESS .and. handle%reports == 0) then
        call b2o_log(handle, B2O_WARNING, "No valid reports after conversion")
        status = B2O_SKIP_MESSAGE
    end if

    if (status == B2O_SUCCESS) then
        call b2o_check_latlon(handle, status)
    end if

    if (status == B2O_SUCCESS) then
        call b2o_set_odb_codes(handle)
        call b2o_set_rdbdate_and_rdbtime(handle)
        call b2o_set_restricted(handle)
        call b2o_amend_sequence_number(handle)
        call b2o_amend_subset_number(handle)
        call b2o_amend_entry_number(handle)
    end if

    if (status == B2O_SKIP_MESSAGE) then
        call b2o_log(handle, B2O_WARNING, "Message skipped...")
    end if

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end subroutine

subroutine unpack_message(handle, id, status)

    type(b2o_handle_t), intent(inout), target :: handle
    integer(b2o_int), intent(in) :: id
    integer(b2o_int), intent(out) :: status

    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "unpack_message"

    if (lhook) call dr_hook(hook_label, 0, hook_handle)

    handle%bufr_id = id
    handle%subset_number = 0

    call codes_get(id, "dataSubCategory", handle%subtype)
    call codes_get(id, "numberOfSubsets", handle%reports)
    
    if (.not.any(handle%subtype == B2O_NO_SKIP_EXTRA_KEY_ATTRIBUTES)) then
        call codes_set(id, "skipExtraKeyAttributes", 1)
    end if

    call codes_set(id, "unpack", 1, status)

    if (status /= CODES_SUCCESS) then
        call b2o_log(handle, B2O_WARNING, "Could not unpack BUFR message")
        status = B2O_SKIP_MESSAGE
    end if

    if (lhook) call dr_hook(hook_label, 1, hook_handle)

end subroutine

subroutine fill_frame(handle, frame, new_columns)

    ! Denormalize, transpose and merge all tables into a single frame.

    use b2o_frame
    use b2o_internal

    type(b2o_handle_t), intent(in) :: handle
    type(b2o_frame_t), intent(inout), target :: frame
    logical(c_bool), intent(out) :: new_columns
    type(b2o_table_t), pointer :: table
    type(b2o_context_t), pointer :: context
    integer(b2o_int) :: i, j, k, n, offset, newfwh, oldfwh, oldmaxfht, fht
    real(b2o_double) :: hook_handle
    character(len=*), parameter :: hook_label = "fill_frame"

    if (lhook) then
        call dr_hook(hook_label, 0, hook_handle)
    end if

    context => handle%context

    new_columns = .FALSE.
    newfwh = 0
    table => handle%tables
    call b2o_assert(associated(table))
    do while (associated(table))
       if (table%is_used) then
          newfwh = newfwh + table%columns
       end if
       table => table%next
    end do
    
    frame%height = sum(handle%entries(1:handle%reports))

    if ( .not.associated(frame%data) &
         & .or. frame%height > frame%max_height &
         & .or. newfwh /= frame%width) then

        oldfwh = frame%width
        new_columns = (newfwh /= oldfwh)
        
        frame%width = 0
        table => handle%tables
        do while (associated(table))
            if (table%is_used) then
                frame%width = frame%width + table%columns
            end if
            table => table%next
        end do

        fht = frame%height
        oldmaxfht = frame%max_height
        write(0,'(a,L1,a,4(i0,1x),2L2)') &
& 'fill_frame: new_columns=',new_columns,' : newfwh,oldfwh,fht,oldmaxfht,associated(frame%data)?,allocated(frame%column_names)?=',&
&                                            newfwh,oldfwh,fht,oldmaxfht,associated(frame%data) ,allocated(frame%column_names)

        if (associated(frame%data)) &
&       write(0,'(a,L1,a,i0,"x",i0)') &
& 'fill_frame: new_columns=',new_columns,' : shape(frame%data)=',shape(frame%data)

        if (allocated(frame%column_names)) &
&       write(0,'(a,L1,a,i0)') &
& 'fill_frame: new_columns=',new_columns,' : size(frame%column_names)=',size(frame%column_names)

        frame%max_height = 2*frame%height

        if (associated(frame%data)) deallocate(frame%data)
        allocate(frame%data(frame%width,frame%max_height))

        if (associated(frame%data)) &
&       write(0,'(a,L1,a,i0,"x",i0)') &
& 'fill_frame: new_columns=',new_columns,' : shape(frame%data):',shape(frame%data)
        
        if (allocated(frame%column_names)) then
           if (new_columns .or. size(frame%column_names) /= frame%width) then
              deallocate(frame%column_names)
           endif
        endif

    end if

    if (.not.allocated(frame%column_names)) then
        allocate(frame%column_names(frame%width))
        i = 1
        table => handle%tables
        do while (associated(table))
            if (table%is_used) then
                do j = 1, table%columns ! size(table%column_names)
                    frame%column_names(i) = trim(table%column_names(j)) // "@" // trim(table%name)
                    i = i + 1
                end do
            end if
            table => table%next
        end do
         
        if (allocated(frame%column_names)) &
&       write(0,'(a,L1,a,i0)') &
& 'fill_frame: new_columns=',new_columns,' : size(frame%column_names):',size(frame%column_names)

    end if

    offset = 0
    table => handle%tables

    table_loop: do while (associated(table))

        if (.not.table%is_used) then
            table => table%next
            cycle table_loop
        end if

        call b2o_assert(offset < frame%width)

        select case (table%kind)
        case (B2O_KIND_HEADER)
            call b2o_assert(table%rows == handle%reports)
            n = 0
            do i = 1, handle%reports
                do j = 1, handle%entries(i)
                    do k = 1, table%columns
                        frame%data(offset+k,n+j) = table%data(i,k)
                    end do
                end do
                n = n + handle%entries(i)
            end do
        case (B2O_KIND_BODY)
            call b2o_assert(table%rows == frame%height)
            do j = 1, table%rows
                do k = 1, table%columns
                    frame%data(offset+k,j) = table%data(j,k)
                end do
            end do
        case default
            call b2o_log(context, B2O_ERROR, "Unrecognized table: "//trim(table%name))
            call b2o_exit(B2O_UNRECOGNIZED_TABLE)
        end select

        offset = offset + table%columns
        table => table%next

    end do table_loop

    if (lhook) then
        call dr_hook(hook_label, 1, hook_handle)
    end if

end subroutine

end module

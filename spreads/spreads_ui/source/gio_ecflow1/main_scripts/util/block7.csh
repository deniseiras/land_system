#!/bin/csh

# ==============================================================================
# Block 7: Actually run the assimilation.
#
# DART namelist settings required:
# &filter_nml
#    adv_ens_command         = "no_CESM_advance_script",
#    obs_sequence_in_name    = 'obs_seq.out'
#    obs_sequence_out_name   = 'obs_seq.final'
#    single_file_in          = .false.,
#    single_file_out         = .false.,
#    stages_to_write         = stages you want + ,'output'
#    input_state_file_list   = 'cam_init_files'
#    output_state_file_list  = 'cam_init_files',
#
# WARNING: the default mode of this script assumes that
#          input_state_file_list = output_state_file_list, so that
#          the CAM initial files used as input to filter will be overwritten.
#          The input model states can be preserved by requesting that stage
#          'forecast' be output.
#
# ==============================================================================

# In the default mode of CAM assimilations, filter gets the model state(s)
# from CAM initial files.  This section puts the names of those files into a text file.
# The name of the text file is provided to filter in filter_nml:input_state_file_list.

# NOTE:
# If the files in input_state_file_list are CESM initial files (all vars and
# all meta data), then they will end up with a different structure than
# the non-'output', stage output written by filter ('preassim', 'postassim', etc.).
# This can be prevented (at the cost of more disk space) by copying
# the CESM format initial files into the names filter will use for preassim, etc.:
#    > cp $case.cam_0001.i.$date.nc  preassim_member_0001.nc.
#    > ... for all members
# Filter will replace the state variables in preassim_member* with updated versions,
# but leave the other variables and all metadata unchanged.

# If filter will create an ensemble from a single state,
#    filter_nml: perturb_from_single_instance = .true.
# it's fine (and convenient) to put the whole list of files in input_state_file_list.
# Filter will just use the first as the base to perturb.



cd ${TMPROOT}
set line = `grep input_state_file_list input.nml | sed -e "s#[=,'\.]# #g"`
set input_file_list_name = $line[2]

# If the file names in $output_state_file_list = names in $input_state_file_list,
# # then the restart file contents will be overwritten with the states updated by DART.

set line = `grep output_state_file_list_ts input.nml | sed -e "s#[=,'\.]# #g"`
set output_file_list_name = $line[2]

if ($input_file_list_name != $output_file_list_name) then
   echo "ERROR: assimilate.csh requires that input_file_list = output_file_list"
   echo "       You can probably find the data you want in stage 'forecast'."
   echo "       If you truly require separate copies of CAM's initial files"
   echo "       before and after the assimilation, see revision 12603, and note that"
   echo "       it requires changing the linking to cam_initial_####.nc, below."
   exit 130
endif

set inst=1
while ( $its <= $NTSLOTS)
   ${REMOVE} ./TS${its}/$input_file_list_name
   @ its++
end

while ( $inst <= $nens )
   set inst_string=`printf _%04d $inst`
   set its=1
   while ( $its <= $NTSLOTS )
        set datets=`ls -l $CASESRUNROOT/${case_name}$inst_string/run/*cam.i* | tail -n $its | head -n 1 | cut -d '.' -f4`
        set ftoass="$CASESRUNROOT/${case_name}$inst_string/run/${case_name}$inst_string.cam.i.${datets}.nc"
        echo "${ftoass}" >> ./TS${its}/$input_file_list_name

    @ its++
   end

  @ inst++
end



echo 'END PREPARATION PHASE 1: departures computation'

echo 'CALLING take_f.sh'
 ${TMPROOT}/take_f.sh ${TMPROOT} "filter" $NTSLOTS "yes"
echo 'END take_f.sh'

###	WE DO NOT NEED ANYMORE OF THIS KIND OF CHECK WITH ECFLOW
# check if the assimilation ended correctly otherwise you neeed to skip all the instruction below
#set its=1
#set ic=0
#   while ( $its <= $NTSLOTS )
#
#   if ( `grep "2" ${TMPROOT}/TS${its}/filter.flag` ) then
#     echo " assimilation ended succesfully, in TS"$its
#     @ ic++
#   endif
#   @ its++
#   end
#if ( $ic == $NTSLOTS ) then
#   echo " assimilation ended succesfully, move files into archive, set check_assi.flag to 1"

#echo "`date` -- END FILTER"





























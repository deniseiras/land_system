#!/bin/bash


   echo "`date` -- BEGIN FILE RENAMING"

   set +e

# The short-term archiver archives files depending on pieces of their names.
# '_####.i.' files are CESM initial files.
# '.dart.i.' files are ensemble statistics (mean, sd) of just the state variables
#            in the initial files.
# '.e.'      designates a file as something from the 'external system processing ESP', e.g. DART.
# for stage in $( echo ${stages_all} );do
    for FILE in  forecast_member_????.nc;do # {forecast,,output}

        parts=$(echo $FILE | sed -e "s#\.# #g" | awk '{print $1}')
        list="$(echo $FILE | sed 's/.nc//g' | sed 's/_/ /g' )"
        dart_file=$(echo $FILE | sed "s/.nc//g")

        # DART 'output_member_****.nc' files are actually linked to cam input files

        if [[ "out" == "${FILE:0:3}" ]];then
            export type="i"
        else
            export type="e"
        fi

        echo "Moving $FILE in ${case_name}.${scomp}_${list}.${type}.${dart_file}.${ATM_DATE_EXT}.nc "
        mv $FILE  ${case_name}.${scomp}_${list}.${type}.${dart_file}.${ATM_DATE_EXT}.nc || exit 150

    done





        for tp in $(echo "mean sd");do
        for stg in $(echo ${stages_all});do
            for FILE in $( ls "${stg}_${tp}*.nc" );do
                echo "$FILE renaming"
                parts=$(echo $FILE | sed -e "s#\.# #g" | awk '{print $1}')
                if [[ "out" == "${FILE:0:3}" ]];then
                    export type="i"
                else
                    export type="e"
                fi

                mv $FILE ${case_name}.dart.${type}.${scomp}_${parts}.${ATM_DATE_EXT}.nc || exit 160
            done
        done
    done

# Rename the observation file and run-time output
    if [ -f obs_seq.final.$(ls -l "dart_log.out*" | tail -1 | awk '{print $9}' | cut -d "." -f 3) ]; then
        mv -f obs_seq.final.$(ls -l "dart_log.out*" | tail -1 | awk '{print $9}' | cut -d "." -f 3) ${case_name}.dart.e.${scomp}_obs_seq_final.${ATM_DATE_EXT} || exit 170
    fi

    mv -f $(ls -l dart_log.out* | tail -1 | awk '{print $9}') ${scomp}_dart_log.${ATM_DATE_EXT}.out || exit 171

    for fdb in $(ls *.db);do
        fdb_no_ext=$(echo ${fdb} | cut -d'.' -f1)
        fdb_num=$(echo ${fdb} | cut -d'.' -f2)
        echo "move ${fdb_no_ext}.${fdb_num}"
        mv -f ${fdb} ${case_name}.spreads.${fdb_no_ext}.${fdb_num}.${ATM_DATE_EXT}.db || exit 170
    done



# Handle localization_diagnostics_files
    MYSTRING=$(grep 'localization_diagnostics_file' input.nml)
    MYSTRING=$(echo $MYSTRING | sed -e "s#[=,']# #g")
    MYSTRING=$(echo $MYSTRING | sed -e 's#"# #g')
    loc_diag=$(echo "$MYSTRING" | awk '{print $2}')

    if [ -f $loc_diag ];then
        mv -f $loc_diag  ${scomp}_${loc_diag}.dart.e.${ATM_DATE_EXT} || exit 190
    fi

# Handle regression diagnostics
    MYSTRING=$(grep 'reg_diagnostics_file' input.nml)
    MYSTRING=$(echo $MYSTRING | sed -e "s#[=,']# #g")
    MYSTRING=$(echo $MYSTRING | sed -e 's#"# #g')
    export reg_diag=$(echo "$MYSTRING" | awk '{print $2}')
    if [ -f $reg_diag ];then
        mv -f $reg_diag  ${scomp}_${reg_diag}.dart.e.${ATM_DATE_EXT} || exit 200
    fi


    member=1
    while [ ${member} -le ${nens} ];do

        inst_string=$(printf _%04d $member)
        cd $CASESRUNROOT/${case_name}$inst_string/run
        echo " In `pwd` for i.c. renaming"
        ATM_INITIAL_FILENAME="${case_name}${inst_string}.cam.i.${ATM_DATE_EXT}.nc"
        rm -f ${scomp}_initial${inst_string}.nc
        echo " Link $ATM_INITIAL_FILENAME in ${scomp}_initial${inst_string}.nc "
        ln -sf $ATM_INITIAL_FILENAME ${scomp}_initial${inst_string}.nc || exit 210

        member=$(echo "${member}+1" | bc)

    done


    echo "$(date) -- END   FILE RENAMING"


    echo ""








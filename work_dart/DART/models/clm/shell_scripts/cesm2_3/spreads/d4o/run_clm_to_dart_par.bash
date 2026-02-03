#!/bin/bash
#
# Este script processa arquivos clm_to_dart em paralelo usando o sistema de jobs 'bsub'.
# Ele cria um job para cada membro do ensemble e espera que todos os jobs sejam concluídos
# antes de prosseguir para a próxima etapa.


# HISTORY
#
# author            version     comments
# Luis Gustavo      none        Improved paralelized version submitting many jobs in a for in any node available
# Denis Eiras       1.0.0       Improved paralelized version submitting many jobs in a job array in one node
# Denis Eiras       1.1.0       Improved paralelized version distributing jobs in some nodes
# Denis Eiras       1.1.1       Adapting to the spreads - firtst github version


# Argumentos do script (valores fornecidos na linha de comando)
#
export CASE=$1               # CASE é o nome do caso específico
export LND_DATE_EXT=$2       # LND_DATE_EXT é a extensão da data para identificar os arquivos
export ENS_MEMBERS_REQ=$3      # num de membros a processar
export RUNDIR=$4             # diretório de execução


# Local variables
#

# TODO check / improve: directory must be generic for all machines
if ( $machine | grep juno > /dev/null ) then
    export base_ram_disk="/work/cmcc/spreads-lnd"
else
    export base_ram_disk="/work/cmcc/de34824"
fi

export restart_files_mask="${CASE}.clm2_*.r.${LND_DATE_EXT}.nc"
# Inicializa uma variável string_id que armazenará os IDs dos jobs que serão submetidos.
string_id=""


echo "Running run_clm_to_dart_par.bash with ... ${CASE} ${LND_DATE_EXT} ${ENS_MEMBERS_REQ} ${RUNDIR} ${PROCESS_PER_NODE} ${EXCLUSIVE_NODE}"


# Function to process data for a specific ensemble member
#
process_data() {

    SECONDS=0 

    local ens_index=$1
    # processes > ens_size will not be processed)
    if (( ens_index > ${ENS_MEMBERS_REQ} )); then
        return 0
    fi
    
    echo "Starting processing member ${ens_index} ..."
    echo "CASE         = "$CASE
    echo "LND_DATE_EXT = "$LND_DATE_EXT
    echo "Looking for files like ${restart_files_mask} ..." 

    # Build an array of files matching the pattern
    # (Optionally sort them if order is important)
    local files=( $(ls ${restart_files_mask} | sort) )

    # Check that the ensemble index is not superior to the number of files
    if (( ens_index < 1 || ens_index > ${#files[@]} )); then
        echo "Error: Ensemble index $ens_index is out of range (1 - ${#files[@]})."
        return 1
    fi

    # Select the file corresponding to the ensemble index.
    local file=${files[$((ens_index - 1))]}
    echo "Processing file: $file for ensemble member $ens_index at host $(hostname)"

    ens_index_4digits=$(printf "%04d" ${ens_index})  # Gera o identificador do ensemble (0001, 0002, ...)
    OUTPUT="clm2_${ens_index_4digits}.r.${LND_DATE_EXT}.nc"

    # Create a RAM disk directory for faster file operations
    ramdisk_dir="${base_ram_disk}/tmp/clm_${CASE}_${LND_DATE_EXT}_${ens_index_4digits}_tmp"
    mkdir -p "$ramdisk_dir" || { echo "Error: Unable to create tmp directory"; exit 1; }


    # Copy the ensemble restart file into the RAM disk
    # rsync --inplace "$file" "$ramdisk_dir/clm.nc" || { echo "Error: Failed to copy $file to tmp"; exit 1; }
    cp -f "$file" "$ramdisk_dir/clm.nc" || { echo "Error: Failed to copy $file to tmp"; exit 1; }

    # Copy input.nml to RAM disk as well
    cp -f "$RUNDIR/input.nml" "$ramdisk_dir/" || { echo "Error: Failed to copy input.nml"; exit 1; }

    # Change to the RAM disk directory to process files
    cd "$ramdisk_dir" || { echo "Error: Failed to change directory to $ramdisk_dir"; exit 1; }

    # Run the clm_to_dart process using the absolute path
    echo "Running clm_to_dart in $ramdisk_dir"
    $RUNDIR/clm_to_dart

    # Move the processed file directly to the final output location
    echo "Moving processed file to $OUTPUT"
    mv clm.nc $RUNDIR/${OUTPUT} || { echo "Error: Failed to move clm.nc to $OUTPUT"; exit 1; }

    # Clean up the RAM disk
    rm -rf "$ramdisk_dir" || { echo "Error: Failed to clean up RAM disk"; exit 1; }

    echo "Processed $OUTPUT sucessfully !"
    echo "Time clm_to_dart: ${SECONDS} seconds"
        
}

export -f process_data


# Certifica-se de que o diretório temporário "tmp" existe para armazenar os arquivos temporários
mkdir -p tmp
# Remove qualquer link simbólico antigo (se existente) do arquivo clm_vector_history
unlink clm_vector_history   

export ens_members_found=$(ls -l ${restart_files_mask} | wc -l)

echo "Found ${ens_members_found} from requested ${ENS_MEMBERS_REQ} members. Executing with ${ENS_MEMBERS_REQ}"
if [ "${ens_members_found}" -lt "${ENS_MEMBERS_REQ}" ]; then
    echo "Error: Insufficient ensemble members. Only ${ens_members_found} found but ${ENS_MEMBERS_REQ} required."
    exit 1
fi

if ( "$machine" == "juno" ) then
    # sources the same modules at assimilate_executor, plus /data/cmcc/de34824/d4o/install/INTEL/source.me
    # which exports a lot of env vars - e.g. below - confirm if needed in cassandra and ... 
    source /users_home/cmcc/lg07622/modules_juno.me
    # ... includes the below
    # source /data/cmcc/${USER}/d4o/install/INTEL/source.me
    # module load intel-2021.6.0/cdo-threadsafe/2.1.1-lyjsw
    # module load intel-2021.6.0/ncview/2.1.8-sds5t
else # cassandra
    # TODO - check the vars exported in juno above
    source /work/cmcc/de34824/spreads/d4o/load-modules-d4o.cassandra
endif 

# TODO - Spread across all nodes evenly to improve performance. 
# This was reached before using blaunch, but now, its not possible because blaunch spreads across all processes
# Executes the process_data function for each ensemble member
for ii in $(seq 1 ${ENS_MEMBERS_REQ}); do
    process_data ${ii} &
done

wait


cd $RUNDIR

enscount=1
for ii in $(seq 1 ${ENS_MEMBERS_REQ}); do
    echo "Creating restart_files.txt, history_files.txt, vector_files.txt: " $ii
    ni=$(printf "%04d" ${ii})  # Gera o identificador do ensemble (0001, 0002, ...)
    OUTPUT="clm2_${ni}.r.${LND_DATE_EXT}.nc"
    HZERO="${RUNDIR}/${CASE}.clm2_${ni}.h0.${LND_DATE_EXT}.nc"
    HTWO="${RUNDIR}/${CASE}.clm2_${ni}.h2.${LND_DATE_EXT}.nc"
    # Check if the output and HZERO and HTWO exist. If not, exit with error
    if [ ! -e $OUTPUT ]; then
        echo "CLM2DART ERROR: could not find $OUTPUT"
        exit 1
    fi
    if [ ! -e $HZERO ]; then
        echo "CLM2DART ERROR: could not find $HZERO"
        exit 1
    fi
    if [ ! -e $HTWO ]; then
        echo "CLM2DART ERROR: could not find $HTWO"
        exit 1
    fi


ls -1 "${OUTPUT}" >> restart_files.txt
ls -1 "${RUNDIR}/${CASE}.clm2_${ni}.h0.${LND_DATE_EXT}.nc" >> history_files.txt
ls -1 "${RUNDIR}/${CASE}.clm2_${ni}.h2.${LND_DATE_EXT}.nc" >> vector_files.txt
    ((enscount++))
done

# Pós-processamento: Move os arquivos de saída processados para o diretório final
#enscount=1
#for ii in $(seq 1 ${ENSEMBLE_SIZE}); do
#    echo "ENTROU NO LOOP : " $ii
#
#    ni=$(printf "%04d" ${ii})  # Gera o identificador do ensemble (0001, 0002, ...)
#    OUTPUT="clm2_${ni}.r.${LND_DATE_EXT}.nc"
#    NDIR="cc_${ni}"
#
#    # Move o arquivo processado (clm.nc) do diretório temporário para o nome final de saída
#    mv "tmp/${NDIR}/clm.nc" "$OUTPUT"
#
#    # Registra os arquivos de reinício, história e vetor nos arquivos de log correspondentes
#    ls -1 "${OUTPUT}" >> restart_files.txt
#    ls -1 "${RUNDIR}/${CASE}.clm2_${ni}.h0.${LND_DATE_EXT}.nc" >> history_files.txt
#    ls -1 "${RUNDIR}/${CASE}.clm2_${ni}.h2.${LND_DATE_EXT}.nc" >> vector_files.txt
#
#    ((enscount++))
#done

# Exibe uma mensagem indicando que todos os jobs de processamento foram concluídos

echo "ALL CLM_TO_DART JOBS FINISHED"
exit 0

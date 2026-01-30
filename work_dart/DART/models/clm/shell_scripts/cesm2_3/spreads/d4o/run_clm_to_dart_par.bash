#!/bin/bash
#
# Este script processa arquivos clm_to_dart em paralelo usando o sistema de jobs 'bsub'.
# Ele cria um job para cada membro do ensemble e espera que todos os jobs sejam concluídos
# antes de prosseguir para a próxima etapa.

# Argumentos do script (valores fornecidos na linha de comando)
# CASE é o nome do caso específico
CASE=$1
# LND_DATE_EXT é a extensão da data para identificar os arquivos
LND_DATE_EXT=$2

ENSEMBLE_SIZE=$3

RUNDIR=$4

echo "Running run_clm_to_dart_par.bash with ramdisk... "$CASE" "$LND_DATE_EXT" "$ENSEMBLE_SIZE" "$RUNDIR
# Inicializa um contador para rastrear o número do ensemble (enscount)
enscount=1

# Inicializa uma variável string_id que armazenará os IDs dos jobs que serão submetidos.
string_id=""

# Função que executa o comando passado como argumento e retorna o ID do job que foi submetido.
#==============================================
#     Function def
#==============================================
# Take the id of the case.submit processes
take_id()
{

  output=$("$@")
  #echo $output | awk '{print $NF}'
  echo 'OUTPUT '$output
  echo $output
}
#
# Function to process data for a specific year and month
process_data() {
   local ni=$1  # Pass ensemble index as an argument
   local FILE=$2  # Pass the FILE as an argument
   local OUTPUT=$3  # Pass the OUTPUT as an argument
   local RUNDIR=$4

   # Create a RAM disk directory for faster file operations
   #ramdisk_dir="/dev/shm/clm_${ni}_tmp"
   ramdisk_dir="/work/cmcc/spreads-lnd/tmp/clm_${ni}_tmp"
   mkdir -p "$ramdisk_dir" || { echo "Error: Unable to create RAM disk directory"; exit 1; }

   # Copy the ensemble restart file into the RAM disk
   echo "Copying $FILE to RAM disk: $ramdisk_dir"
   cp -f "$FILE" "$ramdisk_dir/clm.nc" || { echo "Error: Failed to copy $FILE to RAM disk"; exit 1; }

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
   cd -
   rm -rf "$ramdisk_dir" || { echo "Error: Failed to clean up RAM disk"; exit 1; }

   echo "Processed $OUTPUT using RAM disk"
    

   #jobid=$(take_id ../../../bld/dart_to_clm)
   #d4o change of executables in directories
   #jobid=$(take_id ../../clm_to_dart)

   #take_id ../../../bld/dart_to_clm
   #string_id=$string_id" done($jobid)"
   #echo 'JOB_ID '$jobid
   #echo $string_id

}

export -f process_data
export -f take_id

# Certifica-se de que o diretório temporário "tmp" existe para armazenar os arquivos temporários
mkdir -p tmp
# Remove qualquer link simbólico antigo (se existente) do arquivo clm_vector_history
unlink clm_vector_history   

# Loop que itera sobre todos os arquivos de reinício (restart) que correspondem ao padrão fornecido
for RESTART in "${CASE}.clm2_"*.r."${LND_DATE_EXT}".nc; do
    
    # Cria um identificador único para cada membro do ensemble (ex: 0001, 0002, ...)
    ni=$(printf "%04d" ${enscount})

    OUTPUT="clm2_${ni}.r.${LND_DATE_EXT}.nc"

    # Submete um job para o sistema de batch usando o comando 'bsub'
    # O job executará o script run_clm_to_dart.bash, que processa os arquivos.
    kk=$(bsub -J "process_${ni}" -oo "process_${ni}.log" << EOF

#!/bin/bash
#BSUB -P R000                 # Especifica o projeto
#BSUB -W 00:20                # Tempo máximo de execução (20 minutos)
#BSUB -n 1                    # Número de núcleos de CPU solicitados (2 núcleos)
#BSUB -q p_short              # Fila de jobs curta
#BSUB -R "rusage[mem=1GB]"   # Requisita 2000 MB de memória por job
#BSUB -R "span[hosts=1]"      # Máximo de 8 processos por nó
#BSUB -app spreads_filter     # Aplica o filtro spreads (configuração específica do sistema)

# Carrega módulos necessários para o processamento
source /users_home/cmcc/lg07622/modules_juno.me

# Executa o script de processamento para este membro
process_data "$ni" "$RESTART" "$OUTPUT" "$RUNDIR"
EOF
)

    # Extrai o ID do job submetido a partir da saída do comando 'bsub'
    jobid=$(echo "${kk//<}" | awk '{print $2}')

    # Constrói a string que rastreia todos os IDs dos jobs submetidos. Isso será usado para esperar
    # até que todos os jobs estejam completos antes de prosseguir.
    if [ $enscount -eq 1 ]; then 
        # Se for o primeiro job, inicia a string com 'done(jobid)'
        string_id="done(${jobid//>})"
    else
        # Para os próximos jobs, adiciona à string com '&& done(jobid)'
        string_id="${string_id} && done(${jobid//>})"
    fi

    # Volta para o diretório original
    cd $RUNDIR

    # Incrementa o contador para processar o próximo membro do ensemble
    ((enscount++))
done

# Usa o comando 'bwait' para esperar que todos os jobs sejam concluídos.
# Ele só continua para a próxima etapa quando todos os jobs finalizarem.
echo " string_id = $string_id"
bw=0
bwait -w "$string_id" || bw=$?
bjobs

cd $RUNDIR

enscount=1
for ii in $(seq 1 ${ENSEMBLE_SIZE}); do
    echo "Creating  restart_files.txt, history_files.txt, vector_files.txt: " $ii
    ni=$(printf "%04d" ${ii})  # Gera o identificador do ensemble (0001, 0002, ...)
    OUTPUT="clm2_${ni}.r.${LND_DATE_EXT}.nc"


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
exit

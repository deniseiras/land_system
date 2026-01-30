#!/bin/bash --login
#SBATCH -q np
#SBATCH -A itcmcc
#SBATCH -J d4o-rep
#SBATCH -o d4o-rep-%j.out
#SBATCH -e d4o-rep-%j.err
#SBATCH -N 1
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --time=00:20:00
#SBATCH --export=ALL 

module load anaconda
conda activate cesm
module load ecflow/5.13.3
module load cmake/3.20.2
module load intel/2021.4.0



/usr/bin/time -v /ec/res4/hpcperm/ita0829/conda/envs/cesm/bin/python3 rep_input2.py $(cat rep_input_list.txt) 200 || exit 0

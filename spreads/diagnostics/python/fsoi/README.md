## FSOI_Jo for ensemble filtering

1. preprocess your archived results in order to compute the forward operator: bash prep_fsoijo.sh
    
   nohup ./prep_fsoijo.bash > prep.log 2>&1 &


# Sequential
2. compute the fsoi by means of fsoijo_en.py
   
   bsub < fsoijo_exec.bash 

# Parallel
3. bsub < mpi_fsoijo_exec.bash

4. bsub < mpi_oijo_exec.bash





5. For testing: 
   nohup python3 -u ./fsoijo_en.py > fsoi.log 2>&1 &

6. For testing: 
   nohup python3 -u ./oi_en.py > oi.log 2>&1 &

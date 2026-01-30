Here you can find the scripts to run spreads with the cam-fv model.




<h1> JUNO (useful hints)</h1>

<h2>MODEL:</h2>
Since we have plenty of space  in our home I’ve created a directory called “model” and inside:


1. ``` git clone https://github.com/CMCC-Foundation/CMCC-CM.git spread-cmcc-cm ```

2. ```cd spread-cmcc-cm/```

3. ```git checkout cesm2.3_beta11_cm3_v7z```

4. ```./manage_externals/checkout_externals```

To run the model you need to activate a particular python env:
```module load anaconda/3-2022.10```

and then

```conda activate cmcc-cm_py39 ```


You can also create your own environment based on the one above to be  loaded at the login.

There is a problem now about some files and you need to copy my configuration
```/users_home/cmcc/gc02720/model/cesm2.3_beta11_cm3_v7z/ccs_config/machines/config_machines.xml```


<h2>CONFIGURE .bash_profile:</h2>
If you clone the model in the model dir inside your home you can keep this configuration, otherwise you need to adapt it

```
# User specific environment and startup programs

# For CMCC-CESM
CIME_MODEL='cesm'
export CIME_MACH='juno'
export CESMDATAROOT='/data/inputs/CESM'
export CESMEXP='cesm-exp'
export MODEL_PATH="/users_home/cmcc/${USER}/model"
export CESMDIR='cesm2.3_beta11_cm3_v7z'

#perl
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8


export DIVISION=csp
```



<h2>CONDA ENV:</h2>
To create a copy of an env (useful if you want to create an anvironment containing the pkgs for CESM and to run DA diagnostic)

1. ```module load anaconda/3-2022.10 ```

2. ```conda activate cmcc-cm_py39 ```

3. ```conda list --explicit```

4. save the list of packages in a txt file (pkg.txt)

5. ```conda create --name spreads --file  text.txt```

6. install the package you need
```
conda install -c conda-forge matplotlib cartopy sqlite pandas xarray rioxarray ecflow netcdf4 seaborn mpi scipy
```

7. Remember, if you do not have it, to create .condarc file in your home
```
channels:
  - conda-forge
  - defaults
env_prompt: ({name})
pkgs_dirs:
  - /work/cmcc/${USER}/.conda/pkgs
envs_dirs:
  - /work/cmcc/${USER}/.conda/envs

```

8. Remember to initialize your env the first time
```
conda init bash
```

<h2>SPREADS:</h2>
To compile SPREADS:
the first part (points 3 must be done just one time)
1. clone the repo
```git clone https://github.com/CMCC-Foundation/CMCC-DART.git spreads ```

2. ```cd spreads/d4o```

3.    ```source load-modules-d4o.juno```

4.  This point must be repeated just one time. Once you create the environment you need to source the env and recompile the single program as many time you want (remember to execute also the point 1).

     ```make juno COMPILER=INTEL NPES=32```

5.     
    ```source /data/cmcc/${USER}/d4o/install/INTEL/source.me ```

6. Enter in the directory containining the program you would like to compile:
    ```cd spreads/d4o/flattened/cam-fv/filter.dir```

7. ```make -j 8```

8. Repeat the last two steps also
   
   ```for spreads/d4o/flattened/cam-fv/fill_inflation_restart.dir```
   
    and
   
   ```/users_home/cmcc/gc02720/spreads/d4o/flattened/screening```

# How to create an experiment:
....


<h2>SQLITE:</h2>
Useful commands

```
module load sqlite/3.38.0

alias sqlite="sqlite3 -readonly -batch -init /dev/null -nullvalue NULL -box"
```

Then query like

```
sqlite amsua-dart.spreads.AMSU.1.2017-10-03-43200.db "select id,reportype,entryno,kind,(select distinct description from toc where kind=body.kind) as description,obsvalue,prior_mean,posterior_mean,qc,dart_qc,member,prior,posterior from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and entryno=body_entryno where description in ('EOS_2_AMSUA_TB','NOAA_15_AMSUA_TB','NOAA_19_AMSUA_TB')"
```


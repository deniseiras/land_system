#!/work/cmcc/mg20022/.conda/envs/guatura/bin/python
import glob
import pandas as pd
import sqlite3
import time
import os
import numpy as np
import shutil

#case_name = "CASE_NAME"
case_name = "arc2"

#DATAIN = f"/work/cmcc/mg20022/CMCC-CM/archive/{case_name}"
#DATAOUT = f"/work/cmcc/mg20022/CMCC-CM/basic_diag/{case_name}"
DATAIN = f"/work/cmcc/gc02720/CMCC-CM/archive/{case_name}"
DATAOUT = f"/work/cmcc/gc02720/CMCC-CM/basic_diag/{case_name}"

datas = [os.path.basename(x) for x in glob.glob(f"{DATAIN}/{case_name}-????-??-??-?????")]
datas.sort()
print(f"{datas} datas")
for dt in datas:

    start = time.time()

    data = dt.replace(f"{case_name}-", "")
    isExist = os.path.exists(f"{DATAOUT}/{data}/database.csv")
    if not isExist:
        
        df_temp = []
        for f in glob.glob(f"{DATAIN}/{case_name}-{data}/*db"):
            if 'catalog' not in f:
                print(f)
                try:
                    conn = sqlite3.connect(f"{f}", uri=True)
                    
                    dtemp = pd.read_sql("select id, reportype, entryno, kind, (select distinct description from toc where kind=body.kind) as description,\
                                    obsvalue, height, obs_error, prior_mean, prior_spread, posterior_mean, posterior_spread, levelht, deglat, deglon, dart_qc, member, body.status as bstatus, ens.status as ensstatus from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and entryno=body_entryno \
                                    where member=1 ", conn)
                    
                    dtemp['bias_prior'] = dtemp['obsvalue'] - dtemp['prior_mean']
                    dtemp['bias_posterior'] = dtemp['obsvalue'] - dtemp['posterior_mean']
                    dtemp['total_spread'] = np.sqrt(dtemp['prior_spread']**2 + dtemp['obs_error']**2)
                    dtemp['oi'] = dtemp['prior_spread']**2 / (dtemp['prior_spread']**2 + dtemp['obs_error']**2)
                    
                    if 'GPSRO' in f:
                        P0 = 1013
                        dtemp['levelht'] = P0*(1-dtemp['levelht']/44307.69396)**(1/0.190284)

                    df_temp.append(dtemp.copy())
                    # print(dtemp.head())
                    conn.close()
                except:
                    print(f"PROBLEM {f}")
                    #shutil.move(f"{f}",f"{f}_problem")
                # quit()
        df = pd.concat(df_temp, ignore_index=True)
        isExist = os.path.exists(f"{DATAOUT}/{data}")
        if not isExist:
            os.makedirs(f"{DATAOUT}/{data}")
        df.to_csv(f"{DATAOUT}/{data}/database.csv", index=False)
        print(f"DONE : {DATAOUT}/{data}/database.csv")
    else:
        print(f"SKIP : {DATAOUT}/{data}/database.csv")


    print(f"END1 : {time.time()-start}")

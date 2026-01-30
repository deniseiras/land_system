#!/work/cmcc/mg20022/.conda/envs/guatura/bin/python
import glob
import pandas as pd
import sqlite3
import time
import os
import numpy as np

case_name = "gio_ecflow1"

DATAIN = "/work/cmcc/gc02720/CMCC-CM/archive"
DATAOUT = f"/work/cmcc/gc02720/CMCC-CM/basic_diag/{case_name}"

datas = [os.path.basename(x) for x in glob.glob(f"{DATAOUT}/????-??-??-?????")]
datas.sort()
for dt in datas:

    start = time.time()

    data = dt.replace(f"{case_name}-", "")

    df_temp = []
    for f in glob.glob(f"{DATAIN}/{case_name}/{case_name}-{data}/*db"):
        if 'catalog' not in f:
            print(f)
            conn = sqlite3.connect(f"{f}", uri=True)
            
            
            dtemp = pd.read_sql("select id, reportype, entryno, kind, (select distinct description from toc where kind=body.kind) as description,\
                            obsvalue, height, obs_error, prior_mean, prior_spread, levelht, deglat, deglon,  dart_qc, member from hdr join body on id=body.hdr_id join ens on id=ens.hdr_id and entryno=body_entryno \
                            where member=1 ", conn)
            
            dtemp['bias'] = dtemp['obsvalue'] - dtemp['prior_mean']
            dtemp['total_spread'] = np.sqrt(dtemp['prior_spread']**2 + dtemp['obs_error']**2)
            dtemp['oi'] = dtemp['prior_spread']**2 / (dtemp['prior_spread']**2 + dtemp['obs_error']**2)
            df_temp.append(dtemp.copy())
            # print(dtemp.head())
            conn.close()
            # quit()
    df = pd.concat(df_temp, ignore_index=True)
    df.to_csv(f"{DATAOUT}/{data}/database.csv", index=False)

    print(f"END1 : {time.time()-start}")

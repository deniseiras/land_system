#!/usr/bin/env python3
import os
import requests
import pandas as pd
url ="https://oscar.wmo.int/surface/rest/api/search/station?facilityType=landFixed&programAffiliation=GOSGeneral,RBON,GBON,RBSN,RBSNp,RBSNs,RBSNsp,RBSNst,RBSNt,ANTON,ANTONt&variable=216&variable=224&variable=227&variable=256&variable=310&variable=12000"
print("Requesting from URL",url)
r = requests.get(url)
j = r.json();
result=j['stationSearchResults']
df_stations = pd.DataFrame.from_dict(result).set_index('id').sort_index()
df_stations.to_csv(r'synop_station_list.bsv', sep='|')

cmd="perl -pe 's/,/;/g; s/\|/,/g' < synop_station_list.bsv > synop_station_list.csv"
rc = os.system(cmd)

os.environ["TMPDIR"] = "."
cmd = "csv2sqlite synop_station_list.csv"
rc = os.system(cmd)

sqlite3cmd="sqlite3 -readonly -batch -init /dev/null -nullvalue NULL synop_station_list.db"

cmd=sqlite3cmd  + " -line " + "'select * from synop_station_list limit 1'"
rc = os.system(cmd)

cmd=sqlite3cmd  + " -box " + "'select cast(id as int) as id,name,region,territory,latitude as deglat,mod(longitude+360,360) as deglon,elevation as stalt,wigosId from synop_station_list order by 1 limit 10'"
rc = os.system(cmd)

cmd=sqlite3cmd  + " -box " + "'select cast(id as int) as id,name,region,territory,latitude as deglat,mod(longitude+360,360) as deglon,elevation as stalt,wigosId from synop_station_list order by 1 desc limit 10'"
rc = os.system(cmd)

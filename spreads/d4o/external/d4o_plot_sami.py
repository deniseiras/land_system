#!/usr/bin/env python3

import sqlite3
import pandas as pd
import matplotlib.pyplot as plt
import cartopy, cartopy.crs as ccrs
import cartopy.feature as cfeature
import matplotlib.colors as colors
# [('toc',), ('hdr',), ('sat',), ('body',), ('gpsro',), ('ens',)]

#conn = sqlite3.connect("ACAR.1.db", uri=True)
##conn = sqlite3.connect("source/TC1/ACAR.1.db", uri=True)
conn = sqlite3.connect("merge.db", uri=True)
cursor = conn.cursor()

#body = pd.read_sql_query("select * from body", conn)
#hdr = pd.read_sql_query("select * from hdr", conn)
#body = body.rename(columns={'hdr_id': 'id'})

#ds = pd.merge(hdr, body, on="id", how='left')

#ds = pd.read_sql_query("SELECT deglat,deglon,obsvalue,varno FROM hdr JOIN body ON id = hdr_id", conn)
#data = ds[ds['varno'] == 2 ] # t -- upper air temperature (K) -- see $ODB_SCHEMA_DIR/ecmwf_varno_descr.db

# varno = 2: t -- upper air temperature (K) -- see $ODB_SCHEMA_DIR/ecmwf_varno_descr.db :
#   sqlite3 -readonly -box $ODB_SCHEMA_DIR/ecmwf_varno_descr.db ".tables" "select * from ecmwf_varno_descr where varno = 2"
sql = """SELECT deglat,deglon,obsvalue FROM hdr JOIN body ON id = hdr_id
 WHERE varno = 2 AND obsvalue is NOT NULL and timeslot = 1"""

data = pd.read_sql_query(sql, conn)

fig, axes = plt.subplots(1,1, figsize=(10,4), subplot_kw={'projection': ccrs.PlateCarree()})

lons = data['deglon'].values
lats = data['deglat'].values
val =  data['obsvalue'].values
print(val)

#
print(len(val))
print(len(lons))
print(len(lats))
##quit()
figure = axes.scatter(lons, lats, c=val, cmap=plt.cm.jet, s=20)
axes.add_feature(cfeature.COASTLINE, alpha=0.7)
axes.set_extent([-180,180,-90,90])
plt.title(sql)
plt.colorbar(figure)
plt.tight_layout()
plt.show()

# or : reconstruct windforce (ff) from (u,v) -- the SQL is far from trivial
sql = """SELECT deglat,deglon,sqrt(u*u + v*v) as obsvalue FROM hdr
 JOIN (SELECT obsvalue AS u,hdr_id,levelht FROM body WHERE varno = 3 AND levelht is not NULL) as A ON id = A.hdr_id
 JOIN (SELECT  obsvalue AS v,hdr_id,levelht FROM body WHERE varno = 4 AND levelht is not NULL) as B ON id = B.hdr_id
 WHERE timeslot = 4 AND A.levelht = B.levelht AND u is not NULL AND v is not NULL"""

fig, axes = plt.subplots(1,1, figsize=(10,4), subplot_kw={'projection': ccrs.PlateCarree()})

lons = data['deglon'].values
lats = data['deglat'].values
val =  data['obsvalue'].values
print(val)

#
print(len(val))
print(len(lons))
print(len(lats))
##quit()
figure = axes.scatter(lons, lats, c=val, cmap=plt.cm.jet, s=20)
axes.add_feature(cfeature.COASTLINE, alpha=0.7)
axes.set_extent([-180,180,-90,90])
plt.title(sql)
plt.colorbar(figure)
plt.tight_layout()
plt.show()

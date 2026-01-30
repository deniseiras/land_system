more create_new.sh
#!/bin/bash
#
yfirst=2015
ylast=2020
for yy in {2015..2020};
do
  for mm in {01..12}
  do

  for kk in {04..30}
  do
  fname=user_nl_datm_streams_00${kk}

echo "CLMCRUNCEPv7.Solar:meshfile=${FILE2}"  >> ${fname}
cat<<EOF>user_nl_datm_streams_00${kk}
!------------------------------------------------------------------------"  >> ${fname}
! This file is used to modify datm.streams.xml generated in $RUNDIR"  >> ${fname}
! Entries should have the form"  >> ${fname}
!  <streamname>:<stream_variable>= <new stream_value> (NO Quotes!!!)"  >> ${fname}
! The following are accepted values for a stream named foo"  >> ${fname}
!  foo:meshfile = character string"  >> ${fname}
!  foo:datafiles = comma separated string of full pathnames (e.g. file1,file2,file3...)"  >> ${fname}
!  foo:datavars = comma separated string of field pairs  (e.g. foo foobar,foo2 foobar2...)"  >> ${fname}
!  foo:taxmode = one of [cycle, extend, limit]"  >> ${fname}
!  foo:tintalgo = one of [lower,upper,nearest,linear,coszen]"  >> ${fname}
!  foo:readmode = single (only suported mode right now)"  >> ${fname}
!  foo:mapalgo = one of [bilinear,redist,nn,consf,consd,none]"  >> ${fname}
!  foo:dtlimit = real (1.5 is default)"  >> ${fname}
!  foo:year_first = integer"  >> ${fname}
!  foo:year_last = integer"  >> ${fname}
!  foo:year_align = integer"  >> ${fname}
!  foo:vectors = null or the names of the vector fields in the model (i.e. Sa_u:Sa_v)"  >> ${fname}
!  foo:lev_dimname: = one of [null,name of level dimenion name]"  >> ${fname}
!  foo:offset = integer"  >> ${fname}
! As an example:"  >> ${fname}
!   foo:year_first = 1950"  >> ${fname}
! would change the stream year_first stream_entry to 1950 for the foo stream block"  >> ${fname}
! NOTE: multi-line inputs are enabled by adding a \ at the end of the line"  >> ${fname}
! As an emaple:"  >> ${fname}
! foo:datafiles=foo1,foo2, \"  >> ${fname}
!     foo3"  >> ${fname}
! Will yield the following new entry for datafiles in stream foo"  >> ${fname}
!   <datafiles>"  >> ${fname}
!      <file>foo1</file>"  >> ${fname}
!      <file>foo2</file>"  >> ${fname}
!      <file>foo3</file>"  >> ${fname}
!   </datafiles>"  >> ${fname}
!------------------------------------------------------------------------"  >> ${fname}
presaero.hist:datafiles=/data/inputs/CESM/inputdata/atm/cam/chem/trop_mozart_aero/aero/aerosoldep_WACCM.ensmean_monthly_hist_1849-2015_0.9x1.25_CMIP6_c180926.nc"  >> ${fname}
presaero.hist:taxmode=cycle"  >> ${fname}
presaero.hist:tintalgo=linear"  >> ${fname}
presaero.hist:readmode=single"  >> ${fname}
presaero.hist:mapalgo=bilinear"  >> ${fname}
presaero.hist:dtlimit=1.5"  >> ${fname}
presaero.hist:year_first=${yfirst}"  >> ${fname}
presaero.hist:year_last=${ylast}"  >> ${fname}
presaero.hist:year_align=${yfirst}"  >> ${fname}
presaero.hist:vectors=null
presaero.hist:lev_dimname=null
presaero.hist:meshfile=/data/inputs/CESM/inputdata/share/meshes/fv0.9x1.25_141008_polemod_ESMFmesh.nc
presaero.hist:datavars=  BCDEPWET   Faxa_bcphiwet,\
      BCPHODRY   Faxa_bcphodry,\
      BCPHIDRY   Faxa_bcphidry,\
      OCDEPWET   Faxa_ocphiwet,\
      OCPHIDRY   Faxa_ocphidry,\
      OCPHODRY   Faxa_ocphodry,\
      DSTX01WD   Faxa_dstwet1,\
      DSTX01DD   Faxa_dstdry1,\
      DSTX02WD   Faxa_dstwet2,\
      DSTX02DD   Faxa_dstdry2,\
      DSTX03WD   Faxa_dstwet3,\
      DSTX03DD   Faxa_dstdry3,\
      DSTX04WD   Faxa_dstwet4,\
      DSTX04DD   Faxa_dstdry4
presaero.hist:offset=0


CLMGSWP3v1.Solar:taxmode=cycle
CLMGSWP3v1.Solar:tintalgo=coszen
CLMGSWP3v1.Solar:readmode=single
CLMGSWP3v1.Solar:mapalgo=bilinear
CLMGSWP3v1.Solar:dtlimit=1.5
CLMGSWP3v1.Solar:year_first=1960
CLMGSWP3v1.Solar:year_last=2001
CLMGSWP3v1.Solar:year_align=1960
CLMGSWP3v1.Solar:vectors=null
CLMGSWP3v1.Solar:lev_dimname=null
CLMGSWP3v1.Solar:meshfile=/data/inputs/CESM/inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516/clmforc.GSWP3.c2011.0.5x0.5.TPQWL.SCRIP.210520_ESMFmesh.nc
CLMGSWP3v1.Solar:datafiles= /work/cmcc/lg07622/land/forcing/EDA/forcDIReda/EDA_n4/Solar/clmforc.EDA4.0.5d.Solr.2000-12.nc,\
                     /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Solar/clmforc.EDA4.0.5d.Solr.2001-01.nc,\
                     /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Solar/clmforc.EDA4.0.5d.Solr.2001-02.nc,\
                     /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Solar/clmforc.EDA4.0.5d.Solr.2001-03.nc,\
                     /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Solar/clmforc.EDA4.0.5d.Solr.2001-04.nc,\
                     /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Solar/clmforc.EDA4.0.5d.Solr.2001-05.nc,\
                     /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Solar/clmforc.EDA4.0.5d.Solr.2001-06.nc,\
                     /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Solar/clmforc.EDA4.0.5d.Solr.2001-07.nc,\
                     /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Solar/clmforc.EDA4.0.5d.Solr.2001-08.nc,\
                     /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Solar/clmforc.EDA4.0.5d.Solr.2001-09.nc,\
                     /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Solar/clmforc.EDA4.0.5d.Solr.2001-10.nc,\
                     /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Solar/clmforc.EDA4.0.5d.Solr.2001-11.nc,\
                     /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Solar/clmforc.EDA4.0.5d.Solr.2001-12.nc

CLMGSWP3v1.Solar:datavars=FSDS     Faxa_swdn
CLMGSWP3v1.Solar:offset=0


CLMGSWP3v1.Precip:taxmode=cycle
CLMGSWP3v1.Precip:tintalgo=nearest
CLMGSWP3v1.Precip:readmode=single
CLMGSWP3v1.Precip:mapalgo=bilinear
CLMGSWP3v1.Precip:dtlimit=1.5
CLMGSWP3v1.Precip:year_first=1960
CLMGSWP3v1.Precip:year_last=2001
CLMGSWP3v1.Precip:year_align=1960
CLMGSWP3v1.Precip:vectors=null
CLMGSWP3v1.Precip:lev_dimname=null
CLMGSWP3v1.Precip:meshfile=/data/inputs/CESM/inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516/clmforc.GSWP3.c2011.0.5x0.5.TPQWL.SCRIP.210520_ESMFmesh.nc
CLMGSWP3v1.Precip:datafiles= /work/cmcc/lg07622/land/forcing/EDA/forcDIReda/EDA_n4/Precip/clmforc.EDA4.0.5d.Prec.2000-12.nc,\
                             /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Precip/clmforc.EDA4.0.5d.Prec.2001-01.nc,\
                             /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Precip/clmforc.EDA4.0.5d.Prec.2001-02.nc,\
                             /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Precip/clmforc.EDA4.0.5d.Prec.2001-03.nc,\
                             /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Precip/clmforc.EDA4.0.5d.Prec.2001-04.nc,\
                             /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Precip/clmforc.EDA4.0.5d.Prec.2001-05.nc,\
                             /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Precip/clmforc.EDA4.0.5d.Prec.2001-06.nc,\
                             /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Precip/clmforc.EDA4.0.5d.Prec.2001-07.nc,\
                             /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Precip/clmforc.EDA4.0.5d.Prec.2001-08.nc,\
                             /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Precip/clmforc.EDA4.0.5d.Prec.2001-09.nc,\
                             /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Precip/clmforc.EDA4.0.5d.Prec.2001-10.nc,\
                             /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Precip/clmforc.EDA4.0.5d.Prec.2001-11.nc,\
                             /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/Precip/clmforc.EDA4.0.5d.Prec.2001-12.nc
                            

CLMGSWP3v1.Precip:datavars=PRECTmms Faxa_precn
CLMGSWP3v1.Precip:offset=0


CLMGSWP3v1.TPQW:taxmode=cycle
CLMGSWP3v1.TPQW:tintalgo=linear
CLMGSWP3v1.TPQW:readmode=single
CLMGSWP3v1.TPQW:mapalgo=bilinear
CLMGSWP3v1.TPQW:dtlimit=1.5
CLMGSWP3v1.TPQW:year_first=1960
CLMGSWP3v1.TPQW:year_last=2001
CLMGSWP3v1.TPQW:year_align=1960
CLMGSWP3v1.TPQW:vectors=null
CLMGSWP3v1.TPQW:lev_dimname=null
CLMGSWP3v1.TPQW:meshfile=/data/inputs/CESM/inputdata/atm/datm7/atm_forcing.datm7.GSWP3.0.5d.v1.c170516/clmforc.GSWP3.c2011.0.5x0.5.TPQWL.SCRIP.210520_ESMFmesh.nc
CLMGSWP3v1.TPQW:datafiles= /work/cmcc/lg07622/land/forcing/EDA/forcDIReda/EDA_n4/TPHWL/clmforc.EDA4.0.5d.TPQWL.2000-12.nc,\
                           /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/TPHWL/clmforc.EDA4.0.5d.TPQWL.2001-01.nc,\
                           /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/TPHWL/clmforc.EDA4.0.5d.TPQWL.2001-02.nc,\
                           /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/TPHWL/clmforc.EDA4.0.5d.TPQWL.2001-03.nc,\
                           /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/TPHWL/clmforc.EDA4.0.5d.TPQWL.2001-04.nc,\
                           /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/TPHWL/clmforc.EDA4.0.5d.TPQWL.2001-05.nc,\
                           /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/TPHWL/clmforc.EDA4.0.5d.TPQWL.2001-06.nc,\
                           /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/TPHWL/clmforc.EDA4.0.5d.TPQWL.2001-07.nc,\
                           /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/TPHWL/clmforc.EDA4.0.5d.TPQWL.2001-08.nc,\
                           /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/TPHWL/clmforc.EDA4.0.5d.TPQWL.2001-09.nc,\
                           /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/TPHWL/clmforc.EDA4.0.5d.TPQWL.2001-10.nc,\
                           /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/TPHWL/clmforc.EDA4.0.5d.TPQWL.2001-11.nc,\
                           /work/cmcc/spreads-lnd/work/EDA/forcDIReda/EDA_n4/TPHWL/clmforc.EDA4.0.5d.TPQWL.2001-12.nc
                          

CLMGSWP3v1.TPQW:datavars=TBOT     Sa_tbot,\
      WIND     Sa_wind,\
      QBOT     Sa_shum,\
      PSRF     Sa_pbot
CLMGSWP3v1.TPQW:offset=0


presndep.hist:datafiles=/data/inputs/CESM/inputdata/lnd/clm2/ndepdata/fndep_clm_hist_b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.ensmean_1849-2015_monthly_0.9x1.25_c180926.nc
presndep.hist:taxmode=cycle
presndep.hist:tintalgo=linear
presndep.hist:readmode=single
presndep.hist:mapalgo=bilinear
presndep.hist:dtlimit=1.5
presndep.hist:year_first=1849
presndep.hist:year_last=2001
presndep.hist:year_align=1849
presndep.hist:vectors=null
presndep.hist:lev_dimname=null
presndep.hist:meshfile=/data/inputs/CESM/inputdata/share/meshes/fv0.9x1.25_141008_polemod_ESMFmesh.nc
presndep.hist:datavars=NDEP_NHx_month    Faxa_ndep_nhx,\
          NDEP_NOy_month    Faxa_ndep_noy
presndep.hist:offset=0

preso3.hist:datafiles=/data/inputs/CESM/inputdata/cdeps/datm/ozone/O3_surface.f09_g17.CMIP6-historical-WACCM.001.monthly.185001-201412.nc
preso3.hist:taxmode=cycle
preso3.hist:tintalgo=linear
preso3.hist:readmode=single
preso3.hist:mapalgo=bilinear
preso3.hist:dtlimit=1.5
preso3.hist:year_first=1850
preso3.hist:year_last=2001
preso3.hist:year_align=1850
preso3.hist:vectors=null
preso3.hist:lev_dimname=null
preso3.hist:meshfile=/data/inputs/CESM/inputdata/share/meshes/fv0.9x1.25_141008_polemod_ESMFmesh.nc
preso3.hist:datavars= O3  Sa_o3
preso3.hist:offset=0


co2tseries.20tr:datafiles=/data/inputs/CESM/inputdata/atm/datm7/CO2/fco2_datm_global_simyr_1750-2014_CMIP6_c180929.nc
co2tseries.20tr:taxmode=extend
co2tseries.20tr:tintalgo=linear
co2tseries.20tr:readmode=single
co2tseries.20tr:mapalgo=none
co2tseries.20tr:dtlimit=1.e30
co2tseries.20tr:year_first=1850
co2tseries.20tr:year_last=2001
co2tseries.20tr:year_align=1850
co2tseries.20tr:vectors=null
co2tseries.20tr:lev_dimname=null
co2tseries.20tr:meshfile=none
co2tseries.20tr:datavars=CO2   Sa_co2diag
co2tseries.20tr:offset=0

EOF



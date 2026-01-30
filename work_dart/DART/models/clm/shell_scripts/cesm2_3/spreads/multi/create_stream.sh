#!/bin/bash
#
year_first=2000
year_last=2010

filename=datm.streams.txt.CLMCRUNCEPv7.TPQW.${year_first}_${year_last}
if [ -f ${filename} ]; then rm -f $filename; fi
echo "<?xml version="\""1.0"\""?>" >> $filename
echo "<file id="\""stream"\"" version="\""1.0"\"">" >> $filename
echo "<dataSource>" >> $filename
echo "   GENERIC" >> $filename
echo "</dataSource>" >> $filename
echo "<domainInfo>" >> $filename
echo "  <variableNames>" >> $filename
echo "     time    time" >> $filename
echo "        xc      lon" >> $filename
echo "        yc      lat" >> $filename
echo "        mask    mask" >> $filename
echo "        area    area" >> $filename
echo "  </variableNames>" >> $filename
echo "  <filePath>" >> $filename
echo "     /data/inputs/CESM/inputdata/share/domains/domain.clm" >> $filename
echo "  </filePath>" >> $filename
echo "  <fileNames>" >> $filename
echo "     domain.lnd.360x720.130305.nc" >> $filename
echo "  </fileNames>" >> $filename
echo "</domainInfo>" >> $filename
echo "<fieldInfo>" >> $filename
echo "   <variableNames>" >> $filename
echo "     TBOT     tbot" >> $filename
echo "        WIND     wind" >> $filename
echo "        QBOT     shum" >> $filename
echo "        PSRF     pbot" >> $filename
echo "   </variableNames>" >> $filename
echo "   <filePath>" >> $filename
echo "	   /work/cmcc/lg07622/land/forcing/ERA5/spreads80/TPHWL6Hrly" >> $filename
echo "   </filePath>" >> $filename
echo "   <fileNames>" >> $filename
yy=$year_first
while [ $yy -le $year_last ];
do
  for mm in {01..12}
  do
    echo "    clmforc.NINST.0.5d.TPQWL.${yy}-${mm}.nc" >> $filename
  done  
  yy=$(( $yy + 1 ))
done
echo "   </fileNames>" >> $filename
echo "   <offset>" >> $filename
echo "      0" >> $filename
echo "   </offset>" >> $filename
echo "</fieldInfo>" >> $filename
echo "</file>" >> $filename

filename=datm.streams.txt.CLMCRUNCEPv7.Solar.${year_first}_${year_last}
if [ -f ${filename} ]; then rm -f $filename; fi
echo "<?xml version="\""1.0"\""?>" >> $filename
echo "<file id="\""stream"\"" version="\""1.0"\"">" >> $filename
echo "<dataSource>" >> $filename
echo "   GENERIC" >> $filename
echo "</dataSource>" >> $filename
echo "<domainInfo>" >> $filename
echo "  <variableNames>" >> $filename
echo "     time    time" >> $filename
echo "        xc      lon" >> $filename
echo "        yc      lat" >> $filename
echo "        mask    mask" >> $filename
echo "        area    area" >> $filename
echo "  </variableNames>" >> $filename
echo "  <filePath>" >> $filename
echo "     /data/inputs/CESM/inputdata/share/domains/domain.clm" >> $filename
echo "  </filePath>" >> $filename
echo "  <fileNames>" >> $filename
echo "     domain.lnd.360x720.130305.nc" >> $filename
echo "  </fileNames>" >> $filename
echo "</domainInfo>" >> $filename
echo "<fieldInfo>" >> $filename
echo "   <variableNames>" >> $filename
echo "     FSDS swdn" >> $filename
echo "   </variableNames>" >> $filename
echo "   <filePath>" >> $filename
echo "	   /work/cmcc/lg07622/land/forcing/ERA5/spreads80/Solar6Hrly" >> $filename
echo "   </filePath>" >> $filename
echo "   <fileNames>" >> $filename
yy=$year_first
while [ $yy -le $year_last ];
do
  for mm in {01..12}
  do
    echo "    clmforc.NINST.0.5d.Solr.${yy}-${mm}.nc" >> $filename
  done  
  yy=$(( $yy + 1 ))
done
echo "   </fileNames>" >> $filename
echo "   <offset>" >> $filename
echo "      0" >> $filename
echo "   </offset>" >> $filename
echo "</fieldInfo>" >> $filename
echo "</file>" >> $filename
##


filename=datm.streams.txt.CLMCRUNCEPv7.Precip.${year_first}_${year_last}
if [ -f ${filename} ]; then rm -f $filename; fi
echo "<?xml version="\""1.0"\""?>" >> $filename
echo "<file id="\""stream"\"" version="\""1.0"\"">" >> $filename
echo "<dataSource>" >> $filename
echo "   GENERIC" >> $filename
echo "</dataSource>" >> $filename
echo "<domainInfo>" >> $filename
echo "  <variableNames>" >> $filename
echo "     time    time" >> $filename
echo "        xc      lon" >> $filename
echo "        yc      lat" >> $filename
echo "        mask    mask" >> $filename
echo "        area    area" >> $filename
echo "  </variableNames>" >> $filename
echo "  <filePath>" >> $filename
echo "     /data/inputs/CESM/inputdata/share/domains/domain.clm" >> $filename
echo "  </filePath>" >> $filename
echo "  <fileNames>" >> $filename
echo "     domain.lnd.360x720.130305.nc" >> $filename
echo "  </fileNames>" >> $filename
echo "</domainInfo>" >> $filename
echo "<fieldInfo>" >> $filename
echo "   <variableNames>" >> $filename
echo "     PRECTmms precn" >> $filename
echo "   </variableNames>" >> $filename
echo "   <filePath>" >> $filename
echo "	   /work/cmcc/lg07622/land/forcing/ERA5/spreads80/Precip6Hrly" >> $filename
echo "   </filePath>" >> $filename
echo "   <fileNames>" >> $filename
yy=$year_first
while [ $yy -le $year_last ];
do
  for mm in {01..12}
  do
    echo "    clmforc.NINST.0.5d.Prec.${yy}-${mm}.nc" >> $filename
  done  
  yy=$(( $yy + 1 ))
done
echo "   </fileNames>" >> $filename
echo "   <offset>" >> $filename
echo "      0" >> $filename
echo "   </offset>" >> $filename
echo "</fieldInfo>" >> $filename
echo "</file>" >> $filename



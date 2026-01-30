* ECMWF ODB governance (as of 11-12 of April 2022) from https://apps.ecmwf.int/odbgov/

* Originally semi-colon separated columns stored into .csv-files

* Changed to TAB-separated .tsv-files

* Also each "==" followed by a number changed to "equal to" followed by (that) number
  -- or Excel/LibreOffice misinterprets and issues an error

* The filtering command sequence from csv to tsv:

for f in ~/downloads/apps.ecmwf.int_odbgov_*.csv
do
  ff=$(echo $f | perl -pe 's/^.*_(odbgov)/$1/; s/\.csv/.tsv/')
  echo "$f to $ff"
  perl -pe 's/;/\t/g; s/==(\d+)/equal to $1/g' < $f > $ff
done

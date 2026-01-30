# Create ODC database from (ECMWF) BUFR
../install/bin/b2o bufrfile -o foobar.odc

# Create CSV-file from contents of the ODC database
#../install/eckit/bin/odc sql "select *" -i foobar.odc --full_precision --no_alignment -delimiter ,|perl -pe 's/-2147483647\b/NULL/g' > foobar.csv
../install/eckit/bin/odc sql "select *" -i foobar.odc --full_precision --no_alignment -delimiter "," -o foobar.csv -f ascii

# Number of columns
head -n1 foobar.csv|perl -pe 's/,/\n/g'|wc -l

# Number of rows
echo $(("$(cat foobar.csv | wc -l)-1"))

# Data layout
../install/eckit/bin/odc header [-i] foobar.odc | grep -P '^\d+\.\s+name:\s+' # Most useful !
../install/eckit/bin/odc header | grep -P '^\d+\.\s+name:\s+' | wc -l # also the number of columns
../install/eckit/bin/odc header -ddl -i foobar.odc
../install/eckit/bin/odc header -ddl -table barfoo -i foobar.odc

# Number of rows
../install/eckit/bin/odc count [-i] foobar.odc

# Show file contents (not much use since sql "select *" more powerful)
../install/eckit/bin/odc ls -i foobar.odc -o foobar.txt

# General help
../install/eckit/bin/odc help
../install/eckit/bin/odc help sql # e.g. help for sql subcommand syntax






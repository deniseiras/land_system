#!/bin/bash

for file in user_nl_datm_streams_????; do
  sed -i 's/preso3.hist:year_first=2014/preso3.hist:year_first=2015/' "$file"
  sed -i 's/preso3.hist:year_align=2014/preso3.hist:year_align=2015/' "$file"
done

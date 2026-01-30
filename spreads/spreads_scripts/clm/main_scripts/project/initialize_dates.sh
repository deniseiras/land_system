#!/bin/bash

# Initialize dates for each member based on CONTINUE_RUN status

if [ "$CONT_RUN" = "FALSE" ]; then
    datevar=$(grep ice_ic user_nl_cice | awk '{print $3}')
else
    datevar=$(cut -d'/' -f2 </work/cmcc/${USER}/CMCC-CM/${case_name}_0001/run/rpointer.ice)
fi

# Parse date variables
datevar=$(cut -d'.' -f4 <<<"$datevar")
y=$(cut -d'-' -f1 <<<"$datevar")
m=$(cut -d'-' -f2 <<<"$datevar")
d=$(cut -d'-' -f3 <<<"$datevar")
s=$(cut -d'-' -f4 <<<"$datevar")

# Update date values in user_nl_cice file
if grep -q "sec_init" user_nl_cice; then
    sed -i -e "s/sec_init=.*/sec_init=$s/g" user_nl_cice
else
    echo "sec_init=$s" >> user_nl_cice
fi

if grep -q "day_init" user_nl_cice; then
    sed -i -e "s/day_init=.*/day_init=$d/g" user_nl_cice
else
    echo "day_init=$d" >> user_nl_cice
fi

if grep -q "month_init" user_nl_cice; then
    sed -i -e "s/month_init=.*/month_init=$m/g" user_nl_cice
else
    echo "month_init=$m" >> user_nl_cice
fi

if grep -q "year_init" user_nl_cice; then
    sed -i -e "s/year_init=.*/year_init=$y/g" user_nl_cice
else
    echo "year_init=$y" >> user_nl_cice
fi

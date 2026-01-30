#!/bin/bash

get_last_day_and_previous_month() {
    current_year=$1
    current_month=$2

    # Subtract 1 from the current month to get the previous month
    previous_month=$((current_month - 1))

    # Handle the case when the current month is January (previous month is December of the previous year)
    if [ $previous_month -eq 0 ]; then
        previous_month=12
        current_year=$((current_year - 1))
    fi

    # Get the last day of the previous month
    last_day=$(date -d "$current_year-$previous_month-01 +1 month -1 day" +'%d')

    # Assign the values to an array
    echo "$last_day $previous_month"
}


# Usage example:
#current_year=$(date +'%Y')
#current_month=$(date +'%m')

EVENT=201711
YYYY=`echo $EVENT | cut -c1-4`
MM=`echo $EVENT | cut -c5-6`
current_year=$YYYY
current_month=$MM



result_array=($(get_last_day_and_previous_month $current_year $current_month))

# Access the values from the array
last_day_of_previous_month="${result_array[0]}"
previous_month="${result_array[1]}"

echo "Last day of the previous month: $last_day_of_previous_month"
echo "Previous month: $previous_month"


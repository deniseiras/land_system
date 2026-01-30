#!/bin/bash

START_DATE="2017-10-02-43200"
END_DATE="2017-10-06-43200"

date="2017-10-01-43200"

if [[ "$date" > "${START_DATE}" && "$date" < "${END_DATE}" || "$date" == "${START_DATE}" || "$date" == "${END_DATE}" ]]; then
    	echo $date
fi



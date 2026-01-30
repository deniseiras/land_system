#!/bin/bash

for DD in "08" "09" "10" "11"; do
  if [ "${DD#0}" -gt 10 ]; then
    DDP=$((10#${DD}-1))
  else
    DDP=$(printf "%02d" $((10#${DD}-1)))
  fi

  echo "DDP: ${DDP}"
done


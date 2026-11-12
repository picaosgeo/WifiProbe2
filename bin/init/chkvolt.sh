#!/bin/bash

# Bit   Meaning
# 0     Under-voltage detected
# 1     Arm frequency capped
# 2     Currently throttled
# 3     Soft temperature limit active
# 16    Under-voltage has occurred
# 17    Arm frequency capped has occurred
# 18    Throttling has occurred
# 19    Soft temperature limit has occurred


while true; do
  ./checkthrottled.sh
  sleep 10s
done

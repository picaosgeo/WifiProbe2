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

STAT=`vcgencmd get_throttled`
STAT=${STAT#throttled=}

if [ "$STAT" = "" ]; then
    echo "Unexpected output."
    exit 1
fi

if [ "$(($STAT & 0x04))" != "0" ]; then
    echo -n $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S')  "Throttled due to"
    [ "$(($STAT & 0x01))" != "0" ] && echo -n " under-voltage"
    [ "$(($STAT & 0x02))" != "0" ] && echo -n " frequency cap"
    [ "$(($STAT & 0x08))" != "0" ] && echo -n " temperature limit"
    echo "."
    exit 2 # Critical
elif [ "$(($STAT & 0x040000))" != "0" ]; then
    echo -n $(TZ=UTC-9 date '+%Y-%m-%d %H:%M:%S')  "Recovered from"
    [ "$(($STAT & 0x010000))" != "0" ] && echo -n " under-voltage"
    [ "$(($STAT & 0x020000))" != "0" ] && echo -n " frequency cap"
    [ "$(($STAT & 0x080000))" != "0" ] && echo -n " temperature limit"
    echo "."
    exit 1 # Warning
else
    echo "OK. No throttling has been occurred."
fi

exit 0

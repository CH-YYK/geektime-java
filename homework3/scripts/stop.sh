#!/bin/sh

pid=`ps ax | grep -i 'hero' | grep java | grep -v grep | awk '{print $1}'`
if [ -z "$pid" ] ;
then
    echo "No hero running."
else
    echo "The hero(${pid}) is running..."
    kill -9 ${pid}
    echo "Send shutdown request to heroServer(${pid}) OK"
fi

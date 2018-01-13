#!/bin/bash

if [ "$(id -u)" != "0" ]
then
    echo "Please run this script as root."
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR

while read FROM_FILE; do
    TO_FILE=$(echo $FROM_FILE | sed -e "s|^\.||")

    TARGET_DIR=$(dirname $TO_FILE)
    if [ ! -d $TARGET_DIR ]
    then
        echo "mkdir -p $TARGET_DIR"
        mkdir -p $TARGET_DIR
    fi

    echo "cp -f $FROM_FILE $TO_FILE"
    \cp -f $FROM_FILE $TO_FILE
done < <(find . -type f ! -name Deploy.sh ! -name *.swp)

systemctl daemon-reload
update-alternatives --install /usr/bin/altdocker altdocker /usr/local/bin/altdocker/altdocker 10


#!/bin/bash

SELF_PATH=$(dirname $(readlink -f $0))
PROJECT_NAME=$(basename $SELF_PATH)
PROJECT_VERSION=`awk 'match($0, "VERSION = \"(.*)\"", m) { print m[1] }' version.php`

echo docker build $PROJECT_NAME v$PROJECT_VERSION

docker build -t $PROJECT_NAME:v$PROJECT_VERSION .

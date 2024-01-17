#!/bin/bash
set -e
PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

GPFDIST_PORT=$1
GEN_DATA_PATH=$2

# to use gpfdist we should source additional variables
for profile_filename in ~/.bashrc ~/.profile ~/.bash_profile
do
		if [ -f "$profile_filename" ]; then
			# don't fail if an error is happening in the admin's profile
			source "$profile_filename" || true
		fi
done

gpfdist -p $GPFDIST_PORT -d $GEN_DATA_PATH > gpfdist.$GPFDIST_PORT.log 2>&1 < gpfdist.$GPFDIST_PORT.log &
pid=$!

if [ "$pid" -ne "0" ]; then
	sleep .4
	count=$(ps -ef 2> /dev/null | grep -v grep | awk -F ' ' '{print $2}' | grep $pid | wc -l)
	if [ "$count" -eq "1" ]; then
		echo "Started gpfdist on port $GPFDIST_PORT"
	else
		echo "Unable to start gpfdist on port $GPFDIST_PORT"
		exit 1
	fi
else
	echo "Unable to start background process for gpfdist on port $GPFDIST_PORT"
	exit 1
fi


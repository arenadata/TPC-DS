# script run_one.sh ------ запуск одной итерации цикла с сохранением вспомогательной информации -----------
#!/bin/bash
source ~/.bash_profile

TYPE_TEST=$1
MULTI_USER_COUNT=$2
FNAME="tpcds_variables.sh"
DBNAME="gpperfmon"
INTERVAL="+ interval '0 hour'"
IDSQL="select max(id) from tpcds_runs;"
IDPREFFIX=$(sudo -u gpadmin /usr/lib/gpdb/bin/psql -d $DBNAME -AXqtc "$IDSQL")
let "IDPREFFIX++"
TESTNAME=$TYPE_TEST"_mtu$(ip a | grep eth0 | grep mtu | awk '{print $5}')"

echo "TESTNAME = " $TESTNAME
echo "MULTI_USER_COUNT = " $MULTI_USER_COUNT

DIR="logs__con"$MULTI_USER_COUNT"_$(date +%Y%m%d_%H%M%S)"

if [ "$TYPE_TEST" == "" ]; then
    echo "Error: you must provide the TYPE_TEST as parameter."
    echo "Example: ./run_one.sh lite 2  "
    exit 1
fi

if [ "$MULTI_USER_COUNT" == "" ]; then
    echo "Error: you must provide the MULTI_USER_COUNT as parameter."
    echo "Example: ./run_one.sh lite 2 "
    exit 1
fi

# make new dir for logs
mkdir $DIR

# replace sting with MULTI_USER_COUNT
sed -i "s/MULTI_USER_COUNT=.*/MULTI_USER_COUNT=\"$MULTI_USER_COUNT\"/g" $FNAME

# logging start time for report in gpperfmon
sudo -u gpadmin /usr/lib/gpdb/bin/psql -d $DBNAME -c "insert into public.tpcds_runs values ($IDPREFFIX, $MULTI_USER_COUNT, '$TESTNAME', current_timestamp $INTERVAL)"

bash tpcds.sh $TYPE_TEST | tee -a $DIR/tpcds.log

# get ttt
ttt=$(cat $DIR/tpcds.log |  awk '/TTT/ {print $2}')
ttt=${ttt:-0}

# get real multi user test start time
multiuser_start_time=$(date -r /arenadata/TPC-DS/07_multi_user/1 +"%F %T.%6N")

# logging real sql-start time abd end time for report in gpperfmon
sql="update public.tpcds_runs set endtime = current_timestamp $INTERVAL, ttt= '$ttt', multi_user_test_start='$multiuser_start_time'::timestamp $INTERVAL where id = $IDPREFFIX and endtime is null"
sudo -u gpadmin /usr/lib/gpdb/bin/psql -d $DBNAME -c "$sql"

# copy logs for backup
cp /arenadata/TPC-DS/log/*.log $DIR

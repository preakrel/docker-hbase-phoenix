#!/bin/bash


HBASE_SITE="/opt/hbase/conf/hbase-site.xml"

addConfig () {

    if [ $# -ne 3 ]; then
        echo "There should be 3 arguments to addConfig: <file-to-modify.xml>, <property>, <value>"
        echo "Given: $@"
        exit 1
    fi

    xmlstarlet ed -L -s "/configuration" -t elem -n propertyTMP -v "" \
     -s "/configuration/propertyTMP" -t elem -n name -v $2 \
     -s "/configuration/propertyTMP" -t elem -n value -v $3 \
     -r "/configuration/propertyTMP" -v "property" \
     $1
}

addConfig $HBASE_SITE "hbase.regionserver.wal.codec" "org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec"
addConfig $HBASE_SITE "hbase.region.server.rpc.scheduler.factory.class" "org.apache.hadoop.hbase.ipc.PhoenixRpcSchedulerFactory"
addConfig $HBASE_SITE "hbase.rpc.controllerfactory.class" "org.apache.hadoop.hbase.ipc.controller.ServerRpcControllerFactory"
addConfig $HBASE_SITE "hbase.unsafe.stream.capability.enforce" "false"
addConfig $HBASE_SITE "data.tx.snapshot.dir" "/tmp/tephra/snapshots"
addConfig $HBASE_SITE "data.tx.timeout" "60"
addConfig $HBASE_SITE "phoenix.transactions.enabled" true
addConfig $HBASE_SITE "phoenix.connection.autoCommit" true
addConfig $HBASE_SITE "phoenix.schema.isNamespaceMappingEnabled" "false"
addConfig $HBASE_SITE "phoenix.queryserver.serialization" "JSON"

: ${HADOOP_PREFIX:=/opt/hadoop}
: ${ZOO_HOME:=/opt/zookeeper}
: ${HBASE_HOME:=/opt/hbase}
: ${PHOENIX_HOME:=/opt/phoenix}

rm /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -


function clean_up {
    $HBASE_HOME/bin/stop-hbase.sh
    $PHOENIX_HOME/bin/queryserver.py stop
    $HBASE_HOME/hbase/bin/tephra stop

    exit
}

trap clean_up SIGINT SIGTERM

service sshd start
$HADOOP_PREFIX/sbin/start-dfs.sh
$HADOOP_PREFIX/sbin/start-yarn.sh
$ZOO_HOME/bin/zkServer.sh start
$HBASE_HOME/bin/start-hbase.sh

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi

if [[ $1 == "-sqlline" ]]; then
  /opt/phoenix/hadoop2/bin/sqlline.py localhost
fi

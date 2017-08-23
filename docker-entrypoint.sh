#!/bin/bash

set -e
cd ${MIST_HOME}

if [ "$1" = 'mist' ]; then
  export IP=`ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`

  export JAVA_OPTS="$JAVA_OPTS -Dmist.cluster.host=$IP"
  shift
  exec ./bin/mist-master start --config /usr/share/external_configs/pca-mist.conf --router-config /usr/share/external_configs/router-pca-mist.conf -java-args ${JAVA_OPTS} --debug true $@
elif [ "$1" = 'worker' ]; then 
  export IP=`getent ahostsv4 dev-pca-mist.singularity.k.9dev.io | awk '{ print $1; exit }'`
  export MYIP=`ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`

  JAVA_ARGS="-Dmist.akka.cluster.seed-nodes.0=akka.tcp://mist@$IP:2551"
  JAVA_ARGS="$JAVA_ARGS -Dmist.akka.remote.netty.tcp.hostname=$MYIP"
  export JAVA_ARGS="$JAVA_ARGS -Dmist.akka.remote.netty.tcp.bind-hostname=$MYIP"
  echo """./bin/mist-worker --runner local --master ${IP} --name ${MIST_WORKER_NAME} --context-name ${MIST_WORKER_CONTEXT} --mode ${MIST_WORKER_MODE}"""
  exec ./bin/mist-worker --runner local --master ${IP}:2551 --name ${MIST_WORKER_NAME} --context-name ${MIST_WORKER_CONTEXT} --mode ${MIST_WORKER_MODE}
  
fi

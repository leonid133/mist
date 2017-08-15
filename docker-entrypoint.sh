#!/bin/bash

set -e
cd ${MIST_HOME}

if [ "$1" = 'mist' ]; then
  export IP=`ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`

  export JAVA_OPTS="$JAVA_OPTS -Dmist.cluster.host=$IP"
  shift
  exec ./bin/mist-master start --config /usr/share/external_configs/pca-mist.conf --debug true $@
elif [ "$1" = 'worker' ]; then 
  export IP=`getent hosts dev-pca-mist.singularity.k.9dev.io | awk '{ print $1 }'`
  export MYIP=`ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`

  JAVA_ARGS="-Dmist.akka.cluster.seed-nodes.0=akka.tcp://mist@$IP:2551"
  JAVA_ARGS="$JAVA_ARGS -Dmist.akka.remote.netty.tcp.hostname=$MYIP"
  JAVA_ARGS="$JAVA_ARGS -Dmist.akka.remote.netty.tcp.bind-hostname=$MYIP"
  exec ./bin/mist-worker --runner local --master ${IP} --name ${MIST_WORKER_NAMESPACE} --context-name ${MIST_WORKER_CONTEXT} --java-args "$JAVA_ARGS" --mode ${MIST_WORKER_MODE}
  
fi

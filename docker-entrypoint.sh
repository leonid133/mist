#!/bin/bash
set -e
export PYTHONPATH=${MIST_HOME}/src/main/python:${SPARK_HOME}/python/:`readlink -f ${SPARK_HOME}/python/lib/py4j*`:${PYTHONPATH}
cd ${MIST_HOME}

if [ "$1" = 'tests' ]; then
  ./sbt/sbt -DsparkVersion=${SPARK_VERSION} -Dconfig.file=src/test/resources/tests-${SPARK_VERSION}.conf "project examples" clean package "project mist" clean assembly test
elif [ "$1" = 'mist' ]; then
  #export IP=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | head -n 1`
  export IP=`ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`
  #export IP=getent hosts dev-pca-mist.singularity.k.9dev.io | awk '{ print $1 }'
  echo "$IP    master" >> /etc/hosts
  sed -i "s/leader/$IP/" ext_configs/docker.conf
  sed -i "s/leader/$IP/" ext_configs/docker_worker.conf
  ./bin/mist start master --config ext_configs/docker.conf
elif [ "$1" = 'worker' ]; then 
  #export IP=`getent hosts master | awk '{ print $1 }'`
  export IP=`ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`
  cp -f ext_configs/docker_worker.conf configs/docker_worker.conf
  sed -i "s/my_host/$IP/" configs/docker_worker.conf
  if [ $3 ] && [ $4 ] && [ $5 ] && [ $6 ] && [ $7 ]; then
    ./bin/mist start worker --runner local --namespace $2 --config configs/docker_worker.conf --jar $4 --run-options --repositories "http://eng-01.jiwiredev.com:5050/nexus/content/repositories/jiwire,http://eng-01.jiwiredev.com:5050/nexus/content/repositories/jiwire-snapshots,http://eng-01.jiwiredev.com:5050/nexus/content/repositories/jicore" --packages $5 --exclude-packages $6 --jars $7
  else
    ./bin/mist start worker --runner local --namespace $2 --config configs/docker_worker.conf
  fi
elif [ "$1" = 'dev' ]; then
  ./sbt/sbt -DsparkVersion=${SPARK_VERSION} assembly
  ./bin/mist start master --config ext_configs/docker.conf
else
  exec "$@"
fi

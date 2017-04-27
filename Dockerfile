FROM docker.jiwiredev.com/nined/spark-box:bash-44191aa
MAINTAINER fi@ninthdecimal.com

ENV MIST_HOME=/usr/share/mist \
    SPARK_VERSION=2.1.0 \
    SPARK_HOME=/opt/spark/current

COPY . ${MIST_HOME}
COPY ./docker-entrypoint.sh /

RUN echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list \
 && echo 'deb http://cran.cnr.berkeley.edu/bin/linux/ubuntu trusty/' >> /etc/apt/sources.list \
 && echo 'deb https://get.docker.com/ubuntu docker main' >> /etc/apt/sources.list \
 && apt-get update \
 && pip install http://pypi.jiwiredev.com/packages/nd-singularity-0.6.4.tar.gz

RUN wget http://jenkins-01.jiwiredev.com/job/spark-distribution/35/artifact/release/spark-2.0.3-20161205/spark-2.0.3-SNAPSHOT-bin-2.7.0-mapr-1506.tgz \
    && tar xzf spark-2.0.3-SNAPSHOT-bin-2.7.0-mapr-1506.tgz \
    && mv spark-2.0.3-SNAPSHOT-bin-2.7.0-mapr-1506 ${SPARK_HOME} \
    && rm spark-2.0.3-SNAPSHOT-bin-2.7.0-mapr-1506.tgz
 
RUN cd ${MIST_HOME} && \
    ./sbt/sbt -DsparkVersion=2.1.0 assembly </dev/null && \
    ./sbt/sbt -DsparkVersion=2.1.0 "project examples" package </dev/null && \
    chmod +x /docker-entrypoint.sh

EXPOSE 2003

ENTRYPOINT ["/docker-entrypoint.sh"]

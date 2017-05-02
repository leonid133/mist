FROM docker.jiwiredev.com/nined/spark-box:latest
MAINTAINER fi@ninthdecimal.com

ENV MIST_HOME=/usr/share/mist \
    SPARK_VERSION=2.1.0 \
    SPARK_HOME=/opt/spark/current

COPY . ${MIST_HOME}
COPY ./docker-entrypoint.sh /

RUN echo "Update 2017-04-24" \
 && echo 'deb http://cran.cnr.berkeley.edu/bin/linux/ubuntu trusty/' >> /etc/apt/sources.list \
 && echo 'deb https://get.docker.com/ubuntu docker main' >> /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y --force-yes \
    build-essential \
    python-pip \
    python-tk \
    ed \
    libpq-dev \
    libboost-python-dev \
    supervisor \
 && apt-get -y autoremove \
 && apt-get -y clean all \
 && apt-get -y autoclean all \
 && rm -fr /tmp/* /var/tmp/*
 
RUN pip install http://pypi.jiwiredev.com/packages/nd-singularity-0.6.4.tar.gz

RUN wget http://jenkins-01.jiwiredev.com/job/spark-distribution/35/artifact/release/spark-2.0.3-20161205/spark-2.0.3-SNAPSHOT-bin-2.7.0-mapr-1506.tgz \
    && tar xzf spark-2.0.3-SNAPSHOT-bin-2.7.0-mapr-1506.tgz \
    && mv spark-2.0.3-SNAPSHOT-bin-2.7.0-mapr-1506 ${SPARK_HOME} \
    && rm spark-2.0.3-SNAPSHOT-bin-2.7.0-mapr-1506.tgz
 
RUN cd ${MIST_HOME} && \
    ./sbt/sbt -DsparkVersion=2.1.0 assembly </dev/null && \
    chmod +x /docker-entrypoint.sh

COPY ./spark/conf ${SPARK_HOME}/conf

EXPOSE 2003

ENTRYPOINT ["/docker-entrypoint.sh"]

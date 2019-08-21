ARG PYTHON_VERSION=3.7.2
ARG ALPINE_VERSION=3.8
FROM python:$PYTHON_VERSION-alpine$ALPINE_VERSION

MAINTAINER Talkdesk - SRE <sre@talkdesk.com>

ENV \
  SPARK_HOME=/spark \
  PYSPARK_PYTHON=python3 \
  PYTHONPATH=$SPARK_HOME/python:.:pipeline

COPY requirements.txt /tmp/requirements.txt

RUN \
  TMP_DIR=$(mktemp -d) && cd ${TMP_DIR} && \
  # Install Spark 2.4.0 \
  wget -q http://archive.apache.org/dist/spark/spark-2.4.0/spark-2.4.0-bin-hadoop2.7.tgz \
  && tar -xzf spark-2.4.0-bin-hadoop2.7.tgz \
  && mv spark-2.4.0-bin-hadoop2.7 ${SPARK_HOME} \
  && rm spark-2.4.0-bin-hadoop2.7.tgz \
  && \
  # Add AWS jars for Spark \
  wget -q http://central.maven.org/maven2/com/amazonaws/aws-java-sdk/1.7.4/aws-java-sdk-1.7.4.jar \
  && wget -q http://central.maven.org/maven2/org/apache/hadoop/hadoop-aws/2.7.5/hadoop-aws-2.7.5.jar \
  && mv aws-java-sdk-1.7.4.jar ${SPARK_HOME}/jars \
  && mv hadoop-aws-2.7.5.jar ${SPARK_HOME}/jars \
  && \
  # Install ffmpeg, Java 8, and other dependencies \
  apk add --update --virtual build-deps gcc linux-headers make python3-dev musl-dev build-base postgresql-dev \
  && apk add --update --no-cache ffmpeg openjdk8-jre libpq nss bash \
  && \
  # Install pipeline requirements \
  pip3 install --upgrade --upgrade-strategy eager -r /tmp/requirements.txt \
  && \
  # Install Spacy language models \
  python3 -m spacy download en \
  && python3 -m spacy download pt \
  \
  # Cleanup
  && apk del build-deps \
  && rm -rf ${TMP_DIR} /var/cache/apk/* /root/.pip

CMD ["/usr/local/bin/luigid"]

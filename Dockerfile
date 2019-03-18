FROM ubuntu:16.04
MAINTAINER Abulo Hoo <abulo.hoo@gmail.com>
#环境变量
ENV HBASE_VERSION=2.0.0 HBASE_MINOR_VERSION=2.0 PHOENIX_VERSION=5.0.0 HBASE_HADOOP_VERSION=2.7.4 REPLACEMENT_HADOOP_VERSION=2.8.5 JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 JRE_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
#安装jdk
RUN  sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/' /etc/apt/sources.list \
    && groupadd -r hadoop \
    && useradd -g hadoop hadoop -s /sbin/nologin \
    && apt-get -y update --fix-missing \
    && apt-get install --no-install-recommends -y -q openjdk-8-jdk ant gnupg libncurses5 unzip tar maven xmlstarlet wget net-tools telnetd python htop python3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && chmod -R 777 /opt \
    && cd /opt \
    \
    #安装hadoop
    && wget -q -O hadoop-$REPLACEMENT_HADOOP_VERSION.tar.gz http://www.apache.org/dist/hadoop/common/hadoop-$REPLACEMENT_HADOOP_VERSION/hadoop-$REPLACEMENT_HADOOP_VERSION.tar.gz \
    && tar -xzf hadoop-$REPLACEMENT_HADOOP_VERSION.tar.gz \
    && rm -rf hadoop-$REPLACEMENT_HADOOP_VERSION.tar.gz \
    && mv hadoop-$REPLACEMENT_HADOOP_VERSION hadoop \
    && mkdir -pv /etc/hadoop \
    && cp -rf /opt/hadoop/etc/hadoop/* /etc/hadoop \
    && mkdir -pv /opt/hadoop/tmp && mkdir -pv /opt/hadoop/hdfs \
    && mkdir -pv /opt/hadoop/hdfs/data && mkdir -pv /opt/hadoop/hdfs/name \
    && rm -rf /opt/hadoop/share/doc/hadoop \
    \
    # 安装Hbase
    && wget -q -O hbase-$HBASE_VERSION-bin.tar.gz http://archive.apache.org/dist/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz \
    && tar -xzf hbase-$HBASE_VERSION-bin.tar.gz \
    && mv /opt/hbase-$HBASE_VERSION /opt/hbase \
    && chmod -R +x /opt/hbase \
    && rm -rf hbase-$HBASE_VERSION-bin.tar.gz \
    && rm -rf /opt/hbase/docs \
    \
    # 安装Phoenix
    && wget -q -O apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MINOR_VERSION-bin.tar.gz http://archive.apache.org/dist/phoenix/apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MINOR_VERSION/bin/apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MINOR_VERSION-bin.tar.gz \
    && tar -xzf apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MINOR_VERSION-bin.tar.gz  \
    && mv apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MINOR_VERSION-bin phoenix \
    && chmod -R +x /opt/phoenix \
    && rm -rf  apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MINOR_VERSION-bin.tar.gz \
    && rm -rf /opt/phoenix/examples \
    \
    # 配置hbase & Phoenix
    && cp /opt/phoenix/phoenix-$PHOENIX_VERSION-HBase-$HBASE_MINOR_VERSION-server.jar /opt/hbase/lib/ \
    && cp /opt/phoenix/phoenix-$PHOENIX_VERSION-HBase-$HBASE_MINOR_VERSION-client.jar /opt/hbase/lib/ \
    && cp -rf /opt/phoenix/bin/tephra /opt/hbase/bin/tephra \
    && cp -rf /opt/phoenix/bin/tephra-env.sh /opt/hbase/bin/tephra-env.sh \
    \
    # Replace hbase's guava 11 jar with the guava 13 jar. Remove when TEPHRA-181 is resolved.
    && rm /opt/hbase/lib/guava-11.0.2.jar \
    && wget -q -O /opt/hbase/lib/guava-13.0.1.jar http://search.maven.org/remotecontent?filepath=com/google/guava/guava/13.0.1/guava-13.0.1.jar \
    \
    # Replace HBase's Hadoop 2.7.4 jars with Hadoop 2.8.5 jars
    && for i in /opt/hbase/lib/hadoop-*; do \
    case $i in \
    *test*);; \
    *) \
    NEW_FILE=$(echo $i | sed -e "s/$HBASE_HADOOP_VERSION/$REPLACEMENT_HADOOP_VERSION/g; s/\/opt\/hbase\/lib\///g"); \
    FOLDER=$(echo $NEW_FILE | sed -e "s/-$REPLACEMENT_HADOOP_VERSION.jar//g"); \
    wget -q -O /opt/hbase/lib/$NEW_FILE http://search.maven.org/remotecontent?filepath=org/apache/hadoop/$FOLDER/$REPLACEMENT_HADOOP_VERSION/$NEW_FILE;; \
    esac; \
    \
    rm $i; \
    done \
    \
    # Clean up
    &&  rm -rf  /var/tmp/*

EXPOSE 2181 16010 16020 16030 8765
ADD start-hbase-phoenix.sh /start-hbase-phoenix.sh
RUN chmod 777 -R /start-hbase-phoenix.sh && chown -R root.root /start-hbase-phoenix.sh && chown -R root.root /opt && chmod 777 -R /opt
CMD ["/start-hbase-phoenix.sh"]
USER root
WORKDIR /opt
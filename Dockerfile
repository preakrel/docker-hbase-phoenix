FROM daocloud.io/php_ity/docker-hadoop
MAINTAINER 1396981439@qq.com

ENV ZOOKEEPER_VERSION=3.4.13 HBASE_MAJOR=2.0 HBASE_MINOR=4 HBASE_VERSION="$HBASE_MAJOR}.${HBASE_MINOR}" PHOENIX_VERSION=5.0.0  WEB=http://mirrors.hust.edu.cn/apache

COPY config/* /opt/config/

USER root
WORKDIR /opt

RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/' /etc/apt/sources.list \
    && apt-get -y update --fix-missing \
    && apt-get clean \
    && chmod -R 777 /opt \
    && cd /opt \
    # zookeeper
    && wget -q -O zookeeper-$ZOOKEEPER_VERSION.tar.gz $WEB/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz \
    && tar -zxf zookeeper-$ZOOKEEPER_VERSION.tar.gz \
    && mv /opt/zookeeper-$ZOOKEEPER_VERSION /opt/zookeeper \
    && mv /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg \
    && chmod -R +x /opt/zookeeper \
    && mkdir /tmp/zookeeper \
    && rm -rf zookeeper-$ZOOKEEPER_VERSION.tar.gz \
    # hbase
    && wget -q -O hbase-$HBASE_VERSION-bin.tar.gz $WEB/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz \
    && tar -xzf hbase-$HBASE_VERSION-bin.tar.gz \
    && mv /opt/hbase-$HBASE_VERSION /opt/hbase \
    && chmod -R +x /opt/hbase \
    && rm -rf hbase-$HBASE_VERSION-bin.tar.gz \
    && rm -rf /opt/hbase/docs \
    && rm /opt/hbase/conf/hbase-site.xml \
    && mv /opt/config/hbase-site.xml /opt/hbase/conf/hbase-site.xml \
    # phoenix
    && wget -q -O apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-bin.tar.gz $WEB/phoenix/apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR/bin/apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-bin.tar.gz \
    && tar -xzf apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-bin.tar.gz  \
    && mv apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-bin phoenix \
    && chmod -R +x /opt/phoenix \
    && rm -rf  apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-bin.tar.gz \
    && rm -rf /opt/phoenix/examples \
    # 配置hbase & Phoenix
    && cp /opt/phoenix/phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-server.jar /opt/hbase/lib/ \
    && cp /opt/phoenix/phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-client.jar /opt/hbase/lib/ \
    && cp -rf /opt/phoenix/bin/tephra /opt/hbase/bin/tephra \
    && cp -rf /opt/phoenix/bin/tephra-env.sh /opt/hbase/bin/tephra-env.sh \ 
    && mv /opt/config/bootstrap-phoenix.sh / \
    && rm -rf  /var/tmp/* /tmp/* \
    && chmod 777 -R /opt && chown root:root /bootstrap-phoenix.sh && chmod 777 /bootstrap-phoenix.sh

CMD ["/bootstrap-phoenix.sh", "-bash"]

EXPOSE 8765

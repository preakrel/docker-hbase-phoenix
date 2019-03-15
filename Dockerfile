#FROM centos:6

FROM sequenceiq/pam:centos-6.5

MAINTAINER 1396981439@qq.com

USER root

RUN cp /etc/skel/.bash* ~

RUN yum clean all; rpm --rebuilddb; yum install -y curl which tar sudo rsync openssh-server openssh-clients initscripts python-argparse nano mlocate

RUN yum clean all; rpm --rebuilddb; yum update -y libselinux; yum clean all; rpm --rebuilddb;

# passwordless ssh
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

# java
RUN curl -LO 'http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm' -H 'Cookie: oraclelicense=accept-securebackup-cookie'
RUN rpm -i jdk-8u131-linux-x64.rpm
RUN rm jdk-8u131-linux-x64.rpm

ENV JAVA_HOME /usr/java/default
ENV PATH $PATH:$JAVA_HOME/bin

RUN rm /usr/bin/java && ln -s $JAVA_HOME/bin/java /usr/bin/java

ARG APACHE_MIRROR=https://www.apache.org/dist

# maven
RUN curl -LO 'http://mirror.olnevhost.net/pub/apache/maven/maven-3/3.0.5/binaries/apache-maven-3.0.5-bin.tar.gz'
RUN tar xvf apache-maven-3.0.5-bin.tar.gz
RUN mv apache-maven-3.0.5  /usr/local/apache-maven
RUN echo "export M2_HOME=/usr/local/apache-maven" >> ~/.bashrc
RUN echo "export M2=$M2_HOME/bin" >> ~/.bashrc
RUN echo "export PATH=$M2:$PATH" >> ~/.bashrc
RUN source ~/.bashrc

# Hadoop
ARG HADOOP_VERSION=2.7.3

# download native support
#RUN mkdir -p /tmp/native
#RUN curl -L https://github.com/sequenceiq/docker-hadoop-build/releases/download/v$HADOOP_VERSION/hadoop-native-64-$HADOOP_VERSION.tgz | tar -xz -C /tmp/native

RUN curl $APACHE_MIRROR/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz | tar -xz -C /usr/local
RUN cd /usr/local && ln -s ./hadoop-$HADOOP_VERSION hadoop
ENV HADOOP_PREFIX=/usr/local/hadoop
ENV HADOOP_HOME=${HADOOP_PREFIX}
ENV	HADOOP_COMMON_HOME=${HADOOP_PREFIX}
ENV	HADOOP_HDFS_HOME=${HADOOP_PREFIX}
ENV	HADOOP_MAPRED_HOME=${HADOOP_PREFIX}
ENV	HADOOP_YARN_HOME=${HADOOP_PREFIX}
ENV	HADOOP_CONF_DIR=${HADOOP_PREFIX}/etc/hadoop
ENV	YARN_CONF_DIR=${HADOOP_PREFIX}/etc/hadoop
ENV PATH $PATH:$HADOOP_HOME/bin

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/java/default\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
#RUN . $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

RUN mkdir $HADOOP_PREFIX/input
RUN cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input

# pseudo distributed
ADD config/core-site.xml.template $HADOOP_PREFIX/etc/hadoop/core-site.xml.template
RUN sed s/HOSTNAME/localhost/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
ADD config/hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

ADD config/mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD config/yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

RUN $HADOOP_PREFIX/bin/hdfs namenode -format

# fixing the libhadoop.so like a boss
#RUN rm -rf /usr/local/hadoop/lib/native
#RUN mv /tmp/native /usr/local/hadoop/lib

ADD config/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config

# workingaround docker.io build error
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh
RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "Port 2122" >> /etc/ssh/sshd_config

# zookeeper
ENV ZOOKEEPER_VERSION 3.4.10
RUN curl $APACHE_MIRROR/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./zookeeper-$ZOOKEEPER_VERSION zookeeper
ENV ZOO_HOME /usr/local/zookeeper
ENV PATH $PATH:$ZOO_HOME/bin
RUN mv $ZOO_HOME/conf/zoo_sample.cfg $ZOO_HOME/conf/zoo.cfg
RUN mkdir /tmp/zookeeper

# hbase
ENV HBASE_MAJOR 1.2
ENV HBASE_MINOR 5
ENV HBASE_VERSION "${HBASE_MAJOR}.${HBASE_MINOR}"
RUN curl $APACHE_MIRROR/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./hbase-$HBASE_VERSION hbase
ENV HBASE_HOME /usr/local/hbase
ENV PATH $PATH:$HBASE_HOME/bin
RUN rm $HBASE_HOME/conf/hbase-site.xml
ADD config/hbase-site.xml.template $HBASE_HOME/conf/hbase-site.xml

# Phoenix
ARG PHOENIX_VERSION=4.10.0
RUN curl $APACHE_MIRROR/phoenix/apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR/bin/apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-bin.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./apache-phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-bin phoenix
ENV PHOENIX_HOME /usr/local/phoenix
ENV PATH $PATH:$PHOENIX_HOME/bin
RUN cp $PHOENIX_HOME/phoenix-core-$PHOENIX_VERSION-HBase-$HBASE_MAJOR.jar $HBASE_HOME/lib/phoenix.jar
RUN cp $PHOENIX_HOME/phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-server.jar $HBASE_HOME/lib/phoenix-server.jar

# HBase and Phoenix configuration files
RUN rm $HBASE_HOME/conf/hbase-site.xml
RUN rm $HBASE_HOME/conf/hbase-env.sh
COPY config/hbase-site.xml.template $HBASE_HOME/conf/hbase-site.xml.template
RUN sed s/HOSTNAME/$HOSTNAME/ /usr/local/hbase/conf/hbase-site.xml.template > /usr/local/hbase/conf/hbase-site.xml
COPY config/hbase-env.sh $HBASE_HOME/conf/hbase-env.sh

# bootstrap-phoenix
ADD bootstrap-phoenix.sh /etc/bootstrap-phoenix.sh
RUN chown root:root /etc/bootstrap-phoenix.sh
RUN chmod 700 /etc/bootstrap-phoenix.sh

CMD ["/etc/bootstrap-phoenix.sh", "-bash"]

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# Mapred ports
EXPOSE 10020 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122

#Zookeeper
EXPOSE 2181
#Phoenix QS
EXPOSE 8765
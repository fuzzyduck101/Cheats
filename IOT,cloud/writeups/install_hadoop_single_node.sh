#!/bin/bash

# Exit if any command fails
set -e

# Hadoop and Java variables
HADOOP_VERSION="3.3.6"
JAVA_VERSION="8"
HADOOP_DIR="$HOME/hadoop"
HADOOP_URL="https://downloads.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz"

echo "=== Installing Java ==="
sudo apt update
sudo apt install -y openjdk-${JAVA_VERSION}-jdk ssh rsync

# Set JAVA_HOME
JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")

echo "=== Downloading Hadoop $HADOOP_VERSION ==="
mkdir -p "$HADOOP_DIR"
cd "$HADOOP_DIR"
wget "$HADOOP_URL" -O hadoop.tar.gz
tar -xzf hadoop.tar.gz
rm hadoop.tar.gz
mv "hadoop-$HADOOP_VERSION" hadoop

# Set environment variables
cat >> ~/.bashrc <<EOF

# Hadoop Environment Variables
export HADOOP_HOME=$HADOOP_DIR/hadoop
export HADOOP_INSTALL=\$HADOOP_HOME
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin
export JAVA_HOME=$JAVA_HOME
EOF

source ~/.bashrc

echo "=== Configuring Hadoop ==="
cd "$HADOOP_HOME/etc/hadoop"

# Set JAVA_HOME in hadoop-env.sh
sed -i "s|^export JAVA_HOME=.*|export JAVA_HOME=$JAVA_HOME|" hadoop-env.sh

# core-site.xml
cat > core-site.xml <<EOF
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
  </property>
</configuration>
EOF

# hdfs-site.xml
cat > hdfs-site.xml <<EOF
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
</configuration>
EOF

# mapred-site.xml
cp mapred-site.xml.template mapred-site.xml
cat > mapred-site.xml <<EOF
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
</configuration>
EOF

# yarn-site.xml
cat > yarn-site.xml <<EOF
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
</configuration>
EOF

echo "=== Formatting HDFS Namenode ==="
hdfs namenode -format

echo "=== Starting Hadoop Daemons ==="
start-dfs.sh
start-yarn.sh

echo "=== Creating HDFS directories ==="
hdfs dfs -mkdir -p /user/$USER
hdfs dfs -mkdir input

echo "=== Creating sample input text ==="
echo -e "Hello Hadoop\nHadoop is fun\nFun with Hadoop" > $HOME/input.txt
hdfs dfs -put -f $HOME/input.txt input/

echo "=== Running WordCount MapReduce job ==="
hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar wordcount input output

echo "=== Showing job output ==="
hdfs dfs -cat output/part-r-00000

echo "✅ Hadoop WordCount completed!"

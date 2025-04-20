#!/bin/bash


sudo service ssh start


HOSTNAME=$(hostname)
ID=$(echo "$HOSTNAME" | grep -o '[0-9]*$')

if [[ "$HOSTNAME" == master* ]]; then
    echo " [$HOSTNAME] Master Node Detected"
    
    echo "Starting ZooKeeper..."
    mkdir -p /usr/local/zookeeper/data
    echo "$ID" > /usr/local/zookeeper/data/myid
    /usr/local/zookeeper/bin/zkServer.sh start

    echo "Starting JournalNode..."
    hdfs --daemon start journalnode

     echo "Starting ZKFC on master$ID..."
      hdfs zkfc -formatZK -nonInteractive -force
      hdfs --daemon start zkfc

    if [ "$ID" -eq 1 ]; then
        if [ ! -f /tmp/hadoop-hadoop/dfs/name/current/VERSION ]; then
            echo "Formatting NameNode on master1..."
            hdfs namenode -format -nonInteractive || yes Y | hdfs namenode -format
        else
            echo " NameNode already formatted."
        fi
    else
       sleep 20
        echo "Bootstrapping Standby NameNode on master$ID..."
        hdfs namenode -bootstrapStandby
    fi



    echo "Starting NameNode..."
    hdfs --daemon start namenode
    echo "Starting ResourceManager on master$ID..."
    yarn --daemon start resourcemanager
fi


if [[ "$HOSTNAME" == worker* ]]; then
    echo "[$HOSTNAME] DataNode Node Detected"
    echo "Starting DataNode..."
    hdfs --daemon start datanode
    echo "Starting NodeManager..."
    yarn --daemon start nodemanager

fi


echo "Entering sleep mode to keep container running..."
tail -f /dev/null  
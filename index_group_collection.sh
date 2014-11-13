#!/bin/bash
# Creates a collection based on the /etc/group file
# then indexes the /etc/group file.
# This script expects /etc/hadoop/conf/core-site.xml
# and /etc/solr/conf/solr-env.sh to be correct.
# 

# Change these 3 variables for your env:
# This is the index scratch dir in HDFS:
export TMP_HDFS=/tmp/group_collection_output2
# This is the location where the script
# puts the group file in HDFS to index
export HDFS_DATA=/tmp/group_collection2
# This is the collection name
export ENV_COLLECTION="group_collection2"

export SCRIPT_DIR="$( cd -P "$( dirname "$0" )" && pwd )"
export TMP_LOCATION=${SCRIPT_DIR}
# Get the ZK Ensemble from /etc/solr/conf/solr-env.sh
export ENV_ZK_HOST=`cat /etc/solr/conf/solr-env.sh | awk -F= '{print $2}'`
# Get the namenode or nameservice from /etc/hadoop/conf/core-site.xml
export NAMESERVICE=`grep -A1 defaultFS /etc/hadoop/conf/core-site.xml | tail -1 | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
# Check if cluster is kerberized
export SECURE=`grep -A1 "hadoop.security.authentication" /etc/hadoop/conf/core-site.xml | tail -1 | awk -F\> '{print $2}' | awk -F\< '{print $1}'`

# Copy group file to tmp location and change to "\t" delimited"
cp /etc/group ${TMP_LOCATION}/group.example
sed -i "s/:/\ /g" ${TMP_LOCATION}/group.example
# Put the group file in HDFS
hadoop fs -mkdir ${HDFS_DATA}
hadoop fs -put ${TMP_LOCATION}/group.example ${HDFS_DATA}

# Create the instancedir and collection
solrctl instancedir --create ${ENV_COLLECTION} ${TMP_LOCATION}
solrctl collection --create ${ENV_COLLECTION}

# Create jaas.conf if kerberized cluster and run Indexer with jaas.conf
if [[ "${SECURE}" =~ "kerberos" ]]
then

cat > ${TMP_LOCATION}/jaas.conf << EOF
Client {
 com.sun.security.auth.module.Krb5LoginModule required
 useTicketCache=true
 principal="`klist | grep Default | awk '{print $3}'`";
};
EOF

HADOOP_OPTS="-Djava.security.auth.login.config=${TMP_LOCATION}/jaas.conf" \
hadoop jar /opt/cloudera/parcels/CDH/lib/solr/contrib/mr/search-mr-*-job.jar \
org.apache.solr.hadoop.MapReduceIndexerTool -D'mapred.child.java.opts=-Xmx500m mapred.map.child.java.opts=-Xmx500m mapred.reduce.child.java.opts=-Xmx500m' \
--morphline-file ${TMP_LOCATION}/conf/morphlines.conf --output-dir \
${NAMESERVICE}${TMP_HDFS} --verbose --go-live --zk-host \
${ENV_ZK_HOST} --collection ${ENV_COLLECTION} \
${NAMESERVICE}${HDFS_DATA}

else
# No kerberos so no jaas.conf

hadoop jar /opt/cloudera/parcels/CDH/lib/solr/contrib/mr/search-mr-*-job.jar \
org.apache.solr.hadoop.MapReduceIndexerTool -D'mapred.child.java.opts=-Xmx500m mapred.map.child.java.opts=-Xmx500m mapred.reduce.child.java.opts=-Xmx500m' \
--morphline-file ${TMP_LOCATION}/conf/morphlines.conf --output-dir \
${NAMESERVICE}${TMP_HDFS} --verbose --go-live --zk-host \
${ENV_ZK_HOST} --collection ${ENV_COLLECTION} \
${NAMESERVICE}${HDFS_DATA}

fi



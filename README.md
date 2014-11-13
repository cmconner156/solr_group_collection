solr_group_collection
=====================
This creates a solr collection and
indexes the /etc/group file.  This script
will check if kerberos is enabled
and if it is it will use your current
principal to index.
This expects that /etc/hadoop/conf/core-site.xml
and /etc/solr/conf/solr-env.sh exist and
are configured correctly.
=====================
1.  Clone the repository.
2.  Edit solr_group_collection/index_group_collection.sh
3.  Set the following lines to match the temp locations
    in hdfs you would like to use and the collection name
    you would like to use:

export TMP_HDFS=/tmp/group_collection_output
export HDFS_DATA=/tmp/group_collection
export ENV_COLLECTION="group_collection"

4.  Run "solr_group_collection/index_group_collection.sh"

====================
Overview of the steps can be found in the script comments

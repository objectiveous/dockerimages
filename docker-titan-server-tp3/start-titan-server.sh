#!/bin/bash

env

IP=$(ip -o -4 addr list eth0 | perl -n -e 'if (m{inet\s([\d\.]+)\/\d+\s}xms) { print $1 }')
echo "IP=$IP"

sed -i "s|^host:.*|host: $IP|" $TITAN_HOME/                                     conf/gremlin-server-cassandra-es.yaml


args=

if [ $(ls /conf|wc -l) = 0 ]; then
  cp -r $TITAN_HOME/conf/* /conf
fi

rm -f /tmp/titan.properties

  shortcut=/tmp/titan.properties
  cat >> /tmp/titan.properties <<END
gremlin.graph=com.thinkaurelius.titan.core.TitanFactory
END


if [ -n "$CASS_PORT_9160_TCP_ADDR" ]; then

  shortcut=/tmp/titan.properties
  cat >> /tmp/titan.properties <<END
storage.backend=cassandra
storage.hostname=$CASS_PORT_9160_TCP_ADDR
storage.cassandra.keyspace=$CASS_KEYSPACE
END

elif [ -n "$CASS_ADDR" ]; then

  shortcut=/tmp/titan.properties
  cat >> /tmp/titan.properties <<END
storage.backend=cassandra
storage.hostname=$CASS_ADDR
storage.cassandra.keyspace=$CASS_KEYSPACE
END

fi


esAddr=${ES_ENV_PUBLISH_AS:-ES_PORT_9300_TCP_ADDR}

if [ -n "$ES_CLUSTER" -o -n "$esAddr" ]; then
  shortcut=/tmp/titan.properties
  cat >> /tmp/titan.properties <<END
index.search.backend=elasticsearch
index.search.elasticsearch.client-only=true
END

  if [ -n "$ES_CLUSTER" ]; then
    cat >> /tmp/titan.properties <<END
index.search.elasticsearch.ext.cluster.name=$ES_CLUSTER
END
  fi
  if [ -n "$esAddr" ]; then
    # strip off the port spec, if present
    esAddr=$(echo $esAddr | cut -d: -f1)
    cat >> /tmp/titan.properties <<END
index.search.hostname=$esAddr
END
  fi
  
fi

cp /tmp/titan.properties $TITAN_HOME/conf/titan-cassandra-es.properties

exec $TITAN_HOME/bin/gremlin-server.sh $TITAN_HOME/                                     conf/gremlin-server-cassandra-es.yaml

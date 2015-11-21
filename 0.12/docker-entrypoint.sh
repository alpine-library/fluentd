#!/bin/sh

ELASTICSEARCH_HOST=${ELASTICSEARCH_HOST:-"elasticsearch-logging.kube-system.svc.kube.local"}
ELASTICSEARCH_PORT=${ELASTICSEARCH_PORT:-9200}
FLUENTD_FLUSH_INTERVAL=${FLUENTD_FLUSH_INTERVAL:-60s}
FLUENTD_FLUSH_THREADS=${FLUENTD_FLUSH_THREADS:-1}
FLUENTD_RETRY_LIMIT=${FLUENTD_RETRY_LIMIT:-10}
FLUENTD_RETRY_WAIT=${FLUENTD_RETRY_WAIT:-1s}
FLUENTD_BUFFER_CHUNK_LIMIT=${FLUENTD_BUFFER_CHUNK_LIMIT:-8m}
FLUENTD_BUFFER_QUEUE_LIMIT=${FLUENTD_BUFFER_QUEUE_LIMIT:-256}
FLUENTD_BUFFER_TYPE=${FLUENTD_BUFFER_TYPE:-memory}
FLUENTD_BUFFER_PATH=${FLUENTD_BUFFER_PATH:-/var/fluentd/buffer}

cat << 'EOF' > /etc/fluent/fluent.conf
<source>
  type tail
  path /var/lib/docker/containers/*/*.log
  pos_file /var/log/es-containers.log.pos
  time_format %Y-%m-%dT%H:%M:%S
  tag docker.*
  format json
  read_from_head true
</source>

<match docker.var.lib.docker.containers.*.*.log>
  type docker_format
  container_id ${tag_parts[5]}
  tag docker.${name}
</match>

<source>
  type tail
  format none
  path /var/log/salt/minion
  pos_file /var/log/gcp-salt.pos
  tag salt
</source>

<source>
  type tail
  format none
  path /var/log/startupscript.log
  pos_file /var/log/es-startupscript.log.pos
  tag startupscript
</source>

<source>
  type tail
  format none
  path /var/log/docker.log
  pos_file /var/log/es-docker.log.pos
  tag docker
</source>

<source>
  type tail
  format none
  path /var/log/etcd.log
  pos_file /var/log/es-etcd.log.pos
  tag etcd
</source>

<source>
  type tail
  format none
  path /var/log/kubelet.log
  pos_file /var/log/es-kubelet.log.pos
  tag kubelet
</source>

<source>
  type tail
  format none
  path /var/log/kube-apiserver.log
  pos_file /var/log/es-kube-apiserver.log.pos
  tag kube-apiserver
</source>

<source>
  type tail
  format none
  path /var/log/kube-controller-manager.log
  pos_file /var/log/es-kube-controller-manager.log.pos
  tag kube-controller-manager
</source>

<source>
  type tail
  format none
  path /var/log/kube-scheduler.log
  pos_file /var/log/es-kube-scheduler.log.pos
  tag kube-scheduler
</source>

<filter kubernetes.**>
  type kubernetes_metadata
</filter>

<match **>
   type elasticsearch
   log_level info
   include_tag_key true
   host elasticsearch-logging
   port 9200
   logstash_format true
EOF

cat << EOF >> /etc/fluent/fluent.conf
  host $(eval echo \$${ELASTICSEARCH_HOST})
  port $(eval echo \$${ELASTICSEARCH_PORT})
  scheme ${ELASTICSEARCH_SCHEME}
  $([ -n "${ELASTICSEARCH_USER}" ] && echo user ${ELASTICSEARCH_USER})
  $([ -n "${ELASTICSEARCH_PASSWORD}" ] && echo password ${ELASTICSEARCH_PASSWORD})
  buffer_type ${FLUENTD_BUFFER_TYPE}
  $([ "${FLUENTD_BUFFER_TYPE}" == "file" ] && echo buffer_path ${FLUENTD_BUFFER_PATH})
  buffer_chunk_limit ${FLUENTD_BUFFER_CHUNK_LIMIT}
  buffer_queue_limit ${FLUENTD_BUFFER_QUEUE_LIMIT}
  flush_interval ${FLUENTD_FLUSH_INTERVAL}
  retry_limit ${FLUENTD_RETRY_LIMIT}
  retry_wait ${FLUENTD_RETRY_WAIT}
  num_threads ${FLUENTD_FLUSH_THREADS}
EOF

cat << 'EOF' >> /etc/fluent/fluent.conf
</match>
EOF

exec fluentd

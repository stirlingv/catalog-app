#!/bin/sh

# URL for the primary database, in the format expected by sqlalchemy (required
# unless linked to a container called 'db')
: ${DATABASE_URL:=}
# URL for solr (required unless linked to a container called 'solr')
: ${SOLR_URL:=}
# Email to which errors should be sent (optional, default: none)
: ${ERROR_EMAIL:=}
# SITE_URL default
: ${CKAN_SITE_URL:=}

set -eu

CONFIG="${CKAN_CONFIG}/production.ini"

abort () {
  echo "$@" >&2
  exit 1
}

write_config () {
  "$CKAN_HOME"/bin/paster --plugin=ckan config-tool "$CONFIG" -e \
      "sqlalchemy.url = ${DATABASE_URL}" \
      "solr_url = ${SOLR_URL}" \
      "ckan.site_url = ${CKAN_SITE_URL}" \
      "ckan.harvest.mq.hostname = ${REDIS_PORT_6379_TCP_ADDR}"
}

link_postgres_url () {
  local user=$POSTGRES_USER
  local pass=$POSTGRES_PASSWORD
  local db=$POSTGRES_DB
  local host=$DB_PORT_5432_TCP_ADDR
  local port=$DB_PORT_5432_TCP_PORT
  echo "postgresql://${user}:${pass}@${host}:${port}/${db}"
}

link_solr_url () {
  local host=$SOLR_PORT_8080_TCP_ADDR
  local port=$SOLR_PORT_8080_TCP_PORT
  echo "http://${host}:${port}/solr"
}

# If we don't already have a config file, bootstrap
if [ -e "$CONFIG" ]; then
  if [ -z "$DATABASE_URL" ]; then
    if ! DATABASE_URL=$(link_postgres_url); then
      abort "no DATABASE_URL specified and linked container called 'db' was not found"
    fi
  fi
  if [ -z "$SOLR_URL" ]; then
    if ! SOLR_URL=$(link_solr_url); then
      abort "no SOLR_URL specified and linked container called 'solr' was not found"
    fi
  fi
  write_config
fi
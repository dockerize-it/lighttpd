#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202210181646-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.com
# @@License          :  LICENSE.md
# @@ReadME           :  entrypoint-lighttpd.sh --help
# @@Copyright        :  Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @@Created          :  Tuesday, Oct 18, 2022 16:46 EDT
# @@File             :  entrypoint-lighttpd.sh
# @@Description      :
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  other/docker-entrypoint
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
[ -n "$DEBUG" ] && set -x
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="$(basename "$0" 2>/dev/null)"
VERSION="202210181646-git"
HOME="${USER_HOME:-$HOME}"
USER="${SUDO_USER:-$USER}"
RUN_USER="${SUDO_USER:-$USER}"
SCRIPT_SRC_DIR="${BASH_SOURCE%/*}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set functions
__exec_command() {
  local exitCode=0
  local cmd="${*:-bash -l}"
  echo "Executing command: $cmd"
  eval "$cmd" || exitCode=1
  [ "$exitCode" = 0 ] || exitCode=10
  return ${exitCode:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional functions
__pcheck() { [ -n "$(which pgrep 2>/dev/null)" ] && pgrep "$1" || return 1; }
__find() { find "$1" -mindepth 1 -type f,d 2>/dev/null | grep '^' || return 10; }
__curl() { curl -q -LSsf -o /dev/null -s -w "200" "$@" 2>/dev/null || return 10; }
__pgrep() { __pcheck "$1" || ps aux 2>/dev/null | grep -F " $1" | grep -qv 'grep' || return 10; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__certbot() {
  [ -n "$SSL_CERT_BOT" ] && type -P certbot &>/dev/null || { export SSL_CERT_BOT="" && return 10; }
  certbot certonly --webroot -w "${WWW_ROOT_DIR:-/data/htdocs/www}" -d $DOMANNAME -d $DOMANNAME \
    --put-all-related-files-into "$SSL_DIR" -key-path "$SSL_KEY" -fullchain-path "$SSL_CERT"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__heath_check() {
  status=0 health="Good"
  __pgrep "${1:-$SERVICE_NAME}" || status=$((status + 1))
  #__curl "http://localhost:$HTTP_PORT/server-health" || status=$((status + 1))
  [ "$status" -eq 0 ] || health="Errors reported see docker logs --follow $CONTAINER_NAME"
  echo "$(uname -s) $(uname -m) is running and the health is: $health"
  return ${status:-$?}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# export functions
export -f __exec_command __pgrep __find __curl __heath_check
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define default variables - do not change these - redifine with -e or set under Additional
DISPLAY="${DISPLAY:-}"
LANG="${LANG:-C.UTF-8}"
DOMANNAME="${DOMANNAME:-}"
TZ="${TZ:-America/New_York}"
HTTP_PORT="${HTTP_PORT:-80}"
HTTPS_PORT="${HTTPS_PORT:-443}"
SERVICE_PORT="${SERVICE_PORT:-}"
SERVICE_NAME="${CONTAINER_NAME}"
HOSTNAME="${HOSTNAME:-casjaysdev-lighttpd}"
HOSTADMIN="${HOSTADMIN:-root@${DOMANNAME:-$HOSTNAME}}"
SSL_CERT_BOT="${SSL_CERT_BOT:-false}"
SSL_ENABLED="${SSL_ENABLED:-false}"
SSL_DIR="${SSL_DIR:-/config/ssl}"
SSL_CA="${SSL_CA:-$SSL_DIR/ca.crt}"
SSL_KEY="${SSL_KEY:-$SSL_DIR/server.key}"
SSL_CERT="${SSL_CERT:-$SSL_DIR/server.crt}"
SSL_CONTAINER_DIR="${SSL_CONTAINER_DIR:-/etc/ssl/CA}"
WWW_ROOT_DIR="${WWW_ROOT_DIR:-/data/htdocs}"
LOCAL_BIN_DIR="${LOCAL_BIN_DIR:-/usr/local/bin}"
DEFAULT_DATA_DIR="${DEFAULT_CONF_DIR:-/usr/local/share/template-files/data}"
DEFAULT_CONF_DIR="${DEFAULT_CONF_DIR:-/usr/local/share/template-files/config}"
DEFAULT_TEMPLATE_DIR="${DEFAULT_TEMPLATE_DIR:-/usr/local/share/template-files/defaults}"
CONTAINER_IP_ADDRESS="$(ip a | grep 'inet' | grep -v '127.0.0.1' | awk '{print $2}' | sed 's|/*||g')"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional variables and variable overrides
#export SERVICE_NAME=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Check if this is a new container
[ -f "/data/.docker_has_run" ] && DATA_DIR_INITIALIZED="true" || DATA_DIR_INITIALIZED="false"
[ -f "/config/.docker_has_run" ] && CONFIG_DIR_INITIALIZED="true" || CONFIG_DIR_INITIALIZED="false"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# export variables
export LANG TZ DOMANNAME HOSTNAME HOSTADMIN SSL_ENABLED SSL_DIR SSL_CA SSL_KEY
export SSL_DIR HTTP_PORT HTTPS_PORT LOCAL_BIN_DIR DEFAULT_CONF_DIR CONTAINER_IP_ADDRESS
export SSL_CONTAINER_DIR SSL_CERT_BOT DISPLAY CONFIG_DIR_INITIALIZED DATA_DIR_INITIALIZED
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# import variables from file
[ -f "/root/env.sh" ] && . "/root/env.sh"
[ -f "/config/env.sh" ] && "/config/env.sh"
[ -f "/config/.env.sh" ] && . "/config/.env.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set timezone
[ -n "${TZ}" ] && echo "${TZ}" >"/etc/timezone"
[ -f "/usr/share/zoneinfo/${TZ}" ] && ln -sf "/usr/share/zoneinfo/${TZ}" "/etc/localtime"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set hostname
if [ -n "${HOSTNAME}" ]; then
  echo "${HOSTNAME}" >"/etc/hostname"
  echo "127.0.0.1 ${HOSTNAME} localhost ${HOSTNAME}.local" >"/etc/hosts"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Add domain to hosts file
if [ -n "$DOMANNAME" ]; then
  echo "${HOSTNAME}.${DOMANNAME:-local}" >"/etc/hostname"
  echo "127.0.0.1 ${HOSTNAME} localhost ${HOSTNAME}.local" >"/etc/hosts"
  echo "${CONTAINER_IP_ADDRESS:-127.0.0.1} ${HOSTNAME}.${DOMANNAME}" >>"/etc/hosts"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Delete any gitkeep files
[ -d "/data" ] && rm -Rf "/data/.gitkeep" "/data"/*/*.gitkeep
[ -d "/config" ] && rm -Rf "/config/.gitkeep" "/data"/*/*.gitkeep
[ -f "/usr/local/bin/.gitkeep" ] && rm -Rf "/usr/local/bin/.gitkeep"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create directories
[ -d "/etc/ssl" ] || mkdir -p "$SSL_CONTAINER_DIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create files

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create symlinks

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "$SSL_ENABLED" = "true" ] || [ "$SSL_ENABLED" = "yes" ]; then
  if [ -f "/config/ssl/server.crt" ] && [ -f "/config/ssl/server.key" ]; then
    export SSL_ENABLED="true"
    if [ -n "$SSL_CA" ] && [ -f "$SSL_CA" ]; then
      mkdir -p "$SSL_CONTAINER_DIR/certs"
      cat "$SSL_CA" >>"/etc/ssl/certs/ca-certificates.crt"
      cp -Rf "/config/ssl/." "$SSL_CONTAINER_DIR/"
    fi
  else
    [ -d "$SSL_DIR" ] || mkdir -p "$SSL_DIR"
    create-ssl-cert
  fi
  type update-ca-certificates &>/dev/null && update-ca-certificates
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -f "$SSL_CA" ] && cp -Rfv "$SSL_CA" "$SSL_CONTAINER_DIR/ca.crt"
[ -f "$SSL_KEY" ] && cp -Rfv "$SSL_KEY" "$SSL_CONTAINER_DIR/server.key"
[ -f "$SSL_CERT" ] && cp -Rfv "$SSL_CERT" "$SSL_CONTAINER_DIR/server.crt"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup bin directory
if [ -d "/data/bin" ]; then
  for create_bin in /data/bin/*; do
    create_bin_name="$(basename "$create_bin")"
    ln -sf "$create_bin" "/usr/local/bin/$create_bin_name"
  done
fi # create_bin create_bin_name
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create default config
if [ "$CONFIG_DIR_INITIALIZED" = "false" ] && [ -d "/config" ]; then
  if [ -n "$DEFAULT_TEMPLATE_DIR" ] && [ -d "$DEFAULT_TEMPLATE_DIR" ]; then
    for create_template in "$DEFAULT_TEMPLATE_DIR"/*; do
      create_template_name="$(basename "$create_template")"
      cp -Rf "$create_template" "/config/$create_template_name"
    done
  fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy custom config files
if [ "$CONFIG_DIR_INITIALIZED" = "false" ] && [ -d "/config" ]; then
  for create_config in "$DEFAULT_CONF_DIR"/*; do
    create_config_name="$(basename "$create_config")"
    cp -Rf "$create_config" "/config/$create_config_name"
  done
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy custom data files
if [ "$DATA_DIR_INITIALIZED" = "false" ] && [ -d "/data" ]; then
  for create_data in "$DEFAULT_DATA_DIR"/*; do
    create_data_name="$(basename "$create_data")"
    cp -Rf "$create_data" "/data/$create_data_name"
  done
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy /config to /etc
if [ -d "/config" ]; then
  for create_conf in /config/*; do
    if [ -n "$create_conf" ]; then
      create_conf_name="$(basename "$create_conf")"
      if [ -e "/etc/$create_conf_name" ]; then
        cp -Rf "$create_conf" "/etc/$create_conf_name"
      fi
    fi
  done
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Unset unneeded variables
unset create_bin create_bin_name create_template create_template_name
unset create_data create_data_name create_config create_config_name create_conf create_conf_name
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -f "/data/.docker_has_run" ] || { [ -d "/data" ] && echo "Initialized on: $(date)" >"/data/.docker_has_run"; }
[ -f "/config/.docker_has_run" ] || { [ -d "/config" ] && echo "Initialized on: $(date)" >"/config/.docker_has_run"; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional commands

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
case "$1" in
--help) # Help message
  echo 'Docker container for '$APPNAME''
  echo "Usage: $APPNAME [healthcheck, bash, command]"
  echo "Failed command will have exit code 10"
  echo ""
  exit ${exitCode:-$?}
  ;;

healthcheck) # Docker healthcheck
  __heath_check || exitCode=10
  exit ${exitCode:-$?}
  ;;

*/bin/sh | */bin/bash | bash | shell | sh) # Launch shell
  shift 1
  __exec_command "${@:-/bin/bash}"
  exit ${exitCode:-$?}
  ;;

*) # Execute primary command
  if [ $# -eq 0 ]; then
    echo "Container ip address is: $CONTAINER_IP_ADDRESS"
    start-lighttpd.sh
    exit ${exitCode:-$?}
  else
    __exec_command "$@"
    exitCode=$?
  fi
  ;;
esac
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# end of entrypoint
exit ${exitCode:-$?}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

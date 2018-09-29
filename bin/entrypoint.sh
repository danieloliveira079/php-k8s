#!/usr/bin/env bash

set -eu

COMMAND=${1:-web}

log (){
  DATE=`date '+%Y-%m-%d %H:%M:%S'`
  echo "[INFO] $DATE $1"
}

copy_assets () {
  #used when running inside a K8S POD
  if [[ -d /shared-public-html ]]; then
    cp -R public/* /shared-public-html/
    log "Local assets copied!"
  fi
}

#php artisan 'oberlo:update-dotenv' ${ENVIRONMENT}
#echo "APP_VERSION=${APP_VERSION}" >> .env
php artisan config:cache

case ${COMMAND} in
  worker)
    log "Starting worker..."
    WORKER_DRIVER=${2:-sqs}
    WORKER_QUEUES=${3:-none}
    WORKER_TRIES=${4:-0}
    WORKER_TIMEOUT=${5:-60}
    WORKER_SLEEP=${6:-3}

    exec php artisan queue:work \
      "${WORKER_DRIVER}" \
      --sleep="${WORKER_SLEEP}" \
      --tries="${WORKER_TRIES}" \
      --timeout="${WORKER_TIMEOUT}" \
      --env="${ENVIRONMENT}" \
      --queue="${WORKER_QUEUES}" \
      --quiet
    ;;
  web)
    copy_assets
    log "Starting web..."
    exec php-fpm
    ;;
  provision)
    log "Starting provision..."
    exec php artisan migrate --force --env "${ENVIRONMENT}"
    #php artisan es:index:init
    #php artisan db:seed --class=CountriesTableSeeder
    ;;
  scheduler)
    log "Starting scheduler..."
    exec php artisan schedule:run
    ;;
  *)
    exec php-fpm
    ;;
esac

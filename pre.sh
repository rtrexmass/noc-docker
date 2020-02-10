#!/bin/sh

# setup permissions
# setup promgrafana dashboards\sources

TMPPATH=$(mktemp -d -p /tmp)
TMPPATH1=$(mktemp -d -p /tmp)

CREATEDIR() {
    mkdir -p $INSTALLPATH/data/promgrafana/etc/provisioning/datasources
    mkdir -p $INSTALLPATH/data/promgrafana/etc/provisioning/notifiers
    mkdir -p $INSTALLPATH/data/promgrafana/etc/provisioning/dashboards
    mkdir -p $INSTALLPATH/data/promgrafana/etc/dashboards
    mkdir -p $INSTALLPATH/data/promgrafana/plugins
    mkdir -p $INSTALLPATH/data/promgrafana/db
    mkdir -p $INSTALLPATH/data/promvm
    mkdir -p $INSTALLPATH/data/prometheus/metrics
    mkdir -p $INSTALLPATH/data/prometheus/etc/rules.d
    mkdir -p $INSTALLPATH/data/consul
    mkdir -p $INSTALLPATH/data/clickhouse/data
    mkdir -p $INSTALLPATH/data/nsq
    mkdir -p $INSTALLPATH/data/mongo
    mkdir -p $INSTALLPATH/data/noc/custom
    mkdir -p $INSTALLPATH/data/postgres
    mkdir -p $INSTALLPATH/data/nginx/ssl
    mkdir -p $INSTALLPATH/data/grafana/plugins
    mkdir -p $INSTALLPATH/data/sentry/redis
    mkdir -p $INSTALLPATH/data/sentry/pg
}

SETPERMISSION() {
    chown 101 -R $INSTALLPATH/data/clickhouse/data
    chown 999 -R $INSTALLPATH/data/postgres
    chown 999 -R $INSTALLPATH/data/mongo
    chown 472 -R $INSTALLPATH/data/grafana/
    chown 65534 -R $INSTALLPATH/data/prometheus/metrics
    chown 472 -R $INSTALLPATH/data/promgrafana/plugins
    chown 999 -R $INSTALLPATH/data/sentry/redis
    chown 70 -R $INSTALLPATH/data/sentry/pg
}

SETUPPROMGRAFANA() {
    echo "Clone GRAFANA dashboards from code.getnoc.com"
    cd "$TMPPATH" && git clone https://code.getnoc.com/noc/grafana-selfmon-dashboards.git .
    cp -f -r "$TMPPATH"/dashboards/* "$INSTALLPATH"/data/promgrafana/etc/dashboards
    cp -f -r "$TMPPATH"/provisioning/* "$INSTALLPATH"/data/promgrafana/etc/provisioning
}

SETUPPROMRULES() {
    echo "Clone PROMETHEUS alert rules from code.getnoc.com"
    cd "$TMPPATH1" && git clone https://code.getnoc.com/noc/noc-prometheus-alerts.git .
    cp -f "$TMPPATH1"/*.yml "$INSTALLPATH"/data/prometheus/etc/rules.d
}

SETUPSENTRY() {
    if [ ! -f $INSTALLPATH/data/sentry/sentry.env ]
        then
# @TODO
            GENERATE_PASSWORD="$(dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev)"

            echo "Setup Sentry env in $INSTALLPATH/data/sentry/sentry.env"
            echo "after firsh start need run command for for run migration and setup admin user\passwd"
            echo "docker exec -ti noc-dc_sentry_1 sentry upgrade"
            { echo SENTRY_POSTGRES_HOST=sentry-postgres
              echo SENTRY_DB_NAME=sentry
              echo SENTRY_DB_USER=sentry
              echo SENTRY_DB_PASSWORD="$GENERATE_PASSWORD"
              echo SENTRY_SECRET_KEY="$(dd 'if=/dev/random' 'bs=1' 'count=32' 2>/dev/null | base64)"
              echo SENTRY_REDIS_HOST=sentry-redis
              echo SENTRY_METRICS_SAMPLE_RATE=0.9
              echo POSTGRES_USER=sentry
              echo POSTGRES_DBNAME=sentry
              echo POSTGRES_PASSWORD="$GENERATE_PASSWORD"
              echo "#Important!!! POSTGRES_PASSWORD == SENTRY_DB_PASSWORD"
            } >> $INSTALLPATH/data/sentry/sentry.env
    fi
}

SETUPNOCCONF() {
    if [ ! -f $INSTALLPATH/data/noc/etc/noc.conf ]
        then
            echo "Copy " $INSTALLPATH/data/noc/etc/noc.conf.example " to " $INSTALLPATH/data/noc/etc/noc.conf
            cp $INSTALLPATH/data/noc/etc/noc.conf.example $INSTALLPATH/data/noc/etc/noc.conf
    fi
}

# @TODO
# need check $INSTALLPATH == $COMPOSEPATH and make warning if not
SETUPENV() {
    if [ ! -f $INSTALLPATH/.env ]
        then
            echo "Setup COMPOSEPATH=$INSTALLPATH in $INSTALLPATH/.env"
            echo "COMPOSEPATH=$INSTALLPATH" > $INSTALLPATH/.env
    fi
}

# Setup $INSTALLPATH from second param
if [ -n "$2" ]
    then
        echo "Setup NOC-DC to $2"
        INSTALLPATH="$2"
    else
        INSTALLPATH=/opt/noc-dc
        echo "Setup NOC-DC to $INSTALLPATH"
fi

if [ -n "$1" ]
    then
        if [ "$1" = "all" ]
            then
                CREATEDIR
                SETUPENV
                SETPERMISSION
                SETUPPROMGRAFANA
                SETUPPROMRULES
                SETUPNOCCONF
                SETUPSENTRY
        elif [ "$1" = "perm" ]
            then
                CREATEDIR
                SETPERMISSION
        elif [ "$1" = "grafana" ]
            then
                CREATEDIR
                SETUPPROMGRAFANA
        elif [ "$1" = "promrules" ]
            then
                CREATEDIR
                SETUPPROMRULES
        elif [ "$1" = "nocconf" ]
            then
                SETUPNOCCONF
        elif [ "$1" = "sentry" ]
            then
                SETUPSENTRY
        elif [ "$1" = "env" ]
            then
                SETUPENV
        elif [ "$1" = "help" ]
            then
                echo "pre.sh <all,env,perm,grafana,promrules,nocconf,sentry> <path to install>"
        else
            echo "Unknown parameter"
            echo "Use one of: all,env,perm,grafana,promrules,nocconf,sentry"
        fi
else
    echo "No  parameters found."
    echo "Use one of: all,env,perm,grafana,promrules,nocconf,sentry"
fi

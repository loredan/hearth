#!/bin/bash

check_configuration()
{
    default_password="1234"

    #Security

    if [[ ! -d "security" ]]
    then
        mkdir security
    fi

    if [[ ! -e "security/male_password_hash" ]]
    then
        printf "%s" $default_password | md5sum | cut -c -32 > "security/male_password_hash"
    fi

    if [[ ! -e "security/female_password_hash" ]]
    then
        printf "%s" $default_password | md5sum | cut -c -32 > "security/female_password_hash"
    fi

    #Users

    if [[ ! -d "users" ]]
    then
        mkdir users
    fi

    if [[ ! -e "users/male" ]]; then
        touch users/male
    fi

    if [[ ! -e "users/female" ]]; then
        touch users/female
    fi

    if [[ ! -e "users/config" ]]; then
        touch users/config
    fi

    if [[ -z `cat users/config` ]]; then
        printf "User config empty\n"
        exit 1
    fi
}

check_daemon()
{
    if [[ ! -e hearth_server.pid ]]
    then
        return 1
    fi

    pid=`cat hearth_server.pid`
    if [[ `ps -p $pid | wc -l` > 1 ]]
    then
        return 0
    else
        return 1
    fi
}

launch()
{
    check_daemon
    if [[ $? == 0 ]]
    then
        printf "Daemon already started\n"
        exit 1
    fi

    check_configuration
    exec -a "hearth_server" java -XX:+UseAltSigs -jar hearth_server.jar &
    echo $! > hearth_server.pid
    printf "Daemon started\n"
}

stop()
{
    if [[ ! -e hearth_server.pid ]]
    then
        printf "Daemon is not running\n"
        return 1
    fi

    pid=`cat hearth_server.pid`

    if [[ `ps -p $pid | wc -l` == 1 ]]
    then
        printf "Daemon is not running\n"
    else
        kill -TERM $pid

        timer=0
        while [[ `ps -p $pid | wc -l` > 1 ]]
        do
            if [[ $timer -ge 5 ]]
            then
                kill -KILL $pid
                timer=0
            else
                printf "."
                sleep 1
            fi
            let "timer += 1"
        done

        rm hearth_server.pid

        printf "\nDaemon stopped\n"
    fi
}

cd ${0%/*} #move to script directory

if [[ $# == 0 ]]
then
    launch
fi

if [[ $# == 1 ]]
then
    if [[ ( $1 = "-s" ) || ( $1 = "--start" ) ]]
    then
        launch
    elif [[ ( $1 = "-k" ) || ( $1 = "--kill" ) ]]
    then
        stop
    elif [[ ( $1 = "-r" ) || ( $1 = "--restart" ) ]]; then
        stop
        launch
    else
        printf "Usage: %s [{-s|--start}|{-k|--kill}]\n" ${0##*/}
    fi
fi
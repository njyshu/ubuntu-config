#/bin/sh
start_php() {
    echo -ne Starting php5-cgi...
    exec /usr/local/bin/spawn-fcgi -n -p 9000 -P /var/run/spawn-php-fcgi.pid -C 2 -u www-data -g www-data -f /usr/bin/php5-cgi 2>&1 &
    if [ $? -eq 0 ]
    then
        echo -ne "\t\t\e[32;1mOK\e[0m\n"
    else
        echo -ne "\t\t\e[31;1mFailed\e[0m\n"
    fi
}

stop_php() {
    echo -ne Stopping php5-cgi...
    pkill php5-cgi
    if [ $? -eq 0 ]
    then
        echo -ne "\t\t\e[32;1mOK\e[0m\n"
    else
        echo -ne "\t\t\e[31;1mFailed\e[0m\n"
    fi
}

case $1 in
    start)      start_php

    ;;
    stop)       stop_php
    ;;
    restart)    stop_php
                start_php
    ;;
    *)      echo "Usage: $0 {start|stop|restart}"
    ;;
esac

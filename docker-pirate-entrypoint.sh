#!/bin/bash

if [ ! -z "${WORDPRESS_DB_ROOT_PASSWORD}" ]; then
	echo "You need to pass MySQL's root password as WORDPRESS_DB_ROOT_PASSWORD env variable."
fi

if [ -z "${WORDPRESS_DB_HOST}" ]; then
	: "${WORDPRESS_DB_HOST:=mysql}"
fi

if [ -f /tmp/wordpress-tests-lib/wp-tests-config-sample.php ] && [ ! -z "${WORDPRESS_DB_ROOT_PASSWORD}" ]; then

		TERM=dumb php -- <<'EOPHP'
<?php
$stderr = fopen('php://stderr', 'w');
list($host, $socket) = explode(':', getenv('WORDPRESS_DB_HOST'), 2);
$port = 0;
if (is_numeric($socket)) {
	$port = (int) $socket;
	$socket = null;
}
$user = getenv('WORDPRESS_DB_USER');
$pass = getenv('WORDPRESS_DB_ROOT_PASSWORD');
$dbName = getenv('WORDPRESS_DB_NAME') . '_unit_testing';

if ( empty( $host ) ) {
	$host = 'mysql';
}

$maxTries = 10;
do {
	$mysql = new mysqli($host, 'root', $pass, '', $port, $socket);
	if ($mysql->connect_error) {
		fwrite($stderr, "\n" . 'MySQL Connection Error: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n");
		--$maxTries;
		if ($maxTries <= 0) {
			exit(1);
		}
		sleep(3);
	}
} while ($mysql->connect_error);
if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `' . $mysql->real_escape_string($dbName) . '`')) {
	fwrite($stderr, "\n" . 'MySQL "CREATE DATABASE" Error: ' . $mysql->error . "\n");
	$mysql->close();
	exit(1);
}
$mysql->close();
EOPHP

	sed_escape_lhs() {
		echo "$@" | sed -e 's/[]\/$*.^|[]/\\&/g'
	}

	sed_escape_rhs() {
		echo "$@" | sed -e 's/[\/&]/\\&/g'
	}

	php_escape() {
		local escaped="$(php -r 'var_export(('"$2"') $argv[1]);' -- "$1")"
		if [ "$2" = 'string' ] && [ "${escaped:0:1}" = "'" ]; then
			escaped="${escaped//$'\n'/"' + \"\\n\" + '"}"
		fi
		echo "$escaped"
	}

	set_config() {
		key="$1"
		value="$2"
		var_type="${3:-string}"
		start="(['\"])$(sed_escape_lhs "$key")\2\s*,"
		end="\);"
		if [ "${key:0:1}" = '$' ]; then
			start="^(\s*)$(sed_escape_lhs "$key")\s*="
			end=";"
		fi
		sed -ri -e "s/($start\s*).*($end)$/\1$(sed_escape_rhs "$(php_escape "$value" "$var_type")")\3/" /tmp/wordpress-tests-lib/wp-tests-config.php
	}

	mv /tmp/wordpress-tests-lib/wp-tests-config-sample.php /tmp/wordpress-tests-lib/wp-tests-config.php
	sed -i.bak "s:dirname( __FILE__ ) . '/src/':'/var/www/html/':" /tmp/wordpress-tests-lib/wp-tests-config.php
	set_config 'DB_HOST' "$WORDPRESS_DB_HOST"
	set_config 'DB_USER' "root"
	set_config 'DB_PASSWORD' "$WORDPRESS_DB_ROOT_PASSWORD"
	set_config 'DB_NAME' "${WORDPRESS_DB_NAME}_unit_testing"
	rm /tmp/wordpress-tests-lib/wp-tests-config.php.bak

	uniqueEnvs=(
		AUTH_KEY
		SECURE_AUTH_KEY
		LOGGED_IN_KEY
		NONCE_KEY
		AUTH_SALT
		SECURE_AUTH_SALT
		LOGGED_IN_SALT
		NONCE_SALT
	)

	for unique in "${uniqueEnvs[@]}"; do
		uniqVar="WORDPRESS_$unique"
		if [ -n "${!uniqVar}" ]; then
			set_config "$unique" "${!uniqVar}"
		else
			set_config "$unique" "$(head -c1m /dev/urandom | sha1sum | cut -d' ' -f1)"
		fi
	done

fi

exec docker-entrypoint.sh "$@"
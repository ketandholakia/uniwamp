[mysqld]
port={{DB_PORT}}
basedir={{MARIADB_DIR}}
datadir={{MARIADB_DATA_DIR}}
socket={{TMP_DIR}}/mariadb.sock
pid-file={{LOGS_DIR}}/mariadb.pid
log-error={{LOGS_DIR}}/mariadb-error.log
tmpdir={{TMP_DIR}}

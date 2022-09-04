#!/bin/bash
#
# Create the database for sheGet. The database is in the following form:
# URL (string, primary key, unique) | priority (integer) | complete (integer)
#
if [ -z "$1" ]; then
	echo Please provide a valid path for the database
	echo USAGE:
	echo sheget-makedb.sh path/to/sqlite.db
	exit 1
fi

sqlite3 $1 'CREATE TABLE downloads(
	url TEXT PRIMARY KEY UNIQUE NOT NULL,
	priority INTEGER NOT NULL,
	complete INTEGER NOT NULL
);'

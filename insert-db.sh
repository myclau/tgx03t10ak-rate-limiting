#!/bin/bash
sqlite3 "$1"<< END_SQL
$2
END_SQL
./checker.sh "$1" "$3"
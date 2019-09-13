#!/bin/sh
for i in 1 2 3 4 5
do
	cd level$i
  if eval "./test.sh"; then
    echo "level $i - \033[0;32mOK\033[0m"
	else
    echo "level $i - \033[0;31mKO\033[0m"
	fi
	cd ..
done
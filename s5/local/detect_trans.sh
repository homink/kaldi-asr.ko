#!/bin/bash

cat $2 | while read uid;do
  transid=$(cut -d'_' -f2-3 <<< $uid)
  spkid=$(cut -d'_' -f1 <<< $uid)
  echo $spkid"_"$(grep $transid $1 | sed -e "s/[.?!,]\+//g")
done

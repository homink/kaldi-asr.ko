#!/bin/bash

corpus=$1
data=$2

echo "$0 $@"  # Print the command line for logging

transfile=$corpus/script_nmbd_by_sentence.txt

mkdir -p $data

python -c '
#! /usr/bin/python
# -*- coding: utf-8 -*-
import sys,codecs,re

fin=codecs.open(sys.argv[1],"r","utf-8")
content = fin.read()
fin.close()

content = re.sub(ur"[\d]+\.",u"",content)
content = re.sub(ur"[‘’…“”「」<>~]","",content)
tokens = filter(None, re.split(ur"[\., \-!?:]+",content.replace("\n"," ")))
tokens2 = "\n".join(list(set(tokens)))
print(tokens2.encode("utf-8"))
' $transfile | awk '{ print length(), $0 | "sort -n" }' > $data/tokens.tmp

[ -f $data/lexicon.txt ] && rm -f $data/lexicon.txt
[ -f $data/lexiconp.txt ] && rm -f $data/lexiconp.txt
echo "!SIL"$'\t'"SIL" >> $data/lexicon.txt
echo "<SPOKEN_NOISE>"$'\t'"SPN" >> $data/lexicon.txt
echo "<UNK>"$'\t'"SPN" >> $data/lexicon.txt
echo "!SIL"$'\t'"1.0"$'\t'"SIL" >> $data/lexiconp.txt
echo "<SPOKEN_NOISE>"$'\t'"1.0"$'\t'"SPN" >> $data/lexiconp.txt
echo "<UNK>"$'\t'"1.0"$'\t'"SPN" >> $data/lexiconp.txt
cat $data/tokens.tmp | while read line;do
  line2=$(awk '{print $2}' <<< $line)
  echo $line2$'\t'$(python local/g2p.py $line2 local/rulebook.txt) >> $data/lexicon.txt
  echo $line2$'\t'"1.0"$'\t'$(python local/g2p.py $line2 local/rulebook.txt) >> $data/lexiconp.txt
done

# silence.
echo -e "<SIL>\n<SPN>" >  $data/silence_phones.txt
echo "silence.txt file was generated."

# nonsilence.
awk '{$1=""; print $0}' $data/lexicon.txt | tr -s ' ' '\n' | sort -u | sed '/^$/d' >  $data/nonsilence_phones.txt
echo "nonsilence.txt file was generated."

# optional_silence.
echo '<SIL>' >  $data/optional_silence.txt
echo "optional_silence.txt file was generated."

# extra_questions.
cat $data/silence_phones.txt| awk '{printf("%s ", $1);} END{printf "\n";}' > $data/extra_questions.txt || exit 1;
cat $data/nonsilence_phones.txt | perl -e 'while(<>){ foreach $p (split(" ", $_)) {  $p =~ m:^([^\d]+)(\d*)$: || die "Bad phone $_"; $q{$2} .= "$p "; } } foreach $l (values %q) {print "$l\n";}' >> $data/extra_questions.txt || exit 1;
echo "extra_questions.txt file was generated."


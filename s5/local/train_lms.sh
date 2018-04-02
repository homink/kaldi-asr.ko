#!/bin/bash

echo "$0 $@"  # Print the command line for logging
. utils/parse_options.sh || exit 1;

use_sejong=1
dir=data/local/local_lm
srcdir=$1
lang=$2
corpus=$3
mkdir -p $dir
. ./path.sh || exit 1; # for KALDI_ROOT

awk '{print $1}' $srcdir/lexicon.txt | grep -v -w '!SIL' > $dir/wordlist.txt

if [ "$use_sejong" -lt 1 ];then
  cut -d' ' -f2- data/local/train/text | sed 's/^ //g' | shuf | gzip -c > $dir/train.gz
  cut -d' ' -f2- data/local/test/text | sed 's/^ //g' > $dir/heldout
  ngram-count -text $dir/train.gz -lm $dir/ko_corpus.gz
  lm=$dir/ko_corpus.gz
else
  encoding_type=$(file -b -i $corpus | sed 's/.*charset=//g')
  if [ "$encoding_type" != "utf-8" ];then
    echo "$corpus has $encoding_type encoding, converting to utf-8"
    fname=$(basename "$corpus")
    iconv -f $encoding_type -t UTF-8 $corpus > $dir/$fname.utf8
    corpus=$dir/$fname.utf8
    echo $corpus
  fi
  grep -vP '[\p{Han}]' $corpus | grep -v [0-9] | \
    sed -e "s/[[:punct:]]\+//g" | sed 's/  */ /g' | shuf | \
    gzip -c > $dir/cleaned.gz

  gunzip -c $dir/cleaned.gz | head -n 70000 > $dir/heldout
  gunzip -c $dir/cleaned.gz | tail -n 643742 | gzip -c > $dir/train.gz
  ngram-count -text $dir/train.gz -order 3 -limit-vocab -vocab $dir/wordlist.txt \
    -unk -map-unk "<UNK>" -kndiscount -interpolate -lm $dir/ko_corpus.o3g.kn.gz
  lm=$dir/ko_corpus.o3g.kn.gz
fi

echo "PPL for NIKL LM:"
ngram -unk -lm $lm -ppl $dir/heldout
ngram -unk -lm $lm -ppl $dir/heldout -debug 2 >& $dir/ppl2

gunzip -c $lm | \
arpa2fst --disambig-symbol=#0 \
         --read-symbol-table=$lang/words.txt - $lang/G.fst || exit 1;
fstisstochastic $lang/G.fst


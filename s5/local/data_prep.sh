#!/bin/bash

corpus=$1
data=$2
stage=0


mkdir -p $data

function nums {
  if [ "$1" -lt 10 ];then
    echo "0""$1"
  else
    echo "$1"
  fi
}

function multicpu_process {
  num_cpus=$(grep -c ^processor /proc/cpuinfo)
  input_file=$1;output_file=$2;run_cmd=$3;arg1=$4
  split -l $(echo $(($(wc -l $input_file | awk '{print $1}') / $(expr $num_cpus - 1)))) \
    $input_file -d $input_file"_sub."
  for x in `seq 0 1 $(expr $num_cpus - 1)`;do
     cp $input_file"_sub."$(printf "%02d\n" $x) $input_file"_resub."$(printf "%01d\n" $(expr $x + 1))
  done
  utils/run.pl JOB=1:$num_cpus $input_file.JOB.info \
      $run_cmd $arg1 $input_file"_resub."JOB JOB || exit 1;
  rm -f $output_file
  for x in `seq 1 1 $num_cpus`;do
    cat $input_file.$x.info | grep -v "#" >> $output_file
  done
  rm -f $input_file"_sub."* $input_file"_resub."*
}

if [ $stage -le 0 ]; then

  find $corpus -name "*.wav" | grep -v "Bad\|Non\|small" | sort | uniq > $data/wav.lst
  age=$(cat data/wav.lst | rev | cut -d '/' -f 2 | rev | sed 's/[0-9].*//g' | sort | uniq)

  rm -f $data/wav.test.lst
  rm -f $data/wav.train.lst
  for ad in $age;do
    for ((ns=1;ns<=20;ns++));do
      for ((tp=1;tp<=19;tp++));do
        if [ "$ns" -gt 18 ];then
          if [ "$tp" -gt 17 ];then
            if [[ $ad == *"v"* ]] || [[ $ad == *"x"* ]] || [[ $ad == *"w"* ]]; then
              echo $ad$(nums $ns)"_t"$(nums $tp)
              grep $ad$(nums $ns)"_t"$(nums $tp) $data/wav.lst >> $data/wav.test.lst
            fi
          fi
        else
          if [ "$tp" -lt 18 ];then
            grep $ad$(nums $ns)"_t"$(nums $tp) $data/wav.lst >> $data/wav.train.lst
          fi
        fi
      done
    done
  done

  echo "training wav $(wc -l $data/wav.train.lst) will be processed"
  echo "test wav $(wc -l $data/wav.test.lst) will be processed"
fi

if [ $stage -le 1 ]; then
  mkdir -p $data/train
  mkdir -p $data/test
  rm -f $data/*/wav.scp
  rm -f $data/*/text
  rm -f $data/*/utt2spk
  rm -f $data/*/spk2utt

  for x in test train;do
    cat data/wav.$x.lst | rev | cut -d'/' -f 1 | rev | sed 's/.wav//g' > $data/uid.$x.lst
    cat data/wav.$x.lst | rev | cut -d'/' -f 2 | rev  > $data/spk.$x.lst
    paste $data/uid.$x.lst $data/wav.$x.lst | awk '{print $1" "$2}' > $data/$x/wav.scp || exit 1
    paste $data/uid.$x.lst $data/spk.$x.lst | awk '{print $1" "$2}' > $data/$x/utt2spk || exit 1
    cat $data/$x/utt2spk | utils/utt2spk_to_spk2utt.pl > $data/$x/spk2utt || exit 1;
    cat $data/uid.$x.lst | while read uid;do
      transid=$(cut -d'_' -f2-3 <<< $uid)
      spkid=$(cut -d'_' -f1 <<< $uid)
      echo $spkid"_"$(grep $transid $corpus/trans.txt | sed -e "s/[.,?!]\+//g") >> $data/$x/text
    done
    #multicpu_process $data/uid.$x.lst $data/$x/text local/detect_trans.sh $corpus/trans.txt
  done
fi

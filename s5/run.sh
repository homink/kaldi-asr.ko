#!/bin/bash

. ./cmd.sh
. ./path.sh

nj=12
stage=0
train_set=train
test_sets=test
decode=true
. parse_options.sh  # e.g. this parses the --stage option if supplied.

nikl=/home/kwon/copora/NIKL
sejong=/home/kwon/copora

if [ $stage -le 1 ]; then
  local/data_prep.sh $nikl data || exit 1
  local/prepare_dict.sh $nikl data/local/dict_nosp || exit 1
  utils/prepare_lang.sh data/local/dict_nosp "<SPOKEN_NOISE>" data/lang_tmp_nosp data/lang_nosp || exit 1;
  local/train_lms.sh data/local/dict_nosp data/lang_nosp $sejong

  for x in $test_sets;do
    steps/make_mfcc.sh --cmd "$train_cmd" --nj 10 data/$x || exit 1;
    steps/compute_cmvn_stats.sh data/$x || exit 1;
    utils/fix_data_dir.sh data/$x
  done

  steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj data/$train_set || exit 1;
  steps/compute_cmvn_stats.sh data/$train_set || exit 1;
  utils/fix_data_dir.sh data/$train_set

  utils/subset_data_dir.sh --shortest data/$train_set 2000 data/train_2kshort || exit 1;
  utils/subset_data_dir.sh --shortest data/$train_set 10000 data/train_10k || exit 1;
fi

if [ $stage -le 2 ]; then
  train_set=train_2kshort
  if $train; then
    steps/train_mono.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
      data/$train_set data/lang_nosp exp/mono || exit 1;
  fi

  utils/mkgraph.sh data/lang_nosp exp/mono exp/mono/graph_nosp

  if $decode; then
    for test_set in $test_sets;do
      steps/decode.sh --nj 8 --cmd "$decode_cmd" exp/mono/graph_nosp \
        data/$test_set exp/mono/decode_nosp
      steps/scoring/score_kaldi_cer.sh --stage 2 --cmd "$decode_cmd" data/$test_set \
        exp/mono/graph_nosp exp/mono/decode_nosp
    done

  fi
fi

if [ $stage -le 3 ]; then

  # tri1
  if $train; then
    train_set=train_10k
    steps/align_si.sh --boost-silence 1.25 --nj $nj --cmd "$train_cmd" \
      data/$train_set data/lang_nosp exp/mono exp/mono_ali || exit 1;

    steps/train_deltas.sh --boost-silence 1.25 --cmd "$train_cmd" 2800 20000 \
      data/$train_set data/lang_nosp exp/mono_ali exp/tri1 || exit 1;
  fi

  utils/mkgraph.sh data/lang_nosp \
    exp/tri1 exp/tri1/graph_nosp || exit 1;

  if $decode; then
    for test_set in $test_sets;do
      steps/decode.sh --nj 8 --cmd "$decode_cmd" exp/tri1/graph_nosp \
        data/$test_set exp/tri1/decode_nosp
      steps/scoring/score_kaldi_cer.sh --stage 2 --cmd "$decode_cmd" data/$test_set \
        exp/tri1/graph_nosp exp/tri1/decode_nosp
    done
  fi
fi

if [ $stage -le 4 ]; then
  train_set=train
  if $train; then
    steps/align_si.sh --nj $nj --cmd "$train_cmd" \
      data/$train_set data/lang_nosp exp/tri1 exp/tri1_ali || exit 1;

    steps/train_lda_mllt.sh --cmd "$train_cmd" \
      --splice-opts "--left-context=3 --right-context=3" 2500 15000 \
      data/$train_set data/lang_nosp exp/tri1_ali exp/tri2 || exit 1;
  fi

  utils/mkgraph.sh data/lang_nosp \
    exp/tri2 exp/tri2/graph_nosp || exit 1;

  if $decode; then
    for test_set in $test_sets;do
      steps/decode.sh --nj 8 --cmd "$decode_cmd" exp/tri2/graph_nosp \
        data/$test_set exp/tri2/decode_nosp;
      steps/scoring/score_kaldi_cer.sh --stage 2 --cmd "$decode_cmd" data/$test_set \
        exp/tri2/graph_nosp exp/tri2/decode_nosp
    done


    # Demonstrating Minimum Bayes Risk decoding (like Confusion Network decoding):
    mkdir exp/tri2/decode_nosp_mbr
    cp exp/tri2/decode_nosp/lat.*.gz \
       exp/tri2/decode_nosp_mbr

    local/score_mbr.sh --cmd "$decode_cmd"  \
       data/$test_sets data/lang_nosp \
       exp/tri2/decode_nosp_mbr
  fi
fi

if [ $stage -le 5 ]; then
  # From 2 system, train 3b which is LDA + MLLT + SAT.

  # Align tri2 system with all the si284 data.
  if $train; then
    steps/align_si.sh  --nj $nj --cmd "$train_cmd" \
      data/$train_set data/lang_nosp exp/tri2 exp/tri2_ali  || exit 1;

    steps/train_sat.sh --cmd "$train_cmd" 4200 40000 \
      data/$train_set data/lang_nosp exp/tri2_ali exp/tri3 || exit 1;
  fi

  utils/mkgraph.sh data/lang_nosp \
    exp/tri3 exp/tri3/graph_nosp || exit 1;

  if $decode; then
    for test_set in $test_sets;do
      steps/decode_fmllr.sh --nj $nj --cmd "$decode_cmd" \
        exp/tri3/graph_nosp data/$test_set \
        exp/tri3/decode_nosp
      steps/scoring/score_kaldi_cer.sh --stage 2 --cmd "$decode_cmd" data/$test_set \
        exp/tri3/graph_nosp exp/tri3/decode_nosp
    done
  fi
fi

if [ $stage -le 6 ]; then
  # Estimate pronunciation and silence probabilities.

  # Silprob for normal lexicon.
  steps/get_prons.sh --cmd "$train_cmd" \
    data/$train_set data/lang_nosp exp/tri3 || exit 1;

  utils/dict_dir_add_pronprobs.sh --max-normalize true \
    data/local/dict_nosp \
    exp/tri3/pron_counts_nowb.txt exp/tri3/sil_counts_nowb.txt \
    exp/tri3/pron_bigram_counts_nowb.txt data/local/dict_sp || exit 1

  utils/prepare_lang.sh data/local/dict_sp \
    "<SPOKEN_NOISE>" data/local/lang_tmp data/lang_sp || exit 1;

  cp data/lang_nosp/G.* data/lang_sp/
fi

if [ $stage -le 7 ]; then
  steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" \
  data/$train_set data/lang_sp exp/tri3 exp/tri3_ali || exit 1;

  # From 3b system, now using data/lang as the lang directory (we have now added
  # pronunciation and silence probabilities), train another SAT system (tri4).
  if $train; then
    steps/train_sat.sh  --cmd "$train_cmd" 4200 40000 \
      data/$train_set data/lang_sp exp/tri3_ali exp/tri4 || exit 1;
  fi

  utils/mkgraph.sh data/lang_sp \
    exp/tri4 exp/tri4/graph_sp || exit 1;

  if $decode; then
    for test_set in $test_sets;do
      steps/decode_fmllr.sh --nj 8 --cmd "$decode_cmd" \
        exp/tri4/graph_sp data/$test_sets \
        exp/tri4/decode_sp || exit 1;
      steps/scoring/score_kaldi_cer.sh --stage 2 --cmd "$decode_cmd" data/$test_set \
        exp/tri4/graph_sp exp/tri4/decode_sp
    done
  fi
fi

if [ $stage -le 8 ]; then
  #local/nnet3/run_tdnn_1a.sh --nj $nj
  local/nnet3/run_tdnn_1a.sh --nnet3_affix "_7e902f5"
fi

export use_stage8_res=true
if [ $stage -le 9 ]; then
  if $use_stage8_res; then
    # reuse data created from run_tdnn_1a.sh
    mkdir -p exp/$(basename exp/*_7e902f5)_lstm
    cd exp/$(basename exp/*_7e902f5)_lstm
    ln -s ../$(basename exp/*_7e902f5)/* ./
    rm -f tdnn1a*;cd ../../
    local/nnet3/run_tdnn_lstm_1a.sh --stage 15 --nnet3_affix "_7e902f5_lstm"
  else
    local/nnet3/run_tdnn_lstm_1a.sh --nnet3_affix "_7e902f5_tdnn_lstm"
  fi
fi

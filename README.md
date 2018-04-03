# kaldi-asr.ko

This repository includes bash and Python2.7 scripts written in the convention form of Kaldi recipes for Korean ASR.

## Motivation

[Kaldi Speech Recognition Toolkit](https://github.com/kaldi-asr/kaldi) has been such an active project for ASR development but not much work has been available for Korean from scratch. 3 open resources - 1) Korean read speech corpus (about 120 hours, 17GB) from National Institude of Korean Language (NIKL), 2) Korean G2P, 3) Sejong linguistic corpus from National Institude of Korean Language (NIKL) - are fully integrated for Korean ASR in the Kaldi framework

## Features

1. Latest kaldi recipe based on wsj in [here](https://github.com/kaldi-asr/kaldi/blob/7e902f535cf58f4ffe98cb9298c3867fe084fecf/egs/wsj/s5/run.sh)

2. Korean read speech corpus : about 120 hours (17GB)

* http://www.korean.go.kr/front/board/boardStandardView.do?board_id=4&mn_id=17&b_seq=464

* https://ithub.korean.go.kr/user/corpus/referenceManager.do

3. Korean grapheme-to-phone conversion in Python in [here](https://github.com/scarletcho/KoG2P)

* Numerical expressions and non-Korean characters are not supported.

4. Language model building with Sejong corpus from NIKL

* https://ithub.korean.go.kr/user/total/referenceView.do?boardSeq=5&articleSeq=113&boardGb=M&isInsUpd=&boardType=CORPUS

* https://ithub.korean.go.kr/user/total/referenceView.do?boardSeq=5&articleSeq=114&boardGb=M&isInsUpd=&boardType=CORPUS

* https://ithub.korean.go.kr/user/total/referenceView.do?boardSeq=5&articleSeq=115&boardGb=M&isInsUpd=&boardType=CORPUS


## Installation

```
git clone https://github.com/kaldi-asr/kaldi.git
cd kaldi
git checkout 7e902f5
```

Careully read [tools/INSTALL](https://github.com/kaldi-asr/kaldi/blob/7e902f535cf58f4ffe98cb9298c3867fe084fecf/tools/INSTALL) and install it first. You will need to execute [extras/install_srilm.sh](https://github.com/kaldi-asr/kaldi/blob/7e902f535cf58f4ffe98cb9298c3867fe084fecf/tools/extras/install_srilm.sh) for LM building, requiring additaion manual downloading. You will find details on the prompt line if you don't have it.

When you pass the above, carefully read [src/INSTALL](https://github.com/kaldi-asr/kaldi/blob/7e902f535cf58f4ffe98cb9298c3867fe084fecf/src/INSTALL).

You may do the followings if your system is identical with me.

```
cd tools
extras/check_dependencies.sh
make -j 4
extras/install_srilm.sh
cd ../src
./configure --shared --use-cuda=yes
make depend -j 8
make -j 8
```

## Speech corpus preparation

Follow https://github.com/homink/speech.ko and let [run.sh](https://github.com/homink/kaldi-asr.ko/blob/master/s5/run.sh) know where it is located. You need to locate Sejong corpus as well.

## Training and decoding

```
run.sh
```

If you stopped in the middle of stages in run.sh, you may want to jump in somewhere to start as follows:

```
run.sh --stage 8
```

You will find the decoding results as follows:

```
head exp/chain_7e902f5/tdnn1a_sp_online/decode_sp/scoring_kaldi/penalty_0.0/10.txt 
fv19_t18_s01 조상에게 가난을 먼저 배운 아이들 
fv19_t18_s02 좀더 잘 가르치고 싶고 잘 피우고 싶은 네 조국의 아이들 
fv19_t18_s03 나의 살던 고향은 꽃피는 산골 아이들의 노래 소리가 유리창을 넘어 봄바람을 타고 조용한 마을에 퍼진다 
fv19_t18_s04 한 줄은 찰찰이 한 줄은 짝짝이 한 줄은 작은북 큰 목 실로폰 풍금소리 등에 어울려 봄의 심포니를 이룬다 
fv19_t18_s05 악기라고 해야 헌 바가지를 잘라 종이를 팽팽히 발라서 만든 것이고 깡통에 고운 모래를 담아서 흔들거나 사이다 병을 세 젓가락으로 두 박자를 맞추는 것이지만 즐겁고 흥겹기가 비길 바가 없다 
fv19_t18_s06 훈훈한 열기와 고조된 서정이 교실에 가득 차고 아이들의 눈동자는 더 빛나고 초롱초롱해진다 
fv19_t18_s07 아까부터 자꾸만 박자가 틀리던 착한 녀석에게 눈을 흘겨도 녀석은 여전히 틀리고 나를 흙을 쳐다보고는 벙긋 웃기만 한다 
fv19_t18_s08 땐 땡땡 땐 끝 종이 울린다 
fv19_t18_s09 책보를 싸세요 하는 나의 말이 떨어지자 교실은 떠들썩해지고 어수선해진다 
fv19_t18_s10 잠깐 교무실에 다녀온 사이다 

tail exp/chain_7e902f5_lstm/tdnn_lstm1a_sp_online/decode_sp/scoring_kaldi/penalty_0.0/10.txt 
mw20_t19_s31 그리고는 아 개울에서 알몸으로 않는다 
mw20_t19_s32 그래서 내가 놀던 그 물 속에서 
mw20_t19_s33 되도록이면 어려운 생각을 하지 않는다 
mw20_t19_s34 되도록이면 적게 먹는다 
mw20_t19_s35 되도록이면 적게 마신다 
mw20_t19_s36 되도록이면 적게 담배를 피운다 
mw20_t19_s37 되도록이면 말을 하지 않는다 
mw20_t19_s38 되도록이면 마음을 열어 놓고 산다 
mw20_t19_s39 이렇게 매년 되풀이되는 것이 나의 피어 생활이다 
mw20_t19_s40 그리고 발을 말이면 서울로 올라온다 
```

You will be able to get WER rate as follows:
```
cat `find exp -name "best_wer"`
%WER 87.55 [ 5127 / 5856, 219 ins, 735 del, 4173 sub ] exp/mono/decode_nosp/wer_13_1.0
%WER 61.97 [ 3629 / 5856, 602 ins, 192 del, 2835 sub ] exp/tri1/decode_nosp/wer_17_1.0
%WER 17.62 [ 1032 / 5856, 146 ins, 84 del, 802 sub ] exp/tri2/decode_nosp/wer_13_1.0
%WER 12.89 [ 755 / 5856, 165 ins, 44 del, 546 sub ] exp/tri4/decode_sp/wer_14_0.5
%WER 19.38 [ 1135 / 5856, 258 ins, 62 del, 815 sub ] exp/tri4/decode_sp.si/wer_12_1.0
%WER 13.83 [ 810 / 5856, 145 ins, 81 del, 584 sub ] exp/chain_7e902f5/tdnn1a_sp/decode_sp/wer_10_1.0
%WER 13.76 [ 806 / 5856, 145 ins, 82 del, 579 sub ] exp/chain_7e902f5/tdnn1a_sp_online/decode_sp/wer_10_1.0
%WER 22.40 [ 1312 / 5856, 183 ins, 95 del, 1034 sub ] exp/chain_7e902f5_lstm/tdnn_lstm1a_sp/decode_sp/wer_8_1.0
%WER 22.56 [ 1321 / 5856, 190 ins, 93 del, 1038 sub ] exp/chain_7e902f5_lstm/tdnn_lstm1a_sp/decode_looped_sp/wer_8_1.0
%WER 22.59 [ 1323 / 5856, 170 ins, 109 del, 1044 sub ] exp/chain_7e902f5_lstm/tdnn_lstm1a_sp_online/decode_sp/wer_9_1.0
```

[run.sh](https://github.com/homink/kaldi-asr.ko/blob/master/s5/run.sh) inlcudes CER calcluation although it prints "%WER" prefix. You can get CER rate with the following command.
```
cat `find exp -name "best_cer"`
%WER 71.56 [ 11484 / 16048, 410 ins, 1882 del, 9192 sub ] exp/mono/decode_nosp/cer_10_1.0
%WER 41.77 [ 6704 / 16048, 541 ins, 700 del, 5463 sub ] exp/tri1/decode_nosp/cer_16_1.0
%WER 9.57 [ 1535 / 16048, 173 ins, 209 del, 1153 sub ] exp/tri2/decode_nosp/cer_11_1.0
%WER 6.33 [ 1016 / 16048, 156 ins, 122 del, 738 sub ] exp/tri4/decode_sp/cer_13_1.0
%WER 6.55 [ 1051 / 16048, 201 ins, 125 del, 725 sub ] exp/chain_7e902f5/tdnn1a_sp/decode_sp/cer_8_1.0
%WER 6.59 [ 1057 / 16048, 189 ins, 146 del, 722 sub ] exp/chain_7e902f5/tdnn1a_sp_online/decode_sp/cer_9_1.0
%WER 11.88 [ 1907 / 16048, 240 ins, 210 del, 1457 sub ] exp/chain_7e902f5_lstm/tdnn_lstm1a_sp/decode_sp/cer_7_1.0
%WER 11.88 [ 1906 / 16048, 246 ins, 205 del, 1455 sub ] exp/chain_7e902f5_lstm/tdnn_lstm1a_sp/decode_looped_sp/cer_7_1.0
%WER 11.86 [ 1903 / 16048, 248 ins, 205 del, 1450 sub ] exp/chain_7e902f5_lstm/tdnn_lstm1a_sp_online/decode_sp/cer_7_1.0
```

## Acknowledgements

* https://github.com/hyung8758/kaldi_tutorial
* https://github.com/scarletcho/KoG2P
* http://www.korean.go.kr/
* https://github.com/kaldi-asr/kaldi/tree/master/egs/wsj
* https://github.com/kaldi-asr/kaldi/tree/master/egs/csj

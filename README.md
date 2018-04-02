# kaldi-asr.ko

This repository includes bash and Python2.7 scripts written in the convention form of Kaldi recipes for Korean ASR.

## Motivation

kaldi project has been such an active project for ASR development but not much work has been available for Korean from scratch. 3 open resources - 1) Korean read speech corpus (about 120 hours, 17GB) from National Institude of Korean Language (NIKL), 2) Korean G2P, 3) Sejong linguistic corpus from National Institude of Korean Language (NIKL) - are fully integrated for Korean ASR research in the kaldi framework

## Features

1. Latest kaldi recipe based on wsj in [here](https://github.com/kaldi-asr/kaldi/blob/7e902f535cf58f4ffe98cb9298c3867fe084fecf/egs/wsj/s5/run.sh)

2. Korean read speech corpus : about 120 hours (17GB)

http://www.korean.go.kr/front/board/boardStandardView.do?board_id=4&mn_id=17&b_seq=464

https://ithub.korean.go.kr/user/corpus/referenceManager.do

3. Korean grapheme-to-phone conversion in Python in [here](https://github.com/scarletcho/KoG2P)

4. Language model building with Sejong corpus from NIKL

https://ithub.korean.go.kr/user/total/referenceView.do?boardSeq=5&articleSeq=113&boardGb=M&isInsUpd=&boardType=CORPUS

https://ithub.korean.go.kr/user/total/referenceView.do?boardSeq=5&articleSeq=114&boardGb=M&isInsUpd=&boardType=CORPUS

https://ithub.korean.go.kr/user/total/referenceView.do?boardSeq=5&articleSeq=115&boardGb=M&isInsUpd=&boardType=CORPUS


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

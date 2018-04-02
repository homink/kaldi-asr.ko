#! /usr/bin/python2.7
# -*- coding: utf-8 -*-

import sys,codecs,re

fin=codecs.open(sys.argv[1],'r','utf-8')
content = fin.read()
fin.close()

content = re.sub(ur"흐흐흐⋯⋯",u"흐흐흐",content)
content = re.sub(ur"들이켰으면⋯⋯",u"들이켰으면",content)
content = re.sub(ur"찌익ꠏꠏꠏ깔기는",u"찌익깔기는",content)
content = re.sub(ur"삐익ꠏꠏꠏꠏ",u"삐익",content)
content = re.sub(ur"[\d]+\.",u"",content)
content = re.sub(ur"\ufeff",u"",content)
content = content.replace('\r\n','\n')
content2 = content.split(')')
content3 = []
for c in content2:
  cc = re.sub(ur'\(.*$','',c)
  cc = re.sub(ur'[‘’…“”「」<>"~]','',cc)
  content3.append(cc)

content = "".join(content3)
tokens = filter(None, re.split(ur'[\., \-!?:]+',content.replace('\n',' ')))
tokens2 = '\n'.join(list(set(tokens)))
print(tokens2.encode('utf-8'))

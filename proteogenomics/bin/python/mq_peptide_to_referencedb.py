#!/usr/bin/env python

import pandas as pd
import importlib.machinery
import sys
import os
import collections
from collections import defaultdict
import json
import sequtils
import shutil
import Bio; from Bio import SeqIO

loader = importlib.machinery.SourceFileLoader('config', sys.argv[1])
config = loader.load_module()
output = sys.argv[2]

proteome = list(SeqIO.parse(config.reference_proteome,'fasta'))
peptides = pd.read_csv(config.mq_txt +'/peptides.txt',sep='\t')
peptides = peptides[(peptides['Reverse']!='+') & (peptides['Potential contaminant'] !='+')]

mapped = sequtils.peptides2proteome(proteome,peptides['Sequence'].tolist(), threads=config.threads)

jstr =json.dumps(mapped.pepdict)

w=open(output +'/mapping/{}_peptides.json'.format(config.reference_proteome_id),'w')
w.write(jstr)
w.close()


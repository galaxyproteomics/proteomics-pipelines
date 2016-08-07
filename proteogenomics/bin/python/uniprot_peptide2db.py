#!/usr/bin/env python

import pandas as pd
import importlib.machinery
import sys
import os
import collections
from collections import defaultdict
import json
import shutil

loader = importlib.machinery.SourceFileLoader('config', sys.argv[1])
config = loader.load_module()
output = sys.argv[2]

up_db = pd.read_csv(config.mapping_database, sep ='\t')

nonspec_pep = []
map_dfs = []

for strain in config.strains:
    gssp_df = pd.read_csv(output +'/' + strain +'/{}_mapped_peptides.csv'.format(strain))
    ns = gssp_df[gssp_df['Peptide_distinct_translated_ORF_specfic'] != '+']['Peptide_sequence'].tolist()
    nonspec_pep += ns    
    map_dfs.append(gssp_df)

map_df = pd.concat(map_dfs)
spec_df = map_df[~map_df['Peptide_sequence'].isin(set(nonspec_pep))]

spec_peps = list(set(spec_df['Peptide_sequence'].tolist()))

pep2entry = defaultdict(list)

entrydata = {}

columns = up_db.columns

def get_mapping(df):
    entry = df['Entry']
    sequence = df['Sequence']
    data = {}

    for col in columns:
        data[col] = df[col]
        
    for seq in spec_peps:
        if seq in sequence:
            if not entry in pep2entry[seq]:
                pep2entry[seq].append(entry)

    entrydata[entry] = data
    
up_db.apply(get_mapping, axis=1)

pep2entry = json.dumps(pep2entry)
entrydata = json.dumps(entrydata)

try:
    os.mkdir(output +'/mapping')
except:
    shutil.rmtree(output +'/mapping')
    os.mkdir(output +'/mapping')

w = open(output +'/mapping/pep2entry.json', 'w')
w.write(pep2entry); w.close()

w = open(output +'/mapping/entrydata.json', 'w')
w.write(entrydata); w.close()

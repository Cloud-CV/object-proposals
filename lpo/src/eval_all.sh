#!/bin/bash
# You can change the python interpreter used by setting the evironment variable PYTHON=...
# Call this script as follows to use python 2.7: PYTHON=python bash eval_all.sh
P=${PYTHON:=python3}
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# This script reproduces table 3 in the paper
$P train_lpo.py -f0 0.2 ../models/lpo_VOC_0.2.dat
$P train_lpo.py -f0 0.1 ../models/lpo_VOC_0.1.dat
$P train_lpo.py -f0 0.05 ../models/lpo_VOC_0.05.dat
$P train_lpo.py -f0 0.03 ../models/lpo_VOC_0.03.dat
$P train_lpo.py -f0 0.02 ../models/lpo_VOC_0.02.dat
$P train_lpo.py -f0 0.01 ../models/lpo_VOC_0.01.dat -iou 0.925 # Increase the IoU a bit to make sure the number of proposals match

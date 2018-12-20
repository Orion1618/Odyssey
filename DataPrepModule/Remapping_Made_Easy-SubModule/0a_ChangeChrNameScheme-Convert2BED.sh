#!/bin/bash

#This script automatically looks in the folder it is executed from and performs operations on a plink .bed/bim/fam trio
#If more than one trio exists in the folder then this script will likely not work as intended


# Convert to Plink Chromosome Naming Scheme of 1,2,23 to chr1,chr2,chr23 
NAME="$(ls *.bim | awk -F'.' '{print $1}')"
plink --bfile ${NAME} --make-bed --output-chr chrM --out 1_${NAME}_ChrRenamed


#Turn a the Plink Bim file into a BED (not a Plink .bed) file (Named BED2 so as not to confuse Plink)
awk 'BEGIN{FS="\t"}{print $1,$4,($4+1),$2}' OFS='\t' 1_${NAME}_ChrRenamed.bim > 1_${NAME}_ChrRenamed.BED2

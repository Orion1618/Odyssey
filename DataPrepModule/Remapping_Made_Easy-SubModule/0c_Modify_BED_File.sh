#!/bin/bash


#WARNING: Do not use this script blindly hoping it will fix your problems. It is best to understand the root of your problem.
#This script will help you modify/cleanup the remapped_[FileName].BED2 file.
	#It is designed to remove lines that contain an underscore "_" which are common when a variant is remapped to a chromosome that specifies a contig
	#Be careful using it however as any line (including lines that contain an underscore in a variant name) will be removed

sed '/\_/d' ${NCBI_NAME} > ${NCBI_NAME}Fix && rm ${NCBI_NAME} && mv ${NCBI_NAME}Fix ${NCBI_NAME}

#After running the script go back and re-run 0b_RemNonMapped-UpdateBim.sh


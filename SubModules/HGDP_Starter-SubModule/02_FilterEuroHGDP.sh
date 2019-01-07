#!/bin/bash

##For Odyssey Tutorial Use Only:
   # For using the Odyssey Tutorial only individuals reported from France or Italy were kept for Phasing/Imputation (N=101 in the list, but only N=100 are actually in the Stanford dataset). A list of these individuals are listed in the 'HGDP_Euros' tab within 00_HGDP_StarterPack_Technical_Info.xlsm. Save the tab as "KeepEuroHGDP.txt" to ./DataPrepModule/HGDP_Starter-SubModule/HGDP_Keep_Lists. However, this file is already provided in the HGDP_Keep_Lists directory for convenience.
   
   # Then run the following Plink command to remove those HGDP samples that are not of French or Italian descent

plink --bfile ./0_DataPrepModule/HGDP_Starter-SubModuleHGDP952 --keep ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_Keep_Lists/KeepEuroHGDP.txt --make-bed --out ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_Euro

# While you will be using the HGDP_Euro .bed/.bim/.fam files for the Odyssey Tutorial, you first need to remap the files to the proper genome build (GRCh38) as HGDP is currently mapped to GRCh37. To do this refer to the Remapping_Made_Easy-SubModule

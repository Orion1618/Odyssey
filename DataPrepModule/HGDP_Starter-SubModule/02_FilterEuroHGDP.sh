#!/bin/bash

##For Odyssey Tutorial Use Only:
   # For using the Odyssey Tutorial only individuals reported from France or Italy were kept for Phasing/Imputation (N=101 in the list, but only N=100 are actually in the Stanford dataset). A list of those individuals are posted to the 1_KeepEuroHGDP tab so again save that list as "KeepEuroHGDP.txt", save it in in ./DataPrepModule/HGDP_Starter-SubModule/HGDP_Keep_Lists (this file is already there by default)
   # Then run the following Plink command to remove those HGDP samples that are not of French or Italian descent

plink --bfile HGDP952 --keep ./HGDP_Keep_Lists/KeepEuroHGDP.txt --make-bed --out HGDP_Euro

# You were therefore be using the HGDP_Euro .bed/.bim/.fam files for the Odyssey Tutorial. However, before you use these files it is important that you remap the files since HGDP is currently mapped to hg18. To do this refer to the Remapping_Made_Easy-SubModule

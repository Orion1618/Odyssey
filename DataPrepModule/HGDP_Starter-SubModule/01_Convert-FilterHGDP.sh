#!/bin/bash

#Convert txt files so they are Linux compatible by running the 3 following lines of code
dos2unix HGDP_FinalReport_Forward.txt
dos2unix HGDP_Map.txt
dos2unix HGDP_SampleList.txt


# Takes the Map and FinalReport files and converts them into a .tped by running the following 11 lines of code
head --lines=1 HGDP_FinalReport_Forward.txt > header.txt
awk '{for (i=1;i<=NF;i++) print "0",$i,"0","0"}' header.txt > hgdp_nosex.tfam
sed '1d' HGDP_FinalReport_Forward.txt > HGDP_Data_NoHeader.txt
sort -k 1b,1 HGDP_Data_NoHeader.txt > HGDP_Data_Sorted.txt
sort -k 1b,1 HGDP_Map.txt > HGDP_Map_Sorted.txt
join -j 1 HGDP_Map_Sorted.txt HGDP_Data_Sorted.txt > HGDP_compound.txt
 
awk '{if ($2=="M") $2="MT";printf("%s %s 0 %s ",$2,$1,$3);
    for (i=4;i<=NF;i++)
        printf("%s %s ",substr($i,1,1),substr($i,2,1));
    printf("\n")}' HGDP_compound.txt > hgdp.tped




# Do a little housekeeping to tidy up the HGDP_Starter-SubModule Directory
mkdir -p ./Intermediate_Files

mv ./*.txt  ./Intermediate_Files/
mv ./hgdp_nosex.tfam ./Intermediate_Files/

#Convert the .tfam and .tped into a Plink bed file using the following script
plink --tfile hgdp --out hgdp --make-bed --missing-genotype - --output-missing-genotype 0



#Keep only those who are unrelated and free of errors as determined by the fine folks maintaining the HGDP database
    #The filtered list contains 952 individuals but only 940 are in the Stanford dataset so your final N (datasize) will be 940
    #Create a tab separated list containing the FID and the IID of ONLY those individuals found in unrelated.out (this list can be found in the 1_KeepGoodHGDP tab), name it "1_KeepGoodHGDP.list", and place it in ./DataPrepModule/HGDP_Starter-SubModule/HGDP_Keep_Lists (this file is already there by default)
   #Then run the following Plink command to remove those not on the HGDP list of those to keep

plink --bfile hgdp --keep ./HGDP_Keep_Lists/KeepGoodHGDP.txt --make-bed --out HGDP952

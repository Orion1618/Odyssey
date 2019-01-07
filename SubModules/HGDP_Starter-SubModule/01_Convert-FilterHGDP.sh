#!/bin/bash

# Source from .config files (Program options via Settings.conf & Program execs via Programs.conf)
# ----------------------------
	
	source ./Settings.conf
	
	# Set Working Directory
# -------------------------------------------------
echo
echo Changing to Working Directory
echo ----------------------------------------------
echo ${WorkingDir}

	cd ${WorkingDir}
	# Load Odysseys Dependencies -- pick from several methods
	if [ "${OdysseySetup,,}" == "one" ]; then
		echo
		printf "\n\n Loading Odyssey's Singularity Container Image \n\n"
		source ./Configuration/Setup/Programs-Singularity.conf
	
	elif [ "${OdysseySetup,,}" == "two" ]; then
		echo
		printf "\n\n Loading Odyssey's Manually Configured Dependencies \n\n"
		source ./Configuration/Setup/Programs-Manual.conf
	else

		echo
		echo User Input Not Recognized -- Please specify One or Two
		echo Exiting Dependency Loading
		echo
		exit
	fi


source .TitleSplash.txt


# Splash Screen
# --------------
printf "$Logo"




#Convert txt files so they are Linux compatible by running the 3 following lines of code
dos2unix ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_FinalReport_Forward.txt
dos2unix ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_Map.txt
dos2unix ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_SampleList.txt


# Takes the Map and FinalReport files and converts them into a .tped by running the following 11 lines of code
head --lines=1 ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_FinalReport_Forward.txt > ./0_DataPrepModule/HGDP_Starter-SubModule/header.txt
awk '{for (i=1;i<=NF;i++) print "0",$i,"0","0"}' ./0_DataPrepModule/HGDP_Starter-SubModule/header.txt > ./0_DataPrepModule/HGDP_Starter-SubModule/hgdp_nosex.tfam
sed '1d' ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_FinalReport_Forward.txt > ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_Data_NoHeader.txt
sort -k 1b,1 ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_Data_NoHeader.txt > ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_Data_Sorted.txt
sort -k 1b,1 ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_Map.txt > ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_Map_Sorted.txt
join -j 1 ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_Map_Sorted.txt HGDP_Data_Sorted.txt > ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_compound.txt
 
awk '{if ($2=="M") $2="MT";printf("%s %s 0 %s ",$2,$1,$3);
    for (i=4;i<=NF;i++)
        printf("%s %s ",substr($i,1,1),substr($i,2,1));
    printf("\n")}' ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_compound.txt > ./0_DataPrepModule/HGDP_Starter-SubModule/hgdp.tped




# Do a little housekeeping to tidy up the HGDP_Starter-SubModule Directory
mkdir -p ../0_DataPrepModule/HGDP_Starter-SubModule/Intermediate_Files

mv ./0_DataPrepModule/HGDP_Starter-SubModule/*.txt  ./0_DataPrepModule/HGDP_Starter-SubModule/Intermediate_Files/
mv ./0_DataPrepModule/HGDP_Starter-SubModule/hgdp_nosex.tfam ./0_DataPrepModule/HGDP_Starter-SubModule/Intermediate_Files/

#Convert the .tfam and .tped into a Plink bed file using the following script
$Plink_Exec --tfile ./0_DataPrepModule/HGDP_Starter-SubModule/hgdp --out ./0_DataPrepModule/HGDP_Starter-SubModule/hgdp --make-bed --missing-genotype - --output-missing-genotype 0



#Keep only those who are unrelated and free of errors as determined by the fine folks maintaining the HGDP database
    #The filtered list contains 952 individuals but only 940 are in the Stanford dataset so your final N (datasize) will be 940
    #Create a tab separated list containing the FID and the IID of ONLY those individuals found in unrelated.out (this list can be found in the 1_KeepGoodHGDP tab), name it "1_KeepGoodHGDP.list", and place it in ./DataPrepModule/HGDP_Starter-SubModule/HGDP_Keep_Lists (this file is already there by default)
   #Then run the following Plink command to remove those not on the HGDP list of those to keep

$Plink_Exec --bfile ./0_DataPrepModule/HGDP_Starter-SubModule/hgdp --keep ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP_Keep_Lists/KeepGoodHGDP.txt --make-bed --out ./0_DataPrepModule/HGDP_Starter-SubModule/HGDP952

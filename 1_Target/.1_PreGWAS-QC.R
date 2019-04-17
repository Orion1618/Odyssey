
# Overview:
# -=-=-=-=-=-




# --------- Setup -------------




# Read in the Command arguments into the R environment  
  commandArgs()-> args
    #args

  	args[6]->WorkingDir
	args[7]->X11Option
	X11Option<-as.character(X11Option)
	plink<-'plink'
	#"singularity exec /N/dc2/scratch/ryeller/Odyssey/Configuration/Singularity/OdysseyContainer.sif plink "->plink
	#'/N/dc2/scratch/ryeller/Odyssey'->WorkingDir

  
 AnalyzeGeno <- function(WorkingDir, plink)  { 
  
	# Load the Libraries
		cat("\n\n===================================================\n")
		cat("Loading Required Packages\n")
		cat("--------------------------------\n\n")
			library(data.table)
			library(grDevices)
			library(plotly)
			library(scales)

	
	# Change into the working directory of where the file to be analyzed exists
		setwd(WorkingDir)
		
		cat("\n\n===================================================\n")
		cat("Entering Into Working Directory:\n")
		print(getwd())
		cat("--------------------------------\n\n")

		
	# Get the Base Name of the Plink files currently housed in ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE
		system(paste0("ls ", getwd(), "/1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/*.log", "| awk -F/ '{print $NF}' | sed 's/.log*.//'"), intern=TRUE) ->BaseName
		
	# Setup a QC Folder within the ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE folder
		cat("\n\n===================================================\n")
		cat("Creating QC Folder within ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE\n")
		cat("--------------------------------\n\n")
		
		
		system(paste0("mkdir -p ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization"))


# ============================
## Assess Variant Missingness
# ============================

		
## Calculate the Varinat Missing Rate
	cat("\n\n===================================================\n")
	cat("Assessing Missingness for Individuals & Variants\n")
	cat("--------------------------------\n\n")

	system(paste0(plink, " --bfile ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/", BaseName, " --missing --out ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/Missing"))

	cat('\n\n')

## Import the 'lmiss' file
	cat("\nAssessing Variant Missingness/Call Rate\n")
	cat("----------------------------------------------\n\n")
		
## Prompt for Variant Missingness Cutoff
# Detect if running script interactively or non-interactively
		
	if (interactive() ){
		# Interactive Prompt
			cat(paste('\n\nWhere Would You Like to Set Your Genotype Missingness Cutoff Criteria?\nA Suitable Default is 0.05\nSpecify a number below\n'))
			cat('--------------------------------\n\n')
			GenoQC<-readline(prompt="Variant Missingness Criteria: ")
			GenoQC<-as.numeric(GenoQC)
			cat(paste("Genotype Missingness Criteria Set To:", GenoQC, "\n\n"))
		}
          else{
		# Non-interacti1veve Prompt
			cat(paste('\n\nWhere Would You Like to Set Your Genotype Missingness Cutoff Criteria?\nA Suitable Default is 0.05\nSpecify a number below\n'))
			cat('--------------------------------\n\n')
			GenoQC<-readLines(con="stdin",1)
			GenoQC<-as.numeric(GenoQC)
			cat(paste("\nGenotype Missingness Criteria Set To:", GenoQC, "\n\n"))
			}

# Load the Missingness data
	lmiss <- fread(paste0(getwd(), "/1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/Missing.lmiss"), header = T)
	
# ============================
## Plot Variant Missingness
# ============================

## Output one JPEG Variant Call Rate File to the QC Folder
	plot=ggplot(lmiss, aes(x=lmiss$F_MISS)) +
	geom_histogram(aes(fill=..count..))	
			
		jpeg(paste0(getwd(),"/1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/Missing.jpg"))
			plot+scale_y_continuous(expand = c(0,0),
								label = unit_format(unit="K", scale=1e-3),
								limits=c(0,max(ggplot_build(plot)$data[[1]]$count)/2.5))+
			scale_x_log10(breaks=c(0.005,0.01,0.02,0.05, 0.1,0.2,0.4,0.8,1), 
								label=c(0.005,0.01,0.02,0.05, 0.1,0.2,0.4,0.8,1)) +
			ggtitle(paste0("All SNPs")) +
			scale_fill_continuous(expand = c(0,0), label = unit_format(unit="K", scale=1e-3),
									limits=c(0,max(ggplot_build(plot)$data[[1]]$count)/2.5))+
			geom_vline(xintercept=GenoQC, colour="#BB0000", linetype="dashed")+
			labs(title="SNP Missingness", x="Fraction of missing data", y="Number of SNPs")->VisualizePlot
		print(VisualizePlot)
		dev.off()


if(X11Option == "T" || X11Option == "t")
	{
		# Visualize Plot via X11
		# Output Histogram to X11 Live Display
		## Special thanks to Didzis Elferts: https://stackoverflow.com/questions/14584093/ggplot2-find-number-of-counts-in-histogram-maximum
		
		# Visualize Plot via X11
			cat("\n\nVisualizing Plot:\n")
			cat("====================================\n")
			plot=ggplot(lmiss, aes(x=lmiss$F_MISS)) +
			geom_histogram(aes(fill=..count..))
			
			plot+scale_y_continuous(expand = c(0,0),
									label = unit_format(unit="K", scale=1e-3),
									limits=c(0,max(ggplot_build(plot)$data[[1]]$count)/2.5))+
				scale_x_log10(breaks=c(0.005,0.01,0.02,0.05, 0.1,0.2,0.4,0.8,1), 
									label=c(0.005,0.01,0.02,0.05, 0.1,0.2,0.4,0.8,1)) +
				ggtitle(paste0("All SNPs")) +
				scale_fill_continuous(expand = c(0,0), label = unit_format(unit="K", scale=1e-3),
										limits=c(0,max(ggplot_build(plot)$data[[1]]$count)/2.5))+
				geom_vline(xintercept=GenoQC, colour="#BB0000", linetype="dashed")+
				labs(title="SNP Missingness", x="Fraction of missing data", y="Number of SNPs")->VisualizePlot
			X11()
		print(VisualizePlot)
	}
	else if (X11Option=="F" || X11Option=="f")
	{
		# Do Not Visualize Plot via X11
		cat("\n\nWill Not use X11 to visualize plot:\n")
		cat("- - - - - - - - - - - - - - - - - - - - - -\n")
	}
	else
	{
		# Return Error Message -- User Input Not Recognized
		cat("\n\nUser Input Not Recognized: Specify Either T or F -- Exiting...\n")
		cat("==============================================================================\n")
	}
		

		

## Prompt to continue while detecting interactive environment: https://stackoverflow.com/questions/27112370/make-readline-wait-for-input-in-r
# Detect if running script interactively or non-interactively

if (interactive() ){
	# Interactive Prompt
		cat(paste('\n\nA Graph Visualizing All Variant Missingness Rates Using a User-Provided QC Cutoff of', GenoQC,'Saved To: \n./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization\n'))
		cat('--------------------------------\n\n')
		readline(prompt="Press Enter/Return Key To Continue")
	}
         else{
	# Non-interacti1veve Prompt
		cat(paste('\n\nA Graph Visualizing All Variant Missingness Rates Using a User-Provided QC Cutoff of', GenoQC,'Saved To: \n./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization\n'))
		cat('--------------------------------\n\nPress Enter/Return Key To Continue\n')
		readLines(con="stdin",1)
		cat( "\n" )
		}

# ============================		
## Calculate Heterozygosity
# ============================

##Check the Heterozygosity Rate

	cat("\n\n===================================================\n")
	cat('Assessing Heterozygosity\n')
	cat("--------------------------------\n\n")
		
## Prompt for Heterozygosity Cutoff
# Detect if running script interactively or non-interactively
if (interactive() ){
	# Interactive Prompt
		cat(paste('\n\nWhere Would You Like to Set a Cutoff for Heterozygosity?\nA Suitable STDEV Default is: 3\nSpecify a number below\n'))
		cat('--------------------------------\n\n')
		HetQC<-readline(prompt="Variant Missingness Criteria: ")
		HetQC<-as.numeric(HetQC)
		cat(paste("Individual Heterozygosity Cutoff Criteria Set To: ", HetQC, "\n\n"))
	}
         else{
	# Non-interacti1veve Prompt
		cat(paste('\n\nWhere Would You Like to Set a Cutoff for Heterozygosity?\nA Suitable STDEV Default is: 3 \nSpecify a number below\n'))
		cat('--------------------------------\n\n')
		HetQC<-readLines(con="stdin",1)
		HetQC<-as.numeric(HetQC)
		cat(paste("Individual Heterozygosity Cutoff Criteria Set To: ", HetQC, "\n\n"))
		}
## Prompt for Individual Missingness Cutoff
# Detect if running script interactively or non-interactively
		
	if (interactive() ){
		# Interactive Prompt
			cat(paste('\n\nWhere Would You Like to Set Your Individual Missingness Cutoff Criteria?\nA Suitable Default is: 0.05 \nSpecify a number below\n'))
			cat('--------------------------------\n\n')
			IndivQC<-readline(prompt="Individual Missingness Criteria: ")
			IndivQC<-as.numeric(IndivQC)
			cat(paste("Individual Missingness Criteria Set To: ", IndivQC, "\n\n"))
		}
          else{
		# Non-interacti1veve Prompt
			cat(paste('\n\nWhere Would You Like to Set Your Individual Missingness Cutoff Criteria?\nA Suitable Default is: 0.05 \nSpecify a number below\n'))
			cat('--------------------------------\n\n')
			IndivQC<-readLines(con="stdin",1)
			IndivQC<-as.numeric(IndivQC)
			cat(paste("Individual Missingness Criteria Set To: ", IndivQC, "\n\n"))
			}
		
# Calculate Heterozygosity
	cat('Calculating Heterozygosity\n')
	cat('----------------------------\n\n')
	system(paste0(plink, " --bfile ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/", BaseName, " --het --out ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/Het"))

	cat('\n\n')

	het = fread(paste0(getwd(), "/1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/Het.het"), header = T)

## Add a column onto the imported het variable The new column consists of the calculation of the mean Het
	het$meanHet = (het$`N(NM)` - het$`O(HOM)`)/het$`N(NM)`
		
## Load the .imiss file -- Missingness for individuals file	
	imiss = fread(paste0(getwd(), "/1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/Missing.imiss"), header = T)

# =========================================
## Plot Heterozygosity v Indiv Missingness
# =========================================

## Plot the imiss vs. het Output to a jpeg file (Setup to show +/- X SD of Het Mean)
	jpeg(paste0(getwd(),"/1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/IndivMissingVSheterozygosity.jpg"))
	
	# Set Standard Deviation Cutoff Criteria
		LowerSD<-mean(het$meanHet) - (HetQC * sd(het$meanHet))
		UpperSD<-mean(het$meanHet) + (HetQC * sd(het$meanHet))
	
	# Setup the Heterozygosity Plot
		hetplot=ggplot(imiss, aes(x=imiss$F_MISS, y=het$meanHet)) + geom_point()
	
	# Format the Heterozygosity v IndivMissingness Plot	
		hetplot +
		scale_x_log10(breaks=c(0.001,0.01,0.1,1), 
						label=c(0.001,0.01,0.1,1)) +
		geom_bin2d(bins = 250)+
		
	# Visualize the Cutoffs
		geom_hline(yintercept=LowerSD, colour="#BB0000", linetype="dashed")+
		geom_hline(yintercept=UpperSD, colour="#BB0000", linetype="dashed")+
		geom_vline(xintercept=IndivQC, colour="#BB0000", linetype="dashed")+
	
	# Setup Titles	
		labs(title="Individual Missing V Heterozygosity", x="Proportion of Missing Individuals", y="Heterozygosity")->VisualizePlot
		print(VisualizePlot)
	dev.off()
		
		
## Actually View the Plot 

if(X11Option == "T" || X11Option == "t")
	{
		# Output Histogram to X11 Live Display
				
			# Setup the Heterozygosity Plot
				hetplot=ggplot(imiss, aes(x=imiss$F_MISS, y=het$meanHet)) + geom_point()
			
			# Format the Heterozygosity v IndivMissingness Plot	
				hetplot +
				scale_x_log10(breaks=c(0.001,0.01,0.1,1), 
								label=c(0.001,0.01,0.1,1)) +
				geom_bin2d(bins = 250)+
				
			# Visualize the Cutoffs
				geom_hline(yintercept=LowerSD, colour="#BB0000", linetype="dashed")+
				geom_hline(yintercept=UpperSD, colour="#BB0000", linetype="dashed")+
				geom_vline(xintercept=IndivQC, colour="#BB0000", linetype="dashed")+
			
			# Setup Titles	
				labs(title="Individual Missing V Heterozygosity", x="Proportion of Missing Individuals", y="Heterozygosity")->VisualizePlot
			
			# Initialize X11 and Visualize
				print(VisualizePlot)
	}
	else if (X11Option=="F" || X11Option=="f")
	{
		# Do Not Visualize Plot via X11
		cat("\nWill Not use X11 to visualize plot:\n")
		cat("- - - - - - - - - - - - - - - - - - - - - -\n")
	}
	else
	{
		# Return Error Message -- User Input Not Recognized
		cat("\n\nUser Input Not Recognized: Specify Either T or F -- Exiting...\n")
		cat("==============================================================================\n")
	}


		
## Prompt to continue while detecting interactive environment: https://stackoverflow.com/questions/27112370/make-readline-wait-for-input-in-r
# Detect if running script interactively or non-interactively

if (interactive() ){
	# Interactive Prompt
		cat(paste('\n\nA Graph Visualizing Heterozygosity and Individual Missingness Using the Following User-Provided Cutoffs: \n\nIndividual Missingness Cutoff of:', IndivQC, '\nHeterozygosity Cutoffs of: +/-', HetQC,'STDEV \n\nHas Been Saved to: \n./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization\n'))
		cat('--------------------------------\n\n')
		readline(prompt="Press Enter/Return Key To Continue")
	}
         else{


	# Non-interacti1veve Prompt
		cat(paste('\n\nA Graph Visualizing Heterozygosity and Individual Missingness Using the Following User-Provided Cutoffs: \n\nIndividual Missingness Cutoff of:', IndivQC, '\nHeterozygosity Cutoffs of: +/-', HetQC,'STDEV \n\nHas Been Saved to: \n./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization\n'))
		cat('--------------------------------\n\nPress Enter/Return Key To Continue\n')
		readLines(con="stdin",1)
		cat( "\n" )
		}	


# ============================		
## Remove those who Failed Heterozygosity or Individual Missingness QC
# ============================

# Remove Individuals with High STD DEV Heterozygosity 
	  	cat(paste('Writing individuals whose heterozygosity is outside of +/-', HetQC, 'standard deviations or whose Individual Missingness is less than', IndivQC, '\n'))
		cat('--------------------------------\n')
	
## Computing who to extract due to failed Individual Missingness QC
		failed.miss.het = imiss[(imiss$F_MISS >= IndivQC | (het$meanHet < LowerSD | het$meanHet > 
		UpperSD)) , 1:2]
	
## Export to 'fail-imisshet-qc.txt'
	write.table(failed.miss.het, file = paste0(getwd(),"/1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/failed.imisshet.txt"), col.names = T, row.names = F, quote = F, sep = "\t")

	
# ==============================
## Visualize Relatedness via IBD
# ==============================

## Perform IBD Test to Assess Relatedness
	
	cat("\n\n===================================================\n")
	cat('Assessing Relatedness via IBD -- Identity By Descent\n')
	cat("--------------------------------\n\n")
	


	## Creating a Cleaned QCed Reference Dataset from the Sample dataset (this involves removing any poor samples)

	cat('\n\nCreating TEMP IBD Dataset to Assess IBD\n')
	cat("--------------------------------\n\n")

	system(paste0(plink, " --bfile ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/", BaseName, " --mind 0.05 --geno 0.05 --make-bed --freq --out ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/1_IBDDataset"))

	cat('\n\n')

## Prune the Dataset that has been corrected for poor SNP's and Individuals
	cat('\n\nPruning TEMP IBD Dataset\n-----------------------------------------\n\n')
	system(paste0(plink, " --bfile 	./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/1_IBDDataset --indep-pairwise 50 5 0.2 --out ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/2_IBDDataset_Pruned"))


## Create the IBD File to determine those who need to be removed due to relatedness/dups
	cat('\n\n\nPerforming IBD Test on Sample Dataset with Cleaned Data Allele Frequencies \n-----------------------------------------\n\n')
	system(paste0(plink, " --bfile ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/1_IBDDataset --extract ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/2_IBDDataset_Pruned.prune.in --mind 0.1 --genome --min 0.1875 --read-freq ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/1_IBDDataset.frq --out ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/RelatedTest"))


## Import the '.genome file
	cat(paste('\n\nOutputting Interactive Plotly IBD Plots to Folder\n'))
	cat("--------------------------------------------------------\n\n")

	Related <- fread(paste0('./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/RelatedTest.genome'), h = T)

	
## Prompt for IBD Cutoff
# Detect if running script interactively or non-interactively
		
	if (interactive() ){
		# Interactive Prompt
			cat(paste('\n\nWhat IBD Cutoff Would You Like to Use for Exclusion Purposes?\nA Suitable Default is 0.1875 as this would set 2nd Degree relatives as the cutoff \nSpecify Number Below\n'))
			cat('NOTE: Cutoff Criteria Must be >=0.1875')
			cat('--------------------------------\n\n')
			IBDQC<-readline(prompt="IBD Cutoff: ")
			IBDQC<-as.numeric(IBDQC)
			cat(paste("IBD Relatedness Cutoff Criteria Set To: ", IBDQC, "\n\n"))
		}
          else{
		# Non-interacti1veve Prompt
			cat(paste('\n\nWhat IBD Cutoff Would You Like to Use for Exclusion Purposes?\nA Suitable Default is 0.1875 as this would set 2nd Degree relatives as the cutoff \nSpecify Number Below\n'))
			cat('NOTE: Cutoff Criteria Must be >= 0.1875\n')
			cat('--------------------------------\n\n')
			IBDQC<-readLines(con="stdin",1)
			IBDQC<-as.numeric(IBDQC)
			cat(paste("\nIBD Relatedness Cutoff Criteria Set To: ", IBDQC, "\n\n"))
			}	
	
## Identify Individuals who have Pi-Hats greater than User-Specified Cutoff
	Related.problems <- Related[which(Related$PI_HAT>=IBDQC), c("FID1", "IID1", "FID2", "IID2", "PI_HAT", "Z0", "Z1", "Z2")]

	IBD_Plot <- plot_ly(data = Related.problems, x = ~Z0, y = ~Z1, type = 'scatter', mode = 'markers', hoverinfo = 'text',
                    text=~paste('FID1:', Related.problems$FID1, 'IID1:', Related.problems$IID1,
                                '</br></br> FID2:', Related.problems$FID2, 'IID2:', Related.problems$IID2))

#Visualize Plotly IBD Plot

	# Save Plotly-Plot to QC Folder
		# Plotely Dependencies will be plotted in the Directory where plot is saved
			htmlwidgets::saveWidget(IBD_Plot, paste0(getwd(),'/1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/IBD-Plot.html'), libdir = paste0(getwd(),'/1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/PlotlyDependencies/'), selfcontained=FALSE) 


		cat(paste('\nOutputting List of Individuals with an IBD > ', IBDQC, '\n'))
		cat('--------------------------------\n\n')
		
##Output the 1st two Columns so we can remove those people from the GWAS
	failed.related = Related[which(Related$PI_HAT>=IBDQC), c("FID1", "IID1")]

	write.table(failed.related, file = paste0("./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/failed.related.txt"), col.names = T, row.names = F, quote = F, sep = "\t")

# ==============================
## Perform Final QC Exclusion
# ==============================

	
## Perform Final QC that removes individuals who have failed IBD, Missingness, or Heterozygosity
		
## Prompt to continue while detecting interactive environment: https://stackoverflow.com/questions/27112370/make-readline-wait-for-input-in-r
# Detect if running script interactively or non-interactively

if (interactive() ){
	# Interactive Prompt
		cat('\n\nThis Final Step will take individuals who have failed the IBD, Individual Missingness, or Heterozygosity QC and append them to a removal list \n\nThe files that will be used are the failed.imisshet.txt and failed.related.txt in the ./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization folder \n\nAlter these files now if you want to change the list of individuals who are sent to the final removal list\n')
		cat('--------------------------------\n\n')
		readline(prompt="Press Enter/Return Key To Continue")
	}
         else{
	# Non-interacti1veve Prompt
		cat("\n\n===================================================\n")
		cat('CREATE SAMPLE EXCLUSION LIST:\n')
		cat('--------------------------------\n\n')
		
		cat('This Final Step will take individuals who have failed the IBD, Individual Missingness, and/or Heterozygosity QC and append them to a removal list \n\nThe files that will be used are the failed.imisshet.txt and failed.related.txt in the following directory: \n./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization \n\nAlter these files now if you want to change the list of individuals who are sent to the final removal list\n\nPress Enter/Return Key To Continue\n')

		readLines(con="stdin",1)
		cat( "\n" )
		}	

## Load Related Check QC
	(failed.miss.het = read.table(file = paste0('./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/failed.imisshet.txt'), header = T, colClasses = 'factor'))

	cat('List of the first individual in the pair who failed IBD\n')
	cat('Note: In any IBD pair only ONE individual will be dropped\n')
	cat('--------------------------------\n')

	failed.related = read.table(file = paste0("./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/failed.related.txt"), header = T, colClasses = 'factor')
	colnames(failed.related) <- c("FID", "IID")
	print(failed.related)
	
## Add or remove which files you want to combine (for instance some SexProblems aren't really problems)
	failed.individual = rbind(failed.miss.het, failed.related)
	
	
## Get Rid of non-unique values
	failed.individualuniq <- unique(failed.individual[ ,1:2])

	cat(paste('\n\nIn total', nrow(failed.individualuniq), 'individuals were sent to the removal list due to failed QC\n'))
	cat('--------------------------------\n\n')

	
## Output to a Text File in the QC Folder
	write.table(failed.individualuniq, file = paste0("./1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/failed.qc.txt"), sep = "\t", col.names = F, row.names = F, quote = F)
	
## Cleanup the Junk
	cat("\n\n===================================================\n")
	cat('Cleaning Up Temporary Files\n')
	cat("--------------------------------\n\n")

	system(paste0('rm -f ', getwd(),'/1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/2*'))
	system(paste0('rm -f ', getwd(),'/1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/1*'))
	
	
# Create a custom Readme file in the target directory to explain what is being populated

	cat("\n\n===================================================\n")
	cat('Writing Readme to File\n')
	cat("--------------------------------\n\n")
	
sink(paste0(getwd(),'/1_Target/PLACE_NEW_PROJECT_TARGET_DATA_HERE/Dataset_QC-Visualization/README_QC'))

	
cat(paste0("README for Dataset_QC-Visualization
=============================================\n 
	
In the following folder you will find several documents that pertain to the QC of the data being processed user the following user-defined cutoffs:
	
	--Heterozygosity Cutoff: \t\t", HetQC , " STDEV
	--Individual Missingness Cutoff: \t", IndivQC*100 ,"%
	--Genotype Missingness Cutoff: \t\t", GenoQC*100 ,"%
	--Identify By Decent Cutoff: \t\t", IBDQC ,"
	
1) Failed QC Lists: These lists contain the FID and IID of individuals who failed the user-specified cutoff criteria
	a) failed.imisshet.txt -- Contains list of ID's who failed the heterozygosity test and who contained a high degree of missing genotypes
	b) failed.related.txt -- Contains list of the FIRST ID in the ID-Pair who were failed the Identity by Decent test
	c) failed.qc.test -- A merged list of failed.imisshet and failed.related that contain unique individuals (i.e. duplicates were removed)
	
2) Heterozygosity Results:
	a) Het.het/log: The raw heterozygosity test for the dataset
	b) IndivMissingVSheterozygosity.jpg: The visualization of missingness (on the individual level) and heterozygosity for the dataset, which includes the user-defined cutoffs in red
		
3) Missingness Results:
	a) Missing.imiss/lmiss/log: The raw missingness test results and log run on the dataset
	b) Missing.jpg: The visualization for the genetic missingness in the dataset along with the user-defined cutoff in red
	
4) Relatedness Results:
	a) RelatedTest.genome/log: The raw IBD test results and log run on the dataset
	b) IBD-Plot.html: The interactive Plotly visualization for the IBD test. The PlotlyDependencies folder must me in the same location as the .html in order to visualize the plot via a web browser	\n\n"))

sink()



  cat('\n=========================================\n')
  cat('Finished with Data QC/Visualization!\n')
  cat('=========================================\n\n')
  }
  
AnalyzeGeno(WorkingDir, plink)


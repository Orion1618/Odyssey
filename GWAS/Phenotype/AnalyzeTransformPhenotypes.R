
# ____________________________________________________________
# Analyze Phenotype -- Transformation/Normalization Function
# ____________________________________________________________



#-----------  Instructions ------------------

#1 Specify a csv file that contains at least 1 column (dataset must contain headers) that contains a continuous variable
#2 Refer to Function Setup to Setup the function (working directory and file input)
  #a Load the phenotype file 
  #b Setup the working directory
#3 Load the Actual Function, 'AnalyzePheno,' into the Global Environment
#4 Run the function (remember to input the functions only variable, 'PhenotypeFilePath' which you already setup)
#NOTE: Best Executed from within Rstudio or Jupyter Notebooks


# ------------- Miscellaneous and Potentially Helpful Commands -----------------

  #Wholistic Scatterplot of Variables of Interest
    #scatterplotMatrix(~Diamond+Oval+Round+SqDiamond+Square, regLine=FALSE, 
                  #smooth=FALSE, ellipse=list(levels=c(.5, .9)), 
                  #diagonal=list(method="histogram"), data=Phenotypes)


  #User Input Function -- Load Function by file itself
    #source(file.choose())
    



# ------------ Function Setup ------------------

#Input the File Path of the Phenotype File you Want to Analyze
	#PhenotypeFilePath <- file.path(file.choose())
	PhenotypeFilePath <- readline("Specify the full path of the Phenotype File you Want to Check: ")
	PhenotypeFilePath <- as.character(PhenotypeFilePath , ",")


#Set Current Working Directory

	#setwd(choose.dir())
   	WorkingDir <- readline("Specify the full directory path of where your phenotype file is located: ")
	WorkingDir <- as.character(WorkingDir , ",")
setwd(WorkingDir)



# Load the Function Below into the Global Environment

AnalyzePheno <- function(PhenotypeFilePath, WorkingDir)  {
  
  # Set Directory as that which contains the phenotype file
    setwd(WorkingDir)
  
  # Crunch all the data to be processed by the argumentative section of the function
  
  # Load the Libraries
  
  library(data.table)
  library(tidyverse)
  library(gridExtra)
  library(rcompanion)
  library(MASS)
  library(car)
  
  #Load the Phenotype File
  read.table(PhenotypeFilePath, header=T)->>PhenotypeFile
  
  
  # Calculate number of columns in table
  for(i in 1:ncol(PhenotypeFile)) 
  {
    # Write i iteration to global environment
      i->>i
  
    # Return the name of the column
    cat("\n\n===================================================\n")
    cat("Currently Looking at the Following Dataset Column:\n")
    cat("===================================================\n") 
    cat(colnames(PhenotypeFile)[i])
    cat("\n\n")
    
    # Ask if this is a phenotype column (as opposed to a covariate or an ID column)
    AnalyzeColumn <- readline("Is this column a phenotype column you want analyzed? (e.g. y/n): ")
    AnalyzeColumn <- as.character(AnalyzeColumn, ",")
    
    
    # If the Column is to be analyzed then visualize the distribution and determine whether transformations are neccesary
    if(AnalyzeColumn == "Y" || AnalyzeColumn == "y"){
      
      # Visualize the distribution of the individual phenotype (via a histogram)
      
      cat("\n\nVisualizing Phenotype:\n")
      cat("===========================\n\n")

      print(ggplot(PhenotypeFile, aes(x=PhenotypeFile[,i])) + 
        geom_histogram(aes(y = ..density..),
                       colour="black", fill="white") +
        labs(x = colnames(PhenotypeFile)[i]) +
        geom_density(alpha = .2)+
        ggtitle(paste0("Histogram Plot of Data in Column: ", colnames(PhenotypeFile)[i] )))
      
      
      # This User Specified Transformation Loop Will Repeat Until the user is satisfied with the transformation or told to exit
      repeat 
      {
        
        
        # Ask if User Would Like to Transform the data to fit normality
        
        cat("\nWould you like to transform this phenotype to fit normality? \n")
        cat("-----------------------------------------------------------------\n")
        cat("Type '1' to Perform Yeo-Johnson Normalization \n")
        cat("Type '2' to Perform Rank-Order Inverse Normalization \n")
        cat("Type '3' to Not Perform Any Normalization \n")
        
        Transform <- readline("Input: ")
        Transform <- as.character(Transform, ",")  
        
        
# ------------------ Perform Yeo-Johnson Normalization (Option 1) ----------------------
        # Note: this is similar to Box-Cox although Yeo_Johnson Allows for zero and negative values
        
        if(Transform == "1"){
          
          cat("\n\nBeginning Yeo-Johnson Transformation on Phenotype:\n")
          cat("===================================================\n")

          
          #Get Column Name
          colnames(PhenotypeFile)[i]->ColumnName
          
          # Transform the specified column as a single vector using values that range from -30 to 30 with a step size of 0.1
          
          boxCox(lm(PhenotypeFile[,i]~1), family = "yjPower", plotit = T, lambda = seq(-30,30,0.1))
          Box<- boxCox(lm(PhenotypeFile[,i]~1), family = "yjPower", plotit = F, lambda = seq(-30,30,0.1))
          
          # Create dataframe with the results
          Cox= data.frame(Box$x, Box$y)
          
          # Order the Data by decreasing y
          Cox2= Cox[with(Cox, order(-Cox$Box.y)),]
          
          # Display the lambda with the greatest log likelihood
          Cox2[1,]
          
          # Extract the best lambda
          lambda = Cox2[1, "Box.x"]
          
          #Create Yeo-Johnson Transformed Column Name
          paste0(colnames(PhenotypeFile)[i],"_YeoJohnsonTransform")->TransformColumnName  
          
          # CreateData.Frame with the Yeo-Johnson Transform data using the best lambda 
          After<- yjPower(as.data.frame(PhenotypeFile[,i]), lambda = lambda, jacobian.adjusted = FALSE)
          colnames(After)<- paste0(TransformColumnName) 
          
          # Plot Before Transformation
          BeforePlot <- ggplot(PhenotypeFile, aes(x=PhenotypeFile[,i])) + 
            geom_histogram(aes(y = ..density..),
                           colour="black", fill="white") +
            labs(x = colnames(PhenotypeFile)[i]) +
            geom_density(alpha = .2)+
            ggtitle(paste0("Before Yeo-Johnson Transformation -- Using Power of: ", Cox2[1, "Box.x"] ))
          
          # Plot After Transformation
          AfterPlot <- ggplot(After, aes(x=After[,1])) + 
            geom_histogram(aes(y = ..density..),
                           colour="black", fill="white") +
            labs(x = colnames(After)[1]) +
            geom_density(alpha = .2)+
            ggtitle(paste0("After Yeo-Johnson Transformation -- Using Power of: ", Cox2[1, "Box.x"]))
          
          #View the Before/After Transformation Plots 
          print(grid.arrange(BeforePlot, AfterPlot))                      
          
          # Prompt whether to write transformed data to MasterPhenotype File
          cat("\n")
          Write2PhenoFile <- readline("Do you want to write the transformed data to the Phenotype File? (e.g. 'Y' or 'N'): ")
          Write2PhenoFile <- as.character(Write2PhenoFile, ",")
          if (Write2PhenoFile=="y" || Write2PhenoFile=="Y")
          {
            # Write Yeo-Johnson Transform data with the best lambda to Pheno File
            cat("\n\nWriting Yeo-Johnson Transform data with the best lambda to Pheno File:\n")
            cat("======================================================================\n")
            PhenotypeFile[,paste0(TransformColumnName)] <<- yjPower(as.data.frame(PhenotypeFile[,i]), lambda = lambda, jacobian.adjusted = FALSE)
          }
          else if (Write2PhenoFile=="N" || Write2PhenoFile=="n")
          {
            # Do Not Write Yeo-Johnson Transform data with the best lambda to Pheno File
            cat("\n\nWill Not Write Yeo-Johnson Transform data with the best lambda to Pheno File:\n")
            cat("==============================================================================\n")
          }
          else
          {
            # Return Error Message -- User Input Not Recognized
            cat("\n\nUser Input Not Recognized: Specify Either Y or N -- Exiting...\n")
            cat("==============================================================================\n")
          }
        }
        
        
# ------------------ Perform Rank-Order Inverse Normalization (Option 2) ----------------------
        
        if(Transform == "2"){ 
          
          cat("\n\nBeginning Rank-Order Transformation on Phenotype:\n")
          cat("===================================================\n")

          #Get Column Name
          colnames(PhenotypeFile)[i]->ColumnName
          
          #Create Inverse Normalization Transformed Column Name
          paste0(colnames(PhenotypeFile)[i],"_InverseNormalize")->InverseTransformColumnName            
          
          # Perform Inverse Normalization 
          After <- as.data.frame(qnorm((rank(PhenotypeFile[,i],na.last="keep")-0.5)/sum(!is.na(PhenotypeFile[,i]))))
          colnames(After)<- paste0(InverseTransformColumnName)
          
          
          # Plot Before Transformation
          BeforePlot <- ggplot(PhenotypeFile, aes(x=PhenotypeFile[,i])) + 
            geom_histogram(aes(y = ..density..),
                           colour="black", fill="white") +
            labs(x = colnames(PhenotypeFile)[i]) +
            geom_density(alpha = .2)+
            ggtitle(paste0("Before Rank-Order Inverse Normalization Transformation"))
          
          # Plot After Transformation
          AfterPlot <- ggplot(After, aes(x=After[,1])) + 
            geom_histogram(aes(y = ..density..),
                           colour="black", fill="white") +
            labs(x = colnames(After)[1]) +
            geom_density(alpha = .2)+
            ggtitle(paste0("After Rank-Order Inverse Normalization Transformation"))
          
          #View the Before/After Transformation Plots 
            print(grid.arrange(BeforePlot, AfterPlot))
          
          # Prompt whether to write transformed data to MasterPhenotype File
          Write2PhenoFile <- readline("Do you want to write the transformed data to the Phenotype File? (e.g. 'Y' or 'N'): ")
          Write2PhenoFile <- as.character(Write2PhenoFile, ",")
          if (Write2PhenoFile=="y" || Write2PhenoFile=="Y")
          {
            # Write Inverse Normalization Transformed data to Pheno File
            cat("\n\nWriting Rank-Order Inverse Normalized data to Pheno File:\n")
            cat("======================================================================\n")
            PhenotypeFile[,paste0(InverseTransformColumnName)] <<- as.data.frame(qnorm((rank(PhenotypeFile[,i],na.last="keep")-0.5)/sum(!is.na(PhenotypeFile[,i]))))
          }
          else if (Write2PhenoFile=="N" || Write2PhenoFile=="n")
          {
            # Do Not Write Inverse Normalization Transformed data to Pheno File
            cat("\n\nWill Not Write Rank-Order Inverse Normalized data to Pheno File:\n")
            cat("==============================================================================\n")
          }
          else
          {
            # Return Error Message -- User Input Not Recognized
            cat("\n\nUser Input Not Recognized: Specify Either Y or N -- Exiting...\n")
            cat("==============================================================================\n")
          }
          
        }
        
        
# ------------------ Perform No Normalization (Option 3) ----------------------
        
        if(Transform == "3"){ 
          # User Specified '3' -- No Transformation Needed for Specified Pheno Column
          cat("\n\nNo Transformation Will Be Performed as Specified by User:\n")
          cat("======================================================================\n")
        }
        
        
        
        # Ask if User is Happy with the Transformation for the current phenotype column
        cat("\n\nAre you happy with the transformation for the phenotype column? \n")
        cat("====================================================================\n")
        cat("Selection of 'Y' will exit the transformation of this column and move to the next column \n")
        cat("Selection of 'N' will repeat the transformation loop \n")
        Quit <- readline("Input: ")
        Quit <- as.character(Quit, ",")
        # Exit the Repeat Transformation Loop if User is Happy with the Transformation
        if (Quit=="y" || Quit=="Y"){break}       
      }       
      
    }
    
    # If the Column is not a Column to Analyze then move to the next column
    else if (AnalyzeColumn == "N" || AnalyzeColumn == "n") {
      cat('\n\nAlright will not plot the values in this column. Moving to next column...\n')
    }
    
    # Return Error Message -- User Input Not Recognized
    else {
      
      cat("\n\nUser Input Not Recognized -- Please Specify 'Y' or 'N' -- Moving to next columns\n")
      cat("===============================================================================\n")

    }
    
   
  }

# ---------------- Write Finished Pheno File to Current Working Directory -------------------
  cat("\n\n")
  message(paste0("Exporting Analzyed Pheno File to Current Working Directory: ", getwd()))
            cat("============================================================\n\n")
  write.csv(PhenotypeFile, paste0(getwd(),"/AnalzyedPheno.csv"))
  
  cat("\nPhew! Analysis Complete\n")
  cat("========================\n")
  
}

AnalyzePheno(PhenotypeFilePath, WorkingDir)

########### MAIN ###########
t_start = Sys.time()
#To load the required packages, use this
source("packageLoad.R")

#If you have access to a Bloomberg Terminal, then the data is collected fresh from Bloomberg. Otherwise, the data stored on the computer in /data is loaded in
YEARS_IN_TEST = 9
source("DataLoad.R")

#Initialization of Running Data
size <- 0
accuracyMatrix <- matrix(nrow = 1,ncol = length(sectorNames))
colnames(accuracyMatrix) <- sectorNames
GLOBAL_ACCURACY <- 0.1

#Linear Analysis of Data.
source("linearAnalysis.R")

#ARIMA Analysis of Data.
source("arimaAnalysis.R")

#Random Forest Analysis of Data.
source("randomForestAnalysis.R")

#Calculation of Weightings and Rankings
source("geneticBreedv2.R")

# Go through all the generated weights and find the best one
source("fullTest.R")

# Print the graph of comparative cumulative returns
grid::grid.draw(gt)
t_finish = Sys.time()
print(t_finish - t_start)
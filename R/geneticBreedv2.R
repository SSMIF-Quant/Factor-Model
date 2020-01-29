# Load in SPX data for testing period
SPX_test = exp(as.xts(spx[[1]]))
SPX_test = SPX_test[index(SPX_test) >= index(sectorPrices$IT$`Testing Set`)[1],]
SPX_dailyRet_test = na.omit(diff(log(SPX_test)))
SPX_cumulRet_test = log(as.numeric(SPX_test) / as.numeric(SPX_test[1]))
# Load in Sector Index levels for testing period
sectorPriceMat = read.csv(paste("data/sectors.csv"))
sectorPriceMat = as.xts(sectorPriceMat[,-1], order.by = as.Date(sectorPriceMat$date))
sectorPriceMatTest = sectorPriceMat[index(sectorPriceMat) >= index(sectorPrices$IT$`Testing Set`)[1],]


# Create master prediction and accuracy database
masterPredictions = emptySectorList
masterPredictionsMat = as.data.frame(matrix(ncol = length(masterPredictions),nrow = nrow(predictedValuesLinearMat)))

predictionDatabase <- array(0,dim = c(nrow(predictedValuesLinearMat),ncol(predictedValuesLinearMat),size))
predictionDatabase[,,1] <- as.matrix(predictedValuesLinearMat)
predictionDatabase[,,2] <- as.matrix(predictedValuesARIMAMat)
predictionDatabase[,,3] <- as.matrix(predictedValuesRFMat)

for (i in 1:length(masterPredictions)) {
  totalPred <- rep(0,nrow(predictedValuesLinearMat))
  for (j in 1:size) {
    if (sum(accuracyMatrix[,i]) == 0) {
      accWeight <- 0
    } else {
      accWeight <- (as.numeric(accuracyMatrix[j,i])/sum(accuracyMatrix[,i]))
    }
    totalPred = totalPred + (accWeight*predictionDatabase[,i,j])
  }
  masterPredictions[[i]] <- totalPred
  masterPredictionsMat[,i] <- totalPred
}
names(masterPredictions) <- colnames(masterPredictionsMat) <- sectorNames
masterPredictionsMat = as.xts(masterPredictionsMat, order.by = index(sectorPrices$IT$`Testing Set`))

accSetOverall <- NULL
for (i in 1:ncol(masterPredictionsMat)) {
  testSet <- masterPredictionsMat[,i]
  realSet <- sectorPrices[[i]][["Testing Set"]][,1]
  resultSet <- NULL
  for (j in 1:length(testSet)) {
    if ((testSet[j] >= (realSet[j]*(1-GLOBAL_ACCURACY))) && (testSet[j] <= (realSet[j]*(1+GLOBAL_ACCURACY)))) {
      resultSet[j] <- 1
    } else {
      resultSet[j] <- 0
    }
  }
  accSetOverall <- c(accSetOverall,(sum(resultSet)/length(resultSet)))
  print(paste(sectorNames[i]," Accuracy: ",accSetOverall[i],sep = ''))
}
names(accSetOverall) <- sectorNames

covMat = cov((masterPredictionsMat/data.table::shift(masterPredictionsMat,1))[-1,])


# Implement Genetic Optimization Algorithm
survival_Rate = 1/3
minWeight = 0
maxWeight = 0.25
population_size = 6000
mutation_chance = 0.005
generations = 10

VaR = function(prices, pct) {
  returns = na.omit(diff(log(prices)))
  sort(as.numeric(returns))[round(nrow(returns) * (1 - pct))]
}

CVaR = function(prices, pct) {
  returns = na.omit(diff(log(prices)))
  under_var = sort(as.numeric(returns))[1:(round(nrow(returns) * (1 - pct)))]
  mean(under_var)
}


breeding <- function(p1,p2) {
  # Generate child nodes with the same length as parent (i.e. # of sectors)
  childA = childB = numeric(length = length(p1))
  
  # To determine each sector weight for the child nodes, randomly pull from one parent or the other
  #   -Generate random number 0 <= x <= 1
  #   -If x < =0.5, then child A inherits that sector's weight from parent 1 and child B from parent 2
  #   -Else, child A inherit's that sector's weight from parent 2 and child B from parent 1
  for (i in 1:length(p1)) {
    s = sample(seq(0,1,0.01),1)
    if (s <= 0.5) {
      childA[i] = p1[i]
      childB[i] = p2[i]
    } else {
      childA[i] = p2[i]
      childB[i] = p1[i]
    }
  }
  
  # Normalize weights at the end if necessary
  if (sum(childA) != 1) {
    childA = childA/sum(childA)
  }
  if (sum(childB) != 1) {
    childB = childB/sum(childB)
  }
  
  # Create child C which is average weights of respective sectors of children A and B
  childC = (childA+childB)/2
  
  # Return the three children
  return(list(childA,childB,childC))
}


# Mutation function - with 0.5% chance, each of the weights can be bumped up 1% and 
# a random one will be decreased a corresponding 1%
mutate = function(s) {
  for (i in 1:length(s)) {
    samp = sample(seq(0,1,0.0001),1)
    if (samp <= mutation_chance) {
      s[i] = s[1] + 0.01
      opposingEdit = sample(1:length(s))[1]
      s[opposingEdit] = s[opposingEdit] - 0.01
    }
  }
  return(s)
}

# Enforce weight constratints: Must be long (>=0%), can't be over 25%, and sum of weights = 1
childValidation <- function(w) {
  w = as.numeric(w)
  switch(tolower(as.character(sum(w) == 1 && 
                              all(w <= maxWeight) && 
                              all(w >= minWeight))), 
         true=w, 
         false=rep(0, 10))
}

# Take sector levels and sector weights to come up with portfolio value over time
portfolio_builder = function(prices, w) {
  as.xts(apply(X = prices, MARGIN = 1, FUN = function(p){p %*% w}))
}

# Plug in a set of weights to the objective function, which we are looking to maximize
score = function(w) {
  if(sum(w) == 0){
    return(-Inf)
  }
  
  # (0.85 * abs()) + (0.05 * Excess Vol) + (0.05 * VaR) + (0.05 * CVaR)
  a = c(0.05, 0.85, 0.05, 0.05)
  u = 0.1
  #p = portfolio_builder(masterPredictionsMat, w)
  p = portfolio_builder(sectorPriceMatTest, w) # *** THIS USES ACTUAL SECTOR LEVELS, NOT MODEL PREDICTIONS ***
  
  vol = abs((w %*% covMat %*% w) - (1 - u) * (sd(SPX_dailyRet_test)^2))
  ret = cumReturn(p)[nrow(masterPredictionsMat),1] - SPX_cumulRet_test[length(SPX_cumulRet_test)]
  var = VaR(p, 0.95) - VaR(SPX_test, 0.95)
  cvar = CVaR(p, 0.95) - CVaR(SPX_test, 0.95)
  
  (-a[1] * vol) + (a[2] * ret) + (a[3] * var) + (a[4] * cvar)
}

# Randomly generate the first generation
population = NULL
i<-1
while (i <= population_size) {
  w = sample(seq(minWeight, maxWeight, 0.01), 10)
  if (sum(w) == 1) {
    population = rbind(population, w)
    i = i + 1
  }
}
population = cbind(population,NA)

# Start breeding
currentGen = 1
totalTime = NULL
killScores = NULL
while (currentGen <= generations) {
  s = Sys.time()
  if (currentGen == 1) { cat("\014") }
  cat(paste("Generation ",currentGen," starting...\n",sep = ''))
  cat("       Scoring")
  
  # Go through and score the entire population
  for (i in 1:nrow(population)) {
    if (i %% 1000 == 0) {
      cat(".")
    }
    if(is.na(population[i, 11])) {
      population[i,11] = score(as.numeric(population[i,-11]))
    }
  }
  
  # Find the score threshold to only keep top 33 percent
  survivors = NULL
  threshold = sort(population[,11], decreasing = TRUE)[round(nrow(population) * survival_Rate)]
  killScores = c(killScores, threshold)
  
  # Kill bottom 2/3
  cat("\n       Culling...\n")
  survivors = population[population[,11] >= threshold,] # USE FOR EXACT TOP 1/3 METHOD
  #survivors = population[order(population[,11], decreasing = T),][1:round(nrow(population) * survival_Rate),] # USE FOR NORMAL DISTRIBUTION METHOD
  if(currentGen != generations) {
    survivors = survivors[,-11]
  }
  
  # Then breed the next generation if necessary
  if (currentGen != generations) {
    nextGen = NULL
    cat("       Breeding...\n")
    while (nrow(nextGen) < population_size || is.null(nextGen)) {
      # 1. Choose two random survivors that will be parents
      # 2. Breed the three children and then make sure they are valid
      chosen_pair = sample(1:nrow(survivors),2)
      kids = breeding(as.numeric(survivors[chosen_pair[1],]),as.numeric(survivors[chosen_pair[2],]))
      extracted_kids = t(sapply(kids, function(w) {childValidation(mutate(w))}))
      nextGen = rbind(nextGen,extracted_kids)
    }
    # Add scoring column for next iteration
    population = nextGen
    population = cbind(population,NA)
    currentGen = currentGen + 1
    e = Sys.time()
    totalTime = totalTime + (e-s)
    cat(paste("       Done! Time: ",(e-s),"\n",sep = ''))
  } else {
    population = survivors
    currentGen = currentGen + 1
    e = Sys.time()
    totalTime = totalTime + (e-s)
    cat(paste("       Done! Time: ",(e-s),"\n",sep = ''))
  }
}
print(totalTime)

weightsVector = round(as.numeric(population[which.max(population[,11]),-11]),digits = 2)
names(weightsVector) = sectorNames
plot(index(killScores),killScores)

randomForest_models <- emptySectorList

for (i in 1:length(randomForest_models)) {
  train_mat <- sectorPrices[[i]][["Training Set"]]
  randomForest_models[[i]] <- randomForest(as.formula(form),
                                           data = train_mat,
                                           ytest = train_mat[,1],
                                           ntree = 500,
                                           na.action = na.omit)
}
names(randomForest_models) <- sectorNames

predictedValuesRF <- emptySectorList
predictedValuesRFMat <- matrix(ncol = length(predictedValuesRF),nrow = nrow(predictedValuesLinearMat))

for (i in 1:length(predictedValuesARIMA)) {
  predict_mat <- sectorPrices[[i]][["Testing Set"]][,-1]
  preds <- predict(randomForest_models[[i]],newdata = predict_mat)
  predictedValuesRF[[i]] <- preds
  predictedValuesRFMat[,i] <- preds
}
names(predictedValuesRF) <- colnames(predictedValuesRFMat) <- sectorNames

accSetRF <- NULL
for (i in 1:ncol(predictedValuesRFMat)) {
  testSet <- predictedValuesRFMat[,i]
  realSet <- sectorPrices[[i]][["Testing Set"]][,1]
  resultSet <- NULL
  for (j in 1:length(testSet)) {
    if ((testSet[j] >= (realSet[j]*(1-GLOBAL_ACCURACY))) && (testSet[j] <= (realSet[j]*(1+GLOBAL_ACCURACY)))) {
      resultSet[j] <- 1
    } else {
      resultSet[j] <- 0
    }
  }
  accSetRF <- c(accSetRF,(sum(resultSet)/length(resultSet)))
  print(paste(sectorNames[i]," Accuracy: ",accSetRF[i],sep = ''))
}
names(accSetRF) <- sectorNames

size <- size + 1
if (size == 1) {
  accuracyMatrix[1,] <- accSetRF
  rownames(accuracyMatrix) <- "Random Forest"
} else {
  accuracyMatrix <- rbind(accuracyMatrix,accSetRF)
  rownames(accuracyMatrix)[size] <- "Random Forest"
}


print("Random Forest Analysis: Done!")

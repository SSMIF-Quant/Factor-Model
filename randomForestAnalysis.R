randomForest_models <- emptySectorList

for (i in 1:length(randomForest_models)) {
  train_mat <- sectorPrices[[i]][["Training Set"]]
  randomForest_models[[i]] <- randomForest(as.formula(form),
                                           data = train_mat,
                                           ntree = 500,
                                           na.action = na.omit)
}
names(randomForest_models) <- sectorNames

predictedValuesRF <- emptySectorList
predictedValuesRFMat <- matrix(ncol = length(predictedValuesRF),nrow = nrow(predictedValuesLinearMat))

for (i in 1:length(predictedValuesARIMA)) {
  predict_mat <- sectorPrices[[i]][["Testing Set"]]
  preds <- predict(randomForest_models[[i]],newdata = predict_mat)
  predictedValuesRF[[i]] <- preds
  predictedValuesRFMat[,i] <- preds
}
names(predictedValuesRF) <- colnames(predictedValuesRFMat) <- sectorNames

forestError <- sapply(1:ncol(predictedValuesRFMat), FUN=function(i) {
  sum(log(predictedValuesRFMat[,i] / sectorPrices[[i]][["Testing Set"]][, 2]) ^ 2)
})
for (i in 1:length(forestError)) {
  print(paste(sectorNames[i], " Total Error: ", round(forestError[i], 4), sep = ''))
}
names(forestError) <- sectorNames

size <- size + 1
if (size == 1) {
  accuracyMatrix[1,] <- forestError
  rownames(accuracyMatrix) <- "Random Forest"
} else {
  accuracyMatrix <- rbind(accuracyMatrix, forestError)
  rownames(accuracyMatrix)[size] <- "Random Forest"
}


print("Random Forest Analysis: Done!")

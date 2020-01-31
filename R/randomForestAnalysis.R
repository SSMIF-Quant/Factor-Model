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

forestMAPE <- sapply(1:ncol(predictedValuesRFMat), FUN=function(i) {
  mean(abs((predictedValuesRFMat[,i] - sectorPrices[[i]][["Testing Set"]][,1]) / sectorPrices[[i]][["Testing Set"]][, 1]))
})
for (i in 1:length(forestMAPE)) {
  print(paste(sectorNames[i], " MAPE: ", percent(forestMAPE[i], 0.001), sep = ''))
}
names(forestMAPE) <- sectorNames

size <- size + 1
if (size == 1) {
  accuracyMatrix[1,] <- forestMAPE
  rownames(accuracyMatrix) <- "Random Forest"
} else {
  accuracyMatrix <- rbind(accuracyMatrix, forestMAPE)
  rownames(accuracyMatrix)[size] <- "Random Forest"
}


print("Random Forest Analysis: Done!")

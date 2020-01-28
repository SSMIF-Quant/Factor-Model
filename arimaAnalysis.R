arima_models <- emptySectorList

regMatrices = vector("list", length = length(arima_models))
for (i in 1:length(arima_models)) {
  x <- sectorPrices[[i]][["Training Set"]]
  regMatrix <- matrix(ncol = ncol(x)-2,nrow = nrow(x))
  colN <- NULL
  for (j in 3:ncol(x)) {
    if (colnames(x)[j] == "EPSGrowthRate" || colnames(x)[j] == "EPS.Growth.Rate") {
      next()
    } else {
      regMatrix[,j-2] <- sectorPrices[[i]][["Training Set"]][,j]
      colN <- c(colN,colnames(x)[j])
    }
  }
  regMatrix <- regMatrix[,-5] # Remove the column where EPS Growth Rate was skipped over
  colnames(regMatrix) <- colN
  regMatrix <- regMatrix[,-which(sapply(as.data.frame(regMatrix), function(x){all(x==0 | is.na(x))}))] #remove cols with all zeroes
  regMatrices[[i]] = regMatrix
  arima_models[[i]] <- auto.arima(x[,1],xreg = regMatrix)
}
names(arima_models) <- sectorNames

coeffMatARIMA <- as.data.frame(matrix(nrow = ncol(regMatrix),ncol = length(sectorNames)))
colnames(coeffMatARIMA) <- sectorNames
rownames(coeffMatARIMA) <- colnames(regMatrix)
for (i in names(arima_models)) {
  coeffMatARIMA[,i] = eval(parse(text = paste("arima_models$",i,"$coef[rownames(coeffMatARIMA)]",sep = '')))
}

plotHeatMap3 = function(df) {
  tmp <- cbind(rownames(df),df)
  tmp <- melt(tmp)
  colnames(tmp) <- c("Factors", "Sectors", "Value")
  coeffHeatGGPlot2 <<- 'ggplot(tmp, aes(x = Sectors, y = Factors, fill = Value)) + geom_tile() +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0, space = "Lab") +
  labs(title = "Coeff Heatmap, ARIMA",caption = "Rounded to 4 Decimal Places") +
  geom_text(aes(label = round(Value,digits = 4)))'
  eval(parse(text = coeffHeatGGPlot2))
}
plotHeatMap3(coeffMatARIMA)

predictedValuesARIMA <- emptySectorList

predictedValuesARIMAMat <- as.data.frame(matrix(nrow = nrow(predictedValuesLinearMat),ncol = length(arima_models)))
for (i in 1:length(arima_models)) {
  sectDat <- sectorPrices[[i]][["Testing Set"]]
  preds <- forecast(arima_models[[i]],xreg = as.matrix(sectDat[,which(colnames(sectDat) %in% colnames(regMatrices[[i]]))]))
  preds <- preds$mean
  predictedValuesARIMA[[i]] <- preds
  predictedValuesARIMAMat[,i] <- preds
}
colnames(predictedValuesARIMAMat) <- names(predictedValuesARIMA) <- sectorNames

accSetARIMA <- NULL
for (i in 1:ncol(predictedValuesARIMAMat)) {
  testSet <- predictedValuesARIMAMat[,i]
  realSet <- sectorPrices[[i]][["Testing Set"]][,1]
  resultSet <- NULL
  for (j in 1:length(testSet)) {
    if ((testSet[j] >= (realSet[j]*(1-GLOBAL_ACCURACY))) && (testSet[j] <= (realSet[j]*(1+GLOBAL_ACCURACY)))) {
      resultSet[j] <- 1
    } else {
      resultSet[j] <- 0
    }
  }
  accSetARIMA <- c(accSetARIMA,(sum(resultSet)/length(resultSet)))
  print(paste(sectorNames[i]," Accuracy: ",accSetARIMA[i],sep = ''))
}
names(accSetARIMA) <- sectorNames

size <- size + 1
if (size == 1) {
  accuracyMatrix[1,] <- accSetARIMA
  rownames(accuracyMatrix) <- "ARIMA Regression"
} else {
  accuracyMatrix <- rbind(accuracyMatrix,accSetARIMA)
  rownames(accuracyMatrix)[size] <- "ARIMA Regression"
}

print("ARIMA Analysis: Done!")

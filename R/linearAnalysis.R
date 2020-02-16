linear_models <- emptySectorList

for (i in 1:length(sectorPrices)) {
  sectDat <- sectorPrices[[i]][["Training Set"]]
  form <- paste(colnames(sectDat)[2]," ~ ",colnames(sectDat)[3],sep='')
  for (j in colnames(sectDat)[4:ncol(sectDat)]) {
    if (j == "EPSGrowthRate"|| j == "PutCallOpenInterest" || j == "InstitutionOwnership") {
      next()
    } else {
      form <- paste(form,as.character(j),sep = " + ")
    }
  }
  linear_models[[i]] <- lm(form,sectDat)
}
names(linear_models) <- sectorNames

pValMatrix <- as.data.frame(matrix(
  nrow = length(colnames(sectDat)[3:ncol(sectDat)][-(which(colnames(sectDat) == "EPSGrowthRate")-2)]),
  ncol = length(sectorNames))
)
rownames(pValMatrix) <- colnames(sectDat)[3:ncol(sectDat)][-(which(colnames(sectDat) == "EPSGrowthRate")-2)]
colnames(pValMatrix) <- sectorNames
for (i in 1:length(linear_models)) {
  sTest <- summary(linear_models[[i]])
  for (metric in rownames(pValMatrix)) {
    pValMatrix[metric, i] <- sTest[["coefficients"]][2:nrow(sTest[["coefficients"]]),4][metric]
  }
}

plotHeatMap = function(df) {
  tmp <- cbind(rownames(df),df)
  tmp <- melt(tmp)
  colnames(tmp) <- c("Factors", "Sectors", "Value")
  pValGGPlot <<- 'ggplot(tmp, aes(x = Sectors, y = Factors, fill = Value)) + geom_tile() +
    scale_fill_gradient2(low = "white", high = "blue", midpoint = 0, space = "Lab") + 
    labs(title = "Cold Plot", subtitle = "The bluer the area, the worse the P-Value",caption = "Rounded to 4 Decimal Places") +
    geom_text(aes(label = round(Value,digits = 4)))'
  eval(parse(text = pValGGPlot))
}
# png(filename = "Cold Plot.png",width = 862,height = 550,units = "px")
# plotHeatMap(pValMatrix)
# dev.off()
plotHeatMap(pValMatrix)

#write.csv(pValMatrix,file = "output/P Value Matrix.csv")

coeffMatrix <- as.data.frame(matrix(nrow = nrow(pValMatrix),ncol = length(sectorNames)))
rownames(coeffMatrix) <- rownames(pValMatrix)
colnames(coeffMatrix) <- sectorNames
for (i in 1:length(linear_models)) {
  sTest <- summary(linear_models[[i]])
  for(metric in rownames(coeffMatrix)) {
    coeffMatrix[metric, i] <- sTest[["coefficients"]][2:nrow(sTest[["coefficients"]]),1][metric]
  }
}

plotHeatMap2 = function(df) {
  tmp <- cbind(rownames(df),df)
  tmp <- melt(tmp)
  colnames(tmp) <- c("Factors", "Sectors", "Value")
  coeffHeatGGPlot <<- 'ggplot(tmp, aes(x = Sectors, y = Factors, fill = Value)) + geom_tile() +
    scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0, space = "Lab") +
    labs(title = "Coeff Heatmap, Linear",caption = "Rounded to 2 Decimal Places") +
    geom_text(aes(label = round(Value,digits = 2)))'
  eval(parse(text = coeffHeatGGPlot))
}
plotHeatMap2(coeffMatrix)

plotRSquared = function(lst) {
  tmp <- sapply(lst, function(x) summary(x)$r.squared)
  tmp <- cbind(names(tmp),as.data.frame(tmp))
  colnames(tmp) <- c("Sectors", "RSquared")
  rSquareGGPlot <<- 'ggplot(tmp, aes(x=Sectors,y=RSquared,ymax=1)) + geom_bar(stat = "identity") + geom_text(aes(label = round(RSquared,digits = 4)),nudge_y=.02) + labs(title = "R-Squareds, Linear Model (New)")'
  eval(parse(text = rSquareGGPlot))
}
plotRSquared(linear_models)

predictedValuesLinear <- emptySectorList

predictedValuesLinearMat <- as.data.frame(matrix(nrow = nrow(sectorPrices[[1]][["Testing Set"]]), ncol = length(linear_models)))
for (i in 1:length(linear_models)) {
  preds <- predict.lm(linear_models[[i]],newdata = sectorPrices[[i]][["Testing Set"]][,-1])
  predictedValuesLinear[[i]] <- preds
  predictedValuesLinearMat[,i] <- preds
}
names(predictedValuesLinear) <- sectorNames
colnames(predictedValuesLinearMat) <- names(predictedValuesLinear)

linearMAPE <- sapply(1:ncol(predictedValuesLinearMat), FUN=function(i) {
  mean(abs((predictedValuesLinearMat[,i] - sectorPrices[[i]][["Testing Set"]][,2]) / sectorPrices[[i]][["Testing Set"]][, 2]))
})
for (i in 1:length(linearMAPE)) {
  print(paste(sectorNames[i], " MAPE: ", percent(linearMAPE[i], 0.001), sep = ''))
}
names(linearMAPE) <- sectorNames

plotAccLinear <- function() {
  tmp <- linearMAPE
  tmp <- cbind(names(tmp),as.data.frame(tmp))
  colnames(tmp) <- c("Sectors", "Accuracy")
  rSquareGGPlot <<- 'ggplot(tmp, aes(x=Sectors,y=Accuracy)) + geom_bar(stat = "identity") + geom_text(aes(label = round(Accuracy,digits = 4)),nudge_y=.02) + labs(title = "Accuracy, Linear Model (New)")'
  eval(parse(text = rSquareGGPlot))
}
plotAccLinear()

size <- size + 1
if (size == 1) {
  accuracyMatrix[1,] <- linearMAPE
  rownames(accuracyMatrix) <- "Linear Regression"
} else {
  accuracyMatrix <- rbind(accuracyMatrix, linearMAPE)
  rownames(accuracyMatrix)[size] <- "Linear Regression"
}

print("Linear Analysis: Done!")

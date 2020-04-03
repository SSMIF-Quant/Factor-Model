if (require(ggplot2) == FALSE) {
  install.packages("ggplot2")
}
library(ggplot2)

if (require(lubridate) == FALSE) {
  install.packages("lubridate")
}
library(lubridate)

if (require(reshape2) == FALSE) {
  install.packages("reshape2")
}
library(reshape2)

if (require(Rblpapi) == FALSE) {
  install.packages("Rblpapi")
}
library(Rblpapi)

if (require(xts) == FALSE) {
  install.packages("xts")
}
library(xts)

if(require(forecast) == FALSE) {
  install.packages("forecast")
}
library(forecast)

if(require(randomForest) == FALSE) {
  install.packages("randomForest")
}
library(randomForest)

if(require(PortfolioAnalytics) == FALSE) {
  install.packages("PortfolioAnalytics")
}
library(PortfolioAnalytics)

if(require(fPortfolio)==FALSE) {
  install.packages("fPortfolio")
}
library(fPortfolio)

if(require(scales)==FALSE) {
  install.packages("scales")
}
library(scales)

if(require(randomcoloR)==FALSE) {
  install.packages("randomcoloR")
}
library(randomcoloR)

if(require(RColorBrewer)==FALSE) {
  install.packages("RColorBrewer")
}
library(RColorBrewer)

if(require(cowplot)==FALSE) {
  install.packages("cowplot")
}
library(cowplot)

if(require(grid)==FALSE) {
  install.packages("grid")
}
library(grid)

if(require(data.table)==FALSE) {
  install.packages("data.table")
}
library(data.table)

print("Package Loading: Done!")
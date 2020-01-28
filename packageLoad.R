if (require(ggplot2) == FALSE) {
  install.packages("ggplot2")
  library(ggplot2)
} else {
  library(ggplot2)
}

if (require(lubridate) == FALSE) {
  install.packages("lubridate")
  library(lubridate)
} else {
  library(lubridate)
}

if (require(reshape2) == FALSE) {
  install.packages("reshape2")
  library(reshape2)
} else {
  library(reshape2)
}

if (require(Rblpapi) == FALSE) {
  install.packages("Rblpapi")
  library(Rblpapi)
} else {
  library(Rblpapi)
}

if (require(xts) == FALSE) {
  install.packages("xts")
  library(xts)
} else {
  library(xts)
}

if(require(forecast) == FALSE) {
  install.packages("forecast")
  library(forecast)
} else {
  library(forecast)
}

if(require(randomForest) == FALSE) {
  install.packages("randomForest")
  library(randomForest)
} else {
  library(randomForest)
}

if(require(PortfolioAnalytics) == FALSE) {
  install.packages("PortfolioAnalytics")
  library(PortfolioAnalytics)
} else {
  library(PortfolioAnalytics)
}

if(require(fPortfolio)==FALSE) {
  install.packages("fPortfolio")
  library(fPortfolio)
} else {
  library(fPortfolio)
}

if(require(scales)==FALSE) {
  install.packages("scales")
  library(scales)
} else {
  library(scales)
}

if(require(randomcoloR)==FALSE) {
  install.packages("randomcoloR")
  library(randomcoloR)
} else {
  library(randomcoloR)
}

print("Package Loading: Done!")
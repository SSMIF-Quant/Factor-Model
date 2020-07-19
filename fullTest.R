resultsFolder = gsub("-", "", as.character(Sys.Date()))
savePath = file.path(getwd(), "results", resultsFolder)
if(!file.exists(file.path(getwd(), "results"))) {
  dir.create(file.path(getwd(), "results"))
}
if(!file.exists(resultsFolder)) {
  dir.create(savePath)
}


# Plot weights
weights_df = data.frame(weights=weightsVector, sectors=names(weightsVector))
weights_plot <- ggplot(weights_df[weights_df$weights > 0,], aes(x="", y=weights, fill=sectors)) + 
  geom_bar(width=1, stat="identity") + 
  coord_polar("y") + 
  theme_void() + 
  theme(legend.position = "none") +
  scale_fill_manual(values=RColorBrewer::brewer.pal(10, "Set3")) +
  geom_text(aes(y = weights, label = paste(sectors, ": ", percent(weights), sep="")), position = position_stack(vjust = 0.5))


SPX_all = as.xts(exp(spx[[1]]), order.by = as.Date(rownames(spx[[1]])))
#sectorPriceMat = read.csv("data/sectors.csv")
#sectorPriceMat = as.xts(sectorPriceMat[,-1], order.by = as.Date(sectorPriceMat[,1]))

returnCalculation = function(df) {
  return(apply(X=df, FUN=function(x){cumReturn(x)}, MARGIN=2))
}

port = portfolio_builder(sectorPriceMat, weightsVector)
port_cumulRet = returnCalculation(port)[nrow(port)]
port_sd = sd(na.omit(diff(log(port)))) * sqrt(nrow(port))

mkt_ret = returnCalculation(SPX_all)[nrow(SPX_all)]
mkt_sd = sd(na.omit(diff(log(SPX_all)))) * sqrt(nrow(SPX_all))

# Return Comparison and Sharpe Ratio
returnComparison = as.xts(data.frame(returnCalculation(port), returnCalculation(SPX_all)),
                          order.by=index(port))
colnames(returnComparison) = c("Portfolio", "SPX")

(totalReturnComparison = returnComparison[nrow(returnComparison),])
(sdComparison = c(Portfolio=port_sd, SPX=mkt_sd))
(sharpeComparison = returnComparison[nrow(returnComparison),]/c(port_sd, mkt_sd))
ymax = ceiling(max(returnComparison*10))*10

recessionDatesdf = data.frame(xmin=c(as.Date("1990-07-02"), as.Date("2001-03-01"), as.Date("2007-11-30")), 
                              xmax=c(as.Date("1991-03-01"), as.Date("2001-11-01"), as.Date("2009-06-30")))


# Relative Cumulative Returns (Full Period)
{returnsGraph <- ggplot(returnComparison*100) +
    # 1990-1991 recession
    geom_rect(data = recessionDatesdf[1,], aes(xmin=xmin,xmax=xmax,ymin=-25,ymax=ymax), fill="darkgrey", alpha=0.5) +
    # 2001 recession
    geom_rect(data = recessionDatesdf[2,], aes(xmin=xmin,xmax=xmax,ymin=-25,ymax=ymax), fill="darkgrey", alpha=0.5) +
    # 2008 recession
    geom_rect(data = recessionDatesdf[3,], aes(xmin=xmin,xmax=xmax,ymin=-25,ymax=ymax), fill="darkgrey", alpha=0.5) +
    geom_line(aes(x=as.Date(Index), y=Portfolio, color = "Portfolio")) +
    annotate("text", x = as.Date(index(totalReturnComparison)), y = totalReturnComparison$Portfolio*100, 
             label=paste(round(totalReturnComparison$Portfolio*100, 2), "%", sep=""), hjust = -0.05, size = 3.25) + 
    geom_line(aes(x=as.Date(Index), y=SPX, color = "SPX")) +
    annotate("text", x = as.Date(index(totalReturnComparison)), y = totalReturnComparison$SPX*100, 
             label=paste(round(totalReturnComparison$SPX*100, 2), "%", sep=""), hjust = -0.08, size = 3.25) +
    labs(title = "Cumulative Returns Comparison - since 1990") + ylab("Return (%)") + xlab("Time") +
    scale_color_manual("",breaks = c("Portfolio","SPX"),values = c("red","blue")) +
    scale_x_date(labels = scales::date_format("%Y"), breaks = scales::date_breaks("2 years"), expand = c(0,0)) +
    scale_y_continuous(expand = c(0,0)) +
    theme(legend.position="top", plot.margin=unit(c(0.5,1.5,0.5,0.5),"cm"))
gt = ggplot2::ggplotGrob(returnsGraph)
gt$layout$clip[gt$layout$name == "panel"] = "off"}
cowplot::save_plot(file.path(savePath, "cumulativeReturns.png"), plot=grid::grid.draw(gt), base_width=8, base_height=4.5)


# Relative Cumulative Returns (Testing Period)
returnComparisonTest = as.xts(data.frame(returnCalculation(portfolio_builder(sectorPriceMatTest, weightsVector)), 
                              returnCalculation(SPX_test)), order.by=index(SPX_test))
colnames(returnComparisonTest) = c("Portfolio", "SPX")
(totalReturnComparisonTest = returnComparisonTest[nrow(returnComparisonTest),])
ymaxTest = ceiling(max(totalReturnComparisonTest*10))*10
{returnsGraphTest <- ggplot(returnComparisonTest*100) +
    geom_line(aes(x=as.Date(Index), y=Portfolio, color = "Portfolio")) +
    annotate("text", x = as.Date(index(totalReturnComparisonTest)), y = totalReturnComparisonTest$Portfolio*100, 
             label=paste(round(totalReturnComparisonTest$Portfolio*100, 2), "%", sep=""), hjust = -0.05, size = 3.25) + 
    geom_line(aes(x=as.Date(Index), y=SPX, color = "SPX")) +
    annotate("text", x = as.Date(index(totalReturnComparisonTest)), y = totalReturnComparisonTest$SPX*100, 
             label=paste(round(totalReturnComparisonTest$SPX*100, 2), "%", sep=""), hjust = -0.08, size = 3.25) +
    labs(title = "Cumulative Returns Comparison - Testing Period") + ylab("Return (%)") + xlab("Time") +
    scale_color_manual("",breaks = c("Portfolio","SPX"),values = c("red","blue")) +
    scale_x_date(labels = scales::date_format("%Y"), breaks = scales::date_breaks("2 years"), expand = c(0,0)) +
    scale_y_continuous(expand = c(0,0)) +
    theme(legend.position="top", plot.margin=unit(c(0.5,1.5,0.5,0.5),"cm"))
gt2 = ggplotGrob(returnsGraphTest)
gt2$layout$clip[gt2$layout$name == "panel"] = "off"}
cowplot::save_plot(file.path(savePath, "cumulativeReturnsTest.png"), plot=grid::grid.draw(gt2), base_width=6, base_height=3.5)


# Relative Cumulative Returns (Current Semester)
sem_start = as.Date("2020-01-21")
returnComparisonSem = as.xts(data.frame(returnCalculation(portfolio_builder(sectorPriceMatTest[index(sectorPriceMatTest) >= sem_start], 
                                                                            weightsVector)), 
                                         returnCalculation(SPX_test[index(SPX_test) >= sem_start])), 
                             order.by=index(SPX_test[index(SPX_test) >= sem_start]))
colnames(returnComparisonSem) = c("Portfolio", "SPX")
(totalReturnComparisonSem = returnComparisonSem[nrow(returnComparisonSem),])
ymaxTest = ceiling(max(totalReturnComparisonSem*10))*10
{returnsGraphSem <- ggplot(returnComparisonSem*100) +
    geom_line(aes(x=as.Date(Index), y=Portfolio, color = "Portfolio")) +
    annotate("text", x = as.Date(index(totalReturnComparisonSem)), y = totalReturnComparisonSem$Portfolio*100, 
             label=paste(round(totalReturnComparisonSem$Portfolio*100, 2), "%", sep=""), hjust = -0.05, size = 3.25) + 
    geom_line(aes(x=as.Date(Index), y=SPX, color = "SPX")) +
    annotate("text", x = as.Date(index(totalReturnComparisonSem)), y = totalReturnComparisonSem$SPX*100, 
             label=paste(round(totalReturnComparisonSem$SPX*100, 2), "%", sep=""), hjust = -0.08, size = 3.25) +
    labs(title = "Cumulative Returns Comparison - This Semester") + ylab("Return (%)") + xlab("Time") +
    scale_color_manual("",breaks = c("Portfolio","SPX"),values = c("red","blue")) +
    scale_x_date(labels = scales::date_format("%b %d"), breaks = scales::date_breaks("2 weeks"), expand = c(0,0)) +
    scale_y_continuous(expand = c(0,0)) +
    theme(legend.position="top", plot.margin=unit(c(0.5,1.5,0.5,0.5),"cm"))
  gt3 = ggplotGrob(returnsGraphSem)
  gt3$layout$clip[gt3$layout$name == "panel"] = "off"}
cowplot::save_plot(file.path(savePath, "cumulativeReturnsSem.png"), plot=grid::grid.draw(gt3), base_width=6, base_height=3.5)


# Recession Stress Test (% Return of Portfolio vs SPX)
recessionTest = matrix(ncol=nrow(recessionDatesdf), nrow=2)
recessionTest[1,] = apply(X = recessionDatesdf, MARGIN = 1,
                          FUN = function(x){log(as.numeric(port[x[2],])/as.numeric(port[x[1],]))})
recessionTest[2,] = apply(X = recessionDatesdf, MARGIN = 1,
                          FUN = function(x){log(as.numeric(SPX_all[x[2],])/as.numeric(SPX_all[x[1],]))})
rownames(recessionTest) = c("Portfolio", "SPX")
colnames(recessionTest) = c("1990-1991", "2001", "2008-2009")
recessionTest*100


# Put stats into dataframe and save image of it
metrics = c("Period", "Return", "Risk", "Sharpe", "Daily 95% VaR", "Daily 95% CVaR", "1990 Recession", "2001 Recession", "2008 Recession")
port_metrics = c("1990-2020", scales::percent(port_cumulRet, 0.01), scales::percent(port_sd, 0.01), round(port_cumulRet/port_sd, 2),
                 scales::percent(VaR(port, 0.95), 0.01), scales::percent(CVaR(port, 0.95), 0.01), scales::percent(unname(recessionTest[1,]), 0.01))
spx_metrics = c("1990-2020", scales::percent(mkt_ret, 0.01), scales::percent(mkt_sd, 0.01), round(mkt_ret/mkt_sd, 2),
                scales::percent(VaR(SPX_all, 0.95), 0.01), scales::percent(CVaR(SPX_all, 0.95), 0.01), scales::percent(unname(recessionTest[2,]), 0.01))
stats = data.frame(Metric=metrics, Portfolio=port_metrics, SPX=spx_metrics)
write.csv(stats, file.path(savePath, "stats.csv"), row.names = F)


# Plot each sector's returns
{sectorPricesdf = read.csv(paste("data/sectors.csv"), col.names=c("date", sectorNames))
sectorPricesdf[,2:11] = returnCalculation(sectorPricesdf[,2:11])
sectorPricesdf = melt(sectorPricesdf, id.vars="date", variable.name="sector", value.name="return")
sectorReturns <- ggplot(sectorPricesdf) + 
    geom_rect(data = recessionDatesdf, aes(xmin=xmin,xmax=xmax,ymin=-.8,ymax=3.5), fill="darkgrey", alpha=0.5) + 
    geom_line(aes(x=as.Date(date), y=return, color=sector, group=sector), size=0.1) +
    scale_color_manual("", breaks = sectorPricesdf$sector, values=c(rainbow(6, start=0.9), randomcoloR::distinctColorPalette(k=4))) +
    labs(title="Sector Returns") + xlab("Year") + ylab("Return") +
    scale_x_date(labels = scales::date_format("%Y"), breaks = scales::date_breaks("2 years"), expand = c(0,0)) +
    scale_y_continuous(expand = c(0,0), labels = scales::percent_format())}
ggsave(file.path(savePath, "sectorReturns.png"), plot=sectorReturns, width=8, height=3, units="in")


# Plot predicted returns versus actual per sector
{colnames(sectorPriceMatTest) = sectorNames
actualDF = melt(cbind(Date=index(sectorPriceMatTest), as.data.frame(apply(sectorPriceMatTest, 2, cumReturn))), 
                measure.vars = sectorNames, variable.name="sector", value.name = "CumulativeReturn")
actualDF$Type = "Actual"
predDF = melt(cbind(Date=index(masterPredictionsMat), as.data.frame(apply(exp(masterPredictionsMat), 2, cumReturn))), 
              measure.vars = sectorNames, variable.name="sector", value.name = "CumulativeReturn")
predDF$Type = "Pred"
(modelAssessment <- ggplot(data=rbind(actualDF, predDF)) +
  geom_line(aes(x=Date, y=CumulativeReturn, color=Type), size=0.3) + 
  facet_wrap(~sector, nrow = 2) +
  labs(title="Model Predictions vs. Actual Sector Levels (2011-Present)", ylab="Cumulative Return (%)") +
  scale_x_date(labels = scales::date_format("%Y"), breaks = scales::date_breaks("3 years"), expand = c(0,0)))}
ggsave(file.path(savePath, "modelAssessment.png"), plot=modelAssessment, width=8, height=4, units="in")


# Save weights into CSV file (date run, date of data, and weights)
historyFile = "weightsHistory.csv"
historyPath = file.path(getwd(), "results", historyFile)
if(!file.exists(historyPath)) {
  file.create(historyPath)
  cols = c("Run Date", "Data Date", sectorNames)
  headers = as.data.frame(matrix(ncol=length(cols), nrow=0))
  colnames(headers) = cols
  write.csv(headers, historyFile, row.names = F)
}
currentRun = t(as.matrix(c(as.character(Sys.Date()), as.character(as.Date(file.info("data/SPX.csv")$mtime)), weightsVector)))
write.table(currentRun, file=historyPath, append = T, sep=",", row.names=F, col.names=F)

# Define common variables and helper functions
data.startDate <- as.Date("1990-01-31")
sectorNames <- c("IT","FIN","ENG","HLTH","CONS","COND","INDU","UTIL","TELS","MATR")
emptySectorList = vector("list", length = length(sectorNames))
names(emptySectorList) = sectorNames
# Add S5REAS and XLRE for real estate sector
sector.indices <- c("S5INFT Index", "S5FINL Index", "S5ENRS Index",
                    "S5HLTH Index", "S5CONS Index", "S5COND Index",
                    "S5INDU Index", "S5UTIL Index", "S5TELS Index",
                    "S5MATR Index")
index.names <- sub(" Index", "", sector.indices)

clean <- function(df, dataSet) {
  df <- as.data.frame(df)
  colnames(df) <- "PX_LAST"
  rownames(df) <- dataSet[, 1]
  return(df)
}

numerify <- function(df) {
  res <- sapply(df, function(x) as.numeric(as.character(x)))
  rownames(res) <- rownames(df)
  return(res)
}

cumReturn <- function(x) {
  if("xts" %in% class(x)) {
    return(log(c(x)/as.numeric(x[1])))
  }
  return(as.xts(log(c(x)/as.numeric(x[1])), order.by = as.Date(index(x))))
}

# Remove all market holidays and closures (price and valuations are zero)
getHolidays = function(df) {
  # addtl unplanned closures for 9/11, Presidential dealths/funerals, and Hurricane Sandy
  holidays = c(seq.Date(from=as.Date("2001-09-11"), to=as.Date("2001-09-14"),
                        by="1 day"), as.Date("2018-12-05"), as.Date("2012-10-29"), as.Date("2012-10-30"),
               as.Date("2004-06-11"), as.Date("1994-04-27"), as.Date("2007-01-02"))
  # get the holidays during the span of this data (year of first row to current year)
  firstYear = year(data.startDate)
  currentYear = year(Sys.Date())
  holidays = c(as.Date(holidayNYSE(firstYear:currentYear)), holidays)
  # finally, as a catch-all, remove any other rows with zeroes
  others = as.Date(index(df[df$price == 0,]))[!as.Date(index(df[df$price == 0,])) %in% holidays]
  holidays = c(holidays, others)
  return(holidays)
}

# Retrieve new data and/or load in existing data
tryCatch(
  {
    # First try to connect to Bloomberg and retrieve new data
    blpConnect()
    Time_Interval = seq(data.startDate, Sys.Date(), 1)
    opt = c("periodicitySelection" = "DAILY")

    # Request SPX index level and write to file
    # Change this so that if SPX.csv already exists, only update since the last date there
    retrieveSPX = function() {
      write.csv(bdh("SPX Index", c("PX_LAST"), start.date=data.startDate,
                    options = opt), file = "data/SPX.csv", row.names = FALSE)
    }

    # Request ratios and yields for each sector and write to corresponding files
    retrieveValuationData = function() {
      valuationFields = c("PX_LAST","PE_RATIO", "PX_TO_BOOK_RATIO", "PX_TO_SALES_RATIO",
                          "FREE_CASH_FLOW_YIELD", "EST_LTG_EPS_AGGTE",
                          "TOT_DEBT_TO_TOT_ASSET", "EARN_YLD")
      for (i in 1:length(sector.indices)) {
        tes = bdh(sector.indices[i], valuationFields, start.date = data.startDate,
                   options = opt)
        tes = as.data.frame(na.fill(tes, 0))
        tes = tes[-which(as.Date(tes$date) %in% getHolidays(tes)),] # remove holidays
        write.csv(tes, paste("data/valuation/", index.names[i], " Value Data.csv", sep = ''),
                  row.names = FALSE)
      }
    }

    # Request sentiment fields for each sector and write to corresponding files
    retrieveSentimentData = function() {
      sectorETFs = c("XLK US Equity", "XLF US Equity", "XLE US Equity",
                     "XLV US Equity", "XLP US Equity", "XLY US Equity",
                     "XLI US Equity", "XLU US Equity", "XLC US Equity",
                     "XLB US Equity")
      sentimentFields = c("PX_LAST","PUT_CALL_OPEN_INTEREST_RATIO","EQY_INST_PCT_SH_OUT","PX_VOLUME")
      for (i in 1:length(sectorETFs)) {
        # Use sector ETFs to get sentiment fields
        tes = bdh(sectorETFs[i], sentimentFields, start.date = data.startDate,
                  options = opt, int.as.double = TRUE, include.non.trading.days = TRUE)

        # Institution Ownership only has data on Sundays, so fill in Sunday's value for the next week
        non_zeroes <- which(tes$EQY_INST_PCT_SH_OUT > 0)
        for (j in 1:length(non_zeroes)) {
          # Find how far down to go once we find a value
          if(j == length(non_zeroes)) {
            range = (non_zeroes[j]+1):nrow(tes)
          } else {
            range = (non_zeroes[j]+1):(non_zeroes[j+1]-1)
          }
          # Then fill in that range
          for(k in range) {
            tes[k, "EQY_INST_PCT_SH_OUT"] = tes[non_zeroes[j], "EQY_INST_PCT_SH_OUT"]
          }
        }

        # Then query for the actual index level for those same dates
        sectorPrice = bdh(sector.indices[i], c("PX_LAST"), start.date = data.startDate,
                          options = opt, int.as.double = TRUE, include.non.trading.days = TRUE)
        tes = cbind(sectorPrice, tes[, -c(1, 2)]) # Replace dates/prices of ETF with actual index
        tes = tes[-which(as.Date(tes$date) %in% getHolidays(tes)),] # remove holidays
        write.csv(tes, file = paste("data/sentiment/", index.names[i], " Sentiment Data.csv", sep = ""),
                  row.names = FALSE)
      }
    }

    retrieveEconData = function() {
      econIndices = c("EHGDUS Index", "USGG2YR Index", "USGG10YR Index", "USURTOT Index",
                      "PRUSTOT Index", "CONSSENT Index", "CPI YOY Index")
      for(i in 1:length(econIndices)) {
        # Get data, but start at last quarter's end because of GDP growth
        tes = bdh(econIndices[i], c("PX_LAST"), start.date = as.Date(timeLastDayInQuarter(data.startDate - 90)),
                  options = opt, int.as.double = TRUE, include.non.trading.days = TRUE)
        tes = tes[as.Date(tes$date) <= Sys.Date(),]
        if(i == 1) {
          econData = matrix(ncol = length(econIndices)+1, nrow = nrow(tes))
          econData[,1] = as.character(tes[, 1])
        }

        if(i %in% c(1, 4:7)) {
          non_zeroes <- which(tes[,2] > 0)
          for (j in 1:length(non_zeroes)) {
            # Find how far down to go once we find a value
            if(j == length(non_zeroes)) {
              range = (non_zeroes[j]+1):nrow(tes)
            } else {
              range = (non_zeroes[j]+1):(non_zeroes[j+1]-1)
            }
            # Then fill in that range
            for(k in range) {
              tes[k, 2] = tes[non_zeroes[j], 2]
            }
          }
        }
        tes = tes[which(!is.na(tes$date)),]
        econData[,i+1] = tes[, 2]
      }
      econData = as.data.frame(econData)
      colnames(econData) = c("date", econIndices)
      econData = econData[as.Date(econData$date) >= data.startDate,]
      econData = econData[-which(as.Date(econData$date) %in% getHolidays(tes)),] # remove holidays
      write.csv(econData, file = "data/economic/econData.csv", row.names = FALSE)
    }

    # Merge all sector levels together and write to a file
    writeSectorData = function() {
      for (i in 1:length(index.names)) {
        tes = read.csv(paste("data/valuation/", index.names[i], " Value Data.csv", sep = ""))
        if(i == 1) {
          sectors = matrix(nrow = nrow(tes), ncol = length(index.names) + 1)
          sectors[,1] = as.character(tes[,1])
        }
        sectors[,i+1] = tes[,2]
      }
      colnames(sectors) = c("date", index.names)
      write.csv(sectors, "data/sectors.csv", row.names = FALSE)
    }

    # Finally, call all the above functions
    retrieveSPX()
    retrieveValuationData()
    retrieveSentimentData()
    retrieveEconData()
    writeSectorData()
  },
  error = function(x) {
    message("Not logged into Bloomberg or not on terminal, defaulting to existing data...")
  },
  finally =
  { # This is where all the data that was saved above gets loaded in and cleaned
    # Import sector prices and create master list of data for each sector
    loadSectorData = function() {
      sectors = read.csv("data/sectors.csv", colClasses = "character")
      colnames(sectors) = c("date", index.names)

      res <- emptySectorList
      cols = c("price", "logPrice", "P/E", "P/B", "P/S", "FCF Yield", "PEG", "EPS Growth Rate", "Debt/Asset Percentage",
               "Earnings Yield", "Put/Call Open Interest", "Institution Ownership", "Volume", "Training Set",
               "Testing Set")
      for(i in 1:length(sectorNames)) {
        res[[sectorNames[i]]] = vector("list", length=length(cols))
        names(res[[sectorNames[i]]]) = cols
        price = sectors[, index.names[i]] %>% clean(sectors) %>% numerify
        res[[sectorNames[i]]][["price"]] = price
        res[[sectorNames[i]]][["logPrice"]] = log(price)
      }
      return(res)
    }
    sectorPrices <<- loadSectorData()

    loadEconData = function() {
      econData = read.csv("data/economic/econData.csv")
      econData$date = as.Date(econData$date)
      datesToCheck = as.Date(rownames(sectorPrices[[1]][[1]])) # limit to just what's in sectorPrices
      econData = econData[which(econData$date %in% datesToCheck),]
      return(econData)
    }
    econData = loadEconData()

    # Get data in the "SPX.csv" file and log transform the prices
    loadSPX = function() {
      spx <- read.csv("data/SPX.csv", colClasses = "character")
      return(list(spx[,2] %>% clean(spx) %>% numerify %>% log))
    }
    spx = loadSPX()
    Time_Interval <<- seq(data.startDate,as.Date.character(rownames(spx[[1]])[nrow(spx[[1]])]),1)

    loadValuationData = function() {
      for (i in 1:length(index.names)) {
        value = read.csv(paste("data/valuation/", index.names[i], " Value Data.csv", sep = ""))
        sentiment = read.csv(paste("data/sentiment/", index.names[i], " Sentiment Data.csv", sep = ""))

        # Merge the sentiment data with valuation metrics
        value = merge(value, sentiment[,-2], by="date")

        for (j in 3:(length(sectorPrices[[i]])-2)) {
          if (j == 7) { # Calculate PEG (Price / FCF Yield?)
            signFactor <- as.matrix(sign(value[,2]) * sign(value[,6]))
            sectorPrices[[i]][[j]] <<- signFactor * log(abs(as.matrix((value[,2]/value[,6]))))
          } else if (j >= 8) { # EPS Growth, D/A, Earnings Yield, Put/Call, Institution Ownership, and Volume
            sectorPrices[[i]][[j]] <<- as.matrix(sign(value[,j-1])) * abs(as.matrix(value[,j-1]))
          } else { # P/E, P/S, FCF Yield
            sectorPrices[[i]][[j]] <<- as.matrix(sign(value[,j])) * abs(as.matrix(value[,j]))
          }
          for (z in 1:length(sectorPrices[[i]][[j]])) {
            if(!(is.finite(sectorPrices[[i]][[j]][z]))) {
              sectorPrices[[i]][[j]][z] <<- 0
            }
          }
        }
      }
    }
    loadValuationData()

    # Split the total data roughly 70/30 into training/testing sets
    trainTestSplitting = function() {
      for (i in 1:length(sectorPrices)) {
        tes = as.data.frame(sectorPrices[[i]][1:(length(sectorPrices[[i]])-2)])
        tes = cbind(tes, econData[,-1])
        tes = tes[-nrow(tes),] # Usually a problem with most recent day's data, so remove it
        colnames(tes) = c(names(sectorPrices[[i]])[1:(length(sectorPrices[[i]])-2)],
                          colnames(econData[,-1]))
        # Convert to xts and remove market closures
        tes = as.xts(tes, order.by = as.Date(rownames(tes)))
        trainInterval <<- nrow(tes) - (252 * YEARS_IN_TEST)
        train = tes[1:trainInterval,]
        test = tes[(trainInterval+1):nrow(tes),]
        colnames(train) <- colnames(test) <- c("price",colnames(tes)[-1])

        # Clean column names
        newColNames <- NULL
        for (k in colnames(train)) {
          s <- strsplit(k,split = " ")[[1]]
          s2 <- NULL
          for (j in s) {
            s2 <- c(s2,strsplit(j,split = "/")[[1]])
          }
          newColName <- s2[1]
          if (length(s2) > 1) {
            for (j in s2[2:length(s2)]) {
              newColName <- paste(newColName,j,sep = "")
            }
          }
          newColNames <- c(newColNames,newColName)
        }
        colnames(test) <- colnames(train) <- newColNames
        sectorPrices[[i]][["Training Set"]] <<- train
        sectorPrices[[i]][["Testing Set"]] <<- test
      }
    }
    trainTestSplitting()

    print("Loading Data: Done!")
  }
)

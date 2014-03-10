# Introduction

This script started off as a copy of [Hard drive occupation prediction with R
- part 2](http://lpenz.github.com/articles/df0pred-2/index.html).  It
describes a way of using the [Monte Carlo
method](http://en.wikipedia.org/wiki/Monte_Carlo_method) to estimate when a
disk is going to run out of space.

I have taken the method, and added a few enhancements:

* Multiple server support
* Multiple volume support
* Use total disk usage from captured statistics

# Todo

* Glob files
* Read all data into one big dataset?
* Slice dataset for running simulation
* Output data into another dataset?
* change to chron objects?

# Overview

We process using the following logic:

* Iterate over each file in ~/Data
* Read file into dataset
* Fixup data
* Run Monte Carlo simulation for each path

# Load data sets

    list.files("~/Data", "\\.df")
    Sys.glob("~/Data/*.df")

First, we load the data sets.  We just assume all files matching `~/Data/*.df` should be processed.

*Note*: The base of the filename is the name of the host.

	# duinfo <- read.table('~/Data/198.17.207.3.df', colClasses=c("character", "numeric", "numeric", "character"), col.names=c("day", "usd", "total", "path"))
	duinfo <- read.table('~/Data/hephaestus.df', colClasses=c("character", "numeric", "numeric", "character"), col.names=c("day", "usd", "total", "path"))
	duinfo$day <- as.POSIXct(duinfo$day, tz="UTC", format="%Y-%m-%dT%H:%M")
	duinfo$path <- as.factor(duinfo$path)
	# duinfo$day <- as.Date(duinfo$day)
	# attach(duinfo)
	# totalspace <- 449218752

	# subsets data:
	# subset <- duinfo[which(duinfo$path == "/"),]
	data <- subset(duinfo, path == "/")
	attach(data)

	totalspace <- head(total, 1)

	# Linear model; http://lpenz.github.com/articles/df0pred-1/index.html
	# model <- lm(usd ~ day)
	# model2 <- lm(day ~ usd)
	# as.Date(predict(model2, data.frame(usd = totalspace)), origin="1970-01-01")

# Monte Carlo method

	today <- tail(day, 1)
	dudelta <- diff(usd)

	f <- function(spaceleft) {
	      days <- 0
	      while(spaceleft > 0) {
	      	  # If we're using dates, number should be 1.  If date time, need to use number of seconds in a day!
	          days <- days + 86400
	          spaceleft <- spaceleft - sample(dudelta, 1, replace=TRUE)
	      }
	      days
	  }
	  
	freespace <- totalspace - tail(usd, 1)
	daysleft <- replicate(5000, f(freespace))

	df0day <- sort(daysleft + today)
	df0ecdfunc <- ecdf(df0day)
	df0prob <- df0ecdfunc(df0day)

# Output results

We want to output CSV with the columns: server,volume,total,used,dateExhaustion,timeExhaustion (in hrs)

	# deprecate split=TRUE when done testing...
	# sink("output.txt", split=TRUE)

	# png("output.png")

	# Probability above 5%
	df0day[which(df0prob > 0.05)[1]]

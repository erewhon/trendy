# trendy_file <- function(iterations=5000, probThreshold=0.05, file, sampleIncrement=86400, debug=FALSE) {

# }

trendy <- function(iterations=5000, probThreshold=0.05, files='~/Data/*.df', sampleIncrement=86400, debug=FALSE) {
	# We set a cutoff time <strike>a year</strike> 1 month out
	far_future <- 86400 * 30
	# far_future <- 365

	for (file in Sys.glob(files)) {
		# Read in the file
		# print(file)
		duinfo <- read.table(file, colClasses=c("character", "numeric", "numeric", "character"), col.names=c("day", "usd", "ttl", "path"))

	    filename <- tail(unlist(strsplit(file, "/")), 1)
	    host <- sub('.df', '', filename)

		# Fix dates and paths
		duinfo$day <- as.POSIXct(duinfo$day, tz="UTC", format="%Y-%m-%dT%H:%M")
		# duinfo$day <- as.Date(duinfo$day)
		duinfo$path <- as.factor(duinfo$path)

		for (vol in levels(duinfo$path)) {
			data <- subset(duinfo, path == vol)

			# print(data)
			with(data, {
				totalspace <- head(ttl, 1)

				# Linear model
				model <- lm(day ~ usd)
				linear_threshold <- as.POSIXct(predict(model, data.frame(usd = totalspace)), origin="1970-01-01")

				# Monte Carlo method
				today <- tail(day, 1)
				dudelta <- diff(usd)

				# print(dudelta)
				f <- function(spaceleft) {
					days <- 0
					while(spaceleft > 0 & days < far_future) {
						# If we're using dates, number should be 1.  If date time,
						# need to use number of seconds in day, or at least something
						# much more than 1!
						days <- days + sampleIncrement
						spaceleft <- spaceleft - sample(dudelta, 1, replace=TRUE)

						if (days > far_future) days <- far_future
					}
					days
				}

				last_usd <- tail(usd, 1)
				freespace <- totalspace - last_usd
				daysleft <- replicate(iterations, f(freespace))

				# xxx : We should patch up data.  If date > far_future, then just say "way out" or something...
				df0day <- sort(daysleft + today)
				df0ecdfunc <- ecdf(df0day)

				df0prob <- df0ecdfunc(df0day)

				threshold_date <- df0day[which(df0prob > probThreshold)[1]]
				diff <- format(difftime(threshold_date, Sys.time(), units='hours'))

				cat(host, vol, totalspace, last_usd, format(threshold_date), diff, format(linear_threshold), sep=', ')
				cat('\n')

				# print(df0day[which(df0prob > probThreshold)[1]])
				if (debug) {
					print(threshold_date)
					cat('\n')
				}
			})
		}
	}
}

# trendy(iterations=1000, probThreshold=0.1, sampleIncrement=3600*8)
trendy(iterations=250, probThreshold=0.1, sampleIncrement=3600)

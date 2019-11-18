lastUpdated <- function(x) {
	myKey <- "yourKey"
	theURL <- httr::GET("https://api.clarivate.com/api/incites/InCitesLastUpdated/json", httr::add_headers("X-ApiKey" = myKey))
	httr::stop_for_status(theURL)
	theData <- httr::content(theURL, as = "text")
	theData <- jsonlite::fromJSON(theData)
	theDate <- theData$api$rval[[1]]
	return(theDate)
}

orgPubCount <- function(startYear) {
	myKey <- "yourKey"
	theURL <- httr::GET("https://api.clarivate.com/api/incites/DocumentLevelMetricsByInstitutionIdRecordCount/json", httr::add_headers("X-ApiKey" = myKey), query = list(year = startYear))
	httr::stop_for_status(theURL)
	theData <- httr::content(theURL, as = "text")
	theData <- jsonlite::fromJSON(theData)
	resultCount <- as.numeric(theData$api$rval)
	return(resultCount)
}

orgMetrics <- function(startYear, esci = "y", numrecs = 100, startRec = 1, retMax = Inf, outfile) {
	myKey <- "yourKey"
	theURL <- httr::GET("https://api.clarivate.com/api/incites/DocumentLevelMetricsByInstitutionIdRecordCount/json", httr::add_headers("X-ApiKey" = myKey), query = list(year = startYear))
	if (httr::http_error(theURL) == TRUE) { 
		print("Encountered an HTTP error. Details follow.") 
		print(httr::http_status(theURL)) 
		break
	}
	theData <- httr::content(theURL, as = "text")
	theData <- jsonlite::fromJSON(theData)
	resultCount <- as.numeric(theData$api$rval)
	print(paste("Retrieving", resultCount, "records."))
	retrievedCount <- 0
	theData <- ""
	## loop to request metrics
	while (retrievedCount < resultCount && retrievedCount < retMax) {
		theURL <- httr::GET("https://api.clarivate.com/api/incites/DocumentLevelMetricsByInstitutionId/xml", httr::add_headers("X-ApiKey" = myKey), query = list(year = startYear, esci = esci, recordcount = numrecs, startingrecord = startRec))
		if (httr::http_error(theURL) == TRUE) { 
			print("Encountered an HTTP error. Details follow.") 
			print(httr::http_status(theURL)) 
			break
		}
		theData <- paste(theData, httr::content(theURL, as = "text"), sep = "\n")
		retrievedCount <- retrievedCount + numrecs
		startRec <- startRec + numrecs
		print(paste("Retrieved", retrievedCount, "of", resultCount, "records. Getting more."))
		Sys.sleep(2)
	}
	print(paste("Retrieved", retrievedCount, "records. Formatting and saving results."))
	theData <- gsub("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>", "", theData, fixed = TRUE)
	theData <- gsub("<response xmlns=\"http://www.isinet.com/xrpc42\">", "", theData, fixed = TRUE)
	theData <- gsub("<fn name=\"IncitesWebServices.getDocumentLevelMetricsByInstitutionId\" rc=\"OK\">", "", theData, fixed = TRUE)
	theData <- gsub("<list>", "", theData, fixed = TRUE)
	theData <- gsub("</list>", "", theData, fixed = TRUE)
	theData <- gsub("</fn>", "", theData, fixed = TRUE)
	theData <- gsub("</response>", "", theData, fixed = TRUE)
	theData <- paste("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>", "<response xmlns=\"http://www.isinet.com/xrpc42\">", theData, "</response>", sep = "\n")
	writeLines(theData, con = outfile)
	print("Done.")
	return(theData)
}

searchByUT <- function(utList, esci = "y", outfile) {
	myKey <- "yourKey"
	theIDs <- unique(as.character(utList))
	resultCount <- as.numeric(length(theIDs))
	idList <- split(theIDs, ceiling(seq_along(theIDs)/100))
	idList <- gsub("WOS:", "", lapply(idList, paste0, collapse = ","))
	print(paste("Retrieving", resultCount, "records."))
	theData <- " "
	retrievedCount <- 0
	for (i in 1:length(idList)) {
		string <- idList[i]
		theURL <- httr::GET("https://api.clarivate.com/api/incites/DocumentLevelMetricsByUT/xml", httr::add_headers("X-ApiKey" = myKey), query = list(UT = string, esci = esci))
		if (httr::http_error(theURL) == TRUE) { 
			print("Encountered an HTTP error. Details follow.") 
			print(httr::http_status(theURL)) 
			break
		}
	theData <- paste(theData, httr::content(theURL, as = "text"))
	Sys.sleep(2)
	retrievedCount <- retrievedCount + 100
	print(paste("Retrieved", retrievedCount, "of", resultCount, "records. Getting more."))
	}
	print(paste("Retrieved", retrievedCount, "records. Formatting results."))
	writeLines(theData, outfile, useBytes = TRUE)
	theData <- readChar(outfile, file.info(outfile)$size)
	theData <- gsub("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>", "", theData, fixed = TRUE)
	theData <- gsub("<response xmlns=\"http://www.isinet.com/xrpc42\">", "", theData, fixed = TRUE)
	theData <- gsub("<fn name=\"IncitesWebServices.getDocumentLevelMetrics\" rc=\"OK\">", "", theData, fixed = TRUE)
	theData <- gsub("<list>", "", theData, fixed = TRUE)
	theData <- gsub("</list>", "", theData, fixed = TRUE)
	theData <- gsub("</fn>", "", theData, fixed = TRUE)
	theData <- gsub("</response>", "", theData, fixed = TRUE)
	theData <- paste("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>", "<response xmlns=\"http://www.isinet.com/xrpc42\">", theData, "</response>", sep = "\n")
	writeLines(theData, outfile, sep = " ")
	print("Done")
	return(theData)
}

extractXML <- function(theXML) {
	pxml <- XML::xmlTreeParse(theXML, useInternalNodes = TRUE)
	xroot <- XML::xmlRoot(pxml)
	cxml <- XML::xmlParse(theXML)
	records <- XML::getNodeSet(cxml, "//ISI:map", namespaces = "ISI")
	ut <- XML::xpathSApply(xroot, "//*[@name='ISI_LOC']", XML::xmlValue)
	ut <- as.vector(sapply("WOS:", paste0, ut))
	pubtype <- XML::xpathSApply(xroot, "//*[@name='ARTICLE_TYPE']", XML::xmlValue)
	cites <- lapply(records, XML::xpathSApply, "./*[@name='TOT_CITES']", XML::xmlValue)
	cites[sapply(cites, is.list)] <- NA
	cites <- as.numeric(unlist(cites))
	journalexpectedcites <- lapply(records, XML::xpathSApply, "./*[@name='JOURNAL_EXPECTED_CITATIONS']", XML::xmlValue)
	journalexpectedcites[sapply(journalexpectedcites, is.list)] <- NA
	journalexpectedcites <- as.numeric(unlist(journalexpectedcites))
	journalnormciteimpact <- lapply(records, XML::xpathSApply, "./*[@name='JOURNAL_ACT_EXP_CITATIONS']", XML::xmlValue)
	journalnormciteimpact[sapply(journalnormciteimpact, is.list)] <- NA
	journalnormciteimpact <- as.numeric(unlist(journalnormciteimpact))
	impactfactor <- lapply(records, XML::xpathSApply, "./*[@name='IMPACT_FACTOR']", XML::xmlValue)
	impactfactor[sapply(impactfactor, is.list)] <- NA
	impactfactor <- as.numeric(unlist(impactfactor))
	avgfieldexprate <- lapply(records, XML::xpathSApply, "./*[@name='AVG_EXPECTED_RATE']", XML::xmlValue)
	avgfieldexprate[sapply(avgfieldexprate, is.list)] <- NA
	avgfieldexprate <- as.numeric(unlist(avgfieldexprate))
	percentile <- lapply(records, XML::xpathSApply, "./*[@name='PERCENTILE']", XML::xmlValue)
	percentile[sapply(percentile, is.list)] <- NA
	percentile <- as.numeric(unlist(percentile))
	fieldnormciteimpact <- lapply(records, XML::xpathSApply, "./*[@name='NCI']", XML::xmlValue)
	fieldnormciteimpact[sapply(fieldnormciteimpact, is.list)] <- NA
	fieldnormciteimpact <- as.numeric(unlist(fieldnormciteimpact))
	isesimostcited <- as.numeric(XML::xpathSApply(xroot, "//*[@name='ESI_MOST_CITED_ARTICLE']", XML::xmlValue))
	ishotpaper <- as.numeric(XML::xpathSApply(xroot, "//*[@name='HOT_PAPER']", XML::xmlValue))
	isinternationalcollab <- as.numeric(XML::xpathSApply(xroot, "//*[@name='IS_INTERNATIONAL_COLLAB']", XML::xmlValue))
	isinstitutioncollab <- as.numeric(XML::xpathSApply(xroot, "//*[@name='IS_INSTITUTION_COLLAB']", XML::xmlValue))
	isindustrycollab <- as.numeric(XML::xpathSApply(xroot, "//*[@name='IS_INDUSTRY_COLLAB']", XML::xmlValue))
	oaflag <- as.numeric(XML::xpathSApply(xroot, "//*[@name='OA_FLAG']", XML::xmlValue))
	theDF <- data.frame(ut, pubtype, cites, impactfactor, journalexpectedcites, journalnormciteimpact, avgfieldexprate, fieldnormciteimpact, percentile, isesimostcited, ishotpaper, isinternationalcollab, isinstitutioncollab, isindustrycollab, oaflag, stringsAsFactors = FALSE)
	return(theDF)
}
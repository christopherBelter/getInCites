# getInCites

R functions for working with the InCites API

## About getInCites

getInCites is a set of R functions for working with the InCites API. It allows you to programmatically obtain advanced citation indicators from InCites for a range of publication sets. The InCites APIs allow you to obtain metrics in two ways. The first way is to obtain citation metrics for publications from your institution from a prespecified year to the present. The second way is to obtain metrics for a custom set of publications identified by their Web of Science (WOS) accession, or UT, number. 

getInCites has five functions for requesting data in these different ways. The orgPubCount() and orgMetrics() functions allow you to identify and obtain metrics for your institution. The searchByUT() function allows you obtain metrics for a custom set of publications. The extractXML() function extracts the XML data returned by either method into a data frame in R. Finally, the lastUpdated() function allows you to check when the InCites database was last updated. 

To use these functions, your institution must subscribe to InCites and you must request an API key from the Clarivate Analytics developer portal (https://developer.clarivate.com/). Once you obtain your API key, paste it into the getInCites.r file in each of the request functions so that it is sent along with your request. The API key should replace the "yourKey" text in lines 2, 12, 22, and 64 of the getInCites.r file. 

These functions also require the following R packages be installed: httr, jsonlite, and XML.

Note that these functions are designed to work with version 1.0 of the InCites API. Clarivate Analytics recently launched version 2.0 of the API, which adds some data to the response. Updated functions to work with the new version are forthcoming. 

To use the functions, save the getInCites.r file to your computer and load it into your R session using source(). 

    source("getInCites.r")

## Requesting organization metrics

In some situations, you want to obtain metrics for publications by authors from your own institution over a certain range of years. Depending on the size of your institution and the range of years that you want metrics for, this could result in tens of thousands of publications. The orgPubCount() allows you to check how many publications you might be dealing with for a certain range of years. The function has a single argument, "startYear", which specifies that you want publications from your institution from the "startYear" through the present. So, setting it to "2017" means you want publications from 2017 through the present. Your institution is automatically determined by the API based on the institution that is tied to your API key. 

To check how many publications might be returned, run the orgPubCount() function 

    orgPubCount("2017")

and R will print the number of results returned. 

To actually request metrics for this set of publications, run the orgMetrics() function with the same "startYear" argument.

    myXML <- orgMetrics("2017", outfile = "org_metrics_from2017.xml")

The function will download the results in batches of 100 until it either reaches the total number of results or the number of results specified in the "retMax" argument. If no "retMax" value is specified, the function will download all available results. The function will also save the resulting XML file to your computer using the file name specified in the "outfile" argument.

The optional "esci" argument indicates whether you want citations from the Emerging Sources Citation Index to be included in the metrics you obtain. The argument defaults to "y", meaning that ESCI citations should be included, but you can set it to "n" to exclude them.

The "numrecs" and "startRec" arguments allow you to modify the download process. The "numrecs" argument allows you to specify how many publications to request at a time. This cannot be set any higher than the current default of 100, because that is the limit imposed by the API server itself. The "startRec" argument allows you to specify which search result to start downloading from. This may be useful if you need to download the results in larger batches or if the download process was interrupted before finishing. In most cases, however, you should use the default values for both arguments.

When the download process is complete, the function will return the final XML file as a character vector in R. To extract the XML data into a data frame, feed this character vector into the extractXML() function.

    myDF <- extractXML(myXML)

You can then work with the data frame in R, merge it with any WOS data you might already have for these publications using the "ut" column as a matching key, or write it to a .csv file using the write.csv() function. 

To check when the InCites database was last updated, and therefore the date as of which the retrieved metrics are accurate, simply run the lastUpdated() function without any arguments

    lastUpdated()

and the function will print out the relevant dates.

## Requesting metrics for a custom data set

In other situations, you want to request metrics for a known set of publications (i.e. publications by a specific author, laboratory, or funding portfolio). The InCites API currently only allows you to search for custom publications by their WOS accession number, or UT, so you will need to already have a list of the UT numbers that you want metrics for. This list can be obtained by searching the WOS web interface or the WOS API for the publications you want. I have developed a set of functions to work with the new REST-based WOS API in R and a separate GitHub repo for those functions is forthcoming. 

In either case, the searchByUT() function expects a vector of UT numbers as it’s primary input, so you can either read in a text file of UT numbers using scan()

    uts <- scan("myUTs.txt", what = "varchar", sep = "\n")

or create the vector from a column in a data frame.

    uts <- myDF$UT

To request metrics for this list of UTs, feed this vector into the searchByUT() function and specify a file to which the resulting XML will be saved. 

    myXML <- searchByUT(uts, outfile = "inCitesXML.xml")

The optional "esci" argument indicates whether you want citations from the Emerging Sources Citation Index to be included in the metrics you obtain. The argument defaults to "y", meaning that ESCI citations should be included, but you can set it to "n" to exclude them. 

The function will break the vector of UTs into batches of 100, loop through the batches to request metrics for all of the publications in the vector, combine the results into a single XML file, write that file out to your computer using the filename specified in the "outfile" argument, and return the XML as a character vector in R. 

To extract the XML into a data frame, feed this XML file into the extractXML() function, as above. 

    theDF <- extractXML(myXML)

You can then work with the data frame in R, merge it with any WOS data you might already have for these publications using the "ut" column as a matching key, or write it to a .csv file using the write.csv() function. 

To check when the InCites database was last updated, and therefore the date as of which the retrieved metrics are accurate, simply run the lastUpdated() function as above.

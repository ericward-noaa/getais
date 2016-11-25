#' Returns null, just processes data from web
#'
#' @param df The data frame consisting of the combinations of zones, years, months to process
#' @param hours The time stamp(s) that the algorithm finds the closest points to (e.g. 6, 12, 18)
#'
#' @return NULL
#' @export NULL
#'
#' @examples
process_ais = function(df, hours = c(12)) {

# loop through files to process
for(i in 1:nrow(df)) {
  # if processed file doesn't exist, download
  if(!file.exists(paste0("filtered/",df$zone[i],"_",df$year[i],"_",df$month[i],".csv"))) {

    charMonth = ifelse(df$month[i] < 10, paste0(0, df$month[i]), paste0(df$month[i]))
    month = c("January","February","March","April","May","June","July","August","September","October","November","December")
    # the directory structure changes by year, which is frustrating

    if(df$year[i] == 2009) {
      url = paste0("https://coast.noaa.gov/htdata/CMSP/AISDataHandler/AIS_FGDBs/Zone",df$zone[i],"/Zone",df$zone[i],"_",df$year[i],"_",charMonth,".zip")
      download.file(url, destfile = "temp.zip", quiet=TRUE)
      unzip("temp.zip")
      d = readOGR(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"),"Broadcast")
    }
    if(df$year[i] == 2010) {
      url = paste0("https://coast.noaa.gov/htdata/CMSP/AISDataHandler/",df$year[i],"/",df$month[i],"_",month[df$month[i]],"_",df$year[i],"/Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".zip")
      download.file(url, destfile = "temp.zip", quiet=TRUE)
      unzip("temp.zip")
      d = readOGR(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"),"Broadcast")
    }
    if(df$year[i] == 2011) {
      url = paste0("https://coast.noaa.gov/htdata/CMSP/AISDataHandler/",df$year[i],"/",df$month[i],"/Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb.zip")
      download.file(url, destfile = "temp.zip", quiet=TRUE)
      unzip("temp.zip")
      d = readOGR(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"),"Broadcast")
    }
    if(df$year[i] == 2011) {
      url = paste0("https://coast.noaa.gov/htdata/CMSP/AISDataHandler/",df$year[i],"/",df$month[i],"/Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb.zip")
      download.file(url, destfile = "temp.zip", quiet=TRUE)
      unzip("temp.zip")
      d = readOGR(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"),"Broadcast")
    }
    if(df$year[i] %in% c(2011,2012,2013)) {
      url = paste0("https://coast.noaa.gov/htdata/CMSP/AISDataHandler/",df$year[i],"/",df$month[i],"/Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb.zip")
      download.file(url, destfile = "temp.zip", quiet=TRUE)
      unzip("temp.zip")
      if(df$year[i] %in% c(2011,2012)) d = readOGR(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"),"Broadcast")
      if(df$year[i] == 2013) d = readOGR(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"),paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],"_Broadcast"))
    }
    if(df$year[i] == 2014) {
      url = paste0("https://coast.noaa.gov/htdata/CMSP/AISDataHandler/",df$year[i],"/",df$month[i],"/Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".zip")
      download.file(url, destfile = "temp.zip", quiet=TRUE)
      unzip("temp.zip")
      d = readOGR(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"),paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],"_Broadcast"))
    }
    unlink("temp.zip")

    #d$month = month(d$BaseDateTime)
    dat = as.data.frame(d)
    dat$BaseDateTime = as_datetime(as.POSIXlt(as.character(dat$BaseDateTime)))
    dat$monthday = paste0(month(dat$BaseDateTime), "-", day(dat$BaseDateTime))
    dat$keep = 0

    # loop over times entered, flag records that are closest on each vessel-day
    for(j in 1:length(hours)) {
      # extract mdy
      d = dat
      mdy = unlist(lapply(strsplit(as.character(d$BaseDateTime), " "), getElement, 1))
      # update hour
      d$target = update(as.POSIXlt(mdy, tz="UTC"), hours = hours[j])
      d$timediff = abs(d$BaseDateTime - d$target)
      d$BaseDateTime = as.character(d$BaseDateTime) # needed to keep dplyr from throwing error
      d$target = as.character(d$target) # needed to keep dplyr from throwing error
      # for each day / vessel, find the records that
      g = group_by(d, monthday, MMSI) %>%
        mutate(k = ifelse(timediff == min(timediff), 1, 0))
      dat$keep = dat$keep + g$k
    }

    indx = which(dat$keep > 0)
    if(length(indx) > 0) {
      dat = dat[indx,]
      # write this to csv file
      write.table(dat, paste0("filtered/Zone",df$zone[i],"_",df$month[i],"_",df$year[i],".csv"), row.names=F, col.names=T)
    }
    # trash the temp directory that was created
    unlink(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"), recursive=TRUE)

  }

}


}

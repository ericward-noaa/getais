#' Returns null, just processes data from web
#'
#' @param df The data frame consisting of the combinations of zones, years, months to process
#' @param every_minutes How often algorithm finds the closest points to (e.g. 10 minute, 30 minute, etc)
#' @param status_codes_to_keep Status codes to retain for downsampling. List here: https://help.marinetraffic.com/hc/en-us/articles/203990998-What-is-the-significance-of-the-AIS-Navigational-Status-Values-
#'
#' @return NULL
#' @export NULL
#'
#' @examples
downsample_ais = function(df, every_minutes = 10, status_codes_to_keep = c(0, 7, 8, 9, 10, 11, 12, 13, 14, 15)) {

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
      d = readOGR(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"),"Broadcast", verbose=FALSE)
    }
    if(df$year[i] == 2011) {
      url = paste0("https://coast.noaa.gov/htdata/CMSP/AISDataHandler/",df$year[i],"/",df$month[i],"/Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb.zip")
      download.file(url, destfile = "temp.zip", quiet=TRUE)
      unzip("temp.zip")
      d = readOGR(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"),"Broadcast", verbose=FALSE)
    }
    if(df$year[i] == 2011) {
      url = paste0("https://coast.noaa.gov/htdata/CMSP/AISDataHandler/",df$year[i],"/",df$month[i],"/Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb.zip")
      download.file(url, destfile = "temp.zip", quiet=TRUE)
      unzip("temp.zip")
      d = readOGR(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"),"Broadcast", verbose=FALSE)
    }
    if(df$year[i] %in% c(2011,2012,2013)) {
      url = paste0("https://coast.noaa.gov/htdata/CMSP/AISDataHandler/",df$year[i],"/",df$month[i],"/Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb.zip")
      download.file(url, destfile = "temp.zip", quiet=TRUE)
      unzip("temp.zip")
      if(df$year[i] %in% c(2011,2012)) d = readOGR(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"),"Broadcast", verbose=FALSE)
      if(df$year[i] == 2013) d = readOGR(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"),paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],"_Broadcast"), verbose=FALSE)
    }
    if(df$year[i] == 2014) {
      url = paste0("https://coast.noaa.gov/htdata/CMSP/AISDataHandler/",df$year[i],"/",df$month[i],"/Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".zip")
      download.file(url, destfile = "temp.zip", quiet=TRUE)
      unzip("temp.zip")
      d = readOGR(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"),paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],"_Broadcast"), verbose=FALSE)
    }
    unlink("temp.zip")

    # filter out status codes
    dat = as.data.frame(d)
    dat = filter(dat, Status %in% status_codes_to_keep)

    dat$BaseDateTime = as_datetime(as.POSIXlt(as.character(dat$BaseDateTime)))
    dat$keep = 0

    dat$BaseDateTime_round = round_date(dat$BaseDateTime, "minute")

    dat$minutes = minute(dat$BaseDateTime_round) + second(dat$BaseDateTime)/60
    seq_min = seq(0, 60, by = every_minutes)
    seq_min[1] = -1 # catch against 00:00:00 throwing error
    dat$time_chunk = as.numeric(cut(dat$minutes, seq_min))
    dat$diff_1 = abs(dat$minutes - seq_min[dat$time_chunk])
    dat$diff_2 = abs(dat$minutes - seq_min[dat$time_chunk+1])
    dat$time_1 = ifelse(dat$diff_1 < dat$diff_2, 1, 0)
    dat$min_timediff = dat$diff_1 * dat$time_1 + (1-dat$time_1)*dat$diff_2
    dat$interval = dat$time_chunk * dat$time_1 + (1-dat$time_1)* (dat$time_chunk+1)
    dat = select(dat, -BaseDateTime_round, -minutes, -time_chunk, -diff_1, -diff_2, -time_1)

    # create interval: month: day to group_by on
    dat$chunk = paste0(month(dat$BaseDateTime),":",day(dat$BaseDateTime),":",dat$interval)
    dat$BaseDateTime = as.character(dat$BaseDateTime) # needed to keep dplyr from throwing error

    dat = group_by(dat, MMSI, chunk) %>%
      mutate(mintime = ifelse(min_timediff == min(min_timediff), 1, 0)) %>%
      filter(mintime == 1) %>%
      select(-mintime, -chunk)

    if(nrow(dat) > 0) {
      # write this to csv file
      write.table(dat, paste0("filtered/Zone",df$zone[i],"_",df$month[i],"_",df$year[i],".csv"), row.names=F, col.names=T)
    }
    # trash the temp directory that was created
    unlink(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"), recursive=TRUE)
  }

}


}

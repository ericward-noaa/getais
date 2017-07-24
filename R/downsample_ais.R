#' Returns null, just processes data from web
#'
#' @param df The data frame consisting of the combinations of zones, years, months to process
#' @param every_minutes How often algorithm finds the closest points to (e.g. 10 minute, 30 minute, etc)
#' @param status_codes_to_keep Status codes to retain for downsampling. List here: https://help.marinetraffic.com/hc/en-us/articles/203990998-What-is-the-significance-of-the-AIS-Navigational-Status-Values-
#' @param SOG_threshold threshold to to delete values less than this (corresponding to little or no movement)
#' @param vessel_attr The attributes from the vessel table to join in
#' @param voyage_attr The attributes from the voyage table to join in
#' @param raw If true, no filtering based on time applied. Defaults to FALSE.
#'
#' @return NULL
#' @export NULL
#'
#' @examples
downsample_ais = function(df, every_minutes = 10, status_codes_to_keep = c(0, 7, 8, 9, 10, 11, 12, 13, 14, 15), SOG_threshold = 1, vessel_attr = c("VesselType","Length"), voyage_attr = c("Destination"), raw = FALSE) {

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
      char_month = ifelse(df$month[i] < 10, paste0("0",df$month[i]), paste0(df$month[i]))

      fname = paste0("Zone",df$zone[i],"_",df$year[i],"_",char_month,".gdb")
      dat = readOGR(fname,"Broadcast")

      # process the tables to extract vessel and voyage
      if(.Platform$OS.type != "windows") {
        system(paste0("ogr2ogr -f CSV Vessel.csv ",fname," Vessel"))
        system(paste0("ogr2ogr -f CSV Voyage.csv ",fname," Voyage"))
      }
      else {
        shell(paste0("ogr2ogr -f CSV Vessel.csv ",fname," Vessel"))
        shell(paste0("ogr2ogr -f CSV Voyage.csv ",fname," Voyage"))
      }
      vessel = read.csv("Vessel.csv", stringsAsFactors = FALSE)
      voyage = read.csv("Voyage.csv", stringsAsFactors = FALSE)
    }
    if(df$year[i] == 2010) {
      char_month = ifelse(df$month[i] < 10, paste0("0",df$month[i]), paste0(df$month[i]))

      url = paste0("https://coast.noaa.gov/htdata/CMSP/AISDataHandler/",df$year[i],"/",char_month,"_",month[df$month[i]],"_",df$year[i],"/Zone",df$zone[i],"_",df$year[i],"_",char_month,".zip")
      download.file(url, destfile = "temp.zip", quiet=TRUE)
      unzip("temp.zip")
      fname = paste0("Zone",df$zone[i],"_",df$year[i],"_",char_month,".gdb")
      dat = readOGR(fname,"Broadcast", verbose=FALSE)

      # process the tables to extract vessel and voyage
      if(.Platform$OS.type != "windows") {
        system(paste0("ogr2ogr -f CSV Vessel.csv ",fname," Vessel"))
        system(paste0("ogr2ogr -f CSV Voyage.csv ",fname," Voyage"))
      }
      else {
        shell(paste0("ogr2ogr -f CSV Vessel.csv ",fname," Vessel"))
        shell(paste0("ogr2ogr -f CSV Voyage.csv ",fname," Voyage"))
      }
      vessel = read.csv("Vessel.csv", stringsAsFactors = FALSE)
      voyage = read.csv("Voyage.csv", stringsAsFactors = FALSE)
    }
    if(df$year[i] %in% c(2011,2012,2013)) {
      char_month = ifelse(df$month[i] < 10, paste0("0",df$month[i]), paste0(df$month[i]))
      url = paste0("https://coast.noaa.gov/htdata/CMSP/AISDataHandler/",df$year[i],"/",char_month,"/Zone",df$zone[i],"_",df$year[i],"_",char_month,".gdb.zip")
      download.file(url, destfile = "temp.zip", quiet=TRUE)
      unzip("temp.zip")
      fname = paste0("Zone",df$zone[i],"_",df$year[i],"_",char_month,".gdb")
      if(df$year[i] %in% c(2011,2012)) {
        dat = readOGR(fname,"Broadcast", verbose=FALSE)
        # process the tables to extract vessel and voyage
        if(.Platform$OS.type != "windows") {
          system(paste0("ogr2ogr -f CSV Vessel.csv ",fname," Vessel"))
          system(paste0("ogr2ogr -f CSV Voyage.csv ",fname," Voyage"))
        }
        else {
          shell(paste0("ogr2ogr -f CSV Vessel.csv ",fname," Vessel"))
          shell(paste0("ogr2ogr -f CSV Voyage.csv ",fname," Voyage"))
        }
        vessel = read.csv("Vessel.csv", stringsAsFactors = FALSE)
        voyage = read.csv("Voyage.csv", stringsAsFactors = FALSE)
      }
      if(df$year[i] == 2013) {
        dat = readOGR(fname,paste0("Zone",df$zone[i],"_",df$year[i],"_",char_month,"_Broadcast"), verbose=FALSE)
        # process the tables to extract vessel and voyage
        layername = paste0("Zone",df$zone[i],"_",df$year[i],"_",char_month)

        if(.Platform$OS.type != "windows") {
        system(paste0("ogr2ogr -f CSV Vessel.csv ",fname," ",layername,"_Vessel"))
        system(paste0("ogr2ogr -f CSV Voyage.csv ",fname," ",layername,"_Voyage"))
        }
        else {
        shell(paste0("ogr2ogr -f CSV Vessel.csv ",fname," ",layername,"_Vessel"))
        shell(paste0("ogr2ogr -f CSV Voyage.csv ",fname," ",layername,"_Voyage"))
        }
        vessel = read.csv("Vessel.csv", stringsAsFactors = FALSE)
        voyage = read.csv("Voyage.csv", stringsAsFactors = FALSE)
      }
    }
    if(df$year[i] == 2014) {
      char_month = ifelse(df$month[i] < 10, paste0("0",df$month[i]), paste0(df$month[i]))
      url = paste0("https://coast.noaa.gov/htdata/CMSP/AISDataHandler/",df$year[i],"/",char_month,"/Zone",df$zone[i],"_",df$year[i],"_",char_month,".zip")
      download.file(url, destfile = "temp.zip", quiet=TRUE)
      unzip("temp.zip")
      fname = paste0("Zone",df$zone[i],"_",df$year[i],"_",char_month,".gdb")
      dat = readOGR(fname, paste0("Zone",df$zone[i],"_",df$year[i],"_",char_month,"_Broadcast"), verbose=FALSE)

      layername = paste0("Zone",df$zone[i],"_",df$year[i],"_",char_month)
      if(.Platform$OS.type != "windows") {
        system(paste0("ogr2ogr -f CSV Vessel.csv ",fname," ",layername,"_Vessel"))
        system(paste0("ogr2ogr -f CSV Voyage.csv ",fname," ",layername,"_Voyage"))
      }
      else {
        shell(paste0("ogr2ogr -f CSV Vessel.csv ",fname," ",layername,"_Vessel"))
        shell(paste0("ogr2ogr -f CSV Voyage.csv ",fname," ",layername,"_Voyage"))
      }
      vessel = read.csv("Vessel.csv", stringsAsFactors = FALSE)
      voyage = read.csv("Voyage.csv", stringsAsFactors = FALSE)
    }
    unlink("temp.zip")

    # filter out status codes
    #dat = filter(as.data.frame(dat), SOG >= SOG_threshold) %>%
    #  filter(Status %in% status_codes_to_keep) %>%
    #  left_join(vessel[,c("MMSI",vessel_attr)])
    dat = filter(as.data.frame(dat), SOG >= SOG_threshold) %>%
      filter(Status %in% status_codes_to_keep)

    dat[,c(vessel_attr)] = vessel[match(dat$MMSI, vessel$MMSI),c(vessel_attr)]

    unlink("Vessel.csv")

    # join in voyage destination -- this messes up dplyr because voyage data may be incomplete
    dat[,c(voyage_attr)] = voyage[match(dat$MMSI, voyage$MMSI),c(voyage_attr)]
    unlink("Voyage.csv")

    dat$BaseDateTime = as_datetime(as.POSIXlt(as.character(dat$BaseDateTime)))
    dat$keep = 0

    if(raw == FALSE) {
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
    dat$chunk = as.numeric(as.factor(paste0(month(dat$BaseDateTime),":",day(dat$BaseDateTime),":",dat$interval)))
    dat$BaseDateTime = as.character(dat$BaseDateTime) # needed to keep dplyr from throwing error

    dat = group_by(dat, MMSI, chunk) %>%
      mutate(mintime = ifelse(min_timediff == min(min_timediff), 1, 0)) %>%
      filter(mintime == 1) %>%
      ungroup %>%
      select(-mintime, -chunk, -keep)
    }

    if(nrow(dat) > 0) {
      # write this to csv file
      saveRDS(dat, paste0("filtered/Zone",df$zone[i],"_",df$month[i],"_",df$year[i],".rds"))
    }
    # trash the temp directory that was created
    unlink(paste0("Zone",df$zone[i],"_",df$year[i],"_",df$month[i],".gdb"), recursive=TRUE)
  }

}


}

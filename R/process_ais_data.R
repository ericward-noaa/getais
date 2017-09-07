#' Processes raw AIS data, creates cleaned data frame of hourly observations with speed calculations
#'
#' @param aisdata The data frame consisting of the combinations of zones, years, months to process
#' @param min_from_hr Window around the top of the hour used. Every vessel might not have a position recorded at exactly 12:00 for example, so the closest position +/- minutes_from_hour is used. Defaults to 7.5 (15 min window)
#' @param time_zone The time zone used in calculations (e.g. "GMT", "UTC")
#'
#' @return processed data frame
#' @import PBSmapping, fields, dplyr
#' @export
#' @examples
#' \dontrun{
#' df = data.frame("month"=1:4, "year" = 2009, "zone"=10)
#' downsample_ais(df, raw = TRUE) # gets raw data from marine cadastre
#'
#' d = readRDS("filtered/Zone10_01_2009.rds")
#' d_processed = process_ais_data(d, time_zone = "UTC")
#' }
process_ais_data = function(aisdata, min_from_hr = 7.5, time_zone = "GMT") {
  # The whale data should be in GMT, so we need to convert
  # the AIS data to GMT?

  aisdata$BaseDateTime = as.POSIXct(aisdata$BaseDateTime, tz = time_zone)

  aisdata = arrange(aisdata, MMSI, BaseDateTime) %>%
    group_by(MMSI) %>%
    mutate(diff_time = c(NA, diff(BaseDateTime)) / (60*60),
      lon_lag = c(coords.x1[-1],NA),
      lat_lag = c(coords.x2[-1],NA),
      diff_dist = rdist.earth.vec(cbind(coords.x1,coords.x2),
        cbind(lon_lag, lat_lag), miles=FALSE),
      speed_kmhr = diff_dist/diff_time)

  # remove minutes not within 7.5 min of hr.
  g = aisdata %>% ungroup %>%
    mutate(mint = minute(as_datetime(aisdata$BaseDateTime, tz=time_zone)),
      hourt = hour(as_datetime(aisdata$BaseDateTime, tz=time_zone)),
      dayt = day(as_datetime(aisdata$BaseDateTime, tz=time_zone)),
      montht = month(as_datetime(aisdata$BaseDateTime, tz=time_zone)),
      yeart = year(as_datetime(aisdata$BaseDateTime, tz=time_zone))) %>%
    filter(mint >= (60-min_from_hr) | mint < (min_from_hr)) %>%
    mutate(time_id = paste(yeart,montht,dayt,hourt, sep="-")) %>%
    select(-hourt, -dayt, -montht, -yeart) %>%
    group_by(MMSI, time_id) %>%
    mutate(speed_kmhr2 = sum(diff_dist, na.rm=T)/sum(diff_time, na.rm=T)) %>%
    select(-COG, -Heading, -ROT, -ReceiverType, -ReceiverID, -keep, -mint) %>%
    rename(X = coords.x1) %>%
    rename(Y = coords.x2) %>%
    filter(is.finite(speed_kmhr2)) %>%
    filter(is.finite(speed_kmhr)) %>%
    filter(!is.na(speed_kmhr2)) %>%
    filter(!is.na(speed_kmhr))

  # convert to km
  g$PID = 1
  g$POS = seq(1, nrow(g))
  attr(g, "zone") = 10
  attr(g, "projection") = "LL"
  g = convUL(g, km = TRUE)

  g = g %>%
    select(-PID, -POS)

  return(g)
}

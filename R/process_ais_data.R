library(lubridate)
library(dplyr)
library(PBSmapping)

process_ais_data = function(aisdata) {
  # The whale data should be in GMT, so we need to convert
  # the AIS data to GMT
  aisdata$BaseDateTime = as.POSIXct(aisdata$BaseDateTime)

  # remove minutes not within 5 min of hr
  g = aisdata %>%
    mutate(min = minute(as_datetime(aisdata$BaseDateTime, tz="GMT"))) %>%
    filter(min >= 55 | min < 5) %>%
    select(-COG, -Heading, -ROT, -ReceiverType, -ReceiverID, -keep, -min) %>%
    rename(X = coords.x1) %>%
    rename(Y = coords.x2)

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

d = readRDS("filtered/Zone10_12_2013.rds")
d = process_ais_data(d)
saveRDS(d, "filtered/Zone10_12_2013_processed.rds")

d = readRDS("filtered/Zone10_1_2014.rds")
d = process_ais_data(d)
saveRDS(d, "filtered/Zone10_1_2014_processed.rds")

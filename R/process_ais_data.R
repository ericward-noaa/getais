library(lubridate)
library(dplyr)
library(PBSmapping)
library(fields)

process_ais_data = function(aisdata) {
  # The whale data should be in GMT, so we need to convert
  # the AIS data to GMT
  aisdata$BaseDateTime = as.POSIXct(aisdata$BaseDateTime, tz="GMT")

  # remove minutes not within 5 min of hr
  g = aisdata %>% ungroup %>%
    mutate(mint = minute(as_datetime(aisdata$BaseDateTime, tz="GMT"))) %>%
    filter(mint >= 55 | mint < 5) %>%
    select(-COG, -Heading, -ROT, -ReceiverType, -ReceiverID, -keep, -mint) %>%
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

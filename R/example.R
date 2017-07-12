library(getais)
source("R/process_ais_data.r")

# first grab the data from marine cadastre,
subset = data.frame("zone"=10, "month"=c(1,4,7,10), "year"=2009:2014)
downsample_ais(df = subset, raw = TRUE)

# now the raw files are in the filtered folder

# Next we'll process the raw files - using Apr 2009 as an example:

d = readRDS("filtered/Zone10_4_2009.rds")

d$BaseDateTime = as.POSIXct(d$BaseDateTime)

d = arrange(d, MMSI, BaseDateTime) %>%
  group_by(MMSI) %>%
  mutate(diff_time = c(NA, diff(BaseDateTime)),
    lon_lag = c(coords.x1[-1],NA),
    lat_lag = c(coords.x2[-1],NA),
    diff_dist = rdist.earth.vec(cbind(coords.x1,coords.x2),
      cbind(lon_lag, lat_lag)),
    speed_kmhr = 60*diff_dist/diff_time) %>%
  select(-diff_time, -lon_lag, -lat_lag, -diff_dist)

d = process_ais_data(d)

# Smaller file saved
saveRDS(d, "filtered/Zone10_4_2009_processed.rds")

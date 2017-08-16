#' Returns a dataframe that includes date, Received Level(dB) and location of the whale
#'
#' @param whale The data frame include date(PST), position(UTM) of the whale
#' @param vessel The data frame include date(PST), position(UTM) of the vessel
#'
#' @return dataframe
#' @export


getRL = function(whale, vessel) {
  ## whale
  # separte Date
  whale$date = as.POSIXct(whale$date)
  whale$date = ymd_hms(whale$date)
  whale$year = year(whale$date)
  whale$month = month(whale$date)
  whale$day = day(whale$date)
  whale$hour = hour(whale$date)
  whale$minute = minute(whale$date)
  whale$sec = second(whale$date)

  # obs for every hour
  whale_hour = whale %>%
    group_by(year,month,day,hour) %>%
    filter(minute==min(minute))

  ## vessel
  # estimate to nearest hour
  vessel = vessel %>%
    mutate(minute = minute(BaseDateTime)) %>%
    filter(minute >= 55 | minute <=5) %>%
    mutate(hour = ifelse(minute < 10, hour(BaseDateTime), hour(BaseDateTime)+1))  %>%
    mutate(second = second(BaseDateTime))

  vessel$year = year(vessel$BaseDateTime)
  vessel$month = month(vessel$BaseDateTime)
  vessel$day = day(vessel$BaseDateTime)

  index=which(vessel$hour == 24)
  vessel$hour[index] = 0

  # find the obs that is closet to the whole hour if it is the same vessel
  vessel = vessel %>%
    group_by(year,month,day,hour,MMSI) %>%
    mutate(z = ifelse(minute>=55, 3600 - (minute*60+second), minute*60+second)) %>%
    filter(z == min(z))

  # combine two data frames, keep mutual observations
  # delete vessel which length = 0 or is NA
  # keep the vessels that inside +- 100 km of each whale's location
  data = whale_hour %>%
    left_join(vessel,by=c("year","month","day","hour")) %>%
    mutate(dis = sqrt((X - lon)^2+(Y-lat)^2)) %>%
    filter(dis <= 100) %>%
    filter(Length > 0)

  # find index(observation) which there is no land between the vessel and the whale
  index = acrossLand(df=data)

  ## only keep obs that does cross land
  data_remove_land = data[index,]


  # calculate the RL for every vessel
  RL_eachObs = data_remove_land %>%
    mutate(SL = ifelse(Length <=10,163.6, ifelse(10 <Length&Length<=25, 157.2,
                                                 ifelse(25 <Length&Length<=50, 176.4,
                                                        ifelse(50 <Length&Length<100, 181.1,190.8))))) %>%
    mutate(RL = SL-20*log10(dis*1000))

  # calculate the RL in every whale's location
  RL_eachLoc_sum =  RL_eachObs %>%
    group_by(year,month,day,hour) %>%
    summarise(n = n(),RL_total = 10*log10(sum(10^(RL/10)))) %>%
    left_join(whale_hour,by = c("year","month","day","hour")) %>% # want whale's lon and lat
    select(year,month,day,hour,n,RL_total,lon,lat)

  return(RL_eachLoc_sum)
}







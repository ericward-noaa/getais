#' Returns a dataframe that includes date, Received Level(dB) and location of the whale
#'
#' @param whale The data frame include date(PST), position(UTM) of the whale
#' @param vessel The data frame include date(PST), position(UTM) of the vessel
#' @param map The map around whale and vessel
#' @param depth The depth data include location (x,y) and depth (in meters)
#'
#' @importFrom dplyr group_by filter select mutate left_join summarise
#' @importFrom lubridate ymd_hms year month day hour minute second
#' @return dataframe
#' @export


getRL = function(whale, vessel, map, depth) {
  ## whale
  # separte Date
  whale$date = as.POSIXct(whale$date)
  whale$date = lubridate::ymd_hms(whale$date)
  whale$year = lubridate::year(whale$date)
  whale$month = lubridate::month(whale$date)
  whale$day = lubridate::day(whale$date)
  whale$hour = lubridate::hour(whale$date)
  whale$minute = lubridate::minute(whale$date)
  whale$sec = lubridate::second(whale$date)

  # obs for every hour
  whale_hour = whale %>%
    dplyr::group_by(year,month,day,hour) %>%
    dplyr::filter(minute==lubridate::min(minute)) %>%
    dplyr::select(-X)

  ## vessel
  # estimate to nearest hour
  vessel = vessel %>%
    dplyr::mutate(minute = lubridate::minute(BaseDateTime)) %>%
    dplyr::filter(minute >= 55 | minute <=5) %>%
    dplyr::mutate(hour = ifelse(minute < 10, hour(BaseDateTime), hour(BaseDateTime)+1))  %>%
    dplyr::mutate(second = lubridate::second(BaseDateTime))

  vessel$year = lubridate::year(vessel$BaseDateTime)
  vessel$month = lubridate::month(vessel$BaseDateTime)
  vessel$day = lubridate::day(vessel$BaseDateTime)

  index=which(vessel$hour == 24)
  vessel$hour[index] = 0

  # find the obs that is closet to the whole hour if it is the same vessel
  vessel = vessel %>%
    dplyr::group_by(year,month,day,hour,MMSI) %>%
    dplyr::mutate(z = ifelse(minute>=55, 3600 - (minute*60+second), minute*60+second)) %>%
    dplyr::filter(z == min(z))

  ## combine two data frames, keep mutual observations
  # delete vessel which length = 0 or is NA
  # keep the vessels that inside +- 100 km of each whale's location
  data = whale_hour %>%
    dplyr::left_join(vessel,by=c("year","month","day","hour")) %>%
    dplyr::mutate(dis = sqrt((X - lon)^2+(Y-lat)^2)) %>%
    dplyr::filter(dis <= 100) %>%
    dplyr::filter(Length > 0)

  # find index(observation) which there is no land between the vessel and the whale
  index = acrossLand(df=data, map = map)

  ## only keep obs that does not cross land
  data_remove_land = data[index,]

  # calculate the maximum depth for each whale & vessel pair
  data_remove_land$maxDepth = maxDepth(df = data_remove_land, map, depth, segment_length = 0.5)

  # calculate the RL for every vessel
  RL_eachObs = data_remove_land %>%
    dplyr::mutate(SL = ifelse(Length <=10,163.6, ifelse(10 <Length&Length<=25, 157.2,
                                                 ifelse(25 <Length&Length<=50, 176.4,
                                                        ifelse(50 <Length&Length<100, 181.1,190.8))))) %>%
    dplyr::mutate(RL = SL-10*log10(maxDepth) - 10*log10(dis*1000))

  # calculate the RL in every whale's location
  RL_eachLoc_sum =  RL_eachObs %>%
    dplyr::group_by(year,month,day,hour) %>%
    dplyr::summarise(n = n(),RL_total = 10*log10(sum(10^(RL/10)))) %>%
    dplyr::left_join(whale_hour,by = c("year","month","day","hour")) %>% # want whale's lon and lat
    dplyr::select(year,month,day,hour,n,RL_total,lon,lat)

  return(RL_eachLoc_sum)
}







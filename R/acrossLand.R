#' Return the index that there is no land between the vessel and the whale
#'
#' @param df The data frame that join whale and vessel together. Necessary variables: whale's loc (UTM), vessels'loc (UTM)
#'
#'
#' @return index
#' @export
acrossLand = function(df) {
  # load the map that include British Columbia in Canada + west coast of USA
  # load("data/map.RData")

  # combine in map.RData, stores coordinates, is a list with length 2580
  # British Columbia = 1:2573
  # West Coast = 2574:2580
  # load(R/sysdata.rda)

  # British Columnbis has 2573 polygons.
  # Keep which are inside the range of whale
  inside_range = data.frame(index = 1:(length(combine)-7), inside = rep(NA,length(combine)-7))
  for(i in 1:(length(combine)-7)) {
    fm = as.data.frame(combine[[i]])
    if(max(fm$x) < min(df$lon) - 100 | min(fm$x) > max(df$lon) + 100 | ## polygons that are outside df
       max(fm$y) < min(df$lat) - 100 |min(fm$y) > max(df$lat) +100 ) {
      inside_range$inside[i] = 0
    } else {
      inside_range$inside[i] = 1 ## polygons that we keep
    }
  }
  keep  = filter(inside_range, inside == 1)$index

  # combine these polygons and regard it as the map we are going to test
  bc = st_multipolygon(combine[keep])


  ## first test whether there is a land between whale and vessel in West Coast of USA
  aLand = rep(NA,nrow(df))
  for (i in 1:length(aLand)) {
    line = st_linestring(rbind(c(df$lon[i],df$lat[i]),
                               c(df$X[i],df$Y[i])))
    result1.wa = st_intersection(line,wa)
    result1.or = st_intersection(line,or)
    result1.ca = st_intersection(line,ca)
    if(length(result1.wa)== 0 & length(result1.or)== 0 & length(result1.ca) == 0) {
      aLand[i] = 0 # no land
    } else {
      aLand[i] = 1
    }
  }
  table = data.frame(index = 1:length(aLand),result.wc = aLand)
  table1 = filter(table, result.wc == 0)


  ## then test whether there is a land between whale and vessel in British Columbia
  aLand.result2 = rep(NA,nrow(df))
  for(i in table1$index) {
    line = st_linestring(rbind(c(df$lon[i],df$lat[i]),
                               c(df$X[i],df$Y[i])))
    result2 = st_intersection(line,bc)
    aLand.result2[i] = length(result2)
  }

  table$result.bc = aLand.result2
  table2 = filter(table, result.wc == 0 & result.bc == 0)

  return(table2$index)
}

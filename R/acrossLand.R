#' Return the index that there is no land between the vessel and the whale
#'
#' @param df The data frame that join whale and vessel together. Necessary variables: whale's loc (UTM), vessels'loc (UTM)
#' @param map The map that will be used to test
#'
#' @return index that is not cross land
#' @export
acrossLand = function(df, map) {
  aLand = rep(NA,nrow(df))
  for (i in 1:length(aLand)) {
    line = st_linestring(rbind(c(df$lon[i],df$lat[i]),
                               c(df$X[i],df$Y[i])))
    aLand[i] = length(st_intersection(line,map))
  }
  result = data.frame(index = 1:length(aLand), aLand = aLand)
  result_final = result %>% filter(aLand == 0)

  return(result_final$index)
}

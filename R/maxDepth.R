#' Find the maximum depth for every whale & vessel pair
#'
#' @param df The data frame that join whale and vessel together. Necessary variables: whale's loc (UTM), vessels'loc (UTM)
#' @param map The map that around whale and vessel
#' @param depth The depth data include location (x,y) and depth (in meters)
#' @param segment_length in km
#'
#'
#' @return maximum depth for each whale & vessel pair
#' @export
maxDepth = function(df, map, depth, segment_length = 0.5) {
  # the range of whale&vessel
  min_x = min(min(df$lon), min(df$X))
  max_x = max(max(df$lon), max(df$X))
  max_y = max(max(df$lat), max(df$Y))
  min_y = min(min(df$lat), min(df$Y))

  # make the depth data that is within 0.5km around whale&vessel
  depth  = depth %>%
    filter(x>= min_x*1000 - 500 & x<= max_x*1000 + 500) %>%
    filter(y>= min_y*1000 - 500 & y<= max_y*1000 + 500) %>%
    mutate(X = x/1000, Y = y/1000) %>%
    select(X,Y,depth_m)

  # store the maximum depth for each pair
  maxDepth = rep(NA,nrow(df))

  for(i in 1:nrow(df)) {

    # draw a line between the whale and vessel
    x1 = df$lon[i]
    y1 = df$lat[i]
    x2 = df$X[i]
    y2 = df$Y[i]
    slope = (y2-y1)/(x2-x1)
    intercept = y1-slope*x1

    # points on the line
    pts_x = seq(from = min(x1,x2), to = max(x1,x2), by = segment_length)
    pts = data.frame(pts_x = pts_x,
                     pts_y = slope*pts_x+intercept)

    ## find the maximal depth along this line
    ip_depth = rep(NA,nrow(pts))
    # shrink the depth data that is within 0.1km around whale & vessel
    depth_filter = depth %>%
      filter(X>= min(pts$pts_x) - 0.1 & X<= max(pts$pts_x) + 0.1)%>%
      filter(Y>= min(pts$pts_y) - 0.1 & Y<= max(pts$pts_y) + 0.1)
    for(j in 1:nrow(pts)) {
      ## for every points on the line, find the four closest depth data
      four = depth_filter %>%
        filter(X>= pts$pts_x[j] - 0.1 & X<= pts$pts_x[j] + 0.1) %>%
        filter(Y>= pts$pts_y[j] - 0.1 & Y<= pts$pts_y[j] + 0.1) %>%
        mutate(dis = sqrt((X-pts$pts_x[j])^2+(Y-pts$pts_y[j])^2)) %>%
        arrange(dis)

      if(nrow(four) >= 4) {
        if(sd(four$X[1:4]) < 0.005 | sd(four$Y[1:4]) < 0.005) { # if x or y is too close, just take the mean
          ip_depth[j] = mean(abs(four$depth_m)[1:4])
        } else {
          # bi-linear interpolation
          model = interp(x=four$X[1:4],y=four$Y[1:4],z=abs(four$depth_m)[1:4],
                         xo=pts$pts_x[j],yo=pts$pts_y[j])
          if(!is.na(model$z)) {
            ip_depth[j] = model$z
          }else { # if the target point is outside the four closest depth data, take the mean
            ip_depth[j] = mean(abs(four$depth_m[1:4]))
          }
        }

      } else { # if the number of rows < 4, set to NA temporarly and deal with it later
        ip_depth[j] = NA
      }
    }

    if(sum( !is.na(ip_depth)) == 0) { # if all pts are NA's, set to 0
      maxDepth[i] = 0
    } else {
      maxDepth[i]=max(ip_depth)
    }
  }

  # Now deal with the maximum depth that are NA's
  index = which(is.na(maxDepth))
  if(length(index) > 0) {
    width_to_use = rep(NA,nrow(df))
    for(i in index) {
      x1 = df$lon[i]
      y1 = df$lat[i]
      x2 = df$X[i]
      y2 = df$Y[i]
      slope = (y2-y1)/(x2-x1)
      intercept = y1-slope*x1
      pts_x = seq(from = min(x1,x2), to = max(x1,x2), by = 0.5)
      pts = data.frame(pts_x = pts_x,
                       pts_y = slope*pts_x+intercept)
      ## find the maximal depth
      ip_depth = rep(NA,nrow(pts))
      # shrink the depth data that is within 20 km around whale & vessel
      depth_filter = depth %>%
        filter(X>= min(pts$pts_x) - 20 & X<= max(pts$pts_x) + 20 &
                 Y>= min(pts$pts_y) - 20 & Y<= max(pts$pts_y) + 20)
      for(j in 1:nrow(pts)) {
        ## four closest pts
        four = depth_filter %>%
          filter(X>= pts$pts_x[j] - 0.1 & X<= pts$pts_x[j] + 0.1) %>%
          filter(Y>= pts$pts_y[j] - 0.1 & Y<= pts$pts_y[j] + 0.1) %>%
          mutate(dis = sqrt((X-pts$pts_x[j])^2+(Y-pts$pts_y[j])^2)) %>%
          arrange(dis)
        width = 0.1
        # increase the width until have more than 4 rows.
        while(nrow(four) < 4) {
          width = width + 0.1
          four = depth_filter %>%
            filter(X>= pts$pts_x[j] - width & X<= pts$pts_x[j] + width) %>%
            filter(Y>= pts$pts_y[j] - width & Y<= pts$pts_y[j] + width) %>%
            mutate(dis = sqrt((X-pts$pts_x[j])^2+(Y-pts$pts_y[j])^2)) %>%
            arrange(dis)
        }
        width_to_use[i] = width

        if(sd(four$X[1:4]) < 0.005 | sd(four$Y[1:4]) < 0.005) {
          ip_depth[j] = mean(abs(four$depth_m)[1:4])
        } else {
          model = interp(x=four$X[1:4],y=four$Y[1:4],z=abs(four$depth_m)[1:4],
                         xo=pts$pts_x[j],yo=pts$pts_y[j])
          if(!is.na(model$z)) {
            ip_depth[j] = model$z
          }else {
            ip_depth[j] = mean(abs(four$depth_m[1:4]))
          }
        }
      }
      maxDepth[i]=max(ip_depth)

    }
  }

  return(maxDepth)

}

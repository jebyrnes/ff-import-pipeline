library(png)
library(tidyverse)

make_color_df <- function(atile){
  data.frame(
    red = matrix(atile[,,1], ncol=1),
    green = matrix(atile[,,2], ncol=1),
    blue = matrix(atile[,,3], ncol=1)
  )
}

get_channel_sums <- function(atile){
  # reshape image into a data frame
  df <- make_color_df(atile)
  colSums(df)
}


get_channel_max <- function(atile){
  # reshape image into a data frame
  df <- make_color_df(atile)
  map_dbl(df, max)
}


get_channel_percentile <- function(atile, quant = 0.95){
  # reshape image into a data frame
  df <- make_color_df(atile)
  map_dbl(df, ~quantile(., quant))
}


get_rb_max <- function(atile){
  # reshape image into a data frame
  df <- make_color_df(atile)
  max(df$red/df$blue)
}

get_rb_quant <- function(atile, quant = 0.95){
  # reshape image into a data frame
  df <- make_color_df(atile)
  quantile(df$red/df$blue, quant)
}


get_filtered_tiles_by_colors <- function(dir, 
                                         fun = get_channel_max,
                                         green_filter = 0.6,
                                         blue_filter = 0.6,
                                         red_filter = 0.6){
  dir <- paste(dir, "accepted/", sep="/")
  #  dir <- "LT05_L1TP_220096_19980118_20161228_01_T1_tiles/accepted/" #debug
  f <- list.files(dir)
  f <- f[grep("png", f)]
  
  adf <- data.frame(i = grep("png", f)) %>%
    group_by(i) %>%
    mutate(file = f[i],
           vals = list(fun(readPNG(paste0(dir, f[i])))),
           red = vals[[1]][1],
           green = vals[[1]][2],
           blue = vals[[1]][3]) %>%
    ungroup() %>%
    select(-vals)
  
  adf_filtered <- adf %>% 
    filter(green > green_filter) %>% 
    filter(blue > blue_filter) %>%
    filter(red > red_filter)
  
  adf_filtered$file
  
}


get_filtered_tiles_by_score <- function(dir, 
                                        fun = get_rb_max,
                                        score = 4, ...){
  dir <- paste(dir, "accepted/", sep="/")
  #  dir <- "LT05_L1TP_220096_19980118_20161228_01_T1_tiles/accepted/" #debug
  f <- list.files(dir)
  f <- f[grep("png", f)]
  
  adf <- data.frame(i = grep("png", f)) %>%
    group_by(i) %>%
    mutate(file = f[i],
           vals = fun(readPNG(paste0(dir, f[i])), ...)) %>%
    ungroup() 
  
  adf_filtered <- adf %>% 
    filter(vals > score)
  
  adf_filtered$file
  
}
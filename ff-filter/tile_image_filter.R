#Load methods and libraries
library(tidyverse)
library(foreach)
library(doParallel)
library(readr)
source("./image_filtering_method.R")

scene_dir <- "../ff-import/"
out_dir <- "./new_for_upload"

#setup the parallel backend
registerDoParallel(cores=4)


#get a list of scenes
files <- list.files(scene_dir)
files <- files[grep("LT05", files)] #fix to deal with other satellites
#files <- c(files, "grid_350")

#for each scene
scenes_out <- foreach(scene = files) %do%{
  #1) Figure out which images are good
  good_img <- get_filtered_tiles_by_score(paste0(scene_dir, scene),
                                          fun = get_rb_quant,
                                          score = 1,
					  quant = 0.98)
  
  #2) Write good images to the new output directory
  new_img <- paste(scene, good_img, sep="_") 
  
  #ugh, I hate a for loop in R, but....
  for(i in 1:length(good_img)){
    system(paste("cp", 
                 paste0(scene_dir, scene, "/accepted/", good_img[i]),
                 paste(out_dir,  new_img[i], sep="/"),
                 sep = " "))  
  }
  
  #3) Write a new manifest for the scene
  accepted <- read_csv(paste0(scene_dir, scene, "/accepted/manifest.csv")) %>%
    filter(`#filename` %in% good_img) %>%
    mutate(`!scene` = gsub("temp\\/", "", `!scene`))
  
  write_csv(accepted, paste0(out_dir, "/accepted/", scene, "_manifest.csv"))
  
  
  #4) Write a new rejection manifest for the scene
  new_rejected <- read_csv(paste0(scene_dir, scene, "/accepted/manifest.csv")) %>%
    filter(!(`#filename` %in% good_img)) %>%
    mutate(`#reason` = "All water, clouds, or blank")
  
  rejected <- read_csv(paste0(scene_dir, scene, "/rejected/rejected.csv"))
  
  rejected <- bind_rows(rejected, new_rejected) %>%
    mutate(`!scene` = gsub("temp\\/", "", `!scene`))
  
  write_csv(rejected, paste0(out_dir, "/rejected/", scene, "_rejected.csv"))
  
  scene
}

#Now, merge accepted manifests
accepted_manifests <- list.files( paste0(out_dir, "/accepted/"))
manifest <- read_csv(paste0(out_dir, "/accepted/", accepted_manifests[1]))

for(a_manifest in accepted_manifests[-1]){
  manifest <- manifest %>%
    bind_rows(read_csv(paste0(out_dir, "/accepted/", a_manifest)))
}

write_csv(manifest,  paste(out_dir,  "manifest.csv", sep="/"))

# 
# 
# ######## EARLY TEST MATERIAL
# library(png)
# library(tidyverse)
# dir <- "LT05_L1TP_220096_19980118_20161228_01_T1_tiles/accepted/"
# files <- c("tile_0006.png", #water
#            "tile_0084.png", #clouds
#            "tile_0172.png") #good
# 
# 
# dim(atile)
# 
# atile <- readPNG(paste0(dir, files[3]))
# par(mfrow=c(2,2))
# hist(atile[,,1])
# hist(atile[,,2])
# hist(atile[,,3])
# par(mfrow=c(1,1))
# 
# ############
# 
# make_color_df <- function(atile){
#   data.frame(
#     red = matrix(atile[,,1], ncol=1),
#     green = matrix(atile[,,2], ncol=1),
#     blue = matrix(atile[,,3], ncol=1)
#   )
# }
# 
# get_channel_sums <- function(atile){
#   # reshape image into a data frame
#   df <- make_color_df(atile)
#   colSums(df)
# }
# 
# 
# get_channel_max <- function(atile){
#   # reshape image into a data frame
#   df <- make_color_df(atile)
#   map_dbl(df, max)
# }
# 
# dir <- "LT05_L1TP_220096_19980118_20161228_01_T1_tiles/accepted/"
# get_channel_sums(readPNG(paste0(dir, "tile_0084.png"))) #clouds
# get_channel_max(readPNG(paste0(dir, "tile_0084.png")))
# 
# get_channel_sums(readPNG(paste0(dir, "tile_0172.png"))) #land
# get_channel_max(readPNG(paste0(dir, "tile_0172.png")))
# 
# dir <- "grid_350/accepted/" #brown land small
# get_channel_sums(readPNG(paste0(dir, "tile_0099.png"))) #land
# get_channel_max(readPNG(paste0(dir, "tile_0099.png")))
# 
# ######TEST
# 
# dir <- "LT05_L1TP_220096_19980118_20161228_01_T1_tiles/accepted/"
# f <- list.files(dir)
# 
# adf <- data.frame(i = grep("png", f)) %>%
#   group_by(i) %>%
#   mutate(file = f[i],
#          vals = list(get_channel_max(readPNG(paste0(dir, f[i])))),
#          red = vals[[1]][1],
#          green = vals[[1]][2],
#          blue = vals[[1]][3]) %>%
#   ungroup() %>%
#   select(-vals)
# 
# adf_filtered <- adf %>% 
#   filter(green>0.6) %>% 
#   filter(blue > 0.6) %>%
#   filter(red > 0.6)
# 
# for(i in 1:nrow(adf_filtered)){
#   system(paste0("cp ", paste0(dir, adf_filtered$file[i]), " ./test"))  
# }
# 
# ####### viz
# PCA = prcomp(df[,c("red","green","blue")], center=TRUE, scale=TRUE)
# df$u = PCA$x[,1]
# df$v = PCA$x[,2]
# 
# library(ggplot2)
# 
# ggplot(df, aes(x=u, y=v, col=rgb(red,green,blue))) + 
#   geom_point(size=2) + scale_color_identity()

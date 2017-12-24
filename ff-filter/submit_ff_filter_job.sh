#!/bin/bash

#load modules
module load R/3.4.0
module load libpng/1.6.8
module load acml/5.3.1/gfortran64
module load gcc/5.1.0

# n = number of cores, W = job time, rusage = memory, 1024 = 1 gig
bsub -n 10 -W 72:00 -R "rusage[mem=3000]" Rscript ./tile_image_filter.R

<!-- README.md is generated from README.Rmd. Please edit that file -->
getais
======

The getais R package is simply a data processing package, meant to download and process the very large AIS datasets from MarineCadastre.gov.

You can install the development version of the package with:

``` r
# install.packages("devtools")
devtools::install_github("eric-ward/getais")
```

An example processing script
----------------------------

Create data frame for all combinations

``` r
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(lubridate)
#> 
#> Attaching package: 'lubridate'
#> The following object is masked from 'package:base':
#> 
#>     date
library(getais)
library(rgdal)
#> Loading required package: sp
#> rgdal: version: 1.1-10, (SVN revision 622)
#>  Geospatial Data Abstraction Library extensions to R successfully loaded
#>  Loaded GDAL runtime: GDAL 1.11.4, released 2016/01/25
#>  Path to GDAL shared files: /Users/eric.ward/Library/R/3.3/library/rgdal/gdal
#>  Loaded PROJ.4 runtime: Rel. 4.9.1, 04 March 2015, [PJ_VERSION: 491]
#>  Path to PROJ.4 shared files: /Users/eric.ward/Library/R/3.3/library/rgdal/proj
#>  Linking to sp version: 1.2-3

if (!file.exists("filtered")) dir.create("filtered")

all_combos = expand.grid("zone"=1:19,"year"=2009:2014,"month"=1:12)
```

As an example, we'll only use data from December and UTM Zone 1.

``` r
subset = all_combos[which(all_combos$zone==1 & all_combos$month==12),]
```

Process the data for these combinations of months / years / zones. The user can also specify the 'hours' argument, which finds observations from each vessel that are closest to that time. For example, if observations closest to noon each day are wanted, specify 12, if observations every 6 hours are wanted, specify c(0, 6, 12, 18). Here we'll just get records closest to 4am and noon,

``` r
process_ais(df = subset, hours = c(4,12))
#> OGR data source with driver: OpenFileGDB 
#> Source: "Zone1_2009_12.gdb", layer: "Broadcast"
#> with 26 features
#> It has 10 fields
#> OGR data source with driver: OpenFileGDB 
#> Source: "Zone1_2010_12.gdb", layer: "Broadcast"
#> with 57874 features
#> It has 10 fields
#> OGR data source with driver: OpenFileGDB 
#> Source: "Zone1_2011_12.gdb", layer: "Broadcast"
#> with 47755 features
#> It has 10 fields
#> OGR data source with driver: OpenFileGDB 
#> Source: "Zone1_2011_12.gdb", layer: "Broadcast"
#> with 47755 features
#> It has 10 fields
#> OGR data source with driver: OpenFileGDB 
#> Source: "Zone1_2011_12.gdb", layer: "Broadcast"
#> with 47755 features
#> It has 10 fields
#> OGR data source with driver: OpenFileGDB 
#> Source: "Zone1_2012_12.gdb", layer: "Broadcast"
#> with 38220 features
#> It has 10 fields
#> OGR data source with driver: OpenFileGDB 
#> Source: "Zone1_2013_12.gdb", layer: "Zone1_2013_12_Broadcast"
#> with 58411 features
#> It has 10 fields
#> OGR data source with driver: OpenFileGDB 
#> Source: "Zone1_2014_12.gdb", layer: "Zone1_2014_12_Broadcast"
#> with 10340 features
#> It has 10 fields
```

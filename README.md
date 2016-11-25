<!-- README.md is generated from README.Rmd. Please edit that file -->
getais
======

The getais R package is simply a data processing package, meant to download and process the very large AIS datasets from MarineCadastre.gov.

You can install the development version of the package with:

``` r
# install.packages("devtools")
if("getais" %in% rownames(installed.packages()) == FALSE) {
  devtools::install_github("eric-ward/getais")
}
library(getais)
#> Loading required package: rgdal
#> Loading required package: sp
#> rgdal: version: 1.1-10, (SVN revision 622)
#>  Geospatial Data Abstraction Library extensions to R successfully loaded
#>  Loaded GDAL runtime: GDAL 1.11.4, released 2016/01/25
#>  Path to GDAL shared files: /Users/eric.ward/Library/R/3.3/library/rgdal/gdal
#>  Loaded PROJ.4 runtime: Rel. 4.9.1, 04 March 2015, [PJ_VERSION: 491]
#>  Path to PROJ.4 shared files: /Users/eric.ward/Library/R/3.3/library/rgdal/proj
#>  Linking to sp version: 1.2-3
#> Loading required package: dplyr
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
#> Loading required package: lubridate
#> 
#> Attaching package: 'lubridate'
#> The following object is masked from 'package:base':
#> 
#>     date
```

An example processing script
----------------------------

Create data frame for all combinations

``` r
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
```

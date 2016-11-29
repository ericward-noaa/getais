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
```

An example processing script
----------------------------

Create data frame for all combinations

``` r
if (!file.exists("filtered")) dir.create("filtered")

all_combos = expand.grid("zone"=1:19,"year"=2009:2014,"month"=1:12)
```

As an example, we'll only use data from December and UTM Zone 3.

``` r
subset = all_combos[which(all_combos$zone==3 & all_combos$month==12),]

head(subset)
#>      zone year month
#> 1257    3 2009    12
#> 1276    3 2010    12
#> 1295    3 2011    12
#> 1314    3 2012    12
#> 1333    3 2013    12
#> 1352    3 2014    12
```

Process the data for these combinations of months / years / zones. The user can also specify the 'every\_minutes' argument, which finds observations from each vessel that are closest to that time. For example, if we wanted observations nearest to every 30 minutes, we'd use

``` r
downsample_ais(df = subset, every_minutes = 30)
```

And now we have a few hundered records per file (instead of &gt; 50000) in the 'filtered' folder,

``` r
dir("filtered")
#>  [1] "Zone1_12_2009.csv" "Zone1_12_2010.csv" "Zone1_12_2011.csv"
#>  [4] "Zone1_12_2012.csv" "Zone1_12_2013.csv" "Zone1_12_2014.csv"
#>  [7] "Zone3_12_2009.csv" "Zone3_12_2010.csv" "Zone3_12_2011.csv"
#> [10] "Zone3_12_2012.csv" "Zone3_12_2013.csv" "Zone3_12_2014.csv"
```

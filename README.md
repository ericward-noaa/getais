
getais
======

The getais R package is simply a data processing package, meant to download and process the very large AIS datasets from MarineCadastre.gov.

You can install the development version of the package with:

``` r
# install.packages("devtools")
devtools::install_github("ericward-noaa/getais")

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

Process the data for these combinations of months / years / zones. The user can also specify the status codes to keep, which defaults to

``` r
status_codes_to_keep = c(0, 7, 8, 9, 10, 11, 12, 13, 14, 15)
```

More details here: <https://help.marinetraffic.com/hc/en-us/articles/203990998-What-is-the-significance-of-the-AIS-Navigational-Status-Values-#>'

The additional information that can be joined in relates to the vessel and voyage. The vessel attributes can be specified with *vessel\_attr*. These default to

``` r
vessel_attr = c("VesselType","Length")
```

but can be changed, and other fields may be included ("IMO", "CallSign", "Name", "Width", "DimensionComponents"). The voyage attributes *voyage\_attr* default to just including destination,

``` r
voyage_attr = c("Destination")
```

but also allows other variables ("VariableID", "Cargo", "Draught", "ETA", "StartTime", "EndTime").

### Running the function

The downsample\_ais() function also takes the 'every\_minutes' argument, which finds observations from each vessel that are closest to that time. For example, if we wanted observations nearest to every 30 minutes, we'd use

``` r
downsample_ais(df = subset, every_minutes = 30)
#> Joining, by = "MMSI"
#> Joining, by = "MMSI"
#> Joining, by = "MMSI"
#> Joining, by = "MMSI"
#> Joining, by = "MMSI"
#> Joining, by = "MMSI"
#> Joining, by = "MMSI"
#> Joining, by = "MMSI"
#> Joining, by = "MMSI"
#> Joining, by = "MMSI"
#> Joining, by = "MMSI"
#> Joining, by = "MMSI"
```

And now we have a few hundered or thousand records per tab-delimitted output files in the 'filtered' folder,

``` r
dir("filtered")
#> [1] "Zone3_12_2009.txt" "Zone3_12_2010.txt" "Zone3_12_2011.txt"
#> [4] "Zone3_12_2012.txt" "Zone3_12_2013.txt" "Zone3_12_2014.txt"
```

Using the 30-minute sampling of zone 3 for example, each year has &lt; 10000 records.

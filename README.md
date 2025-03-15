# Stata Eurostat
Import data from Eurostat.

## Installation

To install this package run the following command:

```
net install eurostat, from("https://raw.githubusercontent.com/daniel-alves-fernandes/stata-eurostat/main/") 
```

## Use


Initialize a new dataset from a geo/range list (syntax 1) Eurostat dataset (syntax 2):

```
eurostat init, geo(geolist) range(startdate enddate)
```

```
eurostat init, dataset(dataset_code)
```

Dataset codes can be found at Eurostat's [Database Portal](https://ec.europa.eu/eurostat/web/main/data/database). For instance, to download employment figures navigate to Detailed Datasets > Population and Social Conditions > Labour market > Employment and Unemployment > LFS main indicators > Employment and activity. The first dataset available in this folder is "Employment and activity by sex and age - annual data". Eurostat provides the dataset code between brackets, in this case `lfsi_emp_a`.

Download a dataset:

```
eurostat dataset, dataset(frame) [clear]
```

Get a variable to the current dataset directly from an Eurostat dataset (syntax 1) or from a local dataset (syntax 2):

```
eurostat variable, generate(newvarname) dataset(dataset_code) [help]
```

```
eurostat variable, generate(newvarname) frame(frame) [help]
```

Open the dataset in the Eurostat portal:

```
eurostat browser, dataset(dataset_code)
```


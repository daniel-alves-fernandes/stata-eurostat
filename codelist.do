
* local website ///
* "https://ec.europa.eu/eurostat/api/dissemination/sdmx/3.0/structure"
* local opts "?compress=false&format=TSV&formatVersion=2.0"

**** GEO ****
* import delimited "`website'/codelist/ESTAT/GEO/`opts'", ///
* varname(1) delimit(tab) clear


* Syntax try
eurostat init, ///
geo(list, [Countries|NUTS1|NUTS2|NUTS3]) /// default "countries"
time(numlist, [Yearly|Quarterly|Monthly|Daily]) /// default "yearly"

// geo(PT ES IT, countries) // initiates a dataset with Portugal, Spain and Italy
// geo(PT ES, NUTS2) // initiates a dataset with NUTS 2 of Portugal and Spain
// range(2020, quarterly)

**** TIME ****
*import delimited "`website'/codelist/ESTAT/TIME/`opts'", ///
*varname(1) delimit(tab) clear

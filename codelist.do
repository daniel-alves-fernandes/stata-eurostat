
*******************************************************************************
** Eurostat init
********************************************************************************

capture: program drop eurostat_init_syntax_new
program define eurostat_init_syntax_new

  syntax name(name=function), Geo(string asis) Range(string asis) [clear]

  ** Get data
  local website ///
  "https://ec.europa.eu/eurostat/api/dissemination/sdmx/3.0/structure"
  local opts "?compress=false&format=TSV&formatVersion=2.0"

  import delimited "`website'/codelist/ESTAT/GEO/`opts'", ///
  varname(1) delimit(tab) encoding(utf-8) clear
end


*******************************************************************************
** Get countries
capture: program drop eurostat_init_geo
program define eurostat_init_geo
  syntax namelist, [Countries] [NUTS1] [NUTS2] [NUTS3]

end

*******************************************************************************
** Get range
capture: program drop eurostat_init_range
program define eurostat_init_range

end

*******************************************************************************s
** Geo aggregates
capture: program drop eurostat_init_check_aggregate
program define eurostat_init_check_aggregate, rclass
  /*
  Internal function for eurostat init.
  This function cannot be called outside of the program.
  Returns country list of geo aggregates.
  */

  syntax anything
  quietly: levelsof noteenonly if code == "`anything'", clean
  if (`r(r)' == 0) noisily: display ///
    "`anything' is not an aggregate geo."

  else if (`r(r)' > 1) noisily: display ///
    "`anything' does not identify a single aggregate geo."

  else{
    local country_list: display ///
      subinstr("`r(levels)'","This aggregate covers following countries: ","",.)

    local country_list: display ///
      subinstr("`country_list'",",","",.)
    return local country_list `country_list'
  }
end



/*
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
*/
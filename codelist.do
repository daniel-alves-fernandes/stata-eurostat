
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

  * Keep only observations up to United Kingdom (including)
  tempvar obs
  gen `obs' = _n
  levelsof `obs' if strmatch(code,"UK*") // List all UK values
  local cut: word `r(r)' of `r(levels)'  // Take last value
  keep in 1/`cut'

  * Keep only standard codes (and old standard codes)
  keep if inlist(standardcode,"Y","O")

  gen old_code = standardcode == "O"
  keep code labelenglish old_code noteenonly

  rename (labelenglish noteenonly) (label note)

  * Create groups
  local aggregates ///
  EU   /// European Union
  EA   /// Euro Area
  NMS  /// New member-states
  EEA  /// European Economic Area
  EFTA /// European Free Trade Association

  local countries ///
  BE /// Belgium
  BG /// Bulgaria
  CZ /// Czechia
  DK /// Denmark
  DE /// Germany
  EE /// Estonia
  IE /// Ireland
  EL /// Greece
  ES /// Spain
  FR /// France
  HR /// Croatia
  IT /// Italy
  CY /// Cyprus
  LV /// Latvia
  LT /// Lithuania
  LU /// Luxembourg
  HU /// Hungary
  MT /// Malta
  NL /// Netherlands
  AT /// Austria
  PL /// Poland
  PT /// Portugal
  RO /// Romania
  SI /// Slovenia
  SK /// Slovakia
  FI /// Finland
  SE /// Sweden
  IS /// Iceland
  LI /// Liechtenstein
  NO /// Norway
  CH /// Switzerland
  UK /// United Kingdom

  gen group = "", before(code)
  gen level = "", after(code)

  foreach stub of local aggregates{
    replace group = "`stub'" if strmatch(code,"`stub'*")
    replace level = "Aggregate" if strmatch(code,"`stub'*")
  }

  foreach stub of local countries{
    replace group = "`stub'" if strmatch(code,"`stub'*")

    replace level = "Country" if code == "`stub'"
    replace level = "NUTS1" if strmatch(code,"`stub'*") & strlen(code) == 3
    replace level = "NUTS2" if strmatch(code,"`stub'*") & strlen(code) == 4
    replace level = "NUTS3" if strmatch(code,"`stub'*") & strlen(code) == 5
    drop if strmatch(code,"`stub'*") & (strmatch(code,"*_*") | strmatch(code,"*-*"))
    drop if strmatch(code,"`stub'*") & strmatch(label,"*Unknown*")
    drop if strmatch(code,"`stub'*") & strmatch(label,"*Extra-Regio*")
  }

  ** Possible way to do this:
  // geo(PT ES, [Country|NUTS1|NUTS2|NUTS3])
  // time(2020 2025, yearly)
  levelsof strmatch(code,"PT*") & inlist(level,"NUTS3") & old_code == 0
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
eurostat stub, gen(pop) d(demo_pjan) help
A
NR
Y??
T

* Possible programmer function to extend the functionality of stub
eurostat stubREGEX, gen(pop) d(demo_pjan) help
A
NR
Y\w{1,2}
T
*/
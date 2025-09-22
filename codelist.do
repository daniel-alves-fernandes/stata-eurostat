
*******************************************************************************
** Eurostat init
********************************************************************************

capture: program drop eurostat_init_syntax_new
program define eurostat_init_syntax_new

  syntax name(name=function), Geo(string asis) /// [old]
  /// Geo(geolist, lowest_level old)
  /// Range(string asis, lowest_time) [clear]

  _eurostat_init_check `geo'
  _eurostat_init_aggregates `geo'

end

capture: program drop _eurostat_init_check
program define _eurostat_init_check
  /*
  Checks whether the user-supplied geo codes exist in the Eurostat database.
  Version 4.0 of the eurostat command checks codes against a reference dataset
  based on Eurostat's official GEO code list downloaded on 22/09/2025.
  */
  syntax anything(name=geolist)

  tempname codes
  frame create `codes'
  frame `codes'{
    quietly: use "geo.dta"
    quietly: levelsof code, clean
    local levels: display "`r(levels)'"
  }

  local check: list geolist in levels
  if (`check' == 0){
    local missing: list geolist - levels
    noisily: display as text "Not found in Eurostat: `missing'"
  }
end

capture: program drop _eurostat_init_aggregates
program define _eurostat_init_aggregates
  /*
  This function retrieves country codes from Aggregated codes.
  */
  syntax anything

  noisily: display "`anything'"
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
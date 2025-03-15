/******************************************************************************
eurostat.ado

version 3.2
09/02/2024

author: Daniel Fernandes
contact: d.alves.fernandes@law.leidenuniv.nl
******************************************************************************/

* Command functions
capture: program drop eurostat
capture: program drop eurostat_init
capture: program drop eurostat_dataset
capture: program drop eurostat_variable
capture: program drop eurostat_import
capture: program drop eurostat_browser

* Local functions
capture: program drop eurostat_init_syntax1
capture: program drop eurostat_init_syntax2
capture: program drop eurostat_trim
capture: program drop eurostat_structure

program define eurostat
  syntax name(name=function), *
  version 18

  if inlist("`function'","variable","var") eurostat_variable `0'
  else if inlist("`function'","dataset","data") eurostat_dataset `0'
  else if inlist("`function'","import") eurostat_import `0'
  else if inlist("`function'","init") eurostat_init `0'
  else if inlist("`function'","browser") eurostat_browser `0'
  else{
    display as error "`name' is not a recognised subcommand."
    error 197
  }
end

*******************************************************************************

program define eurostat_init
  /*
  Initializes a new dataset in Stata. This function accepts two syntaxes:
  1. dataset(): initializes a dataset with the same geo+time structure of the
     specified Eurostat dataset
  2. geo() + range(): initializes a dataset with the specified structure.
     As of this version, the command only recognizes country-year structures.
  */
  syntax name(name=function), [Dataset(string) Geo(string) Range(string)] *

  if missing("`dataset'") & missing("`geo'") & missing("`range'"){
    noisily: display as text ///
    "must specify either {it:dataset} or {it:geo+range}"
    exit 198
  }
  if !missing("`dataset'") eurostat_init_syntax1 `0'
  else eurostat_init_syntax2 `0'
end


program define eurostat_dataset
  /*
  This function imports and cleans datasets from Eurostat.
  */

  syntax name(name=function), Dataset(string) [clear]

  eurostat_import import, dataset(`dataset') `clear'
  local description: display "`_dta[note2]'"
  local reshape: display "`_dta[note3]'"

  capture: which greshape
  if (_rc == 111){
    quietly: reshape long value, i(`description') j(`reshape') string
  }
  else quietly: greshape long value, i(`description') j(`reshape') string

  rename value __value
  quietly: gen value = real(regexr(__value,"[bcdefnpuz:|-]+",""))
  drop __*

  quietly: ds geo time value, not
  noisily: display as text "Dimensions: `r(varlist)'"
end


program define eurostat_variable
  /*
  Thus function imports one variable to the active dataset.
  It supports two syntaxes.
  The first specifies the option dataset(). This option downloads the data
  directly from Eurostat.
  The second specifies the option frame(). This option retrieves the data
  from another frame. Use this option in case you need to retrieve many
  variables from the same datases. To import data this way, you should run
  -- frame ...: eurostat import, dataset(...) -- first.
  */

  syntax name(name=function), [help] ///
  GENerate(string) [Dataset(string) Frame(string)]

  if (mi("`dataset'") & mi("`frame'")) | (!mi("`dataset'") & !mi("`frame'")){
    noisily: display as text "must specify either {it:dataset} or {it:frame}"
    exit 198
  }

  local mainframe `c(frame)'
  tempname get_data
  if !missing("`dataset'"){
    frame create `get_data'
    frame `get_data'{
      eurostat_import import, dataset(`dataset')
      eurostat_trim, dataset(`dataset') mainframe(`mainframe') `help'
    }
    frame `get_data': quietly: keep if `r(keep_these_values)'
  }
  else{
    frame `frame': eurostat_trim, frame mainframe(`mainframe') `help'
    frame `frame': frame put _all if `r(keep_these_values)', into(`get_data')

  }

  frame `get_data'{
    local description: display "`_dta[note2]'"
    local reshape: display "`_dta[note3]'"

    capture: which greshape
    if (_rc == 111){
      quietly: reshape long value, i(`description') j(`reshape') string
    }
    else quietly: greshape long value, i(`description') j(`reshape') string

    rename value __value
    quietly: gen value = real(regexr(__value,"[bcdefnpuz:|-]+",""))
    drop __*
    quietly: count
  }
  if `r(N)' == 0{
    noisily: display as error ///
    `"`keep_these_values' did not match any observations"'
    exit 197
  }

  tempvar link
  quietly: frlink m:1 geo time, frame(`get_data') gen(`link')
  quietly: gen `generate' = frval(`link',value)
end


program define eurostat_import
  /*
  Imports datasets from Eurostat. This function DOES NOT fully clean the data.
  Use it only as a first step to use -- eurostat variable, frame(...) -- or
  to debug the cleaning subroutine.
  */
  syntax name(name=function), Dataset(string) [clear]

  noisily: display as text "Downloading data from Eurostat (`dataset')..."

  tempfile imported_data
  local website "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/data/"
  local opts "/?format=TSV&compressed=false"
  quietly: copy "`website'`dataset'`opts'.tsv" "`imported_data'.tsv", replace

  noisily: display as text "Importing data..."
  capture: import delimited "`imported_data'.tsv", varn(1) stringc(_all) ///
    delimiters(",\t") `clear'
  if (_rc == 4) error 4
  if (_rc == 601){
    display as error "`dataset' is not available on Eurostat."
    exit 601
  }

  quietly: compress

  quietly: ds
  local first_var: display "`: word 1 of `r(varlist)''"
  quietly: ds *geo*, insensitive
  local geotime  `r(varlist)'

  quietly: ds `first_var'-`geotime'
  local description "`r(varlist)'"
  local description: list description - geotime

  quietly: ds `first_var'-`geotime', not
  local values "`r(varlist)'"

  foreach var of varlist `values'{
    local varlabel: display "`:var label `var''"
    if "`varlabel'" != ""{
      rename `var' value`varlabel'
    }
  }

  capture: confirm variable geotime_period, exact
  if (_rc == 0){
    rename geotime_period geo
    local reshape time
    local add geo
  }
  else{
    ds *geo*, insensitive
    rename `r(varlist)' time
    local reshape geo
    local add time
  }

  note: `dataset'
  note: `description' `add'
  note: `reshape'
end

program define eurostat_browser
  /*
  Opens specified dataset in the default browser
  */

  syntax name(name=function), Dataset(string) *

  view browse "https://ec.europa.eu/eurostat/databrowser/product/view/`dataset'"

end

*******************************************************************************

program define eurostat_init_syntax1
  /*
    Internal function for eurostat init.
    This function cannot be called outside of the program.
  */

  syntax name(name=function), Dataset(string) [clear]

  eurostat_import import, dataset(`dataset') `clear'
  local range = ""
  foreach var of varlist value*{
    local time: display "`: var label `var''"
    local range "`range' `time'"
  }

  local range: list sort range
  local last: list sizeof range
  local last: display "`: word `last' of `range''"
  local first: display "`: word 1 of `range''"

  local thesemanytimes = (`last' + 1) - `first'
  keep geo
  contract geo
  drop _freq
  expand `thesemanytimes'
  bysort geo: gen time = strofreal(`first' + _n - 1)

  quietly: compress
end


program define eurostat_init_syntax2
  /*
    Internal function for eurostat init.
    This function cannot be called outside of the program.
  */

  syntax name(name=function), Geo(string asis) ///
  Range(numlist integer ascending min=1 max=2) [clear]

  if ("`clear'" == "clear") clear
  else{
    capture: assert _N == 0
    if (_rc == 9) noisily: error 4
  }

  quietly{
    local sizeofclist: list sizeof geo
    display `sizeofclist'
    gen geo_long = ""
    set obs `sizeofclist'
    foreach c of local geo{
      local obs: list posof "`c'" in geo
      replace geo_long = "`c'" in `obs'
    }

    tokenize `range'
    local start `1'
    local end `2'
    if missing(`end') local end `1'

    local thesemanytimes = `end' - `start' + 1
    expand `thesemanytimes'
    bysort geo_long: gen time = strofreal(`start' + _n - 1)

    sort geo (time)
    gen geo = "", after(geo_long)
    replace geo = "AL" if (geo_long == "Albania")
    replace geo = "AT" if (geo_long == "Austria")
    replace geo = "BE" if (geo_long == "Belgium")
    replace geo = "BG" if (geo_long == "Bulgaria")
    replace geo = "CH" if (geo_long == "Switzerland")
    replace geo = "CY" if (geo_long == "Cyprus")
    replace geo = "CZ" if (geo_long == "Czechia")
    replace geo = "DE" if (geo_long == "Germany")
    replace geo = "DK" if (geo_long == "Denmark")
    replace geo = "EE" if (geo_long == "Estonia")
    replace geo = "EL" if (geo_long == "Greece")
    replace geo = "ES" if (geo_long == "Spain")
    replace geo = "FI" if (geo_long == "Finland")
    replace geo = "FR" if (geo_long == "France")
    replace geo = "HR" if (geo_long == "Croatia")
    replace geo = "HU" if (geo_long == "Hungary")
    replace geo = "IE" if (geo_long == "Ireland")
    replace geo = "IS" if (geo_long == "Iceland")
    replace geo = "IT" if (geo_long == "Italy")
    replace geo = "LT" if (geo_long == "Lithuania")
    replace geo = "LU" if (geo_long == "Luxembourg")
    replace geo = "LV" if (geo_long == "Latvia")
    replace geo = "MT" if (geo_long == "Malta")
    replace geo = "NL" if (geo_long == "Netherlands")
    replace geo = "NO" if (geo_long == "Norway")
    replace geo = "PL" if (geo_long == "Poland")
    replace geo = "PT" if (geo_long == "Portugal")
    replace geo = "RO" if (geo_long == "Romania")
    replace geo = "SE" if (geo_long == "Sweden")
    replace geo = "SI" if (geo_long == "Slovenia")
    replace geo = "SK" if (geo_long == "Slovakia")
    replace geo = "UK" if (geo_long == "United Kingdom")

    levelsof geo_long if missing(geo), clean separate(", ")
    if (r(N) > 0) noisily: display as text "Not found in ESTAT: `r(levels)'"

    compress
  }
end


program define eurostat_trim, rclass
  /*
    Internal function to trim datasets according to the specified criteria.
    This function cannot be called outside of the program.
  */
  syntax, [frame dataset(string)] [help] mainframe(string)

  local panelvars: display "`_dta[note2]'"
  local geo geo
  local time time
  local panelvars: list panelvars - geo
  local panelvars: list panelvars - time

  if ("`help'" == "help"){
    local dataset: display "`_dta[note1]'"
    tempname structure
    frame create `structure'
    frame `structure'{
      eurostat_structure, dataset(`dataset')
      quietly: levelsof dimension_code, local(keep_these_dimensions)

      tempvar keep
      quietly: gen `keep' = .
    }

    foreach dim of local keep_these_dimensions{
      local dim_lower: display strlower("`dim'")
      capture: confirm var `dim_lower', exact
      if _rc {
        quietly: frame `structure': drop if (dimension_code == "`dim'")
      }
      else{
        quietly: levelsof `dim_lower', local(values_`dim')

        frame `structure'{
          foreach val of local values_`dim'{
            quietly: replace `keep' = 1 if ///
                     (dimension_code == "`dim'" & category_code == "`val'")
          }
        }
      }
    }
    frame `structure': quietly: keep if (`keep' == 1)
    frame change `structure'
    browse
  }
  else{
    frame change `mainframe'
    *browse
  }

  noisily: display as text "{bf:Select information to import...}"
  foreach var of local panelvars{
    noisily: display as text "`var' == " _request(_sdmxDataRequest)
    if (`"`keep_these_values'"' == ""){
      local keep_these_values `var' == "`sdmxDataRequest'"
    }
    else{
      local keep_these_values `"`keep_these_values' & `var' == "`sdmxDataRequest'""'
    }
  }

  frame change `mainframe'
  return local keep_these_values `keep_these_values'
end


program define eurostat_structure
  /*
    Internal function to download the dataset structure.
    This function cannot be called outside of the program.
  */

  syntax, Dataset(string)

  tempfile import1 import2

  local website "https://ec.europa.eu/eurostat/api/dissemination/sdmx/2.1/dataflow/ESTAT/"
  local opts "/?references=descendants&format=sdmx_2.1_generic"
  quietly: copy "`website'`dataset'`opts'" "`import1'.xml", replace

  quietly: filefilter "`import1'.xml" "`import2'.txt", ///
    from("<s:Code id=") to(\n) replace
  quietly: filefilter "`import2'.txt" "`import1'.txt", ///
    from(`"<c:Name xml:lang="en""') to(§) replace

  quietly: import delimited "`import1'.txt", clear delimiters("§", collapse)
  keep v1 v2

  tempvar flag codes
  quietly: gen `flag' = cond(inlist(v1,"<s:Codelists>","</s:Codelists>"),1,0)
  quietly: gen `codes' = sum(`flag')
  quietly: keep if (`codes' == 1) & !missing(v2)

  quietly: gen dimension_code = regexcapture(1) if ///
    regex(v1,`"id="(.*?)""') & strmatch(v1,"<s:Codelist*")
  quietly: gen category_code = regexcapture(1) if ///
    regexm(v1,`"(.*?)""') & !strmatch(v1,"<s:Codelist*")

  quietly: gen dimension_description = regexcapture(1) if ///
    regexm(v2,">(.*?)<") & strmatch(v1,"<s:Codelist*")
  quietly: gen category_description = regexcapture(1) if ///
    regexm(v2,">(.*?)<") & !strmatch(v1,"<s:Codelist*")

  quietly: keep dimension* category*

  forvalues obs = 1/`=_N'{
    capture: assert missing(dimension_code[`obs'])
    if _rc{
      local code: display dimension_code[`obs']
      local description: display dimension_description[`obs']
    }
    else{
      quietly: replace dimension_code = "`code'" in `obs'
      quietly: replace dimension_description = "`description'" in `obs'
    }
  }

  quietly: drop if missing(category_code)
end

{smcl}
{* *! version 2.0  31jan2023}{...}

{title:Eurostat - Import data from Eurostat}

{pstd}
{hi:eurostat} {hline 2} Import data from Eurostat.

{marker syntax}{...}
{title:Syntax}

Initialize a new dataset from a geo/range list (syntax 1) Eurostat dataset (syntax 2):

{pstd}
  {cmd:eurostat} {it:init},
  {bf:{ul:g}eo(}{it:geolist}{bf:)}
  {bf:{ul:r}ange(}{it:startdate enddate}{bf:)}

{pstd}
  {cmd:eurostat} {it:init},
  {bf:{ul:d}ataset}{bf:(}{it:dataset_code}{bf:)}


Download a dataset:

{pstd}
  {cmd:eurostat} {it:dataset},
  {bf:{ul:d}ataset(}{it:frame}{bf:)}
  {bf:[clear]}


Get a variable to the current dataset directly from an Eurostat dataset (syntax 1) or from a local dataset (syntax 2):

{pstd}
  {cmd:eurostat} {it:{ul:var}iable},
  {bf:{ul:gen}erate(}{it:{help newvarname}}{bf:)}
  {bf:{ul:d}ataset(}{it:dataset_code}{bf:)}
  {bf:[help]}

{pstd}
  {cmd:eurostat} {it:{ul:var}iable},
  {bf:{ul:gen}erate(}{it:{help newvarname}}{bf:)}
  {bf:{ul:f}rame(}{it:frame}{bf:)}
  {bf:[help]}

Open the dataset in the Eurostat portal:

{pstd}
  {cmd:eurostat} {it:browser},
  {bf:{ul:d}ataset}{bf:(}{it:dataset_code}{bf:)}


{title:Author}

{pstd}
{it:Daniel Alves Fernandes}{break}
Leiden University{break}
d.alves.fernandes@law.leidenuniv.nl

{pstd}

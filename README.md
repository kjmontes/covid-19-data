# COVID-19 Data Visualization with Video Animation

![Image of Mar. 22 Change in Cases Hotspot Map](Mar_22_hotspot_frame.jpg)

Author: Kevin Montes

Email: kjmontes1@gmail.com

[ [U.S. Data](us.csv) ([Raw CSV](https://raw.githubusercontent.com/nytimes/covid-19-data/master/us.csv)) | [U.S. State-Level Data](us-states.csv) ([Raw CSV](https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv)) | [U.S. County-Level Data](us-counties.csv) ([Raw CSV](https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv)) ]

[Geographic county data](https://www.sciencebase.gov/catalog/item/52c79543e4b060b9ebca5bf4)

[Population Data](https://www.census.gov/newsroom/press-kits/2020/pop-estimates-county-metro.html) (based on latest US. Census Estimates for 2019)

[Florida Hospital Data](https://bi.ahca.myflorida.com/t/ABICC/views/Public/COVIDHospitalizationsCounty?%3AisGuestRedirectFromVizportal=y&%3Aembed=y&fbclid=IwAR1Vidbf3ZOBVYSJynGR_5AH6IqmD2mfkaab8b9V-w-bQmTmPUSc6jNR0a4)

## Background

This repository has been forked from the [original New York Times repository](https://github.com/nytimes/covid-19-data) of the same name. Additional information about the datasets of COVID-19 cases and deaths can be found there in the 'README.md', including information about formatting, methodology, and licensing. The most up-to-date datasets can also be found there or at the links above.

The code in this repository also relies on the geographic county data available [here](https://www.sciencebase.gov/catalog/item/52c79543e4b060b9ebca5bf4) in order to render geographical projections of county boundaries. The 'tl_2012_us_county.zip' should be downloaded into the repo before running any of the scripts. 

The MATLAB scripts here were developed and tested with MATLAB version R2019b. They can be used to make a video animation of the case and death data located in the 'us-counties.csv' file. Data is loaded for a particular date interval and group of US states using the 'load_county_data.m' script. To plot, simply run the 'plot_usa_counties.m' script. It is written in a way to support plotting other quantities, as any user can write their own function that can be called by the main routine. Two examples of this are shown in the 'get_cases_per_area.m' and 'get_daily_new_cases.m' files.
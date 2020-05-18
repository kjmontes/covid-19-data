# COVID-19 Data Visualization with Video Animation

Author: Kevin Montes

Email: kjmontes1@gmail.com

This repository has been forked from the [original New York Times repository](https://github.com/nytimes/covid-19-data) of the same name, and synced with it using the [Pull](https://github.com/wei/pull) keep the data up-to-date. Additional information about the datasets of COVID-19 cases and deaths can be found there in the 'README.md', including information about formatting, methodology, and licensing. 

The code in this repository also relies on the geographic county data available [here](https://www.sciencebase.gov/catalog/item/52c79543e4b060b9ebca5bf4) in order to render geographical projections of county boundaries. The 'tl_2012_us_county.zip' should be downloaded into the repo before running any of the scripts. 

---

[ [U.S. Data](us.csv) ([Raw CSV](https://raw.githubusercontent.com/nytimes/covid-19-data/master/us.csv)) | [U.S. State-Level Data](us-states.csv) ([Raw CSV](https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv)) | [U.S. County-Level Data](us-counties.csv) ([Raw CSV](https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv)) ]

The MATLAB scripts here were developed and tested with MATLAB version R2019b. They can be used to make a video animation of the case and death data located in the 'us-counties.csv' file. To plot, simply run the 'plot_usa_counties.m' script. It is written in a way to support plotting other quantities, as any user can write their own function that can be called by the main routine. Two examples of this are shown in the 'get_cases_per_area.m' and 'get_daily_new_cases.m' files.
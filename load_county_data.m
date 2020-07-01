%% load_county_data.m
% Loads NYTimes covid-19 data and geographic US county data, then returns
% only the data that falls in the date/place range specified by the user
%
%% Inputs:
%
%   states : a 1D cell array of state names (must match FIPS_codes.csv)
%   dates  : a 2-element vector, with the first and last dates of the time
%            period to analyze (must be in a compatible MATLAB datetime
%            format)
%
%% Outputs:
%
%   covid_data     :  a MATLAB table array of subselected NYTimes data
%   county_shapes  :  a structure with geographic data for each county
%
%% 

function [covid_data,county_shapes] = load_county_data(states, dates)

%% Grab raw data from file
disp('Loading data ...')
opts = detectImportOptions('us-counties.csv');
csv_data = readtable('us-counties.csv',opts); % NYT data
county_shapes = shaperead('./tl_2012_us_county/tl_2012_us_county.shp', ...
    'UseGeoCoords',true); % geographic data
F = readtable('FIPS_codes.csv'); % table of states' FIPS prefix values

%% Check that input states are okay
names = F.Name; names{end+1} = 'conus';
not_found = zeros(size(states));
for i=1:length(states)
    if ~any(strcmp(states{i},names)); not_found(i) = 1; end
end
if any(not_found)
    disp("Valid state names:"); disp(F.Name);
    disp("ERROR: The following are not valid state names:");
    disp(states(find(not_found)));
    disp('Please enter one of the valid state names listed above');
end

%% Filter for region covered by input states & specified time interval

% Find FIPS code prefixes corresponding to the input state names 
if strcmp(states,'conus') % keep only counties inside the contiguous 48 states
    codes = F(F.FIPS<57 & F.FIPS~=15 & F.FIPS~=2,{'FIPS'}).FIPS; % states + DC, exclude HI & AK
else
    codes = zeros(1,length(states));
    for i=1:length(states)
        codes(i) = F(strcmp(F.Name, states{i}), {'FIPS'}).FIPS;
    end
end
regional_table = csv_data(ismember(round(csv_data.fips/1000),codes),:);
fips_geo = round(cellfun(@str2num,extractfield(county_shapes,'GEOID'))/1000);
county_shapes = county_shapes(find(ismember(fips_geo,codes)));
in_time = isbetween(regional_table.date,dates(1),dates(2));
covid_data = regional_table(in_time,:);
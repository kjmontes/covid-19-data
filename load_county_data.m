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

%% Get population data
opts = detectImportOptions('co-est2019-annres.xlsx');
opts.DataRange = '5:3147'; opts.VariableNamesRange = '4:4';
P = readtable('co-est2019-annres.xlsx',opts); % county population data
P.Properties.VariableNames{'Var1'} = 'Area';
area = cellfun(@(x) strip(x,'.'),P.Area,'UniformOutput',false);
County = cellfun(@(x) x(1:strfind(x,',')-8), area, 'UniformOutput', false);
State = cellfun(@(x) x(strfind(x,',')+2:end), area, 'UniformOutput', false);
P = addvars(P,County,State,'After','Area');

% Deal with exception to the rule
indx = find(strcmp(area,'Carson City, Nevada'));
P(indx,{'County'}) = {'Carson City'}; P(indx,{'State'}) = {'Nevada'};
indx = find(strcmp(area,'District of Columbia, District of Columbia'));
P(indx,{'County'}) = {'District of Columbia'};
P(indx,{'State'}) = {'District of Columbia'};

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

%% Add population data to each 'county' structure in 'county_shapes' array
% - use 2019 population estimates from US Census Bureau
% - see 'co-est2019-annres.xlsx' file for details
for i=1:length(county_shapes)
    fips = str2num(county_shapes(i).STATEFP); % get state ID
    state = F.Name(F.FIPS==fips); state = state{1}; % get state name
    county = county_shapes(i).NAME; % get county name
    if strcmp(state,'South Dakota') & strcmp(county,'Shannon') 
        county = 'Oglala Lakota'; % name changed in 2015
        county_shapes(i).NAME = county;
        county_shapes(i).NAMELSAD = 'Oglala Lakota County';
    end
    % Assume current population roughly the same as on Jan 1, 2019
    % To change this assumption later, edit/add to the following line ...
    pop = P(strcmp(P.State,state) & strcmp(P.County,county),:).x2019;
    % Save population in the 'county_shapes' structure
    county_shapes(i).POPULATION = pop;
end
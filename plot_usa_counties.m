%% Chooose a quantity to plot
%
%   - 1 : cases per square mile
%   - 2 : percentage change in cases from previous day
%_________________________________________________________________________

to_plot = 1;

% Specify [start, end] dates for video. Can either be 'dd-mmm-yyyy' format, 
% or chronological index of date (1 = first date in dataset)
date_interval = {'01-Feb-2020','01-Mar-2020'}; 

%% Grab data from file
disp('Loading data ...')
opts = detectImportOptions('us-counties.csv');
csv_data = readtable('us-counties.csv',opts);
S = table2struct(csv_data);
load greatlakes
county_shapes = shaperead('./tl_2012_us_county/tl_2012_us_county.shp', ...
    'UseGeoCoords',true);
fips = extractfield(S,'fips')';
deaths = extractfield(S,'deaths')';
cases = extractfield(S,'cases')';
DateNumber = cellfun(@datenum,extractfield(S,'date'));
unique_dates = unique(DateNumber);

%% Check that dates are okay
D = length(unique_dates); % number of days
date_indx = [1,length(unique_dates)]; % default date indices
if isvector(date_interval) & length(date_interval)==2 & iscell(date_interval)
    for i=1:2
        if ischar(date_interval{i}) & ~isempty(date_interval{i})
            if ismember(datenum(date_interval{i}),unique_dates)
                date_indx(i) = find(unique_dates==datenum(date_interval{i}));
            else
                disp(['ERROR: No data available for ' date_interval{i} ' ...'])
                disp(['Select data between ' datestr(min(unique_dates)) ...
                    ' and ' datestr(max(unique_dates))])
            end
        elseif isnumeric(date_interval{i})
            date_indx(i) = floor(date_interval{i});
            if date_indx(i)<1 | date_indx(i)>D
                disp(['ERROR: date index ' num2str(date_indx(i)) ...
                    ' is out of bounds [1,' num2str(D) ']'])
            end
        elseif isempty(date_interval{i})
            continue % stick with default date
        else
            disp("ERROR: 'date_interval' must contain start & end dates")
            return
        end
    end
else
    disp("ERROR: 'date_interval' must be cell array of length 2")
    return
end

%% Subselect data of interest
disp('Subselecting data from contiguous US ...')
geoid = extractfield(county_shapes,'GEOID');
find_HI_AK = @(x) startsWith(x,{'15','02'}); % get all but Hawaii, Alaska
HI_AK = find_HI_AK(geoid);
geoid = cellfun(@str2num,geoid);
not_a_state = (geoid>57000); % get all outlying areas that aren't in states
contig_US = (~HI_AK & ~not_a_state); % keep only counties inside the
geoid = geoid(contig_US);            % contiguous 48 states
C = length(geoid); % number of counties
land_area = extractfield(county_shapes(contig_US),'ALAND'); % [m^2]

%% Generate figure and set properties
disp('Generating figure ...')
fig = figure('OuterPosition',[0.062,0.062,0.875,0.925], ...
    'InnerPosition',[0.0677,0.0722,0.8635,0.8037],'Units',...
    'normalized','Position',[0.0677,0.0722,0.8635,0.8037]);
ax = usamap('conus');

%% Create DxC matrix (for D days, C counties) to store quantity to plot
disp('Calculating daily case count ...')
cases_array = zeros([D, C]);
for i=1:D
    today = find(DateNumber==unique_dates(i));
    [~,loc_geo,loc_fips] = intersect(geoid,fips(today),'stable');
    cases_array(i,loc_geo) = cases_array(i,loc_geo) + cases(today(loc_fips))';
end

% Calculate quantity for each county
if to_plot==1 % cases / sq. mile
    [quant_to_plot,info] = get_cases_per_area(cases_array,land_area);
elseif to_plot==2
    [quant_to_plot,info] = get_daily_new_cases(cases_array,5);
end

% Make it more plot-friendly
disp(['Calculated ' info.cbar_label])
cmap = info.color_map(length(info.quant_scale));
ax.CLim = [info.min_limit,info.max_limit];
ax.ColorScale = info.scale_type;
ax.Colormap = cmap;

%% Plot colormap for day 1
disp('Plotting day 1 ...')
% Plot county boundaries, each colored according to case count, for day 1
colorIndx = get_colorIndx(quant_to_plot(date_indx(1),:), ...
    info.quant_scale,info.scale_type);
faceColors = makesymbolspec('Polygon',{'INDEX', [1 C], ...
        'FaceColor',cmap(colorIndx',:)});
G = geoshow(ax, county_shapes, 'DisplayType', 'polygon', ...
       'SymbolSpec', faceColors);
framem off; gridm off; mlabel off; plabel off;

% Omit the Great Lakes region
[gtlakes, spec] = updategeostruct(greatlakes, white(3*numel(greatlakes)));
hold on; Lakes = geoshow(gtlakes, 'SymbolSpec', spec); hold off

% Include colorbar and text insert with the date
date_label = text(ax,0.5,0.9,['Date: ' datestr(unique_dates(date_indx(1)), ...
    'mmm.dd,yyyy')],'HorizontalAlignment','center','Units','normalized');
cbar = colorbar(ax);
cbar.Label.String = info.cbar_label;
cbar.Label.FontSize = info.cbar_fontsize;
if strcmp(info.scale_type,'log')
    if info.replace_min_with_0
        tick_labels = cbar.TickLabels;
        cbar.Ticks(1) = info.min_limit;
        cbar.TickLabels = tick_labels;
        cbar.TickLabels{1} = '0';
    end
end

%% Plot colormap for day 2->N
% Continue with the rest of the dates, updating each county's color
disp('Plotting the rest ...')
video = VideoWriter(info.video_name,info.video_type);
video.FrameRate = 6;
open(video)

for i=date_indx(1)+1:date_indx(2)
    % Update color indices according to the day's case count
    colorIndx = get_colorIndx(quant_to_plot(i,:),info.quant_scale,info.scale_type);
    new_cmap = cmap(colorIndx',:); % new colors for day i
    cmap_array = mat2cell(new_cmap,ones(1,C)); % convert to cell array 
    
    % Plot new county colors and new date label
    set(G.Children,{'FaceColor'},cmap_array) % change colors
    date_label.String = ['Date: ', datestr(unique_dates(i),'mmm.dd,yyyy')];
    
    writeVideo(video,getframe(fig)); % add frame to video structure
end

close(video)

function colorIndx = get_colorIndx(q,q_scale,scale_type)
% GET_COLORINDX Local function that returns appropriate colormap index
%   for each value in q, using the color scale in q_scale
    if isrow(q) & isrow(q_scale)
        a = repmat(q_scale',1,length(q));
        b = repmat(q,length(q_scale),1);
        if strcmp(scale_type,'log')
            [~,colorIndx] = min(abs(log10(a)-log10(b))); 
        elseif strcmp(scale_type,'linear')
            [~,colorIndx] = min(abs(a-b));
        end
    else
        disp('Both q and q_scale must be row vectors!')
        color_Indx = NaN(size(q));
    end
end
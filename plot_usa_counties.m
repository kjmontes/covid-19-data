% Specify [start, end] dates for video. Can either be 'dd-mmm-yyyy' format, 
% or chronological index of date (1 = first date in dataset)
to_plot = 2; % 1 for cases per area, 2 for change in moving avg. cases
date_interval = {'20-May-2020','23-May-2020'};
states = {'conus'};

% Load the data, with a 7 day buffer before the first day
days_to_load = {datestr(datenum(date_interval{1})-4),date_interval{2}};
[covid_data,county_shapes] = load_county_data(states, days_to_load);

%% Create DxC matrix (for D days, C counties) to store quantity to plot
disp('Calculating daily case count ...')
unique_dates = unique(datenum(covid_data.date));
geoid = cellfun(@str2num,extractfield(county_shapes,'GEOID'));
D = length(unique_dates); C = length(geoid);
cases = zeros([D, C]);
deaths = zeros([D, C]);
for i=1:D
    today = find(datenum(covid_data.date)==unique_dates(i));
    [~,loc_geo,loc_fips] = intersect(geoid,covid_data.fips(today),'stable');
    cases(i,loc_geo) = cases(i,loc_geo) + covid_data.cases(today(loc_fips))';
    deaths(i,loc_geo) = deaths(i,loc_geo) + covid_data.deaths(today(loc_fips))';
end

% Calculate quantity for each county
if to_plot==1 % cases / sq. mile
    [quant_to_plot,info] = get_cases_per_area(cases,geo_data.ALAND);
elseif to_plot==2
    [quant_to_plot,info] = get_daily_new_cases(cases,5);
end

%% Generate figure and set properties
disp('Generating figure ...')
fig = figure('OuterPosition',[0.062,0.062,0.875,0.925], ...
    'InnerPosition',[0.0677,0.0722,0.8635,0.8037],'Units',...
    'normalized','Position',[0.0677,0.0722,0.8635,0.8037]);
ax = usamap(states);

% Make it more plot-friendly
disp(['Calculated ' info.cbar_label])
cmap = info.color_map(length(info.quant_scale));
ax.CLim = [info.min_limit,info.max_limit];
ax.ColorScale = info.scale_type;
ax.Colormap = cmap;

%% Plot colormap for day 1
disp('Plotting day 1 ...')
% Plot county boundaries, each colored according to case count, for day 1
start_indx = find(unique_dates==datenum(date_interval(1)));
colorIndx = get_colorIndx(quant_to_plot(start_indx,:), ...
    info.quant_scale,info.scale_type);
faceColors = makesymbolspec('Polygon',{'INDEX', [1 C], ...
        'FaceColor',cmap(colorIndx',:)});
G = geoshow(ax, county_shapes, 'DisplayType', 'polygon', ...
       'SymbolSpec', faceColors);
framem off; gridm off; mlabel off; plabel off;

% If region borders the Great Lakes, load the lake data and omit from plot
near_lakes = {'Michigan','Ohio','New York','Indiana','Illinois', ...
    'Wisconsin','Pennsylvania','Minnesota','conus'};
if any(cellfun(@(x) any(strcmp(x,near_lakes)),states))
    load greatlakes;
    % Get county shapes and subselect data of interest
    [gtlakes, spec] = updategeostruct(greatlakes, white(3*numel(greatlakes)));
    hold on; Lakes = geoshow(gtlakes, 'SymbolSpec', spec); hold off
end

% Include colorbar and text insert with the date
date_label = text(ax,0.5,0.9,['Date: ' datestr(unique_dates(start_indx), ...
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

end_indx = find(unique_dates==datenum(date_interval(2)));
for i=start_indx+1:end_indx
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
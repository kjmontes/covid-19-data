date_interval = {'01-Jun-2020','11-July-2020'};
states = {'Florida'};
counties = {'Alachua','Brevard','Broward','Duval','Miami-Dade','Orange','Palm Beach'};
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

[X.cases.quant_to_plot,X.cases.info] = get_daily_new_cases(cases,5);
[X.deaths.quant_to_plot,X.deaths.info] = get_daily_new_cases(deaths,5);
X.cases.info.cbar_label = ['% Daily Change in Cases'];%[5-day Moving Avg.]'];
X.deaths.info.cbar_label = ['% Daily Change in Deaths'];% [5-day Moving Avg.]'];

%% Get cases per capita for counties of interest
population = extractfield(county_shapes,'POPULATION');
county_names = extractfield(county_shapes,'NAME');
ii = cellfun(@(x) strcmp(x,counties),county_names,'UniformOutput',false);
chosen = find(cellfun(@(x) any(x),ii)); % find indices of chosen counties
X.cases.per_person = cases./repmat(population,D,1)*1e3; % per thousand
X.deaths.per_person = deaths./repmat(population,D,1)*1e3; % per thousand
metric = fieldnames(X);
for i=1:length(metric)
    figure(); plot(repmat(unique_dates,1,length(chosen)),X.(metric{i}).per_person(:,chosen))
    xlim([datenum(date_interval{1}) datenum(date_interval{2})])
    ax = gca()
    ax.XTickLabel = cellfun(@(x) datestr(x,'mm/dd'),num2cell(ax.XTick),'UniformOutput',false)
    title(metric{i})
    X.(metric{i}).ylims = ax.YLim;
    legend(ax,county_names(chosen),'Location','Northwest')
end

%% Generate figure and set properties
disp('Generating figure ...')
fig = figure('OuterPosition',[0.062,0.062,0.875,0.925], ...
    'InnerPosition',[0.0677,0.0722,0.8635,0.8037],'Units',...
    'normalized','Position',[0.0677,0.0722,0.8635,0.8037]);

h11 = subplot(2,2,1);
X.cases.ax_map = usamap(states);
set(X.cases.ax_map,'Position',get(h11,'Position'));
X.cases.ax_plot = subplot(2,2,2);
ylabel(X.cases.ax_plot,'Cases per 1,000 People','FontSize',10);

h22 = subplot(2,2,3);
X.deaths.ax_map = usamap(states);
set(X.deaths.ax_map,'Position',get(h22,'Position'));
X.deaths.ax_plot = subplot(2,2,4);
xlabel(X.deaths.ax_plot, 'Date');
ylabel(X.deaths.ax_plot, 'Deaths per 1,000 People','FontSize',10);

X.cases.ax_map.Position = X.cases.ax_map.Position + [-0.05, -0.05, 0.1, 0.1];
X.deaths.ax_map.Position = X.deaths.ax_map.Position + [-0.05, -0.05, 0.1, 0.1];

%% Plot colormap for day 1
disp('Plotting day 1 ...')
% Plot county boundaries, each colored according to case count, for day 1
start_indx = find(unique_dates==datenum(date_interval(1)));
end_indx = find(unique_dates==datenum(date_interval(2)));

% If region borders the Great Lakes, load the lake data and omit from plot
near_lakes = {'Michigan','Ohio','New York','Indiana','Illinois', ...
    'Wisconsin','Pennsylvania','Minnesota','conus'};
if any(cellfun(@(x) any(strcmp(x,near_lakes)),states))
    load greatlakes;
    % Get county shapes and subselect data of interest
    [gtlakes, spec] = updategeostruct(greatlakes, white(3*numel(greatlakes)));
end
sgt = sgtitle(fig,['Date: ' datestr(unique_dates(start_indx), 'mmm.dd,yyyy')]);

metric = fieldnames(X);
for i=1:length(metric)
    info = X.(metric{i}).info;
    quant_to_plot = X.(metric{i}).quant_to_plot;
    ax_map = X.(metric{i}).ax_map;
    ax_plot = X.(metric{i}).ax_plot;
    
    % Make map axis more plot-friendly
    disp(['Calculated ' info.cbar_label])
    cmap = info.color_map(length(info.quant_scale));
    ax_map.CLim = [info.min_limit,info.max_limit];
    ax_map.ColorScale = info.scale_type;
    ax_map.Colormap = cmap;

    colorIndx = get_colorIndx(quant_to_plot(start_indx,:), ...
        info.quant_scale,info.scale_type);
    faceColors = makesymbolspec('Polygon',{'INDEX', [1 C], ...
            'FaceColor',cmap(colorIndx',:)});
    X.(metric{i}).G = geoshow(ax_map, county_shapes, ...
        'DisplayType', 'polygon', 'SymbolSpec', faceColors);
    setm(ax_map,'Frame','off','Grid','off','MeridianLabel','off', ...
        'ParallelLabel','off');
    %framem off; gridm off; mlabel off; plabel off;

    % If region borders the Great Lakes, load the lake data and omit from plot
    if any(cellfun(@(x) any(strcmp(x,near_lakes)),states))
        hold on; Lakes = geoshow(gtlakes, 'SymbolSpec', spec); hold off
    end

    % Include colorbar and text insert with the date
%     X.(metric{i}).date_label = text(ax_map,0.5,0.9, ...
%         ['Date: ' datestr(unique_dates(start_indx), 'mmm.dd,yyyy')], ...
%         'HorizontalAlignment','center','Units','normalized');
    txt = metric{i}; ii = regexp([' ' txt],'(?<=\s+)\S','start')-1;
    txt(ii) = upper(txt(ii));
    text(ax_map,0.5,0.9,txt,'HorizontalAlignment','center',...
        'Units','normalized');
    
    cbar = colorbar(ax_map);
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
    
    % Plot cases per capita
    hold(X.(metric{i}).ax_plot,'on')
    for k=1:length(chosen) % loop through chosen counties
        y = NaN(size(unique_dates));
        indx = start_indx:start_indx+1;
        y(indx) = X.(metric{i}).per_person(indx,chosen(k));
        X.(metric{i}).(['plot_obj' num2str(k)]) = ...
            plot(X.(metric{i}).ax_plot, unique_dates, y, ...
            'DisplayName',county_names{chosen(k)});
    end
    hold(X.(metric{i}).ax_plot,'off')
    
%     X.(metric{i}).line_obj = plot(X.(metric{i}).ax_plot, ...
%         repmat(unique_dates,1,length(chosen)), ...
%         X.(metric{i}).YData);
        
    % Make plot axis more plot-friendly
    X.(metric{i}).ax_plot.XLim = [unique_dates(start_indx) unique_dates(end_indx)];
    X.(metric{i}).ax_plot.YLim = X.(metric{i}).ylims;
    X.(metric{i}).ax_plot.XTickLabel = cellfun(@(x) datestr(x,'mm/dd'), ...
        num2cell(X.(metric{i}).ax_plot.XTick),'UniformOutput',false);
end

legend(X.cases.ax_plot,county_names(chosen),'NumColumns',2, ...
    'Location','Northwest')

%% Plot colormap for day 2->N
% Continue with the rest of the dates, updating each county's color
disp('Plotting the rest ...')
video_name = ['cases_vs_deaths_' strjoin(states,'_') '.mp4'];
video_type = 'MPEG-4';
video = VideoWriter(video_name,video_type);
video.FrameRate = 6;
open(video)

for i=start_indx+1:end_indx
    for j=1:length(metric)
        % Update color indices according to the day's case count
        colorIndx = get_colorIndx(X.(metric{j}).quant_to_plot(i,:), ...
            X.(metric{j}).info.quant_scale,X.(metric{j}).info.scale_type);
        cmap = X.(metric{j}).ax_map.Colormap;
        new_cmap = cmap(colorIndx',:); % new colors for day i
        cmap_array = mat2cell(new_cmap,ones(1,C)); % convert to cell array 

        % Plot new county colors and new date label
        set(X.(metric{j}).G.Children,{'FaceColor'},cmap_array) % change colors
        
        % Update cases per capita
        %X.(metric{j}).YData(start_indx:i,:) = X.(metric{j}).per_person( ...
        %    start_indx:i,chosen);
        for k=1:length(chosen)
            X.(metric{j}).(['plot_obj' num2str(k)]).YData(start_indx:i) = ...
                X.(metric{j}).per_person(start_indx:i,chosen(k));
            refreshdata(X.(metric{j}).(['plot_obj' num2str(k)]));
        end
        
        % Update the date label
%         X.(metric{j}).date_label.String = ['Date: ', ...
%             datestr(unique_dates(i),'mmm.dd,yyyy')];
        sgt.String = ['Date: ', ...
            datestr(unique_dates(i),'mmm.dd,yyyy')];
    end
    writeVideo(video,getframe(fig)); % add frame to video structure
end

close(video)
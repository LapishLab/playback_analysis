clear
file = 'UVS-Schedule.xlsx'; % give full path to the excel sheet or have in your current directory

%% %%%%% Read data from Bao's excel  sheet %%%%%%%%%%
rat_info = readtable(file, Sheet='rat_info');

consumed = read_sheet(file, 'consumed', 'C2', 'C3');
consumed = convertvars(consumed, consumed.Properties.VariableNames, 'double');

audio = read_sheet(file, 'audio_files', 'B2', 'B3');
audio.Properties.RowNames = audio.Cohort;
audio.Cohort = [];
audio = audio(rat_info.Cohort,:); % reshape into same size as consumed
%% %%%%%%%%% Per Day %%%%%%%%%%%%
% Plot mean ethanol consumed for each group and average (single plot)
figure(1); clf; hold on;

plot_group_mean(consumed, rat_info.Cohort, 'HM')
plot_group_mean(consumed, rat_info.Cohort, 'HF')
plot_group_mean(consumed, rat_info.Cohort, 'PM')
plot_group_mean(consumed, rat_info.Cohort, 'PF')

x= 1:width(consumed);
shadedErrorBar(x, consumed{:,:}, {@nan_mean, @sem}, 'lineProps',{'o-k', 'LineWidth', 3,  'DisplayName', 'Avg'})

legend()
xlabel('Day')
ylabel('Ethanol consumed (mg/kg)')
ylim([0, max(ylim())])
title('By Day')
exportgraphics(gcf,'by_day.png');
%% %%%%%%%%% Per audio condition %%%%%%%%%%%%
% resort consumed by audio condition
[B,c_ind] = sort(audio{:,:},2);
r_ind = repmat(1:height(audio), width(audio),1)';
lin_ind = sub2ind(size(audio), r_ind, c_ind);

audio_consumed = consumed{:,:};
audio_consumed = audio_consumed(lin_ind);
audio_consumed = array2table(audio_consumed);
audio_consumed.Properties.VariableNames = B(1,:);
audio_consumed.Properties.RowNames = audio.Properties.RowNames;
audio_consumed = audio_consumed(:, {'none1','none2','noise','happy','sad'}); %reorder

% Plot mean ethanol consumed for each group and average (single plot) 
figure(2); clf; hold on;
plot_group_mean(audio_consumed, rat_info.Cohort, 'HM')
plot_group_mean(audio_consumed, rat_info.Cohort, 'HF')
plot_group_mean(audio_consumed, rat_info.Cohort, 'PM')
plot_group_mean(audio_consumed, rat_info.Cohort, 'PF')

x=1:width(audio_consumed);
shadedErrorBar(x, audio_consumed{:,:}, {@nan_mean, @sem}, 'lineProps',{'o-k', 'LineWidth', 3,  'DisplayName', 'Avg'})

legend()
xticks(x)
xticklabels(audio_consumed.Properties.VariableNames)

ylabel('Ethanol consumed (mg/kg)')
ylim([0, max(ylim())])
title('By Audio Type')

exportgraphics(gcf,'by_audio.png');
%% %%%%%%% Drinking relative to none2 %%%%%%%%%%%%%%%%
rel_none = audio_consumed(:, {'noise','happy','sad'}) ./ audio_consumed{:, 'none2'} ;
rel_none = standardizeMissing(rel_none, inf); % remove inf from dividing by 0

figure(3); clf; hold on;
plot_group_mean(rel_none, rat_info.Cohort, 'HM')
plot_group_mean(rel_none, rat_info.Cohort, 'HF')
plot_group_mean(rel_none, rat_info.Cohort, 'PM')
plot_group_mean(rel_none, rat_info.Cohort, 'PF')
x= 1:width(rel_none);
shadedErrorBar(x, rel_none{:,:}, {@nan_mean, @sem}, 'lineProps',{'o-k', 'LineWidth', 3,  'DisplayName', 'Avg'})
yline(1, '--', 'HandleVisibility', 'off')

legend()
xticks(x)
xticklabels(rel_none.Properties.VariableNames)

ylabel('Ethanol consumed (relative to no audio)')
ylim([0, max(ylim())])
title('Relative to none2 (Tuesday)')
exportgraphics(gcf,'none_relative.png');
%% %%%%%%% Drinking relative to noise %%%%%%%%%%%%%%%
rel_noise = audio_consumed(:, {'happy','sad'}) ./ audio_consumed{:, 'noise'} ;
rel_noise = standardizeMissing(rel_noise, inf); % remove inf from dividing by 0

figure(4); clf; hold on;
plot_group_mean(rel_noise, rat_info.Cohort, 'HM')
plot_group_mean(rel_noise, rat_info.Cohort, 'HF')
plot_group_mean(rel_noise, rat_info.Cohort, 'PM')
plot_group_mean(rel_noise, rat_info.Cohort, 'PF')
x= 1:width(rel_noise);
shadedErrorBar(x, rel_noise{:,:}, {@nan_mean, @sem}, 'lineProps',{'o-k', 'LineWidth', 3,  'DisplayName', 'Avg'})
yline(1, '--', 'HandleVisibility', 'off')

legend()
xticks(x)
xticklabels(rel_noise.Properties.VariableNames)

ylabel('Ethanol consumed (relative to noise)')
ylim([0, max(ylim())])
xlim()
title('Relative to Noise')
exportgraphics(gcf,'noise_relative.png');
%% %%%%%%%%%%%%%% functions %%%%%%%%%%%%%%%%%%%%%%%%%
function plot_group_mean(y, groups, label)
    x= 1:width(y);
    g = contains(groups,label);
    y = y{g,:};
    shadedErrorBar(x, y, {@nan_mean, @sem}, 'lineProps',{ ...
        '.-', ...
        'MarkerSize', 20, ...
        'DisplayName', label ...
        })
    xmargin = .2;
    xlim([x(1)-xmargin x(end)+xmargin])
end
function t = read_sheet(file, sheet, header_start, data_start)
    opts = detectImportOptions(file);
    opts.VariableNamesRange=header_start;
    opts.DataRange=data_start;
    for i = 1:numel(opts.VariableNames)
        opts = setvartype(opts, opts.VariableNames{i}, 'string'); 
    end
    t = readtable(file, opts, Sheet=sheet);

    empty_column = contains(t.Properties.VariableNames, 'Var') & all(ismissing(t));
    t(:, empty_column) = [];
end
function err = sem(y)
    err = std(y,0,1,"omitmissing") / sqrt(height(y));
end
function avg = nan_mean(y)
    avg = mean(y,1,"omitmissing");
end
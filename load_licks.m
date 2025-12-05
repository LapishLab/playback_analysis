function licks = load_licks(excel_sheet, med_folder)
    session_folders = string({dir(fullfile(med_folder, 'med-pc_2025*')).name})';
    rat_info = readtable(excel_sheet, Sheet='rat_info');
    
    exp_dates = read_sheet(excel_sheet, 'audio_files', 'C2', 'C1');
    exp_dates = datetime(exp_dates{1,:});
    
    %% get datetime
    tokens = regexp(session_folders, '\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}', 'match');
    dt = datetime(string(tokens), 'InputFormat', 'yyyy-MM-dd_HH-mm-ss');
    
    %% get group
    group = string(regexp(session_folders, 'group(\d+)', 'tokens'));
    
    %% loop through and load individual files  
    all_med = cell(size(group));
    for s = 1:length(session_folders)
        subfolder = fullfile(med_folder, session_folders(s));
        fnames = string({dir(fullfile(subfolder, '*Subject*.txt')).name});
        f_paths = fullfile(subfolder,fnames)';
    
        sessions = cell(size(f_paths));
        for f = 1:length(f_paths)
            med = importMA(f_paths(f), remove_trailing_zeros = true);
            med.date = dt(s);
            med.group = double(group(s));
            sessions{f} = med;
        end
        all_med{s} = cat(1, sessions{:});
    end
    all_med = cat(1, all_med{:});
    all_med = struct2table(all_med);
    
    %Temporary fix for messed up med file. Better to extract subject from
    %filename and detect error at that point. Or, I need to do more checking
    %here (iscell, then does have empty, then replace with nan)
    all_med.Subject{cellfun(@isempty, all_med.Subject)} = nan;
    all_med.Subject = cell2mat(all_med.Subject);
    %%
    licks = cell(height(rat_info), length(exp_dates));
    for r = 1:height(rat_info)
        for c = 1:length(exp_dates)
            is_group = rat_info.Group(r)==all_med.group;
            is_box = rat_info.Box(r)==all_med.Subject;
            is_day = day(exp_dates(c)) == day(all_med.date); %TODO: change to comparing date, not day of week
            match = is_group & is_box & is_day;
    
            if sum(match) == 0
                warning('missing med file for ...');
                licks{r,c} = nan;
            elseif sum(match) > 1
                warning('Too many matching med files for ...')
                licks{r,c} = nan;
            elseif sum(match) == 1
                licks{r,c} = all_med.E{match}; % pick the left lick array
            end
        end  
    end
end
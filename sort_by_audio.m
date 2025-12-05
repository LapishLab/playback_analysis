function audio_data = sort_by_audio(audio, data)
    [B,c_ind] = sort(audio{:,:},2);
    r_ind = repmat(1:height(audio), width(audio),1)';
    lin_ind = sub2ind(size(audio), r_ind, c_ind);
    
    if istable(data)
        audio_data = data{:,:};
    elseif iscell(data)
        audio_data = data;
    end
    audio_data = audio_data(lin_ind);
    audio_data = array2table(audio_data);
    audio_data.Properties.VariableNames = B(1,:);
    audio_data.Properties.RowNames = audio.Properties.RowNames;
    audio_data = audio_data(:, {'none1','none2','noise','happy','sad'}); %reorder
end
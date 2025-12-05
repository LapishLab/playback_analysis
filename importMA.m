function output = importMA(filename, opts)
% Parse a single MedAssoc file and return a struct
    arguments
        filename {mustBeText} % path to med associates text file
        opts.remove_trailing_zeros logical = false % optional: strip trailing zeros from arrays
        opts.convert_to_number logical = true % optional: Try to convert strings to numbers
    end

    %% Open file and read contents into character array
    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open file: %s', filename);
    end

    char_arr = fread(fid, '*char')';
    fclose(fid); % Close the file

    %% Each array has fieldname and data split by "letter:whitespace"
    % This splitting index is the start of the array's data
    data_start_ind = regexp(char_arr, '[a-zA-Z]:\s') + 1;
    num_arrays = length(data_start_ind);

    %% Find the fieldname start index by moving backwards to the most
    % recent newline (or file start for the first array)
    field_start_ind = ones(size(data_start_ind));
    for i=2:num_arrays
        sub_c = char_arr(1:data_start_ind(i));
        field_start_ind(i) = max(regexp(sub_c, "[\r?\n]"));
    end

    %% The data stop index is the start of the next fieldname or the
    % end of the file for the last array.
    data_stop_ind = [field_start_ind(2:end), length(char_arr)];

    %% pull and clean each array and put in struct
    output = struct();
    for i=1:num_arrays
        % Pull out fieldname and data value using start/stop indices
        field = char_arr( field_start_ind(i) : data_start_ind(i) );
        data = char_arr( data_start_ind(i) : data_stop_ind(i) );

        % clean up field name
        field = strip(field, ":");
        field = strip(field);
        field = replace(field, " ", "_");

        % clean up data
        data = strip(data, ":");
        data = strip(data, "right"); % Don't strip left newlines. I use those to determine if multiline array

        % Format multiline data into a single array
        if ~isempty((regexp(data, '[\n\r]')))
            data = convertCharsToStrings(data); % easier to display strings
            data = split(data); % split by spaces
            data = data(~contains(data, ":")); % remove index values 
            data = strip(data); % I may be stripping more than needed
            data = data(data ~= ""); % remove any empty values
        end
        data = strip(data); % clean any remaining whitespace (just to be safe)
        
        % convert data to number if requested
        if opts.convert_to_number
            data = try_number_conversion(data);
        end

        % remove trailing zeros if requested
        if opts.remove_trailing_zeros & isnumeric(data) & length(data)>1
            data = strip_trailing_zeros(data);
        end

        % Check that this field isn't already in the output struct
        if isfield(field, output)
            error(['Field "%s" is repeated.' ...
                'Was this file merged across subjects?' ...
                ' If so, split the file by subject and' ...
                ' rerun this function'], field);
        end

        % save this array to the output struct
        output.(field) = data;    
    end
end

function data = try_number_conversion(data)
    data_num = str2double(data);
    if any(~isnan(data_num))
        data = data_num;
    end
end

function arr = strip_trailing_zeros(arr)
    % Find the index of the last non-zero element
    lastNonZeroIndex = find(arr,1,'last');
    if ~isempty(lastNonZeroIndex)
        % return array truncated to last nonzero element
        arr = arr(1:lastNonZeroIndex);
    else
        % All values are zero
        arr = []; 
    end
end
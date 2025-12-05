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
function DataPrint(comparison_struct, diag_struct, table_name, compare_3_way, diag_print_to_table, ...
    comp_print_to_table , diagnosis, comparisons, polarization_names_full, directory)
%DataPrint Function which prints out the tables inputted into a csv
%   Detailed explanation goes here

comparison_table = table();

table_height = length(comparison_struct.(comparisons{1}).(comp_print_to_table{1}));

for i = 1:length(compare_3_way);
    compare3_str = char(compare_3_way(i));
    data = zeros(3,table_height);
    middle_names = cell(table_height,1);
    for j = 1:3;
        data(j,:) = diag_struct.(char(diagnosis(j))).(compare3_str);
    end
    for k = 1:table_height
        [~, indicies] = sort(data(:,k));
        middle_names(k,1) = diagnosis(indicies(2));
    end
    comparison_table.(['middle_',compare3_str]) = middle_names;
end

for j = 1:length(comparisons);
    comp = char(comparisons(j));
    for i = 1:length(comp_print_to_table);
        comp_val = char(comp_print_to_table(i));
        name = [comp, '_', comp_val];
        comparison_table.(name) = comparison_struct.(comp).(comp_val);
    end
end

for i = 1:length(diag_print_to_table)
    diag_val = char(diag_print_to_table(i));
    for j = 1:length(diagnosis)
        diag = char(diagnosis(j));
        name = [diag, '_', diag_val];
        comparison_table.(name) = diag_struct.(diag).(diag_val);
    end
end

comparison_table.Properties.RowNames = polarization_names_full;

writetable(comparison_table, [directory, '\Comparison_Table_',table_name, datestr(now, 'yy-mm-dd-HH-MM-SS'), '.xlsx'],'WriteRowNames',true)

end


function DataPrint(comparison_struct, diag_struct, table_name, compare_all_way, diag_print_to_table, ...
    comp_print_to_table , diagnosis, properties_structure, directory, ANOVA)
%DataPrint Function which prints out the tables inputted into a csv
%   Detailed explanation goes here

comparison_table = table();

table_height = length(comparison_struct(1).(comp_print_to_table{1}));

for i = 1:length(compare_all_way);
    compareall_str = char(compare_all_way(i));
    data = zeros(length(diagnosis),table_height);
    middle_names = cell(table_height,1);
    for j = 1:3;
        data(j,:) = diag_struct(j).(compareall_str);
    end
    for k = 1:table_height
        [~, indicies] = sort(data(:,k));
        middle_names(k,1) = diagnosis(indicies(ceil(length(diagnosis)/2)));
    end
    comparison_table.(['middle_',compareall_str]) = middle_names;
end

comparison_table.ANOVA_all_way = ANOVA';

for j = 1:length(comparison_struct);
    comp = char(comparison_struct(j).name);
    for i = 1:length(comp_print_to_table);
        comp_val = char(comp_print_to_table(i));
        name = [comp, '_', comp_val];
        comparison_table.(name) = comparison_struct(j).(comp_val);
    end
end

for i = 1:length(diag_print_to_table)
    diag_val = char(diag_print_to_table(i));
    for j = 1:length(diagnosis)
        diag = char(diagnosis(j));
        name = [diag, '_', diag_val];
        comparison_table.(name) = diag_struct(j).(diag_val);
    end
end


element_type = cell(length(properties_structure),1);
element_type([properties_structure(:).is_deposit]) = {'Deposit'};
element_type(~[properties_structure(:).is_deposit]) = {'Background'};

comparison_table.is_deposit = element_type;

comparison_table.Properties.RowNames = {properties_structure(:).name};

comparison_table = sortrows(comparison_table,'is_deposit');

writetable(comparison_table, [directory, '\Comparison_Table_',table_name, datestr(now, 'yy-mm-dd-HH-MM-SS'), '.xlsx'],'WriteRowNames',true)

end


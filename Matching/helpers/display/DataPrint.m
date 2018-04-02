function[dbts] =  DataPrint(dbts, diagnosis_type, comparison_struct, diag_struct, table_name, compare_all_way, diag_print_to_table, ...
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

% If you get an error here, it is likely a name length error
writetable(comparison_table, [directory, '\Comparison_',table_name, datestr(now, 'yy-mm-dd-HH-MM-SS'), '.xlsx'],'WriteRowNames',true)


%% Here we also print out a summary of the subjects which are used
dbt_s = table();
for i = 1:length(dbts);
    [~, unique_indicies] = unique(dbts(i).table.SubjectIdx);
    subject_table_full = dbts(i).table(unique_indicies,:);
    
    %Subject data fields we wish to print out
    sample_index_low = find(strcmpi(subject_table_full.Properties.VariableNames,'SubjectId'));
    sample_index_high = find(strcmpi(subject_table_full.Properties.VariableNames,'SubjectNotes'));
    sample_index_diagnosis = find(strcmpi(subject_table_full.Properties.VariableNames, diagnosis_type));
    
    subject_table = subject_table_full(:,[sample_index_diagnosis, 1, sample_index_low:sample_index_high]);
    subjects_number = height(subject_table);
    subject_counts = deal(zeros(subjects_number, 1));
    for j = 1:subjects_number;
        Subject_Index = subject_table.SubjectIdx(j);
        subject_deposits = dbts(i).table(dbts(i).table.SubjectIdx == Subject_Index, :);
        subject_counts(j) = height(subject_deposits);
    end
    subject_table.deposits_used = subject_counts;
    subject_table = subject_table(:,[1,width(subject_table), 2:width(subject_table)-1]);
    dbts(i).subject_table_full = subject_table_full;
    dbts(i).subject_table = subject_table;
    dbt_s = [dbt_s; subject_table];
end

writetable(dbt_s, [directory, '\Subjects_',table_name, '.xlsx'],'WriteRowNames',true)

end
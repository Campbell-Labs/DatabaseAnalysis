load('Database Tables (Animal Ex Vivo - Generated 28-Sep-2017).mat')

%%%%%%%USER ENTRY%%%%%%%%%
nameAD = {'Chris','Kurt'};
namePosCon = {'Tanner', 'Camille'};
nameCon = {'Gertrude','Julius'};

indexAD{1} = [1,2,3,4,5,6,8,9,10,11,12,13,14,15,16];
indexAD{2} = [1,2,4,5,6,7,8,9,10,11,12,13,14,15,16,17,19,20,21,22,23,26,27,28];

indexPosCon{1} = [19,15,16,7,14,18,20,6,21,17,10,9,5,12,8];
indexPosCon{2} = [24,19,14,12,9,18,17,16,7,11,2,1,5,6,23,13,22,20,10,8,15,3,21,4];

indexCon{1} = [4,5,3,1,2,10,8,6,7,16,15,13,14,12,11];
indexCon{2} = [25,24,20,21,26,22,27,23,28,10,11,12,9,8,7,6,14,15,16,17,18,3,2,1];

diag_print_to_table = {'mean', 'median', 'std', 'values'};
comp_print_to_table = {'h','p','normal'};

%%%%%%%USER ENTRY ENDS%%%%%%%%%


% Finding how many deposits are being compared for later analysis
indicies_sum = 0;
for i = 1:length(indexAD)
    indicies_sum = indicies_sum + length(indexAD{i});
end

dbts = FilterData( dbt, nameAD, namePosCon, nameCon, indexAD, indexPosCon, indexCon);

column_names = dbts.('AD').Properties.VariableNames;
pol_prop = ~cellfun(@isempty,regexp(column_names,'(Deposit|Background)\w+')); % should check if start of string too
polarization_properties = column_names(pol_prop);
% We now have three databases which contain the loction matched deposits
%polarization_properties = [column_names(pol_prop); [...% List of polarizatioin properties to compare btw subjects
%    ];

% This section is just some uninteresting data management, creating the
% data structures and initalizing arrays for all of them
table_height = length(polarization_properties);
diagnosis = {'AD','PC','C'};
properties = {'mean', 'median', 'std', 'values', 'props'};

comparisons = {'ADvPC', 'ADvC', 'PCvC'};
comparing = {{'AD','PC'},{'AD','C'},{'PC','C'}};
comparisons_values = {'p', 'h', 'normal'};

%Just initalizing structres and arrays of zeros
for j = 1:length(diagnosis);
    diag_struct.(char(diagnosis(j))) = struct();
    for i = 1:length(properties);
        if strcmp(properties(i), 'values'); dealer = cell(table_height,1);
        elseif strcmp(properties(i), 'props'); dealer = zeros(table_height,indicies_sum);
        else dealer = zeros(table_height,1);
        end
        diag_struct.(char(diagnosis(j))).(char(properties(i))) = deal(dealer);
    end
end

for j = 1:length(comparisons)
     comparison_struct.(char(comparisons(j))) = struct();
     for i = 1:length(comparisons_values);
        comparison_struct.(char(comparisons(j))).(char(comparisons_values(i))) =  deal(zeros(table_height,1));
     end
     comparison_struct.(char(comparisons(j))).('comparing') = comparing{j};
end

% This just pushes the data which was in structures into analysis and
% saves them back into structures. It looks a bit messy but means its very
% simple to add in new calculations and print them out if needs be.
for index = 1:table_height;
    polarization_property = char(polarization_properties(index));
    for dig_index = 1:length(diagnosis);
        diagnosis_str = char(diagnosis(dig_index));
        data = dbts.(diagnosis_str).(polarization_property);
        diag_struct.(diagnosis_str).('prop')(index,:) = data;
        diag_struct.(diagnosis_str).('mean')(index) = mean(data);
        diag_struct.(diagnosis_str).('median')(index) = median(data);
        diag_struct.(diagnosis_str).('std')(index) = std(data);
        diag_struct.(diagnosis_str).('values')(index) = num2cell(data,1);
        % Here the calculations of the properties based off of diagnosis
        % sorted data is done, like the mean value of the AD deposits
    end
    for comp_index = 1:length(comparisons)
        comparison = char(comparisons(comp_index));
        for i = 1:length(comparisons_values);
            prop_1 = diag_struct.(comparison_struct.(comparison).comparing{1}).prop(index,:);
            prop_2 = diag_struct.(comparison_struct.(comparison).comparing{2}).prop(index,:);
            [comparison_struct.(comparison).h(index), ... 
             comparison_struct.(comparison).p(index), ... 
             comparison_struct.(comparison).normal(index)...
             ] = CompareData(prop_1, prop_2, 1);
            % Here are the calculations for comparing data sets lie. Right
            % now all that is done is to run the compare data function
        end
    end
end
comparison_table = table();

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

comparison_table.Properties.RowNames = polarization_properties;

writetable(comparison_table, ['Comparison_Table_', strrep(datestr(now),':','_'), '.csv'],'WriteRowNames',true)



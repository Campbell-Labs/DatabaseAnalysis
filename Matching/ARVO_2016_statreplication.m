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
comp_print_to_table = {'h_paired','p_paired','normal_paired',...
    'h_unpaired','p_unpaired','normal_unpaired',...
    'p_ANOVA'...
    };

pre_match = '(?:Deposit|Background|FullImage)';
post_match = '(Mean|Size)';

diagnosis = {'AD', 'PC', 'C' }; % Note that the third property is always the ratioed property

compare_3_way = {'median'};

%%%%%%%USER ENTRY ENDS%%%%%%%%%

% Finding how many deposits are being compared for later analysis
num_of_deposits = 0;
for i = 1:length(indexAD)
    num_of_deposits = num_of_deposits + length(indexAD{i});
end
load('Database Table (Animal Ex Vivo SubSection - Generated 11-Nov-2017)')
table_name = 'Subsection';

dbts = FilterData( dbt, diagnosis, nameAD, namePosCon, nameCon, indexAD, indexPosCon, indexCon);

[comparison_struct, diag_struct, comparisons, polarization_names_full] = ...
    DepositCompare( dbts, num_of_deposits, diagnosis, pre_match, post_match, comp_print_to_table, false);

DataPrint(comparison_struct, diag_struct, table_name, compare_3_way, diag_print_to_table, comp_print_to_table ,diagnosis, comparisons, polarization_names_full) 

load('Database Tables (Animal Ex Vivo - Generated 28-Sep-2017)')
table_name = 'FullData';

dbts = FilterData( dbt, diagnosis, nameAD, namePosCon, nameCon, indexAD, indexPosCon, indexCon);

[comparison_struct, diag_struct, comparisons, polarization_names_full] = ...
    DepositCompare( dbts, num_of_deposits, diagnosis, pre_match, post_match, comp_print_to_table, false);

DataPrint(comparison_struct, diag_struct, table_name, compare_3_way, diag_print_to_table, comp_print_to_table ,diagnosis, comparisons, polarization_names_full) 
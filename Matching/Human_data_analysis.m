addpath(genpath('helpers'))

load(fullfile(pwd,'database_tables','Human Ex Vivo - Database Table (Generated 18-02-13)'))

dbt_s = dbt(dbt.IsNewSubject,:);
dbt_e = dbt(dbt.IsNewEye,:);
dbt_q = dbt(dbt.IsNewQuarter,:);

%% First just reducing the databases to only include VA subjects
VA_regex = ['VA', '.*'];

all_subjects = cellstr(dbt_s.SubjectId);

[dbt_VA_s, VA_s_bool] = match_table_regex(dbt_s, VA_regex ,'SubjectId');
dbt_VA_e = match_table_regex(dbt_e, VA_regex ,'SubjectId');
dbt_VA_q = match_table_regex(dbt_q, VA_regex ,'SubjectId');
dbt_VA = match_table_regex(dbt, VA_regex ,'SubjectId');

VA_subjects = all_subjects(VA_s_bool); % This just gives is only the VA subject names

%% User entry

table_name = 'post_AAIC_data_';

% These should correlate with High, Intermediate, Low and None

diagnosis = {'HIGH', 'INT', 'LOW', 'NONE' }; % Note that the third property is always the ratioed property

pre_match = '(?:Deposit|Background)';

post_match = '(Mean|Size)';

match_properties = {'Diattenuation_Circ','DP_','Psi', 'Retardance_Circ',...
'Polarizance_Circ','Polarizance_Lin'};

diag_print_to_table = {'mean', 'median', 'std', 'data'};
comp_print_to_table = {'h_paired','p_paired','normal_paired',...
    'h_unpaired','p_unpaired','normal_unpaired',...
    'p_ANOVA'...
    };

compare_all_way = {'median'};

%% Management
mid_match = ['.*(',match_properties{1}];
for i = 2:length(match_properties)
    mid_match = [mid_match,'|', match_properties{i}];
end
mid_match = [mid_match,')'];
% 
% post_match = [mid_match,'.*', end_match];

% %% Reject some garbage data
% reject_bool = dbt_VA.SubjectId == 'VA15-14' ;
% dbt_VA(reject_bool,:).SessionRejected = categorical(ones(sum(reject_bool),1));

%% Unrejecting Subject with only dust and particulate measured, for
% background images, since we can segment this out, low deposits will not
% be accurate though
un_reject_bool = dbt_VA.SubjectId == 'VA14-105';
dbt_VA(un_reject_bool,:).SessionRejected = categorical(zeros(sum(un_reject_bool),1));
% 
% %% Changing diagnoisis of subject which was improperly labelled on import 
% % Pretty messy, but converting in and out of categorical seems non-trivial
% mislabelled_diagnosis_bool = ...dbt_VA.SubjectId == 'VA12-55';
% (dbt_VA.SubjectId == 'VA12-55' | dbt_VA.SubjectId == 'VA15-41'); %rename
% %low or none too?
% replace_array = categorical(zeros(sum(mislabelled_diagnosis_bool),1), [0, 1, 2, 3,4], categories(dbt_VA.Likelihood_of_AD), 'Ordinal', true);
% replace_array(:) = 'low';
% dbt_VA(mislabelled_diagnosis_bool,:).Likelihood_of_AD = replace_array;
%% Here I will split up the three groups
all_subjects = cellstr(dbt_s.SubjectId);


dbt_VA = dbt_VA(dbt_VA.SessionRejected == '0', :); % Dont know how to convert out of categorical data
%dbt_VA = dbt_VA(dbt_VA.QuarterArbitrary == '0', :);
dbt_VA = dbt_VA(dbt_VA.IsProcessed, :);

dbt_VA_HI = match_table_regex(dbt_VA, ['high', '.*'] , 'Likelihood_of_AD');
dbt_VA_INT = match_table_regex(dbt_VA, ['intermediate', '.*'] , 'Likelihood_of_AD');
dbt_VA_LO = match_table_regex(dbt_VA, ['low', '.*'] , 'Likelihood_of_AD');
dbt_VA_NONE = match_table_regex(dbt_VA, ['none', '.*'] , 'Likelihood_of_AD');

dbt_VA_HI = match_table_regex(dbt_VA_HI, 'Good' ,'SegmentationQuality');
dbt_VA_INT = match_table_regex(dbt_VA_INT, 'Good' ,'SegmentationQuality');

%dbt_VA_INT = dbt_VA_INT(logical(dbt_VA_INT.DepositSize > 500), :);

%dbt_VA_HI = dbt_VA_HI(logical(dbt_VA_HI.SubjectIdx > 30), :);

dbt_VA_HI = match_table_regex(dbt_VA_HI, 'Erik''s Program' ,'RegistrationType');
dbt_VA_INT = match_table_regex(dbt_VA_INT, 'Erik''s Program' ,'RegistrationType');

% % This is the section to limit only to after the automatic stage
% dbt_VA_HI = dbt_VA_HI(dbt_VA_HI.SubjectIdx >30, :);
% dbt_VA_INT = dbt_VA_INT(dbt_VA_INT.SubjectIdx >30, :);

%% Here I will match the locations of the deposits to send to DataCompare
tables = {dbt_VA_HI, dbt_VA_INT, dbt_VA_LO, dbt_VA_NONE};
[pairing_list, paired_tables] = pairing_function(diagnosis, tables);

%% Values now are paired as stated in paired list
dbts = struct('name', diagnosis, 'table', paired_tables);

%% Print Data
num_of_deposits = length(pairing_list(:,1));

polarization_properties = column_names(~cellfun(@isempty,regexp(column_names, [pre_match,'.*',mid_match ,'.*', post_match])));
close all

out_path = DataGraph(dbts, diagnosis, polarization_properties, pre_match);

[comparison_struct, diag_struct, polarization_names_full, p_ANOVA_all] = ...
    DepositCompare( dbts, num_of_deposits, diagnosis, pre_match, post_match, comp_print_to_table, mid_match,out_path);

DataPrint(comparison_struct, diag_struct, table_name, compare_all_way, diag_print_to_table, comp_print_to_table ,diagnosis, polarization_names_full, out_path, p_ANOVA_all) 

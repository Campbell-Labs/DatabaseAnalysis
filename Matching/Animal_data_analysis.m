%% User Entry Section
%Choose your database file
load(fullfile(pwd,'database_tables','Animal Ex Vivo - Database Table (Generated 18-03-22)'))

type = 'cognition';

if strcmp(type, 'stain')
%What will the outputted data file be
folder_name = 'Final_v0_Animal_Stain_03-22';

% Which diagnosises will be compared
diagnosis = {'Thioflavin', 'Sudan', 'Unstained'}; 
diagnosis_type = 'Stain';
end

if strcmp(type, 'cognition')
%What will the outputted data file be
folder_name = 'Final_v0_Animal_Cog_03-22';

% Which diagnosises will be compared
diagnosis = {'Impaired', 'Normal'}; 
diagnosis_type = 'Diagnosis1Type';
end

%%FIXATION DOESNT WORK ATM
if strcmp(type, 'fixation')
%What will the outputted data file be
folder_name = 'Final_v0_Animal_Cog_03-22';

% Which diagnosises will be compared
diagnosis = {10, 4}; 
diagnosis_type = 'InitialFixativePercent';
end

paired = false;
legacy_table = false;

if paired
    folder_name = [folder_name, '_Paired'];
else
    folder_name = [folder_name, '_UnPaired'];
end

print_graphs = true;

%What should property string start with
section_type_match = '(Deposit|Background)';
property_type_match = '(_Median|Size)'; % And what should it end with

% What should be somewhere in the middle
match_properties = {'Diattenuation_Circ', 'Diattenuation_Lin','DP', 'Retardance_Circ',...
                    'Retardance_Lin', 'Polarizance_Circ','Polarizance_Lin'};
plain_match = {'DepositAreaMicrons2'};

% What should the outputted excel file be filled with
diag_print_to_table = {'mean', 'median', 'std', 'data'};
comp_print_to_table = {'h_unpaired','p_unpaired','normal_unpaired',...
                       'p_ANOVA'...
                        };
if paired;
    comp_paired = {'h_paired','p_paired','normal_paired'};
    comp_print_to_table = [comp_print_to_table, comp_paired];
end
compare_all_way = {'median'};

%Bools to pick which calculated properties should be run
ratio = false; %Divide by control
subtraction = false; %Subtract control from data

% Choose which database subjects to remove
reject_nan = true; % This is to remove properties which have NaN in calculation
remove_rejected = false; % Human rejection criteria 
remove_QuarterArbitrary = false; % This removes deposits which have been flagged as arbitrary quarters
post_automated = false; % Human variable

%% Script
% First we pull in our helper functions to use later
addpath(genpath('helpers'))

% Find a database of only subjects, 
%IsNewEye and IsNewQuarter can also be split out but are not here
dbt_s = dbt(dbt.IsNewSubject,:);
all_subjects = cellstr(dbt_s.SubjectId);

%% Management
property_match = ['.*(',match_properties{1}];
for i = 2:length(match_properties)
    property_match = [property_match,'|', match_properties{i}];
end
property_match = [property_match,')'];

plain_mid_match = ['.*(',plain_match{1}];
for i = 2:length(plain_match);
    plain_mid_match = [property_match,'|', plain_match{i}];
end
plain_mid_match = [plain_mid_match,')'];

if legacy_table
    pre_match = section_type_match;
    mid_match = property_match;    
else
    mid_match = section_type_match;
    pre_match = property_match;    
end
post_match = property_type_match;


%calculate some properties to use later
column_names = dbt.Properties.VariableNames;
regex_matcher = [pre_match,'.*',mid_match ,'.*', post_match];
polarization_properties = column_names(~cellfun(@isempty,regexp(column_names, regex_matcher)));
plain_props = column_names(~cellfun(@isempty,regexp(column_names, plain_mid_match)));

polarization_properties = [polarization_properties, plain_props];

%% Here I will split up the three groups
dbt = cleanup_database(dbt, remove_rejected, remove_QuarterArbitrary, ...
    reject_nan, polarization_properties,  post_automated);

% This uses the diagnosis as a regex and this regex matches the diagnosis
tables = cell(1, length(diagnosis));
for i = 1:length(diagnosis);
    tables(1,i) = {match_table_regex(dbt, [diagnosis{i}, '.*'] , diagnosis_type);};
end

if paired
    % Here I will match the locations of the deposits to send to DataCompare
    [pairing_list, paired_tables] = pairing_function(diagnosis, tables);
    % Values now are paired as stated in paired list
    dbts = struct('name', diagnosis, 'table', paired_tables);
else
    dbts = struct('name', diagnosis, 'table', tables);
end


%% Print/Calculate Data
out_path = CreateFolder(folder_name);

if print_graphs
    DataGraph(dbts, polarization_properties, out_path);
end
[comparison_struct, diag_struct, polarization_properties_struct, p_ANOVA_all] = ...
    DepositCompare(dbts, comp_print_to_table, pre_match, post_match, mid_match, ratio, subtraction, out_path);

dbts = DataPrint(dbts, diagnosis_type, comparison_struct, diag_struct, folder_name, compare_all_way, diag_print_to_table, comp_print_to_table ,diagnosis, polarization_properties_struct, out_path, p_ANOVA_all); 

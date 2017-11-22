load('Database Table (Human Ex Vivo - Generated 03-Oct-2017)_sq')

%% First just reducing the databases to only include VA subjects
VA_regex = ['VA', '.*'];
all_subjects = cellstr(dbt_s.SubjectId);

VA_s_bool = ~cellfun(@isempty,regexp(cellstr(dbt_s.SubjectId),VA_regex));
VA_e_bool = ~cellfun(@isempty,regexp(cellstr(dbt_e.SubjectId),VA_regex));
VA_q_bool = ~cellfun(@isempty,regexp(cellstr(dbt_q.SubjectId),VA_regex));
VA_bool = ~cellfun(@isempty,regexp(cellstr(dbt.SubjectId),VA_regex));

dbt_VA_s = dbt_s(VA_s_bool,:);
dbt_VA_e = dbt_e(VA_e_bool,:);
dbt_VA_q = dbt_q(VA_q_bool,:);
dbt_VA = dbt(VA_bool,:);

VA_subjects = all_subjects(VA_s_bool); % This just gives is only the VA subject names

%% User entry

% These should correlate with High, Intermediate and Low/None

diagnosis = {'HI', 'INT', 'LO' }; % Note that the third property is always the ratioed property

pre_match = '(?:Deposit|Background|FullImage)';

end_match = '(Mean|Size)';

match_properties = {'Diattenuation_Circ','DI','Psi','DP',...
 'Polarizance_45','Polarizance_Circ','Polarizance_Horz','Polarizance_Lin'};

diag_print_to_table = {'mean', 'median', 'std', 'values'};
comp_print_to_table = {'h_paired','p_paired','normal_paired',...
    'h_unpaired','p_unpaired','normal_unpaired',...
    'p_ANOVA'...
    };

compare_3_way = {'median'};

%% Management
mid_match = '.*(';
for i = 1:length(match_properties)
    mid_match = [mid_match,'|', match_properties{i}];
end
mid_match = [mid_match,')'];

post_match = [mid_match, end_match];

%% Here I will match the locations of the deposits to send to DataCompare

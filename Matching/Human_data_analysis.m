function null = Human_data_analysis()
%Creating a dummy function so I can create subfunctions later on
null = NaN;

load('Database Table (Human Ex Vivo - Generated 03-Oct-2017)_sq')

%% First just reducing the databases to only include VA subjects
VA_regex = ['VA', '.*'];
all_subjects = cellstr(dbt_s.SubjectId);

[dbt_VA_s, VA_s_bool] = match_table_regex(dbt_s, VA_regex ,'SubjectId');
dbt_VA_e = match_table_regex(dbt_e, VA_regex ,'SubjectId');
dbt_VA_q = match_table_regex(dbt_q, VA_regex ,'SubjectId');
dbt_VA = match_table_regex(dbt, VA_regex ,'SubjectId');

dbt_VA = dbt_VA(~logical(grp2idx(dbt_VA.SessionRejected) - 1),:); % Dont know how to convert out of categorical data

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

%% Here I will split up the three groups
all_subjects = cellstr(dbt_s.SubjectId);

dbt_VA_HI = match_table_regex(dbt_VA, ['high', '.*'] , 'Likelihood_of_AD');
dbt_VA_INT = match_table_regex(dbt_VA, ['intermediate', '.*'] , 'Likelihood_of_AD');
dbt_VA_LO = match_table_regex(dbt_VA, ['(low|none)', '.*'] , 'Likelihood_of_AD');

%% Here I will match the locations of the deposits to send to DataCompare
point_struct_HI = point_listmaker(dbt_VA_HI);
point_struct_INT = point_listmaker(dbt_VA_INT);
point_struct_LO = point_listmaker(dbt_VA_LO);

%point_struct_LO.distance_INT =  point_comparer(point_struct_LO, point_struct_INT);

smallest_height = min([length(point_struct_HI.indexer),...
                       length(point_struct_INT.indexer),...
                       length(point_struct_LO.indexer)]);

pairing_list = zeros(smallest_height, 3);

pairing_list(:,3) = 1:smallest_height;  %This implies that LO is smallest

[compare_LO_INT_dist, compare_LO_INT_ind, compare_LO_INT_dist_sort]= ...
    point_comparer(point_struct_LO, point_struct_INT);
[compare_LO_HI_dist, compare_LO_HI_ind, compare_LO_HI_dist_sort]= ...
    point_comparer(point_struct_LO, point_struct_HI);

for LO_index = 1:smallest_height;
    pairing_list(LO_index,3) = LO_index;
    pairing_list(LO_index,2) = compare_LO_INT_ind(LO_index,1);
    pairing_list(LO_index,1) = compare_LO_HI_ind(LO_index,1);
end

pairing_list = replace_duplicate_entries(pairing_list, 2, compare_LO_INT_dist_sort, compare_LO_INT_ind);
pairing_list = replace_duplicate_entries(pairing_list, 1, compare_LO_HI_dist_sort, compare_LO_HI_ind);

disp('yooo')

function [matched_table, matched_bool] = match_table_regex(table, regex, field)
    matched_bool = ~cellfun(@isempty,regexp(cellstr(table.(field)),regex));
    matched_table = table(matched_bool,:);
    
function point_structure = point_listmaker(table)
    point_structure = struct;
    
    indexer = zeros(height(table),4);
    indexer(:,1) = table.SubjectIdx;
    indexer(:,2) = table.EyeIdx;
    indexer(:,3) = table.QuarterIdx;
    indexer(:,4) = table.LocationIdx;
    
    point_structure.indexer = indexer;
    
    coords = zeros(height(table),2);
    coords(:,1) = table.XCoord;
    coords(:,2) = table.YCoord;
    
    point_structure.coords = coords;
 
function [distance, sorted_indicies, sorted_distances] = point_comparer(main_list, compare_list)
    main_height = length(main_list.indexer);
    compare_height = length(compare_list.indexer);
    [distance, sorted_distances, sorted_indicies] = deal(zeros(main_height, compare_height));
    for i = 1:main_height
        main_coords = main_list.coords(i,:);
        for j = 1:compare_height
            compare_coords = compare_list.coords(j,:);
            delta_coords = main_coords - compare_coords;
            distance(i, j) = (delta_coords(1)^2 + delta_coords(1)^2)^(1/2);
        end
        [sorted_distances(i,:), sorted_indicies(i,:)] = sort(distance(i,:));
    end
    
function pairing_list = replace_duplicate_entries(pairing_list, column, sorted_distances, sorted_indicies)
    column = pairing_list(:, column);
    [N, E] = histcounts(column, unique(column));
    dup_value  = E(N > 1);
    dup_index  = cell(1, numel(dup_value));
    for k = 1:numel(dup_value)
      dup_index{k} = find(column == dup_value(k));
    end
    
    for i = 1:length(dup_index)
        indicies = dup_index{i};
        if length(indicies) > 1
            % This means that we have to compare and replace these values
            compare_matrix = zeros(length(indicies));
            for j = 1:length(indicies)
                index = indicies(j);
                compare_matrix(j,:) = sorted_distances(index, 1:length(indicies));
            end
        end
    end

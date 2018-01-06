function null = Human_data_analysis()
%Creating a dummy function so I can create subfunctions later on
null = NaN;

load('Database Table (Human Ex Vivo - Generated 19-Dec-2017)')

%% First just reducing the databases to only include VA subjects
VA_regex = ['VA', '.*'];
all_subjects = cellstr(dbt_s.SubjectId);

[dbt_VA_s, VA_s_bool] = match_table_regex(dbt_s, VA_regex ,'SubjectId');
dbt_VA_e = match_table_regex(dbt_e, VA_regex ,'SubjectId');
dbt_VA_q = match_table_regex(dbt_q, VA_regex ,'SubjectId');
dbt_VA = match_table_regex(dbt, VA_regex ,'SubjectId');

VA_subjects = all_subjects(VA_s_bool); % This just gives is only the VA subject names

%% User entry

table_name = 'VA_matched_testing_';

% These should correlate with High, Intermediate and Low/None

diagnosis = {'HIGH', 'LOW', 'NONE' }; % Note that the third property is always the ratioed property

pre_match = '(?:Deposit|Background)';

post_match = '(Mean|Size)';

match_properties = {'Diattenuation_Circ','DI_','Psi', 'Retardance_Circ',...
'Polarizance_Circ','Polarizance_Lin'};

diag_print_to_table = {'mean', 'median', 'std', 'values'};
comp_print_to_table = {'h_paired','p_paired','normal_paired',...
    'h_unpaired','p_unpaired','normal_unpaired',...
    'p_ANOVA'...
    };

compare_3_way = {'median'};

%% Management
mid_match = ['.*(',match_properties{1}];
for i = 2:length(match_properties)
    mid_match = [mid_match,'|', match_properties{i}];
end
mid_match = [mid_match,')'];
% 
% post_match = [mid_match,'.*', end_match];

%% Reject some garbage data
reject_bool = dbt_VA.SubjectId == 'VA15-14' ;
dbt_VA(reject_bool,:).SessionRejected = categorical(ones(sum(reject_bool),1));

%% Unrejecting Subject with only dust and particulate measured, for
% background images, since we can segment this out, low deposits will not
% be accurate though
un_reject_bool = dbt_VA.SubjectId == 'VA14-105';
dbt_VA(un_reject_bool,:).SessionRejected = categorical(zeros(sum(un_reject_bool),1));

%% Changing diagnoisis of subject which was improperly labelled on import 
% Pretty messy, but converting in and out of categorical seems non-trivial
mislabelled_diagnosis_bool = ...dbt_VA.SubjectId == 'VA12-55';
(dbt_VA.SubjectId == 'VA12-55' | dbt_VA.SubjectId == 'VA15-41'); %rename
%low or none too?
replace_array = categorical(zeros(sum(mislabelled_diagnosis_bool),1), [0, 1, 2, 3,4], categories(dbt_VA.Likelihood_of_AD), 'Ordinal', true);
replace_array(:) = 'low';
dbt_VA(mislabelled_diagnosis_bool,:).Likelihood_of_AD = replace_array;
%% Here I will split up the three groups
all_subjects = cellstr(dbt_s.SubjectId);


dbt_VA = dbt_VA(dbt_VA.SessionRejected == '0', :); % Dont know how to convert out of categorical data
%dbt_VA = dbt_VA(dbt_VA.QuarterArbitrary == '0', :);
dbt_VA = dbt_VA(dbt_VA.IsProcessed, :);

dbt_VA_HI = match_table_regex(dbt_VA, ['high', '.*'] , 'Likelihood_of_AD');
dbt_VA_INT = match_table_regex(dbt_VA, ['low', '.*'] , 'Likelihood_of_AD');
dbt_VA_LO = match_table_regex(dbt_VA, ['none', '.*'] , 'Likelihood_of_AD');

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
point_struct_HI = point_listmaker(dbt_VA_HI);
point_struct_INT = point_listmaker(dbt_VA_INT);
point_struct_LO = point_listmaker(dbt_VA_LO);

smallest_height = min([length(point_struct_HI.indexer),...
                       length(point_struct_INT.indexer),...
                       length(point_struct_LO.indexer)]);

pairing_list = zeros(smallest_height, 3);
[LO_INT_dist, LO_HI_dist] = deal(zeros(smallest_height, 1));

pairing_list(:,3) = 1:smallest_height;  %This implies that LO is smallest

[compare_LO_INT_dist, compare_LO_INT_ind, compare_LO_INT_dist_sort]= ...
    point_comparer(point_struct_LO, point_struct_INT);
[compare_LO_HI_dist, compare_LO_HI_ind, compare_LO_HI_dist_sort]= ...
    point_comparer(point_struct_LO, point_struct_HI);

for LO_index = 1:smallest_height;
    pairing_list(LO_index,3) = LO_index;
    pairing_list(LO_index,2) = compare_LO_INT_ind(LO_index,1);
    LO_INT_dist(LO_index) = compare_LO_INT_dist_sort(LO_index,1);
    pairing_list(LO_index,1) = compare_LO_HI_ind(LO_index,1);
    LO_HI_dist(LO_index) = compare_LO_HI_dist_sort(LO_index,1);
end

[pairing_list, LO_INT_rep_dist] = replace_duplicate_entries(pairing_list, 2, compare_LO_INT_dist_sort, compare_LO_INT_ind);
[pairing_list, LO_HI_rep_dist] = replace_duplicate_entries(pairing_list, 1, compare_LO_HI_dist_sort, compare_LO_HI_ind);

LO_INT_dist(LO_INT_rep_dist ~= 1) = LO_INT_rep_dist(LO_INT_rep_dist ~= 1);
LO_HI_dist(LO_HI_rep_dist ~= 1) = LO_HI_rep_dist(LO_HI_rep_dist ~= 1);

%% Values now are paired as stated in paired list

dbt_VA_HI = dbt_VA_HI(pairing_list(:,1),:);
dbt_VA_INT = dbt_VA_INT(pairing_list(:,2),:);
dbt_VA_LO = dbt_VA_LO(pairing_list(:,3),:);

dbts = struct(diagnosis{1}, dbt_VA_HI, diagnosis{2},dbt_VA_INT, diagnosis{3}, dbt_VA_LO);
%% Print Data
num_of_deposits = length(pairing_list(:,1));
[comparison_struct, diag_struct, comparisons, polarization_names_full, p_ANOVA_all] = ...
    DepositCompare( dbts, num_of_deposits, diagnosis, pre_match, post_match, comp_print_to_table, mid_match);

out_path = DataGraph(dbts, diagnosis, polarization_names_full, pre_match);

DataPrint(comparison_struct, diag_struct, table_name, compare_3_way, diag_print_to_table, comp_print_to_table ,diagnosis, comparisons, polarization_names_full, out_path, p_ANOVA_all) 

%% run in debug and breakpoint here.
disp('done')

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
    
function [pairing_list, distance_from] = replace_duplicate_entries(pairing_list, column_index, sorted_distances, sorted_indicies)
    % This pairing is done by brute force... not elegant at all, but it
    % seems to be giving good results at the moment

    column = pairing_list(:, column_index);
    [N, E] = histcounts(column, unique(column));
    dup_value  = E(N > 1);
    dup_index  = cell(1, numel(dup_value));
    for j = 1:numel(dup_value)
      dup_index{j} = find(column == dup_value(j));
    end
    
    used_indicies = setdiff(E,dup_value);
    
    distance_from = ones(size(column));
    
    for i = 1:length(dup_index)
        indicies = dup_index{i};
        if length(indicies) > 1
            % This means that we have to compare and replace these values
            completed_rows = zeros(length(indicies),1); % bool to check if theyre complete
            compare_matrix = zeros(length(indicies), length(sorted_distances), 2);
            for j = 1:length(indicies)
                % Create matrix comparing their closest indicies and
                % distances
                index = indicies(j);
                compare_matrix(j,:,1) = sorted_indicies(index, :);
                compare_matrix(j,:,2) = sorted_distances(index, :);
            end
            %check if some have the exact same closest indicies
            [~, ia, ic] = unique(compare_matrix(:,:,1), 'rows');
            repeated_rows = setdiff(1:size(compare_matrix(:,:,1),1), ...
                            ia( sum(bsxfun(@eq,ic,(1:max(ic))))<=1 ));
            %If they have the same closest indicies they just get them in
            %order
            for j = 1:length(repeated_rows)
                index = indicies(repeated_rows(j));
                row = repeated_rows(j);
                % Ugly way of making sure we dont get a repeated index
                [index_to_add, index_row, index_col] = recursive_search(compare_matrix(:,:,1),row,j, used_indicies);
                used_indicies = [used_indicies; index_to_add];
                pairing_list(index, column_index) =  index_to_add;
                distance_from(index) = compare_matrix(index_row, index_col, 2);
                completed_rows(repeated_rows(j)) = 1;
            end
            uncompleted_rows = find(completed_rows == 0);
            while length(uncompleted_rows) >= 1
            if length(uncompleted_rows) == 1
                % If nothing is competing with the deposit we just give it
                % the best deposit which hasnt been used yet
                index = indicies(uncompleted_rows(1));
                % Ugly way of making sure we dont get a repeated index
                [index_to_add, index_row, index_col] = recursive_search(compare_matrix(:,:,1),uncompleted_rows(1),1, used_indicies);
                used_indicies = [used_indicies; index_to_add];
                pairing_list(index, column_index) = index_to_add;
                distance_from(index) = compare_matrix(index_row, index_col, 2);
                completed_rows(uncompleted_rows(1)) = 1;
            elseif length(uncompleted_rows) > 1
                %Here we should compare the deposits
                %This means the distances should be different?!
                
                compete_matrix = compare_matrix(uncompleted_rows,:,:);
                winner_not_found = true;
                k = 1;
                while winner_not_found;
                    distances = compete_matrix(:,k,2);
                    [~, sorted_dist_index] = sort(distances, 'ascend');
                    smallest_row_index = find(sorted_dist_index == 1);
                    possible_index = compare_matrix(smallest_row_index,k,1);
                    if ~ismember(possible_index, used_indicies)
                        winner_not_found = false;
                        % Index is okay to use
                        pairing_list(index, column_index) = possible_index;
                        distance_from(index) = compare_matrix(smallest_row_index, k, 2);
                        used_indicies = [used_indicies; possible_index];
                        completed_rows(uncompleted_rows(smallest_row_index)) = 1;
                    else
                        k = k + 1;
                    end
                end
            end
            uncompleted_rows = find(completed_rows == 0);
            end
        end
    end
    
function [index, row, col] = recursive_search(indicies, row, col, used_indicies)
    possible_index = indicies(row, col);
    if ~ismember(possible_index, used_indicies)
        index = possible_index;
    else
        index = recursive_search(indicies, row, col+1, used_indicies);
    end
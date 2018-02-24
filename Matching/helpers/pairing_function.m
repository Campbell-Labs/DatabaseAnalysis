function [ pairing_list, paired_tables ] = pairing_function( names, tables )
%UNTITLED Summary of this function goes here
%       names: cell array of names
%       tables: Cell array of tables

%% Here I will match the locations of the deposits to send to DataCompare
for i = 1:length(names)
    pairing_structure(i).diagnosis = names(i);
    pairing_structure(i).table = tables{i};

    indexer = zeros(height(tables{i}),4);
    indexer(:,1) = tables{i}.SubjectIdx;
    indexer(:,2) = tables{i}.EyeIdx;
    indexer(:,3) = tables{i}.QuarterIdx;
    indexer(:,4) = tables{i}.LocationIdx;
    
    pairing_structure(i).height = length(indexer);
    
    pairing_structure(i).indexer = indexer;
    
    coords = zeros(height(tables{i}),2);
    coords(:,1) = tables{i}.XCoord;
    coords(:,2) = tables{i}.YCoord;
    
    pairing_structure(i).coords = coords;
end

%% Smallest table will be the target of pairing always.
[smallest_height, smallest_index]  = min([pairing_structure(:).height]);

pairing_list = zeros(smallest_height, length(pairing_structure));

for n = 1:length(pairing_structure);

    if n == smallest_index;
        % Dont compare since this is the reference, 
        %but include placeholder data?
        [distance, sorted_distances, sorted_indicies] = deal([]); 
        pairing_list(:,n) = 1:smallest_height;
    else
        [distance, sorted_distances, sorted_indicies] = ...
            deal(zeros(smallest_height, pairing_structure(n).height));
        for i = 1:smallest_height
            reference_coords = pairing_structure(smallest_index).coords(i,:);
            for j = 1:pairing_structure(n).height
                compare_coords = pairing_structure(n).coords(j,:);
                delta_coords = reference_coords - compare_coords;
                distance(i, j) = (delta_coords(1)^2 + delta_coords(1)^2)^(1/2);
            end
            [sorted_distances(i,:), sorted_indicies(i,:)] = sort(distance(i,:));
        end
        pairing_list(:,n) = sorted_indicies(:,1);       
    end
    pairing_structure(n).distances = distance;
    pairing_structure(n).sorted_indicies = sorted_indicies;
    pairing_structure(n).compare_sorted_distances = sorted_distances;   
end

for n = 1:length(pairing_structure);
    if n == smallest_index;
        continue
    else
        [pairing_list, rep_dist] = replace_duplicate_entries(pairing_list, n, ...
            pairing_structure(n).compare_sorted_distances, pairing_structure(n).sorted_indicies);
        pairing_structure(n).sorted_distances = pairing_structure(n).compare_sorted_distances;
        % Deals with repeated distances for later record keeping
        pairing_structure(n).sorted_distances(rep_dist ~= 1) = rep_dist(rep_dist ~=1);
    end
end

paired_tables = cell(1, length(pairing_structure));

for n = 1:length(pairing_structure);
    paired_tables{n} = pairing_structure(n).table(pairing_list(:,n),:);
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
    
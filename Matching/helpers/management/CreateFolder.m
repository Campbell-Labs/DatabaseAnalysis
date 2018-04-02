function [ output_folder ] = CreateFolder(pre_name, directory, folder_name)
%CreateFolder Simply creates a new folder with a timestamp
%   All args are optional to provide ease of use
if exist( 'directory','var' ) == 0
    directory = pwd;
end

if exist( 'pre_name','var' ) == 0
    pre_name = 'Data_Directory_';
end

if exist( 'folder_name','var' ) == 0
    folder_name = 'data_dump_folder';
    
end

output_directory = fullfile(directory, folder_name);

new_folder = [pre_name, datestr(now, 'mm-dd-HH-MM')];
output_folder = fullfile(output_directory, new_folder);

mkdir(output_folder)
end
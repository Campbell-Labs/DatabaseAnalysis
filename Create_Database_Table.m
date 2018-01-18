function Create_Database_Table
% Create a table containing metadata and polarization image statistics for
% all deposits in the databases. First this script creates a structure of
% path names to all the existing metadata files and images, then it scrapes
% through all the metadata files to collect relevant information.
%
% Erik Mason (erikmason04@gmail.com)
%
% _v2 started October 20th, 2017 to update the polarization property
% statistics calculations.
%
% _v3 started Nov 23rd, 2017 to use the newly registered and manually
% segmented images
%
% _v3_Subject8_reregister started Nov 29th, 2017 to account for
% re-registered (a new session folder) subject 8
%
% _v4_no_abs started Dec 19th, 2017 to re-calculate the stats with and also
% without the absolute values for some metrics. From
% v3_Subject8_reregister, the only thing changed will be the part that
% calculates the polarization metrics. The previous dbt will be copied in
% directly and the previous metrics will be manually deleted.
%
%_v5_GitHub (RENAMED TO Create_Databate_Table Jan 12th 2018) started Jan 
% 9th, 2018 to clean up the code so it's functional, so it can be put on 
% the Campbell Labs GitHub.

%%

%% USER INPUT

database_path = 'A:\T 01 (Human Ex Vivo)\'; database_name = 'Human Ex Vivo';
% database_path = 'A:\T 02 (Dog Ex Vivo)\'; database_name = 'Dog Ex Vivo';
% database_path = 'A:\T 03 (Stains)\'; database_name = 'Stains';
% database_path = 'A:\T 04 (Buffer Solutions)\'; database_name = 'Buffer Solutions';
% database_path = 'A:\T 05 (LaFora Disease)\'; database_name = 'LaFora Disease';
% database_path = 'A:\T 06 (Human CSLO)\'; database_name = 'Human CSLO';

label_empty = 0;                % for categorical variables, use 'Empty' instead of '' so that empty values can be included as their own group in statistical analysis

recalculate_all = 0;            % if 0, will only calculate polarization property statistics that are not already in the database table. If 1, will completely recalculate everything

%% Gather all of the information

% load in previous database table to transfer existing segmentation
% information and polarization metrics to the new one.
[old_dbt_filename, old_dbt_pathname] = uigetfile('*.mat','Select the .mat file that contains the previous database table');
load([old_dbt_pathname, old_dbt_filename])
if ~exist('dbt', 'var')
    error('Please select a .mat file that contains a database table saved as ''dbt''')
end
old_dbt = dbt; clear dbt

disp('Creating Structure of Pathnames...')
dbpaths = create_pathnames_structure(database_path);
save([database_name, ' - Database Paths (Generated ', strrep(datestr(now, 'yy/mm/dd'),'/','-'), ').mat'], 'dbpaths')
try
    save(['Y:\shared\Erik\Database Analysis\', database_name, ' - Database Paths (Generated ', strrep(datestr(now, 'yy/mm/dd'),'/','-'), ').mat'], 'dbpaths')
end


disp('Creating Table of Metadata...')
dbt = create_metadata_table(dbpaths, label_empty);

if strcmp(database_path, 'A:\T 01 (Human Ex Vivo)\')
    disp('Adding Brain Pathology...')
    dbt = add_disease_stage(dbt);
end

disp('Merging old dbt into new dbt...')
dbt = merge_old_dbt_data(old_dbt, dbt, recalculate_all);

disp('Calculating Polarization Image Statistics...')
dbt = calculate_polarization_stats(dbpaths, dbt, recalculate_all);

clearvars -except dbt database_name
dbt_s = dbt(dbt.IsNewSubject,:);
dbt_e = dbt(dbt.IsNewEye,:);
dbt_q = dbt(dbt.IsNewQuarter,:);
save([database_name, ' - Database Table (Generated ', strrep(datestr(now, 'yy/mm/dd'),'/','-'), ').mat'])
try
    save(['Y:\shared\Erik\Database Analysis\', database_name, ' - Database Table (Generated ', strrep(datestr(now, 'yy/mm/dd'),'/','-'), ').mat'])
end

%% Notes

% find stats from the fluorescence image also, using the segmentation mask
% - to see if the contrast is good enough

end

function [ dbpaths ] = create_pathnames_structure( database_path )
% Creates a MATLAB structure that contains all the relevant file paths in
% the Human Ex Vivo database. Contains paths for the metadata files,
% microscope images, and polarization images. Is organized by subject, eye,
% quarter, and location the same way the folders in the database are.
%
% Erik Mason (erikmason04@gmail.com), Summer 2017
% Started August 17th, 2017
% Made into a function for Create_Database_Table.m on Sept 18th, 2017

%% create structure of metadata file names
dbpaths = [];

subject_folders = dir([database_path,'S*']);

for s = 1:length(subject_folders)
    
    subject_dir = [database_path, subject_folders(s).name, '\'];
    dbpaths(s).FolderPath = subject_dir;
    if exist([subject_dir, 'subject_metadata.mat'], 'file') == 2;
        dbpaths(s).MetadataPath = [subject_dir, 'subject_metadata.mat'];
    else
        dbpaths(s).MetadataPath = [];
    end
    
    eye_folders = dir([subject_dir, 'E*']);        
    if isempty(eye_folders)
        dbpaths(s).Eye = [];
    end
    
    for e = 1:length(eye_folders)
        
        eye_dir = [subject_dir, eye_folders(e).name, '\'];
        dbpaths(s).Eye(e).FolderPath = eye_dir;
        if exist([eye_dir, 'sample_metadata.mat'], 'file') == 2
            dbpaths(s).Eye(e).MetadataPath = [eye_dir, 'sample_metadata.mat'];
        else
            dbpaths(s).Eye(e).MetadataPath = [];
        end                 
        
        quarter_folders = dir([eye_dir, 'Q*']);
        if isempty(quarter_folders)
            dbpaths(s).Eye(e).Quarter = [];
        end
            
        for q = 1:length(quarter_folders)
            
            quarter_dir = [eye_dir, quarter_folders(q).name, '\'];
            dbpaths(s).Eye(e).Quarter(q).FolderPath = quarter_dir;
            if exist([quarter_dir, 'quarter_metadata.mat'], 'file') == 2
                dbpaths(s).Eye(e).Quarter(q).MetadataPath = [quarter_dir, 'quarter_metadata.mat'];
            else
                dbpaths(s).Eye(e).Quarter(q).MetadataPath = [];
            end                            

            location_folders = dir([quarter_dir, 'L*']);
            if isempty(location_folders)
                dbpaths(s).Eye(e).Quarter(q).Location = [];
            end
            
            for l = 1:length(location_folders)
                
                location_dir = [quarter_dir, location_folders(l).name, '\'];
                dbpaths(s).Eye(e).Quarter(q).Location(l).FolderPath = location_dir;
                if exist([location_dir, 'location_metadata.mat'], 'file') == 2
                    dbpaths(s).Eye(e).Quarter(q).Location(l).LocationMetadataPath = [location_dir, 'location_metadata.mat'];
                else
                    dbpaths(s).Eye(e).Quarter(q).Location(l).LocationMetadataPath = [];
                end
                
                if isdir([location_dir, 'CS 001 (Microscope)'])
                    if exist([location_dir, 'CS 001 (Microscope)\session_metadata.mat'], 'file') == 2
                        dbpaths(s).Eye(e).Quarter(q).Location(l).MicroscopeMetadataPath = [location_dir, 'CS 001 (Microscope)\session_metadata.mat'];
                    else
                        dbpaths(s).Eye(e).Quarter(q).Location(l).MicroscopeMetadataPath = [];
                    end
                                                        
                    % fluorescence images and metadata
                    fluorescent_dir = dir([location_dir, 'CS 001 (Microscope)\Fluorescent\*.bmp']);
                    if ~isempty(fluorescent_dir)
                        for f = 1:length(fluorescent_dir)
                            dbpaths(s).Eye(e).Quarter(q).Location(l).FluorescentImages(f).Path = [location_dir, 'CS 001 (Microscope)\Fluorescent\', fluorescent_dir(f).name];
                        end
                    else
                        dbpaths(s).Eye(e).Quarter(q).Location(l).FluorescentImages = [];
                    end

                    % unregistered microscope images
                    unregistered_microscope_dir = dir([location_dir, 'CS 001 (Microscope)\MM\*.bmp']);
                    if ~isempty(unregistered_microscope_dir)
                        for urm = 1:length(unregistered_microscope_dir)
                            dbpaths(s).Eye(e).Quarter(q).Location(l).UnregisteredMicroscopeImages(urm).Path = [location_dir, 'CS 001 (Microscope)\MM\', unregistered_microscope_dir(urm).name];
                        end
                    else
                        dbpaths(s).Eye(e).Quarter(q).Location(l).UnregisteredMicroscopeImages = [];
                    end
                else
                    dbpaths(s).Eye(e).Quarter(q).Location(l).MicroscopeMetadataPath = [];
                    dbpaths(s).Eye(e).Quarter(q).Location(l).FluorescentImages = [];
                    dbpaths(s).Eye(e).Quarter(q).Location(l).UnregisteredMicroscopeImages = [];
                end                
                
                % registered microcscope images and metadata                
                registration_dir = dir([location_dir, 'PS*Registration)']);
                if ~isempty(registration_dir)
                    
                    reg_dir_name = [location_dir, '\', registration_dir(end).name]; % choose the most recent registration session - assume it's the correct one
                    
                    if exist([reg_dir_name,'\session_metadata.mat'], 'file') == 2
                        dbpaths(s).Eye(e).Quarter(q).Location(l).RegistrationMetadataPath = [reg_dir_name,'\session_metadata.mat'];
                    else
                        dbpaths(s).Eye(e).Quarter(q).Location(l).RegistrationMetadataPath = [];
                    end                    
                    
                    registered_microscope_dir = dir([reg_dir_name,'\MM\*.bmp']);
                    if ~isempty(registered_microscope_dir)
                        for rm = 1:length(registered_microscope_dir)
                            dbpaths(s).Eye(e).Quarter(q).Location(l).RegisteredMicroscopeImages(rm).Path = [reg_dir_name,'\MM\', registered_microscope_dir(rm).name];
                        end
                    else
                        dbpaths(s).Eye(e).Quarter(q).Location(l).RegisteredMicroscopeImages = [];
                    end
                    
                else
                    dbpaths(s).Eye(e).Quarter(q).Location(l).RegistrationMetadataPath = [];
                    dbpaths(s).Eye(e).Quarter(q).Location(l).RegisteredMicroscopeImages = [];
                end
                
                % polarization properties images and metadata
                polarization_dir = dir([location_dir, 'PS*(Polarization Analysis*']);
                if ~isempty(polarization_dir)
                    
                    if length(registration_dir) == 1    % shouldn't be important, but this assumes that there is a registered images folder if there is a polarization analysis folder
                        polarization_dir = [location_dir, polarization_dir(1).name, '\'];       % if there is only one registration session, take the first polarization analysis folder corresponding to the full image, not a subsection (if they exist)
                    elseif length(registration_dir) > 1
                        polarization_dir = [location_dir, polarization_dir(end).name, '\'];     % if there is a newer registration session, take the most recent polarization analysis folder, because subsections are not used anymore
                    end
                    
                    if exist([polarization_dir, 'session_metadata.mat'], 'file') == 2
                        dbpaths(s).Eye(e).Quarter(q).Location(l).PolarizationMetadataPath = [polarization_dir, 'session_metadata.mat'];
                    else
                        dbpaths(s).Eye(e).Quarter(q).Location(l).PolarizationMetadataPath = [];
                    end                    
                    
                    diattenuation_dir = dir([polarization_dir, 'Diattenuation\*.mat']);
                    if ~isempty(diattenuation_dir)
                        for d = 1:length(diattenuation_dir)
                            dbpaths(s).Eye(e).Quarter(q).Location(l).DiattenuationImages(d).Path = [polarization_dir, 'Diattenuation\', diattenuation_dir(d).name];
                        end
                    else
                        dbpaths(s).Eye(e).Quarter(q).Location(l).DiattenuationImages = [];
                    end
                    
                    general_metrics_dir = dir([polarization_dir, 'General Metrics\*.mat']);
                    if ~isempty(general_metrics_dir)
                        for gm = 1:length(general_metrics_dir)
                            dbpaths(s).Eye(e).Quarter(q).Location(l).GeneralMetricsImages(gm).Path = [polarization_dir, 'General Metrics\', general_metrics_dir(gm).name];
                        end
                    else
                        dbpaths(s).Eye(e).Quarter(q).Location(l).GeneralMetricsImages = [];
                    end                    
                    
                    more_retardance_metrics_dir = dir([polarization_dir, 'More Retardance Metrics\*.mat']);
                    if ~isempty(more_retardance_metrics_dir)
                        for mrm = 1:length(more_retardance_metrics_dir)
                            dbpaths(s).Eye(e).Quarter(q).Location(l).MoreRetardanceMetricsImages(mrm).Path = [polarization_dir, 'More Retardance Metrics\', more_retardance_metrics_dir(mrm).name];
                        end
                    else
                        dbpaths(s).Eye(e).Quarter(q).Location(l).MoreRetardanceMetricsImages = [];
                    end
                    
                    polarizance_dir = dir([polarization_dir, 'Polarizance\*.mat']);
                    if ~isempty(polarizance_dir)
                        for p = 1:length(polarizance_dir)
                            dbpaths(s).Eye(e).Quarter(q).Location(l).PolarizanceImages(p).Path = [polarization_dir, 'Polarizance\', polarizance_dir(p).name];
                        end
                    else
                        dbpaths(s).Eye(e).Quarter(q).Location(l).PolarizanceImages = [];
                    end
                    
                    retardance_dir = dir([polarization_dir, 'Retardance\*.mat']);
                    if ~isempty(retardance_dir)
                        for r = 1:length(retardance_dir)
                            dbpaths(s).Eye(e).Quarter(q).Location(l).RetardanceImages(r).Path = [polarization_dir, 'Retardance\', retardance_dir(r).name];
                        end
                    else
                        dbpaths(s).Eye(e).Quarter(q).Location(l).RetardanceImages = [];
                    end
                    
                else
                    dbpaths(s).Eye(e).Quarter(q).Location(l).PolarizationMetadataPath = [];
                    dbpaths(s).Eye(e).Quarter(q).Location(l).DiattenuationImages = [];
                    dbpaths(s).Eye(e).Quarter(q).Location(l).GeneralMetricsImages = [];
                    dbpaths(s).Eye(e).Quarter(q).Location(l).MoreRetardanceMetricsImages = [];
                    dbpaths(s).Eye(e).Quarter(q).Location(l).PolarizanceImages = [];
                    dbpaths(s).Eye(e).Quarter(q).Location(l).RetardanceImages = [];
                end
                
            end
        end
    end        
end

end

function [ dbt ] = create_metadata_table( dbpaths, label_empty )
% Creates a MATLAB structure with metadata information for every deposit in
% a given database. Any metadata that is deemed relevant will be saved into
% a table called "dbt", which will then be used to analyze things like
% deposit location on the retina.
%
% Note - in order to read the metadata files, which are class files in
% MATLAB, this script must be run from a session of MATLAB that has the
% Polarization Analysis GUI running. It needs to be run from
% "C:\Alzheimer's Project Code Base - GitHub Master\Polarization-Analysis",
% while the GUI is open.
%
% Erik Mason (erikmason04@gmail.com), Summer 2017
% Started August 21st, 2017
% Remade to use a table datatype August 31st, 2017
% Made into a function for Create_Database_Table.m on Sept 20th, 2017

%% Loop through the paths structure and save relevant data
dbt = [];
i = 1;              % index of location - i will iterate over ALL location points, for each subject/eye/quarter/location

% subject metadata
for s = 1:length(dbpaths)
        
    dbt(i).SubjectIdx = s;    
    load(dbpaths(s).MetadataPath)    % load subject metadata
    sub_md = metadata; clear metadata
    
    dbt(i).SubjectId = filter_data(sub_md.subjectId, 'nominal', label_empty);
    switch dbt(i).SubjectId
        case 'VA-14-91'
            dbt(i).SubjectId = 'VA14-91';
        case 'VA 13-06'
            dbt(i).SubjectId = 'VA13-06';
        case 'VA-15-38'
            dbt(i).SubjectId = 'Practice';
    end
    dbt(i).Age = filter_data(sub_md.age, 'continuous', label_empty);        
    try dbt(i).Gender = filter_data(sub_md.gender.displayString, 'nominal', label_empty); catch, dbt(i).Gender = filter_data([], 'nominal', label_empty); end
    dbt(i).CauseOfDeath = filter_data(sub_md.causeOfDeath, 'nominal', label_empty);    
    dbt(i).TimeOfDeath = filter_data(sub_md.timeOfDeath, 'continuous', label_empty);    
    dbt(i).MedicalHistory = filter_data(sub_md.medicalHistory, 'nominal', label_empty);
    
    if ~isempty(sub_md.diagnoses)                 
        for diag = 1:length(sub_md.diagnoses)
            if diag == 1
                dbt(i).Diagnosis1Type = filter_data(sub_md.diagnoses{1,diag}.diagnosisType.fullString, 'nominal', label_empty);
                dbt(i).Diagnosis1Level = filter_data(sub_md.diagnoses{1,diag}.diagnosisLevel.displayString, 'nominal', label_empty);
                dbt(i).Is1PrimaryDiagnosis = filter_data(sub_md.diagnoses{1,diag}.isPrimaryDiagnosis, 'nominal', label_empty);
                dbt(i).Diagnosis2Type = filter_data([], 'nominal', label_empty);
                dbt(i).Diagnosis2Level = filter_data([], 'nominal', label_empty);
                dbt(i).Is2PrimaryDiagnosis = filter_data([], 'nominal', label_empty);
            elseif diag == 2
                dbt(i).Diagnosis2Type = filter_data(sub_md.diagnoses{1,diag}.diagnosisType.fullString, 'nominal', label_empty);
                dbt(i).Diagnosis2Level = filter_data(sub_md.diagnoses{1,diag}.diagnosisLevel.displayString, 'nominal', label_empty);
                dbt(i).Is2PrimaryDiagnosis = filter_data(sub_md.diagnoses{1,diag}.isPrimaryDiagnosis, 'nominal', label_empty);
            elseif diag == 3
                disp(['Subject ', num2str(s), ' has more than 2 diagnoses. Only the first two will be saved in the table.'])
            end           
        end
               
        if strcmp(dbt(i).Diagnosis1Type, 'Alzheimer''s Disease Negative') || strcmp(dbt(i).Diagnosis2Type, 'Alzheimer''s Disease Negative')
            dbt(i).AD_Positive = '0';
        elseif ( strcmp(dbt(i).Diagnosis1Type, 'Alzheimer''s Disease Postive') && isempty(dbt(i).Diagnosis2Type) )...
                || ( strcmp(dbt(i).Diagnosis2Type, 'Alzheimer''s Disease Postive') && isempty(dbt(i).Diagnosis1Type) )
            dbt(i).AD_Positive = '1';
        elseif strcmp(dbt(i).Diagnosis1Type, 'Alzheimer''s Disease Postive') || strcmp(dbt(i).Diagnosis2Type, 'Alzheimer''s Disease Postive')
            dbt(i).AD_Positive = '2';   % AD as one diagnosis, and another non-AD diagnosis        
        else
            dbt(i).AD_Positive = '-1';  % two non-AD diagnoses, or empty/unknown        
        end        
    else
        dbt(i).Diagnosis1Type = filter_data([], 'nominal', label_empty);
        dbt(i).Diagnosis1Level = filter_data([], 'nominal', label_empty);
        dbt(i).Is1PrimaryDiagnosis = filter_data([], 'nominal', label_empty);
        dbt(i).Diagnosis2Type = filter_data([], 'nominal', label_empty);
        dbt(i).Diagnosis2Level = filter_data([], 'nominal', label_empty);
        dbt(i).Is2PrimaryDiagnosis = filter_data([], 'nominal', label_empty);
        dbt(i).AD_Positive = '-1';      % two non-AD diagnoses, or empty/unknown
    end
    
    dbt(i).SubjectSampleIdx = filter_data(sub_md.sampleIndex, 'nominal', label_empty);   % unknown meaning, in human database it's either 0 (for 1289) or 1 (for 347)
    dbt(i).SubjectNotes = filter_data(sub_md.notes, 'nominal', label_empty);
    
    dbt(i).NumberOfEyesInSubject = 0;       
    for ei = 1:length(dbpaths(s).Eye)
        if ~isempty(dbpaths(s).Eye(ei).Quarter);
            dbt(i).NumberOfEyesInSubject = dbt(i).NumberOfEyesInSubject + 1;
        end
    end
    
    % eye metadata
    for e = 1:length(dbpaths(s).Eye)

        dbt(i).EyeIdx = e;        
        load(dbpaths(s).Eye(e).MetadataPath)
        sam_md = metadata; clear metadata;

        try dbt(i).EyeSource = filter_data(sam_md.source.displayString, 'nominal', label_empty); catch, dbt(i).EyeSource = filter_data([], 'nominal', label_empty); end
        try dbt(i).EyeType = filter_data(sam_md.eyeType.displayString, 'nominal'); catch, dbt(i).EyeType = filter_data([], 'nominal', label_empty); end
        try dbt(i).InitialFixative = filter_data(sam_md.initialFixative.displayString, 'nominal'); catch, dbt(i).InitialFixative = filter_data([], 'nominal', label_empty); end
        dbt(i).InitialFixativePercent = filter_data(sam_md.initialFixativePercent, 'nominal', label_empty);
        dbt(i).InitialFixingTime = filter_data(sam_md.initialFixingTime, 'continuous', label_empty);
        dbt(i).DisectionDoneBy = filter_data(sam_md.dissectionDoneBy, 'nominal', label_empty);
        dbt(i).SampleNotes = filter_data(sam_md.notes, 'nominal', label_empty);

        dbt(i).NumberOfQuartersInEye = 0;     
        for qi = 1:length(dbpaths(s).Eye(e).Quarter)
            if ~isempty(dbpaths(s).Eye(e).Quarter(qi).Location);
                dbt(i).NumberOfQuartersInEye = dbt(i).NumberOfQuartersInEye + 1;
            end
        end

        % quarter metadata
        for q = 1:length(dbpaths(s).Eye(e).Quarter)

            dbt(i).QuarterIdx = q;           
            load(dbpaths(s).Eye(e).Quarter(q).MetadataPath)
            quar_md = metadata; clear metadata;

            dbt(i).MountingDate = filter_data(quar_md.mountingDate, 'continuous', label_empty);
            dbt(i).MountingDoneBy = filter_data(quar_md.mountingDoneBy, 'nominal', label_empty);
            dbt(i).Stain = filter_data(quar_md.stain, 'nominal', label_empty);
            try dbt(i).QuarterType = filter_data(quar_md.quarterType.displayString, 'nominal', label_empty); catch, dbt(i).QuarterType = filter_data([], 'nominal', label_empty); end
            dbt(i).QuarterNumber = filter_data(quar_md.quarterNumber, 'nominal', label_empty);
            dbt(i).QuarterArbitrary = filter_data(quar_md.quarterArbitrary, 'nominal', label_empty);
            dbt(i).QuarterNotes = filter_data(quar_md.notes, 'nominal', label_empty);

            dbt(i).NumberOfLocationsInQuarter = length(dbpaths(s).Eye(e).Quarter(q).Location);

            % location metadata
            for l = 1:length(dbpaths(s).Eye(e).Quarter(q).Location)

                dbt(i+1) = dbt(i);    % copy over up to quarter metadata from the last location

                % location metadata
                dbt(i).LocationIdx = l;
                load(dbpaths(s).Eye(e).Quarter(q).Location(l).LocationMetadataPath)
                loc_md = metadata; clear metadata;

                dbt(i).LocationNumber = filter_data(loc_md.locationNumber, 'continuous', label_empty);
                dbt(i).Deposit = filter_data(loc_md.deposit, 'nominal', label_empty);
                lc = loc_md.locationCoords;
                if ~isempty(lc)
                    dbt(i).XCoord = lc(1);
                    dbt(i).YCoord = lc(2);
                    dbt(i).RadDistFromFovea = sqrt(lc(1)^2 + lc(2)^2);
                else
                    dbt(i).XCoord = filter_data([], 'continuous', label_empty);
                    dbt(i).YCoord = filter_data([], 'continuous', label_empty);
                    dbt(i).RadDistFromFovea = filter_data([], 'continuous', label_empty);
                end                
                dbt(i).LocationNotes = filter_data(loc_md.notes, 'nominal', label_empty);

                % microscope metadata
                if ~isempty(dbpaths(s).Eye(e).Quarter(q).Location(l).MicroscopeMetadataPath)
                    load(dbpaths(s).Eye(e).Quarter(q).Location(l).MicroscopeMetadataPath)
                    sess_md = metadata; clear metadata;
                    dbt(i).Magnification = filter_data(sess_md.magnification, 'nominal', label_empty);
                    dbt(i).BWPixelSizeMicrons = filter_data(sess_md.bwPixelSizeMicrons, 'nominal', label_empty);               
                    dbt(i).RGBPixelSizeMicrons = filter_data(sess_md.rgbPixelSizeMicrons, 'nominal', label_empty);
                    dbt(i).FluoroSignature = filter_data(sess_md.fluoroSignature, 'nominal', label_empty);
                    dbt(i).CrossedSignature = filter_data(sess_md.crossedSignature, 'nominal', label_empty);
                    dbt(i).VisualSignature = filter_data(sess_md.visualSignature, 'nominal', label_empty);
                    dbt(i).SessionDoneBy = filter_data(sess_md.sessionDoneBy, 'nominal', label_empty);
                    dbt(i).SessionRejected = filter_data(sess_md.rejected, 'nominal', label_empty);
                    dbt(i).RejectedReason = filter_data(sess_md.rejectedReason, 'nominal', label_empty);
                    dbt(i).RejectedBy = filter_data(sess_md.rejectedBy, 'nominal', label_empty);
                    dbt(i).SessionNotes = filter_data(sess_md.notes, 'nominal', label_empty);
                else
                    dbt(i).Magnification = filter_data([], 'nominal', label_empty);
                    dbt(i).BWPixelSizeMicrons = filter_data([], 'nominal', label_empty);               
                    dbt(i).RGBPixelSizeMicrons = filter_data([], 'nominal', label_empty);
                    dbt(i).FluoroSignature = filter_data([], 'nominal', label_empty);
                    dbt(i).CrossedSignature = filter_data([], 'nominal', label_empty);
                    dbt(i).VisualSignature = filter_data([], 'nominal', label_empty);
                    dbt(i).SessionDoneBy = filter_data([], 'nominal', label_empty);
                    dbt(i).SessionRejected = filter_data([], 'nominal', label_empty);
                    dbt(i).RejectedReason = filter_data([], 'nominal', label_empty);
                    dbt(i).RejectedBy = filter_data([], 'nominal', label_empty);
                    dbt(i).SessionNotes = filter_data([], 'nominal', label_empty);
                end
                
                % registration metadata
                if ~isempty(dbpaths(s).Eye(e).Quarter(q).Location(l).RegistrationMetadataPath)                    
                    load(dbpaths(s).Eye(e).Quarter(q).Location(l).RegistrationMetadataPath)
                    sess_md = metadata; clear metadata;                    
                    dbt(i).IsRegistered = true;
                    try dbt(i).RegistrationType = filter_data(sess_md.registrationType.displayString, 'nominal', label_empty); catch, dbt(i).RegistrationType = filter_data([], 'nominal', label_empty); end
                    dbt(i).RegistrationDoneBy = filter_data(sess_md.sessionDoneBy, 'nominal', label_empty);
                    dbt(i).RegistrationNotes = filter_data(sess_md.notes, 'nominal', label_empty);                                        
                else                    
                    dbt(i).IsRegistered = false;                    
                    dbt(i).RegistrationType = filter_data([], 'nominal', label_empty);
                    dbt(i).RegistrationDoneBy = filter_data([], 'nominal', label_empty);
                    dbt(i).RegistrationNotes = filter_data([], 'nominal', label_empty);                                        
                end

                % polarization metadata
                if ~isempty(dbpaths(s).Eye(e).Quarter(q).Location(l).PolarizationMetadataPath)                                                            
                    load(dbpaths(s).Eye(e).Quarter(q).Location(l).PolarizationMetadataPath)
                    sess_md = metadata; clear metadata;
                    dbt(i).IsProcessed = true;
                    dbt(i).MMOutOfRangePixelsRatio = filter_data(sess_md.outOfRangePixelsRatio, 'continuous', label_empty);
                    dbt(i).MMProcessedBy = filter_data(sess_md.sessionDoneBy, 'nominal', label_empty);                                         
                else                    
                    dbt(i).IsProcessed = false;
                    dbt(i).MMOutOfRangePixelsRatio = filter_data([], 'continuous', label_empty);
                    dbt(i).MMProcessedBy = filter_data([], 'nominal', label_empty);                   
                end

                i = i + 1;

            end
        end      
    end   
end

dbt(end) = [];     % remove the last entry, which is copied from the one before

%% Add extra fields that need to be calculated from the metadata
% Create a boolean variable to identify a new subject, eye, and quarter.
% This way, the location_data structure can be reduced to only one entry
% per subject, eye, or quarter (instead of having one entry per location),
% and analysis can be done on specifically the subject, eye or quarter
% metadata without over-counting
dbt(1).IsNewSubject = true;
dbt(1).IsNewEye = true;
dbt(1).IsNewQuarter = true;

for d = 1:length(dbt)-1    
    if dbt(d+1).SubjectIdx ~= dbt(d).SubjectIdx        
        dbt(d+1).IsNewSubject = true;
        dbt(d+1).IsNewEye = true;
        dbt(d+1).IsNewQuarter = true;        
    elseif dbt(d+1).EyeIdx ~= dbt(d).EyeIdx        
        dbt(d+1).IsNewSubject = false;
        dbt(d+1).IsNewEye = true;
        dbt(d+1).IsNewQuarter = true;        
    elseif dbt(d+1).QuarterIdx ~= dbt(d).QuarterIdx        
        dbt(d+1).IsNewSubject = false;
        dbt(d+1).IsNewEye = false;
        dbt(d+1).IsNewQuarter = true;
    else
        dbt(d+1).IsNewSubject = false;
        dbt(d+1).IsNewEye = false;
        dbt(d+1).IsNewQuarter = false;
    end        
end 

% Count the number of locations, and deposits, in each subject/eye/quarter.
% Also the number of quarters in each subject (the number of quarters in
% each eye is already calculated, and the number of eyes in each subject is
% already calculated)

% number of deposits in each quarter
new_quarter_idxs = find([dbt(:).IsNewQuarter]);
for nq = 1:length(new_quarter_idxs)
    
    if nq == length(new_quarter_idxs)
        idxs_in_quarter = new_quarter_idxs(nq) : length(dbt);
    else
        idxs_in_quarter = new_quarter_idxs(nq) : (new_quarter_idxs(nq+1) - 1);
    end
    
    num_fluoro_in_quarter = sum(strcmp({dbt(idxs_in_quarter).FluoroSignature}, '1') & strcmp({dbt(idxs_in_quarter).SessionRejected}, '0'));
    num_crossed_in_quarter = sum(strcmp({dbt(idxs_in_quarter).CrossedSignature}, '1') & strcmp({dbt(idxs_in_quarter).SessionRejected}, '0'));
    num_deposits_in_quarter = sum(strcmp({dbt(idxs_in_quarter).Deposit}, '1') & strcmp({dbt(idxs_in_quarter).SessionRejected}, '0'));    
    
    for qi = idxs_in_quarter
        dbt(qi).NumberOfFluoroInQuarter = num_fluoro_in_quarter;
        dbt(qi).NumberOfCrossedInQuarter = num_crossed_in_quarter;
        dbt(qi).NumberOfDepositsInQuarter = num_deposits_in_quarter;        
    end
end

% number of locations and deposits in each eye
location_data_Q = dbt(new_quarter_idxs);
new_eye_idxs_Q = find([location_data_Q(:).IsNewEye]);
new_eye_idxs = find([dbt(:).IsNewEye]);

for ne = 1:length(new_eye_idxs)
    
    if ne == length(new_eye_idxs)
        idxs_in_eye_Q = new_eye_idxs_Q(ne) : length(location_data_Q);
        idxs_in_eye = new_eye_idxs(ne) : length(dbt);
    else
        idxs_in_eye_Q = new_eye_idxs_Q(ne) : (new_eye_idxs_Q(ne+1) - 1);
        idxs_in_eye = new_eye_idxs(ne) : (new_eye_idxs(ne+1) - 1);
    end
    
    num_locations_in_eye = sum([location_data_Q(idxs_in_eye_Q).NumberOfLocationsInQuarter]);
    num_fluoro_in_eye = sum([location_data_Q(idxs_in_eye_Q).NumberOfFluoroInQuarter]);
    num_crossed_in_eye = sum([location_data_Q(idxs_in_eye_Q).NumberOfCrossedInQuarter]);
    num_deposits_in_eye = sum([location_data_Q(idxs_in_eye_Q).NumberOfDepositsInQuarter]);
    
    for ei = idxs_in_eye
        dbt(ei).NumberOfLocationsInEye = num_locations_in_eye;
        dbt(ei).NumberOfFluoroInEye = num_fluoro_in_eye;
        dbt(ei).NumberOfCrossedInEye = num_crossed_in_eye;
        dbt(ei).NumberOfDepositsInEye = num_deposits_in_eye;
    end
end

% number of quarters, locations, and deposits in each subject
location_data_E = dbt(new_eye_idxs);
new_subject_idxs_E = find([location_data_E(:).IsNewSubject]);
new_subject_idxs = find([dbt(:).IsNewSubject]);

for ns = 1:length(new_subject_idxs)
    
    if ns == length(new_subject_idxs)
        idxs_in_subject_E = new_subject_idxs_E(ns) : length(location_data_E);
        idxs_in_subject = new_subject_idxs(ns) : length(dbt);
    else
        idxs_in_subject_E = new_subject_idxs_E(ns) : (new_subject_idxs_E(ns+1) - 1);
        idxs_in_subject = new_subject_idxs(ns) : (new_subject_idxs(ns+1) - 1);
    end
    
    num_quarters_in_subject = sum([location_data_E(idxs_in_subject_E).NumberOfQuartersInEye]);
    num_locations_in_subject = sum([location_data_E(idxs_in_subject_E).NumberOfLocationsInEye]);
    num_fluoro_in_subject = sum([location_data_E(idxs_in_subject_E).NumberOfFluoroInEye]);
    num_crossed_in_subject = sum([location_data_E(idxs_in_subject_E).NumberOfCrossedInEye]);
    num_deposits_in_subject = sum([location_data_E(idxs_in_subject_E).NumberOfDepositsInEye]);
    
    for si = idxs_in_subject
        dbt(si).NumberOfQuartersInSubject = num_quarters_in_subject;
        dbt(si).NumberOfLocationsInSubject = num_locations_in_subject;
        dbt(si).NumberOfFluoroInSubject = num_fluoro_in_subject;
        dbt(si).NumberOfCrossedInSubject = num_crossed_in_subject;
        dbt(si).NumberOfDepositsInSubject = num_deposits_in_subject;
    end
end

%% order the fields for better readability
dbt = orderfields(dbt,...
    {'SubjectIdx', 'EyeIdx', 'QuarterIdx', 'LocationIdx',...
    'IsNewSubject', 'SubjectId', 'Age', 'Gender', 'CauseOfDeath', 'TimeOfDeath',...
    'MedicalHistory', 'AD_Positive',...    
    'Diagnosis1Type', 'Diagnosis1Level', 'Is1PrimaryDiagnosis',...
    'Diagnosis2Type', 'Diagnosis2Level', 'Is2PrimaryDiagnosis',...
    'SubjectSampleIdx',...
    'NumberOfEyesInSubject', 'NumberOfQuartersInSubject', 'NumberOfLocationsInSubject',...
    'NumberOfCrossedInSubject', 'NumberOfFluoroInSubject', 'NumberOfDepositsInSubject',...
    'SubjectNotes'...
    'IsNewEye', 'EyeSource', 'EyeType', 'InitialFixative', 'InitialFixativePercent',...
    'InitialFixingTime', 'DisectionDoneBy',...
    'NumberOfQuartersInEye', 'NumberOfLocationsInEye',...
    'NumberOfCrossedInEye', 'NumberOfFluoroInEye', 'NumberOfDepositsInEye',...
    'SampleNotes',...
    'IsNewQuarter', 'QuarterNumber', 'QuarterArbitrary',...
    'MountingDoneBy', 'MountingDate', 'Stain', 'QuarterType'...
    'NumberOfLocationsInQuarter',...
    'NumberOfCrossedInQuarter', 'NumberOfFluoroInQuarter', 'NumberOfDepositsInQuarter',...
    'QuarterNotes',...
    'LocationNumber', 'Deposit', 'XCoord', 'YCoord', 'RadDistFromFovea',...
    'LocationNotes'...
    'Magnification', 'BWPixelSizeMicrons', 'RGBPixelSizeMicrons',...
    'FluoroSignature', 'CrossedSignature', 'VisualSignature',...
    'SessionDoneBy', 'SessionRejected', 'RejectedReason', 'RejectedBy', 'SessionNotes',...
    'IsRegistered', 'RegistrationType', 'RegistrationDoneBy', 'RegistrationNotes',...
    'IsProcessed', 'MMOutOfRangePixelsRatio', 'MMProcessedBy'});

%% convert to a table, and categorical variables (where necessary)
dbt = struct2table(dbt);  % for 'DataBase Table'
for col = 1:length(dbt.Properties.VariableNames)
    column_type = class(dbt.(col));
    if ~strcmp(column_type, 'double') && ~strcmp(column_type, 'logical')
        dbt.(col) = categorical(dbt.(col));
    end    
end

%% Metadata removed from the structure

%     data(i).NumberOfSamples = subject_metadata.samples;       % empty for all
%         data(i).EyeNumber = sample_metadata.eyeNumber;        % redundant, equal to EyeIdx
        % secondary fixative removed; only entered for one location (s 30, e 1, q 1, l 1) with a note of: 'This was practice, we do not have this eye.'
%         try location_data(i).SecondaryFixative = sample_metadata.secondaryFixative.displayString; catch, location_data(i).SecondaryFixative =  []; end
%         location_data(i).SecondaryFixativePercent = sample_metadata.secondaryFixativePercent;
%         location_data(i).SecondaryFixingTime = sample_metadata.secondaryFixingTime;
%         location_data(i).StorageLocation = sample_metadata.storageLocation;      % removed - all some variation of Campbell's lab fridge
%             location_data(i).SlideMaterial = quarter_metadata.slideMaterial;   % removed - all "Glass"
%             data(i).QuarterLocationIndex = quarter_metadata.locationIndex;    % mostly 0, otherwise not understood            
%             data(i).QuarterIsSelected = quarter_metadata.isSelected;          % empty for all
%             data(i).Locations = quarter_metadata.locations;                   % empty for all
%                 data(i).LocationIsSelected = location_metadata.isSelected;    % empty for all
%                 data(i).Instrument = session_metadata.instrument;                     % same for all ('Nikon Eclipse Ti-U')
%                     location_data(i).RegistrationParams = session_metadata.registrationParams;  % removed - empty for all
%                     location_data(i).RegistrationParams = [];     % removed - empty for all
%                         try location_data(i).MMComputationType =
%                         session_metadata.muellerMatrixComputationType.displayString; catch, location_data(i).MMComputationType = []; end      % removed - is 'Frank''s Program (Correct)' for all that are processed
%                         try location_data(i).MMComputationExplanation = session_metadata.muellerMatrixComputationType.explanationString; catch, location_data(i).MMComputationExplanation = []; end   % removed - same for all
%                         try location_data(i).MMNormalizationType = session_metadata.muellerMatrixNormalizationType.displayString; catch, location_data(i).MMNormalizationType = []; end       % removed - same for all
%                         try location_data(i).MMNormalizationExplanation = session_metadata.muellerMatrixNormalizationType.explanationString; catch, location_data(i).MMNormalizationExplanation = []; end     % removed - same for all                                       
%                         data(i).MMOnly = session_metadata.muellerMatrixOnly;       % 0 or empty for all
%                         data(i).MMComputationVersionNumber = session_metadata.versionNumber;        % 1 or empty for all
%                         data(i).ProcessingNotes = session_metadata.notes;     % empty for all

end

function [ filtered_data ] = filter_data( field_data, data_type, label_empty )
%FILTER_DATA filters the metadata data to ensure it is the correct type
%before being entered into the large data structure
%   [ filtered_data ] = filter_data( field_data, data_type, label_empty ):
%
% filtered_data is the output of the function, turned into a suitable data
% type for the data structure. If the input field_data is empty,
% filtered_data will be the correct missing value of NaN for continuous
% variables, or an empty string for nominal categorical variables.
%
% field_data is the input - it is the data read directly from the
% metadata file. It will be of data type logical, double, or string.
% Importantly, it is also frequently empty. This function was written to
% avoid making an isempty() check repeatedly in Create_Metadata_Structure.m
%
% data_type is either 'nominal' or 'continuous', for nominal categorical
% variables or continuous numerical variables
%
% label_empty is a boolean, if it is 1 and field_data is empty,
% filtered_data will be 'Empty' for 'nominal' data_type (instead of an 
% empty string), but still NaN for 'continuous' data type. If label_empty
% is 0, filtered data will be an empty string for 'nominal' data_type.

switch data_type
    case 'continuous'
        if isempty(field_data)
            filtered_data = NaN;
        else
            filtered_data = field_data;
        end        
    case 'nominal'
        if isempty(field_data)
            if label_empty
                filtered_data = 'Empty';
            else
                filtered_data = '';
            end
        else
            filtered_data = num2str(field_data);
        end
    otherwise
        error('Please enter a valid data type: ''continuous'' or ''nominal''')       
end

end

function [ dbt ] = add_disease_stage( dbt )
% Adds the information about the stage of AD into the database table. Reads
% info from a specific excel file, and includes all of the different
% methods for ranking the severity of the disease.
%
% Erik Mason (erikmason04@gmail.com), Summer 2017
% Started September 11th, 2017
% Made into a function for Create_Database_Table.m on Sept 21st, 2017

%% Load in the database table and read the excel file

[~,~,excel_data] = xlsread('Y:\shared\Tissue\Human From Ian Mackenzie\AAIC 2017 Stats and Figures\OFFICIAL AD eyes final rating with AD likelihood (WITH AB FROM RETINAS)- Ian Mackenzie.xlsx', 2, 'A1:M32');
excel_data_unaltered = excel_data;

%% Find out which row in the excel data is which subject (index) in the table

dbt_s = dbt(dbt.IsNewSubject,:);
subject_names = cellstr(dbt_s.SubjectId);

excel_data(:,2:end+1) = excel_data;
excel_data(:,1) = {[]};
excel_data(1,1) = {'Subject Index'};

for row = 2:length(excel_data)
    excel_data(row,1) = {find(~cellfun(@isempty, strfind(subject_names, excel_data{row,2})))};
end

%% Clean up the entries

% Braak stage (tau)
Braak_stage = excel_data(2:end,5);
for i = 1:length(Braak_stage)
    if strcmp(Braak_stage{i},'N/A')
        Braak_stage{i} = '';
    elseif isa(Braak_stage{i},'double')
        Braak_stage{i} = num2str(Braak_stage{i});
    else
        Braak_stage{i} = char(Braak_stage{i});
    end
end

excel_data(2:end,5) = Braak_stage;

% NP (CERAD) (Biel)
NP = excel_data(2:end,6);
for i = 1:length(NP)
    NP{i} = strtrim(NP{i});
end

excel_data(2:end,6) = NP;

% DP (CERAD) (Biel)
DP = excel_data(2:end,7);
for i = 1:length(DP)
    DP{i} = strtrim(DP{i});
end

excel_data(2:end,7) = DP;

% A-beta (Thal)
for r = 1:size(excel_data,1)
    excel_data{r,8} = num2str(excel_data{r,8}); % convert to strings, to convert to categorical later
end

% CAA (CR)
CAA_CR = excel_data(2:end,9);
for i = 1:length(CAA_CR)
    temp = CAA_CR{i};
    temp = strtrim(temp);
    idx = strfind(temp, '(was');
    if ~isempty(idx)
        temp = temp(1:idx-1);
    end
    CAA_CR{i} = temp;
end

excel_data(2:end,9) = CAA_CR;

% CAA (Abeta)
CAA_Abeta = excel_data(2:end,10);
for i = 1:length(CAA_Abeta)
    temp = CAA_Abeta{i};
    temp = strtrim(temp);
    idx = strfind(temp, '(was');
    if ~isempty(idx)
        temp = temp(1:idx-1);
    end
    CAA_Abeta{i} = temp;
end

excel_data(2:end,10) = CAA_Abeta;

% CAA (Abeta+CR)
CAA_AbetaCR = excel_data(2:end,11);
for i = 1:length(CAA_AbetaCR)
    temp = CAA_AbetaCR{i};
    if isnan(temp)
        CAA_AbetaCR{i} = '';
    else
        temp = strtrim(temp);
        CAA_AbetaCR{i} = temp;
    end
end

excel_data(2:end,11) = CAA_AbetaCR;

% ABC score
ABC = excel_data(2:end,13);
for i = 1:length(ABC)
    ABC{i} = strtrim(ABC{i});
end

excel_data(2:end,13) = ABC;

% likelihood is fine 

%% Split up the table, insert the diagnoses levels, and recombine

split_idx = find(~cellfun(@isempty,strfind(dbt.Properties.VariableNames,'NumberOfEyesInSubject')));
dbt1 = dbt(:,1:(split_idx-1));
dbt2 = dbt(:,split_idx:end);

dbt1.Braak_stage_tau(:,1) = {''};
dbt1.NP_CERAD_Biel(:,1) = {''};
dbt1.DP_CERAD_Biel(:,1) = {''};
dbt1.A_beta_thal(:,1) = {''};
dbt1.CAA_CR(:,1) = {''};
dbt1.CAA_A_beta(:,1) = {''};
dbt1.CAA_A_beta_and_CR(:,1) = {''};
dbt1.ABC_score(:,1) = {''};
dbt1.Likelihood_of_AD(:,1) = {''};

for row = 2:length(excel_data)
    
    if ~isempty(excel_data{row,1})        
        dbt1.Braak_stage_tau(dbt1.SubjectIdx == excel_data{row,1}, 1) = excel_data(row,5);
        dbt1.NP_CERAD_Biel(dbt1.SubjectIdx == excel_data{row,1}, 1) = excel_data(row,6);
        dbt1.DP_CERAD_Biel(dbt1.SubjectIdx == excel_data{row,1}, 1) = excel_data(row,7);
        dbt1.A_beta_thal(dbt1.SubjectIdx == excel_data{row,1}, 1) = excel_data(row,8);
        dbt1.CAA_CR(dbt1.SubjectIdx == excel_data{row,1}, 1) = excel_data(row,9);
        dbt1.CAA_A_beta(dbt1.SubjectIdx == excel_data{row,1}, 1) = excel_data(row,10);
        dbt1.CAA_A_beta_and_CR(dbt1.SubjectIdx == excel_data{row,1}, 1) = excel_data(row,11);
        dbt1.ABC_score(dbt1.SubjectIdx == excel_data{row,1}, 1) = excel_data(row,13);
        dbt1.Likelihood_of_AD(dbt1.SubjectIdx == excel_data{row,1}, 1) = excel_data(row,14);        
    end
    
end

% convert to categorical type
for col = split_idx:width(dbt1)
    dbt1.(col) = categorical(dbt1.(col),'Ordinal',1);
end

% reorder the ordinal categories
NP = dbt1.NP_CERAD_Biel;
NP = reordercats(NP, {'negative', 'sparse', 'moderate', 'frequent'});
dbt1.NP_CERAD_Biel = NP;
DP = dbt1.DP_CERAD_Biel;
DP = reordercats(DP, {'negative', 'sparse', 'moderate', 'frequent'});
dbt1.DP_CERAD_Biel = DP;
CAA_CR = dbt1.CAA_CR;
CAA_CR = reordercats(CAA_CR, {'not done', 'negative', 'mild', 'moderate', 'severe'});
dbt1.CAA_CR = CAA_CR;
CAA_Abeta = dbt1.CAA_A_beta;
CAA_Abeta = reordercats(CAA_Abeta, {'negative', 'mild', 'moderate', 'severe'});
dbt1.CAA_A_beta = CAA_Abeta;
CAA = dbt1.CAA_A_beta_and_CR;
CAA = reordercats(CAA, {'negative', 'mild', 'moderate', 'severe'});
dbt1.CAA_A_beta_and_CR = CAA;
% ABC score is already ordered
Likelihood = dbt1.Likelihood_of_AD;
Likelihood = reordercats(Likelihood, {'none', 'low to none', 'low', 'intermediate', 'high'});
dbt1.Likelihood_of_AD = Likelihood;

dbt = [dbt1 dbt2];

end

function [ dbt ] = merge_old_dbt_data( old_dbt, dbt, recalculate_all )
% Merges data from the previous dbt into the new one. Specifically,
% segmentation information, and polarization property statistics, which
% take some time to calculate. Any segmentation or polarization property
% information contianed in old_dbt will be added into dbt, to the row with
% the same indices (subject, eye, quarter, location)

%% Create the columns in the dbt for segmentation and polarization properties, but don't transfer data yet

old_columns = old_dbt.Properties.VariableNames;

old_IsSegmented_col_idx = find(~cellfun(@isempty, strfind(old_columns, 'IsSegmented')));  % "IsSegmented" is the first variable created by the segmentation code
old_FirstPol_col_idx = find(~cellfun(@isempty, strfind(old_columns, 'Background_Diattenuation_45_AbsMean')));  % "Background_Diattenuation_45_AbsMean" is the first variable created by the polarization property statistics

if recalculate_all
    seg_pol_cols = old_dbt(:,old_IsSegmented_col_idx:old_FirstPol_col_idx-1);
else
    seg_pol_cols = old_dbt(:,old_IsSegmented_col_idx:end);
end

if height(seg_pol_cols) > height(dbt)
    seg_pol_cols = seg_pol_cols(1:height(dbt),:);           % crop off rows until the tables are the same height
elseif height(seg_pol_cols) < height(dbt)
    for i = 1:(height(dbt) - height(seg_pol_cols))
        seg_pol_cols = [seg_pol_cols; seg_pol_cols(end,:)]; % copy the last row until the tables are the same height
    end
end

is_categorical = false(1,width(seg_pol_cols));
for c = 1:width(seg_pol_cols)
    col = seg_pol_cols.(c);
    switch class(col)
        case 'double'
            col = NaN(height(dbt),1);
            seg_pol_cols.(c) = col;            
        case 'logical'
            col = false(height(dbt),1);
            seg_pol_cols.(c) = col;
        case 'categorical'
            temp = cell(height(dbt),1);
            temp(:) = {''};
            seg_pol_cols.(c) = categorical(temp);
            is_categorical(c) = true;
    end
end

dbt = [dbt, seg_pol_cols];

columns = dbt.Properties.VariableNames;
IsSegmented_col_idx = find(~cellfun(@isempty, strfind(columns, 'IsSegmented')));

%% loop through the old dbt, move the segmentation and polarization property information to the new dbt

cat_idxs = find(is_categorical) + IsSegmented_col_idx - 1;
old_cat_idxs = find(is_categorical) + old_IsSegmented_col_idx - 1;

noncat_idxs = find(~is_categorical) + IsSegmented_col_idx - 1;
old_noncat_idxs = find(~is_categorical) + old_IsSegmented_col_idx - 1;

for old_r = 1:height(old_dbt)
    
    if rem(old_r,250) == 0, disp(['Merged up to row ', num2str(old_r)]), end
    
    r = (dbt.SubjectIdx == old_dbt.SubjectIdx(old_r))...
        & (dbt.EyeIdx == old_dbt.EyeIdx(old_r))...
        & (dbt.QuarterIdx == old_dbt.QuarterIdx(old_r))...
        & (dbt.LocationIdx == old_dbt.LocationIdx(old_r));
              
    dbt(r, noncat_idxs) = old_dbt(old_r, old_noncat_idxs);

    for cc = 1:length(cat_idxs)
        if ~isundefined(old_dbt{old_r, old_cat_idxs(cc)})
            dbt(r, cat_idxs(cc)) = old_dbt(old_r, old_cat_idxs(cc));
        end
    end
    
end

end

function dbt = calculate_polarization_stats( dbpaths, dbt, recalculate_all )
% Calculates statistics (mean, median, std, etc) on polarization property
% images of database images. Differentiates between non-deposit locations
% and deposit locations. For images of deposits, segmentation is used to
% differentiate the deposit from the background (segmentation is performed
% through the Segment_Database_Images.m script). The statistics are saved
% into the "dbt" table, so that they can be plotted along with deposit 
% location and other metadata.
%
% Erik Mason (erikmason04@gmail.com), Summer 2017
% Started August 24th, 2017
% Remade to use a table datatype Sept 5th, 2017
% Made into a function for Create_Database_Table.m on Sept 28th, 2017
%
% POSSIBLE TO-DO:
% somewhat DONE - Better segmenation, or checking mask to see if the only labelled parts
% are due to a dust spot. Improper segmentation could provide false
% results. For example, the background properties of images with a deposit
% could be calculated to be higher than non-deposit backgrounds, only 
% because the segmentation did not include the entire deposit and some of 
% the high-value deposit pixels were labelled as background pixels
%
% DONE - Filtering data more than just getting rid of NaNs and Infs, for example
% rejecting data outside of the expected range (ex 0 - 180 for retardance)
%
% DONE - Add boolean variable to indicate a location marked as a deposit, that
% had an empty segmentation mask. May not be relevant until the
% segmentation is improved, but could be useful.

%% Loop through the data, reading in the polarization property images and calculating statistics

if ~recalculate_all
    col_names = dbt.Properties.VariableNames;
    first_pol_property_col = find(strcmp(col_names, 'Background_Diattenuation_45_AbsMean'));
end

num_locations = height(dbt);

for i = 1:num_locations   
    
    if dbt.IsSegmented(i) && dbt.IsProcessed(i)  &&...
            ( recalculate_all || all(isnan(table2array(dbt(i, first_pol_property_col:end)))) )
        
        s = dbt.SubjectIdx(i);
        e = dbt.EyeIdx(i);
        q = dbt.QuarterIdx(i);
        l = dbt.LocationIdx(i);
        
        disp([num2str(i),'/',num2str(num_locations)])
        disp([s,e,q,l])
        
        seg_dir = dir([dbpaths(s).Eye(e).Quarter(q).Location(l).FolderPath, 'Segmentation\Manually*.mat']);
        load([dbpaths(s).Eye(e).Quarter(q).Location(l).FolderPath, 'Segmentation\',seg_dir(1).name])  % variable named segmentation_mask
        mask_empty = nnz(segmentation_mask) == 0;
        bg_idx = ~segmentation_mask;        
        if mask_empty
            dp_d = NaN;
        else
            dp_idx = segmentation_mask;
        end        
        
        % Diattenuation
        if ~isempty(dbpaths(s).Eye(e).Quarter(q).Location(l).DiattenuationImages)                        
            for p_i = 1:5            

                load(dbpaths(s).Eye(e).Quarter(q).Location(l).DiattenuationImages(p_i).Path)
                data = data(4:end-3, 4:end-3);      % crop the edges               
                
                % seperate deposit and background pixels
                full_d = data(:);
                full_d(isnan(full_d) | isinf(full_d)) = [];                    
                if any(size(data) ~= size(segmentation_mask))
                    bg_d = full_d;
                    dp_d = NaN;
                else                    
                    bg_d = data(bg_idx);
                    bg_d(isnan(bg_d) | isinf(bg_d)) = [];
                    if ~mask_empty
                        dp_d = data(dp_idx);
                        dp_d(isnan(dp_d) | isinf(dp_d)) = [];
                    end                                                     
                end
                
                switch p_i
                    case 1   % Diattenuation_45
                        bg_d(bg_d > 1 | bg_d < -1) = [];
                        dp_d(dp_d > 1 | dp_d < -1) = [];
                        full_d(full_d > 1 | full_d < -1) = [];
                        
                        dbt.Background_Diattenuation_45_AbsMean(i,1) = mean(abs(bg_d));
                        dbt.Deposit_Diattenuation_45_AbsMean(i,1) = mean(abs(dp_d));
                        dbt.Background_Diattenuation_45_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_Diattenuation_45_Mean(i,1) = mean(dp_d);
                        
                        dbt.Background_Diattenuation_45_AbsMedian(i,1) = median(abs(bg_d));
                        dbt.Deposit_Diattenuation_45_AbsMedian(i,1) = median(abs(dp_d));
                        dbt.Background_Diattenuation_45_Median(i,1) = median(bg_d);
                        dbt.Deposit_Diattenuation_45_Median(i,1) = median(dp_d);
                        
                        dbt.Background_Diattenuation_45_Std(i,1) = std(bg_d);
                        dbt.Deposit_Diattenuation_45_Std(i,1) = std(dp_d);

                        dbt.Background_Diattenuation_45_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_Diattenuation_45_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Diattenuation_45_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Diattenuation_45_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Diattenuation_45_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_Diattenuation_45_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Diattenuation_45_Std(i,1) = std(full_d);
                        
                    case 2  % Diattenuation_Circ
                        bg_d(bg_d > 1 | bg_d < -1) = [];
                        dp_d(dp_d > 1 | dp_d < -1) = [];
                        full_d(full_d > 1 | full_d < -1) = [];
                        
                        dbt.Background_Diattenuation_Circ_AbsMean(i,1) = mean(abs(bg_d));
                        dbt.Deposit_Diattenuation_Circ_AbsMean(i,1) = mean(abs(dp_d));
                        dbt.Background_Diattenuation_Circ_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_Diattenuation_Circ_Mean(i,1) = mean(dp_d);
                        
                        dbt.Background_Diattenuation_Circ_AbsMedian(i,1) = median(abs(bg_d));
                        dbt.Deposit_Diattenuation_Circ_AbsMedian(i,1) = median(abs(dp_d));
                        dbt.Background_Diattenuation_Circ_Median(i,1) = median(bg_d);
                        dbt.Deposit_Diattenuation_Circ_Median(i,1) = median(dp_d);

                        dbt.Background_Diattenuation_Circ_Std(i,1) = std(bg_d);
                        dbt.Deposit_Diattenuation_Circ_Std(i,1) = std(dp_d);

                        dbt.Background_Diattenuation_Circ_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_Diattenuation_Circ_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Diattenuation_Circ_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Diattenuation_Circ_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Diattenuation_Circ_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_Diattenuation_Circ_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Diattenuation_Circ_Std(i,1) = std(full_d);
                        
                    case 3  % Diattenuation_Full
                        bg_d(bg_d > 1 | bg_d < 0) = [];
                        dp_d(dp_d > 1 | dp_d < 0) = [];
                        full_d(full_d > 1 | full_d < 0) = [];
                        
                        dbt.Background_Diattenuation_Full_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_Diattenuation_Full_Mean(i,1) = mean(dp_d);

                        dbt.Background_Diattenuation_Full_Median(i,1) = median(bg_d);
                        dbt.Deposit_Diattenuation_Full_Median(i,1) = median(dp_d);

                        dbt.Background_Diattenuation_Full_Std(i,1) = std(bg_d);
                        dbt.Deposit_Diattenuation_Full_Std(i,1) = std(dp_d);

                        dbt.Background_Diattenuation_Full_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_Diattenuation_Full_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Diattenuation_Full_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Diattenuation_Full_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Diattenuation_Full_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_Diattenuation_Full_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Diattenuation_Full_Std(i,1) = std(full_d);
                        
                    case 4  % Diattenuation_Horz
                        bg_d(bg_d > 1 | bg_d < -1) = [];
                        dp_d(dp_d > 1 | dp_d < -1) = [];
                        full_d(full_d > 1 | full_d < -1) = [];
                        
                        dbt.Background_Diattenuation_Horz_AbsMean(i,1) = mean(abs(bg_d));
                        dbt.Deposit_Diattenuation_Horz_AbsMean(i,1) = mean(abs(dp_d));
                        dbt.Background_Diattenuation_Horz_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_Diattenuation_Horz_Mean(i,1) = mean(dp_d);

                        dbt.Background_Diattenuation_Horz_AbsMedian(i,1) = median(abs(bg_d));
                        dbt.Deposit_Diattenuation_Horz_AbsMedian(i,1) = median(abs(dp_d));
                        dbt.Background_Diattenuation_Horz_Median(i,1) = median(bg_d);
                        dbt.Deposit_Diattenuation_Horz_Median(i,1) = median(dp_d);

                        dbt.Background_Diattenuation_Horz_Std(i,1) = std(bg_d);
                        dbt.Deposit_Diattenuation_Horz_Std(i,1) = std(dp_d);

                        dbt.Background_Diattenuation_Horz_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_Diattenuation_Horz_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Diattenuation_Horz_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Diattenuation_Horz_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Diattenuation_Horz_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end 
                        
                        dbt.FullImage_Diattenuation_Horz_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Diattenuation_Horz_Std(i,1) = std(full_d);
                        
                    case 5  % Diattenuation_Lin
                        bg_d(bg_d > 1 | bg_d < 0) = [];
                        dp_d(dp_d > 1 | dp_d < 0) = [];
                        full_d(full_d > 1 | full_d < 0) = [];
                        
                        dbt.Background_Diattenuation_Lin_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_Diattenuation_Lin_Mean(i,1) = mean(dp_d);

                        dbt.Background_Diattenuation_Lin_Median(i,1) = median(bg_d);
                        dbt.Deposit_Diattenuation_Lin_Median(i,1) = median(dp_d);

                        dbt.Background_Diattenuation_Lin_Std(i,1) = std(bg_d);
                        dbt.Deposit_Diattenuation_Lin_Std(i,1) = std(dp_d);

                        dbt.Background_Diattenuation_Lin_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_Diattenuation_Lin_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Diattenuation_Lin_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Diattenuation_Lin_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Diattenuation_Lin_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_Diattenuation_Lin_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Diattenuation_Lin_Std(i,1) = std(full_d);
                        
                end
            end
        end        

        % General Metrics
        if ~isempty(dbpaths(s).Eye(e).Quarter(q).Location(l).GeneralMetricsImages)

            for p_i = 1:3

                load(dbpaths(s).Eye(e).Quarter(q).Location(l).GeneralMetricsImages(p_i).Path)
                data = data(4:end-3, 4:end-3);      % crop the edges

                % seperate deposit and background pixels
                full_d = data(:);
                full_d(isnan(full_d) | isinf(full_d)) = [];                    
                if any(size(data) ~= size(segmentation_mask))
                    bg_d = full_d;
                    dp_d = NaN;
                else                    
                    bg_d = data(bg_idx);
                    bg_d(isnan(bg_d) | isinf(bg_d)) = [];
                    if ~mask_empty
                        dp_d = data(dp_idx);
                        dp_d(isnan(dp_d) | isinf(dp_d)) = [];
                    end                                                     
                end

                switch p_i
                    case 1  % GeneralMetrics_DI
                        bg_d(bg_d > 1 | bg_d < 0) = [];
                        dp_d(dp_d > 1 | dp_d < 0) = [];
                        full_d(full_d > 1 | full_d < 0) = [];
                        
                        dbt.Background_GeneralMetrics_DI_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_GeneralMetrics_DI_Mean(i,1) = mean(dp_d);

                        dbt.Background_GeneralMetrics_DI_Median(i,1) = median(bg_d);
                        dbt.Deposit_GeneralMetrics_DI_Median(i,1) = median(dp_d);

                        dbt.Background_GeneralMetrics_DI_Std(i,1) = std(bg_d);
                        dbt.Deposit_GeneralMetrics_DI_Std(i,1) = std(dp_d);

                        dbt.Background_GeneralMetrics_DI_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_GeneralMetrics_DI_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_GeneralMetrics_DI_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_GeneralMetrics_DI_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_GeneralMetrics_DI_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_GeneralMetrics_DI_Mean(i,1) = mean(full_d);
                        dbt.FullImage_GeneralMetrics_DI_Std(i,1) = std(full_d);
                        
                    case 2  % GeneralMetrics_DP
                        bg_d(bg_d > 1 | bg_d < 0) = [];
                        dp_d(dp_d > 1 | dp_d < 0) = [];
                        full_d(full_d > 1 | full_d < 0) = [];
                        
                        dbt.Background_GeneralMetrics_DP_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_GeneralMetrics_DP_Mean(i,1) = mean(dp_d);

                        dbt.Background_GeneralMetrics_DP_Median(i,1) = median(bg_d);
                        dbt.Deposit_GeneralMetrics_DP_Median(i,1) = median(dp_d);

                        dbt.Background_GeneralMetrics_DP_Std(i,1) = std(bg_d);
                        dbt.Deposit_GeneralMetrics_DP_Std(i,1) = std(dp_d);

                        dbt.Background_GeneralMetrics_DP_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_GeneralMetrics_DP_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_GeneralMetrics_DP_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_GeneralMetrics_DP_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_GeneralMetrics_DP_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_GeneralMetrics_DP_Mean(i,1) = mean(full_d);
                        dbt.FullImage_GeneralMetrics_DP_Std(i,1) = std(full_d);
                        
                    case 3  % GeneralMetrics_Q
                        bg_d(bg_d > 3 | bg_d < 0) = [];
                        dp_d(dp_d > 3 | dp_d < 0) = [];
                        full_d(full_d > 3 | full_d < 0) = [];
                        
                        dbt.Background_GeneralMetrics_Q_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_GeneralMetrics_Q_Mean(i,1) = mean(dp_d);

                        dbt.Background_GeneralMetrics_Q_Median(i,1) = median(bg_d);
                        dbt.Deposit_GeneralMetrics_Q_Median(i,1) = median(dp_d);

                        dbt.Background_GeneralMetrics_Q_Std(i,1) = std(bg_d);
                        dbt.Deposit_GeneralMetrics_Q_Std(i,1) = std(dp_d);

                        dbt.Background_GeneralMetrics_Q_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_GeneralMetrics_Q_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_GeneralMetrics_Q_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_GeneralMetrics_Q_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_GeneralMetrics_Q_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_GeneralMetrics_Q_Mean(i,1) = mean(full_d);
                        dbt.FullImage_GeneralMetrics_Q_Std(i,1) = std(full_d);
                        
                end
            end
        end        

        % More Retardance Metrics
        if ~isempty(dbpaths(s).Eye(e).Quarter(q).Location(l).MoreRetardanceMetricsImages)
            
            for p_i = 1:3

                load(dbpaths(s).Eye(e).Quarter(q).Location(l).MoreRetardanceMetricsImages(p_i).Path)
                data = data(4:end-3, 4:end-3);      % crop the edges

                % seperate deposit and background pixels
                full_d = data(:);
                full_d(isnan(full_d) | isinf(full_d)) = [];                    
                if any(size(data) ~= size(segmentation_mask))
                    bg_d = full_d;
                    dp_d = NaN;
                else                    
                    bg_d = data(bg_idx);
                    bg_d(isnan(bg_d) | isinf(bg_d)) = [];
                    if ~mask_empty
                        dp_d = data(dp_idx);
                        dp_d(isnan(dp_d) | isinf(dp_d)) = [];
                    end                                                     
                end

                switch p_i
                    case 1  % RetardanceMetrics_Delta
                        bg_d(bg_d > 180 | bg_d < 0) = [];
                        dp_d(dp_d > 180 | dp_d < 0) = [];
                        full_d(full_d > 180 | full_d < 0) = [];
                        
                        dbt.Background_RetardanceMetrics_Delta_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_RetardanceMetrics_Delta_Mean(i,1) = mean(dp_d);

                        dbt.Background_RetardanceMetrics_Delta_Median(i,1) = median(bg_d);
                        dbt.Deposit_RetardanceMetrics_Delta_Median(i,1) = median(dp_d);

                        dbt.Background_RetardanceMetrics_Delta_Std(i,1) = std(bg_d);
                        dbt.Deposit_RetardanceMetrics_Delta_Std(i,1) = std(dp_d);

                        dbt.Background_RetardanceMetrics_Delta_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_RetardanceMetrics_Delta_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_RetardanceMetrics_Delta_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_RetardanceMetrics_Delta_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_RetardanceMetrics_Delta_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_RetardanceMetrics_Delta_Mean(i,1) = mean(full_d);
                        dbt.FullImage_RetardanceMetrics_Delta_Std(i,1) = std(full_d);
                        
                    case 2  % RetardanceMetrics_Psi
                        bg_d(bg_d > 90 | bg_d < -90) = [];
                        dp_d(dp_d > 90 | dp_d < -90) = [];
                        full_d(full_d > 90 | full_d < -90) = [];
                        
                        dbt.Background_RetardanceMetrics_Psi_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_RetardanceMetrics_Psi_Mean(i,1) = mean(dp_d);

                        dbt.Background_RetardanceMetrics_Psi_Median(i,1) = median(bg_d);
                        dbt.Deposit_RetardanceMetrics_Psi_Median(i,1) = median(dp_d);

                        dbt.Background_RetardanceMetrics_Psi_Std(i,1) = std(bg_d);
                        dbt.Deposit_RetardanceMetrics_Psi_Std(i,1) = std(dp_d);

                        dbt.Background_RetardanceMetrics_Psi_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_RetardanceMetrics_Psi_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_RetardanceMetrics_Psi_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_RetardanceMetrics_Psi_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_RetardanceMetrics_Psi_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_RetardanceMetrics_Psi_Mean(i,1) = mean(full_d);
                        dbt.FullImage_RetardanceMetrics_Psi_Std(i,1) = std(full_d);
                        
                    case 3  % RetardanceMetrics_Theta
                        bg_d(bg_d > 180 | bg_d < 0) = [];
                        dp_d(dp_d > 180 | dp_d < 0) = [];
                        full_d(full_d > 180 | full_d < 0) = [];
                        
                        dbt.Background_RetardanceMetrics_Theta_Mean(i,1) = (180/pi)*circ_mean(2*(pi/180)*bg_d)/2;
                        dbt.Deposit_RetardanceMetrics_Theta_Mean(i,1) = (180/pi)*circ_mean(2*(pi/180)*dp_d)/2;

                        dbt.Background_RetardanceMetrics_Theta_Std(i,1) = (180/pi)*circ_std(2*(pi/180)*bg_d)/2;
                        dbt.Deposit_RetardanceMetrics_Theta_Std(i,1) = (180/pi)*circ_std(2*(pi/180)*dp_d)/2;

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_RetardanceMetrics_Theta_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_RetardanceMetrics_Theta_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_RetardanceMetrics_Theta_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_RetardanceMetrics_Theta_Mean(i,1) = mean(full_d);
                        dbt.FullImage_RetardanceMetrics_Theta_Std(i,1) = std(full_d);
                        
                end
            end
        end

        % Polarizance
        if ~isempty(dbpaths(s).Eye(e).Quarter(q).Location(l).PolarizanceImages)

            for p_i = 1:5

                load(dbpaths(s).Eye(e).Quarter(q).Location(l).PolarizanceImages(p_i).Path)
                data = data(4:end-3, 4:end-3);      % crop the edges

                % seperate deposit and background pixels
                full_d = data(:);
                full_d(isnan(full_d) | isinf(full_d)) = [];                    
                if any(size(data) ~= size(segmentation_mask))
                    bg_d = full_d;
                    dp_d = NaN;
                else                    
                    bg_d = data(bg_idx);
                    bg_d(isnan(bg_d) | isinf(bg_d)) = [];
                    if ~mask_empty
                        dp_d = data(dp_idx);
                        dp_d(isnan(dp_d) | isinf(dp_d)) = [];
                    end                                                     
                end

                switch p_i
                    case 1  % Polarizance_45
                        bg_d(bg_d > 1 | bg_d < -1) = [];
                        dp_d(dp_d > 1 | dp_d < -1) = [];
                        full_d(full_d > 1 | full_d < -1) = [];
                        
                        dbt.Background_Polarizance_45_AbsMean(i,1) = mean(abs(bg_d));
                        dbt.Deposit_Polarizance_45_AbsMean(i,1) = mean(abs(dp_d));
                        dbt.Background_Polarizance_45_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_Polarizance_45_Mean(i,1) = mean(dp_d);
                        
                        dbt.Background_Polarizance_45_AbsMedian(i,1) = median(abs(bg_d));
                        dbt.Deposit_Polarizance_45_AbsMedian(i,1) = median(abs(dp_d));
                        dbt.Background_Polarizance_45_Median(i,1) = median(bg_d);
                        dbt.Deposit_Polarizance_45_Median(i,1) = median(dp_d);

                        dbt.Background_Polarizance_45_Std(i,1) = std(bg_d);
                        dbt.Deposit_Polarizance_45_Std(i,1) = std(dp_d);

                        dbt.Background_Polarizance_45_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_Polarizance_45_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Polarizance_45_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Polarizance_45_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Polarizance_45_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_Polarizance_45_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Polarizance_45_Std(i,1) = std(full_d);
                        
                    case 2  % Polarizance_Circ
                        bg_d(bg_d > 1 | bg_d < -1) = [];
                        dp_d(dp_d > 1 | dp_d < -1) = [];
                        full_d(full_d > 1 | full_d < -1) = [];
                        
                        dbt.Background_Polarizance_Circ_AbsMean(i,1) = mean(abs(bg_d));
                        dbt.Deposit_Polarizance_Circ_AbsMean(i,1) = mean(abs(dp_d));
                        dbt.Background_Polarizance_Circ_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_Polarizance_Circ_Mean(i,1) = mean(dp_d);

                        dbt.Background_Polarizance_Circ_AbsMedian(i,1) = median(abs(bg_d));
                        dbt.Deposit_Polarizance_Circ_AbsMedian(i,1) = median(abs(dp_d));
                        dbt.Background_Polarizance_Circ_Median(i,1) = median(bg_d);
                        dbt.Deposit_Polarizance_Circ_Median(i,1) = median(dp_d);

                        dbt.Background_Polarizance_Circ_Std(i,1) = std(bg_d);
                        dbt.Deposit_Polarizance_Circ_Std(i,1) = std(dp_d);

                        dbt.Background_Polarizance_Circ_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_Polarizance_Circ_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Polarizance_Circ_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Polarizance_Circ_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Polarizance_Circ_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_Polarizance_Circ_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Polarizance_Circ_Std(i,1) = std(full_d);
                        
                    case 3  % Polarizance_Full
                        bg_d(bg_d > 1 | bg_d < 0) = [];
                        dp_d(dp_d > 1 | dp_d < 0) = [];
                        full_d(full_d > 1 | full_d < 0) = [];
                        
                        dbt.Background_Polarizance_Full_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_Polarizance_Full_Mean(i,1) = mean(dp_d);

                        dbt.Background_Polarizance_Full_Median(i,1) = median(bg_d);
                        dbt.Deposit_Polarizance_Full_Median(i,1) = median(dp_d);

                        dbt.Background_Polarizance_Full_Std(i,1) = std(bg_d);
                        dbt.Deposit_Polarizance_Full_Std(i,1) = std(dp_d);

                        dbt.Background_Polarizance_Full_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_Polarizance_Full_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Polarizance_Full_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Polarizance_Full_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Polarizance_Full_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_Polarizance_Full_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Polarizance_Full_Std(i,1) = std(full_d);
                        
                    case 4  % Polarizance_Horz
                        bg_d(bg_d > 1 | bg_d < -1) = [];
                        dp_d(dp_d > 1 | dp_d < -1) = [];
                        full_d(full_d > 1 | full_d < -1) = [];
                        
                        dbt.Background_Polarizance_Horz_AbsMean(i,1) = mean(abs(bg_d));
                        dbt.Deposit_Polarizance_Horz_AbsMean(i,1) = mean(abs(dp_d));
                        dbt.Background_Polarizance_Horz_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_Polarizance_Horz_Mean(i,1) = mean(dp_d);

                        dbt.Background_Polarizance_Horz_AbsMedian(i,1) = median(abs(bg_d));
                        dbt.Deposit_Polarizance_Horz_AbsMedian(i,1) = median(abs(dp_d));
                        dbt.Background_Polarizance_Horz_Median(i,1) = median(bg_d);
                        dbt.Deposit_Polarizance_Horz_Median(i,1) = median(dp_d);

                        dbt.Background_Polarizance_Horz_Std(i,1) = std(bg_d);
                        dbt.Deposit_Polarizance_Horz_Std(i,1) = std(dp_d);

                        dbt.Background_Polarizance_Horz_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_Polarizance_Horz_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Polarizance_Horz_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Polarizance_Horz_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Polarizance_Horz_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_Polarizance_Horz_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Polarizance_Horz_Std(i,1) = std(full_d);
                        
                    case 5  % Polarizance_Lin
                        bg_d(bg_d > 1 | bg_d < 0) = [];
                        dp_d(dp_d > 1 | dp_d < 0) = [];
                        full_d(full_d > 1 | full_d < 0) = [];
                        
                        dbt.Background_Polarizance_Lin_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_Polarizance_Lin_Mean(i,1) = mean(dp_d);

                        dbt.Background_Polarizance_Lin_Median(i,1) = median(bg_d);
                        dbt.Deposit_Polarizance_Lin_Median(i,1) = median(dp_d);

                        dbt.Background_Polarizance_Lin_Std(i,1) = std(bg_d);
                        dbt.Deposit_Polarizance_Lin_Std(i,1) = std(dp_d);

                        dbt.Background_Polarizance_Lin_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_Polarizance_Lin_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Polarizance_Lin_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Polarizance_Lin_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Polarizance_Lin_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_Polarizance_Lin_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Polarizance_Lin_Std(i,1) = std(full_d);
                        
                end
            end
        end        

        % Retardance
        if ~isempty(dbpaths(s).Eye(e).Quarter(q).Location(l).RetardanceImages)
            
            for p_i = 1:5

                load(dbpaths(s).Eye(e).Quarter(q).Location(l).RetardanceImages(p_i).Path)
                data = data(4:end-3, 4:end-3);      % crop the edges

                % seperate deposit and background pixels
                full_d = data(:);
                full_d(isnan(full_d) | isinf(full_d)) = [];                    
                if any(size(data) ~= size(segmentation_mask))
                    bg_d = full_d;
                    dp_d = NaN;
                else                    
                    bg_d = data(bg_idx);
                    bg_d(isnan(bg_d) | isinf(bg_d)) = [];
                    if ~mask_empty
                        dp_d = data(dp_idx);
                        dp_d(isnan(dp_d) | isinf(dp_d)) = [];
                    end                                                     
                end

                switch p_i
                    case 1  % Retardance_45
                        bg_d(bg_d > 180 | bg_d < -180) = [];
                        dp_d(dp_d > 180 | dp_d < -180) = [];
                        full_d(full_d > 180 | full_d < -180) = [];
                        
                        dbt.Background_Retardance_45_Mean(i,1) = (180/pi)*circ_mean((pi/180)*bg_d);
                        dbt.Deposit_Retardance_45_Mean(i,1) = (180/pi)*circ_mean((pi/180)*dp_d);

                        dbt.Background_Retardance_45_Std(i,1) = (180/pi)*circ_std((pi/180)*bg_d);
                        dbt.Deposit_Retardance_45_Std(i,1) = (180/pi)*circ_std((pi/180)*dp_d);

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Retardance_45_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Retardance_45_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Retardance_45_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_Retardance_45_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Retardance_45_Std(i,1) = std(full_d);
                        
                    case 2  % Retardance_Circ
                        bg_d(bg_d > 180 | bg_d < -180) = [];
                        dp_d(dp_d > 180 | dp_d < -180) = [];
                        full_d(full_d > 180 | full_d < -180) = [];
                        
                        dbt.Background_Retardance_Circ_AbsMean(i,1) = mean(abs(bg_d));
                        dbt.Deposit_Retardance_Circ_AbsMean(i,1) = mean(abs(dp_d));
                        dbt.Background_Retardance_Circ_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_Retardance_Circ_Mean(i,1) = mean(dp_d);

                        dbt.Background_Retardance_Circ_AbsMedian(i,1) = median(abs(bg_d));
                        dbt.Deposit_Retardance_Circ_AbsMedian(i,1) = median(abs(dp_d));
                        dbt.Background_Retardance_Circ_Median(i,1) = median(bg_d);
                        dbt.Deposit_Retardance_Circ_Median(i,1) = median(dp_d);
                        
                        dbt.Background_Retardance_Circ_Std(i,1) = std(bg_d);
                        dbt.Deposit_Retardance_Circ_Std(i,1) = std(dp_d);

                        dbt.Background_Retardance_Circ_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_Retardance_Circ_MAD(i,1) = mad(dp_d,1);    % median absolute deviation
                       
                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Retardance_Circ_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Retardance_Circ_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Retardance_Circ_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_Retardance_Circ_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Retardance_Circ_Std(i,1) = std(full_d);
                        
                    case 3  % Retardance_Full
                        bg_d(bg_d > 180 | bg_d < 0) = [];
                        dp_d(dp_d > 180 | dp_d < 0) = [];
                        full_d(full_d > 180 | full_d < 0) = [];
                        
                        dbt.Background_Retardance_Full_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_Retardance_Full_Mean(i,1) = mean(dp_d);

                        dbt.Background_Retardance_Full_Median(i,1) = median(bg_d);
                        dbt.Deposit_Retardance_Full_Median(i,1) = median(dp_d);

                        dbt.Background_Retardance_Full_Std(i,1) = std(bg_d);
                        dbt.Deposit_Retardance_Full_Std(i,1) = std(dp_d);

                        dbt.Background_Retardance_Full_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_Retardance_Full_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Retardance_Full_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Retardance_Full_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Retardance_Full_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_Retardance_Full_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Retardance_Full_Std(i,1) = std(full_d);
                        
                    case 4  % Retardance_Horz
                        bg_d(bg_d > 180 | bg_d < -180) = [];
                        dp_d(dp_d > 180 | dp_d < -180) = [];
                        full_d(full_d > 180 | full_d < -180) = [];
                        
                        dbt.Background_Retardance_Horz_Mean(i,1) = (180/pi)*circ_mean((pi/180)*bg_d);
                        dbt.Deposit_Retardance_Horz_Mean(i,1) = (180/pi)*circ_mean((pi/180)*dp_d);

                        dbt.Background_Retardance_Horz_Std(i,1) = (180/pi)*circ_std((pi/180)*bg_d);
                        dbt.Deposit_Retardance_Horz_Std(i,1) = (180/pi)*circ_std((pi/180)*dp_d);

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Retardance_Horz_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Retardance_Horz_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Retardance_Horz_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end
                        
                        dbt.FullImage_Retardance_Horz_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Retardance_Horz_Std(i,1) = std(full_d);
                        
                    case 5  % Retardance_Lin
                        bg_d(bg_d > 180 | bg_d < 0) = [];
                        dp_d(dp_d > 180 | dp_d < 0) = [];
                        full_d(full_d > 180 | full_d < 0) = [];
                        
                        dbt.Background_Retardance_Lin_Mean(i,1) = mean(bg_d);
                        dbt.Deposit_Retardance_Lin_Mean(i,1) = mean(dp_d);

                        dbt.Background_Retardance_Lin_Median(i,1) = median(bg_d);
                        dbt.Deposit_Retardance_Lin_Median(i,1) = median(dp_d);

                        dbt.Background_Retardance_Lin_Std(i,1) = std(bg_d);
                        dbt.Deposit_Retardance_Lin_Std(i,1) = std(dp_d);

                        dbt.Background_Retardance_Lin_MAD(i,1) = mad(bg_d,1);    % median absolute deviation
                        dbt.Deposit_Retardance_Lin_MAD(i,1) = mad(dp_d,1);    % median absolute deviation

                        [bg_counts, bg_bin_centers] = hist(bg_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                        [~, bg_max_idx] = max(bg_counts);
                        dbt.Background_Retardance_Lin_Mode(i,1) = bg_bin_centers(bg_max_idx);

                        if numel(dp_d) == 1     % if it's been assigned a single NaN value (not a deposit)                  
                            dbt.Deposit_Retardance_Lin_Mode(i,1) = NaN;
                        else                    % if it is a deposit
                            [dp_counts, dp_bin_centers] = hist(dp_d, 512);   % 512 bins for two bins per pixel level in an 8-bit image. Chosen sort of arbitrarily
                            [~, dp_max_idx] = max(dp_counts);
                            dbt.Deposit_Retardance_Lin_Mode(i,1) = dp_bin_centers(dp_max_idx);
                        end 
                        
                        dbt.FullImage_Retardance_Lin_Mean(i,1) = mean(full_d);
                        dbt.FullImage_Retardance_Lin_Std(i,1) = std(full_d);
                        
                end
            end
        end
        
        % MM elements
        pol_dir = dir([dbpaths(s).Eye(e).Quarter(q).Location(l).FolderPath,'PS*(Polarization Analysis*']);
        MM_dir = dir([dbpaths(s).Eye(e).Quarter(q).Location(l).FolderPath,pol_dir(1).name,'\MM\*.mat']);
        load([dbpaths(s).Eye(e).Quarter(q).Location(l).FolderPath,pol_dir(1).name,'\MM\',MM_dir(1).name])
        data = data(4:end-3,4:end-3,:,:);              
        pol_im_wrong_size = (size(segmentation_mask,1) ~= size(data,1) | size(segmentation_mask,2) ~= size(data,2));
        
        for MM_r = 1:4
            for MM_c = 1:4
                
                MM_elem = data(:,:,MM_r,MM_c);
                
                full_d = MM_elem(:);
                full_d(isnan(full_d) | isinf(full_d)) = [];
                if pol_im_wrong_size
                    bg_d = full_d;
                    dp_d = NaN;
                else
                    bg_d = MM_elem(bg_idx);
                    bg_d(isnan(bg_d) | isinf(bg_d)) = [];
                    if ~mask_empty
                        dp_d = MM_elem(dp_idx);
                        dp_d(isnan(dp_d) | isinf(dp_d)) = [];
                    end
                end
                
                if MM_r == 1 && MM_c == 1
                    dbt.Background_MM_11_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_11_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_11_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_11_Median(i,1) = median(dp_d);
                    dbt.Background_MM_11_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_11_Std(i,1) = std(dp_d);
                    dbt.Background_MM_11_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_11_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 1 && MM_c == 2
                    dbt.Background_MM_12_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_12_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_12_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_12_Median(i,1) = median(dp_d);
                    dbt.Background_MM_12_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_12_Std(i,1) = std(dp_d);
                    dbt.Background_MM_12_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_12_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 1 && MM_c == 3
                    dbt.Background_MM_13_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_13_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_13_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_13_Median(i,1) = median(dp_d);
                    dbt.Background_MM_13_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_13_Std(i,1) = std(dp_d);
                    dbt.Background_MM_13_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_13_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 1 && MM_c == 4
                    dbt.Background_MM_14_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_14_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_14_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_14_Median(i,1) = median(dp_d);
                    dbt.Background_MM_14_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_14_Std(i,1) = std(dp_d);
                    dbt.Background_MM_14_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_14_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 2 && MM_c == 1
                    dbt.Background_MM_21_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_21_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_21_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_21_Median(i,1) = median(dp_d);
                    dbt.Background_MM_21_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_21_Std(i,1) = std(dp_d);
                    dbt.Background_MM_21_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_21_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 2 && MM_c == 2
                    dbt.Background_MM_22_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_22_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_22_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_22_Median(i,1) = median(dp_d);
                    dbt.Background_MM_22_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_22_Std(i,1) = std(dp_d);
                    dbt.Background_MM_22_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_22_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 2 && MM_c == 3
                    dbt.Background_MM_23_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_23_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_23_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_23_Median(i,1) = median(dp_d);
                    dbt.Background_MM_23_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_23_Std(i,1) = std(dp_d);
                    dbt.Background_MM_23_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_23_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 2 && MM_c == 4
                    dbt.Background_MM_24_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_24_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_24_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_24_Median(i,1) = median(dp_d);
                    dbt.Background_MM_24_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_24_Std(i,1) = std(dp_d);
                    dbt.Background_MM_24_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_24_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 3 && MM_c == 1
                    dbt.Background_MM_31_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_31_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_31_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_31_Median(i,1) = median(dp_d);
                    dbt.Background_MM_31_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_31_Std(i,1) = std(dp_d);
                    dbt.Background_MM_31_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_31_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 3 && MM_c == 2
                    dbt.Background_MM_32_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_32_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_32_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_32_Median(i,1) = median(dp_d);
                    dbt.Background_MM_32_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_32_Std(i,1) = std(dp_d);
                    dbt.Background_MM_32_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_32_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 3 && MM_c == 3
                    dbt.Background_MM_33_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_33_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_33_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_33_Median(i,1) = median(dp_d);
                    dbt.Background_MM_33_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_33_Std(i,1) = std(dp_d);
                    dbt.Background_MM_33_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_33_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 3 && MM_c == 4
                    dbt.Background_MM_34_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_34_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_34_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_34_Median(i,1) = median(dp_d);
                    dbt.Background_MM_34_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_34_Std(i,1) = std(dp_d);
                    dbt.Background_MM_34_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_34_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 4 && MM_c == 1
                    dbt.Background_MM_41_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_41_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_41_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_41_Median(i,1) = median(dp_d);
                    dbt.Background_MM_41_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_41_Std(i,1) = std(dp_d);
                    dbt.Background_MM_41_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_41_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 4 && MM_c == 2
                    dbt.Background_MM_42_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_42_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_42_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_42_Median(i,1) = median(dp_d);
                    dbt.Background_MM_42_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_24_Std(i,1) = std(dp_d);
                    dbt.Background_MM_42_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_42_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 4 && MM_c == 3
                    dbt.Background_MM_43_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_43_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_43_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_43_Median(i,1) = median(dp_d);
                    dbt.Background_MM_43_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_43_Std(i,1) = std(dp_d);
                    dbt.Background_MM_43_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_43_MAD(i,1) = mad(dp_d,1);
                elseif MM_r == 4 && MM_c == 4
                    dbt.Background_MM_44_Mean(i,1) = mean(bg_d);
                    dbt.Deposit_MM_44_Mean(i,1) = mean(dp_d);
                    dbt.Background_MM_44_Median(i,1) = median(bg_d);
                    dbt.Deposit_MM_44_Median(i,1) = median(dp_d);
                    dbt.Background_MM_44_Std(i,1) = std(bg_d);
                    dbt.Deposit_MM_44_Std(i,1) = std(dp_d);
                    dbt.Background_MM_44_MAD(i,1) = mad(bg_d,1);
                    dbt.Deposit_MM_44_MAD(i,1) = mad(dp_d,1);                    
                end                                                                
            end
        end
        
    end
    
end

% toc

%% Replace any 0s, that auto-filled into the polarization stats for unprocessed images, with NaNs to properly represent missing data

col_names = dbt.Properties.VariableNames;
first_pol_property_col = find(strcmp(col_names, 'Background_Diattenuation_45_Mean')); %DepositSize?

for c = first_pol_property_col:width(dbt)
    col_data = dbt.(c);
    col_data(col_data == 0) = NaN;      % the chance of a mean, median, etc being exactly 0 to the bit is negligable, so this will only catch data that wasn't entered (ie IsProcessed = 0)
    dbt.(c) = col_data;
end

end

function [mu, ul, ll] = circ_mean(alpha, w, dim)
%
% mu = circ_mean(alpha, w)
%   Computes the mean direction for circular data.
%
%   Input:
%     alpha	sample of angles in radians
%     [w		weightings in case of binned angle data]
%     [dim  compute along this dimension, default is 1]
%
%     If dim argument is specified, all other optional arguments can be
%     left empty: circ_mean(alpha, [], dim)
%
%   Output:
%     mu		mean direction
%     ul    upper 95% confidence limit
%     ll    lower 95% confidence limit 
%
% PHB 7/6/2008
%
% References:
%   Statistical analysis of circular data, N. I. Fisher
%   Topics in circular statistics, S. R. Jammalamadaka et al. 
%   Biostatistical Analysis, J. H. Zar
%
% Circular Statistics Toolbox for Matlab

% By Philipp Berens, 2009
% berens@tuebingen.mpg.de - www.kyb.mpg.de/~berens/circStat.html

if nargin < 3
  dim = 1;
end

if nargin < 2 || isempty(w)
  % if no specific weighting has been specified
  % assume no binning has taken place
	w = ones(size(alpha));
else
  if size(w,2) ~= size(alpha,2) || size(w,1) ~= size(alpha,1) 
    error('Input dimensions do not match');
  end 
end

% compute weighted sum of cos and sin of angles
r = sum(w.*exp(1i*alpha),dim);

% obtain mean by
mu = angle(r);

% confidence limits if desired
if nargout > 1
  t = circ_confmean(alpha,0.05,w,[],dim);
  ul = mu + t;
  ll = mu - t;
end

end

function [s, s0] = circ_std(alpha, w, d, dim)
% s = circ_std(alpha, w, d, dim)
%   Computes circular standard deviation for circular data 
%   (equ. 26.20, Zar).   
%
%   Input:
%     alpha	sample of angles in radians
%     [w		weightings in case of binned angle data]
%     [d    spacing of bin centers for binned data, if supplied 
%           correction factor is used to correct for bias in 
%           estimation of r]
%     [dim  compute along this dimension, default is 1]
%
%     If dim argument is specified, all other optional arguments can be
%     left empty: circ_std(alpha, [], [], dim)
%
%   Output:
%     s     angular deviation
%     s0    circular standard deviation
%
% PHB 6/7/2008
%
% References:
%   Biostatistical Analysis, J. H. Zar
%
% Circular Statistics Toolbox for Matlab

% By Philipp Berens, 2009
% berens@tuebingen.mpg.de - www.kyb.mpg.de/~berens/circStat.html

if nargin < 4
  dim = 1;
end

if nargin < 3 || isempty(d)
  % per default do not apply correct for binned data
  d = 0;
end

if nargin < 2 || isempty(w)
  % if no specific weighting has been specified
  % assume no binning has taken place
	w = ones(size(alpha));
else
  if size(w,2) ~= size(alpha,2) || size(w,1) ~= size(alpha,1) 
    error('Input dimensions do not match');
  end 
end

% compute mean resultant vector length
r = circ_r(alpha,w,d,dim);

s = sqrt(2*(1-r));      % 26.20
s0 = sqrt(-2*log(r));    % 26.21

end

function r = circ_r(alpha, w, d, dim)
% r = circ_r(alpha, w, d)
%   Computes mean resultant vector length for circular data.
%
%   Input:
%     alpha	sample of angles in radians
%     [w		number of incidences in case of binned angle data]
%     [d    spacing of bin centers for binned data, if supplied 
%           correction factor is used to correct for bias in 
%           estimation of r, in radians (!)]
%     [dim  compute along this dimension, default is 1]
%
%     If dim argument is specified, all other optional arguments can be
%     left empty: circ_r(alpha, [], [], dim)
%
%   Output:
%     r		mean resultant length
%
% PHB 7/6/2008
%
% References:
%   Statistical analysis of circular data, N.I. Fisher
%   Topics in circular statistics, S.R. Jammalamadaka et al. 
%   Biostatistical Analysis, J. H. Zar
%
% Circular Statistics Toolbox for Matlab

% By Philipp Berens, 2009
% berens@tuebingen.mpg.de - www.kyb.mpg.de/~berens/circStat.html

if nargin < 4
  dim = 1;
end

if nargin < 2 || isempty(w) 
  % if no specific weighting has been specified
  % assume no binning has taken place
	w = ones(size(alpha));
else
  if size(w,2) ~= size(alpha,2) || size(w,1) ~= size(alpha,1) 
    error('Input dimensions do not match');
  end 
end

if nargin < 3 || isempty(d)
  % per default do not apply correct for binned data
  d = 0;
end

% compute weighted sum of cos and sin of angles
r = sum(w.*exp(1i*alpha),dim);

% obtain length 
r = abs(r)./sum(w,dim);

% for data with known spacing, apply correction factor to correct for bias
% in the estimation of r (see Zar, p. 601, equ. 26.16)
if d ~= 0
  c = d/2/sin(d/2);
  r = c*r;
end

end

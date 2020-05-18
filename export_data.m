function export_data(pathInput, iflpfilter, exportBySubject)
%
% EXPORT_DATA(pathInput, iflpfilter, exportBySubjec) loads, preprocesses, and exports raw
% data collected in study by Luo et al. "A database of human gait performance 
% on irregular and uneven surfaces collected by wearable sensors". Under review
%
% Inputs: 
% pathInput : str
%    full path to raw data folder
% iflpfilter : str (default='off'), choices {'on', 'off'}
%   If 'on' data are low pass filtered
%   If 'off' no filtering performed. , 
% exportBySubject : str (default='on;), choices {'on', 'off'} 
%   If 'on', a separate mat file is created for each subject. 
%   If 'off', a single mat file is created for all subjects. 

% Output: - .mat file(s) 
%   stores preprocessd data for all 30 subjects. Mat file is stored in a 
%   subfolder 'processed' in parent of pathInput. e.g. if pathInput is 
%   ~/data/imu/raw, processed data will be saved in ~/data/imu/processed

% MIT License
%
% Copyright (c) [2020] [University of Florida Human Systems Engineering Laboratory]
%
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
%
% Author: Yue Luo
% Version: 1.0
% Last update: 05/14/2020

%--------------------------- BEGIN CODE ---------------------------

%% Section 1 - General Setting
% 0. Setup path and settings
% 1. Filter options
% 2. Input trial information

% 0. Setup path and settings
pathOutput = setup_output_path(pathInput);

if nargin == 1
    iflpfilter = 'off';
    exportBySubject = 'on';
elseif nargin == 2
    exportBySubject = 'on';
end

% 1. Filter options

fs = 100; % sampling frequency
fc = 6; % low-pass filter cutoff frequency

% 2. Trial information
numTrial = 57; % number of trials for one participant
numVarInTXT = 30; % number of columns within individual .txt file

disp('****************  Settings **********************************')
disp(['* filter : ', iflpfilter])
disp(['* export by subject : ', exportBySubject])
disp(['* folder for output data is ', pathOutput])
disp('*************************************************************')
disp(' ')


%% Section 2 - Data Extraction and Preprocess

% 1. Structure file path to load data
% Get id list (sort - sort array elements: 'on'/'off')
ids = list_contents(pathInput,'sort','on');
% number of column for exported data
% (temporary, will change size later in the for loop)
numCol = numVarInTXT+3;

for i = 1:size(ids,1)
    
    % preallocate memory for data storage
    trunk = cell(numTrial,numCol); thighR = cell(numTrial,numCol);
    thighL = cell(numTrial,numCol); shankR = cell(numTrial,numCol);
    shankL = cell(numTrial,numCol); wrist = cell(numTrial,numCol);
    
    % preallocate memory for other information storage
    % including 3 columns: id#, trial#, and trial duration
    info = nan(numTrial,3);
    
    id = ids(i,1);
    pathidInput = [pathInput filesep num2str(id)];
    
    % Get trial list for individual id
    % nametxt = list_contents(pathidInput,'sort','off'); % UNUSED?
    
    % 2. Extract data by sensor location
    for j = 1:numTrial
        
        disp(['Processing ...       Subject:   ' ...
            num2str(id) '/' num2str(size(ids,1)) '      --->      ' ...
            'Trial:   ' num2str(j) '/' num2str(numTrial)])
        
        pathTrials = filepath_with_sensor_loc(pathidInput,num2str(j));
        
        % Trunk (LPFilter - low-pass filter: 'on'/'off')
        [dataTrunk,label] = extract_data(pathTrials{1,1},iflpfilter,fs,fc);
        
        % Right Thigh
        [dataThighR] = extract_data(pathTrials{2,1},iflpfilter,fs,fc);
        
        % Left Thigh
        [dataThighL] = extract_data(pathTrials{3,1},iflpfilter,fs,fc);
        
        % Right Shank
        [dataShankR] = extract_data(pathTrials{4,1},iflpfilter,fs,fc);
        
        % Left Shank
        [dataShankL] = extract_data(pathTrials{5,1},iflpfilter,fs,fc);
        
        % Wrist
        [dataWrist] = extract_data(pathTrials{6,1},iflpfilter,fs,fc);
        
        % 3. Summarize data missing information
        % 1st colomn: missing count, 2nd colomn: missing percentage
        % 1-6 row corresponds for: 1. trunk, 2.thighR, 3.thighL, ...
        %                          4.shankR, 5.shankL, 6.wrist,
        [ms,sz] = summarize_missing_data(dataTrunk,dataThighR,dataThighL,...
            dataShankR,dataShankL,dataWrist);
        
        % 4. Aggregate all required varibales.
        %    Variable: 1. 'Subject'; 2. 'Trial'; 3. 'TrialDuration'; 4. 'Surface';...
        %              5. 'Sensor'; 6. MissingCount; 7. Missingpct; ...
        %              8. PacketCounter; 9. SampleTimeFine;
        %              10-37. Data (including acceleration, angular velocity et al. )
        
        trunk(j,:) = [{'trunk'},ms(1,:),dataTrunk];
        
        thighR(j,:) = [{'thighR'},ms(2,:),dataThighR];
        thighL(j,:) = [{'thighL'},ms(3,:),dataThighL];
        shankR(j,:) = [{'shankR'},ms(4,:),dataShankR];
        shankL(j,:) = [{'shankL'},ms(5,:),dataShankL];
        wrist(j,:) = [{'wrist'},ms(6,:),dataWrist];
        
        info(j,:) = [id, j, sz/fs];
        
    end
    
    surf = label_condition(info(:,2)); % surface type
    cellInfo  = [num2cell(info),cellstr(surf)];
    
    label_full = ['Participant','Trial','TrialDuration','Surface','Sensor',...
        'MissingCount','Missingpct',label];
    
    % Trunk
    trunk = array2table([cellInfo,trunk]);
    trunk.Properties.VariableNames = label_full;
    data.(['ID' num2str(id)]).('trunk') = trunk;
    
    % Right Thigh
    thighR = array2table([cellInfo,thighR]);
    thighR.Properties.VariableNames = label_full;
    data.(['ID' num2str(id)]).('thighR') = thighR;
    
    % Left Thigh
    thighL = array2table([cellInfo,thighL]);
    thighL.Properties.VariableNames = label_full;
    data.(['ID' num2str(id)]).('thighL') = thighL;
    
    % Right Shank
    shankR = array2table([cellInfo,shankR]);
    shankR.Properties.VariableNames = label_full;
    data.(['ID' num2str(id)]).('shankR') = shankR;
    
    % Left Shank
    shankL = array2table([cellInfo,shankL]);
    shankL.Properties.VariableNames = label_full;
    data.(['ID' num2str(id)]).('shankL') = shankL;
    
    % Wrist
    wrist = array2table([cellInfo,wrist]);
    wrist.Properties.VariableNames = label_full;
    data.(['ID' num2str(id)]).('wrist') = wrist;
    
    % Export individual .mat file (one file per subject)
    if strcmp(exportBySubject,'on')
        fl = [pathOutput, filesep, (num2str(id)) '.mat'];
        disp(['saving data to ', fl])
        save(fl, 'trunk','thighR','thighL','shankR','shankL','wrist', '-v7.3')
    end
    
end

%% Section 3 - Data Export to single file for all subects
% Export .mat file (one file including all subjects)

if strcmp(exportBySubject,'off')
    fl = [pathOutput, filesep, 'data.mat'];
    disp(['saving data to ', fl])
    save(fl,'data','-v7.3')
end

disp('Finished')

end

%% Section 4 - Functions Used

function pathOutput = setup_output_path(pathInput)
% helper function to set up output path for processed data

final_char = pathInput(end);
if final_char ~= filesep
    pathInput = [pathInput, filesep];
end
indx = strfind(pathInput, filesep);
pathOutput = [pathInput(1:indx(end-1)), 'processed data'];

if ~exist(pathOutput, 'dir')
    mkdir(pathOutput)
end

end

function list = list_contents(pth,~,ifsort)
%% List files in the target path
% Similar with function dir but removes '.' & '..'
%
% sorting option - sort array elements: 'on'/'off'
% Input: 1. pth: target path;
%        2. placeholder
%        3. ifsort: indicator for sorting option
% Ontput: list: filename list contained in target path

% list files in target path (w/ '.')
list = dir(pth);
list = ({list.name})';
temp = cellfun(@(v)(v(1)),list,'UniformOutput', false); % first element
% delete row if first element is '.'
list(contains(temp,'.'),:)=[];

if strcmp(ifsort,'on')
    list = sort(str2double(list)); % sort list if required
    
end

end

function filepaths = filepath_with_sensor_loc(pth,trial)
%% List of filepaths with sensor location information
% Per trial per subject
%
% Input: 1. pth: target path;
%        2. trial: trial #
% Ontput: filepaths: list containing sensor location indicator
%                    and the corresponding filename

filepaths=[];
pth = [pth filesep trial];

filepaths = [filepaths ; {[pth '-000_00B432CC.txt']}]; %sensor B trialTrunk
filepaths = [filepaths ; {[pth '-000_00B43293.txt']}]; %sensor D right thigh
filepaths = [filepaths ; {[pth '-000_00B4328B.txt']}]; %sensor C left thigh
filepaths = [filepaths ; {[pth '-000_00B4329B.txt']}]; %sensor F right shank
filepaths = [filepaths ; {[pth '-000_00B432B6.txt']}]; %sensor E left shank
filepaths = [filepaths ; {[pth '-000_00B43295.txt']}]; %sensor A wrist
filepaths(:,2) = {'Trunk';'ThighR';'ThighL';'ShankR';'ShankL';'Wrist'};

end

function [data,label] = extract_data(pth,iffilter,fs,fc)
%% Load and preprocess data
% 1. Load data from .txt/.csv
% 2. Low-pass filter non-nan data matrix
%
% filtering option: 'on'/'off'
% Input: 1. pth: target path;
%        2. placeholder
%        3. iffilter: indicator for filtering option
% Ontput: 1. data: extracted data (cell arrays)
%         2. label: labels of variables (columns) in extracted data

% Load raw data
data = readtable(pth);

% Replace all-zero columns by all-nan columns
idxzerocol = all(data{:,:}==0,1);
temp = nan(size(data{:,idxzerocol},1),size(data{:,idxzerocol},2));

if ~isempty(temp)
    data{:,idxzerocol} = temp;
end

% Butterworth low-pass filter (2nd order) if required
if strcmp(iffilter,'on')
    
    % Index for columns in need of filter
    idxfiltcol = [false,false,(all(isnan(data{:,3:end}),1))~=1];
    idxfiltrow = [(all(isnan(data{:,3:end}),2))~=1];
    
    [b,a] = butter(2,fc/(fs/2));
    %  freqz(b,a)
    data{idxfiltrow,idxfiltcol} = filtfilt(b,a,data{idxfiltrow,idxfiltcol});
    
end

% Convert table into cell arrays
label = data.Properties.VariableNames;
data = mat2cell(data{:,:},size(data{:,:},1),ones(1,size(data{:,:},2)));

end

function [ms,n] = summarize_missing_data(a,b,c,d,e,f)
%% Summarize data missing information
% 1. Load data from 6 sensor locations and check for missing incidents
%
% Input: a,b,c,d,e,f: data from 6 sensor locations
% Ontput: 1. ms: data missing information
%            1st colomn: missing count, 2nd colomn: missing percentage
%            1-6 row corresponds for: 1. trunk, 2.thighR, 3.thighL, ...
%                                     4.shankR, 5.shankL, 6.wrist,
%         2. n: # of frames

% Change matrix format from cell to matrix
a = cell2mat(a);
b = cell2mat(b);
c = cell2mat(c);
d = cell2mat(d);
e = cell2mat(e);
f = cell2mat(f);

% missing data
sz = [size(a,1);size(b,1);size(c,1);size(d,1);size(e,1);size(f,1)];
n = max(sz);
ms_gap = sz - n;

% nans
ms_nan(1,:) = [sum(all((isnan(a(:,3:end))),2))];
ms_nan(2,:) = [sum(all((isnan(b(:,3:end))),2))];
ms_nan(3,:) = [sum(all((isnan(c(:,3:end))),2))];
ms_nan(4,:) = [sum(all((isnan(d(:,3:end))),2))];
ms_nan(5,:) = [sum(all((isnan(e(:,3:end))),2))];
ms_nan(6,:) = [sum(all((isnan(f(:,3:end))),2))];

ms(:,1) = ms_gap + ms_nan;
ms(:,2) = ms(:,1)/n * 100;

ms = num2cell(ms);

end

function cond = label_condition(trial)
%% Label walking surface condition by trial number
%
% Input: trial: trial array
% Ontput: cond: condition array

cond = strings(size(trial,1),1);

cond(trial >=  1 & trial <=  3,:) = 'CALIB'; % calibration
cond(trial >=  4 & trial <=  9,:) = 'FE'; % flat even
cond(trial >= 10 & trial <= 15,:) = 'CS'; % cobble stone
cond(trial >= 16 & trial <= 26 & mod(trial,2)==0,:) = 'StrU'; % stair up
cond(trial >= 17 & trial <= 27 & mod(trial,2)==1,:) = 'StrD'; % stair down
cond(trial >= 28 & trial <= 38 & mod(trial,2)==0,:) = 'SlpU'; % stair up
cond(trial >= 29 & trial <= 39 & mod(trial,2)==1,:) = 'SlpD'; % stair down
cond(trial >= 40 & trial <= 50 & mod(trial,2)==0,:) = 'BnkL'; % bank left
cond(trial >= 41 & trial <= 51 & mod(trial,2)==1,:) = 'BnkR'; % bank right
cond(trial >= 52 & trial <= 57,:) = 'GR'; % grass

end

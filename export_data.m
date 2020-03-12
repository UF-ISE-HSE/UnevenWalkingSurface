% Copyright (c) <2020>, <University of Florida Human Systems Engineering Laboratory>
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 1. Redistributions of source code must retain the above copyright
%    notice, this list of conditions and the following disclaimer.
% 2. Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the distribution.
% 3. All advertising materials mentioning features or use of this software
%    must display the following acknowledgement:
%    This product includes software developed by the <organization>.
% 4. Neither the name of the <organization> nor the
%    names of its contributors may be used to endorse or promote products
%    derived from this software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDER> ''AS IS'' AND ANY
% EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
% DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
% ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

% load_data - script to load and preprocess raw data
% Inputs: raw data folder
% Output: - .mat file storing preprocessd data for all 30 subjects
% Author: Yue Luo
% Version: 1.0
% Last update: 3/12/2020

%--------------------------- BEGIN CODE ---------------------------

clear
clc
close all
global fs fc

%% Section 1 - General Setting
% 1. Set path of raw data
% 2. Filter options

% 1. Path of raw data
% Set directory for data importing and exporting
pathInput = [pwd slash 'input data']; % folder path for raw data

% 2. Filter options
iflpfilter = 'on';  % low-pass filter: 'on' or 'off'
fs = 100; % sampling frequency
fc = 6; % low-pass filter cutoff frequency

%% Section 2 - Data Extraction and Preprocess

% 1. Structure file path to load data
% Get id list (sort - sort array elements: 'on'/'off')
ids = list_contents(pathInput,'sort','on');

for i = 1:size(ids,1)
    
    trunk = []; thighR = [];
    thighL = []; shankR = [];
    shankL = []; wrist = [];
    info = [];
    
    id = ids(i,1);
    pathidInput = [pathInput slash num2str(i)];
    
    % Get trial list for individual id
    nametxt = list_contents(pathidInput,'sort','off');
    
    % 2. Extract data by sensor location
    for j = 1:57
        
        disp(['Processing...       Subject:   ' ...
            num2str(i) '/' num2str(size(ids,1)) '      <--->      ' ...
            'Trial:   ' num2str(j) '/57'])
        
        pathTrials = filepath_with_sensor_loc(pathidInput,num2str(j));
        
        % Trunk (LPFilter - low-pass filter: 'on'/'off')
        [dataTrunk,label] = extract_data(pathTrials{1,1},'LPFilter',iflpfilter);
        
        % Right Thigh
        [dataThighR] = extract_data(pathTrials{2,1},'LPFilter',iflpfilter);
        
        % Left Thigh
        [dataThighL] = extract_data(pathTrials{3,1},'LPFilter',iflpfilter);
        
        % Right Shank
        [dataShankR] = extract_data(pathTrials{4,1},'LPFilter',iflpfilter);
        
        % Left Shank
        [dataShankL] = extract_data(pathTrials{5,1},'LPFilter',iflpfilter);
        
        % Wrist
        [dataWrist] = extract_data(pathTrials{6,1},'LPFilter',iflpfilter);
        
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
        
        dataInfo = [i, j, sz/fs];
        
        trunk = vertcat(trunk,[{'trunk'},ms(1,:),dataTrunk]);
        thighR = vertcat(thighR,[{'thighR'},ms(2,:),dataThighR]);
        thighL = vertcat(thighL,[{'thighL'},ms(3,:),dataThighL]);
        shankR = vertcat(shankR,[{'shankR'},ms(4,:),dataShankR]);
        shankL = vertcat(shankL,[{'shankL'},ms(5,:),dataShankL]);
        wrist = vertcat(wrist,[{'wrist'},ms(6,:),dataWrist]);
        
        info = vertcat(info,dataInfo);
        
    end
    
    surf = label_condition(info(:,2)); % surface type
    cellInfo  = [num2cell(info),cellstr(surf)];
    
    label = ['Subject','Trial','TrialDuration','Surface','Sensor',...
        'MissingCount','Missingpct',label];
    
    % Trunk
    trunk = array2table([cellInfo,trunk]);
    trunk.Properties.VariableNames = label;
    data.(['Sub' num2str(i)]).('trunk') = trunk;
    
    % Right Thigh
    thighR = array2table([cellInfo,thighR]);
    thighR.Properties.VariableNames = label;
    data.(['Sub' num2str(i)]).('thighR') = thighR;
    
    % Left Thigh
    thighL = array2table([cellInfo,thighL]);
    thighL.Properties.VariableNames = label;
    data.(['Sub' num2str(i)]).('thighL') = thighL;
    
    % Right Shank
    shankR = array2table([cellInfo,shankR]);
    shankR.Properties.VariableNames = label;
    data.(['Sub' num2str(i)]).('shankR') = shankR;
    
    % Left Shank
    shankL = array2table([cellInfo,shankL]);
    shankL.Properties.VariableNames = label;
    data.(['Sub' num2str(i)]).('shankL') = shankL;
    
    % Wrist
    wrist = array2table([cellInfo,wrist]);
    wrist.Properties.VariableNames = label;
    data.(['Sub' num2str(i)]).('wrist') = wrist;
    
    %     % Export induvidual .mat file (one file per subject)
    %     save([(num2str(i)) '.mat'],...
    %          'trunk','thighR','thighL','shankR','shankL','wrist')
    
end

%% Section 3 - Data Export
% Export .mat file (including all subjects)
save('data.mat','data','-v7.3')

disp('Finished')

%% Section 4 - Functions

function output = slash()
%% Output '/' for macOS system, '\' for Windows system
% Input: NA
% Ontput: '/' or '\'

c=pwd;

if strcmp(c(:,1),'/') % macOS system
    output = '/';
else % Windows system
    output = '\';
end

end

function list = list_contents(path,~,ifsort)
%% List files in the target path
% Similar with function dir but removes '.' & '..'
%
% sorting option - sort array elements: 'on'/'off'
% Input: 1. path: target path;
%        2. placeholder
%        3. ifsort: indicator for sorting option
% Ontput: list: filename list contained in target path

list = ({dir(path).name})'; % list files in target path (w/ '.')
temp = cellfun(@(v)(v(1)),list,'UniformOutput', false); % first element
list(contains(temp,'.'),:)=[]; % delete row if first element is '.'

if strcmp(ifsort,'on')
    list = sort(str2double(list)); % sort list if required
else
    
end

end

function filepaths = filepath_with_sensor_loc(path,trial)
%% List of filepaths with sensor location information
% Per trial per subject
%
% Input: 1. path: target path;
%        2. trial: trial #
% Ontput: filepaths: list containing sensor location indicator
%                    and the corresponding filename

filepaths=[];
path = [path slash trial];

filepaths = [filepaths ; {[path '-000_00B432CC.txt.csv']}]; %sensor B trialTrunk
filepaths = [filepaths ; {[path '-000_00B43293.txt.csv']}]; %sensor D right thigh
filepaths = [filepaths ; {[path '-000_00B4328B.txt.csv']}]; %sensor C left thigh
filepaths = [filepaths ; {[path '-000_00B4329B.txt.csv']}]; %sensor F right shank
filepaths = [filepaths ; {[path '-000_00B432B6.txt.csv']}]; %sensor E left shank
filepaths = [filepaths ; {[path '-000_00B43295.txt.csv']}]; %sensor A wrist
filepaths(:,2) = {'Trunk';'ThighR';'ThighL';'ShankR';'ShankL';'Wrist'};

end

function [data,label] = extract_data(path,~,iffilter)
%% Load and preprocess data
% 1. Load data from .txt/.csv
% 2. Low-pass filter non-nan data matrix
%
% filtering option: 'on'/'off'
% Input: 1. path: target path;
%        2. placeholder
%        3. iffilter: indicator for filtering option
% Ontput: 1. data: extracted data (cell arrays)
%         2. label: labels of variables (columns) in extracted data

global fs fc
ms_gap = 0; ms_nan = 0;

% Load raw data
data = readtable(path);

% Replace empty columns by all-nan columns
% (data missing for sub 05 ThighL in trial 14-28)
if iscell(data{1,1})
    
    temp = nan(size(data,1),size(data,2));
    tbl = array2table(temp);
    label = erase(data.Properties.VariableNames,'_');
    tbl.Properties.VariableNames = label;
    data = tbl;
    
else
end

% Replace all-zero columns by all-nan columns
idxzerocol = all(data{:,:}==0,1);
temp = nan(size(data{:,idxzerocol},1),size(data{:,idxzerocol},2));

if ~isempty(temp)
    data{:,idxzerocol} = temp;
else
end

% Butterworth low-pass filter (4th order) if required
if strcmp(iffilter,'on')
    
    % Index for columns in need of filter
    idxfiltcol = [false,false,(all(isnan(data{:,3:end}),1))~=1];
    idxfiltrow = [(all(isnan(data{:,3:end}),2))~=1];
    
    [b,a] = butter(2,fc/(fs/2));
    %  freqz(b,a)
    data{idxfiltrow,idxfiltcol} = filtfilt(b,a,data{idxfiltrow,idxfiltcol});
    
else
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

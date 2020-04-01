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

% detect_toe_off - script to roughly detect toe-offs from 
%                  shank acceleration magnitude
% Inputs: acc_shank (n x 1 double): magnitude of shank acceleration
%          (combination of shank acceleration in all three X,Y,Z axis)
% Output: - idx_toe_off (m x 1 double): frame index for toe-offs
%                                     (m: # of toe-offs detected)
% Author: Yue Luo
% Version: 1.0
% Last update: 04/01/2020

%--------------------------- BEGIN CODE ---------------------------

function [idx_toe_off] = detect_toe_off(acc_shank)
%% Roughly detect toe-offs from shank acceleration magnitude
%
% Input: acc_shank (n x 1 double): magnitude of shank acceleration
%          (combination of shank acceleration in all three X,Y,Z axis)
% Ontput: idx_toe_off (m x 1 double): frame index for toe-offs
%                                     (m: # of toe-offs detected)

%% Identify toe offs
% data size
ifvisual = 'on'; % Visualize toe off on figure: 'on'/'off'
n = size(acc_shank,1);

% 1.Set threshold for peak detection in gait detection
% 1.1 threshold for peak height (20% of the maximun peak height)
limitPeakH = 0.2 * max(acc_shank,[],'all');
% 1.2 minimun distance between two peaks
limitPeakD = 10;
% 1.3 minimun distance between mid-swings
limitSWD = 25;

% 2. Get frame index for toe-offs
% 2.1 Find mid-swings
[~,locstemp,widths,~] = findpeaks(-acc_shank,[1:n],...
    'MinPeakProminence',limitPeakH,...
    'MinPeakDistance',limitPeakD);
% find higher peaks
idx_mid_swing = locstemp(widths<=mean(widths));
% consider as mid-swings only when width between peaks wide enough
idx_mid_swing = idx_mid_swing([true,diff(idx_mid_swing)>limitSWD]);

% 2.2 Find toe-offs
[pkstemp,locstemp,~,~] = findpeaks(acc_shank,[1:n],...
    'MinPeakProminence',limitPeakH,...
    'MinPeakDistance',limitPeakD);

idx_toe_off = []; pks_toe_off=[];
for i=1:size(idx_mid_swing,2)
    % find single toe off based on idx_mid_swing
    idx_single = find((idx_mid_swing(1,i)-locstemp)>0);
    if ~isempty(idx_single)
        % get index and acceleration value of toe_offs
        idx_toe_off = [idx_toe_off;locstemp(:,idx_single(:,end))];
        pks_toe_off = [pks_toe_off;pkstemp(idx_single(:,end),:)];
    end
end

%% Visualize toe off on figure (marked with red circle)
if strcmp(ifvisual,'on')
    figure
    
    findpeaks(acc_shank,[1:n],...
        'MinPeakProminence',limitPeakH,...
        'MinPeakDistance',limitPeakD);
    
    hold on
    plot(idx_toe_off,pks_toe_off,'o')
else
end

end
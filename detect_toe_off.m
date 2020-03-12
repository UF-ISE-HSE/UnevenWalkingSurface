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
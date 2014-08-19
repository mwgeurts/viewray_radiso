function handles = UpdateStatistics(handles, head)
% UpdateStatistics is called by ArcCheckRadIso to compute and update
% the statistics table for each head.  See below for more information on
% the statistics computed.  This function uses GUI handles data (passed in
% the first input variable) loaded by ParseSNCProfiles and ComputeRadIso.  
% This function also uses the input variable head, which should be a string 
% indicating the head number (h1, h2, or h3) to determine which UI table to 
% modify.  Upon successful completion, an updated GUI handles structure is 
% returned.
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2014 University of Wisconsin Board of Regents
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the  
% Free Software Foundation, either version 3 of the License, or (at your 
% option) any later version.
%
% This program is distributed in the hope that it will be useful, but 
% WITHOUT ANY WARRANTY; without even the implied warranty of 
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
% Public License for more details.
% 
% You should have received a copy of the GNU General Public License along 
% with this program. If not, see http://www.gnu.org/licenses/.

% Load table data cell array
table = get(handles.([head, 'table']), 'Data');

% Initialize row counter
c = 0;

% Report radiation isocenter
c = c + 1;
table{c,1} = 'Minimum Radiation Isocenter Radius';
if isfield(handles, [head,'radiso']) && ...
        size(handles.([head,'radiso']), 2) == 3
    table{c,2} = sprintf('%0.2f cm', handles.([head, 'radiso'])(3));
end

% Report IEC X offset
c = c + 1;
table{c,1} = 'Isocenter IEC X Offset';
if isfield(handles, [head,'radiso']) && ...
        size(handles.([head,'radiso']), 2) == 3
    table{c,2} = sprintf('%0.2f cm', handles.([head, 'radiso'])(2));
end

% Report IEC Z offset
c = c + 1;
table{c,1} = 'Isocenter IEC Y Offset';
if isfield(handles, [head,'frames']) && ...
        size(handles.([head,'frames']), 1) > 0 && ...
        size(handles.([head,'frames']), 3) >= c

    % Initialize offset array
    offsets = zeros(1, size(handles.([head,'frames']), 3));

    % Loop through frames
    for i = 1:size(handles.([head,'frames']), 3)

        % Extract circumferential profile
        profile = handles.([head,'frames'])(handles.profile,:,i);

        % Determine location of maximum
        [~, I] = max(profile);

        % Circshift to center maximum
        profile = circshift(profile, floor(size(profile,2)/2)-I, 2);
        frame = squeeze(circshift(handles.([head,'frames'])(:,:,i), ...
            floor(size(profile,2)/2)-I, 2));

        % Redetermine location and value of maximum
        [C, I] = max(profile);

        % Search left side for half-maximum value
        for j = I:-1:1
            if profile(j) == C/2
                l = j;
                break;
            elseif profile(j) < C/2 && profile(j+1) > C/2
                l = interp1(profile(j:j+1), j:j+1, C/2, 'linear');
                break;
            end
        end

        % Search right side for half-maximum value
        for j = I:size(profile,2)-1
            if profile(j) == C/2
                r = j;
                break;
            elseif profile(j) > C/2 && profile(j+1) < C/2
                r = interp1(profile(j:j+1), j:j+1, C/2, 'linear');
                break;
            end
        end 

        % Interpolate longitudinal profile
        long = interp1(1:size(frame,2), frame(:,:)', (r+l)/2);

        % Determine location and value of longitudinal maximum
        [C, I] = max(long);

        % Search left side for half-maximum value
        for j = I:-1:1
            if long(j) == C/2
                l = handles.iY(j);
                break;
            elseif long(j) < C/2 && long(j+1) > C/2
                l = interp1(long(j:j+1), handles.iY(j:j+1), C/2, 'linear');
                break;
            end
        end

        % Search right side for half-maximum value
        for j = I:size(long,2)-1
            if long(j) == C/2
                r = handles.iY(j);
                break;
            elseif long(j) > C/2 && long(j+1) < C/2
                r = interp1(long(j:j+1), handles.iY(j:j+1), C/2, 'linear');
                break;
            end
        end

        % Store field center
        offsets(1,i) = (r+l)/2;
    end
    
    % Compute average
    table{c,2} = sprintf('%0.2f cm', mean(offsets));
end

% Report IEC Z offset
c = c + 1;
table{c,1} = 'Isocenter IEC Z Offset';
if isfield(handles, [head,'radiso']) && ...
        size(handles.([head,'radiso']), 2) == 3
    table{c,2} = sprintf('%0.2f cm', handles.([head, 'radiso'])(1));
end

% Report average MLC X offset
c = c + 1;
table{c,1} = 'Mean MLC X Offset';
if isfield(handles, [head,'alpha']) && ...
        size(handles.([head,'alpha']), 2) > 0 && ...
        isfield(handles, [head,'radiso']) && ...
        size(handles.([head,'radiso']), 2) == 3

    % Initialize offset array
    offsets = zeros(1, size(handles.([head,'alpha']), 2));

    % Loop through angles
    for i = 1:size(handles.([head,'alpha']), 2)

        % Convert points to cartesian coordinates
        [x, y] = pol2cart(handles.([head,'alpha'])(:,i)*pi/180, ...
            handles.radius);

        % Compute disance from line to radiation isocenter
        r = det([[x(2);y(2)]-[x(1);y(1)], ...
            [handles.([head,'radiso'])(1); ...
            handles.([head,'radiso'])(2)]-[x(1);y(1)]])/...
            abs([x(2);y(2)]-[x(1);y(1)]);
        if r(1) ~= 0
            offsets(1,i) = r(1);
        else
            offsets(1,i) = r(2);
        end
    end
    
    % Compute average
    table{c,2} = sprintf('%0.2f cm', mean(offsets));
end

% Set table data
set(handles.([head, 'table']), 'Data', table);
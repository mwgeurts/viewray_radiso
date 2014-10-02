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

% Run in try-catch to log error via Event.m
try

% Log start
Event(['Updating ', head, 'table statistics']);
tic;

% Load table data cell array
table = get(handles.([head, 'table']), 'Data');

% Initialize row counter
c = 0;

% Report radiation isocenter
c = c + 1;
table{c,1} = 'Minimum Radiation Isocenter Radius';
if isfield(handles, [head,'isoradius'])
    table{c,2} = sprintf('%0.2f mm', handles.([head, 'isoradius']) * 10);
end

% Report IEC X offset
c = c + 1;
table{c,1} = 'Isocenter IEC X Offset';
if isfield(handles, [head,'isocenter']) && ...
        size(handles.([head,'isocenter']), 2) >= 2
    table{c,2} = sprintf('%0.2f mm', handles.([head, 'isocenter'])(2) * 10);
end

% Report IEC Y offset
c = c + 1;
table{c,1} = 'Isocenter IEC Y Offset';

% If 3D was computed
if isfield(handles, [head,'isocenter']) && ...
        size(handles.([head,'isocenter']), 2) == 3
    table{c,2} = sprintf('%0.2f mm', handles.([head, 'isocenter'])(3) * 10);
    
% Otherwise, if 2D was computed
elseif size(handles.([head,'isocenter']), 2) == 2
    table{c,2} = 'N/A';
end

% Report IEC Z offset
c = c + 1;
table{c,1} = 'Isocenter IEC Z Offset';
if isfield(handles, [head,'isocenter']) && ...
        size(handles.([head,'isocenter']), 2) >= 2
    table{c,2} = sprintf('%0.2f mm', handles.([head, 'isocenter'])(1) * 10);
end

% Report average/max/min MLC X offset
if isfield(handles, [head,'alpha']) && ...
        size(handles.([head,'alpha']), 2) > 0 && ...
        isfield(handles, [head,'isocenter']) && ...
        size(handles.([head,'isocenter']), 2) >= 2

    % Initialize offset array
    offsets = zeros(1, size(handles.([head,'alpha']), 2));

    % Loop through angles
    for i = 1:size(handles.([head,'alpha']), 2)

        % Convert points to cartesian coordinates
        [x, y] = pol2cart(handles.([head,'alpha'])(:,i)*pi/180, ...
            handles.radius);

        % Compute disance from line to radiation isocenter
        offsets(1,i) = -((y(2)-y(1)) * handles.([head,'isocenter'])(1) ...
            - (x(2)-x(1)) * handles.([head,'isocenter'])(2) - x(1) * ...
            y(2) + x(2) * y(1)) / sqrt((x(2)-x(1))^2 + (y(2)-y(1))^2);
    end
    
    % Log result
    Event(sprintf(['MLC X offset statistics computed: mean = %g, ', ...
        'max = %g, min = %g'], mean(offsets), max(offsets), min(offsets)));
    
    % Compute average
    c = c + 1;
    table{c,1} = 'Mean MLC X Offset';
    table{c,2} = sprintf('%0.2f mm', mean(offsets) * 10);
    
    % Compute max
    c = c + 1;
    table{c,1} = 'Max MLC X Offset';
    table{c,2} = sprintf('%0.2f mm', max(offsets) * 10);
    
    % Compute min
    c = c + 1;
    table{c,1} = 'Min MLC X Offset';
    table{c,2} = sprintf('%0.2f mm', min(offsets) * 10);
end

% Set table data
set(handles.([head, 'table']), 'Data', table);

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end 
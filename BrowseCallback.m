function handles = BrowseCallback(handles, head)
% BrowseCallback is called by ArcCheckRadIso when a browse button is
% clicked. The first input argument is the guidata handles structure, while
% the second is a string indicating which head to load. This function
% returns a modified handles structure upon successful completion.
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

% Log event
Event([head, ' browse button selected']);

% Request the user to select the SNC ArcCHECK acm file
Event('UI window opened to select file');
[name, path] = uigetfile('*.acm', ...
    'Select an SNC ArcCHECK Movie File', handles.path, 'MultiSelect', 'on');

% If a file was selected
if iscell(name) || sum(name ~= 0)
    
    % Start timer
    t = tic;

    % If not cell array, cast as one
    if ~iscell(name)
    
        % Update text box with file name
        set(handles.([head,'file']), 'String', fullfile(path, name));
        
        % Store filenames
        handles.([head,'names']){1} = name;
    else
    
        % Update text box with first file
        set(handles.([head,'file']), 'String', 'Multiple files selected');
        
        % Store filenames
        handles.([head,'names']) = name;
    end
    
    % Log names
    Event([strjoin(handles.([head,'names']), ' selected\n'), ' selected']);
    
    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
    
    % Load data
    handles.([head,'data']) = ...
        ParseSNCacm(handles.path, handles.([head,'names']));
    
    % Parse profiles and store results
    results = AnalyzeACFields(handles.([head,'data']));
    handles.itheta = results.itheta;
    handles.iY = results.iY;
    handles.([head,'frames']) = results.frames;
    handles.([head,'alpha']) = results.alpha;
    handles.([head,'beta']) = results.beta;
    
    % If T&G offset correction is enabled, adjust angles
    if handles.usetg == 1
        Event(sprintf(['Entrance and exit angles adjusted by %0.3f cm ', ...
            ', or %0.3f deg, perpendicular to the beam angle to ', ...
            'account for T&G effect'], handles.tg, ...
            asind(handles.tg/handles.radius)));

        % Decrease entrance angle by arcsin
        handles.([head,'alpha'])(1,:) = handles.([head,'alpha'])(1,:) ...
            - asind(handles.tg/handles.radius);

        % Increase exit angle by arcsin
        handles.([head,'alpha'])(2,:) = handles.([head,'alpha'])(2,:) ...
            + asind(handles.tg/handles.radius);
    end
    
    % If less than three frames were found, error 
    if size(handles.([head,'alpha']), 2) < 3
        Event(['At least three frames are required to perform the ', ...
            'analysis. Add more angle measurements.'], 'ERROR');
    end
    
    % Compute RADISO
    if strcmp(get(handles.([head,'mode']), 'String'), '3D') == 1
        [handles.([head,'isocenter']), handles.([head,'isoradius'])] = ...
            ComputeRadIso3d(handles.([head,'alpha']), ...
            handles.([head,'beta']), handles.radius);
    else
        [handles.h1isocenter, handles.h1isoradius] = ...
            ComputeRadIso(handles.([head,'alpha']), handles.radius);
    end
    
    % Update statistics table
    handles = UpdateStatistics(handles, head);

    % Update plot to show radiation isocenter
    set(handles.([head,'display']), 'Value', 3);
    handles = UpdateDisplay(handles, head);
    
    % Update slider maximum to actual value
    set(handles.([head,'slider']), 'Min', 1);
    set(handles.([head,'slider']), 'Max', ...
        size(handles.([head,'alpha']), 2));
    set(handles.([head,'slider']), 'Value', ...
        size(handles.([head,'alpha']), 2));
    set(handles.([head,'slider']), 'SliderStep', ...
        [1/(size(handles.([head,'alpha']), 2)-1) ...
        5/(size(handles.([head,'alpha']), 2)-1)]);
    
    % Enable print button
    set(handles.print_button, 'enable', 'on');
    
    % Log event
    Event(sprintf('%s data loaded successfully in %0.3f seconds', ...
        head, toc(t)));
    
    % Clear temporary variables
    clear t results;
end

% Clear temporary variables
clear name path;


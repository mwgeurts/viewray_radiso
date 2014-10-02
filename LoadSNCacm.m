function handles = LoadSNCacm(handles, head)
% LoadSNCacm is called by ArcCheckRadIso when the user selects a Browse
% button to read SNC ArcCHECK acm exported data.  The data within the files
% is parsed using ParseSNCProfiles.  This function sets the
% selected file and data structures to store the data
%
% This function requires the GUI handles structure and a string indicating 
% the head number (h1, h2, or h3). It returns a modified GUI handles 
% structure.
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
    
% Request the user to select the SNC ArcCHECK acm file
Event('UI window opened to select file');
[name, path] = uigetfile('*.acm', ...
    'Select an SNC ArcCHECK Movie File', handles.path, 'MultiSelect', 'on');

% If a file was selected
if iscell(name) || sum(name ~= 0)
    % If not cell array, cast as one
    if ~iscell(name)
        % Update text box with file name
        set(handles.([head,'file']), 'String', fullfile(path, name));
        names{1} = name;
    else
        % Update text box with first file
        set(handles.([head,'file']), 'String', 'Multiple files selected');
        names = name;
    end
    clear name;
    
    % Log names
    Event([strjoin(names, ' selected\n'), ' selected']);
    tic;
    
    % Update default path
    handles.path = path;
    Event(['Default file path updated to ', path]);
      
    % Initialize data array
    handles.([head,'data']) = [];
    
    % Loop through each file selected, concatenating data arrays
    for i = 1:length(names)
        
        % Open file handle
        fid = fopen(fullfile(path, names{i}), 'r');
        if fid >= 3 
            Event(['Read handle successfully established for ', names{i}]);
        else
            Event(['Read handle not successful for ', names{i}], 'ERROR');
        end

        % While the end-of-file has not been reached
        while ~feof(fid)
            % Retrieve the next line in the file
            tline = fgetl(fid);

            % Search for dose calibration
            [match, nomatch] = regexp(tline, ...
                sprintf('^Dose Per Count:\t'), 'match', 'split');
            if size(match,1) > 0
                % Extract dose per count
                scan = textscan(nomatch{2}, '%f');
                handles.([head,'dose']) = scan{1};
            end

            % Search for inclinometer reading and radius
            [match, nomatch] = regexp(tline, ...
                sprintf('^Inclinometer Rotation:\t'), 'match', 'split');
            if size(match,1) > 0
                % Extract rotation and radius
                scan = textscan(nomatch{2}, '%f %s %s %f');
                handles.([head,'rotation']) = scan{1};
                handles.radius = scan{4};
                
                % Log values
                Event(['Inclinometer rotation: ', ...
                    sprintf('%i deg', handles.([head,'rotation']))]);
                Event(['ArcCHECK radius: ', ...
                    sprintf('%i cm', handles.radius)]);
            end

            % Search for the detector Z coordinates
            [match, nomatch] = regexp(tline, ...
                sprintf('^Detector Spacing:\t\t\t\t\t\t\t\t\tz\\(n\\)\t\t'), ...
                'match', 'split');
            if size(match,1) > 0
                % Extract all Z positions
                Z = cell2mat(textscan(nomatch{2}, repmat('%f ', 1, 1386)));
                
                % Log values
                Event('Detector Z positions loaded');
            end

            % Search for detector X coordinates
            [match, nomatch] = regexp(tline, ...
                sprintf('^Concatenation:\tFALSE\t\t\t\t\t\t\t\tX\\(n\\)\t\t'), ...
                'match', 'split');
            if size(match,1) > 0
                % Extract all X positions
                X = cell2mat(textscan(nomatch{2}, repmat('%f ', 1, 1386)));
                
                % Log values
                Event('Detector X positions loaded');
            end

            % Search for detector Y coordinates
            [match, nomatch] = regexp(tline, ...
                sprintf('^Imported Data:\tFALSE\t\t\t\t\t\t\t\tY\\(n\\) cm\t\t'), ...
                'match', 'split');
            if size(match,1) > 0
                % Extract all Y positions
                handles.([head,'Y']) = cell2mat(textscan(nomatch{2}, ...
                    repmat('%f ', 1, 1386)));
                
                % Log values
                Event('Detector Y positions loaded');
            end

            % Search for background counts
            [match, nomatch] = regexp(tline, ...
                sprintf('^Background\t\t\t\t\t\t\t\t\t\t'), 'match', 'split');
            if size(match,1) > 0
                % Extract all background counts
                handles.([head,'bkgd']) = cell2mat(textscan(nomatch{2}, ...
                    repmat('%f ', 1, 1386 + 1)));
                
                % Log values
                Event(sprintf(['Detector backgrounds loaded, randing ', ...
                    'from %g to %g'], min(handles.([head,'bkgd'])), ...
                    max(handles.([head,'bkgd']))));
            end

            % Search for array calibration and data
            [match, nomatch] = regexp(tline, ...
                sprintf('^Calibration\t\t\t\t\t\t\t\t\t\t'), 'match', 'split');
            if size(match,1) > 0
                % Extract all calibration values
                handles.([head,'cal']) = cell2mat(textscan(nomatch{2}, ...
                    repmat('%f ', 1, 1386 + 1)));

                % Scan for all data
                data = textscan(fid, ['%s', repmat(' %f', 1, 1386 + 10)]);
                data{1,1} = zeros(size(data{1,2},1),1);
                handles.([head,'data']) = ...
                    vertcat(handles.([head,'data']), cell2mat(data));
                
                % Log values
                Event(sprintf(['Detector array calibration loaded, randing ', ...
                    'from %g to %g'], min(handles.([head,'cal'])), ...
                    max(handles.([head,'cal']))));
                Event(sprintf('%i x %i data array loaded', ...
                    size(handles.([head,'data']))));
            end
        end

        % Close file handle
        fclose(fid);
        
        % Log completion
        Event(sprintf('SNC files loaded successfully in %0.3f seconds', toc));
    end

    % Convert x,z into theta
    handles.([head,'theta']) = atan2d(Z,X) + 90;
    Event('Detector cartesian coordinates converted to cylindrical');
end
    
% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end 
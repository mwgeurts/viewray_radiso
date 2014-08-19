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

% Request the user to select the SNC ArcCHECK acm file
[name, path] = uigetfile('*.acm', ...
    'Select an SNC ArcCHECK Movie File', handles.path);

% If a file was selected
if ~name == 0
    % Update default path
    handles.path = path;
    
    % Update text box
    set(handles.([head,'file']), 'String', fullfile(path, name));

    % Open file handle
    fid = fopen(fullfile(path, name), 'r');
    
    % Initialize data array
    handles.([head,'data']) = [];
    
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
        end

        % Search for the detector Z coordinates
        [match, nomatch] = regexp(tline, ...
            sprintf('^Detector Spacing:\t\t\t\t\t\t\t\t\tz\\(n\\)\t\t'), ...
            'match', 'split');
        if size(match,1) > 0
            % Extract all Z positions
            Z = cell2mat(textscan(nomatch{2}, repmat('%f ', 1, 1386)));
        end

        % Search for detector X coordinates
        [match, nomatch] = regexp(tline, ...
            sprintf('^Concatenation:\tFALSE\t\t\t\t\t\t\t\tX\\(n\\)\t\t'), ...
            'match', 'split');
        if size(match,1) > 0
            % Extract all X positions
            X = cell2mat(textscan(nomatch{2}, repmat('%f ', 1, 1386)));
        end

        % Search for detector Y coordinates
        [match, nomatch] = regexp(tline, ...
            sprintf('^Imported Data:\tFALSE\t\t\t\t\t\t\t\tY\\(n\\) cm\t\t'), ...
            'match', 'split');
        if size(match,1) > 0
            % Extract all Y positions
            handles.([head,'Y']) = cell2mat(textscan(nomatch{2}, ...
                repmat('%f ', 1, 1386)));
        end

        % Search for background counts
        [match, nomatch] = regexp(tline, ...
            sprintf('^Background\t\t\t\t\t\t\t\t\t\t'), 'match', 'split');
        if size(match,1) > 0
            % Extract all background counts
            handles.([head,'bkgd']) = cell2mat(textscan(nomatch{2}, ...
                repmat('%f ', 1, 1386 + 1)));
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
        end
    end

    % Close file handle
    fclose(fid);

    % Convert x,z into theta
    handles.([head,'theta']) = atan2d(Z,X) + 90;
end
    
    
    
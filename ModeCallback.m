function handles = ModeCallback(handles, head)
% ModeCallback is called by ArcCheckRadIso when a 2D/3D button is clicked. 
% The first input argument is the guidata handles structure, while the 
% second is a string indicating which head to load. This function returns 
% a modified handles structure upon successful completion.
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
Event([head, ' mode button selected']);

% Toggle current value from 2D/3D
if strcmp(get(handles.([head,'mode']), 'String'), '3D')
    set(handles.([head,'mode']), 'String', '2D');
    Event('Mode changed from 3D to 2D');
else
    set(handles.([head,'mode']), 'String', '3D');
    Event('Mode changed from 2D to 3D');
end

% If data was loaded, recompute RADISO
if isfield(handles, [head,'data'])
    
    % Log event
    Event('Recomputing existing data');
    
    % Retrieve current values of mode
    if strcmp(get(handles.([head,'mode']), 'String'), '3D')
        
        % Compute 3D RADISO
        [handles.([head,'isocenter']), handles.([head,'isoradius'])] = ...
            ComputeRadIso3d(handles.([head,'alpha']), ...
            handles.([head,'beta']), handles.radius);
    else
        % Compute 2D RADISO
        [handles.h1isocenter, handles.h1isoradius] = ...
            ComputeRadIso(handles.([head,'alpha']), handles.radius);
    end
    
    % Update statistics table
    handles = UpdateStatistics(handles, head);
    
    % Update display
    handles = UpdateDisplay(handles, head);
end
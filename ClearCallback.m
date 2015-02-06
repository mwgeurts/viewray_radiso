function handles = ClearCallback(handles, head)
% ClearCallback is called by ArcCheckRadIso when a clear data button is
% executed. The first input argument is the guidata handles structure, 
% while the second is a string indicating which head to load. This function
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

% Clear data
handles.([head,'frames']) = [];
handles.([head,'alpha']) = [];
handles.([head,'beta']) = [];
handles.([head,'isocenter']) = [];
handles.([head,'isoradius']) = 0;

% Clear file
set(handles.([head,'file']), 'String', '');

% Call UpdateDisplay to clear plot
set(handles.([head,'display']), 'Value', 1);
handles = UpdateDisplay(handles, head);

% Set table data
set(handles.([head,'table']), 'Data', cell(7,2));

% Log event
Event([head, ' data cleared from memory']);

function varargout = ArcCheckRadIso(varargin)
% ArcCheckRadIso computes the radiation isocenter from a series of ViewRay 
% starshot exposures on a Sun Nuclear ArcCheck diode array.  The exposures  
% are acquired as a movie file.
%
% Author: Mark Geurts, mark.w.geurts@gmail.com
% Copyright (C) 2015 University of Wisconsin Board of Regents
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

% Last Modified by GUIDE v2.5 03-Jan-2015 09:37:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ArcCheckRadIso_OpeningFcn, ...
                   'gui_OutputFcn',  @ArcCheckRadIso_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ArcCheckRadIso_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ArcCheckRadIso (see VARARGIN)

% Choose default command line output for ArcCheckRadIso
handles.output = hObject;

% Determine path of current application
[path, ~, ~] = fileparts(mfilename('fullpath'));

% Set current directory to location of this application
cd(path);

% Clear temporary variable
clear path;

% Set version information.  See LoadVersionInfo for more details.
handles.versionInfo = LoadVersionInfo;

% Store program and MATLAB/etc version information as a string cell array
string = {'ViewRay ArcCHECK Radiation Isocenter'
    sprintf('Version: %s', handles.versionInfo{6});
    sprintf('Author: Mark Geurts <mark.w.geurts@gmail.com>');
    sprintf('MATLAB Version: %s', handles.versionInfo{2});
    sprintf('MATLAB License Number: %s', handles.versionInfo{3});
    sprintf('Operating System: %s', handles.versionInfo{1});
    sprintf('CUDA: %s', handles.versionInfo{4});
    sprintf('Java Version: %s', handles.versionInfo{5})
};

% Add dashed line separators      
separator = repmat('-', 1,  size(char(string), 2));
string = sprintf('%s\n', separator, string{:}, separator);

% Log information
Event(string, 'INIT');

% Turn off images
set(allchild(handles.h1axes), 'visible', 'off'); 
set(handles.h1axes, 'visible', 'off'); 
set(allchild(handles.h2axes), 'visible', 'off'); 
set(handles.h2axes, 'visible', 'off'); 
set(allchild(handles.h3axes), 'visible', 'off'); 
set(handles.h3axes, 'visible', 'off'); 

% Disable frame sliders
set(handles.h1slider, 'enable', 'off');
set(handles.h1angle, 'enable', 'off');
set(handles.h2slider, 'enable', 'off');
set(handles.h2angle, 'enable', 'off');
set(handles.h3slider, 'enable', 'off');
set(handles.h3angle, 'enable', 'off');

% Set plot options
handles.plotoptions = UpdateDisplay();
set(handles.h1display, 'String', handles.plotoptions);
set(handles.h2display, 'String', handles.plotoptions);
set(handles.h3display, 'String', handles.plotoptions);

% Initialize tables
set(handles.h1table, 'Data', cell(7,2));
set(handles.h2table, 'Data', cell(7,2));
set(handles.h3table, 'Data', cell(7,2));

% Disable print button
set(handles.print_button, 'enable', 'off');

% Default mode to 3D
Event('Default mode set to 3D');
set(handles.h1mode, 'String', '3D');
set(handles.h2mode, 'String', '3D');
set(handles.h3mode, 'String', '3D');

% Initialize global variables
handles.path = userpath;
Event(['Default file path set to ', handles.path]);

handles.tg = 0.03; % cm
Event(sprintf('TG offset set to %0.3f cm', handles.tg));

handles.radius = 10.4;
Event(sprintf('ArcCHECK radius set to %0.3f cm', handles.radius));

handles.usetg = 1; % 1 accounts for TG offset (handles.tg), 0 doesn't
Event('TG offset enabled');

% Add snc_extract submodule to search path
addpath('./snc_extract');

% Check if MATLAB can find ParseSNCacm.m
if exist('ParseSNCacm', 'file') ~= 2
    
    % If not, throw an error
    Event(['The snc_extract submodule does not exist in the search path. ', ...
        'Use git clone --recursive or git submodule init followed by git ', ...
        'submodule update to fetch all submodules'], 'ERROR');
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = ArcCheckRadIso_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1file_Callback(~, ~, ~) %#ok<*DEFNU>
% hObject    handle to h1file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1file_CreateFcn(hObject, ~, ~)
% hObject    handle to h1file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1browse_Callback(hObject, ~, handles)
% hObject    handle to h1browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h1');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1display_Callback(hObject, ~, handles)
% hObject    handle to h1display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h1');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1display_CreateFcn(hObject, ~, ~)
% hObject    handle to h1display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1slider_Callback(hObject, ~, handles)
% hObject    handle to h1slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h1');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1slider_CreateFcn(hObject, ~, ~)
% hObject    handle to h1slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1angle_Callback(~, ~, ~)
% hObject    handle to h1angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1angle_CreateFcn(hObject, ~, ~)
% hObject    handle to h1angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1clear_Callback(hObject, ~, handles)
% hObject    handle to h1clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute ClearCallback
handles = ClearCallback(handles, 'h1');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2file_Callback(~, ~, ~) %#ok<*DEFNU>
% hObject    handle to h2file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2file_CreateFcn(hObject, ~, ~)
% hObject    handle to h2file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2browse_Callback(hObject, ~, handles)
% hObject    handle to h2browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h2');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2display_Callback(hObject, ~, handles)
% hObject    handle to h2display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('h2 display dropdown changed');

% Call UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h2');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2display_CreateFcn(hObject, ~, ~)
% hObject    handle to h2display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2slider_Callback(hObject, ~, handles)
% hObject    handle to h2slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h2');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2slider_CreateFcn(hObject, ~, ~)
% hObject    handle to h2slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2angle_Callback(~, ~, ~)
% hObject    handle to h2angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2angle_CreateFcn(hObject, ~, ~)
% hObject    handle to h2angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2clear_Callback(hObject, ~, handles)
% hObject    handle to h1clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute ClearCallback
handles = ClearCallback(handles, 'h2');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3file_Callback(~, ~, ~) %#ok<*DEFNU>
% hObject    handle to h3file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3file_CreateFcn(hObject, ~, ~)
% hObject    handle to h3file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3browse_Callback(hObject, ~, handles)
% hObject    handle to h3browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute BrowseCallback to load new data
handles = BrowseCallback(handles, 'h3');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3display_Callback(hObject, ~, handles)
% hObject    handle to h3display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('H3 display dropdown changed');

% Call UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h3');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3display_CreateFcn(hObject, ~, ~)
% hObject    handle to h3display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Popupmenu controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3slider_Callback(hObject, ~, handles)
% hObject    handle to h1slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h3');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3slider_CreateFcn(hObject, ~, ~)
% hObject    handle to h3slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3angle_Callback(~, ~, ~)
% hObject    handle to h3angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3angle_CreateFcn(hObject, ~, ~)
% hObject    handle to h3angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Edit controls usually have a white background on Windows.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3clear_Callback(hObject, ~, handles)
% hObject    handle to h3clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute ClearCallback
handles = ClearCallback(handles, 'h3');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3mode_Callback(hObject, ~, handles)
% hObject    handle to h3mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute ModeCallback
handles = ModeCallback(handles, 'h3');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2mode_Callback(hObject, ~, handles)
% hObject    handle to h2mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute ModeCallback
handles = ModeCallback(handles, 'h2');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1mode_Callback(hObject, ~, handles)
% hObject    handle to h1mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Execute ModeCallback
handles = ModeCallback(handles, 'h1');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function figure1_ResizeFcn(hObject, ~, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set units to pixels
set(hObject, 'Units', 'pixels') 

% Loop through each head statistics table
for i = 1:3
    
    % Get table width
    pos = get(handles.(sprintf('h%itable', i)), 'Position') .* ...
        get(handles.(sprintf('uipanel%i', i)), 'Position') .* ...
        get(hObject, 'Position');
    
    % Update column widths to scale to new table size
    set(handles.(sprintf('h%itable', i)), 'ColumnWidth', ...
        {floor(0.75*pos(3))-12 floor(0.25*pos(3))-12});
end

% Clear temporary variables
clear pos;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function print_button_Callback(~, ~, handles)
% hObject    handle to print_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Log event
Event('Print button selected');

% Execute PrintReport, passing current handles structure as data
PrintReport('Data', handles);

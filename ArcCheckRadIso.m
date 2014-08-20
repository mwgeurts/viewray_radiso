function varargout = ArcCheckRadIso(varargin)
% ArcCheckRadIso computes the radiation isocenter from a series of ViewRay 
% starshot exposures on a Sun Nuclear ArcCheck diode array.  The exposures  
% are acquired as a movie file.
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

% Last Modified by GUIDE v2.5 18-Aug-2014 09:50:46

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
set(handles.h1table, 'Data', cell(4,2));
set(handles.h2table, 'Data', cell(4,2));
set(handles.h3table, 'Data', cell(4,2));

% Default offsets to on
set(handles.h1offset, 'Value', 1);
set(handles.h2offset, 'Value', 1);
set(handles.h3offset, 'Value', 1);

% Initialize global variables
handles.path = userpath;
handles.tg = 0.03; % cm
[handles.itheta, handles.iY] = meshgrid(0:359, -10:0.1:10);
[~, handles.profile] = min(abs(handles.iY(:,1)));

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

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1browse_Callback(hObject, ~, handles)
% hObject    handle to h1browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Load profile data
handles = LoadSNCacm(handles, 'h1');

% If data was loaded
if isfield(handles, 'h1data') && ~isempty(handles.h1data) > 0
    % Parse profiles
    handles = ParseSNCProfiles(handles, 'h1');

    % Compute RADISO
    handles.h1radiso = ComputeRadIso(handles.h1alpha, handles.radius);
    
    % Update statistics table
    handles = UpdateStatistics(handles, 'h1');

    % Update plot to show radiation isocenter
    set(handles.h1display, 'Value', 2);
    handles = UpdateDisplay(handles, 'h1');
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1display_Callback(hObject, ~, handles)
% hObject    handle to h1display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h1');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1display_CreateFcn(hObject, ~, ~)
% hObject    handle to h1display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1slider_Callback(hObject, ~, handles)
% hObject    handle to h1slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h1');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1slider_CreateFcn(hObject, ~, ~)
% hObject    handle to h1slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
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

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1clear_Callback(hObject, ~, handles)
% hObject    handle to h1clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Clear data
handles.h1dose = [];
handles.h1bkgd = [];
handles.h1cal = [];
handles.h1rotation = [];
handles.h1Y = [];
handles.h1theta = [];
handles.h1data = [];
handles.h1frames = [];
handles.h1alpha = [];
handles.h1radiso = [];

% Clear file
set(handles.h1file, 'String', '');

% Call UpdateDisplay to clear plot
handles = UpdateDisplay(handles, 'h1');

% Set table data
set(handles.h1table, 'Data', cell(4,2));

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

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2browse_Callback(hObject, ~, handles)
% hObject    handle to h2browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Load profile data
handles = LoadSNCacm(handles, 'h2');

% If data was loaded
if isfield(handles, 'h2data') && ~isempty(handles.h2data) > 0
    % Parse profiles
    handles = ParseSNCProfiles(handles, 'h2');

    % Compute RADISO
    handles.h2radiso = ComputeRadIso(handles.h2alpha, handles.radius);
    
    % Update statistics table
    handles = UpdateStatistics(handles, 'h2');

    % Update plot to show radiation isocenter
    set(handles.h2display, 'Value', 2);
    handles = UpdateDisplay(handles, 'h2');
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2display_Callback(hObject, ~, handles)
% hObject    handle to h2display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h2');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2display_CreateFcn(hObject, ~, ~)
% hObject    handle to h2display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
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

% Hint: slider controls usually have a light gray background.
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

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2clear_Callback(hObject, ~, handles)
% hObject    handle to h1clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Clear data
handles.h2dose = [];
handles.h2bkgd = [];
handles.h2cal = [];
handles.h2rotation = [];
handles.h2Y = [];
handles.h2theta = [];
handles.h2data = [];
handles.h2frames = [];
handles.h2alpha = [];
handles.h2radiso = [];

% Clear file
set(handles.h2file, 'String', '');

% Call UpdateDisplay to clear plot
handles = UpdateDisplay(handles, 'h2');

% Set table data
set(handles.h2table, 'Data', cell(4,2));

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

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3browse_Callback(hObject, ~, handles)
% hObject    handle to h3browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Load profile data
handles = LoadSNCacm(handles, 'h3');

% If data was loaded
if isfield(handles, 'h3data') && ~isempty(handles.h3data) > 0
    % Parse profiles
    handles = ParseSNCProfiles(handles, 'h3');

    % Compute RADISO
    handles.h3radiso = ComputeRadIso(handles.h3alpha, handles.radius);
    
    % Update statistics table
    handles = UpdateStatistics(handles, 'h3');

    % Update plot to show radiation isocenter
    set(handles.h3display, 'Value', 2);
    handles = UpdateDisplay(handles, 'h3');
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3display_Callback(hObject, ~, handles)
% hObject    handle to h3display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call UpdateDisplay to update plot
handles = UpdateDisplay(handles, 'h3');

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3display_CreateFcn(hObject, ~, ~)
% hObject    handle to h3display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
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

% Hint: slider controls usually have a light gray background.
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

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3clear_Callback(hObject, ~, handles)
% hObject    handle to h3clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Clear data
handles.h3dose = [];
handles.h3bkgd = [];
handles.h3cal = [];
handles.h3rotation = [];
handles.h3Y = [];
handles.h3theta = [];
handles.h3data = [];
handles.h3frames = [];
handles.h3alpha = [];
handles.h3radiso = [];

% Clear file
set(handles.h3file, 'String', '');

% Call UpdateDisplay to clear plot
handles = UpdateDisplay(handles, 'h3');

% Set table data
set(handles.h3table, 'Data', cell(4,2));

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h3offset_Callback(hObject, ~, handles)
% hObject    handle to h3offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If data was loaded, recompute data
if isfield(handles, 'h3data')
    % Parse profiles
    handles = ParseSNCProfiles(handles, 'h3');

    % Compute RADISO
    handles.h3radiso = ComputeRadIso(handles.h3alpha, handles.radius);
    
    % Update statistics table
    handles = UpdateStatistics(handles, 'h3');

    % Update plot to show radiation isocenter
    set(handles.h3display, 'Value', 2);
    handles = UpdateDisplay(handles, 'h3');
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h2offset_Callback(hObject, ~, handles)
% hObject    handle to h2offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If data was loaded, recompute data
if isfield(handles, 'h2data')
    % Parse profiles
    handles = ParseSNCProfiles(handles, 'h2');

    % Compute RADISO
    handles.h2radiso = ComputeRadIso(handles.h2alpha, handles.radius);
    
    % Update statistics table
    handles = UpdateStatistics(handles, 'h2');

    % Update plot to show radiation isocenter
    set(handles.h2display, 'Value', 2);
    handles = UpdateDisplay(handles, 'h2');
end

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h1offset_Callback(hObject, ~, handles)
% hObject    handle to h1offset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If data was loaded, recompute data
if isfield(handles, 'h1data')
    % Parse profiles
    handles = ParseSNCProfiles(handles, 'h1');

    % Compute RADISO
    handles.h1radiso = ComputeRadIso(handles.h1alpha, handles.radius);
    
    % Update statistics table
    handles = UpdateStatistics(handles, 'h1');

    % Update plot to show radiation isocenter
    set(handles.h1display, 'Value', 2);
    handles = UpdateDisplay(handles, 'h1');
end

% Update handles structure
guidata(hObject, handles);
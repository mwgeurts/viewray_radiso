function varargout = PrintReport(varargin)
% PrintReport is called by ExitDetector.m after daily and patient static
% couch QA has been loaded and analyzed, and creates a "report" figure of
% the plots and statistics generated in ExitDetector.  This report is then
% saved to a temporary file in PDF format and opened using the default
% application.  Once the PDF is opened, this figure is deleted. The visual 
% layout of the report is defined in PrintReport.fig.
%
% When calling PrintReport, the GUI handles structure (or data structure
% containing the daily and patient specific variables) should be passed
% immediately following the string 'Data', as shown in the following
% example:
%
% PrintReport('Data', handles);
%
% For more information on the variables required in the data structure, see
% LoadPlan.m, UpdateSinogramDisplay.m, InitializeViewer.m, UpdateDVH.m, and
% UpdateResultsDisplay.m.
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

% Last Modified by GUIDE v2.5 09-Nov-2014 20:08:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PrintReport_OpeningFcn, ...
                   'gui_OutputFcn',  @PrintReport_OutputFcn, ...
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
function PrintReport_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PrintReport (see VARARGIN)

% Choose default command line output for PrintReport
handles.output = hObject;

% Log start of printing and start timer
Event('Printing Exit Detector Analysis report');
tic;

% Load data structure from varargin
for i = 1:length(varargin)
    if strcmp(varargin{i}, 'Data')
        data = varargin{i+1}; 
        break; 
    end
end

% Set report date/time
set(handles.text12, 'String', datestr(now,'yyyy-mm-dd HH:MM:SS'));

% Set user name
[s, cmdout] = system('whoami');
if s == 0
    set(handles.text7, 'String', cmdout);
else
    cmdout = inputdlg('Enter your name:', 'Username', [1 50]);
    set(handles.text7, 'String', cmdout{1});
end
clear s cmdout;

% Set version
set(handles.text8, 'String', data.versionInfo{6});

% Define a color map for displaying multiple datasets
cmap = jet(24);

% If head 1 data was loaded
if isfield(data, 'h1data') && ~isempty(data.h1data) > 0
    
    % Set file
    set(handles.text14, 'String', get(data.h1file, 'String'));
    
    % If data exists
    if isfield(data, 'h1isoradius') && data.h1isoradius > 0 && ...
            isfield(data, 'h1isocenter') && size(data.h1isocenter, 2) >= 2
        
        % Log event
        Event('Plotting head 1 radiation isocenter');

        % Set axes
        axes(handles.axes1);

        % Define square voxels
        axis image;
        
        % Hold plot
        hold on;

        % Plot isocenter
        [x, y] = pol2cart(linspace(0,2*pi,100), data.h1isoradius);
        x = x + data.h1isocenter(1);
        y = y + data.h1isocenter(2);
        plot(y * 10, x * 10, '-r', 'LineWidth', 2);

        % Plot field centers
        for i = 1:size(data.h1alpha, 2)
            [x, y]  = pol2cart(data.h1alpha(:,i)*pi/180, data.radius);
            plot(y * 10, x * 10, '-', 'Color', cmap(min(i,size(cmap,1)),:));
        end

        % Set axis labels
        xlabel('IEC X Axis (mm)');
        ylabel('IEC Z Axis (mm)');

        % Set plot options
        xlim([-3 3]);
        set(gca, 'XTick', -3:1:3);
        ylim([-3 3]);
        set(gca, 'YTick', -3:1:3);
        hold off;
        title('Head 1 Radiation Isocenter', 'FontSize', 9);
        grid on;

        % Turn on display
        set(allchild(handles.axes1), 'visible', 'on'); 
        set(handles.axes1, 'visible', 'on'); 
        
        % Log event
        Event('Plotting head 1 MLC X Offsets');

        % Set axes
        axes(handles.axes2);

        % Initialize offset array
        offsets = zeros(2, size(data.h1alpha, 2));

        % Loop through angles
        for i = 1:size(data.h1alpha, 2)

            % Convert points to cartesian coordinates
            [x, y] = pol2cart(data.h1alpha(:,i)*pi/180, data.radius);

            % Compute disance from line to radiation isocenter
            offsets(1,i) = -((y(2)-y(1)) * ...
                data.h1isocenter(1) - (x(2)-x(1)) * ...
                data.h1isocenter(2) - x(1) * y(2) + x(2) ...
                * y(1)) / sqrt((x(2)-x(1))^2 + (y(2)-y(1))^2);

            % Compute central axis angle (for display)
            if data.h1alpha(2,i) < ...
                    data.h1alpha(1,i)
                offsets(2,i) = (data.h1alpha(2,i) + ...
                    data.h1alpha(1,i)+180)/2;
            else
                offsets(2,i) = (data.h1alpha(2,i) + ...
                    data.h1alpha(1,i)-180)/2;
            end
        end

        % Plot map
        h = plot(offsets(2,:), offsets(1,:) * 10, 'o');
        set(h, 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b')
        xlim([min(offsets(2,:))-0.1 max(offsets(2,:))+0.1]);
        xlabel('Beam Angle (deg)');
        ylim([-3 3]);
        set(gca, 'YTick', -3:1:3);
        title('Head 1 MLC X Offset (mm)', 'FontSize', 9);
        grid on;

        % Turn on display
        set(allchild(handles.axes2), 'visible', 'on'); 
        set(handles.axes2, 'visible', 'on'); 
    end

    % Log start
    Event('Updating head 1 table statistics');
    
    % Add statistics table
    table = get(data.h1table, 'Data');
    set(handles.text19, 'String', sprintf('%s\n\n', table{:,1}));
    set(handles.text20, 'String', sprintf('%s\n\n', table{:,2}));
    
    % Clear temporary variables
    clear table h i offsets x y;

else
    
    % Hide input file
    set(handles.text13, 'visible', 'off'); 
    set(handles.text14, 'visible', 'off'); 
    
    % Hide displays
    set(allchild(handles.axes1), 'visible', 'off'); 
    set(handles.axes1, 'visible', 'off'); 
    set(allchild(handles.axes2), 'visible', 'off'); 
    set(handles.axes2, 'visible', 'off'); 
    
    % Hide statistics table
    set(handles.text17, 'visible', 'off'); 
    set(handles.text18, 'visible', 'off'); 
    set(handles.text19, 'visible', 'off'); 
    set(handles.text20, 'visible', 'off'); 
end

% If head 2 data was loaded
if isfield(data, 'h2data') && ~isempty(data.h2data) > 0
    
    % Set file
    set(handles.text28, 'String', get(data.h2file, 'String'));
    
    % If data exists
    if isfield(data, 'h2isoradius') && data.h2isoradius > 0 && ...
            isfield(data, 'h2isocenter') && size(data.h2isocenter, 2) >= 2
        
        % Log event
        Event('Plotting head 2 radiation isocenter');

        % Set axes
        axes(handles.axes3);

        % Define square voxels
        axis image;
        
        % Hold plot
        hold on;

        % Plot isocenter
        [x, y] = pol2cart(linspace(0,2*pi,100), data.h2isoradius);
        x = x + data.h2isocenter(1);
        y = y + data.h2isocenter(2);
        plot(y * 10, x * 10, '-r', 'LineWidth', 2);

        % Plot field centers
        for i = 1:size(data.h2alpha, 2)
            [x, y]  = pol2cart(data.h2alpha(:,i)*pi/180, data.radius);
            plot(y * 10, x * 10, '-', 'Color', cmap(min(i,size(cmap,1)),:));
        end

        % Set axis labels
        xlabel('IEC X Axis (mm)');
        ylabel('IEC Z Axis (mm)');

        % Set plot options
        xlim([-3 3]);
        set(gca, 'XTick', -3:1:3);
        ylim([-3 3]);
        set(gca, 'YTick', -3:1:3);
        hold off;
        title('Head 2 Radiation Isocenter', 'FontSize', 9);
        grid on;

        % Turn on display
        set(allchild(handles.axes3), 'visible', 'on'); 
        set(handles.axes3, 'visible', 'on'); 
        
        % Log event
        Event('Plotting head 2 MLC X Offsets');

        % Set axes
        axes(handles.axes4);

        % Initialize offset array
        offsets = zeros(2, size(data.h2alpha, 2));

        % Loop through angles
        for i = 1:size(data.h2alpha, 2)

            % Convert points to cartesian coordinates
            [x, y] = pol2cart(data.h2alpha(:,i)*pi/180, data.radius);

            % Compute disance from line to radiation isocenter
            offsets(1,i) = -((y(2)-y(1)) * ...
                data.h2isocenter(1) - (x(2)-x(1)) * ...
                data.h2isocenter(2) - x(1) * y(2) + x(2) ...
                * y(1)) / sqrt((x(2)-x(1))^2 + (y(2)-y(1))^2);

            % Compute central axis angle (for display)
            if data.h2alpha(2,i) < ...
                    data.h2alpha(1,i)
                offsets(2,i) = (data.h2alpha(2,i) + ...
                    data.h2alpha(1,i)+180)/2;
            else
                offsets(2,i) = (data.h2alpha(2,i) + ...
                    data.h2alpha(1,i)-180)/2;
            end
        end

        % Plot map
        h = plot(offsets(2,:), offsets(1,:) * 10, 'o');
        set(h, 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b')
        xlim([min(offsets(2,:))-0.1 max(offsets(2,:))+0.1]);
        xlabel('Beam Angle (deg)');
        ylim([-3 3]);
        set(gca, 'YTick', -3:1:3);
        title('Head 2 MLC X Offset (mm)', 'FontSize', 9);
        grid on;

        % Turn on display
        set(allchild(handles.axes4), 'visible', 'on'); 
        set(handles.axes4, 'visible', 'on'); 
    end

    % Log start
    Event('Updating head 2 table statistics');
    
    % Add statistics table
    table = get(data.h2table, 'Data');
    set(handles.text31, 'String', sprintf('%s\n\n', table{:,1}));
    set(handles.text32, 'String', sprintf('%s\n\n', table{:,2}));
    
    % Clear temporary variables
    clear table h i offsets x y;

else
    
    % Hide input file
    set(handles.text27, 'visible', 'off'); 
    set(handles.text28, 'visible', 'off'); 
    
    % Hide displays
    set(allchild(handles.axes3), 'visible', 'off'); 
    set(handles.axes3, 'visible', 'off'); 
    set(allchild(handles.axes4), 'visible', 'off'); 
    set(handles.axes4, 'visible', 'off'); 
    
    % Hide statistics table
    set(handles.text29, 'visible', 'off'); 
    set(handles.text30, 'visible', 'off'); 
    set(handles.text31, 'visible', 'off'); 
    set(handles.text32, 'visible', 'off'); 
end

% If head 3 data was loaded
if isfield(data, 'h3data') && ~isempty(data.h3data) > 0
    
    % Set file
    set(handles.text34, 'String', get(data.h3file, 'String'));
    
    % If data exists
    if isfield(data, 'h3isoradius') && data.h3isoradius > 0 && ...
            isfield(data, 'h3isocenter') && size(data.h3isocenter, 2) >= 2
        
        % Log event
        Event('Plotting head 3 radiation isocenter');

        % Set axes
        axes(handles.axes5);

        % Define square voxels
        axis image;
        
        % Hold plot
        hold on;

        % Plot isocenter
        [x, y] = pol2cart(linspace(0,2*pi,100), data.h3isoradius);
        x = x + data.h3isocenter(1);
        y = y + data.h3isocenter(2);
        plot(y * 10, x * 10, '-r', 'LineWidth', 2);

        % Plot field centers
        for i = 1:size(data.h3alpha, 2)
            [x, y]  = pol2cart(data.h3alpha(:,i)*pi/180, data.radius);
            plot(y * 10, x * 10, '-', 'Color', cmap(min(i,size(cmap,1)),:));
        end

        % Set axis labels
        xlabel('IEC X Axis (mm)');
        ylabel('IEC Z Axis (mm)');

        % Set plot options
        xlim([-3 3]);
        set(gca, 'XTick', -3:1:3);
        ylim([-3 3]);
        set(gca, 'YTick', -3:1:3);
        hold off;
        title('Head 3 Radiation Isocenter', 'FontSize', 9);
        grid on;

        % Turn on display
        set(allchild(handles.axes5), 'visible', 'on'); 
        set(handles.axes5, 'visible', 'on'); 
        
        % Log event
        Event('Plotting head 3 MLC X Offsets');

        % Set axes
        axes(handles.axes6);

        % Initialize offset array
        offsets = zeros(2, size(data.h3alpha, 2));

        % Loop through angles
        for i = 1:size(data.h3alpha, 2)

            % Convert points to cartesian coordinates
            [x, y] = pol2cart(data.h3alpha(:,i)*pi/180, data.radius);

            % Compute disance from line to radiation isocenter
            offsets(1,i) = -((y(2)-y(1)) * ...
                data.h3isocenter(1) - (x(2)-x(1)) * ...
                data.h3isocenter(2) - x(1) * y(2) + x(2) ...
                * y(1)) / sqrt((x(2)-x(1))^2 + (y(2)-y(1))^2);

            % Compute central axis angle (for display)
            if data.h3alpha(2,i) < ...
                    data.h3alpha(1,i)
                offsets(2,i) = (data.h3alpha(2,i) + ...
                    data.h3alpha(1,i)+180)/2;
            else
                offsets(2,i) = (data.h3alpha(2,i) + ...
                    data.h3alpha(1,i)-180)/2;
            end
        end

        % Plot map
        h = plot(offsets(2,:), offsets(1,:) * 10, 'o');
        set(h, 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b')
        xlim([min(offsets(2,:))-0.1 max(offsets(2,:))+0.1]);
        xlabel('Beam Angle (deg)');
        ylim([-3 3]);
        set(gca, 'YTick', -3:1:3);
        title('Head 2 MLC X Offset (mm)', 'FontSize', 9);
        grid on;

        % Turn on display
        set(allchild(handles.axes6), 'visible', 'on'); 
        set(handles.axes6, 'visible', 'on'); 
    end

    % Log start
    Event('Updating head 3 table statistics');
    
    % Add statistics table
    table = get(data.h3table, 'Data');
    set(handles.text37, 'String', sprintf('%s\n\n', table{:,1}));
    set(handles.text38, 'String', sprintf('%s\n\n', table{:,2}));
    
    % Clear temporary variables
    clear table h i offsets x y;

else
    
    % Hide input file
    set(handles.text33, 'visible', 'off'); 
    set(handles.text34, 'visible', 'off'); 
    
    % Hide displays
    set(allchild(handles.axes5), 'visible', 'off'); 
    set(handles.axes5, 'visible', 'off'); 
    set(allchild(handles.axes6), 'visible', 'off'); 
    set(handles.axes6, 'visible', 'off'); 
    
    % Hide statistics table
    set(handles.text35, 'visible', 'off'); 
    set(handles.text36, 'visible', 'off'); 
    set(handles.text37, 'visible', 'off'); 
    set(handles.text38, 'visible', 'off'); 
end

% Update handles structure
guidata(hObject, handles);

% Clear temporary variable
clear data;

% Get temporary file name
temp = [tempname, '.pdf'];

% Print report
Event(['Saving report to ', temp]);
saveas(hObject, temp);

% Open file
Event(['Opening file ', temp]);
open(temp);

% Log completion
Event(sprintf('Report saved successfully in %0.3f seconds', toc));

% Close figure
close(hObject);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PrintReport_OutputFcn(~, ~, ~) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

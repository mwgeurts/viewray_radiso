function varargout = UpdateDisplay(varargin)
% UpdateDisplay is called by ArcCheckRadIso when initializing or
% updating a plot display.  When called with no input arguments, this
% function returns a string cell array of available plots that the user can
% choose from.  When called with two input arguments, the first being a GUI
% handles structure and the second a string indicating the head number (h1,
% h2, or h3), this function will look for measured data (loaded by 
% ParseSNCProfiles  respectively) and update the display based on the 
% display menu UI component.
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

% Specify plot options and order
plotoptions = {
    'Measured Data'
    'Radiation Isocenter'
    'Circumferential Profiles'
    'Isocenter Offsets'
    'Longitudinal Profiles'
    'Longitudinal Flatness'
    'Longitudinal Symmetry'
};

% If no input arguments are provided
if nargin == 0
    % Return the plot options
    varargout{1} = plotoptions;
    
    % Stop execution
    return;
    
% Otherwise, if 2, set the input variables and update the plot
elseif nargin == 2
    handles = varargin{1};
    head = varargin{2};

% Otherwise, throw an error
else 
    error('Incorrect number of inputs');
end

% Clear and set reference to axis
cla(handles.([head, 'axes']), 'reset');
axes(handles.([head, 'axes']));

% Turn off the display while building
set(allchild(handles.([head, 'axes'])), 'visible', 'off'); 
set(handles.([head, 'axes']), 'visible', 'off');

% Define a color map for displaying multiple datasets
cmap = jet(24);

% Execute code block based on display GUI item value
switch get(handles.([head, 'display']),'Value')
    case 1 
        % Get slider and angle
        c = round(get(handles.([head,'slider']), 'Value'));
        
        % If data exists
        if isfield(handles, [head,'frames']) && ...
                size(handles.([head,'frames']), 1) > 0 && ...
                size(handles.([head,'frames']), 3) >= c
            
            % Enable slider
            set(handles.([head, 'slider']), 'enable', 'on');
            set(handles.([head, 'angle']), 'enable', 'on');
            
            % Plot map
            imagesc(circshift(handles.([head,'frames'])(:,:,c),-180,2));
            set(gca,'XTick', 1:30:361);
            set(gca,'XTickLabel', -180:30:180);
            xlabel('ArcCHECK Angle (deg)');
            set(gca,'YTick', 1:20:201);
            set(gca,'YTickLabel', 10:-2:-10);
            ylabel('ArcCHECK IEC Y (cm)');

            % Compute central axis angle (for display)
            if handles.([head,'alpha'])(2,c) < handles.([head,'alpha'])(1,c)
                angle = (handles.([head,'alpha'])(2,c) + ...
                    handles.([head,'alpha'])(1,c)+180)/2;
            else
                angle = (handles.([head,'alpha'])(2,c) + ...
                    handles.([head,'alpha'])(1,c)-180)/2;
            end
            set(handles.([head,'angle']), 'String', sprintf('%0.1f', angle));
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
            zoom on;
        else
            % Diable slider
            set(handles.([head, 'slider']), 'enable', 'off');
            set(handles.([head, 'angle']), 'enable', 'off');
        end
    case 2
        % Define square voxels
        axis image;
        
        % Disable slider
        set(handles.([head, 'slider']), 'enable', 'off');
        set(handles.([head, 'angle']), 'String', '');
        set(handles.([head, 'angle']), 'enable', 'off');
        
        % If data exists
        if isfield(handles, [head,'radiso']) && ...
                size(handles.([head,'radiso']), 2) == 3
            hold on;

            % Initialize legend text
            legends = cell(1,size(handles.([head, 'alpha']),2)+1);
            
            % Plot isocenter
            [x, y] = pol2cart(linspace(0,2*pi,100), ...
                handles.([head, 'radiso'])(3));
            x = x + handles.([head, 'radiso'])(1);
            y = y + handles.([head, 'radiso'])(2);
            plot(y, x, '-r','LineWidth',2);
            legends{1} = sprintf('%0.2f cm', ...
                handles.([head, 'radiso'])(3));
            
            % Plot field centers
            for i = 1:size(handles.([head, 'alpha']),2)
                [x, y]  = pol2cart(handles.([head, 'alpha'])(:,i)*pi/180, ...
                    handles.radius);
                plot(y, x, '-', 'Color', cmap(i,:));
                
                % Compute central axis angle (for display)
                if handles.([head,'alpha'])(2,i) < handles.([head,'alpha'])(1,i)
                    angle = (handles.([head,'alpha'])(2,i) + ...
                        handles.([head,'alpha'])(1,i)+180)/2;
                else
                    angle = (handles.([head,'alpha'])(2,i) + ...
                        handles.([head,'alpha'])(1,i)-180)/2;
                end
            
                legends{i+1} = sprintf('%0.1f', angle);
            end

            legend(legends);

            xlabel('IEC X Axis (cm)');
            ylabel('IEC Z Axis (cm)');

            xlim([-1 1]);
            set(gca,'XTick',-1:0.2:1);
            ylim([-1 1]);
            set(gca,'YTick',-1:0.2:1);
            hold off;
            grid on;

            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
            zoom on;
        end
end

% Return the modified handles
varargout{1} = handles; 
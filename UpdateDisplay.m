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
    'Longitudinal Profiles'
    'MLC X Offsets'
    'MLC Y Offsets'
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

% Get slider and angle
c = round(get(handles.([head,'slider']), 'Value'));

% Execute code block based on display GUI item value
switch get(handles.([head, 'display']),'Value')
    case 1 
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
            plot(y * 10, x * 10, '-r','LineWidth',2);
            legends{1} = sprintf('%0.2f mm', ...
                handles.([head, 'radiso'])(3) * 10);
            
            % Plot field centers
            for i = 1:size(handles.([head, 'alpha']),2)
                [x, y]  = pol2cart(handles.([head, 'alpha'])(:,i)*pi/180, ...
                    handles.radius);
                plot(y * 10, x * 10, '-', 'Color', cmap(i,:));
                
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

            xlabel('IEC X Axis (mm)');
            ylabel('IEC Z Axis (mm)');

            xlim([-5 5]);
            set(gca,'XTick',-5:1:5);
            ylim([-5 5]);
            set(gca,'YTick',-5:1:5);
            hold off;
            grid on;

            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
            zoom on;
        end
    case 3
        % If data exists
        if isfield(handles, [head,'frames']) && ...
                size(handles.([head,'frames']), 1) > 0 && ...
                size(handles.([head,'frames']), 3) >= c
            
            % Enable slider
            set(handles.([head, 'slider']), 'enable', 'on');
            set(handles.([head, 'angle']), 'enable', 'on');
            
            % Extract circumferential profile
            profile = handles.([head,'frames'])(handles.profile,:,c);
            
            % Plot map
            plot(handles.itheta, profile, '-b');
            xlim([1 361]);
            set(gca,'XTick', 1:30:361);
            set(gca,'XTickLabel', -180:30:180);
            xlabel('ArcCHECK Angle (deg)');
            ylabel('Measured Dose (cGy)');
            grid on;

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
        end
    case 4
        % If data exists
        if isfield(handles, [head,'frames']) && ...
                size(handles.([head,'frames']), 1) > 0 && ...
                size(handles.([head,'frames']), 3) >= c
            
            % Enable slider
            set(handles.([head, 'slider']), 'enable', 'on');
            set(handles.([head, 'angle']), 'enable', 'on');
            
            % Extract circumferential profile
            profile = handles.([head,'frames'])(handles.profile,:,c);
            
            % Determine location of maximum
            [~, I] = max(profile);

            % Circshift to center maximum
            profile = circshift(profile, floor(size(profile,2)/2)-I, 2);
            frame = squeeze(circshift(handles.([head,'frames'])(:,:,c), ...
                floor(size(profile,2)/2)-I, 2));

            % Redetermine location and value of maximum
            [C, I] = max(profile);

            % Search left side for half-maximum value
            for j = I:-1:1
                if profile(j) == C/2
                    l = j;
                    break;
                elseif profile(j) < C/2 && profile(j+1) > C/2
                    l = interp1(profile(j:j+1), j:j+1, C/2, 'linear');
                    break;
                end
            end

            % Search right side for half-maximum value
            for j = I:size(profile,2)-1
                if profile(j) == C/2
                    r = j;
                    break;
                elseif profile(j) > C/2 && profile(j+1) < C/2
                    r = interp1(profile(j:j+1), j:j+1, C/2, 'linear');
                    break;
                end
            end 
            
            % Interpolate longitudinal profile
            long = interp1(1:size(frame,2), frame(:,:)', (r+l)/2);
            
            % Plot map
            plot(handles.iY(:,1), long, '-b');
            xlim([-10 10]);
            set(gca,'XTick', -10:2:10);
            set(gca,'XTickLabel', -10:2:10);
            xlabel('IEC Y (cm)');
            ylabel('Measured Dose (cGy)');
            grid on;

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
        end
    case 5
        % Disable slider
        set(handles.([head, 'slider']), 'enable', 'off');
        set(handles.([head, 'angle']), 'String', '');
        set(handles.([head, 'angle']), 'enable', 'off');
        
        % If data exists
        if isfield(handles, [head,'alpha']) && ...
                size(handles.([head,'alpha']), 2) > 0 && ...
                isfield(handles, [head,'radiso']) && ...
                size(handles.([head,'radiso']), 2) == 3
            
            % Initialize offset array
            offsets = zeros(2, size(handles.([head,'alpha']), 2));
            
            % Loop through angles
            for i = 1:size(handles.([head,'alpha']), 2)
                
                % Convert points to cartesian coordinates
                [x, y] = pol2cart(handles.([head,'alpha'])(:,i)*pi/180, ...
                    handles.radius);
        
                % Compute disance from line to radiation isocenter
                offsets(1,i) = -((y(2)-y(1)) * handles.([head,'radiso'])(1) ...
                    - (x(2)-x(1)) * handles.([head,'radiso'])(2) - x(1) * ...
                    y(2) + x(2) * y(1)) / sqrt((x(2)-x(1))^2 + (y(2)-y(1))^2);

                % Compute central axis angle (for display)
                if handles.([head,'alpha'])(2,i) < handles.([head,'alpha'])(1,i)
                    offsets(2,i) = (handles.([head,'alpha'])(2,i) + ...
                        handles.([head,'alpha'])(1,i)+180)/2;
                else
                    offsets(2,i) = (handles.([head,'alpha'])(2,i) + ...
                        handles.([head,'alpha'])(1,i)-180)/2;
                end
            end
            
            % Plot map
            h = plot(offsets(2,:), offsets(1,:) * 10, 'o');
            set(h,'MarkerEdgeColor','b','MarkerFaceColor','b')
            xlim([min(offsets(2,:))-0.1 max(offsets(2,:))+0.1]);
            xlabel('Beam Angle (deg)');
            ylim([-3 3]);
            set(gca,'YTick', -3:0.5:3);
            ylabel('MLC X Offset (mm)');
            grid on;
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
            zoom on;
        end
    case 6
        % Disable slider
        set(handles.([head, 'slider']), 'enable', 'off');
        set(handles.([head, 'angle']), 'String', '');
        set(handles.([head, 'angle']), 'enable', 'off');
        
        % If data exists
        if isfield(handles, [head,'frames']) && ...
                size(handles.([head,'frames']), 1) > 0 && ...
                size(handles.([head,'frames']), 3) >= c
            
            % Initialize offset array
            offsets = zeros(2, size(handles.([head,'frames']), 3));
            
            % Loop through frames
            for i = 1:size(handles.([head,'frames']), 3)
                
                % Extract circumferential profile
                profile = handles.([head,'frames'])(handles.profile,:,i);
            
                % Determine location of maximum
                [~, I] = max(profile);

                % Circshift to center maximum
                profile = circshift(profile, floor(size(profile,2)/2)-I, 2);
                frame = squeeze(circshift(handles.([head,'frames'])(:,:,i), ...
                    floor(size(profile,2)/2)-I, 2));

                % Redetermine location and value of maximum
                [C, I] = max(profile);

                % Search left side for half-maximum value
                for j = I:-1:1
                    if profile(j) == C/2
                        l = j;
                        break;
                    elseif profile(j) < C/2 && profile(j+1) > C/2
                        l = interp1(profile(j:j+1), j:j+1, C/2, 'linear');
                        break;
                    end
                end

                % Search right side for half-maximum value
                for j = I:size(profile,2)-1
                    if profile(j) == C/2
                        r = j;
                        break;
                    elseif profile(j) > C/2 && profile(j+1) < C/2
                        r = interp1(profile(j:j+1), j:j+1, C/2, 'linear');
                        break;
                    end
                end 
            
                % Interpolate longitudinal profile
                long = interp1(1:size(frame,2), frame(:,:)', (r+l)/2);
            
                % Determine location and value of longitudinal maximum
                [C, I] = max(long);
                
                % Search left side for half-maximum value
                for j = I:-1:1
                    if long(j) == C/2
                        l = handles.iY(j);
                        break;
                    elseif long(j) < C/2 && long(j+1) > C/2
                        l = interp1(long(j:j+1), handles.iY(j:j+1), C/2, 'linear');
                        break;
                    end
                end

                % Search right side for half-maximum value
                for j = I:size(long,2)-1
                    if long(j) == C/2
                        r = handles.iY(j);
                        break;
                    elseif long(j) > C/2 && long(j+1) < C/2
                        r = interp1(long(j:j+1), handles.iY(j:j+1), C/2, 'linear');
                        break;
                    end
                end
                
                % Store field center
                offsets(1,i) = (r+l)/2;
                
                % Compute central axis angle
                if handles.([head,'alpha'])(2,i) < handles.([head,'alpha'])(1,i)
                    offsets(2,i) = (handles.([head,'alpha'])(2,i) + ...
                        handles.([head,'alpha'])(1,i)+180)/2;
                else
                    offsets(2,i) = (handles.([head,'alpha'])(2,i) + ...
                        handles.([head,'alpha'])(1,i)-180)/2;
                end
            end
            
            % Plot map
            h = plot(offsets(2,:), offsets(1,:) * 10, 'o');
            set(h,'MarkerEdgeColor','b','MarkerFaceColor','b')
            xlim([min(offsets(2,:))-0.1 max(offsets(2,:))+0.1]);
            xlabel('Beam Angle (deg)');
            ylim([-3 3]);
            set(gca,'YTick', -3:0.5:3);
            ylabel('MLC Y Offset (mm)');
            grid on;
            
            % Turn on display
            set(allchild(handles.([head, 'axes'])), 'visible', 'on'); 
            set(handles.([head, 'axes']), 'visible', 'on'); 
            zoom on;
        end
end

% Return the modified handles
varargout{1} = handles; 
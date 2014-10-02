function handles = ParseSNCProfiles(handles, head)
% ParseSNCProfiles extracts star shot frames from an ArcCheck movie file,
% and computes the FWHM defined center through the entrance/exit profiles. 
% While loading each frame, the GUI axes handle is updated to display the
% frame scaled image. This function is called by ArcCheckRadIso; see the 
% readme for more information on data acquisition.
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

% Log start
Event('Parsing frames from SNC data');
tic;

% Check if data exists
if isfield(handles, [head,'data']) && ~isempty(handles.([head,'data'])) > 0
    
    % Initialize counters
    c = 0;
    i = 0;

    % Log plot actions
    Event(['Clearing plot handle ',head, 'axes']);
    
    % Clear and set reference to axis
    cla(handles.([head, 'axes']), 'reset');
    axes(handles.([head, 'axes']));
    
    % Enable the slider
    set(handles.([head,'slider']), 'Enable', 'On');
    set(handles.([head,'slider']), 'Min', 1);
    set(handles.([head,'slider']), 'Max', 20);
    set(handles.([head,'angle']), 'Enable', 'On');
    
    % Set display to "Measured Data"
    set(handles.([head, 'display']), 'Value', 1);

    % Continue while the counter has not reached the end of the data array
    while i < size(handles.([head,'data']),1)
        % Increment data point counter
        i = i + 1;

        % Begin searching ahead
        for j = i+1:size(handles.([head,'data']),1)

            % If there is a gap in the data
            if j == size(handles.([head,'data']),1) || ...
                    abs(handles.([head,'data'])(j+1,2) - ...
                    handles.([head,'data'])(j,2)) > 2 

                % Log find
                Event(sprintf(['Frame identified from packets %i to %i, ', ...
                    'computing integral dose'], i, j));
                
                % Extract data
                group(1:1386) = (handles.([head,'data'])(j, 12:1397) - ...
                    handles.([head,'data'])(i, 12:1397) - ...
                    (handles.([head,'data'])(j,3) - ...
                    handles.([head,'data'])(i,3)) .* ...
                    handles.([head,'bkgd'])(2:1387)) .* ...
                    handles.([head,'cal'])(2:1387) * handles.([head,'dose']);

                % Jump forward
                i = j;
                break;      
            end
        end

        % Increment counter
        c = c + 1;

        % Generate scattered interpolant object for diode data
        scatter = scatteredInterpolant([handles.([head,'theta'])-360, ...
            handles.([head,'theta']), handles.([head,'theta'])+360]', ...
            [handles.([head,'Y']), handles.([head,'Y']), handles.([head,'Y'])]', ...
            [group, group, group]', 'linear', 'linear');

        % Interpolate group data into 2D array of itheta, iY
        handles.([head,'frames'])(:,:,c) = scatter(handles.itheta, handles.iY);
        Event(sprintf('Diode data interpolated to cylindrical map for frame %i', i));

        % Extract center profile
        profile = handles.([head,'frames'])(handles.profile,:,c);

        % Determine location of maximum
        [~, I] = max(profile);

        % Circshift to center maximum
        profile = circshift(profile, floor(size(profile,2)/2)-I, 2);
        itheta = circshift(handles.itheta, floor(size(profile,2)/2)-I, 2);
        frame = squeeze(circshift(handles.([head,'frames'])(:,:,c), ...
            floor(size(profile,2)/2)-I, 2));
        Event(sprintf('Frame circshifted to center on position %i', I));
        
        % Redetermine location and value of maximum
        [C, I] = max(profile);
        Event(sprintf(['Radial entrance profile maximum identified as %g at', ...
            ' angle %0.3f deg'], C, itheta(1,I)));

        % Search left side for half-maximum value
        for j = I:-1:1
            if profile(j) == C/2
                l = itheta(1,j);
                li = j;
                break;
            elseif profile(j) < C/2 && profile(j+1) > C/2
                l = interp1(profile(j:j+1), itheta(1,j:j+1), C/2, 'linear');
                li = interp1(profile(j:j+1), j:j+1, C/2, 'linear');
                break;
            end
        end
        Event(sprintf('Left hand half-maximum identified at angle %0.3f deg', l));

        % Search right side for half-maximum value
        for j = I:size(profile,2)-1
            if profile(j) == C/2
                r = itheta(1,j);
                ri = j;
                break;
            elseif profile(j) > C/2 && profile(j+1) < C/2
                r = interp1(profile(j:j+1), itheta(1,j:j+1), C/2, 'linear');
                ri = interp1(profile(j:j+1), j:j+1, C/2, 'linear');
                break;
            end
        end 
        Event(sprintf('Right hand half-maximum identified at angle %0.3f deg', r));

        % Compute angle as average of r and l thetas
        if (r < l); r = r + 360; end
        handles.([head,'alpha'])(1,c) = mod((r+l)/2 - ...
            handles.([head,'rotation']),360); %#ok<*SAGROW>
        Event(sprintf('Frame %i entrance beam angle computed as %0.3f deg', c, ...
            handles.([head,'alpha'])(1,c)));
        
        % Interpolate longitudinal profile
        long = interp1(1:size(frame,2), frame(:,:)', (ri+li)/2);
        Event('Longitudinal entrance profile interpolated along profile center');
        
        % Determine location and value of longitudinal maximum
        [C, I] = max(long);
        Event(sprintf(['Longitudinal entrance profile maximum identified as %g at', ...
            ' angle %0.3f cm'], C, handles.iY(I)));

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
        Event(sprintf('Left hand half-maximum identified at IEC Y %0.3f cm', l));

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
        Event(sprintf('Right hand half-maximum identified at IEC Y %0.3f cm', r));

        % Store field center
        handles.([head,'beta'])(1,c) = (r+l)/2;
        Event(sprintf('Entrance IEC Y FWHM defined center identified at %0.3f cm', ...
            handles.([head,'beta'])(1,c)));
        
        % Circshift to center the exit profile
        profile = circshift(profile, itheta(1,1) - ...
            floor(handles.([head,'alpha'])(1,c)), 2);
        itheta = circshift(itheta, itheta(1,1) - ...
            floor(handles.([head,'alpha'])(1,c)), 2);
        frame = squeeze(circshift(frame, itheta(1,1) - ...
            floor(handles.([head,'alpha'])(1,c)), 2));
        
        % Determine location and value of maximum
        [C, I] = max(profile(floor(size(profile,2)/4):...
            floor(size(profile,2)*3/4)));
        I = I + floor(size(profile,2)/4);
        Event(sprintf(['Radial exit profile maximum identified as %g at', ...
            ' angle %0.3f deg'], C, itheta(1,I)));

        % Search left side for half-maximum value
        for j = I:-1:1
            if profile(j) == C/2
                l = itheta(1,j);
                li = j;
                break;
            elseif profile(j) < C/2 && profile(j+1) > C/2
                l = interp1(profile(j:j+1), itheta(1,j:j+1), C/2, 'linear');
                li = interp1(profile(j:j+1), j:j+1, C/2, 'linear');
                break;
            end
        end
        Event(sprintf('Left hand half-maximum identified at angle %0.3f deg', l));

        % Search right side for half-maximum value
        for j = I:size(profile,2)-1
            if profile(j) == C/2
                r = itheta(1,j);
                ri = j;
                break;
            elseif profile(j) > C/2 && profile(j+1) < C/2
                r = interp1(profile(j:j+1), itheta(1,j:j+1), C/2, 'linear');
                ri = interp1(profile(j:j+1), j:j+1, C/2, 'linear');
                break;
            end
        end 
        Event(sprintf('Right hand half-maximum identified at angle %0.3f deg', r));

        % Compute angle as average of r and l thetas
        if (r < l); r = r + 360; end
        handles.([head,'alpha'])(2,c) = mod((r+l)/2, 360);
        Event(sprintf('Frame %i exit beam angle computed as %0.3f deg', c, ...
            handles.([head,'alpha'])(1,c)));

        % Interpolate longitudinal profile
        long = interp1(1:size(frame,2), frame(:,:)', (ri+li)/2);
        Event('Longitudinal exit profile interpolated along profile center');
        
        % Determine location and value of longitudinal maximum
        [C, I] = max(long);
        Event(sprintf(['Longitudinal exit profile maximum identified as %g at', ...
            ' angle %0.3f cm'], C, handles.iY(I)));

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
        Event(sprintf('Left hand half-maximum identified at IEC Y %0.3f cm', l));

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
        Event(sprintf('Right hand half-maximum identified at angle %0.3f deg', r));

        % Store field center
        handles.([head,'beta'])(2,c) = (r+l)/2;
        Event(sprintf('Exit IEC Y FWHM defined center identified at %0.3f cm', ...
            handles.([head,'beta'])(2,c)));
        
        % If T&G offset correction is enabled, adjust angles
        if handles.usetg == 1
            Event(sprintf(['Entrance and exit angles adjusted by %0.3f cm ', ...
                ', or %0.3f deg, perpendicular to the beam angle to ', ...
                'account for T&G effect'], handles.tg, ...
                asind(handles.tg/handles.radius)));
            
            % Decrease entrance angle by arcsin
            handles.([head,'alpha'])(1,c) = handles.([head,'alpha'])(1,c) ...
                - asind(handles.tg/handles.radius);
           
            % Increase exit angle by arcsin
            handles.([head,'alpha'])(2,c) = handles.([head,'alpha'])(2,c) ...
                + asind(handles.tg/handles.radius);
        end
        
        % Compute central axis angle (for display)
        if handles.([head,'alpha'])(2,c) < handles.([head,'alpha'])(1,c)
            angle = (handles.([head,'alpha'])(2,c) + ...
                handles.([head,'alpha'])(1,c)+180)/2;
        else
            angle = (handles.([head,'alpha'])(2,c) + ...
                handles.([head,'alpha'])(1,c)-180)/2;
        end
        
        % Log plotting
        Event(sprintf('Plotting frame %i and pausing 0.1 sec', c));

        % Update slider and angle
        set(handles.([head,'slider']), 'Value', ...
            min(c, get(handles.([head,'slider']), 'Max')));
        set(handles.([head,'angle']), 'String', sprintf('%0.2f', angle));

        % Plot map
        imagesc(circshift(handles.([head,'frames'])(:,:,c),-180,2));
        set(gca,'XTick', 1:30:361);
        set(gca,'XTickLabel', -180:30:180);
        xlabel('ArcCHECK Angle (deg)');
        set(gca,'YTick', 1:20:201);
        set(gca,'YTickLabel', 10:-2:-10);
        ylabel('ArcCHECK IEC Y (cm)');
        
        % Update plot and pause temporarily
        drawnow;
        pause(0.1);
        
        % Temporary workaround to remove angles through couch
        if (angle > 121 && angle < 139) == 130 || ...
                (angle > 221 && angle < 239)
            % Warn user that the angle will be ingored
            Event(sprintf(['Frame %i removed from radiation isocenter ', ...
               'calculation as the angle %0.3f is known to go through ', ...
               'the couch edge'], c, angle), 'WARN');
           
            % Decrease the counter to overwrite the data (assumes
            % additional points will be added afterwards)
            c = c - 1; 
        end
    end
    
    % If less than three frames were found, error 
    if c < 3
        Event(['At least three frames are required to perform the ', ...
            'analysis. Add more angle measurements.'], 'ERROR');
    end
    
    % Update slider maximum to actual value
    set(handles.([head,'slider']), 'Min', 1);
    set(handles.([head,'slider']), 'Max', c);
    set(handles.([head,'slider']), 'Value', c);
    set(handles.([head,'slider']), 'SliderStep', [1/(c-1) 5/(c-1)]);
else
    % Log warning
    Event('No data found to parse', 'WARN');
end

% Log finish
Event(sprintf('Frame parsing completed successfully in %0.3f seconds', toc));

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end
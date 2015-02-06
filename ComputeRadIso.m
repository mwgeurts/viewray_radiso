function [isocenter, isoradius] = ComputeRadIso(alpha, radius)
% ComputeRadIso computes the minimum radius and position of a circle that 
% intersects all rays.  The n rays are defined by two points in cylindrical 
% coordinates; the first input argument is a 2 x n array of angles, while
% the second is the radius.
%
% The algorithm used to determine the minimum radius is detailed in Depuydt
% et al, Computer-aided analysis of star shot films for high-accuracy 
% radiation therapy treatment units, Phys. Med. Biol. 57 (2012), 2997-3011.
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

% Run in try-catch to log error via Event.m
try
    
% Log start
Event('Computing 2D radiation isocenter using Depuydt method');
tic;

%% Compute Triplets
% Compute each permutation of three rays
triplets = nchoosek(1:size(alpha,2), 3);
Event(sprintf('%i triplet permutations will be computed', size(triplets,1)));

% Initialize array of circle positions and radii
circles = zeros(size(alpha,2), 3);

% Loop through each triplet
for i = 1:size(triplets,1)
    % Check if alpha points are within 1 deg of each other; if so, skip
    % this triplet (necessary for combination analysis)
    if round(alpha(1,triplets(i,1))) == round(alpha(1,triplets(i,2))) || ...
            round(alpha(1,triplets(i,1))) == round(alpha(1,triplets(i,3))) || ...
            round(alpha(1,triplets(i,2))) == round(alpha(1,triplets(i,3)))
        
        % Log skip
        Event(sprintf('Triplet %i ignored as duplicate angles exist', i));
        
        % Skip ahead
        continue;
    end
    
    % Convert alpha points to cartesian space
    [x1, y1]  = pol2cart(alpha(:,triplets(i,1))*pi/180, radius);
    [x2, y2]  = pol2cart(alpha(:,triplets(i,2))*pi/180, radius);
    [x3, y3]  = pol2cart(alpha(:,triplets(i,3))*pi/180, radius);
    
    % Compute intersection of triplet rays 1 and 2
    p1 = polyfit(x1,y1,1);
    p2 = polyfit(x2,y2,1);
    x12 = fzero(@(x) polyval(p1-p2,x),3);
    y12 = polyval(p1,x12);
    
    % Compute intersection of triplet rays 1 and 3
    p1 = polyfit(x1,y1,1);
    p2 = polyfit(x3,y3,1);
    x13 = fzero(@(x) polyval(p1-p2,x),3);
    y13 = polyval(p1,x13);
    
    % Compute intersection of triplet 1 and 2
    p1 = polyfit(x2,y2,1);
    p2 = polyfit(x3,y3,1);
    x23 = fzero(@(x) polyval(p1-p2,x),3);
    y23 = polyval(p1,x23);
    
    % Create triangulation object given intersection points
    DT = delaunayTriangulation([x12; x13; x23], [y12; y13; y23]);
    
    % Compute incenter and radius
    [IC, r] = incenter(DT);
    if ~isempty(IC)
        circles(i,1:2) = IC;
        circles(i,3) = r;
    else
        % Otherwise, log error
        Event(sprintf(['Incenter failed for Delaunay triangulation of ', ...
            'triplet %i [%g %g %g], [%g %g %g]'], i, x12, x13, x23, y12, ...
            y13, y23));
    end
end

%% Find smallest circle intersecting all rays
% Sort circles by radius ascending
circles = sortrows(circles,3);
Event('Incenter circles sorted by ascending radius');

% Loop through each circle, starting at the smallest
for i = 1:size(circles,1)
    
    % If the radius is greater than zero
    if circles(i,3) > 0
        
        % Initialize flag
        flag = true;
        
        % Loop through each ray
        for j = 1:size(alpha,2)
            
            % Convert alpha points to cartesian space
            [x, y]  = pol2cart(alpha(:,j)*pi/180, radius);
            
            % Compute intersection
            [xc, ~] = linecirc((y(2)-y(1))/(x(2)-x(1)), ...
                y(2)-(y(2)-y(1))/(x(2)-x(1))*x(2), circles(i,1), ...
                circles(i,2), circles(i,3)+1e-6);
            
            % If the ray did not intersect with the circle
            if isnan(xc(1))
                
                % Set the flag to false and break the loop
                flag = false;
                break;
            end 
        end
        
        % If all rays intersect the circle
        if flag
            % Log result
            Event(sprintf(['Triplet %i incenter identified as smallest', ...
                ' radius intersecting all rays (%g cm)'], i, circles(i,3)));
            
            % Set radiation isocenter to the smallest circle
            isocenter = circles(i,1:2);
            isoradius = circles(i,3);
            
            % Exit the circle loop, as the smallest circle was found
            break;
        end
    end 
end

% If no value was found
if ~exist('isocenter', 'var')
    Event('A minimum radius was not found that intersects all rays', 'ERROR');
end

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end 
function radiso = ComputeRadIso(alpha, radius)
% ComputeRadIso computes the minimum radius and position of a circle that 
% intersects all rays.  The n rays are defined by two points in cylindrical 
% coordinates; the first input argument is a 2 x n array of angles, while
% the second is the radius.
%
% The algorithm used to determine the minimum radius is detailed in Depuydt
% et al, Computer-aided analysis of star shot films for high-accuracy 
% radiation therapy treatment units, Phys. Med. Biol. 57 (2012), 2997?3011.
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

%% Compute Triplets
% Compute each permutation of three rays
triplets = nchoosek(1:size(alpha,2), 3);

% Initialize array of circle positions and radii
circles = zeros(size(alpha,2), 3);

% Loop through each triplet
for i = 1:size(triplets,1)
    % Convert alpha points to cartesian space
    [x1, y1]  = pol2cart(alpha(:,triplets(i,1))*pi/180, radius);
    [x2, y2]  = pol2cart(alpha(:,triplets(i,2))*pi/180, radius);
    [x3, y3]  = pol2cart(alpha(:,triplets(i,3))*pi/180, radius);
    
    % Compute intersection points
    [x12, y12] = polyxpoly(x1, y1, x2, y2);
    [x13, y13] = polyxpoly(x1, y1, x3, y3);
    [x23, y23] = polyxpoly(x2, y2, x3, y3);
    
    % If lines do not intersect, skip
    if size(x12,2) == 0 || size(x13,2) == 0 || size(x23,2) == 0
        continue
    end
    
    % Compute circle center
    circles(i,1) = mean([x12 x13 x23]);
    circles(i,2) = mean([y12 y13 y23]);
    
    % Compute radii of tangent circle
    r1 = abs(det([[x1(2);y1(2)]-[x1(1);y1(1)],[circles(i,1);circles(i,2)]- ...
        [x1(1);y1(1)]]))/abs([x1(2);y1(2)]-[x1(1);y1(1)]);
    r2 = abs(det([[x2(2);y2(2)]-[x2(1);y2(1)],[circles(i,1);circles(i,2)]- ...
        [x2(1);y2(1)]]))/abs([x2(2);y2(2)]-[x2(1);y2(1)]);
    r3 = abs(det([[x3(2);y3(2)]-[x3(1);y3(1)],[circles(i,1);circles(i,2)]- ...
        [x3(1);y3(1)]]))/abs([x3(2);y3(2)]-[x3(1);y3(1)]);

    % Set maximum
    circles(i,3) = max(max([r1; r2; r3]));
end

%% Find smallest circle intersecting all rays
% Sort circles by radius ascending
circles = sortrows(circles,3);

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
                circles(i,2), circles(i,3));
            
            % If the ray did not intersect with the circle
            if isnan(xc(1))
                
                % Set the flag to false and break the loop
                flag = false;
                break;
            end 
        end
        
        % If all rays intersect the circle
        if flag
            
            % Set radiation isocenter to the smallest circle
            radiso = circles(i,:);
            break;
        end
    end 
end
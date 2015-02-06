function [isocenter, isoradius] = ComputeRadIso3d(alpha, beta, radius)
% ComputeRadIso3d computes the minimum radius and position of a sphere that 
% intersects all rays.  The n rays are defined by two points in cylindrical 
% coordinates; the first input argument is a 2 x n array of angles, the 
% second is a 2 x n array of entrance and exit IEC-Y locations, and the
% third is the radius on which the alpha points are defined.
%
% The algorithm uses the MATLAB fminsearch optimization toolbox function to
% iteratively optimize the point coordinates that minimizes the maximum  
% distance between the point for each ray.  The initial guess for isocenter
% is set at 0,0,0, and convergence tolerances of 1e-5 are placed.  The
% Nelder-Mead simplex direct search optimization algorithm is detailed in 
% Lagarias, J.C., J. A. Reeds, M. H. Wright, and P. E. Wright, "Convergence 
% Properties of the Nelder-Mead Simplex Method in Low Dimensions," SIAM 
% Journal of Optimization, Vol. 9 Number 1, pp. 112-147, 1998.
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
Event(['Computing 3D radiation isocenter using Nelder-Mead simplex ', ...
    'direct search method']);
tic;

% Run minimum solution finder, using 0,0,0 as initial guess
Event('[0 0 0] cm set as initial guess');

% Set optimization options
options = optimset('Display', 'off', 'MaxIter', 200, 'MaxFunEvals', 500, ...
    'TolFun', 1e-5, 'TolX', 1e-5, 'PlotFcns', []);

% Start optimization
[isocenter, isoradius, exitflag, output] = fminsearch(@maxradius, [0,0,0], ...
    options, alpha, beta, radius);

% Verify exit status
if exitflag == 1
    
    % Optimization converged
    Event(sprintf(['Optimization converged to solution after %i iterations', ...
        ' and %i function calls in %0.3f seconds'], output.iterations, ...
        output.funcCount, toc));
    
elseif exitflag == 0
    
    % Optimization stopped due to MaxIter or MaxFunEvals
    Event(sprintf(['Optimization stopped prematurely after %i iterations', ...
        ' and %i function calls in %0.3f seconds'], output.iterations, ...
        output.funcCount, toc));
    
elseif exitflag == -1
    
    % Optimization terminated by output function
    Event(sprintf(['Optimization was terminated by the output function in', ...
        ' %0.3f seconds'], toc));
end

% Log solution
Event(sprintf(['Minimum sphere of radius %g cm identified at coordinates ', ...
    '[%g %g %g] cm'], isoradius, isocenter));

% Catch errors, log, and rethrow
catch err
    Event(getReport(err, 'extended', 'hyperlinks', 'off'), 'ERROR');
end 

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function maxr = maxradius(center, a, b, r)
% maxradius is the objective function called during fminsearch in the
% parent function ComputeRadIso3d
%
% center The point X/Y/Z coordinates (obective function variable)
% a      2 x n array of alpha values (cylindrical angles) for the entrance
%        and exit points of the ray
% b 	 2 x n array of beta values (cylindrical Y values) for the entrance
%        and exit points of the ray
% r      Radius of the cylinder upon which the alpha values are determined

% Initialize variable for radii
rs = zeros(size(a,2),1);

% Loop through each line
for i = 1:size(a,2)

    % Convert alpha/beta points to cartesian space
    [x, y]  = pol2cart(a(:,i)*pi/180, r);
    z = b(:,i);

    % Compute minimum distance from point to line
    rs(i) = norm(cross([x(1),y(1),z(1)] - [x(2),y(2),z(2)], ...
        [center(1),center(2),center(3)] - [x(2),y(2),z(2)])) / ...
        norm([x(1),y(1),z(1)] - [x(2),y(2),z(2)]);

end

% Set return variable to maximum of all distances
maxr = max(rs);

end
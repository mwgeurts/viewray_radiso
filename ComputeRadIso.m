function radiso = ComputeRadIso(alpha, radius)


%% Compute Triplets
triplets = nchoosek(1:size(alpha,2), 3);
circles = zeros(size(alpha,2), 3);

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
    circles(i,3) = max([r1(1), r2(1), r3(1)]);
end

%% Find smallest circle intersecting all rays
circles = sortrows(circles,3);

for i = 1:size(circles,1)
    if circles(i,3) > 0
        flag = true;
        for j = 1:size(alpha,2)
            % Convert alpha points to cartesian space
            [x, y]  = pol2cart(alpha(:,j)*pi/180, radius);
            
            % Compute intersection
            [xc, ~] = linecirc((y(2)-y(1))/(x(2)-x(1)), ...
                y(2)-(y(2)-y(1))/(x(2)-x(1))*x(2), circles(i,1), ...
                circles(i,2), circles(i,3));
            
            if isnan(xc(1))
                flag = false;
                break;
            end 
        end
        
        if flag
            radiso = circles(i,:);
            break;
        end
    end 
end
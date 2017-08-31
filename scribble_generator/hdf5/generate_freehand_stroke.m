function [ spline_img ] = generate_freehand_stroke(x,y,width, height, brush_radius)

%Default value for brush_radius if not specified
if nargin == 4; brush_radius = 1; end

%Linearly interpolate between x-y coords
x_lin = [];
y_lin = [];
for i = 1:numel(x) - 1
    x_lin = [x_lin linspace(x(i), x(i+1), 50)];
    y_lin = [y_lin linspace(y(i), y(i+1), 50)];
end

x_lin = floor(x_lin);
y_lin = floor(y_lin);

%Initialise mask. Pad by brush radius
mask = zeros(width+2*brush_radius,height+2*brush_radius);
m = numel(x_lin);
for i = 1:m
    %taper edge
    s = min(floor(i/3),floor((m - i)/3));
    if s < brush_radius
        b_r = s;
        brush = strel('diamond',b_r).Neighborhood;
        
    else 
        b_r = brush_radius;
        if size(brush,1) ~= (2*brush_radius + 1); brush = strel('diamond',brush_radius).Neighborhood; end;
    end
    
    %coordinates of brush centre
    y_c = x_lin(i) + brush_radius;
    x_c = y_lin(i) + brush_radius;
    mask((x_c - b_r):(x_c + b_r), (y_c - b_r):(y_c + b_r)) = mask((x_c - b_r):(x_c + b_r), (y_c - b_r):(y_c + b_r)) + brush;
end
mask = mask((brush_radius + 1):(width + brush_radius),(brush_radius + 1):(height + brush_radius));
spline_img = mask > 0;
end
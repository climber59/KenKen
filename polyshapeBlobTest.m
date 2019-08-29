clear,clc,close all

x = [0 0 1 1];
y = [1 0 0 1];

p = simplify(polyshape({x,x,x+1,x+2,x+3},{y,y+1,y,y,y},'Simplify',false)); % double simplify prevents warning message
% p = polyshape({x,x,x+1},{y,y+1,y},'Simplify',true);
% p = simplify(p);
% p = polyshape(x,y);
% p = addboundary(p,x,y+1);


p2 = simplify(polyshape({1+x,1+x,1+x+1,1+x+1},{1+y,1+y+1,1+y,1+y+1},'Simplify',false));

c = plot([p,p2]); % p is a polyshape, c is a polygon
for i=1:length(c)
	c(i).ButtonDownFcn = @click;
end
axis equal


% ax = gca;
% ax.ButtonDownFcn = @click;

function [] = click(src,evt)
% 	src
% 	evt
	src.FaceColor
end
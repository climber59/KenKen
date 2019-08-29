function [] = blankNums()
		textGrid = matlab.graphics.primitive.Text.empty;
		notesGrid = matlab.graphics.primitive.Text.empty;
		strC = {};
		str = '';
		l = 0;
		for i = 1:n
			str = [str, num2str(i),' '];
			if mod(i,5)==0 || i==n
				strC{end+1} = str(1:end-1);
				l = max(l,length(strC{end}));
				str = '';
			end
		end
		strC
% 		length(strC{:})
% 		str(end) = '';
		fs = 1.5/(n*l)
		for r = 1:n
			for c = 1:n
				textGrid(r,c) = text(c+0.5,r+0.5,' ','FontSize',20,'HorizontalAlignment','center');
				for k = 1:n
% 					notesGrid(r,c,k) = text(c+k*0.85/n, r+0.9, num2str(k),'FontSize',10,'Visible','off');
					notesGrid(r,c,k) = text('Position',[c+.05 r+0.85],'String', strC,'FontName','FixedWidth','FontUnits','normalized','FontSize',fs,'Visible','off');
				end
			end
		end
		notesGrid(1,1,1).Visible = 'on';
		notesGrid(1,1,1).Extent
% 		notesGrid(1,1,1).Rotation = -90;
	end
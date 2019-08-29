
		% toolbar setup
		f.ToolBar = 'figure';
		tb = findall(f,'Type','uitoolbar');
		togs = findall(tb,'Parent',tb);
		for i = length(togs):-1:1
			s = togs(i).Tag;
			if ~(strcmp(s,'Exploration.Pan') || strcmp(s,'Exploration.ZoomOut') || strcmp(s,'Exploration.ZoomIn'))
				delete(togs(i))
			end
		end
		
		% Has issues. The ways the tools revert to the original view/zoom
		% seems to always go back to the original 5x5 window. Would probably
		% need some sort of custom reset button. On large grids it is also
		% fairly laggy. All text objects will still show up outside the axes.
		% Can be fixed by giving them all the 'Clipping' 'on' property.
		
%{
===================================== new features
copy notes to all of blob
-copies notes in current square to all others of the same blob

more options/controls for ui scaling

Export mode for printting/publish a good puzzle?
-can be done now with screenshots, so not essential

Zoom feature
-could potentially resolve a bunch of the ui issues on large grids
-alt option is to create a zoomed in version of the selected box to make
notes more visible on large grids

a way to highlight all of a given number?
--on the 20x20, bit hard to see all 17s on the board

some preset game modes?
-powers of two, addition only
-primes multiplication

===================================== known bugs
Double right-clicking counts as a left click
-not sure if f.SelectionType can differentiate different double clicks

===================================== Programming changes
changing tabs shouldn't necessarily close the enter tool
-mostly comes up when trying to change its size

investigate optimization of new game by not using 'cla'
-not as important with note optimizations. 20x20 takes ~8 seconds
-biggest slowdown atm is the matrix generation

make numSelection() only change to custom if done by user
-possibly with checks to evt
===================================== UI changes
large numbers may need commas for legibility
-generally not bad, but using 10.^(1:5) as the array is hard to read

numbers in the thousands do not show fully in small enter tools
-not priority as the tool scales

font scaling when resizing?
-with switch to 'normalized' most text() objects are covered
-uicontrol() objects may still need it

enter tool can extend beyond the right edge of the figure

size of ui options is dependent on the size of the figure when it first
runs. some things look good if it's a new figure or wonky if not
-mostly font sizes and the inital enter tool


===================================== Rule changes
allow negative numbers and 0. 
-requires a lot of rewrites
-- 0 is used frequently for blank numbers, both in generation and gameplay
-- negatives will likely need special code for operations and answers


%}

%#ok<*ST2NM>
%asdf#ok<*NASGU>
% remove warning for str2num(). I use str2num() instead of str2double()
% because it evaluates strings such as '112/7'

function [] = KenKen()
	f = [];
	ax = [];
	numGrid = [];
	blobs = [];
	indGrid = [];
	n = [];
	numPanel = [];
	textGrid = [];
	userGrid = [];
	notesGrid = [];
	blobSize = [];
	gridSize = [];
	finished = [];
	but = [];
	allowedOps = [];
	numPicker = [];
	addCheck = [];
	arrayOptions = [];
	arrayCustom = [];
	theNums = [];
	checkmark = [];
	noteMode = [];
	selectorBox = [];
	numBoxes = [];
	tableSlider = [];
	toolColumnsSlider = [];
	gValues = [];
	
	figureSetup();
	newGame();
	
	% Checks each note in a given box to see if it can be eliminated
	% because of a filled in box in the same row or column
	function [] = updateNotes(~,~,ra,ca)
		numPanel.Visible = 'off';
		if nargin < 4 %if no specified ra/rc, check all notes in all squares
			ra = 1:n;
			ca = 1:n;
		end
		for i = ra
			r = unique(userGrid(i,:)); % nums in row
			r(isnan(r)) = [];
			for j = ca
				if isnan(userGrid(i,j)) % only update squares not filled in
					k = unique([r, userGrid(:,j)']); % all nums in row and column
					k(isnan(k)) = [];
					for k = k
						butInd = 2 + find(theNums == k,1);
						notesGrid(i,j).String{but(butInd).UserData.cellRow}(but(butInd).UserData.strInds) = ' ';
					end
				end
			end
		end
	end
	
	
	% Added in case future development requires special code when resizing
	% the window
	function [] = resize(~,~)
		
	end
	
	% rescales the Enter Tool.
	function [] = toolScale(~,~,bigger)
		numPanel.Position([3,4]) = numPanel.Position([3,4])*1.1^bigger;
	end
	
	% Checks if the puzzle has been completed
	function [won] = winCheck()
		won = sum(sum(~isnan(userGrid)))==n^2; %everything filled in
		if ~won
			return
		end
		
		for i = 1:n^2
			won = (textGrid(i).Color(1)==0); % no red numbers
			if ~won
				return
			end
		end
		
		for i = 1:length(blobs)
			won = (blobs(i).UserData.opT.Color(1)==0); % no red operations
			if ~won
				return
			end
		end
		
		won = true; % no mistakes, display check mark, and return true
		checkmark.Visible = 'on';
	end
	
	% Handles mouse clicks within the figure window. Primarily handles the
	% positioning of the Enter Tool and enter/note switching when using
	% right clicks
	function [] = click(~,~)
		if finished
			return
		end
		highlight(false); % unhighlight last box
		m = floor(ax.CurrentPoint([3, 1]));% gives (r,c)
		if any(m<1) || any(m>n)
			numPanel.Visible = 'off';
			return
		end
		
		% find x,y location to put the enter tool
		% positioned at the right edge and with the height centered
		ax.Units = 'pixels';
		if ax.Position(4) > ax.Position(3) % axes limited by width
			x = m(2)*(ax.Position(3))/n + ax.Position(1);
			y = (n-m(1)+0.5)*(ax.Position(3))/n + (ax.Position(4) - ax.Position(2) - ax.Position(3))/2 - numPanel.Position(4)/2;
		else % axes limited by height
			x = m(2)*(ax.Position(4))/n + ax.Position(1) + (ax.Position(3) - ax.Position(4))/2;
			y = (n-m(1)+0.5)*(ax.Position(4)-ax.Position(2))/n + ax.Position(2) - numPanel.Position(4)/2;
		end
		ax.Units = 'normalized';		
		
		numPanel.Position(1) = x;
		numPanel.Position(2) = max(0, min([y, f.Position(4) - numPanel.Position(4)])); % keeps the tool from displaying off the screen vertically
		
		numPanel.UserData = m;
		if strcmp(f.SelectionType,'alt')
			noteMode = true;
			but(2).Visible = 'on';
		else
			noteMode = false;
			but(2).Visible = 'off';
		end
		highlight(true,m);
		f.UserData = f.SelectionType;
		for i = 3:n+2
			if notesGrid(m(1),m(2)).String{but(i).UserData.cellRow}(but(i).UserData.strInds(1)) ~=' '
				but(i).BackgroundColor = gValues.noteOnColor; % square color
			else
				but(i).BackgroundColor = gValues.noteOffColor;
			end
		end
		numPanel.Visible = 'on';
	end
	

	% Highlights the currently selected box. Green if entering big numbers,
	% blue if entering notes
	function [] = highlight(on,rc)
		if on
			selectorBox.XData = rc(2) + selectorBox.UserData.x;
			selectorBox.YData = rc(1) + selectorBox.UserData.y;
			selectorBox.FaceColor = [0.9 0.9 0.9] + [0 0.1*~noteMode 0.1*noteMode];
			selectorBox.Visible = 'on';
		else
			selectorBox.Visible = 'off';
		end
	end
	
	
% 	% Highlights all instances of a selected number. Helpful on large grids
% 	function [] = highlightAll(~,~,check, pick)
% 		for i = 1:n^2
% 			textGrid(i).Color(2) = 0.75*(check.Value && strcmp(textGrid(i).String,pick.String{pick.Value}));
% 		end
% 	end
	
	
	% Enters new numbers or notes into grid squares
	function [] = numFill(~,~,newNumStr, num, cellRow, strInds)
		r = numPanel.UserData(1); % get grid location from numPanel
		c = numPanel.UserData(2);
		
		% Entering/removing notes
		if noteMode
			userGrid(r,c) = nan; % remove any "big" numbers
			textGrid(r,c).String = '';
			if ~isnan(num)% change a specific number
				if notesGrid(r,c).String{cellRow}(strInds(1)) == ' '
					s = newNumStr;
					but(find(theNums == num, 1) + 2).BackgroundColor = gValues.noteOnColor;
				else
					s = ' ';
					but(find(theNums == num, 1) + 2).BackgroundColor = gValues.noteOffColor;
				end
				notesGrid(r,c).String{cellRow}(strInds) = s;
			elseif isnan(num) % enter all possible notes (based on latin square)
				notesGrid(r,c).String = notesGrid(1,1).UserData.all;
				updateNotes(0,0,r,c); % remove blocked numbers
				numPanel.Visible = 'off';
				highlight(false);
			else % X button pressed, clear the notes
				notesGrid(r,c).String = notesGrid(1,1).UserData.none;
				numPanel.Visible = 'off';
				highlight(false);
			end
			mistakeChecks(r,c);
		else
			% Enter 'big' number
			textGrid(r,c).FontSize = gValues.noteHeight/n;
			textGrid(r,c).String = newNumStr;
			if textGrid(r,c).Extent(3) > 1 % scale text to fit in the box
				textGrid(r,c).FontSize = textGrid(r,c).FontSize/textGrid(r,c).Extent(3);
			end
			numPanel.Visible = 'off';

			if isempty(num) % X button pressed
				num = nan; % should only check if turning off red text			
			else
				notesGrid(r,c).String = notesGrid(1,1).UserData.none;
			end
			userGrid(r,c) = num;
			mistakeChecks(r,c);

			% display the check mark if the puzzle is completed
			finished = winCheck();
			highlight(false);
		end
		
		% Checks for mistakes
		function [] = mistakeChecks(row,col)
			for i = 1:n %latin square mistakes
				blackNum(row,i);
				blackNum(i,col);
			end
			mathCheck(row,col); % check for math mistake
		end
	end
	
	
	% Checks if a newly entered 'big' number causes or resolves a math
	% mistake
	function [] = mathCheck(r,c)
		ind = indGrid(r,c); % find its blob
		blob = blobs(ind);
		count = 0;
		for i = 1:blob.UserData.size % count how many boxes in the blob are filled
			count = count + ~isnan(userGrid(blob.UserData.rc(i,1),blob.UserData.rc(i,2)));
		end
		
		if count~=blob.UserData.size % only check the math when the blob is finished
			blob.UserData.opT.Color = [0 0 0];
		else
			% b.UserData.op -- 1,2,3,4,5 - single,add,sub,mult,div
			switch blob.UserData.op
				case 1 % single box blob
					color = (blob.UserData.ans ~= userGrid(r,c));
				case 2 % addition
					a = 0;
					for i=1:blob.UserData.size
						a = a + userGrid(blob.UserData.rc(i,1),blob.UserData.rc(i,2));
					end
					color = (blob.UserData.ans ~= a);
				case 3 % subtraction
					color = (blob.UserData.ans ~= abs(userGrid(blob.UserData.rc(1,1),blob.UserData.rc(1,2))-userGrid(blob.UserData.rc(2,1),blob.UserData.rc(2,2))));
				case 4 % multiplication
					a = 1;
					for i=1:blob.UserData.size
						a = a * userGrid(blob.UserData.rc(i,1),blob.UserData.rc(i,2));
					end
					color = (blob.UserData.ans ~= a);
				case 5 % division
					a = userGrid(blob.UserData.rc(1,1),blob.UserData.rc(1,2))/userGrid(blob.UserData.rc(2,1),blob.UserData.rc(2,2));
					if abs(a) < 1
						a = 1/a;
					end
					if isinf(a)
						a = 0; % changes 1/0 to 0/1. I think it looks better than '/ Inf' as it really should be undefined
					end
					color = (blob.UserData.ans ~= a);
			end
			blob.UserData.opT.Color(1) = color; % changes operation color between black and red
		end
	end
	
	% Checks if 'big' numbers should be black or red if they cause a latin
	% square mistake
	function [] = blackNum(r,c)
		num = userGrid(r,c);
		i = find(userGrid(r,:)==num);
		j = find(userGrid(:,c)==num)';
		textGrid(r,c).Color(1) = ~(length(i)==1 && length(j)==1);
	end
	
	
	% Restarts the puzzle. Clears all notes and 'big' numbers
	function [] = restart(~,~)
		userGrid = nan(n);
		for r = 1:n
			for c = 1:n
				textGrid(r,c).String = ' ';
				notesGrid(r,c).String = notesGrid(1,1).UserData.none;
			end
		end
		for i = 1:length(blobs)
			blobs(i).UserData.opT.Color(1) = 0;
		end
		checkmark.Visible = 'off';
	end
	
	% 'New' button callback. Calls functions to generate the puzzle and
	% construct the board
	function [] = newGame(~,~)
		cla
		
		numPanel.Visible = 'off';
		numPanel.UserData = [1 1];
		
		n = gridSize.UserData;
		theNums = numPicker.UserData;
		finished = false;
		noteMode = false;
		
		axis(1+[0 n 0 n])
		userGrid = nan(n);
		patchGrid(n);
		numGrid = gridGen(n);
		blobGen();
		drawnow;
		opChooser();
		opShower();
		drawnow;
		blankNums();
		buildEnterTool();
		checkmark = patch(1.5+(n-1)*[0 9 37 87 100 42]/100,1.5+(n-1)*[72 59 78 3 12 100]/100,[0 1 0],'FaceAlpha',0.5,'EdgeColor','none','Visible','off');
% 		showNums(); % For debugging purposes only
	end
	
	% Generates the Enter Tool. Sets its size and creates all the numbered
	% buttons
	function [] = buildEnterTool()
		% get current aspect ratio of numPanel
		% determine how many rows needed (max 3 buts per column) (remember x)
		% change aspect ratio of panel to match
		% position needed buttons
		% hide/show as needed
		
		cols = toolColumnsSlider.Value;
		
		nR = ceil((n+2)/cols);
		numPanel.Position(4) = numPanel.Position(3)/cols*nR;
		bottom = 1-1/nR;
		for i = 1:n
			[indI, indF] = regexp(notesGrid(1,1).UserData.all,[' ' num2str(theNums(i))]); % without the space in the expression, it finds the '2' in '-2'
			j = 1;
			while isempty(indI{j}) && j < length(indI) %in theory the j< check is unnecessary
				j = j + 1;
			end
			
			if i > length(but) - 2
				but(i+2) = uicontrol(...
				'Parent',numPanel,...
				'Style','pushbutton',...
				'Units','normalized',...
				'Position',[mod(i-1,cols)/cols 0.5, 1/cols 0.5],...
				'FontSize',15);
			end
			but(i+2).String = num2str(theNums(i));
			but(i+2).Callback = {@numFill, num2str(theNums(i)), theNums(i), j, (indI{j}+1):indF{j}};
			but(i+2).UserData.cellRow = j;
			but(i+2).UserData.strInds = (indI{j}+1):indF{j};
			but(i+2).Position(2) = bottom;
			but(i+2).Position(4) = 1/nR;
			if mod(i,cols)==0
				bottom = bottom - 1/nR;
			end
			but(i+2).Visible = 'on';
		end
		for i = (n+3):length(but) % hide any extra buttons
			but(i).Visible = 'off';
		end
		but(1).Position(4) = 1/nR; % Position the 'all' and 'X' buttons
		but(2).Position(4) = 1/nR;
	end
	
	
	% Changes the number of columns in the enter tool. Triggered by using
	% the scrollbar in the UI options panel
	function [] = toolColumns(~,~)
		cols = round(toolColumnsSlider.Value);
		toolColumnsSlider.Value = cols;
		
		nR = ceil((n+2)/cols); %number of rows needed
		
		numPanel.Position(3) = numPanel.Position(3)*cols/toolColumnsSlider.UserData; %preserve button size
		numPanel.Position(4) = numPanel.Position(3)/cols*nR;
		
		a = 1-1/nR;
		for i = 1:n
			but(i+2).Position = [mod(i-1,cols)/cols, a, 1/cols, 1/nR];
			if mod(i,cols)==0
				a = a - 1/nR;
			end
		end
		but(1).Position = [1-1/cols, 0, 1/cols, 1/nR]; % Position the 'all' and 'X' buttons
		but(2).Position = [1-2/cols, 0, 1/cols, 1/nR];
		toolColumnsSlider.UserData = cols;
	end
	
	
	% Displays the prime factorization of the entered number
	function [] = primeFac(in,~, out)
		num = min(round(str2num(in.String)),flintmax);
		if ~isempty(num)
			in.String = num2str(num);
			
			fac = factor(num);
			out.String = sprintf('%d ',fac);
		end
	end
	
	
	% Adds notes to all blank squares. Will not add notes to squares that
	% already contain notes. Only adds notes that will not violate latin
	% square rules.
	function [] = allNotesFcn(~,~)
		for i = 1:n
			for j = 1:n
				if isnan(userGrid(i,j)) && isempty(regexp([notesGrid(i,j).String{:}],'\d','once')) %~any(arrayfun(fcn,notesGrid(i,j)))
					notesGrid(i,j).String = notesGrid(1,1).UserData.all;
					updateNotes(0,0,i,j);
				end
			end
		end
	end
	
	
	% Fills in the numbers for every single box blob. Just a time saver.
	% Not a big deal on small grids, but can save minutes on a 20x20
	function [] = fillSingles(~,~)
		for i = 1:length(blobs)
			if blobs(i).UserData.size == 1
				r = blobs(i).UserData.rc(1);
				c = blobs(i).UserData.rc(2);
				userGrid(r,c) = blobs(i).UserData.ans;
				notesGrid(r,c).String = notesGrid(1,1).UserData.none;
				
				textGrid(r,c).FontSize = gValues.noteHeight/n;
				textGrid(r,c).String = num2str(blobs(i).UserData.ans);
				if textGrid(r,c).Extent(3) > 1
					textGrid(r,c).FontSize = textGrid(r,c).FontSize/textGrid(r,c).Extent(3);
				end
				blobs(i).UserData.opT.Color = [0 0 0];
			end
		end
		for i = 1:n
			for j = 1:n
				blackNum(i,j);
			end
		end
		finished = winCheck();
	end
	
	
	% Callback when any of the operators are enabled or disabled. Ensures
	% that at least one operator is enabled and that special requirements
	% are met if the only operators are subtraction or division.
	function [] = opSelection(src, ~, op)
		allowedOps(op) = src.Value;
		if ~any(allowedOps) % all turned off
			allowedOps(1) = true;
			src.Parent.Children('+'==[src.Parent.Children.String]).Value = true;
		elseif allowedOps(4) && all(~allowedOps(1:3)) % division only
			% only allow if the array is all powers of x and blob size is limited to 2
			x = numPicker.UserData;
			x = x(2:end)./x(1:end-1);
			if all(x(1) == x)
				blobSize.String = '2';
				blobClip();
			else
				allowedOps(1) = true;
				addCheck.Value = true;
			end
		elseif allowedOps(2) && all(~allowedOps([1 3 4])) % subtraction only
			% blob size is limited to 2
			if ~strcmp(blobSize.String,'2')
				allowedOps(1) = true;
				addCheck.Value = true;
			end
		end
	end
	
	
	% Callback when a new number is entered into the table. Numbers must be
	% whole numbers greater than 0. Does not allow repeats. Sorts the table
	function [] = numSelection(src, ~, ind)
		arrayOptions.SelectedObject = arrayCustom;
		num = round(str2num(src.String));
		if isempty(num) || isnan(num) || isinf(num) %|| num <=0
			num = nextNewNum();
		end
		src.String = num2str(num);
		numPicker.UserData(ind) = num;
		
		if length(unique(numPicker.UserData)) ~= gridSize.UserData % no repeats
			num = nextNewNum();
			src.String = num2str(num);
			numPicker.UserData(ind) = num;
		end
		
		sortedNums = sort(numPicker.UserData);
		if ~all(numPicker.UserData == sortedNums)
			for i = 1:length(sortedNums)
				numBoxes(i).String = num2str(sortedNums(i));
				numBoxes(i).FontSize = min(12,numBoxes(i).FontSize*numBoxes(i).Position(3)/numBoxes(i).Extent(3));
			end
			numPicker.UserData = sortedNums;
		end
		
		
		if allowedOps(4) && all(~allowedOps(1:3))
			% only allow if the array is all powers of x and blob size is
			% limited to 2
			x = numPicker.UserData;
			x = x(2:end)./x(1:end-1);
			if ~all(x(1) == x)
				allowedOps(1) = true;
				addCheck.Value = true;
			end
		end
		
		% Font Size Check
		src.FontSize = min(12,src.FontSize*src.Position(3)/src.Extent(3));
		
		function [i] = nextNewNum()
			i = 1;
			newNum = find(i == numPicker.UserData,1);
			while ~isempty(newNum)
				i = i + 1;
				newNum = find(i == numPicker.UserData,1);
			end
		end
	end	
	
	% Callback when selecting a preset array.
	function [] = arraySelection(~, ~, option)
		ng = gridSize.UserData;
		switch option
			case 1 % 1:n
				updateArray(1:ng);
			case 2 % primes
				x = ng;
				a = primes(x);
				while length(a) ~= (ng - 1)
					x = x + 2;
					a = primes(x);
				end
				updateArray([1 a]);
			case 3 % 2^x
				% maybe turn 2^x into x^y somehow
				updateArray(2.^(0:ng-1));
		end
		if (option == 1 || option == 2) && allowedOps(4) && all(~allowedOps(1:3))
			% when switching from powers of two, make sure division isn't
			% the only operator
			allowedOps(1) = true;
			addCheck.Value = true;
		end
		
		% Puts the new array into the table
		function [] = updateArray(newArray)
			numPicker.UserData = newArray;
			for i = 1:gridSize.UserData
				numBoxes(i).String = num2str(newArray(i));
				numBoxes(i).FontSize = min(12,numBoxes(i).FontSize*numBoxes(i).Position(3)/numBoxes(i).Extent(3));
				numBoxes(i).Visible = 'on';
			end
		end
	end
	
	
	% Ensures that only integers greater than 1 are ented into the 'Max
	% Size' text box. A blank entry will be replaced by 4.
	function [] = blobClip(~,~)
		b = round(str2num(blobSize.String));
		if isempty(b)
			b = 4;
		elseif b<2
			b = 2;
		end
		if b~=2 && allowedOps(2) && all(~allowedOps([1 3 4]))
			allowedOps(1) = true;
			addCheck.Value = true;
		end
		s = num2str(b);
		blobSize.String = s;
		blobSize.UserData = b;
	end
	
	
	% Ensures that only acceptable values are entered into the 'Grid Size'
	% text box. Min of 2. Defaults to 5 for blank entries.
	function [] = gridClip(~,~)
		a = gridSize.UserData;
		b = round(str2num(gridSize.String));
		if isempty(b)
			b = 5;
		elseif b<2
			b = 2;
		end
		s = num2str(b);
		gridSize.String = s;
		gridSize.UserData = b;
		
		% update table
		if b < a %smaller grid
			numPicker.UserData = numPicker.UserData(1:b);
			for i = b+1:a
				numBoxes(i).Visible = 'off';
			end
			if b <= tableSlider.UserData
				tableSlider.Visible = 'off';
			end
		elseif b > a
			set = arrayOptions.SelectedObject;
			for i = length(numBoxes)+1:b
				newNumBox(i);
			end
			if b > tableSlider.UserData
				tableSlider.Visible = 'on';
			end
			if set == arrayCustom
				for i = a:b
					numSelection(numBoxes(i), 5, i); % the 5 is filler
					if numBoxes(i).Position(2) < 0
						numBoxes(i).Visible = 'off';
					else
						numBoxes(i).Visible = 'on';
					end
				end
			else
				arrayOptions.SelectedObject = set;
				arraySelection(2, 4, arrayOptions.SelectedObject.Callback{2}); %2 and 4 are src/evt filler
			end
		end
		if gridSize.UserData > tableSlider.UserData
			tableSlider.SliderStep = [1/3 1]./(gridSize.UserData - tableSlider.UserData);
		end
		tableScroll();
	end
	
	
	% Debug function that will display the solution
	% warning message suppressed as this function is rarely actually called
	function [] = showNums() %#ok<DEFNU>
		for r = 1:n
			for c = 1:n
				text(c+0.5,r+0.5,num2str(theNums(numGrid(r,c))),'FontSize',10,'HorizontalAlignment','center');
			end
		end
	end
	
	
	% Generates the text objects for the notes and 'big' numbers
	function [] = blankNums()
		textGrid = gobjects(n);%matlab.graphics.primitive.Text.empty;
		notesGrid = gobjects(n);%matlab.graphics.primitive.Text.empty;
		
		% Code for determining the font size required for the notes to fit
		% in one box
		fs = 1/(3*n);
		temp = text(1, 1, '1','FontName','fixedwidth','FontUnits','normalized','FontSize',fs); % initial test object
		a = num2str(theNums);
		a(a==' ') = [];	
		x = roots([(length(a) + n - 1)/temp.Extent(4), -gValues.noteHeight, -gValues.noteHeight]);
		fs = fs * x(1) / temp.Extent(3); % guess at good font size
		shortEnough = false;
		while ~shortEnough % repeat the test until the text object fits in the alloted space
			temp.FontSize = fs;
			m = 1 - 0.5*temp.Extent(3);
			y = 1;
			notesGrid(1,1) = text(1+m, 1+y, {''},'FontName','fixedwidth','FontUnits','normalized','FontSize',fs,'Visible','off','HorizontalAlignment','right','VerticalAlignment','bottom');
			noteString = {notesGrid(1,1).String};
			for k = n:-1:1
				notesGrid(1,1).String{1} = [' ', num2str(theNums(k)), notesGrid(1,1).String{1}];
				if notesGrid(1,1).Position(1) + notesGrid(1,1).Extent(3) > 3
					noteString(2:length(noteString)+1,1) = noteString;
					noteString(1) = {[' ', num2str(theNums(k))]};
					notesGrid(1,1).String = noteString;
				end
				noteString = notesGrid(1,1).String;
			end
			shortEnough = (notesGrid(1,1).Extent(4) < gValues.noteHeight + 0.1);
			if ~shortEnough
				fs = fs * 0.9;
			end
		end
		none = regexprep(noteString,'-|\d',' '); % get a blank copy of the string with only spaces
		
		for r = 1:n
			for c = 1:n
				textGrid(r,c) = text(c+0.5,r+0.575,' ','FontUnits','normalized','FontSize',gValues.noteHeight/n,'HorizontalAlignment','center','VerticalAlignment','middle');
				notesGrid(r,c) = text(c+m, r+y, none,'FontName','fixedwidth','FontUnits','normalized','FontSize',fs,'HorizontalAlignment','right','VerticalAlignment','bottom','Color',0.2*[1 1 1]);
			end
		end
		notesGrid(1,1).UserData.all = noteString;
		notesGrid(1,1).UserData.none = none;
		delete(temp);
	end
	
	
	% Displays the operator and target value for each blob
	function [] = opShower()
		ops = ' +-*/';
		fs = 0.1;
		for i = 1:length(blobs)
			r = min(blobs(i).UserData.rc(:,1));
			c = min(blobs(i).UserData.rc(blobs(i).UserData.rc(:,1)==r,2));
			blobs(i).UserData.opT = text(0.5+c,gValues.opHeight+r,sprintf('%s %d',ops(blobs(i).UserData.op), blobs(i).UserData.ans),'FontUnits','normalized','FontSize',fs,'FontName','fixedwidth','FontWeight','bold','HorizontalAlignment','center');
			if blobs(i).UserData.op == 1
				blobs(i).UserData.opT.String = blobs(i).UserData.opT.String(3:end); %remove extra spaces on single box blobs
			end
			if blobs(i).UserData.opT.Extent(3) > (1-gValues.opHeight) || blobs(i).UserData.opT.Extent(4) > (1-gValues.noteHeight)
				blobs(i).UserData.opT.FontSize = min((1-gValues.opHeight)*fs/blobs(i).UserData.opT.Extent(3),(1-gValues.noteHeight)*fs/blobs(i).UserData.opT.Extent(4));
			end
% 			drawnow;
		end
	end
	
	
	% Selects the operation for each blob. Subtraction and division are
	% limited to size two blobs. Operators are chosen randomly otherwise.
	% Also determines the answer of each blob.
	function [] = opChooser()
		for i = 1:length(blobs)
			% 5 bools, [n + - * /] (n refers to a single square)
			s = blobs(i).UserData.size;
			num = theNums(numGrid(sub2ind([n n], blobs(i).UserData.rc(:,1), blobs(i).UserData.rc(:,2))));
			if s==1
				blobs(i).UserData.op = 1; % single num
			elseif s==2
				% check div, then choose randomly
				if allowedOps(4) && (mod(num(1),num(2))==0 || mod(num(2),num(1))==0)
					x = nonzeros((1:5).*[0 allowedOps]);
					blobs(i).UserData.op = x(randi(length(x)));
				else
					x = nonzeros((1:5).*[0 allowedOps(1:3) 0]);
					blobs(i).UserData.op = x(randi(length(x)));
				end
			else
				blobs(i).UserData.op = (randi(2)*2)*(allowedOps(1) && allowedOps(3)) + xor(allowedOps(1),allowedOps(3)).*(2*allowedOps(1) + 4*allowedOps(3)); % overly complicated, but chooses between addition and multiplication
			end
			switch blobs(i).UserData.op
				case 1 % single num
					target = num;
				case 2 % add
					target = sum(num);
				case 3 % sub
					target = abs(diff(num));
				case 4 % mult
					target = prod(num);
				case 5 % div
					target = max(num(1)/num(2),num(2)/num(1));
					if abs(target)<1
						target = 1/target;
					end
					if isinf(target)
						target = 0; % changes 1/0 to 0/1. I think it looks better than '/ Inf' as it really should be undefined
					end
			end
			blobs(i).UserData.ans = target;
		end
	end
	
	
	% Adds the thin grid lines and the box used for highlighting the
	% currently selected square
	function [] = patchGrid(n)
		gridlines = gobjects(2*n-2,1);
		for i = 2:n
			gridlines(i-1) = line([i i], [1 n+1],'Color',0.5*ones(1,3),'Visible','on');
			gridlines(i+n-2) = line([1 n+1], [i i],'Color',0.5*ones(1,3),'Visible','on');
			
		end
		selectorBox = patch([0 1 1 0],[0 0 1 1],[1 1 1],'EdgeColor',0.5*ones(1,3),'Visible','off');
		selectorBox.UserData.x = [0 1 1 0];
		selectorBox.UserData.y = [0 0 1 1];
	end
	
	
	% Handles the scrolling of the custom array table
	function [] = tableScroll(~, ~)
		if gridSize.UserData <= tableSlider.UserData
			tableSlider.Value = 1;
		end
		m = min(gridSize.UserData, length(numBoxes));
		for i = 1:m
			numBoxes(i).Position(2) = 1 + numBoxes(1).Position(4)*((1 - tableSlider.Value)*(m-tableSlider.UserData) - i);
			if numBoxes(i).Position(2) > 1 || numBoxes(i).Position(2) < -numBoxes(1).Position(4)
				numBoxes(i).Visible = 'off';
			else
				numBoxes(i).Visible = 'on';
			end
		end
	end
	
	
	% Creates new uicontrol() objects for the array table. The builtin
	% uitable() object handles resizing very poorly.
	function [] = newNumBox(i)
		numBoxes(i) = uicontrol(...
			'Parent',numPicker,...
			'Units','normalized',...
			'Style','edit',...
			'String',num2str(i),...
			'UserData',i,...
			'Position',[0 1-0.125*i 0.75 0.125],...
			'FontSize',12,...
			'Callback',{@numSelection, i});
		numSelection(numBoxes(i),5,i);
		if numBoxes(i).Position(2) < 0
			numBoxes(i).Visible = 'off';
		end
		if ~isempty(tableSlider) && i > tableSlider.UserData
			tableSlider.Visible = 'on';
		end
	end
	
	


	
	%================== board generation functions========================
	
	% Sets up the inital values for the recursive latin square generation.
	% The first column is selected randomly here, as any permutation of the
	% first column can lead to a valid latin square, so the recursion is
	% not needed
	function [g] = gridGen(n)
		g = zeros(n);
		g(:,1) = randperm(n);
		g = recGen(g,1,2);
	end
	
	% Generates the latin square used in the puzzle. Uses recursion to
	% randomly place numbers. Backtracks when it encounters a location with
	% no possible numbers.
	function [grid, good] = recGen(grid, r, c)
		if nnz(grid) == n^2
			good = true;
			return
		end
		if r > n
			r = 1;
			c = c + 1;
		end
		good = false;
		w = nonzeros(unique([grid(:,c),grid(r,:)'])); %all blocked options
		e = 1:n;
		for i = 1:length(w)
			e(e == w(i)) = []; % remove blocked options
		end
		
		e = e(randperm(length(e))); %randomize order
		for i = 1:length(e)
			grid(r,c) = e(i);
			[grid, good] = recGen(grid, r + 1, c);
			if good
				return
			end
			grid(sub2ind(size(grid),r,c):end) = 0; % make sure all failed attempts are erased
		end
	end
	
	% Generates the blobs used to divide the puzzle
	function [] = blobGen()
		grid = reshape(1:n^2, [n, n]);
		indGrid = zeros(n);
		blobs = matlab.graphics.primitive.Patch.empty;
		cur = 1;
		z = [0 1; 0 -1; 1 0; -1 0];
		while nnz(grid)~=0 % each loop generates one blob. ends when all squares are blobbed
			inds = nonzeros(grid);
			[r, c] = ind2sub(size(grid),inds(randi(length(inds)))); % Select a random unblobbed square
			rc = [r,c];
			grid(r,c) = 0;

			for i = 2:blobSize.UserData
				rcNew = rc(randi(size(rc,1)),:) + z(randi(size(z,1)),:); % Select a random adjacent square
				if rcNew(2)<=n && rcNew(1)<=n && rcNew(2)>0 && rcNew(1)>0 && grid(rcNew(1),rcNew(2))~=0
					% if it's within the grid and unblobbed, add it to the blob
					rc(size(rc,1)+1,:) = rcNew;
					grid(rcNew(1),rcNew(2)) = 0;
				end
			end
			
			% I suspect much of this code could be simplified or removed by
			% using polyshape() for the graphics objects, but it would
			% require at least R2017b and break 32-bit support which is
			% limited to R2015b
			if size(rc,1)>1
				% Get the vertices of all squares in the blob
				v = zeros(size(rc,1)*4,2);
				for i = 1:size(rc,1)
					box = rc(i,:);
					indGrid(box(1),box(2)) = cur;
					v(((i-1)*4+1):(i*4),1:2) = [box; box+[0 1]; box+[1 1]; box+[1 0]];
				end

				% Pick bottom left point
				d = sum(v.^2,2); % array of squared distances
				[~, j] = min(d);
				j = blob_fcn(v, j, rc); % Get only the outer vertices
				verts = zeros(length(j),2);
				for i = 1:length(j)
					verts(i,:) = v(j(i),:);
				end
			else
				verts = [rc; rc+[0 1]; rc+[1 1]; rc+[1 0]];
				indGrid(rc(1),rc(2)) = cur;
			end
			
			blobs(cur) = patcher(rc,verts); % draw the blob and add it to the array
			cur = cur+1;
		end

		% Finds the outer vertices from an array of vertices within a given
		% blob and arranges them in the counterclockwise order
		function [ vInds ] = blob_fcn( rc, vInds, blob )
			%{
			look for the adjacent points
			-pick the one that fits in the rotation
			--rotation is 3 long to j(end-1)ent backtracking
			---this rotation is dependent on the angle of the vector formed by the last 2 points.
			------ 0 - d,r,u
			------90 - r,u,l
			-----180 - u,l,d
			-----270 - l,d,r
			-----the rotation is d,r,u,l shifted w/ one eliminated
			Needs to check that this rotation does not block off concave
			sections of the polygon
			%}
			if length(vInds)==1 % first fcn call
				theta = 0;
			elseif vInds(1)==vInds(end)
				return
			else
				theta = atan2d(rc(vInds(end-1),1)-rc(vInds(end),1),rc(vInds(end),2)-rc(vInds(end-1),2)); % y is reversed to match reversed axis
			end
			b = [cosd(theta+[0 90 180]'),sind(theta+[0 90 180]')];

			for k = 1:3
				nxtPt = b(k,:) + rc(vInds(end),:);
				for q = 1:size(rc,1)
					if all(rc(q,:)==nxtPt)
						good = false;
						if b(k,1)~=0 % vert line
							asd = min([nxtPt(1),rc(vInds(end),1)]);
							b1 = [asd,nxtPt(2)];
							b2 = [asd,nxtPt(2)-1];
						else %horiz line
							asd = min([nxtPt(2),rc(vInds(end),2)]);
							b1 = [nxtPt(1),asd];
							b2 = [nxtPt(1)-1,asd];
						end

						for w = 1:size(blob,1)
							if all(blob(w,:)== b1) || all(blob(w,:)==b2)
								good = true;
								break
							end
						end
						if good
							vInds = blob_fcn(rc,[vInds,q],blob);
							return
						end
					end
				end
			end
		end

		% Creates the graphics objects for each blob
		function [p] = patcher(rc,verts)
			p = patch(verts(:,2),verts(:,1),[1 1 1]);
			p.LineWidth = 3;
			p.FaceAlpha = 0;
			p.UserData.rc = rc;
			p.UserData.size = size(rc,1);
			drawnow;
		end
	end

	% Creates the figure and generates the majority of the UI elements
	function [] = figureSetup()
		f = figure(1);
		clf
		f.MenuBar = 'none';
		f.Name = 'KenKen';
		f.NumberTitle = 'off';
		f.WindowButtonDownFcn = @click;
		f.SizeChangedFcn = @resize;
		f.UserData = 'normal';
		f.Resize = 'on';
		f.Units = 'pixels';
		
		
		
		ax = axes('Parent',f);
		ax.Position = [0.175 0 0.6 1];
		ax.YDir = 'reverse';
		ax.YTick = [];
		ax.XTick = [];
		ax.XColor = [1 1 1];
		ax.YColor = [1 1 1];
		axis equal
		
		gValues.noteHeight = 0.7;
		gValues.noteOnColor = [0.94 0.94 1];
		gValues.noteOffColor = [0.94 0.94 0.94];
		gValues.opHeight = 0.15;
		gValues.startN = 5;
		
		
		ng = uicontrol(...
			'Parent',f,...
			'Units','normalized',...
			'Style','pushbutton',...
			'String','New',...
			'Callback',@newGame,...
			'Position',[0.05 0.25 0.1 0.1],...
			'TooltipString','New Puzzle',...
			'FontUnits','normalized',...
			'FontSize',0.25);
		
		clearer = uicontrol(...
			'Parent',f,...
			'Units','normalized',...
			'Style','pushbutton',...
			'String','Restart',...
			'Callback',@restart,...
			'Position',[0.05 0.05 0.1 0.1],...
			'TooltipString','Restart Puzzle',...
			'FontUnits','normalized',...
			'FontSize',0.25);			
		
		
		
		
		
		% ============= Menu Panels ==========================
		menuPanel = uitabgroup(...
			'Parent',f,...
			'Units','normalized',...
			'Position',[sum([0.01, ax.Position([1,3])]) 0 (0.99-sum(ax.Position([1,3]))) 1]);
		toolsPanel = uitab(...
			'Parent',menuPanel,...
			'Title','Tools');
		genOptions = uitab(...
			'Parent',menuPanel,...
			'Title','Generation');
		uiOptions = uitab(...
			'Parent',menuPanel,...
			'Title',' UI ');
		
		% =================== Tools Panel ==================
		factorDisp = uicontrol(...
			'Parent',toolsPanel,...
			'Units','normalized',...
			'Style','text',...
			'String','2 2 3',...
			'Position',[0.025 0.6725 0.95 0.15],...
			'FontSize',15);
		factorInput = uicontrol(...
			'Parent',toolsPanel,...
			'Units','normalized',...
			'Style','edit',...
			'String',num2str(prod(str2num(factorDisp.String))),...
			'Position',[0.025 0.85 0.95 0.075],...
			'Callback',{@primeFac, factorDisp},...
			'TooltipString','Displays prime factors',...
			'FontSize',15);		
		
% 		numHighlightPicker = uicontrol(...
% 			'Parent',toolsPanel,...
% 			'Units','normalized',...
% 			'Style','popupmenu',...
% 			'String',num2cell(num2str((1:gValues.startN)')),...
% 			'Position',[0.525 0.5 0.4 0.05]);
% 		numHighlight = uicontrol(...
% 			'Parent',toolsPanel,...
% 			'Units','normalized',...
% 			'Style','checkbox',...
% 			'String','Highlight All:',...
% 			'Position',[0.025 0.5 0.5 0.08],...
% 			'Value',false);
% 		numHighlightPicker.Callback = {@highlightAll, numHighlight, numHighlightPicker};
% 		numHighlight.Callback = {@highlightAll, numHighlight, numHighlightPicker};
		
		
		singleFiller = uicontrol(...
			'Parent',toolsPanel,...
			'Units','normalized',...
			'Style','pushbutton',...
			'String','Fill Singles',...
			'Callback',@fillSingles,...
			'Position',[0.1 0.4 0.8 0.1],...
			'TooltipString','Fills all single number boxes',...
			'FontUnits','normalized',...
			'FontSize',0.25);
		
		noteClearer = uicontrol(...
			'Parent',toolsPanel,...
			'Units','normalized',...
			'Style','pushbutton',...
			'String','Update Notes',...
			'Callback',@updateNotes,...
			'Position',[0.1 0.25 0.8 0.1],...
			'TooltipString','Removes blocked notes',...
			'FontUnits','normalized',...
			'FontSize',0.25);
		
		allNotes = uicontrol(...
			'Parent',toolsPanel,...
			'Units','normalized',...
			'Style','pushbutton',...
			'String','Add All Notes',...
			'Callback',@allNotesFcn,...
			'Position',[0.1 0.1 0.8 0.1],...
			'TooltipString','Adds notes to all blank squares',...
			'FontUnits','normalized',...
			'FontSize',0.25);
		
		
		
		
		
		% ============ Generation Options ==================
		blobSize = uicontrol(...
			'Parent',genOptions,...
			'Units','normalized',...
			'Style','edit',...
			'String','4',...
			'Callback',@blobClip,...
			'UserData',4,...
			'Position',[0.75 0.91 0.25 0.05],...
			'FontSize',12,...
			'TooltipString','Max size of each blob');
		blobLbl = uicontrol(...
			'Parent',genOptions,...
			'Units','normalized',...
			'Style','text',...
			'String','Max Blob Size',...
			'HorizontalAlignment','right',...
			'Position',[0.01 blobSize.Position(2)-0.029 blobSize.Position(1)-0.02 0.075],...
			'FontSize',9,...
			'FontUnits','normalized');
		
		gridSize = uicontrol(...
			'Parent',genOptions,...
			'Units','normalized',...
			'Style','edit',...
			'String',num2str(gValues.startN),...
			'Callback',@gridClip,...
			'UserData',gValues.startN,...
			'Position',[0.75 0.81 0.25 0.05],...
			'FontSize',12,...
			'TooltipString','Board size');
		gridLbl = uicontrol(...
			'Parent',genOptions,...
			'Units','normalized',...
			'Style','text',...
			'String','Grid Size',...
			'HorizontalAlignment','right',...
			'Position',[0.01 gridSize.Position(2)-0.029 gridSize.Position(1)-0.02 0.075],...
			'FontSize',9,...
			'FontUnits','normalized');
		
		allowedOps = true(1,4);
		opPickerPanel = uipanel(...
			'Parent',genOptions,...
			'Units','normalized',...
			'Position',[0.1 0.55, 0.8 0.25],...
			'Title','Operators',...
			'TitlePosition','centertop');
		addCheck = uicontrol(...
			'Parent',opPickerPanel,...
			'Units','normalized',...
			'Style','checkbox',...
			'String','+',...
			'Position',[0.375 0.75 0.35 0.25],...
			'Value',true,...
			'Callback',{@opSelection, 1});
		subCheck = uicontrol(...
			'Parent',opPickerPanel,...
			'Units','normalized',...
			'Style','checkbox',...
			'String','-',...
			'Position',[0.375 0.5 0.35 0.25],...
			'Value',true,...
			'Callback',{@opSelection, 2});
		multCheck = uicontrol(...
			'Parent',opPickerPanel,...
			'Units','normalized',...
			'Style','checkbox',...
			'String','*',...
			'Position',[0.375 0.25 0.35 0.25],...
			'Value',true,...
			'Callback',{@opSelection, 3});
		divCheck = uicontrol(...
			'Parent',opPickerPanel,...
			'Units','normalized',...
			'Style','checkbox',...
			'String','/',...
			'Position',[0.375 0 0.35 0.25],...
			'Value',true,...
			'Callback',{@opSelection, 4},...
			'ToolTipString','Usually cannont be only operator');

		
		numPicker = uipanel(...
			'Parent',genOptions,...
			'Units','normalized',...
			'Position',[0.02 0.02, 0.43 0.5],...
			'UserData',1:gValues.startN);
		numBoxes = gobjects(gValues.startN,1);
		for i = 1:gValues.startN
			newNumBox(i);
		end
		tableSlider = uicontrol(...
			'Parent',numPicker,...
			'Units','normalized',...
			'Style','slider',...
			'Position',[0.02+sum(numBoxes(1).Position([1 3])) 0 0.98-numBoxes(1).Position(3) 1],...
			'Min',0,...
			'Max',1,...
			'Value',1,...
			'SliderStep',[0.5 2/3].*numBoxes(1).Position(4),...
			'FontSize',12,...
			'UserData',1/numBoxes(1).Position(4),...
			'Callback',{@tableScroll});
		if tableSlider.UserData > gValues.startN
			tableSlider.Visible = 'off';
		end
		
		arrayOptions = uibuttongroup(...
			'Parent',genOptions,...
			'Units','normalized',...
			'Position',[0.45 0.02 0.55 0.5]);		
		arrayOrdered = uicontrol(...
			'Parent',arrayOptions,...
			'Units','normalized',...
			'Style','radiobutton',...
			'String','1:n',...
			'Position',[0 0.8 1 0.2],...
			'Value',true,...
			'Callback',{@arraySelection, 1});
		arrayPrimes = uicontrol(...
			'Parent',arrayOptions,...
			'Units','normalized',...
			'Style','radiobutton',...
			'String','Primes',...
			'Position',[0 0.6 1 0.2],...
			'Value',false,...
			'Callback',{@arraySelection, 2});
		arrayTwos = uicontrol(...
			'Parent',arrayOptions,...
			'Units','normalized',...
			'Style','radiobutton',...
			'String','2^x',...
			'Position',[0 0.4 1 0.2],...
			'Value',false,...
			'Callback',{@arraySelection, 3});
		arrayCustom = uicontrol(...
			'Parent',arrayOptions,...
			'Units','normalized',...
			'Style','radiobutton',...
			'String','Custom',...
			'Position',[0 0.2 1 0.2],...
			'Value',false,...
			'Callback',{@arraySelection, 4});
		
		
		
		% ============ UI Options ==================
% 		menuPanel.SelectedTab = uiOptions;
		
		enterToolOptions = uipanel(...
			'Parent',uiOptions,...
			'Units','normalized',...
			'Position',[0.02 0.78, 0.96 0.2]);
		
		smaller = uicontrol(...
			'Parent',enterToolOptions,...
			'Units','normalized',...
			'Style','pushbutton',...
			'String','-',...
			'Callback',{@toolScale,-1},...
			'Position',[0.05 0.55 0.25 0.4],...
			'FontSize',15,...
			'TooltipString','Decreases tool size');
		toolSizeLbl = uicontrol(...
			'Parent',enterToolOptions,...
			'Units','normalized',...
			'Style','text',...
			'String','Size',...
			'HorizontalAlignment','center',...
			'Position',[0.3 0.5 0.4 0.4],...
			'FontSize',10,...
			'FontUnits','normalized');
		bigger = uicontrol(...
			'Parent',enterToolOptions,...
			'Units','normalized',...
			'Style','pushbutton',...
			'String','+',...
			'Callback',{@toolScale,1},...
			'Position',[sum(toolSizeLbl.Position([1 3])) smaller.Position(2:4)],...
			'FontSize',15,...
			'TooltipString','Increases tool size');
		
		toolColumnsLbl = uicontrol(...
			'Parent',enterToolOptions,...
			'Units','normalized',...
			'Style','text',...
			'String','# of Columns',...
			'HorizontalAlignment','center',...
			'Position',[0.05 0.325 0.9 0.2],...
			'FontSize',9,...
			'FontUnits','normalized');
		toolColumnsSlider = uicontrol(...
			'Parent',enterToolOptions,...
			'Units','normalized',...
			'Style','slider',...
			'Position',[0.05 0.05 0.9 0.2],...
			'Min',1,...
			'Max',10,...
			'Value',3,...
			'SliderStep',[1/9 1/9],...
			'FontSize',12,...
			'Callback',{@toolColumns},...
			'UserData',3);
		
		
		
		% ========== Enter Tool ======
		h = 0.175;
		numPanel = uipanel(... % will need special resizing code
			'Parent',f,...
			'Units','normalized',...
			'Position',[0.1 0.1, h*1.5*f.Position(4)/f.Position(3) h],...
			'Units','pixels'); % if pixels is removed, need to alter code for where numpanel moves to when clicking
		
		but = uicontrol(...
			'Parent',numPanel,...
			'Style','pushbutton',...
			'Units','normalized',...
			'Position',[2/3 0, 1/3 0.5],...
			'String','X',...
			'FontSize',15,...
			'Callback',{@numFill, ' ', []});	
		but(2) = uicontrol(...
			'Parent',numPanel,...
			'Style','pushbutton',...
			'Units','normalized',...
			'Position',[1/3 0, 1/3 0.5],...
			'String','all',...
			'FontSize',15,...
			'Callback',{@numFill, 'NaN', nan},...
			'Visible','off');	
		
		
	end
end



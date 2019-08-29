%{
===================================== new features
currently - left does what btn says, right does reverse
----I feel like the code is a little funky to accomplish this
--maybe change selected box highlight to reflect mode
----green for big, blue for notes?
--maybe fill note or ink based on left/right clicking the panel buttons

more options/controls for ui scaling

Export mode for printting/publish a good puzzle?
-can be done now with screenshots, so not essential

Zoom feature
-could potentially resolve a bunch of the ui issues on large grids
-alt option is to create a zoomed in version of the selected box to make
notes more visible on large grids

keyboard entry for numbers?

a way to highlight all of a given number?
--on the 20x20, bit hard to see all 17s on the board

===================================== known bugs
replacing a big number with notes does not remove red errors

entering a really big number breaks the factor tool

certain things can break the left/right click system. I think it has to do
with clicking onto other ui elements
- i think it could make sense to only enable the button if a checkbox is
checked. the button is good for touch screens, not mouse

===================================== Programming changes
investigate optimization of new game by not using 'cla'

on large grids there is lag just from creating each note as an individual
text object. (9x9 has 963 children on the axes). maybe try just making them
one string that has characters replaced with spaces rather than being
hidden
---inital testing has issues. the positions of individual text objects
shift as the window is resized allowing for it to fit for any grid size and
window size. A single string will have constant spacing and will require
more resizing code, (potentially as simple as scaling the font size)


'boxes' is probably a waste of resources
-only used for the thin grid lines and highlighting current square
--could be achieved with one moving box and a few straight lines
--#objects would go from n^2 to 2n-1
---considering there are n^3 note objects, not sure how much it matters

===================================== UI changes
with large numbers, sometimes answer goes into the next blob over

alter spacing of notes for large grids?
-maybe two rows at a certain point

font scaling when resizing?

make tool appear at right edge?
-would make box you're working on more visible

Change number of columns in enter tool in larger grids?
-fine at 9, ridiculous at 20

size of ui options is dependent on the size of the figure when it first
runs. some things look good if it's a new figure or  wonky if not

enter tool buttons have an indicator for if the note is on or not?
-currently useful with the overlapping notes. If that's fixed, it may not
---be needed
===================================== Rule changes
control for ops? (ie, no div, only mult, etc)

numbers not determined by grid size?
-eg - 5x5 with [1 2 3 5 7]
--would require recoding in recGen and in the numbertool





%}

%#ok<*ST2NM>
%#ok<*NASGU>
% remove warnings for str2num() and unused variables. I use str2num()
% instead of str2double() because it evaluates strings such as '112/7'. I
% suppressed the warning for unused variables because I assgined every UI
% element to a variable because it is descriptive and in case it is needed
% in other functions. With the number of UI elements, it creates a large
% number of warnings.

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
	noteBtn = [];
	notesGrid = [];
	blobSize = [];
	gridSize = [];
	finished = [];
	but = [];
	boxes = [];
	allowedOps = [];
	numPicker = [];
	addCheck = [];
	arrayOptions = [];
	arrayCustom = [];
	theNums = [];
	checkmark = [];
	
	figureSetup();
	newGame();
	
	% Checks each note in a given box to see if it can be eliminated
	% because of a filled in box in the same row or column
	function [] = updateNotes(~,~,ra,ca)
		if nargin < 4 %if no specified ra/rc, check all notes in all squares
			ra = 1:n;
			ca = 1:n;
		end
		for i = ra
			r = nonzeros(unique(userGrid(i,:))); % nums in row
			for j = ca
				if userGrid(i,j)==0 % only update squares not filled in
% 					[i j]
					k = nonzeros(unique([r; userGrid(:,j)]))'; % all nums
					if ~isempty(k)
						for k = k
							notesGrid(i,j,find(k==theNums,1)).Visible = 'off';
						end
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
		numPanel.Position([3,4]) = numPanel.Position([3,4])*(sign(bigger)*1.1 - sign(bigger-1)*1/1.1);
	end
	
	% Checks if the puzzle has been completed
	function [won] = winCheck()
		won = nnz(userGrid)==n^2; %eveything filled in
		if ~won
			return
		end
		
		for r = 1:n
			for c = 1:n
				won = (textGrid(r,c).Color(1)==0); % no red numbers
				if ~won
					return
				end
			end
		end
		
		for i = 1:length(blobs)
			won = (blobs(i).UserData.opT.Color(1)==0); % no red operations
			if ~won
				return
			end
		end
		
		won = true; % no mistakes, display check mark, and return true
		delete(checkmark);
		checkmark = patch(1.5+(n-1)*[0 9 37 87 100 42]/100,1.5+(n-1)*[72 59 78 3 12 100]/100,[0 1 0],'FaceAlpha',0.5,'EdgeColor','none');
	end
	
	% Handles mouse clicks within the figure window. Primarily handles the
	% positioning of the Enter Tool and enter/note switching when using
	% right clicks
	function [] = click(~,~)
		if finished
			return
		end
		boxes(numPanel.UserData(1),numPanel.UserData(2)).FaceColor = [1 1 1]; % unhighlight last box
		m = fliplr(floor(ax.CurrentPoint([1,3]))); % gives (r,c)
		if any(m<1) || any(m>n)
			numPanel.Visible = 'off';
			return
		end
		
		numPanel.Position(1) = f.CurrentPoint(1);
		numPanel.Position(2) = min([f.CurrentPoint(2), f.Position(4) - numPanel.Position(4)]);
		
		numPanel.UserData = m;
		boxes(m(1),m(2)).FaceColor = [0.9 1 0.9]; %highlight selected box
		if (strcmp(f.SelectionType,'alt') && strcmp(f.UserData,'normal')) || (strcmp(f.SelectionType,'normal') && strcmp(f.UserData,'alt'))
			if noteBtn.Value
				noteBtn.Value = false;
				but(2).Visible = 'off';
			else
				noteBtn.Value = true;
				but(2).Visible = 'on';
			end
		end
		f.UserData = f.SelectionType;
		numPanel.Visible = 'on';
	end
	
	% Enters new numbers or notes into grid squares
	function [] = numFill(~,~,newNum, num, numInd)
		r = numPanel.UserData(1); % get grid location from numPanel
		c = numPanel.UserData(2);
% 		num = str2num(newNum);
		
		% Entering/removing notes
		if noteBtn.Value
			userGrid(r,c) = 0; % remove any "big" numbers
			textGrid(r,c).String = '';
			if ~isnan(num)% change a specific number
				if strcmp(notesGrid(r,c,numInd).Visible,'on')
					notesGrid(r,c,numInd).Visible = 'off';
				else
					notesGrid(r,c,numInd).Visible = 'on';
				end
			elseif isnan(num) % enter all possible notes (based on latin square)
				for i = 1:n
					notesGrid(r,c,i).Visible = 'on';
				end
				updateNotes(0,0,r,c); % remove blocked numbers
				numPanel.Visible = 'off';
				boxes(numPanel.UserData(1),numPanel.UserData(2)).FaceColor = [1 1 1];
			else % num is empty
				for i = 1:n
					notesGrid(r,c,i).Visible = 'off';
				end
				numPanel.Visible = 'off';
				boxes(numPanel.UserData(1),numPanel.UserData(2)).FaceColor = [1 1 1];
			end
			return
		end
		
		% Enter 'big' number
		textGrid(r,c).String = newNum;
		numPanel.Visible = 'off';
		
		if isempty(num)
			num = 0; % should only check if turning off red text			
		else
			for i=1:n
				notesGrid(r,c,i).Visible = 'off';
			end
		end
		userGrid(r,c) = num;
		for i = 1:n
			blackNum(r,i);
			blackNum(i,c);
		end
		mathCheck(r,c); % check for math mistake
		
		% display the check mark if the puzzle is completed
		finished = winCheck();
		boxes(numPanel.UserData(1),numPanel.UserData(2)).FaceColor = [1 1 1];
	end
	
	
	% Checks if a newly entered 'big' number causes or resolves a math
	% mistake
	function [] = mathCheck(r,c)
		ind = indGrid(r,c); % find its blob
		blob = blobs(ind);
		count = 0;
		for i = 1:blob.UserData.size % count how many boxes in the blob are filled
			count = count + (0~=userGrid(blob.UserData.rc(i,1),blob.UserData.rc(i,2)));
		end
		
		if count~=blob.UserData.size % only check the math when the blob is finished
			blob.UserData.opT.Color = [0 0 0];
		else
			% b.UserData.op = 1,2,3,4,5 - single,add,sub,mult,div
			switch blob.UserData.op
				case 1 % single box blob
					col = (blob.UserData.ans ~= userGrid(r,c));
				case 2 % addition
					a = 0;
					for i=1:blob.UserData.size
						a = a + userGrid(blob.UserData.rc(i,1),blob.UserData.rc(i,2));
					end
					col = (blob.UserData.ans ~= a);
				case 3 % subtraction
					col = (blob.UserData.ans ~= abs(userGrid(blob.UserData.rc(1,1),blob.UserData.rc(1,2))-userGrid(blob.UserData.rc(2,1),blob.UserData.rc(2,2))));
				case 4 % multiplication
					a = 1;
					for i=1:blob.UserData.size
						a = a * userGrid(blob.UserData.rc(i,1),blob.UserData.rc(i,2));
					end
					col = (blob.UserData.ans ~= a);
				case 5 % division
					a = userGrid(blob.UserData.rc(1,1),blob.UserData.rc(1,2))/userGrid(blob.UserData.rc(2,1),blob.UserData.rc(2,2));
					if a<1
						a = 1/a;
					end
					col = (blob.UserData.ans ~= a);
			end
			blob.UserData.opT.Color(1) = col; % changes operation color between black and red
		end
	end
	
	% Checks if 'big' numbers should be black or red if they caseu a latin
	% square mistake
	function [] = blackNum(r,c)
		num = userGrid(r,c);
		i = find(userGrid(r,:)==num);
		j = find(userGrid(:,c)==num)';
		if length(i)==1 && length(j)==1
			textGrid(r,c).Color = [0 0 0];
		else
			textGrid(r,c).Color = [1 0 0];
		end
	end
	
	% Changes between Enter and Note mode when using the button
	function [] = noteSwitch(~,~)
		if strcmp(noteBtn.String, noteBtn.UserData{1})
			noteBtn.String = noteBtn.UserData{2}; %'Pencil';
			noteBtn.Value = true;
			but(2).Visible = 'on';
		else
			noteBtn.String = noteBtn.UserData{1};%'Ink';
			noteBtn.Value = false;
			but(2).Visible = 'off';
		end
	end
	
	% Restarts the puzzle. Clears all notes and 'big' numbers
	function [] = restart(~,~)
		userGrid = zeros(n);
		for r = 1:n
			for c = 1:n
				textGrid(r,c).String = ' ';
				for i = 1:n
					notesGrid(r,c,i).Visible = 'off';
				end
			end
		end
		for i = 1:length(blobs)
			blobs(i).UserData.opT.Color(1) = 0;
		end
		delete(checkmark)
	end
	
	% 'New Game' button callback. Calls functions to generate the puzzle
	% and construct the board
	function [] = newGame(~,~)
		cla
		
		numPanel.Visible = 'off';
		numPanel.UserData = [1 1];
		
		n = gridSize.UserData;
		theNums = numPicker.Data;
% 		b = blobSize.UserData;
		finished = false;
		
		axis(1+[0 n 0 n])
		userGrid = zeros(n);
		patchGrid(n);
		numGrid = gridGen(n);
		blobGen();
		drawnow;
		opChooser();
		opShower();
		drawnow;
		blankNums();
		buildEnterTool();
		for i = 1:numel(boxes)
			boxes(i).Visible = 'on';
		end
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
		
		nR = ceil((n+2)/3);
		numPanel.Position(4) = numPanel.Position(3)/3*nR;
		a = 1-1/nR;
		for i = 1:n
			if i > length(but) - 2
				but(i+2) = uicontrol(...
				'Parent',numPanel,...
				'Style','pushbutton',...
				'Units','normalized',...
				'Position',[mod(i-1,3)/3 0.5, 1/3 0.5],...
				'String',num2str(theNums(i)),...
				'FontSize',15,...
				'Callback',{@numFill, num2str(theNums(i)), theNums(i), i});
			else
				but(i+2).String = num2str(theNums(i));
				but(i+2).Callback = {@numFill, num2str(theNums(i)), theNums(i), i};
			end
			but(i+2).Position(2) = a;
			but(i+2).Position(4) = 1/nR;
			if mod(i,3)==0
				a = a -1/nR;
			end
			but(i+2).Visible = 'on';
		end
% 		but
		for i = (n+3):length(but)
			but(i).Visible = 'off';
		end
		but(1).Position(4) = 1/nR; % Position the 'all' and 'X' buttons
		but(2).Position(4) = 1/nR;
	end
	
	% Displays the prime factorization of the entered number when pressing
	% the Factor Button
	function [] = primeFac(in,~, out)
		num = round(str2num(in.String));
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
		fcn = @(x) strcmp(x.Visible,'on');
		for i = 1:n
			for j = 1:n
				if userGrid(i,j) == 0 && ~any(arrayfun(fcn,notesGrid(i,j,:)))
					for k = 1:n
						notesGrid(i,j,k).Visible = 'on';
					end
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
				textGrid(r,c).String = num2str(blobs(i).UserData.ans);
				for j=1:n
					notesGrid(r,c,j).Visible = 'off';
				end
			end
		end
		for i = 1:n
			for j = 1:n
				blackNum(i,j);
			end
		end
		finished = winCheck();
	end
	
	
	
	function [] = opSelection(src, ~, op)
		allowedOps(op) = src.Value;
		if ~any(allowedOps) % all turned off
			allowedOps(1) = true;
			src.Parent.Children('+'==[src.Parent.Children.String]).Value = true;
		elseif allowedOps(4) && all(~allowedOps(1:3)) % division only
			% only allow if the array is all powers of x and blob size is limited to 2
			x = numPicker.Data;
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
	
	
	% should negative numbers be allowed? it worked well in rullo
	% should 0 be banned? (it might cause trouble with division if allowed
	function [] = numSelection(src, evt)
		% Negative numbers are banned because it makes subtraction messy.
		% It would also require rewriting portions of code that assume
		% positive numbers
		% zero is banned because userGrid uses 0 as blank and a lot of code
		% would have to be changed
		arrayOptions.SelectedObject = arrayCustom;
		if isnan(evt.NewData)
			if ~isnan(str2num(evt.EditData))
				src.Data(evt.Indices(1),evt.Indices(2)) = str2num(evt.EditData);
			else
				src.Data(evt.Indices(1),evt.Indices(2)) = nextNewNum();
			end
		elseif evt.NewData ~= round(evt.NewData)
			src.Data(evt.Indices(1),evt.Indices(2)) = round(evt.NewData);
		elseif evt.NewData <= 0
			src.Data(evt.Indices(1),evt.Indices(2)) = nextNewNum();
		end
		if length(unique(src.Data)) ~= gridSize.UserData
			src.Data(evt.Indices(1),evt.Indices(2)) = nextNewNum();
		end
		src.Data = sort(src.Data);
		
		
		if allowedOps(4) && all(~allowedOps(1:3))
			% only allow if the array is all powers of x and blob size is
			% limited to 2
			x = src.Data;
			x = x(2:end)./x(1:end-1);
			if ~all(x(1) == x)
				allowedOps(1) = true;
				addCheck.Value = true;
			end
		end
		
		function [i] = nextNewNum()
			i = 1;
			num = find(i == src.Data,1);
			while ~isempty(num)
				i = i + 1;
				num = find(i == src.Data,1);
			end
		end
	end
	
	% maybe turn 2^x into x^y somehow
	function [] = arraySelection(~, ~, option)
% 		arrayOptions.SelectedObject.Callback
		ng = gridSize.UserData;
		switch option
			case 1
				numPicker.Data = (1:ng)';
			case 2
				x = ng;
				a = primes(x);
				while length(a) ~= (ng - 1)
					x = x + 2;
					a = primes(x);
				end
				numPicker.Data = [1 a]';
			case 3
				numPicker.Data = 2.^(0:ng-1)';
		end
		if (option == 1 || option == 2) && allowedOps(4) && all(~allowedOps(1:3))
			% when going off powers of two, make sure division isn't the
			% only operator
			allowedOps(1) = true;
			addCheck.Value = true;
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
			numPicker.Data = numPicker.Data(1:b);
		elseif b > a
			if arrayOptions.SelectedObject == arrayCustom
				for i = a:b
					evt.Indices = [i, 1];
					evt.EditData = '';
					evt.NewData = nan;
					numSelection(numPicker, evt);
				end
			else
				arraySelection(2, 4, arrayOptions.SelectedObject.Callback{2});
			end
		end
	end
	
	
	% Debug function that will display the solution
	function [] = showNums() %#ok<DEFNU>
		for r = 1:n
			for c = 1:n
				text(c+0.5,r+0.5,num2str(numGrid(r,c)),'FontSize',10,'HorizontalAlignment','center');
			end
		end
	end
	
	% Generates the text objects for the notes and 'big' numbers
	function [] = blankNums()
		textGrid = matlab.graphics.primitive.Text.empty;
		notesGrid = matlab.graphics.primitive.Text.empty;
		fs = 1/(3*n);
		temp = text(1, 1, '1','FontName','fixedwidth','FontUnits','normalized','FontSize',fs);
		
		a = num2str(theNums);
		a(a==' ') = [];
		numChars = length(a) + n-1;
% 		r = temp.Extent(3) / temp.Extent(4);
% 		x = sqrt(temp.Extent(4)*(1*0.7)/numChars);
% 		fs2 = fs*x/temp.Extent(3);
		
		x = roots([numChars/temp.Extent(4), -0.7, -0.7*1]);
		x = x(1);
		r2 = x / temp.Extent(3);
		
		
		fs = r2 * fs;
		temp.FontSize = fs;
		
		m = 1 - 0.5*temp.Extent(3);
		y = 1 - 2*temp.Extent(4);
		notesGrid(1,1,1) = text(1+m, 1+y, {''},'FontName','fixedwidth','FontUnits','normalized','FontSize',fs,'Visible','off','HorizontalAlignment','right');
		noteString = {notesGrid(1,1,1).String};
		for k = n:-1:1
			notesGrid(1,1,1).String{1} = [' ', num2str(theNums(k)), notesGrid(1,1,1).String{1}];
			if notesGrid(1,1,1).Position(1) + notesGrid(1,1,1).Extent(3) > 3
				noteString(2:length(noteString)+1,1) = noteString;
				noteString(1) = {[' ', num2str(theNums(k))]};
				notesGrid(1,1,1).String = noteString;
			end
			noteString = notesGrid(1,1,1).String;
		end
		
% 		notesGrid(1,1,1).Position
% 		notesGrid(1,1,1).Extent
		
		for r = 1:n
			for c = 1:n
				textGrid(r,c) = text(c+0.5,r+0.5,' ','FontSize',20,'HorizontalAlignment','center');
				notesGrid(r,c) = text(c+m, r+y, noteString,'FontName','fixedwidth','FontUnits','normalized','FontSize',fs,'Visible','off','HorizontalAlignment','right');
			end
		end
		
% 		for r = 1:n
% 			for c = 1:n
% 				textGrid(r,c) = text(c+0.5,r+0.5,' ','FontSize',20,'HorizontalAlignment','center');
% 				m = c+1;
% 				y = r+0.9;
% 				
% % 				count = 1;
% 				for k = n:-1:1
% 					notesGrid(r,c,k) = text(c, r, [' ' num2str(theNums(k))],'FontName','fixedwidth','FontUnits','normalized','FontSize',fs,'Visible','off','Color',0.0*[1 1 1]);
% 					m = m - notesGrid(r,c,k).Extent(3);
% 					if m < c-temp.Extent(3)
% 						m = c + 1 - notesGrid(r,c,k).Extent(3);
% 						y = y - notesGrid(r,c,k).Extent(4);
% % 						count = count + 1;
% 					end
% 					notesGrid(r,c,k).Position(1:2) = [m, y];
% 				end
% 			end
% 		end
		delete(temp)
	end
	% 				for k = 1:n
% 					notesGrid(r,c,k) = text(c+(k-1)*0.85/n+0.2/n, r+0.9, num2str(theNums(k)),'FontSize',10,'Visible','off');
% 				end
	% Displays the operator and target value for each blob
	function [] = opShower()
		ops = ' +-*/';
		a = [blobs(:).UserData];
		[~,i] = max([a(:).ans]);
		
		fs = 0.15/n;
		temp = text(0,0,sprintf('%s %d',ops(blobs(i).UserData.op), blobs(i).UserData.ans),'FontUnits','normalized','FontSize',fs);
		fs = 0.9*fs/temp.Extent(3);
		delete(temp);
		for i = 1:length(blobs)
			r = min(blobs(i).UserData.rc(:,1));
			c = min(blobs(i).UserData.rc(blobs(i).UserData.rc(:,1)==r,2));
			blobs(i).UserData.opT = text(0.1+c,0.15+r,sprintf('%s %d',ops(blobs(i).UserData.op), blobs(i).UserData.ans),'FontUnits','normalized','FontSize',fs);
			drawnow;
		end
	end
	
	% Selects the operator and target value for each blob
	function [] = opChooser()
		for i = 1:length(blobs)
			% 5 bools, [n + - * /] (n refers to a single square)
% 			ops = [true allowedOps];
% 			ops = ops();
			s = blobs(i).UserData.size;
			num = numGrid(sub2ind([n n], blobs(i).UserData.rc(:,1), blobs(i).UserData.rc(:,2)));
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
				blobs(i).UserData.op = (randi(2)*2)*(allowedOps(1) && allowedOps(3)) + xor(allowedOps(1),allowedOps(3)).*(2*allowedOps(1) + 4*allowedOps(3));
			end
% 			blobs(i).UserData.op
			switch blobs(i).UserData.op
				case 1 % single num
					a = num;
				case 2 % add
					a = sum(num);
				case 3 % sub
					a = abs(diff(num));
				case 4 % mult
					a = prod(num);
				case 5 % div
					a = num(1)/num(2);
					if a<1
						a = 1/a;
					end
			end
			blobs(i).UserData.ans = a;
		end
	end
	
	% Adds the squares that create the thin grid lines and serve for
	% highlighting the currently selected square
	function [] = patchGrid(n)
		boxes = matlab.graphics.primitive.Patch.empty;
		for r = 1:n
			for c = 1:n
				boxes(r,c) = patch(c+[0 1 1 0],r+[0 0 1 1],[1 1 1],'EdgeColor',0.5*ones(1,3),'Visible','off');
			end
		end
	end

	
	%================== board generation functions========================
	
	% Sets up the inital values for the recursive latin square generation.
	% The first column is selected randomly here, as any permutation of the
	% first column can lead to a valid latin square, so the recursion is
	% not needed
	function [g] = gridGen(n)
		g = zeros(n);
		g(:,1) = theNums(randperm(n));
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
		gridOrig = grid;
		w = nonzeros(unique([grid(:,c),grid(r,:)'])); %all blocked options
		e = theNums;
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
			grid = gridOrig;
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
			p.LineWidth = 2.5;
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
		
		%{
		
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
		% need some sort or custom reset button. On large grids it is also
		% fairly laggy. All text objects will still show up outside the axes.
		% Can be fixed by giving them all the 'Clipping' 'on' property.
		%}
		
		ax = axes('Parent',f);
% 		ax.Position = [0.5*(1-f.Position(4)/f.Position(3)) 0 1*f.Position(4)/f.Position(3) 1];
		ax.Position = [0.175 0 0.6 1];
		ax.YDir = 'reverse';
		ax.YTick = [];
		ax.XTick = [];
		ax.XColor = [1 1 1];
		ax.YColor = [1 1 1];
		axis equal
		
		
		
		
		
		
		ng = uicontrol(...
			'Parent',f,...
			'Units','normalized',...
			'Style','pushbutton',...
			'String','New Game',...
			'Callback',@newGame,...
			'Position',[0.05 0.45 0.1 0.1],...
			'FontSize',15); 
		
		clearer = uicontrol(...
			'Parent',f,...
			'Units','normalized',...
			'Style','pushbutton',...
			'String','Restart',...
			'Callback',@restart,...
			'Position',[0.05 0.05 0.1 0.1],...
			'FontSize',15);
		
		str = {'Enter','Notes'};
		noteBtn = uicontrol(...
			'Parent',f,...
			'Units','normalized',...
			'Style','togglebutton',...
			'String',str{1},... %ink
			'UserData',str,...
			'Callback',@noteSwitch,...
			'Position',[0.05 0.25 0.1 0.1],...
			'FontSize',15,...
			'TooltipString','Switches note mode on and off');
			
		
		
		
		
		
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
			'String','12',...
			'Position',[0.025 0.85 0.95 0.075],...
			'Callback',{@primeFac, factorDisp},...
			'TooltipString','Displays prime factors',...
			'FontSize',15);		
		
		singleFiller = uicontrol(...
			'Parent',toolsPanel,...
			'Units','normalized',...
			'Style','pushbutton',...
			'String','Fill Singles',...
			'Callback',@fillSingles,...
			'Position',[0.1 0.4 0.8 0.1],...
			'FontSize',12,...
			'TooltipString','Fills all single number boxes');
		
		noteClearer = uicontrol(...
			'Parent',toolsPanel,...
			'Units','normalized',...
			'Style','pushbutton',...
			'String','Update Notes',...
			'Callback',@updateNotes,...
			'Position',[0.1 0.25 0.8 0.1],...
			'FontSize',12,...
			'TooltipString','Removes notes based on inked numbers in the same row and column');
		allNotes = uicontrol(...
			'Parent',toolsPanel,...
			'Units','normalized',...
			'Style','pushbutton',...
			'String','Add All Notes',...
			'Callback',@allNotesFcn,...
			'Position',[0.1 0.1 0.8 0.1],...
			'FontSize',12,...
			'TooltipString','Adds notes to all blank squares');
		
		
		
		
		
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
			'String','5',...
			'Callback',@gridClip,...
			'UserData',5,...
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


		numPicker = uitable(...
			'Parent',genOptions,...
			'Units','normalized',...
			'Position',[0.02 0.02 0.96 0.5],...
			'Data',(1:gridSize.UserData)',...
			'ColumnEditable',true,...
			'ColumnWidth',{30},...
			'ColumnName',{'#'},...
			'RowName',{},...
			'CellEditCallback',@numSelection);
		x = numPicker.Extent(3);
		numPicker.Position([1 3]) = [0.2-x/2 x-0.01];
		
		
		arrayOptions = uibuttongroup(...
			'Parent',genOptions,...
			'Units','normalized',...
			'Position',[0.05+sum(numPicker.Position([1 3])) 0.02 0.1 0.5]);
		arrayOptions.Position(3) = 1 - arrayOptions.Position(1);
		
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
		bigger = uicontrol(...
			'Parent',uiOptions,...
			'Units','normalized',...
			'Style','pushbutton',...
			'String','+',...
			'Callback',{@toolScale,1},...
			'Position',[0.05 0.85 0.25 0.05],...
			'FontSize',15,...
			'TooltipString','Increases tool size');
		smaller = uicontrol(...
			'Parent',uiOptions,...
			'Units','normalized',...
			'Style','pushbutton',...
			'String','-',...
			'Callback',{@toolScale,0},...
			'Position',[0.325 0.85 0.25 0.05],...
			'FontSize',15,...
			'TooltipString','Decreases tool size');
		
		
		
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



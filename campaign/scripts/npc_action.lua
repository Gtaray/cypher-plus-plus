local bParsed = false;
local aComponents = {};

local bDragging = nil;
local hoverComp = nil;
local clickedComp = nil;

function getActionNode()	
	local nodePower = window.getDatabaseNode();
	if not nodePower then
		nodePower = window.windowlist.window.getDatabaseNode();
	end
	return nodePower;
end

function getActorNode()
	local nodeAction = getActionNode();
	return nodeAction.getChild("...");
end

function getActor()
	local nodeCreature = getActorNode();
	return ActorManager.resolveActor(nodeCreature);
end

function onValueChanged()
	bParsed = false;
end

function parseComponents()
	aComponents = PowerManager.parseNPCPower(window.getDatabaseNode());
	bParsed = true;
end

-- Reset selection when the cursor leaves the control
function onHover(bOnControl)
	if bDragging or bOnControl then
		return;
	end

	hoverComp = nil;
	setSelectionPosition(0);
end

-- Hilight attack or damage hovered on
function onHoverUpdate(x, y)
	if bDragging then
		return;
	end

	if not bParsed then
		parseComponents();
	end
	local nMouseIndex = getIndexAt(x, y);
	hoverComp = nil;

	for i = 1, #aComponents do
		if aComponents[i].startpos <= nMouseIndex and aComponents[i].endpos > nMouseIndex then
			setCursorPosition(aComponents[i].startpos);
			setSelectionPosition(aComponents[i].endpos);

			hoverComp = i;			
		end
	end
	
	if hoverComp then
		nDragIndex = hoverComp;
		setHoverCursor("hand");
	else
		nDragIndex = nil;
		setHoverCursor("arrow");
	end
end

function action(draginfo, rAction)
	-- Get power name
	local nodeAction = getActionNode();
	local sPowerName = DB.getValue(nodeAction, "name", "");
	local rActionCopy = UtilityManager.copyDeep(rAction);
	rActionCopy.label = sPowerName;

	local rActor = getActor();
	return PowerManager.performNpcAction(draginfo, rActor, rActionCopy, window.getDatabaseNode());
end

-- Suppress default processing to support dragging
function onClickDown(button, x, y)
	clickedComp = hoverComp;
	return true;
end

-- On mouse click, set focus, set cursor position and clear selection
function onClickRelease(button, x, y)
	setFocus();
	
	local n = getIndexAt(x, y);
	setSelectionPosition(n);
	setCursorPosition(n);
	
	return true;
end

function onDoubleClick(x, y)
	if hoverComp then
		action(nil, aComponents[hoverComp]);
		return true;
	end
end

function onDragStart(button, x, y, draginfo)
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if bDragging then
		return true;
	end

	if clickedComp then
		action(draginfo, aComponents[clickedComp]);
		clickedComp = nil;
		bDragging = true;
		return true;
	end
	
	return true;
end

function onDragEnd(dragdata)
	setCursorPosition(0);
	bDragging = false;
end
-- Reactor controller v2.0 ETMBP, Ede Teller must be proud project

bSide = "bottom"
wSide = "left"
mSide = "back"

-- Print array for debug purpose
function printArray(arr)
	for i, v in pairs(arr) do
		print(i.." "..v)
	end
end
-- Device class, mother of all
local Device = {id = "N/A"}
function Device:new(o, id, number, obj, category, shortName)
	local ob = o or {}
	setmetatable(ob, Device)
	self.__index = self
	self.id = id or "N/A"
	self.number = number or "N/A"
	self.obj = obj or "N/A"
	self.category = category or "N/A"
	self.shortName = shortName or "N/A"
	return ob
end

function Device:getCategory()
	return self.category
end

--Reactor class from Device
local Reactor = Device:new()
--Reactor = {}
function Reactor:new(o, id)
	local ob = o or Device:new(o,id)
	setmetatable(ob, Reactor)
	self.__index = self
	--print("R ",id)
	self.obj = peripheral.wrap(id)
	return ob
end

function Reactor:getConnected() 
	 return self.obj.getConnected()
end

function Reactor:getActive()
	return self.obj.getActive
end

function Reactor:setActive(online)
	self.obj.setActive(online)
end

function Reactor:getYelloriumTemp()
	return math.floor(self.obj.getFuelTemperature())
end

function Reactor:getRodSetting()
	return self.obj.getControlRodLevel(1)
end

function Reactor:setRodSetting(level)
	self.obj.setAllControlRodLevels(level)
end

function Reactor:getRadiation()
	return math.floor(self.obj.getFuelReactivity())
end

function Reactor:getSteamOutput()
	return math.floor(self.obj.getHotFluidProducedLastTick())
end

function Reactor:getYelloriumMax()
	return math.floor(self.obj.getFuelAmountMax())
end

function Reactor:getYelloriumLeft()
	return math.floor(self.obj.getFuelAmount())
end

function Reactor:getYelloriumConsumption()
	return self.obj.getFuelConsumedLastTick()
end

--Monitor class
local  Monitor = Device:new()
function Monitor:new(o, id, width, height)
	local ob = o or Device:new(o, id)
	setmetatable(ob, Monitor)
	self.__index = self
	--print("M ",id)
	self.obj = peripheral.wrap(id)
	self.width, self.height = width, height or self:getSize()
	return ob
end

function Monitor:getSize()
	return self.obj.getSize()
end

function Monitor:getPos()
	return self.obj.getCursorPos()
end

function Monitor:setPos(x, y)
	self.obj.setCursorPos(x, y)
end

function Monitor:setColor(color)
	self.obj.setTextColor(color)
end

function Monitor:setBGColor(color)
	self.obj.setBackgroundColor(color)
end

function Monitor:reset()
	self.obj.clear()
	self.obj.setCursorPos(1,1)
	self.obj.setTextScale(1)
	self.obj.setTextColor(colors.white)
	self.obj.setBackgroundColor(colors.black)
end

function Monitor:writeOut(what, putNewLine)
	self.putNewLine = putNewLine or false
	x, y = self:getPos()
	self.obj.write(what)
	if putNewLine then
		self:setPos(x, y+1)
	end
end

-- Turbine Class

local Turbine = Device:new()
function Turbine:new(o, id)
	local ob = o or Device:new(o, id)
	setmetatable(ob, Turbine)
	self.__index = self
	--print("T ",id)
	self.obj = peripheral.wrap(id)
	self.obj.getConnected()
	return ob
end

function Turbine:getConnected()
	return self.obj.getConnected()
end

function Turbine:getActive()
	return self.obj.getActive()
end

function Turbine:setActive(online)
	self.obj.setActive(online)
end

function Turbine:getCoilActive()
	return self.obj.getInductorEngaged()
end

function Turbine:setCoilActive(online)
	self.obj.setInductorEngaged(online)
end

function Turbine:getRPM()
	return math.floor(self.obj.getRotorSpeed())
end

function Turbine:getSteamInput()
	return math.floor(self.obj.getInputAmount())
end

function Turbine:getRFGenerated()
	return math.floor(self.obj.getEnergyProducedLastTick())
end

function Turbine:setOffline()
	self:setActive(false)
	self:setCoilActive(false)
end

--Capacitor class
local Capacitor = Device:new()
function Capacitor:new(o, id, blockCount, blockStore)
	local ob = o or Device:new(o, id)
	setmetatable(ob, Capacitor)
	self.__index = self
	--print("C ",id)
	self.obj = peripheral.wrap(id)
	self.blockCount = blockCount or 225
	self.blockStore = blockStore or 2500000
	return ob
end

function Capacitor:getCapacity()
	return self.blockCount * self.blockStore
end

function Capacitor:getStored()
	return self.obj.getEnergyStored() * self.blockCount
end

function Capacitor.getPercent()
	return self:getStored() / (self:getCapacity() / 100)
end

function Capacitor:getFlow()
	before = self:getStored()
	sleep(0.1)
	return math.floor((self:getStored() - before) / 3)
end

--Controller class with some Vytutas mineral water
local Controller = { id = "" }
function Controller:new(o, optimalRPM, optimalRodPercent, minTemp, maxTemp, minStoredPercent, maxStoredPercent, yelloriumEmitterLevel, controlledDevices, countByType, liveSettings)
	local ob = o or {}
	setmetatable(ob, Controller)
	self.__index = self
	self.optimalRPM = optimalRPM or 1870
	self.optimalRodPercent = optimalRodPercent or 40
	self.minTemp = minTemp or 500
	self.maxTemp = maxTemp or 550
	self.minStoredPercent = minStoredPercent or 45
	self.maxStoredPercent = maxStoredPercent or 98
	self.yelloriumEmitterLevel = yelloriumEmitterLevel or 1000
	self.controlledDevices = controlledDevices or self:wrapAll()
	--self.countByType = countByType or self:countTypes()
	--self.liveSettings = liveSettings or { maintenanceByLever = false, maintenancebyPalm = false, maintenancebyYelloriumLevel = false, generate = false, forceOnLine = false }
	return ob
end

function Controller:countTypes()
	countByType = { turbine = 0, reactor = 0, monitor = 0, capacitor = 0}
	for i, v in pairs(self.controlledDevices) do
		if v.category == "turbine" then countByType["turbine"] = countByType["turbine"] + 1
		elseif v.category == "monitor" then countByType["monitor"] = countByType["monitor"] + 1
		elseif v.category == "reactor" then countByType["reactor"] = countByType["reactor"] + 1
		elseif v.category == "capacitor" then countByType["capacitor"] = countByType["capacitor"] + 1 end
	end
	return countByType
end

function Controller:wrapAll()
	devicesList = peripheral.getNames()
	filteredDevices = {}
	testTable = {}
	j=1
	for i, v in pairs(devicesList) do
		testTable[j] = Device:new()
		if string.find(v, "-Reactor") then
			table.insert(filteredDevices, v)
		elseif string.find(v, "Turbine") then
			table.insert(filteredDevices, v)
		elseif string.find(v, "capacitor") then
			table.insert(filteredDevices, v)
		elseif string.find(v, "monitor") then
			table.insert(filteredDevices, v)
		end
		j = j+1
	end
	--printArray(filteredDevices)
	controlledDevices = {}
	j=1
	for i, v in pairs(filteredDevices) do
		--print("0 ", tostring(#controlledDevices))
		if string.find(v, "-Reactor") then
			dObj = Reactor:new(nil, v)
			table.insert(controlledDevices, dObj)
			controlledDevices[#controlledDevices].category = "reactor"
		elseif string.find(v, "Turbine") then
			dObj = Turbine:new(nil, v)
			table.insert(controlledDevices, dObj)
			controlledDevices[#controlledDevices].category = "turbine"
		elseif string.find(v, "capacitor") then
			dObj = Capacitor:new(nil, v)
			table.insert(controlledDevices, dObj)
			controlledDevices[#controlledDevices].category = "capacitor"
		elseif string.find(v, "monitor") then
			dObj = Monitor:new(nil, v)
			table.insert(controlledDevices, dObj)
			controlledDevices[#controlledDevices].category = "monitor"
		end
		if dObj then
			testTable[j] = dObj
			--print(dObj.id)
			--print(dObj.category)
			j=j+1
		end
		--print("1 ", tostring(#controlledDevices))
		--print("ID: ", controlledDevices[#controlledDevices].id)
		--print("Cat:"..controlledDevices[#controlledDevices].category)
		if ((#controlledDevices) > 1 ) then
			--print("elso elem: ",tostring(controlledDevices[1].id))
		end
	end
	debugTable(controlledDevices)
	--print(tostring(controlledDevices[2].id))
	
	return controlledDevices
end

function Controller:getCableActive(color)
	return colors.test(redstone.getBundledInput(bSide), color)
end

function Controller:getMaintenance()
	if self:getCableActive(colors.white) or self:getCableActive(colors.purple) or self.liveSettings["maintenancebyYelloriumLevel"] then return true
	else return false end
end

function Controller:setReactorOnline(state)
	for i, v in pairs(self.controlledDevices) do
		if v:getCategory() == "reactor" then v:setActive(state) end
	end
end

function Controller:setAllTurbineOnline(state)
	for i, v in pairs(self.controlledDevices) do
		if v:getCategory() == "turbine" then v:setActive(state) end
	end
end

--Regulate by Warren G
function Controller:regulate()
	generationCycle = false
	firstRun = true
	capacitorIndex = 0
	for i,v in pairs(controlledDevices) do
		if v.category == "capacitor" then
			capacitorIndex = i
		end
	end
	if self:getMaintenance() then
		self:setReactorOnline(false)
		self:setAllTurbineOnline(false)
		sleep(5)
	else
		if generationCycle then
			if firstRun then
				--Activate reactor
				--Set rod 0
				--set turbines online
				--wait 10
				--Set Coil online
				firstRun = false
			elseif controlledDevices[capacitorIndex]:getPercent() > self.maxStoredPercent then
				--stop generation
			end
		else
			if self.liveSettings["forceOnLine"] then
				--Activate reactor
				--Activate turbines
			else
				for i, v in pairs(controlledDevices) do
					if v.category == "turbine" then
						if v:getRPM() < self.optimalRPM then
							--activate turbine
						else
							--deactivate turbine
						end
					end
				end
				for i, v in pairs(controlledDevices) do
					if v.category == "turbine" then
						if v:getActive() then
							--Activate reactor
							break
						else
							--deactivate reactor
						end
					end
				end
			end
			for i, v in pairs(controlledDevices) do
				if v.category == "reactor" then
					if v:getActive() then
						if v:getYelloriumTemp() < self.minTemp then
							--Pull out rods by one
						elseif v:getYelloriumTemp() > maxTemp then
							--Push rods by one
						end
					end
				end
			end
		end
	end
end

function Controller:listenToPalm()
	rednet.open("left")
	id, msg = rednet.receive()
	if msg == keys.e then
		--Do things
	end
end

function Controller:getMonitors()
	local monitors = {}
	for i, v in pairs(controlledDevices) do
		if v:getCategory() == "monitor" then
			table.insert(monitors, v)
		end
	end
	return monitors
end

--View
local View = { id = "" }
function View:new(o, monitors, termMon, reactorMon, turbineMon)
	local ob = o or {}
	setmetatable(ob, View)
	self.__index = self
	self.monitors = monitors or {}
	self.termMon = termMon or self:setTermMon()
	self.reactorMon = reactorMon or {}
	self.turbineMon = turbineMon or {}
	return ob
end

function View:setTermMon()
	size = 10240
	monObj = {}
	height = 0
	for i, v in pairs(monitors) do
		height = v.obj.getSize()
		if height < size then
			monObj = v
			size = v.height
		end
	end
	return monObj
end

function View:redirectToTerm()
	term.redirect(self.termMon.obj)
	self.termMon:reset()
end

function debugTable(tableObj)
	for i, obj in pairs(tableObj) do
		print(i..":"..obj.id)
	end 
end

-- Do the hardwork
c = Controller:new()
v = View:new(_, c:getMonitors())
v:redirectToTerm()
--c:regulate()

--!strict
-- @soder / kokabiella
local methods = {}

export type InstanceCache<T> = {
	new: (T: Instance) -> (InstanceCache<T>),
	GetInstance: (self: InstanceCache<t>) -> (T),
	ReturnInstance: (self: InstanceCache<T>, Instance: T) -> (),
	Expand: (self: InstanceCache<T>) -> (),
	DelayReturn: (self: InstanceCache<T>, Instance: T, Time: number) -> (),
	
	Template: T,
	InUse: {T},
	Open: {T},
	ExpansionSize: number,
	Type: string
}

function methods.ReturnInstance<T>(self: InstanceCache<T>, Instance: T)
	if typeof(Instance) ~= self.Type then
		warn(`InstanceCache can only accept one type of an instance at a time. Do not return type: {typeof(Instance)} to this InstanceCache because it is incompatible with type: {self.Type}`)
	end
	
	for i,v in self.InUse do
		if v == Instance then
			table.remove(self.InUse, i)
			break
		end
	end
	
	local Properties = self.Template:GetProperties()
	
	for i,v in Properties do
		Instance[i] = v
	end
	
	table.insert(self.Open, Instance)
end

function methods.Expand<T>(self: InstanceCache<T>)
	for i = 1, self.ExpansionSize do
		table.insert(self.Open, Instance.fromExisting(self.Template))
	end
end

function methods.DelayReturn<T>(self: InstanceCache<T>, Instance: T, Time: number)
	task.delay(Time, function()
		self:ReturnInstance(Instance)
	end)
end

function methods.GetInstance<T>(self: InstanceCache<T>): T
	if #self.Open == 0 then
		self:Expand()
	end
	local Inst = table.remove(self.Open, 1) :: T
	table.insert(self.InUse, Inst)
	return Inst
end

function methods.new<T>(Template: T, Amount: number, ExpansionSize: number): InstanceCache<T>
	local self = {} :: InstanceCache<T>

	self.Template = Template
	self.InUse = {}
	self.Open = {}
	self.ExpansionSize = ExpansionSize
	self.Type = typeof(Template)
	
	self.GetInstance = methods.GetInstance
	self.ReturnInstance = methods.ReturnInstance
	self.Expand = methods.Expand
	self.DelayReturn = methods.DelayReturn

	return self
end

return methods

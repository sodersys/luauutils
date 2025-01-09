--!strict
-- @soder / kokabiella
local methods = {}

export type InstanceCache<t> = {
	new: (t: Instance) -> (InstanceCache<t>),
	GetInstance: (self: InstanceCache<t>) -> (t),
	ReturnInstance: (self: InstanceCache<t>, Instance: t) -> (),
	Expand: (self: InstanceCache<t>) -> (),
	DelayReturn: (self: InstanceCache<t>, Instance: t, Time: number) -> (),
	
	Template: t,
	InUse: {t},
	Open: {t},
	ExpansionSize: number,
	Type: string
}

function methods.ReturnInstance<t>(self: InstanceCache<t>, Instance: t)
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

function methods.Expand<t>(self: InstanceCache<t>)
	for i = 1, self.ExpansionSize do
		table.insert(self.Open, Instance.fromExisting(self.Template))
	end
end

function methods.DelayReturn<t>(self: InstanceCache<t>, Instance: t, Time: number)
	task.delay(Time, function()
		self:ReturnInstance(Instance)
	end)
end

function methods.GetInstance<t>(self: InstanceCache<t>): t
	if #self.Open == 0 then
		self:Expand()
	end
	local Inst = table.remove(self.Open, 1) :: t
	table.insert(self.InUse, Inst)
	return Inst
end

function methods.new<t>(Template: t, Amount: number, ExpansionSize: number): InstanceCache<t>
	local self = {} :: InstanceCache<t>

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

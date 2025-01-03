FuncTools = {}

function FuncTools.CallByName(ObjMeta, funcName, ...)
  local Load_string = "return "
  if ObjMeta then
    Load_string = Load_string .. ObjMeta .. "." .. funcName
  else
    Load_string = Load_string .. funcName
  end
  print(Load_string)
  local func = load(Load_string)()
  return func(...)
end

function FuncTools.Hello(Obj)
  print(Obj.a)
  print("hahahaha")
end

BaseClass = {}
BaseClass.__index = BaseClass

function BaseClass:New()
  local BaseObj = {}
  setmetatable(BaseObj, BaseClass)
  return BaseObj
end

function BaseClass:Print()
  print("!!!!")
  print(self.a)
end

SubClass = {}
SubClass.__index = SubClass
setmetatable(SubClass, BaseClass)

function SubClass:New()
  local SubObj = BaseClass:New()
  setmetatable(SubObj, SubClass)
  SubObj.a = 1
  return SubObj
end

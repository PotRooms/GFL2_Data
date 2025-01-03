require("NetCmd.LuaNullClientCmd")
LuaRes_roleInfo = class("LuaRes_roleInfo", LuaNullClientCmd)
LuaRes_roleInfo.__index = LuaRes_roleInfo
LuaRes_roleInfo.id = 0
LuaRes_roleInfo.uid = 0
LuaRes_roleInfo.name = nil
LuaRes_roleInfo.create_date = 0
LuaRes_roleInfo.broadcast_sign = 0
LuaRes_roleInfo.private_sign = 0

function LuaRes_roleInfo:ctor()
  LuaRes_roleInfo.super.ctor(self)
  self.cmd = CS.LuaUtils.EnumToInt(CS.Cmd.CmdDef.roleInfo)
end

function LuaRes_roleInfo:PackData(byteBuffer)
  byteBuffer:WriteLong(self.id)
  byteBuffer:WriteInt(self.uid)
  byteBuffer:WriteLanString(self.name)
  byteBuffer:WriteInt(self.create_date)
  byteBuffer:WriteLanString(self.broadcast_sign)
  byteBuffer:WriteLanString(self.private_sign)
end

function LuaRes_roleInfo:UnPackData(byteBuffer)
  self.id = byteBuffer:ReadLong()
  self.uid = byteBuffer:ReadInt()
  self.name = byteBuffer:ReadLanString()
  self.create_date = byteBuffer:ReadInt()
  self.broadcast_sign = byteBuffer:ReadLanString()
  self.private_sign = byteBuffer:ReadLanString()
end

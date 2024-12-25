NetTool = CS.NetTool
ByteBuffer = CS.ByteBuffer
CmdConst = CS.CmdConst
CmdDef = CS.Cmd.CmdDef

function CommonUnPack(cmd, msg, _UnPack)
  local byteBuffer = ByteBuffer(msg)
  local tempcmd = byteBuffer:ReadUShort()
  if tempcmd ~= cmd then
    print("\233\148\153\232\175\175\231\154\132\230\140\135\228\187\164:" .. tempcmd .. "  \229\174\158\233\153\133\230\140\135\228\187\164:" .. tostring(cmd))
  end
  local len = byteBuffer:ReadUShort()
  local msgLength = string.len(msg)
  if len ~= msgLength - CmdConst.CMD_HEAD_LEN then
    print("\233\148\153\232\175\175\231\154\132\230\140\135\228\187\164\233\149\191\229\186\166:" .. len .. "  \229\174\158\233\153\133\230\140\135\228\187\164\233\149\191\229\186\166:" .. msgLength - CmdConst.CMD_HEAD_LEN)
  end
  _UnPack(byteBuffer)
  byteBuffer:Close()
end

function CommonPack(cmd, _Pack)
  local byteBuffer = ByteBuffer()
  byteBuffer:WriteUShort(0)
  byteBuffer:WriteByte(0)
  byteBuffer:WriteUShort(0)
  byteBuffer:WriteUShort(cmd)
  local offset = byteBuffer.Pos
  byteBuffer:WriteUShort(0)
  local length = byteBuffer.Pos
  _Pack(byteBuffer)
  length = byteBuffer.Pos - length
  byteBuffer:WriteLength(offset, length)
  local res = byteBuffer:ToBytes()
  byteBuffer:Close()
  return res
end

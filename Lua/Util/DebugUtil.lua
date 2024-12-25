local cls = {}
local listenPort = 9966
local connectPort = 9955

function cls.Listen()
  if cls.listening then
    return
  end
  cls.listening = true
  local port = 0
  local isListen = CS.DebugCenter.Instance:IsOn(CS.DebugToggleType.EmmyLuaDebugListen)
  if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor then
    package.cpath = package.cpath .. ";Assets/Editor/EmmyLua/?.dll"
    local succ, err = xpcall(function()
      emmyDebugger = require("emmy_core")
      if isListen then
        port = listenPort
        emmyDebugger.tcpListen("localhost", port)
      else
        port = connectPort
        emmyDebugger.tcpConnect("localhost", port)
      end
      CS.UnityEngine.Debug.Log("EmmyLua Debug Server Started. Version: " .. tostring(emmyLuaDebuggerVersion) .. " port: " .. tostring(port) .. " isListen: " .. tostring(isListen))
    end, debug.traceback)
    if not succ then
      CS.UnityEngine.Debug.Log("EmmyLua Debug Server Failed to Start: " .. tostring(err) .. " port: " .. tostring(port) .. " isListen: " .. tostring(isListen))
    end
  end
end

function cls.Break()
  if CS.UnityEngine.Application.isEditor and emmyDebugger then
    emmyDebugger.waitIDE()
    emmyDebugger.breakHere()
  end
end

return cls

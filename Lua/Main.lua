print("Load Main.lua")
local m = xlua.getmetatable(CS.GF2.Data.LanguageStringData)

function m.__tostring(o)
  return o.str
end

function m.__concat(l, r)
  return table.concat({
    type(l) == "string" and l or l.str,
    type(r) == "string" and r or r.str
  })
end

xlua.setmetatable(CS.GF2.Data.LanguageStringData, m)
require("Lib.class")
require("Lib.Console")
require("Lib.Dictionary")
require("Lib.FuncTools")
require("Lib.GFLib")
require("Lib.List")
require("Lib.TableTools")
require("NetCmd.LuaNullClientCmd")
require("NetCmd.LuaRes_roleInfo")
require("NetCmd.NetLib")
require("NetCmd.Patch")
require("perf.memory")
require("perf.profiler")
require("xlua.util")
require("UI.GlobalConfig")
require("UI.UIBaseCtrl")
require("UI.UIBasePanel")
require("UI.UIBaseView")
require("UI.UICNWords")
require("UI.UIDef")
require("UI.Config.UIDefineConfig")
require("UI.UIManager")
require("UI.UITweenCamera")
require("UI.UIUtils")
require("UI.MessageBox.Data.MessageContent")
require("UI.MessageBox.MessageBoxPanel")
require("UI.Common.UICommonItem")
if CS.UnityEngine.Application.isEditor then
  DebugUtil = require("Util.DebugUtil")
  DebugUtil.Listen()
end

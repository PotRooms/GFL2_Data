require("UI.UIBaseCtrl")
ActivityTourGridEventInfo = class("ActivityTourGridEventInfo", UIBaseCtrl)
ActivityTourGridEventInfo.__index = ActivityTourGridEventInfo
ActivityTourGridEventInfo.ui = nil
ActivityTourGridEventInfo.mData = nil

function ActivityTourGridEventInfo:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function ActivityTourGridEventInfo:InitCtrl(itemPrefab, parent)
  local obj = instantiate(itemPrefab, parent)
  self:SetRoot(obj.transform)
  self.ui = {}
  self.mData = nil
  self:LuaUIBindTable(obj, self.ui)
  MonopolyUtil:SetMonopolyActivityUIHint(self.mUIRoot.transform)
end

function ActivityTourGridEventInfo:Refresh(data, enable)
  local funcName = data.name.str
  if MpGridManager.GmShowFuncID then
    funcName = tostring(data.id) .. ":" .. funcName
  end
  if enable then
    self.ui.mText_Name.text = funcName
  else
    self.ui.mText_Name.text = funcName .. MonopolyUtil:GetMonopolyActivityHint(23002001)
  end
  self.ui.mText_Detail.text = data.desc.str
  local isDescEmpty = data.desc.str == nil or data.desc.str == ""
  setactive(self.ui.mText_Detail, not isDescEmpty)
end

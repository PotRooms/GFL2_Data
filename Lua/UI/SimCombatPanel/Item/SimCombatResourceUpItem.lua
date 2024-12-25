require("UI.UIBaseCtrl")
SimCombatResourceUpItem = class("SimCombatResourceUpItem", UIBaseCtrl)
SimCombatResourceUpItem.__index = SimCombatResourceUpItem

function SimCombatResourceUpItem:ctor()
end

function SimCombatResourceUpItem:InitCtrl(target, parent)
  local instObj = instantiate(target, parent)
  self:InitCtrlWithNoInstantiate(instObj, false)
end

function SimCombatResourceUpItem:InitCtrlWithNoInstantiate(obj, setToZero)
  self:SetRoot(obj.transform)
  obj.transform.localPosition = vectorzero
  if setToZero == nil or setToZero then
    obj.transform.anchoredPosition = vector2zero
  else
    obj.transform.anchoredPosition = vector2one * 1000000
  end
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
end

function SimCombatResourceUpItem:SetData(desc, numCurrent, numMax)
  self.ui.mText_Desc.text = desc
  self.ui.mText_Num.text = 0 < numMax and numCurrent .. "/" .. numMax or ""
  if numCurrent <= 0 and 0 < numMax then
    self.ui.mImg_ImgBg.color = ColorUtils.StringToColor("7A7A7A")
  end
  setactivewithcheck(self:GetRoot(), true)
end

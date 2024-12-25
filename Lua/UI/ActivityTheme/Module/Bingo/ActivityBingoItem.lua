require("UI.UIBaseCtrl")
ActivityBingoItem = class("ActivityBingoItem", UIBaseCtrl)
ActivityBingoItem.__index = ActivityBingoItem

function ActivityBingoItem:ctor()
end

function ActivityBingoItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:InitCtrlWithNoInstantiate(instObj, false)
end

function ActivityBingoItem:InitCtrlWithNoInstantiate(obj, setToZero)
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

function ActivityBingoItem:SetData(key, index, status)
end

function ActivityBingoItem:UpdateStatus(status, withAnim)
end

function ActivityBingoItem:OnReward()
end

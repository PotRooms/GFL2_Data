require("UI.UIBaseCtrl")
ActivityBingoTaskItem = class("ActivityBingoTaskItem", UIBaseCtrl)
ActivityBingoTaskItem.__index = ActivityBingoTaskItem

function ActivityBingoTaskItem:ctor()
end

function ActivityBingoTaskItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:InitCtrlWithNoInstantiate(instObj, false)
end

function ActivityBingoTaskItem:InitCtrlWithNoInstantiate(obj, setToZero)
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

function ActivityBingoTaskItem:SetData(data, activityId, bingoId)
end

function ActivityBingoTaskItem:Refresh()
end

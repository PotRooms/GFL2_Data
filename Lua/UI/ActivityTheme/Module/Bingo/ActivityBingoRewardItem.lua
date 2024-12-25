require("UI.UIBaseCtrl")
ActivityBingoRewardItem = class("ActivityBingoRewardItem", UIBaseCtrl)
ActivityBingoRewardItem.__index = ActivityBingoRewardItem

function ActivityBingoRewardItem:ctor()
end

function ActivityBingoRewardItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:InitCtrlWithNoInstantiate(instObj, false)
end

function ActivityBingoRewardItem:InitCtrlWithNoInstantiate(obj, setToZero)
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

function ActivityBingoRewardItem:SetData(key, index, config, status)
end

function ActivityBingoRewardItem:UpdateStatus(status)
end

function ActivityBingoRewardItem:OnReward(status)
end

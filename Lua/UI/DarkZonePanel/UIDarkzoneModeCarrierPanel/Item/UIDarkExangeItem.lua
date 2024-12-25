require("UI.UIBaseCtrl")
UIDarkExangeItem = class("UIDarkExangeItem", UIBaseCtrl)
UIDarkExangeItem.__index = UIDarkExangeItem

function UIDarkExangeItem:InitCtrl(prefab, parent, callback)
  local obj = instantiate(prefab, parent)
  self:SetRoot(obj.transform)
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
  setactive(obj, true)
  self.itemList = {}
end

function UIDarkExangeItem:SetExchangeData(escort_goodData, num)
  if num == nil then
    num = 0
  end
  local itemLeft = UICommonItem.New()
  local fakeItemData = CS.UICommonItem.GetFakeItemData(escort_goodData, num)
  itemLeft:InitCtrl(self.ui.mScrollListChild_GrpItem.transform)
  itemLeft:SetFakeItem(fakeItemData)
  table.insert(self.itemList, itemLeft)
  local itemRight = UICommonItem.New()
  itemRight:InitCtrl(self.ui.mScrollListChild_GrpItemList.transform)
  itemRight:SetItemData(escort_goodData.ItemId, num)
  table.insert(self.itemList, itemRight)
  if self.animationTimer then
    self.animationTimer:Stop()
    self.animationTimer = nil
  end
  self.animationTimer = TimerSys:DelayCall(1, function()
    if self.ui.mAnimation_Exchange then
      self.ui.mAnimation_Exchange:Play("Ani_DarkzoneCarrierRewardExchangeItem_Exchange")
    end
  end)
end

function UIDarkExangeItem:OnRelease()
  for i = 1, #self.itemList do
    self.itemList[i]:OnRelease()
  end
  if self.animationTimer then
    self.animationTimer:Stop()
    self.animationTimer = nil
  end
end

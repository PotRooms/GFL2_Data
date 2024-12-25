require("UI.Repository.Item.UIRepositoryListItemV2")
require("UI.Repository.RepositoryPanel.SubPanel.UIRepositoryBasePanel")
UIRepositoryItemPanel = class("UIRepositoryItemPanel", UIRepositoryBasePanel)
UIRepositoryItemPanel.__index = UIRepositoryItemPanel

function UIRepositoryItemPanel:ctor(parent, panelId, transRoot)
  self.super.ctor(self, parent, panelId, transRoot)
  self.itemList = nil
end

function UIRepositoryItemPanel:InitItemTypeList()
  local parentRoot = self.parent.ui.mContent_Item.transform
  local typeList = TableData.listRepositoryCategoryDatas
  for i = 0, typeList.Count - 1 do
    local item = UIRepositoryListItemV2.New()
    item:InitCtrl(parentRoot)
    item:SetData(typeList[i])
    table.insert(self.itemList, item)
  end
end

function UIRepositoryItemPanel:CheckItemToDel()
  local timeLimitItem = {}
  local itemDataList = NetCmdItemData:GetOverTimeItem()
  if itemDataList ~= nil then
    for i = 0, itemDataList.Count - 1 do
      local itemData = itemDataList[i]
      local itemTableData = TableData.listItemDatas:GetDataById(itemData.item_id)
      if itemTableData.ShowType ~= 0 then
        table.insert(timeLimitItem, itemData)
      end
    end
    if 0 < #timeLimitItem then
      UIManager.OpenUIByParam(UIDef.UIComExpirationPopDialog, timeLimitItem)
    end
  end
end

function UIRepositoryItemPanel:Show()
  self.super.Show(self)
  self.parent.ui.mTrans_Item.localPosition = vectorzero
  self:CheckItemToDel()
end

function UIRepositoryItemPanel:OnPanelBack()
  self:Refresh()
  self:CheckItemToDel()
end

function UIRepositoryItemPanel:Refresh()
  self:UpdateItemList()
end

function UIRepositoryItemPanel:UpdateItemList()
  if self.itemList == nil then
    self.itemList = {}
    self:InitItemTypeList()
    self.time2 = TimerSys:DelayFrameCall(1, function()
      self:UpdateItemListDetail()
    end)
  else
    self:UpdateItemListDetail()
  end
end

function UIRepositoryItemPanel:UpdateItemListDetail()
  for i, item in ipairs(self.itemList) do
    item:UpdateItemListWithDelay(i - 1)
  end
  if self.isFirstIn == true then
    self.parent.ui.mFade_ItemContent:InitFade()
    self.isFirstIn = false
  end
end

function UIRepositoryItemPanel:SortItemList()
end

function UIRepositoryItemPanel:Close()
  self.super.Close(self)
  self.isFirstIn = true
  self.parent.ui.mTrans_Item.localPosition = Vector3(0, 3000, 0)
  for _, item in ipairs(self.itemList) do
    item:StopTimer()
  end
  if self.time1 ~= nil then
    self.time1:Stop()
  end
  if self.time2 ~= nil then
    self.time2:Stop()
  end
end

function UIRepositoryItemPanel:OnRelease()
  if self.itemList ~= nil then
    for _, item in ipairs(self.itemList) do
      item:OnRelease()
    end
  end
  self.isFirstIn = nil
  self.super.OnRelease(self)
end

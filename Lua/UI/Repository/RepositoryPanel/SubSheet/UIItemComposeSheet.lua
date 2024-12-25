require("UI.Common.UICommonItemL")
UIItemComposeSheet = class("UIItemComposeSheet")

function UIItemComposeSheet:ctor(parent, subSheetId, transRoot)
  self.parent = parent
  self.transRoot = transRoot
  self.subSheetId = subSheetId
  self.itemList = {}
  self.parentRoot = parent.ui.mTrans_ComposeContent.transform
  self.typeList = TableData.listItemCompoundDatas
end

function UIItemComposeSheet:Show()
  if self.transRoot then
    self.transRoot.alpha = 1
    self.transRoot.blocksRaycasts = true
  end
end

function UIItemComposeSheet:Refresh()
  if #self.itemList == 0 then
    self:InitItemTypeList()
    self.time2 = TimerSys:DelayFrameCall(1, function()
      self:UpdateItemListDetail()
    end)
  else
    self:UpdateItemListDetail()
  end
end

function UIItemComposeSheet:InitItemTypeList()
  for i = 0, self.typeList.Count - 1 do
    local item = UIRepositoryListItemV2.New()
    item:InitCtrl(self.parentRoot, "ItemCompound")
    item:SetData(self.typeList[i])
    setactive(item.mImg_Icon, false)
    table.insert(self.itemList, item)
  end
end

function UIItemComposeSheet:UpdateItemListDetail()
  for i, item in ipairs(self.itemList) do
    item:UpdateItemListWithDelay(i - 1)
  end
end

function UIItemComposeSheet:Close()
  if self.transRoot then
    self.transRoot.alpha = 0
    self.transRoot.blocksRaycasts = false
  end
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

function UIItemComposeSheet:OnRelease()
  if self.itemList ~= nil then
    for _, item in ipairs(self.itemList) do
      item:OnRelease()
    end
  end
  self.parent = nil
  self.transRoot = nil
  self.subSheetId = nil
  self.itemList = nil
  self.parentRoot = nil
  self.typeList = nil
end

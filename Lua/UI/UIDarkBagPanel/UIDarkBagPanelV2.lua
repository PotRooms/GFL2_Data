require("UI.Repository.Item.UIRepositoryListItemV2")
require("UI.Repository.UIRepositoryGlobal")
require("UI.DarkZonePanel.UIDarkZoneRepositoryPanel.UIDarkZoneRepositoryGlobal")
UIDarkBagPanelV2 = class("UIDarkBagPanelV2", UIBasePanel)
UIDarkBagPanelV2.__index = UIDarkBagPanelV2

function UIDarkBagPanelV2:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIDarkBagPanelV2:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self.itemList = {}
  self.tagList = {}
  self.detailUI = {}
  self:LuaUIBindTable(root, self.ui)
  if self.detailInfo == nil then
    self.detailInfo = instantiate(self.ui.mScrollChild_Right.childItem, self.ui.mScrollChild_Right.transform)
  end
  self:LuaUIBindTable(self.detailInfo, self.detailUI)
  self:AddBtnListener()
end

function UIDarkBagPanelV2:AddBtnListener()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIDarkBagPanel)
  end
end

function UIDarkBagPanelV2:InitData()
  self.contentItem = {}
  self.selectFrameIndex = -1
  self.index = 0
  self.BagMgr = CS.LuaPlayerDataHandler.DarkPlayerBag
  self.curClickTabId = -1
  self.isEmpty = true
  self:SetDetailShow()
end

function UIDarkBagPanelV2:Show()
  setactive(self.ui.mText_Num.transform.parent, false)
  self:InitItemsUI()
end

function UIDarkBagPanelV2:InitItemsUI()
  self:InitItemTypeList()
  for index, tag in ipairs(self.tagList) do
    self:UpdateDarkZoneItemList(index, tag)
  end
end

function UIDarkBagPanelV2:ResetInit()
  self:InitData()
  self:Show()
  setactive(self.ui.mTrans_Empty.gameObject, self.isEmpty)
  setactive(self.detailUI.mTrans_TexpEmpty, not self.isEmpty)
  setactive(self.detailUI.mTrans_TopInfo, false)
  if self.isEmpty then
    for i = 1, #self.tagList do
      setactive(self.tagList[i]:GetRoot(), false)
    end
  end
end

function UIDarkBagPanelV2:InitItemTypeList()
  local parentRoot = self.ui.mContent_Item.transform
  local typeList = TableData.listDarkzoneRepositoryCategoryDatas
  for i = 0, typeList.Count - 1 do
    local item = self.tagList[i + 1]
    if item == nil then
      item = UIRepositoryListItemV2.New()
      table.insert(self.tagList, item)
      item:InitCtrl(parentRoot)
    end
    setactive(item:GetRoot(), true)
    item:SetData(typeList[i])
  end
end

function UIDarkBagPanelV2:UpdateDarkZoneItemList(index, tag)
  local index = self.index
  local tagEmpty = true
  if tag.mData then
    for i = 1, #tag.itemList do
      setactive(tag.itemList[i]:GetRoot(), false)
    end
    local ItemType = tag.mData.item_type
    local itemDataList = self.BagMgr:GetBagByType(index, ItemType)
    for i = 0, itemDataList.Count - 1 do
      self.isEmpty = false
      tagEmpty = false
      local itemData = itemDataList[i]
      if 0 < itemData.num then
        local itemTableData = TableData.listItemDatas:GetDataById(itemData.itemID)
        local timeLimit = itemTableData.time_limit
        if timeLimit == 0 or timeLimit > CGameTime:GetTimestamp() then
          local item
          if i + 1 > #self.itemList then
            item = UICommonItem.New()
            item:InitCtrl(tag.mTrans_ItemList)
            table.insert(tag.itemList, item)
          else
            item = tag.itemList[i + 1]
          end
          index = self.index
          self.contentItem[index] = item
          item:SetItemData(itemData.itemID, itemData.num, false, false, itemData.num, nil, nil, function(tempItem)
            self:ShowCommonItem(tempItem)
          end, nil, true)
          item:SetBagIndex(index)
          self.index = self.index + 1
        end
      end
    end
  end
  if tagEmpty then
    setactive(tag:GetRoot(), false)
  end
end

function UIDarkBagPanelV2:ShowCommonItem(item)
  if self.selectFrameIndex >= 0 then
    self.contentItem[self.selectFrameIndex]:SetSelectShow(false)
  end
  local index = item.bagIndex
  self.selectFrameIndex = index
  self:OnClickStackItem(index, item)
  local itemTabData = TableData.GetItemData(item.itemId)
  if itemTabData ~= nil then
    self.detailUI.mText_Title.text = itemTabData.name.str
    self.detailUI.mImg_QualityLine.color = TableData.GetGlobalGun_Quality_Color2(itemTabData.rank)
    self.detailUI.mTxt_DetailInfo.text = itemTabData.introduction.str
    self.detailUI.mTxt_ItemName.text = TableData.listItemTypeDescDatas:GetDataById(itemTabData.type).name.str
  end
  setactive(self.detailUI.mTrans_TopInfo, itemTabData ~= nil)
  self.curClickTabId = UIRepositoryGlobal.PanelType.ItemPanel
  self:SetDetailShow()
end

function UIDarkBagPanelV2:OnClickStackItem(index, item)
  item:SetSelectShow(true)
end

function UIDarkBagPanelV2:OnShowFinish()
  TimerSys:DelayCall(0.02, function()
    self:ResetInit()
  end)
end

function UIDarkBagPanelV2:SetDetailShow()
  setactive(self.detailUI.mTrans_GrpInfo, self.curClickTabId == UIRepositoryGlobal.PanelType.ItemPanel)
  setactive(self.detailUI.mTrans_TexpEmpty, self.curClickTabId == -1)
  setactive(self.detailUI.mTrans_TopInfo, true)
  setactive(self.detailUI.mTrans_GrpWeaponPart, false)
  setactive(self.detailUI.mText_Flaw, false)
  setactive(self.detailUI.mTrans_Capacity, false)
  setactive(self.ui.mTrans_Empty.gameObject, self.isEmpty)
end

function UIDarkBagPanelV2:OnClose()
  self.selectIndex = -1
  self.selectFrameIndex = -1
  self.contentItem = {}
  setactive(self.detailUI.mTrans_Capacity, false)
  setactive(self.detailUI.mImg_PartType, false)
  setactive(self.detailUI.mText_Flaw, false)
  setactive(self.detailUI.mScrollChild_Attribute, false)
  setactive(self.detailUI.mTrans_Special, false)
  setactive(self.detailUI.mTrans_MakeUp, false)
  setactive(self.detailUI.mTrans_GrpPolarity, false)
  setactive(self.detailUI.mTrans_TopInfo, false)
  gfdestroy(self.detailInfo.gameObject)
  self.detailInfo = nil
  if self.tagList then
    for i = 1, #self.tagList do
      gfdestroy(self.tagList[i]:GetRoot())
    end
  end
end

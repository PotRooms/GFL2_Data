require("UI.Common.UICommonItem")
require("UI.UIBaseCtrl")
UIRepositoryListItemV2 = class("UIRepositoryListItemV2", UIBaseCtrl)
UIRepositoryListItemV2.__index = UIRepositoryListItemV2
UIRepositoryListItemV2.mImg_Icon = nil
UIRepositoryListItemV2.mText_Name = nil
UIRepositoryListItemV2.mText_Sub = nil

function UIRepositoryListItemV2:__InitCtrl()
  self.mImg_Icon = self.ui.mImg_Icon
  self.mText_Name = self.ui.mText_Name
  self.mText_Sub = self.ui.mText_Sub
  self.mTrans_ItemList = self.ui.mTrans_ItemList
end

function UIRepositoryListItemV2:ctor()
  self.itemList = {}
  self.dataSourceType = "RepositoryCategory"
  self.data2SetData = {}
  
  function self.data2SetData.RepositoryCategory(data)
    self:SetRepositoryCategoryItemData(data)
  end
  
  function self.data2SetData.ItemCompound(data)
    self:SetItemCompoundItemData(data)
  end
  
  self.data2UpdateFunction = {}
  
  function self.data2UpdateFunction.RepositoryCategory()
    return self:UpdateRepositoryCategoryItem()
  end
  
  function self.data2UpdateFunction.ItemCompound()
    return self:UpdateItemCompoundItem()
  end
  
  self.data2CreateItemFunction = {}
  
  function self.data2CreateItemFunction.RepositoryCategory(index, itemDataList, defaulDelay)
    self:UpdateItem(index, itemDataList, defaulDelay)
  end
  
  function self.data2CreateItemFunction.ItemCompound(index, itemDataList, defaulDelay)
    self:UpdateItemCompoundUIItem(index, itemDataList, defaulDelay)
  end
end

function UIRepositoryListItemV2:InitCtrl(parent, dateType)
  self.parent = parent
  local obj
  local childItem = parent:GetComponent(typeof(CS.ScrollListChild))
  if childItem then
    obj = instantiate(childItem.childItem)
  else
    obj = instantiate(UIUtils.GetGizmosPrefab("Repository/RepositoryListItemV2.prefab", self))
  end
  self:SetRoot(obj.transform)
  self.ui = {}
  self:LuaUIBindTable(obj.transform, self.ui)
  obj.transform:SetParent(parent, false)
  obj.transform.localScale = vectorone
  self.dataSourceType = dateType or "RepositoryCategory"
  self:SetRoot(obj.transform)
  self:__InitCtrl()
end

function UIRepositoryListItemV2:SetData(data)
  self.mData = data
  if data then
    self.data2SetData[self.dataSourceType](data)
  end
end

function UIRepositoryListItemV2:SetRepositoryCategoryItemData(data)
  self.mText_Name.text = data.title.str
  self.mImg_Icon.sprite = IconUtils.GetRepositoryIcon(data.icon)
end

function UIRepositoryListItemV2:SetItemCompoundItemData(data)
  self.mText_Name.text = data.name.str
end

function UIRepositoryListItemV2:UpdateItemListWithDelay(delay)
  if delay == nil or delay < 0 then
    self:UpdateItemList()
    return
  end
  self.delayTimer = TimerSys:DelayFrameCall(delay, function()
    self:UpdateItemList()
  end)
end

function UIRepositoryListItemV2:StopTimer()
  if self.delayTimer == nil then
    return
  end
  self.delayTimer:Stop()
  self.delayTimer = nil
end

function UIRepositoryListItemV2:UpdateItemList()
  local t = TableData.GlobalSystemData.BackpackJumpSwitch == 1
  if self.mData then
    local itemDataList = self.data2UpdateFunction[self.dataSourceType]()
    self.data2CreateItemFunction[self.dataSourceType](0, itemDataList, 0)
  end
end

function UIRepositoryListItemV2:UpdateRepositoryCategoryItem()
  local itemDataList = NetCmdItemData:GetRepositoryItemListByTypes(self.mData.item_type)
  for i = 1, #self.itemList do
    if i > itemDataList.Count then
      setactive(self.itemList[i]:GetRoot(), false)
    end
  end
  return itemDataList
end

function UIRepositoryListItemV2:UpdateItemCompoundItem()
  local itemDataList = self.mData.list
  for i = 1, #self.itemList do
    if i > itemDataList.Count then
      setactive(self.itemList[i]:GetRoot(), false)
    end
  end
  return itemDataList
end

function UIRepositoryListItemV2:UpdateItemCompoundUIItem(index, itemDataList, defaulDelay)
  local itemId = itemDataList[index]
  local delay = defaulDelay or 1
  TimerSys:DelayFrameCall(delay, function()
    local itemTableData = TableData.listItemDatas:GetDataById(itemId)
    local item
    if index + 1 > #self.itemList then
      item = UICommonItem.New()
      item:InitCtrl(self.mTrans_ItemList)
      table.insert(self.itemList, item)
    else
      item = self.itemList[index + 1]
    end
    setactive(item.ui.mTrans_Num, false)
    if item.itemId ~= itemId then
      item:SetItemComposeSheetItemData(itemId, function()
        local data = {}
        data[0] = itemTableData
        UIManager.OpenUIByParam(UIDef.UIRepositoryComposeDialog, data)
      end)
    else
      setactive(item:GetRoot(), true)
    end
    if index < itemDataList.Count - 1 then
      self:UpdateItemCompoundUIItem(index + 1, itemDataList)
    end
  end)
end

function UIRepositoryListItemV2:UpdateItem(index, itemDataList, defaulDelay)
  local itemData = itemDataList[index]
  local delay = defaulDelay or 1
  TimerSys:DelayFrameCall(delay, function()
    if itemData.item_num > 0 then
      local itemTableData = TableData.listItemDatas:GetDataById(itemData.item_id)
      local timeLimit = itemTableData.time_limit
      if timeLimit == 0 or timeLimit ~= 0 and timeLimit > CGameTime:GetTimestamp() then
        do
          local item
          if index + 1 > #self.itemList then
            item = UICommonItem.New()
            item:InitCtrl(self.mTrans_ItemList)
            table.insert(self.itemList, item)
          else
            item = self.itemList[index + 1]
          end
          local custOnclick
          if itemTableData.type == GlobalConfig.ItemType.GiftPick then
            function custOnclick()
              UIManager.OpenUIByParam(UIDef.UIRepositoryBoxDialog, itemTableData)
            end
          end
          if item.itemId ~= itemData.item_id or item.itemNum ~= itemData.item_num then
            item:SetItemData(itemData.item_id, itemData.item_num, false, TableData.GlobalSystemData.BackpackJumpSwitch == 1, itemData.item_num, nil, nil, custOnclick, nil, true)
            item:LimitNumTop(itemData.item_num)
          else
            setactive(item:GetRoot(), true)
          end
        end
      end
    end
    if index < itemDataList.Count - 1 then
      self:UpdateItem(index + 1, itemDataList)
    end
  end)
end

function UIRepositoryListItemV2:OnRelease()
  self:StopTimer()
  self.itemList = {}
end

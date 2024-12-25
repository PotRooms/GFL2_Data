require("UI.UIBaseCtrl")
require("UI.SimCombatPanel.WeaponModWish.Item.UISimCombatWeaponModWishItem")
require("UI.SimCombatPanel.WeaponModWish.Item.UISimCombatWeaponModWishDescItem")
UISimCombatWeaponModWishSelectItem = class("UISimCombatWeaponModWishSelectItem", UIBaseCtrl)
UISimCombatWeaponModWishSelectItem.__index = UISimCombatWeaponModWishSelectItem

function UISimCombatWeaponModWishSelectItem:__InitCtrl()
end

function UISimCombatWeaponModWishSelectItem:InitCtrl(root)
  self:SetRoot(root)
  self:SetBaseData()
  self:LuaUIBindTable(self.mUIRoot, self.ui)
  
  function self.ui.mLoopGridView_ItemList.itemCreated(renderData)
    local item = self:ItemProvider(renderData)
    return item
  end
  
  function self.ui.mLoopGridView_ItemList.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
end

function UISimCombatWeaponModWishSelectItem:ItemProvider(renderData)
  local itemView = UISimCombatWeaponModWishItem.New()
  itemView:InitCtrlWithoutInstantiate(renderData.gameObject, false)
  renderData.data = itemView
end

function UISimCombatWeaponModWishSelectItem:ItemRenderer(index, renderData)
  local data = self.allList[index]
  local item = renderData.data
  item:SetData(data, index, self.lastSelect == data)
  local str = self.nameList[index + 1] or "\230\151\160\233\133\141\231\189\174"
  item:SetItemName(str)
  item:SetClickFunction(function(item)
    self:ClickLeftTabFunction(item, true)
  end)
  item:SetSelectState(self.selectSuitID)
  if self.isFirstIn == true then
    if self.lastSelect > 0 then
      if self.lastSelect == item.suitID then
        self.curSelectItem = item
        self.isFirstIn = false
      end
    else
      self.curSelectItem = item
      self.isFirstIn = false
    end
    if self.curSelectItem then
      self:ClickLeftTabFunction(self.curSelectItem)
      item:SetSelectState(self.selectSuitID)
    end
  end
end

function UISimCombatWeaponModWishSelectItem:SetBaseData()
  self.curSelectItem = nil
  self.curSelectItemIndex = 0
  self.isFirstIn = true
  self.ui = {}
  self.descItemList = {}
end

function UISimCombatWeaponModWishSelectItem:SetData(data)
  self.simCombatData = data
  self.allList = self.simCombatData.mod_suit_drop
  self.nameList = string.split(self.simCombatData.suit_plan_des.str, ",")
  self.lastSelect = PlayerPrefs.GetInt(AccountNetCmdHandler:GetUID() .. "WeaponModWishSelect" .. self.simCombatData.sim_type, -1)
  local listCount = self.allList.Count
  self.ui.mLoopGridView_ItemList.numItems = listCount
  local listIndex = 0
  self:DelayCall(0.01, function()
    if self.isFirstIn == true then
      for i = 0, listCount - 1 do
        local suitID = self.allList[i]
        if self.lastSelect == suitID then
          listIndex = i
          break
        end
      end
    end
    self.ui.mLoopGridView_ItemList:ScrollTo(listIndex)
    self.ui.mLoopGridView_ItemList:Refresh()
  end)
end

function UISimCombatWeaponModWishSelectItem:ClickLeftTabFunction(item, refresh)
  self.curSelectItemIndex = item.itemIndex
  self:SetCurSelectItem(item)
  self:RefreshRightList(item.modSuitPlanIDList)
  if refresh then
    self.ui.mLoopGridView_ItemList:Refresh()
  end
end

function UISimCombatWeaponModWishSelectItem:SetCurSelectItem(item)
  self.selectSuitID = item.suitID
  self.selectSuitName = item.suitName
  self.selectSuitIDList = item.modSuitPlanIDList
end

function UISimCombatWeaponModWishSelectItem:RefreshRightList(idList)
  local listCount = idList.Count
  for i = 0, listCount - 1 do
    local suitID = idList[i]
    local index = i + 1
    if self.descItemList[index] == nil then
      self.descItemList[index] = UISimCombatWeaponModWishDescItem.New()
      self.descItemList[index]:InitCtrl(self.ui.mScrollListChild_RightContent)
    end
    local item = self.descItemList[index]
    item:SetData(suitID)
  end
end

function UISimCombatWeaponModWishSelectItem:OnRelease()
  self.ui.mLoopGridView_ItemList.numItems = 0
  self.curSelectItem = nil
  self.selectSuitID = nil
  self.selectSuitName = nil
  self.selectSuitIDList = nil
  self.curSelectItemIndex = nil
  self.isFirstIn = nil
  self.ui = nil
  self:ReleaseCtrlTable(self.descItemList, true)
  self.descItemList = nil
  self.super.OnRelease(self, false)
end

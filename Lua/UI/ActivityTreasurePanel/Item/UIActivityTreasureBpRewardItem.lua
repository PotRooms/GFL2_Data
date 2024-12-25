require("UI.UIBaseCtrl")
require("UI.Common.UICommonItem")
UIActivityTreasureBpRewardItem = class("UIActivityTreasureBpRewardItem", UIBaseCtrl)
UIActivityTreasureBpRewardItem.__index = UIActivityTreasureBpRewardItem
local locked = 0
local enable = 1
local received = 2

function UIActivityTreasureBpRewardItem:ctor()
end

function UIActivityTreasureBpRewardItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:InitCtrlWithNoInstantiate(instObj, false)
end

function UIActivityTreasureBpRewardItem:InitCtrlWithNoInstantiate(obj, setToZero)
  self:SetRoot(obj.transform)
  obj.transform.localPosition = vectorzero
  if setToZero == nil or setToZero then
    obj.transform.anchoredPosition = vector2zero
  else
    obj.transform.anchoredPosition = vector2one * 1000000
  end
  self.ui = {}
  self.itemPool = {}
  self:LuaUIBindTable(obj, self.ui)
  self:RegisterEvent()
end

function UIActivityTreasureBpRewardItem:RegisterEvent()
  function self.OnTreasureLevelRewardRefresh(data)
    if data.Content.betterBp then
      self:RefreshBetterUI()
    else
      self:RefreshUI(data.Content.from, data.Content.to)
    end
  end
  
  MessageSys:AddListener(UIEvent.OnTreasureLevelRewardRefresh, self.OnTreasureLevelRewardRefresh)
end

function UIActivityTreasureBpRewardItem:SetData(data)
  self.data = data
  self.id = data.id
  self.level = data.level
  self.ui.mText_Lv.text = self.level < 10 and "0" .. self.level or self.level
  self:RefreshStatus()
end

function UIActivityTreasureBpRewardItem:RefreshStatus()
  local commonStatus = NetCmdActivityTreasureData:GetRewardStatusByChannel(UIActivityTreasureItem.id, self.id, 0)
  local betterStatus = NetCmdActivityTreasureData:GetRewardStatusByChannel(UIActivityTreasureItem.id, self.id, 1)
  self:ClearRewardItems()
  local commonRewards = self.data.commonRewards
  local betterRewards = self.data.betterRewards
  self.commonRewardItems = {}
  self.betterRewardItems = {}
  self:CreateReward(commonRewards, 0, commonStatus)
  self:CreateReward(betterRewards, 1, betterStatus)
end

function UIActivityTreasureBpRewardItem:RefreshUI(from, to)
  local commonStatus = NetCmdActivityTreasureData:GetRewardStatusByChannel(UIActivityTreasureItem.id, self.id, 0)
  local betterStatus = NetCmdActivityTreasureData:GetRewardStatusByChannel(UIActivityTreasureItem.id, self.id, 1)
  if commonStatus == enable and from < self.level and to >= self.level then
    for _, item in ipairs(self.commonRewardItems) do
      item:SetAniFadein()
    end
  end
  if betterStatus == enable and from < self.level and to >= self.level then
    for _, item in ipairs(self.betterRewardItems) do
      item:SetAniFadein()
    end
  end
end

function UIActivityTreasureBpRewardItem:RefreshBetterUI()
  local betterStatus = NetCmdActivityTreasureData:GetRewardStatusByChannel(UIActivityTreasureItem.id, self.id, 1)
  if betterStatus == enable then
    for _, item in ipairs(self.betterRewardItems) do
      item:SetAniFadein()
    end
  end
end

function UIActivityTreasureBpRewardItem:TryGetItem(channel)
  local poolObj, parent, item
  poolObj = self.itemPool[1]
  if channel == 0 then
    parent = self.ui.mTrans_Com
  else
    parent = self.ui.mTrans_Better
  end
  if poolObj == nil then
    item = UICommonItem.New()
    item:InitCtrl(parent)
  else
    item = poolObj.item
    CS.LuaUIUtils.SetParent(poolObj.go, parent.gameObject)
    setactivewithcheck(poolObj.go, true)
    table.remove(self.itemPool, 1)
  end
  return item
end

function UIActivityTreasureBpRewardItem:CreateReward(rewards, channel, status)
  for _, v in ipairs(rewards) do
    local id = v.id
    local count = v.count
    local item = self:TryGetItem(channel)
    item:GetRoot():SetAsLastSibling()
    if enable == status then
      item:SetItemData(id, count, nil, nil, nil, nil, nil, function()
        NetCmdActivityTreasureData:SendReceiveSingleBpReward(self.id, function(ret)
          if ret == ErrorCodeSuc then
            UISystem:OpenCommonReceivePanel({
              function()
                MessageSys:SendMessage(UIEvent.OnTreasureBpRewardReceive, nil)
              end
            })
          end
        end)
      end)
    else
      item:SetItemData(id, count)
    end
    item:SetLock(locked == status)
    item:SetLockColor()
    item:SetRedPoint(enable == status)
    item:SetReceivedIcon(received == status)
    if channel == 0 then
      table.insert(self.commonRewardItems, item)
    else
      table.insert(self.betterRewardItems, item)
    end
  end
end

function UIActivityTreasureBpRewardItem:ClearRewardItems()
  if self.commonRewardItems ~= nil then
    for i = #self.commonRewardItems, 1, -1 do
      local item = self.commonRewardItems[i]
      table.remove(self.commonRewardItems, i)
      self:ReturnToPool(item)
    end
    self.commonRewardItems = nil
  end
  if self.betterRewardItems ~= nil then
    for i = #self.betterRewardItems, 1, -1 do
      local item = self.betterRewardItems[i]
      table.remove(self.betterRewardItems, i)
      self:ReturnToPool(item)
    end
    self.betterRewardItems = nil
  end
end

function UIActivityTreasureBpRewardItem:ReturnToPool(item)
  local root = item:GetRoot()
  local go = root.gameObject
  setactivewithcheck(root, false)
  table.insert(self.itemPool, {item = item, go = go})
end

function UIActivityTreasureBpRewardItem:ReleaseRewardItems()
  self:ReleaseTable(self.commonRewardItems)
  self:ReleaseTable(self.betterRewardItems)
  self:DestroyTab(self.itemPool)
  self.commonRewardItems = nil
  self.betterRewardItems = nil
  self.itemPool = nil
end

function UIActivityTreasureBpRewardItem:ReleaseTable(tab)
  if tab == nil then
    return
  end
  for i = #tab, 1, -1 do
    local item = tab[i]
    item:OnRelease(true)
    table.remove(tab, i)
  end
end

function UIActivityTreasureBpRewardItem:DestroyTab(tab)
  if tab == nil then
    return
  end
  for i = #tab, 1, -1 do
    local item = tab[i].item
    item:OnRelease(true)
    table.remove(tab, i)
  end
end

function UIActivityTreasureBpRewardItem:OnRelease()
  self:UnregisterEvent()
  self:ReleaseRewardItems()
  self.super.OnRelease(self, true)
end

function UIActivityTreasureBpRewardItem:UnregisterEvent()
  if self.OnTreasureLevelRewardRefresh then
    MessageSys:RemoveListener(UIEvent.OnTreasureLevelRewardRefresh, self.OnTreasureLevelRewardRefresh)
    self.OnTreasureLevelRewardRefresh = nil
  end
end

require("UI.ActivityTreasurePanel.Item.UIActivityTreasureBpRewardItem")
UIActivityTreasureBpRewardSubPanel = class("UIActivityTreasureBpRewardSubPanel", UIBaseView)
UIActivityTreasureBpRewardSubPanel.__index = UIActivityTreasureBpRewardSubPanel

function UIActivityTreasureBpRewardSubPanel:InitCtrl(root)
  self.ui = {}
  self:SetRoot(root)
  self:LuaUIBindTable(root, self.ui)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Receive.gameObject, function()
    self:ClickReceive()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Unlock.gameObject, function()
    self:ClickUnlock()
  end)
  
  function self.ui.mScrollCtrl.itemCreated(renderData)
    self:ItemProvider(renderData)
  end
  
  function self.ui.mScrollCtrl.itemRenderer(index, rendererData)
    self:ItemRenderer(index, rendererData)
  end
end

function UIActivityTreasureBpRewardSubPanel:SetTab(tab)
  self.tab = tab
end

function UIActivityTreasureBpRewardSubPanel:ClickReceive()
  NetCmdActivityTreasureData:SendReceiveBpReward(function(ret)
    if ret == ErrorCodeSuc then
      NetCmdActivityTreasureData:DirtyRedPoint()
      UISystem:OpenCommonReceivePanel({
        function()
          MessageSys:SendMessage(UIEvent.OnTreasureBpRewardReceive, nil)
        end
      })
    end
  end)
end

function UIActivityTreasureBpRewardSubPanel:ClickUnlock()
  local bpId = TableDataBase.listTreasureMainDatas:GetDataById(self.id).BpId
  local costItemId = TableDataBase.listTreasureConfigDatas:GetDataById(bpId).ItemId
  local costCount = TableDataBase.listTreasureConfigDatas:GetDataById(bpId).Price
  local name = TableDataBase.listItemDatas:GetDataById(costItemId).Name
  local contentStr = string_format(TableData.GetHintById(260125), costCount, name)
  local content = MessageContent.New(contentStr, MessageContent.MessageType.DoubleBtn, function()
    if self:EnoughToBuy() then
      MessageBoxPanel.Close()
      self:BuyBetterBp()
    elseif costItemId == 1 then
      UIManager.OpenUI(UIDef.UIComDiamondExchangeDialog)
    elseif costItemId == 11 then
      CS.UIStoreGlobal.OpenCharge()
    end
  end, function()
    MessageBoxPanel.Close()
  end, TableData.GetHintById(260126))
  MessageBoxPanel.Show(content)
end

function UIActivityTreasureBpRewardSubPanel:BuyBetterBp()
  local timer = TimerSys:DelayCall(0.5, function()
    NetCmdActivityTreasureData:SendBuyBetterBp(function(ret)
      if ret then
        NetCmdActivityTreasureData:DirtyRedPoint()
        self:OnBetterUnlock()
      end
    end)
  end)
  table.insert(self.timers, timer)
end

function UIActivityTreasureBpRewardSubPanel:OnBetterUnlock()
  self:RefreshRewardStatus()
  MessageSys:SendMessage(UIEvent.OnTreasureLevelRewardRefresh, nil, {betterBp = true})
  self.ui.mAnim_Lock:Play()
  local timer = TimerSys:DelayCall(self.ui.mAnim_Lock.clip.length, function()
    setactivewithcheck(self.ui.mTrans_Lock.gameObject, false)
  end)
  table.insert(self.timers, timer)
end

function UIActivityTreasureBpRewardSubPanel:RefreshRewardStatus()
  local rewardAvailable = NetCmdActivityTreasureData:CheckBpReward(self.id)
  self.tab:SetRedPointVisible(0 < rewardAvailable)
  if not self.ui.mUIRoot.gameObject.activeSelf then
    return
  end
  self.ui.mScrollCtrl:Refresh()
  self.ui.mScrollCtrl:SetLayoutDoneDirty()
  self:MoveToLastLevel(true)
  setactivewithcheck(self.ui.mTrans_Receive.gameObject, 0 < rewardAvailable)
end

function UIActivityTreasureBpRewardSubPanel:EnableSubPanel(id)
  self.id = id
  local bpId = TableDataBase.listTreasureMainDatas:GetDataById(self.id).BpId
  local bpChannel = NetCmdActivityTreasureData:IsUnlockAdvancedBp(self.id)
  setactivewithcheck(self.ui.mTrans_Lock.gameObject, not bpChannel)
  local rewardAvailable = NetCmdActivityTreasureData:CheckBpReward(self.id)
  setactivewithcheck(self.ui.mTrans_Receive.gameObject, 0 < rewardAvailable)
  local rewards = TableDataBase.listTreasureConfigDatas:GetDataById(bpId).RewardId
  self.timers = {}
  self.rewardItemList = {}
  self.rewardDataList = {}
  for i = 0, rewards.Count - 1 do
    local rewardData = TableDataBase.listTreasureRewardDatas:GetDataById(rewards[i])
    table.insert(self.rewardDataList, self:HandleOriginData(rewardData))
  end
  self.ui.mScrollCtrl.numItems = #self.rewardDataList
  local costItemId = TableDataBase.listTreasureConfigDatas:GetDataById(bpId).ItemId
  local costCount = TableDataBase.listTreasureConfigDatas:GetDataById(bpId).Price
  self.ui.mText_Cost.color = self:EnoughToBuy() and ColorUtils.StringToColor("3D2D20") or ColorUtils.RedColor
  self.ui.mImg_Icon.sprite = UIUtils.GetItemIcon(costItemId)
  self.ui.mText_Cost.text = costCount
  setactive(self.mUIRoot.gameObject, true)
  local timer = TimerSys:DelayFrameCall(1, function()
    self:MoveToLastLevel(false)
  end)
  table.insert(self.timers, timer)
  self:RegisterEvent()
end

function UIActivityTreasureBpRewardSubPanel:EnoughToBuy()
  local bpId = TableDataBase.listTreasureMainDatas:GetDataById(self.id).BpId
  local costItemId = TableDataBase.listTreasureConfigDatas:GetDataById(bpId).ItemId
  local costCount = TableDataBase.listTreasureConfigDatas:GetDataById(bpId).Price
  local ownNum = NetCmdItemData:GetItemCountById(costItemId)
  local enoughToBuy = costCount <= ownNum
  return enoughToBuy
end

function UIActivityTreasureBpRewardSubPanel:HandleOriginData(source)
  local data = {}
  data.id = source.id
  data.level = source.LevelId
  local commonRewards = {}
  local baseRewardStr = string.split(source.BaseRewardStr, ",")
  for _, str in ipairs(baseRewardStr) do
    local config = string.split(str, ":")
    local id = tonumber(config[1])
    local count = tonumber(config[2])
    table.insert(commonRewards, {id = id, count = count})
  end
  data.commonRewards = commonRewards
  local betterRewards = {}
  local advancedRewardStr = string.split(source.AdvancedRewardStr, ",")
  for _, str in ipairs(advancedRewardStr) do
    local config = string.split(str, ":")
    local id = tonumber(config[1])
    local count = tonumber(config[2])
    table.insert(betterRewards, {id = id, count = count})
  end
  data.betterRewards = betterRewards
  return data
end

function UIActivityTreasureBpRewardSubPanel:RefreshUI()
  self.ui.mText_Cost.color = self:EnoughToBuy() and ColorUtils.StringToColor("3D2D20") or ColorUtils.RedColor
end

function UIActivityTreasureBpRewardSubPanel:ItemProvider(renderData)
  local itemView = UIActivityTreasureBpRewardItem.New()
  itemView:InitCtrlWithNoInstantiate(renderData.gameObject)
  renderData.data = itemView
  table.insert(self.rewardItemList, itemView)
end

function UIActivityTreasureBpRewardSubPanel:ItemRenderer(index, renderData)
  local item = renderData.data
  local data = self.rewardDataList[index + 1]
  item:SetData(data)
end

function UIActivityTreasureBpRewardSubPanel:RegisterEvent()
  function self.onTreasureBpRewardReceive()
    self:RefreshRewardStatus()
  end
  
  MessageSys:AddListener(UIEvent.OnTreasureBpRewardReceive, self.onTreasureBpRewardReceive)
  
  function self.ItemUpdateHandler()
    self:RefreshUI()
  end
  
  MessageSys:AddListener(CS.GF2.Message.CommonEvent.ItemUpdate, self.ItemUpdateHandler)
end

function UIActivityTreasureBpRewardSubPanel:MoveToLastLevel(smooth)
  local bpLevel = NetCmdActivityTreasureData:GetBpLevel(self.id)
  local targetIndex = math.max(0, bpLevel - 3)
  self.ui.mScrollCtrl:ScrollTo(targetIndex, smooth)
end

function UIActivityTreasureBpRewardSubPanel:DisableSubPanel()
  self:StopTimers()
  self:ClearRewardItemList()
  self:UnregisterEvent()
  setactive(self.mUIRoot.gameObject, false)
end

function UIActivityTreasureBpRewardSubPanel:UnregisterEvent()
  MessageSys:RemoveListener(UIEvent.OnTreasureBpRewardReceive, self.onTreasureBpRewardReceive)
  MessageSys:RemoveListener(CS.GF2.Message.CommonEvent.ItemUpdate, self.ItemUpdateHandler)
end

function UIActivityTreasureBpRewardSubPanel:StopTimers()
  if self.timers == nil then
    return
  end
  for _, timer in ipairs(self.timers) do
    timer:Stop()
  end
  self.timers = nil
end

function UIActivityTreasureBpRewardSubPanel:ClearRewardItemList()
  if self.rewardItemList == nil then
    return
  end
  for i = #self.rewardItemList, 1, -1 do
    local item = self.rewardItemList[i]
    item:OnRelease()
    table.remove(self.rewardItemList, i)
  end
  self.ui.mScrollCtrl:DestroyAllItem()
  self.rewardItemList = nil
  self.rewardDataList = nil
end

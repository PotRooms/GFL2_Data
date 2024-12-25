require("UI.UIBasePanel")
UIActivityTreasureFlopRewardPreviewDialog = class("UIActivityTreasureFlopRewardPreviewDialog", UIBasePanel)
UIActivityTreasureFlopRewardPreviewDialog.__index = UIActivityTreasureFlopRewardPreviewDialog

function UIActivityTreasureFlopRewardPreviewDialog:ctor(root)
  self.super.ctor(self, root)
  root.Type = UIBasePanelType.Dialog
end

function UIActivityTreasureFlopRewardPreviewDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  UIUtils.AddBtnClickListener(self.ui.mBtn_CloseBg.gameObject, function()
    self:CloseSelf()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Close.gameObject, function()
    self:CloseSelf()
  end)
  setactive(self.ui.mTrans_Item.gameObject, false)
end

function UIActivityTreasureFlopRewardPreviewDialog:CloseSelf()
  UIManager.CloseUI(UIDef.UITreasureFlopRewardPreviewDialog)
end

function UIActivityTreasureFlopRewardPreviewDialog:OnInit(root, data)
  function self.OnActivityReset()
    UIUtils.PopupPositiveHintMessage(260010)
    
    UISystem:JumpToMainPanel()
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnDayChange, self.OnActivityReset)
  self.config = data.config
  self:CreateCloseTimer()
end

function UIActivityTreasureFlopRewardPreviewDialog:CreateCloseTimer()
  local now = CGameTime:GetTimestamp()
  self.activityOverTimer = TimerSys:UnscaledDelayCall(UIActivityTreasureItem.closeTime - now, function()
    local topUI = UISystem:GetTopUI(UIGroupType.Default)
    if topUI ~= nil and topUI.UIDefine.UIType ~= UIDef.UITreasureFlopRewardPreviewDialog then
      return
    end
    print("Close By UIActivityTreasureFlopRewardPreviewDialog")
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
    UISystem:JumpToMainPanel()
  end)
end

function UIActivityTreasureFlopRewardPreviewDialog:OnTop()
  local now = CGameTime:GetTimestamp()
  if now > UIActivityTreasureItem.closeTime then
    print("Close By UIActivityTreasureFlopRewardPreviewDialog OnTop")
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
    UISystem:JumpToMainPanel()
  end
end

function UIActivityTreasureFlopRewardPreviewDialog:OnShowStart()
  self:InitRewards()
end

function UIActivityTreasureFlopRewardPreviewDialog:InitRewards()
  self.id = UIActivityTreasureItem.id
  local rewardIds = self.config.RewardId
  local rewardData = {}
  self.rewardData = {}
  self.commonItems = {}
  local total = 0
  for i = 0, rewardIds.Count - 1 do
    local reward = TableDataBase.listBingoRewardDatas:GetDataById(rewardIds[i])
    local rewardType = reward.Type
    if rewardType == 1 then
      table.insert(rewardData, 1, reward)
    else
      table.insert(rewardData, reward)
    end
    total = total + reward.Stock
  end
  local totalCost = NetCmdActivityTreasureData:GetTotalBingoRewardCost(self.id)
  self.ui.mText_Num.text = string_format(TableData.GetHintById(260113), total - totalCost, total)
  for _, v in ipairs(rewardData) do
    local id = v.Id
    local item = instantiate(self.ui.mTrans_Item)
    CS.LuaUIUtils.SetParent(item.gameObject, self.ui.mTrans_Content.gameObject, true)
    table.insert(self.rewardData, item)
    local cost = NetCmdActivityTreasureData:GetBingoRewardCostById(self.id, id)
    local commonItem = UICommonItem.New()
    commonItem:InitCtrl(item)
    commonItem:SetRewardEffect(v.Type == 1)
    table.insert(self.commonItems, commonItem)
    for id, count in pairs(v.RewardItem or {}) do
      local itemData = TableData.GetItemData(id)
      if itemData then
        commonItem:SetItemData(id, count)
        commonItem:SetReceivedIcon(0 >= v.Stock - cost)
      end
      break
    end
    local binding = {}
    self:LuaUIBindTable(item, binding)
    binding.mText_Num.text = string_format(TableData.GetHintById(270113), v.Stock - cost, v.Stock)
    setactivewithcheck(item, true)
  end
end

function UIActivityTreasureFlopRewardPreviewDialog:OnClose()
  self:ClearRewards()
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnDayChange, self.OnActivityReset)
  if self.activityOverTimer ~= nil then
    self.activityOverTimer:Stop()
    self.activityOverTimer = nil
  end
end

function UIActivityTreasureFlopRewardPreviewDialog:ClearRewards()
  self:ReleaseCtrlTable(self.commonItems, true)
  for i = #self.rewardData, 1, -1 do
    local item = self.rewardData[i]
    gfdestroy(item)
    table.remove(self.rewardData, i)
  end
  self.commonItems = nil
  self.rewardData = nil
end

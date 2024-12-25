require("UI.UIBasePanel")
require("UI.DarkZonePanel.UIDarkzoneModeCarrierPanel.Item.UIDarkzoneMapCarrierRewardTab")
require("UI.DarkZonePanel.UIDarkzoneModeCarrierPanel.Item.UIDarkzoneMapCarrierRewardItem")
UIDarkzoneMapCarrierRewardDialog = class("UIDarkzoneMapCarrierRewardDialog", UIBasePanel)
UIDarkzoneMapCarrierRewardDialog.__index = UIDarkzoneMapCarrierRewardDialog
UIDarkzoneMapCarrierRewardDialog.Type = {
  Collect = 1,
  Exchange = 2,
  Raid = 3
}

function UIDarkzoneMapCarrierRewardDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
  csPanel.Is3DPanel = false
end

function UIDarkzoneMapCarrierRewardDialog:OnAwake(root, data)
end

function UIDarkzoneMapCarrierRewardDialog:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.questID = data
  self.questData = TableData.listDzActivityQuestDatas:GetDataById(self.questID)
  self:AddBtnListener()
  self.curClick = 1
  self.collectList = {}
  self.exchangeList = {}
  self.raidList = {}
  self.TabList = {}
  self.activeID = NetCmdActivityDarkZone:GetCurrActivityID(SubmoduleType.ActivityDarkzone, NetCmdActivitySimData.offcialConfigId)
  self.state = NetCmdActivityDarkZone:GetCurrActivityState(NetCmdActivitySimData.offcialConfigId)
  self.activityEntranceData = NetCmdActivityDarkZone:GetActivityEntranceData(NetCmdActivitySimData.offcialConfigId, self.state)
  self.activityConfigData = NetCmdThemeData:GetActivityDataByEntranceId(self.activityEntranceData.id)
  self.activitySubmodeleId = LuaUtils.EnumToInt(SubmoduleType.ActivityDarkzone)
  self:InitContent()
end

function UIDarkzoneMapCarrierRewardDialog:InitContent()
  self.ui.mText_Title.text = TableData.GetActivityHint(271001, self.activityConfigData.Id, 2, self.activitySubmodeleId, self.activeID)
  self.collectTab = UIDarkzoneMapCarrierRewardTab.New()
  self.collectTab:InCtrl(self.ui.mTrans_Tab.childItem, self.ui.mTrans_Tab.transform, function()
    self:OnTabClick(self.Type.Collect)
  end, TableData.GetActivityHint(271006, self.activityConfigData.Id, 2, self.activitySubmodeleId, self.activeID))
  self.exchageTab = UIDarkzoneMapCarrierRewardTab.New()
  self.exchageTab:InCtrl(self.ui.mTrans_Tab.childItem, self.ui.mTrans_Tab.transform, function()
    self:OnTabClick(self.Type.Exchange)
  end, TableData.GetActivityHint(271007, self.activityConfigData.Id, 2, self.activitySubmodeleId, self.activeID))
  table.insert(self.TabList, self.collectTab)
  table.insert(self.TabList, self.exchageTab)
  if self.questData.sweep_control then
    self.raidTab = UIDarkzoneMapCarrierRewardTab.New()
    self.raidTab:InCtrl(self.ui.mTrans_Tab.childItem, self.ui.mTrans_Tab.transform, function()
      self:OnTabClick(self.Type.Raid)
    end, TableData.GetActivityHint(271008, self.activityConfigData.Id, 2, self.activitySubmodeleId, self.activeID))
    table.insert(self.TabList, self.raidTab)
  end
  self.isShowCollectTab = false
  self.isShowExchangeTab = false
  self.isShowRaidTab = false
  self:OnTabClick(self.Type.Collect)
end

function UIDarkzoneMapCarrierRewardDialog:ShowCollect()
  self.isShowCollectTab = true
  for i = 1, 3 do
    local item = UIDarkzoneMapCarrierRewardItem.New()
    item:InitCtrl(self.ui.mScrollList_Reward.childItem, self.ui.mScrollList_Reward.transform)
    item:SetTopText(TableData.GetActivityHint(271008 + i, self.activityConfigData.Id, 2, self.activitySubmodeleId, self.activeID))
    table.insert(self.collectList, item)
  end
  self.collectList[1]:SetRewardDataWithNum(NetCmdActivityDarkZone:GetRewardDataShow(self.questID), self.questID)
  self.collectList[2]:SetRewardData(self.questData.activity_rewardshow)
  self.collectList[3]:SetRewardData(self.questData.explore_rewardshow)
end

function UIDarkzoneMapCarrierRewardDialog:ShowExchange()
  self.isShowExchangeTab = true
  for i = 1, 3 do
    local activityEscortExchangeData = TableData.listActivityEscortExchangeByGoodsTypeDatas:GetDataById(i, true)
    if activityEscortExchangeData ~= nil then
      local itemIdList = activityEscortExchangeData.ItemId
      if itemIdList ~= nil then
        local item = UIDarkzoneMapCarrierRewardItem.New()
        item:InitCtrl(self.ui.mScrollList_Reward.childItem, self.ui.mScrollList_Reward.transform)
        item:CreateExchangeList(itemIdList)
        item:SetTopText(TableData.GetActivityHint(271011 + i, self.activityConfigData.Id, 2, self.activitySubmodeleId, self.activeID))
        table.insert(self.exchangeList, item)
      end
    end
  end
end

function UIDarkzoneMapCarrierRewardDialog:ShowRaid()
  self.isShowRaidTab = true
  local raidIdList = TableData.listActivitySweepRewardBySweepPlanDatas:GetDataById(self.questData.sweep_plan).Id
  for i = 0, raidIdList.Count - 1 do
    local raidData = TableData.listActivitySweepRewardDatas:GetDataById(raidIdList[i])
    if 0 >= raidData.sweep_reward.Value.Count then
      return
    end
    local item = UIDarkzoneMapCarrierRewardItem.New()
    item:InitCtrl(self.ui.mScrollList_Reward.childItem, self.ui.mScrollList_Reward.transform)
    item:SetRaidData(raidData)
    table.insert(self.raidList, item)
  end
end

function UIDarkzoneMapCarrierRewardDialog:OnTabClick(index)
  if index == self.Type.Collect and not self.isShowCollectTab then
    self:ShowCollect()
  elseif index == self.Type.Raid and not self.isShowRaidTab then
    self:ShowRaid()
  elseif index == self.Type.Exchange and not self.isShowExchangeTab then
    self:ShowExchange()
  end
  self.ui.mAnimator_TabIn:SetTrigger("Tab_FadeIn")
  for i = 1, #self.TabList do
    self.TabList[i]:SetBtnInteractable(true)
  end
  self.TabList[index]:SetBtnInteractable(false)
  self.curClick = index
  for i = 1, #self.collectList do
    self.collectList[i]:SetShow(index == self.Type.Collect)
  end
  for i = 1, #self.exchangeList do
    self.exchangeList[i]:SetShow(index == self.Type.Exchange)
  end
  for i = 1, #self.raidList do
    self.raidList[i]:SetShow(index == self.Type.Raid)
  end
  setactive(self.ui.mText_Description, index == self.Type.Exchange or index == self.Type.Raid)
  if index == self.Type.Exchange then
    self.ui.mText_Description.text = TableData.GetActivityHint(271044, self.activityConfigData.Id, 2, self.activitySubmodeleId, self.activeID)
  elseif index == self.Type.Raid then
    self.ui.mText_Description.text = TableData.GetActivityHint(271045, self.activityConfigData.Id, 2, self.activitySubmodeleId, self.activeID)
  end
  setactive(self.ui.mTrans_desc, index ~= self.Type.Collect)
end

function UIDarkzoneMapCarrierRewardDialog:AddBtnListener()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIDarkzoneMapCarrierRewardDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIDarkzoneMapCarrierRewardDialog)
  end
end

function UIDarkzoneMapCarrierRewardDialog:OnShowFinish()
end

function UIDarkzoneMapCarrierRewardDialog:OnClose()
  if self.collectList then
    for i = 1, #self.collectList do
      self.collectList[i]:OnRelease()
    end
  end
  if self.exchangeList then
    for i = 1, #self.exchangeList do
      self.exchangeList[i]:OnRelease()
    end
  end
  if self.raidList then
    for i = 1, #self.raidList do
      self.raidList[i]:OnRelease()
    end
  end
  self.collectTab:OnRelease()
  self.exchageTab:OnRelease()
  if self.raidTab then
    self.raidTab:OnRelease()
  end
end

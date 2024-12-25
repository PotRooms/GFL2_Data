require("UI.UIBasePanel")
require("UI.Common.UIComTopTabItemB")
require("UI.UniTopbar.Item.ResourcesCommonItem")
require("UI.ActivityTreasurePanel.UIActivityTreasureBpRewardSubPanel")
require("UI.ActivityTreasurePanel.UIActivityTreasureBpMissionSubPanel")
UIActivityTreasureBpPanel = class("UIActivityTreasureBpPanel", UIBasePanel)
UIActivityTreasureBpPanel.__index = UIActivityTreasureBpPanel
local totalTime = 0.33

function UIActivityTreasureBpPanel:ctor(root)
  self.super.ctor(self, root)
  self.root = root
end

function UIActivityTreasureBpPanel:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Back.gameObject, function()
    self:ClickBack()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Home.gameObject, function()
    self:ClickHome()
  end)
  self.rewardSubPanel = UIActivityTreasureBpRewardSubPanel.New()
  self.rewardSubPanel:InitCtrl(self.ui.mTrans_Bp)
  self.missionSubPanel = UIActivityTreasureBpMissionSubPanel.New()
  self.missionSubPanel:InitCtrl(self.ui.mTrans_Mission)
end

function UIActivityTreasureBpPanel:RegisterEvent()
  function self.OnBuyLevelSuccessCallback()
    self:OnBuyLevelSuccess()
  end
  
  MessageSys:AddListener(UIEvent.OnTreasureBuyLevel, self.OnBuyLevelSuccessCallback)
  
  function self.onQuestReceived()
    self.missionSubPanel:RefreshMissionStatus()
    self:OnMissionComplete()
  end
  
  MessageSys:AddListener(UIEvent.OnTreasureMissionComplete, self.onQuestReceived)
  
  function self.OnActivityReset()
    UIUtils.PopupPositiveHintMessage(260010)
    UISystem:JumpToMainPanel()
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnDayChange, self.OnActivityReset)
end

function UIActivityTreasureBpPanel:ClickBack()
  UIManager.CloseUI(UIDef.UITreasureBpPanel)
end

function UIActivityTreasureBpPanel:ClickHome()
  UISystem:JumpToMainPanel()
end

function UIActivityTreasureBpPanel:ClickBuy()
end

function UIActivityTreasureBpPanel:OnInit(root, data)
  self.id = UIActivityTreasureItem.id
  local activityConfig = TableDataBase.listActivityListDatas:GetDataById(self.id)
  if activityConfig ~= nil then
    setactivewithcheck(self.ui.mText_time, activityConfig.permanent ~= 1)
    if activityConfig.permanent ~= 1 then
      self.ui.mText_time:StartCountdown(UIActivityTreasureItem.closeTime)
    end
  end
  self:RefreshUI()
  self:InitCurrency()
  self:InitTabs()
  self.defaultTab = data ~= nil and data[0] == 2 and "mission" or "reward"
  self.first = true
  self:RegisterEvent()
  self:CreateCloseTimer()
end

function UIActivityTreasureBpPanel:CreateCloseTimer()
  local now = CGameTime:GetTimestamp()
  self.activityOverTimer = TimerSys:UnscaledDelayCall(UIActivityTreasureItem.closeTime - now, function()
    local topUI = UISystem:GetTopUI(UIGroupType.Default)
    if topUI ~= nil and topUI.UIDefine.UIType ~= UIDef.UITreasureBpPanel then
      return
    end
    print("Close By UIActivityTreasureBpPanel")
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
    UISystem:JumpToMainPanel()
  end)
end

function UIActivityTreasureBpPanel:OnTop()
  local now = CGameTime:GetTimestamp()
  if now > UIActivityTreasureItem.closeTime then
    print("Close By UIActivityTreasureBpPanel OnTop")
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
    UISystem:JumpToMainPanel()
  end
end

function UIActivityTreasureBpPanel:OnShowFinish()
  if self.first then
    self.selectedTab = self.defaultTab == "mission" and self.tabs.reward or self.tabs.mission
    self:EnableTab(self.defaultTab)
    self.defaultTab = nil
    self.first = false
  end
end

function UIActivityTreasureBpPanel:RefreshUI()
  local bpLevel = NetCmdActivityTreasureData:GetBpLevel(self.id)
  local lv1 = math.floor(bpLevel / 10)
  local lv2 = bpLevel % 10
  self.ui.mText_Lv.text = "<color=#ddc68eff>" .. lv1 .. "</color><color=#faedcdff>" .. lv2 .. "</color>"
  self.currentLv = bpLevel
  local bpId = TableDataBase.listTreasureMainDatas:GetDataById(self.id).BpId
  local maxLv = TableDataBase.listTreasureConfigDatas:GetDataById(bpId).MaxLevel
  self.reachMaxLv = bpLevel >= maxLv
  setactivewithcheck(self.ui.mBtn_Buy.gameObject, false)
  setactivewithcheck(self.ui.mTrans_FullLv.gameObject, self.reachMaxLv)
  local currentExp = NetCmdActivityTreasureData:GetBpExp(self.id)
  local maxExp = TableDataBase.listTreasureConfigDatas:GetDataById(bpId).UpgradeExp
  self.ui.mText_Progress.text = (self.reachMaxLv and maxExp or currentExp) .. "/" .. maxExp
  self.ui.mImg_Progress.fillAmount = self.reachMaxLv and 1 or currentExp / maxExp
  self.ui.mImg_Progress2.fillAmount = self.ui.mImg_Progress.fillAmount
  self.expBefore = currentExp
end

function UIActivityTreasureBpPanel:InitCurrency()
  local resources = TableData.GetResourcesBarData(UIDef.UITreasureBpPanel).resources
  self.root.TopResourceBar.UITopResourceBar:Init(true)
  self.root.TopResourceBar.UITopResourceBar:UpdateCurrencyContent(resources)
end

function UIActivityTreasureBpPanel:InitTabs()
  self.rewardTab = UIComTopTabItemB.New()
  self.rewardTab:InitCtrl(self.ui.mTrans_Tab, {
    name = TableData.GetHintById(260123)
  })
  self.rewardTab:AddClickListener(function()
    self.ui.mRoot_Animator:SetTrigger("Tab_FadeIn")
    self:EnableTab("reward")
  end)
  self.rewardTab:SetRedPointVisible(NetCmdActivityTreasureData:CheckBpReward(self.id) > 0)
  self.rewardSubPanel:SetTab(self.rewardTab)
  self.missionTab = UIComTopTabItemB.New()
  self.missionTab:InitCtrl(self.ui.mTrans_Tab, {
    name = TableData.GetHintById(260124)
  })
  self.missionTab:AddClickListener(function()
    self.ui.mRoot_Animator:SetTrigger("Tab_FadeIn")
    self:EnableTab("mission")
  end)
  self.missionTab:SetRedPointVisible(0 < NetCmdActivityTreasureData:CheckBpMission(self.id))
  self.missionSubPanel:SetTab(self.missionTab)
  self.tabs = {
    reward = {
      tab = self.rewardTab,
      subPanel = self.rewardSubPanel
    },
    mission = {
      tab = self.missionTab,
      subPanel = self.missionSubPanel
    }
  }
end

function UIActivityTreasureBpPanel:EnableTab(key)
  if self.selectedTab then
    self.selectedTab.tab:SetBtnInteractable(true)
    self.selectedTab.subPanel:DisableSubPanel()
  end
  self.selectedTab = self.tabs[key]
  self.selectedTab.tab:SetBtnInteractable(false)
  self.selectedTab.subPanel:EnableSubPanel(self.id)
end

function UIActivityTreasureBpPanel:OnBuyLevelSuccess()
  self:OnMissionComplete()
end

function UIActivityTreasureBpPanel:OnMissionComplete()
  if self.reachMaxLv then
    return
  end
  self:StopTimer()
  self:KillFillTween()
  self.tweenList = {}
  local currentExp = NetCmdActivityTreasureData:GetBpExp(self.id)
  local bpId = TableDataBase.listTreasureMainDatas:GetDataById(self.id).BpId
  local maxExp = TableDataBase.listTreasureConfigDatas:GetDataById(bpId).UpgradeExp
  local bpLevel = NetCmdActivityTreasureData:GetBpLevel(self.id)
  if self.currentLv ~= bpLevel then
    local t1 = (1 - self.expBefore / maxExp) * totalTime
    local t2 = currentExp / maxExp * totalTime
    local tween = CS.UITweenManager.PlayImageFillAmount(self.ui.mImg_Progress, self.expBefore / maxExp, 1, t1, 1, function()
      local tween1 = CS.UITweenManager.PlayImageFillAmount(self.ui.mImg_Progress, 0, currentExp / maxExp, t2, 1, function()
        self:LevelUpPerformance()
      end)
      table.insert(self.tweenList, tween1)
    end)
    table.insert(self.tweenList, tween)
    local tween2 = CS.UITweenManager.PlayImageFillAmount(self.ui.mImg_Progress2, self.expBefore / maxExp, 1, t1, 1, function()
      local tween3 = CS.UITweenManager.PlayImageFillAmount(self.ui.mImg_Progress2, 0, currentExp / maxExp, t2, 1)
      table.insert(self.tweenList, tween3)
    end)
    table.insert(self.tweenList, tween2)
  else
    local before = self.expBefore / maxExp
    local after = currentExp / maxExp
    local tween = CS.UITweenManager.PlayImageFillAmount(self.ui.mImg_Progress, before, after, (after - before) * totalTime, 1, function()
      self:RefreshUI()
    end)
    table.insert(self.tweenList, tween)
    local tween1 = CS.UITweenManager.PlayImageFillAmount(self.ui.mImg_Progress2, before, after, (after - before) * totalTime, 1)
    table.insert(self.tweenList, tween1)
  end
end

function UIActivityTreasureBpPanel:LevelUpPerformance()
  self.ui.mRoot_Animator:SetTrigger("LvUp")
  local oldLevel = self.currentLv
  local newLevel = NetCmdActivityTreasureData:GetBpLevel(self.id)
  self.timer1 = TimerSys:DelayFrameCall(6, function()
    self:RefreshUI()
  end)
  self.timer2 = TimerSys:DelayCall(1, function()
    self.rewardSubPanel:RefreshRewardStatus()
    MessageSys:SendMessage(UIEvent.OnTreasureLevelRewardRefresh, nil, {from = oldLevel, to = newLevel})
  end)
end

function UIActivityTreasureBpPanel:KillFillTween()
  if self.tweenList ~= nil then
    for i = #self.tweenList, 1, -1 do
      local tween = self.tweenList[i]
      if tween then
        CS.UITweenManager.TweenKill(tween)
        table.remove(self.tweenList, i)
      end
    end
  end
  self.tweenList = nil
end

function UIActivityTreasureBpPanel:StopTimer()
  if self.timer1 ~= nil then
    self.timer1:Stop()
    self.timer1 = nil
  end
  if self.timer2 ~= nil then
    self.timer2:Stop()
    self.timer2 = nil
  end
  if self.activityOverTimer ~= nil then
    self.activityOverTimer:Stop()
    self.activityOverTimer = nil
  end
end

function UIActivityTreasureBpPanel:OnActivityFinished()
  CS.PopupMessageManager.PopupString(TableData.GetHintById(260044))
  UIManager.CloseUI(UIDef.UITreasureBpPanel)
end

function UIActivityTreasureBpPanel:ClearTabs()
  for _, v in pairs(self.tabs) do
    local tab = v.tab
    tab:OnRelease()
    local subPanel = v.subPanel
    subPanel:DisableSubPanel()
  end
  self.tabs = nil
  self.selectedTab = nil
end

function UIActivityTreasureBpPanel:OnClose()
  self:UnregisterEvent()
  self:StopTimer()
  self:KillFillTween()
  self:ClearTabs()
end

function UIActivityTreasureBpPanel:UnregisterEvent()
  MessageSys:RemoveListener(UIEvent.OnTreasureBuyLevel, self.OnBuyLevelSuccessCallback)
  MessageSys:RemoveListener(UIEvent.OnTreasureMissionComplete, self.onQuestReceived)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnDayChange, self.OnActivityReset)
end

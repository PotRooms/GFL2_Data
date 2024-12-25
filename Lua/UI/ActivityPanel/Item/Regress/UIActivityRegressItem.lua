local color_time_simcombat_over = Color(0.3294, 0.3294, 0.3294, 0.9)
local color_time_simcombat_not_over = Color(0.3608, 0.4471, 0.6, 0.85)
local color_time_target_over = Color(0.3294, 0.3294, 0.3294, 90)
local color_time_target_not_over = Color(0.102, 0.1725, 0.2, 0.64)
UIActivityRegressItem = class("UIActivityRegressItem", UIActivityItemBase)
UIActivityRegressItem.__index = UIActivityRegressItem

function UIActivityRegressItem:OnInit()
  self:RegisterEvent()
end

function UIActivityRegressItem:OnShow()
  self.ui.mText_Info.text = self.mActivityTableData.desc.str
  self.mOpenTime = NetCmdActivityRegressData:GetOpenTime()
  self.mCloseTime = NetCmdActivityRegressData:GetCloseTime()
  self:UpdateText(self.ui.mText_Time, self.mCloseTime)
  local day = TableDataBase.listBackTimeConfigDatas:GetDataById(1).UpTime
  self:UpdateText(self.ui.mText_TimeSimCombat, self.mOpenTime + 86400 * day)
  local day2 = TableDataBase.listBackTimeConfigDatas:GetDataById(1).TaskTime
  self:UpdateText(self.ui.mText_TimeTarget, self.mOpenTime + 86400 * day2)
  UIUtils.AddBtnClickListener(self.ui.mBtn_SimCombat.gameObject, function()
    self:OnSimCombatClick()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Target.gameObject, function()
    self:OnTargetClick()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Reward.gameObject, function()
    self:OnRewardClick()
  end)
  self.activityIsOver = NetCmdActivityRegressData:IsActivityOver()
  self.upActivityIsOver = NetCmdActivityRegressData:IsUpOver()
  self.taskActivityIsOver = NetCmdActivityRegressData:IsTaskOver()
  self:SetTargetBtnColor()
  self:SetSimCombatBtnColor()
  self:RefreshUpCounts()
  self:RefreshRedPoint()
  self:TryOpenQuest()
end

function UIActivityRegressItem:OnTop()
  self.activityIsOver = NetCmdActivityRegressData:IsActivityOver()
  self.upActivityIsOver = NetCmdActivityRegressData:IsUpOver()
  self.taskActivityIsOver = NetCmdActivityRegressData:IsTaskOver()
  self:SetTargetBtnColor()
  self:SetSimCombatBtnColor()
  self:RefreshUpCounts()
  self:RefreshRedPoint()
  self:TryOpenQuest()
end

function UIActivityRegressItem:RegisterEvent()
  function self.ItemUpdateHandler()
    self:RefreshUpCounts()
  end
  
  MessageSys:AddListener(CS.GF2.Message.CommonEvent.ItemUpdate, self.ItemUpdateHandler)
  
  function self.onActivityOver()
    self.activityIsOver = true
    self.upActivityIsOver = true
    self.taskActivityIsOver = true
    self:SetSimCombatBtnColor()
    self:SetTargetBtnColor()
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnRegressOver, self.onActivityOver)
  
  function self.onUpActivityOver()
    self.upActivityIsOver = true
    self:SetSimCombatBtnColor()
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnRegressUpOver, self.onUpActivityOver)
  
  function self.onTaskActivityOver()
    self.taskActivityIsOver = true
    self:SetTargetBtnColor()
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnRegressTaskOver, self.onTaskActivityOver)
end

function UIActivityRegressItem:OnSimCombatClick()
  if self.activityIsOver then
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260044))
    return
  end
  if self.upActivityIsOver then
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260044))
    return
  end
  local showData = CS.ShowBattleIndexData()
  showData.Regress = true
  UIManager.OpenUIByParam(enumUIPanel.UIBattleIndexPanel, showData)
end

function UIActivityRegressItem:UpdateText(text, close)
  text:StartCountdown(close)
end

function UIActivityRegressItem:OnTargetClick()
  if self.activityIsOver then
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260044))
    return
  end
  if self.taskActivityIsOver then
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260044))
    return
  end
  UIManager.OpenUIByParam(UIDef.UIRegressQuestDialog, {
    closeTime = self.mCloseTime
  })
end

function UIActivityRegressItem:SetSimCombatBtnColor()
  if self.upActivityIsOver then
    setactivewithcheck(self.ui.mText_Num, false)
    self.ui.mText_Remain.text = TableData.GetHintById(260170)
  end
  self.ui.mImg_SimCombat.color = self.upActivityIsOver and color_time_simcombat_over or color_time_simcombat_not_over
end

function UIActivityRegressItem:OnRewardClick()
  UIManager.OpenUI(UIDef.UIRegressActivityRewardDialog)
end

function UIActivityRegressItem:SetTargetBtnColor()
  self.ui.mImg_Target.color = self.taskActivityIsOver and color_time_target_over or color_time_target_not_over
end

function UIActivityRegressItem:RefreshUpCounts()
  if self.upActivityIsOver then
    return
  end
  self.upMax = NetCmdActivityRegressData:GetActivityUpCountMax()
  self.current = NetCmdActivityRegressData:GetActivityUpCountCurrent()
  if self.current > 0 then
    setactivewithcheck(self.ui.mText_Num, true)
    self.ui.mText_Remain.text = TableData.GetHintById(260074)
    self.ui.mText_Num.text = "<color=#F36814>" .. self.current .. "</color>/" .. self.upMax
  else
    setactivewithcheck(self.ui.mText_Num, false)
    self.ui.mText_Remain.text = TableData.GetHintById(260170)
  end
end

function UIActivityRegressItem:RefreshRedPoint()
  local redPoint = NetCmdActivityRegressData:CheckOneTimeRewardAndCheckIn() + NetCmdActivityRegressData:CheckDailyCheckIn()
  setactive(self.ui.mTrans_RedPoint.gameObject, 0 < redPoint)
  local data = NetCmdActivityRegressData:GetActivityBackInfo()
  local complete = data.OneTimeRewardClaimed and data.CheckinDays >= 7
  setactive(self.ui.mTrans_Complete.gameObject, complete)
  local taskRedPoint = NetCmdActivityRegressData:CheckTaskReward() + NetCmdActivityRegressData:CheckStepsReward()
  setactive(self.ui.mTrans_TaskRedPoint.gameObject, 0 < taskRedPoint)
end

function UIActivityRegressItem:OnHide()
end

function UIActivityRegressItem:UnregisterEvent()
  MessageSys:RemoveListener(CS.GF2.Message.CommonEvent.ItemUpdate, self.ItemUpdateHandler)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnRegressOver, self.onActivityOver)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnRegressUpOver, self.onUpActivityOver)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnRegressTaskOver, self.onTaskActivityOver)
end

function UIActivityRegressItem:OnClose()
  UIActivityRegressItem.openQuest = false
  self:UnregisterEvent()
end

function UIActivityRegressItem:CloseTrigger()
  self.ui.mAnimator_Root:SetTrigger("FadeOut")
end

function UIActivityRegressItem:TryOpenQuest()
  if UIActivityRegressItem.openQuest then
    UIActivityRegressItem.openQuest = false
    self:OnTargetClick()
  end
end

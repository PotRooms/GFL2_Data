require("UI.UIBasePanel")
require("UI.DarkZonePanel.UIDarkzoneModeCarrierPanel.Item.UIDarkzoneModeCarrierItem")
require("UI.ActivityTheme.Cafe.ActivityCafeGlobal")
UIDarkzoneModeCarrierPanel = class("UIDarkzoneModeCarrierPanel", UIBasePanel)
UIDarkzoneModeCarrierPanel.__index = UIDarkzoneModeCarrierPanel

function UIDarkzoneModeCarrierPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function UIDarkzoneModeCarrierPanel:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListener()
  ActivityCafeGlobal.IsNeedOpenMessageBox = false
  NetCmdActivitySimData.IsOpenCarrierPanel = true
  NetCmdActivitySimData.NeedLoadTeam = true
  ActivityCafeGlobal.LoadFinish = false
  if data ~= nil then
    NetCmdActivitySimData.NeedLoadTeam = data
    ActivityCafeGlobal.LoadFinish = true
  end
  self.activeID = NetCmdActivityDarkZone:GetCurrActivityID(SubmoduleType.ActivityDarkzone, NetCmdActivitySimData.offcialConfigId)
  self.curPhaseID = NetCmdActivityDarkZone:GetCurrentPhase(NetCmdActivitySimData.offcialConfigId)
  self.isStopUpdateAnimation = false
  if self.isTimeFinishTimer then
    self.isTimeFinishTimer:Stop()
    self.isTimeFinishTimer = nil
  end
  self.isTimeFinishTimer = TimerSys:DelayCall(1, function()
    self.isStopUpdateAnimation = true
  end)
  self.prefabQuestList = {
    [1] = {
      name = "GrpEasy",
      prefabParent = self.ui.mTrans_QuestEasy
    },
    [2] = {
      name = "GrpNormal",
      prefabParent = self.ui.mTrans_QuestNormal
    },
    [3] = {
      name = "GrpHard",
      prefabParent = self.ui.mTrans_QuestHard
    },
    [4] = {
      name = "GrpHardest",
      prefabParent = self.ui.mTrans_QuestHardest
    }
  }
  self.showItemTimerList = {}
  self.btnList = {}
  self.state = NetCmdActivityDarkZone:GetCurrActivityState(NetCmdActivitySimData.offcialConfigId)
  if self.state ~= ActivitySimState.Official then
    ActivityCafeGlobal.IsNeedOpenMessageBox = true
    return
  end
  self.activePhaseList = TableData.listDzActivityPhaseByActivityDzDatas:GetDataById(self.activeID).Id
  self:GetCloseTime()
  self.activityEntranceData = NetCmdActivityDarkZone:GetActivityEntranceData(NetCmdActivitySimData.offcialConfigId, self.state)
  self.activityConfigData = NetCmdThemeData:GetActivityDataByEntranceId(self.activityEntranceData.id)
  self.activityModuleData = TableData.listActivityModuleDatas:GetDataById(self.activityEntranceData.module_id)
  self.plan = TableData.listPlanDatas:GetDataById(self.activityEntranceData.plan_id)
  self.isFirst = true
  self.activityTKey = LuaUtils.EnumToInt(SubmoduleType.ActivityDarkzone)
  self.activityTValue = self.activeID
  self:CreateButton()
  self.enterSceneType = SceneSys.CurrentAdditiveSceneType
end

function UIDarkzoneModeCarrierPanel:AddBtnListener()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    if NetCmdActivitySimData.IsOpenCafeMain then
      if self.loadTeamTimer then
        self.loadTeamTimer:Stop()
        self.loadTeamTimer = nil
      end
      UIManager.CloseUI(UIDef.UIDarkzoneModeCarrierPanel)
    else
      UIManager.CloseUI(UIDef.UIDarkzoneModeCarrierPanel)
    end
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Cafe.gameObject).onClick = function()
    if NetCmdActivitySimData.IsOpenCafeMain then
      if self.loadTeamTimer then
        self.loadTeamTimer:Stop()
        self.loadTeamTimer = nil
      end
      UIManager.CloseUI(UIDef.UIDarkzoneModeCarrierPanel)
    else
      UIManager.OpenUIByParam(UIDef.UIActivityCafeMainPanel, {
        activityEntranceData = self.activityEntranceData,
        activityModuleData = self.activityModuleData,
        activityConfigData = self.activityConfigData
      })
    end
  end
  
  function self.unloadTeam()
  end
  
  MessageSys:AddListener(UIEvent.DzTeamUnload, self.unloadTeam)
end

function UIDarkzoneModeCarrierPanel:CreateButton()
  for i = 0, self.activePhaseList.Count - 1 do
    local phase = TableData.listDzActivityPhaseDatas:GetDataById(self.activePhaseList[i])
    local id = phase.Id
    local btnData = {}
    local btn = instantiate(self.ui.mTrans_TabBar.childItem, self.ui.mTrans_TabBar.transform)
    local btnui = {}
    self:LuaUIBindTable(btn, btnui)
    UIUtils.GetButtonListener(btnui.mBtn_Quest.gameObject).onClick = function()
      self.ui.mAnimator_Root:SetTrigger("Switch")
      self.ui.mAnimator_Root:SetInteger("Difficulty", i)
      self:BtnClick(id)
    end
    btnui.mQuest_Name.text = phase.model_title.str
    btnData.btnUI = btnui
    btnData.BtnPrefab = btn
    btnData.phaseData = phase
    btnData.GrpList = {}
    btnData.animateState = i
    btnData.TransPrefabParent = self.prefabQuestList[i + 1].prefabParent
    btnData.isUnlock = self:CheckBtnUnlock(id)
    btnData.TimeCount = self:GetBtnTimeCount(id)
    btnData.preUnLock = btnData.isUnlock
    if 0 < btnData.TimeCount then
      btnData.Timer = TimerSys:DelayCall(1, function()
        local preUnLock = btnData.preUnLock
        local nowUnlock = self:CheckBtnUnlock(btnData.phaseData.id)
        local phase = TableData.listDzActivityPhaseDatas:GetDataById(self.curPhaseID)
        local simGrade = TableData.listSimGradeDatas:GetDataById(phase.unlock_rate)
        local levelLockStr = string_format(TableData.GetActivityHint(271028, self.activityConfigData.Id, 2, self.activityTKey, self.activityTValue), simGrade.grade_name)
        if self.curPhaseID == phase.Id and nowUnlock and not preUnLock then
          self:BtnClick(self.curPhaseID)
        elseif self:CheckBtnTimeCondition(self.curPhaseID) then
          self.ui.mText_Lock.text = levelLockStr
        else
          local timeLockStr = string_format(TableData.GetHintById(271099), self:GetTimeConditionText(self.curPhaseID))
          if NetCmdActivityDarkZone:CheckBtnPhaseLevelCondition(self.curPhaseID) then
            self.ui.mText_Lock.text = timeLockStr
          else
            self.ui.mText_Lock.text = string_format(TableData.GetHintById(271312), simGrade.grade_name, self:GetTimeConditionText(self.curPhaseID))
          end
        end
        btnData.preUnLock = nowUnlock
      end, nil, btnData.TimeCount)
    else
      btnData.Timer = nil
    end
    btnui.mAni_BtnItem.keepAnimatorControllerStateOnDisable = true
    btnData.isFinish = self:CheckBtnFinish(id)
    btnui.mBtn_Quest.interactable = self.curPhaseID ~= id
    self.btnList[id] = btnData
    setactive(btnData.btnUI.mTrans_Compelete, btnData.isFinish)
  end
end

function UIDarkzoneModeCarrierPanel:InitContent()
  self:BtnClick(self.curPhaseID)
end

function UIDarkzoneModeCarrierPanel:DestoryPrefabList(btn)
  for i = 1, #btn.GrpList do
    local item = btn.GrpList[i]
    if item then
      item:OnRelease()
    end
  end
  btn.GrpList = {}
end

function UIDarkzoneModeCarrierPanel:PlayFadeInItem(prefabList)
  for i = 1, #prefabList do
    prefabList[i]:PlayFadeIn()
  end
end

function UIDarkzoneModeCarrierPanel:GetPrefabList(parentTrans, name, prefabList, len)
  for i = 1, len do
    local item = prefabList[i]
    if item == nil then
      item = UIDarkzoneModeCarrierItem.New()
      local prefab = parentTrans:Find(name .. tostring(i))
      if prefab == nil then
        gferror("\233\162\132\229\136\182\228\189\147\228\184\138\231\154\132\228\189\141\231\189\174\230\149\176\233\135\143\229\146\140\232\161\168\233\135\140\228\184\141\228\184\128\232\135\180")
        return
      end
      item:InitCtrl(prefab:GetComponent(typeof(ScrollListChild)).childItem, prefab)
      table.insert(prefabList, item)
    end
  end
end

function UIDarkzoneModeCarrierPanel:BtnClick(phaseID)
  for i, btn in pairs(self.btnList) do
    self:DestoryPrefabList(btn)
  end
  local btnData = self.btnList[phaseID]
  if btnData == nil then
    return
  end
  if #btnData.GrpList == 0 then
    self:GetPrefabList(self.prefabQuestList[phaseID].prefabParent, self.prefabQuestList[phaseID].name, btnData.GrpList, btnData.phaseData.dz_activity_quest.Count)
  end
  self.btnList[self.curPhaseID].btnUI.mBtn_Quest.interactable = true
  self.btnList[phaseID].btnUI.mBtn_Quest.interactable = false
  self.curPhaseID = phaseID
  self:CloseBtnList()
  self:SetPhaseListData(phaseID)
  self:ShowCurPhaseList(phaseID)
  self:PlayFadeInItem(self.btnList[phaseID].GrpList)
  setactive(self.ui.mTrans_RoundEffect, self.btnList[phaseID].isUnlock)
  setactive(self.ui.mTrans_ImgLight, self.btnList[phaseID].isUnlock)
end

function UIDarkzoneModeCarrierPanel:ShowCurPhaseList(phaseID)
  NetCmdActivityDarkZone:SetPhaseUnlockKey(phaseID, self.activityConfigData.id)
  setactive(self.btnList[phaseID].TransPrefabParent, true)
  local isUnlock = self:CheckBtnUnlock(phaseID)
  if not isUnlock then
    local phase = TableData.listDzActivityPhaseDatas:GetDataById(self.curPhaseID)
    local simGrade = TableData.listSimGradeDatas:GetDataById(phase.unlock_rate)
    local levelLockStr = string_format(TableData.GetActivityHint(271028, self.activityConfigData.Id, 2, self.activityTKey, self.activityTValue), simGrade.grade_name)
    local timeLockStr = string_format(TableData.GetHintById(271099), self:GetTimeConditionText(self.curPhaseID))
    if NetCmdActivityDarkZone:CheckBtnPhaseLevelCondition(self.curPhaseID) then
      self.ui.mText_Lock.text = timeLockStr
    elseif self:CheckBtnTimeCondition(self.curPhaseID) then
      self.ui.mText_Lock.text = levelLockStr
    else
      self.ui.mText_Lock.text = string_format(TableData.GetHintById(271312), simGrade.grade_name, self:GetTimeConditionText(self.curPhaseID))
    end
  end
  setactive(self.ui.mTrans_Locked, not isUnlock)
  setactive(self.ui.mTrans_GrpQuestMode, isUnlock)
  self:UpdateBtnLock()
  self:UpdateBtnRedPoint()
end

function UIDarkzoneModeCarrierPanel:SetPhaseListData(phaseID, isDelay)
  local btn = self.btnList[phaseID]
  self:SetQuestItemData(btn.GrpList, btn.phaseData.dz_activity_quest, btn.animateState)
  self.isSet = true
end

function UIDarkzoneModeCarrierPanel:SetQuestItemData(prefabList, dz_activity_quest, animateState)
  for i = 0, dz_activity_quest.Count - 1 do
    if #prefabList >= i + 1 then
      prefabList[i + 1]:SetData(dz_activity_quest[i], self.curPhaseID, animateState, self.activityConfigData.id, function()
      end)
    end
  end
end

function UIDarkzoneModeCarrierPanel:UpdatePhaseListData(phaseID)
  local btn = self.btnList[phaseID]
  self:UpdateQuestItemData(btn.GrpList, btn.phaseData.dz_activity_quest, btn.animateState)
end

function UIDarkzoneModeCarrierPanel:UpdateQuestItemData(prefabList, dz_activity_quest, animateState)
  for i = 0, dz_activity_quest.Count - 1 do
    if #prefabList >= i + 1 and prefabList[i + 1].state ~= animateState then
      prefabList[i + 1]:SetData(dz_activity_quest[i], self.curPhaseID, animateState, self.activityConfigData.id, function()
      end)
    end
  end
end

function UIDarkzoneModeCarrierPanel:OnUpdate()
  if self.isSet or not self.isStopUpdateAnimation then
    self:UpdateState(self.curPhaseID)
  end
end

function UIDarkzoneModeCarrierPanel:UpdateState(phaseID)
  local btn = self.btnList[phaseID]
  local flag = true
  if btn and btn.GrpList then
    for i = 1, #btn.GrpList do
      local aniFinish = btn.GrpList[i]:UpdateAnimationState(btn.animateState)
      flag = flag and aniFinish
    end
    if flag then
      self.isSet = false
    end
  end
end

function UIDarkzoneModeCarrierPanel:OnRecover()
  local cachePhase = NetCmdActivityDarkZone.cachePhaseID
  if cachePhase == 0 then
    return
  end
  self:BtnClick(cachePhase)
  if ActivityCafeGlobal.cacheOpenDarkzone ~= nil then
    NetCmdActivitySimData.IsOpenDarkzone = ActivityCafeGlobal.cacheOpenDarkzone
    ActivityCafeGlobal.cacheOpenDarkzone = nil
  end
  self.isRecover = true
end

function UIDarkzoneModeCarrierPanel:UpdateBtnRedPoint()
  for i = 1, #self.btnList do
    local btnData = self.btnList[i]
    setactive(btnData.btnUI.mTrans_RedPoint, NetCmdActivityDarkZone:GetRedPointByPhaseId(self.btnList[i].phaseData.Id, self.activityConfigData.id))
  end
end

function UIDarkzoneModeCarrierPanel:UpdateBtnLock()
  for i = 1, #self.btnList do
    local btnData = self.btnList[i]
    btnData.isUnlock = self:CheckBtnUnlock(self.btnList[i].phaseData.Id)
    btnData.btnUI.mAni_BtnItem:SetBool("Locked", not btnData.isUnlock)
  end
end

function UIDarkzoneModeCarrierPanel:CheckBtnFinish(phaseID)
  local phase = TableData.listDzActivityPhaseDatas:GetDataById(phaseID)
  local flag = true
  for i = 0, phase.dz_activity_quest.Count - 1 do
    local id = phase.dz_activity_quest[i]
    local stageInfo = NetCmdActivityDarkZone:GetDarkZoneStageInfo(id)
    flag = flag and stageInfo ~= nil and stageInfo.state == 1
  end
  return flag
end

function UIDarkzoneModeCarrierPanel:CheckBtnUnlock(phaseID)
  local isLevelUnlock = NetCmdActivityDarkZone:CheckBtnPhaseLevelCondition(phaseID)
  local isTimeOpen = self:CheckBtnTimeCondition(phaseID)
  return isLevelUnlock and isTimeOpen
end

function UIDarkzoneModeCarrierPanel:CheckBtnTimeCondition(phaseID)
  local nowTime = CGameTime:GetTimestamp()
  local openTime = self:GetBtnOpenTime(phaseID)
  return nowTime >= openTime
end

function UIDarkzoneModeCarrierPanel:GetTimeConditionText(phaseID)
  local openTime = self:GetBtnOpenTime(phaseID)
  return CS.TimeUtils.GetLeftTime(openTime)
end

function UIDarkzoneModeCarrierPanel:GetBtnTimeCount(phaseID)
  local nowTime = CGameTime:GetTimestamp()
  local openTime = self:GetBtnOpenTime(phaseID)
  return openTime - nowTime
end

function UIDarkzoneModeCarrierPanel:GetBtnOpenTime(phaseID)
  return self.plan.OpenTime + TableData.listDzActivityPhaseDatas:GetDataById(phaseID).UnlockDaynum * 60
end

function UIDarkzoneModeCarrierPanel:OnSave()
  ActivityCafeGlobal.cacheOpenDarkzone = NetCmdActivitySimData.IsOpenDarkzone
end

function UIDarkzoneModeCarrierPanel:OnShowFinish()
  local diff = 1
  if self.activePhaseList == nil then
    return
  end
  for i = 0, self.activePhaseList.Count - 1 do
    if self.curPhaseID == self.activePhaseList[i] then
      diff = i
    end
  end
  self.ui.mAnimator_Root:SetInteger("Difficulty", diff)
  if NetCmdActivitySimData.NeedLoadTeam and self.isFirst then
    if self.loadTeamTimer then
      self.loadTeamTimer:Stop()
      self.loadTeamTimer = nil
    end
    if self.isRecover then
      self:OnFromCafe()
    else
      self.loadTeamTimer = TimerSys:DelayCall(0.33, function()
        self:OnFromCafe()
        self.loadTeamTimer = nil
      end)
    end
  end
  if self.isRecover then
    self.isRecover = false
    TimerSys:DelayCall(0.5, function()
      self:BtnClick(self.curPhaseID)
    end)
  end
end

function UIDarkzoneModeCarrierPanel:OnShowStart()
  NetCmdActivityDarkZone:UpdateUnlockList(self.activityConfigData.id)
  self.newUnlockList = NetCmdActivityDarkZone:GetNewUnlockList()
  self.newUnlockList:Sort()
  if self.newUnlockList.Count >= 1 then
    local phaseID = NetCmdActivityDarkZone:GetPhaseByQuestID(self.activityConfigData.id, self.newUnlockList[0])
    local quest = TableData.listDzActivityQuestDatas:GetDataById(self.newUnlockList[0])
    PopupMessageManager.PopupDZStateChangeString(string_format(TableData.GetActivityHint(271307, self.activityConfigData.Id, 2, self.activityTKey, self.activityTValue), quest.quest_name.str))
    self.curPhaseID = phaseID
    NetCmdActivityDarkZone:ClearNewUnlockList()
  end
  self:InitContent()
  for i = 1, #self.btnList do
    local btn = self.btnList[i]
    btn.btnUI.mAni_BtnItem:SetBool("Locked", not btn.isUnlock)
  end
end

function UIDarkzoneModeCarrierPanel:OnBackFrom()
  if self.closeTime then
    self:CreateStageChangeTimer()
  end
  NetCmdActivityDarkZone:UpdateUnlockList(self.activityConfigData.id)
  self.newUnlockList = NetCmdActivityDarkZone:GetNewUnlockList()
  self.newUnlockList:Sort()
  if self.newUnlockList.Count >= 1 then
    local phaseID = NetCmdActivityDarkZone:GetPhaseByQuestID(self.activityConfigData.id, self.newUnlockList[0])
    local quest = TableData.listDzActivityQuestDatas:GetDataById(self.newUnlockList[0])
    PopupMessageManager.PopupDZStateChangeString(string_format(TableData.GetActivityHint(271307, self.activityConfigData.Id, 2, self.activityTKey, self.activityTValue), quest.quest_name.str))
    self:BtnClick(phaseID)
    NetCmdActivityDarkZone:ClearNewUnlockList()
  end
  self:ShowCurPhaseList(self.curPhaseID)
  self:UpdatePhaseListData(self.curPhaseID)
  self:PlayFadeInItem(self.btnList[self.curPhaseID].GrpList)
  setactive(self.ui.mTrans_RoundEffect, self.btnList[self.curPhaseID].isUnlock)
  setactive(self.ui.mTrans_ImgLight, self.btnList[self.curPhaseID].isUnlock)
end

function UIDarkzoneModeCarrierPanel:OnClose()
  NetCmdActivitySimData.IsOpenCarrierPanel = false
  self:ClearTimer()
  for id, btn in pairs(self.btnList) do
    if btn.Timer then
      btn.Timer:Stop()
    end
    for j = 1, #btn.GrpList do
      btn.GrpList[j]:OnRelease()
    end
    gfdestroy(btn.BtnPrefab)
  end
  self:ReleaseTimer()
  self.unloadTeam()
  ActivityCafeGlobal.LoadFinish = false
  self.ui.mBtn_Back.interactable = true
  self.ui.mBtn_Home.interactable = true
  MessageSys:RemoveListener(UIEvent.DzTeamUnload, self.unloadTeam)
end

function UIDarkzoneModeCarrierPanel:ClearTimer()
  if self.isTimeFinishTimer then
    self.isTimeFinishTimer:Stop()
    self.isTimeFinishTimer = nil
  end
  if self.timerBackChpater then
    self.timerBackChpater:Stop()
    self.timerBackChpater = nil
  end
  if self.showItemTimerList then
    for i = 1, #self.showItemTimerList do
      self.showItemTimerList[i]:Stop()
      self.showItemTimerList[i] = nil
    end
    self.showItemTimerList = {}
  end
  if self.timerTeam then
    self.timerTeam:Stop()
    self.timerTeam = nil
  end
  if self.loadTeamTimer then
    self.loadTeamTimer:Stop()
    self.loadTeamTimer = nil
  end
  if self.loadModelTimerList then
    for i = 1, #self.loadModelTimerList do
      if self.loadModelTimerList[i] then
        self.loadModelTimerList[i]:Stop()
        self.loadModelTimerList[i] = nil
      end
    end
    self.loadModelTimerList = {}
  end
end

function UIDarkzoneModeCarrierPanel:CloseBtnList()
  for id, btn in pairs(self.btnList) do
    setactive(btn.TransPrefabParent, false)
  end
end

function UIDarkzoneModeCarrierPanel:OnRelease()
end

function UIDarkzoneModeCarrierPanel:GetCloseTime()
  local ConfigData = NetCmdActivityDarkZone:GetCurrActivityConfig(NetCmdActivitySimData.offcialConfigId)
  if not ConfigData then
    return
  end
  local EntranceData = TableData.listActivityEntranceDatas:GetDataById(ConfigData.ActivityEntrance[0])
  local plan = TableData.listPlanDatas:GetDataById(EntranceData.plan_id)
  local openTime = plan.OpenTime
  local closeTime = plan.CloseTime
  if self.state == ActivitySimState.WarmUp then
    self.closeTime = closeTime
  end
  if self.state == ActivitySimState.OfficialDown then
    EntranceData = TableData.listActivityEntranceDatas:GetDataById(ConfigData.ActivityEntrance[2])
  elseif self.state == ActivitySimState.End then
    EntranceData = TableData.listActivityEntranceDatas:GetDataById(ConfigData.ActivityEntrance[ConfigData.ActivityEntrance.Count - 1])
  else
    EntranceData = TableData.listActivityEntranceDatas:GetDataById(ConfigData.ActivityEntrance[1])
  end
  plan = TableData.listPlanDatas:GetDataById(EntranceData.plan_id)
  openTime = plan.OpenTime
  closeTime = plan.CloseTime
  if self.state ~= ActivitySimState.WarmUp then
    self.closeTime = closeTime
  end
  self:CreateStageChangeTimer()
  return self.closeTime
end

function UIDarkzoneModeCarrierPanel:ReleaseTimer()
  if ActivityCafeGlobal.stateChangeTimer then
    ActivityCafeGlobal.stateChangeTimer:Stop()
    ActivityCafeGlobal.stateChangeTimer = nil
  end
end

function UIDarkzoneModeCarrierPanel:CreateStageChangeTimer()
  local repeatCount = self.closeTime - CGameTime:GetTimestamp() + 1
  self:ReleaseTimer()
  if ActivityCafeGlobal.stateChangeTimer == nil then
    ActivityCafeGlobal.stateChangeTimer = TimerSys:DelayCall(1, function()
      if CGameTime:GetTimestamp() >= self.closeTime then
        self:ReleaseTimer()
        local ConfigData = NetCmdActivityDarkZone:GetCurrActivityConfig(NetCmdActivitySimData.offcialConfigId)
        if not ConfigData then
          return
        end
        if ConfigData.ActivityEntrance.Count == 3 then
          if self.state == ActivitySimState.WarmUp or self.state == ActivitySimState.End then
            MessageBox.Show(TableData.GetHintById(64), TableData.GetHintById(270144), nil, function()
              UISystem:JumpToMainPanel()
            end, UIGroupType.Default)
          elseif self.state == ActivitySimState.Official then
            self:BlackJump()
          end
        elseif ConfigData.ActivityEntrance.Count == 4 then
          if self.state == ActivitySimState.WarmUp or self.state == ActivitySimState.Official or self.state == ActivitySimState.End then
            MessageBox.Show(TableData.GetHintById(64), TableData.GetHintById(270144), nil, function()
              UISystem:JumpToMainPanel()
            end, UIGroupType.Default)
          elseif self.state == ActivitySimState.OfficialDown then
            self:BlackJump()
          end
        end
      end
    end, nil, repeatCount)
  end
end

function UIDarkzoneModeCarrierPanel:BlackJump()
  CS.PopupMessageManager.PopupDZStateChangeString(TableData.GetActivityHint(271162, self.activityConfigData.Id, 2, 3003, 101), function()
    if NetCmdActivitySimData.IsOpenDarkzone then
      if self.blackTimer then
        self.blackTimer:Stop()
        self.blackTimer = nil
      end
      UISystem.UISystemBlackCanvas:PlayFadeOutEnhanceBlack(0.33, function()
        self.blackTimer = TimerSys:DelayCall(2, function()
          UISystem.UISystemBlackCanvas:PlayFadeInEnhanceBlack(0.33, function()
          end)
        end)
      end)
      UISystem:JumpToMainPanel()
    else
      UISystem:JumpToMainPanel()
    end
  end)
end

function UIDarkzoneModeCarrierPanel:AutoToBattle()
  local teamData = DarkNetCmdTeamData.Teams[0]
  local realCount = 0
  local gunCount = DarkNetCmdTeamData.Teams[0].Guns.Count
  for i = 0, gunCount - 1 do
    local gunID = teamData.Guns[i]
    if 0 < gunID then
      realCount = realCount + 1
    end
  end
  if teamData.Leader == 0 or realCount ~= 4 then
    local list = DarkNetCmdTeamData:AutoToBattle()
    local listCount = list.Count - 1
    local gunlist = DarkNetCmdTeamData:ConstructData()
    local gunsCount = teamData.Guns.Count
    for i = 0, listCount do
      local id = list[i].GunId
      gunlist:Add(id)
      if i < gunsCount then
        DarkNetCmdTeamData.Teams[0].Guns[i] = id
      else
        DarkNetCmdTeamData.Teams[0].Guns:Add(id)
      end
    end
    local data = DarkZoneTeamData(0, gunlist, gunlist[0])
    DarkNetCmdTeamData.Teams[0].Leader = gunlist[0]
    DarkNetCmdTeamData:SetTeamInfo(data)
  end
end

function UIDarkzoneModeCarrierPanel:OnFromCafe()
end

function UIDarkzoneModeCarrierPanel:LoadTeam()
  self:UpdateTeamList()
  self:UpdateAllModel()
  ActivityCafeGlobal.LoadFinish = true
end

function UIDarkzoneModeCarrierPanel:loadEffect()
end

function UIDarkzoneModeCarrierPanel:UpdateTeamList()
  local Data = DarkNetCmdTeamData.Teams
  for i = 0, Data.Count - 1 do
    local data = {}
    data.name = Data[i].Name
    data.guns = Data[i].Guns
    data.leader = Data[i].Leader
    for j = data.guns.Count, 3 do
      data.guns:Add(0)
    end
    table.insert(self.TeamDataDic, data)
  end
end

function UIDarkzoneModeCarrierPanel:UpdateAllModel()
  local TeamIndex = DarkNetCmdTeamData.CurTeamIndex
  local TeamData = self.TeamDataDic[TeamIndex + 1]
  self.needWait = true
  self.gunModelCacheList = {}
  for i = 0, 3 do
    if TeamData.guns[i] ~= 0 then
      self.maxCacheIndex = self.maxCacheIndex + 1
    end
  end
  if self.loadModelTimerList then
    for i = 1, #self.loadModelTimerList do
      local timer = self.loadModelTimerList[i]
      if timer then
        timer:Stop()
        timer = nil
      end
    end
  end
  self.loadModelTimerList = {}
  for i = 0, 3 do
    if TeamData.guns[i] ~= 0 then
      local timer = TimerSys:DelayFrameCall(i + 1, function()
        self:UpdateModel(TeamData.guns[i], i)
      end)
      table.insert(self.loadModelTimerList, timer)
    end
  end
end

function UIDarkzoneModeCarrierPanel:UpdateModel(GunId, Index)
  local Tabledata = TableData.listGunDatas:GetDataById(GunId)
  local GunCmdData = NetCmdTeamData:GetGunByID(GunId)
  local modelId = GunId
  local weaponModelId = GunCmdData.WeaponData ~= nil and GunCmdData.WeaponData.stc_id or Tabledata.weapon_default or Tabledata.weapon_default
  if UIDarkZoneTeamModelManager:IsCacheLoadedContains(modelId) >= 0 then
    local model = UIDarkZoneTeamModelManager:GetCaCheModel(modelId)
    model.Index = Index
    self:SetGunModel(model, Index)
    return
  end
  UIUtils.GetDarkZoneTeamUIModelAsyn(modelId, weaponModelId, Index, function(go)
    self:UpdateModelCallback(go, Index)
  end)
end

function UIDarkzoneModeCarrierPanel:SetGunModel(model, index)
  model:Show(self.needWait ~= true)
  local num = index + 1
  local str1 = string.format("unit_character_%d_position", num)
  local str2 = string.format("unit_character_%d_rotation", num)
  local data1 = TableData.listGunGlobalConfigDatas:GetDataById(model.tableId)
  local data2 = TableData.listDarkzoneUnitCameraDatas:GetDataById(data1.darkzone_unit_camera)
  local positionList = data2[str1]
  local rotationList = data2[str2]
  if model.transform == nil then
    return
  end
  model.transform.localScale = Vector3.one
  model.transform.position = Vector3(positionList[0], positionList[1], positionList[2])
  model.transform.localEulerAngles = Vector3(rotationList[0], rotationList[1], rotationList[2])
  GFUtils.MoveToLayer(model.transform, CS.UnityEngine.LayerMask.NameToLayer("Friend"))
  if self.DarkZoneTeamCameraCtrl == nil then
    return
  end
  if self.DarkZoneTeamCameraCtrl:GetCameraLength() <= CS.LuaUtils.EnumToInt(CS.DarkZoneTeamCameraPosType.Captain) then
    return
  end
  if index == 0 then
    self.DarkZoneTeamCameraCtrl:ChangeCameraStand(model.tableId, CS.DarkZoneTeamCameraPosType.Captain, model.gameObject)
  end
  self.DarkZoneTeamCameraCtrl:UpdateMateriaList(model.gameObject, index)
  self.DarkZoneTeamCameraCtrl:SetBaseColorByBool(index, true)
  local LODNum = 0
  if not CS.LuaUtils.IsPc() then
    LODNum = (index == 0 or index == 3) and 0 or 1
  end
  model:SetModelLODLevel(LODNum)
end

function UIDarkzoneModeCarrierPanel:UpdateModelCallback(obj, index)
  obj.transform.parent = nil
  if self.DarkZoneTeamCameraCtrl == nil then
    return
  end
  if obj ~= nil and obj.gameObject ~= nil then
    self:SetGunModel(obj, index)
    if self.needWait then
      self.cacheIndex = self.cacheIndex + 1
      self.gunModelCacheList[index] = obj
      self:ResSysLoadAsyncIsAllFinish()
    end
  end
end

function UIDarkzoneModeCarrierPanel:ResSysLoadAsyncIsAllFinish()
  if not (self.cacheIndex >= self.maxCacheIndex) then
    return
  end
  self:ShowAllGunModelByIndex(0)
end

function UIDarkzoneModeCarrierPanel:ShowAllGunModelByIndex(index)
  if self.DarkZoneTeamCameraCtrl == nil then
    return
  end
  if index >= self.maxCacheIndex then
    return
  end
  local model = self.gunModelCacheList[index]
  if model then
    model.gameObject:SetActive(true)
    self:DelayCall(0.1, function()
      self:ShowAllGunModelByIndex(index + 1)
    end)
  else
    self:ShowAllGunModelByIndex(index + 1)
  end
end

require("UI.UIRecentActivityPanel.UIRecentActivityTab")
require("UI.UIRecentActivityPanel.UIRecentActivityFirstOpenedDialog")
require("UI.ActivityTheme.Lenna.LennaActivity")
UIRecentActivityPanel = class("UIRecentActivityPanel", UIBasePanel)

function UIRecentActivityPanel:OnAwake(root, data)
  self.ui = UIUtils.GetUIBindTable(root)
  self:SetRoot(root)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnBack.gameObject, function()
    self:OnClickBack()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnHome.gameObject, function()
    self:OnClickHome()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_DarkzoneEnter.gameObject, function()
    self:OnClickDarkZoneEnter()
  end)
  setactivewithcheck(self.ui.mTrans_TIme, false)
  self.tabTable = {}
end

function UIRecentActivityPanel:OnInit(root, data, behaviourId)
  self.needPlayAnim = true
end

function UIRecentActivityPanel:OnShowStart()
  self:SetVisible(false)
  self.last = false
  self.showMessBox = false
  self:Refresh()
end

function UIRecentActivityPanel:OnBackFrom()
  self:SetVisible(false)
  self:Refresh()
end

function UIRecentActivityPanel:OnTop()
  self:Refresh()
end

function UIRecentActivityPanel:OnReconnectSuc()
  gfdebug("UIRecentActivityPanel \233\135\141\232\191\158\229\144\142\233\135\141\230\150\176\232\175\183\230\177\130")
  if self.mCSPanel.State == CS.UISystem.UIGroup.BasePanelUI.UIState.Show then
    self:Refresh()
  end
end

function UIRecentActivityPanel:OnSave()
end

function UIRecentActivityPanel:OnRecover()
  self:Refresh()
end

function UIRecentActivityPanel:IsReadyToStartTutorial()
  self.planActivityDataList = NetCmdRecentActivityData:GetRequestedPlanActivityDataList()
  self:InitAllRecentActivityTab()
  for i, tab in ipairs(self.tabTable) do
    if tab:IsFirstOpen() then
      return false
    end
  end
  return true
end

function UIRecentActivityPanel:OnHideFinish()
  self.planActivityDataList = nil
  self.isDarkZoneOpenTime = nil
  if self.timer_FadeIn1 then
    self.timer_FadeIn1:Stop()
    self.timer_FadeIn1 = nil
  end
  if self.waitNetTimer then
    self.waitNetTimer:Stop()
    self.waitNetTimer = nil
  end
  self:ReleaseCtrlTable(self.tabTable, true)
end

function UIRecentActivityPanel:OnClose()
  self:CleanFinishTime()
  self.last = false
  if self.timer_FadeIn1 then
    self.timer_FadeIn1:Stop()
    self.timer_FadeIn1 = nil
  end
  if self.waitNetTimer then
    self.waitNetTimer:Stop()
    self.waitNetTimer = nil
  end
  NetCmdThemeData:SetShowAniIndex(0)
end

function UIRecentActivityPanel:OnRelease()
  self.tabTable = nil
  self.ui = nil
  if self.timer_FadeIn1 then
    self.timer_FadeIn1:Stop()
    self.timer_FadeIn1 = nil
  end
  if self.waitNetTimer then
    self.waitNetTimer:Stop()
    self.waitNetTimer = nil
  end
  self:CleanFinishTime()
  self.super.OnRelease(self)
  NetCmdThemeData:SetShowAniIndex(0)
end

function UIRecentActivityPanel:Refresh()
  self.needPlayAnim = true
  self:RefreshRecentActivityTab()
  self:RefreshDarkZoneEntrance()
end

function UIRecentActivityPanel:GetEndParam()
  local endCount = 0
  local endTime = 0
  for i, tab in ipairs(self.tabTable) do
    if tab.activityModuleData.stage_type == 3 then
      endCount = endCount + 1
      if endTime < tab.planActivityData.close_time then
        endTime = tab.planActivityData.close_time
      end
    end
  end
  if endCount == self.planActivityDataList.Count then
    return true, endTime
  end
  return false, 0
end

function UIRecentActivityPanel:checkRecentActivityFirstOpened()
  for i, tab in ipairs(self.tabTable) do
    if tab:IsFirstOpen() then
      local param = {}
      param.activityEntranceData = tab:GetActivityEntranceData()
      param.activityConfigData = tab:GetActivityConfigData()
      param.activityModuleData = tab:GetActivityModuleData()
      if self.mCSPanel.State == CS.UISystem.UIGroup.BasePanelUI.UIState.Show then
        UISystem:OpenUI(UIDef.UIRecentActivityFirstOpenedDialog, param)
      end
      self.showMessBox = true
      break
    else
      local isAllend, endTime = self:GetEndParam()
      if isAllend then
        self:UpdateFinishTime(endTime)
      end
    end
  end
end

function UIRecentActivityPanel:CleanFinishTime()
  if self.finishTime then
    self.finishTime:Stop()
    self.finishTime = nil
  end
end

function UIRecentActivityPanel:UpdateFinishTime(endTime)
  self:CleanFinishTime()
  local repeatCount = endTime - CGameTime:GetTimestamp()
  if 0 < repeatCount then
    self.finishTime = TimerSys:DelayCall(1, function()
      if CGameTime:GetTimestamp() >= endTime then
        self:CleanFinishTime()
        self:SetAllRecentActivityTabVisible(false)
      end
    end, nil, repeatCount)
  end
end

function UIRecentActivityPanel:RefreshRecentActivityTab()
  self.waitNetTimer = TimerSys:DelayCall(1, function()
    self:SetVisible(true)
    self:SetAllRecentActivityTabVisible(false)
    setactivewithcheck(self.ui.mTrans_Mask, false)
    gfdebug("UIRecentActivityPanel \231\173\137\229\190\1331s\230\178\161\230\156\137\231\189\145\231\187\156\230\182\136\230\129\175, \230\152\190\231\164\186\233\148\129\229\174\154\230\128\129\231\149\140\233\157\162")
  end)
  NetCmdRecentActivityData:ReqPlanActivityData(PlanType.PlanFunctionActivityThematic, function(ret)
    gfdebug("UIRecentActivityPanel \230\156\137\231\189\145\231\187\156\229\155\158\232\176\131\230\160\185\230\141\174\231\189\145\231\187\156\229\155\158\232\176\131\229\177\149\231\164\186\231\149\140\233\157\162, \232\175\183\230\177\130\230\136\144\229\138\159: " .. ret == ErrorCodeSuc)
    if self.waitNetTimer then
      self.waitNetTimer:Stop()
      self.waitNetTimer = nil
      gfdebug("UIRecentActivityPanel \230\148\182\229\136\176\231\189\145\231\187\156\229\155\158\232\176\131\229\143\150\230\182\1361s\231\173\137\229\190\133\232\174\161\230\151\182")
    end
    if ret ~= ErrorCodeSuc then
      self:SetVisible(true)
      self:SetAllRecentActivityTabVisible(false)
      setactivewithcheck(self.ui.mTrans_Mask, false)
      return
    end
    self:SetVisible(true)
    self.planActivityDataList = NetCmdRecentActivityData:GetRequestedPlanActivityDataList()
    local animCount = NetCmdThemeData:GetThemeAnimCount(self.planActivityDataList)
    if self.planActivityDataList.Count > 0 then
      local showAniIndex = NetCmdThemeData:GetShowAniIndex()
      if animCount > showAniIndex then
        showAniIndex = animCount
        NetCmdThemeData:SetShowAniIndex(animCount)
      end
      local isPlayFadeIn = true
      if showAniIndex >= self.planActivityDataList.Count then
        self.last = true
        NetCmdThemeData:SetShowAniIndex(0)
        showAniIndex = 0
        isPlayFadeIn = self.needPlayAnim
      end
      local enterID = self.planActivityDataList[showAniIndex].id
      local activityPlayState = NetCmdThemeData:GetThemeAnimState(enterID)
      self:InitAllRecentActivityTab()
      self:RefreshActivityPoint()
      self:RefreshAllRecentActivityTab()
      self:CheckActivity()
      setactivewithcheck(self.ui.mTrans_Mask, activityPlayState < 1 and enterID ~= 0)
      if 0 < activityPlayState then
        if isPlayFadeIn then
          self.ui.mAnimator_Root:SetTrigger("FadeIn_0")
        end
        self.needPlayAnim = false
        self:checkRecentActivityFirstOpened()
        return
      end
      if self.timer_FadeIn1 then
        if isPlayFadeIn then
          self.ui.mAnimator_Root:SetBool("Sweep", true)
        end
        length = LuaUtils.GetAnimationClipLength(self.ui.mAnimator_Root, "Sweep")
        self.needPlayAnim = false
      else
        if isPlayFadeIn then
          self.ui.mAnimator_Root:SetTrigger("FadeIn_1")
          self.ui.mAnimator_Root:SetBool("Sweep", true)
        end
        length = LuaUtils.GetAnimationClipLength(self.ui.mAnimator_Root, "FadeIn_1")
      end
      self.timer_FadeIn1 = TimerSys:DelayCall(length, function(data)
        self:checkRecentActivityFirstOpened()
      end)
      self.needPlayAnim = false
    else
      self.ui.mAnimator_Root:SetTrigger("FadeIn_0")
      setactivewithcheck(self.ui.mTrans_Mask, false)
      self.needPlayAnim = false
    end
  end)
end

function UIRecentActivityPanel:CheckActivity()
  if self:CheckActivityIsOpen(2) or self:CheckActivityIsOpen(3) then
    NetCmdActivityDarkZone:SendGetDarkZoneCarInfo()
  end
end

function UIRecentActivityPanel:CheckActivityIsOpen(configId)
  if self.planActivityDataList == nil then
    return false
  end
  for i = 0, self.planActivityDataList.Count - 1 do
    local entranceId = self.planActivityDataList[i].id
    local activityConfigData = NetCmdThemeData:GetActivityDataByEntranceId(entranceId)
    if activityConfigData ~= nil and configId == activityConfigData.id then
      return true
    end
  end
  return false
end

function UIRecentActivityPanel:RefreshDarkZoneEntrance()
  self.ui.mBtn_DarkzoneEnter.interactable = false
  setactivewithcheck(self.ui.mCountdown, false)
  NetCmdRecentActivityData:ReqPlanActivityData(PlanType.PlanFunctionDarkzone, function(ret)
    if ret ~= ErrorCodeSuc then
      return
    end
    self.ui.mBtn_DarkzoneEnter.interactable = true
    local sc_planActivityData = NetCmdRecentActivityData:GetPlanActivityData()
    local planActivityIdList = sc_planActivityData.ActiveIds
    local nextPlanActivityIdList = sc_planActivityData.NextIds
    self.isDarkZoneOpenTime = true
    if planActivityIdList.Count > 1 then
      gferror("\229\144\140\230\151\182\229\188\128\229\144\175\228\184\164\228\184\170\230\154\151\229\140\186\230\180\187\229\138\168!!!")
    end
    for i = 0, planActivityIdList.Count - 1 do
      local planActivityId = planActivityIdList[i]
      local planActivityData = TableDataBase.listPlanDatas:GetDataById(planActivityId)
      gfdebug("RefreshDarkZoneEntrance closeTime" .. planActivityData.close_time)
      break
    end
    local isOpenTime = self.isDarkZoneOpenTime
    local isUnlock = AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.Darkzone)
    local canEnter = isOpenTime and isUnlock
    self.ui.mAnimator_DarkZoneEnter:SetBool("Unlock", canEnter)
    if not isOpenTime and nextPlanActivityIdList.Count > 0 then
      local nextPlanActivityId = nextPlanActivityIdList[0]
      local nextPlanActivityData = TableDataBase.listPlanDatas:GetDataById(nextPlanActivityId)
      gfdebug("RefreshDarkZoneEntrance openTime" .. nextPlanActivityData.open_time)
    end
    if not GFUtils.IsOverseaServer() then
      local isNeedRedPoint = NetCmdRecentActivityData:CheckRecentActivityDarkZoneRedPoint() and canEnter
      setactivewithcheck(self.ui.mObj_RedPoint, isNeedRedPoint)
      setactivewithcheck(self.ui.mObj_RedPoint.parent.transform, isNeedRedPoint)
    end
  end)
end

function UIRecentActivityPanel:InitAllRecentActivityTab()
  local showAniIndex = NetCmdThemeData:GetShowAniIndex()
  local dataCount = self.planActivityDataList.Count
  for i = dataCount + 1, #self.tabTable do
    local tab = self.tabTable[i]
    tab:SetVisible(false)
  end
  local showIndex = 0
  if self.last then
    local enterID = self.planActivityDataList[showAniIndex].id
    local activityPlayState = NetCmdThemeData:GetThemeAnimState(enterID)
    showIndex = self.planActivityDataList.Count
  elseif 0 < showAniIndex and showAniIndex < self.planActivityDataList.Count then
    local enterID = self.planActivityDataList[showAniIndex].id
    local activityPlayState = NetCmdThemeData:GetThemeAnimState(enterID)
    if 0 < activityPlayState then
      showIndex = showAniIndex + 1
    else
      showIndex = showAniIndex
    end
  else
    isEndCount = 0
    for i = 0, self.planActivityDataList.Count - 1 do
      local enterID = self.planActivityDataList[i].id
      local activityPlayState = NetCmdThemeData:GetThemeAnimState(enterID)
      if 0 < activityPlayState then
        isEndCount = isEndCount + 1
      end
    end
    if isEndCount >= self.planActivityDataList.Count then
      showIndex = self.planActivityDataList.Count
    else
      showIndex = isEndCount
    end
  end
  for i = 0, self.planActivityDataList.Count - 1 do
    local tab = self.tabTable[i + 1]
    if not tab then
      tab = UIRecentActivityTab.New()
      tab:InitCtrl(self.ui.mScrollListChild_GrpRight.transform)
      table.insert(self.tabTable, i + 1, tab)
    end
    tab:SetVisible(i < showIndex)
    tab:SetData(self.planActivityDataList[i], i + 1, function(index)
      self:OnClickTab(index)
    end)
    tab:AddActivityEndCallback(function(tabIndex)
      self:OnActivityTimerEnd(tabIndex)
    end)
  end
end

function UIRecentActivityPanel:RefreshAllRecentActivityTab()
  for i = 0, self.planActivityDataList.Count - 1 do
    local tab = self.tabTable[i + 1]
    tab:SetData(self.planActivityDataList[i], i + 1, function(index)
      self:OnClickTab(index)
    end)
    tab:AddActivityEndCallback(function(tabIndex)
      self:OnActivityTimerEnd(tabIndex)
    end)
    tab:Refresh()
  end
end

function UIRecentActivityPanel:SetAllRecentActivityTabVisible(visible)
  if self.tabTable == nil then
    return
  end
  for i, tab in ipairs(self.tabTable) do
    tab:SetVisible(visible)
  end
end

function UIRecentActivityPanel:RefreshActivityPoint()
  for i = 1, 2 do
    local tab = self.tabTable[i]
    if tab and tab:IsFirstOpen() then
      for j = i, 2 do
        local point = self.ui["mTrans_ActivityPoint" .. j]
        setactivewithcheck(point, false)
      end
      break
    end
  end
  for i, tab in ipairs(self.tabTable) do
    local point = self.ui["mTrans_ActivityPoint" .. i]
    if point then
      if tab:IsFirstOpen() then
        setactivewithcheck(point, true)
        break
      else
        setactivewithcheck(point, true)
      end
    end
  end
end

function UIRecentActivityPanel:IsHaveFirstOpenActivity()
  local haveFirstOpen = false
  for i, tab in ipairs(self.tabTable) do
    haveFirstOpen = haveFirstOpen or tab:IsFirstOpen()
  end
  return haveFirstOpen
end

function UIRecentActivityPanel:OnActivityTimerEnd(index)
  self:Refresh()
end

function UIRecentActivityPanel:OnDarkZoneTimerEnd(succ)
  if not succ then
    return
  end
  self:RefreshDarkZoneEntrance()
end

function UIRecentActivityPanel:OnClickTab(index)
  local tab = self.tabTable[index]
  local activityConfigData = tab:GetActivityConfigData()
  if activityConfigData then
    if NetCmdThemeData:CheckActivityEqual(activityConfigData.Id, ThemeActivityType.Daiyan) then
      if activityConfigData.prologue > 0 and NetCmdThemeData:GetThemeAVGState(activityConfigData.id) < 1 then
        NetCmdThemeData:SendThemeCheckInQuestionInfo(tab.activityEntranceData.id, function(ret)
          if ret == ErrorCodeSuc then
            if tab.activityModuleData.stage_type == 1 then
              UIManager.OpenUIByParam(UIDef.DaiyanPreheatPanel, {
                activityEntranceData = tab:GetActivityEntranceData(),
                activityModuleData = tab:GetActivityModuleData(),
                activityConfigData = tab:GetActivityConfigData()
              })
            else
              UIManager.OpenUIByParam(UIDef.DaiyanMainPanel, {
                activityEntranceData = tab:GetActivityEntranceData(),
                activityModuleData = tab:GetActivityModuleData(),
                activityConfigData = tab:GetActivityConfigData()
              })
            end
            CS.AVGController.PlayAvgByPlotId(activityConfigData.prologue, function()
              NetCmdThemeData:SetThemeAVGState(activityConfigData.id, 1)
            end, true)
          end
        end)
      else
        NetCmdThemeData:SendThemeCheckInQuestionInfo(tab.activityEntranceData.id, function(ret)
          if ret == ErrorCodeSuc then
            if tab.activityModuleData.stage_type == 1 then
              UIManager.OpenUIByParam(UIDef.DaiyanPreheatPanel, {
                activityEntranceData = tab:GetActivityEntranceData(),
                activityModuleData = tab:GetActivityModuleData(),
                activityConfigData = tab:GetActivityConfigData()
              })
            else
              UIManager.OpenUIByParam(UIDef.DaiyanMainPanel, {
                activityEntranceData = tab:GetActivityEntranceData(),
                activityModuleData = tab:GetActivityModuleData(),
                activityConfigData = tab:GetActivityConfigData()
              })
            end
          end
        end)
      end
    elseif NetCmdThemeData:CheckActivityEqual(activityConfigData.Id, ThemeActivityType.Cafe) then
      local state = NetCmdActivityDarkZone:GetCurrActivityState(activityConfigData.id)
      if state == ActivitySimState.WarmUp then
        if 0 < activityConfigData.prologue and NetCmdThemeData:GetThemeAVGState(activityConfigData.id) < 1 then
          NetCmdActivitySimData:CSThemeActivityInfo(tab.activityEntranceData.id, function(ret)
            if ret == ErrorCodeSuc then
              UIManager.OpenUIByParam(UIDef.UIActivityCafeMainPanel, {
                activityEntranceData = tab:GetActivityEntranceData(),
                activityModuleData = tab:GetActivityModuleData(),
                activityConfigData = tab:GetActivityConfigData()
              })
            end
            CS.AVGController.PlayAvgByPlotId(activityConfigData.prologue, function()
              NetCmdThemeData:SetThemeAVGState(activityConfigData.id, 1)
            end, true)
          end)
        else
          NetCmdActivitySimData:CSThemeActivityInfo(tab.activityEntranceData.id, function(ret)
            if ret == ErrorCodeSuc then
              UIManager.OpenUIByParam(UIDef.UIActivityCafeMainPanel, {
                activityEntranceData = tab:GetActivityEntranceData(),
                activityModuleData = tab:GetActivityModuleData(),
                activityConfigData = tab:GetActivityConfigData()
              })
            end
            CS.AVGController.PlayAvgByPlotId(activityConfigData.prologue, function()
              NetCmdThemeData:SetThemeAVGState(activityConfigData.id, 1)
            end, true)
          end)
        end
      elseif 0 < activityConfigData.prologue and NetCmdThemeData:GetThemeAVGState(activityConfigData.id) < 1 then
        UIManager.OpenUIByParam(UIDef.UIActivityCafeMainPanel, {
          activityEntranceData = tab:GetActivityEntranceData(),
          activityModuleData = tab:GetActivityModuleData(),
          activityConfigData = tab:GetActivityConfigData()
        })
        CS.AVGController.PlayAvgByPlotId(activityConfigData.prologue, function()
          NetCmdThemeData:SetThemeAVGState(activityConfigData.id, 1)
        end, true)
      else
        UIManager.OpenUIByParam(UIDef.UIActivityCafeMainPanel, {
          activityEntranceData = tab:GetActivityEntranceData(),
          activityModuleData = tab:GetActivityModuleData(),
          activityConfigData = tab:GetActivityConfigData()
        })
        CS.AVGController.PlayAvgByPlotId(activityConfigData.prologue, function()
          NetCmdThemeData:SetThemeAVGState(activityConfigData.id, 1)
        end, true)
      end
    elseif NetCmdThemeData:CheckActivityEqual(activityConfigData.Id, ThemeActivityType.Lenna) then
      LennaActivity.Enter(tab, activityConfigData)
    elseif NetCmdThemeData:CheckActivityEqual(activityConfigData.Id, ThemeActivityType.JiangYu) then
      local state = NetCmdActivityDarkZone:GetCurrActivityState(activityConfigData.id)
      if state == ActivitySimState.WarmUp then
        local data = CS.UIActivityThemePreheatPanel.Param(activityConfigData.Id, activityConfigData.ActivityEntrance[0])
        UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIActivityThemePreheatPanel, data)
      elseif state == ActivitySimState.Official then
        local data = CS.UIJiangyuMainPanel.Param(activityConfigData.Id, activityConfigData.ActivityEntrance[1])
        UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIJiangyuMainPanel, data)
      end
    elseif NetCmdThemeData:CheckActivityEqual(activityConfigData.Id, ThemeActivityType.Card) then
    end
  end
end

function UIRecentActivityPanel:OnClickDarkZoneEnter()
  if TipsManager.NeedLockTips(SystemList.Darkzone) then
    return
  end
  local isOpenTime = self.isDarkZoneOpenTime
  if not isOpenTime then
    local str = TableData.GetHintById(200003)
    CS.PopupMessageManager.PopupString(str)
    MessageSys:SendMessage(GuideEvent.OnTabSwitchFail, nil)
    return
  end
end

function UIRecentActivityPanel:OnClickBack()
  UIManager.CloseUI(self.mCSPanel)
end

function UIRecentActivityPanel:OnClickHome()
  UISystem:JumpToMainPanel()
end

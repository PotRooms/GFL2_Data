require("UI.UIBasePanel")
require("UI.UIRecentActivityPanel.UIRecentActivityTab")
require("UI.UIRecentActivityPanel.UIRecentActivityFirstOpenedDialog")
require("UI.ActivityTheme.Lenna.LennaActivity")
require("UI.UIRecentActivityPanel.Btn_RecentActivitieCombatEnterItem")
RecentActivitiePanelV2 = class("RecentActivitiePanelV2", UIBasePanel)
RecentActivitiePanelV2.__index = RecentActivitiePanelV2

function RecentActivitiePanelV2:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
end

function RecentActivitiePanelV2:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.planActivityDataList = {}
  self.activityDataList = {}
  self.activityItemList = {}
  self.limitDataList = {}
  self.limitItemList = {}
  self.ShowDialogIndex = -1
  self.netTimeSucc = false
end

function RecentActivitiePanelV2:OnInit(root, data)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnBack.gameObject, function()
    UIManager.CloseUI(UIDef.RecentActivitiePanelV2)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnHome.gameObject, function()
    UISystem:JumpToMainPanel()
  end)
  
  function RecentActivitiePanelV2.ConnectSuccess()
    RecentActivitiePanelV2:OnSuccessRefresh()
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnReconnectSuc, RecentActivitiePanelV2.ConnectSuccess)
  self:RefreshLeftAct()
  self:RefreshRightAct()
end

function RecentActivitiePanelV2:OnSuccessRefresh()
  if self.mCSPanel.State == CS.UISystem.UIGroup.BasePanelUI.UIState.Show then
    self:RefreshLeftAct()
  end
end

function RecentActivitiePanelV2:RefreshRightAct()
  self.limitDataList = NetCmdRecentActivityData:GetLimitEntranceDatas()
  for i = 0, self.limitDataList.Count - 1 do
    local item = self.limitItemList[i + 1]
    if not item then
      item = Btn_RecentActivitieCombatEnterItem.New()
      item:InitCtrl(self.ui.mTrans_RightContent)
      table.insert(self.limitItemList, item)
    end
    item:SetVisible(true)
    item:SetData(self.limitDataList[i])
  end
  if #self.limitItemList > self.limitDataList.Count then
    for j = self.limitDataList.Count + 1, #self.limitItemList do
      self.limitItemList[j]:SetVisible(false)
    end
  end
end

function RecentActivitiePanelV2:CleanWaitNet()
  if self.waitNetTimer then
    self.waitNetTimer:Stop()
    self.waitNetTimer = nil
  end
end

function RecentActivitiePanelV2:WaitNetStart()
  self:CleanWaitNet()
  self.waitNetTimer = TimerSys:DelayCall(1, function()
    if not self.netTimeSucc then
      self:CleanWaitNet()
      UIManager.CloseUI(UIDef.RecentActivitiePanelV2)
    end
  end)
end

function RecentActivitiePanelV2:RefreshLeftAct()
  self:SetVisible(false)
  self:WaitNetStart()
  NetCmdRecentActivityData:ReqPlanActivityData(PlanType.PlanFunctionActivityThematic, function(ret)
    self:SetVisible(true)
    if ret ~= ErrorCodeSuc then
      return
    end
    self.netTimeSucc = true
    self.planActivityDataList = NetCmdRecentActivityData:GetRequestedPlanActivityDataList()
    self.activityDataList = NetCmdThemeData:GetShowEntranceDataList(self.planActivityDataList)
    self.ShowDialogIndex = NetCmdThemeData:GetActivityPlayIndex(self.planActivityDataList)
    self:InitAllRecentActivityTab()
    setactive(self.ui.mTrans_Mask.gameObject, false)
    if self.planActivityDataList.Count > 0 and self.ShowDialogIndex ~= -1 then
      local entranceData = self.planActivityDataList[self.ShowDialogIndex]
      if entranceData then
        do
          local length = 1
          if self.ShowDialogIndex == 0 then
            self.ui.mAnimator_Root:SetTrigger("FadeIn_1")
            self.ui.mAnimator_Root:SetBool("Sweep", true)
            length = LuaUtils.GetAnimationClipLength(self.ui.mAnimator_Root, "FadeIn_1")
          else
            self.ui.mAnimator_Root:SetBool("Sweep", true)
            length = LuaUtils.GetAnimationClipLength(self.ui.mAnimator_Root, "Sweep")
          end
          self.timer_FadeIn1 = TimerSys:DelayCall(length, function(data)
            local activityModuleData = TableData.listActivityModuleDatas:GetDataById(entranceData.module_id)
            if activityModuleData and activityModuleData.stage_type ~= 3 then
              self:checkRecentActivityFirstOpened(entranceData)
            end
          end)
          setactive(self.ui.mTrans_Mask.gameObject, true)
        end
      end
    else
      self.ui.mAnimator_Root:SetTrigger("FadeIn_0")
    end
  end)
end

function RecentActivitiePanelV2:CleanFadeInTime()
  if self.timer_FadeIn1 then
    self.timer_FadeIn1:Stop()
    timer_FadeIn1 = nil
  end
end

function RecentActivitiePanelV2:checkRecentActivityFirstOpened(entranceData)
  local param = {}
  param.activityEntranceData = entranceData
  param.activityConfigData = NetCmdThemeData:GetActivityDataByEntranceId(entranceData.id)
  if param.activityConfigData then
    param.activityModuleData = TableData.listActivityModuleDatas:GetDataById(entranceData.module_id)
    if self.mCSPanel.State == CS.UISystem.UIGroup.BasePanelUI.UIState.Show then
      UISystem:OpenUI(UIDef.UIRecentActivityFirstOpenedDialog, param)
    end
  end
end

function RecentActivitiePanelV2:InitAllRecentActivityTab()
  for i = 0, self.activityDataList.Count - 1 do
    local tab = self.activityItemList[i + 1]
    if not tab then
      tab = UIRecentActivityTab.New()
      tab:InitCtrl(self.ui.mTrans_LeftContent)
      table.insert(self.activityItemList, tab)
    end
    tab:SetVisible(true)
    tab:SetData(self.activityDataList[i], i + 1, function(index)
      self:OnClickTab(index)
    end)
    tab:Refresh()
    tab:AddActivityEndCallback(function(tabIndex)
      self:RefreshLeftAct()
    end)
  end
  if #self.activityItemList > self.activityDataList.Count then
    for j = self.activityDataList.Count + 1, #self.activityItemList do
      self.activityItemList[j]:SetVisible(false)
    end
  end
end

function RecentActivitiePanelV2:OnClickTab(index)
  local tab = self.activityItemList[index]
  local activityConfigData = tab:GetActivityConfigData()
  if activityConfigData then
    if NetCmdThemeData:CheckActivityEqual(activityConfigData.Id, ThemeActivityType.Daiyan) then
      UIManager.OpenUIByParam(UIDef.DaiyanMainPanel, {
        activityEntranceData = tab:GetActivityEntranceData(),
        activityModuleData = tab:GetActivityModuleData(),
        activityConfigData = tab:GetActivityConfigData()
      })
    elseif NetCmdThemeData:CheckActivityEqual(activityConfigData.Id, ThemeActivityType.Cafe) then
      local state = NetCmdActivityDarkZone:GetCurrActivityState(activityConfigData.id)
      if state == ActivitySimState.WarmUp then
        if activityConfigData.prologue > 0 and NetCmdThemeData:GetThemeAVGState(activityConfigData.id) < 1 then
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
    elseif NetCmdThemeData:IsThemeTemplateActivity(activityConfigData.Id) then
      NetCmdRecentActivityData:OpenActivityWnd(activityConfigData.Id)
    elseif NetCmdThemeData:CheckActivityEqual(activityConfigData.Id, ThemeActivityType.Card) then
    elseif NetCmdThemeData:CheckActivityEqual(activityConfigData.Id, ThemeActivityType.Anniversary) then
      local data = CS.UIAnniversaryMainPanel.Param(activityConfigData.Id, activityConfigData.ActivityEntrance[0])
      UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIAnniversaryMainPanel, data)
    elseif NetCmdThemeData:CheckActivityEqual(activityConfigData.Id, ThemeActivityType.KeLuKai) then
      local data = CS.UISummerActivityMainPanel.Param(activityConfigData.Id, activityConfigData.ActivityEntrance[0])
      UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UISummerActivityMainPanel, data)
    else
      NetCmdRecentActivityData:OpenActivityWnd(activityConfigData.Id)
    end
  end
end

function RecentActivitiePanelV2:OnShowStart()
end

function RecentActivitiePanelV2:OnShowFinish()
end

function RecentActivitiePanelV2:OnRecover()
  self:RefreshLeftAct()
  self:RefreshRightAct()
end

function RecentActivitiePanelV2:OnTop()
  self:RefreshLeftAct()
  self:RefreshRightAct()
end

function RecentActivitiePanelV2:OnBackFrom()
  self:RefreshLeftAct()
  self:RefreshRightAct()
end

function RecentActivitiePanelV2:OnClose()
  self:CleanFadeInTime()
  self.netTimeSucc = false
  self:CleanWaitNet()
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnReconnectSuc, RecentActivitiePanelV2.ConnectSuccess)
end

function RecentActivitiePanelV2:OnHide()
end

function RecentActivitiePanelV2:OnHideFinish()
end

function RecentActivitiePanelV2:OnRelease()
end

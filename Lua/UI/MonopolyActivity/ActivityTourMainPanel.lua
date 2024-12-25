require("UI.UIBasePanel")
require("UI.MonopolyActivity.SelectInfo.ActivityTourGridDetailItem")
require("UI.MonopolyActivity.SelectInfo.ActivityTourInfoItem")
require("UI.MonopolyActivity.TaskInfo.ActivityTourTaskInfo")
require("UI.MonopolyActivity.CharInfo.ActivityTourChrInfo")
require("UI.MonopolyActivity.ActivityTourGlobal")
require("UI.MonopolyActivity.RightTips.ActivityTourTips")
require("UI.MonopolyActivity.RandomMovePoint.ActivityTourPointRandomItem")
require("UI.MonopolyActivity.ActionTimeLine.ActionTimeLine")
require("UI.MonopolyActivity.Command.ActivityTourCommand")
require("UI.MonopolyActivity.BattleReport.ActivityTourBattleReport")
ActivityTourMainPanel = class("ActivityTourMainPanel", UIBasePanel)
ActivityTourMainPanel.__index = ActivityTourMainPanel

function ActivityTourMainPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
  csPanel.Is3DPanel = true
end

function ActivityTourMainPanel:OnInit(root)
  ActivityTourGlobal.SetGlobalValue()
  MonopolyUtil:SetMonopolyActivityUIHint(root)
  ActivityTourGlobal.PointsId = MonopolyWorld.MpData.levelData.token
  self.super.SetRoot(self, root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.ui.mAnim_Speed.keepAnimatorControllerStateOnDisable = true
  self:RegisterEvent()
  self:RegisterMessage()
  self:InitGM()
  self:InitPoints()
  if not MonopolyWorld.MpData.isStart then
    self:OnHideActivityTourMainPanel()
    return
  end
  self:InitAll()
  self:OnHideActivityTourMainPanel()
end

function ActivityTourMainPanel:OnTop()
  self:RefreshStamina()
end

function ActivityTourMainPanel:InitGM()
  if MonopolyWorld.IsDebugMode then
    local GMItem = instantiate(UIUtils.GetGizmosPrefab("GameCommand/Btn_GMActivityTour.prefab", self), self.mUIRoot.transform)
    GMItem.transform:SetParent(self.mUIRoot, true)
    UIUtils.GetButtonListener(GMItem.gameObject).onClick = function()
      if CS.UI.Monopoly.UIMonopolyGMDialog.IsOpen() then
        CS.UI.Monopoly.UIMonopolyGMDialog.CloseSelf()
      else
        CS.UI.Monopoly.UIMonopolyGMDialog.Open()
      end
    end
  end
end

function ActivityTourMainPanel:InitAll()
  ActivityTourGlobal.MaxCommandNum = MonopolyWorld.MpData.levelData.max_order_number
  self:InitHud()
  self:InitAllCtrl()
  self:InitCurrency()
  ActivityTourGlobal.ReplaceAllColor(self.mUIRoot)
end

function ActivityTourMainPanel:InitCurrency()
  if self.mTopCurrency == nil then
    self.mTopCurrency = ResourcesCommonItem.New()
    self.mTopCurrency:InitCtrlWithObj(self.ui.mTrans_Stamina)
    local showCommandItemID = CS.GF2.Data.StaminaResourceType.Stamina:GetHashCode()
    local itemData = TableData.GetItemData(showCommandItemID)
    self.mTopCurrency:SetData({
      id = itemData.id,
      jumpID = 2
    })
    self:AddMessageListener(CS.GF2.Message.ModelDataEvent.StaminaChange, self.RefreshStamina)
  end
end

function ActivityTourMainPanel:InitPoints()
  self.ui.mImg_PointsIcon.sprite = ActivityTourGlobal.GetPointIcon()
  self.currency = MonopolyWorld.MpData.Points
  self.ui.mText_Currency.text = self.currency
end

function ActivityTourMainPanel:RefreshStamina()
  if self.mTopCurrency ~= nil then
    self.mTopCurrency:UpdateData()
  end
end

function ActivityTourMainPanel:InitHud()
  if not self.mHudCtrl then
    self.mHudCtrl = CS.UI.Monopoly.UIMonopolyHudCtrl()
    self.mHudCtrl:InitCtrl(self.ui.mTrans_HudNameRoot.childItem.gameObject, self.ui.mTrans_HudNameRoot.transform)
  end
end

function ActivityTourMainPanel.CloseSelf()
  UIManager.CloseUI(UIDef.ActivityTourMainPanel)
end

function ActivityTourMainPanel:RegisterEvent()
  UIUtils.GetButtonListener(self.ui.mBtn_Quit.gameObject).onClick = function()
    if MonopolyWorld.IsGmMode then
      NetCmdMonopolyData:ReturnToMainPanel()
    else
      UIManager.OpenUIByParam(UIDef.ActivityTourDoubleCheckDialog, {
        themeId = NetCmdMonopolyData.themID
      })
    end
  end
  UIUtils.GetButtonListener(self.ui.mBtn_MapInfo.gameObject).onClick = function()
    self:OnBtnMapInfo()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_PPT.gameObject).onClick = function()
    self:ShowPPT()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Points.gameObject).onClick = function()
    TipsPanelHelper.OpenUITipsPanel(TableData.GetItemData(ActivityTourGlobal.PointsId))
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Speed.gameObject).onClick = function()
    self:SetGameSeed(not self.mSpeedUp)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_TaskShow.gameObject).onClick = function()
    self.mUITaskInfo:OnlyShowRoundInfo(not self.mUITaskInfo.isOnlyShowRoundInfo)
  end
end

function ActivityTourMainPanel:SetGameSeed(speed)
  self.mSpeedUp = speed
  MonopolyWorld.MpData.IsGameSpeedUp = self.mSpeedUp
  self.ui.mAnim_Speed:SetBool("BtnSpeedSwitch", self.mSpeedUp)
  local speed = CS.GF2.Monopoly.MonopolyDefine.NormalGameSpeed
  local configData = MonopolyWorld.MpData.configData
  if self.mSpeedUp and configData ~= nil then
    speed = configData.game_speed
  end
  CS.DebugCenter.Instance:SetTimeScale(math.max(speed, 1))
end

function ActivityTourMainPanel:ShowPPT()
  local pptId = MonopolyWorld.MpData.levelData.PptId
  if pptId <= 0 then
    print("\233\133\141\231\189\174\231\154\132PPT ID\228\184\1860")
    return
  end
  local newShowData = CS.ShowGuideDialogPPTData()
  newShowData.GroupId = pptId
  if NetCmdTeachPPTData:GetGroupIdsByType(CS.EPPTGroupType.All):IndexOf(newShowData.GroupId) ~= -1 then
    local showTeachData = CS.ShowTeachPPTData()
    showTeachData.GroupId = pptId
    UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIGuidePPTDialog, showTeachData)
  else
    UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIComGuideDialogV2PPT, newShowData)
  end
end

function ActivityTourMainPanel:RegisterMessage()
  self:AddMessageListener(MonopolyEvent.OnShowSelectDetail, self.OnShowSelectDetail)
  self:AddMessageListener(MonopolyEvent.OnHideSelectDetail, self.OnHideSelectDetail)
  self:AddMessageListener(MonopolyEvent.ShowActivityTourMainPanel, self.OnShowActivityTourMainPanel)
  self:AddMessageListener(MonopolyEvent.HideActivityTourMainPanel, self.OnHideActivityTourMainPanel)
  self:AddMessageListener(MonopolyEvent.BlockActivityTourMainPanel, self.OnBlockActivityTourMainPanel)
  self:AddMessageListener(MonopolyEvent.CancelBlockActivityTourMainPanel, self.OnCancelBlockActivityTourMainPanel)
  self:AddMessageListener(MonopolyEvent.OnShowPointTip, self.OnShowPointTip)
  self:AddMessageListener(MonopolyEvent.RefreshAndResetPoints, self.RefreshAndResetPoints)
  self:AddMessageListener(MonopolyEvent.OnShowInspirationTip, self.OnShowInspirationTip)
  self:AddMessageListener(MonopolyEvent.OnShowCommandGetRightTip, self.OnShowCommandGetRightTip)
  self:AddMessageListener(MonopolyEvent.OnShowRandomPoint, self.OnShowRandomPoint)
  self:AddMessageListener(MonopolyEvent.OnFleetComplete, self.OnFleetComplete)
  self:AddMessageListener(MonopolyEvent.OnRefreshCommand, self.OnRefreshCommand)
  self:AddMessageListener(MonopolyEvent.MoveNextActionTimeLine, self.MoveNextActionTimeLine)
  self:AddMessageListener(MonopolyEvent.ResetActionTimeLine, self.ResetActionTimeLine)
  self:AddMessageListener(MonopolyEvent.HideActionTimeLine, self.HideActionTimeLine)
  self:AddMessageListener(MonopolyEvent.OnRefreshRoundCount, self.OnRefreshRoundCount)
  self:AddMessageListener(MonopolyEvent.OnUpdateTaskProgress, self.OnUpdateTaskProgress)
  self:AddMessageListener(MonopolyEvent.OnTeamPropChange, self.OnTeamPropChange)
  self:AddMessageListener(MonopolyEvent.RefreshActorMainPanelState, self.RefreshActorMainPanelState)
  self:AddMessageListener(MonopolyEvent.EnterSelectDirectionGrid, self.EnterSelectDirectionGrid)
  self:AddMessageListener(MonopolyEvent.LeaveSelectDirectionGrid, self.LeaveSelectDirectionGrid)
  self:AddMessageListener(MonopolyEvent.ShowBattleReportInfo, self.ShowBattleReportInfo)
  self:AddMessageListener(MonopolyEvent.HideBattleReportInfo, self.HideBattleReportInfo)
  self:AddMessageListener(MonopolyEvent.OnGridOccupyChange, self.OnGridOccupyChange)
end

function ActivityTourMainPanel:InitAllCtrl()
  self.mUITaskInfo = ActivityTourTaskInfo.New()
  self.mUITaskInfo:InitCtrl(self.ui)
  self.mUICharInfo = ActivityTourChrInfo.New()
  self.mUICharInfo:InitCtrl(self.ui)
  self.mUIActionTimeLine = ActionTimeLine.New()
  self.mUIActionTimeLine:InitCtrl(self.ui)
  self.mUIActivityTourCommand = ActivityTourCommand.New()
  self.mUIActivityTourCommand:InitCtrl(self.ui, self)
  self.mUIActivityTourBattleReport = ActivityTourBattleReport.New()
  self.mUIActivityTourBattleReport:InitCtrl(self.ui, self)
end

function ActivityTourMainPanel:OnRelease()
end

function ActivityTourMainPanel:OnClose()
  self.super.OnClose(self)
  if self.mHudCtrl then
    self.mHudCtrl:Destroy()
  end
  self.mHudCtrl = nil
  self.mTopCurrency = nil
  if self.mUITaskInfo then
    self.mUITaskInfo:Release()
    self.mUITaskInfo = nil
  end
  if self.mUICharInfo then
    self.mUICharInfo:Release()
    self.mUICharInfo = nil
  end
  if self.mUIActionTimeLine then
    self.mUIActionTimeLine:Release()
    self.mUIActionTimeLine = nil
  end
  if self.mUIActivityTourCommand then
    self.mUIActivityTourCommand:Release()
    self.mUIActivityTourCommand = nil
  end
  if self.mUIActivityTourBattleReport then
    self.mUIActivityTourBattleReport:Release()
    self.mUIActivityTourBattleReport = nil
  end
  self:OnCloseSelInfo()
  CS.DebugCenter.Instance:SetTimeScale(CS.GF2.Monopoly.MonopolyDefine.NormalGameSpeed)
end

function ActivityTourMainPanel:OnCloseSelInfo()
  if self.selGridDetail ~= nil then
    self.selGridDetail:OnRelease(true)
  end
  self.selGridDetail = nil
  if self.selRoleDetail ~= nil then
    self.selRoleDetail:OnRelease()
  end
  self.selRoleDetail = nil
  if self.activityTourTips ~= nil then
    self.activityTourTips:OnRelease()
  end
  self.activityTourTips = nil
  self.currencyTimer = nil
  if self.pointsTween ~= nil then
    LuaDOTweenUtils.Kill(self.pointsTween, false)
  end
  self.pointsTween = nil
  if self.randomPoint ~= nil then
    self.randomPoint:OnRelease()
  end
  self.randomPoint = nil
end

function ActivityTourMainPanel:ShowCommandAnimator(isShowCommand)
  if isShowCommand then
    setactive(self.ui.mTrans_CommandInfoRoot, true)
    setactive(self.ui.mAnim_Line01, false)
    setactive(self.ui.mAnim_Line01, true)
  end
  ActivityTourGlobal.ReplaceAllColor(self.ui.mTrans_CommandInfoRoot)
  if self.mUICharInfo.mShowChar then
    self.mUICharInfo:FadeInOut(not isShowCommand)
  end
  self.ui.mCVG_CharInfoRoot.blocksRaycasts = not isShowCommand
  UIUtils.AnimatorFadeInOut(self.ui.mAnimator_Command, isShowCommand)
  self.ui.mCG_CommandInfo.blocksRaycasts = isShowCommand
  UIUtils.AnimatorFadeInOut(self.ui.mAnimator_Top, not isShowCommand)
  if not isShowCommand then
    self.ui.mAnimator_Top:ResetTrigger("GrpAvatarStepList_FadeOut")
    self.ui.mAnimator_Top:SetTrigger("GrpAvatarStepList_FadeIn")
  else
    self.ui.mAnimator_Top:ResetTrigger("GrpAvatarStepList_FadeIn")
    self.ui.mAnimator_Top:SetTrigger("GrpAvatarStepList_FadeOut")
  end
  UIUtils.AnimatorFadeInOut(self.ui.mAnimator_CharOpen, not isShowCommand)
  self.mUITaskInfo:Show(not isShowCommand)
  self.ui.mBtn_TaskShow.enabled = not isShowCommand
  self.mUIActionTimeLine:FadeInOut(not isShowCommand)
end

function ActivityTourMainPanel:OnShowSelectDetail(msg)
  if not (msg and msg.Sender) or not msg.Content then
    return
  end
  local type = msg.Sender
  local id = msg.Content
  self:ShowSelectGridDetail(id)
  self:ShowSelectRoleDetail(id)
end

function ActivityTourMainPanel:OnShowActivityTourMainPanel(msg)
  local oldIsShow = self.mIsShow
  self.mIsShow = true
  local isAnim = true
  if msg.Sender ~= nil then
    isAnim = msg.Sender
  end
  setactive(self.ui.mTrans_Root, true)
  self.mUITaskInfo:RefreshAll()
  self.mUICharInfo:RefreshAll()
  self.mUIActionTimeLine:Reset(true, false)
  self.mUIActivityTourCommand:RefreshAllCommand(isAnim)
  self.mUIActivityTourCommand:HideCommandInfo()
  setactive(self.ui.mTrans_CommandInfoRoot, false)
  setactive(self.ui.mTrans_TaskTitleRoot, true)
  setactive(self.ui.mTrans_TaskInfoRoot, true)
  self.mUITaskInfo:OnlyShowRoundInfo(self.mUITaskInfo.isOnlyShowRoundInfo, true)
  self:SetGameSeed(MonopolyWorld.MpData.IsGameSpeedUp)
  self:RefreshGridOccupyInfo(false)
  if oldIsShow ~= self.mIsShow then
    self.mUIActivityTourBattleReport:ResetHeight()
  end
end

function ActivityTourMainPanel:OnHideActivityTourMainPanel(msg)
  self.mIsShow = false
  setactive(self.ui.mTrans_Root, false)
  setactive(self.ui.mTrans_TaskTitleRoot, false)
  setactive(self.ui.mTrans_TaskInfoRoot, false)
end

function ActivityTourMainPanel:OnBlockActivityTourMainPanel(msg)
  self.ui.mCG_Root.blocksRaycasts = false
  self.ui.mCVG_CommandInfo.blocksRaycasts = false
end

function ActivityTourMainPanel:OnCancelBlockActivityTourMainPanel(msg)
  self.ui.mCG_Root.blocksRaycasts = true
  self.ui.mCVG_CommandInfo.blocksRaycasts = true
end

function ActivityTourMainPanel:OnHideSelectDetail(msg)
  self:ShowSelectGridDetail(0)
  self:ShowSelectRoleDetail(0)
end

function ActivityTourMainPanel:ShowSelectGridDetail(gridId)
  if not MonopolySelectManager:IfShowGridDetail() or gridId <= 0 then
    setactive(self.ui.mTrans_GridDetail.gameObject, false)
    return
  end
  setactive(self.ui.mTrans_GridDetail.gameObject, true)
  if not self.selGridDetail then
    self.selGridDetail = ActivityTourGridDetailItem.New()
    self.selGridDetail:InitCtrl(self.ui.mTrans_GridDetail.transform)
  else
  end
  self.selGridDetail:Refresh(gridId)
end

function ActivityTourMainPanel:ShowSelectRoleDetail(gridId)
  if not MonopolySelectManager:IfShowActorDetail() or gridId <= 0 then
    setactive(self.ui.mTrans_SelInfo.gameObject, false)
    return
  end
  local role = MonopolyWorld:GetActorByGridID(gridId)
  if not role then
    setactive(self.ui.mTrans_SelInfo.gameObject, false)
    return
  end
  self:ShowSelectRoleDetailInternal(role.id)
end

function ActivityTourMainPanel:ShowSelectRoleDetailInternal(roleId)
  setactive(self.ui.mTrans_SelInfo.gameObject, true)
  if not self.selRoleDetail then
    self.selRoleDetail = ActivityTourInfoItem.New()
    self.selRoleDetail:InitCtrl(self.ui.mTrans_SelInfo.transform)
  else
  end
  self.selRoleDetail:Refresh(roleId)
end

function ActivityTourMainPanel:RefreshAndResetPoints(msg)
  self:RefreshPoints()
end

function ActivityTourMainPanel:OnShowPointTip(msg)
  self:RefreshPointsAni(msg)
end

function ActivityTourMainPanel:RefreshPoints()
  self:ResetPointsTimer()
  self.currency = MonopolyWorld.MpData.Points
  self.ui.mText_Currency.text = self.currency
end

function ActivityTourMainPanel:RefreshPointsAfterAni(newPoints, msg)
  self.currency = newPoints
  self.ui.mText_Currency.text = self.currency
  if msg.Content then
    msg.Content()
  end
end

function ActivityTourMainPanel:ResetPointsTimer()
  if self.currencyTimer then
    self.currencyTimer:Stop()
  end
  if self.pointsTween then
    LuaDOTweenUtils.Kill(self.pointsTween, false)
  end
end

function ActivityTourMainPanel:RefreshPointsAni(msg)
  self:ResetPointsTimer()
  self:RefreshPointsAniInternal(msg)
end

function ActivityTourMainPanel:RefreshPointsAniInternal(msg)
  local getter = function(tempSelf)
    return tempSelf.currency
  end
  local setter = function(tempSelf, value)
    tempSelf.ui.mText_Currency.text = math.floor(value)
  end
  local newPoints = msg.Sender
  if self.currency == newPoints then
    return
  end
  newPoints = math.max(newPoints, 0)
  self.pointsTween = LuaDOTweenUtils.ToOfFloat(self, getter, setter, newPoints, 0.5, function()
    self:RefreshPointsAfterAni(newPoints, msg)
  end)
end

function ActivityTourMainPanel:OnShowInspirationTip(msg)
  if not self.activityTourTips then
    self.activityTourTips = ActivityTourTips.New()
    self.activityTourTips:InitCtrl(self.mUIRoot.parent)
  end
  self.activityTourTips:RefreshInspiration(msg)
end

function ActivityTourMainPanel:OnShowCommandGetRightTip(msg)
  if not self.activityTourTips then
    self.activityTourTips = ActivityTourTips.New()
    self.activityTourTips:InitCtrl(self.mUIRoot.parent)
  end
  self.activityTourTips:RefreshCommand(msg)
end

function ActivityTourMainPanel:OnShowRandomPoint(msg)
  if not self.randomPoint then
    self.randomPoint = ActivityTourPointRandomItem.New()
    self.randomPoint:InitCtrl(self.ui.mTrans_PointRandom)
  end
  local rollInfo = msg.Sender
  local config = TableDataBase.listMonopolyOrderDatas:GetDataById(rollInfo.OrderId)
  if not config then
    return
  end
  local showResult = false
  local minPoint, maxPoint = ActivityTourGlobal.GetOrderMoveRange(config)
  if config.order_type == ActivityTourGlobal.CommandType_ManualMovePoint then
    showResult = true
  else
    showResult = minPoint == maxPoint
  end
  if not (minPoint and maxPoint) or maxPoint < minPoint or minPoint < 1 then
    return
  end
  setactive(self.randomPoint:GetRoot(), true)
  self.randomPoint:Refresh(minPoint, maxPoint, rollInfo.BaseRoll, rollInfo.FinRoll, rollInfo.EffectBuffs, showResult)
end

function ActivityTourMainPanel:OnBtnMapInfo()
  local stageData = NetCmdThemeData:GetLevelStageData(MonopolyWorld.MpData.levelData.id)
  if stageData == nil then
    print("\229\183\161\230\184\184\229\177\128\229\134\133\228\191\157\229\173\152\231\154\132\229\133\179\229\141\161ID\233\148\153\232\175\175 = " .. MonopolyWorld.MpData.levelData.id)
  end
  UIManager.OpenUIByParam(UIDef.ActivityTourMapInfoDialog, {openIndex = 2, levelStageData = stageData})
end

function ActivityTourMainPanel:OnFleetComplete()
  self:InitAll()
end

function ActivityTourMainPanel:OnRefreshCommand(msg)
  local slotIndex = msg.Sender
  if self.mUIActivityTourCommand then
    self.mUIActivityTourCommand:RefreshCommand(slotIndex)
  end
end

function ActivityTourMainPanel:MoveNextActionTimeLine(msg)
  self.mUIActionTimeLine:MoveNext()
end

function ActivityTourMainPanel:ResetActionTimeLine(msg)
  local isSaveIndex = msg.Sender
  local isInsertNull = msg.Content
  if msg.Sender == nil then
    isSaveIndex = false
  end
  if msg.Content == nil then
    isInsertNull = false
  end
  self.mUIActionTimeLine:Reset(isSaveIndex, isInsertNull)
end

function ActivityTourMainPanel:HideActionTimeLine(msg)
  self.mUIActionTimeLine:Hide()
end

function ActivityTourMainPanel:OnRefreshRoundCount(msg)
  self.mUITaskInfo:RefreshRoundInfo()
end

function ActivityTourMainPanel:OnUpdateTaskProgress(msg)
  local taskID = msg.Sender
  self.mUITaskInfo:RefreshWinTaskList(taskID)
  self.mUITaskInfo:RefreshFailedTaskList(taskID)
end

function ActivityTourMainPanel:OnTeamPropChange(msg)
  self.mUICharInfo:RefreshPropChange()
end

function ActivityTourMainPanel:RefreshActorMainPanelState(msg)
  local actor = msg.Sender
  if actor == nil then
    return
  end
  local isMainPlayer = actor.actorType == CS.GF2.Monopoly.MonopolyActorDefine.ActorType.MainPlayer
  if not isMainPlayer then
    self:OnBlockActivityTourMainPanel()
  end
  setactive(self.ui.mScrollListChild_Command, isMainPlayer)
  if self.mUICharInfo.mShowChar then
    self.mUICharInfo:FadeInOut(isMainPlayer)
  end
  self.ui.mCVG_CharInfoRoot.blocksRaycasts = isMainPlayer
  UIUtils.AnimatorFadeInOut(self.ui.mAnimator_Top, isMainPlayer)
  UIUtils.AnimatorFadeInOut(self.ui.mAnimator_CharOpen, isMainPlayer)
end

function ActivityTourMainPanel:EnterSelectDirectionGrid(msg)
  self:OnCancelBlockActivityTourMainPanel()
  self.ui.mCVG_CommandInfo.blocksRaycasts = false
end

function ActivityTourMainPanel:LeaveSelectDirectionGrid(msg)
  self:OnBlockActivityTourMainPanel()
end

function ActivityTourMainPanel:ShowBattleReportInfo(msg)
  local content = msg.Content
  self.mUIActivityTourBattleReport:ShowInfo(content)
end

function ActivityTourMainPanel:HideBattleReportInfo(msg)
  self.mUIActivityTourBattleReport:FadeAll()
end

function ActivityTourMainPanel:IsReadyToStartTutorial()
  return MonopolyWorld:IsInTheRoundState()
end

function ActivityTourMainPanel:OnGridOccupyChange(msg)
  self:RefreshGridOccupyInfo(true)
end

function ActivityTourMainPanel:RefreshGridOccupyInfo(isAnim)
  if not self.mIsShow then
    return
  end
  local oldPlayOccupyCount = self.mPlayerOccupyCount or 0
  local oldEnemyOccupyCount = self.mEnemyOccupyCount or 0
  self.mPlayerOccupyCount = MpGridManager:GetCampOccupyGridCount(ActivityTourGlobal.PlayerCamp_Int)
  self.mEnemyOccupyCount = MpGridManager:GetCampOccupyGridCount(ActivityTourGlobal.MonsterCamp_Int)
  local offsetPlayerOccupyCount = self.mPlayerOccupyCount - oldPlayOccupyCount
  local offsetEnemyOccupyCount = self.mEnemyOccupyCount - oldEnemyOccupyCount
  if not isAnim then
    self.ui.mText_OccupyPlayer:SetValue(self.mPlayerOccupyCount, false)
    self.ui.mText_OccupyEnemy:SetValue(self.mEnemyOccupyCount, false)
    return
  end
  if offsetPlayerOccupyCount < 0 then
    self.ui.mAnim_Occupy:SetTrigger("Player_Reduce")
    self.ui.mText_OccupyPlayer:SetValue(self.mPlayerOccupyCount, false)
  elseif 0 < offsetPlayerOccupyCount then
    self.ui.mAnim_Occupy:SetTrigger("Player_Add")
    self.ui.mText_OccupyPlayer:SetValue(self.mPlayerOccupyCount, true)
  end
  if offsetEnemyOccupyCount < 0 then
    self.ui.mAnim_Occupy:SetTrigger("Emeny_Reduce")
    self.ui.mText_OccupyEnemy:SetValue(self.mEnemyOccupyCount, false)
  elseif 0 < offsetEnemyOccupyCount then
    self.ui.mAnim_Occupy:SetTrigger("Emeny_Add")
    self.ui.mText_OccupyEnemy:SetValue(self.mEnemyOccupyCount, true)
  end
end

require("UI.UIBasePanel")
require("UI.ChapterPanel.UIChapterGlobal")
require("UI.ActivityTheme.Daiyan.DaiyanGlobal")
require("UI.ActivityGachaPanel.ActivityGachaGlobal")
DaiyanMainPanel = class("DaiyanMainPanel", UIBasePanel)
DaiyanMainPanel.__index = DaiyanMainPanel

function DaiyanMainPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
end

function DaiyanMainPanel:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListen()
end

function DaiyanMainPanel:OnInit(root, data)
  self.dyActFinish = 99903
  self.lastUpdateTime = 0
  self.isShowBox = false
  self.activityEntranceData = data.activityEntranceData
  self.activityModuleData = data.activityModuleData
  self.activityConfigData = data.activityConfigData
  self.activityPlanData = TableData.listPlanDatas:GetDataById(self.activityEntranceData.plan_id)
  CS.NetCmdThemeData.Instance.openShowingThemeId = self.activityConfigData.Id
  self:UpdateInfo()
  self:UpdateCD()
end

function DaiyanMainPanel:AddBtnListen()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.DaiyanMainPanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    UISystem:JumpToMainPanel()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Video.gameObject).onClick = function()
    CS.AVGController.PlayAvgByPlotId(self.activityConfigData.prologue, function()
    end, true)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Exchange.gameObject).onClick = function()
    if self.btnStateList[self.shopKey] == 2 or not self:CheckActivitySubmoduleOpen(self.shopKey) then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
      return
    end
    UIManager.OpenUIByParam(UIDef.UIStorePanel, CS.UIStorePanel.Param(self.shopId))
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Barrier.gameObject).onClick = function()
    if self.btnStateList[self.monopolyKey] == 2 or not self:CheckActivitySubmoduleOpen(self.monopolyKey) then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
      return
    end
    NetCmdActivitySimData:SetAnniversaryActivitySubLastEnterTime(self.activityEntranceData.Id, self.monopolyKey)
    CS.NetCmdRichManData.Instance:OpenActivityTourMainWnd(self.activityEntranceData.Id)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_ChapterEntry.gameObject).onClick = function()
    if self.btnStateList[self.chapterKey] == 2 or not self:CheckActivitySubmoduleOpen(self.chapterKey) then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
      return
    end
    NetCmdActivitySimData:SetAnniversaryActivitySubLastEnterTime(self.activityEntranceData.Id, self.chapterKey)
    self:OpenChapterPanel(self.chapterId, 1)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Hard.gameObject).onClick = function()
    if self.btnStateList[self.chapterHardKey] == 2 or not self:CheckActivitySubmoduleOpen(self.chapterHardKey) then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
      return
    end
    NetCmdActivitySimData:SetAnniversaryActivitySubLastEnterTime(self.activityEntranceData.Id, self.chapterHardKey)
    self:OpenChapterPanel(self.chapterHardId, 2)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Challenge.gameObject).onClick = function()
    if self.btnStateList[self.challangeKey] == 2 or not self:CheckActivitySubmoduleOpen(self.challangeKey) then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
      return
    end
    NetCmdActivitySimData:SetAnniversaryActivitySubLastEnterTime(self.activityEntranceData.Id, self.challangeKey)
    self:OpenChallengePanel()
  end
end

function DaiyanMainPanel:UpdateCD()
  self:ReleaseTimer()
  if self.activityModuleData.stage_type == 2 then
    local repeatCount = self.activityPlanData.close_time - CGameTime:GetTimestamp() + 1
    local cdCount = 0
    if 0 < repeatCount then
      self.cdTimer = TimerSys:DelayCall(1, function()
        cdCount = cdCount + 1
        if cdCount >= repeatCount then
          self:ReleaseTimer()
          self:OnStageChange()
        end
      end, nil, repeatCount)
    end
  end
end

function DaiyanMainPanel:ReleaseTimer()
  if self.cdTimer then
    self.cdTimer:Stop()
    self.cdTimer = nil
  end
end

function DaiyanMainPanel:OnStageChange()
  NetCmdRecentActivityData:ReqPlanActivityData(PlanType.PlanFunctionActivityThematic, function(ret)
    if ret == ErrorCodeSuc then
      local planId = NetCmdRecentActivityData:GetPlanActivityId(3)
      if 0 < planId then
        self.activityPlanData = TableData.listPlanDatas:GetDataById(planId)
        if self.activityPlanData then
          self.activityEntranceData = TableData.listActivityEntranceDatas:GetDataById(self.activityPlanData.args[0])
          if self.activityEntranceData then
            self.activityModuleData = TableData.listActivityModuleDatas:GetDataById(self.activityEntranceData.module_id)
            self:UpdateInfo()
          end
        end
      end
    end
  end)
end

function DaiyanMainPanel:UpdateInfo()
  self.btnStateList = {}
  self.challangeKey = 2002
  self.chapterKey = 2003
  self.chapterHardKey = 2004
  self.monopolyKey = 21003
  self.shopKey = 11001
  for k, v in pairs(self.activityModuleData.activity_submodule) do
    if k == self.challangeKey then
      self.challangeId = v
    elseif k == self.chapterKey then
      self.chapterId = v
    elseif k == self.chapterHardKey then
      self.chapterHardId = v
    elseif k == self.monopolyKey then
      self.monopolyId = v
    elseif k == self.shopKey then
      self.shopId = v
    end
  end
  self.chapterKeys = {
    self.chapterKey,
    self.chapterHardKey,
    self.challangeKey
  }
  self.chapterIds = {
    self.chapterId,
    self.chapterHardId,
    self.challangeId
  }
  self.mTrans_RedPoints = {
    self.ui.mTrans_ChapterRedPoint,
    self.ui.mTrans_RedPoint_Hard,
    self.ui.mTrans_RedPoint_Challenge
  }
  self.mTrans_GrpPrograsss = {
    self.ui.mTrans_GrpPrograss,
    self.ui.mTrans_GrpPrograss_Hard,
    self.ui.mTrans_GrpPrograss_Challenge
  }
  self.mTrans_GrpLocks = {
    self.ui.mTrans_GrpLock,
    self.ui.mTrans_GrpLock_Hard,
    self.ui.mTrans_GrpLock_Challenge
  }
  self.mText_Pers = {
    self.ui.mText_Per,
    self.ui.mText_Per_Hard,
    self.ui.mText_Per_Challenge
  }
  self.mTrans_ImgLocks = {
    self.ui.mTrans_ImgLock,
    self.ui.mTrans_HardImgLock,
    self.ui.mTrans_ChallengImgLock
  }
  self.mText_Texts = {
    self.ui.mTrans_Text,
    self.ui.mTrans_HardText,
    self.ui.mText_ChallengText
  }
  for k, v in pairs(self.activityModuleData.entrance_type) do
    self.btnStateList[k] = v
  end
  self.ui.mText_Title.text = self.activityEntranceData.name.str
  self.ui.mText_Describe.text = self.activityModuleData.activity_information.str
  if self.activityModuleData == 3 then
    setactive(self.ui.mTrans_ExchangeRedPoint.gameObject, false)
    setactive(self.ui.mTrans_BarrierRedPoint.gameObject, false)
  else
    setactive(self.ui.mTrans_ExchangeRedPoint.gameObject, false)
    setactive(self.ui.mTrans_BarrierRedPoint.gameObject, NetCmdActivitySimData:HasAnniversaryActivitySubRedDot(self.activityEntranceData.Id, self.monopolyKey))
  end
  self:UpdateStageState()
  self:RefreshBtnState()
  setactive(self.ui.mBtn_Video.gameObject, self.activityConfigData.prologue > 0)
  self.ui.mImg_Bg.sprite = IconUtils.GetActivityThemeSprite("ActivityTheme_A/Daiyan/" .. self.activityModuleData.activity_main_bg)
  if self.btnStateList[self.chapterKey] == 2 or self.btnStateList[self.chapterKey] == 3 then
    self.ui.mText_Per.text = TableData.GetHintById(192046)
  end
  self.ui.mBtn_Exchange.interactable = self.btnStateList[self.shopKey] ~= 3
  self.ui.mBtn_Barrier.interactable = self.btnStateList[self.monopolyKey] ~= 3
  self.ui.mBtn_ChapterEntry.interactable = self.btnStateList[self.chapterKey] ~= 3
  setactive(self.ui.mBtn_Exchange.gameObject, self.btnStateList[self.shopKey] ~= 4)
  setactive(self.ui.mBtn_Barrier.gameObject, self.btnStateList[self.monopolyKey] ~= 4)
  setactive(self.ui.mBtn_ChapterEntry.gameObject, self.btnStateList[self.chapterKey] ~= 4)
end

function DaiyanMainPanel:RefreshBtnState()
  setactive(self.ui.mTrans_Locked, not self:CheckActivitySubmoduleOpen(self.shopKey))
  setactive(self.ui.mTrans_Locked1, not self:CheckActivitySubmoduleOpen(self.monopolyKey))
  for i = 1, 3 do
    if self.activityModuleData.stage_type == 1 or self.activityModuleData.stage_type == 2 then
      local chapterData = TableData.listChapterDatas:GetDataById(self.chapterIds[i])
      if chapterData then
        local lockStr = CS.LuaUIUtils.CheckUnlockPopupStrByRepeatedList(chapterData.unlock)
        local isOpen, _, type = self:CheckActivitySubmoduleOpen(self.chapterKeys[i])
        local isLock = string.len(lockStr) > 0 or not isOpen
        setactive(self.mTrans_GrpLocks[i], isLock)
        setactive(self.mTrans_GrpPrograsss[i], not isLock)
        if isLock then
          if type & 2 ~= 0 then
            setactive(self.mTrans_ImgLocks[i], false)
            self.mText_Texts[i].text = TableData.GetHintById(273009)
          elseif type & 4 ~= 0 then
            setactive(self.mTrans_ImgLocks[i], false)
            self.mText_Texts[i].text = TableData.GetHintById(273011)
          elseif type & 1 ~= 0 then
            setactive(self.mTrans_ImgLocks[i], true)
            self.mText_Texts[i].text = TableData.GetHintById(273009)
          end
        end
        if 0 < chapterData.chapter_reward_value.Count then
          local stars = NetCmdDungeonData:GetCurStarsByChapterID(chapterData.id)
          local totalCount = chapterData.chapter_reward_value[chapterData.chapter_reward_value.Count - 1]
          if stars == 0 or totalCount == 0 then
            self.mText_Pers[i].text = "0%"
          else
            self.mText_Pers[i].text = math.ceil(stars / totalCount * 100) .. "%"
          end
        else
          local chapterInfo = TableData.GetStorysByChapterID(chapterData.id)
          local compCount = NetCmdDungeonData:GetChapterCompteCount(chapterData.id)
          if chapterInfo then
            self.mText_Pers[i].text = math.ceil(compCount / chapterInfo.Count * 100) .. "%"
          else
            self.mText_Pers[i].text = "0%"
          end
        end
        setactive(self.mTrans_RedPoints[i], NetCmdActivitySimData:HasAnniversaryActivitySubRedDot(self.activityEntranceData.Id, self.chapterKeys[i], true, false))
      end
    else
      self.mText_Pers[i].text = TableData.GetHintById(192046)
      setactive(self.mTrans_RedPoints[i], false)
    end
  end
end

function DaiyanMainPanel:CheckActivitySubmoduleOpen(subModuleId)
  local isOpen, planData, type = NetCmdActivitySimData:CheckAnniversaryActivitySubmoduleOpen(self.activityEntranceData.Id, subModuleId)
  return isOpen, planData, type
end

function DaiyanMainPanel:UpdateStageState()
  setactive(self.ui.mTrans_State.gameObject, false)
  setactive(self.ui.mTrans_SecondOnGoing.gameObject, false)
  if self.activityPlanData ~= nil then
    local serverTime = CS.CGameTime.Instance:GetTimestamp()
    if serverTime >= self.activityPlanData.open_time and serverTime < self.activityPlanData.close_time then
      local closeDiffTime = self.activityPlanData.close_time - serverTime
      self.ui.mText_LastTime.text = string_format(TableData.GetHintById(273001), CS.CGameTime.ReturnDurationBySecAuto(closeDiffTime))
    else
      self.ui.mText_LastTime.text = TableData.GetHintById(340002)
      if not self.isShowBox then
        self.isShowBox = true
        NetCmdActivitySimData:ShowActivityEndBoxPanel()
      end
    end
  end
end

function DaiyanMainPanel:OpenChapterPanel(chapterId, diff)
  if self.chapterId == nil then
    return
  end
  local chapterData = TableData.listChapterDatas:GetDataById(chapterId)
  if chapterData == nil then
    return
  end
  local lockStr = CS.LuaUIUtils.CheckUnlockPopupStrByRepeatedList(chapterData.unlock)
  local isLock = string.len(lockStr) > 0
  if isLock then
    CS.PopupMessageManager.PopupString(lockStr)
    return
  end
  NetCmdThemeData.currSelectChapterId = chapterId
  NetCmdThemeData:SetThemeChapterDiff(chapterId, diff)
  local param = CS.UIActivityThemeBChapterPanel.UIParams(false, self.activityPlanData.Id, self.activityConfigData.Id, self.activityModuleData)
  UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIActivityThemeBChapterPanel, param)
end

function DaiyanMainPanel:OpenChallengePanel()
  local chapterData = TableDataBase.listChapterDatas:GetDataById(self.challangeId)
  if chapterData == nil then
    CS.PopupMessageManager:PopupString(TableData:GetHintById(260007))
    return
  end
  local param = CS.UIActivityThemeBChallengePanel.UIParams(0, self.challangeId, chapterData.PlanId, self.activityConfigData.Id)
  UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIActivityThemeBChallengePanel, param)
end

function DaiyanMainPanel:OnShowStart()
end

function DaiyanMainPanel:OnShowFinish()
end

function DaiyanMainPanel:OnTop()
end

function DaiyanMainPanel:OnUpdate()
  if Time.time - self.lastUpdateTime >= 1 then
    self.lastUpdateTime = Time.time
    self:UpdateStageState()
    self:RefreshBtnState()
  end
end

function DaiyanMainPanel:OnBackFrom()
  self:UpdateInfo()
  self:UpdateCD()
end

function DaiyanMainPanel:OnClose()
  self:ReleaseTimer()
end

function DaiyanMainPanel:OnHide()
  self:ReleaseTimer()
end

function DaiyanMainPanel:OnHideFinish()
end

function DaiyanMainPanel:OnRelease()
end

function DaiyanMainPanel:ActivityIsFinish()
  local serverTime = CGameTime:GetTimestamp()
  local activityEntranceData = TableData.listActivityEntranceDatas:GetDataById(self.dyActFinish)
  if activityEntranceData == nil then
    return false
  end
  local currPlanData = TableData.listPlanDatas:GetDataById(activityEntranceData.PlanId)
  if currPlanData == nil then
    return false
  end
  if serverTime > currPlanData.CloseTime then
    return true
  end
  return false
end

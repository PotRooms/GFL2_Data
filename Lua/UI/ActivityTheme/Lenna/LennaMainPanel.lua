require("UI.UIBasePanel")
require("UI.ChapterPanel.UIChapterGlobal")
require("UI.ActivityTheme.Daiyan.DaiyanGlobal")
require("UI.ActivityGachaPanel.ActivityGachaGlobal")
LennaMainPanel = class("LennaMainPanel", UIBasePanel)
LennaMainPanel.__index = LennaMainPanel
local Easy = 1
local Hard = 2
local StateLock = 1
local StateAvailable = 2
local StateOVer = 3

function LennaMainPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
end

function LennaMainPanel:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.diffNameList = {
    103201,
    103202,
    103203
  }
  self:AddBtnListen()
  self:InitComponent()
end

function LennaMainPanel:AddBtnListen()
  UIUtils.GetButtonListener(self.ui.mBtn_Back).onClick = function()
    UIManager.CloseUI(UIDef.LennaMainPanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home).onClick = function()
    UISystem:JumpToMainPanel()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Video).onClick = function()
    CS.AVGController.PlayAvgByPlotId(self.activityConfigData.prologue, function()
    end, true)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Exchange).onClick = function()
    local collectionData = TableData.listCollectionThemeDatas:GetDataById(self.collectId)
    if collectionData and not AccountNetCmdHandler:CheckSystemIsUnLock(collectionData.unlock) then
      local unlockData = TableDataBase.listUnlockDatas:GetDataById(collectionData.unlock)
      if unlockData then
        local str = UIUtils.CheckUnlockPopupStr(unlockData)
        PopupMessageManager.PopupString(str)
      end
      return
    end
    if self.btnStateList[5001] == 2 or self:ActivityIsFinish() then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
      return
    end
    local id
    for k, v in pairs(self.activityModuleData.activity_submodule) do
      if k == 5001 then
        id = v
        break
      end
    end
    UIManager.OpenUIByParam(UIDef.LennaMusePanel, {
      activity = self.activityConfigData.id,
      themeId = self.activityEntranceData.id,
      moduleId = id
    })
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Barrier).onClick = function()
    local monopolyData = TableData.listMonopolyConfigDatas:GetDataById(self.monopolyId)
    if monopolyData and not AccountNetCmdHandler:CheckSystemIsUnLock(monopolyData.unlock) then
      local unlockData = TableDataBase.listUnlockDatas:GetDataById(monopolyData.unlock)
      if unlockData then
        local str = UIUtils.CheckUnlockPopupStr(unlockData)
        PopupMessageManager.PopupString(str)
      end
      return
    end
    if self.btnStateList[3002] == 2 then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
      return
    end
    NetCmdThemeData:SetCurrLevelIndex(0, true)
    NetCmdThemeData:SendMonopolyInfo(self.activityEntranceData.id, function(ret)
      if ret == ErrorCodeSuc then
        UIManager.OpenUIByParam(UIDef.ActivityTourDifficultySelectPanel, {
          themeId = self.activityEntranceData.id,
          activityId = self.activityConfigData.Id,
          monopolyId = self.monopolyId
        })
      end
    end)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Gacha).onClick = function()
    if self.btnStateList[4001] == 2 then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
      return
    end
    self:EnterGacha()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_ChapterEntry).onClick = function()
    if self.btnStateList[2001] == 2 then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
      return
    end
    if self.chapterId == nil then
      return
    end
    local chapterData = TableData.listChapterDatas:GetDataById(self.chapterId)
    if chapterData == nil then
      return
    end
    UIManager.OpenUIByParam(UIDef.LennaChapterPanel, {
      ChapterData = chapterData,
      ActivityConfigId = self.activityConfigData.Id,
      ChapterModelId = self.chapterModelId
    })
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Challenge).onClick = function()
    if self.btnStateList[LuaUtils.EnumToInt(SubmoduleType.ActivityStoryChallenge)] == LuaUtils.EnumToInt(ThemeEntranceStatus.Close) then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
      return
    end
    local chapterData = TableData.listChapterDatas:GetDataById(self.challengeId)
    if chapterData == nil then
      return
    end
    if not self.activityConfigData then
      return
    end
    local challengePlan = TableData.listPlanDatas:GetDataById(chapterData.plan_id)
    local now = CGameTime:GetTimestamp()
    local open = challengePlan and now >= challengePlan.open_time and now < challengePlan.close_time
    if open then
      UIManager.OpenUIByParam(UIDef.LennaChallengePanel, {
        ChapterData = chapterData,
        PlanId = self.activityEntranceData.plan_id,
        ActivityConfigId = self.activityConfigData.Id
      })
    elseif now < challengePlan.open_time then
      local str = CS.CGameTime.ReturnDurationBySecAuto(challengePlan.open_time - now)
      local hintStr = string_format(TableData.GetActivityHint(22002004, self.activityConfigData.Id, 2, 2002, self.challengeId), str)
      CS.PopupMessageManager.PopupString(hintStr)
    else
      CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
    end
  end
end

function LennaMainPanel:GetChapterState(id)
  local chapterData = TableData.listChapterDatas:GetDataById(id)
  local challengePlan = TableData.listPlanDatas:GetDataById(chapterData.plan_id)
  local now = CGameTime:GetTimestamp()
  local open = challengePlan and now >= challengePlan.open_time and now < challengePlan.close_time
  if open and self.activityModuleData.stage_type == 2 then
    return StateAvailable
  end
  if now < challengePlan.open_time then
    return StateLock
  end
  return StateOVer
end

function LennaMainPanel:InitComponent()
  self.ui.mText_GachaName = self.ui.mBtn_Gacha.transform:Find("Text_Name"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  self.ui.mTrans_GachaRedPoint = self.ui.mBtn_Gacha.transform:Find("Trans_RedPoint")
  self.ui.mText_BarrierName = self.ui.mBtn_Barrier.transform:Find("Text_Name"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  self.ui.mTrans_BarrierRedPoint = self.ui.mBtn_Barrier.transform:Find("Trans_RedPoint")
  self.ui.mTrans_Locked1 = self.ui.mBtn_Barrier.transform:GetComponent(typeof(CS.UnityEngine.Animator))
  self.ui.mTrans_Enable = self.ui.mBtn_Barrier.transform:Find("ImgIcon")
  self.ui.mTrans_Disable = self.ui.mBtn_Barrier.transform:Find("ImgOver")
  self.ui.mText_ExchangeName = self.ui.mBtn_Exchange.transform:Find("Text_Name"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  self.ui.mTrans_ExchangeRedPoint = self.ui.mBtn_Exchange.transform:Find("Trans_RedPoint")
  self.ui.mTrans_Locked = self.ui.mBtn_Exchange:GetComponent(typeof(CS.UnityEngine.Animator))
  self.ui.mText_Chapter = self.ui.mBtn_ChapterEntry.transform:Find("Root/Text_Name"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  self.ui.mAnim_Chapter = self.ui.mBtn_ChapterEntry.transform:GetComponent(typeof(CS.UnityEngine.Animator))
  self.ui.mTrans_ChapterRedPoint = self.ui.mBtn_ChapterEntry.transform:Find("Root/Trans_RedPoint")
  self.ui.mTrans_Easy = self.ui.mBtn_ChapterEntry.transform:Find("Root/GrpMode/GrpEasy")
  self.ui.mTrans_Hard = self.ui.mBtn_ChapterEntry.transform:Find("Root/GrpMode/GrpHard")
  self.ui.mText_ChapterNum = self.ui.mBtn_ChapterEntry.transform:Find("Root/GrpMode/GrpNum/Text_Num"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  self.ui.mTrans_ChapterLocked = self.ui.mBtn_ChapterEntry.transform:Find("Root/ImgLocked")
  self.ui.mTrans_ChapterAvailable = self.ui.mBtn_ChapterEntry.transform:Find("Root/ImgIcon")
  self.ui.mTrans_ChapterOver = self.ui.mBtn_ChapterEntry.transform:Find("Root/ImgOver")
  self.ui.mText_Challenge = self.ui.mBtn_Challenge.transform:Find("Root/Text_Name"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  self.ui.mAnim_Challenge = self.ui.mBtn_Challenge.transform:GetComponent(typeof(CS.UnityEngine.Animator))
  self.ui.mTrans_ChallengeRedPoint = self.ui.mBtn_Challenge.transform:Find("Root/Trans_RedPoint")
  self.ui.mTrans_Challenge = self.ui.mBtn_Challenge.transform:Find("Root/GrpMode/GrpChallenge")
  self.ui.mText_ChallengeNum = self.ui.mBtn_Challenge.transform:Find("Root/GrpMode/GrpNum/Text_Num"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  self.ui.mTrans_ChallengeLocked = self.ui.mBtn_Challenge.transform:Find("Root/ImgLocked")
  self.ui.mTrans_ChallengeAvailable = self.ui.mBtn_Challenge.transform:Find("Root/ImgIcon")
  self.ui.mTrans_ChallengeOver = self.ui.mBtn_Challenge.transform:Find("Root/ImgOver")
end

function LennaMainPanel:OnInit(root, data)
  self:InitCamera()
  self:SetVisible(false)
  if data == nil then
    self:OnServerReq()
  else
    self.activityEntranceData = data.activityEntranceData
    self.activityModuleData = data.activityModuleData
    self.activityConfigData = data.activityConfigData
    self.activityPlanData = TableData.listPlanDatas:GetDataById(self.activityEntranceData.plan_id)
    self:UpdateInfo()
    self:UpdateCD()
  end
end

function LennaMainPanel:OnServerReq()
  NetCmdRecentActivityData:ReqPlanActivityData(PlanType.PlanFunctionActivityThematic, function(ret)
    if ret == ErrorCodeSuc then
      local planActivityId = NetCmdThemeData:GetThemePlanId()
      self.activityPlanData = TableData.listPlanDatas:GetDataById(planActivityId, true)
      if self.activityPlanData == nil then
        UIManager.CloseUI(UIDef.LennaMainPanel)
        return
      end
      self.activityEntranceData = TableData.listActivityEntranceDatas:GetDataById(self.activityPlanData.args[0])
      self.activityModuleData = TableData.listActivityModuleDatas:GetDataById(self.activityEntranceData.module_id)
      self.activityConfigData = NetCmdThemeData:GetActivityDataByEntranceId(self.activityEntranceData.id)
      self:UpdateInfo()
      self:UpdateCD()
    end
  end)
end

function LennaMainPanel:UpdateCD()
  self:ReleaseTimer()
  self:CreateCDTimer()
  self:CreateChallengeTimer()
end

function LennaMainPanel:CreateCDTimer()
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

function LennaMainPanel:CreateChallengeTimer()
  local chapterData = TableData.listChapterDatas:GetDataById(self.challengeId)
  if chapterData == nil then
    return
  end
  if not self.activityConfigData then
    return
  end
  local challengePlan = TableData.listPlanDatas:GetDataById(chapterData.plan_id)
  local now = CGameTime:GetTimestamp()
  if now < challengePlan.open_time then
    self.challengeTimer = TimerSys:UnscaledDelayCall(challengePlan.open_time - now, function()
      self:UpdateInfo()
    end)
  end
end

function LennaMainPanel:ReleaseTimer()
  if self.cdTimer then
    self.cdTimer:Stop()
    self.cdTimer = nil
  end
  if self.challengeTimer ~= nil then
    self.challengeTimer:Stop()
    self.challengeTimer = nil
  end
  if self.delayAnimTimer ~= nil then
    self.delayAnimTimer:Stop()
    self.delayAnimTimer = nil
  end
end

function LennaMainPanel:OnStageChange()
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

function LennaMainPanel:UpdateInfo()
  self:SetVisible(true)
  self.btnStateList = {}
  for k, v in pairs(self.activityModuleData.activity_submodule) do
    if k == 2001 then
      self.chapterId = v
      self.chapterModelId = v
    elseif k == 2002 then
      self.challengeId = v
    elseif k == 4001 then
      self.gachaponId = v
    elseif k == 3002 then
      self.monopolyId = v
    elseif k == 5001 then
      self.collectId = v
    end
  end
  for k, v in pairs(self.activityModuleData.entrance_type) do
    self.btnStateList[k] = v
  end
  if self.gachaponId == nil then
    self.gachaponId = 104
  end
  if self.monopolyId == nil then
    self.monopolyId = 103
  end
  if self.chapterId == nil then
    self.chapterId = 4006
  end
  if self.chapterModelId == nil then
    self.chapterModelId = 4006
  end
  if self.challengeId == nil then
    self.challengeId = 994004
  end
  if self.collectId == nil then
    self.collectId = 103
  end
  local selectDiff = 1
  local chapterData = TableData.listChapterDatas:GetDataById(self.chapterId)
  if NetCmdThemeData.currSelectChapterId > 0 then
    selectDiff = NetCmdThemeData:GetActivityEndDiffIndex(NetCmdThemeData.currSelectChapterId)
    local currSelectData = TableData.listChapterDatas:GetDataById(NetCmdThemeData.currSelectChapterId, true)
    if currSelectData and currSelectData.difficulty_group == chapterData.difficulty_group then
      self.chapterId = currSelectData.id
      chapterData = currSelectData
    end
  else
    local diffChapterList = TableData.listChapterByDifficultyGroupDatas:GetDataById(chapterData.difficulty_group)
    for i = 1, diffChapterList.Id.Count do
      local diff = NetCmdThemeData:GetThemeChapterDiff(diffChapterList.Id[i - 1])
      if 0 < diff then
        selectDiff = diff
        self.chapterId = diffChapterList.Id[i - 1]
        break
      end
    end
  end
  self.chapterData = TableData.listChapterDatas:GetDataById(self.chapterId)
  self.challengeData = TableData.listChapterDatas:GetDataById(self.challengeId)
  local gachaponData = TableData.listActivityGachaConfigDatas:GetDataById(self.gachaponId)
  if gachaponData then
    self.ui.mText_GachaName.text = gachaponData.activity_name.str
  end
  local monopolyData = TableData.listMonopolyConfigDatas:GetDataById(self.monopolyId)
  if monopolyData then
    self.ui.mText_BarrierName.text = monopolyData.monopoly_name.str
  end
  local collectionData = TableData.listCollectionThemeDatas:GetDataById(self.collectId)
  if collectionData then
    self.ui.mText_ExchangeName.text = collectionData.name.str
  end
  self:UpdateStageState()
  self.ui.mText_Title.text = self.activityEntranceData.name.str
  self.ui.mText_TitleShadow.text = self.activityEntranceData.name.str
  self.ui.mText_Describe.text = self.activityModuleData.activity_information.str
  if self.activityModuleData == 3 then
    setactive(self.ui.mTrans_ExchangeRedPoint, false)
    setactive(self.ui.mTrans_BarrierRedPoint, false)
  else
    setactive(self.ui.mTrans_ExchangeRedPoint, AccountNetCmdHandler:CheckSystemIsUnLock(collectionData.unlock) and NetCmdThemeData:ThemeCollectRed(self.collectId))
    setactive(self.ui.mTrans_BarrierRedPoint, AccountNetCmdHandler:CheckSystemIsUnLock(monopolyData.unlock) and NetCmdThemeData:MissionRed())
  end
  CSUIUtils.GetAndSetActivityHintText(self.ui.mTrans_GachaRedPoint, self.activityConfigData.id, 2, 3002, self.monopolyId)
  CSUIUtils.GetAndSetActivityHintText(self.ui.mTrans_BarrierRedPoint, self.activityConfigData.id, 2, 3002, self.monopolyId)
  CSUIUtils.GetAndSetActivityHintText(self.ui.mTrans_ExchangeRedPoint, self.activityConfigData.id, 2, 3002, self.monopolyId)
  CSUIUtils.GetAndSetActivityHintText(self.ui.mTrans_ChapterRedPoint, self.activityConfigData.id, 2, 3002, self.monopolyId)
  CSUIUtils.GetAndSetActivityHintText(self.ui.mTrans_ChallengeRedPoint, self.activityConfigData.id, 2, 3002, self.monopolyId)
  CSUIUtils.GetAndSetActivityHintText(self.ui.mTrans_Tips, self.activityConfigData.id, 2, 3002, self.monopolyId)
  CSUIUtils.GetAndSetActivityHintText(self.ui.mTrans_Easy, self.activityConfigData.id, 2, 2001, self.chapterModelId)
  CSUIUtils.GetAndSetActivityHintText(self.ui.mTrans_Hard, self.activityConfigData.id, 2, 2001, self.chapterModelId)
  CSUIUtils.GetAndSetActivityHintText(self.ui.mTrans_Challenge, self.activityConfigData.id, 2, 2002, self.challengeId)
  if self.chapterData then
    local stateChapter = self:GetChapterState(self.chapterModelId)
    if stateChapter == StateAvailable then
      self.ui.mAnim_Chapter:SetBool("Locked", false)
    else
      self.ui.mAnim_Chapter:SetBool("Locked", true)
    end
    setactivewithcheck(self.ui.mTrans_ChapterAvailable, stateChapter == StateAvailable)
    setactivewithcheck(self.ui.mTrans_ChapterLocked, stateChapter == StateLock)
    setactivewithcheck(self.ui.mTrans_ChapterOver, stateChapter == StateOVer)
    NetCmdThemeData:UpdateLevelInfo(self.chapterData.stage_group)
    self.ui.mText_Chapter.text = self.chapterData.tab_name.str
    local difficulty_type = self.chapterData.difficulty_type
    setactive(self.ui.mTrans_Easy, difficulty_type == Easy and stateChapter == StateAvailable)
    setactive(self.ui.mTrans_Hard, difficulty_type == Hard and stateChapter == StateAvailable)
    local stars = NetCmdDungeonData:GetCurStarsByChapterID(self.chapterData.id)
    local totalCount = self.chapterData.chapter_reward_value[self.chapterData.chapter_reward_value.Count - 1]
    if stars == 0 or totalCount == 0 then
      self.ui.mText_ChapterNum.text = "0%"
    else
      self.ui.mText_ChapterNum.text = math.ceil(stars / totalCount * 100) .. "%"
    end
    self.ui.mText_ChapterNum.text = stateChapter == StateAvailable and self.ui.mText_ChapterNum.text or ""
    if self.activityModuleData.stage_type == 2 then
      if 0 < self.chapterData.chapter_reward_value.Count then
        if self.btnStateList[2001] == 2 or self.btnStateList[2001] == 3 then
          setactive(self.ui.mTrans_ChapterRedPoint, false)
        else
          local hasRed = false
          local diffData = TableData.listChapterByDifficultyGroupDatas:GetDataById(self.chapterData.difficulty_group)
          if diffData then
            for i = 0, diffData.Id.Count - 1 do
              if 0 < NetCmdDungeonData:UpdateChatperRewardRedPoint(diffData.Id[i]) then
                hasRed = true
                break
              end
            end
            for i = 0, diffData.Id.Count - 1 do
              local id = diffData.Id[i]
              if NetCmdThemeData:ShowHardChapterFirstRedPoint(id) then
                hasRed = true
                break
              end
            end
          end
          setactive(self.ui.mTrans_ChapterRedPoint, hasRed)
        end
      else
        setactive(self.ui.mTrans_ChapterRedPoint, false)
      end
    else
      setactive(self.ui.mTrans_ChapterRedPoint, false)
    end
  else
    self.ui.mText_Chapter.text = ""
    self.ui.mText_ChapterNum.text = ""
    setactive(self.ui.mTrans_Easy, false)
    setactive(self.ui.mTrans_Hard, false)
    setactivewithcheck(self.ui.mTrans_ChapterAvailable, false)
    setactivewithcheck(self.ui.mTrans_ChapterLocked, true)
    setactivewithcheck(self.ui.mTrans_ChapterOver, false)
    self.ui.mAnim_Chapter:SetBool("Locked", true)
  end
  if self.challengeData then
    local stateChallenge = self:GetChapterState(self.challengeId)
    if stateChallenge == StateAvailable then
      self.ui.mAnim_Challenge:SetBool("Locked", false)
    else
      self.ui.mAnim_Challenge:SetBool("Locked", true)
    end
    setactivewithcheck(self.ui.mTrans_ChallengeAvailable, stateChallenge == StateAvailable)
    setactivewithcheck(self.ui.mTrans_ChallengeLocked, stateChallenge == StateLock)
    setactivewithcheck(self.ui.mTrans_ChallengeOver, stateChallenge == StateOVer)
    NetCmdThemeData:UpdateLevelInfo(self.challengeData.stage_group)
    self.ui.mText_Challenge.text = self.challengeData.tab_name.str
    if stateChallenge == StateAvailable then
      local chapterInfo = TableData.GetStorysByChapterID(self.challengeData.id)
      local compCount = NetCmdDungeonData:GetChapterPassedCount(self.challengeData.id)
      if chapterInfo then
        self.ui.mText_ChallengeNum.text = math.ceil(compCount / chapterInfo.Count * 100) .. "%"
      else
        self.ui.mText_ChallengeNum.text = "0%"
      end
    else
      self.ui.mText_ChallengeNum.text = ""
      setactivewithcheck(self.ui.mTrans_Challenge, false)
    end
    if self.activityModuleData.stage_type == 2 then
      if 0 < self.challengeData.chapter_reward_value.Count then
        if self.btnStateList[2002] == 2 or self.btnStateList[2002] == 3 then
          setactive(self.ui.mTrans_ChallengeRedPointRedPoint, false)
        else
          local hasRed = false
          local diffData = TableData.listChapterByDifficultyGroupDatas:GetDataById(self.challengeData.difficulty_group)
          if diffData then
            for i = 0, diffData.Id.Count - 1 do
              if 0 < NetCmdDungeonData:UpdateChatperRewardRedPoint(diffData.Id[i]) then
                hasRed = true
                break
              end
            end
          end
          setactive(self.ui.mTrans_ChallengeRedPoint, hasRed)
        end
      else
        setactive(self.ui.mTrans_ChallengeRedPoint, false)
      end
    else
      setactive(self.ui.mTrans_ChallengeRedPoint, false)
    end
  else
    self.ui.mText_Challenge.text = ""
    self.ui.mText_ChallengeNum.text = ""
    setactivewithcheck(self.ui.mTrans_Challenge, false)
    setactivewithcheck(self.ui.mTrans_ChallengeAvailable, false)
    setactivewithcheck(self.ui.mTrans_ChallengeLocked, true)
    setactivewithcheck(self.ui.mTrans_ChallengeOver, false)
    self.ui.mAnim_Chapter:SetBool("Locked", true)
  end
  setactive(self.ui.mBtn_Video, 0 < self.activityConfigData.prologue)
  self:RefreshGachaButton()
  self.ui.mTrans_Locked:SetBool("Locked", not AccountNetCmdHandler:CheckSystemIsUnLock(collectionData.unlock))
  local monopolyEnable = AccountNetCmdHandler:CheckSystemIsUnLock(monopolyData.unlock) and self.btnStateList[3002] == 1
  self.ui.mTrans_Locked1:SetBool("Locked", not monopolyEnable)
  setactivewithcheck(self.ui.mTrans_Enable, monopolyEnable)
  setactivewithcheck(self.ui.mTrans_Disable, not monopolyEnable)
  self.ui.mBtn_Exchange.interactable = self.btnStateList[5001] ~= 3
  self.ui.mBtn_Barrier.interactable = self.btnStateList[3002] ~= 3
  self.ui.mBtn_Gacha.interactable = self.btnStateList[4001] ~= 3
  self.ui.mBtn_ChapterEntry.interactable = self.btnStateList[2001] ~= 3
  setactive(self.ui.mBtn_Exchange, self.btnStateList[5001] ~= 4)
  setactive(self.ui.mBtn_Barrier, self.btnStateList[3002] ~= 4)
  setactive(self.ui.mBtn_Gacha, self.btnStateList[4001] ~= 4)
  setactive(self.ui.mBtn_ChapterEntry, self.btnStateList[2001] ~= 4)
  local open = CGameTime:GetTimestamp() >= self.activityPlanData.open_time and CGameTime:GetTimestamp() < self.activityPlanData.close_time
  if self.btnStateList[LuaUtils.EnumToInt(SubmoduleType.ActivityMonopoly)] == LuaUtils.EnumToInt(ThemeEntranceStatus.Open) and open then
    NetCmdThemeData:SendMonopolyInfo(self.activityEntranceData.id, function(ret)
      if ret == ErrorCodeSuc then
        setactivewithcheck(self.ui.mTrans_Tips, NetCmdThemeData:HasPlayingStage() and open)
      end
    end)
  else
    setactivewithcheck(self.ui.mTrans_Tips, false)
  end
end

function LennaMainPanel:UpdateStageState()
  local serverTime = CGameTime:GetTimestamp()
  self.ui.mText_EventTime.text = TableData.GetActivityHint(23002006, self.activityConfigData.Id, 2, 3002, self.monopolyId)
  for i = 1, self.activityConfigData.activity_entrance.Count do
    local entranceData = TableData.listActivityEntranceDatas:GetDataById(self.activityConfigData.activity_entrance[i - 1])
    if entranceData then
      local planData = TableData.listPlanDatas:GetDataById(entranceData.plan_id, true)
      if planData and serverTime >= planData.open_time and serverTime <= planData.close_time then
        local currOpenData = CS.CGameTime.ConvertLongToDateTime(planData.open_time)
        local currCloseData = CS.CGameTime.ConvertLongToDateTime(planData.close_time)
        local currOpenTime, currCloseTime
        if currOpenData.Year == currCloseData.Year then
          currOpenTime = currOpenData:ToString("MM.dd/HH:mm")
          currCloseTime = currCloseData:ToString("MM.dd/HH:mm")
        else
          currOpenTime = currOpenData:ToString("yyyy.MM.dd/HH:mm")
          currCloseTime = currCloseData:ToString("yyyy.MM.dd/HH:mm")
        end
        self.ui.mText_LastTime.text = currOpenTime .. " - " .. currCloseTime
        break
      end
    end
  end
end

function LennaMainPanel:OnShowStart()
  AudioUtils.PlayCommonAudio(1020457)
end

function LennaMainPanel:OnTop()
end

function LennaMainPanel:OnBackFrom()
  self:InitCamera()
  self:SetVisible(false)
  if self.activityPlanData == nil then
    self:OnServerReq()
  elseif CGameTime:GetTimestamp() < self.activityPlanData.open_time or CGameTime:GetTimestamp() >= self.activityPlanData.close_time then
    self:OnServerReq()
  else
    self:UpdateInfo()
    self:UpdateCD()
  end
  AudioUtils.PlayCommonAudio(1020457)
end

function LennaMainPanel:OnClose()
  self:ReleaseTimer()
end

function LennaMainPanel:OnHide()
  self:ReleaseTimer()
  AudioUtils.PlayCommonAudio(1020458)
end

function LennaMainPanel:OnHideFinish()
  self:ResetCamera()
end

function LennaMainPanel:OnBeCovered()
  self:ReleaseTimer()
end

function LennaMainPanel:OnRelease()
end

function LennaMainPanel:RefreshGachaButton()
  setactive(self.ui.mBtn_Gacha, false)
  setactive(self.ui.mTrans_GachaRedPoint, false)
  if self.gachaponId <= 0 then
    return
  end
  setactive(self.ui.mBtn_Gacha.gameObject, true)
  if not NetCmdActivityGachaData:IfInActTimeAndUnlock(self.gachaponId) then
    return
  end
  NetCmdActivityGachaData:CheckSendCS_ActivityGachaSettle(self.activityConfigData.Id)
  local bShow = NetCmdActivityGachaData:IfShowRedPoint(self.activityModuleData)
  setactive(self.ui.mTrans_GachaRedPoint, bShow)
end

function LennaMainPanel:EnterGacha()
  if self.gachaponId <= 0 then
    return
  end
  local data = NetCmdActivityGachaData:GetActivityGachaByActId(self.activityConfigData.Id)
  if not data then
    return
  end
  local endTime = NetCmdActivityGachaData:GetActEndTime(self.activityConfigData.Id)
  if endTime < CGameTime:GetTimestamp() then
    PopupMessageManager.PopupString(TableData.GetHintById(260007))
    return
  end
  if self.ui.mTrans_GachaRedPoint.gameObject.activeSelf and NetCmdActivityGachaData:IfShowEnterRedPoint(self.activityModuleData) then
    if not NetCmdActivityGachaData:IfShowRoundRedPoint(self.activityModuleData) then
      setactive(self.ui.mTrans_GachaRedPoint.gameObject, false)
    end
    NetCmdActivityGachaData:SetEntryPrefs(self.gachaponId)
  end
  UIManager.OpenUIByParam(UIDef.UIActivityGachaPanel, {
    actId = self.activityConfigData.Id,
    gachaId = self.gachaponId,
    planId = self.activityEntranceData.plan_id,
    spritePath = ActivityGachaGlobal.LennaPath
  })
end

function LennaMainPanel:ActivityIsFinish()
  local serverTime = CGameTime:GetTimestamp()
  local activityEntranceData = TableData.listActivityEntranceDatas:GetDataById(NetCmdThemeData.dyFinish)
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

function LennaMainPanel:InitCamera()
  if SceneSys.IsInChangingScene then
    return
  end
  local data = self.ui.mCamera_Camera:GetComponent(typeof(CS.UnityEngine.Rendering.Universal.UniversalAdditionalCameraData))
  local cameraData = UISystem.UICamera:GetComponent(typeof(CS.UnityEngine.Rendering.Universal.UniversalAdditionalCameraData))
  cameraData.renderType = CS.UnityEngine.Rendering.Universal.CameraRenderType.Overlay
  data.cameraStack:Add(UISystem.UICamera)
  setactivewithcheck(self.ui.mCamera_Camera, true)
end

function LennaMainPanel:ResetCamera()
  local data = self.ui.mCamera_Camera:GetComponent(typeof(CS.UnityEngine.Rendering.Universal.UniversalAdditionalCameraData))
  data.cameraStack:Clear()
  local cameraData = UISystem.UICamera:GetComponent(typeof(CS.UnityEngine.Rendering.Universal.UniversalAdditionalCameraData))
  cameraData.renderType = CS.UnityEngine.Rendering.Universal.CameraRenderType.CustomUILinear
  cameraData:SetRenderer(1)
  setactivewithcheck(self.ui.mCamera_Camera, false)
end

require("UI.UIBasePanel")
require("UI.MonopolyActivity.ActivityTourGlobal")
require("UI.Common.UICommonItem")
require("UI.ActivityTour.ActivityTourDifficultySelectItem")
ActivityTourDifficultySelectPanel = class("ActivityTourDifficultySelectPanel", UIBasePanel)
ActivityTourDifficultySelectPanel.__index = ActivityTourDifficultySelectPanel

function ActivityTourDifficultySelectPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
end

function ActivityTourDifficultySelectPanel:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.isOpenFinishWnd = false
  self.currSelect = -1
  self.currPhase = 1
  self.rewardUIList = {}
  self.dropUIList = {}
  self.monopolyData = NetCmdThemeData:GetCurrMonopolyCfg()
  if self.monopolyData == nil then
    self.needClose = true
    return
  end
  self.phaseLevelList = NetCmdThemeData:GetAllPhaseLevelList(self.monopolyData.monopoly_phase)
  self.planId = NetCmdThemeData:GetPlanIdByModuleTypeAndId(self.monopolyData.activity_submodule, self.monopolyData.id)
  self.messionRed = self.ui.mBtn_Mission.transform:Find("Trans_RedPoint").gameObject
  self:InitLevelPhase()
  self:ManualUI()
  self:AddBtnListen()
end

function ActivityTourDifficultySelectPanel:InitLevelPhase()
  self.levelPhaseList = {}
  self.phaseLevelCount = {}
  local phases = self.monopolyData.monopoly_phase
  for i = 0, phases.Length - 1 do
    local phase = phases[i]
    local data = TableDataBase.listMonopolyPhaseDatas:GetDataById(phase)
    self.phaseLevelCount[i + 1] = data.monopoly_difficulty
    for j = 0, data.monopoly_difficulty.Count - 1 do
      self.levelPhaseList[data.monopoly_difficulty[j]] = i + 1
    end
  end
end

function ActivityTourDifficultySelectPanel:ActivityIsFinish()
  if not NetCmdRecentActivityData:ThemeActivityIsOpen(self.themeId) then
    local content = MessageContent.New(TableData.GetHintById(260007), MessageContent.MessageType.SingleBtn, function()
      UIManager.CloseUI(UIDef.ActivityTourDifficultySelectPanel)
    end)
    if self.isOpenFinishWnd == false then
      self.isOpenFinishWnd = true
      MessageBoxPanel.Show(content)
    end
    return true
  end
  return false
end

function ActivityTourDifficultySelectPanel:AddBtnListen()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.ActivityTourDifficultySelectPanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    UISystem:JumpToMainPanel()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Detail.gameObject).onClick = function()
    UIManager.OpenUIByParam(UIDef.ActivityTourMapInfoDialog, {
      openIndex = 1,
      levelStageData = self.levelStageData,
      activityId = self.activityId,
      monopolyId = self.monopolyId
    })
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Command.gameObject).onClick = function()
    if self:ActivityIsFinish() then
      return
    end
    UIManager.OpenUI(UIDef.ActivityTourCommandDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Mission.gameObject).onClick = function()
    if self:ActivityIsFinish() then
      return
    end
    UIManager.OpenUIByParam(UIDef.ActivityTourMissionDialog, {
      themeId = self.themeId,
      monopoly = self.monopolyData.Id,
      activity = self.activityId
    })
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Start.gameObject).onClick = function()
    if self:ActivityIsFinish() then
      return
    end
    NetCmdMonopolyData:SendStartMonopoly(self.themeId, self.phaseLevelList[self.currSelect], self.levelStageData.MapId, function(errorCode)
      if errorCode == ErrorCodeSuc then
        NetCmdMonopolyData.MapId = self.levelStageData.MapId
        SceneSys:OpenMonoPolyScene(self.levelStageData.MapId)
        NetCmdThemeData:SaveMonopolyLevel(self.levelStageData.Id)
        local levelStageData = NetCmdThemeData:GetLevelStageData(self.levelStageData.Id)
        local finish = levelStageData and levelStageData.First ~= nil and levelStageData.First == true or false
        if finish then
          NetCmdThemeData:SetLevelComplete(self.levelStageData.Id)
        end
      end
    end)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Raid.gameObject).onClick = function()
    if self:ActivityIsFinish() then
      return
    end
    if self.LevelUnLock then
      UIManager.OpenUIByParam(UIDef.ActivityRaidDialog, {
        stage_id = self.levelData.id,
        sweep_cost = self.levelData.sweep_cost,
        sweep_times = self.levelData.sweep_times,
        themeId = self.themeId
      })
    else
      CS.PopupMessageManager.PopupString(self.lockText)
    end
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GiveUp.gameObject).onClick = function()
    if self:ActivityIsFinish() then
      return
    end
    UIManager.OpenUIByParam(UIDef.ActivityTourDoubleCheckDialog, {
      themeId = self.themeId
    })
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Continue.gameObject).onClick = function()
    if self:ActivityIsFinish() then
      return
    end
    NetCmdMonopolyData:SendContinueMonopoly(self.themeId, function(errorCode)
      if errorCode == ErrorCodeSuc then
        SceneSys:OpenMonoPolyScene(NetCmdMonopolyData.MapId)
      end
    end)
  end
  UIUtils.GetButtonListener(self.ui.mObj_BtnArrowL.gameObject).onClick = function()
    self:UpdateSelectIndex(self.currSelect - 1, true)
  end
  UIUtils.GetButtonListener(self.ui.mObj_BtnArrowR.gameObject).onClick = function()
    local index = self.currSelect + 1
    if index >= self.phaseLevelList.Count then
      return
    end
    self:UpdateSelectIndex(self.currSelect + 1, true)
  end
end

function ActivityTourDifficultySelectPanel:ManualUI()
  self.stageUIList = {}
  local phases = TableData.listMonopolyConfigDatas:GetDataById(self.monopolyData.id).MonopolyPhase
  local phaseCount = phases.Count
  for i = 1, self.ui.mTrans_Stage.childCount do
    local phaseId = phases[i - 1]
    local phaseConfig = TableData.listMonopolyPhaseDatas:GetDataById(phaseId)
    local item = self.ui.mTrans_Stage:GetChild(i - 1)
    local cell = {}
    cell.Trans_Locked = item.transform:Find("Trans_Locked").gameObject
    cell.Trans_Unlock = item.transform:Find("Trans_Unlock").gameObject
    cell.Trans_OnGoing = item.transform:Find("Trans_OnGoing").gameObject
    if phaseConfig then
      local textLocked = item.transform:Find("Trans_Locked/Text_Stage"):GetComponent(typeof(CS.UnityEngine.UI.Text))
      local textUnlocked = item.transform:Find("Trans_Unlock/Text_Stage"):GetComponent(typeof(CS.UnityEngine.UI.Text))
      local textOnGoing = item.transform:Find("Trans_OnGoing/Text_Stage"):GetComponent(typeof(CS.UnityEngine.UI.Text))
      textLocked.text = phaseConfig.ModelTitle.str
      textUnlocked.text = phaseConfig.ModelTitle.str
      textOnGoing.text = phaseConfig.ModelTitle.str
    end
    if i > phaseCount then
      cell.isUnlock = false
    else
      cell.isUnlock = NetCmdThemeData:PhaseIsUnLock(phaseId, self.planId, false)
    end
    table.insert(self.stageUIList, cell)
  end
  self.levelUIList = {}
  for i = 1, 4 do
    local item = self.ui.mTrans_ProgressBar.transform:Find("GrpState" .. i)
    local cell = {}
    cell.go = item.transform.gameObject
    cell.Trans_Locked = item.transform:Find("Trans_Locked").gameObject
    cell.Trans_Finished = item.transform:Find("Trans_Finished").gameObject
    cell.Trans_Selected = item.transform:Find("Trans_Selected").gameObject
    cell.Trans_Ongoing = item.transform:Find("Trans_Ongoing").gameObject
    table.insert(self.levelUIList, cell)
  end
  self.targetUIList = {}
  for i = 1, self.ui.mTrans_Content.childCount do
    local trans = self.ui.mTrans_Content:GetChild(i - 1)
    local cell = {}
    cell.go = trans.gameObject
    cell.txt = trans.transform:Find("Text_Target"):GetComponent(typeof(CS.UnityEngine.UI.Text))
    table.insert(self.targetUIList, cell)
  end
  self.teamUIList = {}
  self.iconPathList = {
    "Icon_ActivityTourDifficulty_Round",
    "Icon_ActivityTourDifficulty_Square3",
    "Icon_ActivityTourDifficulty_Square4",
    "Icon_ActivityTourDifficulty_Square1"
  }
  for i = 1, self.ui.mTrans_LevelDetail.childCount do
    local item = self.ui.mTrans_LevelDetail:GetChild(i - 1)
    local itemView = ActivityTourDifficultySelectItem.New()
    itemView:InitCtrl(item)
    table.insert(self.teamUIList, itemView)
  end
end

function ActivityTourDifficultySelectPanel:UpdateInfo()
  local mapData = TableData.listMonopolyMapDatas:GetDataById(self.levelStageData.MapId, true)
  if mapData then
    self.ui.mText_MapName.text = mapData.map_name.str
    self.ui.mImg_Map.sprite = IconUtils.GetActivitySprite(mapData.map_image)
  end
end

function ActivityTourDifficultySelectPanel:OnInit(root, data)
  self.themeId = data.themeId
  self.activityId = data.activityId
  self.monopolyId = data.monopolyId
  self:InitData()
  ActivityTourGlobal.SetGlobalValue()
end

function ActivityTourDifficultySelectPanel:InitData()
  self:SetVisible(false)
  if not NetCmdRecentActivityData:ThemeActivityIsOpen(self.themeId) then
    return
  end
  NetCmdThemeData:SendMonopolyInfo(self.themeId, function(ret)
    self:UpdateSelectIndex(NetCmdThemeData:GetLevelIndex(), false)
    self:SetVisible(true)
  end)
  NetCmdThemeData:ShowNewLevelDesc()
  ActivityTourGlobal.ReplaceAllColor(self.mUIRoot)
end

function ActivityTourDifficultySelectPanel:UpdateSelectIndex(index, isShowAni)
  if self.currSelect == index then
    return
  end
  if index >= self.phaseLevelList.Count then
    return
  end
  local levelId = self.phaseLevelList[index]
  local unlock, reason = NetCmdThemeData:MonLevelIsUnLockAndReason(levelId, self.planId)
  self.levelStageData = NetCmdThemeData:GetLevelStageData(levelId)
  if self.levelStageData == nil then
    print("\229\133\179\229\141\161\230\149\176\230\141\174\229\135\186\231\142\176\233\148\153\232\175\175")
    UIManager.CloseUI(UIDef.ActivityTourDifficultySelectPanel)
  end
  CSUIUtils.GetAndSetActivityHintText(self.mUIRoot, self.activityId, 2, 3002, self.monopolyId, true)
  self:UpdateInfo()
  if isShowAni then
    if index > self.currSelect then
      self.ui.mAnimator_Info:SetBool("Next", true)
    else
      self.ui.mAnimator_Info:SetBool("Previous", true)
    end
  end
  local levelState = NetCmdThemeData:GetLevelState(levelId, self.planId)
  self.currSelect = index
  self.currPhase = self.levelPhaseList[levelId]
  self:UpdatePhase()
  self:UpdateLevelState(levelId)
  self:UpdateLevelInfo(levelId)
  self:UpdateBtnState(levelState, unlock, reason)
end

function ActivityTourDifficultySelectPanel:UpdateLevelState(levelId)
  local phaseLevelData = self.phaseLevelCount[self.currPhase]
  for i = 1, #self.levelUIList do
    local cell = self.levelUIList[i]
    if i <= phaseLevelData.Count then
      local levelState = NetCmdThemeData:GetLevelState(phaseLevelData[i - 1], self.planId)
      local levelStageData = NetCmdThemeData:GetLevelStageData(phaseLevelData[i - 1])
      local finish = levelStageData and levelStageData.First ~= nil and levelStageData.First == true or false
      setactive(cell.Trans_Finished, levelState ~= 2 and finish)
      setactive(cell.Trans_Selected, levelId == phaseLevelData[i - 1])
      setactive(cell.Trans_Locked, levelState < 2)
      setactive(cell.Trans_Ongoing, levelState == 2)
      setactive(cell.go, true)
    else
      setactive(cell.go, false)
    end
  end
end

function ActivityTourDifficultySelectPanel:UpdateLevelInfo(levelId)
  local levelData = TableDataBase.listMonopolyDifficultyDatas:GetDataById(levelId)
  if levelData == nil then
    return
  end
  self.levelData = levelData
  self.ui.mImg_Icon.sprite = IconUtils.GetActivityTourIcon(levelData.stage_icon)
  self.ui.mText_Difficulty.text = levelData.name.str
  self.ui.mText_Lv.text = string_format(TableData.GetHintById(901061), levelData.sug_level)
  local hintIdList = {
    270138,
    270139,
    270305,
    270141
  }
  for i = 1, #self.teamUIList do
    local iconPath = "ActivityTour/" .. self.monopolyData.pic_resoures .. self.iconPathList[i]
    if i == 1 then
      self.teamUIList[i]:SetData(iconPath, self.monopolyData.team_number, i, self.levelStageData)
      self.teamUIList[i]:SetHint(hintIdList[i], self.activityId, self.monopolyId)
    elseif i == 2 then
      self.teamUIList[i]:SetData(iconPath, levelData.initial_point, i, self.levelStageData)
      self.teamUIList[i]:SetHint(hintIdList[i], self.activityId, self.monopolyId)
    elseif i == 3 then
      self.teamUIList[i]:SetData(iconPath, levelData.round_occupy_point, i, self.levelStageData)
      self.teamUIList[i]:SetHint(hintIdList[i], self.activityId, self.monopolyId)
    else
      self.teamUIList[i]:SetData(iconPath, string_format(TableData.GetHintById(901061), levelData.enemy_level), i, self.levelStageData)
      self.teamUIList[i]:SetHint(hintIdList[i], self.activityId, self.monopolyId)
      self.teamUIList[i]:SetActivityData(self.activityId, self.monopolyId)
    end
  end
  local mapConfig = TableDataBase.listMonopolyMapDatas:GetDataById(self.levelStageData.MapId)
  local winIds
  if mapConfig then
    winIds = mapConfig.WinCondition
    for i = 1, #self.targetUIList do
      if i <= winIds.Length then
        local winConfig = TableData.listMonopolyWinConditionDatas:GetDataById(winIds[i - 1])
        if winConfig then
          self.targetUIList[i].txt.text = winConfig.des.str
          setactive(self.targetUIList[i].go, true)
        end
      else
        setactive(self.targetUIList[i].go, false)
      end
    end
  end
  local currRewardPoint = self.levelStageData.RewardPoint or 0
  local maxRewardPoint = levelData.max_reward_point
  self.ui.mText_Explore.text = TableData.GetActivityHint(270303, self.activityId, 2, 3002, self.monopolyId) .. string_format(TableData.GetActivityHint(270304, self.activityId, 2, 3002, self.monopolyId), currRewardPoint, maxRewardPoint)
  if currRewardPoint >= maxRewardPoint then
    setactive(self.ui.mTrans_Finished.gameObject, true)
    setactive(self.ui.mTrans_RContent.gameObject, false)
  else
    setactive(self.ui.mTrans_Finished.gameObject, false)
    self:UpdateDropReward(levelData.drop_show)
    setactive(self.ui.mTrans_RContent.gameObject, true)
  end
  local levelStageData = NetCmdThemeData:GetLevelStageData(levelId)
  local isFinish = levelStageData and levelStageData.First ~= nil and levelStageData.First == true or false
  if levelData.can_sweep then
    if not isFinish then
      self.ui.mText_FirstPass.text = TableData.GetActivityHint(270301, self.activityId, 2, 3002, self.monopolyId)
      self:UpdatePassReward(levelData.first_reward_item, true, false)
    else
      self.ui.mText_FirstPass.text = TableData.GetActivityHint(270302, self.activityId, 2, 3002, self.monopolyId)
      self:UpdatePassReward(levelData.sweep_reward, false, false)
    end
  else
    self.ui.mText_FirstPass.text = TableData.GetActivityHint(270301, self.activityId, 2, 3002, self.monopolyId)
    self:UpdatePassReward(levelData.first_reward_item, true, isFinish)
  end
end

function ActivityTourDifficultySelectPanel:UpdateBtnState(levelState, unlock, reason)
  setactivewithcheck(self.ui.mObj_BtnArrowL.gameObject, self.currSelect > 0 and levelState ~= 2)
  setactivewithcheck(self.ui.mObj_BtnArrowR.gameObject, self.currSelect < self.phaseLevelList.Count - 1 and levelState ~= 2)
  if unlock then
    setactivewithcheck(self.ui.mBtn_Start.transform.parent.gameObject, levelState ~= 2)
    setactivewithcheck(self.ui.mBtn_GiveUp.transform.parent.gameObject, levelState == 2)
    setactivewithcheck(self.ui.mBtn_Continue.transform.parent.gameObject, levelState == 2)
    self.lockText = ""
    local lockTextList = {}
    self.LevelUnLock = true
    for i = 0, self.levelData.sweep_unlock.Length - 1 do
      local condtionId = self.levelData.sweep_unlock[i]
      local condtionData = TableData.listSweepCondtionDatas:GetDataById(condtionId)
      if condtionData then
        local count = CS.NetCmdCounterData.Instance:GetCounterCount(24, condtionData.id)
        if count < condtionData.condition_num then
          self.LevelUnLock = false
          table.insert(lockTextList, condtionData.name.str)
        end
      end
    end
    if #lockTextList == 2 then
      self.lockText = string_format(TableData.GetHintById(240121), lockTextList[1], lockTextList[2])
    else
      self.lockText = lockTextList[1]
    end
    setactivewithcheck(self.ui.mBtn_Raid.gameObject, levelState ~= 2 and self.levelData.can_sweep)
    self:CleanTime()
    self.refreshTime = TimerSys:DelayCall(0.1, function()
      self:CleanTime()
      self.ui.mAnimator_Raid:SetBool("Lock", not self.LevelUnLock)
    end)
    setactivewithcheck(self.ui.mTrans_Reason, false)
  else
    setactivewithcheck(self.ui.mBtn_Start.transform.parent.gameObject, false)
    setactivewithcheck(self.ui.mBtn_GiveUp.transform.parent.gameObject, false)
    setactivewithcheck(self.ui.mBtn_Continue.transform.parent.gameObject, false)
    setactivewithcheck(self.ui.mBtn_Raid.gameObject, false)
    setactivewithcheck(self.ui.mTrans_Reason, true)
    self.ui.mText_Reason.text = reason
  end
end

function ActivityTourDifficultySelectPanel:UpdateDropReward(list)
  for i = 0, list.Count - 1 do
    local index = i + 1
    if self.dropUIList[index] then
      self.dropUIList[index]:SetItemData(list[i])
    else
      local item = UICommonItem.New()
      item:InitCtrl(self.ui.mTrans_RContent)
      setactive(item.ui.mBtn_Select.gameObject, true)
      item:SetItemData(list[i], nil, nil, nil, nil, nil, nil, function()
        TipsPanelHelper.OpenUITipsPanel(TableData.GetItemData(list[i]))
      end)
      table.insert(self.dropUIList, item)
    end
  end
  if #self.dropUIList > list.Count then
    for i = list.Count + 1, #self.dropUIList do
      setactive(self.dropUIList[i].ui.mBtn_Select.gameObject, false)
    end
  end
end

function ActivityTourDifficultySelectPanel:UpdatePassReward(list, isfirst, isShowFinish)
  local sortedItemList = LuaUtils.SortItemByDict(list)
  for i = 0, sortedItemList.Count - 1 do
    local index = i + 1
    local kvPair = sortedItemList[i]
    local item = self.rewardUIList[index]
    if item == nil then
      item = UICommonItem.New()
      item:InitCtrl(self.ui.mTrans_LContent)
      table.insert(self.rewardUIList, item)
    end
    setactive(item.ui.mBtn_Select.gameObject, true)
    item:SetFirstDrop(isfirst and not isShowFinish)
    setactive(item.ui.mTrans_ReceivedIcon, isShowFinish)
    item:SetItemData(kvPair.Key, kvPair.Value, nil, nil, nil, nil, nil, function()
      TipsPanelHelper.OpenUITipsPanel(TableData.GetItemData(kvPair.Key))
    end)
  end
  if #self.rewardUIList > sortedItemList.Count then
    for i = sortedItemList.Count + 1, #self.rewardUIList do
      setactive(self.rewardUIList[i].ui.mBtn_Select.gameObject, false)
    end
  end
end

function ActivityTourDifficultySelectPanel:UpdatePhase()
  for i = 1, #self.stageUIList do
    if i == self.currPhase then
      setactive(self.stageUIList[i].Trans_OnGoing, true)
      setactive(self.stageUIList[i].Trans_Locked, false)
      setactive(self.stageUIList[i].Trans_Unlock, false)
    else
      setactive(self.stageUIList[i].Trans_OnGoing, false)
      setactive(self.stageUIList[i].Trans_Locked, not self.stageUIList[i].isUnlock)
      setactive(self.stageUIList[i].Trans_Unlock, self.stageUIList[i].isUnlock)
    end
  end
end

function ActivityTourDifficultySelectPanel:OnShowStart()
end

function ActivityTourDifficultySelectPanel:OnShowFinish()
  setactive(self.messionRed, NetCmdThemeData:MissionRed())
  if self.needClose then
    UIManager.CloseUI(UIDef.ActivityTourDifficultySelectPanel)
  end
end

function ActivityTourDifficultySelectPanel:OnTop()
  if self:ActivityIsFinish() then
    return
  end
  NetCmdThemeData:SendMonopolyInfo(self.themeId, function(ret)
    local index = self.currSelect
    self.currSelect = -1
    self:UpdateSelectIndex(index, false)
  end)
end

function ActivityTourDifficultySelectPanel:RefreshData()
  self:SetVisible(false)
  self.needClose = false
  if not NetCmdRecentActivityData:ThemeActivityIsOpen(self.themeId) then
    self.needClose = true
    return
  end
  NetCmdThemeData:SendMonopolyInfo(self.themeId, function(ret)
    if ret == ErrorCodeSuc then
      self.monopolyData = NetCmdThemeData:GetCurrMonopolyCfg()
      self.phaseLevelList = NetCmdThemeData:GetAllPhaseLevelList(self.monopolyData.monopoly_phase)
      self.planId = NetCmdThemeData:GetPlanIdByModuleTypeAndId(self.monopolyData.activity_submodule, self.monopolyData.id)
      ActivityTourGlobal.ReplaceAllColor(self.mUIRoot)
      self.currSelect = -1
      self:UpdateSelectIndex(NetCmdThemeData:GetLevelIndex(), false)
      NetCmdThemeData:ShowNewLevelDesc()
      self:SetVisible(true)
    else
      UIManager.CloseUI(UIDef.ActivityTourDifficultySelectPanel)
    end
  end)
end

function ActivityTourDifficultySelectPanel:OnBackFrom()
  self:RefreshData()
end

function ActivityTourDifficultySelectPanel:CleanTime()
  if self.refreshTime then
    self.refreshTime:Stop()
    self.refreshTime = nil
  end
end

function ActivityTourDifficultySelectPanel:OnRecover()
  self:RefreshData()
end

function ActivityTourDifficultySelectPanel:OnClose()
  self.isOpenFinishWnd = false
  self.themeId = nil
  self:CleanTime()
end

function ActivityTourDifficultySelectPanel:OnHide()
end

function ActivityTourDifficultySelectPanel:OnHideFinish()
end

function ActivityTourDifficultySelectPanel:OnRelease()
  self.currSelect = -1
  self.isOpenFinishWnd = false
end

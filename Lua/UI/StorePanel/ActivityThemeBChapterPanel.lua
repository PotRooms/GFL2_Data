require("UI.UIBasePanel")
require("UI.ActivityThemeB.ActivityThemeBChapterPanelBg")
require("UI.StorePanel.ActivityThemeBChapterItem")
require("UI.MessageBox.Data.MessageContent")
require("UI.BattleIndexPanel.UIBattleDetailDialog")
ActivityThemeBChapterPanel = class("ActivityThemeBChapterPanel", UIBasePanel)
ActivityThemeBChapterPanel.__index = ActivityThemeBChapterPanel

function ActivityThemeBChapterPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
end

function ActivityThemeBChapterPanel:OnAwake(root, data)
  self:SetRoot(root)
  self.normalChapterId = 0
  self.storyCount = 0
  self.jumpId = 0
  self.stageItemList = {}
  self.diffChapterUIList = {}
  self.selectDiff = -1
  self.curStage = nil
  self.scrollReset = false
  self.diffNameList = {
    103201,
    103202,
    103203
  }
  self.mainBg = nil
  self.diffLevelList = {}
end

function ActivityThemeBChapterPanel:OnInit(root, data)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.chapterData = TableData.listChapterDatas:GetDataById(NetCmdThemeData.currSelectChapterId)
  self.totalChapterId = self.chapterData.id
  self.curDiff = 1
  self.curDiff = NetCmdThemeData:GetThemeChapterDiff(self.chapterData.id)
  if self.curDiff < 1 then
    self.curDiff = 1
  end
  if data.NeedShowDifficultyTab == nil then
    self.needShowDifficultyTab = true
  else
    self.needShowDifficultyTab = data.NeedShowDifficultyTab
  end
  local diffChapterList = TableData.listChapterByDifficultyGroupDatas:GetDataById(self.chapterData.difficulty_group)
  for i = 1, diffChapterList.Id.Count do
    if i == self.curDiff then
      local chapterId = diffChapterList.Id[i - 1]
      self.chapterData = TableData.listChapterDatas:GetDataById(chapterId)
      break
    end
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    self:OnClickBack()
    UIManager.CloseUI(UIDef.ActivityThemeBChapterPanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    self:OnClickBack()
    UISystem:JumpToMainPanel()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_ChapterReward.gameObject).onClick = function()
    self:OnClickChapterReward()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Root.gameObject).onClick = function()
    self:OnClickChapterReward()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_DetailsList.gameObject).onClick = function()
    MessageSys:SendMessage(UIEvent.StoryCloseDetail, nil)
    setactive(self.ui.mBtn_CloseNew.gameObject, false)
  end
  
  function self.ShowCloseNew()
    setactive(self.ui.mBtn_CloseNew.gameObject, true)
  end
  
  setactive(self.ui.mBtn_CloseNew.gameObject, false)
  UIUtils.GetButtonListener(self.ui.mBtn_CloseNew.gameObject).onClick = function()
    MessageSys:SendMessage(UIEvent.StoryCloseDetail, nil)
    setactive(self.ui.mBtn_CloseNew.gameObject, false)
  end
  self:InitResourcesBarColor()
  self:InitDiffData()
  self:AddListeners()
  self:InitTabBg()
end

function ActivityThemeBChapterPanel:InitTabBg()
  local targetChapterData = NetCmdDungeonData:GetStoryCharterDataByDifficultyGroup(self.chapterData, 1)
  if targetChapterData then
    self.ui.mImage_NormalTab.color = NetCmdThemeData:GetTabBgColor(targetChapterData.id)
  end
  targetChapterData = NetCmdDungeonData:GetStoryCharterDataByDifficultyGroup(self.chapterData, 2)
  if targetChapterData then
    self.ui.mImage_HardTab.color = NetCmdThemeData:GetTabBgColor(targetChapterData.id)
  end
end

function ActivityThemeBChapterPanel:InitResourcesBarColor()
  local color = NetCmdThemeData:GetResourceBarColor(self.chapterData.id)
  local imageBack = self.ui.mBtn_Back.transform:Find("IconNor"):GetComponent(typeof(CS.UnityEngine.UI.Image))
  local imageHome = self.ui.mBtn_Home.transform:Find("IconNor"):GetComponent(typeof(CS.UnityEngine.UI.Image))
  imageBack.color = color
  imageHome.color = color
end

function ActivityThemeBChapterPanel:UpdateDiffLevelTable()
  local diffChapterList = TableData.listChapterByDifficultyGroupDatas:GetDataById(self.chapterData.difficulty_group)
  if not diffChapterList then
    return
  end
  for i = 0, diffChapterList.Id.Count - 1 do
    local index = i + 1
    local data = TableData.listChapterDatas:GetDataById(diffChapterList.Id[i], true)
    if NetCmdThemeData:GetLevelBack(data.stage_group) then
      self.diffLevelList[index] = NetCmdThemeData:GetCurrResultLevelId(data.stage_group)
      NetCmdThemeData:SetLevelBack(data.stage_group, false)
    else
      self.diffLevelList[index] = NetCmdThemeData:GetChapterLevelUnLockId(diffChapterList.Id[i])
    end
  end
end

function ActivityThemeBChapterPanel:InitDiffData()
  self:UpdateDiffLevelTable()
  local diffChapterList = TableData.listChapterByDifficultyGroupDatas:GetDataById(self.chapterData.difficulty_group)
  self.diffChapterDiffList = {}
  self.firstScroll = false
  if diffChapterList then
    for i = 0, diffChapterList.Id.Count - 1 do
      local index = i + 1
      setactive(self.ui.mTrans_Action:GetChild(i), self.needShowDifficultyTab)
      local diffUI = self.diffChapterUIList[index]
      if diffUI == nil then
        diffUI = self:GetUIDetail(self.ui.mTrans_Action:GetChild(i))
        table.insert(self.diffChapterUIList, diffUI)
      end
      diffUI.name.text = TableData.GetHintById(self.diffNameList[index])
      local data = TableData.listChapterDatas:GetDataById(diffChapterList.Id[i], true)
      if data then
        do
          local lockStr = CS.LuaUIUtils.CheckUnlockPopupStrByRepeatedList(data.unlock)
          local isLock = 0 < string.len(lockStr)
          local firstOpenRed = NetCmdThemeData:GetChapterOnOpen(diffChapterList.Id[i]) == -1
          setactive(diffUI.red.gameObject, not isLock and 0 < NetCmdDungeonData:UpdateChatperRewardRedPoint(diffChapterList.Id[i]) or firstOpenRed)
          self.diffChapterDiffList[index] = isLock
          UIUtils.GetButtonListener(diffUI.btn.gameObject).onClick = function()
            if not data then
              return
            end
            local lockStr = CS.LuaUIUtils.CheckUnlockPopupStrByRepeatedList(data.unlock)
            local isLock = string.len(lockStr) > 0
            if isLock then
              CS.PopupMessageManager.PopupString(lockStr)
              return
            end
            setactive(diffUI.red.gameObject, 0 < NetCmdDungeonData:UpdateChatperRewardRedPoint(diffChapterList.Id[i]))
            self.firstScroll = true
            self.scrollReset = false
            self.scrollReset = false
            self.chapterData = TableData.listChapterDatas:GetDataById(data.id)
            NetCmdThemeData:SaveEnterChapterId(data.id)
            self:UpdateDiffChapter(index)
            if 1 < index then
              self.ui.mAnimator_Root:SetBool("Next", true)
            else
              self.ui.mAnimator_Root:SetBool("Previous", true)
            end
            self:UpdateData(1)
            if 1 < index then
              self.mainBg:SetTrigger("Next")
            else
              self.mainBg:SetTrigger("Previous")
            end
          end
        end
      end
    end
    if self.ui.mTrans_Action.childCount > diffChapterList.Id.Count then
      for k = diffChapterList.Id.Count + 1, self.ui.mTrans_Action.childCount do
        setactive(self.ui.mTrans_Action:GetChild(k - 1), false)
      end
    end
    self:CleanTime()
    self.themeaticData = TableDataBase.listPlanDatas:GetDataById(self.chapterData.plan_id)
    self.delayTime = TimerSys:DelayCall(0.1, function()
      local diff = NetCmdThemeData:GetActivityEndDiffIndex(self.totalChapterId)
      if diff < 1 then
        diff = 1
      end
      self:UpdateDiffChapter(self.curDiff)
    end)
    NetCmdThemeData:SaveEnterChapterId(self.chapterData.id)
  end
  self:RefreshBoxStarSprite()
end

function ActivityThemeBChapterPanel:CleanTime()
  if self.delayTime then
    self.delayTime:Stop()
    self.delayTime = nil
  end
end

function ActivityThemeBChapterPanel:GetUIDetail(trans)
  local cell = {}
  cell.btn = trans:Find("Root"):GetComponent(typeof(CS.UnityEngine.UI.GFButton))
  cell.anim = trans:Find("Root"):GetComponent(typeof(CS.UnityEngine.Animator))
  cell.name = trans:Find("Root/GrpLayout/Text_Difficulty"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  cell.red = trans:Find("Root/Trans_RedPoint"):GetComponent(typeof(CS.UnityEngine.RectTransform))
  cell.anim.keepAnimatorControllerStateOnDisable = true
  return cell
end

function ActivityThemeBChapterPanel:UpdateDiffChapter(index)
  if index == self.selectDiff then
    return
  end
  NetCmdThemeData:SetChapterOnOpen(self.chapterData.id, 1)
  if self.chapterData.type == 3 then
    NetCmdThemeData.currSelectEndId = self.chapterData.id
  elseif self.chapterData.type == 4 then
    NetCmdThemeData.currSelectChapterId = self.chapterData.id
  end
  self.selectDiff = index
  NetCmdThemeData:SetActivityEndDiffIndex(self.chapterData.id, self.chapterData.difficulty_type)
  for i = 1, #self.diffChapterUIList do
    local diffUI = self.diffChapterUIList[i]
    local isLock = self.diffChapterDiffList[i]
    if isLock then
      diffUI.anim:SetBool("Locked", true)
    elseif index == i then
      diffUI.btn.interactable = false
    else
      diffUI.btn.interactable = true
    end
  end
  if not self.ui.mBgScrollHelper.enabled then
    self.ui.mBgScrollHelper.enabled = true
  end
  if self.mainBg then
    self.ui.mBgScrollHelper.bgFitter = self.mainBg:GetAspectRatioFitter()
  end
  self.ui.mBgScrollHelper:Init()
  self.ui.mBgScrollHelper:RefreshPos(true)
end

function ActivityThemeBChapterPanel:IsEndedActivity()
end

function ActivityThemeBChapterPanel:AddListeners()
  function self.UpdateChapterData()
    self:UpdateRewardInfo()
    
    self:OnClickCloseChapterInfoPanel()
  end
  
  function self.OpenReceivePanel()
    self.ui.mCanvasGroup_Root.blocksRaycasts = true
  end
  
  function self.OnAVGStartShowCallback()
    self:CleanAllSelected()
  end
  
  function self.AvgSceneClose()
    UISystem:OpenCommonReceivePanel({
      nil,
      function()
        self.ui.mCanvasGroup_Root.blocksRaycasts = true
      end,
      true,
      false,
      nil,
      nil,
      UIBasePanelType.Panel
    })
  end
  
  CS.GF2.Message.MessageSys.Instance:AddListener(CS.GF2.Message.UIEvent.RefreshChapterInfo, self.UpdateChapterData)
  CS.GF2.Message.MessageSys.Instance:AddListener(CS.GF2.Message.AVGEvent.AVGFirstDrop, self.OpenReceivePanel)
  CS.GF2.Message.MessageSys.Instance:AddListener(CS.GF2.Message.AVGEvent.AVGStartShow, self.OnAVGStartShowCallback)
  CS.GF2.Message.MessageSys.Instance:AddListener(CS.GF2.Message.UIEvent.AvgSceneClose, self.AvgSceneClose)
  MessageSys:AddListener(UIEvent.StoryShowDetail, self.ShowCloseNew)
end

function ActivityThemeBChapterPanel:RemoveListeners()
  CS.GF2.Message.MessageSys.Instance:RemoveListener(CS.GF2.Message.UIEvent.RefreshChapterInfo, self.UpdateChapterData)
  CS.GF2.Message.MessageSys.Instance:RemoveListener(CS.GF2.Message.AVGEvent.AVGFirstDrop, self.OpenReceivePanel)
  CS.GF2.Message.MessageSys.Instance:RemoveListener(CS.GF2.Message.UIEvent.AvgSceneClose, self.AvgSceneClose)
  CS.GF2.Message.MessageSys.Instance:RemoveListener(CS.GF2.Message.AVGEvent.AVGStartShow, self.OnAVGStartShowCallback)
  MessageSys:RemoveListener(UIEvent.StoryShowDetail, self.ShowCloseNew)
end

function ActivityThemeBChapterPanel:OnClickChapterReward()
  if self:IsEndedActivity() then
    return
  end
  local data = CS.ShowChapterRewardData()
  data.ChapterId = self.chapterData.id
  data.IsDifficult = false
  UIManager.OpenUIByParam(enumUIPanel.UIStoryChapterRewardlDialogV2, data)
end

function ActivityThemeBChapterPanel:OnShowStart()
  self:UpdateData(1)
  self:StartFinishTime()
  self.mainBg:SetTrigger("FadeIn")
end

function ActivityThemeBChapterPanel:OnSave()
  NetCmdThemeData.currSelectChapterId = self.chapterData.id
  NetCmdThemeData:SetActivityEndDiffIndex(self.chapterData.id, self.chapterData.difficulty_type)
  NetCmdThemeData:SetThemeChapterDiff(self.chapterData.id, self.chapterData.difficulty_type)
end

function ActivityThemeBChapterPanel:OnShowFinish()
  if not self.ui.mBgScrollHelper.enabled then
    self.ui.mBgScrollHelper.enabled = true
  end
  if self.mainBg then
    self.ui.mBgScrollHelper.bgFitter = self.mainBg:GetAspectRatioFitter()
  end
  self.ui.mBgScrollHelper:Init()
  self.ui.mBgScrollHelper:RefreshPos(true)
end

function ActivityThemeBChapterPanel:UpdateDiffRed()
  local diffUI
  if self.chapterData.tab > 0 then
    diffUI = self.diffChapterUIList[self.selectDiff]
  else
    diffUI = self.diffChapterUIList[self.selectDiff]
  end
  if diffUI then
    setactive(diffUI.red.gameObject, 0 < NetCmdDungeonData:UpdateChatperRewardRedPoint(self.chapterData.id))
  end
end

function ActivityThemeBChapterPanel:UpdateData()
  self:UpdateChapterBG()
  self:UpdateChapterInfo()
  self:UpdateStoryStageItem()
  self:UpdateRewardInfo()
  self:UpdateDiffLevelTable()
  self.jumpId = self.diffLevelList[self.chapterData.difficulty_type]
  self:ResetScroll()
end

function ActivityThemeBChapterPanel:UpdateChapterBG()
  local chapterData = TableData.listChapterDatas:GetDataById(self.chapterData.id)
  local mainBgPrefab
  if self.ui.mTrans_Bg.childCount > 0 then
    mainBgPrefab = self.ui.mTrans_Bg:GetChild(0)
  else
    mainBgPrefab = NetCmdThemeData:InstantiateChapterPanelBg(self.chapterData.id, self.ui.mTrans_Bg)
    self.mainBgPrefab = mainBgPrefab
  end
  if self.mainBg == nil then
    self.mainBg = ActivityThemeBChapterPanelBg.New()
    self.mainBg:InitCtrl(mainBgPrefab.transform)
  end
  self.mainBg:SetLevelDiff(chapterData.difficulty_type)
end

function ActivityThemeBChapterPanel:UpdateChapterInfo()
  self.ui.mText_ActivityName.text = NetCmdThemeData:GetActivityName(self.chapterData.id)
  self.ui.mText_ChapterName.text = NetCmdThemeData:GetTabName(self.chapterData.id)
  self.ui.mText_ActivityName.color = NetCmdThemeData:GetActivityNameColor(self.chapterData.id)
  self.ui.mText_ChapterName.color = NetCmdThemeData:GetTabNameColor(self.chapterData.id)
end

function ActivityThemeBChapterPanel:UpdateRewardInfo()
  if self.chapterData.chapter_reward_value.Count > 0 then
    local stars = NetCmdDungeonData:GetCurStarsByChapterID(self.chapterData.id)
    local totalStar = self.chapterData.chapter_reward_value[self.chapterData.chapter_reward_value.Count - 1]
    self.ui.mText_RewardNum.text = stars .. "/" .. totalStar
    self.ui.mText_RewardBubbleNum.text = stars .. "/" .. totalStar
    self:UpdateRewardState()
  else
    setactive(self.ui.mTrans_Bubble.gameObject, false)
    setactive(self.ui.mTrans_Received, false)
    setactive(self.ui.mTrans_Reward, false)
    setactive(self.ui.mTrans_RewardRedPoint.gameObject, false)
  end
  self:UpdateDiffRed()
end

function ActivityThemeBChapterPanel:UpdateRewardState()
  local canReceive = NetCmdDungeonData:UpdateChatperRewardRedPoint(self.chapterData.id) > 0
  local phase = NetCmdDungeonData:GetCannotGetPhaseByChapterID(self.chapterData.id)
  local rewardCount = NetCmdDungeonData:GetChapterRewardCount(self.chapterData.id)
  setactive(self.ui.mTrans_Received, phase == -1)
  setactive(self.ui.mTrans_Reward, phase == 0)
  setactive(self.ui.mTrans_Bubble, 0 < phase and phase < 4)
  if 0 < phase then
    local strList = string.split(self.chapterData.chapter_reward, "|")
    setactive(self.ui.mTrans_RedPoint.gameObject, canReceive)
    local state = NetCmdDungeonData:GetCurStateByChapterID(self.chapterData.id, phase)
    local count
    if phase > self.chapterData.chapter_reward_value.Count then
      count = 0
    else
      count = self.chapterData.chapter_reward_value[phase - 1]
    end
    local star = NetCmdDungeonData:GetCurStarsByChapterID(self.chapterData.id)
    self.ui.mText_RewardText.text = state == 0 and TableData.GetHintReplaceById(103098, count - star) or TableData.GetHintById(103099)
    for i = 1, rewardCount do
      if phase == i then
        local rewardList = {}
        local ss = string.split(strList[i], ",")
        for _, v in ipairs(ss) do
          local s = string.split(v, ":")
          local item = {}
          item.itemId = tonumber(s[1])
          item.itemNum = tonumber(s[2])
          table.insert(rewardList, item)
        end
        for _, value in ipairs(rewardList) do
          local key = value.itemId
          if key == self.chapterData.chapter_reward_show[i] then
            local itemData = TableData.GetItemData(key)
            self.ui.mImg_RewardIcon.sprite = IconUtils.GetItemIconSprite(key)
            self.ui.mImg_QualityCor.color = TableData.GetGlobalGun_Quality_Color2(itemData.rank)
          end
        end
      end
    end
  else
    setactive(self.ui.mTrans_RewardRedPoint.gameObject, canReceive)
  end
end

function ActivityThemeBChapterPanel:UpdateStoryStageItem()
  if self.scrollReset then
    for _, item in pairs(self.stageItemList) do
      if item.storyDataList[_] then
        item:UpdateItem(item.storyDataList[_])
      end
    end
    return
  end
  for _, item in pairs(self.stageItemList) do
    item:SetDataFalse()
  end
  local storyListData = TableData.GetStorysByChapterID(self.chapterData.id, false, true)
  self.storyCount = storyListData.Count
  if self.storyCount == 0 then
    storyListData = TableData.GetStorysByChapterID(self.chapterData.stage_group, false, true)
    self.storyCount = storyListData.Count
  end
  local lastData = storyListData[0]
  local firstData = storyListData[0]
  local delta = TableData.GlobalConfigData.SelectedStoryPosition * LuaUtils.GetRectTransformSize(self.mUIRoot.gameObject).x
  local branchSoryDataList = {}
  local storyIdDataList = {}
  self.storyIDIndexList = {}
  self.storyIdPosList = {}
  local count = 0
  for i = 0, storyListData.Count - 1 do
    if storyListData[i].mSfxPos.x > lastData.mSfxPos.x then
      lastData = storyListData[i]
    end
    if storyListData[i].mSfxPos.x < firstData.mSfxPos.x then
      firstData = storyListData[i]
    end
    local item
    local data = storyListData[i]
    local posList = string.split(data.position, ",")
    self.storyIdPosList[data.id] = tonumber(posList[1])
    if data.type == GlobalConfig.StoryType.Normal or data.type == GlobalConfig.StoryType.Story then
      local id = GlobalConfig.StoryType.Normal * 100 + count
      self.storyIDIndexList[data.id] = id
      count = count + 1
      if self.stageItemList[id] == nil then
        item = ActivityThemeBChapterItem.New()
        item:InitCtrl(self.ui.mTrans_CombatList)
        self.stageItemList[id] = item
      else
        item = self.stageItemList[id]
      end
      item:SetMainData(self.chapterData, data, i + 1)
      UIUtils.GetButtonListener(item.mainItemView.ui.mBtn_Stage.gameObject).onClick = function()
        self:OnStoryClick(item, data, false)
      end
    elseif data.type == GlobalConfig.StoryType.Branch then
      table.insert(branchSoryDataList, data)
    end
    storyIdDataList[data.id] = data
  end
  for i = 1, #branchSoryDataList do
    local branchData = branchSoryDataList[i]
    local mainId = self.storyIDIndexList[branchData.pre_id[0]]
    local item = self.stageItemList[mainId]
    local preData = storyIdDataList[branchData.pre_id[0]]
    if preData then
      if item == nil then
        item = self:GetMainItemById(preData.pre_id[0])
      end
      if preData.mSfxPos.y == 0 then
        if 0 < branchData.mSfxPos.y then
          item:SetTopData(self.chapterData, branchData)
        elseif 0 > branchData.mSfxPos.y then
          item:SetBtmData(self.chapterData, branchData)
        end
      elseif 0 < preData.mSfxPos.y then
        if 0 < branchData.mSfxPos.y then
          item:SetTopGroupData(self.chapterData, branchData, i)
        elseif 0 > branchData.mSfxPos.y then
          item:SetBtmData(self.chapterData, branchData)
        end
      elseif 0 < branchData.mSfxPos.y then
        item:SetTopData(self.chapterData, branchData)
      elseif 0 > branchData.mSfxPos.y then
        item:SetBtmGroupData(self.chapterData, branchData, i)
      end
      UIUtils.GetButtonListener(item.itemViewList[branchData.id].ui.mBtn_Stage.gameObject).onClick = function()
        self:OnStoryClick(item, branchData, true)
      end
    end
  end
  self.ui.mText_ChapterName.text = self.chapterData.tab_name.str
  LayoutRebuilder.ForceRebuildLayoutImmediate(self.ui.mTrans_CombatList)
end

function ActivityThemeBChapterPanel:GetMainItemById(preId)
  local mainItem = self.stageItemList[self.storyIDIndexList[preId]]
  while mainItem == nil do
    local data = TableData.listStoryDatas:GetDataById(preId)
    mainItem = self.stageItemList[self.storyIDIndexList[data.pre_id[0]]]
  end
  return mainItem
end

function ActivityThemeBChapterPanel:OnStoryClick(item, data, isBranch, needAni, hideDetails)
  gfinfo("OnStoryClick stage_id: " .. data.stage_id)
  if self:IsEndedActivity() then
    return
  end
  needAni = needAni == nil and true or needAni
  isBranch = isBranch or false
  local stageData = TableData.GetStageData(data.stage_id)
  self.currClickData = data
  if stageData ~= nil then
    local record = NetCmdStageRecordData:GetStageRecordById(stageData.id)
    if not hideDetails then
      self:ShowStageInfo(record, item.storyDataList[data.id], stageData)
      local shiftingCount = 0
      if isBranch then
        local mainData = self:GetMainDataById(data.pre_id[0])
        if mainData then
          shiftingCount = data.mSfxPos.x - mainData.mSfxPos.x - 550
        end
      end
      self:ScrollMoveToMid(item.mUIRoot.transform.localPosition, 0.35, shiftingCount)
      item:SetSelected(data, true, isBranch)
      self.curStage = item
    else
      self:ScrollMoveToMid(item.mUIRoot.transform.localPosition, 0, 0)
    end
  end
end

function ActivityThemeBChapterPanel:CleanAllSelected()
  for _, item in pairs(self.stageItemList) do
    item:CleanAllSelected()
  end
end

function ActivityThemeBChapterPanel:GetMainDataById(branchid)
  local mainData = TableData.listStoryDatas:GetDataById(branchid)
  if mainData == nil then
    return
  end
  while mainData.type == 11 do
    mainData = TableData.listStoryDatas:GetDataById(mainData.pre_id[0])
  end
  return mainData
end

function ActivityThemeBChapterPanel:ShowStageInfo(stageRecord, storyData, stageData)
  UIBattleDetailDialog.OpenByChapterData(LuaUtils.EnumToInt(enumUIPanel.UIStoryChapterPanel), stageData, stageRecord, storyData, NetCmdDungeonData:IsUnLockStory(storyData.id), function(tempFirst)
    if tempFirst then
      self.scrollReset = false
    else
    end
    self:UpdateData()
    self:OnClickCloseChapterInfoPanel()
  end, true)
end

function ActivityThemeBChapterPanel:OnClickCloseChapterInfoPanel()
  self.ui.mScrollRect_GrpDetailsList.enabled = true
  for _, item in pairs(self.stageItemList) do
    item:CleanAllSelected()
  end
end

function ActivityThemeBChapterPanel:ScrollMoveToMid(itemPos, duration, offsetX)
  if duration == nil then
    duration = 0.35
  end
  local content = self.ui.mScrollRect_GrpDetailsList.content
  local newToPos = itemPos.x + content.anchoredPosition.x + offsetX
  local screenWidth = UISystem.UICanvas.transform.sizeDelta.x
  local toX = screenWidth * 0.37 - newToPos
  local toPos = Vector3(toX, content.localPosition.y, 0)
  local deltaPos = content.localPosition + toPos
  if self.fillAmountTween ~= nil then
    CS.UITweenManager.TweenKill(self.fillAmountTween)
    self.fillAmountTween = nil
  end
  self.ui.mScrollRect_GrpDetailsList.enabled = false
  self.fillAmountTween = CS.UITweenManager.PlayLocalPositionTween(content, content.localPosition, deltaPos, duration)
end

function ActivityThemeBChapterPanel:GetStoryItemId(id)
  for _, item in pairs(self.stageItemList) do
    if item.storyDataList[_] ~= nil and item.storyDataList[_].id == id then
      return item
    end
  end
end

function ActivityThemeBChapterPanel:ResetScroll()
  if self.ui.mTrans_CombatList == nil or self.scrollReset then
    return
  end
  local offsetX = LuaUtils.GetRectTransformSize(self.ui.mTrans_CombatList.gameObject).x - LuaUtils.GetRectTransformSize(self.ui.mTrans_DetailsList.gameObject).x
  local itemX = 0
  self.mOffsetX = offsetX <= 0 and 0 or offsetX
  local curItem, currData
  for _, item in pairs(self.stageItemList) do
    if 0 < self.jumpId and item.storyDataList[self.jumpId] then
      curItem = item
      currData = item.storyDataList[self.jumpId]
      break
    end
    local storyData = item.storyDataList[_]
    if storyData ~= nil then
      if self.recordStoryId ~= 0 then
        if self.recordStoryId == storyData.id then
          curItem = item
          currData = storyData
        end
      elseif item.isUnlock and (storyData.type == GlobalConfig.StoryType.Normal or storyData.type == GlobalConfig.StoryType.Story or storyData.type == GlobalConfig.StoryType.Hide) and itemX <= storyData.mSfxPos.x then
        itemX = storyData.mSfxPos.x
        curItem = item
        currData = storyData
      end
    end
  end
  if curItem and currData then
    local content = LuaUtils.GetRectTransformSize(self.ui.mTrans_CombatList.gameObject)
    local screenWidth = LuaUtils.GetRectTransformSize(self.mUIRoot.gameObject).x
    local targetX = curItem.mUIRoot.transform.localPosition.x
    local normalSize = targetX / content.x
    local scrollDelta = UIUtils.Clam(normalSize, 0, 1)
    local currDelta = UIUtils.Clam(self.ui.mScrollRect_GrpDetailsList.horizontalNormalizedPosition, 0, 1)
    if 1 < self.ui.mScrollRect_GrpDetailsList.horizontalNormalizedPosition then
      self.ui.mScrollRect_GrpDetailsList.horizontalNormalizedPosition = 1
    end
    if self.firstScroll then
      if math.abs(scrollDelta - currDelta) <= 0.3 then
        self.ui.mScrollRect_GrpDetailsList.horizontalNormalizedPosition = scrollDelta
      else
        if self.fillAmountTween ~= nil then
          CS.UITweenManager.TweenKill(self.fillAmountTween)
        end
        if scrollDelta > currDelta then
          self.ui.mScrollRect_GrpDetailsList.horizontalNormalizedPosition = UIUtils.Clam(scrollDelta - 0.3, 0, 1)
          self.fillAmountTween = CS.UITweenManager.PlayScrollRectNormalPos(self.ui.mScrollRect_GrpDetailsList, scrollDelta, 0.5, CS.DG.Tweening.Ease.OutExpo)
        else
          self.ui.mScrollRect_GrpDetailsList.horizontalNormalizedPosition = UIUtils.Clam(scrollDelta + 0.3, 0, 1)
          self.fillAmountTween = CS.UITweenManager.PlayScrollRectNormalPos(self.ui.mScrollRect_GrpDetailsList, scrollDelta, 0.5, CS.DG.Tweening.Ease.OutExpo)
        end
      end
    else
      self.ui.mScrollRect_GrpDetailsList.horizontalNormalizedPosition = scrollDelta
    end
  end
  self.scrollReset = true
end

function ActivityThemeBChapterPanel:RefreshBoxStarSprite()
  self.ui.mImage_BoxStar.sprite = NetCmdThemeData:GetTreasureChestStarSprite(self.chapterData.id)
end

function ActivityThemeBChapterPanel:CleanFinishTime()
  if self.finishTime then
    self.finishTime:Stop()
    self.finishTime = nil
  end
end

function ActivityThemeBChapterPanel:StartFinishTime()
end

function ActivityThemeBChapterPanel:OnTop()
end

function ActivityThemeBChapterPanel:GetChapterId()
  local chapterId = NetCmdThemeData:GetEnterChapterId()
  return TableData.listChapterDatas:GetDataById(chapterId, true)
end

function ActivityThemeBChapterPanel:OnBackFrom()
  local chapterData = self:GetChapterId()
  if chapterData ~= nil then
    self.chapterData = chapterData
  end
  self.scrollReset = false
  self:UpdateData(2)
  self:StartFinishTime()
end

function ActivityThemeBChapterPanel:ScrollToCurStage()
  if self.curStage == nil then
    return
  end
  self:ScrollMoveToMid(self.curStage.mUIRoot.transform.localPosition, 0, 0)
end

function ActivityThemeBChapterPanel:OnRecover()
  local chapterData = self:GetChapterId()
  if chapterData ~= nil then
    self.chapterData = chapterData
  end
  self.scrollReset = false
  self:UpdateData(2)
  self:StartFinishTime()
end

function ActivityThemeBChapterPanel:OnClose()
  self.recordChapterId = 0
  self.chapterId = 0
  self.normalChapterId = 0
  self.storyCount = 0
  self.jumpId = 0
  self.jumpNotOpenId = 0
  self.curStage = nil
  self.lineUpdate = false
  self.scrollReset = false
  self.skipClear = nil
  self.selectDiff = -1
  self:CleanTime()
  self:CleanAllSelected()
  self:RemoveListeners()
  self:CleanFinishTime()
  ResourceManager:DestroyInstance(self.mainBgPrefab)
  self.mainBgPrefab = nil
  self.mainBg = nil
end

function ActivityThemeBChapterPanel:OnHide()
  for _, item in pairs(self.stageItemList) do
    item:DownSortingOrder()
  end
end

function ActivityThemeBChapterPanel:OnClickBack()
  NetCmdThemeData:SetActivityEndDiffIndex(self.chapterData.id, self.chapterData.difficulty_type)
  NetCmdThemeData:SetThemeChapterDiff(self.chapterData.id, self.chapterData.difficulty_type)
  self.mainBg:SetTrigger("FadeOut")
  for _, item in pairs(self.stageItemList) do
    item:UpdateSortingOrder()
  end
end

function ActivityThemeBChapterPanel:OnHideFinish()
end

function ActivityThemeBChapterPanel:OnRelease()
  self.recordChapterId = 0
  self.chapterId = 0
  self.normalChapterId = 0
  self.storyCount = 0
  self.jumpId = 0
  self.jumpNotOpenId = 0
  self.curStage = nil
  self.lineUpdate = false
  self.scrollReset = false
  self.skipClear = nil
  self:CleanTime()
  self:CleanAllSelected()
  self:RemoveListeners()
  self:CleanFinishTime()
end

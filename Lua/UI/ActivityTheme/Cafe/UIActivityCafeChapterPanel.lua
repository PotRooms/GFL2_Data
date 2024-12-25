require("UI.UIBasePanel")
require("UI.BattleIndexPanel.UIBattleDetailDialog")
require("UI.StoryChapterPanel.Item.UIStageLineItem")
require("UI.ActivityTheme.Cafe.UIActivityCafeChapterListItem")
UIActivityCafeChapterPanel = class("UIActivityCafeChapterPanel", UIBasePanel)
UIActivityCafeChapterPanel.__index = UIActivityCafeChapterPanel

function UIActivityCafeChapterPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
end

function UIActivityCafeChapterPanel:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
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
  setactive(self.ui.mTrans_Hard.gameObject, true)
  self.diffLevelList = {}
  self.animateState = -1
end

function UIActivityCafeChapterPanel:OnInit(root, data)
  if data == nil then
    local chapterId = 3002
    self.chapterData = TableData.listChapterDatas:GetDataById(chapterId)
  else
    self.chapterData = data.ChapterData
  end
  self.activityConfigId = data.ActivityConfigId
  self.activityModuleData = data.ActivityModuleData
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIActivityCafeChapterPanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
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
  self:InitDiffData()
  self:AddListeners()
end

function UIActivityCafeChapterPanel:InitDiffData()
  local diffChapterList = TableData.listChapterByDifficultyGroupDatas:GetDataById(self.chapterData.difficulty_group)
  self.diffChapterDiffList = {}
  self.firstScroll = false
  if diffChapterList then
    for i = 0, diffChapterList.Id.Count - 1 do
      local index = i + 1
      setactive(self.ui.mTrans_Action:GetChild(i), true)
      local diffUI = self.diffChapterUIList[index]
      if diffUI == nil then
        diffUI = self:GetUIDetail(self.ui.mTrans_Action:GetChild(i))
        table.insert(self.diffChapterUIList, diffUI)
      end
      diffUI.name.text = TableData.GetHintById(self.diffNameList[index])
      local data = TableData.listChapterDatas:GetDataById(diffChapterList.Id[i], true)
      if NetCmdThemeData:GetLevelBack(data.stage_group) then
        self.diffLevelList[index] = NetCmdThemeData:GetCurrResultLevelId(data.stage_group)
        NetCmdThemeData:SetLevelBack(data.stage_group, false)
      else
        self.diffLevelList[index] = NetCmdThemeData:GetChapterLevelUnLockId(diffChapterList.Id[i])
      end
      if data then
        do
          local timeStr = ""
          local isPlanOpen = NetCmdActivitySimData:IsPlanOpen(data.PlanId, timeStr)
          local lockStr = CS.LuaUIUtils.CheckUnlockPopupStrByRepeatedList(data.unlock)
          local isLock = 0 < string.len(lockStr) or isPlanOpen == -1
          setactive(diffUI.red.gameObject, not isLock and 0 < NetCmdDungeonData:UpdateChatperRewardRedPoint(diffChapterList.Id[i]))
          self.diffChapterDiffList[index] = isLock
          UIUtils.GetButtonListener(diffUI.btn.gameObject).onClick = function()
            local timeStr2 = ""
            local isPlanOpen2, timeStr2 = NetCmdActivitySimData:IsPlanOpen(data.PlanId, timeStr2)
            if isPlanOpen2 == -1 then
              if self.activityModuleData then
                timeStr2 = string_format(TableData.GetActivityHint(271122, self.activityConfigId, 1, self.activityModuleData.type), timeStr2)
                CS.PopupMessageManager.PopupString(timeStr2)
              else
                local content = TableData.GetHintById(272000)
                CS.PopupMessageManager.PopupString(content)
              end
              return
            end
            local lockStr2 = CS.LuaUIUtils.CheckUnlockPopupStrByRepeatedList(data.unlock)
            local isLock2 = string.len(lockStr2) > 0
            if isLock2 then
              CS.PopupMessageManager.PopupString(lockStr2)
              return
            end
            self.diffChapterDiffList[index] = false
            self.firstScroll = true
            self.scrollReset = false
            self.scrollReset = false
            self.chapterData = TableData.listChapterDatas:GetDataById(data.id)
            NetCmdThemeData:SaveEnterChapterIdForCafe(data.id)
            self:UpdateDiffChapter(index)
            self:UpdateData(1)
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
      local diff = NetCmdThemeData:GetThemeChapterDiff(self.chapterData.id)
      if diff < 1 then
        diff = 1
      end
      self:UpdateDiffChapter(diff, false)
    end)
    NetCmdThemeData:SaveEnterChapterIdForCafe(self.chapterData.id)
  end
end

function UIActivityCafeChapterPanel:CleanTime()
  if self.delayTime then
    self.delayTime:Stop()
    self.delayTime = nil
  end
end

function UIActivityCafeChapterPanel:GetUIDetail(trans)
  local cell = {}
  cell.btn = trans:Find("Root"):GetComponent(typeof(CS.UnityEngine.UI.GFButton))
  cell.anim = trans:Find("Root"):GetComponent(typeof(CS.UnityEngine.Animator))
  cell.name = trans:Find("Root/GrpLayout/Text_Difficulty"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  cell.red = trans:Find("Root/Trans_RedPoint"):GetComponent(typeof(CS.UnityEngine.RectTransform))
  cell.anim.keepAnimatorControllerStateOnDisable = true
  return cell
end

function UIActivityCafeChapterPanel:UpdateDiffChapter(index, needAnim)
  if needAnim == nil then
    needAnim = true
  end
  if index == self.selectDiff then
    return
  end
  self.selectDiff = index
  NetCmdThemeData:SetActivityEndDiffIndex(self.chapterData.id, self.chapterData.difficulty_type)
  for i = 1, #self.diffChapterUIList do
    local diffUI = self.diffChapterUIList[i]
    local isLock = self.diffChapterDiffList[i]
    if isLock then
    elseif index == i then
      diffUI.btn.interactable = false
    else
      diffUI.btn.interactable = true
    end
    diffUI.anim:SetBool("Locked", isLock)
  end
  if needAnim then
    if self.chapterData.difficulty_type > 1 then
      self.ui.mAnimator_Root:SetBool("Previous", true)
    else
      self.ui.mAnimator_Root:SetBool("Next", true)
    end
  end
  if self.chapterData.difficulty_type > 1 then
    if self.animateState ~= 1 then
      self.animateState = 1
      self.ui.mAnimator_Hard:ResetTrigger("FadeOut")
      self.ui.mAnimator_Hard:SetBool("FadeIn", true)
    end
  elseif self.animateState ~= 2 then
    self.animateState = 2
    self.ui.mAnimator_Hard:ResetTrigger("FadeIn")
    self.ui.mAnimator_Hard:SetBool("FadeOut", true)
  end
  if not self.ui.mBgScrollHelper.enabled then
    self.ui.mBgScrollHelper.enabled = true
  end
  self.ui.mBgScrollHelper:RefreshPos(true)
  NetCmdDungeonData:RecordDifficultyIdByGroup(self.chapterData.difficulty_group, index)
end

function UIActivityCafeChapterPanel:AddListeners()
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

function UIActivityCafeChapterPanel:RemoveListeners()
  CS.GF2.Message.MessageSys.Instance:RemoveListener(CS.GF2.Message.UIEvent.RefreshChapterInfo, self.UpdateChapterData)
  CS.GF2.Message.MessageSys.Instance:RemoveListener(CS.GF2.Message.AVGEvent.AVGFirstDrop, self.OpenReceivePanel)
  CS.GF2.Message.MessageSys.Instance:RemoveListener(CS.GF2.Message.UIEvent.AvgSceneClose, self.AvgSceneClose)
  CS.GF2.Message.MessageSys.Instance:RemoveListener(CS.GF2.Message.AVGEvent.AVGStartShow, self.OnAVGStartShowCallback)
  MessageSys:RemoveListener(UIEvent.StoryShowDetail, self.ShowCloseNew)
end

function UIActivityCafeChapterPanel:OnClickChapterReward()
  local data = CS.ShowChapterRewardData()
  data.ChapterId = self.chapterData.id
  data.IsDifficult = false
  UIManager.OpenUIByParam(enumUIPanel.UIStoryChapterRewardlDialogV2, data)
end

function UIActivityCafeChapterPanel:OnShowStart()
  self:UpdateData(1)
  self:StartFinishTime()
  local simHelper = CS.Activities.ActivitySim.ActivitySimHelper.Instance
  if simHelper == nil then
    return
  end
  simHelper:SetEnabled(false)
end

function UIActivityCafeChapterPanel:UpdateDiffRed()
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

function UIActivityCafeChapterPanel:UpdateData(index)
  self:UpdateChapterBG()
  self:UpdateChapterInfo()
  self:UpdateStoryStageItem()
  self:UpdateRewardInfo()
  self.jumpId = self.diffLevelList[self.chapterData.difficulty_type]
  self:ResetScroll()
end

function UIActivityCafeChapterPanel:UpdateChapterBG()
  local chapterData = TableData.listChapterDatas:GetDataById(self.chapterData.id)
  self.ui.mImage_Bg.sprite = IconUtils.GetChapterBg(chapterData.map_background)
  if not self.ui.mBgScrollHelper.enabled then
    self.ui.mBgScrollHelper.enabled = true
    self.ui.mBgScrollHelper:RefreshPos(true)
  end
end

function UIActivityCafeChapterPanel:UpdateChapterInfo()
  local activityConfigData = TableDataBase.listActivityConfigDatas:GetDataById(self.activityConfigId)
  if activityConfigData then
    self.ui.mText_ActivityName.text = activityConfigData.name.str
  end
  if type("string") == type(self.chapterData.tab_name) then
    self.ui.mText_ChapterName.text = self.chapterData.tab_name
  else
    self.ui.mText_ChapterName.text = self.chapterData.tab_name.str
  end
  if not self.ui.mBgScrollHelper.enabled then
    self.ui.mBgScrollHelper.enabled = true
    self.ui.mBgScrollHelper:RefreshPos(true)
  end
  if self.themeaticData and self.themeaticData.args.Count > 0 then
    if self.themeaticData.system == 5 then
      local activityEntranceData = TableDataBase.listActivityEntranceDatas:GetDataById(self.themeaticData.args[0], true)
      if activityEntranceData then
        self.ui.mText_ActivityName.text = activityEntranceData.name.str
      end
    elseif self.themeaticData.system == 7 then
      local activityData = TableDataBase.listActivityConfigDatas:GetDataById(self.themeaticData.args[0], true)
      if activityData then
        self.ui.mText_ActivityName.text = activityData.name.str
      end
    end
  end
end

function UIActivityCafeChapterPanel:UpdateRewardInfo()
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
  setactive(self.ui.mTrans_Challenge.gameObject, self.chapterData.chapter_reward_value.Count == 0 and self.chapterData.difficulty_type == 3)
  self:UpdateDiffRed()
end

function UIActivityCafeChapterPanel:UpdateRewardState()
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

function UIActivityCafeChapterPanel:UpdateStoryStageItem()
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
    local nextData
    if i + 1 < storyListData.Count then
      nextData = storyListData[i + 1]
    end
    local posList = string.split(data.position, ",")
    self.storyIdPosList[data.id] = tonumber(posList[1])
    if data.type == GlobalConfig.StoryType.Normal or data.type == GlobalConfig.StoryType.Story then
      local id = GlobalConfig.StoryType.Normal * 100 + count
      self.storyIDIndexList[data.id] = id
      count = count + 1
      if self.stageItemList[id] == nil then
        item = UIActivityCafeChapterListItem.New()
        item:InitCtrl(self.ui.mTrans_CombatList)
        self.stageItemList[id] = item
      else
        item = self.stageItemList[id]
      end
      item:SetMainData(self.chapterData, data, nextData)
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
          item:SetTopGroupData(self.chapterData, branchData)
        elseif 0 > branchData.mSfxPos.y then
          item:SetBtmData(self.chapterData, branchData)
        end
      elseif 0 < branchData.mSfxPos.y then
        item:SetTopData(self.chapterData, branchData)
      elseif 0 > branchData.mSfxPos.y then
        item:SetBtmGroupData(self.chapterData, branchData)
      end
      UIUtils.GetButtonListener(item.itemViewList[branchData.id].ui.mBtn_Stage.gameObject).onClick = function()
        self:OnStoryClick(item, branchData, true)
      end
    end
  end
  self:UpdateCombatContent(firstData, lastData)
  LayoutRebuilder.ForceRebuildLayoutImmediate(self.ui.mTrans_CombatList)
end

function UIActivityCafeChapterPanel:GetMainItemById(preId)
  local mainItem = self.stageItemList[self.storyIDIndexList[preId]]
  while mainItem == nil do
    local data = TableData.listStoryDatas:GetDataById(preId)
    mainItem = self.stageItemList[self.storyIDIndexList[data.pre_id[0]]]
  end
  return mainItem
end

function UIActivityCafeChapterPanel:OnStoryClick(item, data, isBranch, needAni, hideDetails)
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
          shiftingCount = data.mSfxPos.x - mainData.mSfxPos.x
        end
      end
      self:ScrollMoveToMid(item.mUIRoot.transform.localPosition, needAni, true, shiftingCount)
      item:SetSelected(data, true)
      self.curStage = item
    else
      self:ScrollMoveToMid(item.mUIRoot.transform.localPosition, needAni, true, shiftingCount)
    end
  end
end

function UIActivityCafeChapterPanel:CleanAllSelected()
  for _, item in pairs(self.stageItemList) do
    item:CleanAllSelected()
  end
end

function UIActivityCafeChapterPanel:GetMainDataById(branchid)
  local mainData = TableData.listStoryDatas:GetDataById(branchid)
  if mainData == nil then
    return
  end
  while mainData.type == 11 do
    mainData = TableData.listStoryDatas:GetDataById(mainData.pre_id[0])
  end
  return mainData
end

function UIActivityCafeChapterPanel:ShowStageInfo(stageRecord, storyData, stageData)
  UIBattleDetailDialog.OpenByChapterData(LuaUtils.EnumToInt(enumUIPanel.UIStoryChapterPanel), stageData, stageRecord, storyData, NetCmdDungeonData:IsUnLockStory(storyData.id), function(tempFirst)
    if tempFirst then
      self.lineUpdate = false
      self.scrollReset = false
      self:UpdateData(1)
      self.ui.mCanvasGroup_Root.blocksRaycasts = false
    else
      self.lineUpdate = false
      self:UpdateData(1)
      self:OnClickCloseChapterInfoPanel()
    end
  end, true)
end

function UIActivityCafeChapterPanel:OnClickCloseChapterInfoPanel()
  self.ui.mScrollRect_GrpDetailsList.enabled = true
  for _, item in pairs(self.stageItemList) do
    item:CleanAllSelected()
  end
end

function UIActivityCafeChapterPanel:ScrollMoveToMid(itemPos, needSlide, onClick, shiftingCount)
  local content = self.ui.mScrollRect_GrpDetailsList.content
  local newToPos = itemPos.x + content.anchoredPosition.x
  local screenWidth = UISystem.UICanvas.transform.sizeDelta.x
  gfdebug("UIActivityCafeChapterPanel:ScrollMoveToMid" .. screenWidth)
  local toX = screenWidth * 0.3 - newToPos
  local toPos = Vector3(toX, content.localPosition.y, 0)
  local deltaPos = content.localPosition + toPos
  if self.fillAmountTween ~= nil then
    CS.UITweenManager.TweenKill(self.fillAmountTween)
    self.fillAmountTween = nil
  end
  self.ui.mScrollRect_GrpDetailsList.enabled = false
  self.fillAmountTween = CS.UITweenManager.PlayLocalPositionTween(content, content.localPosition, deltaPos, 0.35)
end

function UIActivityCafeChapterPanel:UpdateCombatContent(first, last)
  local panelSize = LuaUtils.GetRectTransformSize(self.mUIRoot.gameObject).x * TableData.GlobalConfigData.SelectedStoryPosition * 2
  local delta = last.mSfxPos.x - first.mSfxPos.x
  self.ui.mTrans_CombatList.sizeDelta = Vector2(delta + panelSize, 0)
end

function UIActivityCafeChapterPanel:GetStoryItemId(id)
  for _, item in pairs(self.stageItemList) do
    if item.storyDataList[_] ~= nil and item.storyDataList[_].id == id then
      return item
    end
  end
end

function UIActivityCafeChapterPanel:ResetScroll()
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
    local normalSize = curItem.mUIRoot.transform.localPosition.x / content.x
    local scrollDelta = UIUtils.Clam(normalSize, 0, 1)
    local currDelta = UIUtils.Clam(self.ui.mScrollRect_GrpDetailsList.horizontalNormalizedPosition, 0, 1)
    if 1 < self.ui.mScrollRect_GrpDetailsList.horizontalNormalizedPosition then
      self.ui.mScrollRect_GrpDetailsList.horizontalNormalizedPosition = 1
    end
    if self.firstScroll then
      if math.abs(scrollDelta - currDelta) <= 0.3 then
        self.ui.mScrollRect_GrpDetailsList.horizontalNormalizedPosition = scrollDelta
      elseif scrollDelta > currDelta then
        self.ui.mScrollRect_GrpDetailsList.horizontalNormalizedPosition = UIUtils.Clam(scrollDelta - 0.3, 0, 1)
        CS.UITweenManager.PlayScrollRectNormalPos(self.ui.mScrollRect_GrpDetailsList, scrollDelta, 0.5, CS.DG.Tweening.Ease.OutExpo)
      else
        self.ui.mScrollRect_GrpDetailsList.horizontalNormalizedPosition = UIUtils.Clam(scrollDelta + 0.3, 0, 1)
        CS.UITweenManager.PlayScrollRectNormalPos(self.ui.mScrollRect_GrpDetailsList, scrollDelta, 0.5, CS.DG.Tweening.Ease.OutExpo)
      end
    else
      self.ui.mScrollRect_GrpDetailsList.horizontalNormalizedPosition = scrollDelta
    end
  end
  self.scrollReset = true
end

function UIActivityCafeChapterPanel:CleanFinishTime()
  if self.finishTime then
    self.finishTime:Stop()
    self.finishTime = nil
  end
end

function UIActivityCafeChapterPanel:StartFinishTime()
  self:CleanFinishTime()
  if self.chapterData.tab == 0 then
    local planData = TableData.listPlanDatas:GetDataById(self.chapterData.plan_id, true)
    if planData then
      do
        local repeatCount = planData.close_time - CGameTime:GetTimestamp()
        if repeatCount < 1 then
          self:CleanFinishTime()
          local content = MessageContent.New(TableData.GetHintById(270144), MessageContent.MessageType.SingleBtn, function()
            UIManager.CloseUI(UIDef.UIActivityCafeChapterPanel)
          end)
          MessageBoxPanel.Show(content)
          return
        end
        self.finishTime = TimerSys:DelayCall(1, function()
          if CGameTime:GetTimestamp() >= planData.close_time then
            self:CleanFinishTime()
            local content = MessageContent.New(TableData.GetHintById(990009), MessageContent.MessageType.SingleBtn, function()
              UIManager.CloseUI(UIDef.UIActivityCafeChapterPanel)
            end)
            MessageBoxPanel.Show(content)
          end
        end, nil, repeatCount)
      end
    end
  end
end

function UIActivityCafeChapterPanel:OnShowFinish()
end

function UIActivityCafeChapterPanel:OnTop()
end

function UIActivityCafeChapterPanel:GetChapterId()
  local difficultyId = NetCmdDungeonData:GetRecordedDifficultyIdByGroup(self.chapterData.difficulty_group)
  local targetChapterData = NetCmdDungeonData:GetStoryCharterDataByDifficultyGroup(self.chapterData.difficulty_group, difficultyId)
  return targetChapterData
end

function UIActivityCafeChapterPanel:OnBackFrom()
  local chapterData = self:GetChapterId()
  if chapterData ~= nil then
    self.chapterData = chapterData
  end
  self:UpdateData(2)
  self:StartFinishTime()
end

function UIActivityCafeChapterPanel:OnRecover()
  local chapterData = self:GetChapterId()
  if chapterData ~= nil then
    self.chapterData = chapterData
  end
  self:UpdateData(2)
  self:StartFinishTime()
end

function UIActivityCafeChapterPanel:OnClose()
  self.recordChapterId = 0
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
  self.animateState = -1
  self:CleanAllSelected()
  self:RemoveListeners()
  self:CleanFinishTime()
end

function UIActivityCafeChapterPanel:OnHide()
  NetCmdThemeData:SetActivityEndDiffIndex(self.chapterData.id, self.chapterData.difficulty_type)
  NetCmdThemeData:SetThemeChapterDiff(self.chapterData.id, self.chapterData.difficulty_type)
end

function UIActivityCafeChapterPanel:OnHideFinish()
end

function UIActivityCafeChapterPanel:OnRelease()
  self.recordChapterId = 0
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

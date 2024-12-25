require("UI.BattleIndexPanel.Item.UIBattleIndexTabStoryItem")
require("UI.ChapterPanel.UIChapterGlobal")
UIBattleIndexStorySubPanel = class("UIBattleIndexStorySubPanel", UIBaseView)

function UIBattleIndexStorySubPanel:InitCtrl(root, uiBattleIndexPanel)
  self.ui = UIUtils.GetUIBindTable(root)
  self:SetRoot(root.transform)
  self.uiBattleIndexPanel = uiBattleIndexPanel
  self.curTab = nil
  self.difficult = 1
  
  function self.ui.mVirtualList.itemCreated(renderData)
    local item = self:ItemProvider(renderData)
    return item
  end
  
  function self.ui.mVirtualList.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
  
  UIUtils.GetButtonListener(self.ui.mBtn_Ok.gameObject).onClick = function()
    self:EnterChapter()
  end
  UIUtils.AddBtnClickListener(self.ui.mBtn_TutorialStage, function()
    self:OnClickTutorialStage()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Normal, function()
    self:OnClickNormal()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Hard, function()
    self:OnClickHard()
  end)
  self:AddListeners()
  print_debug("StorySubPanel:InitCtrl")
end

function UIBattleIndexStorySubPanel:AddListeners()
  function self.StoryChangeToHard()
    self:OnClickHard()
  end
  
  function self.StoryChangeToNormal()
    self:OnClickNormal()
  end
  
  CS.GF2.Message.MessageSys.Instance:AddListener(CS.GF2.Message.UIEvent.StoryChangeToHard, self.StoryChangeToHard)
  CS.GF2.Message.MessageSys.Instance:AddListener(CS.GF2.Message.UIEvent.StoryChangeToNormal, self.StoryChangeToNormal)
end

function UIBattleIndexStorySubPanel:RemoveListeners()
  CS.GF2.Message.MessageSys.Instance:RemoveListener(CS.GF2.Message.UIEvent.StoryChangeToHard, self.StoryChangeToHard)
  CS.GF2.Message.MessageSys.Instance:RemoveListener(CS.GF2.Message.UIEvent.StoryChangeToNormal, self.StoryChangeToNormal)
end

function UIBattleIndexStorySubPanel:OnShowStart()
  local recordData = NetCmdDungeonData:GetRecordUserAction()
  local tempId = NetCmdDungeonData:GetMaxClearedChapterIdWithIgnoreDifficulty()
  if 0 < recordData then
    local targetChapterData = TableDataBase.listChapterDatas:GetDataById(recordData)
    tempId = targetChapterData.id
    self.difficult = targetChapterData.difficulty_type
  end
  self:RefreshTabs()
  self.ui.mVirtualList:ForceRefresh()
  self:OnClickTabByChapterId(tempId, true)
  self:NewChapterUnlock()
  print_debug("StorySubPanel:OnShowStart")
end

function UIBattleIndexStorySubPanel:OnShowFinish()
  print_debug("StorySubPanel:OnShowFinish")
end

function UIBattleIndexStorySubPanel:OnBackFrom()
  self:RefreshTabs()
  self:NewChapterUnlock()
  self:OnClickTabByRecordChapterId()
  print_debug("StorySubPanel:OnBackFrom")
end

function UIBattleIndexStorySubPanel:OnTop()
  print_debug("StorySubPanel:OnTop")
end

function UIBattleIndexStorySubPanel:OnRecover()
  local recordData = NetCmdDungeonData:GetRecordUserAction()
  if 0 < recordData then
    local targetChapterData = TableDataBase.listChapterDatas:GetDataById(recordData)
    self.difficult = targetChapterData.difficulty_type
  end
  self:RefreshTabs()
  self:NewChapterUnlock()
  self:OnClickTabByRecordChapterId()
  print_debug("StorySubPanel:OnRecover")
end

function UIBattleIndexStorySubPanel:OnHide()
  self:ReleaseCtrlTable(self.tabList, true)
end

function UIBattleIndexStorySubPanel:OnClose()
  self.opened = nil
  self.curTab = nil
  self.chapterDataList = nil
  if self.timer1 ~= nil then
    self.timer1:Stop()
    self.timer1 = nil
  end
  if self.timer2 ~= nil then
    self.timer2:Stop()
    self.timer2 = nil
  end
  if self.timer3 ~= nil then
    self.timer3:Stop()
    self.timer3 = nil
  end
  self:RemoveListeners()
end

function UIBattleIndexStorySubPanel:OnRelease()
end

function UIBattleIndexStorySubPanel:Refresh()
  self:RefreshTabs()
  TimerSys:DelayFrameCall(1, function()
    self.ui.mAnimator_Root:SetTrigger("FX")
  end)
end

function UIBattleIndexStorySubPanel:RefreshTabs()
  self.chapterDataList = NetCmdDungeonData:GetStoryChapterDataListByDifficulty(self.difficult)
  self.ui.mVirtualList.numItems = self.chapterDataList.Count
  self.ui.mVirtualList:Refresh()
  self:RefreshTutorialStageTab()
end

function UIBattleIndexStorySubPanel:IsReadyToStartTutorial()
  return not NetCmdDungeonData.HasNewChapterUnlocked
end

function UIBattleIndexStorySubPanel:SetCurrentIndex(index)
  UIChapterGlobal:RecordChapterId(index)
end

function UIBattleIndexStorySubPanel:NewChapterUnlock()
  local newIdList = NetCmdDungeonData.NewChapterIDList
  if NetCmdDungeonData.HasNewChapterUnlocked and newIdList.Count > 0 then
    local index = 0
    local chapterId = newIdList[index]
    local chapterData = TableDataBase.listChapterDatas:GetDataById(chapterId)
    if chapterData == nil then
      return
    end
    if chapterData.difficulty_type == 1 then
      self.timer1 = TimerSys:DelayCall(0.5, function()
        UIManager.OpenUIByParam(UIDef.UINewChapterShowDialog, {NewChapterID = chapterId})
        NetCmdDungeonData:ClearNewChapterIDList()
      end)
    else
      do
        local function showDifTip()
          local difficultyName = TableData.GetHintById(103200 + chapterData.difficulty_type)
          
          local str = string_format(TableData.GetHintById(103206), chapterData.name, difficultyName)
          PopupMessageManager.PopupDZStateChangeString(str, function()
            NetCmdDungeonData.HasNewChapterUnlocked = false
            NetCmdDungeonData.NewChapterID = -1
            NetCmdDungeonData:ClearNewChapterIDList()
            MessageSys:SendMessage(UIEvent.UINewChapterShowFinish, nil)
          end)
          index = index + 1
          if index < newIdList.Count then
            chapterId = newIdList[index]
            chapterData = TableDataBase.listChapterDatas:GetDataById(chapterId)
            if chapterData == nil then
              return
            end
            if chapterData.difficulty_type == 2 then
              self.timer3 = TimerSys:DelayCall(0.5, showDifTip)
            end
          end
        end
        
        self.timer2 = TimerSys:DelayCall(0.5, function()
          NetCmdDungeonData:WriteUnlockDataToClient()
          showDifTip()
        end)
      end
    end
  end
end

function UIBattleIndexStorySubPanel:OnClickTabByRecordChapterId()
  local recordData = NetCmdDungeonData:GetRecordUserAction()
  local tempId = NetCmdDungeonData:GetMaxClearedChapterIdWithIgnoreDifficulty()
  local chapterId = 0 < recordData and recordData or tempId
  self:OnClickTabByChapterId(chapterId, true)
end

function UIBattleIndexStorySubPanel:OnClickTabByChapterId(chapterId, needScrollTo)
  local chapterData = TableDataBase.listChapterDatas:GetDataById(chapterId)
  self:OnClickTab(chapterData, needScrollTo)
end

function UIBattleIndexStorySubPanel:OnClickTab(data, needScrollTo)
  local id = data.id
  local str = CS.LuaUIUtils.CheckUnlockPopupStrByRepeatedList(data.unlock)
  if string.len(str) > 0 then
    CS.PopupMessageManager.PopupString(str)
    return
  end
  self.curTab = data
  local scrollIndex = -1
  local chapterCount = self.chapterDataList.Count - 1
  for i = 0, chapterCount do
    local v = self.chapterDataList[i]
    if v.id == id then
      scrollIndex = i
      break
    end
  end
  local obj = self.ui.mVirtualList:GetViewItemByIndex(scrollIndex)
  if obj then
    local itemView = obj.data
    self.globalTab = itemView:GetGlobalTab()
    self.curTabIsUnlock = itemView.isUnLock
    self.curTabIsNew = itemView.isNew
  end
  if needScrollTo == false then
    scrollIndex = -1
  end
  self:OnClickTabAfter(data, scrollIndex)
  NetCmdDungeonData:RecordUserAction(id)
end

function UIBattleIndexStorySubPanel:OnClickTabAfter(data, scrollIndex)
  UIChapterGlobal:RecordChapterId(data.id)
  self:RefreshByDifficulty(data)
  self:RefreshNormalHard(data)
  self:CalculatePercent()
  self.ui.mText_Des.text = data.chapter_des.str
  if 0 <= scrollIndex then
    self.ui.mVirtualList:ScrollTo(scrollIndex)
  end
  MessageSys:SendMessage(GuideEvent.OnTabSwitched, UIDef.UIBattleIndexPanel, self.globalTab)
  self.ui.mVirtualList:Refresh()
end

function UIBattleIndexStorySubPanel:RefreshByDifficulty(chapterData)
  if not chapterData then
    return
  end
  local difficulty = NetCmdDungeonData:GetChapterDifficultyId(chapterData.id)
  setactivewithcheck(self.ui.mTrans_GrpDifficulty1, false)
  setactivewithcheck(self.ui.mTrans_GrpDifficulty2, false)
  setactivewithcheck(self.ui.mTrans_Difficulty1Fx, difficulty == 1)
  setactivewithcheck(self.ui.mTrans_Difficulty2Fx, difficulty == 2)
  setactivewithcheck(self.ui.mText_Normal, difficulty == 1)
  setactivewithcheck(self.ui.mText_Hard, difficulty == 2)
  setactivewithcheck(self.ui.mTrans_Difficulty1Fx, false)
  setactivewithcheck(self.ui.mTrans_Difficulty2Fx, false)
  if difficulty == 1 then
    IconUtils.GetStageIconAsync(self.ui.mImg_Difficulty1Bg, chapterData.background)
    IconUtils.GetStageIconAsync(self.ui.mImg_Difficulty1Bg_Fx, chapterData.background)
    setactivewithcheck(self.ui.mTrans_Difficulty1Fx, true)
  else
    IconUtils.GetStageIconAsync(self.ui.mImg_Difficulty2Bg, chapterData.background)
    IconUtils.GetStageIconAsync(self.ui.mImg_Difficulty2Bg_Fx, chapterData.background)
    setactivewithcheck(self.ui.mTrans_Difficulty2Fx, true)
  end
  self.ui.mAnimator_Root:SetTrigger("FX")
end

function UIBattleIndexStorySubPanel:EnterChapter()
  if self.opened then
    return
  end
  local chapterId = self.curTab.id
  if chapterId and self.curTabIsUnlock then
    if self.curTabIsNew == true then
      AccountNetCmdHandler:UpdateWatchedChapter(chapterId)
      self.curTabIsNew = false
      if self.opened == nil then
        self.opened = true
      end
      local story = TableData.GetFirstStoryByChapterID(chapterId)
      CS.AVGController.PlayAVG(story.stage_id, 10, function()
        local data = CS.ShowStoryChapterData()
        data.ChapterId = chapterId
        data.DataType = CS.EShowStoryChapterDataType.UsebehaviorId
        UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIStoryChapterPanel, data)
        gfdebug("\229\136\157\230\172\161\231\130\185\229\135\187\232\191\155\229\133\165\231\171\160\232\138\130")
        self.opened = nil
      end)
    else
      local data = CS.ShowStoryChapterData()
      data.ChapterId = chapterId
      data.DataType = CS.EShowStoryChapterDataType.UsebehaviorId
      UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIStoryChapterPanel, data)
      self.opened = nil
    end
  end
end

function UIBattleIndexStorySubPanel:CalculatePercent()
  local storyCount = NetCmdDungeonData:GetCanChallengeStoryList(self.curTab.id).Count
  local total = storyCount * UIChapterGlobal.MaxChallengeNum
  local stars = NetCmdDungeonData:GetCurStarsByChapterID(self.curTab.id)
  local storyData = NetCmdDungeonData:GetCurrentStory()
  self.ui.mText_Num.text = storyData.code.str
  self.ui.mText_Percentage.text = tostring(math.ceil(stars / total * 100)) .. "%"
  self.ui.mText_PercentNum.text = string_format(TableData.GetHintById(112016), stars, total)
  if stars == total then
    self.ui.mColor_Bg.color = ColorUtils.RedColor5
  else
    self.ui.mColor_Bg.color = ColorUtils.BlueColor5
  end
end

function UIBattleIndexStorySubPanel:RefreshTutorialStageTab()
  local isNeedRedPoint = NetCmdSimulateBattleData:CheckTeachingUnlockRedPoint()
  setactive(self.ui.mTrans_TutorialStageRedPoint, isNeedRedPoint)
  local stageTypeId = LuaUtils.EnumToInt(StageType.TutorialStage)
  local underCombatTypeData = TableDataBase.listUnderCombatTypeDatas:GetDataById(stageTypeId)
  local isUnlock = AccountNetCmdHandler:CheckSystemIsUnLock(underCombatTypeData.unlock)
  if not isUnLock then
    setactivewithcheck(self.ui.mTrans_TutorialLock, not isUnlock)
    UIUtils.SetTextAlpha(self.ui.mText_Text, 0.7)
    UIUtils.SetAlpha(self.ui.mImg_ImgDeco1, 0.7)
  end
  local spriteName = NetCmdSimulateBattleData:GetSimCombatTutorialLevelSpriteName("Img_Img_BattleIndexGuide_")
  self.ui.mImg_Num.sprite = IconUtils.GetAtlasV2("BattleIndexBg", spriteName)
end

function UIBattleIndexStorySubPanel:OnClickTutorialStage()
  local enumId = LuaUtils.EnumToInt(StageType.TutorialStage)
  local underCombatTypeData = TableDataBase.listUnderCombatTypeDatas:GetDataById(enumId)
  if not AccountNetCmdHandler:CheckSystemIsUnLock(underCombatTypeData.unlock) then
    local unlockDetailData = TableDataBase.listUnlockDetailDatas:GetDataById(underCombatTypeData.unlock)
    if unlockDetailData then
      PopupMessageManager.PopupString(unlockDetailData.des.str)
    end
    return
  end
  local simType = underCombatTypeData.id
  local eType = StageType.__CastFrom(simType)
  NetCmdStageRecordData:RequestStageRecordByType(eType, function(ret)
    if ret == ErrorCodeSuc then
      local sectionTutorialData = TableData.listSimCombatTutorialSectionDatas:GetDataById(1)
      if not AccountNetCmdHandler:CheckSystemIsUnLock(sectionTutorialData.section_unlock_n[0]) then
        PopupMessageManager.PopupString(sectionTutorialData.unlcok_tips.str)
        return
      end
      if NetCmdSimulateBattleData:CheckTutorialRedPoint() then
        NetCmdSimulateBattleData:RemoveTutorialRedPoint()
      end
      UIManager.OpenUI(CS.GF2.UI.enumUIPanel.UISimCombatTutorialEntrancePanelV2)
    end
  end)
end

function UIBattleIndexStorySubPanel:ItemProvider(renderData)
  local itemView = UIBattleIndexTabStoryItem.New()
  itemView:InitCtrlWithoutInstance(renderData.gameObject.transform)
  UIUtils.GetButtonListener(itemView.ui.mBtn_Root.gameObject).onClick = function()
    self:OnClickTab(itemView.mData, false)
  end
  renderData.data = itemView
end

function UIBattleIndexStorySubPanel:ItemRenderer(index, renderData)
  if not self.chapterDataList then
    return
  end
  local item = renderData.data
  local chapterData = self.chapterDataList[index]
  item:SetData(chapterData)
  item:SetIndexText(index + 1)
  item:SetGlobalTabId(chapterData.GlobalTab)
  item:SetVisible(true)
  if self.curTab then
    if self.curTab.id == chapterData.id then
      self.curTabIsUnlock = item.isUnLock
    end
    item:SetSelectState(self.curTab.id)
  end
end

function UIBattleIndexStorySubPanel:OnClickNormal()
  self.difficult = 1
  self:RefreshTabs()
  local chapterDataOfDifficulty1 = NetCmdDungeonData:GetStoryCharterDataByDifficultyGroup(self.curTab, 1)
  self:OnClickTabByChapterId(chapterDataOfDifficulty1.id, true)
end

function UIBattleIndexStorySubPanel:OnClickHard()
  local diffData = NetCmdDungeonData:GetStoryChapterDataListByDifficulty(2)
  local isUnlockOfDifficulty2 = NetCmdDungeonData:IsUnLockChapter(diffData[0].id)
  if isUnlockOfDifficulty2 == false then
    local str = CS.LuaUIUtils.CheckUnlockPopupStrByRepeatedList(diffData[0].unlock)
    if 0 < string.len(str) then
      CS.PopupMessageManager.PopupString(str)
    end
    return
  end
  self.difficult = 2
  self:RefreshTabs()
  local lastData = NetCmdDungeonData:GetDiffLastChapterData()
  if lastData.difficulty_group < self.curTab.difficulty_group then
    self:OnClickTabByChapterId(lastData.id, true)
  else
    local chapterDataOfDifficulty2 = NetCmdDungeonData:GetStoryCharterDataByDifficultyGroup(self.curTab, 2)
    self:OnClickTabByChapterId(chapterDataOfDifficulty2.id, true)
  end
end

function UIBattleIndexStorySubPanel:RefreshNormalHard(chapterData)
  local chapterDataOfDifficulty1 = NetCmdDungeonData:GetStoryCharterDataByDifficultyGroup(chapterData, 1)
  local canReceive1 = NetCmdDungeonData:UpdateChatperRewardRedPoint(chapterDataOfDifficulty1.id) > 0
  setactivewithcheck(self.ui.mRed_Normal, canReceive1)
  local chapterDataOfDifficulty2 = NetCmdDungeonData:GetStoryCharterDataByDifficultyGroup(chapterData, 2)
  local diffData = NetCmdDungeonData:GetStoryChapterDataListByDifficulty(2)
  local isUnlockOfDifficulty2 = NetCmdDungeonData:IsUnLockChapter(diffData[0].id)
  self.ui.mAnim_Hard:SetBool("UnLocked", isUnlockOfDifficulty2)
  local canReceive2 = NetCmdDungeonData:UpdateChatperRewardRedPoint(chapterDataOfDifficulty2.id) > 0
  local isNewChapter2 = 0 < NetCmdDungeonData:UpdateChatperNewUnlockRedPoint(chapterDataOfDifficulty2.id)
  setactivewithcheck(self.ui.mRed_Hard, isUnlockOfDifficulty2 and (canReceive2 or isNewChapter2))
  self.ui.mBtn_Normal.interactable = chapterData.difficulty_type ~= 1
  self.ui.mBtn_Hard.interactable = chapterData.difficulty_type ~= 2
end

require("UI.UIBaseCtrl")
require("UI.ChapterPanel.UIChapterGlobal")
Btn_ActivityThemeBChapterListItem = class("Btn_ActivityThemeBChapterListItem", UIBaseCtrl)
Btn_ActivityThemeBChapterListItem.__index = Btn_ActivityThemeBChapterListItem

function Btn_ActivityThemeBChapterListItem:ctor()
end

function Btn_ActivityThemeBChapterListItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:SetRoot(instObj.transform)
  self.isUnlock = false
  self.challengeList = {}
  for i = 1, UIChapterGlobal.MaxChallengeNum do
    local challenge = {}
    local obj = self:GetRectTransform("Root/GrpStar/Star_" .. i)
    challenge.obj = obj
    challenge.tranOff = UIUtils.GetRectTransform(obj, "Star_Off")
    challenge.tranOn = UIUtils.GetRectTransform(obj, "Star_On")
    table.insert(self.challengeList, challenge)
  end
  setactivewithcheck(self.ui.mImage_PreMidLine, false)
  setactivewithcheck(self.ui.mImage_PreBlowLine, false)
  setactivewithcheck(self.ui.mImage_PreAboveLine, false)
end

function Btn_ActivityThemeBChapterListItem:SetData(chapterData, data)
  self.chapterData = chapterData
  self.storyData = data
  self:UpdateStage()
end

function Btn_ActivityThemeBChapterListItem:UpdateItem()
end

function Btn_ActivityThemeBChapterListItem:UpdateStage()
  self.ui.mTrans_Self.sizeDelta = Vector2.zero
  if self.ui.mText_Title then
    self.ui.mText_Title.text = "/"
  end
  self.ui.mText_StageName.text = self.storyData.name.str
  if self.ui.mText_ChapterName then
    self.ui.mText_ChapterName.text = self.chapterData.name.str
  end
  local stageData = TableData.GetStageData(self.storyData.stage_id)
  local stageRecord = NetCmdDungeonData:GetCmdStoryData(self.storyData.id)
  self.isNext = stageRecord == nil and true or stageRecord.first_pass_time <= 0
  setactive(self.ui.mTrans_Sound.gameObject, self.storyData.type == GlobalConfig.StoryType.Story)
  if stageData ~= nil then
    setactive(self.ui.mTrans_RewardIcon, 0 < stageData.reward_show and self.isNext)
    if 0 < stageData.reward_show then
      local rewardBubbleItem = UIRewardBubbleItem.New()
      rewardBubbleItem:InitObj(self.ui.mObj_RewardIcon)
      rewardBubbleItem:SetData(stageData.reward_show)
    end
    self.isUnlock = NetCmdThemeData:LevelIsUnLock(self.storyData.id)
    setactive(self.ui.mTrans_NowProgress, self.isNext and self.isUnlock and self.storyData.type ~= GlobalConfig.StoryType.Branch)
    local haveStar = self.storyData.type ~= GlobalConfig.StoryType.StoryBattle and 0 < stageData.challenge_list.Count and self.isUnlock
    setactive(self.ui.mTrans_Star, haveStar)
    setactive(self.ui.mTrans_NoneStar, not haveStar and self.storyData.type ~= GlobalConfig.StoryType.Story)
    if self.isUnlock then
      if stageRecord then
        if self.storyData.type == GlobalConfig.StoryType.StoryBattle then
          setactive(self.ui.mTrans_Complete, true)
        elseif self.storyData.type == GlobalConfig.StoryType.Story then
          setactive(self.ui.mTrans_Complete, stageRecord.first_pass_time > 0)
        else
          setactive(self.ui.mTrans_Complete, stageRecord.ChallengeNum >= UIChapterGlobal.MaxChallengeNum)
        end
      else
        setactive(self.ui.mTrans_Complete, false)
      end
      setactive(self.ui.mTrans_StoryUnlock.gameObject, false)
    else
      setactive(self.ui.mTrans_Complete, false)
      setactive(self.ui.mTrans_StoryUnlock.gameObject, true)
      self.ui.mImg_AboveNextLine.color = Color(0.13333333333333333, 0.13333333333333333, 0.13333333333333333, 0.8)
    end
    self:UpdateChallenge(stageRecord)
  end
  self:RefreshTitleColor()
  self:RefreshStoryNumColor()
  self:RefreshCanRaidSprite()
  self:RefreshCanRaidIconVisible()
  self:RefreshStarSprite()
  self:RefreshStarBgSprite()
  self:RefreshStorySoundSprite()
  self:RefreshStarBgVisible()
  self:RefreshProgressSprite()
  self:RefreshHLSprite()
  self:RefreshSelectedSprite()
  self:RefreshSelectedBg()
  self:RefreshLockSprite()
  self:RefreshLineSprite()
  self:RefreshBranchLineSprite()
end

function Btn_ActivityThemeBChapterListItem:UpdateChallenge(cmdData)
  local stageData = TableData.GetStageData(self.storyData.stage_id)
  if cmdData then
    for i, obj in ipairs(self.challengeList) do
      if cmdData ~= nil and i <= cmdData.ChallengeNum then
        setactive(obj.tranOn, true)
        setactive(obj.tranOff, false)
      else
        setactive(obj.tranOn, false)
        setactive(obj.tranOff, true)
      end
      if i > stageData.ChallengeList.Count then
        setactive(obj.obj, false)
      else
        setactive(obj.obj, true)
      end
    end
  else
    for i, obj in ipairs(self.challengeList) do
      setactive(obj.tranOff, true)
      setactive(obj.tranOn, false)
      if i > stageData.ChallengeList.Count then
        setactive(obj.obj, false)
      else
        setactive(obj.obj, true)
      end
    end
  end
end

function Btn_ActivityThemeBChapterListItem:UpdateBg(index)
  if index == 1 then
    setactive(self.ui.mTrans_Hard.gameObject, 1 < self.chapterData.difficulty_type)
    setactive(self.ui.mTrans_Main.gameObject, self.chapterData.difficulty_type == 1)
    setactive(self.ui.mTrans_Branch.gameObject, false)
  elseif index == 2 then
    setactive(self.ui.mTrans_Hard.gameObject, false)
    setactive(self.ui.mTrans_Main.gameObject, false)
    setactive(self.ui.mTrans_Branch.gameObject, true)
  end
  self:RefreshMainBgSprite(index == 2)
end

function Btn_ActivityThemeBChapterListItem:SetNextLine(isShow)
end

function Btn_ActivityThemeBChapterListItem:SetPreMidLineVisible(isVisible)
  setactive(self.ui.mImage_PreMidLine.gameObject, isVisible)
end

function Btn_ActivityThemeBChapterListItem:SetPreBottomBranchLineVisible(isVisible)
  setactivewithcheck(self.ui.mImage_PreBlowLine, isVisible)
end

function Btn_ActivityThemeBChapterListItem:SetPreTopBranchLineVisible(isVisible)
  setactivewithcheck(self.ui.mImage_PreAboveLine, isVisible)
end

function Btn_ActivityThemeBChapterListItem:SetPreMidLineColor(color)
  self.ui.mImage_PreMidLine.color = color
end

function Btn_ActivityThemeBChapterListItem:SetPreBottomBranchLineColor(color)
  self.ui.mImage_PreBlowLine.color = color
end

function Btn_ActivityThemeBChapterListItem:SetPreTopBranchLineColor(color)
  self.ui.mImage_PreAboveLine.color = color
end

function Btn_ActivityThemeBChapterListItem:SetSelected(isSelect)
  if LuaUtils.IsNullOrDestroyed(self.ui.mBtn_Stage) then
    return
  end
  self.ui.mBtn_Stage.interactable = not isSelect
  if isSelect then
    setactive(self.ui.mTrans_NowProgress, false)
  else
    setactive(self.ui.mTrans_NowProgress, self.isNext and self.isUnlock and self.storyData.type ~= GlobalConfig.StoryType.Branch)
  end
end

function Btn_ActivityThemeBChapterListItem:RefreshTitleColor()
  if self.ui.mText_Title then
    self.ui.mText_Title.color = NetCmdThemeData:GetItemNameColorForChallenge(self.chapterData.id)
  end
end

function Btn_ActivityThemeBChapterListItem:RefreshStoryNumColor()
  if self.ui.mText_ChapterName then
    self.ui.mText_ChapterName.color = NetCmdThemeData:GetStoryNumberColor(self.chapterData.id)
  end
end

function Btn_ActivityThemeBChapterListItem:RefreshCanRaidSprite()
  self.ui.mImage_Auto.sprite = NetCmdThemeData:GetCanRaidSprite(self.chapterData.id)
end

function Btn_ActivityThemeBChapterListItem:RefreshCanRaidIconVisible()
  local isCanRaid = NetCmdThemeData:IsCanRaid(self.storyData.stage_id)
  setactivewithcheck(self.ui.mImage_Auto.gameObject, false)
end

function Btn_ActivityThemeBChapterListItem:RefreshStarBgVisible()
end

function Btn_ActivityThemeBChapterListItem:RefreshStarSprite()
  self.ui.mImage_Star1Off.sprite = NetCmdThemeData:GetStageStarSprite(self.chapterData.id, false)
  self.ui.mImage_Star1On.sprite = NetCmdThemeData:GetStageStarSprite(self.chapterData.id, true)
  self.ui.mImage_Star2Off.sprite = NetCmdThemeData:GetStageStarSprite(self.chapterData.id, false)
  self.ui.mImage_Star2On.sprite = NetCmdThemeData:GetStageStarSprite(self.chapterData.id, true)
  self.ui.mImage_Star3Off.sprite = NetCmdThemeData:GetStageStarSprite(self.chapterData.id, false)
  self.ui.mImage_Star3On.sprite = NetCmdThemeData:GetStageStarSprite(self.chapterData.id, true)
end

function Btn_ActivityThemeBChapterListItem:RefreshProgressSprite()
  self.ui.mImage_ProgressNow.sprite = NetCmdThemeData:GetProgressNowSprite(self.chapterData.id)
end

function Btn_ActivityThemeBChapterListItem:RefreshMainBgSprite(isBranch)
  if isBranch then
    self.ui.mImage_BranchBg.sprite = NetCmdThemeData:GetBranchStageBg(self.chapterData.id)
  elseif self.chapterData.difficulty_type == 1 then
    self.ui.mImage_MainBg.sprite = NetCmdThemeData:GetMainStageBg(self.chapterData.id)
  else
    self.ui.mImage_HardBg.sprite = NetCmdThemeData:GetMainStageBg(self.chapterData.id)
  end
end

function Btn_ActivityThemeBChapterListItem:RefreshHLSprite()
  self.ui.mImage_HL.sprite = NetCmdThemeData:GetButtonHLSprite(self.chapterData.id)
end

function Btn_ActivityThemeBChapterListItem:RefreshSelectedSprite()
  self.ui.mImage_Sel.sprite = NetCmdThemeData:GetButtonSelectedSprite(self.chapterData.id)
end

function Btn_ActivityThemeBChapterListItem:RefreshSelectedBg()
  self.ui.mImage_Selected.sprite = NetCmdThemeData:GetButtonSelectedBg(self.chapterData.id)
end

function Btn_ActivityThemeBChapterListItem:RefreshLockSprite()
  self.ui.mImage_Lock.sprite = NetCmdThemeData:GetLockSprite(self.chapterData.id)
end

function Btn_ActivityThemeBChapterListItem:RefreshStarBgSprite()
  self.ui.mImage_StarBg.sprite = NetCmdThemeData:GetMainStarBg(self.chapterData.id)
end

function Btn_ActivityThemeBChapterListItem:RefreshStorySoundSprite()
  if self.storyData.type == GlobalConfig.StoryType.Story then
    self.ui.mImage_Sound.sprite = NetCmdThemeData:GetStoryStageSoundBg(self.chapterData.id)
  end
end

function Btn_ActivityThemeBChapterListItem:RefreshLineSprite()
  self.ui.mImage_PreMidLine.sprite = NetCmdThemeData:GetLineSprite(self.chapterData.id)
end

function Btn_ActivityThemeBChapterListItem:RefreshBranchLineSprite()
  self.ui.mImage_PreBlowLine.sprite = NetCmdThemeData:GetBranchLineSprite(self.chapterData.id)
  self.ui.mImage_PreAboveLine.sprite = NetCmdThemeData:GetBranchLineSprite(self.chapterData.id)
end

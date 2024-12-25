require("UI.UIBaseCtrl")
require("UI.ChapterPanel.UIChapterGlobal")
UIActivityCafeBtnItem = class("UIActivityCafeBtnItem", UIBaseCtrl)

function UIActivityCafeBtnItem:InitCtrl(parent)
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
    local obj = self:GetRectTransform("Root/GrpInfo/GrpStar/Star_" .. i)
    challenge.obj = obj
    challenge.tranOff = UIUtils.GetRectTransform(obj, "Star_Off")
    challenge.tranOn = UIUtils.GetRectTransform(obj, "Star_On")
    table.insert(self.challengeList, challenge)
  end
end

function UIActivityCafeBtnItem:SetData(chapterData, data)
  self.chapterData = chapterData
  self.storyData = data
  self:UpdateStage()
end

function UIActivityCafeBtnItem:UpdateItem()
end

function UIActivityCafeBtnItem:UpdateStage()
  self.ui.mTrans_Self.sizeDelta = Vector2.zero
  self.ui.mText_Title.text = "/"
  self.ui.mText_StageName.text = self.storyData.name.str
  self.ui.mText_ChapterName.text = self.chapterData.name.str
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
    local haveStar = self.storyData.type ~= GlobalConfig.StoryType.StoryBattle and 0 < stageData.challenge_list.Count
    setactive(self.ui.mTrans_Star, haveStar)
    if self.isUnlock then
      if stageRecord then
        if self.storyData.type == GlobalConfig.StoryType.StoryBattle then
          setactive(self.ui.mTrans_Complete, true)
        elseif self.storyData.type == GlobalConfig.StoryType.Story then
          setactive(self.ui.mTrans_Complete, true)
        else
          setactive(self.ui.mTrans_Complete, stageRecord.ChallengeNum >= UIChapterGlobal.MaxChallengeNum)
        end
      else
        setactive(self.ui.mTrans_Complete, false)
      end
    else
      setactive(self.ui.mTrans_Complete, false)
    end
    self:UpdateChallenge(stageRecord)
  end
  if self.difficultyTimer then
    self.difficultyTimer:Stop()
  end
  self.difficultyTimer = TimerSys:DelayFrameCall(1, function()
    self.ui.mAnimator:SetInteger("Mode", self.chapterData.difficulty_type - 1)
  end)
  if self.lockTimer then
    self.lockTimer:Stop()
  end
  self.lockTimer = TimerSys:DelayFrameCall(1, function()
    self.ui.mAnimator:SetBool("Locked", self.isUnlock)
  end)
end

function UIActivityCafeBtnItem:UpdateChallenge(cmdData)
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

function UIActivityCafeBtnItem:UpdateBg(index)
  setactive(self.ui.mTrans_Main.gameObject, index == 1)
end

function UIActivityCafeBtnItem:SetNextLine(isShow)
  setactive(self.ui.mTrans_AboveNextLine.gameObject, isShow)
end

function UIActivityCafeBtnItem:SetSelected(isSelect)
  self.ui.mBtn_Stage.interactable = not isSelect
  if isSelect then
    setactive(self.ui.mTrans_NowProgress, false)
  else
    setactive(self.ui.mTrans_NowProgress, self.isNext and self.isUnlock and self.storyData.type ~= GlobalConfig.StoryType.Branch)
  end
end

function UIActivityCafeBtnItem:OnRelease(isDestroy)
  if self.difficultyTimer then
    self.difficultyTimer:Stop()
    self.difficultyTimer = nil
  end
  if self.lockTimer then
    self.lockTimer:Stop()
    self.lockTimer = nil
  end
end

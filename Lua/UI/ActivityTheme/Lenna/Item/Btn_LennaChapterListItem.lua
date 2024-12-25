require("UI.UIBaseCtrl")
require("UI.ChapterPanel.UIChapterGlobal")
Btn_LennaChapterListItem = class("Btn_LennaChapterListItem", UIBaseCtrl)
Btn_LennaChapterListItem.__index = Btn_LennaChapterListItem

function Btn_LennaChapterListItem:ctor()
end

function Btn_LennaChapterListItem:InitCtrl(parent)
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
end

function Btn_LennaChapterListItem:SetData(chapterData, data)
  self.chapterData = chapterData
  self.storyData = data
  self:UpdateStage()
end

function Btn_LennaChapterListItem:UpdateItem()
  self:UpdateStage()
  self:UpdateBg(self.index)
end

function Btn_LennaChapterListItem:UpdateStage()
  self.ui.mTrans_Self.sizeDelta = Vector2.zero
  self.ui.mText_Title.text = "/"
  self.ui.mText_StageName.text = self.storyData.name.str
  self.ui.mText_ChapterName.text = self.chapterData.name.str
  local stageData = TableData.GetStageData(self.storyData.stage_id)
  local stageRecord = NetCmdDungeonData:GetCmdStoryData(self.storyData.id)
  self.isNext = stageRecord == nil and true or stageRecord.first_pass_time <= 0
  setactivewithcheck(self.ui.mTrans_Sound, self.storyData.type == GlobalConfig.StoryType.Story)
  if stageData ~= nil then
    setactivewithcheck(self.ui.mTrans_RewardIcon, 0 < stageData.reward_show and self.isNext)
    if 0 < stageData.reward_show then
      local rewardBubbleItem = UIRewardBubbleItem.New()
      rewardBubbleItem:InitObj(self.ui.mObj_RewardIcon)
      rewardBubbleItem:SetData(stageData.reward_show)
    end
    self.isUnlock = NetCmdThemeData:LevelIsUnLock(self.storyData.id)
    setactivewithcheck(self.ui.mTrans_NowProgress, self.isNext and self.isUnlock and self.storyData.type ~= GlobalConfig.StoryType.Branch)
    local haveStar = self.storyData.type ~= GlobalConfig.StoryType.StoryBattle and 0 < stageData.challenge_list.Count
    setactivewithcheck(self.ui.mTrans_Star, haveStar)
    setactivewithcheck(self.ui.mTrans_NoneStar, not haveStar and self.storyData.type ~= GlobalConfig.StoryType.Story)
    if self.isUnlock then
      if stageRecord then
        if self.storyData.type == GlobalConfig.StoryType.StoryBattle then
          setactivewithcheck(self.ui.mTrans_Complete, true)
        elseif self.storyData.type == GlobalConfig.StoryType.Story then
          setactivewithcheck(self.ui.mTrans_Complete, true)
        else
          setactivewithcheck(self.ui.mTrans_Complete, stageRecord.ChallengeNum >= UIChapterGlobal.MaxChallengeNum)
        end
      else
        setactivewithcheck(self.ui.mTrans_Complete, false)
      end
      setactivewithcheck(self.ui.mTrans_StoryUnlock, false)
    else
      setactivewithcheck(self.ui.mTrans_Complete, false)
      setactivewithcheck(self.ui.mTrans_StoryUnlock, true)
      self.ui.mImg_AboveNextLine.color = ColorUtils.StringToColor("494949")
    end
    self:UpdateChallenge(stageRecord)
  end
end

function Btn_LennaChapterListItem:UpdateChallenge(cmdData)
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

function Btn_LennaChapterListItem:UpdateBg(index)
  self.index = index
  TimerSys:DelayFrameCall(1, function()
    local hard = self.chapterData.difficulty_type > 1
    if self.index == 1 then
      if hard then
        self.ui.mAnim:SetInteger("BgColor", 2)
      else
        self.ui.mAnim:SetInteger("BgColor", 0)
      end
    elseif index == 2 then
      if hard then
        self.ui.mAnim:SetInteger("BgColor", 3)
      else
        self.ui.mAnim:SetInteger("BgColor", 1)
      end
    end
  end)
end

function Btn_LennaChapterListItem:SetNextLine(isShow)
  setactive(self.ui.mTrans_AboveNextLine.gameObject, isShow)
end

function Btn_LennaChapterListItem:SetSelected(isSelect)
  self.ui.mBtn_Stage.interactable = not isSelect
  if isSelect then
    setactive(self.ui.mTrans_NowProgress, false)
    setactivewithcheck(self.ui.mTrans_Sel, true)
  else
    setactive(self.ui.mTrans_NowProgress, self.isNext and self.isUnlock and self.storyData.type ~= GlobalConfig.StoryType.Branch)
    setactivewithcheck(self.ui.mTrans_Sel, false)
  end
end

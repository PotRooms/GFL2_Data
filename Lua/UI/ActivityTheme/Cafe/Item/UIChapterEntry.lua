UIChapterEntry = class("UIChapterEntry", UIBaseCtrl)

function UIChapterEntry:ctor(root)
  self.ui = UIUtils.GetUIBindTable(root)
  self:SetRoot(root.transform)
  self:SetVisible(true)
  UIUtils.AddBtnClickListener(self.ui.mBtn_ChapterEntry.gameObject, function()
    self:onClickSelf()
  end)
end

function UIChapterEntry:OnRelease()
  if self.timerForLocked then
    self.timerForLocked:Stop()
    self.timerForLocked = nil
  end
  self.activityModuleData = nil
  self.onClickCallback = nil
  self.btnStateList = nil
  self.chapterId = nil
  self.ui = nil
  self.super.OnRelease(self)
end

function UIChapterEntry:SetData(activityModuleData, activityState, activityConfigId, activityId, chapterData)
  self.activityModuleData = activityModuleData
  self.activityState = activityState
  self.activityConfigId = activityConfigId
  self.activityId = activityId
  self.btnStateList = {}
  for k, v in pairs(self.activityModuleData.entrance_type) do
    self.btnStateList[k] = v
  end
  self.chapterData = chapterData
  self:RefreshIsPlanOpen()
end

function UIChapterEntry:Refresh()
  if not self.activityModuleData then
    self:SetVisible(false)
    return
  end
  local chapterData = self.chapterData
  if not chapterData then
    self:SetVisible(false)
    return
  end
  local str = CS.LuaUIUtils.CheckUnlockPopupStrByRepeatedList(chapterData.unlock)
  if self.timerForLocked then
    self.timerForLocked:Stop()
  end
  self.timerForLocked = TimerSys:DelayFrameCall(1, function()
    if string.len(str) > 0 then
      self.ui.mAnimator:SetBool("Locked", true)
      return
    end
    if self.isPlanOpen ~= 0 then
      self.ui.mAnimator:SetBool("Locked", true)
      return
    end
    self.ui.mAnimator:SetBool("Locked", false)
  end)
  if self.btnStateList[2001] == 1 then
    self:SetVisible(true)
    self.ui.mBtn_ChapterEntry.interactable = true
  elseif self.btnStateList[2001] == 2 then
    self:SetVisible(true)
    self.ui.mBtn_ChapterEntry.interactable = true
  elseif self.btnStateList[2001] == 3 then
    self:SetVisible(true)
    self.ui.mBtn_ChapterEntry.interactable = false
  elseif self.btnStateList[2001] == 4 then
    self:SetVisible(false)
  end
  setactive(self.ui.mTrans_State.gameObject, self.isPlanOpen == 1)
  local submoduleType = SubmoduleType.ActivityStory
  self.ui.mText_Hard.text = TableData.GetActivityHint(22001002, self.activityConfigId, 2, LuaUtils.EnumToInt(submoduleType), self.activityId)
  self.ui.mText_Normal.text = TableData.GetActivityHint(22001001, self.activityConfigId, 2, LuaUtils.EnumToInt(submoduleType), self.activityId)
  self.ui.mText_ActivityState.text = TableData.GetHintById(260007)
  local selectDiff = chapterData.difficulty_type
  setactive(self.ui.mTrans_NormalMode.gameObject, selectDiff == 1)
  setactive(self.ui.mTrans_HardMode.gameObject, 1 < selectDiff)
  if chapterData then
    self.ui.mText_ChapterName.text = chapterData.name.str
    self.ui.mText_Chapter.text = chapterData.tab_name.str
    if self.activityModuleData.stage_type == 2 then
      if chapterData.chapter_reward_value.Count > 0 then
        local stars = NetCmdDungeonData:GetCurStarsByChapterID(chapterData.id)
        local totalCount = chapterData.chapter_reward_value[chapterData.chapter_reward_value.Count - 1]
        if stars == 0 or totalCount == 0 then
          self.ui.mText_Percent.text = "0%"
        else
          self.ui.mText_Percent.text = math.ceil(stars / totalCount * 100) .. "%"
        end
        if self.btnStateList[2001] == 2 or self.btnStateList[2001] == 3 then
          setactive(self.ui.mObj_ChapterRedPoint.gameObject, false)
        else
          local hasRed = false
          local diffData = TableData.listChapterByDifficultyGroupDatas:GetDataById(chapterData.difficulty_group)
          if diffData then
            for i = 0, diffData.Id.Count - 1 do
              if 0 < NetCmdDungeonData:UpdateChatperRewardRedPoint(diffData.Id[i]) then
                hasRed = true
                break
              end
            end
          end
          setactive(self.ui.mObj_ChapterRedPoint.gameObject, hasRed)
        end
      else
        local chapterInfo = TableData.GetStorysByChapterID(chapterData.id)
        local compCount = NetCmdDungeonData:GetChapterPassedCount(chapterData.id)
        if chapterInfo then
          self.ui.mText_Percent.text = math.ceil(compCount / chapterInfo.Count * 100) .. "%"
        else
          self.ui.mText_Percent.text = "0%"
        end
        setactive(self.ui.mObj_ChapterRedPoint.gameObject, false)
      end
    else
      self.ui.mText_Percent.text = TableData.GetHintById(192046)
      setactive(self.ui.mObj_ChapterRedPoint.gameObject, false)
    end
  else
    self.ui.mText_Percent.text = TableData.GetHintById(192046)
    self.ui.mText_Chapter.text = "None"
    setactive(self.ui.mObj_ChapterRedPoint.gameObject, false)
  end
  if self.btnStateList[2001] == 2 or self.btnStateList[2001] == 3 then
    self.ui.mText_Percent.text = TableData.GetHintById(192046)
  end
end

function UIChapterEntry:AddBtnClickListener(callback)
  self.onClickCallback = callback
end

function UIChapterEntry:SetInteractable(interactable)
  self.ui.mBtn_ChapterEntry.interactable = interactable
end

function UIChapterEntry:IsInteractable()
  return self.ui.mBtn_ChapterEntry.interactable
end

function UIChapterEntry:SetVisible(visible)
  setactive(self:GetRoot(), visible)
end

function UIChapterEntry:RefreshIsPlanOpen()
  local timeStr = ""
  if self.chapterData == nil then
    return
  end
  self.isPlanOpen, timeStr = NetCmdActivitySimData:IsPlanOpen(self.chapterData.PlanId, timeStr)
end

function UIChapterEntry:onClickSelf()
  local timeStr = ""
  if self.chapterData == nil then
    return
  end
  self.isPlanOpen, timeStr = NetCmdActivitySimData:IsPlanOpen(self.chapterData.PlanId, timeStr)
  if self.isPlanOpen == -1 then
    timeStr = string_format(TableData.GetActivityHint(271122, self.activityConfigId, 1, self.activityModuleData.type), timeStr)
    CS.PopupMessageManager.PopupString(timeStr)
    return
  end
  local chapterData = self.chapterData
  local str = CS.LuaUIUtils.CheckUnlockPopupStrByRepeatedList(chapterData.unlock)
  if string.len(str) > 0 then
    CS.PopupMessageManager.PopupString(str)
    return
  end
  if self.btnStateList[2001] == 2 then
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
    return
  end
  if self.isPlanOpen == 1 then
    local content = TableData.GetHintById(260007)
    PopupMessageManager.PopupString(content)
    return
  end
  if self.onClickCallback then
    self.onClickCallback()
  end
end

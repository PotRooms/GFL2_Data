UIChallengeEntry = class("UIChallengeEntry", UIBaseCtrl)

function UIChallengeEntry:ctor(root)
  self.ui = UIUtils.GetUIBindTable(root)
  self:SetRoot(root.transform)
  self:SetVisible(true)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Self.gameObject, function()
    self:onClickSelf()
  end)
end

function UIChallengeEntry:OnRelease()
  if self.timerForLocked then
    self.timerForLocked:Stop()
    self.timerForLocked = nil
  end
  self.activityModuleData = nil
  self.activityConfigId = nil
  self.onClickCallback = nil
  self.btnStateList = nil
  self.chapterId = nil
  self.ui = nil
  self.super.OnRelease(self)
end

function UIChallengeEntry:SetData(activityModuleData, activityState, activityConfigId, activityId, chapterId)
  self.activityModuleData = activityModuleData
  self.activityState = activityState
  self.activityConfigId = activityConfigId
  self.activityId = activityId
  self.btnStateList = {}
  for k, v in pairs(self.activityModuleData.entrance_type) do
    self.btnStateList[k] = v
  end
  self.chapterId = chapterId
  self:RefreshIsPlanOpen()
end

function UIChallengeEntry:Refresh()
  if not self.activityModuleData then
    self:SetVisible(false)
    return
  end
  local chapterId = self.chapterId
  if not chapterId then
    self:SetVisible(false)
    return
  end
  local chapterData = TableData.listChapterDatas:GetDataById(chapterId)
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
  if self.btnStateList[2002] == 1 then
    self:SetVisible(true)
    self.ui.mBtn_Self.interactable = true
  elseif self.btnStateList[2002] == 2 then
    self:SetVisible(true)
    self.ui.mBtn_Self.interactable = true
  elseif self.btnStateList[2002] == 3 then
    self:SetVisible(true)
    self.ui.mBtn_Self.interactable = false
  elseif self.btnStateList[2002] == 4 then
    self:SetVisible(false)
  end
  local submoduleType = SubmoduleType.ActivityStoryChallenge
  if self.isPlanOpen == -1 then
    self.ui.mText_Mode.text = "\230\156\170\229\188\128\229\144\175"
  elseif self.isPlanOpen == 0 then
    self.ui.mText_Mode.text = TableData.GetActivityHint(22002001, self.activityConfigId, 2, LuaUtils.EnumToInt(submoduleType), self.activityId)
  elseif self.isPlanOpen == 1 then
    self.ui.mText_Mode.text = TableData.GetActivityHint(271188, self.activityConfigId, 2, LuaUtils.EnumToInt(submoduleType), self.activityId)
  end
  if chapterData then
    self.ui.mText_Chapter.text = chapterData.tab_name.str
    if self.activityModuleData.stage_type == 2 then
      if 0 < chapterData.chapter_reward_value.Count then
        local stars = NetCmdDungeonData:GetChapterPassedCount(chapterData.id)
        local totalCount = chapterData.chapter_reward_value[chapterData.chapter_reward_value.Count - 1]
        if stars == 0 or totalCount == 0 then
          self.ui.mText_Percent.text = "0%"
        else
          self.ui.mText_Percent.text = math.ceil(stars / totalCount * 100) .. "%"
        end
        if self.btnStateList[2002] == 2 or self.btnStateList[2002] == 3 then
          setactive(self.ui.mTrans_RendPoint.gameObject, false)
        else
          setactive(self.ui.mTrans_RendPoint.gameObject, false)
        end
      else
        local chapterInfo = TableData.GetStorysByChapterID(chapterData.id)
        local compCount = NetCmdDungeonData:GetChapterPassedCount(chapterData.id)
        if chapterInfo then
          self.ui.mText_Percent.text = math.ceil(compCount / chapterInfo.Count * 100) .. "%"
        else
          self.ui.mText_Percent.text = "0%"
        end
        setactive(self.ui.mTrans_RendPoint.gameObject, false)
      end
    else
      self.ui.mText_Percent.text = TableData.GetHintById(192046)
      setactive(self.ui.mTrans_RendPoint.gameObject, false)
    end
  else
    self.ui.mText_Percent.text = TableData.GetHintById(192046)
    self.ui.mText_Chapter.text = "None"
    setactive(self.ui.mTrans_RendPoint.gameObject, false)
  end
  if self.btnStateList[2002] == 2 or self.btnStateList[2002] == 3 then
    self.ui.mText_Percent.text = TableData.GetHintById(192046)
  end
end

function UIChallengeEntry:AddBtnClickListener(callback)
  self.onClickCallback = callback
end

function UIChallengeEntry:SetInteractable(interactable)
  self.ui.mBtn_ChapterEntry.interactable = interactable
end

function UIChallengeEntry:IsInteractable()
  return self.ui.mBtn_ChapterEntry.interactable
end

function UIChallengeEntry:SetVisible(visible)
  setactive(self:GetRoot(), visible)
end

function UIChallengeEntry:RefreshIsPlanOpen()
  local timeStr = ""
  if self.chapterId == nil then
    return
  end
  local chapterData = TableData.listChapterDatas:GetDataById(self.chapterId)
  if chapterData == nil then
    return
  end
  self.isPlanOpen, timeStr = NetCmdActivitySimData:IsPlanOpen(chapterData.PlanId, timeStr)
end

function UIChallengeEntry:onClickSelf()
  if self.chapterId == nil then
    return
  end
  local chapterData = TableData.listChapterDatas:GetDataById(self.chapterId)
  if chapterData == nil then
    return
  end
  local timeStr = ""
  self.isPlanOpen, timeStr = NetCmdActivitySimData:IsPlanOpen(chapterData.PlanId, timeStr)
  if self.isPlanOpen == -1 then
    timeStr = string_format(TableData.GetActivityHint(271122, self.activityConfigId, 1, self.activityModuleData.type), timeStr)
    CS.PopupMessageManager.PopupString(timeStr)
    return
  end
  local str = CS.LuaUIUtils.CheckUnlockPopupStrByRepeatedList(chapterData.unlock)
  if string.len(str) > 0 then
    CS.PopupMessageManager.PopupString(str)
    return
  end
  if self.btnStateList[2002] == 2 then
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

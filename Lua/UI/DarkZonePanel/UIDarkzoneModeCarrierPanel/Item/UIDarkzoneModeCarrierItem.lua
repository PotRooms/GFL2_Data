require("UI.DarkZonePanel.UIDarkZoneModePanel.DarkZoneGlobal")
UIDarkzoneModeCarrierItem = class("UIDarkzoneModeCarrierItem", UIBaseCtrl)
UIDarkzoneModeCarrierItem.__index = UIDarkzoneModeCarrierItem

function UIDarkzoneModeCarrierItem:ctor()
end

function UIDarkzoneModeCarrierItem:InitCtrl(prefab, parent)
  local obj = instantiate(prefab, parent)
  self:SetRoot(obj.transform)
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
  self.index = 0
  self.callBack = nil
  self.mData = nil
  self.ui.mAni_QuestItem.keepAnimatorControllerStateOnDisable = true
  self.ui.mCanvasGroup_Ongoing.alpha = 0
  self.ui.mCanvasGroup_GrpLayout.alpha = 0
  self.ui.mCanvasGroup_GrpType.alpha = 0
  self.ui.mCanvasGroup_Locked.alpha = 0
  self.ui.mCanvasGroup_RedPoint.alpha = 0
  self.ShowFlag = true
  UIUtils.GetButtonListener(self.ui.mBtn_Room.gameObject).onClick = function()
    if self.state == DarkZoneGlobal.ActivityQuestState.UnLocked or self.state == DarkZoneGlobal.ActivityQuestState.Finished then
      local t = {}
      t[0] = 4
      t[1] = self.mData.QuestId
      if not pcall(function()
        NetCmdActivityDarkZone.cachePhaseID = self.phaseID
      end) then
        gfwarning("UIDarkzoneModeCarrierItem\228\189\141\231\189\174\231\188\147\229\173\152\229\135\186\231\142\176\229\188\130\229\184\184")
      end
      UIManager.OpenUIByParam(UIDef.UIDarkZoneQuestPanel, t)
    elseif self.state == DarkZoneGlobal.ActivityQuestState.Locked then
      local reason = ""
      local level = self.mData.quest_unlock
      local userLevel = NetCmdActivityDarkZone:GetActivityUnlockLevel()
      if level > userLevel then
        local simGrade = TableData.listSimGradeDatas:GetDataById(level)
        if simGrade ~= nil then
          reason = string_format(TableData.GetHintById(271028), simGrade.grade_name.str)
        end
      end
      local reason2 = ""
      if not NetCmdActivityDarkZone:CheckFrontQuestFinish(self.mData.quest_id) then
        reason2 = string_format(TableData.GetHintById(271029), TableData.listDzActivityQuestDatas:GetDataById(self.mData.FrontQuest).quest_name.str)
      end
      if reason ~= "" and reason2 ~= "" then
        local simGrade = TableData.listSimGradeDatas:GetDataById(level)
        local reasonCon = ""
        if simGrade ~= nil then
          reasonCon = string_format(TableData.GetHintById(271035), simGrade.grade_name.str) .. TableData.GetHintById(103157) .. reason2
        end
        PopupMessageManager.PopupString(reasonCon)
      elseif reason ~= "" then
        PopupMessageManager.PopupString(reason)
      elseif reason2 ~= "" then
        PopupMessageManager.PopupString(reason2)
      end
    end
    self:OnClickFunc()
  end
end

function UIDarkzoneModeCarrierItem:SetData(activeQuestID, phaseID, animateState, activityConfigId, onclickback)
  local data = TableData.listDzActivityQuestDatas:GetDataById(activeQuestID)
  self.mData = data
  self.phaseID = phaseID
  self.activityConfigId = activityConfigId
  self.info = NetCmdActivityDarkZone:GetDarkZoneStageInfo(activeQuestID)
  self.isUnlock = NetCmdActivityDarkZone:IsQuestUnlock(activeQuestID, activityConfigId)
  self.OnClickFunc = onclickback
  local score = 0
  if self.info == nil then
    self.state = DarkZoneGlobal.ActivityQuestState.Locked
    if self.isUnlock then
      self.state = DarkZoneGlobal.ActivityQuestState.UnLocked
    end
  else
    self.state = self.info.State
    score = self.info.Score
  end
  if self.timer then
    self.timer:Stop()
  end
  self.timer = TimerSys:DelayFrameCall(1, function(State)
    self.ui.mAni_QuestItem:SetInteger("Difficulty", State)
    self.ui.mAni_QuestItem:SetBool("Locked", self.state ~= DarkZoneGlobal.ActivityQuestState.Locked)
  end, animateState)
  self.ui.mText_QuestName.text = self.mData.quest_name.str
  self.ui.mImg_icon.sprite = IconUtils.GetAtlasSprite(data.quest_pic2)
  self.raid = NetCmdActivityDarkZone:GetRaidLevel(data)
  self.ui.mText_Score.text = string_format(TableData.GetHintById(271304), self.raid.EvaluateLevel.str)
  if self.raid.point.Count == 1 then
    self.ui.mText_Score.color = ColorUtils.OrangeColor
  elseif self.raid.point.Count == 2 then
    self.ui.mText_Score.color = ColorUtils.GrayColor
  end
  setactive(self.ui.mTrans_Type, self.info == nil)
  setactive(self.ui.mText_Score, self.state ~= DarkZoneGlobal.ActivityQuestState.Locked and self.info ~= nil)
  setactive(self.ui.mTrans_Finished, self.info ~= nil)
end

function UIDarkzoneModeCarrierItem:CloseSelf()
  setactive(self.ui.mUIRoot, false)
end

function UIDarkzoneModeCarrierItem:SetShowFlag(flag)
  if flag ~= nil then
    self.ShowFlag = flag
  end
end

function UIDarkzoneModeCarrierItem:OpenSelf()
  if not self.ShowFlag then
    return
  end
  setactive(self.ui.mUIRoot, true)
end

function UIDarkzoneModeCarrierItem:OnRelease()
  if self.timer then
    self.timer:Stop()
    self.timer = nil
  end
  gfdestroy(self:GetRoot())
end

function UIDarkzoneModeCarrierItem:UpdateAnimationState(State)
  local aniState = self.ui.mAni_QuestItem:GetInteger("Difficulty")
  local aniFinish = true
  if aniState ~= State then
    self.ui.mAni_QuestItem:SetInteger("Difficulty", State)
    aniFinish = aniFinish and false
  else
    aniFinish = aniFinish and true
  end
  local aniUnLock = self.ui.mAni_QuestItem:GetBool("Locked")
  local unlock = self.state ~= DarkZoneGlobal.ActivityQuestState.Locked
  if aniUnLock ~= unlock then
    self.ui.mAni_QuestItem:SetBool("Locked", unlock)
    aniFinish = aniFinish and false
  else
    aniFinish = aniFinish and true
  end
  return aniFinish
end

function UIDarkzoneModeCarrierItem:PlayFadeIn()
  self.ui.mAni_QuestItem:ResetTrigger("FadeIn")
  self.ui.mAni_QuestItem:SetTrigger("FadeIn")
end

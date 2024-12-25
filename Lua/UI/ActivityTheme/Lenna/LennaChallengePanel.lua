require("UI.UIBasePanel")
require("UI.ActivityTheme.Lenna.Item.LennaChallengeItem")
LennaChallengePanel = class("LennaChallengePanel", UIBasePanel)

function LennaChallengePanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function LennaChallengePanel:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = UIUtils.GetUIBindTable(root)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnBack.gameObject, function()
    self:OnClickClose()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnHome.gameObject, function()
    self:OnClickHome()
  end)
  
  function self.ui.mSuperGridScrollerController_GrpList.itemRenderer(index, loopGridViewItem)
    self:OnItemRenderer(index, loopGridViewItem)
  end
  
  function self.ui.mSuperGridScrollerController_GrpList.itemCreated(loopGridViewItem)
    self:OnItemCreated(loopGridViewItem)
  end
  
  UIUtils.GetButtonListener(self.ui.mBtn_DetailsList).onClick = function()
    local challengePlan = TableData.listPlanDatas:GetDataById(self.chapterData.plan_id)
    local now = CGameTime:GetTimestamp()
    local open = challengePlan and now >= challengePlan.open_time and now < challengePlan.close_time
    if not open then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
      UIManager.CloseUI(self.mCSPanel)
      return
    end
    self.selectedIndex = -1
    self.ui.mSuperGridScrollerController_GrpList:Refresh()
    MessageSys:SendMessage(UIEvent.StoryCloseDetail, nil)
    setactive(self.ui.mBtn_CloseNew, false)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_CloseNew).onClick = function()
    local challengePlan = TableData.listPlanDatas:GetDataById(self.chapterData.plan_id)
    local now = CGameTime:GetTimestamp()
    local open = challengePlan and now >= challengePlan.open_time and now < challengePlan.close_time
    if not open then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
      UIManager.CloseUI(self.mCSPanel)
      return
    end
    self.selectedIndex = -1
    self.ui.mSuperGridScrollerController_GrpList:Refresh()
    MessageSys:SendMessage(UIEvent.StoryCloseDetail, nil)
    setactive(self.ui.mBtn_CloseNew, false)
  end
end

function LennaChallengePanel:OnInit(root, data)
  self.chapterData = data.ChapterData
  self.planId = data.PlanId
  self.activityConfigId = data.ActivityConfigId
  self.selectedIndex = -1
  local submoduleType = SubmoduleType.ActivityStoryChallenge
  local stateType = NetCmdActivityDarkZone:GetCurrActivityState(self.activityConfigId)
  local submoduleValue = NetCmdActivityDarkZone:GetCurrActivityID(submoduleType, self.activityConfigId, stateType)
  local textType = 2
  CS.UIUtils.GetAndSetActivityHintText(self.mUIRoot, self.activityConfigId, textType, LuaUtils.EnumToInt(submoduleType), submoduleValue)
  
  function self.ShowCloseNew()
    setactive(self.ui.mBtn_CloseNew.gameObject, true)
  end
  
  setactive(self.ui.mBtn_CloseNew.gameObject, false)
  MessageSys:AddListener(UIEvent.StoryShowDetail, self.ShowCloseNew)
  self:OverTimer()
end

function LennaChallengePanel:OverTimer()
  local challengePlan = TableData.listPlanDatas:GetDataById(self.chapterData.plan_id)
  local now = CGameTime:GetTimestamp()
  local open = challengePlan and now >= challengePlan.open_time and now < challengePlan.close_time
  if open then
    return
  end
  if self.overTimer ~= nil then
    self.overTimer:Stop()
    self.overTimer = nil
  end
  self.overTimer = TimerSys:UnscaledDelayCall(challengePlan.close_time - now, function()
    MessageSys:SendMessage(UIEvent.StoryCloseDetail, nil)
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
    self:OnClickClose()
  end)
end

function LennaChallengePanel:OnShowStart()
  self:Refresh()
end

function LennaChallengePanel:OnTop()
end

function LennaChallengePanel:OnRecover()
  self:Refresh()
end

function LennaChallengePanel:Refresh()
  self.themeaticData = TableDataBase.listPlanDatas:GetDataById(self.planId)
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
  else
    self.ui.mText_ActivityName.text = ""
  end
  self.ui.mText_ChapterName.text = self.chapterData.tab_name.str
  setactivewithcheck(self.ui.mText_ChapterName, true)
  self.nowStoryData = NetCmdDungeonData:GetCurrentStoryByChapterID(self.chapterData.id)
  self.storyDataList = TableData.GetStorysByChapterID(self.chapterData.id, false)
  if self.storyDataList then
    self.ui.mSuperGridScrollerController_GrpList.numItems = self.storyDataList.Count
    self.ui.mSuperGridScrollerController_GrpList:Refresh()
  end
end

function LennaChallengePanel:OnHide()
  if self.fillAmountTween ~= nil then
    CS.UITweenManager.TweenKill(self.fillAmountTween)
    self.fillAmountTween = nil
  end
  if self.defaultTween ~= nil then
    CS.UITweenManager.TweenKill(self.defaultTween)
    self.defaultTween = nil
  end
  self.ui.mSuperGridScrollerController_GrpList:SetScrollRectEnabled(true)
end

function LennaChallengePanel:OnClose()
  if self.overTimer ~= nil then
    self.overTimer:Stop()
    self.overTimer = nil
  end
  self.selectedIndex = -1
  self.storyDataList = nil
  MessageSys:RemoveListener(UIEvent.StoryShowDetail, self.ShowCloseNew)
end

function LennaChallengePanel:OnRelease()
  self.ui = nil
end

function LennaChallengePanel:OnClickClose()
  UIManager.CloseUI(self.mCSPanel)
end

function LennaChallengePanel:OnClickHome()
  UISystem:JumpToMainPanel()
end

function LennaChallengePanel:OnItemCreated(loopGridViewItem)
  local item = LennaChallengeItem.New(loopGridViewItem.transform)
  item:AddBtnClickListener(function(tempItem)
    self:OnClickItem(tempItem)
  end)
  loopGridViewItem.data = item
end

function LennaChallengePanel:OnItemRenderer(index, loopGridViewItem)
  local storyData = self.storyDataList[index]
  local item = loopGridViewItem.data
  item:SetData(storyData, self.planId, index)
  item:Refresh()
  if self.nowStoryData then
    local isNowProgress = item:GetStoryData().id == self.nowStoryData.id and index ~= self.selectedIndex
    item:IsNowProgress(isNowProgress)
  end
  item:SetSelect(index == self.selectedIndex)
end

function LennaChallengePanel:OnClickItem(item)
  local challengePlan = TableData.listPlanDatas:GetDataById(self.chapterData.plan_id)
  local now = CGameTime:GetTimestamp()
  local open = challengePlan and now >= challengePlan.open_time and now < challengePlan.close_time
  if not open then
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
    UIManager.CloseUI(self.mCSPanel)
    return
  end
  if not item then
    return
  end
  self.selectedIndex = item:GetIndex()
  self.ui.mSuperGridScrollerController_GrpList:Refresh()
  local storyData = item:GetStoryData()
  local stageData = TableData.GetStageData(storyData.stage_id)
  local stageRecord = NetCmdStageRecordData:GetStageRecordById(stageData.id)
  UIBattleDetailDialog.OpenByChapterData(LuaUtils.EnumToInt(enumUIPanel.UIStoryChapterPanel), stageData, stageRecord, storyData, NetCmdDungeonData:IsUnLockStory(storyData.id), function()
    self:ScrollToNormalPos()
  end, true)
  self:ScrollToMiddlePos(item.mUIRoot.transform.localPosition)
end

function LennaChallengePanel:ScrollToMiddlePos(itemPos)
  local content = self.ui.mSuperGridScrollerController_GrpList.Content
  local newToPos = itemPos.x + content.anchoredPosition.x
  local screenWidth = UISystem.UICanvas.transform.sizeDelta.x
  local toX = screenWidth * 0.4 - newToPos - screenWidth * content.pivot.x
  local toPos = Vector3(toX, content.localPosition.y, 0)
  local deltaPos = content.localPosition + toPos
  if self.fillAmountTween ~= nil then
    CS.UITweenManager.TweenKill(self.fillAmountTween)
    self.fillAmountTween = nil
  end
  self.ui.mSuperGridScrollerController_GrpList:SetScrollRectEnabled(false)
  self.fillAmountTween = CS.UITweenManager.PlayLocalPositionTween(content, content.localPosition, deltaPos, 0.35)
end

function LennaChallengePanel:ScrollToNormalPos()
  self.ui.mSuperGridScrollerController_GrpList:SetScrollRectEnabled(true)
end

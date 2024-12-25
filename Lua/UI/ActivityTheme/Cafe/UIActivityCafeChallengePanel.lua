require("UI.UIBasePanel")
require("UI.ActivityTheme.Cafe.Item.UIActivityCafeChallengeItem")
UIActivityCafeChallengePanel = class("UIActivityCafeChallengePanel", UIBasePanel)

function UIActivityCafeChallengePanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function UIActivityCafeChallengePanel:OnAwake(root, data)
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
  
  UIUtils.GetButtonListener(self.ui.mBtn_DetailsList.gameObject).onClick = function()
    local prevSelectedIndex = self.selectedIndex
    self.selectedIndex = -1
    self.ui.mSuperGridScrollerController_GrpList:Refresh(prevSelectedIndex)
    MessageSys:SendMessage(UIEvent.StoryCloseDetail, nil)
    setactive(self.ui.mBtn_CloseNew.gameObject, false)
  end
end

function UIActivityCafeChallengePanel:OnInit(root, data)
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
  UIUtils.GetButtonListener(self.ui.mBtn_CloseNew.gameObject).onClick = function()
    MessageSys:SendMessage(UIEvent.StoryCloseDetail, nil)
    setactive(self.ui.mBtn_CloseNew.gameObject, false)
  end
  MessageSys:AddListener(UIEvent.StoryShowDetail, self.ShowCloseNew)
end

function UIActivityCafeChallengePanel:OnShowStart()
  self:Refresh()
  local simHelper = CS.Activities.ActivitySim.ActivitySimHelper.Instance
  if simHelper == nil then
    return
  end
  simHelper:SetEnabled(false)
end

function UIActivityCafeChallengePanel:OnTop()
end

function UIActivityCafeChallengePanel:OnRecover()
  self:Refresh()
end

function UIActivityCafeChallengePanel:Refresh()
  self.ui.mText_ChapterName.text = self.chapterData.tab_name.str
  setactivewithcheck(self.ui.mText_ChapterName, true)
  self.nowStoryData = NetCmdDungeonData:GetCurrentStoryByChapterID(self.chapterData.id)
  self.storyDataList = TableData.GetStorysByChapterID(self.chapterData.id, false)
  if self.storyDataList then
    self.ui.mSuperGridScrollerController_GrpList.numItems = self.storyDataList.Count
    self.ui.mSuperGridScrollerController_GrpList:Refresh()
  end
end

function UIActivityCafeChallengePanel:OnHide()
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

function UIActivityCafeChallengePanel:OnClose()
  self.selectedIndex = -1
  self.storyDataList = nil
  MessageSys:RemoveListener(UIEvent.StoryShowDetail, self.ShowCloseNew)
end

function UIActivityCafeChallengePanel:OnRelease()
  self.ui = nil
end

function UIActivityCafeChallengePanel:OnClickClose()
  UIManager.CloseUI(self.mCSPanel)
end

function UIActivityCafeChallengePanel:OnClickHome()
  UIManager.JumpToMainPanel()
end

function UIActivityCafeChallengePanel:OnItemCreated(loopGridViewItem)
  local item = UIActivityCafeChallengeItem.New(loopGridViewItem.transform)
  item:AddBtnClickListener(function(tempItem)
    self:OnClickItem(tempItem)
  end)
  loopGridViewItem.data = item
end

function UIActivityCafeChallengePanel:OnItemRenderer(index, loopGridViewItem)
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

function UIActivityCafeChallengePanel:OnClickItem(item)
  if not item then
    return
  end
  local storyData = item:GetStoryData()
  local stageData = TableData.GetStageData(storyData.stage_id)
  local stageRecord = NetCmdStageRecordData:GetStageRecordById(stageData.id)
  UIBattleDetailDialog.OpenByChapterData(LuaUtils.EnumToInt(enumUIPanel.UIStoryChapterPanel), stageData, stageRecord, storyData, NetCmdDungeonData:IsUnLockStory(storyData.id), function()
    self:ScrollToNormalPos()
  end, true)
  local prevSelectedIndex = self.selectedIndex
  self.selectedIndex = item:GetIndex()
  self.ui.mSuperGridScrollerController_GrpList:Refresh(prevSelectedIndex)
  self.ui.mSuperGridScrollerController_GrpList:Refresh(self.selectedIndex)
  self:ScrollToMiddlePos(item.mUIRoot.transform.localPosition)
end

function UIActivityCafeChallengePanel:ScrollToMiddlePos(itemPos)
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

function UIActivityCafeChallengePanel:ScrollToNormalPos()
  self.ui.mSuperGridScrollerController_GrpList:SetScrollRectEnabled(true)
  local prevSelectedIndex = self.selectedIndex
  self.selectedIndex = -1
  self.ui.mSuperGridScrollerController_GrpList:Refresh(prevSelectedIndex)
end

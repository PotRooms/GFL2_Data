require("UI.BattleIndexPanel.Content.UIBattleIndexHardSubPanel")
require("UI.BattleIndexPanel.Item.UIBattleIndexModeListItem")
require("UI.BattleIndexPanel.Content.UIBattleIndexSimCombatSubPanel")
require("UI.UIBasePanel")
require("UI.BattleIndexPanel.UIBattleIndexPanelV2View")
require("UI.BattleIndexPanel.Content.UIChapterInfoPanel")
require("UI.BattleIndexPanel.Content.UIBattleIndexStorySubPanel")
require("UI.BattleIndexPanel.Content.UIBattleIndexResourcesSubPanel")
require("UI.ActivityRegressPanel.UIRegressActivityDropupDialog")
require("UI.SimCombatPanel.ResourcesCombat.UISimCombatGlobal")
require("UI.BattleIndexPanel.Item.UIBattleIndexResourcesCard")
require("UI.BattleIndexPanel.Content.UIBattleIndexBranchStorySubPanel")
UIBattleIndexPanelV2 = class("UIBattleIndexPanelV2", UIBasePanel)
UIBattleIndexPanelV2.__index = UIBattleIndexPanelV2
UIBattleIndexPanelV2.tabList = {}
UIBattleIndexPanelV2.mView = nil
UIBattleIndexPanelV2.currentType = -1
UIBattleIndexPanelV2.SUB_PANEL_ID = {
  STORY = 1,
  HARD = 3,
  SIM_COMBAT = 2,
  SIM_RESOURCES = 4,
  BRANCH_STORY = 5
}

function UIBattleIndexPanelV2:OnSave()
  UIBattleIndexGlobal.OnSaveTabId = self.currentType
  self:OnRelease()
end

function UIBattleIndexPanelV2:ctor()
  UIBattleIndexPanelV2.super.ctor(self)
end

function UIBattleIndexPanelV2:Close()
  UIManager.CloseUI(UIDef.UIBattleIndexPanel)
end

function UIBattleIndexPanelV2:OnBackFrom()
  for id, item in pairs(self.tabList) do
    item:SetData(TableData.listStageIndexDatas:GetDataById(id))
  end
  self.mSimCombatSubView:RefreshTabs()
  if self.currentType == self.SUB_PANEL_ID.STORY then
    self.mStorySubView:OnBackFrom()
  end
  if self.mBranchStorySubView then
    self.mBranchStorySubView:OnBackFrom()
  end
  if self.currentType == self.SUB_PANEL_ID.SIM_RESOURCES then
    self.mSimResourcesSubView:OnBackFrom()
  end
  if self.currentType == self.SUB_PANEL_ID.SIM_COMBAT then
    self.mSimCombatSubView:OnBackFrom()
  end
end

function UIBattleIndexPanelV2:OnRecover()
  local targetTabId = UIBattleIndexGlobal.OnSaveTabId
  if targetTabId == nil or targetTabId <= 0 then
    targetTabId = self.currentType
  end
  self:EnableSubPanel(targetTabId)
  self:OnShowStart(true)
  self.mStorySubView:OnRecover()
  if self.currentType == self.SUB_PANEL_ID.SIM_RESOURCES then
    self.mSimResourcesSubView:OnRecover()
  end
end

function UIBattleIndexPanelV2:OnShowStart(isRecover)
  for id, item in pairs(self.tabList) do
    item:SetData(TableData.listStageIndexDatas:GetDataById(id))
  end
  if self.mSimCombatSubView then
    self.mSimCombatSubView:RefreshTabs()
  end
  if isRecover then
    return
  end
  if self.currentType == self.SUB_PANEL_ID.STORY then
    self.mStorySubView:OnShowStart()
  end
  if self.currentType == self.SUB_PANEL_ID.SIM_RESOURCES and self.mSimResourcesSubView then
    self.mSimResourcesSubView:OnShowStart()
  end
end

function UIBattleIndexPanelV2:OnShowFinish()
  if self.currentType == self.SUB_PANEL_ID.STORY then
    self.mStorySubView:OnShowFinish()
  end
end

function UIBattleIndexPanelV2:OnHide()
  if self.currentType == self.SUB_PANEL_ID.STORY then
    self.mStorySubView:OnHide()
  end
end

function UIBattleIndexPanelV2:OnAwake(root)
  self:SetRoot(root)
  self.mView = UIBattleIndexPanelV2View.New()
  self.Ui = {}
  self.mView:InitCtrl(root, self.Ui)
  self.mStorySubView = UIBattleIndexStorySubPanel.New()
  self.mStorySubView:InitCtrl(self.Ui.mTrans_Story, self)
  self.mSimResourcesSubView = UIBattleIndexResourcesSubPanel.New()
  self.mSimResourcesSubView:InitCtrl(self.Ui.mTrans_SimResources)
  self.mSimCombatSubView = UIBattleIndexSimCombatSubPanel.New()
  self.mSimCombatSubView:InitCtrl(self.Ui.mTrans_SimCombat)
end

function UIBattleIndexPanelV2:OnInit(root, data)
  if data then
    if type(data) == "userdata" then
      if data.Length == 2 then
        local chapterID = data[1]
        if 0 < chapterID then
          self.curChapterId = data[1]
        else
          self.curChapterId = NetCmdDungeonData:GetCurrentStoryByType(1).chapter
        end
      end
      self.currentType = data[0]
    else
      if data[1] then
        self.currentType = data[1]
        self.curChapterId = NetCmdDungeonData:GetCurrentStoryByType(1).chapter
      end
      if data.Regress then
        self.currentType = UIBattleIndexPanelV2.SUB_PANEL_ID.SIM_RESOURCES
      end
      self.mData = data
    end
  else
    self.curChapterId = NetCmdDungeonData:GetCurrentStoryByType(1).chapter
    self.mData = data
  end
  UIUtils.GetButtonListener(self.Ui.mBtn_Back.gameObject).onClick = function()
    self:OnClickBack()
  end
  UIUtils.GetButtonListener(self.Ui.mBtn_Home.gameObject).onClick = function()
    self:OnClickHome()
  end
  
  function self.updateChapter()
    self:UpdateRedPoint()
  end
  
  function self.showUnlock()
    self.curChapterId = NetCmdDungeonData:GetCurrentStoryByType(1).chapter
    self.mStorySubView:OnClickTabByChapterId(self.curChapterId, true)
  end
  
  MessageSys:AddListener(UIEvent.UINewChapterItemFinish, self.showUnlock)
  CS.GF2.Message.MessageSys.Instance:AddListener(CS.GF2.Message.UIEvent.RefreshChapterInfo, self.updateChapter)
  if self.curChapterId ~= nil and self.curChapterId == NetCmdDungeonData.NewChapterID then
    self.curChapterId = self.curChapterId - 1
  end
  if self.curChapterId ~= nil and 0 >= self.curChapterId then
    self.curChapterId = 1
  end
  self:InitRecentData()
  self:InitSubPanels()
end

function UIBattleIndexPanelV2:InitRecentData()
  self.isCanInitBranchStory = false
  self.isBranchStoryLock = true
  local lockAchieveCount = 0
  local indexData = TableData.listStageIndexDatas:GetDataById(self.SUB_PANEL_ID.BRANCH_STORY)
  if indexData and 0 < indexData.detail_id.Count then
    for i = 0, indexData.detail_id.Count - 1 do
      local chapterData = TableData.listChapterDatas:GetDataById(indexData.detail_id[i])
      if chapterData then
        local planActivity = TableData.listPlanDatas:GetDataById(chapterData.plan_id, true)
        if planActivity and CGameTime:GetTimestamp() >= planActivity.open_time and CGameTime:GetTimestamp() < planActivity.close_time then
          self.isCanInitBranchStory = true
          self.isBranchStoryLock = false
        end
        for j = 0, chapterData.unlock.Count - 1 do
          if AccountNetCmdHandler:CheckSystemIsUnLock(chapterData.unlock[j]) then
            lockAchieveCount = lockAchieveCount + 1
            break
          end
        end
      end
    end
  end
  self.recentActOpen = 0 < lockAchieveCount
  if self.isCanInitBranchStory and self.recentActOpen and UIBattleIndexPanelV2.mBranchStorySubView == nil then
    UIBattleIndexPanelV2.mBranchStorySubView = UIBattleIndexBranchStorySubPanel
    UIBattleIndexPanelV2.mBranchStorySubView:InitCtrl(self.Ui.mTrans_GrpBranch, self.SUB_PANEL_ID.BRANCH_STORY, self.isBranchStoryLock)
  end
end

function UIBattleIndexPanelV2:InitSubPanels()
  self:InitStorySubPanel()
  if not CS.AuditUtils:IsAudit() then
    self:InitBranchStorySubPanel()
  end
  self:InitHardPanel()
  self:InitSimResourcesPanel()
  self:InitSimCombatPanel()
  if UIBattleIndexPanelV2.currentType > 0 then
    self:EnableSubPanel(UIBattleIndexPanelV2.currentType)
  elseif UIBattleIndexGlobal.CachedTabIndex and 0 < UIBattleIndexGlobal.CachedTabIndex then
    self:EnableSubPanel(UIBattleIndexGlobal.CachedTabIndex)
  else
    self:EnableSubPanel(self.SUB_PANEL_ID.STORY)
  end
end

function UIBattleIndexPanelV2:InitStorySubPanel()
  self:AddSubPanel(self.SUB_PANEL_ID.STORY)
end

function UIBattleIndexPanelV2:InitBranchStorySubPanel()
  self:AddSubPanel(self.SUB_PANEL_ID.BRANCH_STORY)
end

function UIBattleIndexPanelV2:InitHardPanel()
end

function UIBattleIndexPanelV2:InitSimCombatPanel()
  self:AddSubPanel(self.SUB_PANEL_ID.SIM_COMBAT)
end

function UIBattleIndexPanelV2:InitSimResourcesPanel()
  self:AddSubPanel(self.SUB_PANEL_ID.SIM_RESOURCES)
end

function UIBattleIndexPanelV2:AddSubPanel(id)
  local item
  if self.tabList[id] == nil then
    item = UIBattleIndexModeListItem.New()
    item:InitCtrl(self.Ui.mTrans_Content, self.Ui.mScrollChild_Content.childItem)
    self.tabList[id] = item
  else
    item = self.tabList[id]
  end
  item:SetData(TableData.listStageIndexDatas:GetDataById(id))
  UIUtils.GetButtonListener(item.ui.mBtn_Item.gameObject).onClick = function()
    self:EnableSubPanel(id)
  end
end

function UIBattleIndexPanelV2:EnableSubPanel(index)
  if index == self.SUB_PANEL_ID.HARD then
    index = self.SUB_PANEL_ID.STORY
  end
  if index == self.SUB_PANEL_ID.BRANCH_STORY and not self.isCanInitBranchStory then
    PopupMessageManager.PopupString(TableData.GetHintById(210005))
    MessageSys:SendMessage(GuideEvent.OnTabSwitchFail, nil)
    return
  end
  if self.tabList[index].mIsLock and self.tabList[index].mData.unlock > 0 then
    local unlockData = TableData.listUnlockDatas:GetDataById(self.tabList[index].mData.unlock)
    local str = UIUtils.CheckUnlockPopupStr(unlockData)
    PopupMessageManager.PopupString(str)
    MessageSys:SendMessage(GuideEvent.OnTabSwitchFail, nil)
    return
  end
  UIBattleIndexPanelV2.currentType = index
  for i, item in pairs(self.tabList) do
    item.ui.mBtn_Item.interactable = i ~= index
  end
  if index == self.SUB_PANEL_ID.STORY then
    self.Ui.mAnimator_Root:SetInteger("SwitchTab", 0)
  elseif index == self.SUB_PANEL_ID.HARD then
    self.Ui.mAnimator_Root:SetInteger("SwitchTab", 1)
  elseif index == self.SUB_PANEL_ID.SIM_COMBAT then
    self.Ui.mAnimator_Root:SetInteger("SwitchTab", 2)
  elseif index == self.SUB_PANEL_ID.SIM_RESOURCES then
    self.Ui.mAnimator_Root:SetInteger("SwitchTab", 3)
  elseif index == self.SUB_PANEL_ID.BRANCH_STORY then
    self.Ui.mAnimator_Root:SetInteger("SwitchTab", 4)
  end
  setactive(self.Ui.mTrans_Story, index == self.SUB_PANEL_ID.STORY)
  setactive(self.Ui.mTrans_Hard, index == self.SUB_PANEL_ID.HARD)
  setactive(self.Ui.mTrans_SimCombat, index == self.SUB_PANEL_ID.SIM_COMBAT)
  setactive(self.Ui.mTrans_SimResources, index == self.SUB_PANEL_ID.SIM_RESOURCES)
  setactive(self.Ui.mTrans_GrpBranch, index == self.SUB_PANEL_ID.BRANCH_STORY)
  if index == self.SUB_PANEL_ID.SIM_RESOURCES then
    if self.mSimResourcesSubView then
      self.mSimResourcesSubView:OnShowStart()
    end
  elseif index == self.SUB_PANEL_ID.STORY then
    self.mStorySubView:Refresh()
    self.mStorySubView:OnClickTabByRecordChapterId()
  elseif index == self.SUB_PANEL_ID.SIM_COMBAT then
    self.mSimCombatSubView:Refresh()
  end
  if index == self.SUB_PANEL_ID.HARD then
    self.Ui.mAnimator_Root:SetTrigger("FX")
  end
  UIBattleIndexGlobal.CachedTabIndex = index
  MessageSys:SendMessage(GuideEvent.OnTabSwitched, UIDef.UIBattleIndexPanel, self.tabList[index]:GetGlobalTab())
end

function UIBattleIndexPanelV2:IsReadyToStartTutorial()
  if self.currentType == UIBattleIndexPanelV2.SUB_PANEL_ID.STORY then
    return self.mStorySubView:IsReadyToStartTutorial()
  end
  return true
end

function UIBattleIndexPanelV2:RefreshStoryBg(data)
  self.Ui.mImg_StoryMapBg.sprite = IconUtils.GetStageIcon(data.background)
  self.Ui.mImg_StoryMapBgFx.sprite = IconUtils.GetStageIcon(data.background)
  self.Ui.mAnimator_Root:SetTrigger("FX")
end

function UIBattleIndexPanelV2:RefreshHardBg(data)
  self.Ui.mImg_HardMapBg.sprite = IconUtils.GetStageIcon(data.background)
  self.Ui.mImg_HardMapBgFx.sprite = IconUtils.GetStageIcon(data.background)
  self.Ui.mAnimator_Root:SetTrigger("FX")
end

function UIBattleIndexPanelV2:OnClickBack()
  UIBattleIndexPanelV2.currentType = -1
  UIBattleIndexGlobal.CachedTabIndex = nil
  UIBattleIndexHardSubPanel.OnClose()
  UIBattleIndexBranchStorySubPanel.OnClose()
  UIChapterGlobal:RecordChapterId(nil)
  if CS.DebugCenter.Instance.QuickLogInButton then
    UISystem:JumpToMainPanel()
  else
    UIBattleIndexPanelV2:Close()
  end
end

function UIBattleIndexPanelV2:OnClickHome()
  UIBattleIndexPanelV2.currentType = -1
  UIBattleIndexGlobal.CachedTabIndex = nil
  UIBattleIndexHardSubPanel.OnClose()
  UIBattleIndexBranchStorySubPanel.OnClose()
  UIChapterGlobal:RecordChapterId(nil)
  UISystem:JumpToMainPanel()
end

function UIBattleIndexPanelV2:OnClose()
  UIBattleIndexPanelV2.currentType = -1
  MessageSys:RemoveListener(UIEvent.UINewChapterItemFinish, self.showUnlock)
  CS.GF2.Message.MessageSys.Instance:RemoveListener(CS.GF2.Message.UIEvent.RefreshChapterInfo, self.updateChapter)
  self:ReleaseCtrlTable(self.tabList)
  self.tabList = {}
  self.mStorySubView:OnClose()
  self.mSimResourcesSubView:OnClose()
  self.mSimCombatSubView:OnRelease()
  if self.mBranchStorySubView then
    self.mBranchStorySubView:OnRelease()
    self.mBranchStorySubView = nil
  end
  UIBattleIndexPanelV2.mView = nil
end

function UIBattleIndexPanelV2:OnRelease()
  self.mStorySubView:OnRelease()
  self.mSimResourcesSubView:OnRelease()
end

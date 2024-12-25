require("UI.QuestPanel.UIQuestGlobal")
require("UI.QuestPanel.UIQuestDailyPanel")
require("UI.QuestPanel.UICommonTab")
require("UI.ArchivesPanel.ArchivesCenterAchievementPanelV2")
UIQuestPanel = class("UIQuestPanel", UIBasePanel)

function UIQuestPanel:OnAwake(root)
  self.ui = UIUtils.GetUIBindTable(root)
  self:SetRoot(root)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnBack.gameObject, function()
    self:onClickBack()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnHome.gameObject, function()
    self:onClickHome()
  end)
  self.tabTable = {}
  self.curTabIndex = nil
  self.subPanelTable = {}
  self.delayframeIndex = 0
  self:initAllTopTab()
  self:initAllSubPanel()
end

function UIQuestPanel:OnInit(root)
end

function UIQuestPanel:OnShowStart()
  self:onClickTab(1)
  UIQuestGlobal.cachedTabIndex = nil
end

function UIQuestPanel:OnShowFinish()
end

function UIQuestPanel:OnRecover()
  self:OnShowStart()
end

function UIQuestPanel:OnBackFrom()
  self:onPanelBack()
end

function UIQuestPanel:OnTop()
  self:onDialogBack()
end

function UIQuestPanel:OnSave()
  UIQuestGlobal.cachedTabIndex = self.curTabIndex
end

function UIQuestPanel:OnRelease()
  for i, subPanel in pairs(self.subPanelTable) do
    subPanel:Release()
  end
  self:ReleaseCtrlTable(self.tabTable, true)
  self.curTabIndex = nil
  self.ui = nil
end

function UIQuestPanel:Refresh()
  self:refreshTabRedPoint()
end

function UIQuestPanel:IsReadyToStartTutorial()
  if self.curTabIndex ~= nil and self.subPanelTable[self.curTabIndex] ~= nil and self.subPanelTable[self.curTabIndex].IsReadyToStartTutorial ~= nil then
    return self.subPanelTable[self.curTabIndex]:IsReadyToStartTutorial()
  end
  return false
end

function UIQuestPanel:initAllTopTab()
  local taskTypeDataList = TableData.listTaskTypeDatas:GetList()
  local tabTemplate = self.ui.mScrollItem_TopTab.childItem
  local sortedTable = {}
  for i = 0, taskTypeDataList.Count - 1 do
    local taskTypeData = taskTypeDataList[i]
    if taskTypeData.Sequence ~= 0 and taskTypeData.type ~= 3 then
      table.insert(sortedTable, taskTypeData)
    end
  end
  table.sort(sortedTable, function(a, b)
    return a.Sequence > b.Sequence
  end)
  for i = 1, #sortedTable do
    local taskTypeData = sortedTable[i]
    local tab = UICommonTab.New(instantiate(tabTemplate, self.ui.mScrollItem_TopTab.transform))
    tab:InitByTaskTypeData(taskTypeData, i, function(tabIndex)
      self:onClickTab(tabIndex)
    end)
    local isUnlock = AccountNetCmdHandler:CheckSystemIsUnLock(tab:GetUnlockId())
    local redPointVisible = isUnlock and NetCmdQuestData:CheckIshaveGetReward(tab:GetType())
    tab:SetRedPointVisible(redPointVisible)
    tab:SetLockIconVisible(not isUnlock)
    table.insert(self.tabTable, tab)
  end
end

function UIQuestPanel:initAllSubPanel()
  local tempSubPanelTable = {}
  for i = 1, 2 do
    if i == 1 then
      table.insert(tempSubPanelTable, UIQuestDailyPanel.New(self.ui.mTrans_Daily.gameObject, self))
      for i, tab in ipairs(self.tabTable) do
        local tabType = tab:GetType()
        self.subPanelTable[i] = self:getSubPanelByType(tabType, tempSubPanelTable)
      end
    end
  end
end

function UIQuestPanel:getSubPanelByType(tabType, subPanelTable)
  for i, subPanel in ipairs(subPanelTable) do
    if not subPanel.GetTaskTypeId then
      gferror("\232\175\183\229\174\158\231\142\176\229\135\189\230\149\176GetTaskTypeId()")
      return
    end
    if tabType == subPanel:GetTaskTypeId() then
      return subPanel
    end
  end
end

function UIQuestPanel:onClickTab(tabIndex)
  if tabIndex <= 0 or tabIndex > #self.tabTable then
    return
  end
  local targetTab = self.tabTable[tabIndex]
  if targetTab and TipsManager.NeedLockTips(targetTab:GetUnlockId()) then
    return
  end
  if self.tabTable[self.curTabIndex] then
    self.tabTable[self.curTabIndex]:Deselect()
  end
  local preTabIndex = self.curTabIndex
  self.curTabIndex = tabIndex
  if targetTab then
    targetTab:Select()
  end
  self:onTabChanged(preTabIndex, self.curTabIndex)
end

function UIQuestPanel:onTabChanged(preTabIndex, curTabIndex)
  self:TryCreatePanel(curTabIndex)
  if preTabIndex and self.subPanelTable[preTabIndex] then
    self.subPanelTable[preTabIndex]:Hide()
  end
  if curTabIndex then
    local targetSubPanel = self.subPanelTable[curTabIndex]
    if targetSubPanel then
      targetSubPanel:Show()
    end
  end
end

function UIQuestPanel:TryCreatePanel(curTabIndex)
  if curTabIndex == 2 and not self.subPanelTable[curTabIndex] then
    self.subPanelTable[curTabIndex] = ArchivesCenterAchievementPanelV2.New(self.ui.mTrans_Novice.gameObject, self, 1)
  end
end

function UIQuestPanel:onPanelBack()
  local targetSubPanel = self.subPanelTable[self.curTabIndex]
  if targetSubPanel then
    targetSubPanel:OnPanelBack()
  end
end

function UIQuestPanel:onDialogBack()
  local targetSubPanel = self.subPanelTable[self.curTabIndex]
  if targetSubPanel then
    targetSubPanel:OnDialogBack()
  end
end

function UIQuestPanel:getMaxPhaseId()
  local dataList = TableData.listGuideQuestPhaseDatas:GetList()
  return dataList[dataList.Count - 1].id
end

function UIQuestPanel:refreshTabRedPoint()
  for i, tab in pairs(self.tabTable) do
    local redPointVisible = AccountNetCmdHandler:CheckSystemIsUnLock(tab:GetUnlockId()) and NetCmdQuestData:CheckIshaveGetReward(tab:GetType())
    tab:SetRedPointVisible(redPointVisible and i ~= self.curTabIndex)
  end
end

function UIQuestPanel:onClickHome()
  UISystem:JumpToMainPanel()
end

function UIQuestPanel:onClickBack()
  UIManager.CloseUI(UIDef.UIQuestPanel)
end

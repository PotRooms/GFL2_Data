require("UI.UIBasePanel")
require("UI.Common.UICommonItem")
require("UI.Common.UIComTabBtn1ItemV2")
require("UI.ActivityRegressPanel.Item.UIRegressQuestItem")
UIRegressQuestDialog = class("UIRegressQuestDialog", UIBasePanel)
UIRegressQuestDialog.__index = UIRegressQuestDialog

function UIRegressQuestDialog:ctor(csPanel)
  self.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIRegressQuestDialog:OnInit(root, data)
  self.super.SetRoot(UIRegressQuestDialog, root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.mCloseTime = data.closeTime
  self.ui.mText_Time:StartCountdown(self.mCloseTime)
  self:InitTabs()
  self:InitTopTab()
  self:InitStepReward()
  UIUtils.AddBtnClickListener(self.ui.mBtn_BGClose.gameObject, function()
    UIManager.CloseUI(UIDef.UIRegressQuestDialog)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Close.gameObject, function()
    UIManager.CloseUI(UIDef.UIRegressQuestDialog)
  end)
  self:RegisterEvent()
end

function UIRegressQuestDialog:OnTop()
  for _, item in ipairs(self.taskItems) do
    item:UpdateStateAndProgress()
  end
end

function UIRegressQuestDialog:RegisterEvent()
  function self.onPhaseQuestReceived()
    UISystem:OpenCommonReceivePanel({
      nil,
      
      function()
        NetCmdActivityRegressData:DirtyRedPoint()
        self:RefreshUI()
      end
    })
  end
  
  MessageSys:AddListener(CS.GF2.Message.QuestEvent.OnPhaseQuestReceived, self.onPhaseQuestReceived)
  
  function self.onQuestReceived()
    UISystem:OpenCommonReceivePanel({
      nil,
      function()
        NetCmdActivityRegressData:DirtyRedPoint()
        self:RefreshUI()
        self:ClickTab(self.selectId, true)
      end
    })
  end
  
  MessageSys:AddListener(CS.GF2.Message.QuestEvent.OnQuestReceived, self.onQuestReceived)
  
  function self.onRegressReset()
    UIUtils.PopupPositiveHintMessage(260010)
    UISystem:JumpToMainPanel()
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnDayChange, self.onRegressReset)
  
  function self.onRegressOver()
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260044))
    UIManager.CloseUI(UIDef.UIRegressActivityRewardDialog)
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnRegressOver, self.onRegressOver)
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnRegressTaskOver, self.onRegressOver)
end

function UIRegressQuestDialog:InitTabs()
  self:ClearTabs()
  self.tabItems = {}
  local tabs = TableData.listBackTaskGroupDatas:GetList()
  local currDay = NetCmdActivityRegressData:GetActivityBackInfo().CurrDay
  for i = 0, tabs.Count - 1 do
    local tabData = tabs[i]
    local item = UIComTabBtn1ItemV2.New()
    local locked = NetCmdActivityRegressData:IsDayLocked(tabData.id)
    local redPoint = NetCmdActivityRegressData:DayHasTaskCanReceive(tabData.id)
    local allFinished = NetCmdActivityRegressData:DayTaskAllReceived(tabData.id)
    item:InitCtrl(self.ui.mTrans_GrpTabBtn, {
      index = tabData.id,
      name = tabData.name.str
    })
    item:SetLockVisible(locked)
    item:SetRedPointVisible(redPoint)
    item:SetCheckVisible(allFinished)
    local clickFunc = function()
      if locked then
        local nowTime = CS.CGameTime.ConvertLongToDateTime(CGameTime:GetTimestamp())
        if nowTime.Hour >= 5 then
          nowTime = CS.CGameTime.ConvertLongToDateTime(CGameTime:GetTimestamp() + 86400 * (tabData.id - currDay))
        else
          nowTime = CS.CGameTime.ConvertLongToDateTime(CGameTime:GetTimestamp() + 86400 * (tabData.id - currDay - 1))
        end
        CS.PopupMessageManager.PopupString(string_format(TableData.GetHintById(260021), nowTime.Month, nowTime.Day))
        return
      end
      if self.selectTab then
        self.selectTab:SetBtnInteractable(true)
      end
      self:ClickTab(tabData.id)
      item:SetBtnInteractable(false)
      self.selectTab = item
      self.selectId = tabData.id
    end
    item:AddClickListener(clickFunc)
    table.insert(self.tabItems, {
      item = item,
      id = tabData.id
    })
  end
end

function UIRegressQuestDialog:ClearTabs()
  if self.tabItems == nil then
    return
  end
  for i = #self.tabItems, 1, -1 do
    local item = self.tabItems[i].item
    item:OnRelease()
    table.remove(self.tabItems, i)
  end
  self.tabItems = nil
end

function UIRegressQuestDialog:ClickTab(groupId, ignoreAnim)
  self:ClearTasks()
  self.taskItems = {}
  local tabData = TableData.listBackTaskGroupDatas:GetDataById(groupId)
  local taskIds = tabData.ThemeQuests
  local tempTask = {}
  for i = 0, taskIds.Count - 1 do
    local id = taskIds[i]
    table.insert(tempTask, id)
  end
  table.sort(tempTask, function(a, b)
    local stateA = NetCmdActivityRegressData:GetTaskState(a)
    local stateB = NetCmdActivityRegressData:GetTaskState(b)
    if stateA == stateB then
      return a < b
    else
      return stateB == 2 or stateA == 1
    end
  end)
  for _, v in ipairs(tempTask) do
    local item = UIRegressQuestItem.New()
    item:InitCtrl(self.ui.mTrans_TaskContent.transform, self.ui.mTrans_TaskContent.childItem)
    local taskDetail = TableData.listBackTaskListDatas:GetDataById(v)
    item:SetData(taskDetail)
    item:UpdateStateAndProgress()
    table.insert(self.taskItems, item)
  end
  if ignoreAnim then
    return
  end
  self.ui.mTrans_TaskContent.transform.localPosition = vectorzero
  self.ui.mTrans_AutoFade:DoScrollFade()
end

function UIRegressQuestDialog:InitTopTab()
  for i = #self.tabItems, 1, -1 do
    local locked = NetCmdActivityRegressData:IsDayLocked(i)
    local notComplete = NetCmdActivityRegressData:DayHasTaskNotComplete(i)
    if not locked and notComplete then
      self.tabItems[i].item.clickAction()
      return
    end
  end
  self.tabItems[1].item.clickAction()
end

function UIRegressQuestDialog:ClearTasks()
  if self.taskItems == nil then
    return
  end
  for i = #self.taskItems, 1, -1 do
    local item = self.taskItems[i]
    item:OnRelease()
    table.remove(self.taskItems, i)
  end
  self.taskItems = nil
end

function UIRegressQuestDialog:InitStepReward()
  self:ClearStepReward()
  local totalCount = 0
  local completedTasks = NetCmdActivityRegressData:GetCompletedTaskCount()
  local days = TableData.listBackTaskGroupDatas.Count
  for i = 1, days do
    local dayTasks = TableData.listBackTaskGroupDatas:GetDataById(i).ThemeQuests
    totalCount = totalCount + dayTasks.Count
  end
  self.ui.mText_Progress.text = completedTasks .. "/" .. totalCount
  self.stepRewards = {}
  local stepData = {}
  local taskNum = 0
  local steps = TableData.listBackTaskStepDatas:GetList()
  for i = 0, steps.Count - 1 do
    local step = steps[i]
    local instObj = instantiate(self.ui.mRewardItem.gameObject, self.ui.mTrans_StepRewards)
    setactive(instObj, true)
    local textNum = instObj.transform:Find("GrpText/Text_Num"):GetComponent(typeof(CS.UnityEngine.UI.Text))
    textNum.text = step.step_num
    local itemContent = instObj.transform:Find("GrpItem")
    local item = UICommonItem.New()
    item:InitCtrl(itemContent)
    local itemId, itemNum
    for k, v in pairs(step.reward) do
      itemId = k
      itemNum = v
      item:SetItemData(k, v)
    end
    local startPosX = -460
    local fullX = 920
    instObj.transform.localPosition = Vector3(startPosX + fullX * ((i + 1) / steps.Count), instObj.transform.localPosition.y, 0)
    item:SetRedPoint(false)
    item:SetReceivedIcon(false)
    if completedTasks >= step.step_num then
      if not NetCmdActivityRegressData:CheckPhaseIsReceived(step.id) then
        item:SetItemData(itemId, itemNum, nil, nil, nil, nil, nil, function()
          NetCmdActivityRegressData:SendGetRegressStepReward(step.id)
        end)
        item:SetRedPoint(true)
      else
        item:SetReceivedIcon(true)
      end
    end
    table.insert(self.stepRewards, item)
    table.insert(stepData, step.step_num - taskNum)
    taskNum = step.step_num
  end
  local progress = 0
  local stepProgress = 1 / steps.Count
  for _, num in ipairs(stepData) do
    if completedTasks >= num then
      progress = progress + stepProgress
      completedTasks = completedTasks - num
    else
      progress = progress + completedTasks / num * stepProgress
      break
    end
  end
  self.ui.mImage_ProgressBar.fillAmount = progress
end

function UIRegressQuestDialog:ClearStepReward()
  if self.stepRewards == nil then
    return
  end
  for i = #self.stepRewards, 1, -1 do
    local item = self.stepRewards[i]
    item:OnRelease(true)
    table.remove(self.stepRewards, i)
  end
  self.stepRewards = nil
end

function UIRegressQuestDialog:RefreshUI()
  for _, item in ipairs(self.tabItems) do
    local redPoint = NetCmdActivityRegressData:DayHasTaskCanReceive(item.id)
    local allFinished = NetCmdActivityRegressData:DayTaskAllReceived(item.id)
    item.item:SetRedPointVisible(redPoint)
    item.item:SetCheckVisible(allFinished)
  end
  self:InitStepReward()
end

function UIRegressQuestDialog:OnClose()
  self.selectTab = nil
  self:ClearTabs()
  self:ClearTasks()
  self:ClearStepReward()
  self:UnregisterEvent()
end

function UIRegressQuestDialog:UnregisterEvent()
  MessageSys:RemoveListener(CS.GF2.Message.QuestEvent.OnQuestReceived, self.onQuestReceived)
  MessageSys:RemoveListener(CS.GF2.Message.QuestEvent.OnPhaseQuestReceived, self.onPhaseQuestReceived)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnDayChange, self.onRegressReset)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnRegressOver, self.onRegressOver)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnRegressTaskOver, self.onRegressOver)
end

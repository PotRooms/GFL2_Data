require("UI.UIBasePanel")
require("UI.Common.UICommonItem")
require("UI.ActivitySevenQuestPanel.Item.UISevenQuestTabItem")
require("UI.ActivitySevenQuestPanel.Item.UIActivitySevenQuestTaskItem")
UISevenQuestPanel = class("UISevenQuestPanel", UIBasePanel)
UISevenQuestPanel.__index = UISevenQuestPanel

function UISevenQuestPanel:ctor(csPanel)
  self.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Panel
end

function UISevenQuestPanel:OnInit(root, data)
  self.super.SetRoot(UISevenQuestPanel, root)
  self.ui = {}
  self.closeTime = data.closeTime
  self:LuaUIBindTable(root, self.ui)
  self:RegisterEvent()
  self:InitTopTab()
  setactive(self.ui.mTrans_Receive, not self.activityNewbee.FirstEnterRewardClaimed)
  setactive(self.ui.mTrans_Text, self.activityNewbee.FirstEnterRewardClaimed)
  
  function self.onQuestReceived()
    NetCmdActivitySevenQuestData:DirtyRedPoint()
    UISystem:OpenCommonReceivePanel()
  end
  
  function self.onPhaseQuestReceived()
    NetCmdActivitySevenQuestData:DirtyRedPoint()
    UISystem:OpenCommonReceivePanel()
  end
  
  function self.onSevenQuestReset()
    UIUtils.PopupPositiveHintMessage(260010)
    self.CloseSelf()
  end
  
  function self.onNewbeeStepUpdate(msg)
    self.timer = TimerSys:DelayCall(0.5, function()
      self:InitTopTab()
    end)
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnSevenQuestReset, self.onSevenQuestReset)
  MessageSys:AddListener(CS.GF2.Message.QuestEvent.OnPhaseQuestReceived, self.onPhaseQuestReceived)
  MessageSys:AddListener(CS.GF2.Message.QuestEvent.OnQuestReceived, self.onQuestReceived)
  MessageSys:AddListener(CS.GF2.Message.QuestEvent.OnNewbeeStepUpdate, self.onNewbeeStepUpdate)
end

function UISevenQuestPanel:OnTop()
  self:UpdateProgress()
end

function UISevenQuestPanel:OnBackFrom()
  self:UpdateTask()
end

function UISevenQuestPanel:InitTopTab()
  if self.topTabTable ~= nil then
    self:ReleaseCtrlTable(self.topTabTable)
  end
  self.topTabTable = {}
  self.ui.mText_Time:StartCountdown(self.closeTime)
  self.ui.mText_Time:AddFinishCallback(function(suc)
    UIUtils.PopupPositiveHintMessage(260007)
    self.CloseSelf()
  end)
  self.activityNewbee = NetCmdActivitySevenQuestData:GetActivityNewbee()
  self.currDay = self.activityNewbee.CurStep
  self.totalDay = TableData.listEventSevendayGroupDatas:GetList().Count
  for i = 1, self.totalDay do
    local tabItem = UISevenQuestTabItem.New()
    self.topTabTable[i] = tabItem
    local dayData = TableData.listEventSevendayGroupDatas:GetDataById(i)
    local data = {
      index = i,
      name = dayData.name
    }
    tabItem:InitCtrl(self.ui.mTrans_GrpTabBtn.gameObject, data)
    tabItem:SetLockVisible(i > self.currDay)
    tabItem:SetRedPointVisible(NetCmdActivitySevenQuestData:IsDayXCanReceive(i))
    tabItem:AddClickListener(function()
      if self.currDay < i then
        local nowTime = CS.CGameTime.ConvertLongToDateTime(CGameTime:GetTimestamp())
        if nowTime.Hour >= 5 then
          nowTime = CS.CGameTime.ConvertLongToDateTime(CGameTime:GetTimestamp() + 86400 * (i - self.currDay))
        else
          nowTime = CS.CGameTime.ConvertLongToDateTime(CGameTime:GetTimestamp() + 86400 * (i - self.currDay - 1))
        end
        CS.PopupMessageManager.PopupString(TableData.GetHintById(260262))
        return
      end
      if self.selectedItem then
        self.selectedItem:SetBtnInteractable(true)
      end
      tabItem:SetBtnInteractable(false)
      self.selectedItem = tabItem
      self:UpdateTask()
    end)
  end
  self.topTabTable[math.min(self.totalDay, self.currDay)]:SetBtnInteractable(false)
  self.selectedItem = self.topTabTable[math.min(self.totalDay, self.currDay)]
  self:UpdateTask()
end

function UISevenQuestPanel:UpdateTask()
  if self.taskTable ~= nil then
    self:ReleaseCtrlTable(self.taskTable)
  end
  self.taskTable = {}
  local taskIdTab = {}
  local dayData = TableData.listEventSevendayGroupDatas:GetDataById(self.selectedItem.index)
  for i = 0, dayData.theme_quests.Count - 1 do
    local taskId = dayData.theme_quests[i]
    table.insert(taskIdTab, taskId)
  end
  table.sort(taskIdTab, function(a, b)
    local stateA = NetCmdActivitySevenQuestData:GetTaskState(a)
    local stateB = NetCmdActivitySevenQuestData:GetTaskState(b)
    if stateA == stateB then
      return a < b
    else
      return stateB == 2 or stateA == 1
    end
  end)
  for _, taskId in pairs(taskIdTab) do
    local taskData = TableData.listEventSevendayTasklistDatas:GetDataById(taskId)
    local item = UIActivitySevenQuestTaskItem.New()
    table.insert(self.taskTable, item)
    item:InitCtrl(self.ui.mTrans_TaskContent.gameObject, {
      taskData = taskData,
      day = self.selectedItem.index
    })
  end
  self.ui.mTrans_TaskContent.enabled = false
  self.ui.mTrans_TaskContent.enabled = true
  self:UpdateProgress()
end

function UISevenQuestPanel:InitSteps()
  local steps = TableData.listEventSevendayStepDatas:GetList()
  if self.stepItems ~= nil then
    for _, item in pairs(self.stepItems) do
      gfdestroy(item:GetRoot())
    end
  end
  self.stepItems = {}
  if self.stepRewards ~= nil then
    for _, item in pairs(self.stepRewards) do
      gfdestroy(item)
    end
  end
  self.stepRewards = {}
  for i = 0, steps.Count - 1 do
    self:InitStepReward(steps[i], steps.Count)
  end
end

function UISevenQuestPanel:InitStepReward(data, totalStep)
  local instObj = instantiate(self.ui.mRewardItem.gameObject, self.ui.mTrans_StepRewards)
  table.insert(self.stepRewards, instObj)
  setactive(instObj, true)
  local textNum = instObj.transform:Find("GrpText/Text_Num"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  textNum.text = data.step_num
  local transFinish = instObj.transform:Find("GrpItem/Root/Trans_GrpFinished")
  local transRedPoint = instObj.transform:Find("GrpItem/Root/Trans_RedPoint")
  local button = instObj.transform:Find("GrpItem/Root"):GetComponent(typeof(CS.UnityEngine.UI.GFButton))
  local startPosX = -200
  local fullX = 593.0
  instObj.transform.localPosition = Vector3(startPosX + fullX * ((data.id - 1) / (totalStep - 1)), instObj.transform.localPosition.y, 0)
  local itemId = 0
  for k, v in pairs(data.reward) do
    itemId = k
  end
  setactive(transFinish, false)
  setactive(transRedPoint, false)
  if self.completeNum >= data.step_num then
    if not NetCmdActivitySevenQuestData:CheckPhaseIsReceived(data.id) then
      setactive(transRedPoint, true)
      UIUtils.GetButtonListener(button.gameObject).onClick = function()
        NetCmdActivitySevenQuestData:SendGetSevenQuestPhaseReward(data.id, function(ret)
          if ret == ErrorCodeSuc then
            UISystem:OpenCommonReceivePanel()
          end
        end)
      end
    else
      setactive(transFinish, true)
      if itemId ~= 0 then
        local itemData = TableData.GetItemData(itemId)
        TipsManager.Add(button.gameObject, itemData)
      end
    end
  elseif itemId ~= 0 then
    local itemData = TableData.GetItemData(itemId)
    TipsManager.Add(button.gameObject, itemData)
  end
end

function UISevenQuestPanel:UpdateProgress()
  for i = 1, self.totalDay do
    if i <= self.currDay then
      self.topTabTable[i]:SetRedPointVisible(NetCmdActivitySevenQuestData:IsDayXCanReceive(i))
      self.topTabTable[i]:SetCheckVisible(NetCmdActivitySevenQuestData:IsDayXChecked(i))
    end
  end
  for _, item in pairs(self.taskTable) do
    item:UpdateTaskState()
  end
  self.totalNum = 0
  self.completeNum = NetCmdActivitySevenQuestData:GetCompleteTaskCount()
  for i = 1, self.totalDay do
    local dayData = TableData.listEventSevendayGroupDatas:GetDataById(i)
    self.totalNum = self.totalNum + dayData.theme_quests.Count
  end
  self.ui.mText_Progress.text = self.completeNum
  local steps = TableData.listEventSevendayStepDatas:GetList()
  local lastStep = 0
  local fillValues = {}
  fillValues[0] = 0
  fillValues[1] = 0.2455470737913486
  local gap = (1 - fillValues[1]) / 4
  for i = 2, 5 do
    fillValues[i] = fillValues[1] + (i - 1) * gap
  end
  for i = 0, steps.Count - 1 do
    if self.completeNum <= steps[i].step_num then
      self.ui.mImage_ProgressBar.fillAmount = fillValues[i] + (self.completeNum - lastStep) / (steps[i].step_num - lastStep) * (fillValues[i + 1] - fillValues[i])
      self:InitSteps()
      return
    else
      lastStep = steps[i].step_num
    end
  end
end

function UISevenQuestPanel:OnClickReceive()
  NetCmdActivitySevenQuestData:NewbeeTakeFirstReward(function(ret)
    if ret == ErrorCodeSuc then
      UISystem:OpenCommonReceivePanel()
      setactive(self.ui.mTrans_Receive, false)
      setactive(self.ui.mTrans_Text, true)
    end
  end)
end

function UISevenQuestPanel.CloseSelf()
  UIManager.CloseUI(UIDef.UISevenQuestPanel)
end

function UISevenQuestPanel:RegisterEvent()
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    self.CloseSelf()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Receive.gameObject).onClick = function()
    self:OnClickReceive()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Preview.gameObject).onClick = function()
    local mainTable = TableData.listEventSevendayMainTableDatas:GetDataById(NetCmdActivitySevenQuestData.ActivityId)
    local gunId = 0
    for key, _ in pairs(mainTable.first_rewards) do
      gunId = key
    end
    local listType = CS.System.Collections.Generic.List(CS.System.Int32)
    local mlist = listType()
    mlist:Add(gunId)
    mlist:Add(FacilityBarrackGlobal.ShowContentType.UIGachaPreview)
    mlist:Add(1001)
    UISystem:JumpByID(4001, false, mlist)
  end
end

function UISevenQuestPanel:OnClose()
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnSevenQuestReset, self.onSevenQuestReset)
  MessageSys:RemoveListener(CS.GF2.Message.QuestEvent.OnQuestReceived, self.onQuestReceived)
  MessageSys:RemoveListener(CS.GF2.Message.QuestEvent.OnPhaseQuestReceived, self.onPhaseQuestReceived)
  MessageSys:RemoveListener(CS.GF2.Message.QuestEvent.OnNewbeeStepUpdate, self.onNewbeeStepUpdate)
  self:ReleaseCtrlTable(self.topTabTable)
  self.topTabTable = nil
  self:ReleaseCtrlTable(self.taskTable)
  self.taskTable = nil
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  if self.stepItems ~= nil then
    for _, item in pairs(self.stepItems) do
      gfdestroy(item:GetRoot())
    end
  end
  self.stepItems = nil
  if self.stepRewards ~= nil then
    for _, item in pairs(self.stepRewards) do
      gfdestroy(item)
    end
  end
  self.stepRewards = nil
end

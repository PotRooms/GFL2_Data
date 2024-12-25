require("UI.UIBasePanel")
require("UI.ActivityTreasurePanel.Item.UIActivityTreasureFlopTaskItem")
UIActivityTreasureFlopTaskPanel = class("UIActivityTreasureFlopTaskPanel", UIBasePanel)
UIActivityTreasureFlopTaskPanel.__index = UIActivityTreasureFlopTaskPanel

function UIActivityTreasureFlopTaskPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIActivityTreasureFlopTaskPanel:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Close, function()
    self:CloseSelf()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_CloseBg, function()
    self:CloseSelf()
  end)
end

function UIActivityTreasureFlopTaskPanel:OnInit(root, data)
  self.id = UIActivityTreasureItem.id
  print("\229\189\147\229\137\141\230\180\187\229\138\168id:" .. self.id)
  self:InitTasks()
  self:RegisterEvent()
  self:CreateCloseTimer()
end

function UIActivityTreasureFlopTaskPanel:CreateCloseTimer()
  local now = CGameTime:GetTimestamp()
  self.activityOverTimer = TimerSys:UnscaledDelayCall(UIActivityTreasureItem.closeTime - now, function()
    local topUI = UISystem:GetTopUI(UIGroupType.Default)
    if topUI ~= nil and topUI.UIDefine.UIType ~= UIDef.UIActivityTreasureFlopTaskPanel then
      return
    end
    print("Close By UIActivityTreasureFlopTaskPanel")
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
    UISystem:JumpToMainPanel()
  end)
end

function UIActivityTreasureFlopTaskPanel:OnShowStart()
end

function UIActivityTreasureFlopTaskPanel:OnShowFinish()
end

function UIActivityTreasureFlopTaskPanel:OnTop()
  local now = CGameTime:GetTimestamp()
  if now > UIActivityTreasureItem.closeTime then
    print("Close By UIActivityTreasureFlopTaskPanel OnTop")
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
    UISystem:JumpToMainPanel()
  end
end

function UIActivityTreasureFlopTaskPanel:OnClose()
  self:UnregisterEvent()
  self:ReleaseTasks()
  if self.activityOverTimer then
    self.activityOverTimer:Stop()
    self.activityOverTimer = nil
  end
end

function UIActivityTreasureFlopTaskPanel:OnHide()
end

function UIActivityTreasureFlopTaskPanel:OnHideFinish()
end

function UIActivityTreasureFlopTaskPanel:OnRelease()
end

function UIActivityTreasureFlopTaskPanel:CloseSelf()
  UIManager.CloseUI(UIDef.UIActivityTreasureFlopTaskPanel)
end

function UIActivityTreasureFlopTaskPanel:InitTasks()
  self.taskItems = {}
  local bingoId = TableDataBase.listTreasureMainDatas:GetDataById(self.id).BingoId
  local tasks = TableDataBase.listBingoConfigDatas:GetDataById(bingoId).TaskId
  local tempIds = {}
  local taskConfigs = {}
  for i = 0, tasks.Count - 1 do
    local taskId = tasks[i]
    local taskConfig = TableDataBase.listBingoTaskDatas:GetDataById(taskId)
    taskConfigs[taskId] = taskConfig
    table.insert(tempIds, taskId)
  end
  table.sort(tempIds, function(a, b)
    local stateA = NetCmdActivityTreasureData:GetBingoMissionStatus(a)
    local stateB = NetCmdActivityTreasureData:GetBingoMissionStatus(b)
    local typeA = taskConfigs[a].type
    local typeB = taskConfigs[b].type
    if stateA == stateB then
      if typeA == typeB then
        return a < b
      end
      return typeA < typeB
    else
      return stateB == 2 or stateA == 1
    end
  end)
  local callback = function()
    UISystem:OpenCommonReceivePanel({
      nil,
      function()
        NetCmdActivityTreasureData:DirtyRedPoint()
        self:ReleaseTasks()
        self:InitTasks()
      end
    })
  end
  for _, id in ipairs(tempIds) do
    local item = UIActivityTreasureFlopTaskItem.New()
    item:InitCtrl(self.ui.mTrans_Content)
    item:SetData(taskConfigs[id])
    item:SetCallback(callback)
    table.insert(self.taskItems, item)
  end
end

function UIActivityTreasureFlopTaskPanel:RegisterEvent()
  function self.onActivityReset()
    UIUtils.PopupPositiveHintMessage(260010)
    
    UISystem:JumpToMainPanel()
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnDayChange, self.onActivityReset)
end

function UIActivityTreasureFlopTaskPanel:ReleaseTasks()
  self:ReleaseCtrlTable(self.taskItems, true)
end

function UIActivityTreasureFlopTaskPanel:UnregisterEvent()
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnDayChange, self.onActivityReset)
end

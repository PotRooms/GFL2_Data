require("UI.ActivityTheme.Module.Bingo.ActivityBingo")
require("UI.UIBasePanel")
ActivityBingoBasePanel = class("ActivityBingoBasePanel", UIBasePanel)
ActivityBingoBasePanel.__index = ActivityBingoBasePanel

function ActivityBingoBasePanel:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddButtonListener()
  setactivewithcheck(self.ui.mTrans_Quest, false)
end

function ActivityBingoBasePanel:OnInit(root, data)
  self.activityEntranceData = data.activityEntranceData
  self.activityModuleData = data.activityModuleData
  self.activityConfigData = data.activityConfigData
  self.planActivityData = TableDataBase.listPlanDatas:GetDataById(self.activityEntranceData.plan_id)
  for k, v in pairs(self.activityModuleData.activity_submodule) do
    if k == 1011 then
      self.bingoId = v
      break
    end
  end
  self:InitActivity()
  self:InitBaseInfo()
  self:InitCurrency()
  self:InitGrid()
  self:InitRewards()
  self:InitDailyTasks()
  self:InitAllReceivedReward()
  self:InitScratch()
  self:RegisterEvent()
end

function ActivityBingoBasePanel:OnShowStart()
end

function ActivityBingoBasePanel:OnShowFinish()
end

function ActivityBingoBasePanel:OnTop()
  if self.planActivityData == nil then
    self:OnActivityOver()
    return
  end
  local serverTime = CGameTime:GetTimestamp()
  local open = self.planActivityData and serverTime >= self.planActivityData.open_time and serverTime < self.planActivityData.close_time
  if not open then
    self:OnActivityOver()
    return
  end
  self:RefreshTask()
end

function ActivityBingoBasePanel:OnBackFrom()
  if self.planActivityData == nil then
    self:OnActivityOver()
    return
  end
  local serverTime = CGameTime:GetTimestamp()
  local open = self.planActivityData and serverTime >= self.planActivityData.open_time and serverTime < self.planActivityData.close_time
  if not open then
    self:OnActivityOver()
    return
  end
  self:RefreshTask()
end

function ActivityBingoBasePanel:OnClose()
  self:ReleaseCurrency()
  self:ReleaseGrid()
  self:ReleaseRewards()
  self:ReleaseDailyTasks()
  self:ReleaseTimer()
  self:UnregisterEvent()
end

function ActivityBingoBasePanel:OnHide()
end

function ActivityBingoBasePanel:OnHideFinish()
end

function ActivityBingoBasePanel:OnRelease()
end

function ActivityBingoBasePanel:AddButtonListener()
  UIUtils.AddBtnClickListener(self.ui.mBtn_Scratch, function()
    self:BingoScratch()
  end)
end

function ActivityBingoBasePanel:InitActivity()
  local bingoConfig = TableDataBase.listActivityBingoDatas:GetDataById(self.bingoId)
  self.taskGroup = bingoConfig.TaskGroup
  for id, cost in pairs(bingoConfig.BingoCost) do
    self.currencyId = id
    self.currencyCost = cost
    break
  end
  self.imgRes = bingoConfig.BingoRes
  self.imgRes = bingoConfig.BingoReward
  self.activityName = bingoConfig.Name.str
end

function ActivityBingoBasePanel:InitBaseInfo()
  self.ui.mText_Name.text = self.activityName
  self.ui.mText_NameShadow.text = self.activityName
  IconUtils.GetItemIconSpriteAsync(self.currencyId, self.ui.mImg_Icon)
  local serverTime = CGameTime:GetTimestamp()
  if self.planActivityData == nil then
    self:OnActivityOver()
    return
  end
  local open = self.planActivityData and serverTime >= self.planActivityData.open_time and serverTime < self.planActivityData.close_time
  if not open then
    self:OnActivityOver()
    return
  end
  local currOpenData = CS.CGameTime.ConvertLongToDateTime(self.planActivityData.open_time)
  local currCloseData = CS.CGameTime.ConvertLongToDateTime(self.planActivityData.close_time)
  local currOpenTime, currCloseTime
  if currOpenData.Year == currCloseData.Year then
    currOpenTime = currOpenData:ToString("MM.dd/HH:mm")
    currCloseTime = currCloseData:ToString("MM.dd/HH:mm")
  else
    currOpenTime = currOpenData:ToString("yyyy.MM.dd/HH:mm")
    currCloseTime = currCloseData:ToString("yyyy.MM.dd/HH:mm")
  end
  self.ui.mText_CountDown.text = currOpenTime .. " - " .. currCloseTime
  self.activityOverTimer = TimerSys:UnscaledDelayCall(self.planActivityData.close_time - serverTime, function()
    local topUI = UISystem:GetTopUI(UIGroupType.Default)
    if topUI ~= nil and topUI.UIDefine.UIType ~= self:GetUiDef() then
      return
    end
    self:OnActivityOver()
  end)
end

function ActivityBingoBasePanel:OnActivityOver()
end

function ActivityBingoBasePanel:GetUiDef()
end

function ActivityBingoBasePanel:InitScratch()
  local count = NetCmdItemData:GetItemCountById(self.currencyId)
  self.scratchCount = math.floor(count / self.currencyCost)
  self.ui.mBtn_Scratch.interactable = self.scratchCount > 0
end

function ActivityBingoBasePanel:InitCurrency()
  local item = {
    id = self.currencyId
  }
  self.currencyItem = ResourcesCommonItem.New()
  self.currencyItem:InitCtrl(self.ui.mTrans_Currency, true)
  self.currencyItem:SetData(item)
end

function ActivityBingoBasePanel:InitGrid()
  self.gridItem = {}
  local serverStatus = {}
  local gridStatus = NetCmdActivityBingoData:GetBingoGridStatus()
  for i = 0, gridStatus.Count - 1 do
    serverStatus[gridStatus[i]] = true
  end
  for i = 2, self.width + 1 do
    for j = 2, self.height + 1 do
      local item = self:GetGridItem()
      item:InitCtrl(self.ui.mTrans_Grid)
      local key = ActivityBingo.XY2Key(i, j)
      local index = ActivityBingo.XY2Index(i, j, self.totalWidth)
      item:SetData(key, index, serverStatus[index])
      self.gridItem[key] = item
    end
  end
end

function ActivityBingoBasePanel:GetGridItem()
end

function ActivityBingoBasePanel:InitRewards()
  self.rewardItem = {}
  local serverStatus = {}
  local rewardStatus = NetCmdActivityBingoData:GetBingoRewardStatus()
  for i = 0, rewardStatus.Count - 1 do
    serverStatus[rewardStatus[i]] = true
  end
  local ids = TableDataBase.listActivityBingoRewardByBingoRewardDatas:GetDataById(self.taskGroup).Id
  local rewardConfig = {}
  for i = 0, ids.Length - 1 do
    local id = ids[i]
    local config = TableDataBase.listActivityBingoRewardDatas:GetDataById(id)
    rewardConfig[config.RewardPos] = config
  end
  for i = self.startX, self.rewardWidth + self.startX - 1 do
    local item = self:GetRewardItem()
    item:InitCtrl(self.ui.mTrans_Horizontal)
    local key = ActivityBingo.XY2Key(1, i)
    local index = ActivityBingo.XY2Index(1, i, self.totalWidth)
    item:SetData(key, index, rewardConfig[key], serverStatus[index], 1)
    self.rewardItem[key] = item
  end
  for i = self.startY, self.rewardHeight + self.startY - 1 do
    local item = self:GetRewardItem()
    item:InitCtrl(self.ui.mTrans_Vertical)
    local key = ActivityBingo.XY2Key(i, self.rewardWidth + self.startX)
    local index = ActivityBingo.XY2Index(i, self.rewardWidth + self.startX, self.totalWidth)
    item:SetData(key, index, rewardConfig[key], serverStatus[index], 2)
    self.rewardItem[key] = item
  end
end

function ActivityBingoBasePanel:GetRewardItem()
end

function ActivityBingoBasePanel:InitAllReceivedReward()
end

function ActivityBingoBasePanel:InitDailyTasks()
  self.taskItem = {}
  local activityDay = NetCmdActivityBingoData:GetBingoDay(self.planActivityData.open_time)
  local todayTasks
  local ids = TableDataBase.listActivityBingoTaskByBingoTaskIdDatas:GetDataById(self.taskGroup).Id
  for i = 0, ids.Length - 1 do
    local id = ids[i]
    local config = TableDataBase.listActivityBingoTaskDatas:GetDataById(id)
    if activityDay == config.DayNum then
      todayTasks = config.TaskGroup
      break
    end
  end
  if not todayTasks then
    return
  end
  local taskIds = TableDataBase.listActivityTaskByTaskGroupDatas:GetDataById(todayTasks).Id
  for i = 0, taskIds.Length - 1 do
    local id = taskIds[i]
    local config = TableDataBase.listActivityTaskDatas:GetDataById(id)
    local go = instantiate(self.ui.mTrans_Quest, self.ui.mTrans_QuestParent)
    local item = self:GetTaskItem()
    item:InitCtrlWithNoInstantiate(go, false)
    item:SetData(config, self.activityConfigData.id, self.bingoId)
    table.insert(self.taskItem, item)
  end
end

function ActivityBingoBasePanel:GetTaskItem()
end

function ActivityBingoBasePanel:RegisterEvent()
  function self.ItemUpdateHandler()
    self.currencyItem:UpdateData()
    
    self:InitScratch()
  end
  
  MessageSys:AddListener(CS.GF2.Message.CommonEvent.ItemUpdate, self.ItemUpdateHandler)
  
  function self.ScratchHandler(data)
    local serverGridStatus = {}
    local gridStatus = NetCmdActivityBingoData:GetNewBingoGridStatus()
    for i = 0, gridStatus.Count - 1 do
      serverGridStatus[gridStatus[i]] = true
    end
    local serverRewardStatus
    if data.Content then
      serverRewardStatus = {}
      local rewardStatus = NetCmdActivityBingoData:GetNewBingoRewardStatus()
      for i = 0, rewardStatus.Count - 1 do
        serverRewardStatus[rewardStatus[i]] = true
      end
    end
    self:OnScratchBehavior(serverGridStatus, serverRewardStatus)
  end
  
  MessageSys:AddListener(UIEvent.ThemeActivityBingoScratch, self.ScratchHandler)
end

function ActivityBingoBasePanel:RefreshTask()
  for _, v in pairs(self.taskItem) do
    v:Refresh()
  end
end

function ActivityBingoBasePanel:BingoScratch()
  NetCmdActivityBingoData:BingoScratch(self.activityEntranceData.id)
end

function ActivityBingoBasePanel:OnScratchBehavior(serverGridStatus, serverRewardStatus)
  for _, item in pairs(self.gridItem) do
    item:UpdateStatus(serverGridStatus[item.index], true)
  end
  if serverRewardStatus then
    for _, item in pairs(self.rewardItem) do
      item:UpdateStatus(serverRewardStatus[item.index])
    end
    UISystem:OpenCommonReceivePanel()
  end
end

function ActivityBingoBasePanel:ReleaseCurrency()
  self.currencyItem:OnRelease()
  self.currencyItem = nil
end

function ActivityBingoBasePanel:ReleaseGrid()
  if self.gridItem == nil then
    return
  end
  for _, item in pairs(self.gridItem) do
    item:OnRelease(true)
  end
  self.gridItem = nil
end

function ActivityBingoBasePanel:ReleaseRewards()
  if self.rewardItem == nil then
    return
  end
  for _, item in pairs(self.rewardItem) do
    item:OnRelease(true)
  end
  self.rewardItem = nil
end

function ActivityBingoBasePanel:ReleaseDailyTasks()
  if self.taskItem == nil then
    return
  end
  self:ReleaseCtrlTable(self.taskItem, true)
end

function ActivityBingoBasePanel:ReleaseTimer()
  if self.activityOverTimer ~= nil then
    self.activityOverTimer:Stop()
    self.activityOverTimer = nil
  end
end

function ActivityBingoBasePanel:UnregisterEvent()
  MessageSys:RemoveListener(CS.GF2.Message.CommonEvent.ItemUpdate, self.ItemUpdateHandler)
  MessageSys:RemoveListener(UIEvent.ThemeActivityBingoScratch, self.ScratchHandler)
end

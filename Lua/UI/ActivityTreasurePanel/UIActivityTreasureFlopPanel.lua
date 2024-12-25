require("UI.UIBasePanel")
require("UI.ActivityTreasurePanel.Item.UIActivityTreasureFlopItem")
require("UI.ActivityTreasurePanel.Item.UIActivityTreasureFlopRewardItem")
require("UI.UniTopbar.Item.ResourcesCommonItem")
UIActivityTreasureFlopPanel = class("UIActivityTreasureFlopPanel", UIBasePanel)
UIActivityTreasureFlopPanel.__index = UIActivityTreasureFlopPanel
UIActivityTreasureFlopItem.openDialog = false
local guidePos = {x = 3, y = 3}
local Grid2Index = function(x, y, xMax, yMax)
  return (y - 1) * xMax + x
end

function UIActivityTreasureFlopPanel:ctor(root)
  self.super.ctor(self, root)
end

function UIActivityTreasureFlopPanel:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Task.gameObject, function()
    self:ShowTask()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Reward.gameObject, function()
    self:ClickReward()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Back.gameObject, function()
    UIManager.CloseUI(UIDef.UITreasureFlopPanel)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Home.gameObject, function()
    UISystem:JumpToMainPanel()
  end)
end

function UIActivityTreasureFlopPanel:RegisterEvent()
  function self.onTreasureRewardReceive(data)
    local param = data.Content
    
    local start = param.start
    local x = param.x
    local y = param.y
    if start then
      self:HideGuide()
      self.ui.mCanvas.blocksRaycasts = false
      self:UnRegistrationKeyboard(KeyCode.Escape)
    else
      self.ui.mCanvas.blocksRaycasts = true
      self:CheckExtraByXY(x, y)
      self:RegistrationKeyboardAction(KeyCode.Escape, function()
        UIManager.CloseUI(UIDef.UITreasureFlopPanel)
      end)
    end
    self:RefreshCurrencyItemCount()
  end
  
  MessageSys:AddListener(UIEvent.OnTreasureRewardReceive, self.onTreasureRewardReceive)
  
  function self.ItemUpdateHandler()
    if self.currencyItem then
      self.currencyItem:UpdateData()
    end
  end
  
  MessageSys:AddListener(CS.GF2.Message.CommonEvent.ItemUpdate, self.ItemUpdateHandler)
  
  function self.OnActivityReset()
    UIUtils.PopupPositiveHintMessage(260010)
    UISystem:JumpToMainPanel()
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnDayChange, self.OnActivityReset)
  
  function self.onTreasureLineRewardReceive(data)
    local param = data.Content
    local start = param.start
    if start then
      self:UnRegistrationKeyboard(KeyCode.Escape)
    else
      self:RegistrationKeyboardAction(KeyCode.Escape, function()
        UIManager.CloseUI(UIDef.UITreasureFlopPanel)
      end)
    end
  end
  
  MessageSys:AddListener(UIEvent.OnTreasureLineRewardReceive, self.onTreasureLineRewardReceive)
end

function UIActivityTreasureFlopPanel:ShowTask()
  UIManager.OpenUI(UIDef.UIActivityTreasureFlopTaskPanel)
end

function UIActivityTreasureFlopPanel:ClickReward()
  local bingoId = TableDataBase.listTreasureMainDatas:GetDataById(self.id).BingoId
  local bingoConfig = TableDataBase.listBingoConfigDatas:GetDataById(bingoId)
  UIManager.OpenUIByParam(UIDef.UITreasureFlopRewardPreviewDialog, {config = bingoConfig})
end

function UIActivityTreasureFlopPanel:OnInit(root)
  self.id = UIActivityTreasureItem.id
  local activityConfig = TableDataBase.listActivityListDatas:GetDataById(self.id)
  if activityConfig ~= nil then
    setactivewithcheck(self.ui.mText_Time, activityConfig.permanent ~= 1)
    if activityConfig.permanent ~= 1 then
      self.ui.mText_Time:StartCountdown(UIActivityTreasureItem.closeTime)
    end
  end
  self:TryOpenDialog()
  self:RegisterEvent()
  self:ShowStart()
  self:CreateCloseTimer()
end

function UIActivityTreasureFlopPanel:CreateCloseTimer()
  local now = CGameTime:GetTimestamp()
  self.activityOverTimer = TimerSys:UnscaledDelayCall(UIActivityTreasureItem.closeTime - now, function()
    local topUI = UISystem:GetTopUI(UIGroupType.Default)
    if topUI ~= nil and topUI.UIDefine.UIType ~= UIDef.UITreasureFlopPanel then
      return
    end
    print("Close By UIActivityTreasureFlopPanel")
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
    UISystem:JumpToMainPanel()
  end)
end

function UIActivityTreasureFlopPanel:CheckExtra(withAnim)
  for i = 1, #self.horizontalList do
    self:CheckRewardY(i, withAnim)
  end
  for i = 1, #self.verticalList do
    self:CheckRewardX(i, withAnim)
  end
  self:CheckFinalExtraReward(withAnim)
end

function UIActivityTreasureFlopPanel:CheckExtraByXY(x, y)
  local rewardItemY, rewardItemX
  if NetCmdActivityTreasureData:CheckY(self.id, y) then
    rewardItemY = self.verticalList[y]
  end
  if NetCmdActivityTreasureData:CheckX(self.id, x) then
    rewardItemX = self.horizontalList[x]
  end
  local hasExtraItem = rewardItemX ~= nil or rewardItemY ~= nil
  if not hasExtraItem then
    return
  end
  local xReward = #self.horizontalList
  local yReward = #self.verticalList
  local startNode = self.gridList[Grid2Index(x, y, xReward, yReward)]
  startNode:PlayLineEffect()
  if rewardItemY then
    local indexY = 1
    for i = x - 1, 1, -1 do
      local d = indexY * 5
      local item = self.gridList[Grid2Index(i, y, xReward, yReward)]
      local timer = TimerSys:DelayFrameCall(d, function()
        item:PlayLineEffect()
      end)
      table.insert(self.timers, timer)
      indexY = indexY + 1
    end
    indexY = 1
    for i = x + 1, #self.horizontalList do
      local d = indexY * 5
      local item = self.gridList[Grid2Index(i, y, xReward, yReward)]
      local timer = TimerSys:DelayFrameCall(d, function()
        item:PlayLineEffect()
      end)
      table.insert(self.timers, timer)
      indexY = indexY + 1
    end
    local timer = TimerSys:DelayFrameCall(15, function()
      rewardItemY:Unlock(true)
    end)
    table.insert(self.timers, timer)
  end
  if rewardItemX then
    local indexX = 1
    for i = y - 1, 1, -1 do
      local d = indexX * 5
      local item = self.gridList[Grid2Index(x, i, xReward, yReward)]
      local timer = TimerSys:DelayFrameCall(d, function()
        item:PlayLineEffect()
      end)
      table.insert(self.timers, timer)
      indexX = indexX + 1
    end
    indexX = 1
    for i = y + 1, #self.verticalList do
      local d = indexX * 5
      local item = self.gridList[Grid2Index(x, i, xReward, yReward)]
      local timer = TimerSys:DelayFrameCall(d, function()
        item:PlayLineEffect()
      end)
      table.insert(self.timers, timer)
      indexX = indexX + 1
    end
    local timer = TimerSys:DelayFrameCall(15, function()
      rewardItemX:Unlock(true)
    end)
    table.insert(self.timers, timer)
  end
  local timer = TimerSys:DelayFrameCall(15, function()
    self:CheckFinalExtraReward(true)
  end)
  table.insert(self.timers, timer)
end

function UIActivityTreasureFlopPanel:CreateJumps()
end

function UIActivityTreasureFlopPanel:InitCurrency()
  local bingoId = TableDataBase.listTreasureMainDatas:GetDataById(self.id).BingoId
  local item = {}
  self.bingoItem = TableDataBase.listBingoConfigDatas:GetDataById(bingoId).BingoItem
  item.id = self.bingoItem
  self.currencyItem = ResourcesCommonItem.New()
  self.currencyItem:InitCtrl(self.ui.mTrans_Currency, true)
  self.currencyItem:SetData(item)
end

function UIActivityTreasureFlopPanel:RefreshCurrencyItemCount()
  local count = NetCmdItemData:GetItemCountById(self.bingoItem)
  self.currencyItem:UpdateNum(count)
end

function UIActivityTreasureFlopPanel:InitGrid()
  local xReward = #self.horizontalList
  local yReward = #self.verticalList
  self.gridList = {}
  for y = yReward, 1, -1 do
    for x = 1, xReward do
      local index = Grid2Index(x, y, xReward, yReward)
      local item = UIActivityTreasureFlopItem.New()
      item:InitCtrl(self.ui.mTrans_Block)
      item:SetData({
        x = x,
        y = y,
        index = index
      })
      if x == guidePos.x and y == guidePos.y then
        self:ShowGuide(item:GetRoot())
      end
      self.gridList[index] = item
    end
  end
end

function UIActivityTreasureFlopPanel:InitHorizontal()
  local bingoId = TableDataBase.listTreasureMainDatas:GetDataById(self.id).BingoId
  local rewards = string.split(TableDataBase.listBingoConfigDatas:GetDataById(bingoId).HorizontalItem, ",")
  self.horizontalList = {}
  for index, config in ipairs(rewards) do
    local data = string.split(config, ":")
    local id = data[1]
    local count = data[2]
    local item = UIActivityTreasureFlopRewardItem.New()
    item:InitCtrl(self.ui.mTrans_Horizontal)
    item:SetData({
      dir = 1,
      index = index,
      id = id,
      count = count
    })
    table.insert(self.horizontalList, item)
  end
end

function UIActivityTreasureFlopPanel:InitVertical()
  local bingoId = TableDataBase.listTreasureMainDatas:GetDataById(self.id).BingoId
  local rewards = string.split(TableDataBase.listBingoConfigDatas:GetDataById(bingoId).VerticalItem, ",")
  self.verticalList = {}
  for index, config in pairs(rewards) do
    local data = string.split(config, ":")
    local id = data[1]
    local count = data[2]
    local item = UIActivityTreasureFlopRewardItem.New()
    item:InitCtrl(self.ui.mTrans_Vertical)
    item:SetData({
      dir = 0,
      index = index,
      id = id,
      count = count
    })
    table.insert(self.verticalList, item)
  end
end

function UIActivityTreasureFlopPanel:CheckRewardX(x, withAnim)
  if NetCmdActivityTreasureData:CheckX(self.id, x) then
    local rewardItem = self.horizontalList[x]
    rewardItem:Unlock(withAnim)
  end
end

function UIActivityTreasureFlopPanel:CheckRewardY(y, withAnim)
  if NetCmdActivityTreasureData:CheckY(self.id, y) then
    local rewardItem = self.verticalList[y]
    rewardItem:Unlock(withAnim)
  end
end

function UIActivityTreasureFlopPanel:CheckFinalExtraReward(withAnim)
  local totalCost = NetCmdActivityTreasureData:GetTotalBingoRewardCost(self.id)
  local total = #self.horizontalList * #self.verticalList
  if totalCost >= total then
    self.finalExtraReward:Unlock(withAnim)
  end
end

function UIActivityTreasureFlopPanel:ShowStart()
  self.timers = {}
  self:RefreshRedPoint()
  self:InitCurrency()
  self:ClearHorizontal()
  self:InitHorizontal()
  self:ClearVertical()
  self:InitVertical()
  self:ClearGrid()
  self:InitGrid()
  self.finalExtraReward = UIActivityTreasureFlopRewardItem.New()
  self.finalExtraReward:InitCtrlWithNoInstantiate(self.ui.mTrans_Reward)
  self.finalExtraReward:SetFinalRewardData(self.id)
  self:CheckExtra()
end

function UIActivityTreasureFlopPanel:OnTop()
  local now = CGameTime:GetTimestamp()
  if now > UIActivityTreasureItem.closeTime then
    print("Close By UIActivityTreasureFlopPanel OnTop")
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
    UISystem:JumpToMainPanel()
    return
  end
  self:RefreshRedPoint()
  self:TryOpenDialog()
end

function UIActivityTreasureFlopPanel:OnBackFrom()
  self:OnTop()
end

function UIActivityTreasureFlopPanel:RefreshRedPoint()
  setactivewithcheck(self.ui.mTrans_RedPoint, NetCmdActivityTreasureData:CheckBingoTask(self.id) > 0)
end

function UIActivityTreasureFlopPanel:ShowGuide(parent)
  if NetCmdActivityTreasureData:GetTotalBingoRewardCost(self.id) > 0 then
    return
  end
  self.guideObj = instantiate(UIUtils.GetGizmosPrefab("Combat/Effect/UIGuideBoxNew_Effect02.prefab", self), parent)
  local ctrl = addcomponent(self.guideObj, typeof(CS.UISortingOrderController))
  ctrl.PrefabRelativeSortingOrder = 1
end

function UIActivityTreasureFlopPanel:HideGuide()
  if self.guideObj then
    gfdestroy(self.guideObj)
    self.guideObj = nil
  end
end

function UIActivityTreasureFlopPanel:ClearTimers()
  if self.timers ~= nil then
    for i = #self.timers, 1, -1 do
      local timer = self.timers[i]
      if timer ~= nil then
        timer:Stop()
      end
      table.remove(self.timers, i)
      timer = nil
    end
    self.timers = nil
  end
  if self.activityOverTimer ~= nil then
    self.activityOverTimer:Stop()
    self.activityOverTimer = nil
  end
end

function UIActivityTreasureFlopPanel:OnClose()
  self:UnregisterEvent()
  self:ClearGrid()
  self:ClearHorizontal()
  self:ClearVertical()
  self:ClearCurrency()
  self:HideGuide()
  self:ClearTimers()
  self.finalExtraReward:OnRelease(false)
  self.finalExtraReward = nil
end

function UIActivityTreasureFlopPanel:UnregisterEvent()
  MessageSys:RemoveListener(UIEvent.OnTreasureRewardReceive, self.onTreasureRewardReceive)
  MessageSys:RemoveListener(CS.GF2.Message.CommonEvent.ItemUpdate, self.ItemUpdateHandler)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnDayChange, self.OnActivityReset)
  MessageSys:RemoveListener(UIEvent.OnTreasureLineRewardReceive, self.onTreasureLineRewardReceive)
end

function UIActivityTreasureFlopPanel:ClearCurrency()
  self.currencyItem:OnRelease()
  self.currencyItem = nil
end

function UIActivityTreasureFlopPanel:ClearGrid()
  if self.gridList == nil then
    return
  end
  for i = #self.gridList, 1, -1 do
    local item = self.gridList[i]
    item:OnRelease(true)
    table.remove(self.gridList, i)
  end
  self.gridList = nil
end

function UIActivityTreasureFlopPanel:ClearHorizontal()
  if self.horizontalList == nil then
    return
  end
  for i = #self.horizontalList, 1, -1 do
    local item = self.horizontalList[i]
    item:OnRelease(true)
    table.remove(self.horizontalList, i)
  end
  self.horizontalList = nil
end

function UIActivityTreasureFlopPanel:ClearVertical()
  if self.verticalList == nil then
    return
  end
  for i = #self.verticalList, 1, -1 do
    local item = self.verticalList[i]
    item:OnRelease(true)
    table.remove(self.verticalList, i)
  end
  self.verticalList = nil
end

function UIActivityTreasureFlopPanel:TryOpenDialog()
  if UIActivityTreasureFlopItem.openDialog then
    UIActivityTreasureFlopItem.openDialog = false
    self:ShowTask()
  end
end

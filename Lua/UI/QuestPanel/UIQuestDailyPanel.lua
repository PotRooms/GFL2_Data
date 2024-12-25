require("UI.QuestPanel.UIQuestDailySlot")
require("UI.QuestPanel.UIQuestDailyRewardPoint")
require("UI.QuestPanel.UIQuestSubPanelBase")
require("UI.CommonLevelUpPanel.UICommonLevelUpPanel")
UIQuestDailyPanel = class("UIQuestDailyPanel", UIQuestSubPanelBase)
UIQuestDailyPanel.InOutCirc = CS.DG.Tweening.Ease.InOutCirc

function UIQuestDailyPanel:ctor(go, parentPanel)
  self.ui = UIUtils.GetUIBindTable(go)
  self:SetRoot(go.transform)
  
  function self.ui.mVirtualListEx.itemRenderer(...)
    self:itemRenderer(...)
  end
  
  function self.ui.mVirtualListEx.itemCreated(loopGridViewItem)
    self:itemCreated(loopGridViewItem)
  end
  
  UIUtils.AddBtnClickListener(self.ui.mContainer_ReceiveAll, function()
    self:onClickReceiveAll()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_ReceiveAll, function()
    self:onClickReceiveAllTask()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_LeftRewardIcon, function()
    self:onClickTreasureChest()
  end)
  
  function self.onPlayerCounterReset()
    self:Refresh()
  end
  
  function self.onUIClose(msg)
    if self.isDialogBack ~= nil and self.isDialogBack then
      local panelId = tonumber(msg.Content)
      if panelId == 679 then
        self:refreshLeftPanel()
      elseif panelId == 648 or panelId == 562 then
      else
        self:Refresh()
      end
      self.isDialogBack = nil
    end
  end
  
  function self.onItemUpdate(msg)
    if msg.Sender == 8000 then
      self:refreshLeftPanel()
    end
  end
  
  MessageSys:AddListener(CS.GF2.Message.CommonEvent.ItemUpdate, self.onItemUpdate)
  MessageSys:AddListener(UIEvent.OnUIClose, self.onUIClose)
  MessageSys:AddListener(CS.GF2.Message.QuestEvent.OnPlayerCounterReset, self.onPlayerCounterReset)
  self.parentPanel = parentPanel
  self.slotDataList = self:getSlotDataList()
  self.pointTable = self:initAllRewardPoint()
end

function UIQuestDailyPanel:Show()
  local content = self.ui.mScrollItem_DailyItem:GetComponent(typeof(CS.UnityEngine.RectTransform))
  LuaDOTweenUtils.DOAnchorPosY(content, 0, 0)
  self.super.Show(self)
  self.ui.mImage_QuestProgress.fillAmount = 0
  self:Refresh()
end

function UIQuestDailyPanel:CheckUnlockScrollPos()
  self.ui.mCanvasGroup.blocksRaycasts = true
  self.indexList = NetCmdQuestData:GetUnlockQuestIndex()
  if self.indexList.Count == 0 then
    return
  end
  local maxIndex = self.indexList[self.indexList.Count - 1]
  local content = self.ui.mScrollItem_DailyItem.transform.parent:GetComponent(typeof(CS.UnityEngine.RectTransform))
  local gridLayoutGroup = self.ui.mScrollItem_DailyItem.transform:GetComponent(typeof(CS.UnityEngine.UI.GridLayoutGroup))
  local moveY
  local offset = gridLayoutGroup.spacing.y + gridLayoutGroup.cellSize.y
  local maxCount = math.floor(content.rect.height / gridLayoutGroup.cellSize.y)
  if maxCount >= self.slotDataList.Count then
    return
  elseif maxIndex > self.slotDataList.Count - maxCount then
    moveY = offset * (self.slotDataList.Count - maxCount)
  else
    moveY = offset * (maxIndex - 1)
  end
  self.ui.mCanvasGroup.blocksRaycasts = false
  self.popTimer = TimerSys:DelayCall(1, function()
    CS.PopupMessageManager.PopupStateChangeString(TableData.GetHintById(112019))
    LuaDOTweenUtils.DOAnchorPosY(self.ui.mScrollItem_DailyItem.transform, moveY, 0.75)
  end)
  self.blockTimer = TimerSys:DelayCall(1.5, function()
    self.indexList = nil
    self.ui.mCanvasGroup.blocksRaycasts = true
  end)
end

function UIQuestDailyPanel:OnPanelBack()
  self:Refresh()
end

function UIQuestDailyPanel:OnDialogBack()
  self.ui.mBtn_LeftRewardIcon.interactable = false
  TimerSys:DelayCall(0.4, function(data)
    self.ui.mBtn_LeftRewardIcon.interactable = true
  end)
  if self.forbiddenRefresh == nil or not self.forbiddenRefresh then
    self.isDialogBack = true
  else
    self.forbiddenRefresh = false
  end
end

function UIQuestDailyPanel:Hide()
  self.super.Hide(self)
end

function UIQuestDailyPanel:Release()
  if self.progressTween then
    LuaDOTweenUtils.Kill(self.progressTween, false)
    self.progressTween = nil
  end
  if self.popTimer ~= nil then
    self.popTimer:Stop()
    self.popTimer = nil
  end
  if self.blockTimer ~= nil then
    self.blockTimer:Stop()
    self.blockTimer = nil
  end
  MessageSys:RemoveListener(CS.GF2.Message.CommonEvent.ItemUpdate, self.onItemUpdate)
  MessageSys:RemoveListener(UIEvent.OnUIClose, self.onUIClose)
  MessageSys:RemoveListener(CS.GF2.Message.QuestEvent.OnPlayerCounterReset, self.onPlayerCounterReset)
  self.indexList = nil
  self.slotDataList = nil
  self.cacheDropDirty = nil
  self.ui = nil
end

function UIQuestDailyPanel:Refresh()
  self.parentPanel:Refresh()
  self:refreshAllSlot()
  self:refreshLeftPanel()
  TimerSys:DelayFrameCall(1, function()
    self:CheckUnlockScrollPos()
  end)
end

function UIQuestDailyPanel:GetTaskTypeId()
  return 1
end

function UIQuestDailyPanel:GetAnimPageSwitchInt()
  return 0
end

function UIQuestDailyPanel:IsReadyToStartTutorial()
  if self.cacheDropDirty == true then
    return false
  end
  local levelDelta = AccountNetCmdHandler.mLevelDelta
  if 0 < levelDelta then
    return false
  end
  local topUI = UISystem:GetTopUIWithoutClosing(UIGroupType.BattleUI) or UISystem:GetTopUIWithoutClosing()
  if topUI.UIDefine.UIType ~= self.parentPanel.mCSPanel.UIDefine.UIType then
    return false
  end
  return true
end

function UIQuestDailyPanel:initAllRewardPoint()
  local pointTable = {}
  local havePoint = self:getHavePointCount()
  local totalPointCount = self:getTotalPointCount()
  if totalPointCount == 5 then
    self.ui.mLayout_Points.spacing = 0
  elseif totalPointCount == 4 then
    self.ui.mLayout_Points.spacing = 50
  else
    gferror("space\230\156\170\229\174\154\228\185\137!")
  end
  for i = 1, totalPointCount do
    local pointTrans = self.ui["mTrans_Point" .. tostring(i)]
    if not pointTrans then
      break
    end
    local point = UIQuestDailyRewardPoint.New(pointTrans.gameObject)
    point:SetData(havePoint, i)
    point:SetVisible(true)
    table.insert(pointTable, point)
  end
  return pointTable
end

function UIQuestDailyPanel:itemCreated(loopGridViewItem)
  local slot = UIQuestDailySlot.New(loopGridViewItem.gameObject)
  loopGridViewItem.data = slot
end

function UIQuestDailyPanel:itemRenderer(index, loopGridViewItem)
  local slotData = self.slotDataList[index]
  local slot = loopGridViewItem.data
  slot:SetData(slotData, index + 1, function()
    self:onSlotReceived()
  end)
  if self.indexList and self.indexList.Count > 0 then
    for i = 0, self.indexList.Count - 1 do
      if self.indexList[i] == index + 1 then
        slot:PlayUnlockFx()
      end
    end
  end
end

function UIQuestDailyPanel:onClickReceiveAllTask()
  if self.canReceiveList ~= nil and #self.canReceiveList > 0 then
    NetCmdQuestData:Sendtake_quest_rewardCmd(self.canReceiveList, function(ret)
      if ret == ErrorCodeSuc then
        self:onSlotReceived()
      end
    end)
  end
end

function UIQuestDailyPanel:refreshAllSlot()
  self.canReceiveList = {}
  setactive(self.ui.mTrans_GrpAction, false)
  self.slotDataList = self:getSlotDataList()
  if not self.slotDataList or self.slotDataList.Count == 0 then
    return
  end
  for k, questData in pairs(self.slotDataList) do
    if not questData.isReceived and questData.isComplete then
      table.insert(self.canReceiveList, questData.Id)
    end
  end
  setactive(self.ui.mTrans_GrpAction, #self.canReceiveList > 0)
  self.ui.mVirtualListEx.numItems = self.slotDataList.Count
  self.ui.mVirtualListEx:Refresh()
end

function UIQuestDailyPanel:refreshLeftPanel()
  self:refreshProgress()
  self:refreshAllPoint()
  self:refreshLeftReceiveBtn()
end

function UIQuestDailyPanel:refreshProgress()
  local havePoint = self:getHavePointCount()
  local totalPoint = TableData.listDailyRewardDatas:GetDataById(TableData.listDailyRewardDatas.Count).value
  self.ui.mText_QuestProgress.text = TableData.GetHintById(112013, havePoint, totalPoint)
  if self.progressTween then
    LuaDOTweenUtils.Kill(self.progressTween, false)
  end
  local getter = function(tempSelf)
    return tempSelf.ui.mImage_QuestProgress.fillAmount
  end
  local setter = function(tempSelf, value)
    tempSelf.ui.mImage_QuestProgress.fillAmount = value
  end
  self.progressTween = LuaDOTweenUtils.ToOfFloat(self, getter, setter, havePoint / totalPoint, 1.5, nil)
  self.ui.mText_ReceivedProgress.text = TableData.GetHintById(112016, self:getReceivedCount(), self:getTotalPointCount())
  self.ui.mText_TodayProgress.text = TableData.GetHintById(112016, self:getReceivedQuestCount(), self.slotDataList.Count)
end

function UIQuestDailyPanel:refreshAllPoint()
  local activeCount = 0
  local allCount = 0
  for i, point in pairs(self.pointTable) do
    point:SetData(self:getHavePointCount(), i)
    allCount = allCount + 1
    if point.isActive then
      activeCount = activeCount + 1
    end
  end
  self.ui.mImage_PointProgress.FillAmount = (activeCount - 1) / (allCount - 1)
end

function UIQuestDailyPanel:refreshLeftReceiveBtn()
  setactive(self.ui.mTrans_NotReceive, false)
  setactive(self.ui.mTrans_Received, false)
  setactive(self.ui.mContainer_ReceiveAll, false)
  setactive(self.ui.mTrans_RedPoint, false)
  setactive(self.ui.mTrans_LeftRewardFx, false)
  local isAllReceived = self:isAllReceived()
  local haveCanReceivePoint = self:isHaveReceivable()
  if isAllReceived then
    setactive(self.ui.mTrans_Received, true)
  elseif haveCanReceivePoint then
    setactive(self.ui.mContainer_ReceiveAll, true)
    setactive(self.ui.mTrans_LeftRewardFx, true)
    setactive(self.ui.mTrans_RedPoint, true)
  else
    setactive(self.ui.mTrans_NotReceive, true)
  end
end

function UIQuestDailyPanel:getSlotDataList()
  return NetCmdQuestData:GetShowDailyQuestList()
end

function UIQuestDailyPanel:getTotalPointCount()
  local dailyRewardDataList = NetCmdQuestData:GetDailyRewardDataList()
  return dailyRewardDataList.Count
end

function UIQuestDailyPanel:getReceivedQuestCount()
  local receivedCount = 0
  for k, questData in pairs(self.slotDataList) do
    if questData.isReceived then
      receivedCount = receivedCount + 1
    end
  end
  return receivedCount
end

function UIQuestDailyPanel:getHavePointCount()
  return NetCmdItemData:GetItemCount(8000)
end

function UIQuestDailyPanel:isAllReceived()
  local dailyRewards = NetCmdQuestData:GetDailyRewards()
  if not dailyRewards or dailyRewards.Count ~= 4 then
    return false
  end
  for i, isReceived in pairs(dailyRewards) do
    if not isReceived then
      return false
    end
  end
  return true
end

function UIQuestDailyPanel:isHaveReceivable()
  local receiveList = {}
  local havePoint = self:getHavePointCount()
  local dailyRewardDataList = NetCmdQuestData:GetDailyRewardDataList()
  for i, dailyRewardData in pairs(dailyRewardDataList) do
    if havePoint >= dailyRewardData.value and not NetCmdQuestData:IsDailyRewardReceive(dailyRewardData.Id) then
      table.insert(receiveList, dailyRewardData.Id)
    end
  end
  return 0 < #receiveList
end

function UIQuestDailyPanel:getReceivedCount()
  local count = 0
  local dailyRewards = NetCmdQuestData:GetDailyRewards()
  if dailyRewards then
    for id, isReceived in pairs(dailyRewards) do
      if isReceived then
        count = count + 1
      end
    end
  end
  return count
end

function UIQuestDailyPanel:getMaxCanReceivePointId()
  local maxCanReceiveId = 0
  local dailyRewardDataList = TableData.listDailyRewardDatas:GetList()
  local havePoint = self:getHavePointCount()
  for k, dailyRewardData in pairs(dailyRewardDataList) do
    if havePoint >= dailyRewardData.value then
      maxCanReceiveId = dailyRewardData.id
    end
  end
  return maxCanReceiveId
end

function UIQuestDailyPanel:getUnreceiveQuestCount()
  local maxCanReceiveId = 0
  local dailyRewardDataList = TableData.listDailyRewardDatas:GetList()
  local havePoint = self:getHavePointCount()
  local count = 0
  for k, dailyRewardData in pairs(dailyRewardDataList) do
    if havePoint >= dailyRewardData.value then
      count = count + 1
    end
  end
  return count
end

function UIQuestDailyPanel:onClickReceiveAll()
  local addExp = 0
  local receiveList = {}
  local havePoint = self:getHavePointCount()
  local dailyRewardDataList = NetCmdQuestData:GetDailyRewardDataList()
  for i, dailyRewardData in pairs(dailyRewardDataList) do
    if havePoint >= dailyRewardData.value and not NetCmdQuestData:IsDailyRewardReceive(dailyRewardData.Id) then
      local rewardData = TableData.listDailyRewardDatas:GetDataById(dailyRewardData.Id)
      for itemId, num in pairs(rewardData.reward_list) do
        if itemId == 200 then
          addExp = addExp + num
        end
        if TipsManager.CheckItemIsOverflowAndStop(itemId, num) then
          return
        end
      end
      table.insert(receiveList, dailyRewardData.Id)
    end
  end
  if 0 < #receiveList then
    local curLevel = AccountNetCmdHandler:GetLevel()
    local curExp = AccountNetCmdHandler.mOldExp
    local maxExp = 0
    if curLevel < TableData.GlobalSystemData.CommanderLevel then
      local data = TableData.listPlayerLevelDatas:GetDataById(curLevel + 1)
      maxExp = data.exp
      self.forbiddenRefresh = maxExp <= curExp + addExp
    else
      self.forbiddenRefresh = false
    end
    self.cacheDropDirty = true
    NetCmdQuestData:C2SQuestTakeDailyReward2(receiveList, function(ret)
      self.cacheDropDirty = false
      self:onReceivedLeftAll(ret)
    end)
  end
end

function UIQuestDailyPanel:onClickTreasureChest()
  local dailyRewardDataList = TableData.listDailyRewardDatas:GetList()
  if not dailyRewardDataList or dailyRewardDataList.Count == 0 then
    return
  end
  UIManager.OpenUIByParam(UIDef.UIQuestDailyRewardDialog, self:getHavePointCount())
end

function UIQuestDailyPanel:onReceivedLeftAll(ret)
  if ret ~= ErrorCodeSuc then
    return
  end
  local onCloseCallback = function()
    if AccountNetCmdHandler.IsLevelUpdate then
      UICommonLevelUpPanel.Open(UICommonLevelUpPanel.ShowType.Settlement, function()
        UISystem:OpenCommonReceivePanel()
      end)
    end
  end
  UISystem:OpenCommonReceivePanel({onCloseCallback})
  self:Refresh()
end

function UIQuestDailyPanel:onSlotReceived(guideQuestData, index)
  local hint = TableData.GetHintById(112018)
  PopupMessageManager.PopupPositiveString(hint)
  self:Refresh()
  NetCmdItemData:ClearUserDropCache()
end

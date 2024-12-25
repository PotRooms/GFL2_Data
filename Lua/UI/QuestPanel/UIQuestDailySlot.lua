UIQuestDailySlot = class("UIQuestDailySlot", UIBaseCtrl)

function UIQuestDailySlot:ctor(go)
  self.ui = UIUtils.GetUIBindTable(go.transform)
  self:SetRoot(go.transform)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnGoto.gameObject, function()
    self:onClickGoto()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnClose.gameObject, function()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnLocked.gameObject, function()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Receive.gameObject, function()
    self:onClickReceive()
  end)
  self.questData = nil
  self.index = nil
  self.onReceiveCallback = nil
  self.itemTable = {}
end

function UIQuestDailySlot:SetData(questData, index, onReceiveCallback)
  self.questData = questData
  self.index = index
  self.onReceiveCallback = onReceiveCallback
  self:Refresh()
end

function UIQuestDailySlot:Release()
  self:ReleaseCtrlTable(self.itemTable)
  self.questData = nil
  self.index = nil
  self.onReceiveCallback = nil
  self.ui = nil
end

function UIQuestDailySlot:Refresh()
  self.ui.mText_Tittle.text = self.questData.name
  self.ui.mText_Progress.text = self.questData:GetRatioStr()
  self.ui.mImage_Progress.fillAmount = self.questData:GetProgress()
  self.ui.mText_Content.text = self.questData.description
  setactive(self.ui.mTrans_Mask, false)
  setactive(self.ui.mTrans_Mask1, false)
  local rewardList = {}
  for itemId, num in pairs(self.questData.rewardList) do
    table.insert(rewardList, {itemId = itemId, num = num})
  end
  table.sort(rewardList, function(a, b)
    return a.itemId == 8000
  end)
  local rewardCount = 0
  for _, reward in pairs(rewardList) do
    rewardCount = rewardCount + 1
    local item = self.itemTable[rewardCount]
    if item == nil then
      item = UICommonItem.New()
      item:InitCtrl(self.ui.mTrans_GrpItem.transform)
      table.insert(self.itemTable, item)
    end
    item:SetItemData(reward.itemId, reward.num)
    item.mUIRoot:SetAsLastSibling()
    item.mUIRoot.gameObject:SetActive(true)
    local stcData = TableData.GetItemData(reward.itemId)
    TipsManager.Add(item.mUIRoot, stcData)
  end
  if rewardCount < #self.itemTable then
    for i = rewardCount + 1, #self.itemTable do
      local item = self.itemTable[i]
      if item then
        item.mUIRoot.gameObject:SetActive(false)
      end
    end
  end
  setactive(self.ui.mTrans_EmptyRewardSlot1, self.questData.rewardList.Count == 1)
  setactive(self.ui.mTrans_EmptyRewardSlot2, self.questData.rewardList.Count == 0)
  setactive(self.ui.mTrans_Finished, false)
  setactive(self.ui.mTrans_Unfinished, false)
  setactive(self.ui.mBtn_BtnGoto, false)
  setactive(self.ui.mBtn_Receive, false)
  if self.questData.isReceived then
    setactive(self.ui.mTrans_Finished, true)
    self.ui.mAnimator:SetBool("Finshed", true)
  else
    self.ui.mAnimator:SetBool("Finshed", false)
    if self.questData.isComplete then
      setactive(self.ui.mBtn_Receive, true)
    elseif self.questData.link == "" then
      setactive(self.ui.mTrans_Unfinished, true)
    else
      setactive(self.ui.mBtn_BtnGoto, true)
    end
  end
end

function UIQuestDailySlot:PlayUnlockFx()
  setactive(self.ui.mTrans_Mask, true)
  setactive(self.ui.mTrans_Mask1, true)
  TimerSys:DelayCall(0.5, function()
    self.ui.mAnimator:SetTrigger("Fx")
  end)
end

function UIQuestDailySlot:onClickGoto()
  if CS.UIUtils.GetTouchClicked() then
    return
  end
  CS.UIUtils.SetTouchClicked()
  UISystem:JumpByID(tonumber(self.questData.link))
end

function UIQuestDailySlot:onClickReceive()
  NetCmdQuestData:Sendtake_quest_rewardCmd({
    self.questData.Id
  }, function(ret)
    self:onReceivedCallback(ret)
  end)
end

function UIQuestDailySlot:onReceivedCallback(ret)
  if ret ~= ErrorCodeSuc then
    return
  end
  self:Refresh()
  if self.onReceiveCallback then
    self.onReceiveCallback(self.questData, self.index)
  end
end

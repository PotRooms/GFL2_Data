require("UI.ActivityTheme.Lenna.LennaActivity")
require("UI.ActivityTheme.Lenna.Item.UILennaBingoItem")
require("UI.ActivityTheme.Lenna.Item.UILennaBingoRewardItem")
require("UI.ActivityTheme.Lenna.Item.UILennaBingoTaskItem")
require("UI.ActivityTheme.Lenna.Item.LennaPreWarmAnimItem")
require("UI.ActivityTheme.Module.Bingo.ActivityBingoBasePanel")
LennaPreWarmPanel = class("LennaPreWarmPanel", ActivityBingoBasePanel)
LennaPreWarmPanel.__index = LennaPreWarmPanel

function LennaPreWarmPanel:ctor(root)
  self.super.ctor(self, root)
end

function LennaPreWarmPanel:AddButtonListener()
  UIUtils.AddBtnClickListener(self.ui.mBtn_Back, function()
    UIManager.CloseUI(UIDef.LennaPreWarmPanel)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Home, function()
    UISystem:JumpToMainPanel()
  end)
  self.super.AddButtonListener(self)
end

function LennaPreWarmPanel:OnInit(root, data)
  self.width = LennaActivity.bingoConfig.width
  self.height = LennaActivity.bingoConfig.height
  self.startX = LennaActivity.bingoConfig.startX
  self.startY = LennaActivity.bingoConfig.startY
  self.rewardWidth = LennaActivity.bingoConfig.rewardWidth
  self.rewardHeight = LennaActivity.bingoConfig.rewardHeight
  self.totalWidth = LennaActivity.bingoConfig.totalWidth
  self:InitAnimFadeIn()
  self.showing = false
  self.super.OnInit(self, root, data)
end

function LennaPreWarmPanel:GetUiDef()
  return UIDef.LennaPreWarmPanel
end

function LennaPreWarmPanel:InitBaseInfo()
  self.super.InitBaseInfo(self)
  self.ui.mText_Name1.text = self.activityName
  self.ui.mText_Time.text = TableData.GetActivityHint(21011005, self.activityConfigData.id, 2, 1011, self.bingoId)
  self.ui.mText_Task.text = TableData.GetActivityHint(21011009, self.activityConfigData.id, 2, 1011, self.bingoId)
  self.ui.mText_All.text = TableData.GetActivityHint(21011008, self.activityConfigData.id, 2, 1011, self.bingoId)
  self.ui.mText_Title.text = TableData.GetActivityHint(21011007, self.activityConfigData.id, 2, 1011, self.bingoId)
  self.ui.mText_ScratchFinished.text = TableData.GetActivityHint(21011011, self.activityConfigData.id, 2, 1011, self.bingoId)
end

function LennaPreWarmPanel:OnActivityOver()
  CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
  UIManager.CloseUI(UIDef.LennaPreWarmPanel)
end

function LennaPreWarmPanel:InitScratch()
  self.super.InitScratch(self)
  self.ui.mText_Item.text = string_format(TableData.GetActivityHint(21011006, self.activityConfigData.id, 2, 1011, self.bingoId), self.currencyCost)
  if NetCmdActivityBingoData:ReceiveAllReward(self.bingoId) then
    setactivewithcheck(self.ui.mTrans_Scratch, false)
    setactivewithcheck(self.ui.mTrans_ScratchFinished, true)
    return
  end
  self.scratchCount = math.min(self.scratchCount, NetCmdActivityBingoData:GetRemainCount(self.width * self.height))
  self.ui.mText_Scratch.text = self.scratchCount <= 0 and TableData.GetActivityHint(21011004, self.activityConfigData.id, 2, 1011, self.bingoId) or string_format(TableData.GetActivityHint(21011001, self.activityConfigData.id, 2, 1011, self.bingoId), self.scratchCount)
  setactivewithcheck(self.ui.mTrans_Scratch, true)
  setactivewithcheck(self.ui.mTrans_ScratchFinished, false)
  setactivewithcheck(self.ui.mTrans_AwardFinished, false)
end

function LennaPreWarmPanel:InitAllReceivedReward()
  local ids = TableDataBase.listActivityBingoRewardByBingoRewardDatas:GetDataById(self.taskGroup).Id
  self.allId = nil
  for i = 0, ids.Length - 1 do
    local id = ids[i]
    local config = TableDataBase.listActivityBingoRewardDatas:GetDataById(id)
    if config.reward_pos == "" or config.reward_pos == nil then
      for itemId, itemCount in pairs(config.ItemId) do
        self.allId = itemId
      end
      break
    end
  end
  if self.allId ~= nil then
    IconUtils.GetItemIconSpriteAsync(self.allId, self.ui.mImg_Reward)
    local itemData = TableData.GetItemData(self.allId)
    TipsManager.Add(self.ui.mBtn_Award.gameObject, itemData)
    if NetCmdActivityBingoData:ReceiveAllReward(self.bingoId) then
      self:CheckAllRewardReceived()
    end
  end
end

function LennaPreWarmPanel:GetGridItem()
  return UILennaBingoItem.New()
end

function LennaPreWarmPanel:GetRewardItem()
  return UILennaBingoRewardItem.New()
end

function LennaPreWarmPanel:GetTaskItem()
  return UILennaBingoTaskItem.New()
end

function LennaPreWarmPanel:InitAnimFadeIn()
  if self.animTimer then
    self.animTimer:Stop()
    self.animTimer = nil
  end
  self.animTimer = TimerSys:DelayFrameCall(1, function()
    local key = AccountNetCmdHandler.Uid .. "LennaPreWarnAnim1"
    local now = CGameTime:GetTimestamp()
    if PlayerPrefs.HasKey(key) then
      local time = PlayerPrefs.GetInt(key)
      local passDay = CGameTime:SpanDay(time, now, 0)
      if 0 < passDay then
        PlayerPrefs.SetInt(key, now)
        self.ui.mAnimator_Root:SetTrigger("FadeIn_First")
      end
    else
      PlayerPrefs.SetInt(key, now)
      self.ui.mAnimator_Root:SetTrigger("FadeIn_First")
    end
  end)
end

function LennaPreWarmPanel:BingoScratch()
  if self.showing then
    return
  end
  self.super.BingoScratch(self)
end

function LennaPreWarmPanel:OnScratchBehavior(serverGridStatus, serverRewardStatus)
  self.showing = true
  local i = 0
  for _, item in pairs(self.gridItem) do
    local active = serverGridStatus[item.index]
    if active then
      self:DelayCall(i * 0.05, function()
        item:UpdateStatus(serverGridStatus[item.index], true)
      end)
      i = i + 1
    end
  end
  if serverRewardStatus == nil then
    self.showing = false
    return
  end
  self:DelayCall(i * 0.05 + 0.8, function()
    local itemKeys = {}
    for _, item in pairs(self.rewardItem) do
      if serverRewardStatus[item.index] then
        item:OnReward()
        local rewardCondition = item.rewardCondition
        local s = string.sub(rewardCondition, 1, string.len(rewardCondition) - 1)
        local keys = string.split(s, ",")
        for _, key in ipairs(keys) do
          itemKeys[key] = true
        end
      end
    end
    for key, item in pairs(self.gridItem) do
      if itemKeys[key] then
        item:OnReward()
      end
    end
    self:DelayCall(0.7, function()
      self.showing = false
      UISystem:OpenCommonReceivePanel({
        nil,
        function()
          if NetCmdActivityBingoData:ReceiveAllReward(self.bingoId) then
            setactivewithcheck(self.ui.mTrans_Scratch, false)
            setactivewithcheck(self.ui.mTrans_ScratchFinished, true)
            self:CheckAllRewardReceived()
          else
            setactivewithcheck(self.ui.mTrans_AwardFinished, false)
          end
        end
      })
    end)
  end)
end

function LennaPreWarmPanel:CheckAllRewardReceived()
  if self.allId ~= nil then
    setactivewithcheck(self.ui.mTrans_AwardFinished, true)
  end
end

function LennaPreWarmPanel:OnClose()
  self.showing = false
  if self.animTimer then
    self.animTimer:Stop()
    self.animTimer = nil
  end
  self.super.OnClose(self)
end

function LennaPreWarmPanel:RegisterEvent()
  self.super.RegisterEvent(self)
  
  function self.OnDayChange()
    local serverTime = CGameTime:GetTimestamp()
    local open = self.planActivityData and serverTime >= self.planActivityData.open_time and serverTime < self.planActivityData.close_time
    if not open then
      return
    end
    NetCmdActivityBingoData:GetBingoInfo(self.activityEntranceData.id, function(ret)
      if ret == ErrorCodeSuc then
        self:DelayCall(5, function()
          self:ReleaseDailyTasks()
          self:InitDailyTasks()
        end)
      end
    end)
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnDayChange, self.OnDayChange)
end

function LennaPreWarmPanel:UnregisterEvent()
  self.super.UnregisterEvent(self)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnDayChange, self.OnDayChange)
end

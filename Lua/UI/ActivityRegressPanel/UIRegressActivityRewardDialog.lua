require("UI.Common.UICommonItem")
require("UI.ActivityRegressPanel.Item.UIRegressActivityRewardItem")
UIRegressActivityRewardDialog = class("UIRegressActivityRewardDialog", UIBasePanel)
UIRegressActivityRewardDialog.__index = UIRegressActivityRewardDialog

function UIRegressActivityRewardDialog:ctor(csPanel)
  self.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIRegressActivityRewardDialog:OnInit(root, data)
  self.super.SetRoot(UIRegressActivityRewardDialog, root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.ui.mText_Info.text = TableData.listBackBoxDatas:GetDataById(1).explain.str
  UIUtils.AddBtnClickListener(self.ui.mBtn_Close, function()
    UIManager.CloseUI(UIDef.UIRegressActivityRewardDialog)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_GrpClose, function()
    UIManager.CloseUI(UIDef.UIRegressActivityRewardDialog)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Start, function()
    self:SendGetRegressReward()
  end)
  
  function self.ui.mScrollCtrl.itemCreated(renderData)
    local item = self:ItemProvider(renderData)
    return item
  end
  
  function self.ui.mScrollCtrl.itemRenderer(index, rendererData)
    self:ItemRenderer(index, rendererData)
  end
  
  self:RegisterEvent()
end

function UIRegressActivityRewardDialog:ItemProvider(renderData)
  local itemView = UICommonItem.New()
  itemView:InitCtrlWithNoInstantiate(renderData.gameObject, false)
  renderData.data = itemView
end

function UIRegressActivityRewardDialog:ItemRenderer(index, renderData)
  local item = renderData.data
  local data = self.oneTimeRewardList[index + 1]
  item:SetByItemData(data.data, data.count, data.received)
end

function UIRegressActivityRewardDialog:RegisterEvent()
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
end

function UIRegressActivityRewardDialog:OnShowStart()
  self:RefreshOneTimeReward()
  self:RefreshDailyReward()
  self:TryAutoCheckIn()
end

function UIRegressActivityRewardDialog:RefreshOneTimeReward()
  local activityData = NetCmdActivityRegressData:GetActivityBackInfo()
  local oneTimeRewardClaimed = activityData.OneTimeRewardClaimed
  setactivewithcheck(self.ui.mTrans_GrpReceived, oneTimeRewardClaimed)
  setactivewithcheck(self.ui.mBtn_Start, not oneTimeRewardClaimed)
  self:ReleaseOneTimeReward()
  self.oneTimeRewardList = {}
  local oneTimeReward = TableData.listBackBoxDatas:GetDataById(1).RewardSort
  local showData = UIUtils.GetKVSortItemTable(oneTimeReward)
  for _, v in pairs(showData) do
    local itemData = TableData.GetItemData(v.id)
    table.insert(self.oneTimeRewardList, {
      data = itemData,
      count = v.num,
      received = oneTimeRewardClaimed
    })
  end
  self.ui.mScrollCtrl.numItems = #self.oneTimeRewardList
  self.ui.mScrollCtrl:Refresh()
end

function UIRegressActivityRewardDialog:RefreshDailyReward()
  self.activityRewardList = {}
  local total = TableData.listBackLoginDatas:GetList()
  for i = 0, total.Count - 1 do
    local data = total[i]
    local showData = UIUtils.GetKVSortItemTable(data.RewardSort)
    for _, v in pairs(showData) do
      local item = UIRegressActivityRewardItem.New()
      item:InitCtrl(self.ui.mScrollList_Daily.transform, self.ui.mScrollList_Daily.childItem)
      local itemData = TableData.GetItemData(v.id)
      item:SetData(itemData, v.num, data.checkin_num)
      if item:SetStatus(data.checkin_num) then
        self.checkInItem = item
      end
      table.insert(self.activityRewardList, item)
      break
    end
  end
end

function UIRegressActivityRewardDialog:TryAutoCheckIn()
  if self.checkInItem ~= nil then
    self.enableRegressReward = false
    self:StopTimer()
    self.timer = TimerSys:DelayCall(1, function()
      self.checkInItem:SendBackCheckIn()
    end)
    self.timer2 = TimerSys:DelayCall(2, function()
      NetCmdActivityRegressData:SendCheckInReward(function(ret)
        if ret == ErrorCodeSuc then
          self.checkInItem:SetStatus()
          self.checkInItem = nil
          UISystem:OpenCommonReceivePanel()
        end
        self.enableRegressReward = true
      end)
    end)
  else
    self.enableRegressReward = true
  end
end

function UIRegressActivityRewardDialog:SendGetRegressReward()
  if not self.enableRegressReward then
    return
  end
  if CS.UIUtils.GetTouchClicked() then
    return
  end
  CS.UIUtils.SetTouchClicked()
  NetCmdActivityRegressData:SendOneTimeReward(function(ret)
    if ret == ErrorCodeSuc then
      UISystem:OpenCommonReceivePanel({
        nil,
        function()
          self:RefreshOneTimeReward()
        end
      })
    end
  end)
end

function UIRegressActivityRewardDialog:OnClose()
  self.checkInItem = nil
  self:StopTimer()
  self:ReleaseOneTimeReward()
  self:ReleaseDailyReward()
  self:UnregisterEvent()
end

function UIRegressActivityRewardDialog:StopTimer()
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  if self.timer2 ~= nil then
    self.timer2:Stop()
    self.timer2 = nil
  end
end

function UIRegressActivityRewardDialog:ReleaseOneTimeReward()
end

function UIRegressActivityRewardDialog:ReleaseDailyReward()
  if self.activityRewardList == nil then
    return
  end
  for i = #self.activityRewardList, 1, -1 do
    local item = self.activityRewardList[i]
    item:OnRelease(true)
    table.remove(self.activityRewardList, i)
  end
  self.activityRewardList = nil
end

function UIRegressActivityRewardDialog:UnregisterEvent()
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnDayChange, self.onRegressReset)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnRegressOver, self.onRegressOver)
end

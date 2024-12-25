require("UI.UIBasePanel")
require("UI.Common.UICommonItem")
HigherPVPSeasonSettlementDialog = class("HigherPVPSeasonSettlementDialog", UIBasePanel)
HigherPVPSeasonSettlementDialog.__index = HigherPVPSeasonSettlementDialog

function HigherPVPSeasonSettlementDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function HigherPVPSeasonSettlementDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.itemList = {}
end

function HigherPVPSeasonSettlementDialog:CleanCloseTimer()
  if self.closeTimer ~= nil then
    self.closeTimer:Stop()
    self.closeTimer = nil
  end
end

function HigherPVPSeasonSettlementDialog:OnInit(root, data)
  self:CleanCloseTimer()
  self.closeTimer = TimerSys:DelayCall(4, function()
    UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
      NetCmdHigherPVPData:CleanSeasonSettleData()
      NetCmdHigherPVPData:MsgCsHighPvpSeasonAcquire()
      UIManager.CloseUI(UIDef.HigherPVPSeasonSettlementDialog)
    end
  end)
  self:RefreshInfo()
end

function HigherPVPSeasonSettlementDialog:RefreshInfo()
  local settleData = NetCmdHigherPVPData:GetHigherPVPSettle()
  self.ui.mText_Num1.text = 0
  self.ui.mText_Num2.text = 0
  self.ui.mText_Num3.text = 0
  if settleData then
    self.ui.mText_Name.text = TableData.GetHintById(290701)
    if settleData.Rank ~= nil then
      if 0 < settleData.Rank.Rank then
        self.ui.mText_Date.text = settleData.Rank.Rank
        self.ui.mText_Num.text = settleData.Rank.Rank
      elseif 0 < settleData.Rank.RankRate then
        self.ui.mText_Date.text = string_format(TableData.GetHintById(290003), settleData.Rank.RankRate)
        self.ui.mText_Num.text = string_format(TableData.GetHintById(290003), settleData.Rank.RankRate)
      else
        self.ui.mText_Date.text = TableData.GetHintById(130006)
        self.ui.mText_Num.text = TableData.GetHintById(130006)
      end
      if settleData.Rank.Points and 0 < settleData.Rank.Points then
        self.ui.mText_Num1.text = settleData.Rank.Points
      end
      if settleData.Rank.SeasonAtk then
        if settleData.Rank.SeasonAtk.Win and 0 < settleData.Rank.SeasonAtk.Win then
          self.ui.mText_Num2.text = settleData.Rank.SeasonAtk.Win
        end
        if settleData.Rank.SeasonAtk.Total and 0 < settleData.Rank.SeasonAtk.Total then
          self.ui.mText_Num3.text = settleData.Rank.SeasonAtk.Total
        end
      end
    else
      self.ui.mText_Date.text = TableData.GetHintById(130006)
      self.ui.mText_Num.text = TableData.GetHintById(130006)
    end
    local planData = NetCmdHigherPVPData:GetPlanData(settleData.PlanId)
    if planData then
      local openTime = CS.CGameTime.ConvertLongToDateTime(planData.OpenTime):ToString("yyyy.MM.dd")
      local closeTime = CS.CGameTime.ConvertLongToDateTime(planData.CloseTime):ToString("yyyy.MM.dd")
      local openTimeAndCloseTime = string_format(TableData.GetHintById(120157), openTime, closeTime)
      self.ui.mText_Time.text = openTimeAndCloseTime
      self.ui.mText_Time1.text = openTimeAndCloseTime
    end
    local rewardList = {}
    for k, v in pairs(settleData.SeasonRewards) do
      local item = {}
      item.id = k
      item.num = v
      table.insert(rewardList, item)
    end
    if 0 < #rewardList then
      for i = 1, #rewardList do
        local itemView = self.itemList[i]
        if itemView == nil then
          itemView = UICommonItem.New()
          itemView:InitCtrl(self.ui.mTrans_Content)
          itemView.mUIRoot.transform:SetAsLastSibling()
          table.insert(self.itemList, itemView)
        end
        itemView:SetItemData(rewardList[i].id, rewardList[i].num, nil, nil, nil, nil, nil, function()
          TipsPanelHelper.OpenUITipsPanel(TableData.GetItemData(rewardList[i].id))
        end)
      end
      setactive(self.ui.mTrans_Reward.gameObject, true)
    else
      setactive(self.ui.mTrans_Reward.gameObject, false)
    end
  end
end

function HigherPVPSeasonSettlementDialog:OnShowStart()
end

function HigherPVPSeasonSettlementDialog:OnShowFinish()
end

function HigherPVPSeasonSettlementDialog:OnTop()
end

function HigherPVPSeasonSettlementDialog:OnBackFrom()
end

function HigherPVPSeasonSettlementDialog:OnClose()
  self:CleanCloseTimer()
end

function HigherPVPSeasonSettlementDialog:OnHide()
end

function HigherPVPSeasonSettlementDialog:OnHideFinish()
end

function HigherPVPSeasonSettlementDialog:OnRelease()
end

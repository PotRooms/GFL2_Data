require("UI.UIBasePanel")
require("UI.HigherPVP.PVPRankRewardItem")
require("UI.Common.UIComTabBtn1ItemV2")
require("UI.HigherPVP.HigherPVPRankInvolvedRewardItem")
HigherPVPRankRewardDialog = class("HigherPVPRankRewardDialog", UIBasePanel)
HigherPVPRankRewardDialog.__index = HigherPVPRankRewardDialog

function HigherPVPRankRewardDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function HigherPVPRankRewardDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.HigherPVPRankRewardDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Close1.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.HigherPVPRankRewardDialog)
  end
  self.curSelectIndex = -1
  self.itemUIList = {}
  self.timesUIList = {}
  self.tabBtnUIList = {}
  self.tabNameList = {
    TableData.GetHintById(290605),
    TableData.GetHintById(290909)
  }
end

function HigherPVPRankRewardDialog:OnInit(root, data)
  self.pvpRewardDataList = NetCmdHigherPVPData:GetRewardDatas()
  self.pvpTimesRewardDataList = NetCmdHigherPVPData:GetTimesRewardDatas()
  setactive(self.ui.mTrans_TabList.gameObject, self.pvpTimesRewardDataList ~= nil and self.pvpTimesRewardDataList.Count > 0)
  local rankRate = NetCmdHigherPVPData:GetSelfRankPercent()
  for i = 1, 2 do
    local item = self.tabBtnUIList[i]
    if item == nil then
      item = UIComTabBtn1ItemV2.New()
      item:InitCtrl(self.ui.mTrans_TabList, {
        index = i,
        name = self.tabNameList[i]
      })
      table.insert(self.tabBtnUIList, item)
    end
    item:SetRedPointVisible(NetCmdHigherPVPData:GetRedByTabIndex(i))
    item:AddClickListener(function()
      self:OnClickItem(i)
    end)
  end
  self:OnClickItem(1)
  if self.pvpRewardDataList ~= nil then
    for i = 1, self.pvpRewardDataList.Count do
      local cell = self.itemUIList[i]
      if cell == nil then
        cell = PVPRankRewardItem.New()
        cell:InitCtrl(self.ui.mTrans_Content)
        table.insert(self.itemUIList, cell)
      end
      cell:SetData(self.pvpRewardDataList[i - 1], rankRate)
    end
  end
  if self.pvpTimesRewardDataList ~= nil then
    for i = 1, self.pvpTimesRewardDataList.Count do
      local timeCell = self.timesUIList[i]
      if timeCell == nil then
        timeCell = HigherPVPRankInvolvedRewardItem.New()
        timeCell:InitCtrl(self.ui.mTrans_Content2)
        table.insert(self.timesUIList, timeCell)
      end
      timeCell:SetData(self.pvpTimesRewardDataList[i - 1])
    end
  end
end

function HigherPVPRankRewardDialog:OnClickItem(index)
  if self.curSelectIndex == index then
    return
  end
  self.curSelectIndex = index
  for k, v in ipairs(self.tabBtnUIList) do
    v:SetBtnInteractable(k ~= index)
  end
  setactive(self.ui.mTrans_RewardList.gameObject, self.curSelectIndex == 1)
  setactive(self.ui.mTrans_InvolvedRewardList.gameObject, self.curSelectIndex == 2)
end

function HigherPVPRankRewardDialog:UpdateRedPoint()
  for i = 1, #self.timesUIList do
    local cell = self.timesUIList[i]
    cell:SetData(self.pvpTimesRewardDataList[i - 1])
  end
  for i = 1, #self.tabBtnUIList do
    local item = self.tabBtnUIList[i]
    item:SetRedPointVisible(NetCmdHigherPVPData:GetRedByTabIndex(i))
  end
end

function HigherPVPRankRewardDialog:OnShowStart()
end

function HigherPVPRankRewardDialog:OnShowFinish()
end

function HigherPVPRankRewardDialog:OnTop()
  self:UpdateRedPoint()
end

function HigherPVPRankRewardDialog:OnBackFrom()
  self:UpdateRedPoint()
end

function HigherPVPRankRewardDialog:OnClose()
  self.curSelectIndex = -1
end

function HigherPVPRankRewardDialog:OnHide()
end

function HigherPVPRankRewardDialog:OnHideFinish()
end

function HigherPVPRankRewardDialog:OnRelease()
end

require("UI.UIBasePanel")
require("UI.DarkZonePanel.UIDarkzoneModeCarrierPanel.Item.UIDarkzoneMapCarrierRewardItem")
require("UI.ActivityTheme.Cafe.ActivityCafeGlobal")
UIDarkzoneCarrierRewardExchangeDialog = class("UIDarkzoneCarrierRewardExchangeDialog", UIBasePanel)
UIDarkzoneCarrierRewardExchangeDialog.__index = UIDarkzoneCarrierRewardExchangeDialog

function UIDarkzoneCarrierRewardExchangeDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIDarkzoneCarrierRewardExchangeDialog:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.data = data
  self.exchangeList = {}
  self:AddBtnListener()
  self:InitContent()
  NetCmdActivityDarkZone:ClearEscortExchangeList()
end

function UIDarkzoneCarrierRewardExchangeDialog:InitContent()
  self:ShowExchange(self.data)
end

function UIDarkzoneCarrierRewardExchangeDialog:ShowExchange()
  for i = 3, 1, -1 do
    local data = TableData.listActivityEscortExchangeByGoodsTypeDatas:GetDataById(i, true)
    if data ~= nil then
      local item = UIDarkzoneMapCarrierRewardItem.New()
      item:InitCtrl(self.ui.mScrollListChild_GrplRewardExchange.childItem, self.ui.mScrollListChild_GrplRewardExchange.transform)
      local itemIdList = data.ItemId
      local flag = item:CreateEscortExchangeList(itemIdList, self.data)
      if flag == 1 then
        item:SetTopText(TableData.GetActivityHint(271011 + i, 2, 2, 7001, 101))
      else
        item:SetTop(false)
      end
      table.insert(self.exchangeList, item)
    end
  end
end

function UIDarkzoneCarrierRewardExchangeDialog:AddBtnListener()
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIDarkzoneCarrierRewardExchangeDialog)
  end
end

function UIDarkzoneCarrierRewardExchangeDialog:GetContainEscortExchange(id)
  for i = 0, self.data.Count - 1 do
    if self.data[i].itemId == id then
      return self.data[i]
    end
  end
  return nil
end

function UIDarkzoneCarrierRewardExchangeDialog:OnShowFinish()
end

function UIDarkzoneCarrierRewardExchangeDialog:OnClose()
  if self.exchangeList then
    for i = 1, #self.exchangeList do
      self.exchangeList[i]:OnRelease()
    end
  end
  if ActivityCafeGlobal.IsNeedOpenMessageBox then
    ActivityCafeGlobal.IsNeedOpenMessageBox = false
    ActivityCafeGlobal.ShowToMainBox()
  end
end

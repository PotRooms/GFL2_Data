require("UI.UIBasePanel")
UIActivityTreasureBpLvBuyDialog = class("UIActivityTreasureBpLvBuyDialog", UIBasePanel)
UIActivityTreasureBpLvBuyDialog.__index = UIActivityTreasureBpLvBuyDialog

function UIActivityTreasureBpLvBuyDialog:ctor(csPanel)
  self.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIActivityTreasureBpLvBuyDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  UIUtils.AddBtnClickListener(self.ui.mBtn_CloseBg.gameObject, function()
    self:CloseSelf()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Close.gameObject, function()
    self:CloseSelf()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Cancel.gameObject, function()
    self:CloseSelf()
  end)
end

function UIActivityTreasureBpLvBuyDialog:CloseSelf()
  UIManager.CloseUI(UIDef.UITreasureBpLvBuyDialog)
end

function UIActivityTreasureBpLvBuyDialog:ConfirmBuy()
end

function UIActivityTreasureBpLvBuyDialog:OnInit(root, data)
  self.id = data.id
  local current = data.currentLv
  local next = current + 1
  self.ui.mText_Before.text = current < 10 and "0" .. current or current
  self.ui.mText_After.text = next < 10 and "0" .. next or next
  local bpId = TableDataBase.listTreasureMainDatas:GetDataById(self.id).BpId
  self.costId = TableDataBase.listTreasureConfigDatas:GetDataById(bpId).ItemlvId
  self.ui.mImg_Icon.sprite = IconUtils.GetItemIconSprite(self.costId)
  local ownNum = NetCmdItemData:GetItemCountById(self.costId)
  self.costNum = TableDataBase.listTreasureConfigDatas:GetDataById(bpId).Price2
  self.enoughToBuy = ownNum >= self.costNum
  self.ui.mText_Cost.text = self.costNum
  self.ui.mText_Cost.color = self.enoughToBuy and ColorUtils.StringToColor("325563") or ColorUtils.RedColor
end

function UIActivityTreasureBpLvBuyDialog:OnBackFrom()
  local ownNum = NetCmdItemData:GetItemCountById(self.costId)
  self.enoughToBuy = ownNum >= self.costNum
  self.ui.mText_Cost.color = self.enoughToBuy and ColorUtils.StringToColor("325563") or ColorUtils.RedColor
end

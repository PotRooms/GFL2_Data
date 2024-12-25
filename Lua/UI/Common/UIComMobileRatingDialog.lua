require("UI.UIBasePanel")
UIComMobileRatingDialog = class("UIComMobileRatingDialog", UIBasePanel)
UIComMobileRatingDialog.__index = UIComMobileRatingDialog

function UIComMobileRatingDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIComMobileRatingDialog:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListener()
  self:InitContent()
end

function UIComMobileRatingDialog:AddBtnListener()
  UIUtils.AddBtnClickListener(self.ui.mBtn_Close.gameObject, function()
    UIManager.CloseUI(UIDef.UIComMobileRatingDialog)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Good.gameObject, function()
    CS.GashaponNetCmdHandler.RequestIOSPreview()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Other.gameObject, function()
    UIManager.CloseUI(UIDef.UIComMobileRatingDialog)
  end)
end

function UIComMobileRatingDialog:InitContent()
  self.ui.mText_TitleText.text = TableData.GetHintById(260127)
  self.ui.mText_Good.text = TableData.GetHintById(260128)
  self.ui.mText_Other.text = TableData.GetHintById(260129)
end

function UIComMobileRatingDialog:OnShowStart()
end

function UIComMobileRatingDialog:OnShowFinish()
end

function UIComMobileRatingDialog:OnClose()
end

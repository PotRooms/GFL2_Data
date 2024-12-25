require("UI.Common.UICommonSimpleView")
require("UI.UIBasePanel")
UIDarkZoneMapDotDialog = class("UIDarkZoneMapDotDialog", UIBasePanel)
UIDarkZoneMapDotDialog.__index = UIDarkZoneMapDotDialog

function UIDarkZoneMapDotDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIDarkZoneMapDotDialog:OnInit(root, data)
  self:SetRoot(root)
  self:InitBaseData()
  self.mData = data
  self.mView:InitCtrl(root, self.ui)
  self:AddBtnListen()
end

function UIDarkZoneMapDotDialog:OnShowStart()
  self:RefreshDialog()
end

function UIDarkZoneMapDotDialog:OnClose()
  self.ui = nil
  self.mView = nil
end

function UIDarkZoneMapDotDialog:OnRelease()
  self.hasCache = false
  self.super.OnRelease(self)
end

function UIDarkZoneMapDotDialog:InitBaseData()
  self.mView = UICommonSimpleView.New()
  self.ui = {}
end

function UIDarkZoneMapDotDialog:AddBtnListen()
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    self:CloseSelf()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpClose.gameObject).onClick = function()
    self:CloseSelf()
  end
end

function UIDarkZoneMapDotDialog:RefreshDialog()
  self.ui.mTextFit_Content.text = self.mData.icon_desc.str
  self.ui.mText_Type.text = self.mData.icon_name.str
  self.ui.mImg_Icon.sprite = IconUtils.GetDarkzoneIcon(self.mData.icon)
end

function UIDarkZoneMapDotDialog:OnShowFinish()
end

function UIDarkZoneMapDotDialog:CloseSelf()
  UIManager.CloseUI(UIDef.UIDarkZoneMapDotDialog)
end

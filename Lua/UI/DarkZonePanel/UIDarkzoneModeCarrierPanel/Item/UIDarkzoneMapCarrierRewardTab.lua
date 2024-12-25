require("UI.UIBaseCtrl")
UIDarkzoneMapCarrierRewardTab = class("UIDarkzoneMapCarrierRewardTab", UIBaseCtrl)
UIDarkzoneMapCarrierRewardTab.__index = UIDarkzoneMapCarrierRewardTab

function UIDarkzoneMapCarrierRewardTab:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function UIDarkzoneMapCarrierRewardTab:InCtrl(prefab, parent, callback, text)
  local obj = instantiate(prefab, parent)
  self:SetRoot(obj.transform)
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
  UIUtils.GetButtonListener(self.ui.mBtn_ComTab1ItemV2.gameObject).onClick = function()
    callback()
  end
  self.ui.mText_Name.text = text
end

function UIDarkzoneMapCarrierRewardTab:SetBtnInteractable(bool)
  self.ui.mBtn_ComTab1ItemV2.interactable = bool
end

function UIDarkzoneMapCarrierRewardTab:OnRelease()
  gfdestroy(self:GetRoot())
end

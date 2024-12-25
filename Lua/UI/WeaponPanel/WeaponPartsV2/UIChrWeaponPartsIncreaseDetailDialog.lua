require("UI.WeaponPanel.Item.ChrWeaponPartsIncreaseDetailItem")
UIChrWeaponPartsIncreaseDetailDialog = class("UIChrWeaponPartsIncreaseDetailDialog", UIBasePanel)
UIChrWeaponPartsIncreaseDetailDialog.__index = UIChrWeaponPartsIncreaseDetailDialog

function UIChrWeaponPartsIncreaseDetailDialog:ctor(csPanel)
  UIChrWeaponPartsIncreaseDetailDialog.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIChrWeaponPartsIncreaseDetailDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.gunWeaponModData = nil
end

function UIChrWeaponPartsIncreaseDetailDialog:OnInit(root, param)
  self.gunWeaponModData = param.gunWeaponModData
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIChrWeaponPartsIncreaseDetailDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpClose.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIChrWeaponPartsIncreaseDetailDialog)
  end
end

function UIChrWeaponPartsIncreaseDetailDialog:OnShowStart()
  self:SetData()
end

function UIChrWeaponPartsIncreaseDetailDialog:OnRecover()
end

function UIChrWeaponPartsIncreaseDetailDialog:OnBackFrom()
end

function UIChrWeaponPartsIncreaseDetailDialog:OnTop()
end

function UIChrWeaponPartsIncreaseDetailDialog:OnShowFinish()
end

function UIChrWeaponPartsIncreaseDetailDialog:OnHide()
end

function UIChrWeaponPartsIncreaseDetailDialog:OnHideFinish()
end

function UIChrWeaponPartsIncreaseDetailDialog:OnClose()
end

function UIChrWeaponPartsIncreaseDetailDialog:OnRelease()
  self.super.OnRelease(self)
end

function UIChrWeaponPartsIncreaseDetailDialog:SetData()
  local parent = self.ui.mScrollListChild_Content
  local map = self.gunWeaponModData.PropertyList
  local index = 1
  for i, v in pairs(map) do
    local propData = i
    local value = v / 10
    local item
    item = ChrWeaponPartsIncreaseDetailItem.New()
    if index < parent.transform.childCount then
      item:InitCtrl(parent, parent.transform:GetChild(index))
    else
      item:InitCtrl(parent, nil)
    end
    item:SetData(propData.show_name.str, value, propData.icon)
    index = index + 1
  end
end

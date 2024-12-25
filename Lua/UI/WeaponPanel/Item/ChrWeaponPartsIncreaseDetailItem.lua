require("UI.UIBaseCtrl")
ChrWeaponPartsIncreaseDetailItem = class("ChrWeaponPartsIncreaseDetailItem", UIBaseCtrl)
ChrWeaponPartsIncreaseDetailItem.__index = ChrWeaponPartsIncreaseDetailItem

function ChrWeaponPartsIncreaseDetailItem:ctor()
end

function ChrWeaponPartsIncreaseDetailItem:InitCtrl(parent, obj)
  local instObj
  if obj == nil then
    local itemPrefab = parent.gameObject:GetComponent(typeof(CS.ScrollListChild))
    instObj = instantiate(itemPrefab.childItem, parent.transform)
  else
    instObj = obj
  end
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  self:SetRoot(instObj.transform)
end

function ChrWeaponPartsIncreaseDetailItem:SetData(text, value, icon)
  local hint = TableData.GetHintById(310057)
  value = math.floor(value) .. "%"
  local txt = string_format(hint, text, value)
  self.ui.mText_Attribute.text = txt
  self.ui.mImg_Icon.sprite = IconUtils.GetAttributeIcon(icon)
end

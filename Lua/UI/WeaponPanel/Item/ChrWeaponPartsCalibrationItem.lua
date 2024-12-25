require("UI.UIBaseCtrl")
ChrWeaponPartsCalibrationItem = class("ChrWeaponPartsCalibrationItem", UIBaseCtrl)
ChrWeaponPartsCalibrationItem.__index = ChrWeaponPartsCalibrationItem

function ChrWeaponPartsCalibrationItem:ctor()
  self.gunWeaponModProperty = nil
  self.callback = nil
  self.isSelected = true
  self.index = -1
  self.isPercent = false
  self.isCalibrationMaxNum = false
end

function ChrWeaponPartsCalibrationItem:InitCtrl(parent, obj)
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

function ChrWeaponPartsCalibrationItem:SetData(data, callback)
  self.gunWeaponModProperty = data
  self.index = self.gunWeaponModProperty.AffixIndex
  self.callback = callback
  self.isPercent = self.gunWeaponModProperty.PropData.show_type == 2
  UIUtils.GetButtonListener(self.ui.mBtn_Root.gameObject).onClick = function()
    self:SetSelect()
  end
  self:SetSelect()
  self:SetGunWeaponModPropertyData()
end

function ChrWeaponPartsCalibrationItem:ResetData(data)
  self.gunWeaponModProperty = data
  self.index = self.gunWeaponModProperty.AffixIndex
  self:SetGunWeaponModPropertyData()
end

function ChrWeaponPartsCalibrationItem:SetGunWeaponModPropertyData()
  self.ui.mText_Type.text = self.gunWeaponModProperty.PropData.show_name.str
  self.ui.mText_Base.text = "+" .. self:GetAndCheckValue(self.gunWeaponModProperty.PropValueWithOutPolarity)
  self.ui.mText_Full.text = "/" .. self:GetAndCheckValue(self.gunWeaponModProperty.MaxValue)
  self.ui.mText_Now.text = "+" .. self:GetAndCheckValue(self.gunWeaponModProperty.Calibration)
  self.isCalibrationMaxNum = false
  local modCalibrationPropertyNumSwitch = CS.GunWeaponModProperty.ModCalibrationPropertyNumSwitch
  local isMaxNum = self.gunWeaponModProperty.CalibrationNum == CS.GunWeaponModProperty.CalibrationMaxNum and modCalibrationPropertyNumSwitch
  local isMaxValue = self.gunWeaponModProperty.IsMaxCalibrationValue
  setactive(self.ui.mText_Num.gameObject, modCalibrationPropertyNumSwitch)
  if modCalibrationPropertyNumSwitch then
    self.ui.mText_Num.text = self.gunWeaponModProperty.CalibrationNum .. "/" .. CS.GunWeaponModProperty.CalibrationMaxNum
  end
  if isMaxNum or isMaxValue then
    self.ui.mText_Num.color = CS.GunWeaponModProperty.CalibrationMaxColor
    self.isCalibrationMaxNum = true
    self.ui.mAnimator_Root:SetBool("Selected", false)
  else
    self.ui.mText_Num.color = CS.GunWeaponModProperty.CalibrationDefaultColor
  end
  self.gunWeaponModProperty:SetTextColor(self.ui.mText_Now)
  self.gunWeaponModProperty:SetCalibrationRange(self.ui.mText_View)
  self.ui.mBtn_Root.enabled = not isMaxValue and not self.isCalibrationMaxNum
  setactive(self.ui.mTrans_IconBg.gameObject, not isMaxValue and not self.isCalibrationMaxNum)
end

function ChrWeaponPartsCalibrationItem:SetSelect()
  local isSelected = not self.isSelected
  self.isSelected = isSelected
  self.ui.mAnimator_Root:SetBool("Selected", isSelected)
  if self.callback ~= nil then
    self.callback(self.index, self.isSelected)
  end
end

function ChrWeaponPartsCalibrationItem:IsCalibrationMaxNum()
  return self.isCalibrationMaxNum
end

function ChrWeaponPartsCalibrationItem:GetAndCheckValue(value)
  if self.isPercent then
    return self:PercentValue(value)
  else
    return value
  end
end

function ChrWeaponPartsCalibrationItem:PercentValue(value)
  value = value / 10
  value = math.floor(value * 10 + 0.5) / 10
  return value .. "%"
end

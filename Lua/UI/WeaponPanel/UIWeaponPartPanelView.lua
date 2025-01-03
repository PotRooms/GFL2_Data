require("UI.UIBaseView")
UIWeaponPartPanelView = class("UIWeaponPartPanelView", UIBaseView)
UIWeaponPartPanelView.__index = UIWeaponPartPanelView

function UIWeaponPartPanelView:ctor()
end

function UIWeaponPartPanelView:__InitCtrl()
  self.mBtn_Close = UIUtils.GetTempBtn(self:GetRectTransform("Root/GrpTop/BtnBack"))
  self.mBtn_CommandCenter = UIUtils.GetTempBtn(self:GetRectTransform("Root/GrpTop/BtnHome"))
  self.mTrans_TabList = self:GetRectTransform("Root/GrpLeft/GrpDetailsList/Content")
  self.mTrans_Detail = self:GetRectTransform("Root/GrpRight/Trans_GrpDetails")
  self.mTrans_Enhance = self:GetRectTransform("Root/GrpRight/Trans_GrpPowerUp")
  self.mTrans_PartInfo = self:GetRectTransform("Root/GrpRight/Trans_GrpDetails/GrpWeaponPartsInfo")
  self.mTrans_EnhaceInfo = self:GetRectTransform("Root/GrpRight/Trans_GrpPowerUp/GrpWeaponPartsInfo")
  self.mText_EquipWeapon = self:GetText("Root/GrpRight/Trans_GrpDetails/GrpTextInfo/Text_Name")
  self.mImage_Icon = self:GetImage("Root/GrpWeaponPartsIcon/Img_WeaponPartsIcon")
  self.mTrans_CostContent = self:GetRectTransform("Root/GrpRight/Trans_GrpPowerUp/Trans_GrpConsume")
  self.mTrans_CostItem = self:GetRectTransform("Root/GrpRight/Trans_GrpPowerUp/Trans_GrpConsume/GrpItem")
  self.mTrans_Weapon = self:GetRectTransform("Root/Trans_GrpEquiped")
  self.mTrans_LevelUp = self:GetRectTransform("Root/GrpRight/Trans_GrpPowerUp/GrpAction/Trans_BtnPowerUp")
  self.mTrans_MaxLevel = self:GetRectTransform("Root/GrpRight/Trans_GrpPowerUp/GrpAction/Trans_TextMax")
  self.mTrans_PartList = self:GetRectTransform("Root/Trans_GrpWeaponPartsList")
  self.mTrans_Mask = self:GetRectTransform("Root/Trans_Mask")
end

function UIWeaponPartPanelView:InitCtrl(root)
  self:SetRoot(root)
  self:__InitCtrl()
end

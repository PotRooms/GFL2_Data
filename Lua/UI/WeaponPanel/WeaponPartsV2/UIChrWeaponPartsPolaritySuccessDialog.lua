UIChrWeaponPartsPolaritySuccessDialog = class("UIChrWeaponPartsPolaritySuccessDialog", UIBasePanel)
UIChrWeaponPartsPolaritySuccessDialog.__index = UIChrWeaponPartsPolaritySuccessDialog

function UIChrWeaponPartsPolaritySuccessDialog:ctor(csPanel)
  UIChrWeaponPartsPolaritySuccessDialog.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIChrWeaponPartsPolaritySuccessDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.gunWeaponModData = nil
  self.lastGunWeaponModData = nil
  self.polarityTagData = nil
  self.showType = {
    Polarity = 1,
    Calibration = 2,
    Decompose = 3
  }
  self.curType = 0
  self.isPolarityAgain = false
end

function UIChrWeaponPartsPolaritySuccessDialog:OnInit(root, param)
  self.ui.mText_Title.text = param.title
  self.gunWeaponModData = param.gunWeaponModData
  self.lastGunWeaponModData = self.gunWeaponModData.LastModData
  self.polarityTagData = self.gunWeaponModData.PolarityTagData
  if param.isPolarityAgain == nil then
    param.isPolarityAgain = false
  end
  self.isPolarityAgain = param.isPolarityAgain
  self.callback = param.callback
  if param.curType == nil then
    self.curType = 1
  else
    self.curType = param.curType
  end
end

function UIChrWeaponPartsPolaritySuccessDialog:OnShowStart()
  self:SetData()
end

function UIChrWeaponPartsPolaritySuccessDialog:OnRecover()
end

function UIChrWeaponPartsPolaritySuccessDialog:OnBackFrom()
end

function UIChrWeaponPartsPolaritySuccessDialog:OnTop()
end

function UIChrWeaponPartsPolaritySuccessDialog:OnShowFinish()
  self.closeTiemr = TimerSys:DelayCall(1.54, function()
    UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
      UIManager.CloseUI(UIDef.UIChrWeaponPartsPolaritySuccessDialog)
    end
    UIUtils.GetButtonListener(self.ui.mBtn_Redo.gameObject).onClick = function()
      local rollBack = function()
        self.mCSPanel:SetUIInteractable(false)
        NetCmdWeaponPartsData:ReqWeaponPartPolarizationRollBack(self.gunWeaponModData.id, true, function(ret)
          if ret == ErrorCodeSuc then
            local hint = TableData.GetHintById(251050)
            CS.PopupMessageManager.PopupPositiveString(hint)
          end
          UIManager.CloseUI(UIDef.UIChrWeaponPartsPolaritySuccessDialog)
          self.mCSPanel:SetUIInteractable(true)
        end)
        self.gunWeaponModData:RollBackPolarity()
      end
      if NetCmdWeaponPartsData:CheckTodayWeaponPartPolarityRollBack() then
        rollBack()
      else
        local todayTipsParam = {}
        todayTipsParam[1] = TableData.GetHintById(251048)
        todayTipsParam[2] = function()
          rollBack()
        end
        todayTipsParam[10] = function()
          NetCmdWeaponPartsData:SetTodayWeaponPartPolarityRollBack()
        end
        todayTipsParam[3] = nil
        todayTipsParam[4] = nil
        todayTipsParam[8] = 251049
        UIManager.OpenUIByParam(UIDef.UIComTodayTipsDialog, todayTipsParam)
      end
    end
    UIUtils.GetButtonListener(self.ui.mBtn_Confirm.gameObject).onClick = function()
      local rollBack = function()
        self.mCSPanel:SetUIInteractable(false)
        NetCmdWeaponPartsData:ReqWeaponPartPolarizationRollBack(self.gunWeaponModData.id, false, function(ret)
          self.mCSPanel:SetUIInteractable(true)
          UIManager.CloseUI(UIDef.UIChrWeaponPartsPolaritySuccessDialog)
        end)
      end
      if NetCmdWeaponPartsData:CheckTodayWeaponPartPolarityRollBack() then
        rollBack()
      else
        local todayTipsParam = {}
        todayTipsParam[1] = TableData.GetHintById(251052)
        todayTipsParam[2] = function()
          rollBack()
        end
        todayTipsParam[10] = function()
          NetCmdWeaponPartsData:SetTodayWeaponPartPolarityRollBack()
        end
        todayTipsParam[3] = nil
        todayTipsParam[4] = nil
        todayTipsParam[8] = 251051
        UIManager.OpenUIByParam(UIDef.UIComTodayTipsDialog, todayTipsParam)
      end
    end
  end)
end

function UIChrWeaponPartsPolaritySuccessDialog:OnHide()
end

function UIChrWeaponPartsPolaritySuccessDialog:OnHideFinish()
end

function UIChrWeaponPartsPolaritySuccessDialog:OnClose()
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = nil
  UIUtils.GetButtonListener(self.ui.mBtn_Confirm.gameObject).onClick = nil
  UIUtils.GetButtonListener(self.ui.mBtn_Redo.gameObject).onClick = nil
  if self.callback ~= nil then
    self.callback()
  end
  if self.closeTiemr ~= nil then
    self.closeTiemr:Stop()
    self.closeTiemr = nil
  end
end

function UIChrWeaponPartsPolaritySuccessDialog:OnRelease()
  self.super.OnRelease(self)
end

function UIChrWeaponPartsPolaritySuccessDialog:SetData()
  local icon = self.gunWeaponModData.icon
  self.ui.mImg_PartsIcon.sprite = IconUtils.GetWeaponPartIcon(icon)
  self.ui.mImg_Quality.color = TableData.GetGlobalGun_Quality_Color2(self.gunWeaponModData.rank, self.ui.mImg_Quality.color.a)
  self.ui.mImg_QualityLine.color = TableData.GetGlobalGun_Quality_Color2(self.gunWeaponModData.rank, self.ui.mImg_QualityLine.color.a)
  setactive(self.ui.mImg_TypeIcon.gameObject, false)
  self.ui.mImg_TypeIcon.sprite = ResSys:GetWeaponPartEffectSprite(self.gunWeaponModData.ModEffectTypeData.icon)
  setactive(self.ui.mTrans_SpIcon.gameObject, self.gunWeaponModData.IsSp)
  setactive(self.ui.mTrans_Fx.gameObject, self.gunWeaponModData.PolarityId ~= 0)
  if self.curType == self.showType.Polarity then
    self:SetSkill()
    self:SetPolarityEffect()
    self:UpdateAction()
    setactive(self.ui.mImg_Icon.gameObject, false)
  elseif self.curType == self.showType.Calibration then
    self:SetCalibrationAttr()
    setactive(self.ui.mImg_Icon.gameObject, true)
    self.ui.mImg_Icon.sprite = IconUtils.GetElementIcon("Icon_Calibration_2")
  elseif self.curType == self.showType.Decompose then
    setactive(self.ui.mImg_Icon.gameObject, true)
    self.ui.mImg_Icon.sprite = IconUtils.GetElementIcon("Icon_Decompose_2")
    self:SetSkill()
    self:SetPolarityEffect()
    self:UpdateAction()
  end
end

function UIChrWeaponPartsPolaritySuccessDialog:SetSkill()
  local tmpParent = self.ui.mTrans_OtherPartsSkillDescribe
  local tmpItem = self.ui.mTrans_PartsSkill1
  local hasAddition = false
  setactive(tmpItem.gameObject, false)
  self.subPropList = CS.GunWeaponModData.SetWeaponPartAttr(self.gunWeaponModData, self.ui.mTrans_Attribute.transform, 0, true, 0)
  if self.subPropList.Count >= 1 then
    self.subPropList[self.subPropList.Count - 1]:ShowLine(false)
  end
  if self.subPropList.Count % 2 == 0 and self.subPropList.Count >= 2 then
    self.subPropList[self.subPropList.Count - 2]:ShowLine(false)
  end
  for i = 0, tmpParent.childCount - 1 do
    setactive(tmpParent:GetChild(i).gameObject, false)
  end
  local index = 1
  local proficiencySkillData = self.gunWeaponModData.ProficiencySkillData
  if proficiencySkillData then
    local item
    if index < tmpParent.childCount then
      item = tmpParent:GetChild(index)
    else
      item = instantiate(tmpItem, tmpParent, false)
    end
    setactive(item.gameObject, true)
    CS.GunWeaponModData.SetProficiencySkill(item, proficiencySkillData.description.str, proficiencySkillData.level)
    index = index + 1
  end
  local gunWeaponModPropertyListWithAddValue = self.gunWeaponModData.GunWeaponModPropertyListWithAddValue
  local hint1 = TableData.GetHintById(220079)
  for i = 0, gunWeaponModPropertyListWithAddValue.Count - 1 do
    local gunWeaponModProperty = gunWeaponModPropertyListWithAddValue[i]
    local item
    if index < tmpParent.childCount then
      item = tmpParent:GetChild(index)
    else
      item = instantiate(tmpItem, tmpParent, false)
    end
    setactive(item.gameObject, true)
    CS.GunWeaponModData.SetGunWeaponModPropertyPolarity(item, gunWeaponModProperty, self.gunWeaponModData)
    index = index + 1
  end
  local hint2 = TableData.GetHintById(250057)
  if 0 < self.gunWeaponModData.AddValue.Length then
    setactive(self.ui.mTrans_GroupSkill.gameObject, true)
    self.ui.mImg_SuitIcon.sprite = IconUtils.GetWeaponPartIconSprite(self.gunWeaponModData.ModPowerData.image, false)
    local text = string_format(hint2, self.gunWeaponModData.ModPowerData.name.str, self.gunWeaponModData.AddLevel)
    self.ui.mTextFit_GroupDescribe.text = text
  else
    setactive(self.ui.mTrans_GroupSkill.gameObject, false)
  end
  local hasAddAttr = false
  local tmpAttrParent = self.ui.mTrans_Attribute.transform
  for i = 0, tmpAttrParent.childCount - 1 do
    if tmpAttrParent:GetChild(i).gameObject.activeSelf then
      hasAddAttr = true
      break
    end
  end
  hasAddition = hasAddAttr or proficiencySkillData ~= nil or 0 < gunWeaponModPropertyListWithAddValue.Count or 0 < self.gunWeaponModData.AddValue.Length
  setactive(self.ui.mTrans_AdditionEffect.gameObject, hasAddition)
end

function UIChrWeaponPartsPolaritySuccessDialog:SetPolarityEffect()
  if self.ui.mTrans_Fx.transform.childCount > 0 then
    ResourceDestroy(self.ui.mTrans_Fx.transform:GetChild(0).gameObject)
  end
  local fxGameObject = ResSys:GetUICharacterEffect("UI_PolarityIcon_Normal")
  self.fxGameObject = fxGameObject
  if self.fxGameObject == nil then
    return
  end
  fxGameObject.transform:SetParent(self.ui.mTrans_Fx.transform, false)
end

function UIChrWeaponPartsPolaritySuccessDialog:OnRelease()
  if self.fxGameObject == nil then
    return
  end
  ResourceManager:DestroyInstance(self.fxGameObject)
end

function UIChrWeaponPartsPolaritySuccessDialog:UpdateAction()
  setactive(self.ui.mBtn_Confirm.transform.parent.gameObject, self.isPolarityAgain)
  setactive(self.ui.mBtn_Redo.transform.parent.gameObject, self.isPolarityAgain)
  self.ui.mBtn_Close.enabled = not self.isPolarityAgain
  self.ui.mTrans_TextNext.enabled = not self.isPolarityAgain
end

function UIChrWeaponPartsPolaritySuccessDialog:SetCalibrationAttr()
  self.subPropList = CS.GunWeaponModData.SetWeaponPartCalibrationAttr(self.gunWeaponModData, self.ui.mTrans_Attribute.transform)
  setactive(self.ui.mTrans_AdditionEffect.gameObject, true)
  setactive(self.ui.mTrans_Attribute.gameObject, true)
  setactive(self.ui.mTrans_OtherPartsSkillDescribe.gameObject, false)
  if self.subPropList.Count % 2 == 0 and self.subPropList.Count >= 2 then
    self.subPropList[self.subPropList.Count - 2]:ShowLine(false)
  end
end

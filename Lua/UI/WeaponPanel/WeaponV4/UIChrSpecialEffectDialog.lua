UIChrSpecialEffectDialog = class("UIChrSpecialEffectDialog", UIBasePanel)
UIChrSpecialEffectDialog.__index = UIChrSpecialEffectDialog

function UIChrSpecialEffectDialog:ctor(csPanel)
  UIChrSpecialEffectDialog.super:ctor(csPanel)
  csPanel.Is3DPanel = true
  csPanel.Type = UIBasePanelType.Dialog
end

function UIChrSpecialEffectDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.isGroupSkillActive = false
end

function UIChrSpecialEffectDialog:OnInit(root, param)
  self.weaponCmdData = param.weaponCmdData
end

function UIChrSpecialEffectDialog:OnShowStart()
  self:SetWeaponData()
end

function UIChrSpecialEffectDialog:OnRecover()
end

function UIChrSpecialEffectDialog:OnBackFrom()
end

function UIChrSpecialEffectDialog:OnTop()
end

function UIChrSpecialEffectDialog:OnShowFinish()
  TimerSys:DelayCall(0.3, function()
    UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
      UIManager.CloseUI(UIDef.UIChrSpecialEffectDialog)
    end
    UIUtils.GetButtonListener(self.ui.mBtn_GrpClose.gameObject).onClick = function()
      UIManager.CloseUI(UIDef.UIChrSpecialEffectDialog)
    end
  end)
end

function UIChrSpecialEffectDialog:OnHide()
end

function UIChrSpecialEffectDialog:OnHideFinish()
end

function UIChrSpecialEffectDialog:OnClose()
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = nil
  UIUtils.GetButtonListener(self.ui.mBtn_GrpClose.gameObject).onClick = nil
end

function UIChrSpecialEffectDialog:OnRelease()
  self.super.OnRelease(self)
end

function UIChrSpecialEffectDialog:SetWeaponData()
  self:UpdateWeaponSkills()
end

function UIChrSpecialEffectDialog:UpdateWeaponSkills()
  local weaponSkillDatas = self.weaponCmdData.WeaponSkillDatas
  local tmpParent = self.ui.mTrans_Specific
  if weaponSkillDatas == nil or weaponSkillDatas.Count == 0 then
    setactive(self.ui.mTrans_None.gameObject, true)
    setactive(tmpParent.gameObject, false)
    return
  end
  setactive(self.ui.mTrans_None.gameObject, false)
  setactive(tmpParent.gameObject, true)
  local tmpItem = self.ui.mTrans_Specific1
  for i = 0, weaponSkillDatas.Count - 1 do
    local tmpObj
    if tmpParent.childCount < i + 1 then
      tmpObj = instantiate(tmpItem.gameObject, tmpParent)
    else
      tmpObj = tmpParent:GetChild(i).gameObject
    end
    local ui = {}
    self:LuaUIBindTable(tmpObj, ui)
    local skillDes = self.weaponCmdData:FormatSkillDesc(weaponSkillDatas[i].id)
    ui.mText_Specific.text = skillDes
    setactive(ui.mTrans_ImgLine.gameObject, i ~= weaponSkillDatas.Count - 1)
  end
end

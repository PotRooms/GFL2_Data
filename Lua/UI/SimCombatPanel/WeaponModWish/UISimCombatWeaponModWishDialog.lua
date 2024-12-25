require("UI.Common.UICommonSimpleView")
require("UI.SimCombatPanel.WeaponModWish.UISimCombatWeaponModWishSelectItem")
require("UI.UIBasePanel")
UISimCombatWeaponModWishDialog = class("UISimCombatWeaponModWishDialog", UIBasePanel)
UISimCombatWeaponModWishDialog.__index = UISimCombatWeaponModWishDialog

function UISimCombatWeaponModWishDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UISimCombatWeaponModWishDialog:OnInit(root, data)
  self:SetRoot(root)
  self:InitBaseData()
  self.mview:InitCtrl(root, self.ui)
  self:AddBtnListen()
  self.simCombatData = TableData.listSimCombatResourceDatas:GetDataById(data[0])
  self.stageData = TableData.listStageDatas:GetDataById(data[0])
  self.confirmFunction = data[1]
end

function UISimCombatWeaponModWishDialog:OnShowStart()
  self.wishSelectItem:SetData(self.simCombatData)
end

function UISimCombatWeaponModWishDialog:OnTop()
  self:RefreshTabItem()
end

function UISimCombatWeaponModWishDialog:OnBackForm()
  self:RefreshTabItem()
end

function UISimCombatWeaponModWishDialog:CloseFunction()
  UIManager.CloseUI(UIDef.UISimCombatWeaponModWishDialog)
end

function UISimCombatWeaponModWishDialog:OnClose()
  self.super.OnClose(self)
  self.ui = nil
  self.mview = nil
  self.simCombatData = nil
  self.wishSelectItem:OnRelease()
  self.wishSelectItem = nil
end

function UISimCombatWeaponModWishDialog:OnRelease()
  self.super.OnRelease(self)
end

function UISimCombatWeaponModWishDialog:InitBaseData()
  self.mview = UICommonSimpleView.New()
  self.ui = {}
  self.wishSelectItem = UISimCombatWeaponModWishSelectItem.New()
  self.wishSelectItem:InitCtrl(self.mUIRoot)
end

function UISimCombatWeaponModWishDialog:AddBtnListen()
  local f = function()
    self:CloseFunction()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BGClose.gameObject).onClick = f
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = f
  UIUtils.GetButtonListener(self.ui.mBtn_Cancel.gameObject).onClick = f
  UIUtils.GetButtonListener(self.ui.mBtn_Confirm.gameObject).onClick = function()
    self:StartBattle()
  end
end

function UISimCombatWeaponModWishDialog:RefreshTabItem()
end

function UISimCombatWeaponModWishDialog:StartBattle()
  if not TipsManager.CheckStaminaIsEnoughOnly(self.stageData.stamina_cost) then
    return
  end
  self.ui.mBtn_Confirm.interactable = false
  NetCmdSimulateBattleData:SendSimCombatWeaponModAssignedDrop(self.stageData.id, self.stageData.type, self.wishSelectItem.selectSuitID, function()
    self.ui.mBtn_Confirm.interactable = true
    self:CloseFunction()
    PlayerPrefs.SetInt(AccountNetCmdHandler:GetUID() .. "WeaponModWishSelect" .. self.simCombatData.sim_type, self.wishSelectItem.selectSuitID)
    self.confirmFunction()
  end)
end

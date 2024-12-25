require("UI.SimCombatPanel.ResourcesCombat.UISimCombatResourcePanelBase")
UISimCombatWeaponExpPanel = class("UISimCombatWeaponExpPanel", UISimCombatResourcePanelBase)

function UISimCombatWeaponExpPanel:OnInit(root, data, behaviourId)
  local enumId = LuaUtils.EnumToInt(StageType.WeaponExpStage)
  self.simEntranceId = enumId
  self.super.OnInit(self, root, data, behaviourId)
end

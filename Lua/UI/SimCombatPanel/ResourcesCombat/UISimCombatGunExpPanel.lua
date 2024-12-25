require("UI.SimCombatPanel.ResourcesCombat.UISimCombatResourcePanelBase")
UISimCombatGunExpPanel = class("UISimCombatGunExpPanel", UISimCombatResourcePanelBase)

function UISimCombatGunExpPanel:OnInit(root, data, behaviourId)
  local enumId = LuaUtils.EnumToInt(StageType.ExpStage)
  self.simEntranceId = enumId
  self.super.OnInit(self, root, data, behaviourId)
end

require("UI.SimCombatPanel.ResourcesCombat.UISimCombatResourcePanelBase")
UISimCombatGoldPanel = class("UISimCombatGoldPanel", UISimCombatResourcePanelBase)

function UISimCombatGoldPanel:OnInit(root, data, behaviourId)
  local enumId = LuaUtils.EnumToInt(StageType.CashStage)
  self.simEntranceId = enumId
  self.super.OnInit(self, root, data, behaviourId)
end

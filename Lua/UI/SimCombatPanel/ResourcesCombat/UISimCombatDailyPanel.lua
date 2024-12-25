require("UI.SimCombatPanel.ResourcesCombat.UISimCombatResourcePanelBase")
UISimCombatDailyPanel = class("UISimCombatDailyPanel", UISimCombatResourcePanelBase)

function UISimCombatDailyPanel:OnInit(root, data, behaviourId)
  local enumId = LuaUtils.EnumToInt(StageType.DailyStage)
  self.simEntranceId = enumId
  self.super.OnInit(self, root, data, behaviourId)
end

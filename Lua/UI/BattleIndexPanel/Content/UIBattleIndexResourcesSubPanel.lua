UIBattleIndexResourcesSubPanel = class("UIBattleIndexResourcesSubPanel", UIBaseView)
UIBattleIndexResourcesSubPanel.numStr = {
  "987.19054.30",
  "554.26543.25",
  "715.32467.64",
  "428.49359.96",
  "038.80383.73",
  "124.61712.62"
}
UIBattleIndexResourcesSubPanel.CurResourcesSubIndex = 0

function UIBattleIndexResourcesSubPanel:InitCtrl(root, parentPanel)
  self.ui = UIUtils.GetUIBindTable(root)
  self:SetRoot(root)
  self.parentPanel = parentPanel
  
  function self.ui.mVirtualList.itemCreated(renderData)
    local item = self:itemProvider(renderData)
    return item
  end
  
  function self.ui.mVirtualList.itemRenderer(...)
    self:itemRenderer(...)
  end
end

function UIBattleIndexResourcesSubPanel:OnShowStart()
  self:Refresh()
end

function UIBattleIndexResourcesSubPanel:OnBackFrom()
  self:Refresh()
end

function UIBattleIndexResourcesSubPanel:OnRecover()
end

function UIBattleIndexResourcesSubPanel:Refresh()
  self.cardDataList = self:getCardDataList()
  if not self.cardDataList or self.cardDataList.Count == 0 then
    return
  end
  self.ui.mVirtualList.numItems = self.cardDataList.Count
  self.ui.mVirtualList:Refresh()
  self.timer = TimerSys:DelayFrameCall(3, function()
    self.ui.mVirtualList:ScrollTo(UIBattleIndexResourcesSubPanel.CurResourcesSubIndex - 1)
  end)
end

function UIBattleIndexResourcesSubPanel:OnClose()
end

function UIBattleIndexResourcesSubPanel:OnRelease()
  self.ui = nil
  self.parentPanel = nil
  self.cardDataList = nil
end

function UIBattleIndexResourcesSubPanel:getCardDataList()
  local simCombatEntranceDataList = TableData.GetStageIndexSimResourcesList()
  if not simCombatEntranceDataList then
    return
  end
  return simCombatEntranceDataList
end

function UIBattleIndexResourcesSubPanel:itemProvider(renderData)
  local card = UIBattleIndexResourcesCard.New()
  card:InitCtrlWithoutInstance(renderData.gameObject.transform)
  renderData.data = card
end

function UIBattleIndexResourcesSubPanel:itemRenderer(index, renderData)
  local slotData = self.cardDataList[index]
  local card = renderData.data
  card:SetData(slotData, index + 1)
  card:SetNumShow(self.numStr[index + 1])
  card:Refresh()
  card:AddClickListener(function(tempSimCombatEntranceData, _index)
    self:onClickCard(tempSimCombatEntranceData, _index)
  end)
end

function UIBattleIndexResourcesSubPanel:onClickCard(simCombatEntranceData, index)
  if TipsManager.NeedLockTips(simCombatEntranceData.unlock) then
    return
  end
  self:openSimCombatUI(simCombatEntranceData.id)
  UIBattleIndexResourcesSubPanel.CurResourcesSubIndex = index
end

function UIBattleIndexResourcesSubPanel:openSimCombatUI(simId)
  local stageType = StageType.__CastFrom(simId)
  if stageType == StageType.CashStage then
    UISystem:OpenUI(CS.GF2.UI.enumUIPanel.UISimCombatGoldPanel)
  elseif stageType == StageType.ExpStage then
    UISystem:OpenUI(CS.GF2.UI.enumUIPanel.UISimCombatGunExpPanel)
  elseif stageType == StageType.WeaponExpStage then
    UISystem:OpenUI(CS.GF2.UI.enumUIPanel.UISimCombatWeaponExpPanel)
  elseif stageType == StageType.DailyStage then
    UISystem:OpenUI(CS.GF2.UI.enumUIPanel.UISimCombatDailyPanel)
  elseif stageType == StageType.WeaponModStage then
    UISystem:OpenUI(CS.GF2.UI.enumUIPanel.UISimCombatWeaponModPanel)
  end
end

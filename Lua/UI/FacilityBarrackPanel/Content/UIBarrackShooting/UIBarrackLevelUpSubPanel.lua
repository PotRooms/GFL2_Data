require("UI.FacilityBarrackPanel.Content.UIBarrackShooting.UIBarrackTargetLevelSlot")
require("UI.FacilityBarrackPanel.Content.UIBarrackShooting.UITrainingSkipPanel")
require("UI.UniTopbar.Item.ResourcesCommonItem")
UIBarrackLevelUpSubPanel = class("UIBarrackLevelUpSubPanel", UIBaseCtrl)

function UIBarrackLevelUpSubPanel:ctor(root, trainingPanel)
  self.ui = UIUtils.GetUIBindTable(root)
  self:SetRoot(root)
  self.trainingPanel = trainingPanel
  UIUtils.AddBtnClickListener(self.ui.mScrollListChild_BtnConfirm.gameObject, function()
    self:onClickStartTraining()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_ConsumeItem.gameObject, function()
    local itemData = TableData.GetItemData(25)
    TipsPanelHelper.OpenUITipsPanel(itemData, 0, true)
  end)
  self.ui.mScrollRectWrap:Init()
  
  function self.onIndexChangedCallback(index)
    self:onIndexChanged(index)
  end
  
  self.ui.mScrollRectWrap:OnIndexChanged("+", self.onIndexChangedCallback)
  self.isInTraining = false
end

function UIBarrackLevelUpSubPanel:SetData(gunCmdData)
  self.gunCmdData = gunCmdData
end

function UIBarrackLevelUpSubPanel:OnRelease()
  self.gunCmdData = nil
  self:ReleaseCtrlTable(self.emptyTopSlotTable, true)
  self:ReleaseCtrlTable(self.slotTable, true)
  self:ReleaseCtrlTable(self.emptyBottomSlotTable, true)
  self.ui.mScrollRectWrap:OnIndexChanged("-", self.onIndexChangedCallback)
  self.onStartTimelineCallback = nil
  self.ui = nil
  self.super.OnRelease(self)
end

function UIBarrackLevelUpSubPanel:SetVisible(visible)
  local go = self:GetRoot().gameObject
  if go.activeSelf == visible then
    return
  end
  setactive(go, visible)
  if visible then
    self:onShow()
  else
    self:onHide()
  end
end

function UIBarrackLevelUpSubPanel:Refresh()
  self:ReleaseCtrlTable(self.emptyTopSlotTable, true)
  self:ReleaseCtrlTable(self.slotTable, true)
  self:ReleaseCtrlTable(self.emptyBottomSlotTable, true)
  if not self.gunCmdData then
    return
  end
  local slotCount = self.gunCmdData.MaxGunLevel - self.gunCmdData.level
  self.emptyTopSlotTable = self:createEmptySlot(1, 115)
  self.slotTable = self:createTargetLevelSlot(slotCount)
  self.emptyBottomSlotTable = self:createEmptySlot(1, 95)
  LayoutRebuilder.ForceRebuildLayoutImmediate(self.ui.mScrollListChild_Content.transform)
  local targetLevel = self:getMaxTargetLevel()
  local slotIndex = targetLevel - self.gunCmdData.level
  TimerSys:DelayFrameCall(10, function()
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.ui.mScrollListChild_Content.transform)
    gfdebug("DelayFrameCall \231\155\174\230\160\135\231\173\137\231\186\167\239\188\154" .. targetLevel .. "    SlotIndex: " .. slotIndex - 1)
    self.ui.mScrollRectWrap:MoveToCenter(slotIndex - 1, false)
  end)
  self.ui.mScrollListChild_BtnConfirm.interactable = true
end

function UIBarrackLevelUpSubPanel:IsInTraining()
  return self.isInTraining
end

function UIBarrackLevelUpSubPanel:IsVisible()
  local root = self:GetRoot()
  if root == nil then
    return false
  end
  return root.gameObject.activeSelf
end

function UIBarrackLevelUpSubPanel:AddStartTimelineListener(callback)
  self.onStartTimelineCallback = callback
end

function UIBarrackLevelUpSubPanel:onShow()
  self:Refresh()
  self:CheckSpecialVoidScene()
end

function UIBarrackLevelUpSubPanel:CheckSpecialVoidScene()
  BarrackHelper.SceneMgr:CheckVoidSpace()
end

function UIBarrackLevelUpSubPanel:onHide()
  self:ReleaseCtrlTable(self.emptyTopSlotTable, true)
  self:ReleaseCtrlTable(self.slotTable, true)
  self:ReleaseCtrlTable(self.emptyBottomSlotTable, true)
end

function UIBarrackLevelUpSubPanel:onClickStartTraining()
  local slot = self:getFirstFocusedTargetLevelSlot()
  if not slot then
    gferror("\230\178\161\230\156\137\232\129\154\231\132\166\231\154\132Slot?, \233\129\135\229\136\176\232\175\183\232\129\148\231\179\187\231\168\139\229\186\143!!!!")
    local targetLevel = self:getMaxTargetLevel()
    local slotIndex = targetLevel - self.gunCmdData.level
    self:focusSlot(slotIndex)
    return
  end
  local targetLv = slot:GetLevel()
  local haveCount, cost = self:getItemEnoughInfo(targetLv)
  cost = cost - self.gunCmdData.Exp
  if haveCount < cost then
    local itemData = TableData.listItemDatas:GetDataById(GlobalConfig.GunExpItem)
    TipsPanelHelper.OpenUITipsPanel(itemData, 0, true)
    return
  end
  self.ui.mScrollListChild_BtnConfirm.interactable = false
  NetCmdTrainGunData:SendCmdLevelUp(self.gunCmdData.id, targetLv, function(ret)
    if ret ~= ErrorCodeSuc then
      self.ui.mScrollListChild_BtnConfirm.interactable = true
      return
    end
    if AccountNetCmdHandler.BarrackSkip == 0 then
      local isDayFirst = FacilityBarrackGlobal.IsTodayFirstWatchLevelUpTimeline(self.gunCmdData.id)
      if isDayFirst then
        self:levelUpWithTrain()
      else
        self:levelUpWithoutTrain()
      end
    elseif AccountNetCmdHandler.BarrackSkip == 1 then
      self:levelUpWithoutTrain()
    elseif AccountNetCmdHandler.BarrackSkip == 2 then
      self:levelUpWithTrain()
    else
      gferror("onClickStartTraining AccountNetCmdHandler.BarrackSkip \230\156\170\229\174\154\228\185\137\231\154\132\231\177\187\229\158\139" .. AccountNetCmdHandler.BarrackSkip)
    end
    if self.onStartTimelineCallback then
      self.onStartTimelineCallback()
    end
  end)
end

function UIBarrackLevelUpSubPanel:levelUpWithoutTrain()
  local callback = function(phaseType, timingType)
    local enumTimingType = CS.BarrackTimelineManager.TimingType
    local enumPhaseType = CS.BarrackTrainingTimelineBase.PhaseType
    if phaseType == enumPhaseType.Ending then
      if timingType == enumTimingType.Started then
        local param = {
          GunId = self.gunCmdData.id,
          OnCloseCallback = function()
            self.trainingPanel:onTimelineEnd()
            self.isInTraining = false
            BarrackHelper.TimelineMgr:Resume()
          end
        }
        UIManager.OpenUIByParam(UIDef.UIBarrackLevelUpFinishDialog, param)
      elseif timingType == enumTimingType.WillEnd then
      elseif timingType == enumTimingType.LastFrame then
      end
    elseif phaseType ~= enumPhaseType.EndingIdle or timingType == enumTimingType.Started then
    elseif timingType == enumTimingType.WillEnd then
    elseif timingType == enumTimingType.LastFrame then
    end
  end
  self.isInTraining = true
  BarrackHelper.TimelineMgr:PlayLevelUpTimelineWithoutTrain(self.gunCmdData, callback)
end

function UIBarrackLevelUpSubPanel:levelUpWithTrain()
  local callback = function(phaseType, timingType)
    local enumTimingType = CS.BarrackTimelineManager.TimingType
    local enumPhaseType = CS.BarrackTrainingTimelineBase.PhaseType
    if phaseType == enumPhaseType.EnemyEntry then
      if timingType == enumTimingType.Started then
      elseif timingType == enumTimingType.WillEnd then
      elseif timingType == enumTimingType.LastFrame then
      end
    elseif phaseType == enumPhaseType.Training then
      if timingType == enumTimingType.Started then
        if not FacilityBarrackGlobal.IsFirstWatchingLevelUpTimeline(self.gunCmdData.id) then
          local param = {
            GunId = self.gunCmdData.id,
            TrainingType = UITrainingSkipPanel.TrainingType.LevelUp,
            OnClickSkipCallback = function()
              self:onClickSkip()
            end
          }
          UIManager.OpenUIByParam(UIDef.UITrainingSkipPanel, param)
        end
      elseif timingType == enumTimingType.WillEnd then
        local isOpen = UISystem:PanelIsOpen(UIDef.UITrainingSkipPanel)
        if isOpen then
          UIManager.CloseUI(UIDef.UITrainingSkipPanel)
        end
      elseif timingType == enumTimingType.LastFrame then
      end
    elseif phaseType == enumPhaseType.Ending then
      if timingType == enumTimingType.Started then
        local param = {
          GunId = self.gunCmdData.id,
          OnCloseCallback = function()
            FacilityBarrackGlobal.WatchedLevelUpTimeline(self.gunCmdData.id)
            self.trainingPanel:onTimelineEnd()
            self.isInTraining = false
            BarrackHelper.TimelineMgr:Resume()
          end
        }
        UIManager.OpenUIByParam(UIDef.UIBarrackLevelUpFinishDialog, param)
      elseif timingType == enumTimingType.WillEnd then
      elseif timingType == enumTimingType.LastFrame then
      end
    elseif phaseType ~= enumPhaseType.EndingIdle or timingType == enumTimingType.Started then
    elseif timingType == enumTimingType.WillEnd then
    elseif timingType == enumTimingType.LastFrame then
    end
  end
  self.isInTraining = true
  BarrackHelper.TimelineMgr:PlayLevelUpTimeline(self.gunCmdData, callback)
end

function UIBarrackLevelUpSubPanel:createTargetLevelSlot(count)
  local tempTable = {}
  for i = 1, count do
    local template = self.ui.mScrollListChild_Content.childItem
    local slot = UIBarrackTargetLevelSlot.New(instantiate(template, self.ui.mScrollListChild_Content.transform))
    slot:SetData(i, self.gunCmdData.level + i)
    table.insert(tempTable, slot)
  end
  return tempTable
end

function UIBarrackLevelUpSubPanel:createEmptySlot(count, height)
  local tempTable = {}
  for i = 1, count do
    local template = self.ui.mScrollListChild_Content.childItem
    local slot = UIBarrackTargetLevelSlot.New(instantiate(template, self.ui.mScrollListChild_Content.transform))
    slot:SetData(-1, -1)
    slot:SetAlpha(0)
    slot:SetSlotHeight(height)
    table.insert(tempTable, slot)
  end
  return tempTable
end

function UIBarrackLevelUpSubPanel:focusSlot(targetIndex)
  if not targetIndex or targetIndex == 0 then
    return
  end
  if targetIndex < 1 or targetIndex > #self.slotTable then
    return
  end
  local focusedSlot = self:getFirstFocusedTargetLevelSlot()
  local preIndex = -1
  if focusedSlot then
    preIndex = focusedSlot:GetIndex()
    if targetIndex == preIndex then
      return
    end
    focusedSlot:LoseFocus()
  end
  local targetSlot = self.slotTable[targetIndex]
  if targetSlot then
    targetSlot:Focus()
    self:onFocusSlotChanged(preIndex, targetSlot:GetIndex())
  end
end

function UIBarrackLevelUpSubPanel:onFocusSlotChanged(preIndex, curIndex)
  self:refreshItemCount(self.gunCmdData.level + curIndex)
  self:refreshBtnState(self.gunCmdData.level + curIndex)
end

function UIBarrackLevelUpSubPanel:refreshBtnState(targetLv)
  local canLevelUp = NetCmdTrainGunData:IsCanUpgradableToTargetLevel(self.gunCmdData.id, targetLv, false)
  setactive(self.ui.mScrollListChild_BtnConfirm, canLevelUp)
  setactive(self.ui.mTrans_Locked, not canLevelUp)
end

function UIBarrackLevelUpSubPanel:RefreshItemCountByCurFocusLevel()
  local targetSlot = self:getFirstFocusedTargetLevelSlot()
  if not targetSlot then
    gferror("RefreshItemCountByCurFocusLevel \230\178\161\230\156\137\233\128\137\228\184\173\231\154\132Slot?")
    return
  end
  self:refreshItemCount(self.gunCmdData.level + targetSlot:GetIndex())
end

function UIBarrackLevelUpSubPanel:refreshItemCount(targetLevel)
  local haveCount, cost = self:getItemEnoughInfo(targetLevel)
  cost = cost - self.gunCmdData.Exp
  local haveDigit = CS.LuaUIUtils.GetMaxNumberText(haveCount)
  local costDigit = CS.LuaUIUtils.GetMaxNumberText(cost)
  if haveCount < cost then
    self.ui.mText_ItemNum.text = "<color=#FF5E41>" .. haveDigit .. "</color>/" .. costDigit
  else
    self.ui.mText_ItemNum.text = haveDigit .. "/" .. costDigit
  end
end

function UIBarrackLevelUpSubPanel:getItemEnoughInfo(targetLevel)
  local haveCount = NetCmdItemData:GetItemCount(GlobalConfig.GunExpItem)
  local cost = 0
  for i = self.gunCmdData.level + 1, targetLevel do
    local gunLevelExpData = TableData.listGunLevelExpDatas:GetDataById(i)
    if gunLevelExpData then
      cost = cost + gunLevelExpData.exp
    end
  end
  return haveCount, cost
end

function UIBarrackLevelUpSubPanel:getFirstFocusedTargetLevelSlot()
  for i, slot in ipairs(self.slotTable) do
    if slot:IsFocused() then
      return slot
    end
  end
  return nil
end

function UIBarrackLevelUpSubPanel:getMaxTargetLevel()
  local maxUpgradableLevel = NetCmdTrainGunData:GetMaxUpgradableLevel(self.gunCmdData.id)
  if maxUpgradableLevel == self.gunCmdData.level then
    return self.gunCmdData.level + 1
  else
    return maxUpgradableLevel
  end
  return maxTargetLevel
end

function UIBarrackLevelUpSubPanel:onIndexChanged(index)
  gfdebug("onIndexChanged" .. tostring(index))
  self:focusSlot(index + 1)
end

function UIBarrackLevelUpSubPanel:onClickSkip()
  BarrackHelper.TimelineMgr:JumpToLastFrameInCurTimeline()
end

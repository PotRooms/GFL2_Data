require("UI.Common.UICommonItem")
require("UI.FacilityBarrackPanel.Item.ComAttributeDetailItem")
require("UI.UniTopbar.Item.ResourcesCommonItem")
UIBarrackBreakSubPanel = class("UIBarrackBreakSubPanel", UIBaseCtrl)

function UIBarrackBreakSubPanel:ctor(root, trainingPanel)
  self.ui = UIUtils.GetUIBindTable(root)
  self:SetRoot(root)
  self.trainingPanel = trainingPanel
  UIUtils.AddBtnClickListener(self.ui.mScrollListChild_BtnConfirm.gameObject, function()
    self:onClickStartBreak()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_ConsumeItem.gameObject, function()
    local itemData = TableData.GetItemData(2)
    TipsPanelHelper.OpenUITipsPanel(itemData, 0, true)
  end)
  self.isInTraining = false
  self.costItemTable = {}
end

function UIBarrackBreakSubPanel:SetData(gunCmdData)
  self.gunCmdData = gunCmdData
end

function UIBarrackBreakSubPanel:OnRelease()
  self.gunCmdData = nil
  self:ReleaseCtrlTable(self.costItemTable, true)
  self:ReleaseCtrlTable(self.propertyItemTable, true)
  self.onStartTimelineCallback = nil
  self.ui = nil
  self.super.OnRelease(self)
end

function UIBarrackBreakSubPanel:SetVisible(visible)
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

function UIBarrackBreakSubPanel:Refresh()
  self:ReleaseCtrlTable(self.costItemTable, true)
  self:ReleaseCtrlTable(self.propertyItemTable, true)
  self.ui.mText_NumAfter.text = tostring(self.gunCmdData.nextGunClass.GunLevelMax)
  self:refreshAllProperty()
  self:refreshItemCost()
  self:refreshBtnRedPoint()
  self.ui.mScrollListChild_BtnConfirm.interactable = true
end

function UIBarrackBreakSubPanel:IsInTraining()
  return self.isInTraining
end

function UIBarrackBreakSubPanel:IsVisible()
  local root = self:GetRoot()
  if root == nil then
    return false
  end
  return root.gameObject.activeSelf
end

function UIBarrackBreakSubPanel:AddStartTimelineListener(callback)
  self.onStartTimelineCallback = callback
end

function UIBarrackBreakSubPanel:onShow()
  self:Refresh()
  self:CheckSpecialVoidScene()
end

function UIBarrackBreakSubPanel:CheckSpecialVoidScene()
  BarrackHelper.SceneMgr:CheckVoidSpace()
end

function UIBarrackBreakSubPanel:PlayBreakAudio()
  if self.gunCmdData ~= nil then
    local clothAudio = TableData.listAudioQuoteClothesDatas:GetDataById(self.gunCmdData.model_id)
    if clothAudio ~= nil then
      local voiceConfig = TableData.listAudioVoiceConfigDatas:GetDataById(clothAudio.audio_voice)
      local classLevel = self.gunCmdData.curGunClass.class_level
      if voiceConfig ~= nil and 1 < classLevel and voiceConfig.Sys_Break_id.Length > classLevel - 2 then
        AudioUtils.PlayCommonAudio(voiceConfig.Sys_Break_id[classLevel - 2])
      end
    end
  end
end

function UIBarrackBreakSubPanel:onHide()
  self:ReleaseCtrlTable(self.costItemTable, true)
  self:ReleaseCtrlTable(self.propertyItemTable, true)
end

function UIBarrackBreakSubPanel:onClickStartBreak()
  local itemId = self:getNotEnoughItemId()
  if itemId ~= 0 then
    local itemData = TableData.listItemDatas:GetDataById(itemId)
    TipsPanelHelper.OpenUITipsPanel(itemData, 0, true)
    return
  end
  self.ui.mScrollListChild_BtnConfirm.interactable = false
  NetCmdTrainGunData:SendCmdGunClassUp(self.gunCmdData.id, function(ret)
    if ret ~= ErrorCodeSuc then
      self.ui.mScrollListChild_BtnConfirm.interactable = true
      return
    end
    if AccountNetCmdHandler.BarrackSkip == 0 then
      local isDayFirst = FacilityBarrackGlobal.IsTodayFirstWatchBreakTimeline(self.gunCmdData.id)
      if isDayFirst then
        self:breakWithTrain()
      else
        self:breakWithoutTrain()
      end
    elseif AccountNetCmdHandler.BarrackSkip == 1 then
      self:breakWithoutTrain()
    elseif AccountNetCmdHandler.BarrackSkip == 2 then
      self:breakWithTrain()
    else
      gferror("onClickStartBreak AccountNetCmdHandler.BarrackSkip \230\156\170\229\174\154\228\185\137\231\154\132\231\177\187\229\158\139" .. AccountNetCmdHandler.BarrackSkip)
    end
    if self.onStartTimelineCallback then
      self.onStartTimelineCallback()
    end
  end)
end

function UIBarrackBreakSubPanel:breakWithoutTrain()
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
        UIManager.OpenUIByParam(UIDef.UIBarrackBreakFinishDialog, param)
        self:PlayBreakAudio()
      elseif timingType == enumTimingType.WillEnd then
      elseif timingType == enumTimingType.LastFrame then
      end
    elseif phaseType ~= enumPhaseType.EndingIdle or timingType == enumTimingType.Started then
    elseif timingType == enumTimingType.WillEnd then
    elseif timingType == enumTimingType.LastFrame then
    end
  end
  self.isInTraining = true
  BarrackHelper.TimelineMgr:PlayBreakTimelineWithoutTrain(self.gunCmdData, callback)
end

function UIBarrackBreakSubPanel:breakWithTrain()
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
        if not FacilityBarrackGlobal.IsFirstWatchingBreakTimeline(self.gunCmdData.id) then
          local param = {
            GunId = self.gunCmdData.id,
            TrainingType = UITrainingSkipPanel.TrainingType.Break,
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
            FacilityBarrackGlobal.WatchedBreakTimeline(self.gunCmdData.id)
            self.trainingPanel:onTimelineEnd()
            self.isInTraining = false
            BarrackHelper.TimelineMgr:Resume()
          end
        }
        UIManager.OpenUIByParam(UIDef.UIBarrackBreakFinishDialog, param)
        self:PlayBreakAudio()
      elseif timingType == enumTimingType.WillEnd then
      elseif timingType == enumTimingType.LastFrame then
      end
    elseif phaseType ~= enumPhaseType.EndingIdle or timingType == enumTimingType.Started then
    elseif timingType == enumTimingType.WillEnd then
    elseif timingType == enumTimingType.LastFrame then
    end
  end
  self.isInTraining = true
  BarrackHelper.TimelineMgr:PlayBreakTimeline(self.gunCmdData, callback)
end

function UIBarrackBreakSubPanel:getNotEnoughItemId()
  local notEnoughItemId = 0
  local maxRankNotEnoughItemData
  for id, cost in pairs(self.gunCmdData.curGunClass.item_cost) do
    local haveCount = NetCmdItemData:GetItemCount(id)
    if cost > haveCount then
      if id == GlobalConfig.CoinId then
        return GlobalConfig.CoinId
      else
        local itemData = TableData.listItemDatas:GetDataById(id)
        if itemData then
          if maxRankNotEnoughItemData then
            if itemData.Rank > maxRankNotEnoughItemData.Rank then
              maxRankNotEnoughItemData = itemData
            end
          else
            maxRankNotEnoughItemData = itemData
          end
        end
      end
    end
  end
  if maxRankNotEnoughItemData then
    notEnoughItemId = maxRankNotEnoughItemData.id
  end
  return notEnoughItemId
end

function UIBarrackBreakSubPanel:RefreshItemCost()
  self:refreshItemCost()
end

function UIBarrackBreakSubPanel:refreshItemCost()
  local itemList = {}
  for id, cost in pairs(self.gunCmdData.curGunClass.item_cost) do
    if id == GlobalConfig.CoinId then
      local haveCount = NetCmdItemData:GetItemCount(id)
      local haveDigit = CS.LuaUIUtils.GetMaxNumberText(haveCount)
      local costDigit = CS.LuaUIUtils.GetMaxNumberText(cost)
      if cost > haveCount then
        self.ui.mText_Num.text = "<color=#FF5E41>" .. haveDigit .. "</color>/" .. costDigit
      else
        self.ui.mText_Num.text = haveDigit .. "/" .. costDigit
      end
    else
      local item = {Id = id, Cost = cost}
      table.insert(itemList, item)
    end
  end
  table.sort(itemList, function(a, b)
    return a.Id < b.Id
  end)
  for i, item in ipairs(itemList) do
    if self.costItemTable[i] == nil then
      self.costItemTable[i] = UICommonItem.New()
      self.costItemTable[i]:InitCtrl(self.ui.mScrollListChild_GrpItem)
    end
    self.costItemTable[i]:SetItemData(item.Id, item.Cost, true, true, nil, nil, nil, nil, nil, nil, nil, true)
    local itemOwn = NetCmdItemData:GetItemCountById(item.Id)
    self.costItemTable[i]:SetCostItemNum(itemOwn, item.Cost)
  end
end

function UIBarrackBreakSubPanel:refreshAllProperty()
  local startPropertyId = LuaUtils.EnumToInt(DevelopProperty.None)
  local endPropertyId = LuaUtils.EnumToInt(DevelopProperty.AllEnd)
  self.propertyItemTable = {}
  local itemIndex = 1
  for i = startPropertyId + 1, endPropertyId - 1 do
    local propertyType = DevelopProperty.__CastFrom(i)
    if propertyType then
      local nowPropertyValue = PropertyUtils.GetBasePropertyValue(self.gunCmdData.GunId, self.gunCmdData.level, propertyType) + self.gunCmdData:GetGunClassValueByPropertyType(propertyType, self.gunCmdData.gunClass)
      local nextPropertyValue = PropertyUtils.GetBasePropertyValue(self.gunCmdData.GunId, self.gunCmdData.level, propertyType) + self.gunCmdData:GetGunClassValueByPropertyType(propertyType, self.gunCmdData.gunClass + 1)
      local delta = nextPropertyValue - nowPropertyValue
      if 0 < delta then
        local item = ComAttributeDetailItem.New()
        local template = self.ui.mScrollListChild_Content.childItem
        local parent = self.ui.mScrollListChild_Content.transform
        item:InitByTemplate(template, parent)
        item:ShowDiff(itemIndex, propertyType, nowPropertyValue, nextPropertyValue, true)
        itemIndex = itemIndex + 1
        table.insert(self.propertyItemTable, item)
      end
    end
  end
end

function UIBarrackBreakSubPanel:refreshBtnRedPoint()
  local isBreakable = NetCmdTrainGunData:IsBreakable(self.gunCmdData.Id)
  local isOpen = NetCmdTrainGunData:IsBreakRedPointOpen()
  setactivewithcheck(self.ui.mTrans_RedPoint, isBreakable and isOpen)
end

function UIBarrackBreakSubPanel:onClickSkip()
  BarrackHelper.TimelineMgr:JumpToLastFrameInCurTimeline()
end

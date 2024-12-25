require("UI.BattleIndexPanel.Item.UIBattleIndexSimCombatItem")
UIBattleIndexSimCombatSubPanel = class("UIBattleIndexSimCombatSubPanel", UIBaseView)
UIBattleIndexSimCombatSubPanel.__index = UIBattleIndexSimCombatSubPanel
UIBattleIndexSimCombatSubPanel.CurSimType = nil
UIBattleIndexSimCombatSubPanel.CurSimBattleIndex = 0
UIBattleIndexSimCombatSubPanel.tabList = {}

function UIBattleIndexSimCombatSubPanel:__InitCtrl()
end

function UIBattleIndexSimCombatSubPanel:InitCtrl(root)
  self.ui = {}
  self:SetRoot(root)
  self:LuaUIBindTable(root, self.ui)
  self:__InitCtrl()
  self.chapterList = TableData.GetStageIndexSimCombatList()
  
  function self.ui.mVirtualListEx_List.itemCreated(renderData)
    local item = self:ItemProvider(renderData)
    return item
  end
  
  function self.ui.mVirtualListEx_List.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
  
  self:InitTabs()
end

function UIBattleIndexSimCombatSubPanel:InitTabs()
  self.ui.mVirtualListEx_List.numItems = self.chapterList.Count
  self:RefreshTabs()
end

function UIBattleIndexSimCombatSubPanel:OnShowFinish()
  if not NetCmdHigherPVPData.PVPIsOpen then
    NetCmdHigherPVPData:ReqHighPVPPlanInfo(function(ret)
      if ret == ErrorCodeSuc then
        NetCmdHigherPVPData:InitPlanTime()
        if NetCmdHigherPVPData.PVPIsOpen then
          self.ui.mVirtualListEx_List:Refresh()
        end
      end
    end)
  end
end

function UIBattleIndexSimCombatSubPanel:Refresh()
  self.ui.mVirtualListEx_List.numItems = self.chapterList.Count
  self:RefreshTabs()
end

function UIBattleIndexSimCombatSubPanel:OnBackFrom()
  self:Refresh()
end

function UIBattleIndexSimCombatSubPanel:RefreshTabs()
  self.ui.mVirtualListEx_List:Refresh()
  self.timer = TimerSys:DelayFrameCall(3, function()
    local obj = self.ui.mVirtualListEx_List:GetGoByIndex(UIBattleIndexSimCombatSubPanel.CurSimBattleIndex)
    if obj ~= nil then
      self.ui.mVirtualListEx_List:ScrollTo(obj)
    end
  end)
end

function UIBattleIndexSimCombatSubPanel:OnClickSimCombat(simType, unlockType, listIndex)
  if TipsManager.NeedLockTips(unlockType) then
    return
  end
  local eType = StageType.__CastFrom(simType)
  if eType == StageType.NrtpvpStage then
    self:OnClickPVP()
  elseif eType == StageType.DifficultStage then
    self:OnClickHardChapter()
  elseif eType == StageType.ExpandStage then
    self:OnClickUnite()
  elseif eType == StageType.NrtpvpAdvanceStage then
    self:OnClickHigherPVP()
  else
    NetCmdStageRecordData:RequestStageRecordByType(eType, function(ret)
      if ret == ErrorCodeSuc then
        self:OpenSimCombatUI(simType)
      end
    end)
  end
  UIBattleIndexSimCombatSubPanel.CurSimBattleIndex = listIndex
end

function UIBattleIndexSimCombatSubPanel:OnClickHigherPVP()
  if not NetCmdHigherPVPData.PVPIsOpen then
    CS.PopupMessageManager.PopupString(TableData.GetHintById(226))
    return
  end
  if not AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.HighPvp, true) then
    return
  end
  UIManager.OpenUI(UIDef.HigherPVPMainPanel)
end

function UIBattleIndexSimCombatSubPanel:OpenSimCombatUI(simType)
  self.contentPos = self.ui.mVirtualListEx_List.horizontalNormalizedPosition
  local eType = StageType.__CastFrom(simType)
  UIBattleIndexSimCombatSubPanel.CurSimType = simType
  if eType == StageType.DailyStage then
    UIManager.OpenUIByParam(UIDef.UISimCombatDailyPanel, simType)
  elseif eType == StageType.TowerStage then
    UIManager.OpenUIByParam(UIDef.UISimCombatTrainingPanel, simType)
  elseif eType == StageType.WeeklyStage then
    NetCmdSimulateBattleData:ReqSimCombatWeeklyPlanInfo(function(ret)
      if ret == ErrorCodeSuc then
        NetCmdSimulateBattleData:ReqSimCombatWeeklyInfo(function(ret)
          if ret == ErrorCodeSuc then
            self:OpenWeekly(NetCmdSimulateBattleData:GetPlanByType(1), simType)
          end
        end)
      end
    end)
  elseif eType == StageType.MythicStage then
    UIManager.OpenUIByParam(enumUIPanel.UISimCombatMythicMainPanel, {})
  elseif eType == StageType.DutyStage then
    UIManager.OpenUIByParam(UIDef.UISimCombatProTalentPanel, simType)
  elseif eType == StageType.TutorialStage then
    UIManager.OpenUIByParam(UIDef.UISimCombatTutorialEntrancePanel, simType)
  end
end

function UIBattleIndexSimCombatSubPanel:OpenWeekly(plan, simType)
  if UISystem:GetTopUI(UIGroupType.Default).UIDefine.UIType ~= UIDef.UIBattleIndexPanel then
    return
  end
  if LuaUtils.IsNullOrDestroyed(self.mUIRoot) or self.mUIRoot.gameObject.activeInHierarchy == false then
    return
  end
  if plan == nil then
    gfwarning("Invalid plan !!!!!!!!!!!!!")
    return
  end
  if CGameTime:GetTimestamp() > plan.CloseTime then
    CS.PopupMessageManager.PopupString(TableData.GetHintById(108064))
    for i = 1, 3 do
      local key = AccountNetCmdHandler:GetUID() .. "_SimCombatWeeklyTeam" .. string.char(string.byte("A") + i - 1)
      PlayerPrefs.SetString(key, "")
    end
    return
  end
  UIManager.OpenUIByParam(enumUIPanel.UIWeeklyEnterPanel, simType)
end

function UIBattleIndexSimCombatSubPanel:OnClickPVP()
  if not NetCmdPVPData.PVPIsOpen then
    NetCmdSimulateBattleData:ReqPlanData(3, function(ret)
      if ret then
        NetCmdPVPData:SetPvpSeason()
        if not NetCmdPVPData.PVPIsOpen then
          CS.PopupMessageManager.PopupString(TableData.GetHintById(226))
        end
      end
    end)
    return
  end
  NetCmdPVPData:RequestPVPInfo(function()
    UIManager.OpenUI(UIDef.UINRTPVPPanel)
    NetCmdPVPData:SetUnLockRedPoint(0)
  end)
end

function UIBattleIndexSimCombatSubPanel:OnClickHardChapter()
  UIManager.OpenUI(UIDef.UIHardChapterSelectPanelV2)
end

function UIBattleIndexSimCombatSubPanel:OnClickUnite()
  NetCmdSimulateBattleData:SendSimCombatUniteInfo(function(code)
    if code == ErrorCodeSuc then
      local isEnter = NetCmdSimulateBattleData:GetUniteEnteredThisWeek()
      NetCmdSimulateBattleData:SendSimCombatUniteEnter(function(ret)
        if ret == ErrorCodeSuc then
          UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIUniteChapterPanel, isEnter)
        end
      end)
    end
  end)
end

function UIBattleIndexSimCombatSubPanel:OnRelease()
  self.CurSimType = nil
  self.contentPos = nil
end

function UIBattleIndexSimCombatSubPanel:ItemProvider(renderData)
  local itemView = UIBattleIndexSimCombatItem.New()
  itemView:InitCtrlWithoutInstance(renderData.gameObject.transform)
  UIUtils.GetButtonListener(itemView.ui.mBtn_Root.gameObject).onClick = function()
    self:OnClickSimCombat(itemView.mData.id, itemView.mData.unlock, itemView.index)
  end
  renderData.data = itemView
end

function UIBattleIndexSimCombatSubPanel:ItemRenderer(index, renderData)
  local item = renderData.data
  local data = self.chapterList[index]
  item:SetData(data, index)
end

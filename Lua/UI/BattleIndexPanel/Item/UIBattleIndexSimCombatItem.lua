require("UI.UIBaseCtrl")
UIBattleIndexSimCombatItem = class("UIBattleIndexSimCombatItem", UIBaseCtrl)
UIBattleIndexSimCombatItem.__index = UIBattleIndexSimCombatItem
UIBattleIndexSimCombatItem.mText_Tips = nil
UIBattleIndexSimCombatItem.mText_Title = nil
UIBattleIndexSimCombatItem.mText_ = nil
UIBattleIndexSimCombatItem.mText_BattleIndexSimbatItem1 = nil

function UIBattleIndexSimCombatItem:__InitCtrl()
end

function UIBattleIndexSimCombatItem:InitCtrl(parent)
  local instObj = instantiate(UIUtils.GetGizmosPrefab("BattleIndex/Btn_BattleIndexSimCombatItem.prefab", parent))
  self:InitCtrlWithoutInstance(instObj.transform)
end

function UIBattleIndexSimCombatItem:InitCtrlWithoutInstance(instObj)
  self:SetRoot(instObj.transform)
  self.ui = {}
  self:LuaUIBindTable(self.mUIRoot, self.ui)
  setactive(self.ui.mText_TitleName, false)
  self:__InitCtrl()
end

function UIBattleIndexSimCombatItem:SetData(data, index)
  self.mData = data
  self.index = index
  self.mSimType = StageType.__CastFrom(data.id)
  self.ui.mText_Text.text = self:GetSimCombatName(data)
  self.ui.mText_Open.text = data.open_time.str
  self.ui.mImg_Pic.sprite = IconUtils.GetStageIcon(data.image)
  self.ui.mImg_Icon.sprite = IconUtils.GetStageIcon(data.icon)
  self:CheckSimCombatIsUnLock()
  self:CheckExtraTimesAndItems()
  self:CheckDuty()
  self:CheckDropUp()
  setactive(self.ui.mTrans_RedPoint, self:CheckHasRedPoint())
  if self.mData.id == 26 then
    setactive(self.ui.mTrans_RedPoint, NetCmdSimulateBattleData:CheckTeachingUnlockRedPoint() or NetCmdSimulateBattleData:CheckTeachingRewardRedPoint() or NetCmdSimulateBattleData:CheckTeachingNoteReadRedPoint() or NetCmdSimulateBattleData:CheckTeachingNoteProgressRedPoint())
  elseif self.mData.id == 30 then
    local timeCount = NetCmdPVPData.PVPLastTime
    if timeCount <= 0 then
      self.ui.mText_Open.text = TableData.GetHintById(150001)
      setactive(self.ui.mTrans_RedPoint, false)
    else
      local deltaTimeStr = NetCmdPVPData:ConvertPvpTime(CGameTime:GetTimestamp(), NetCmdPVPData.PVPCloseTime)
      self.ui.mText_Open.text = string_format(TableData.GetHintById(103129), deltaTimeStr)
      setactive(self.ui.mTrans_RedPoint, NetCmdPVPData:CheckPvpRedPoint() ~= 0)
    end
  elseif self.mData.id == 25 then
    local hasReceiveTarget = NetCmdSimCombatMythicData:CheckRedPoint()
    setactive(self.ui.mTrans_RedPoint, hasReceiveTarget)
    setactive(self.ui.mText_TitleName, true)
    self.ui.mText_TitleName.text = NetCmdSimCombatMythicData:GetEntranceLevelName()
    local maxIndex = NetCmdSimCombatMythicData:GetAutoSelectedGroupIndex()
    local cfg = TableData.listSimCombatMythicGroupDatas:GetDataById(maxIndex)
    if cfg.group_type == 1 then
      local time = NetCmdSimCombatMythicData:GetUnlimitTimeOffset()
      if 0 < time then
        local timeStr = CS.TimeUtils.LeftTimeToShowFormat(time)
        self.ui.mText_Open.text = string_format(TableData.GetHintById(103130), timeStr)
      end
    end
  elseif self.mData.id == CS.GF2.Data.StageType.DifficultStage:GetHashCode() then
    local hasReward = false
    local hardList = TableData.GetHardChapterListV2()
    local systemHasLook = NetCmdDungeonData:CheckDifficultChapterSystemHasLook()
    for i = 0, hardList.Count - 1 do
      local id = hardList[i].id
      hasReward = hasReward or 0 < NetCmdDungeonData:UpdateDifficultChapterRewardRedPoint(id) or NetCmdSimulateBattleData:CheckCanAnalysisByChapterID(id) or NetCmdDungeonData:CheckNewChapterUnlockByID(id)
    end
    setactive(self.ui.mTrans_RedPoint, hasReward or systemHasLook == false)
  elseif self.mSimType == StageType.WeeklyStage then
    local weeklyData = NetCmdSimulateBattleData:GetSimCombatWeeklyData()
    if weeklyData then
      local time = weeklyData:GetLastTime()
      local timeStr = CS.TimeUtils.LeftTimeToShowFormat(time)
      if 0 < time then
        self.ui.mText_Open.text = string_format(TableData.GetHintById(103130), timeStr)
      else
        self.ui.mText_Open.text = string_format("{0}{1}", CS.TimeUtils.LeftTimeToShowFormat(weeklyData:LastOpenTime()), TableData.GetHintById(180168))
      end
      local isStart = weeklyData.isStartB or weeklyData:HasStartCustomBoss()
      setactive(self.ui.mText_TitleName, isStart)
      if isStart then
        self.ui.mText_TitleName.text = UIUtils.GetHintStr(108155)
      end
    end
  elseif self.mSimType == StageType.ExpandStage then
    local uniteInfo = NetCmdSimulateBattleData:GetFirstUniteMission()
    local planID = 0
    if uniteInfo ~= nil then
      planID = uniteInfo.PlanId
    end
    local leftTime = 0
    local dataTable = TableData.listPlanDatas:GetDataById(planID, true)
    if dataTable ~= nil then
      leftTime = dataTable.close_time
    end
    local s = CS.TimeUtils.GetLeftTime(leftTime)
    self.ui.mText_Open.text = string_format(TableData.GetHintById(310019), s)
    local canShowRedDot = 0 < NetCmdSimulateBattleData:GetUniteRewardRedDot() or 0 < NetCmdSimulateBattleData:GetUniteRefreshRedDot()
    setactive(self.ui.mTrans_RedPoint, canShowRedDot == true)
  elseif self.mSimType == StageType.NrtpvpAdvanceStage then
    if not AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.HighPvp, false) then
      self.ui.mText_Open.text = ""
      setactive(self.ui.mTrans_RedPoint, false)
    elseif NetCmdHigherPVPData.PVPIsOpen then
      local deltaTimeStr = NetCmdPVPData:ConvertPvpTime(CGameTime:GetTimestamp(), NetCmdHigherPVPData.PVPCloseTime)
      self.ui.mText_Open.text = string_format(TableData.GetHintById(103129), deltaTimeStr)
      setactive(self.ui.mTrans_RedPoint, NetCmdHigherPVPData:HigherPVPHasRed())
    else
      self.ui.mText_Open.text = TableData.GetHintById(150001)
      setactive(self.ui.mTrans_RedPoint, false)
    end
  end
end

function UIBattleIndexSimCombatItem:GetSimCombatName(data)
  if self.mSimType == StageType.WeeklyStage then
    return TableData.GetHintById(900026)
  end
  return data.name.str
end

function UIBattleIndexSimCombatItem:CheckSimCombatIsUnLock()
  local isUnLock = AccountNetCmdHandler:CheckSystemIsUnLock(self.mData.unlock)
  setactive(self.ui.mTrans_GrpLocked, not isUnLock)
  setactive(self.ui.mTrans_GrpLockedTitle, not isUnLock)
  setactive(self.ui.mTrans_GrpOpen, isUnLock)
  if not isUnLock then
    self.ui.mText_Locked.text = self.mData.unlock_describe.str
  end
end

function UIBattleIndexSimCombatItem:CheckExtraTimesAndItems()
end

function UIBattleIndexSimCombatItem:CheckDuty()
  local dutyStageId = LuaUtils.EnumToInt(StageType.DutyStage)
  if self.mData.id == 22 or self.mData.id == dutyStageId then
    NetCmdSimulateBattleData:ReqPlanData(CS.GF2.Data.PlanType.PlanFunctionSimDailyopen:GetHashCode(), function()
      setactive(self.ui.mTrans_GrpDuty, AccountNetCmdHandler:CheckSystemIsUnLock(self.mData.unlock))
      local args = NetCmdSimulateBattleData.PlanData.Args
      local list = self.mData.label_id
      for i = 0, list.Count - 1 do
        for j = 0, args.Count - 1 do
          if list[i] == args[j] then
            setactive(self.ui.mTrans_GrpDuty:GetChild(i):Find("Off"), false)
            setactive(self.ui.mTrans_GrpDuty:GetChild(i):Find("On"), true)
            break
          else
            setactive(self.ui.mTrans_GrpDuty:GetChild(i):Find("Off"), true)
            setactive(self.ui.mTrans_GrpDuty:GetChild(i):Find("On"), false)
          end
        end
      end
    end)
  end
end

function UIBattleIndexSimCombatItem:CheckHasRedPoint()
  if self.mSimType == StageType.WeeklyStage then
    return NetCmdSimulateBattleData:CheckSimWeeklyRedPoint()
  end
  return false
end

function UIBattleIndexSimCombatItem:CheckDropUp()
  UIUtils.GetButtonListener(self.ui.mBtn_GrpDropup).onClick = function()
    UIManager.OpenUIByParam(UIDef.UIComDropUpDialog, {
      stageType = self.mData.id
    })
  end
  local totalMax = 0
  local totalCurrent = 0
  local regressMax = NetCmdActivityRegressData:GetActivityUpCountMaxByStageType(self.mData.id)
  if 0 < regressMax then
    totalMax = totalMax + regressMax
    totalCurrent = totalCurrent + NetCmdActivityRegressData:GetActivityUpCountCurrent()
  end
  local enable, dropUpMax = NetCmdActivityDropUpData:GetActivityUpCountMaxByStageType(self.mData.id)
  if enable then
    totalMax = totalMax + dropUpMax
    totalCurrent = totalCurrent + NetCmdActivityDropUpData:GetActivityUpCountCurrentByStageType(self.mData.id)
  end
  local cycleDropUp = NetCmdActivityDropUpData:HasRefreshTypeZeroActivity(self.mData.id)
  setactive(self.ui.mBtn_GrpDropup.gameObject, 0 < totalMax or enable)
  self.ui.mText_DropupTimes.text = totalCurrent .. "/" .. totalMax
  local spriteName = (0 < totalCurrent or cycleDropUp) and "Icon_DropupL" or "Icon_Dropup_GreyL"
  self.ui.mText_DropupIcon.sprite = IconUtils.GetItemCornerMarkIcon(spriteName)
end

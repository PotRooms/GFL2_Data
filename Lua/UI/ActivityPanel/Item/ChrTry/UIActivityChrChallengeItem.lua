require("UI.UIBaseCtrl")
require("UI.ActivityPanel.Item.UIActivityItemBase")
require("UI.Common.UICommonItem")
require("UI.ActivityStage.Item.UIActivityStageLevelItem")
UIActivityChrChallengeItem = class("UIActivityChrChallengeItem", UIActivityItemBase)
UIActivityChrChallengeItem.__index = UIActivityChrChallengeItem
UIActivityChrChallengeItem.selectIndex = nil

function UIActivityChrChallengeItem:OnInit()
end

function UIActivityChrChallengeItem:OnShow()
  self.ui.mText_Name.text = self.mActivityTableData.name.str
  self.ui.mText_Info.text = self.mActivityTableData.desc.str
  self.ui.mText_Time:StartCountdown(self.mCloseTime)
  self:ReleaseStage()
  self:ReleaseTimer()
  self.stageIds = TableData.listEventStageByActivityIdDatas:GetDataById(self.mActivityID).Stageid
  self:CreateStages()
  NetCmdStageRecordData:RequestStageRecordByType(CS.GF2.Data.StageType.EventActivityStage, function(ret)
    if ret == ErrorCodeSuc then
      self:SelectDefaultStage()
      self:CreateOverTimer()
    end
  end)
end

function UIActivityChrChallengeItem:CreateStages()
  self.stages = {}
  for i = 0, self.stageIds.Count - 1 do
    local id = self.stageIds[i]
    local item = UIActivityStageLevelItem.New()
    item:InitCtrl(self.ui.mTrans_LevelContent)
    item:SetData(i + 1, id, self.mOpenTime, self.mActivityID)
    item:SetSelected(i + 1 == UIActivityChrChallengeItem.selectIndex)
    local onClick = function()
      if self.selectItem then
        self.selectItem:SetSelected(false)
      end
      UIActivityChrChallengeItem.selectIndex = i + 1
      self.selectItem = item
      self.selectItem:SetSelected(true)
      self:ShowStageReward(id)
    end
    item:SetOnClick(onClick)
    table.insert(self.stages, item)
  end
end

function UIActivityChrChallengeItem:ShowStageReward(stageId)
  if self.UICommonItems ~= nil then
    self:ReleaseCtrlTable(self.UICommonItems, true)
  end
  self.UICommonItems = {}
  local stageData = TableData.listStageDatas:GetDataById(stageId)
  local itemList = UIUtils.SortStageNormalDrop(stageData.first_reward)
  for _, id in pairs(itemList) do
    local item = UICommonItem.New()
    item:InitCtrl(self.ui.mTrans_Content)
    table.insert(self.UICommonItems, item)
    local count = stageData.first_reward[id]
    item:SetItemData(id, count)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Goto).onClick = function()
    local lock, reason = self:IsLockAndReason(stageId)
    if lock then
      CS.PopupMessageManager.PopupString(reason)
    else
      SceneSys:OpenBattleSceneForGacha(stageData)
    end
  end
  local record = NetCmdStageRecordData:GetStageRecordById(stageId)
  for _, item in pairs(self.UICommonItems) do
    item:SetReceivedIcon(record.first_pass_time ~= 0)
  end
  local lock, reason = self:IsLockAndReason(stageId)
  setactivewithcheck(self.ui.mBtn_Goto, not lock)
  setactivewithcheck(self.ui.mTrans_GrpLock, lock)
  self.ui.mText_Lock.text = reason
end

function UIActivityChrChallengeItem:SelectDefaultStage()
  for i, item in ipairs(self.stages) do
    item:SetData(i, item.stageId, self.mOpenTime, self.mActivityID)
  end
  if UIActivityChrChallengeItem.selectIndex == nil then
    local select = 1
    for i, item in ipairs(self.stages) do
      local stageId = item.stageId
      local lock = self:IsLockAndReason(stageId)
      local record = NetCmdStageRecordData:GetStageRecordById(stageId)
      if not lock and record.first_pass_time == 0 then
        select = i
        break
      end
    end
    UIActivityChrChallengeItem.selectIndex = select
  end
  self.selectItem = self.stages[UIActivityChrChallengeItem.selectIndex]
  self.selectItem:SetSelected(true)
  self:ShowStageReward(self.selectItem.stageId)
end

function UIActivityChrChallengeItem:CreateOverTimer()
  if self.overTimer ~= nil then
    self.overTimer:Stop()
    self.overTimer = nil
  end
  local now = CGameTime:GetTimestamp()
  if self.mCloseTime - now > 0 then
    self.overTimer = TimerSys:UnscaledDelayCall(self.mCloseTime - now, function()
      UIUtils.PopupErrorWithHint(260010)
      UISystem:JumpToMainPanel()
    end)
  end
end

function UIActivityChrChallengeItem:ReleaseTable()
  self:ReleaseReward()
  self:ReleaseStage()
end

function UIActivityChrChallengeItem:ReleaseReward()
  if self.UICommonItems then
    self:ReleaseCtrlTable(self.UICommonItems, true)
  end
  self.UICommonItems = nil
end

function UIActivityChrChallengeItem:ReleaseStage()
  if self.stages then
    self:ReleaseCtrlTable(self.stages, true)
  end
  self.stages = nil
end

function UIActivityChrChallengeItem:ReleaseTimer()
  if self.overTimer ~= nil then
    self.overTimer:Stop()
    self.overTimer = nil
  end
end

function UIActivityChrChallengeItem:OnHide()
  self:ReleaseTable()
  self:ReleaseTimer()
  UIActivityChrChallengeItem.selectIndex = nil
end

function UIActivityChrChallengeItem:OnTop()
end

function UIActivityChrChallengeItem:OnClose()
  self:ReleaseTable()
  self:ReleaseTimer()
  UIActivityChrChallengeItem.selectIndex = nil
end

function UIActivityChrChallengeItem:IsLockAndReason(stageId)
  local now = CGameTime:GetTimestamp()
  local openTime = self.mOpenTime
  local day = CGameTime:DayPass(openTime, now, 5)
  local requireDay = TableData.listEventStageDatas:GetDataById(stageId).unlock_time
  if day >= requireDay then
    return false, ""
  end
  local nowTime = CS.CGameTime.ConvertLongToDateTime(now)
  if 5 <= nowTime.Hour then
    nowTime = CS.CGameTime.ConvertLongToDateTime(now + 86400 * (requireDay - day))
  else
    nowTime = CS.CGameTime.ConvertLongToDateTime(now + 86400 * (requireDay - day - 1))
  end
  local reason = string_format(TableData.GetHintById(260203), nowTime.Month, nowTime.Day)
  return true, reason
end

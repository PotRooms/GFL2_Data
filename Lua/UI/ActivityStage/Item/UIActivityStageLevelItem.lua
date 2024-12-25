require("UI.UIBaseCtrl")
UIActivityStageLevelItem = class("UIActivityStageLevelItem", UIBaseCtrl)
UIActivityStageLevelItem.__index = UIActivityStageLevelItem
local lock = 1
local unlock = 2
local clear = 3

function UIActivityStageLevelItem:ctor()
end

function UIActivityStageLevelItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:InitCtrlWithNoInstantiate(instObj, false)
end

function UIActivityStageLevelItem:InitCtrlWithNoInstantiate(obj, setToZero)
  self:SetRoot(obj.transform)
  obj.transform.localPosition = vectorzero
  if setToZero == nil or setToZero then
    obj.transform.anchoredPosition = vector2zero
  else
    obj.transform.anchoredPosition = vector2one * 1000000
  end
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
end

function UIActivityStageLevelItem:SetData(index, stageId, openTime, activityId)
  self.stageId = stageId
  self.openTime = openTime
  self.activityId = activityId
  self.ui.mText_Num.text = index < 10 and "0" .. index or index
  local now = CGameTime:GetTimestamp()
  local day = CGameTime:DayPass(openTime, now, 5)
  local requireDay = TableData.listEventStageDatas:GetDataById(stageId).unlock_time
  local status = lock
  local color = self.ui.mText_Num.color
  if day >= requireDay then
    local record = NetCmdStageRecordData:GetStageRecordById(stageId)
    if record.first_pass_time ~= 0 then
      status = clear
    else
      status = unlock
    end
    color.a = 1
  else
    status = lock
    color.a = 0.3
  end
  self.ui.mText_Num.color = color
  setactivewithcheck(self.ui.mTrans_ImgComplete, status == clear)
  setactivewithcheck(self.ui.mTrans_ImgLock, status == lock)
  setactivewithcheck(self.ui.mTrans_GrpNone, status == lock)
  setactivewithcheck(self.ui.mTrans_ImgIcon, status == unlock)
  setactivewithcheck(self.ui.mObj_RedPoint, NetCmdActivityChrChallengeData:IsShowChapterRedPoint(self.openTime, self.activityId, self.stageId))
  UIUtils.GetButtonListener(self.ui.mBtn_Root).onClick = function()
    if self.onClick ~= nil then
      self.onClick()
    end
  end
end

function UIActivityStageLevelItem:SetOnClick(callback)
  self.onClick = callback
end

function UIActivityStageLevelItem:SetSelected(select)
  self.ui.mBtn_Root.interactable = not select
  if select then
    NetCmdActivityChrChallengeData:WatchStage(self.openTime, self.activityId, self.stageId)
    setactivewithcheck(self.ui.mObj_RedPoint, NetCmdActivityChrChallengeData:IsShowChapterRedPoint(self.openTime, self.activityId, self.stageId))
  end
  NetCmdActivityChrChallengeData:DirtyRedPoint()
end

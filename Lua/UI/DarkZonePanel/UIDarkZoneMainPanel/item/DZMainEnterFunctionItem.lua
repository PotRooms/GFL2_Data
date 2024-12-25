require("UI.UIBaseCtrl")
DZMainEnterFunctionItem = class("DZMainEnterFunctionItem", UIBaseCtrl)
DZMainEnterFunctionItem.__index = DZMainEnterFunctionItem

function DZMainEnterFunctionItem:__InitCtrl()
end

function DZMainEnterFunctionItem:InitCtrl(root)
  local com = root:GetComponent(typeof(CS.ScrollListChild))
  local obj = instantiate(com.childItem)
  if root then
    CS.LuaUIUtils.SetParent(obj.gameObject, root.gameObject, true)
  end
  self.ui = {}
  self.mData = {}
  self:LuaUIBindTable(obj, self.ui)
  self:SetRoot(obj.transform)
  self.ui.mAnim_Self.keepAnimatorControllerStateOnDisable = true
  self.activityID = 0
end

function DZMainEnterFunctionItem:SetModeScheduleData(name, tipHitID, func, unlockID, tipHitStr, modeScheduleData)
  self.clickFunc = func
  self.unlockID = unlockID
  self.mIsUnLock = self.unlockID == nil or not (self.unlockID > 0)
  self.modeScheduleData = modeScheduleData
  if tipHitID and 0 < tipHitID then
    self.hint = TableData.GetHintById(tipHitID)
  elseif unlockID and 0 < unlockID then
    local d = TableData.GetUnLockInfoByType(unlockID)
    if d then
      local str = UIUtils.CheckUnlockPopupStr(d)
      self.hint = str
    end
  end
  if tipHitStr then
    self.hint = tipHitStr
  end
  if name then
    self.ui.mText_ItemName.text = name
  end
  self.ui.mBtn_Self.onClick:AddListener(function()
    self:ClickFunction()
  end)
  self:SetTimeLimit(true)
end

function DZMainEnterFunctionItem:SetData(nameHitID, tipHitID, func, unlockID, tipHitStr)
  self.clickFunc = func
  self.unlockID = unlockID
  self.mIsUnLock = self.unlockID == nil or not (self.unlockID > 0)
  if tipHitID and 0 < tipHitID then
    self.hint = TableData.GetHintById(tipHitID)
  elseif unlockID and 0 < unlockID then
    local d = TableData.GetUnLockInfoByType(unlockID)
    if d then
      local str = UIUtils.CheckUnlockPopupStr(d)
      self.hint = str
    end
  end
  if tipHitStr then
    self.hint = tipHitStr
  end
  if nameHitID then
    self.ui.mText_ItemName.text = TableData.GetHintById(nameHitID)
  end
  self.ui.mBtn_Self.onClick:AddListener(function()
    self:ClickFunction()
  end)
end

function DZMainEnterFunctionItem:SetImage(imgName)
  self.ui.mImg_Icon.sprite = IconUtils.GetDarkzoneIcon(imgName)
end

function DZMainEnterFunctionItem:RefreshLockState()
  if self.unlockID and self.unlockID > 0 then
    self.mIsUnLock = AccountNetCmdHandler:CheckSystemIsUnLock(self.unlockID)
  end
  self.ui.mAnim_Self:SetBool("UnLock", self.mIsUnLock)
end

function DZMainEnterFunctionItem:RefreshRedDot(needShow)
  setactive(self.ui.mTrans_RedPoint, needShow)
end

function DZMainEnterFunctionItem:SetActivityID()
  self.modeType = SubmoduleType.ActivityDarkzone
  self.activityID = NetCmdActivityDarkZone:GetCurrActivityID(SubmoduleType.ActivityDarkzone, NetCmdActivitySimData.offcialConfigId)
end

function DZMainEnterFunctionItem:SetActivityState()
  local state = NetCmdActivityDarkZone:GetCurrActivityState(NetCmdActivitySimData.offcialConfigId)
  if state == ActivitySimState.NotOpen then
    self.ui.mText_ItemName.text = TableData.GetHintById(210005)
    self.mIsUnLock = false
    self.ui.mAnim_Self:SetBool("UnLock", self.mIsUnLock)
    self.hint = TableData.GetHintById(210005)
    self:SetTimeLimit(false)
  elseif self.activityID == 101 and (state == ActivitySimState.Official or state == ActivitySimState.OfficialDown) then
    NetCmdActivitySimData:CSSimCafeInfo()
    self:RefreshLockListState()
    self:SetTimeLimit(true)
  elseif self.activityID == 101 and state == ActivitySimState.End then
    self.ui.mAnim_Self:SetBool("UnLock", false)
    self.mIsUnLock = false
    self:SetTimeLimit(true)
    self.hint = TableData.GetHintById(260044)
  elseif state == ActivitySimState.WarmUp then
    self.ui.mAnim_Self:SetBool("UnLock", false)
    self.mIsUnLock = false
    self:SetTimeLimit(true)
    self.hint = TableData.GetHintById(210005)
  else
    self:RefreshLockListState()
    self:SetTimeLimit(true)
  end
end

function DZMainEnterFunctionItem:SetTimeLimit(needShow)
  setactive(self.ui.mTrans_TimeLimit, needShow)
end

function DZMainEnterFunctionItem:ClickFunction()
  if self.mIsUnLock == false then
    PopupMessageManager.PopupString(self.hint)
    return
  end
  if self.clickFunc then
    self.clickFunc()
  end
end

function DZMainEnterFunctionItem:OnClose()
  self.mIsUnLock = nil
  self.clickFunc = nil
  self.hint = nil
  self:DestroySelf()
end

function DZMainEnterFunctionItem:SetQuestType()
  self.isQuestType = true
end

function DZMainEnterFunctionItem:SetQuestState()
  self:RefreshLockState()
end

function DZMainEnterFunctionItem:RefreshLockListState()
  local d = TableData.GetUnLockInfoByType(self.unlockID)
  self.mIsUnLock = true
  if d then
    self.mIsUnLock = AccountNetCmdHandler:CheckSystemIsUnLock(self.unlockID)
  end
  self.ui.mAnim_Self:SetBool("UnLock", self.mIsUnLock)
end

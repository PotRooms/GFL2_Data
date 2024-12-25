require("UI.ActivityTheme.Lenna.LennaActivity")
UIRecentActivityTab = class("UIRecentActivityTab", UIBaseCtrl)

function UIRecentActivityTab:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:SetRoot(instObj.transform)
  UIUtils.AddBtnClickListener(self.ui.mBtn_RecentActivitieItem.gameObject, function()
    self:onClickSelf()
  end)
  self.ui.mCountdown:AddFinishCallback(function(succ)
    self:onTimerEmd(succ)
  end)
  self.ui.mAnimator.keepAnimatorControllerStateOnDisable = true
end

function UIRecentActivityTab:SetData(activityEntranceData, index, onClickCallback)
  self.activityEntranceData = activityEntranceData
  self.planActivityData = TableDataBase.listPlanDatas:GetDataById(activityEntranceData.plan_id)
  self.index = index
  self.onClickCallback = onClickCallback
  if not self.activityEntranceData then
    return
  end
  self.activityConfigData = NetCmdThemeData:GetActivityDataByEntranceId(self.activityEntranceData.id)
  self.activityModuleData = TableData.listActivityModuleDatas:GetDataById(self.activityEntranceData.module_id)
  self.isUnlock = self:IsUnlock()
  self:RefreshTimer()
end

function UIRecentActivityTab:SetVisible(isShow)
  setactive(self.ui.mBtn_RecentActivitieItem.gameObject, isShow)
end

function UIRecentActivityTab:Refresh()
  setactive(self.ui.mObj_RedPoint, false)
  if self.ui == nil then
    return
  end
  if not self.activityEntranceData then
    self.ui.mAnimator:SetBool("Unlock", false)
    return
  end
  setactivewithcheck(self.ui.mCountdown, false)
  self.ui.mText_Title.text = self.activityEntranceData.name.str
  setactive(self.ui.mTrans_Preheat, false)
  setactive(self.ui.mTrans_Mental, false)
  for key, value in pairs(self.activityModuleData.ActivitySubmodule) do
    if key == 2003 then
      local chapterData = TableData.listChapterDatas:GetDataById(value, true)
      if chapterData ~= nil then
        setactive(self.ui.mTrans_Mental, chapterData.is_gun_story == 1)
      end
    end
  end
  local state = CS.NetCmdActivityDarkZone.Instance:GetCurrActivityState(self.activityConfigData.Id)
  if self.activityModuleData then
    if self.activityModuleData.stage_type == 1 then
      if NetCmdThemeData:CheckActivityEqual(self.activityConfigData.Id, ThemeActivityType.Daiyan) then
        setactive(self.ui.mObj_RedPoint, NetCmdThemeData:ThemeHaveRedPoint(self.activityConfigData.Id, 1))
      elseif NetCmdThemeData:CheckActivityEqual(self.activityConfigData.Id, ThemeActivityType.Cafe) or NetCmdThemeData:CheckActivityEqual(self.activityConfigData.Id, ThemeActivityType.JiangYu) then
        NetCmdActivitySimData:CSThemeActivityInfo(self.activityEntranceData.id, function(ret)
          if ret == ErrorCodeSuc then
            if self.ui == nil or self.ui.mObj_RedPoint == nil then
              return
            end
            setactive(self.ui.mObj_RedPoint, NetCmdThemeData:ThemeHaveRedPoint(self.activityConfigData.Id, 1))
          end
        end)
      elseif NetCmdThemeData:CheckActivityEqual(self.activityConfigData.Id, ThemeActivityType.Lenna) then
        NetCmdActivityBingoData:GetBingoInfo(self.activityEntranceData.id, function(ret)
          if ret == ErrorCodeSuc then
            if self.ui == nil or self.ui.mObj_RedPoint == nil then
              return
            end
            setactivewithcheck(self.ui.mObj_RedPoint, NetCmdThemeData:ThemeHaveRedPoint(self.activityConfigData.Id, 1))
          end
        end)
      elseif NetCmdThemeData:IsThemeTemplateActivity(self.activityConfigData.Id) then
        setactive(self.ui.mObj_RedPoint, NetCmdThemeData:ThemeHaveRedPoint(self.activityConfigData.Id, 1))
      else
        setactive(self.ui.mObj_RedPoint, NetCmdThemeData:ThemeHaveRedPoint(self.activityConfigData.Id, 1))
      end
    else
      local stage = 2
      if self.activityModuleData ~= nil then
        stage = self.activityModuleData.stage_type
      end
      setactive(self.ui.mObj_RedPoint, NetCmdThemeData:ThemeHaveRedPoint(self.activityConfigData.Id, stage))
    end
  end
  local isOpenTime = CGameTime:GetTimestamp() >= self.planActivityData.open_time and CGameTime:GetTimestamp() < self.planActivityData.close_time
  local canEnter = isOpenTime and self.isUnlock
  self.ui.mAnimator:SetBool("Unlock", canEnter)
  TimerSys:DelayFrameCall(1, function()
    self.ui.mAnimator:SetBool("Unlock", canEnter)
  end)
  IconUtils.GetAtlasSpriteAsyc("RecentActivitie/" .. self.activityEntranceData.banner_resource, function(s, o, arg)
    if o then
      self.ui.mImage_Bg.sprite = o
    else
      self.ui.mImage_Bg.sprite = IconUtils.GetAtlasSprite("RecentActivitie/" .. self.activityEntranceData.banner_resource)
    end
  end)
  self:RefreshTimer()
end

function UIRecentActivityTab:Update()
end

function UIRecentActivityTab:OnRelease(isDestroy)
  self.activityEntranceData = nil
  self.activityConfigData = nil
  self.index = nil
  self.onClickCallback = nil
  self.ui = nil
  self.super.OnRelease(self, isDestroy)
end

function UIRecentActivityTab:AddActivityEndCallback(callback)
  self.activityEndCallback = callback
end

function UIRecentActivityTab:GetIndex()
  return self.index
end

function UIRecentActivityTab:GetActivityEntranceData()
  return self.activityEntranceData
end

function UIRecentActivityTab:GetActivityConfigData()
  return self.activityConfigData
end

function UIRecentActivityTab:GetActivityModuleData()
  return self.activityModuleData
end

function UIRecentActivityTab:IsFirstOpen()
  return NetCmdThemeData:GetThemeMessageBoxState(self.activityEntranceData.id) < 1
end

function UIRecentActivityTab:IsUnlock()
  return AccountNetCmdHandler:CheckSystemIsUnLock(self.activityConfigData.unlock_id)
end

function UIRecentActivityTab:RefreshTimer()
  setactive(self.ui.mTrans_Time.gameObject, true)
  setactive(self.ui.mTrans_End.gameObject, false)
  if not self.planActivityData then
    return
  end
  if self.activityModuleData.stage_type == 3 then
    self.ui.mText_Time.text = "\229\183\178\231\187\147\230\157\159"
    setactivewithcheck(self.ui.mCountdown, true)
    setactive(self.ui.mTrans_Time.gameObject, false)
    setactive(self.ui.mTrans_End.gameObject, true)
    return
  end
  self.ui.mCountdown:StartCountdown(self.planActivityData.close_time + 1)
  setactivewithcheck(self.ui.mCountdown, true)
end

function UIRecentActivityTab:onTimerEmd(succ)
  if not succ then
    return
  end
  self:SetVisible(false)
  if self.activityEndCallback then
    self.activityEndCallback(self.index)
  end
end

function UIRecentActivityTab:onClickSelf()
  if not self.isUnlock then
    local lockInfo = TableData.listUnlockDatas:GetDataById(self.activityConfigData.unlock_id)
    if lockInfo then
      local str = UIUtils.CheckUnlockPopupStr(lockInfo)
      PopupMessageManager.PopupString(str)
    end
    return
  end
  if CGameTime:GetTimestamp() < self.planActivityData.open_time then
    local str = TableData.GetHintById(272000)
    CS.PopupMessageManager.PopupString(str)
    return
  end
  if CGameTime:GetTimestamp() >= self.planActivityData.close_time then
    local str = TableData.GetHintById(272001)
    CS.PopupMessageManager.PopupString(str)
    return
  end
  if CS.UIUtils.GetTouchClicked() then
    return
  end
  CS.UIUtils.SetTouchClicked()
  if self.onClickCallback then
    self.onClickCallback(self.index)
  end
end

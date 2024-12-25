require("UI.UIBaseCtrl")
Btn_RecentActivitieCombatEnterItem = class("Btn_RecentActivitieCombatEnterItem", UIBaseCtrl)
Btn_RecentActivitieCombatEnterItem.__index = Btn_RecentActivitieCombatEnterItem

function Btn_RecentActivitieCombatEnterItem:ctor()
end

function Btn_RecentActivitieCombatEnterItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
    CS.LuaUIUtils.SetParent(instObj.gameObject, parent.gameObject, true)
  end
  self:SetRoot(instObj.transform)
  UIUtils.AddBtnClickListener(self.ui.mBtn_RecentActivitieCombatEnterItem.gameObject, function()
    if self.data.id == 1 then
      if TipsManager.NeedLockTips(SystemList.Darkzone) then
        return
      end
      local isOpenTime = self.isDarkZoneOpenTime
      if not isOpenTime then
        local str = TableData.GetHintById(200003)
        CS.PopupMessageManager.PopupString(str)
        MessageSys:SendMessage(GuideEvent.OnTabSwitchFail, nil)
        return
      end
      if CS.UIUtils.GetTouchClicked() then
        return
      end
      CS.UIUtils.SetTouchClicked()
      if not GFUtils.IsOverseaServer() then
        UIManager.OpenUI(UIDef.UIDarkZoneMainPanel)
      end
    elseif self.data.id == 2 then
      if not AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.ControlFight, true) then
        return
      end
      if not self.isInOpenTime then
        CS.PopupMessageManager.PopupString(TableData.GetHintById(103080))
        return
      end
      if CS.UIUtils.GetTouchClicked() then
        return
      end
      CS.UIUtils.SetTouchClicked()
      NetCmdControlFightData:ControlFightSetUnlocked(true)
      UIManager.OpenUI(CS.GF2.UI.enumUIPanel.UIControlFightChapterPanel)
    elseif self.data.id == 4 then
      CS.LuaUIUtils.OpenDarkZoneEntrance()
    end
  end)
  self.ui.mCountdown:AddFinishCallback(function(succ)
    self:onTimerEmd(succ)
  end)
end

function Btn_RecentActivitieCombatEnterItem:SetVisible(isShow)
  setactive(self.ui.mBtn_RecentActivitieCombatEnterItem.gameObject, isShow)
end

function Btn_RecentActivitieCombatEnterItem:onTimerEmd(succ)
  self:SetVisible(false)
end

function Btn_RecentActivitieCombatEnterItem:SetData(data)
  self.data = data
  self.ui.mText_Name.text = data.name.str
  self.ui.mImg_Bg.sprite = IconUtils.GetAtlasSprite("RecentActivitie/" .. data.background)
  self.activityLock = data.unlock > 0 and not AccountNetCmdHandler:CheckSystemIsUnLock(data.unlock)
  self.isInOpenTime = false
  setactive(self.ui.mTrans_RedPoint.gameObject, false)
  if not self.activityLock then
    if data.id == 1 and not GFUtils.IsOverseaServer() then
      NetCmdRecentActivityData:ReqPlanActivityData(PlanType.PlanFunctionDarkzone, function(ret)
        if ret ~= ErrorCodeSuc then
          return
        end
        local sc_planActivityData = NetCmdRecentActivityData:GetPlanActivityData()
        local planActivityIdList = sc_planActivityData.ActiveIds
        local nextPlanActivityIdList = sc_planActivityData.NextIds
        self.isDarkZoneOpenTime = true
        if self.ui.mTrans_RedPoint ~= nil and self.ui.mTrans_RedPoint.gameObject ~= nil then
          setactive(self.ui.mTrans_RedPoint.gameObject, NetCmdRecentActivityData:CheckRecentActivityDarkZoneRedPoint() and self.isDarkZoneOpenTime)
        end
      end)
    elseif data.id == 2 then
      NetCmdControlFightData:ReqControlFightInfo(function(ret)
        if ret ~= ErrorCodeSuc then
          return
        end
        if self.ui.mTrans_RedPoint ~= nil and self.ui.mTrans_RedPoint.gameObject ~= nil then
          setactive(self.ui.mTrans_RedPoint.gameObject, NetCmdControlFightData:ControlFightHasRedPoint())
        end
      end)
    elseif data.id == 4 then
      setactive(self.ui.mTrans_RedPoint.gameObject, CS.LuaUIUtils.GetWeeklyInfoIsShowRedPoint())
    end
  end
  setactive(self.ui.mTrans_Time.gameObject, false)
  setactive(self.ui.mTrans_Lock.gameObject, true)
  setactive(self.ui.mTrans_ImgUnOpne.gameObject, true)
  if 0 < data.plan_type then
    if self.activityLock then
      setactive(self.ui.mTrans_ImgUnOpne.gameObject, false)
      setactive(self.ui.mTrans_ImgLock.gameObject, true)
    else
      setactive(self.ui.mTrans_ImgLock.gameObject, false)
      local planData = NetCmdRecentActivityData:GetLimitPlanBySys(data.plan_type)
      if planData then
        self.ui.mCountdown:StartCountdown(planData.close_time + 1)
        setactivewithcheck(self.ui.mCountdown, true)
        setactive(self.ui.mTrans_Time.gameObject, true)
        setactive(self.ui.mTrans_Lock.gameObject, false)
        self.isInOpenTime = true
      end
    end
  elseif data.id == 1 then
    local modeData = TableData.listDarkzoneModeScheduleDatas:GetDataById(1001)
    if modeData then
      self.ui.mCountdown:StartCountdown(modeData.EndTime)
      setactivewithcheck(self.ui.mCountdown, true)
      setactive(self.ui.mTrans_Time.gameObject, true)
      setactive(self.ui.mTrans_Lock.gameObject, false)
      self.isInOpenTime = true
    end
  else
    setactive(self.ui.mTrans_Lock.gameObject, self.activityLock)
    setactive(self.ui.mTrans_ImgUnOpne.gameObject, false)
  end
end

require("UI.ActivityTheme.Cafe.ActivityCafeGlobal")
UIActivityCafeJumpItem = class("UIActivityCafeJumpItem", UIBaseCtrl)

function UIActivityCafeJumpItem:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function UIActivityCafeJumpItem:InitCtrl(parent, prefab, data, onJumpClick, parentPanel)
  local instObj = instantiate(prefab, parent)
  self:SetRoot(instObj.transform)
  self.articleData = TableData.listActivitySimArticleDatas:GetDataById(data.article_id)
  self.sceneData = data
  local simHelper = self:GetSimHelper()
  if simHelper == nil then
    return
  end
  self.activityModel = simHelper.ModelManager:GetActivityArticleModelByConfigId(data.article_id)
  self.onJumpClick = onJumpClick
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  self.ui.mTrans_Arrow = instObj.transform:Find("ImgArrow")
  self.ui.mText_Name.text = self.articleData.article_name_show.str
  self.parentPanel = parentPanel
  self.activityConfigData = self.parentPanel.activityConfigData
  self.activityEntranceData = self.parentPanel.activityEntranceData
  self.activityModuleData = self.parentPanel.activityModuleData
  self.activityId = NetCmdActivityDarkZone:GetCurrActivityID(SubmoduleType.ActivityDarkzone, self.activityConfigData.Id)
  if self.articleData.ArticleId == 202 then
    self.ui.mText_Name.text = self.articleData.article_name_show.str .. " " .. string_format(TableData.GetHintById(901061), NetCmdActivityDarkZone.mCarLevel)
  end
  self.parent = parent
  self.uiCamera = UISystem.UICamera
  UIUtils.GetButtonListener(self.ui.mBtn_self.gameObject).onClick = function()
    if self.articleData.ArticleId == 201 then
      if not self.unlock then
        PopupMessageManager.PopupString(self.hintStr)
        return
      end
      if NetCmdActivitySimData.IsOpenCarrierPanel then
        UISystem:CloseUIForce(UIDef.UIActivityCafeMainPanel)
        return
      end
      self.onJumpClick()
      NetCmdActivitySimData.IsOpenDarkzone = true
      self.parentPanel:CallWithAniDelay(function()
        local simHelper = self:GetSimHelper()
        if simHelper == nil then
          return
        end
        simHelper:SetEnabled(false)
        UISystem:JumpByUIType(self.articleData.open_ui)
      end)
    elseif self.articleData.ArticleId == 202 then
      if not self.unlock then
        PopupMessageManager.PopupString(self.hintStr)
        return
      end
      self.onJumpClick()
      self.parentPanel:CallWithAniDelay(function()
        UISystem:JumpByUIType(self.articleData.open_ui)
      end)
    else
      self.onJumpClick()
      self.parentPanel:CallWithAniDelay(function()
        UISystem:JumpByUIType(self.articleData.open_ui)
      end)
    end
  end
  setactive(self:GetRoot(), false)
  self:UpdateState()
  
  function self.updatePosfunc()
    self:UpdatePos()
  end
  
  MessageSys:AddListener(UIEvent.SimCameraMoveEnd, self.updatePosfunc)
end

function UIActivityCafeJumpItem:OnRelease()
  MessageSys:RemoveListener(UIEvent.SimCameraMoveEnd, self.updatePosfunc)
  gfdestroy(self:GetRoot())
end

function UIActivityCafeJumpItem:UpdateVision(vision)
  self.vision = vision
  if self.vision ~= 4 - self.sceneData.scene_area then
    setactive(self:GetRoot(), false)
  end
  setactive(self.ui.mTrans_RedPoint.parent, false)
  self:UpdateState()
end

function UIActivityCafeJumpItem:UpdatePos()
  local simHelper = self:GetSimHelper()
  if simHelper == nil then
    return
  end
  self.activityModel = simHelper.ModelManager:GetActivityArticleModelByConfigId(self.sceneData.article_id)
  if self.activityModel == nil then
    return
  end
  self.pos = self.activityModel:GetTopPos()
  setactive(self:GetRoot(), self.vision == 4 - self.sceneData.scene_area)
  local scene = SceneSys:GetActivitySimScene()
  if scene then
    self.ui.mTrans_Enter.anchoredPosition = scene:SetUIPos(self.pos, self.parent, self.uiCamera)
  end
end

function UIActivityCafeJumpItem:UpdateRedPoint()
  if self.articleData.ArticleId == 202 then
    self:UpdateMachineryRedPoint()
  elseif self.articleData.ArticleId == 201 then
    self:UpdateCarrierRedPoint()
  end
end

function UIActivityCafeJumpItem:UpdateState()
  if self.articleData.ArticleId == 202 then
    self:UpdateDarkMachineLock()
    self:UpdateMachineryRedPoint()
    self:UpdateInfo()
  elseif self.articleData.ArticleId == 201 then
    self:UpdateDarkCarrierLock()
    self:UpdateCarrierRedPoint()
  else
    setactive(self.ui.mTrans_RedPoint.parent, false)
  end
end

function UIActivityCafeJumpItem:UpdateInfo()
  if self.articleData.ArticleId == 202 then
    self.ui.mText_Name.text = self.articleData.article_name_show.str .. " " .. string_format(TableData.GetHintById(901061), NetCmdActivityDarkZone.mCarLevel)
  end
end

function UIActivityCafeJumpItem:UpdateMachineryRedPoint()
  self:SetRedPoint(NetCmdActivityDarkZone:CheckCarLevelCanUp())
end

function UIActivityCafeJumpItem:UpdateCarrierRedPoint()
  self:SetRedPoint(NetCmdActivityDarkZone:GetDarkZoneCarrierRedPoint(self.activityConfigData.id) > 0)
end

function UIActivityCafeJumpItem:SetRedPoint(isShow)
  setactive(self.ui.mTrans_RedPoint.parent, isShow and self.unlock)
end

function UIActivityCafeJumpItem:UpdateDarkCarrierLock()
  self.unlockId = TableData.listActivityDarkzoneDatas:GetDataById(self.activityId).unlock
  self.unlock = true
  if self.unlockId == 0 then
    self.hintStr = ""
    self.unlock = true
  else
    local d = TableData.GetUnLockInfoByType(self.unlockId)
    if d then
      self.unlock = AccountNetCmdHandler:CheckSystemIsUnLock(self.unlockId)
    end
    self.hintStr = UIUtils.CheckUnlockPopupStr(d)
  end
  setactive(self.ui.mTrans_Lock, not self.unlock)
  if self.ui.mTrans_Arrow then
    setactive(self.ui.mTrans_Arrow, self.unlock)
  end
end

function UIActivityCafeJumpItem:UpdateDarkMachineLock()
  self.gamePlayId = NetCmdActivityDarkZone:GetCurrGamePlayID(SubmoduleType.ActivityDarkzone, self.activityConfigData.id)
  self.unlockId = TableData.listDzActivityGameplayDatas:GetDataById(self.gamePlayId).talent_entrance_unlock
  self.unlock = true
  if self.unlockId == 0 then
    self.hintStr = ""
    self.unlock = true
  else
    local d = TableData.GetUnLockInfoByType(self.unlockId)
    if d then
      self.unlock = AccountNetCmdHandler:CheckSystemIsUnLock(self.unlockId)
    end
    self.hintStr = UIUtils.CheckUnlockPopupStr(d)
  end
  setactive(self.ui.mTrans_Lock, not self.unlock)
  if self.ui.mTrans_Arrow then
    setactive(self.ui.mTrans_Arrow, self.unlock)
  end
end

function UIActivityCafeJumpItem:GetSimHelper()
  return CS.Activities.ActivitySim.ActivitySimHelper.Instance
end

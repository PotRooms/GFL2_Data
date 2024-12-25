require("UI.UIBasePanel")
require("UI.Common.ComBtnInputKeyPC")
require("UI.Lounge.DormGlobal")
UIDormVisualVPanel = class("UIDormVisualVPanel", UIBasePanel)
UIDormVisualVPanel.__index = UIDormVisualVPanel

function UIDormVisualVPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Is3DPanel = true
end

function UIDormVisualVPanel:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListener()
  self:InitContent()
  self.mCSPanel.AutoShowNextPanel = true
  DormGlobal.ChangeOrientation()
end

function UIDormVisualVPanel:AddBtnListener()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    LoungeHelper.CameraCtrl.isDebug = false
    DormGlobal.IsResetOrientation = true
    LoungeHelper.PhysicSimulate(false)
    UIManager.CloseUI(UIDef.UIDormVisualVPanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    DormGlobal.jumptomainpanel = true
    if LoungeHelper.CameraCtrl ~= nil then
      LoungeHelper.CameraCtrl:SetCanSendMessage(false)
    end
    DormGlobal.IsResetOrientation = true
    UISystem:JumpToMainPanel()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onDown = function()
    self:SetUIClick(true)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Top.gameObject).onDown = function()
    self:MoveForward(DormGlobal.Direction.Forward)
    self:SetUIClick(true)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onUp = function()
    self:SetUIClick(false)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Right.gameObject).onDown = function()
    self:MoveRight(DormGlobal.Direction.Right)
    self:SetUIClick(true)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Bottom.gameObject).onDown = function()
    self:MoveBack(DormGlobal.Direction.Back)
    self:SetUIClick(true)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Left.gameObject).onDown = function()
    self:MoveLeft(DormGlobal.Direction.Left)
    self:SetUIClick(true)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Top.gameObject).onUp = function()
    self:MoveForward(DormGlobal.Direction.None)
    self:SetUIClick(false)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Right.gameObject).onUp = function()
    self:MoveRight(DormGlobal.Direction.None)
    self:SetUIClick(false)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Bottom.gameObject).onUp = function()
    self:MoveBack(DormGlobal.Direction.None)
    self:SetUIClick(false)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Left.gameObject).onUp = function()
    self:MoveLeft(DormGlobal.Direction.None)
    self:SetUIClick(false)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Reset.gameObject).onClick = function()
    LoungeHelper.CameraCtrl.CameraPreObj:ResetCamera()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Hide.gameObject).onClick = function()
    self:OnHideClick()
  end
  
  function self.ui.mTouchPad.PointerDownHandler(eventData)
    CS.LoungeModelManager.Instance:PlayTouchEffect(eventData)
  end
end

function UIDormVisualVPanel:AddListener()
  if self.updateOrient ~= nil then
    return
  end
  
  function self.updateOrient(message)
    self:UpdateOrient(message)
  end
  
  MessageSys:AddListener(CS.GF2.Message.LoungeEvent.CameraDirChange, self.updateOrient)
end

function UIDormVisualVPanel:RemoveListener()
  if self.updateOrient ~= nil then
    MessageSys:RemoveListener(CS.GF2.Message.LoungeEvent.CameraDirChange, self.updateOrient)
    self.updateOrient = nil
  end
end

function UIDormVisualVPanel:InitContent()
  self.isShow = not DormGlobal.IsShowUI
  self:OnHideClick()
end

function UIDormVisualVPanel:OnShowFinish()
  LoungeHelper.CameraCtrl.isDebug = true
  LoungeHelper.PhysicSimulate(true)
  if LoungeHelper.CameraCtrl ~= nil then
    setactive(LoungeHelper.CameraCtrl, true)
  end
  self:AddListener()
end

function UIDormVisualVPanel:SetUIClick(bool)
  CS.LoungeCameraPreObj.isUIClick = bool
end

function UIDormVisualVPanel:MoveLeft(Direction)
  CS.LoungeCameraPreObj.eNowDirection = Direction
end

function UIDormVisualVPanel:MoveRight(Direction)
  CS.LoungeCameraPreObj.eNowDirection = Direction
end

function UIDormVisualVPanel:MoveForward(Direction)
  CS.LoungeCameraPreObj.eNowDirection = Direction
end

function UIDormVisualVPanel:MoveBack(Direction)
  CS.LoungeCameraPreObj.eNowDirection = Direction
end

function UIDormVisualVPanel:OnHide()
  if LoungeHelper.CameraCtrl ~= nil then
    setactive(LoungeHelper.CameraCtrl, false)
  end
end

function UIDormVisualVPanel:OnHideFinish()
  if DormGlobal.IsResetOrientation then
    DormGlobal.IsChangeOrientation = false
    gfdebug("UIDormVisualVPanel " .. tostring(CS.UnityEngine.Screen.orientation))
    SceneSys:ResetScreenOrientation()
    self.ui.mBtn_AniTime.m_FadeOutTime = 0.33
  end
  self:RemoveListener()
end

function UIDormVisualVPanel:OnClose()
  self:UnRegistrationKeyboard(KeyCode.Escape)
  LoungeHelper.PhysicSimulate(false)
  LoungeHelper.CameraCtrl.isDebug = false
  if LoungeHelper.CameraCtrl ~= nil then
    setactive(LoungeHelper.CameraCtrl, false)
  end
end

function UIDormVisualVPanel:OnRelease()
end

function UIDormVisualVPanel:OnUpdate()
end

function UIDormVisualVPanel:OnHideClick()
  self.isShow = not self.isShow
  setactivewithcheck(self.ui.mTrans_Action, self.isShow)
  setactivewithcheck(self.ui.mTrans_Icon1, self.isShow)
  setactivewithcheck(self.ui.mTrans_Left, self.isShow)
  setactivewithcheck(self.ui.mTrans_Reset, self.isShow)
  setactivewithcheck(self.ui.mTrans_Icon2, not self.isShow)
  DormGlobal.IsShowUI = self.isShow
end

function UIDormVisualVPanel:UpdateOrient(message)
  local orientation = message.Sender
  gfdebug("UIDormVisualVPanel orientation " .. tostring(orientation))
  if orientation == CS.UnityEngine.ScreenOrientation.LandscapeLeft or orientation == CS.UnityEngine.ScreenOrientation.LandscapeRight or orientation == CS.UnityEngine.ScreenOrientation.Landscape then
    if not LuaUtils.IsNullOrDestroyed(self.ui.mBtn_AniTime) then
      self.ui.mBtn_AniTime.m_FadeOutTime = 0
    end
    if not LuaUtils.IsNullOrDestroyed(self.mCSPanel) then
      self.mCSPanel.AutoShowNextPanel = false
    end
    DormGlobal.IsShowUI = true
    UIManager.CloseUI(UIDef.UIDormVisualVPanel)
    UIManager.OpenUI(UIDef.UIDormVisualHPanel)
  end
end

function UIDormVisualVPanel:OnCameraStart()
  return 0.01
end

function UIDormVisualVPanel:OnCameraBack()
  return 0.01
end

function UIDormVisualVPanel:OnRelease()
  if DormGlobal.IsChangeOrientation then
    DormGlobal.IsChangeOrientation = false
    SceneSys:ResetScreenOrientation()
    self:RemoveListener()
  end
end

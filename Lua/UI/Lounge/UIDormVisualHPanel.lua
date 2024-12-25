require("UI.UIBasePanel")
require("UI.Common.ComBtnInputKeyPC")
require("UI.Lounge.DormGlobal")
UIDormVisualHPanel = class("UIDormVisualHPanel", UIBasePanel)
UIDormVisualHPanel.__index = UIDormVisualHPanel

function UIDormVisualHPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Is3DPanel = true
end

function UIDormVisualHPanel:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListener()
  self:InitContent()
  self.closeTime = 0.01
  self.mCSPanel.AutoShowNextPanel = true
  DormGlobal.ChangeOrientation()
  self.isChanging = false
  self:UpdateRedPoint()
end

function UIDormVisualHPanel:UpdateRedPoint()
  setactive(self.ui.mTrans_RedPoint.gameObject, NetCmdLoungeData:GetDormSetRed(NetCmdLoungeData:GetCurrGunId()))
end

function UIDormVisualHPanel:AddBtnListener()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    LoungeHelper.CameraCtrl.isDebug = false
    DormGlobal.IsResetOrientation = true
    LoungeHelper.PhysicSimulate(false)
    NetCmdLoungeData:SetCameraEditor(false)
    UIManager.CloseUI(UIDef.UIDormVisualHPanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    DormGlobal.jumptomainpanel = true
    NetCmdLoungeData:SetIsInMainPanel(true)
    self.closeTime = 0
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
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onUp = function()
    self:SetUIClick(false)
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
    NetCmdLoungeData:SetCameraReserve(false)
    LoungeHelper.InteractManager:ResetCameraPos()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Hide.gameObject).onClick = function()
    self:OnHideClick()
  end
  
  function self.ui.mTouchPad.PointerDownHandler(eventData)
    CS.LoungeModelManager.Instance:PlayTouchEffect(eventData)
  end
  
  UIUtils.GetButtonListener(self.ui.mBtn_AddCommandCenter.gameObject).onClick = function()
    self:SetVisible(false)
    setactive(self.ui.mTrans_RedPoint.gameObject, false)
    NetCmdLoungeData:SetDormSetRed(1)
    local tmpCommandBGData = TableData.listCommandBackgroundDatas:GetDataById(NetCmdLoungeData.LoungeBackgroundId)
    local param = CS.UIDormCommandCenterBgSetDialog.UIParam()
    param.BGName = tmpCommandBGData.Name.str
    
    function param.ConfirmCallback()
      if CS.UIUtils.GetTouchClicked() then
        return
      end
      CS.UIUtils.SetTouchClicked()
      NetCmdCommandCenterData:ReqBackgroundChange(NetCmdLoungeData.LoungeBackgroundId, function(ret)
        if ret == ErrorCodeSuc then
          LoungeHelper.CameraCtrl.CameraPreObj.CameraFocusObj:ResetFocusPos()
          NetCmdLoungeData.IsSetDormBg = true
          NetCmdLoungeData:SaveLoungeData()
          UIManager.CloseUI(CS.GF2.UI.enumUIPanel.UIDormCommandCenterBgSetDialog)
          NetCmdCommandCenterData:SetBackground(NetCmdLoungeData.LoungeBackgroundId)
          NetCmdCommandCenterData:SetSelectBackGroundId(NetCmdLoungeData.LoungeBackgroundId)
          CS.PopupMessageManager.PopupPositiveString(TableData.GetHintById(113008))
        end
      end)
    end
    
    UISystem:OpenUI(enumUIPanel.UIDormCommandCenterBgSetDialog, param)
  end
  self:RegistrationKeyboard(KeyCode.Escape, self.ui.mBtn_Back)
end

function UIDormVisualHPanel:AddListener()
  if self.updateOrient ~= nil then
    return
  end
  
  function self.updateOrient(message)
    self:UpdateOrient(message)
  end
  
  MessageSys:AddListener(CS.GF2.Message.LoungeEvent.CameraDirChange, self.updateOrient)
end

function UIDormVisualHPanel:RemoveListener()
  if self.updateOrient ~= nil then
    MessageSys:RemoveListener(CS.GF2.Message.LoungeEvent.CameraDirChange, self.updateOrient)
    self.updateOrient = nil
  end
end

function UIDormVisualHPanel:InitContent()
  self.isShow = DormGlobal.IsShowUI
  setactivewithcheck(self.ui.mTrans_RockInfo, self.isShow)
  setactivewithcheck(self.ui.mTrans_Left, self.isShow)
  setactivewithcheck(self.ui.mTrans_Reset, self.isShow)
  setactivewithcheck(self.ui.mBtn_AddCommandCenter, self.isShow)
  if CS.GameRoot.Instance.AdapterPlatform == CS.PlatformSetting.PlatformType.Mobile then
    setactivewithcheck(self.ui.mTrans_Action, self.isShow)
  end
  setactivewithcheck(self.ui.mTrans_Icon1, self.isShow)
  setactivewithcheck(self.ui.mTrans_Icon2, not self.isShow)
  self.BtnResetKeyPC = ComBtnInputKeyPC.New()
  self.BtnResetKeyPC:InitCtrl(self.ui.mBtn_ResetPC, {
    self.ui.mTrans_RockInfo,
    self.ui.mTrans_Left,
    self.ui.mTrans_Reset,
    self.ui.mBtn_AddCommandCenter
  }, self, KeyCode.Mouse2, "Mouse2")
  self.BtnInputKeyPC = ComBtnInputKeyPC.New()
  self.BtnInputKeyPC:InitCtrl(self.ui.mBtn_HidePC, {
    self.ui.mTrans_RockInfo,
    self.ui.mTrans_Left,
    self.ui.mTrans_Reset,
    self.ui.mBtn_AddCommandCenter,
    self.BtnResetKeyPC:GetRoot()
  }, self, KeyCode.H, "H", function()
    DormGlobal.IsShowUI = not DormGlobal.IsShowUI
  end)
  self.topKeyUI = {}
  self.bottomKeyUI = {}
  self.leftKeyUI = {}
  self.rightKeyUI = {}
  if CS.GameRoot.Instance.AdapterPlatform == CS.PlatformSetting.PlatformType.PC then
    self:ShowKeyText(self.ui.mBtn_LeftPC.gameObject, self.leftKeyUI, "A")
    self:ShowKeyText(self.ui.mBtn_TopPC.gameObject, self.topKeyUI, "W")
    self:ShowKeyText(self.ui.mBtn_RightPC.gameObject, self.rightKeyUI, "D")
    self:ShowKeyText(self.ui.mBtn_BottomPC.gameObject, self.bottomKeyUI, "S")
  else
  end
end

function UIDormVisualHPanel:ShowKeyText(obj, table, str)
  local pcKey = obj.transform:Find("PCKey_Content")
  self:LuaUIBindTable(pcKey, table)
  table.mText_InputKey.text = str
end

function UIDormVisualHPanel:OnShowFinish()
  LoungeHelper.CameraCtrl.isDebug = true
  LoungeHelper.PhysicSimulate(true)
  if LoungeHelper.CameraCtrl ~= nil then
    setactive(LoungeHelper.CameraCtrl, true)
  end
  self:AddListener()
  local orientation = CS.UnityEngine.Screen.orientation
  local platform = CS.UnityEngine.Application.platform
  if platform == CS.UnityEngine.RuntimePlatform.WindowsEditor or platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer then
    return
  end
  if (orientation == CS.UnityEngine.ScreenOrientation.Portrait or orientation == CS.UnityEngine.ScreenOrientation.PortraitUpsideDown) and self.isChanging == false then
    self.ui.mBtn_AniTime.m_FadeOutTime = 0
    self.mCSPanel.AutoShowNextPanel = false
    self.isChanging = true
    DormGlobal.IsShowUI = true
    UIManager.CloseUI(UIDef.UIDormVisualHPanel)
    UIManager.OpenUI(UIDef.UIDormVisualVPanel)
  end
end

function UIDormVisualHPanel:SetUIClick(bool)
  CS.LoungeCameraPreObj.isUIClick = bool
end

function UIDormVisualHPanel:MoveLeft(Direction)
  CS.LoungeCameraPreObj.eNowDirection = Direction
end

function UIDormVisualHPanel:MoveRight(Direction)
  CS.LoungeCameraPreObj.eNowDirection = Direction
end

function UIDormVisualHPanel:MoveForward(Direction)
  CS.LoungeCameraPreObj.eNowDirection = Direction
end

function UIDormVisualHPanel:MoveBack(Direction)
  CS.LoungeCameraPreObj.eNowDirection = Direction
end

function UIDormVisualHPanel:OnHide()
  if LoungeHelper.CameraCtrl ~= nil then
    setactive(LoungeHelper.CameraCtrl, false)
  end
end

function UIDormVisualHPanel:OnHideFinish()
  if DormGlobal.IsResetOrientation then
    DormGlobal.IsChangeOrientation = false
    gfdebug("UIDormVisualHPanel " .. tostring(CS.UnityEngine.Screen.orientation))
    SceneSys:ResetScreenOrientation()
    self.ui.mBtn_AniTime.m_FadeOutTime = 0.33
  end
  self:RemoveListener()
end

function UIDormVisualHPanel:OnClose()
  self:SetVisible(true)
  self:UnRegistrationKeyboard(KeyCode.Escape)
  LoungeHelper.PhysicSimulate(false)
  LoungeHelper.CameraCtrl.isDebug = false
  if LoungeHelper.CameraCtrl ~= nil then
    setactive(LoungeHelper.CameraCtrl, false)
  end
end

function UIDormVisualHPanel:OnRelease()
  if DormGlobal.IsChangeOrientation then
    DormGlobal.IsChangeOrientation = false
    SceneSys:ResetScreenOrientation()
    self:RemoveListener()
  end
end

function UIDormVisualHPanel:OnHideClick()
  self.isShow = not self.isShow
  setactivewithcheck(self.ui.mTrans_Action, self.isShow)
  setactivewithcheck(self.ui.mTrans_Icon1, self.isShow)
  setactivewithcheck(self.ui.mTrans_Left, self.isShow)
  setactivewithcheck(self.ui.mTrans_Reset, self.isShow)
  setactivewithcheck(self.ui.mTrans_Icon2, not self.isShow)
  setactivewithcheck(self.ui.mBtn_AddCommandCenter, self.isShow)
  DormGlobal.IsShowUI = self.isShow
end

function UIDormVisualHPanel:UpdateOrient(message)
  local orientation = message.Sender
  gfdebug("UIDormVisualHPanel orientation " .. tostring(orientation))
  if (orientation == CS.UnityEngine.ScreenOrientation.Portrait or orientation == CS.UnityEngine.ScreenOrientation.PortraitUpsideDown) and self.isChanging == false then
    if not LuaUtils.IsNullOrDestroyed(self.ui.mBtn_AniTime) then
      self.ui.mBtn_AniTime.m_FadeOutTime = 0
    end
    if not LuaUtils.IsNullOrDestroyed(self.mCSPanel) then
      self.mCSPanel.AutoShowNextPanel = false
    end
    DormGlobal.IsShowUI = true
    self.isChanging = true
    UIManager.CloseUI(UIDef.UIDormVisualHPanel)
    UIManager.OpenUI(UIDef.UIDormVisualVPanel)
  end
end

function UIDormVisualHPanel:OnCameraStart()
  return self.closeTime or 0.01
end

function UIDormVisualHPanel:OnCameraBack()
  return self.closeTime
end

function UIDormVisualHPanel:OnTop()
  self:SetVisible(true)
  self:UpdateRedPoint()
end

require("UI.UIBasePanel")
require("UI.Lounge.Btn_DormMainFunctionItem")
require("UI.Lounge.DormGlobal")
DormMainPanel = class("DormMainPanel", UIBasePanel)
DormMainPanel.__index = DormMainPanel

function DormMainPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
  csPanel.Is3DPanel = true
end

function DormMainPanel:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self.formatString = TableData.GetHintById(280019)
  self:LuaUIBindTable(root, self.ui)
end

function DormMainPanel:UpdateUIState()
  setactive(self.ui.mTrans_NormalFeel, self.mGunCmdData.Id ~= NetCmdLoungeData.loveCharacterID)
  setactive(self.ui.mTrans_FavorFeel, self.mGunCmdData.Id == NetCmdLoungeData.loveCharacterID)
  self:UpdateRedPoint()
  self:SetPlayerPrefs()
end

function DormMainPanel:ManualUI()
  self.isShowUI = true
  NetCmdLoungeData:SetCameraEditor(false)
end

function DormMainPanel:OnInit(root, data)
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.DormMainPanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    DormGlobal.jumptomainpanel = true
    UISystem:JumpToMainPanel()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Visual.gameObject).onClick = function()
    NetCmdLoungeData:SetCameraEditor(true)
    NetCmdLoungeData:SetCameraReserve(true)
    self.isShowUI = not self.isShowUI
    self:UpdateUIState()
    UIManager.OpenUI(UIDef.UIDormVisualHPanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Feel.gameObject).onClick = function()
    self:onClickLove()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnChrChange.gameObject).onClick = function()
    UIManager.OpenUIByParam(UIDef.UIDormChrChangePanel, self.mGunCmdData)
  end
  
  function self.ui.mTouchPad.PointerDownHandler(eventData)
    CS.LoungeModelManager.Instance:PlayTouchEffect(eventData)
  end
  
  self.mTrans_TextBeta = self.ui.mText_Title.transform:Find("TextBeta")
  self.ossDeltaTime = 0
  setactive(self.mTrans_TextBeta.gameObject, not CS.AuditUtils:IsAudit())
  self:SetBaseData()
  self:UpdateName()
  self:InitFunctionItem()
  self:UpdateUIState()
  self:UpdateRedPoint()
  local info = CS.OssLoungeLog(1, NetCmdLoungeData:GetCurrGunId(), 0, NetCmdLoungeData:GetGunTimelineIdByGunId(NetCmdLoungeData:GetCurrGunId()))
  MessageSys:SendMessage(OssEvent.OnLoungeLog, null, info)
end

function DormMainPanel:OnAdditiveSceneLoaded(loadedScene, isOpen)
  if isOpen then
    LoungeHelper.CameraCtrl:SetCanSendMessage(true)
    self:ManualUI()
  end
end

function DormMainPanel:UpdateName()
  self.mGunCmdData = NetCmdLoungeData:GetCurrGunCmdData()
  self.gunData = TableData.listGunCharacterDatas:GetDataById(self.mGunCmdData.gunData.character_id)
  self.ui.mText_Title.text = string_format(self.formatString, self.gunData.name.str)
  NetCmdLoungeData:SendEnterDorm(self.mGunCmdData.gunData.id, function(ret)
    if ret == ErrorCodeSuc then
    end
  end)
end

function DormMainPanel:OnShowStart()
  NetCmdLoungeData:SetIsInMainPanel(false)
  DormGlobal.jumptomainpanel = false
  LoungeHelper.CameraCtrl.CameraPreObj:SetCameraFov()
  LoungeHelper.CameraCtrl.enabled = true
  NetCmdLoungeData.IsDormMute = false
end

function DormMainPanel:CleanCameraTime()
  if self.cameraTime then
    self.cameraTime:Stop()
    self.cameraTime = nil
  end
end

function DormMainPanel:OnShowFinish()
  self:CleanCameraTime()
  if LoungeHelper.CameraCtrl then
    LoungeHelper.CameraCtrl.isDebug = false
  else
    self.cameraTime = TimerSys:DelayCall(0.5, function()
      self:CleanCameraTime()
      if LoungeHelper.CameraCtrl then
        LoungeHelper.CameraCtrl.isDebug = false
      end
    end)
  end
  NetCmdLoungeData.IsDormMute = false
end

function DormMainPanel:OnTop()
  self:UpdateName()
  self:UpdateUIState()
  self:UpdateRedPoint()
  NetCmdLoungeData.IsDormMute = false
end

function DormMainPanel:OnBackFrom()
  LoungeHelper.CameraCtrl:SetCameraEnable(true)
  self:UpdateName()
  self:UpdateUIState()
  self:UpdateRedPoint()
  NetCmdLoungeData.IsDormMute = false
end

function DormMainPanel:OnUpdate()
  if self.ossDeltaTime == nil then
    self.ossDeltaTime = 0
  end
  self.ossDeltaTime = self.ossDeltaTime + Time.deltaTime
end

function DormMainPanel:OnClose()
  NetCmdLoungeData:SetIsInMainPanel(true)
  local gunId = NetCmdLoungeData:GetCurrGunId()
  local info = CS.OssLoungeLog(2, gunId, self.ossDeltaTime, NetCmdLoungeData:GetGunTimelineIdByGunId(gunId))
  MessageSys:SendMessage(OssEvent.OnLoungeLog, nil, info)
  NetCmdLoungeData:CleanGunTimeline()
  LoungeHelper.CameraCtrl:ResetCameraObjPos()
  self.isShowUI = true
  NetCmdLoungeData:SetCameraEditor(false)
  NetCmdLoungeData:SetCameraReserve(false)
  self:ReleaseCtrlTable(self.rightBtnList, true)
  self.rightBtnList = nil
  self:CleanCameraTime()
  LoungeHelper.CameraCtrl:SetCanSendMessage(false)
  if DormGlobal.jumptomainpanel or CS.NetCmdLoungeData.Instance.IsSetDormBg then
    CS.NetCmdLoungeData.Instance.IsSetDormBg = false
    SceneSys:GetHallScene():ChangeBackground(NetCmdCommandCenterData.Background)
  elseif SceneSys:GetHallScene().CurrentSceneType ~= CS.HallScene.SceneType.Lounge then
    SceneSys:UnloadLoungeScene()
  end
  NetCmdLoungeData.IsDormMute = true
end

function DormMainPanel:OnHide()
end

function DormMainPanel:ReleaseFovTimer()
  if self.fovTimer then
    self.fovTimer:Stop()
    self.fovTimer = nil
  end
end

function DormMainPanel:OnHideFinish()
  self:ReleaseFovTimer()
  if DormGlobal.IsSkinOpen then
    DormGlobal.IsSkinOpen = false
    self.fovTimer = TimerSys:DelayCall(0, function()
      LoungeHelper.CameraCtrl.CameraPreObj:EnterLookAt()
    end)
  end
end

function DormMainPanel:OnRelease()
  self:CleanCameraTime()
end

function DormMainPanel:SetBaseData()
  self.rightBtnList = {}
end

function DormMainPanel:InitFunctionItem()
  for i = 1, 4 do
    if self.rightBtnList[i] == nil then
      self.rightBtnList[i] = Btn_DormMainFunctionItem.New()
      self.rightBtnList[i]:InitCtrl(self.ui.mScrollListChild_TabFunctionList)
    end
  end
  self.rightBtnList[1]:SetBtnName(TableData.GetHintById(280020))
  self.rightBtnList[1]:SetClickFunction(function()
    UIManager.OpenUI(UIDef.UIDormChrBehaviourPanel)
  end)
  self.rightBtnList[1]:SetRedPoint(false)
  self.rightBtnList[1]:SetIcon("Icon_DormFunction_Behaviour")
  self.rightBtnList[2]:SetBtnName(TableData.GetHintById(280021))
  self.rightBtnList[2]:SetClickFunction(function()
    DormGlobal.IsSkinOpen = true
    UIManager.OpenUIByParam(UIDef.UIDormSkinChangePanel, self.mGunCmdData.id)
  end)
  self.rightBtnList[2]:SetRedPoint(NetCmdGunClothesData:IsAnyClothesDormNeedRedPoint(self.mGunCmdData.id))
  self.rightBtnList[2]:SetIcon("Icon_DormFunction_Skin")
  self.rightBtnList[3]:SetBtnName(TableData.GetHintById(280022))
  self.rightBtnList[3]:SetClickFunction(function()
    UIManager.OpenUI(UIDef.UIDormChrRecordSelectPanel)
  end)
  self.rightBtnList[3]:SetRedPoint(NetCmdLoungeData:DormChrDailyRedPointByGunID(self.mGunCmdData.id) > 0)
  self.rightBtnList[3]:SetIcon("Icon_DormFunction_Record")
  self.rightBtnList[4]:SetBtnName(TableData.GetHintById(280023))
  self.rightBtnList[4]:SetClickFunction(function()
    UIManager.OpenUIByParam(UIDef.UIDormPlayStoryDialog, {
      currData = self.gunData
    })
  end)
  self.rightBtnList[4]:SetRedPoint(0 < NetCmdLoungeData:DormChrStoryRedPointByGunID(self.mGunCmdData.id))
  self.rightBtnList[4]:SetIcon("Icon_DormFunction_Plot")
  self.rightBtnList[4]:SetLineVisible(false)
end

function DormMainPanel:onClickLove()
  local loveId = self.mGunCmdData.Id
  if loveId == NetCmdLoungeData.loveCharacterID then
    loveId = 0
  end
  NetCmdLoungeData:SendCS_DormSetLove(loveId, function()
    self:UpdateUIState()
    if loveId ~= 0 then
      CS.PopupMessageManager.PopupPositiveString(TableData.GetHintById(280025))
      self.ui.mAnimator_Feel:SetBool("Light", true)
    end
  end)
end

function DormMainPanel:UpdateRedPoint()
  self.rightBtnList[2]:SetRedPoint(NetCmdGunClothesData:IsAnyClothesDormNeedRedPoint(self.mGunCmdData.id))
  self.rightBtnList[3]:SetRedPoint(NetCmdLoungeData:DormChrDailyRedPointByGunID(self.mGunCmdData.id) > 0)
  self.rightBtnList[4]:SetRedPoint(0 < NetCmdLoungeData:DormChrStoryRedPointByGunID(self.mGunCmdData.id))
  setactive(self.ui.mTransChr_RedPoint, NetCmdLoungeData:GetDormRedPoint())
  setactive(self.ui.mTrans_RedPoint.gameObject, NetCmdLoungeData:GetDormSetRed(self.mGunCmdData.id))
end

function DormMainPanel:SetPlayerPrefs()
  local key = AccountNetCmdHandler:GetUID() .. "DormUnlock" .. self.mGunCmdData.Id
  PlayerPrefs.SetInt(key, 1)
end

require("UI.FacilityBarrackPanel.Content.UIModelToucher")
require("UI.FacilityBarrackPanel.FacilityBarrackGlobal")
require("UI.FacilityBarrackPanel.Content.UIChrStageUpPanel")
require("UI.FacilityBarrackPanel.UIChrTalent.UIChrTalentPanel")
require("UI.FacilityBarrackPanel.Content.UIChrOverviewPanel")
require("UI.FacilityBarrackPanel.Item.ChrBarrackTopBarItemV3")
UIChrPowerUpPanel = class("UIChrPowerUpPanel", UIBasePanel)
UIChrPowerUpPanel.__index = UIChrPowerUpPanel

function UIChrPowerUpPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Is3DPanel = true
end

function UIChrPowerUpPanel:OnAwake(root, data)
  self:SetRoot(root)
  self.contentList = {}
  self.curContent = nil
  self.tabItemList = {}
  self.curTabItem = nil
  self.mModelGameObject = nil
  self.mGunCmdData = nil
  self.mGunData = nil
  self.roleTemplateData = nil
  self.reflectionPanel = nil
  self.notCommandCenter = false
  self.isLockGun = false
  self.lastContentType = 0
  self.curContentType = 0
  self.gachaId = 0
  self.gachaGunId = 0
  self.delayCameraTimer = nil
  self.delayClickArrowTimer = nil
  self.isVisual = false
  self.setBackground = false
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:InitTab()
end

function UIChrPowerUpPanel:OnInit(root, data)
  self.notCommandCenter = false
  BarrackHelper.CameraMgr:ShowParticleObj(false)
  FacilityBarrackGlobal.CurShowContentType = FacilityBarrackGlobal.ShowContentType.UIChrOverview
  self.isVisual = false
  if data ~= nil and type(data) == "table" and 0 < #data then
    self.isVisual = data[1]
    data = nil
  end
  if self.isVisual then
    CS.NetCmdBarrackCameraData.Instance:ResetBarrackCameraData()
    BarrackHelper.CameraMgr.BarrackCharacterCameraCtrl:SetRotateEnabled(true)
  else
    BarrackHelper.CameraMgr.BarrackCharacterCameraCtrl:SetupBaseCameraStand()
  end
  if data == nil then
    if CS.UIBarrackModelManager.Instance.GunStcDataId == 0 or NetCmdTeamData:GetGunByID(CS.UIBarrackModelManager.Instance.GunStcDataId) == nil then
      self.mGunCmdData = NetCmdTeamData:GetFirstGun()
      local canUnlockGunCmdDataList = NetCmdTeamData:GetBarrackCanUnLockGunCmdDatas()
      if 0 < canUnlockGunCmdDataList.Count then
        self.mGunCmdData = canUnlockGunCmdDataList[0]
      end
    else
      self:GetCurGun()
    end
  elseif data and type(data) == "userdata" then
    if 1 < data.Length and data[1] ~= FacilityBarrackGlobal.ShowContentType.UIChrOverview then
      FacilityBarrackGlobal.SetTargetContentType(nil)
    end
    if 1 < data.Length and data[1] == FacilityBarrackGlobal.ShowContentType.UIGachaPreview then
      self.gachaId = data[2]
      self.gachaGunId = data[0]
      FacilityBarrackGlobal.CurShowContentType = FacilityBarrackGlobal.ShowContentType.UIGachaPreview
      self.notCommandCenter = false
      self.mGunCmdData = NetCmdTeamData:GetGachaPreviewGunData(data[0])
    elseif 1 < data.Length and data[1] == FacilityBarrackGlobal.ShowContentType.UIShopClothes then
      self.mGunCmdData = NetCmdTeamData:GetLockGunData(data[0], true)
      FacilityBarrackGlobal.CurShowContentType = FacilityBarrackGlobal.ShowContentType.UIShopClothes
      self.notCommandCenter = false
    elseif 1 < data.Length and data[1] == FacilityBarrackGlobal.ShowContentType.UIClothesPreview then
      self.mGunCmdData = NetCmdTeamData:GetLockGunData(data[0], true)
      FacilityBarrackGlobal.CurShowContentType = FacilityBarrackGlobal.ShowContentType.UIClothesPreview
      self.notCommandCenter = false
    elseif 1 < data.Length and data[1] == FacilityBarrackGlobal.ShowContentType.UIBpClothes then
      self.mGunCmdData = NetCmdTeamData:GetLockGunData(data[0], true)
      FacilityBarrackGlobal.CurShowContentType = FacilityBarrackGlobal.ShowContentType.UIBpClothes
      self.notCommandCenter = false
    elseif 1 < data.Length and data[1] == FacilityBarrackGlobal.ShowContentType.UIChrOverview then
      CS.UIBarrackModelManager.Instance:ResetGunStcDataId()
      local gunId = data[0]
      self.mGunCmdData = NetCmdTeamData:GetGunByID(gunId)
      if self.mGunCmdData == nil then
        self.mGunCmdData = NetCmdTeamData:GetFirstGun()
      end
      FacilityBarrackGlobal.CurShowContentType = FacilityBarrackGlobal.ShowContentType.UIChrOverview
    end
  else
    self.mGunCmdData = data[1]
    FacilityBarrackGlobal.CurShowContentType = data[2]
    self.notCommandCenter = true
  end
  if FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrBattlePass then
    FacilityBarrackGlobal.IsBattlePassMaxLevel = false
  end
  self.mGunData = self.mGunCmdData.TabGunData
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    self:OnBackBtnClick()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    FacilityBarrackGlobal.SetTargetContentType(nil)
    CS.UIBarrackModelManager.Instance:ResetGunStcDataId()
    UISystem:JumpToMainPanel()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnDescription.gameObject).onClick = function()
    if self.showGroupId == nil then
      self.showGroupId = 1101
    end
    if NetCmdTeachPPTData:GetGroupIdsByType(CS.EPPTGroupType.All):IndexOf(self.showGroupId) ~= -1 then
      local showTeachData = CS.ShowTeachPPTData()
      showTeachData.GroupId = self.showGroupId
      UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIGuidePPTDialog, showTeachData)
    else
      local newShowData = CS.ShowGuideDialogPPTData()
      newShowData.GroupId = self.showGroupId
      UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIComGuideDialogV2PPT, newShowData)
    end
  end
  UIUtils.GetButtonListener(self.ui.mBtn_PreGun.gameObject).onClick = function()
    self:SwitchGun(false)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_NextGun.gameObject).onClick = function()
    self:SwitchGun(true)
  end
  self.mCSPanel:BindEscButton()
  self:AddListener()
  BarrackHelper.InteractManager:SetVisualState(false)
end

function UIChrPowerUpPanel:OnShowStart(needBarrackEntrance, needChangeContent)
  SceneSys:SwitchVisible(EnumSceneType.Barrack)
  if needBarrackEntrance == nil then
    needBarrackEntrance = true
  end
  if needChangeContent == nil then
    needChangeContent = true
  end
  FacilityBarrackGlobal.SetNeedBarrackEntrance(needBarrackEntrance)
  setactive(UISystem.BarrackCharacterCameraCtrl.CharacterCamera, true)
  self:UpdateModel()
  if not self.isVisual then
    FacilityBarrackGlobal:SwitchCameraPos(BarrackCameraStand.Base, false)
  end
  if self.curContent ~= nil and self.curTabItem ~= nil then
    self.curTabItem:SetSelect(true)
  end
  if needChangeContent then
    self:ChangeContent(FacilityBarrackGlobal.ContentType.UIChrOverviewPanel, false)
    local chrOverviewPanel = self.contentList[FacilityBarrackGlobal.ContentType.UIChrOverviewPanel]
    if self.isVisual then
      chrOverviewPanel:VisualChanged(true, false)
    end
  end
  self:UpdateTabLock()
  CS.UIBarrackModelManager.Instance:ShowBarrackObjWithLayer(true)
  UIWeaponGlobal:ReleaseWeaponModel()
  if not self.isVisual then
    self:PlayFadeAnim(true, true)
  end
end

function UIChrPowerUpPanel:OnBackFrom()
  if self.curContentType == FacilityBarrackGlobal.ContentType.UIChrStageUpPanel then
    self:OnRecover(false)
    return
  end
  SceneSys:SwitchVisible(EnumSceneType.Barrack)
  if self.mGunCmdData == nil then
    self.mGunCmdData = NetCmdTeamData:GetFirstGun()
    self.mGunData = self.mGunCmdData.TabGunData
  else
    self:GetCurGun()
    self:UpdateModel()
  end
  if self.curContent ~= nil then
    self.curContent:OnBackFrom()
  end
  self:OtherPanelOrDialogBack()
  self:UpdateTabLock()
  CS.UIBarrackModelManager.Instance:ShowBarrackObjWithLayer(true)
  self:ResetEffectNumObj()
  if self.curContentType == FacilityBarrackGlobal.ContentType.UIChrTalentPanel then
    FacilityBarrackGlobal.HideEffectNum(false)
  end
  if FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview then
    FacilityBarrackGlobal.HideEffectNum(true)
  end
  if not self.isVisual then
    self:PlayFadeAnim(true, true)
  end
end

function UIChrPowerUpPanel:OnTop()
  SceneSys:SwitchVisible(EnumSceneType.Barrack)
  if self.curContent ~= nil then
    if self.curContentType == FacilityBarrackGlobal.ContentType.UIChrOverviewPanel and self.curContent ~= nil and self.curContent.isSetBg then
      self.curContent:ResetVisualTrans()
      if self.curContentType == FacilityBarrackGlobal.ContentType.UIChrOverviewPanel and self.curContent.isSetBg then
        self.curContent:SetVisible(true)
        self.curContent:UpdateBarrackCameraRedPoint()
        self.curContent.isSetBg = false
        return
      end
      self:PlayAnim(self.ui.mAnimator_Root, true)
      self:PlayAnim(self.curContent.ui.mAnimator_Root, true)
      return
    end
    self.curContent:OnTop()
  end
  self:OtherPanelOrDialogBack()
  self:UpdateTabLock()
  CS.UIBarrackModelManager.Instance:ShowBarrackObjWithLayer(true)
end

function UIChrPowerUpPanel:OnShowFinish()
  self:GetCurGun()
  self:SetTabShow()
  self.mIsRelatedBP = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrBattlePass or FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrBattlePassCollection
  if self.mIsRelatedBP then
    CS.UIBarrackModelManager.Instance:SetCurModelLock(false)
  else
    CS.UIBarrackModelManager.Instance:SetCurModelLock(self.isLockGun)
  end
  if self.curContent ~= nil then
    self.curContent:OnShowFinish()
  end
  self:UpdateTabRedPoint()
  local normalView = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrOverview
  local isGachaPreview = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview
  setactive(self.ui.mScrollListChild_TopRightBtn, normalView or isGachaPreview)
  setactive(self.ui.mAnimator_Arrow, normalView)
  self:UpdateTabLock()
  self:ActiveSwitchGunBtn(self.curContentType == FacilityBarrackGlobal.ContentType.UIChrStageUpPanel or self.curContentType == FacilityBarrackGlobal.ContentType.UIChrTalentPanel)
  self.createTalentPanelTimer = TimerSys:DelayFrameCall(1, function()
    local talentPanelType = FacilityBarrackGlobal.ContentType.UIChrTalentPanel
    if self.contentList[talentPanelType] == nil then
      self.contentList[talentPanelType] = self:CreateContentPanel(talentPanelType)
    end
  end)
end

function UIChrPowerUpPanel:OnUpdate(deltaTime)
  local talentPanelType = FacilityBarrackGlobal.ContentType.UIChrTalentPanel
  if self.contentList[talentPanelType] then
    local v = self.contentList[talentPanelType]
    v:OnUpdate()
  end
end

function UIChrPowerUpPanel:OnHide()
  if self.createTalentPanelTimer then
    self.createTalentPanelTimer:Stop()
  end
  for i, v in pairs(self.contentList) do
    if v.OnHide ~= nil then
      v:OnHide(true)
    end
  end
  self:PlayFadeAnim(false, true, true)
end

function UIChrPowerUpPanel:OnHideFinish()
  for i, v in pairs(self.contentList) do
    if v.OnHideFinish ~= nil then
      v:OnHideFinish(true)
    end
  end
end

function UIChrPowerUpPanel:OnSave()
  FacilityBarrackGlobal.SetTargetContentType(self.curContentType)
  self.notCommandCenter = true
end

function UIChrPowerUpPanel:OnRecover(needChangeContent)
  if needChangeContent == nil then
    needChangeContent = true
  end
  local targetContentType = FacilityBarrackGlobal.GetTargetContentType()
  if targetContentType == nil and self.curContentType ~= nil and self.curContentType ~= 0 then
    targetContentType = self.curContentType
  end
  SceneSys:SwitchVisible(EnumSceneType.Barrack)
  self.notCommandCenter = false
  CS.UIBarrackModelManager.Instance:ShowBarrackObjWithLayer(true)
  self:UpdateTabLock()
  self:ResetCurSelectTabItem()
  self:OnShowStart(false, needChangeContent)
  if targetContentType == nil then
    self:ChangeContent(FacilityBarrackGlobal.ContentType.UIChrOverviewPanel, false)
  else
    self:ChangeContent(targetContentType, false)
  end
  FacilityBarrackGlobal.SetTargetContentType(nil)
  if self.curContent ~= nil then
    self.curContent:OnRecover()
  end
  if FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview then
    FacilityBarrackGlobal.HideEffectNum(true)
  end
end

function UIChrPowerUpPanel:OnRefresh()
  self:UpdateTabRedPoint()
  self:UpdateTabLock()
  self:ActiveSwitchGunBtn(self.curContentType ~= FacilityBarrackGlobal.ContentType.UIChrOverviewPanel)
  if self.curContent.OnRefresh then
    self.curContent:OnRefresh()
  end
end

function UIChrPowerUpPanel:OnClose()
  if self.curTabItem ~= nil then
    self.curTabItem:SetSelect(false)
  end
  for i, v in pairs(self.contentList) do
    v:OnClose(true)
  end
  UIModelToucher.ReleaseWeaponToucher()
  UIModelToucher.ReleaseCharacterToucher()
  if self.delayCameraTimer ~= nil then
    self.delayCameraTimer:Stop()
  end
  if self.delayClickArrowTimer ~= nil then
    self.delayClickArrowTimer:Stop()
  end
  self.curContent = nil
  self.curTabItem = nil
  local curModel = CS.UIBarrackModelManager.Instance.curModel
  if curModel ~= nil and not CS.LuaUtils.IsNullOrDestroyed(curModel) then
    curModel:StopAudio()
  end
  if self.notCommandCenter == false and (FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrBattlePass or FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrBattlePassCollection) then
    SceneSys:SwitchVisible(EnumSceneType.BattlePass)
  elseif self.notCommandCenter == false and FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIShopClothes then
    SceneSys:SwitchVisible(EnumSceneType.Store)
  elseif self.notCommandCenter == false then
    if self.setBackground and NetCmdCommandCenterData.Background == NetCmdCommandCenterData.ConstBarrackID then
      SceneSys:GetHallScene():ChangeBackground(NetCmdCommandCenterData.Background)
    end
    SceneSys:SwitchVisible(EnumSceneType.HallScene)
    FacilityBarrackGlobal.ActiveEffectNum(false)
    if SceneSys.CurrentSingleScene ~= nil and SceneSys.CurrentSingleScene.OnUIShowFinish ~= nil then
      SceneSys.CurrentSingleScene:OnUIShowFinish(false)
    end
  end
  self:RemoveListener()
  setactive(FacilityBarrackGlobal.EffectNumObj, false)
end

function UIChrPowerUpPanel:OnRelease()
  self.super.OnRelease(self)
  for i, v in pairs(self.contentList) do
    v:OnRelease()
  end
  self.contentList = {}
end

function UIChrPowerUpPanel:OnCameraStart()
  if not self.curContent then
    return
  end
  if self.curContent.OnCameraStart ~= nil then
    return self.curContent:OnCameraStart()
  end
end

function UIChrPowerUpPanel:OnCameraBack()
  if not self.curContent then
    return
  end
  if self.curContent.OnCameraBack ~= nil then
    return self.curContent:OnCameraBack()
  end
end

function UIChrPowerUpPanel:InitTab()
  local tmpList = {}
  local tmpIndex = 1
  local tmpTabParent = self.ui.mScrollListChild_TopRightBtn.transform
  for i, v in pairs(FacilityBarrackGlobal.ContentType) do
    local tabItem = ChrBarrackTopBarItemV3.New()
    local callback = function(contentType)
      if TipsManager.NeedLockTips(tabItem.systemId) then
        return
      end
      FacilityBarrackGlobal.SetTargetContentType(contentType)
      self:ChangeContent(contentType)
      MessageSys:SendMessage(GuideEvent.OnTabSwitched, UIDef.UIChrPowerUpPanel, tabItem:GetGlobalTab())
    end
    if tmpIndex + 1 <= tmpTabParent.childCount then
      tabItem:InitCtrl(tmpTabParent.gameObject, v, callback, tmpTabParent:GetChild(tmpIndex - 1))
    else
      tabItem:InitCtrl(tmpTabParent.gameObject, v, callback)
    end
    self.tabItemList[v] = tabItem
    tmpList[tmpIndex] = tabItem
    tmpIndex = tmpIndex + 1
  end
  table.sort(tmpList, function(a, b)
    return a.contentType < b.contentType
  end)
  for i, tab in ipairs(tmpList) do
    tab.mUIRoot:SetSiblingIndex(i - 1)
  end
end

function UIChrPowerUpPanel:UpdateTabLock()
  for _, item in pairs(self.tabItemList) do
    item:UpdateSystemLock()
  end
end

function UIChrPowerUpPanel:CreateContentPanel(contentType)
  if contentType == FacilityBarrackGlobal.ContentType.UIChrOverviewPanel then
    local trans = self.ui.mScrollChild_Overview:Instantiate()
    return UIChrOverviewPanel.New(trans, self)
  elseif contentType == FacilityBarrackGlobal.ContentType.UIChrStageUpPanel then
    local trans = self.ui.mScrollChild_StageUp:Instantiate()
    return UIChrStageUpPanel.New(trans, self)
  elseif contentType == FacilityBarrackGlobal.ContentType.UIChrTalentPanel then
    local trans = self.ui.mScrollChild_Talent:Instantiate()
    return CS.UIChrTalentPanel(trans, self)
  end
end

function UIChrPowerUpPanel:ChangeContent(contentType, needBlending)
  if contentType == FacilityBarrackGlobal.ContentType.UIChrOverviewPanel then
    self.showGroupId = 1101
  elseif contentType == FacilityBarrackGlobal.ContentType.UIChrStageUpPanel then
    self.showGroupId = 1103
  elseif contentType == FacilityBarrackGlobal.ContentType.UIChrTalentPanel then
    self.showGroupId = 1208
  end
  local changeContent = function()
    needBlending = needBlending == nil and true or needBlending
    self.lastContentType = self.curContentType
    self.curContentType = contentType
    if self.curTabItem ~= nil and self.curTabItem.contentType == contentType then
      if self.contentList[self.curContentType].ShowUI ~= nil then
        self.contentList[self.curContentType]:ShowUI()
        if not needBlending then
          if contentType == FacilityBarrackGlobal.ContentType.UIChrStageUpPanel then
            BarrackHelper.CameraMgr:StartCameraMoving(BarrackCameraOperate.OverviewToGrade, not needBlending)
          elseif contentType == FacilityBarrackGlobal.ContentType.UIChrTalentPanel then
            BarrackHelper.CameraMgr:StartCameraMoving(BarrackCameraOperate.OverviewToTalentTree, not needBlending)
          end
        end
      end
      return
    end
    self:ShowMask(true)
    if self.contentList[self.curContentType] == nil then
      self.contentList[self.curContentType] = self:CreateContentPanel(contentType)
    end
    if self.contentList[self.curContentType].Init then
      self.contentList[self.curContentType]:Init(self.mGunCmdData)
    end
    local changeContentFunc = function()
      if self.curTabItem ~= nil then
        self:PlayFadeAnim(false)
        self:ActiveSwitchGunBtn(contentType ~= FacilityBarrackGlobal.ContentType.UIChrOverviewPanel)
        local cameraMoveEnd = function(attachTouch)
          self:SetSwitchGunBtnInteractable(true)
          self:PlayFadeAnim(true)
          self.contentList[self.lastContentType]:OnClose()
          if self.curContentType == FacilityBarrackGlobal.ContentType.UIChrTalentPanel and FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview then
            self.contentList[self.curContentType]:OnShowStart(true)
          else
            self.contentList[self.curContentType]:OnShowStart()
          end
          self:ShowMask(false)
          self.curTabItem = self.tabItemList[contentType]
          self:SetTabItemsSwitchMask(true)
          if contentType == FacilityBarrackGlobal.ContentType.UIChrOverviewPanel then
            FacilityBarrackGlobal.HideEffectNum(true)
          end
        end
        local delayCameraMoveEnd = function(time, attachTouch)
          self.delayCameraTimer = TimerSys:DelayCall(time, function()
            cameraMoveEnd(attachTouch)
          end)
        end
        local cameraMove = function(barrackCameraOperate, attachTouch)
          self:SetSwitchGunBtnInteractable(false)
          BarrackHelper.CameraMgr:StartCameraMoving(barrackCameraOperate, not needBlending)
          if needBlending then
            delayCameraMoveEnd(BarrackHelper.CameraMgr:GetAlmostEndDuration(barrackCameraOperate) + 0.4, attachTouch)
          else
            cameraMoveEnd(attachTouch)
          end
        end
        if self.curTabItem.contentType == FacilityBarrackGlobal.ContentType.UIChrStageUpPanel and contentType == FacilityBarrackGlobal.ContentType.UIChrOverviewPanel then
          setactive(self.ui.mTrans_TouchPad.gameObject, false)
          FacilityBarrackGlobal:SwitchCameraPos(BarrackCameraStand.Base, false)
          cameraMove(BarrackCameraOperate.GradeToOverview, true)
        elseif self.curTabItem.contentType == FacilityBarrackGlobal.ContentType.UIChrOverviewPanel and contentType == FacilityBarrackGlobal.ContentType.UIChrStageUpPanel then
          FacilityBarrackGlobal.HideEffectNum()
          setactive(self.ui.mTrans_TouchPad.gameObject, false)
          cameraMove(BarrackCameraOperate.OverviewToGrade, false)
          CS.UIBarrackModelManager.Instance:ResetBarrackIdle()
        elseif self.curTabItem.contentType == FacilityBarrackGlobal.ContentType.UIChrTalentPanel and contentType == FacilityBarrackGlobal.ContentType.UIChrOverviewPanel then
          setactive(self.ui.mTrans_TouchPad.gameObject, false)
          cameraMove(BarrackCameraOperate.TalentTreeToOverview, false)
        elseif self.curTabItem.contentType == FacilityBarrackGlobal.ContentType.UIChrOverviewPanel and contentType == FacilityBarrackGlobal.ContentType.UIChrTalentPanel then
          FacilityBarrackGlobal.HideEffectNum()
          setactive(self.ui.mTrans_TouchPad.gameObject, false)
          cameraMove(BarrackCameraOperate.OverviewToTalentTree, false)
          BarrackHelper.ModelMgr:ResetBarrackIdle()
        elseif self.curTabItem.contentType == FacilityBarrackGlobal.ContentType.UIChrTalentPanel and contentType == FacilityBarrackGlobal.ContentType.UIChrStageUpPanel then
          cameraMove(BarrackCameraOperate.TalentTreeToGrade, false)
        elseif self.curTabItem.contentType == FacilityBarrackGlobal.ContentType.UIChrStageUpPanel and contentType == FacilityBarrackGlobal.ContentType.UIChrTalentPanel then
          cameraMove(BarrackCameraOperate.GradeToTalentTree, false)
        end
      else
        self:ShowMask(false)
        if contentType == FacilityBarrackGlobal.ContentType.UIChrTalentPanel and FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview then
          self.contentList[contentType]:OnShowStart(true)
        else
          self.contentList[contentType]:OnShowStart()
        end
      end
      if self.curContent ~= nil then
        self.curContent:OnHide()
      else
        self.curContent = self.contentList[contentType]
        if contentType == FacilityBarrackGlobal.ContentType.UIChrTalentPanel and FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview then
          self.curContent:OnShowStart(true)
        else
          self.curContent:OnShowStart()
        end
      end
      self.curContent = self.contentList[contentType]
      for _, item in pairs(self.tabItemList) do
        item:SetSelect(contentType == item.contentType)
      end
      self.curTabItem = self.tabItemList[contentType]
      if needBlending then
        self:SetTabItemsSwitchMask(false)
      end
      self:EnableCharacterModel(self.curContent.needModel)
    end
    changeContentFunc()
  end
  changeContent()
end

function UIChrPowerUpPanel:SetSwitchGunBtnInteractable(boolean)
  self.ui.mBtn_PreGun.interactable = boolean
  self.ui.mBtn_NextGun.interactable = boolean
end

function UIChrPowerUpPanel:ActiveSwitchGunBtn(boolean)
  self:PlayAnim(self.ui.mAnimator_Arrow, boolean)
end

function UIChrPowerUpPanel:PlayAnim(animator, boolean)
  if animator == nil then
    return
  end
  if boolean then
    animator:ResetTrigger("FadeOut")
    animator:SetTrigger("FadeIn")
  else
    animator:ResetTrigger("FadeIn")
    animator:SetTrigger("FadeOut")
  end
end

function UIChrPowerUpPanel:PlayFadeAnim(boolean, includeTop, includeArrow)
  if includeTop == nil then
  end
  if includeArrow == nil then
  end
  if includeTop then
    self:PlayAnim(self.ui.mAnimator_Root, boolean)
  end
  if includeArrow then
    self:PlayAnim(self.ui.mAnimator_Arrow, boolean)
  end
  if self.curContent ~= nil and self.curContent.ui ~= nil and self.curContent.ui.mAnimator_Root ~= nil then
    self:PlayAnim(self.curContent.ui.mAnimator_Root, boolean)
  elseif self.curContent ~= nil and self.curContent.m_animatorRoot ~= nil then
    self:PlayAnim(self.curContent.m_animatorRoot, boolean)
  end
end

function UIChrPowerUpPanel:OtherPanelOrDialogBack()
  local targetContent = FacilityBarrackGlobal.GetTargetContentType()
  if targetContent ~= nil and self.curContentType ~= targetContent then
    self:ChangeContent(targetContent)
    FacilityBarrackGlobal.SetTargetContentType(nil)
  elseif self.curContent == nil then
    self:ChangeContent(FacilityBarrackGlobal.ContentType.UIChrOverviewPanel)
  end
  if self.curContent.barrackCameraStand ~= nil then
    FacilityBarrackGlobal:SwitchCameraPos(self.curContent.barrackCameraStand)
  end
end

function UIChrPowerUpPanel:UpdateTabRedPoint()
  for i, tab in pairs(self.tabItemList) do
    local redPoint = 0
    local isUnlock = not self.isLockGun
    local isGachaPreview = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview
    if tab.contentType == FacilityBarrackGlobal.ContentType.UIChrOverviewPanel then
      if not isGachaPreview then
        if isUnlock then
          redPoint = NetCmdWeaponData:UpdateWeaponCanChangeRedPoint(self.mGunCmdData.WeaponId, self.mGunCmdData.GunId)
          if self.mGunCmdData.WeaponData ~= nil then
            redPoint = redPoint + self.mGunCmdData.WeaponData:GetWeaponLevelUpBreakPolarityRedPoint()
          end
          if AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.GundetailWeaponpart) then
            redPoint = redPoint + NetCmdTeamData:UpdateWeaponModRedPoint(self.mGunCmdData)
          end
          redPoint = redPoint + NetCmdTalentData:TalentSkillItemRedPoint(self.mGunCmdData.GunId)
          local isBreakable = NetCmdTrainGunData:IsBreakable(self.mGunCmdData.GunId) and NetCmdTrainGunData:IsBreakRedPointOpen()
          if isBreakable then
            redPoint = redPoint + 1
          end
          if NetCmdGunClothesData:IsAnyClothesNeedRedPoint(self.mGunCmdData.id) then
            redPoint = redPoint + 1
          end
        else
          redPoint = NetCmdTeamData:UpdateLockRedPoint(self.mGunCmdData.TabGunData)
        end
        local overviewPanel = self.contentList[FacilityBarrackGlobal.ContentType.UIChrOverviewPanel]
        if overviewPanel ~= nil then
          redPoint = redPoint + overviewPanel:UpdateRedPoint()
        end
      end
    elseif tab.contentType == FacilityBarrackGlobal.ContentType.UIChrStageUpPanel then
      if isUnlock and not isGachaPreview then
        redPoint = NetCmdTeamData:UpdateUpgradeRedPoint(self.mGunCmdData)
      end
    elseif tab.contentType == FacilityBarrackGlobal.ContentType.UIChrTalentPanel and isUnlock and not isGachaPreview and NetCmdTalentData:IsNeedRedPointOfGunTalentTab(self.mGunCmdData.Id) then
      redPoint = redPoint + 1
    end
    tab:UpdateRedPoint(0 < redPoint)
  end
end

function UIChrPowerUpPanel:SetTabItemsSwitchMask(boolean, isAll)
  for _, item in pairs(self.tabItemList) do
    if boolean then
      item:SetSwitchMask(true)
    else
      item:SetSwitchMask(self.curContentType == item.contentType)
    end
  end
end

function UIChrPowerUpPanel:ResetCurSelectTabItem()
  for i, v in pairs(FacilityBarrackGlobal.ContentType) do
    self.tabItemList[v]:SetSelect(self.curContentType == v)
  end
end

function UIChrPowerUpPanel:SetTabShow()
  for i, v in pairs(self.tabItemList) do
    self.tabItemList[i]:SetActive(v.isLockGunShow ~= nil and v.isLockGunShow and self.isLockGun or not self.isLockGun)
  end
  self:UpdateTabLock()
end

function UIChrPowerUpPanel:OnBackBtnClick()
  if self.curTabItem.contentType ~= FacilityBarrackGlobal.ContentType.UIChrOverviewPanel then
    self:ChangeContent(FacilityBarrackGlobal.ContentType.UIChrOverviewPanel)
    FacilityBarrackGlobal.SetTargetContentType(nil)
    return
  end
  CS.UIBarrackModelManager.Instance:ResetGunStcDataId()
  UIManager.CloseUI(UIDef.UIChrPowerUpPanel)
end

function UIChrPowerUpPanel:ChangeVisualEscapeBtn(boolean, btn)
  self:UnRegistrationKeyboard(KeyCode.Escape)
  if boolean then
    self:RegistrationKeyboard(KeyCode.Escape, btn)
  else
    self.mCSPanel:BindEscButton()
  end
end

function UIChrPowerUpPanel:SwitchGun(isNext)
  isNext = isNext == nil and true or isNext
  FacilityBarrackGlobal.SetNeedBarrackEntrance(self.curTabItem.contentType == FacilityBarrackGlobal.ContentType.UIChrOverviewPanel and not self.isLockGun)
  if isNext then
    CS.UIBarrackModelManager.Instance:SwitchRightGunModel(function(modelGameObject)
      self:UpdateModelCallback(modelGameObject)
    end)
  else
    CS.UIBarrackModelManager.Instance:SwitchLeftGunModel(function(modelGameObject)
      self:UpdateModelCallback(modelGameObject)
    end)
  end
  FacilityBarrackGlobal:SwitchCameraPos(BarrackCameraStand.Base, true)
  if self.curContent ~= nil and self.curContent.SwitchGun ~= nil then
    self.curContent:SwitchGun(isNext)
  end
  self:GetCurGun()
  if self.curContent ~= nil and self.curContent.ResetData ~= nil then
    self.curContent:ResetData()
  end
  self:SetSwitchGunBtnInteractable(false)
  self.delayClickArrowTimer = TimerSys:DelayCall(0.2, function()
    self:SetSwitchGunBtnInteractable(true)
  end)
end

function UIChrPowerUpPanel:GetCurGun()
  local gunId = BarrackHelper.ModelMgr.GunStcDataId
  if gunId == 0 then
    return
  end
  self.isLockGun = NetCmdTeamData:GetGunByStcId(gunId) == nil and FacilityBarrackGlobal.CurShowContentType ~= FacilityBarrackGlobal.ShowContentType.UIGachaPreview
  if FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview then
    self.mGunCmdData = NetCmdTeamData:GetGachaPreviewGunData(self.gachaGunId)
  elseif self.isLockGun then
    self.mGunCmdData = NetCmdTeamData:GetLockGunByStcId(gunId)
  else
    self.mGunCmdData = NetCmdTeamData:GetGunByStcId(gunId)
  end
  self.mGunData = self.mGunCmdData.TabGunData
end

function UIChrPowerUpPanel:UpdateModel()
  local curModel = CS.UIBarrackModelManager.Instance.curModel
  if CS.UIBarrackModelManager.Instance.GunStcDataId == self.mGunCmdData.id and curModel ~= nil and curModel.gameObject ~= nil and curModel.gameObject.activeSelf and FacilityBarrackGlobal.GetNeedBarrackEntrance() then
    curModel:Show(false)
    curModel:Show(true)
    FacilityBarrackGlobal.SetNeedBarrackEntrance(false)
  end
  if FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview or FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrBattlePass or FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrBattlePassCollection then
    CS.UIBarrackModelManager.Instance:SwitchGunModel(self.mGunCmdData, function(modelGameObject)
    end, false)
  else
    CS.UIBarrackModelManager.Instance:SwitchGunModel(self.mGunCmdData)
  end
end

function UIChrPowerUpPanel:UpdateModelCallback(modelGameObject)
  self:GetCurGun()
  self:SetTabShow()
  self.mModelGameObject = modelGameObject
  local topUi = UISystem:GetTopPanelUI()
  if topUi.UIDefine.UIName ~= "UIChrPowerUpPanel" then
    return
  end
  self:UpdateTabRedPoint()
  if self.mModelGameObject ~= nil and self.mModelGameObject.gameObject ~= nil then
    self.mModelGameObject:Show(true)
    self:ResetEffectNumObj()
  end
end

function UIChrPowerUpPanel:OnAnimaChange(currentAnimatorStateInfo)
  local topUi = UISystem:GetTopPanelUI()
  if topUi == nil or topUi.UIDefine.UIName ~= "UIChrPowerUpPanel" then
    return
  end
  if currentAnimatorStateInfo:IsName("BarrackEntrance") then
  elseif currentAnimatorStateInfo:IsName("BarrackIdle") then
    if self.curContentType == FacilityBarrackGlobal.ContentType.UIChrTalentPanel then
      FacilityBarrackGlobal.HideEffectNum(false)
    elseif self.curContentType == FacilityBarrackGlobal.ContentType.UIChrOverviewPanel then
    elseif self.curContentType == FacilityBarrackGlobal.ContentType.UIChrStageUpPanel then
      FacilityBarrackGlobal.HideEffectNum(false)
    else
      FacilityBarrackGlobal.HideEffectNum(true)
    end
    self:ResetEffectNumPosition()
  end
end

function UIChrPowerUpPanel:GunModelChangeAnimState(currentAnimatorStateInfo)
  self:OnAnimaChange(currentAnimatorStateInfo)
end

function UIChrPowerUpPanel:ResetEffectNumPosition()
  local clothesData = TableDataBase.listClothesDatas:GetDataById(self.mGunCmdData.costume)
  if not clothesData then
    return
  end
  local gunGlobalConfigData = TableData.listGunGlobalConfigDatas:GetDataById(clothesData.model_id)
  if gunGlobalConfigData ~= nil then
    FacilityBarrackGlobal.SetEffectNumPosition(gunGlobalConfigData.GunHigh)
  end
end

function UIChrPowerUpPanel:SetLookAtCharacter(obj)
  local characterSelfShadowSettings = SceneSys.CurrentSingleScene.CharacterSelfShadowSettings
  if characterSelfShadowSettings then
    characterSelfShadowSettings:SetLookAtCharacter(obj)
  end
end

function UIChrPowerUpPanel:EnableCharacterModel(enable)
  if (self.gunModel or {}).gameObject and enable then
    local data = TableData.listModelConfigDatas:GetDataById(self.mGunCmdData.model_id)
    local vec = UIUtils.SplitStrToVector(data.character_type)
    self.gunModel.gameObject.transform.position = vec
    if self.reflectionPanel == nil then
      local canvas = UISystem.CharacterCanvas
      self.reflectionPanel = UIUtils.GetTransform(canvas, "ReflectionPlane")
    end
    self.reflectionPanel.transform.position = vec
  end
end

function UIChrPowerUpPanel:ResetEffectNumObj()
  local nextFrameFunc = function()
    local isNeedBarrackEntrance = FacilityBarrackGlobal.GetNeedBarrackEntrance() and self.mModelGameObject.animChangeDispatcher ~= nil and self.mModelGameObject.animChangeDispatcher:IsCurAnim("BarrackIdle")
    local isIdle = false
    if self.mModelGameObject ~= nil and self.mModelGameObject.animChangeDispatcher ~= nil and not isNeedBarrackEntrance and self.mModelGameObject.gameObject ~= nil and self.mModelGameObject.gameObject.activeInHierarchy and self.mModelGameObject.animChangeDispatcher:IsCurAnim("BarrackIdle") then
      isIdle = true
    end
    local isVisual = BarrackHelper.InteractManager:GetVisualState()
    FacilityBarrackGlobal.HideEffectNum(not self.isLockGun and not isVisual and self.curContentType == FacilityBarrackGlobal.ContentType.UIChrOverviewPanel)
    self:ResetEffectNumPosition()
  end
  TimerSys:DelayFrameCall(5, function()
    nextFrameFunc()
  end)
end

function UIChrPowerUpPanel:ShowOrHideMask(message)
  local boolean = message.Sender
  self:ShowMask(boolean)
end

function UIChrPowerUpPanel:ShowMask(boolean)
  self:SetInputActive(not boolean)
  if self ~= nil and self.ui ~= nil and not CS.LuaUtils.IsNullOrDestroyed(self.ui.mTrans_Mask) and not CS.LuaUtils.IsNullOrDestroyed(self.ui.mTrans_Mask.gameObject) then
    setactive(self.ui.mTrans_Mask.gameObject, boolean)
  end
end

function UIChrPowerUpPanel:SetUIInteractable(interactable)
  self.mCSPanel:SetUIInteractable(interactable)
end

function UIChrPowerUpPanel:ShowOrHideUI(message)
  local boolean = message.Sender
  boolean = boolean == nil and true or boolean
  self:PlayFadeAnim(boolean, true)
end

function UIChrPowerUpPanel:ReLoginSuccess(message)
  for i, v in pairs(self.contentList) do
    if v.ReLoginSuccess ~= nil then
      v:ReLoginSuccess()
    end
  end
end

function UIChrPowerUpPanel:AddListener()
  function self.showOrHideMask(message)
    self:ShowOrHideMask(message)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.ShowOrHideMask, self.showOrHideMask)
  
  function self.refreshGun(message)
    self:UpdateTabRedPoint()
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.RefreshGun, self.refreshGun)
  
  function self.showOrHideUI(message)
    self:ShowOrHideUI(message)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.ShowOrHideUI, self.showOrHideUI)
  
  function self.updateModelCallback(message)
    self:UpdateModelCallback(message.Sender)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.UpdateModelCallback, self.updateModelCallback)
  
  function self.gunModelChangeAnimState(message)
    self:GunModelChangeAnimState(message.Sender)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.GunModelChangeAnimState, self.gunModelChangeAnimState)
  
  function self.reLoginSuccess(message)
    self:ReLoginSuccess(message.Sender)
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.ReLoginSuccess, self.reLoginSuccess)
  
  function self.updateTabRedPointFunc(message)
    self:UpdateTabRedPoint()
  end
  
  MessageSys:AddListener(UIEvent.OnChrTalentUpdateTabRedPoint, self.updateTabRedPointFunc)
  
  function self.showMaskFunc(message)
    self:ShowMask(message.Content)
  end
  
  MessageSys:AddListener(UIEvent.OnChrTalentShowMask, self.showMaskFunc)
  
  function self.setUIInteractableFunc(message)
    self:SetUIInteractable(message.Content)
  end
  
  MessageSys:AddListener(UIEvent.OnChrTalentSetUIInteractable, self.setUIInteractableFunc)
  
  function self.assemblySwitchGunFunc(message)
    self:AssemblySwitchGunCallback(message.Content)
  end
  
  MessageSys:AddListener(UIEvent.OnTalentAssemblySwitchGun, self.assemblySwitchGunFunc)
end

function UIChrPowerUpPanel:AssemblySwitchGunCallback(isNext)
  FacilityBarrackGlobal.HideEffectNum()
  isNext = isNext == nil and true or isNext
  if isNext then
    CS.UIBarrackModelManager.Instance:SwitchRightGunModel(function(modelGameObject)
      self:AssemblySwitchGunUpdateModel(modelGameObject)
    end)
  else
    CS.UIBarrackModelManager.Instance:SwitchLeftGunModel(function(modelGameObject)
      self:AssemblySwitchGunUpdateModel(modelGameObject)
    end)
  end
  FacilityBarrackGlobal:SwitchCameraPos(BarrackCameraStand.Base, true)
  CS.UIBarrackModelManager.Instance:PlayChangeGunEffect()
  MessageSys:SendMessage(CS.GF2.Message.FacilityBarrackEvent.OnSwitchGun, gunId)
end

function UIChrPowerUpPanel:AssemblySwitchGunUpdateModel(modelGameObject)
  self.SetLookAtCharacter(modelGameObject.gameObject)
  self.mModelGameObject = modelGameObject
  if self.mModelGameObject ~= nil and self.mModelGameObject.gameObject ~= nil then
    FacilityBarrackGlobal.SetNeedBarrackEntrance(false)
    self.mModelGameObject:Show(true)
  end
  FacilityBarrackGlobal.HideEffectNum(false)
end

function UIChrPowerUpPanel:RemoveListener()
  if self.showOrHideMask ~= nil then
    MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.ShowOrHideMask, self.showOrHideMask)
    self.showOrHideMask = nil
  end
  if self.refreshGun ~= nil then
    MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.RefreshGun, self.refreshGun)
    self.refreshGun = nil
  end
  if self.showOrHideUI ~= nil then
    MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.ShowOrHideUI, self.showOrHideUI)
    self.showOrHideUI = nil
  end
  if self.updateModelCallback ~= nil then
    MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.UpdateModelCallback, self.updateModelCallback)
    self.updateModelCallback = nil
  end
  if self.gunModelChangeAnimState ~= nil then
    MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.GunModelChangeAnimState, self.gunModelChangeAnimState)
    self.gunModelChangeAnimState = nil
  end
  if self.reLoginSuccess ~= nil then
    MessageSys:RemoveListener(CS.GF2.Message.UIEvent.ReLoginSuccess, self.reLoginSuccess)
    self.reLoginSuccess = nil
  end
  if self.updateTabRedPointFunc ~= nil then
    MessageSys:RemoveListener(UIEvent.OnChrTalentUpdateTabRedPoint, self.updateTabRedPointFunc)
    self.updateTabRedPointFunc = nil
  end
  if self.showMaskFunc ~= nil then
    MessageSys:RemoveListener(UIEvent.OnChrTalentShowMask, self.showMaskFunc)
    self.showMaskFunc = nil
  end
  if self.setUIInteractableFunc ~= nil then
    MessageSys:RemoveListener(UIEvent.OnChrTalentSetUIInteractable, self.setUIInteractableFunc)
    self.setUIInteractableFunc = nil
  end
  if self.assemblySwitchGunFunc ~= nil then
    MessageSys:RemoveListener(UIEvent.OnTalentAssemblySwitchGun, self.assemblySwitchGunFunc)
    self.assemblySwitchGunFunc = nil
  end
end

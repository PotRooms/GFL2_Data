require("UI.UniTopbar.UITopResourceBar")
require("UI.BattlePass.UIBattlePassGlobal")
require("UI.BattlePass.Item.BpTopBarItem")
require("UI.BattlePass.BattleMain.UICollectionPanel")
require("UI.BattlePass.BattleMain.UIBattleMainPanel")
require("UI.UIBasePanel")
require("UI.BattlePass.BattleMain.UIBpMissionPanel")
require("UI.BattlePass.BattleMain.UIBpShopPanel")
require("UI.BattlePass.UIBattlePassGlobal")
require("UI.FacilityBarrackPanel.FacilityBarrackGlobal")
UIBattlePassPanel = class("UIBattlePassPanel", UIBasePanel)
UIBattlePassPanel.__index = UIBattlePassPanel

function UIBattlePassPanel:ctor(csPanel)
  UIBattlePassPanel.super.ctor(UIBattlePassPanel, csPanel)
  self.mCSPanel = csPanel
  csPanel.Is3DPanel = false
end

function UIBattlePassPanel:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  UIUtils.GetButtonListener(self.ui.mBtn_BtnBack.transform).onClick = function()
    self:Close()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnHome.gameObject).onClick = function()
    self:OnCommanderCenter()
  end
  self:RegistrationKeyboard(KeyCode.Escape, self.ui.mBtn_BtnBack)
end

function UIBattlePassPanel:OnInit(root, data)
  UIManager.CloseUI(UIDef.UIPostPanelV2)
  UIBattlePassGlobal.BpMainPanelBlackTime = 0.1
  self.mIsFirstShow = true
  self.mHasEnterMainPanel = false
  self.mIsShowForceCommand = false
  self.RedPointType = {
    RedPointConst.BattlePass
  }
  self.mTabItems = {}
  self.mTabPanels = {}
  self.mCurItemPanel = nil
  self.mMainPanel = UIBattleMainPanel.New()
  self.mMainPanel:InitCtrl(self.ui.mScrollListChild_Main.childItem, self.ui.mScrollListChild_Main.transform)
  table.insert(self.mTabPanels, self.mMainPanel)
  table.insert(self.mTabItems, self.ui.mScrollListChild_Main)
  table.insert(self.mTabItems, self.ui.mScrollListChild_Mission)
  if data ~= nil and data.Length > 0 then
    self.mIndex = data[0]
  else
    self.mIndex = UIBattlePassGlobal.ButtonType.MainPanel
  end
  self:ShowInfo()
  self:InitTabBtn()
  setactive(self.mTabBtns[UIBattlePassGlobal.ButtonType.Collection]:GetRoot(), false)
  setactive(self.mTabBtns[UIBattlePassGlobal.ButtonType.Shop]:GetRoot(), false)
  self:UpdateModel()
  local status = NetCmdBattlePassData.BattlePassStatus
  if status ~= CS.ProtoObject.BattlepassType.None then
    self.ui.mAni_Root:SetTrigger("FadeIn")
  end
  local bpMissionPanel = UIBpMissionPanel.New()
  bpMissionPanel:InitCtrl(self.ui.mScrollListChild_Mission.childItem, self.ui.mScrollListChild_Mission.transform, self)
  table.insert(self.mTabPanels, bpMissionPanel)
  bpMissionPanel:SetTopBtnRedPointFun(function()
    self.mTabBtns[UIBattlePassGlobal.ButtonType.Mission]:UpdateRedPoint(NetCmdBattlePassData:UpdateRedPointCount() > 0)
  end)
  self.mCSPanel.m_ExitAnimators = CS.LuaUIUtils.GetExitAllAnimator(self.ui.mUIRoot.transform)
  
  function self.OnBattlePassResfresh()
    if self.mCSPanel.UIGroup:GetTopUI() ~= self.mCSPanel then
      return
    end
    UIManager.OpenUI(UIDef.UIBattlePassLevelUpDialog)
  end
  
  function self.RefreshFun2()
    if self.mTabBtns[UIBattlePassGlobal.ButtonType.Mission] then
      self.mTabBtns[UIBattlePassGlobal.ButtonType.Mission]:UpdateRedPoint(NetCmdBattlePassData:UpdateRedPointCount() > 0)
    end
  end
  
  function self.BpResfresh()
    if self.mCurItemPanel ~= nil then
      self.mCurItemPanel:OnRefresh()
    end
  end
  
  function self.UserTapScreen()
    local topUIType = self.mCSPanel.UIGroup:GetTopUI().UIDefine.UIType
    if self.mIsOpen == false and self.mIsShowForceCommand == false and (topUIType == UIDef.UIBattlePassUnlockPanel or topUIType == UIDef.UIBattlePassPanel) then
      self.mIsShowForceCommand = true
      local title = TableData.GetHintById(208)
      MessageBox.ShowMidBtn(title, TableData.GetHintById(192095), nil, nil, function()
        self:OnCommanderCenter()
      end)
    end
  end
  
  function self.OnUpdateItem()
    if self.topRes ~= nil then
      self.topRes:OnUpdateItemData()
    end
  end
  
  MessageSys:AddListener(UIEvent.BattlePassLevelUp, self.OnBattlePassResfresh)
  MessageSys:AddListener(UIEvent.BpResfresh, self.BpResfresh)
  MessageSys:AddListener(UIEvent.BpOnLookClick, self.RefreshFun2)
  MessageSys:AddListener(UIEvent.UserTapScreen, self.UserTapScreen)
  RedPointSystem:GetInstance():UpdateRedPointByType(RedPointConst.BattlePass)
  MessageSys:AddListener(CS.GF2.Message.CampaignEvent.ResInfoUpdate, self.OnUpdateItem)
  self.lastSceneType = SceneSys.CurrentAdditiveSceneType
end

function UIBattlePassPanel:InitTopBar()
  self.mTopBarIds = {
    TableDataBase.GlobalSystemData.BattlepassResourcesMain,
    TableDataBase.GlobalSystemData.BattlepassResourcesTask,
    TableDataBase.GlobalSystemData.BattlepassResourcesCollection,
    TableDataBase.GlobalSystemData.BattlepassResourcesShop
  }
end

function UIBattlePassPanel:InitTabBtn()
  self.mTabBtns = {}
  for i = 1, UIBattlePassGlobal.ButtonType.Shop do
    local item = BpTopBarItem.New()
    item:InitCtrl(self.ui.mScrollListChild_GrpTopMidBtn.transform)
    item:SetData(i, function()
      UIBattlePassGlobal.CurBpMainpanelRefreshType = UIBattlePassGlobal.BpMainpanelRefreshType.ClickTab
      self:OnClickTab(i)
    end)
    if i == UIBattlePassGlobal.ButtonType.MainPanel then
      item:SetGlobalTab(71)
    elseif i == UIBattlePassGlobal.ButtonType.Mission then
      item:UpdateRedPoint(NetCmdBattlePassData:UpdateRedPointCount() > 0)
      item:SetGlobalTab(72)
    end
    item:SetInteractable(true)
    table.insert(self.mTabBtns, item)
  end
  self.mTabBtns[UIBattlePassGlobal.ButtonType.MainPanel]:SetInteractable(false)
end

function UIBattlePassPanel:OnClickTab(index)
  if self.mHasEnterMainPanel == false and index == UIBattlePassGlobal.ButtonType.MainPanel then
    UIBattlePassGlobal.CurBpMainpanelRefreshType = UIBattlePassGlobal.BpMainpanelRefreshType.FristShow
    self.mHasEnterMainPanel = true
  end
  self.mIndex = index
  if index == UIBattlePassGlobal.ButtonType.Mission and self.mTabPanels[index]:IsObjNull() then
    self.mTabPanels[index]:InitBase(self.ui.mScrollListChild_Mission.childItem, self.ui.mScrollListChild_Mission.transform)
  end
  UIBattlePassGlobal.TabIndx = self.mIndex
  for i = 1, #self.mTabItems do
    setactive(self.mTabItems[i], false)
  end
  if index <= #self.mTabItems then
    setactive(self.mTabItems[index], true)
  end
  for _, item in pairs(self.mTabPanels) do
    item:Hide()
  end
  if self.mTabPanels[index] ~= nil then
    self.mCurItemPanel = self.mTabPanels[index]
    self.mCurItemPanel:Show()
  end
  for i = 1, #self.mTabBtns do
    local tabBtn = self.mTabBtns[i]
    tabBtn:SetInteractable(true)
  end
  if self.mTabBtns[index] ~= nil then
    self.mTabBtns[index]:SetInteractable(false)
  end
  if self.topRes == nil then
    self.topRes = UITopResourceBar.New()
    self.topRes:Init(self.mUIRoot, TableDataBase.GlobalSystemData.BattlepassResourcesMain, true)
  end
  self:UpdateResourceBar(index)
  MessageSys:SendMessage(GuideEvent.OnTabSwitched, UIDef.UIBattlePassPanel, self.mTabBtns[index]:GetGlobalTab())
end

function UIBattlePassPanel:UpdateResourceBar(index)
  local currencyParent = CS.TransformUtils.DeepFindChild(self.mUIRoot, "GrpCurrency/TopResourceBarRoot(Clone)")
  if currencyParent == nil then
    TimerSys:DelayCall(0.1, function()
      self:UpdateResourceBar(index)
    end, nil)
    return
  end
  if currencyParent ~= nil then
    self.topRes:Close()
    self.topRes:Release()
    self.topRes:UpdateCurrencyContent(currencyParent, self.mTopBarIds[index])
  end
end

function UIBattlePassPanel:IsReadyToStartTutorial()
  return UIBattlePassGlobal.IsVideoPlay == false
end

function UIBattlePassPanel:OnShowStart()
  self:FirstEnterPlayVideo()
  local status = NetCmdBattlePassData.BattlePassStatus
  if status ~= CS.ProtoObject.BattlepassType.None then
    self.ui.mAni_Root:SetTrigger("FadeIn")
  end
end

function UIBattlePassPanel:OnBackFrom()
  self.ui.mAni_Root:Rebind()
  self.lastSceneType = SceneSys.CurrentAdditiveSceneType
  self.mCurItemPanel:OnBackFrom()
  self.ui.mAni_Root:SetTrigger("FadeIn")
  UISystem:SetMainCamera(false)
  if self.mIsOpen == false then
    MessageSys:SendMessage(UIEvent.UserTapScreen, nil)
  end
end

function UIBattlePassPanel:OnHide()
  if self.mCSPanel == nil or self.mCSPanel.UIGroup == nil or self.mCSPanel.UIGroup:GetTopUI() == nil or self.mCSPanel.UIGroup:GetTopUI().UIDefine == nil then
    return
  end
  if self.mCSPanel.UIGroup:GetTopUI() == nil or self.mCSPanel.UIGroup:GetTopUI().UIDefine.UIType == UIDef.UIStorePanel then
  end
  if self.mCSPanel.UIGroup:GetTopUI().UIDefine.UIType ~= UIDef.UIBattlePassUnlockPanel and self.mCSPanel.UIGroup:GetTopUI().UIDefine.UIType ~= UIDef.UIChrWeaponPowerUpPanelV4 then
    self.lastSceneType = SceneSys.CurrentAdditiveSceneType
  end
  UISystem:SetMainCamera(false)
end

function UIBattlePassPanel:OnShowFinish()
  if self.mMainPanel ~= nil then
    setactive(self.mMainPanel.obj, true)
  end
  if self.mIsFirstShow == true then
    self:OnClickTab(self.mIndex)
  else
  end
  self.mIsFirstShow = false
  self.mTabBtns[UIBattlePassGlobal.ButtonType.MainPanel]:UpdateRedPoint(NetCmdBattlePassData:UpdateMainPanelRedPointCount() > 0)
  if NetCmdBattlePassData.PlayLevelUpEffect == true then
    UIManager.OpenUI(UIDef.UIBattlePassLevelUpDialog)
  end
  UIBattlePassGlobal.UnlockPanelBlackTime = 0.1
  UIBattlePassGlobal.BpShowSourceType = UIBattlePassGlobal.BpShowSource.MainPanel
  if UIBattlePassGlobal.BpBuyPromote2 == true then
    UIBattlePassGlobal.BpBuyPromote2 = false
    MessageSys:SendMessage(UIEvent.BpPromt2, nil)
  end
  UIBattlePassGlobal.BpMainPanelBlackTime = 0.1
end

function UIBattlePassPanel:OnRecover()
  UIBattlePassGlobal.CurBpMainpanelRefreshType = UIBattlePassGlobal.BpMainpanelRefreshType.OnTop
  self:OnClickTab(UIBattlePassGlobal.TabIndx)
end

function UIBattlePassPanel:OnTop()
  if self.mIndex == UIBattlePassGlobal.ButtonType.Mission and UIBattlePassGlobal.IsRefresh then
    self.mTabPanels[self.mIndex]:Refresh(true)
  end
  UIBattlePassGlobal.IsRefresh = true
  local currencyParent = CS.TransformUtils.DeepFindChild(self.mUIRoot, "GrpCurrency/TopResourceBarRoot(Clone)")
  if currencyParent ~= nil then
    self.topRes:Release()
    self.topRes:UpdateCurrencyContent(currencyParent, self.mTopBarIds[self.mIndex])
  end
end

function UIBattlePassPanel:OnBattlePassLevelUp()
  if self.mCurItemPanel ~= nil then
    self.mCurItemPanel:Show()
  end
end

function UIBattlePassPanel:ShowInfo()
  UIBattlePassGlobal.IsVideoPlay = false
  self:InitTopBar()
end

function UIBattlePassPanel:OnCameraStart()
  return UIBattlePassGlobal.BpMainPanelBlackTime
end

function UIBattlePassPanel:OnCameraBack()
  UISystem:SetMainCamera(false)
  return 0
end

function UIBattlePassPanel:OnUpdate()
  if self.mCurItemPanel ~= nil then
    self.mCurItemPanel:OnUpdate()
  end
  self.mIsOpen = NetCmdSimulateBattleData:CheckPlanIsOpen(CS.GF2.Data.PlanType.PlanFunctionBattlepass)
end

function UIBattlePassPanel:Close()
  UIManager.CloseUISelf(self)
end

function UIBattlePassPanel:OnClose()
  self:UnRegistrationAllKeyboard()
  for i = 1, #self.mTabPanels do
    self.mTabPanels[i]:Release()
  end
  for _, item in pairs(self.mTabBtns) do
    gfdestroy(item:GetRoot())
  end
  for _, item in pairs(self.mTabPanels) do
    gfdestroy(item:Release())
  end
  for i = 1, #self.mTabItems do
    setactive(self.mTabItems[i], false)
  end
  UIBattlePassGlobal.TempItemIndex = 0
  MessageSys:RemoveListener(UIEvent.BpResfresh, self.BpResfresh)
  MessageSys:RemoveListener(UIEvent.BattlePassLevelUp, self.OnBattlePassResfresh)
  MessageSys:RemoveListener(UIEvent.BpOnLookClick, self.RefreshFun2)
  MessageSys:RemoveListener(UIEvent.UserTapScreen, self.UserTapScreen)
  MessageSys:RemoveListener(CS.GF2.Message.CampaignEvent.ResInfoUpdate, self.OnUpdateItem)
  ResourceManager:DestroyInstance(UIBattlePassGlobal.EffectNumObj)
  ResourceManager:DestroyInstance(UIBattlePassGlobal.MoveAssetObj)
  ResourceManager:DestroyInstance(UISystem.BpCharacterCanvas)
end

function UIBattlePassPanel:FirstEnterPlayVideo()
  local StartSeason = function()
    NetCmdBattlePassData:SendBattlepassFirstIn(function()
      NetCmdBattlePassData.BattlePassStatus = CS.ProtoObject.BattlepassType.Base
      RedPointSystem:GetInstance():UpdateRedPointByType(RedPointConst.BattlePass)
      if self.mCurItemPanel ~= nil then
        self.mCurItemPanel:OnRefresh()
        if self.mIndex == UIBattlePassGlobal.ButtonType.MainPanel then
        end
      end
      setactive(self.ui.mTran_Black, false)
      UIBattlePassGlobal.IsVideoPlay = false
      MessageSys:SendMessage(UIEvent.UIBpCanStartGuide, nil)
      if self.mIndex == UIBattlePassGlobal.ButtonType.MainPanel then
      end
    end)
  end
  local PlayVideo = function()
    if TableData.GlobalSystemData.BpEntryAnimationResource == "" then
      StartSeason()
    else
      setactive(self.ui.mTran_Black, true)
      UIBattlePassGlobal.IsVideoPlay = true
      CS.CriWareVideoController.StartPlay(TableData.GlobalSystemData.BpEntryAnimationResource, CS.CriWareVideoType.eVideoPath, function()
        StartSeason()
      end, true)
    end
  end
  local status = NetCmdBattlePassData.BattlePassStatus
  if status == CS.ProtoObject.BattlepassType.None then
    PlayVideo()
  end
end

function UIBattlePassPanel:OnCommanderCenter()
  UISystem:JumpToMainPanel()
end

function UIBattlePassPanel:UpdateModel()
end

function UIBattlePassPanel:SetGunAndLightPos(model, isGun)
end

function UIBattlePassPanel:OnEffectNumClick()
end

function UIBattlePassPanel:JumpSkin(storeGoodData)
  local clothesData = TableDataBase.listClothesDatas:GetDataById(storeGoodData.Frame)
  if clothesData ~= nil then
    FacilityBarrackGlobal.CurSkinShowContentType = FacilityBarrackGlobal.ShowContentType.UIBpClothes
    local list = new_array(typeof(CS.System.Int32), 3)
    list[0] = clothesData.gun
    list[1] = FacilityBarrackGlobal.ShowContentType.UIBpClothes
    list[2] = clothesData.id
    local jumpParam = CS.BarrackPresetJumpParam(1, clothesData.gun, clothesData.id, list)
    JumpSystem:Jump(EnumSceneType.Barrack, jumpParam)
  end
end

function UIBattlePassPanel:ShowFadeOut()
  self.ui.mAni_Root:SetTrigger("FadeOut")
end

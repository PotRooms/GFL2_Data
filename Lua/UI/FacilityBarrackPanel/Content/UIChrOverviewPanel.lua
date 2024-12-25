require("UI.CommonGetGunPanel.UICommonGetGunPanel")
require("UI.WeaponPanel.UIWeaponPanel")
require("UI.FacilityBarrackPanel.Item.ChrWeaponItem")
require("UI.Character.UIComStageItemV3")
require("UI.FacilityBarrackPanel.Content.UIBtnTrainingCtrl")
require("UI.FacilityBarrackPanel.Item.ChrAttributeListItemOverview")
require("UI.FacilityBarrackPanel.Content.UIBtnChangeSkinCtrl")
require("UI.FacilityBarrackPanel.Content.UIChangeSkin.UIBarrackChangeSkinPanel")
require("UI.FacilityBarrackPanel.Item.ChrBarrackSkillItem")
require("UI.FacilityBarrackPanel.Item.ChrSelectListItem")
require("UI.FacilityBarrackPanel.Item.ComChrInfoItem")
UIChrOverviewPanel = class("UIChrOverviewPanel", UIBasePanel)
UIChrOverviewPanel.__index = UIChrOverviewPanel

function UIChrOverviewPanel:ctor(root, uiChrPowerUpPanel)
  UIChrOverviewPanel.super.ctor(self, uiChrPowerUpPanel)
  self.mUIRoot = root
  self.isInit = false
  self.uiChrPowerUpPanel = uiChrPowerUpPanel
  self.ui = {}
  self:LuaUIBindTable(self.mUIRoot, self.ui)
end

function UIChrOverviewPanel:InitUI()
  if self.isInit then
    return
  end
  self.isInit = true
  setinteractable(self.ui.mCanvasGroup_Root.gameObject, false)
  self.mGunCmdData = nil
  self.mGunData = nil
  self.gunMaxLevel = 0
  self.skillList = {}
  self.attributeList = {}
  self.btnTrainingCtrl = nil
  self.needModel = true
  self.barrackCameraStand = BarrackCameraStand.Base
  self.chrWeaponItem = nil
  self.btnTalentSet = nil
  self.stageItem = nil
  self.isNeedHideEffect = true
  self.isGunUnlockEnough = false
  self.composeRedPoint = nil
  self.chrSwitchRedPoint = nil
  self.isCurTOrW = true
  self.curChrSelectListItemT = nil
  self.curChrSelectListItemW = nil
  self.isUnLock = true
  self.curGunId = 0
  self.curLockGunId = 0
  self.comScreenItem = nil
  self.textTable = {
    unlockText = TableData.GetHintById(160047),
    lockText = TableData.GetHintById(160046),
    unfoldText = TableData.GetHintById(160049),
    foldText = TableData.GetHintById(160048)
  }
  self.isRefreshW = false
  self.scrollToWTimer = nil
  self.needResetAll = true
  self.loveVowItem = {}
  self:InitRank()
  self:InitAttributeList()
  self:InitSkillList()
  self:InitUIBtnTrainingCtrl()
  self:InitBtnChangeSkin()
  self:InitChrWeaponItem()
  self:InitDorm()
  self:InitList()
  self.ui.mToggle_ChrState.isOn = true
  self.isShowFinish = false
  self.hasAddListener = false
  self.isSetBg = false
  self:OnInit(self.uiChrPowerUpPanel.mGunCmdData)
end

function UIChrOverviewPanel:OnInit(data)
  self.mGunCmdData = data
  if self.mGunCmdData ~= nil then
    self.mGunData = self.mGunCmdData.TabGunData
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Detail.gameObject).onClick = function()
    local param = {
      attributeShowType = FacilityBarrackGlobal.AttributeShowType.Gun,
      gunId = self.mGunCmdData.id
    }
    UIManager.OpenUIByParam(UIDef.UIChrAttributeDetailsDialogV3, param)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnChrSwitch.gameObject).onClick = function()
    self:ShowListTOrW(not self.isCurTOrW, true)
    if self.isCurTOrW then
      self.comScreenItem:OnCloseFilterBtnClick()
    end
  end
  setactive(self.ui.mBtn_ExitVisual_TL.transform.parent.gameObject, true)
  setactive(self.ui.mBtn_ExitVisual_TR.transform.parent.gameObject, false)
  setactive(self.ui.mBtn_ExitVisual_BL.transform.parent.gameObject, false)
  setactive(self.ui.mBtn_ExitVisual_BR.transform.parent.gameObject, false)
  setactive(self.ui.mTrans_TextTips_Top.gameObject, true)
  setactive(self.ui.mTrans_TextTips_Bottom.gameObject, false)
  setactive(self.ui.mTrans_BtnAddCommandCenter.gameObject, true)
  UIUtils.GetButtonListener(self.ui.mBtn_ExitVisual_TL.gameObject).onClick = function()
    self:OnClickVisual(false)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_ExitVisual_TR.gameObject).onClick = function()
    self:OnClickVisual(false)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_ExitVisual_BL.gameObject).onClick = function()
    self:OnClickVisual(false)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_ExitVisual_BR.gameObject).onClick = function()
    self:OnClickVisual(false)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnCompose.gameObject).onClick = function()
    self:OnClickBtnCompose()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Duty.gameObject).onClick = function()
    self:OnClickBtnDuty()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_AddCommandCenter.gameObject).onClick = function()
    self:OnClickBtnAddCommandCenter()
  end
  local composeContainner = self.ui.mBtn_BtnCompose.transform:Find("Root/Trans_RedPoint").gameObject:GetComponent(typeof(CS.UICommonContainer))
  self.composeRedPoint = composeContainner.transform
  self.chrSwitchRedPoint = self.ui.mBtn_BtnChrSwitch.transform:Find("Trans_RedPoint")
  setactive(self.ui.mTrans_VisualRedPoint.gameObject, CS.NetCmdBarrackCameraData.Instance:CheckRedPoint())
  self:AddListener()
end

function UIChrOverviewPanel:OnShowStart(isRealOnShowStart)
  if not self.isInit then
    self:InitUI()
  end
  self.isShowFinish = true
  self.needResetAll = true
  if self:IsShow() then
    return
  end
  if isRealOnShowStart == nil then
    isRealOnShowStart = true
  end
  setinteractable(self.ui.mCanvasGroup_Root.gameObject, true)
  self.btnTrainingCtrl:SetInteractable(true)
  self.btnChangeSkinCtrl:SetInteractable(true)
  if isRealOnShowStart then
    self:ShowListTOrW(self.isCurTOrW)
    self.ui.mAnimator_Root:SetTrigger("FadeIn")
    setactive(self.uiChrPowerUpPanel.ui.mTrans_TouchPad, false)
    self.showVisualTrans = false
    setactive(self.ui.mTrans_BtnExitVisual, false)
  end
  self:SetData()
  BarrackHelper.InteractManager:AddListener()
end

function UIChrOverviewPanel:OnRecover()
end

function UIChrOverviewPanel:OnBackFrom()
  self.ui.mAnimator_Root:SetTrigger("FadeIn")
  setinteractable(self.ui.mCanvasGroup_Root.gameObject, true)
  self.btnTrainingCtrl:SetInteractable(true)
  self.btnChangeSkinCtrl:SetInteractable(true)
  local normalView = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrOverview
  if normalView == true then
    self:SetData()
    self:ShowListTOrW(self.isCurTOrW, true)
  end
  BarrackHelper.SceneMgr:SetAimoLineEffectVisible(false)
end

function UIChrOverviewPanel:OnTop()
  setinteractable(self.ui.mCanvasGroup_Root.gameObject, true)
  self:SetData()
end

function UIChrOverviewPanel:OnShowFinish()
  self:OnShowStart(false)
  self:InitVisualBtn()
  local gunid = self.mGunCmdData.Id
  self.ui.mAnimator_Dorm:SetBool("UnLock", NetCmdTeamData:IsDormSystemUnlock() and NetCmdTeamData:GetGunDormUnlockByUnlockedID(gunid) ~= nil)
  self:AddListener()
  BarrackHelper.InteractManager:AddListener()
  if self.isLockDirty then
    if not self.isCurTOrW and not self.isUnLock then
      self:RefreshGunListW()
    elseif self.isCurTOrW then
      self.ui.mLoopGridView_ChrListT:Refresh()
    end
    self.isLockDirty = false
  end
  setactive(self.ui.mTrans_VisualRedPoint.gameObject, CS.NetCmdBarrackCameraData.Instance:CheckRedPoint())
end

function UIChrOverviewPanel:OnUpdate(deltaTime)
end

function UIChrOverviewPanel:OnCameraBack()
  return 0
end

function UIChrOverviewPanel:OnClose(isRealClose)
  if isRealClose then
    self.curGunId = 0
    self.curLockGunId = 0
    self.isCurTOrW = true
    self:RemoveListener()
    if self.scrollToWTimer ~= nil then
      self.scrollToWTimer:Stop()
    end
    UISystem.BarrackCharacterCameraCtrl:SetEnterLookAtFinishedCallback(function()
    end)
    UISystem.BarrackCharacterCameraCtrl:SetExitLookAtFinishedCallback(function()
    end)
  end
  if self.comScreenItem ~= nil then
    self.comScreenItem:OnCloseFilterBtnClick()
  end
  setinteractable(self.ui.mCanvasGroup_Root.gameObject, false)
  BarrackHelper.InteractManager:RemoveListener()
  setactive(self.ui.mTrans_BtnExitVisual, false)
  CS.NetCmdBarrackCameraData.Instance:ResetTmpChangeBgIndex()
end

function UIChrOverviewPanel:OnRelease()
  if self.comScreenItem then
    self.comScreenItem:OnRelease()
    self.comScreenItem = nil
  end
  self.super.OnRelease(self)
end

function UIChrOverviewPanel:OnHide(isRealHide)
  if not isRealHide then
    BarrackHelper.InteractManager:RemoveListener()
    if self.needResetAll then
      BarrackHelper.InteractManager:ResetAll()
    end
  end
end

function UIChrOverviewPanel:OnHideFinish(isRealHideFinish)
  self.isShowFinish = false
  if isRealHideFinish then
    BarrackHelper.InteractManager:RemoveListener()
    if self.comScreenItem ~= nil then
      self.comScreenItem:OnCloseFilterBtnClick()
    end
  end
  if self.needResetAll then
    BarrackHelper.InteractManager:ResetAll()
  end
end

function UIChrOverviewPanel:OnRefresh()
  self.ui.mLoopGridView_ChrListT:UpdateContentSize()
  self.ui.mLoopGridView_ListW:UpdateContentSize()
  self:OnBackFrom()
end

function UIChrOverviewPanel:IsShow()
  local isShow = self.ui.mCanvasGroup_Root.interactable == true and self.ui.mCanvasGroup_Root.blocksRaycasts == true and self.ui.mCanvasGroup_Root.alpha == 1
  return isShow
end

function UIChrOverviewPanel:ShowUI()
  self.ui.mAnimator_Root:SetTrigger("FadeIn")
  setinteractable(self.ui.mCanvasGroup_Root.gameObject, true)
end

function UIChrOverviewPanel:InitRank()
  local tmpStageParent = self.ui.mScrollListChild_GrpStage.transform
  local stageItem = UIComStageItemV3.New()
  if 1 <= tmpStageParent.childCount then
    stageItem:InitCtrl(tmpStageParent, true, tmpStageParent:GetChild(0))
  else
    stageItem:InitCtrl(tmpStageParent, true)
  end
  self.stageItem = stageItem
end

function UIChrOverviewPanel:InitAttributeList()
  self:InitShowAttributeOnPc()
  local tmpAttriParent = self.ui.mScrollListChild_Content.transform
  for i, att in ipairs(FacilityBarrackGlobal.ShowAttribute) do
    local attr = ChrAttributeListItemOverview.New()
    if i <= tmpAttriParent.childCount then
      attr:InitCtrl(tmpAttriParent, tmpAttriParent:GetChild(i - 1))
    else
      attr:InitCtrl(tmpAttriParent)
    end
    table.insert(self.attributeList, attr)
  end
  UIUtils.ForceRebuildLayout(tmpAttriParent)
end

function UIChrOverviewPanel:InitSkillList()
  self.skillList = {}
  local tmpSkillParent = self.ui.mScrollListChild_GrpSkill.transform
  for i = 1, 5 do
    local skillItem = ChrBarrackSkillItem.New()
    if i <= tmpSkillParent.childCount then
      skillItem:InitCtrl(tmpSkillParent, tmpSkillParent:GetChild(i - 1))
    else
      skillItem:InitCtrl(tmpSkillParent)
    end
    table.insert(self.skillList, skillItem)
  end
end

function UIChrOverviewPanel:InitShowAttributeOnPc()
end

function UIChrOverviewPanel:InitChrWeaponItem()
  local tmpWeaponParent = self.ui.mScrollListChild_WeaponBox.transform
  self.chrWeaponItem = ChrWeaponItem.New()
  if tmpWeaponParent.childCount > 2 then
    self.chrWeaponItem:InitCtrl(tmpWeaponParent, tmpWeaponParent:GetChild(0))
  else
    self.chrWeaponItem:InitCtrl(tmpWeaponParent)
  end
end

function UIChrOverviewPanel:InitScreen()
  if self.comScreenItem ~= nil then
    return
  end
  if self.gunCmdDataList == nil then
    self:ResetCurGunCmdDataList()
  end
  self.comScreenItem = ComScreenItemHelper:InitGun(self.ui.mScrollListChild_Screen.gameObject, self.gunCmdDataList, function()
    if self.isShowFinish then
      self:RefreshGunListW()
    end
  end, nil, true)
end

function UIChrOverviewPanel:UpdateComScreenItem()
  if self.isCurTOrW then
    return
  end
  if self.comScreenItem == nil then
    self:InitScreen()
  end
  self.comScreenItem:SetUserData(not self.isUnLock)
  if self.isUnLock then
    self.comScreenItem:SetList(NetCmdTeamData:GetBarrackGunCmdDatas())
  else
    self.comScreenItem:SetList(NetCmdTeamData:GetBarrackLockGunCmdDatas())
  end
end

function UIChrOverviewPanel:InitUIBtnTrainingCtrl()
  self.btnTrainingCtrl = UIBtnTrainingCtrl.New(self.ui.mTrans_BtnLevelUp)
  self.btnTrainingCtrl:AddBtnClickListener(function()
    self:OnClickTraining()
  end)
  self.btnTrainingCtrl:SetInteractable(false)
end

function UIChrOverviewPanel:OnClickTraining()
  FacilityBarrackGlobal.HideEffectNum()
  self.ui.mAnimator_Root:ResetTrigger("FadeIn")
  BarrackHelper.ModelMgr:ResetBarrackIdle()
  UIManager.OpenUIByParam(UIDef.UIBarrackTrainingPanel, self.mGunCmdData.id)
  BarrackHelper.CameraMgr:StartCameraMoving(BarrackCameraOperate.OverviewToUpgrade)
  self.btnTrainingCtrl:SetInteractable(false)
  self:GunModelStopAudioAndEffect()
  BarrackHelper.SceneMgr:SetAimoLineEffectVisible(true)
end

function UIChrOverviewPanel:InitBtnChangeSkin()
  self.btnChangeSkinCtrl = UIBtnChangeSkinCtrl.New(self.ui.mTrans_ChangeSkin)
  self.btnChangeSkinCtrl:AddBtnClickListener(function()
    self:OnClickChangeSkin()
  end)
  self.btnChangeSkinCtrl:SetInteractable(false)
end

function UIChrOverviewPanel:OnClickChangeSkin()
  self.needResetAll = false
  self.ui.mAnimator_Root:ResetTrigger("FadeIn")
  BarrackHelper.ModelMgr:ResetBarrackIdle()
  self:GunModelStopAudioAndEffect()
  self.btnChangeSkinCtrl:SetInteractable(false)
  FacilityBarrackGlobal.CurSkinShowContentType = FacilityBarrackGlobal.ShowContentType.UIChrOverview
  UIManager.OpenUIByParam(UIDef.UIBarrackChangeSkinPanel, self.mGunCmdData.id)
end

function UIChrOverviewPanel:ResetCurGunCmdDataList()
  self.gunCmdDataList = NetCmdTeamData:GetBarrackCanUnLockGunCmdDatas()
  self.gunCmdDataList:AddRange(NetCmdTeamData:GetBarrackGunCmdDatas())
  self.lockGunDataList = NetCmdTeamData:GetBarrackLockGunCmdDatas()
end

function UIChrOverviewPanel:GetCurGun()
  local gunId = BarrackHelper.ModelMgr.GunStcDataId
  self.isUnLock = NetCmdTeamData:GetGunByStcId(gunId) ~= nil
  local isBattlePassRelated = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrBattlePass or FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrBattlePassCollection
  if FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview then
    self.mGunCmdData = NetCmdTeamData:GetGachaPreviewGunData(gunId)
  elseif isBattlePassRelated then
    self.mGunCmdData = NetCmdTeamData:GetLockGunData(self.mGunCmdData.id, true, FacilityBarrackGlobal.IsBattlePassMaxLevel)
  elseif not self.isUnLock then
    self.mGunCmdData = NetCmdTeamData:GetLockGunByStcId(gunId)
  else
    self.mGunCmdData = NetCmdTeamData:GetGunByStcId(gunId)
  end
  self.mGunData = self.mGunCmdData.TabGunData
  if self.isUnLock then
    self.curGunId = gunId
  else
    self.curLockGunId = gunId
  end
end

function UIChrOverviewPanel:SetGunCmdData(gunCmdData)
  self.mGunCmdData = gunCmdData
  if self.mGunCmdData ~= nil then
    self.mGunData = self.mGunCmdData.TabGunData
  end
  if self.mGunData == nil then
    self.mGunData = TableData.listGunDatas:GetDataById(gunCmdData.stc_id)
  end
  self.isUnLock = NetCmdTeamData:GetGunByStcId(self.mGunData.id) ~= nil
end

function UIChrOverviewPanel:ResetData()
  self:SetData()
end

function UIChrOverviewPanel:SetData()
  self:GetCurGun()
  self:RefreshGunData()
  self:UpdateComScreenItem()
end

function UIChrOverviewPanel:RefreshGunData()
  local gunData = self.mGunCmdData
  local isBattlePassView = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrBattlePass or FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrBattlePassCollection
  local isGachaPreview = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview
  self.gunMaxLevel = self.mGunCmdData.MaxGunLevel
  local dutyData = TableData.listGunDutyDatas:GetDataById(gunData.TabGunData.duty)
  self.ui.mImg_Duty.sprite = IconUtils.GetGunTypeIcon(dutyData.icon .. "_W")
  local dutyTxt = dutyData.name.str
  self.ui.mText_Name1.text = dutyTxt
  local secondDutyText = CS.GunCmdData.GetGunSecondDutyStrByGunId(gunData.GunId)
  self.ui.mText_DutyFeature.text = secondDutyText
  self.ui.mText_ChrName.text = gunData.TabGunData.name.str
  self.ui.mText_Num.text = GlobalConfig.SetLvText(gunData.level)
  self.ui.mText_MaxLevel.text = self.gunMaxLevel
  if isGachaPreview then
    self.ui.mText_MaxLevel.text = TableData.GlobalConfigData.GunMaxLv
  elseif isBattlePassView then
    self.gunMaxLevel = TableData.GlobalConfigData.GunMaxLv
    if FacilityBarrackGlobal.IsBattlePassMaxLevel then
      self.ui.mText_Num.text = GlobalConfig.SetLvText(self.gunMaxLevel)
    else
      self.ui.mText_Num.text = GlobalConfig.SetLvText(1)
    end
    self.ui.mText_MaxLevel.text = self.gunMaxLevel
  end
  setactive(self.ui.mTrans_GrpGachaTalent, false)
  setactive(self.ui.mBtn_Video, isGachaPreview)
  setactive(self.ui.mBtn_GachaTry, isGachaPreview)
  if isGachaPreview then
    local talentPos = self.ui.mTrans_GrpGachaTalent.transform.localPosition
    self.ui.mBtn_Video.transform.localPosition = Vector3(talentPos.x, -310, 0)
  end
  setactive(self.ui.mBtn_AddCommandCenter, not isGachaPreview)
  setactive(self.ui.mTrans_GachaPreviewRedpoint, isGachaPreview and not GashaponNetCmdHandler:CheckPoolPreviewed(self.uiChrPowerUpPanel.gachaId))
  if isGachaPreview then
    self:InitGachaPreview()
  end
  local isRelateBp = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrBattlePass or FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrBattlePassCollection
  self.btnTrainingCtrl:SetData(gunData.Id)
  self.btnTrainingCtrl:Refresh()
  self.btnChangeSkinCtrl:SetData(gunData.Id)
  self.btnChangeSkinCtrl:Refresh()
  local changeSkinBtnVisible = NetCmdTeamData:GetGunByID(gunData.Id) ~= nil and FacilityBarrackGlobal.CurShowContentType ~= FacilityBarrackGlobal.ShowContentType.UIGachaPreview and not isRelateBp
  self.btnChangeSkinCtrl:SetVisible(changeSkinBtnVisible)
  FacilityBarrackGlobal.SetVisualOnClick(function()
    self:OnClickVisual(true)
  end)
  self.ui.mText_Num1.text = gunData.fightingCapacity
  self.ui.mImg_Line.color = TableData.GetGlobalGun_Quality_Color2(gunData.TabGunData.rank, self.ui.mImg_Line.color.a)
  local elementData = TableData.listLanguageElementDatas:GetDataById(gunData.TabGunData.Element)
  if elementData ~= nil then
  end
  local normalView = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrOverview
  setactivewithcheck(self.ui.mBtn_Dorm, normalView)
  setactive(self.ui.mBtn_BtnChrSwitch, normalView)
  setactive(self.ui.mText_TorWName, normalView)
  setactive(self.ui.mTrans_BtnCompose, not self.isUnLock and normalView)
  self.btnTrainingCtrl:SetVisible(self.isUnLock and normalView)
  setactive(self.ui.mTrans_Equipment, self.isUnLock and normalView)
  local unlockId = gunData.TabGunData.unlock_hint
  setactive(self.ui.mTrans_GainWays, not self.isUnLock and normalView and 0 < unlockId)
  if not self.isUnLock and normalView then
    self.ui.mText_Way1.text = TableData.GetHintById(unlockId)
  end
  setactive(self.ui.mBtn_Detail.gameObject, self.isUnLock and FacilityBarrackGlobal.CurShowContentType ~= FacilityBarrackGlobal.ShowContentType.UIGachaPreview)
  if isBattlePassView then
    self.btnTrainingCtrl:SetVisible(false)
  end
  setactive(self.ui.mTrans_GrpTalent, self.isUnLock and normalView)
  self.canHideEffect = true
  if not self.isUnLock then
    local itemData = TableData.listItemDatas:GetDataById(self.mGunData.core_item_id)
    local curChipNum = NetCmdItemData:GetItemCount(itemData.id)
    local unLockNeedNum = tonumber(self.mGunData.unlock_cost)
    self.isGunUnlockEnough = curChipNum >= unLockNeedNum
    if self.isGunUnlockEnough then
      self.ui.mText_ComposeNum.text = curChipNum .. "/" .. unLockNeedNum
    else
      self.ui.mText_ComposeNum.text = "<color=red>" .. curChipNum .. "</color>/" .. unLockNeedNum
    end
    self.ui.mImg_ComposeItem.sprite = IconUtils.GetItemIconSprite(self.mGunData.core_item_id)
    UIUtils.GetButtonListener(self.ui.mBtn_ConsumeItem.gameObject).onClick = function()
      TipsPanelHelper.OpenUITipsPanel(itemData, 0, true)
    end
    setactive(self.composeRedPoint.gameObject, self.isGunUnlockEnough)
  else
    TimerSys:DelayFrameCall(1, function()
      self:UpdateTalent()
    end)
    TimerSys:DelayFrameCall(1, function()
      self:UpdateChrWeaponItem()
    end)
    self:UpdateGunLevelLock()
  end
  self:UpdateRank()
  TimerSys:DelayFrameCall(1, function()
    self:UpdateAttributeList()
  end)
  self:UpdateSkillList()
  self:UpdateRedPoint()
  self:UpdateDorm()
  self:UpdateFavorablity()
  self:UpdateLoveVowItem()
end

function UIChrOverviewPanel:InitGachaPreview()
  local gachaID = self.uiChrPowerUpPanel.gachaId
  if gachaID ~= 0 then
    local gachaData = TableDataBase.listGachaDatas:GetDataById(gachaID)
    setactive(self.ui.mBtn_Video, true)
    setactive(self.ui.mBtn_GachaTry, tonumber(gachaData.gun_up_character) == self.uiChrPowerUpPanel.mGunCmdData.id and gachaData.Type == 3)
    local gunData = TableData.listGunDatas:GetDataById(self.uiChrPowerUpPanel.mGunCmdData.id)
    UIUtils.GetButtonListener(self.ui.mBtn_Video.gameObject).onClick = function()
      self.uiChrPowerUpPanel:ChangeVisualEscapeBtn(true, function()
      end)
      CS.CriWareVideoController.StartPlay(gunData.gacha_get_timeline .. ".usm", CS.CriWareVideoType.eVideoPath, function()
        self.uiChrPowerUpPanel:ChangeVisualEscapeBtn(false)
      end, true, 1, false, -1, 0, {
        gunData.gacha_get_audio,
        gunData.gacha_get_voice
      })
    end
    UIUtils.GetButtonListener(self.ui.mBtn_GachaTry.gameObject).onClick = function()
      GashaponNetCmdHandler:PreviewPool(self.uiChrPowerUpPanel.gachaId)
      local strList = string.split(gachaData.gun_up_character_stage, ",")
      self.mStageItems = {}
      for _, id in pairs(strList) do
        local stageData = TableData.listStageDatas:GetDataById(tonumber(id))
        SceneSys:OpenBattleSceneForGacha(stageData)
      end
    end
  else
    setactive(self.ui.mBtn_Video, false)
    setactive(self.ui.mBtn_GachaTry, false)
  end
  local talentGunData = TableData.listSquadTalentGunDatas:GetDataById(self.mGunCmdData.id)
  local itemId = talentGunData.FullyActiveItemId
  local itemData = TableData.listItemDatas:GetDataById(itemId)
  self.ui.mImg_GachaTalentIcon.sprite = IconUtils.GetItemIconSprite(itemId)
  self.ui.mText_GachaTalentName.text = itemData.name.str
  TipsManager.Add(self.ui.mBtn_GachaTalent.gameObject, itemData, nil, false)
end

function UIChrOverviewPanel:UpdateRedPoint()
  if self.chrSwitchRedPoint ~= nil then
    setactive(self.chrSwitchRedPoint.gameObject, false)
  end
  return 0
end

function UIChrOverviewPanel:UpdateRank()
  self.stageItem:SetData(self.mGunCmdData.upgrade)
end

function UIChrOverviewPanel:UpdateAttributeList()
  for i, attName in ipairs(FacilityBarrackGlobal.ShowAttribute) do
    local attr = self.attributeList[i]
    local value = self:GetTotalPropValueByName(attName)
    local languagePropertyData = TableData.GetPropertyDataByName(attName, 1)
    attr:SetData(languagePropertyData, value)
  end
end

function UIChrOverviewPanel:GetTotalPropValueByName(name)
  return self.mGunCmdData:GetGunPropertyValueWithPercentByType(name)
end

function UIChrOverviewPanel:UpdateSkillList()
  if self.skillList then
    self.mGunCmdData:RecomputeGunSkillAbbr()
    local data = self.mGunCmdData.CurAbbr
    for i = 0, data.Count - 1 do
      local skill = self.skillList[i + 1]
      skill:SetData(self.mGunCmdData, data[i], function()
        self:OnClickSkill(skill.mBattleSkillData, i + 1)
      end)
    end
  end
  FacilityBarrackGlobal.CurBattleSkillDataList = self.skillList
end

function UIChrOverviewPanel:UpdateGunLevelLock()
  local isCanLevelUp = self.mGunCmdData.CanLevelUp
  local isFullLevel = self.mGunCmdData.IsFullLevel
  local isBreakable = not self.mGunCmdData:IsMaxClass() and self.mGunCmdData.level == self.mGunCmdData.MaxGunLevel
  local normalView = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrOverview
  self.btnTrainingCtrl:SetVisible(not isFullLevel and normalView and self.isUnLock)
  setactive(self.ui.mTrans_MaxLevel, isFullLevel and normalView and self.isUnLock)
  if FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrBattlePass then
    local status = NetCmdBattlePassData.BattlePassStatus
    local isBuyBp = status == CS.ProtoObject.BattlepassType.AdvanceTwo or status == CS.ProtoObject.BattlepassType.AdvanceOne
    local isFullBpLevel = NetCmdBattlePassData.BattlePassLevel == NetCmdBattlePassData.CurSeason.max_level
    local isMaxRewardGet = NetCmdBattlePassData.IsMaxRewardGet
  end
end

function UIChrOverviewPanel:UpdateTalent()
  local id = self.mGunCmdData.id
  self:UpdateTalentButton()
  local sprite = NetCmdTalentData:GetTalentIcon(id)
  local talentData = NetCmdTalentData:GetTalentData(id)
  if sprite ~= nil then
  else
    printstack("mylog:Lua:" .. "\229\135\186\233\148\153\228\186\134")
  end
end

function UIChrOverviewPanel:UpdateTalentButton()
  if self.btnTalentSet == nil then
    self.btnTalentSet = UIGunTalentAssemblyUnlockItem.New()
    self.btnTalentSet:InitCtrl(self.ui.mTrans_SetTalent)
    self.btnTalentSet:SetData(self.mGunCmdData.GunId)
    self.btnTalentSet:AddClickListener(function()
      self:OnClickTalentButton()
    end)
  else
    self.btnTalentSet:SetData(self.mGunCmdData.GunId)
  end
end

function UIChrOverviewPanel:OnClickTalentButton()
  if AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.SquadTalentEquip) then
    local gunId = self.mGunCmdData.GunId
    local needMoveCamera = true
    UIManager.OpenUIByParam(UIDef.UIGunTalentAssemblyPanel, {gunId, needMoveCamera})
    self.canHideEffect = false
    BarrackHelper.ModelMgr:ResetBarrackIdle()
    FacilityBarrackGlobal.HideEffectNum(false)
  elseif TipsManager.NeedLockTips(SystemList.SquadTalentEquip) then
    return
  end
end

function UIChrOverviewPanel:UpdateChrWeaponItem()
  self.chrWeaponItem:SetData(self.mGunCmdData, function()
    self:OnClickWeaponItem()
  end)
  setactive(self.ui.mTrans_TextTitle.gameObject, false)
  setactive(self.ui.mText_Type.transform.parent.gameObject, true)
  setactive(self.ui.mText_Type.gameObject, true)
  setactive(self.ui.mImg_Type.gameObject, true)
  self.ui.mText_Type.text = self.mGunCmdData.WeaponData.WeaponTagData.name.str
  self.ui.mImg_Type.sprite = IconUtils.GetElementIcon(self.mGunCmdData.WeaponData.WeaponTagData.Icon .. "_S")
end

function UIChrOverviewPanel:GunModelStopAudioAndEffect()
  local curModel = CS.UIBarrackModelManager.Instance.curModel
  curModel:StopAudio()
  curModel:StopEffect()
end

function UIChrOverviewPanel:OnClickWeaponItem()
  local param = CS.UIChrWeaponPanelV4.UIParams()
  param.weaponId = self.mGunCmdData.WeaponData.id
  param.openFromType = CS.UIChrWeaponPanelV4.WeaponPanelOpenFrom.Barrack
  param.needReplaceBtn = true
  param.needEffect = false
  UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIChrWeaponPanelV4, param)
end

function UIChrOverviewPanel:OnClickSkill(skillData, pos)
  UIManager.OpenUIByParam(UIDef.UIChrSkillInfoDialog, {
    skillData = skillData,
    gunCmdData = self.mGunCmdData,
    isGunLock = not self.isUnLock,
    pos = pos,
    showBottomBtn = true,
    isGachaPreview = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview
  })
end

function UIChrOverviewPanel:SwitchGun(isNext)
  self:PlaySwitchGunEffect()
  self:GetCurGun()
  if self.isCurTOrW then
    self:RefreshGunListT()
  else
    self:RefreshGunListW()
  end
end

function UIChrOverviewPanel:PlaySwitchGunEffect()
  self.ui.mAnimator_Root:SetTrigger("Switch")
end

function UIChrOverviewPanel:InitDorm()
  UIUtils.GetButtonListener(self.ui.mBtn_Dorm.gameObject).onClick = function()
    if not NetCmdTeamData:IsDormSystemUnlock() then
      local unlockData = TableData.listUnlockDatas:GetDataById(15100)
      local str = UIUtils.CheckUnlockPopupStr(unlockData)
      PopupMessageManager.PopupString(str)
      MessageSys:SendMessage(GuideEvent.OnSystemIsLocked, nil)
      return
    end
    local gun = NetCmdTeamData:GetGunByID(self.mGunCmdData.Id)
    if gun == nil then
      gun = NetCmdTeamData:GetLockGunByStcId(self.mGunCmdData.Id)
    end
    if gun.isDormLockGun then
      local unlockDesc = ""
      for i = 0, gun.UnlockDorm.Count - 1 do
        local id = gun.UnlockDorm[i]
        local achieve = TableData.listAchievementDetailDatas:GetDataById(id)
        if achieve ~= nil then
          unlockDesc = unlockDesc .. achieve.des.str
        end
      end
      PopupMessageManager.PopupString(unlockDesc)
      MessageSys:SendMessage(GuideEvent.OnSystemIsLocked, nil)
    else
      if CS.UIUtils.GetTouchClicked() then
        return
      end
      CS.UIUtils.SetTouchClicked()
      NetCmdLoungeData:SetGunId(self.mGunCmdData.Id)
      NetCmdLoungeData:SetEnterSceneType(EnumSceneType.Barrack)
      NetCmdLoungeData:CleanCameraPos()
      NetCmdLoungeData:SetCameraReserve(false)
      if LoungeHelper.InteractManager ~= nil then
        LoungeHelper.InteractManager:CleanTimeLine()
      end
      LoungeHelper.CleanTimelineTransition()
      NetCmdLoungeData:SetIsInMainPanel(false)
      NetCmdLoungeData:SetCameraReserve(false)
      if LoungeHelper.CameraCtrl ~= nil then
        LoungeHelper.CameraCtrl.CameraObj:ResetPosRot()
      end
      if NetCmdLoungeData:HavePreLoadModel() and CS.LoungeModelManager.Instance.curShowModel ~= nil and CS.LoungeModelManager.Instance.curShowModel.GunCmdData.GunId ~= NetCmdLoungeData:GetCurrGunId() then
        UIUtils.DormChrChange(NetCmdLoungeData:GetCurrGunId(), function()
          CS.NetCmdLoungeData.Instance.IsForceRandom = true
          NetCmdLoungeData:OpenDormMainPanel()
        end)
      else
        CS.NetCmdLoungeData.Instance.IsForceRandom = true
        NetCmdLoungeData:OpenDormMainPanel()
      end
    end
  end
end

function UIChrOverviewPanel:UpdateDorm()
  local gunid = self.mGunCmdData.Id
  local gunDormData = NetCmdTeamData:GetGunByID(gunid)
  setactivewithcheck(self.ui.mTrans_DormRedPoint, NetCmdLoungeData:GetDormSetRed(gunid) or NetCmdLoungeData:LoveVowRedByGunData(gunDormData))
  local normalView = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrOverview
  if CS.AuditUtils:IsAudit() then
    setactivewithcheck(self.ui.mBtn_Dorm, gunDormData ~= nil and normalView and not gunDormData.isDormLockGun)
  else
    setactivewithcheck(self.ui.mBtn_Dorm, gunDormData ~= nil and normalView)
  end
  self.ui.mAnimator_Dorm:SetBool("UnLock", NetCmdTeamData:IsDormSystemUnlock() and NetCmdTeamData:GetGunDormUnlockByUnlockedID(gunid) ~= nil)
end

function UIChrOverviewPanel:InitVisualBtn()
  UISystem.BarrackCharacterCameraCtrl:SetEnterLookAtFinishedCallback(function()
    self:EnterVisual()
  end)
  UISystem.BarrackCharacterCameraCtrl:SetExitLookAtFinishedCallback(function()
    self:ExitVisual()
  end)
end

function UIChrOverviewPanel:EnterVisual()
  self.uiChrPowerUpPanel:ChangeVisualEscapeBtn(true, self.ui.mBtn_ExitVisual_TL)
  UISystem.BarrackCharacterCameraCtrl:AttachChrTouchCtrlEvents()
  self.showVisualTrans = true
  setactive(self.ui.mTrans_BtnExitVisual, true)
  setactive(self.uiChrPowerUpPanel.ui.mTrans_TouchPad, true)
  self.ui.mBtn_ExitVisual_TL.interactable = true
  self:ShowMask(false)
end

function UIChrOverviewPanel:ExitVisual()
  self.uiChrPowerUpPanel:ChangeVisualEscapeBtn(false)
  UISystem.BarrackCharacterCameraCtrl:DetachChrTouchCtrlEvents()
  BarrackHelper.InteractManager:OnVisualCameraChanged(false)
  FacilityBarrackGlobal.HideEffectNum(true)
  self.showVisualTrans = false
  setactive(self.ui.mTrans_BtnExitVisual, false)
  setactive(self.uiChrPowerUpPanel.ui.mTrans_TouchPad, false)
  self.ui.mBtn_ExitVisual_TL.interactable = true
  self:ShowMask(false)
end

function UIChrOverviewPanel:OnClickVisual(enabled)
  if not enabled and BarrackHelper.InteractManager:IsPlaying() or not UISystem.BarrackCharacterCameraCtrl:IsInteractiveCameraBlendFinished() then
    local str = TableData.GetHintById(102274)
    CS.PopupMessageManager.PopupString(str)
    return
  end
  if not enabled and self.uiChrPowerUpPanel.isVisual then
    UIManager.CloseUI(UIDef.UIChrPowerUpPanel)
    return
  end
  self:VisualChanged(enabled)
end

function UIChrOverviewPanel:VisualChanged(enabled, needMoveCamera)
  if needMoveCamera == nil then
    needMoveCamera = true
  end
  self:ShowMask(true)
  self.ui.mBtn_ExitVisual_TL.interactable = false
  BarrackHelper.InteractManager:SetVisualState(enabled)
  if enabled then
    function self.uiChrPowerUpPanel.ui.mTrans_TouchPad.PointerDownHandler(eventData)
      BarrackHelper.InteractManager:PlayTouchEffect(eventData)
    end
    
    FacilityBarrackGlobal.HideEffectNum()
    if needMoveCamera then
      UISystem.BarrackCharacterCameraCtrl:EnterLookAt()
    else
      self:EnterVisual()
    end
    CS.GF2.Message.MessageSys.Instance:SendMessage(CS.GF2.Message.FacilityBarrackEvent.ShowOrHideUI, false)
    BarrackHelper.InteractManager:OnVisualCameraChanged(true)
  else
    self.ui.mAnimator_Visual:SetTrigger("FadeOut")
    CS.GF2.Message.MessageSys.Instance:SendMessage(CS.GF2.Message.FacilityBarrackEvent.ShowOrHideUI, true)
    self.uiChrPowerUpPanel.ui.mTrans_TouchPad.PointerDownHandler = nil
    if needMoveCamera then
      UISystem.BarrackCharacterCameraCtrl:ExitLookAt()
    else
      self:ExitVisual()
    end
  end
end

function UIChrOverviewPanel:OnClickBtnCompose()
  if not self.isGunUnlockEnough then
    local itemData = TableData.GetItemData(self.mGunData.core_item_id)
    TipsPanelHelper.OpenUITipsPanel(itemData, 0, true)
  else
    NetCmdTrainGunData:SendCmdUpgradeGun(self.mGunData.id, function(ret)
      FacilityBarrackGlobal.SetNeedBarrackEntrance(true)
      self:UnLockCallBack(ret)
    end)
  end
end

function UIChrOverviewPanel:UnLockCallBack(ret)
  if ret == ErrorCodeSuc then
    local data = {}
    
    function data.CloseCallback()
      local tmpNewGunCmdData = NetCmdTeamData:GetGunByStcId(self.mGunCmdData.id)
      self:ResetData(tmpNewGunCmdData)
      if SceneSys.CurrentSingleScene:GetSceneType() == CS.EnumSceneType.HallScene then
        SceneSys:SwitchVisible(CS.EnumSceneType.Barrack)
      end
    end
    
    UISystem:OpenCommonReceivePanel(data)
    self.curGunId = self.mGunCmdData.id
    if self.lockGunDataList.Count > 0 then
      self.curLockGunId = self.lockGunDataList[0].GunId
    else
      self.curLockGunId = 0
    end
  else
    printstack("\232\167\163\233\148\129\228\186\186\229\189\162\229\164\177\232\180\165")
  end
end

function UIChrOverviewPanel:IsNeedEffectNum()
  return self.btnTrainingCtrl:IsInteractable() and self.canHideEffect == true and self.btnChangeSkinCtrl:IsInteractable()
end

function UIChrOverviewPanel:OnClickBtnDuty()
  UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIChrDutyDetailsDialog, self.mGunCmdData.TabGunData.duty)
end

function UIChrOverviewPanel:OnClickBtnAddCommandCenter()
  setactive(self.mUIRoot.gameObject, false)
  self.isSetBg = true
  CS.NetCmdBarrackCameraData.Instance:OnClickBtnAddCommandCenter(function()
    CS.NetCmdBarrackCameraData.Instance:ResetCurIndex()
    setactive(self.mUIRoot.gameObject, true)
  end, function()
    self.uiChrPowerUpPanel.setBackground = true
  end)
  self.ui.mAnimator_Visual:SetTrigger("FadeOut")
  CS.NetCmdBarrackCameraData.Instance:SetRedPoint()
end

function UIChrOverviewPanel:ResetVisualTrans()
  if self.showVisualTrans and self.ui.mTrans_BtnExitVisual.gameObject.activeSelf then
    setactive(self.ui.mTrans_BtnExitVisual, false)
  end
  setactive(self.ui.mTrans_BtnExitVisual, self.showVisualTrans)
end

function UIChrOverviewPanel:ShowMask(boolean)
  self.uiChrPowerUpPanel:ShowMask(boolean)
end

function UIChrOverviewPanel:ToggleChrStateOnValueChanged(ison)
  self.mGunData = nil
  self.mGunCmdData = nil
  self.isUnLock = ison
  self.curChrSelectListItemW = nil
  local otherGun = self:GetCurModelIsOtherGun()
  FacilityBarrackGlobal.SetNeedBarrackEntrance(ison and otherGun)
  self:UpdateComScreenItem()
  self.comScreenItem:DoFilter()
  self.uiChrPowerUpPanel:GetCurGun()
  self.uiChrPowerUpPanel:SetTabShow()
  if ison then
    self.ui.mText_State.text = self.textTable.unlockText
  else
    self.ui.mText_State.text = self.textTable.lockText
  end
  if self.mGunCmdData == nil then
    self.mGunCmdData = BarrackHelper.ModelMgr.curModel.GunCmdData
  end
  self:UpdateToggleRedPoint()
end

function UIChrOverviewPanel:AddListener()
  if self.hasAddListener then
    return
  end
  self.hasAddListener = true
  self:InitVisualBtn()
  
  function self.toggleChrStateOnValueChanged(ison)
    self:ToggleChrStateOnValueChanged(ison)
  end
  
  self.ui.mToggle_ChrState.onValueChanged:AddListener(self.toggleChrStateOnValueChanged)
  
  function self.updateOrient(message)
    self:UpdateOrient(message)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackModelEvent.CameraOrient, self.updateOrient)
  
  function self.onSwitchGun(message)
    self:OnSwitchGun(message)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.OnSwitchGun, self.onSwitchGun)
  
  function self.redPointUpdate(message)
    self:RedPointUpdate(message)
  end
  
  MessageSys:AddListener(CS.GF2.Message.RedPointEvent.RedPointUpdate, self.redPointUpdate)
end

function UIChrOverviewPanel:RemoveListener()
  if not self.hasAddListener then
    return
  end
  self.hasAddListener = false
  if self.toggleChrStateOnValueChanged ~= nil then
    self.ui.mToggle_ChrState.onValueChanged:RemoveListener(self.toggleChrStateOnValueChanged)
  end
  if self.updateOrient ~= nil then
    MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackModelEvent.CameraOrient, self.updateOrient)
    self.updateOrient = nil
  end
  if self.onSwitchGun ~= nil then
    MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.OnSwitchGun, self.onSwitchGun)
  end
  if self.redPointUpdate ~= nil then
    MessageSys:RemoveListener(CS.GF2.Message.RedPointEvent.RedPointUpdate, self.redPointUpdate)
  end
end

function UIChrOverviewPanel:UpdateOrient(message)
  setactive(self.ui.mBtn_ExitVisual_TL.transform.parent.gameObject, false)
  setactive(self.ui.mBtn_ExitVisual_TR.transform.parent.gameObject, false)
  setactive(self.ui.mBtn_ExitVisual_BL.transform.parent.gameObject, false)
  setactive(self.ui.mBtn_ExitVisual_BR.transform.parent.gameObject, false)
  setactive(self.ui.mTrans_TextTips_Top.gameObject, false)
  setactive(self.ui.mTrans_TextTips_Bottom.gameObject, false)
  local orientation = tonumber(message.Content)
  if orientation == 0 then
    setactive(self.ui.mBtn_ExitVisual_TL.transform.parent.gameObject, true)
    setactive(self.ui.mTrans_TextTips_Top.gameObject, true)
  elseif orientation == -1 then
    setactive(self.ui.mBtn_ExitVisual_BL.transform.parent.gameObject, true)
  elseif orientation == 1 then
    setactive(self.ui.mBtn_ExitVisual_TR.transform.parent.gameObject, true)
  elseif orientation == 2 then
    setactive(self.ui.mBtn_ExitVisual_BR.transform.parent.gameObject, true)
    setactive(self.ui.mTrans_TextTips_Bottom.gameObject, true)
  end
  setactive(self.ui.mTrans_BtnAddCommandCenter.gameObject, orientation == 0)
end

function UIChrOverviewPanel:CheckIsOtherGun(gunId)
  return gunId ~= BarrackHelper.ModelMgr.curModel.tableId
end

function UIChrOverviewPanel:GetCurModelIsOtherGun()
  local notShow = BarrackHelper.ModelMgr.curModel.gameObject == nil
  local otherGun = self.mGunCmdData == nil or self.mGunCmdData ~= nil and self.mGunCmdData.GunId ~= BarrackHelper.ModelMgr.curModel.tableId
  return notShow or otherGun
end

function UIChrOverviewPanel:ShowListTOrW(boolean, forceRefresh)
  local isGachaPreview = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview
  if isGachaPreview then
    setactive(self.ui.mTrans_ChrSelectListT.gameObject, false)
    setactive(self.ui.mTrans_ChrSelectListW.gameObject, false)
    return
  end
  self.isCurTOrW = boolean
  setactive(self.ui.mTrans_ChrSelectListT.gameObject, boolean)
  setactive(self.ui.mTrans_ChrSelectListW.gameObject, not boolean)
  local gunId = BarrackHelper.ModelMgr.GunStcDataId
  local gunCmdData = NetCmdTeamData:GetGunByID(gunId)
  self.isUnLock = gunCmdData ~= nil
  self:ResetCurGunCmdDataList()
  if gunCmdData == nil then
    gunCmdData = NetCmdTeamData:GetLockGunData(gunId)
    local count = NetCmdTeamData:UpdateLockRedPoint(gunCmdData.gunData)
    if count == 0 then
      gunCmdData = self.gunCmdDataList[0]
      gunId = gunCmdData.GunId
    end
    self.curLockGunId = gunId
  end
  self.curGunId = gunId
  if boolean then
    self.ui.mText_TorWName.text = self.textTable.foldText
    self:RefreshGunListT()
  else
    self.ui.mText_TorWName.text = self.textTable.unfoldText
    if self.isUnLock then
      self.ui.mText_State.text = self.textTable.unlockText
    else
      self.ui.mText_State.text = self.textTable.lockText
    end
    self.ui.mToggle_ChrState.isOn = self.isUnLock
    local isOtherGun = self:GetCurModelIsOtherGun()
    if self.comScreenItem == nil then
      self:InitScreen()
    end
    self.comScreenItem:DoSort()
    if isOtherGun or forceRefresh then
      self:RefreshGunListW()
    else
      self:ScrollToW()
    end
  end
  self.ui.mAnimator_BtnChrListSwitch:SetBool("Thin", boolean)
  self:UpdateToggleRedPoint()
  if boolean then
    if self.curGunId ~= 0 then
      self:RefreshModelT(self.curGunId)
    else
      local gunCmdData
      if gunId ~= 0 then
        gunCmdData = NetCmdTeamData:GetGunByID(gunId)
      end
      self:RefreshModelT(gunId)
    end
  end
  self.uiChrPowerUpPanel:GetCurGun()
  self.uiChrPowerUpPanel:SetTabShow()
end

function UIChrOverviewPanel:InitList()
  self:InitGunListT()
  self:InitGunListW()
end

function UIChrOverviewPanel:InitGunListT()
  function self.itemProviderT(renderData)
    self:ItemProviderT(renderData)
  end
  
  function self.itemRendererT(index, renderData)
    self:ItemRendererT(index, renderData)
  end
  
  self.ui.mLoopGridView_ChrListT.itemCreated = self.itemProviderT
  self.ui.mLoopGridView_ChrListT.itemRenderer = self.itemRendererT
end

function UIChrOverviewPanel:RefreshGunListT()
  self:ResetCurGunCmdDataList()
  local itemDataList = LuaUtils.ConvertToItemIdList(self.gunCmdDataList)
  self.ui.mLoopGridView_ChrListT:SetItemIdList(itemDataList)
  self.ui.mLoopGridView_ChrListT.numItems = self.gunCmdDataList.Count
  self.ui.mLoopGridView_ChrListT:Refresh()
  self:ScrollToT()
end

function UIChrOverviewPanel:ItemProviderT(renderData)
  local itemView = ChrSelectListItem.New()
  itemView:InitCtrl(renderData.gameObject)
  renderData.data = itemView
end

function UIChrOverviewPanel:ItemRendererT(index, renderData)
  local item = renderData.data
  item.ItemIndex = index
  local data = self.gunCmdDataList[index]
  item:SetSelect(false)
  item:SetData(data, function()
    FacilityBarrackGlobal.SetNeedBarrackEntrance(true)
    self:OnChrSelectListItemClickT(item)
  end)
  if data.GunId == self.curGunId then
    self:OnChrSelectListItemClickT(item, false)
  end
  local go = item:GetRoot().gameObject
  local itemId = data.gunData.id
  MessageSys:SendMessage(GuideEvent.VirtualListRendererChanged, VirtualListRendererChangeData(go, itemId, index))
end

function UIChrOverviewPanel:OnChrSelectListItemClickT(ChrSelectListItem, needRefresh)
  if ChrSelectListItem then
    if self.curChrSelectListItemT then
      self.curChrSelectListItemT:SetSelect(false)
    end
    if needRefresh == nil then
      needRefresh = true
    end
    ChrSelectListItem:SetSelect(true)
    self.curChrSelectListItemT = ChrSelectListItem
    local gunCmdData = self.curChrSelectListItemT.mGunCmdData
    self.curGunId = self.curChrSelectListItemT.mGunData.id
    if needRefresh then
      self:PlaySwitchGunEffect()
      self:RefreshModelT(ChrSelectListItem.mGunCmdData.Id)
      FacilityBarrackGlobal:SwitchCameraPos(BarrackCameraStand.Base, true)
    elseif needRefresh or BarrackHelper.ModelMgr.curModel.tableId ~= gunCmdData.GunId then
      local otherGun = self:GetCurModelIsOtherGun()
      FacilityBarrackGlobal.SetNeedBarrackEntrance(self.isUnLock and otherGun)
      CS.UIBarrackModelManager.Instance:SwitchGunModel(gunCmdData)
      self:PlaySwitchGunEffect()
      self:RefreshGunData()
      FacilityBarrackGlobal:SwitchCameraPos(BarrackCameraStand.Base, true)
    end
    self:SetGunCmdData(gunCmdData)
    self:RefreshGunData()
    if needRefresh then
      self:AdaptiveTItem()
    end
  end
end

function UIChrOverviewPanel:RefreshModelT(gunId)
  local isOtherGun = self:CheckIsOtherGun(gunId)
  if not isOtherGun then
    return
  end
  FacilityBarrackGlobal.HideEffectNum(false)
  local gunCmdData = NetCmdTeamData:GetGunByID(gunId)
  self.isUnLock = gunCmdData ~= nil
  if gunCmdData == nil then
    gunCmdData = NetCmdTeamData:GetLockGunData(gunId)
    self.curLockGunId = gunId
  end
  CS.UIBarrackModelManager.Instance:SwitchGunModel(gunCmdData)
  FacilityBarrackGlobal:SwitchCameraPos(BarrackCameraStand.Base, true)
end

function UIChrOverviewPanel:ScrollToT()
  if self.curGunId ~= 0 then
    local index = self.ui.mLoopGridView_ChrListT:GetIndexByItemId(self.curGunId)
    if index ~= -1 then
      self.ui.mLoopGridView_ChrListT:ScrollTo(index)
    end
    self:AdaptiveTItem()
  end
end

function UIChrOverviewPanel:AdaptiveTItem()
  local curIndex = self.ui.mLoopGridView_ChrListT:GetIndexByItemId(self.curGunId)
  self.ui.mLoopGridView_ChrListT:AutoScrollToVisible(curIndex, 1, 0.5)
end

function UIChrOverviewPanel:InitGunListW()
  function self.itemProviderW(renderData)
    self:ItemProviderW(renderData)
  end
  
  function self.itemRendererW(index, renderData)
    self:ItemRendererW(index, renderData)
  end
  
  self.ui.mLoopGridView_ListW.itemCreated = self.itemProviderW
  self.ui.mLoopGridView_ListW.itemRenderer = self.itemRendererW
end

function UIChrOverviewPanel:RefreshGunListW()
  if self.isCurTOrW then
    return
  end
  if self.comScreenItem == nil then
    self:InitScreen()
  end
  if not self.ui.mTrans_ChrSelectListW.gameObject.activeSelf then
    return
  end
  self:ResetCurGunCmdDataList()
  local tmpResultList = self.comScreenItem:GetResultList()
  local hasNoLockGun = tmpResultList.Count == 0
  setactive(self.ui.mTrans_None.gameObject, hasNoLockGun)
  if not hasNoLockGun then
    if self.isUnLock then
      self.gunCmdDataList = tmpResultList
      local itemDataList = LuaUtils.ConvertToItemIdList(self.gunCmdDataList)
      if not itemDataList:Contains(self.curGunId) then
        self.curGunId = itemDataList[0]
        self:SetGunCmdData(tmpResultList[0])
      end
      if self.mGunCmdData == nil then
        self:SetGunCmdData(tmpResultList[0])
      end
      self.ui.mLoopGridView_ListW:SetItemIdList(itemDataList)
      self.ui.mLoopGridView_ListW.numItems = self.gunCmdDataList.Count
    else
      self.lockGunDataList = tmpResultList
      local itemDataList = LuaUtils.ConvertToItemIdList(self.lockGunDataList)
      if not itemDataList:Contains(self.curLockGunId) then
        self.curLockGunId = itemDataList[0]
        self.mGunData = self.lockGunDataList[0]
      end
      if self.mGunData == nil then
        self.mGunData = self.lockGunDataList[0]
      end
      self.ui.mLoopGridView_ListW:SetItemIdList(itemDataList)
      self.ui.mLoopGridView_ListW.numItems = self.lockGunDataList.Count
    end
  else
    self.ui.mLoopGridView_ListW.numItems = 0
  end
  if self.curChrSelectListItemW then
    self.curChrSelectListItemW:SetSelect(false)
  end
  self.ui.mLoopGridView_ListW:Refresh()
  self:ScrollToW()
end

function UIChrOverviewPanel:ItemProviderW(renderData)
  local itemView = ComChrInfoItem.New()
  itemView:InitCtrlWithoutInstantiate(renderData.gameObject)
  renderData.data = itemView
end

function UIChrOverviewPanel:ItemRendererW(index, renderData)
  local item = renderData.data
  item.ItemIndex = index
  item:SetSelect(false)
  local data
  if self.isUnLock then
    if index >= self.gunCmdDataList.Count then
      return
    end
    data = self.gunCmdDataList[index]
    item:SetData(data, data.gunData, function()
      self:OnChrSelectListItemClickW(item)
    end)
  else
    if index >= self.lockGunDataList.Count then
      return
    end
    data = self.lockGunDataList[index]
    item:SetData(nil, data.gunData, function()
      self:OnChrSelectListItemClickW(item)
    end)
  end
  local tmpGunId = 0
  if self.isUnLock then
    tmpGunId = self.curGunId
  else
    tmpGunId = self.curLockGunId
  end
  if data.GunId == tmpGunId then
    self:OnChrSelectListItemClickW(item)
  elseif tmpGunId == 0 and self.curLockGunId == 0 and index == 0 then
    self:OnChrSelectListItemClickW(item)
  end
  local go = item:GetRoot().gameObject
  local itemId = data.gunData.id
  MessageSys:SendMessage(GuideEvent.VirtualListRendererChanged, VirtualListRendererChangeData(go, itemId, index))
end

function UIChrOverviewPanel:OnChrSelectListItemClickW(ComChrInfoItem)
  if ComChrInfoItem then
    if self.curChrSelectListItemW then
      self.curChrSelectListItemW:SetSelect(false)
      self.curChrSelectListItemW = ComChrInfoItem
    end
    ComChrInfoItem:SetSelect(true)
    self.curChrSelectListItemW = ComChrInfoItem
    if self.isUnLock then
      self.curGunId = ComChrInfoItem.mGunData.id
    else
      local count = NetCmdTeamData:UpdateLockRedPoint(ComChrInfoItem.mGunData)
      if 0 < count then
        self.curGunId = ComChrInfoItem.mGunData.id
      end
      self.curLockGunId = ComChrInfoItem.mGunData.id
    end
    local gunCmdData
    if self.curChrSelectListItemW.mGunCmdData == nil then
      gunCmdData = NetCmdTeamData:GetLockGunData(self.curChrSelectListItemW.mGunData.id)
    else
      gunCmdData = self.curChrSelectListItemW.mGunCmdData
    end
    self:SetGunCmdData(gunCmdData)
    local otherGun = self:GetCurModelIsOtherGun()
    FacilityBarrackGlobal.SetNeedBarrackEntrance(self.isUnLock and otherGun)
    if otherGun then
      self:RefreshModelW()
    end
  end
end

function UIChrOverviewPanel:RefreshModelW()
  FacilityBarrackGlobal.HideEffectNum(false)
  CS.UIBarrackModelManager.Instance:SwitchGunModel(self.mGunCmdData)
  self:PlaySwitchGunEffect()
  self:RefreshGunData()
  FacilityBarrackGlobal:SwitchCameraPos(BarrackCameraStand.Base, true)
end

function UIChrOverviewPanel:ScrollToW()
  local scrollToW = function()
    local tmpId = 0
    if self.isUnLock then
      tmpId = self.curGunId
    else
      tmpId = self.curLockGunId
    end
    if tmpId ~= 0 then
      local index = self.ui.mLoopGridView_ListW:GetIndexByItemId(tmpId)
      if index ~= -1 then
        self.ui.mLoopGridView_ListW:ScrollTo(index)
      end
    end
  end
  self.ui.mLoopGridView_ListW:Refresh()
  self.scrollToWTimer = TimerSys:DelayFrameCall(2, function()
    scrollToW()
  end)
end

function UIChrOverviewPanel:UpdateToggleRedPoint()
  if not self.isUnLock then
    setactive(self.ui.mTrans_RedPoint.gameObject, false)
    return
  end
  local redPoint = 0
  local lockGuns = NetCmdTeamData:GetBarrackLockGunCmdDatas()
  for i = 0, lockGuns.Count - 1 do
    redPoint = redPoint + lockGuns[i]:GetGunRedPoint()
    if 0 < redPoint then
      setactive(self.ui.mTrans_RedPoint.gameObject, 0 < redPoint)
      return
    end
  end
  setactive(self.ui.mTrans_RedPoint.gameObject, 0 < redPoint)
end

function UIChrOverviewPanel:UpdateBarrackCameraRedPoint()
  FacilityBarrackGlobal.SetEffectNumRedPoint()
  setactive(self.ui.mTrans_VisualRedPoint.gameObject, CS.NetCmdBarrackCameraData.Instance:CheckRedPoint())
end

function UIChrOverviewPanel:UpdateFavorablity()
  setactive(self.ui.mTrans_Favorability.gameObject, false)
  setactive(self.ui.mTrans_ImgNor.gameObject, false)
  self.ui.mText_NumNor.text = 1
  setactive(self.ui.mTrans_ImgMer.gameObject, false)
  self.ui.mText_NumMer.text = 10
end

function UIChrOverviewPanel:UpdateLoveVowItem()
  if not AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.Dorm) then
    setactive(self.ui.mTrans_DormLoveVow.gameObject, false)
    return
  end
  local isHaveLove = NetCmdLoungeData:IsHaveLove(self.mGunCmdData.Id)
  setactive(self.ui.mTrans_DormLoveVow.gameObject, isHaveLove)
  if not isHaveLove then
    return
  end
  local dormLoveVowItem = self.loveVowItem[1]
  local isOpenFunctionLove = OpenFunctionsManager:CheckFunctionOpen(100019) == 1
  setactive(self.ui.mScrollListChild_DormLoveVow.gameObject, isOpenFunctionLove)
  if dormLoveVowItem == nil then
    local tmpDormLoveVow = self.ui.mScrollListChild_DormLoveVow:Instantiate()
    dormLoveVowItem = CS.UIDormLoveVowItem(tmpDormLoveVow)
    table.insert(self.loveVowItem, dormLoveVowItem)
  end
  dormLoveVowItem:SetData(self.mGunCmdData)
end

function UIChrOverviewPanel:OnSwitchGun(message)
  local id = message.Sender
  self.mGunCmdData = NetCmdTeamData:GetGunByStcId(id)
  if self.mGunCmdData ~= nil then
    self.mGunData = self.mGunCmdData.TabGunData
  end
end

function UIChrOverviewPanel:RedPointUpdate(message)
  local redPointType = message.Sender
  if redPointType ~= "Barracks" then
    return
  end
  self.isLockDirty = true
end

require("UI.WeaponPanel.WeaponV4.Item.ChrWeaponTopBarItemV4")
require("UI.WeaponPanel.WeaponV4.UIWeaponPartPanelV2")
require("UI.WeaponPanel.WeaponV4.UIWeaponOverviewPanelV4")
require("UI.WeaponPanel.WeaponV4.WeaponPowerUpV4.UIWeaponPolarityPanelV4")
require("UI.WeaponPanel.WeaponV4.WeaponWindowDialog.UIChrWeaponBreakWindowDialog")
require("UI.WeaponPanel.WeaponV4.WeaponWindowDialog.UIChrWeaponLevelUpWindowDialog")
require("UI.WeaponPanel.UIWeaponPanel")
require("UI.FacilityBarrackPanel.FacilityBarrackGlobal")
require("UI.WeaponPanel.UIWeaponGlobal")
require("UI.Common.UICommonLockItem")
UIChrWeaponPanelV4 = class("UIChrWeaponPanelV4", UIBasePanel)
UIChrWeaponPanelV4.__index = UIChrWeaponPanelV4

function UIChrWeaponPanelV4:ctor(csPanel)
  UIChrWeaponPanelV4.super:ctor(csPanel)
  csPanel.Is3DPanel = true
  self.mCSPanel = csPanel
end

function UIChrWeaponPanelV4:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.gunCmdData = nil
  self.weaponCmdData = nil
  self.suitList = {}
  self.weaponPartUis = {}
  self.replaceBtnRedPoint = nil
  self.needReplaceBtn = false
  self.isLockGun = false
  self.tabItemList = {}
  self.isCompose = false
  self.bgImg = nil
  self.lockItem = nil
  self.isShowReplaceList = false
  self.curIsChrChange = false
  self.needEffect = true
  self.tmpUIWeaponPanelList = nil
  self.tabHint = {
    [1] = 220055,
    [2] = 220056
  }
  self.contentList = {}
  self.curContentType = 0
  self:InitTab()
  self:InitContent()
end

function UIChrWeaponPanelV4:OnInit(root, data)
  local weaponId = data[1]
  self.needReplaceBtn = data.needReplaceBtn
  self.needEffect = data.needEffect or false
  if self.needReplaceBtn == nil then
    self.needReplaceBtn = false
  end
  self.isCompose = false
  setactive(self.ui.mScrollListChild_TopRightBtn, true)
  self.openFromType = data[4]
  if self.openFromType == UIWeaponPanel.OpenFromType.BattlePass or self.openFromType == UIWeaponPanel.OpenFromType.BattlePassCollection then
    self.weaponCmdData = NetCmdWeaponData:GetWeaponByStcId(weaponId)
    setactive(self.ui.mScrollListChild_TopRightBtn, false)
  elseif self.openFromType == UIWeaponPanel.OpenFromType.GachaPreview then
    self.weaponCmdData = NetCmdWeaponData:GetMaxlvWeaponByStcId(weaponId)
    setactive(self.ui.mScrollListChild_TopRightBtn, false)
  elseif self.openFromType == UIWeaponPanel.OpenFromType.RepositoryWeaponCompose then
    self.weaponCmdData = NetCmdWeaponData:GetWeaponByStcId(weaponId)
    self.isCompose = true
  else
    self.weaponCmdData = NetCmdWeaponData:GetWeaponById(weaponId)
  end
  self.tmpUIWeaponPanelList = data[6]
  if self.tmpUIWeaponPanelList ~= nil then
    self:ActiveArrowByWeaponList()
  end
  if self.weaponCmdData.gun_id ~= 0 then
    self.gunCmdData = NetCmdTeamData:GetGunByStcId(self.weaponCmdData.gun_id)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    UIWeaponGlobal.SetNeedCloseBarrack3DCanvas(true)
    UIManager.CloseUI(UIDef.UIWeaponPanel)
  end
  self:SetEscapeEnabled(true)
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    UIWeaponGlobal.SetNeedCloseBarrack3DCanvas(true)
    UISystem:JumpToMainPanel()
  end
  setactive(self.ui.mBtn_Description.transform.parent, true)
  UIUtils.GetButtonListener(self.ui.mBtn_PreGun.gameObject).onClick = function()
    self:SwitchGun(false)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_NextGun.gameObject).onClick = function()
    self:SwitchGun(true)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_ChrChange.gameObject).onClick = function()
    self:InteractChrChangeBtn(false)
    self.curIsChrChange = true
    self:OnWeaponPanelActiveArrow(false)
    local closeCallback = function()
      self.curIsChrChange = false
      self:OnWeaponPanelActiveArrow(true)
      self:InteractChrChangeBtn(true)
    end
    local param = {
      [1] = self.gunCmdData.Id,
      [2] = closeCallback
    }
    UIManager.OpenUIByParam(UIDef.UIChrWeaponChangeEquipedChrDialog, param)
  end
  self:AddListener()
  self:InitLockItem()
  self.bgImg = BarrackHelper.CameraMgr.Barrack3DCanvas.transform:Find("Panel"):GetComponent(typeof(CS.UnityEngine.UI.Image))
  for i, v in ipairs(self.contentList) do
    v:OnInit(self.weaponCmdData)
  end
end

function UIChrWeaponPanelV4:OnShowStart()
  SceneSys:SwitchVisible(EnumSceneType.Barrack)
  CS.UIBarrackModelManager.Instance:ShowBarrackObjWithLayer(false)
  BarrackHelper.CameraMgr:ChangeCameraStand(BarrackCameraStand.Weapon, false)
  self:ChangeContent(UIWeaponGlobal.WeaponContentTypeV4.Weapon)
  self:SetWeaponData()
end

function UIChrWeaponPanelV4:OnSave()
  self.saveContentType = self.curContentType
end

function UIChrWeaponPanelV4:OnRecover()
  SceneSys:SwitchVisible(EnumSceneType.Barrack)
  CS.UIBarrackModelManager.Instance:ShowBarrackObjWithLayer(false)
  BarrackHelper.CameraMgr:ChangeCameraStand(BarrackCameraStand.Weapon, false)
  self:SetWeaponData()
  for i, v in ipairs(self.contentList) do
    v:OnRecover(self.weaponCmdData)
  end
  if self.saveContentType == nil then
    self.saveContentType = UIWeaponGlobal.WeaponContentTypeV4.Weapon
  end
  self:ChangeContent(self.saveContentType)
  self.saveContentType = nil
end

function UIChrWeaponPanelV4:OnBackFrom()
  self:SetWeaponData()
  UIBarrackWeaponModelManager:UpdatePartsOnGameobject(nil, self.weaponCmdData.WeaponConfig)
  CS.UIBarrackModelManager.Instance:ShowBarrackObjWithLayer(false)
  if self.curContentType ~= 0 and self.contentList ~= nil and self.contentList[self.curContentType] ~= nil then
    self.contentList[self.curContentType]:OnBackFrom()
  end
end

function UIChrWeaponPanelV4:OnTop()
  if self.curContentType ~= 0 and self.contentList[self.curContentType] ~= nil and self.curContentType == UIWeaponGlobal.WeaponContentTypeV4.WeaponSkin then
    self.contentList[self.curContentType]:OnTop()
    self:UpdateRedPoint()
    return
  end
  if self.openFromType ~= UIWeaponPanel.OpenFromType.GachaPreview then
    self:SetWeaponData()
  end
  if self.curContentType ~= 0 and self.contentList[self.curContentType] ~= nil then
    self.contentList[self.curContentType]:OnTop()
  end
end

function UIChrWeaponPanelV4:OnShowFinish()
  self:UpdateTabLock()
end

function UIChrWeaponPanelV4:OnCameraStart()
  return 0.01
end

function UIChrWeaponPanelV4:OnCameraBack()
end

function UIChrWeaponPanelV4:OnRefresh()
  if self.curContentType ~= 0 and self.contentList[self.curContentType] ~= nil and self.contentList[self.curContentType].OnRefresh ~= nil then
    self.contentList[self.curContentType]:OnRefresh()
  end
end

function UIChrWeaponPanelV4:OnHide()
end

function UIChrWeaponPanelV4:OnHideFinish()
end

function UIChrWeaponPanelV4:OnClose()
  if UIWeaponGlobal.GetNeedCloseBarrack3DCanvas() then
    UIWeaponGlobal:ReleaseWeaponModel()
    CS.UIBarrackModelManager.Instance:ShowBarrackObjWithLayer(true)
  end
  FacilityBarrackGlobal:SwitchCameraPos(BarrackCameraStand.Base, false)
  if self.curContentType ~= 0 then
    if self.contentList[self.curContentType] ~= nil then
      self.contentList[self.curContentType]:Show(false)
    end
    if self.tabItemList[self.curContentType] ~= nil then
      self.tabItemList[self.curContentType]:SetItemState(false)
    end
    if self.curContentType == UIWeaponGlobal.WeaponContentTypeV4.WeaponSkin then
      self:ShowContent(self.curContentType, false)
    end
  end
  if self.openFromType == UIWeaponPanel.OpenFromType.GachaPreview then
    SceneSys:SwitchVisible(EnumSceneType.Gacha)
  end
  self.curContentType = 0
  self.curIsChrChange = false
  self:SetInputActive(true)
  self:RemoveListener()
end

function UIChrWeaponPanelV4:OnRelease()
  self.super.OnRelease(self)
  self:ReleaseCtrlTable(self.contentList)
  self:SetEscapeEnabled(false)
end

function UIChrWeaponPanelV4:InitTab()
  if #self.tabItemList > 0 then
    return
  end
  local tmpTabParent = self.ui.mScrollListChild_TopRightBtn.transform
  local initTab = function(index, systemId, hintId, globalTabId)
    local obj
    if index < tmpTabParent.childCount then
      obj = tmpTabParent:GetChild(index)
    end
    local tabItem = ChrWeaponTopBarItemV4.New()
    tabItem:InitCtrl(tmpTabParent.gameObject, systemId, hintId, obj, globalTabId)
    tabItem:OnButtonClick(function()
      self:ChangeContent(index)
      MessageSys:SendMessage(GuideEvent.OnTabSwitched, UIDef.UIWeaponPanel, tabItem:GetGlobalTab())
    end)
    table.insert(self.tabItemList, tabItem)
  end
  self.tabItemList = {}
  initTab(1, SystemList.GundetailWeapon, self.tabHint[1], 41)
  initTab(2, SystemList.GundetailWeaponpart, self.tabHint[2], 42)
end

function UIChrWeaponPanelV4:UpdateTabLock()
  for _, item in ipairs(self.tabItemList) do
    if self.isCompose then
      item:SetEnable(false)
    else
      item:SetEnable(true)
      item:UpdateSystemLock()
      if item.systemId == SystemList.GundetailWeaponpart then
        item:SetEnable(self.weaponCmdData.CanEquipMod)
      elseif item.systemId == SystemList.WeaponSkin then
        item:SetEnable(CS.WeaponCmdData.WeaponSkinSwitch)
      end
      if item.systemId == SystemList.GundetailWeapon then
        item:UpdateLockState(true)
      end
    end
  end
end

function UIChrWeaponPanelV4:InitContent()
  if #self.contentList > 0 then
    return
  end
  self.curContent = nil
  self.contentList = {}
  self.contentList[1] = UIWeaponOverviewPanelV4.New(self.ui.mTrans_Overview, self)
  self.contentList[2] = UIWeaponPartPanelV2.New(self.ui.mTrans_WeaponParts, self)
  self.contentList[3] = CS.UITrans_WeaponSkin_3.New(self.ui.mTrans_WeaponSkin, self)
end

function UIChrWeaponPanelV4:InitLockItem()
  self.lockItem = UICommonLockItem.New()
  self.lockItem:InitToggle(self.ui.mToggle_Locked, self.ui.mTrans_LockState)
  self.lockItem:AddClickListener(function(isOn)
    self:OnClickLock(isOn)
  end)
end

function UIChrWeaponPanelV4:ChangeContent(contentType)
  if contentType == 0 or contentType == nil then
    return
  end
  self:CheckWeaponSkin(contentType)
  if self.curContentType == 0 then
    self.curContentType = contentType
    self:ShowContent(self.curContentType, true)
    self:OnTabChanged(contentType, true)
    self.tabItemList[self.curContentType]:SetItemState(true)
  elseif self.curContentType ~= contentType then
    self:ShowMask(true)
    self.contentList[self.curContentType]:OnHide()
    self:OnTabChanged(self.curContentType, false)
    self:OnTabChanged(contentType, true)
    TransformUtils.PlayAniWithCallback(self.contentList[self.curContentType].mUIRoot.transform, function()
      self:ShowContent(self.curContentType, false)
      self.curContentType = contentType
      self:ShowContent(self.curContentType, true)
      self:ShowMask(false)
    end)
  end
end

function UIChrWeaponPanelV4:ShowContent(contentType, enabled)
  self.ui.mGFUIGroupList_ChrWeaponPanelV4:ChangeUIComponentGroups("partsclose", contentType ~= UIWeaponGlobal.WeaponContentTypeV4.WeaponPart)
  self.contentList[contentType]:Show(enabled)
  if enabled then
    self.contentList[contentType]:OnShowStart()
    setactive(self.contentList[contentType].mUIRoot.gameObject, true)
  else
    self.contentList[contentType]:OnHideFinish()
    setactive(self.contentList[contentType].mUIRoot.gameObject, false)
  end
  self:CheckTouchPad()
end

function UIChrWeaponPanelV4:OnTabChanged(contentType, enabled)
  if self.tabItemList ~= nil and self.tabItemList[contentType] ~= nil and self.tabItemList[contentType].SetItemState ~= nil then
    self.tabItemList[contentType]:SetItemState(enabled)
  end
  if self.contentList ~= nil and self.contentList[contentType] ~= nil and self.contentList[contentType].OnTabChanged ~= nil then
    self.contentList[contentType]:OnTabChanged(enabled)
  end
  self:CheckTouchPad()
end

function UIChrWeaponPanelV4:CheckTouchPad()
  setactive(self.ui.mTrans_TouchPad.gameObject, self.curContentType == UIWeaponGlobal.WeaponContentTypeV4.Weapon or self.curContentType == UIWeaponGlobal.WeaponContentTypeV4.WeaponSkin)
end

function UIChrWeaponPanelV4:ShowMask(boolean)
  self:SetInputActive(not boolean)
  if self ~= nil and self.ui ~= nil and not CS.LuaUtils.IsNullOrDestroyed(self.ui.mTrans_Mask) and not CS.LuaUtils.IsNullOrDestroyed(self.ui.mTrans_Mask.gameObject) then
    setactive(self.ui.mTrans_Mask.gameObject, boolean)
  end
end

function UIChrWeaponPanelV4:SetWeaponCmdData(weaponId)
  if self.openFromType == UIWeaponPanel.OpenFromType.Repository or self.openFromType == UIWeaponPanel.OpenFromType.Barrack then
    local weaponCmdData = NetCmdWeaponData:GetWeaponById(weaponId)
    local tmpWeaponCmdData = CS.WeaponCmdData(weaponCmdData.CmdData)
    self.weaponCmdData = tmpWeaponCmdData
  end
end

function UIChrWeaponPanelV4:ResetModelRealData()
  if self.openFromType == UIWeaponPanel.OpenFromType.Repository or self.openFromType == UIWeaponPanel.OpenFromType.Barrack then
    UIBarrackWeaponModelManager:ResetCurWeaponCmdData()
    self:SetWeaponCmdData(self.weaponCmdData.id)
    if self.curContentType == UIWeaponGlobal.WeaponContentTypeV4.WeaponPart then
      self.weaponCmdData:SetUseSkin(false)
    end
  end
end

function UIChrWeaponPanelV4:SetWeaponData()
  self:ResetModelRealData()
  SceneSys:SwitchVisible(EnumSceneType.Barrack)
  BarrackHelper.CameraMgr:SetWeaponRT()
  self.weaponCmdData:ResetPreviewWeaponMod()
  self.bgImg.sprite = ResSys:GetWeaponBgSprite("Img_Weapon_Bg")
  self.bgImgAnimator = self.bgImg.gameObject:GetComponent(typeof(CS.UnityEngine.Animator))
  FacilityBarrackGlobal:SwitchCameraPos(BarrackCameraStand.Weapon, false)
  UISystem.BarrackCharacterCameraCtrl:ShowBarrack3DCanvas(true)
  self:UpdateWeaponModel(self.openFromType == UIWeaponPanel.OpenFromType.RepositoryWeaponCompose)
  if self.openFromType ~= UIWeaponPanel.OpenFromType.BattlePass and self.openFromType ~= UIWeaponPanel.OpenFromType.BattlePassCollection and not self.isCompose and self.openFromType ~= UIWeaponPanel.OpenFromType.GachaPreview then
    self:UpdateRedPoint()
  end
  self.mIsRelatedBP = self.openFromType == UIWeaponPanel.OpenFromType.BattlePass or self.openFromType == UIWeaponPanel.OpenFromType.BattlePassCollection
  self.lockItem:SetActive(not self.isCompose and not self.mIsRelatedBP and self.openFromType ~= UIWeaponPanel.OpenFromType.GachaPreview)
  self:UpdateLockStatue()
  setactive(self.ui.mTrans_Equiped.gameObject, false)
  if self.weaponCmdData ~= nil and self.weaponCmdData.CmdData ~= nil and self.weaponCmdData.CmdData.GunId ~= 0 then
    setactive(self.ui.mTrans_Equiped.gameObject, true)
    local beUsedGunId = self.weaponCmdData.CmdData.GunId
    local gunData = TableData.listGunDatas:GetDataById(beUsedGunId)
    self.ui.mText_Name.text = gunData.Name.str
    self.ui.mImg_ChrHead.sprite = IconUtils.GetCharacterHeadSpriteWithClothByGunId(IconUtils.cCharacterAvatarType_Avatar, gunData.id)
  end
end

function UIChrWeaponPanelV4:UpdateWeaponModel(needRefresh)
  if needRefresh == nil then
    needRefresh = false
  end
  local ignoreUnGet = self.openFromType == UIWeaponPanel.OpenFromType.GachaPreview or self.openFromType == UIWeaponPanel.OpenFromType.BattlePassCollection or self.openFromType == UIWeaponPanel.OpenFromType.BattlePass
  local tmpWeaponCmdData = CS.WeaponCmdData(self.weaponCmdData.CmdData)
  if self.curContentType == UIWeaponGlobal.WeaponContentTypeV4.WeaponPart then
    tmpWeaponCmdData:SetUseSkin(false)
  end
  UIBarrackWeaponModelManager:GetBarrckWeaponModelByData(tmpWeaponCmdData, needRefresh, ignoreUnGet, self.needEffect)
  if not self.needEffect then
    self.needEffect = true
  end
  UIBarrackWeaponModelManager:ShowCurWeaponModel(true)
end

function UIChrWeaponPanelV4:UpdateRedPoint()
  if self.weaponCmdData ~= nil then
    local redPoint
    for _, item in ipairs(self.tabItemList) do
      redPoint = 0
      if item.hintId == self.tabHint[1] then
        self.contentList[1]:UpdateRedPoint()
        redPoint = self.weaponCmdData:GetWeaponLevelUpBreakRedPoint()
        redPoint = redPoint + self.contentList[1].redPointCount
      elseif item.hintId == self.tabHint[2] then
        redPoint = self.weaponCmdData:UpdateWeaponModRedPoint()
      end
      item:SetRedPointEnable(0 < redPoint)
    end
  end
end

function UIChrWeaponPanelV4:UpdateWeaponCapacity()
  setactive(self.ui.mTrans_PartsVolume.gameObject, false)
  return
end

function UIChrWeaponPanelV4:SetEscapeEnabled(enabled, btn)
  if enabled then
    if btn == nil then
      btn = self.ui.mBtn_Back
    end
    self:UnRegistrationKeyboard(KeyCode.Escape)
    self:RegistrationKeyboard(KeyCode.Escape, btn)
  else
    self:UnRegistrationKeyboard(KeyCode.Escape)
  end
end

function UIChrWeaponPanelV4:SwitchGun(isNext)
  isNext = isNext == nil and true or isNext
  if self:SwitchGunByWeaponList(isNext) then
    return
  end
  if isNext then
    CS.UIBarrackModelManager.Instance:SwitchRightGunModel()
  else
    CS.UIBarrackModelManager.Instance:SwitchLeftGunModel()
  end
  local gunCmdData = NetCmdTeamData:GetOtherGunById(self.weaponCmdData.gun_id, isNext)
  self.weaponCmdData = gunCmdData.WeaponData
  if self.weaponCmdData.gun_id ~= 0 then
    self.gunCmdData = NetCmdTeamData:GetGunByStcId(self.weaponCmdData.gun_id)
  end
  self:SetWeaponData()
  MessageSys:SendMessage(CS.GF2.Message.FacilityBarrackEvent.OnSwitchGun, gunCmdData.stc_id)
end

function UIChrWeaponPanelV4:SwitchGunByWeaponList(isNext)
  if self.tmpUIWeaponPanelList == nil then
    return false
  end
  local tmpWeaponCmdData = self.tmpUIWeaponPanelList:SwitchGun(isNext)
  self.weaponCmdData = tmpWeaponCmdData
  if self.contentList ~= nil and self.contentList[1] ~= nil and self.contentList[1].RefreshDataByWeaponCmdData ~= nil then
    self.contentList[1]:RefreshDataByWeaponCmdData(tmpWeaponCmdData)
  end
  return true
end

function UIChrWeaponPanelV4:OnClickLock(isOn)
  local tmpWeaponCmdData = self.weaponCmdData
  if self.weaponCmdData == nil then
    tmpWeaponCmdData = self.weaponCmdData
  end
  if isOn == tmpWeaponCmdData.IsLocked then
    return
  end
  NetCmdWeaponData:SendGunWeaponLockUnlock(tmpWeaponCmdData.id, function(ret)
    if ret == ErrorCodeSuc then
      self.weaponCmdData = NetCmdWeaponData:GetWeaponById(self.weaponCmdData.id)
      if isOn then
        UIUtils.PopupPositiveHintMessage(220007)
      else
        UIUtils.PopupPositiveHintMessage(220008)
      end
      self:UpdateLockStatue()
    end
  end)
end

function UIChrWeaponPanelV4:UpdateLockStatue()
  local tmpWeaponCmdData = self.weaponCmdData
  if self.weaponCmdData == nil then
    tmpWeaponCmdData = self.weaponCmdData
  end
  self.lockItem:SetLock(tmpWeaponCmdData.IsLocked)
end

function UIChrWeaponPanelV4:ActiveChrChangeBtn(boolean)
  self.ui.mBtn_ChrChange.interactable = boolean and self.needReplaceBtn and not self.isShowReplaceList
end

function UIChrWeaponPanelV4:OnWeaponUseSkinChanged(boolean)
  if self.contentList == nil or self.contentList[1] == nil or self.contentList[1].ui == nil or self.contentList[1].ui.mTrans_WeaponSkinIcon == nil then
    return
  end
  setactive(self.contentList[1].ui.mTrans_WeaponSkinIcon, boolean)
end

function UIChrWeaponPanelV4:InteractChrChangeBtn(boolean)
  self.ui.mBtn_ChrChange.interactable = boolean and self.needReplaceBtn and not self.isShowReplaceList
end

function UIChrWeaponPanelV4:CheckWeaponSkin(contentType)
  self:SetWeaponCmdData(self.weaponCmdData.id)
  if self.curContentType == UIWeaponGlobal.WeaponContentTypeV4.WeaponPart and contentType == UIWeaponGlobal.WeaponContentTypeV4.Weapon then
    UIBarrackWeaponModelManager:ShowWeaponModelByUseSkin(self.weaponCmdData.WeaponConfig, true)
  elseif self.curContentType == UIWeaponGlobal.WeaponContentTypeV4.Weapon and contentType == UIWeaponGlobal.WeaponContentTypeV4.WeaponPart then
    UIBarrackWeaponModelManager:ShowWeaponModelByUseSkin(self.weaponCmdData.WeaponConfig, false)
  end
end

function UIChrWeaponPanelV4:OnChangeWeapon(message)
  local id = message.Sender
  if id == 0 or self.weaponCmdData ~= nil and self.weaponCmdData.id == id then
    return
  end
  self.weaponCmdData = NetCmdWeaponData:GetWeaponById(id)
  if self.contentList ~= nil and self.weaponCmdData ~= nil and 0 < #self.contentList then
    for i, v in ipairs(self.contentList) do
      if v.OnChangeWeapon ~= nil then
        v:OnChangeWeapon(self.weaponCmdData, self.curContentType == i)
      end
    end
  end
  self:SetWeaponData()
end

function UIChrWeaponPanelV4:OnSwitchGun(message)
  local id = message.Sender
  self.gunCmdData = NetCmdTeamData:GetGunByStcId(id)
  self.weaponCmdData = self.gunCmdData.WeaponData
  if self.contentList ~= nil and self.weaponCmdData ~= nil and #self.contentList > 0 then
    for i, v in ipairs(self.contentList) do
      if v.SwitchGun ~= nil then
        v:SwitchGun(self.gunCmdData, i == self.curContentType)
      end
    end
  end
end

function UIChrWeaponPanelV4:OnWeaponPanelFadeInOrFadeOut(message)
  local boolean = message.Sender
  if boolean then
    self.ui.mAnimator_Root:ResetTrigger("FadeOut")
    self.ui.mAnimator_Root:SetTrigger("FadeIn")
  else
    self.ui.mAnimator_Root:ResetTrigger("FadeIn")
    self.ui.mAnimator_Root:SetTrigger("FadeOut")
  end
end

function UIChrWeaponPanelV4:OnSetEscapeEnabled(message)
  local btn = message.Sender
  self:SetEscapeEnabled(true, btn)
end

function UIChrWeaponPanelV4:OnWeaponPanelMask(message)
  local boolean = message.Sender
  self:ShowMask(boolean)
  self.mCSPanel:SetUIInteractable(not boolean)
end

function UIChrWeaponPanelV4:OnClickWeaponSkin(boolean)
  if boolean then
    self.ui.mAnimator_Root:ResetTrigger("FadeIn")
    self.ui.mAnimator_Root:SetTrigger("FadeOut")
    self:ChangeContent(UIWeaponGlobal.WeaponContentTypeV4.WeaponSkin)
  else
    self.ui.mAnimator_Root:ResetTrigger("FadeOut")
    self.ui.mAnimator_Root:SetTrigger("FadeIn")
    self:ChangeContent(UIWeaponGlobal.WeaponContentTypeV4.Weapon)
  end
end

function UIChrWeaponPanelV4:OnWeaponPanelActiveArrow(boolean)
  if self.tmpUIWeaponPanelList ~= nil then
    self:ActiveArrowByWeaponList()
    return
  end
  local curContent = self.contentList[self.curContentType]
  local canShowArrow = true
  if curContent ~= nil and curContent.CanShowArrow ~= nil and canShowArrow then
    canShowArrow = curContent:CanShowArrow()
  end
  setactive(self.ui.mTrans_Arrow.gameObject, boolean and self.needReplaceBtn and canShowArrow and not self.curIsChrChange)
end

function UIChrWeaponPanelV4:ActiveArrowByWeaponList()
  local boolean = self.tmpUIWeaponPanelList ~= nil
  setactive(self.ui.mTrans_Arrow.gameObject, boolean)
end

function UIChrWeaponPanelV4:OnWeaponPanelTouch(boolean)
  if boolean then
    self.ui.mAnimator_Root:SetBool("Visual", true)
  else
    self.ui.mAnimator_Root:SetBool("Visual", false)
  end
end

function UIChrWeaponPanelV4:OnWeaponPanelListFade(boolean)
  if boolean then
    self.ui.mAnimator_WeaponInfo:ResetTrigger("WeaponList_FadeOut")
    self.ui.mAnimator_WeaponInfo:SetTrigger("WeaponList_FadeIn")
  else
    self.ui.mAnimator_WeaponInfo:ResetTrigger("WeaponList_FadeIn")
    self.ui.mAnimator_WeaponInfo:SetTrigger("WeaponList_FadeOut")
  end
end

function UIChrWeaponPanelV4:AddListener()
  function self.onChangeWeapon(message)
    self:OnChangeWeapon(message)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.OnChangeWeapon, self.onChangeWeapon)
  
  function self.onSwitchGun(message)
    self:OnSwitchGun(message)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.OnSwitchGun, self.onSwitchGun)
  
  function self.onWeaponPanelFadeInOrFadeOut(message)
    self:OnWeaponPanelFadeInOrFadeOut(message)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponPanelFadeInOrFadeOut, self.onWeaponPanelFadeInOrFadeOut)
  
  function self.onSetEscapeEnabled(message)
    self:OnSetEscapeEnabled(message)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponPanelEscapeEnabled, self.onSetEscapeEnabled)
  
  function self.onWeaponPanelMask(message)
    self:OnWeaponPanelMask(message)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponPanelMask, self.onWeaponPanelMask)
  
  function self.onWeaponPanelChangeContent(message)
    local boolean = message.Sender
    self:OnClickWeaponSkin(boolean)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponPanelChangeContent, self.onWeaponPanelChangeContent)
  
  function self.onWeaponPanelActiveArrow(message)
    local boolean = message.Sender
    self:OnWeaponPanelActiveArrow(boolean)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponPanelActiveArrow, self.onWeaponPanelActiveArrow)
  
  function self.onWeaponPanelTouch(message)
    local boolean = message.Sender
    self:OnWeaponPanelTouch(boolean)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponPanelTouch, self.onWeaponPanelTouch)
  
  function self.onWeaponPanelListFade(message)
    local boolean = message.Sender
    self:OnWeaponPanelListFade(boolean)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponPanelListFade, self.onWeaponPanelListFade)
  
  function self.onActiveChrChangeBtn(message)
    local boolean = message.Sender
    self:ActiveChrChangeBtn(boolean)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.OnActiveChrChangeBtn, self.onActiveChrChangeBtn)
  
  function self.onWeaponUseSkinChanged(message)
    local boolean = message.Sender
    self:OnWeaponUseSkinChanged(boolean)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponUseSkinChanged, self.onWeaponUseSkinChanged)
  for i, v in ipairs(self.contentList) do
    if v.AddListener ~= nil then
      v:AddListener()
    end
  end
end

function UIChrWeaponPanelV4:RemoveListener()
  MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.OnChangeWeapon, self.onChangeWeapon)
  MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.OnSwitchGun, self.onSwitchGun)
  MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponPanelFadeInOrFadeOut, self.onWeaponPanelFadeInOrFadeOut)
  MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponPanelEscapeEnabled, self.onSetEscapeEnabled)
  MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponPanelMask, self.onWeaponPanelMask)
  MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponPanelChangeContent, self.onWeaponPanelChangeContent)
  MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponPanelActiveArrow, self.onWeaponPanelActiveArrow)
  MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponPanelTouch, self.onWeaponPanelTouch)
  MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponPanelListFade, self.onWeaponPanelListFade)
  MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.OnActiveChrChangeBtn, self.onActiveChrChangeBtn)
  MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackEvent.OnWeaponUseSkinChanged, self.onWeaponUseSkinChanged)
  for i, v in ipairs(self.contentList) do
    if v.RemoveListener ~= nil then
      v:RemoveListener()
    end
  end
end

require("UI.Common.UICommonLockItem")
require("UI.Common.UICommonItem")
require("UI.WeaponPanel.UIWeaponGlobal")
require("UI.MessageBox.MessageBoxPanel")
require("UI.Common.UICommonArrowBtnItem")
UIChrWeaponPartsPowerUpPanelV4 = class("UIChrWeaponPartsPowerUpPanelV4", UIBasePanel)
UIChrWeaponPartsPowerUpPanelV4.__index = UIChrWeaponPartsPowerUpPanelV4

function UIChrWeaponPartsPowerUpPanelV4:ctor(csPanel)
  UIChrWeaponPartsPowerUpPanelV4.super:ctor(csPanel)
  csPanel.Is3DPanel = true
end

function UIChrWeaponPartsPowerUpPanelV4:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.weaponPartInfoUI = {}
  self:LuaUIBindTable(self.ui.mTrans_PartsRepositoryInfo, self.weaponPartInfoUI)
  self.gunWeaponModData = nil
  self.itemId = nil
  self.tmpWeaponPartMaterialItem = nil
  self.weaponPartUis = {}
  self.weaponPartsList = nil
  self.subPropList = {}
  self.curSelectPartItem = nil
  self.selectMaterial = {}
  self.curSelectCount = 0
  self.resultMaterial = {}
  self.comScreenItemV2 = nil
  self.curAutoSelectRank = 0
  self.curItem = nil
  self.lockItem = nil
  self.weaponPartsInfoLockItem = nil
  self.needResetCameraPosToBase = false
  self.isMaxLevel = false
  self.isPolarityType = false
  self.curImgFillAmount = 0
  self.curBgImgFillAmount = 0
  self.isLvUpBack = false
  self.isPolarityBack = false
  self.chrWeaponPartsInfoItem = nil
  self.comPropsDetailsItem = nil
  self.targetContentType = 0
  self.curContentType = 0
  self.weaponPartInfoFadeOutAnimLength = 0
  self.weaponPartPowerUpFadeOutAnimLength = 0
  self.curCostCoin = 0
  self.AccelerationCount = 0
  self.ColorList = {
    White = Color(0.9372549019607843, 0.9372549019607843, 0.9372549019607843, 0.5098039215686274),
    Red = Color(1, 0.3686274509803922, 0.2549019607843137, 1)
  }
  self.curSelectIncreaseItemNum = 0
  self.IncreaseBgColorTable = {
    Default = Color(0.4745098039215686, 0.4745098039215686, 0.4745098039215686, 0.2980392156862745),
    Max = Color(0.8901960784313725, 0.48627450980392156, 0.08627450980392157, 0.2980392156862745)
  }
  self.btnPolarityText = nil
  self.btnPolarity1Text = nil
  self.btnIncreaseText = nil
  self.polarityId = 0
end

function UIChrWeaponPartsPowerUpPanelV4:OnInit(root, data)
  self.gunWeaponModData = data[1]
  self.polarityId = self.gunWeaponModData.PolarityId
  self.targetContentType = data[2]
  self.weaponModList = data[3]
  self.openFromType = self.targetContentType
  UIWeaponGlobal.MaxMaterialCount = TableData.GlobalSystemData.WeaponModDisposalLimit
  UIUtils.GetButtonListener(self.ui.mBtn_BtnBack.gameObject).onClick = function()
    if self.curContentType ~= UIWeaponGlobal.WeaponPartPanelTab.Info and self.targetContentType == UIWeaponGlobal.WeaponPartPanelTab.Info then
      self:SetCurItem()
      self:ShowOrHideComPropsDetails(false)
      self:ChangeContent(UIWeaponGlobal.WeaponPartPanelTab.Info)
    else
      UIManager.CloseUI(UIDef.UIChrWeaponPartsPowerUpPanelV4)
    end
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnHome.gameObject).onClick = function()
    UIWeaponGlobal.SetNeedCloseBarrack3DCanvas(true)
    UISystem:JumpToMainPanel()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnLvUp.gameObject).onClick = function()
    self:OnStageUpClick()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnQuickChoose.gameObject).onClick = function()
    self:OnQuickChooseClick()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnPolarity1.gameObject).onClick = function()
    self.curSelectIncreaseItemNum = 0
    self:OnSendPolarity()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnIncrease.gameObject).onClick = function()
    self:OnSendPolarity()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpConsume.gameObject).onClick = function()
    self:OpenItemDialog()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpConsume1.gameObject).onClick = function()
    self:OpenItemDialog()
  end
  UIUtils.GetButtonListener(self.weaponPartInfoUI.mBtn_BtnLevelUp.gameObject).onClick = function()
    self:OnClickLevelUp()
  end
  UIUtils.GetButtonListener(self.weaponPartInfoUI.mBtn_BtnPolarity.gameObject).onClick = function()
    self:OnClickPolarity()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Calibration.gameObject).onClick = function()
    self:OnBtnCalibrationClick()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Calibration1.gameObject).onClick = function()
    self:OnBtnCalibrationClick()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Details.gameObject).onClick = function()
    self:OnBtnIncreaseDetailsClick()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Increase.gameObject).onClick = function()
    self:OnBtnIncreaseClick()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Add.gameObject).onClick = function()
    self:OnBtnIncreaseAddClick()
  end
  self.bgImg = BarrackHelper.CameraMgr.Barrack3DCanvas.transform:Find("Panel"):GetComponent(typeof(CS.UnityEngine.UI.Image))
  self:InitLockItem()
  self.weaponPartInfoFadeOutAnimLength = CS.LuaUtils.GetAnimationClipLength(self.ui.mAnimator_PartsRepositoryInfo, "FadeOut")
  self.weaponPartPowerUpFadeOutAnimLength = CS.LuaUtils.GetAnimationClipLength(self.ui.mAnimator_PartsPowerUp, "FadeOut")
  self:InitWeaponPartList()
  self:AddListener()
  local btnPolarityLua = {}
  self:LuaUIBindTable(self.weaponPartInfoUI.mBtn_BtnPolarity, btnPolarityLua)
  self.btnPolarityText = btnPolarityLua.mText_Name
  local btnPolarity1Lua = {}
  self:LuaUIBindTable(self.ui.mBtn_BtnPolarity1, btnPolarity1Lua)
  self.btnPolarity1Text = btnPolarity1Lua.mText_Name
  local btnIncreaseLua = {}
  self:LuaUIBindTable(self.ui.mBtn_BtnIncrease, btnIncreaseLua)
  self.btnIncreaseText = btnIncreaseLua.mText_Name
end

function UIChrWeaponPartsPowerUpPanelV4:OnShowStart()
  UIBarrackWeaponModelManager:ShowCurWeaponModel(false)
  SceneSys:SwitchVisible(EnumSceneType.Barrack)
  CS.UIBarrackModelManager.Instance:ShowBarrackObjWithLayer(false)
  BarrackHelper.CameraMgr:ChangeCameraStand(BarrackCameraStand.Weapon, false)
  self:SetWeaponPartData()
  self.curSelectIncreaseItemNum = 0
  self:ChangeContent(self.targetContentType)
end

function UIChrWeaponPartsPowerUpPanelV4:OnCameraStart()
  return 0.01
end

function UIChrWeaponPartsPowerUpPanelV4:OnSave()
  self.saveContentType = self.curContentType
end

function UIChrWeaponPartsPowerUpPanelV4:OnRecover()
  UIBarrackWeaponModelManager:ShowCurWeaponModel(false)
  SceneSys:SwitchVisible(EnumSceneType.Barrack)
  CS.UIBarrackModelManager.Instance:ShowBarrackObjWithLayer(false)
  BarrackHelper.CameraMgr:ChangeCameraStand(BarrackCameraStand.Weapon, false)
  if self.saveContentType ~= nil then
    self:ChangeContent(self.saveContentType)
    self.saveContentType = nil
  else
    self:ChangeContent(UIWeaponGlobal.WeaponPartPanelTab.Enhance)
    self:SetWeaponPartData()
  end
end

function UIChrWeaponPartsPowerUpPanelV4:OnBackFrom()
  self:SetWeaponPartData()
end

function UIChrWeaponPartsPowerUpPanelV4:OnTop()
  if self.isLvUpBack then
    if self.gunWeaponModData.maxLevel == self.gunWeaponModData.level then
      if self.openFromType ~= UIWeaponGlobal.WeaponPartPanelTab.Info and not self.gunWeaponModData.WeaponModData.can_polarity then
        UIManager.CloseUI(UIDef.UIChrWeaponPartsPowerUpPanelV4)
        return
      end
      if self.gunWeaponModData.WeaponModData.can_polarity then
        self.targetContentType = UIWeaponGlobal.WeaponPartPanelTab.Enhance
        self.isPolarityType = true
      else
        self:CheckResetTargetContentType2Info()
      end
      self:ChangeContent(self.targetContentType)
    else
      self:SetWeaponPartData()
    end
    self:CheckResetTargetContentType2Info()
  end
  self.isLvUpBack = false
  if self.isPolarityBack and self.gunWeaponModData:HasPolarizationData() then
    setactive(self.ui.mTrans_Mask, false)
    self:OpenChrWeaponPartsPolaritySuccessDialog()
    self.polarityId = self.gunWeaponModData.PolarityId
  end
  self.isPolarityBack = false
  self:CheckAndActiveCalibrationBtn()
end

function UIChrWeaponPartsPowerUpPanelV4:OnShowFinish()
end

function UIChrWeaponPartsPowerUpPanelV4:OnHide()
end

function UIChrWeaponPartsPowerUpPanelV4:OnHideFinish()
  if UIWeaponGlobal.GetNeedCloseBarrack3DCanvas() then
    UIWeaponGlobal:ReleaseWeaponModel()
    CS.UIBarrackModelManager.Instance:ShowBarrackObjWithLayer(true)
  end
  self:ShowOrHideComPropsDetails(false)
end

function UIChrWeaponPartsPowerUpPanelV4:OnClose()
  if self.curContentType == UIWeaponGlobal.WeaponPartPanelTab.Enhance then
    self:SetCurItem()
  end
  if self.comScreenItemV2 then
    self.comScreenItemV2:OnRelease()
    self.comScreenItemV2 = nil
  end
  if self.lockItem ~= nil then
    self.lockItem:OnRelease(true)
  end
  if self.weaponPartsInfoLockItem ~= nil then
    self.weaponPartsInfoLockItem:OnRelease(true)
  end
  self.curSelectPartItem = nil
  self.curPropsDetailsId = 0
  self:ShowOrHideComPropsDetails(false)
  self.chrWeaponPartsInfoItem = nil
  self.comPropsDetailsItem = nil
  if self.curContentType == UIWeaponGlobal.WeaponPartPanelTab.Info then
    self:ShowInfo(false)
  elseif self.curContentType == UIWeaponGlobal.WeaponPartPanelTab.Enhance then
    self:ShowPowerUp(false)
  end
  self.targetContentType = 0
  self.curContentType = 0
  self:RemoveListener()
end

function UIChrWeaponPartsPowerUpPanelV4:OnRelease()
  self.super.OnRelease(self)
  ComPropsDetailsHelper:Release()
end

function UIChrWeaponPartsPowerUpPanelV4:InitLockItem()
  local parent = self.ui.mScrollListChild_BtnLock.transform
  local obj
  if parent.childCount > 0 then
    obj = parent:GetChild(0)
  end
  self.lockItem = UICommonLockItem.New()
  self.lockItem:InitCtrl(parent, obj)
  self.lockItem:AddClickListener(function(isOn)
    self:OnClickLock(isOn)
  end)
  local parent2 = self.weaponPartInfoUI.mScrollListChild_BtnLock.transform
  if parent2.childCount > 0 then
    obj = parent2:GetChild(0)
  end
  self.weaponPartsInfoLockItem = UICommonLockItem.New()
  self.weaponPartsInfoLockItem:InitCtrl(parent2, obj)
  self.weaponPartsInfoLockItem:AddClickListener(function(isOn)
    self:OnClickWeaponPartInfoLock(isOn)
  end)
end

function UIChrWeaponPartsPowerUpPanelV4:InitWeaponPartList()
  function self.itemProvider(renderData)
    return self:ItemProvider(renderData)
  end
  
  function self.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
  
  self.ui.mVirtualListExNew_WeaponPartsList.itemCreated = self.itemProvider
  self.ui.mVirtualListExNew_WeaponPartsList.itemRenderer = self.itemRenderer
end

function UIChrWeaponPartsPowerUpPanelV4:ItemProvider(renderData)
  local itemView = UICommonItem.New()
  itemView:InitCtrlWithNoInstantiate(renderData.gameObject, false)
  renderData.data = itemView
end

function UIChrWeaponPartsPowerUpPanelV4:ItemRenderer(index, renderDataItem)
  if self.resultMaterial == nil or #self.resultMaterial == 0 then
    return
  end
  local itemOrWeaponPartData = self.resultMaterial[index + 1]
  local item = renderDataItem.data
  item:LoseFocus()
  itemOrWeaponPartData.UICommonItem = item
  itemOrWeaponPartData.index = index
  item:SetMaterialPartData(itemOrWeaponPartData)
  if itemOrWeaponPartData.itemData ~= nil then
    item:SetNowEquip(false)
    setactive(item.ui.mTrans_Lock, false)
  else
    item:SetNowEquip(itemOrWeaponPartData.gunWeaponModData.equipWeapon ~= 0)
    setactive(item.ui.mTrans_Lock, itemOrWeaponPartData.gunWeaponModData.IsLocked)
  end
  if self.curItem ~= nil then
    if self.curItem.gunWeaponModData ~= nil then
      if itemOrWeaponPartData.gunWeaponModData ~= nil and itemOrWeaponPartData.gunWeaponModData.id == self.curItem.gunWeaponModData.id then
        item:Focus()
      end
    elseif self.curItem.itemData ~= nil and itemOrWeaponPartData.itemData ~= nil and itemOrWeaponPartData.itemData.id == self.curItem.itemData.id then
      item:Focus()
    end
  end
  self:SetItemLongPressBtn(item, itemOrWeaponPartData)
  UIUtils.GetButtonListener(item.ui.mBtn_Select.gameObject).onClick = function()
    self:OnClickItem(itemOrWeaponPartData)
  end
  UIUtils.GetButtonListener(item.ui.mBtn_Reduce.gameObject).onClick = function()
    self:OnClickReduce(itemOrWeaponPartData)
  end
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateSortContent()
  local gunWeaponModDatas = NetCmdWeaponPartsData:GetEnhanceWeaponPartList(self.gunWeaponModData.id)
  if self.comScreenItemV2 == nil then
    self.comScreenItemV2 = ComScreenItemHelper:InitWeaponPartPowerUp(self.ui.mScrollListChild_GrpScreen.gameObject, gunWeaponModDatas, function()
      self.tmpItemSelectCount = 0
      if self.selectMaterial[self.itemId] ~= nil then
        self.tmpItemSelectCount = self.selectMaterial[self.itemId].selectCount
      end
      self:UpdateReplaceList()
    end)
  else
    self.comScreenItemV2:SetList(gunWeaponModDatas)
  end
  self:UpdateReplaceList()
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateReplaceList()
  if self.comScreenItemV2 == nil then
    return
  end
  if self.curSelectPartItem ~= nil then
    self.curSelectPartItem:SetSelect(false)
  end
  self.weaponPartsList = self.comScreenItemV2:GetResultList()
  self.curAutoSelectRank = self.comScreenItemV2:GetCurSortRank()
  self.resultMaterial = {}
  local itemOwn = NetCmdItemData:GetItemCountById(self.itemId)
  if 0 < itemOwn then
    local tmpWeaponPartMaterial = {}
    tmpWeaponPartMaterial = self.tmpWeaponPartMaterialItem
    table.insert(self.resultMaterial, tmpWeaponPartMaterial)
    self.tmpItemSelectCount = 0
  end
  for i = 0, self.weaponPartsList.Count - 1 do
    local gunWeaponModData = self.weaponPartsList[i]
    local isSelectItem = self.selectMaterial[gunWeaponModData.id]
    if self.selectMaterial[gunWeaponModData.id] ~= nil then
      table.insert(self.resultMaterial, isSelectItem)
    else
      local tmpWeaponPartMaterial = {}
      tmpWeaponPartMaterial.gunWeaponModData = self.weaponPartsList[i]
      tmpWeaponPartMaterial.selectCount = 0
      table.insert(self.resultMaterial, tmpWeaponPartMaterial)
    end
  end
  setactive(self.ui.mTrans_None.gameObject, #self.resultMaterial <= 0)
  if not self.ui.mVirtualListExNew_WeaponPartsList.gameObject.activeInHierarchy then
    return
  end
  self.ui.mVirtualListExNew_WeaponPartsList.numItems = #self.resultMaterial
  self.ui.mVirtualListExNew_WeaponPartsList:Refresh()
  self.ui.mVirtualListExNew_WeaponPartsList.verticalNormalizedPosition = 1
end

function UIChrWeaponPartsPowerUpPanelV4:GetSelectMaterialCount()
  return self.curSelectCount
end

function UIChrWeaponPartsPowerUpPanelV4:AutoSelect()
  if self.gunWeaponModData.level >= self.gunWeaponModData.maxLevel then
    UIUtils.PopupHintMessage(40020)
    return
  end
  local maxLevelExp = self:GetPartTotalExpByLevel(self.gunWeaponModData.maxLevel)
  self.totalExp = self.gunWeaponModData.exp + self:GetPartTotalExpByLevel(self.gunWeaponModData.level)
  local needExp = maxLevelExp - self.totalExp
  local selectMaterialTableIsNil = true
  for i, v in pairs(self.selectMaterial) do
    selectMaterialTableIsNil = false
    local item = v
    if item.itemData ~= nil then
      needExp = needExp - item.itemData.args[0] * item.selectCount
    else
      needExp = needExp - item.gunWeaponModData:GetWeaponOfferExp()
    end
  end
  self.totalExp = maxPolarityExp - needExp
  if needExp <= 0 or self:GetSelectMaterialCount() >= UIWeaponGlobal.MaxMaterialCount then
    local hint = TableData.GetHintById(40020)
    CS.PopupMessageManager.PopupString(hint)
    return
  end
  self.curCostCoin = 0
  local isItemEnough = false
  local isCashEnough = true
  local itemOwn = NetCmdItemData:GetItemCountById(self.itemId)
  if self.selectMaterial[self.itemId] ~= nil then
    itemOwn = itemOwn - self.selectMaterial[self.itemId].selectCount
  end
  if 0 < needExp and 0 < itemOwn then
    local tmpWeaponPartMaterial = {}
    if self.selectMaterial[self.itemId] == nil then
      tmpWeaponPartMaterial = self.tmpWeaponPartMaterialItem
    else
      tmpWeaponPartMaterial = self.selectMaterial[self.itemId]
    end
    local itemExp = tmpWeaponPartMaterial.itemData.args[0]
    local getCanSelect = function()
      return math.floor((GlobalData.cash - self.curCostCoin) / itemExp)
    end
    local needItemCount = math.ceil(needExp / itemExp)
    if itemOwn >= needItemCount then
      tmpWeaponPartMaterial.selectCount = tmpWeaponPartMaterial.selectCount + needItemCount
      isCashEnough = self:CheckCashEnough(tmpWeaponPartMaterial.selectCount * itemExp)
      if not isCashEnough then
        tmpWeaponPartMaterial.selectCount = getCanSelect()
      end
    elseif self.selectMaterial[self.itemId] == nil then
      tmpWeaponPartMaterial.selectCount = itemOwn
      isCashEnough = self:CheckCashEnough(tmpWeaponPartMaterial.selectCount * itemExp)
      if not isCashEnough then
        tmpWeaponPartMaterial.selectCount = getCanSelect()
      end
    else
      isCashEnough = self:CheckCashEnough(itemOwn * itemExp)
      if not isCashEnough then
        tmpWeaponPartMaterial.selectCount = tmpWeaponPartMaterial.selectCount + getCanSelect()
      else
        tmpWeaponPartMaterial.selectCount = tmpWeaponPartMaterial.selectCount + itemOwn
      end
    end
    if tmpWeaponPartMaterial ~= nil and tmpWeaponPartMaterial.selectCount ~= 0 then
      isItemEnough = true
      self.selectMaterial[self.itemId] = tmpWeaponPartMaterial
      self.resultMaterial[1] = tmpWeaponPartMaterial
      self.curSelectCount = self.curSelectCount + 1
      needExp = needExp - tmpWeaponPartMaterial.selectCount * itemExp
    end
  end
  self:UpdateSelectListData()
  isCashEnough = GlobalData.cash > self.curCostCoin
  if isCashEnough and not isItemEnough then
    local startIndex = 1
    local endIndex = #self.resultMaterial
    local step = 1
    if self.comScreenItemV2.IsReverse then
      startIndex = #self.resultMaterial
      endIndex = 1
      step = -1
    end
    for i = startIndex, endIndex, step do
      local tmpWeaponPartMaterial = self.resultMaterial[i]
      if self:CanBeAutoSelect(tmpWeaponPartMaterial) then
        if self:GetSelectMaterialCount() >= UIWeaponGlobal.MaxMaterialCount or needExp <= 0 then
          break
        end
        isCashEnough = self:CheckCashEnough(tmpWeaponPartMaterial.gunWeaponModData:GetWeaponOfferExp())
        if not isCashEnough then
          break
        end
        needExp = needExp - tmpWeaponPartMaterial.gunWeaponModData:GetWeaponOfferExp()
        tmpWeaponPartMaterial.selectCount = 1
        self.selectMaterial[tmpWeaponPartMaterial.gunWeaponModData.id] = tmpWeaponPartMaterial
        self.curSelectCount = self.curSelectCount + 1
        self:CalculateCurCostCoin()
      end
    end
  end
  self:UpdateSelectListData()
  if self.selectMaterial[self.itemId] ~= nil or 0 < self.curSelectCount then
    UIUtils.PopupPositiveHintMessage(40067)
    for i, v in pairs(self.selectMaterial) do
      local item = v
      if item.itemData == nil then
        self.ui.mVirtualListExNew_WeaponPartsList:RefreshItemByIndex(item.index)
      elseif self.selectMaterial[self.itemId] ~= nil then
        self.ui.mVirtualListExNew_WeaponPartsList:RefreshItemByIndex(0)
      end
    end
  else
    self:PopupNotEnoughHint(selectMaterialTableIsNil)
  end
end

function UIChrWeaponPartsPowerUpPanelV4:CanBeAutoSelect(weaponPartMaterial)
  local gunWeaponModData = weaponPartMaterial.gunWeaponModData
  if gunWeaponModData == nil then
    return false
  end
  return gunWeaponModData.id ~= self.gunWeaponModData.id and gunWeaponModData.rank <= self.curAutoSelectRank and gunWeaponModData.level <= 1 and gunWeaponModData.exp <= 0 and 1 > weaponPartMaterial.selectCount and gunWeaponModData.PolarityId == 0 and not gunWeaponModData.IsLocked
end

function UIChrWeaponPartsPowerUpPanelV4:ResetMaterialList()
  for i, item in pairs(self.selectMaterial) do
    item.index = -1
    item.selectCount = 0
  end
  self.selectMaterial = {}
  self.curSelectCount = 0
  self:SetWeaponPartData()
  self.ui.mVirtualListExNew_WeaponPartsList:Refresh()
end

function UIChrWeaponPartsPowerUpPanelV4:GetPartTotalExpByLevel(level)
  level = math.min(level, self.gunWeaponModData.maxLevel)
  local maxExp = self.gunWeaponModData.NewExpList[level - 1]
  return maxExp.exp_total
end

function UIChrWeaponPartsPowerUpPanelV4:ShowOrHideComPropsDetails(boolean)
  local hideCallback
  if boolean then
    setactive(self.ui.mTrans_WeaponPartsInfo.gameObject, boolean)
  else
    function hideCallback()
      if not CS.LuaUtils.IsNullOrDestroyed(self.ui.mTrans_WeaponPartsInfo) then
        setactive(self.ui.mTrans_WeaponPartsInfo.gameObject, boolean)
      end
    end
  end
  if self.curPropsDetailsId == self.itemId then
    if self.chrWeaponPartsInfoItem ~= nil then
      self.chrWeaponPartsInfoItem:ShowOrHide(false, true, hideCallback)
    end
    if self.comPropsDetailsItem ~= nil then
      self.comPropsDetailsItem:ShowOrHide(boolean, true)
    end
  else
    if self.comPropsDetailsItem ~= nil then
      self.comPropsDetailsItem:ShowOrHide(false, true)
    end
    if self.chrWeaponPartsInfoItem ~= nil then
      self.chrWeaponPartsInfoItem:ShowOrHide(boolean, true, hideCallback)
    end
  end
end

function UIChrWeaponPartsPowerUpPanelV4:OnClickBlock()
  self:ShowOrHideComPropsDetails(false)
end

function UIChrWeaponPartsPowerUpPanelV4:SetWeaponPartData()
  BarrackHelper.CameraMgr:SetWeaponRT()
  BarrackHelper.CameraMgr:EnableCharacterCanvas(true)
  UIWeaponGlobal.SetNeedCloseBarrack3DCanvas(false)
  UISystem.BarrackCharacterCameraCtrl:ShowBarrack3DCanvas(true)
  self.targetLevel = self.gunWeaponModData.level
  self.maxLevel = self.gunWeaponModData.maxLevel
  self.isMaxLevel = self.maxLevel == self.gunWeaponModData.level
  self.isPolarityType = self.isMaxLevel and self.gunWeaponModData.WeaponModData.can_polarity
  if self.isPolarityType then
    local mapField = TableData.GlobalSystemData.ModPolarityExpItems
    for i, v in pairs(mapField) do
      if i == self.gunWeaponModData.rank then
        self.itemId = v
        break
      end
    end
  else
    self.itemId = TableData.GlobalSystemData.WeaponModLevelUpItem
  end
  local tmpWeaponPartMaterial = {}
  tmpWeaponPartMaterial.itemData = TableData.listItemDatas:GetDataById(self.itemId)
  tmpWeaponPartMaterial.selectCount = 0
  self.tmpWeaponPartMaterialItem = tmpWeaponPartMaterial
  self:SetWeaponPartTopData()
  if self.curContentType == UIWeaponGlobal.WeaponPartPanelTab.Info then
    self:SetWeaponPartInfoData()
  elseif self.curContentType == UIWeaponGlobal.WeaponPartPanelTab.Enhance and self.isPolarityType then
    setactive(self.ui.mTrans_Polarity.gameObject, true)
    setactive(self.ui.mTrans_LvUp.gameObject, false)
    self:SetWeaponPartPolarityData()
  elseif self.curContentType == UIWeaponGlobal.WeaponPartPanelTab.Enhance and not self.isPolarityType then
    setactive(self.ui.mTrans_Polarity.gameObject, false)
    setactive(self.ui.mTrans_LvUp.gameObject, true)
    self:SetWeaponPartLvUpData()
  end
end

function UIChrWeaponPartsPowerUpPanelV4:SetWeaponPartTopData()
  self:InitLockItem()
  local typeData = self.gunWeaponModData.weaponModTypeData
  local icon = self.gunWeaponModData.icon
  self.ui.mText_Text.text = self.gunWeaponModData.level
  self.ui.mImg_WeaponPartsIcon.sprite = IconUtils.GetWeaponPartIcon(icon)
  self.ui.mText_Name.text = self.gunWeaponModData.name
  self.ui.mText_Type.text = typeData.name.str
  self.ui.mImg_QualityLine.color = TableData.GetGlobalGun_Quality_Color2(self.gunWeaponModData.rank, self.ui.mImg_QualityLine.color.a)
  self.ui.mText_LevelAfter.text = self.gunWeaponModData.level
  self.ui.mImg_TypeIcon.sprite = ResSys:GetWeaponPartEffectSprite(self.gunWeaponModData.ModEffectTypeData.icon)
  self.ui.mText_Num.text = self.gunWeaponModData.Capacity
  self.ui.mText_Quality.text = self.gunWeaponModData.QualityStr
  self:UpdateLockStatue()
  self:SetBtnText()
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateSelectListData()
  if not self.isPolarityType then
    self:UpdateSelectListDataLvUp()
  else
    self:UpdateSelectListDataPolarity()
  end
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateCompareDetail()
  if self.curItem == nil then
    self:ShowOrHideComPropsDetails(false)
    return
  end
  local gunWeaponModData = self.curItem.gunWeaponModData
  local itemData = self.curItem.itemData
  local isFocused = self.curItem.UICommonItem:IsFocused() and self.curItem.selectCount > 0 or self.curItem.gunWeaponModData ~= nil and self.curItem.gunWeaponModData.IsLocked
  if gunWeaponModData then
    function self.lockCallback()
      self:OnClickLockCallback(gunWeaponModData, true)
    end
    
    if self.curPropsDetailsId ~= gunWeaponModData.id and isFocused then
      self.chrWeaponPartsInfoItem = ComPropsDetailsHelper:InitWeaponPartsDataV2(self.ui.mScrollListChild_GrpInfo.transform, gunWeaponModData.id, 0, self.lockCallback, nil, false, false)
      ComPropsDetailsHelper:SetBlockUIRoot(nil, self.ui.mTrans_PartsPowerUp.gameObject, 0, function()
        self:OnClickBlock()
      end)
      self.curPropsDetailsId = gunWeaponModData.id
    end
    self:ShowOrHideComPropsDetails(isFocused)
  elseif itemData ~= nil then
    self:ShowOrHideComPropsDetails(false)
  end
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateAction()
  setactive(self.ui.mBtn_BtnLvUp.transform.parent.gameObject, false)
  setactive(self.ui.mBtn_BtnQuickChoose.transform.parent.gameObject, false)
  setactive(self.ui.mBtn_BtnQuickChoose1.transform.parent.gameObject, false)
  setactive(self.ui.mBtn_BtnIncrease.transform.parent.gameObject, false)
  setactive(self.ui.mBtn_BtnPolarity1.transform.parent.gameObject, false)
  setactive(self.ui.mTrans_Max.gameObject, false)
  if not self.isPolarityType then
    setactive(self.ui.mBtn_BtnLvUp.transform.parent.gameObject, true)
    setactive(self.ui.mBtn_BtnQuickChoose.transform.parent.gameObject, true)
  elseif self.isPolarityType then
    setactive(self.ui.mBtn_BtnQuickChoose1.transform.parent.gameObject, true)
    setactive(self.ui.mBtn_BtnPolarity1.transform.parent.gameObject, self.curSelectIncreaseItemNum == 0)
    setactive(self.ui.mBtn_BtnIncrease.transform.parent.gameObject, self.curSelectIncreaseItemNum > 0)
  else
    setactive(self.ui.mTrans_Max.gameObject, true)
  end
end

function UIChrWeaponPartsPowerUpPanelV4:SetWeaponPartLvUpData()
  self.subPropList = CS.GunWeaponModData.SetWeaponPartAttr(self.gunWeaponModData, self.ui.mScrollListChild_GrpAttribute.transform, self.ui.mTrans_MainAttribute.transform)
  self.targetLevel = self.gunWeaponModData.level
  self.selectMaterial = {}
  self.totalExp = self:GetPartTotalExpByLevel(self.gunWeaponModData.level) + self.gunWeaponModData.exp
  if self.gunWeaponModData.level < self.gunWeaponModData.maxLevel then
    local nextLv = self.gunWeaponModData.level + 1
    local exp = self:GetPartExpByLevel(nextLv)
    self.nextLevelExp = exp
  else
    self.nextLevelExp = 0
  end
  setactive(self.ui.mTrans_SpIcon.gameObject, self.gunWeaponModData.IsSp)
  self:CheckAndActiveCalibrationBtn()
  self:UpdateSelectListData()
  self:UpdateSortContent()
  self:UpdateWeaponPartsSkill()
  self:UpdateAction()
  self.curImgFillAmount = self.ui.mImg_ProgressBarBefore.fillAmount
  self.curBgImgFillAmount = self.ui.mImg_ProgressBarAfter.fillAmount
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateWeaponPartsSkill()
  local modPowerData = self.gunWeaponModData.ModPowerData
  local groupSkillData = self.gunWeaponModData.GroupSkillData
  local powerSkillData = self.gunWeaponModData.PowerSkillCsData
  local hasSkill = false
  if nil == groupSkillData then
    setactive(self.ui.mTrans_GroupSkill.gameObject, false)
  else
    hasSkill = true
    setactive(self.ui.mTrans_GroupSkill.gameObject, true)
    CS.GunWeaponModData.SetModPowerDataNameWithGroupNum(self.ui.mText_Skill, nil, modPowerData, self.gunWeaponModData)
    local showText = self.gunWeaponModData:GetModGroupSkillShowText()
    self.ui.mTextFit_GroupDescribe.text = showText
    setactive(self.ui.mText_Num2.gameObject, false)
    self.ui.mImg_SuitIcon.sprite = IconUtils.GetWeaponPartIconSprite(self.gunWeaponModData.ModPowerData.image, false)
  end
  local tmpParent = self.ui.mTextFit_ProficiencyDescribe.transform.parent
  local extraCapacity = self.gunWeaponModData.ExtraCapacity
  if extraCapacity ~= 0 then
    hasSkill = true
    setactive(tmpParent.gameObject, true)
    local hint2 = TableData.GetHintById(250056)
    self.ui.mTextFit_ProficiencyDescribe.text = string_format(hint2, extraCapacity)
  else
    setactive(tmpParent.gameObject, false)
  end
  setactive(self.ui.mTrans_Skill.gameObject, hasSkill)
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateLvUpInteractable(boolean)
  self.ui.mBtn_BtnLvUp.interactable = boolean
  setactive(self.ui.mTrans_MaxLvTipText.gameObject, not boolean)
  setactive(self.ui.mTrans_SelectText.gameObject, boolean)
  setactive(self.ui.mTrans_SelectAfter.gameObject, boolean)
end

function UIChrWeaponPartsPowerUpPanelV4:CalculateCurCostCoin()
  local addExp = 0
  self.curSelectCount = 0
  for i, tmpWeaponPartMaterial in pairs(self.selectMaterial) do
    self.curSelectCount = self.curSelectCount + 1
    if tmpWeaponPartMaterial.gunWeaponModData ~= nil then
      addExp = addExp + tmpWeaponPartMaterial.gunWeaponModData:GetWeaponOfferExp()
    else
      addExp = addExp + tmpWeaponPartMaterial.itemData.args[0] * tmpWeaponPartMaterial.selectCount
    end
  end
  self.addExp = addExp
  self.totalExp = self.gunWeaponModData.exp + addExp + self:GetPartTotalExpByLevel(self.gunWeaponModData.level)
  local costCoin = self.gunWeaponModData:GetChipCash(self.totalExp)
  self.curCostCoin = costCoin
end

function UIChrWeaponPartsPowerUpPanelV4:CalculateCurPolarityCostCoin()
  local addExp = 0
  self.curSelectCount = 0
  for i, tmpWeaponPartMaterial in pairs(self.selectMaterial) do
    self.curSelectCount = self.curSelectCount + 1
    if tmpWeaponPartMaterial.gunWeaponModData ~= nil then
      addExp = addExp + tmpWeaponPartMaterial.gunWeaponModData:GetWeaponOfferExp()
    else
      addExp = addExp + tmpWeaponPartMaterial.itemData.args[0] * tmpWeaponPartMaterial.selectCount
    end
  end
  self.addExp = addExp
  local totalExp = self.gunWeaponModData.PolarizationExp + addExp
  local costCoin = self.gunWeaponModData:GetPolarityChipCash(totalExp)
  self.curCostCoin = costCoin
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateSelectListDataLvUp()
  self.curSelectCount = 0
  self:CalculateCurCostCoin()
  self.ui.mText_PartsNum.text = self.curSelectCount .. "/" .. UIWeaponGlobal.MaxMaterialCount
  self.targetLevel = math.min(self:CalculateLevel(self.totalExp), self.gunWeaponModData.maxLevel)
  local haveCoinStr = CS.LuaUIUtils.GetNumberText(GlobalData.cash)
  local costCoin = self.curCostCoin
  local addExp = self.addExp
  local costCoinStr = ResourcesCommonItem.ChangeNumDigit(costCoin)
  self.isCoinEnough = costCoin <= GlobalData.cash
  self.ui.mText_GoldNum.text = haveCoinStr
  self.ui.mText_After.text = costCoinStr
  if not self.isCoinEnough then
    self.ui.mText_GoldNum.color = self.ColorList.Red
  else
    self.ui.mText_GoldNum.color = self.ColorList.White
  end
  local maxExp = 0
  local curExp = 0
  local sliderBeforeValue = 0
  local sliderAfterValue = 0
  local curExpData = self:GetPartTotalExpByLevel(self.gunWeaponModData.level)
  local targetExpData = self:GetPartTotalExpByLevel(self.targetLevel)
  if self.gunWeaponModData.exp + addExp >= self.nextLevelExp then
    local nextLevel = self.targetLevel >= self.gunWeaponModData.maxLevel and self.gunWeaponModData.maxLevel or self.targetLevel + 1
    maxExp = self:GetPartExpByLevel(nextLevel)
    if self.targetLevel >= self.gunWeaponModData.maxLevel then
      curExp = maxExp
      sliderBeforeValue = self.ui.mImg_ProgressBarBefore.fillAmount
    else
      curExp = curExpData + self.gunWeaponModData.exp + addExp - targetExpData
    end
    sliderAfterValue = curExp / maxExp
  else
    maxExp = self.nextLevelExp
    if self.targetLevel >= self.gunWeaponModData.maxLevel then
      curExp = maxExp
      sliderBeforeValue = 1
      sliderAfterValue = 1
    else
      curExp = self.gunWeaponModData.exp + addExp
      sliderBeforeValue = self.gunWeaponModData.exp / self.nextLevelExp
      sliderAfterValue = (self.gunWeaponModData.exp + addExp) / self.nextLevelExp
    end
  end
  self.ui.mText_Exp.text = string_format("{0}/{1}", curExp, maxExp)
  self.curBgImgFillAmount = sliderAfterValue
  self.ui.mImg_ProgressBarAfter.fillAmount = sliderAfterValue
  self.ui.mImg_ProgressBarBefore.fillAmount = sliderBeforeValue
  setactive(self.ui.mText_Add.gameObject, 0 < addExp)
  self.ui.mText_Add.text = "+" .. addExp
  self.ui.mText_LevelAfter.text = self.targetLevel
  self.ui.mText_LevelMax.text = "/" .. self.gunWeaponModData.maxLevel
  self:UpdateLvUpInteractable(0 < addExp)
  self.canLevelUp = 0 < addExp
  if self.gunWeaponModData.level ~= self.targetLevel then
    self.subPropList = CS.GunWeaponModData.SetWeaponPartAttr(self.gunWeaponModData, self.ui.mScrollListChild_GrpAttribute.transform, self.ui.mTrans_MainAttribute.transform, self.targetLevel)
  else
    self.subPropList = CS.GunWeaponModData.SetWeaponPartAttr(self.gunWeaponModData, self.ui.mScrollListChild_GrpAttribute.transform, self.ui.mTrans_MainAttribute.transform)
  end
end

function UIChrWeaponPartsPowerUpPanelV4:GetPartExpByLevel(level)
  level = math.min(level, self.gunWeaponModData.maxLevel)
  local maxExp = self.gunWeaponModData.NewExpList[level - 1]
  return maxExp.exp
end

function UIChrWeaponPartsPowerUpPanelV4:CalculateLevel(exp)
  for i = 1, self.gunWeaponModData.NewExpList.Count - 1 do
    local needData = self.gunWeaponModData.NewExpList[i]
    local lastData = self.gunWeaponModData.NewExpList[i - 1]
    local needExp = needData.exp_total
    local lastExp = lastData.exp_total
    if exp >= lastExp and exp < needExp then
      return lastData.level
    end
  end
  local expData = self.gunWeaponModData.NewExpList[self.gunWeaponModData.NewExpList.Count - 1]
  return expData.level
end

function UIChrWeaponPartsPowerUpPanelV4:SetWeaponPartPolarityData()
  self.subPropList = CS.GunWeaponModData.SetWeaponPartAttr(self.gunWeaponModData, self.ui.mScrollListChild_GrpAttribute.transform, self.ui.mTrans_MainAttribute.transform)
  self.polarityId = self.gunWeaponModData.PolarityId
  CS.GunWeaponModData.SetModLevelText(self.ui.mText_Level, self.gunWeaponModData, nil, false, self.ui.mCanvasGroup_Level)
  self.selectMaterial = {}
  self.totalExp = self.gunWeaponModData.PolarizationExp
  if self.gunWeaponModData.level < self.gunWeaponModData.maxLevel then
    local nextLv = self.gunWeaponModData.level + 1
    local exp = self:GetPartExpByLevel(nextLv)
    self.nextLevelExp = exp
  else
    self.nextLevelExp = 0
  end
  setactive(self.ui.mTrans_SpIcon.gameObject, self.gunWeaponModData.IsSp)
  self:CheckAndActiveCalibrationBtn()
  local isUnLockIncrease = AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.ModDecompose) and CS.GunWeaponModData.ModDecomposeUpSwitch
  setactive(self.ui.mTrans_Increase.gameObject, isUnLockIncrease)
  self:UpdateCostItem()
  IconUtils.GetItemIconSpriteAsync(CS.GunWeaponModProperty.DecomposeUpItemId, self.ui.mImg_IncreaseIcon)
  self:UpdateSelectListData()
  self:UpdateSortContent()
  self:UpdateWeaponPartsSkillPolarity()
  self:UpdateAction()
  self.curImgFillAmount = self.ui.mImg_ProgressBarBefore1.fillAmount
  self.curBgImgFillAmount = self.ui.mImg_ProgressBarAfter1.fillAmount
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateWeaponPartsSkillPolarity()
  local modPowerData = self.gunWeaponModData.ModPowerData
  local groupSkillData = self.gunWeaponModData.GroupSkillData
  local powerSkillData = self.gunWeaponModData.PowerSkillCsData
  local hasSkill = false
  if nil == groupSkillData then
    setactive(self.ui.mTrans_GroupSkill1.gameObject, false)
  else
    hasSkill = true
    setactive(self.ui.mTrans_GroupSkill1.gameObject, true)
    CS.GunWeaponModData.SetModPowerDataNameWithGroupNum(self.ui.mText_Skill1, nil, modPowerData, self.gunWeaponModData)
    local showText = self.gunWeaponModData:GetModGroupSkillShowText()
    self.ui.mTextFit_GroupDescribe1.text = showText
    setactive(self.ui.mText_Num6.gameObject, false)
    self.ui.mImg_SuitIcon1.sprite = IconUtils.GetWeaponPartIconSprite(self.gunWeaponModData.ModPowerData.image, false)
  end
  local extraCapacity = self.gunWeaponModData.ExtraCapacity
  if extraCapacity ~= 0 then
    setactive(self.ui.mTrans_OtherPartsSkillDescribe1.gameObject, true)
    hasSkill = true
    setactive(self.ui.mTextFit_ProficiencyDescribe1.gameObject, true)
    local hint2 = TableData.GetHintById(250056)
    self.ui.mTextFit_ProficiencyDescribe1.text = string_format(hint2, extraCapacity)
  else
    setactive(self.ui.mTrans_OtherPartsSkillDescribe1.gameObject, false)
  end
  setactive(self.ui.mTrans_Skill1.gameObject, hasSkill)
  local weaponModStcData = self.gunWeaponModData.WeaponModData
  setactive(self.ui.mTrans_AdditionTab2.gameObject, false)
  setactive(self.ui.mTrans_AdditionTab3.gameObject, false)
  if weaponModStcData.polarity_affix ~= 0 then
    setactive(self.ui.mTrans_AdditionTab2.gameObject, true)
  end
  if weaponModStcData.polarity_skill ~= 0 then
    setactive(self.ui.mTrans_AdditionTab3.gameObject, true)
  end
end

function UIChrWeaponPartsPowerUpPanelV4:UpdatePolarityInteractable(boolean)
  self.ui.mBtn_BtnPolarity1.interactable = boolean
  self.ui.mBtn_BtnIncrease.interactable = boolean
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateSelectListDataPolarity()
  local addExp = 0
  self.curSelectCount = 0
  for i, tmpWeaponPartMaterial in pairs(self.selectMaterial) do
    self.curSelectCount = self.curSelectCount + 1
    if tmpWeaponPartMaterial.gunWeaponModData ~= nil then
      addExp = addExp + tmpWeaponPartMaterial.gunWeaponModData:GetWeaponOfferExp()
    else
      addExp = addExp + tmpWeaponPartMaterial.itemData.args[0] * tmpWeaponPartMaterial.selectCount
    end
  end
  self.ui.mText_PartsNum1.text = self.curSelectCount .. "/" .. UIWeaponGlobal.MaxMaterialCount
  self.totalExp = self.gunWeaponModData.PolarizationExp + addExp
  local haveCoinStr = CS.LuaUIUtils.GetMaxNumberText(GlobalData.cash)
  local costCoin = self.gunWeaponModData:GetPolarityChipCash(self.totalExp)
  local costNum = CS.GunWeaponModProperty.DecomposeUpCoinNum * self.curSelectIncreaseItemNum
  costCoin = costCoin + costNum
  local costCoinStr = CS.LuaUIUtils.GetMaxNumberText(costCoin)
  self.isCoinEnough = costCoin <= GlobalData.cash
  self.ui.mText_Before.text = haveCoinStr
  self.ui.mText_After1.text = costCoinStr
  if not self.isCoinEnough then
    self.ui.mText_Before.color = self.ColorList.Red
  else
    self.ui.mText_Before.color = self.ColorList.White
  end
  local maxExp = self.gunWeaponModData.PolarityExpData.exp
  local curExp = self.gunWeaponModData.PolarizationExp
  if self.gunWeaponModData.PolarityTagData ~= nil then
    curExp = maxExp
  end
  local sliderBeforeValue = curExp / maxExp
  local sliderAfterValue = self.totalExp / maxExp
  if maxExp < self.totalExp then
    sliderAfterValue = 1
  end
  setactive(self.ui.mTrans_Full.gameObject, sliderAfterValue == 1)
  local totalExp = self.totalExp
  if maxExp <= totalExp then
    self.ui.mText_Exp1.text = string_format("{0}/{1}", totalExp, maxExp)
  else
    self.ui.mText_Exp1.text = string_format("<color=#ff5e41>{0}</color>/{1}", totalExp, maxExp)
  end
  self.curBgImgFillAmount = sliderAfterValue
  self.ui.mImg_ProgressBarAfter1.fillAmount = sliderAfterValue
  self.ui.mImg_ProgressBarBefore1.fillAmount = 0
  setactive(self.ui.mText_Add1.gameObject, false)
  self:UpdatePolarityInteractable(self.totalExp >= self.gunWeaponModData.MaxPolarityExp)
  setactive(self.ui.mTrans_SelectText1.gameObject, 0 < addExp or 0 < costCoin)
  setactive(self.ui.mTrans_SelectAfter1.gameObject, 0 < addExp or 0 < costCoin)
  self.subPropList = CS.GunWeaponModData.SetWeaponPartAttr(self.gunWeaponModData, self.ui.mScrollListChild_GrpAttribute1.transform, self.ui.mTrans_MainAttribute1.transform)
end

function UIChrWeaponPartsPowerUpPanelV4:AutoSelectPolarity()
  if self.gunWeaponModData.PolarizationExp >= self.gunWeaponModData.PolarityExpData.exp then
    UIUtils.PopupHintMessage(250037)
    return
  end
  local maxPolarityExp = self.gunWeaponModData.PolarityExpData.exp
  self.totalExp = self.gunWeaponModData.PolarizationExp
  local needExp = maxPolarityExp - self.totalExp
  local selectMaterialTableIsNil = true
  for i, v in pairs(self.selectMaterial) do
    selectMaterialTableIsNil = false
    local item = v
    if item.itemData ~= nil then
      needExp = needExp - item.itemData.args[0] * item.selectCount
    else
      needExp = needExp - item.gunWeaponModData:GetWeaponOfferExp()
    end
  end
  self.totalExp = maxPolarityExp - needExp
  if needExp <= 0 or self:GetSelectMaterialCount() >= UIWeaponGlobal.MaxMaterialCount then
    local hint = TableData.GetHintById(40020)
    CS.PopupMessageManager.PopupString(hint)
    return
  end
  self.curCostCoin = 0
  local isItemEnough = false
  local isCashEnough = true
  local itemOwn = NetCmdItemData:GetItemCountById(self.itemId)
  if self.selectMaterial[self.itemId] ~= nil then
    itemOwn = itemOwn - self.selectMaterial[self.itemId].selectCount
  end
  if 0 < needExp and 0 < itemOwn then
    local tmpWeaponPartMaterial = {}
    if self.selectMaterial[self.itemId] == nil then
      tmpWeaponPartMaterial = self.tmpWeaponPartMaterialItem
    else
      tmpWeaponPartMaterial = self.selectMaterial[self.itemId]
    end
    local itemExp = tmpWeaponPartMaterial.itemData.args[0]
    local getCanSelect = function()
      return math.floor((GlobalData.cash - self.curCostCoin) / itemExp)
    end
    local needItemCount = math.ceil(needExp / itemExp)
    if itemOwn >= needItemCount then
      tmpWeaponPartMaterial.selectCount = needItemCount
      isCashEnough = self:CheckCashEnoughPolarity(tmpWeaponPartMaterial.selectCount * itemExp)
      if not isCashEnough then
        tmpWeaponPartMaterial.selectCount = getCanSelect()
      end
    elseif self.selectMaterial[self.itemId] == nil then
      tmpWeaponPartMaterial.selectCount = itemOwn
      isCashEnough = self:CheckCashEnoughPolarity(tmpWeaponPartMaterial.selectCount * itemExp)
      if not isCashEnough then
        tmpWeaponPartMaterial.selectCount = getCanSelect()
      end
    else
      isCashEnough = self:CheckCashEnoughPolarity(itemOwn * itemExp)
      if not isCashEnough then
        tmpWeaponPartMaterial.selectCount = tmpWeaponPartMaterial.selectCount + getCanSelect()
      else
        tmpWeaponPartMaterial.selectCount = tmpWeaponPartMaterial.selectCount + itemOwn
      end
    end
    if tmpWeaponPartMaterial ~= nil and tmpWeaponPartMaterial.selectCount ~= 0 then
      isItemEnough = true
      self.selectMaterial[self.itemId] = tmpWeaponPartMaterial
      self.resultMaterial[1] = tmpWeaponPartMaterial
      self.curSelectCount = self.curSelectCount + 1
      needExp = needExp - tmpWeaponPartMaterial.selectCount * itemExp
    end
  end
  self:UpdateSelectListData()
  isCashEnough = GlobalData.cash > self.curCostCoin
  if isCashEnough and not isItemEnough then
    local startIndex = 1
    local endIndex = #self.resultMaterial
    local step = 1
    if self.comScreenItemV2.IsReverse then
      startIndex = #self.resultMaterial
      endIndex = 1
      step = -1
    end
    for i = startIndex, endIndex, step do
      local tmpWeaponPartMaterial = self.resultMaterial[i]
      if self:CanBeAutoSelect(tmpWeaponPartMaterial) then
        if self:GetSelectMaterialCount() >= UIWeaponGlobal.MaxMaterialCount or needExp <= 0 then
          break
        end
        isCashEnough = self:CheckCashEnoughPolarity(tmpWeaponPartMaterial.gunWeaponModData:GetWeaponOfferExp())
        if not isCashEnough then
          break
        end
        needExp = needExp - tmpWeaponPartMaterial.gunWeaponModData:GetWeaponOfferExp()
        tmpWeaponPartMaterial.selectCount = 1
        self.selectMaterial[tmpWeaponPartMaterial.gunWeaponModData.id] = tmpWeaponPartMaterial
        self.curSelectCount = self.curSelectCount + 1
        self:CalculateCurCostCoin()
      end
    end
  end
  self:UpdateSelectListData()
  if self.selectMaterial[self.itemId] ~= nil or 0 < self.curSelectCount then
    UIUtils.PopupPositiveHintMessage(40067)
    for i, v in pairs(self.selectMaterial) do
      local item = v
      if item.itemData == nil then
        self.ui.mVirtualListExNew_WeaponPartsList:RefreshItemByIndex(item.index)
      elseif self.selectMaterial[self.itemId] ~= nil then
        self.ui.mVirtualListExNew_WeaponPartsList:RefreshItemByIndex(0)
      end
    end
  else
    self:PopupNotEnoughHint(selectMaterialTableIsNil)
  end
end

function UIChrWeaponPartsPowerUpPanelV4:ChangeContent(contentType)
  if self.curContentType == contentType then
    if self.curContentType == UIWeaponGlobal.WeaponPartPanelTab.Enhance and self.isPolarityType then
      self:ShowPowerUp(false, function()
        self:ShowPowerUp(true)
      end)
    end
    return
  end
  if contentType == 0 then
    self:ShowInfo(false)
    self:ShowPowerUp(false)
    self.targetContentType = 0
    self.curContentType = 0
    return
  end
  if self.curContentType ~= 0 then
    if self.curContentType == UIWeaponGlobal.WeaponPartPanelTab.Info then
      self:ShowInfo(false, function()
        self:ShowPowerUp(true)
      end)
    elseif self.curContentType == UIWeaponGlobal.WeaponPartPanelTab.Enhance then
      self:ShowPowerUp(false, function()
        self:ShowInfo(true)
      end)
    end
  elseif contentType == UIWeaponGlobal.WeaponPartPanelTab.Info then
    self:ShowInfo(true)
  elseif contentType == UIWeaponGlobal.WeaponPartPanelTab.Enhance then
    self:ShowPowerUp(true)
  end
  self.curContentType = contentType
  self:SetWeaponPartData()
end

function UIChrWeaponPartsPowerUpPanelV4:ListIndexChange(value)
  self.listIndex = self.listIndex + value
  if self.listIndex < 1 then
    self.listIndex = #self.weaponModList.list
  elseif self.listIndex > #self.weaponModList.list then
    self.listIndex = 1
  end
  if NetCmdWeaponPartsData:GetWeaponModById(self.weaponModList.list[self.listIndex].id) == nil then
    self:ListIndexChange(value)
  else
    self.gunWeaponModData = self.weaponModList.list[self.listIndex]
    self.gunWeaponModData = NetCmdWeaponPartsData:GetWeaponModById(self.gunWeaponModData.id)
    self:SetWeaponPartData()
  end
end

function UIChrWeaponPartsPowerUpPanelV4:ShowList()
  for i, mod in pairs(self.weaponModList.list) do
    if mod.id == self.gunWeaponModData.id then
      self.listIndex = i
      self.gunWeaponModData = NetCmdWeaponPartsData:GetWeaponModById(mod.id)
      break
    end
  end
  local arrowBtn = UICommonArrowBtnItem.New()
  arrowBtn:InitObj(self.weaponPartInfoUI.mTrans_Arrow)
  arrowBtn:SetLeftArrowClickFunction(function()
    self:ListIndexChange(-1)
  end)
  arrowBtn:SetRightArrowClickFunction(function()
    self:ListIndexChange(1)
  end)
  arrowBtn:SetLeftArrowActiveFunction(function()
    return #self.weaponModList.list > 1
  end)
  arrowBtn:SetRightArrowActiveFunction(function()
    return #self.weaponModList.list > 1
  end)
  arrowBtn:RefreshArrowActive()
end

function UIChrWeaponPartsPowerUpPanelV4:ShowInfo(boolean, callback)
  if boolean then
    setactive(self.ui.mTrans_PartsRepositoryInfo.gameObject, true)
    setactive(self.weaponPartInfoUI.mTrans_Arrow, self.weaponModList ~= nil)
    if self.weaponModList ~= nil then
      self:ShowList()
    end
    self:SetWeaponPartData()
  else
    self.ui.mAnimator_PartsRepositoryInfo:SetTrigger("FadeOut")
    local length = self.weaponPartInfoFadeOutAnimLength
    TimerSys:DelayCall(length, function()
      if not CS.LuaUtils.IsNullOrDestroyed(self.ui.mTrans_PartsRepositoryInfo) then
        setactive(self.ui.mTrans_PartsRepositoryInfo.gameObject, false)
      end
      if callback ~= nil then
        callback()
      end
    end)
  end
end

function UIChrWeaponPartsPowerUpPanelV4:ShowPowerUp(boolean, callback)
  if boolean then
    setactive(self.ui.mTrans_PartsPowerUp.gameObject, true)
    self:SetWeaponPartData()
  else
    self.ui.mAnimator_PartsPowerUp:SetTrigger("FadeOut")
    local length = self.weaponPartPowerUpFadeOutAnimLength
    TimerSys:DelayCall(length, function()
      if not CS.LuaUtils.IsNullOrDestroyed(self.ui.mTrans_PartsPowerUp) then
        setactive(self.ui.mTrans_PartsPowerUp.gameObject, false)
      end
      if callback ~= nil then
        callback()
      end
    end)
  end
end

function UIChrWeaponPartsPowerUpPanelV4:CheckResetTargetContentType2Info()
  if self.openFromType == UIWeaponGlobal.WeaponPartPanelTab.Info then
    self.targetContentType = UIWeaponGlobal.WeaponPartPanelTab.Info
  end
end

function UIChrWeaponPartsPowerUpPanelV4:SetWeaponPartInfoData()
  UIWeaponGlobal.SetNeedCloseBarrack3DCanvas(false)
  self.bgImg.sprite = ResSys:GetWeaponBgSprite("Img_Weapon_Bg")
  UISystem.BarrackCharacterCameraCtrl:ShowBarrack3DCanvas(true)
  self.gunWeaponModData = NetCmdWeaponPartsData:GetWeaponModById(self.gunWeaponModData.id)
  local tmpGunWeaponModData = self.gunWeaponModData
  self.weaponPartInfoUI.mText_Name.text = tmpGunWeaponModData.name
  self.weaponPartInfoUI.mText_Type1.text = tmpGunWeaponModData.weaponModTypeData.Name.str
  self.weaponPartInfoUI.mText_Quality.text = tmpGunWeaponModData.QualityStr
  self.weaponPartInfoUI.mImg_TypeIcon.sprite = ResSys:GetWeaponPartEffectSprite(tmpGunWeaponModData.ModEffectTypeData.icon)
  self.weaponPartInfoUI.mImg_QualityLine.color = TableData.GetGlobalGun_Quality_Color2(tmpGunWeaponModData.rank, self.weaponPartInfoUI.mImg_QualityLine.color.a)
  self.weaponPartInfoUI.mText_Num.text = tmpGunWeaponModData.Capacity
  setactive(self.ui.mTrans_SpIcon1.gameObject, tmpGunWeaponModData.IsSp)
  self:SetModLevelInfo(tmpGunWeaponModData)
  self.weaponPartInfoUI.mText_Type.text = tmpGunWeaponModData.weaponModTypeData.weapon_mod_des.str
  self.weaponPartInfoUI.mTextFit_Describe.text = tmpGunWeaponModData.ItemData.introduction.str
  self.subPropList = CS.GunWeaponModData.SetWeaponPartAttr(tmpGunWeaponModData, self.weaponPartInfoUI.mScrollListChild_GrpItem.transform, self.ui.mTrans_MainAttribute2.transform)
  setactive(self.weaponPartInfoUI.mText_Num2.gameObject, false)
  self:CheckAndActiveCalibrationBtn()
  self:UpdateWeaponPartInfoLockStatue()
  self:UpdateIsUse()
  self:UpdateWeaponPartInfoSkill()
  self:UpdateWeaponPartInfoAction()
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateIsUse()
  setactive(self.weaponPartInfoUI.mTrans_State.gameObject, self.gunWeaponModData.equipWeapon ~= 0)
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateWeaponPartInfoLockStatue()
  self.weaponPartsInfoLockItem:SetLock(self.gunWeaponModData.IsLocked)
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateWeaponPartInfoSkill()
  local modPowerData = self.gunWeaponModData.ModPowerData
  local groupSkillData = self.gunWeaponModData.GroupSkillData
  local PowerSkillCsData = self.gunWeaponModData.PowerSkillCsData
  if nil == groupSkillData then
    setactive(self.weaponPartInfoUI.mTrans_GroupSkill.gameObject, false)
  else
    setactive(self.weaponPartInfoUI.mTrans_GroupSkill.gameObject, true)
    CS.GunWeaponModData.SetModPowerDataNameWithGroupNum(self.weaponPartInfoUI.mText_Skill, nil, modPowerData, self.gunWeaponModData)
    local showText = self.gunWeaponModData:GetModGroupSkillShowText()
    self.weaponPartInfoUI.mTextFit_GroupDescribe.text = showText
    self.weaponPartInfoUI.mImg_SuitIcon.sprite = IconUtils.GetWeaponPartIconSprite(self.gunWeaponModData.ModPowerData.image, false)
  end
  local tmpParent = self.weaponPartInfoUI.mTrans_OtherPartsSkillDescribe1
  local tmpItem = self.weaponPartInfoUI.mTrans_PartsSkill1
  local count = CS.GunWeaponModData.SetWeaponPartProficiencySkill(self.gunWeaponModData, tmpParent, tmpItem)
  setactive(self.weaponPartInfoUI.mTrans_PartsSkill.gameObject, nil ~= groupSkillData or 0 ~= count)
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateWeaponPartInfoAction()
  setactive(self.weaponPartInfoUI.mBtn_BtnLevelUp.transform.parent.gameObject, false)
  setactive(self.weaponPartInfoUI.mBtn_BtnPolarity.transform.parent.gameObject, false)
  setactive(self.weaponPartInfoUI.mTrans_Disable.gameObject, false)
  setactive(self.weaponPartInfoUI.mTrans_Mismatch.gameObject, false)
  setactive(self.weaponPartInfoUI.mTrans_MaxLevel.gameObject, false)
  if not AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.GundetailWeaponpartUpgrade) then
    setactive(self.weaponPartInfoUI.mTrans_Mismatch.gameObject, true)
    local unlockData = AccountNetCmdHandler:GetUnlockDataBySystemId(SystemList.GundetailWeaponpartUpgrade)
    local str = UIUtils.CheckUnlockPopupStr(unlockData)
    self.weaponPartInfoUI.mText_MismatchName.text = str
    return
  end
  if not AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.GundetailWeaponpartPolarity) then
    setactive(self.weaponPartInfoUI.mTrans_Disable.gameObject, true)
    local unlockData = AccountNetCmdHandler:GetUnlockDataBySystemId(SystemList.GundetailWeaponpartPolarity)
    local str = UIUtils.CheckUnlockPopupStr(unlockData)
    self.weaponPartInfoUI.mText_MismatchName.text = str
    return
  end
  if self.gunWeaponModData.level < self.gunWeaponModData.maxLevel then
    setactive(self.weaponPartInfoUI.mBtn_BtnLevelUp.transform.parent.gameObject, true)
    return
  end
  if not self.gunWeaponModData.WeaponModData.can_polarity then
    setactive(self.weaponPartInfoUI.mTrans_Disable.gameObject, true)
    return
  end
  setactive(self.weaponPartInfoUI.mBtn_BtnPolarity.transform.parent.gameObject, true)
end

function UIChrWeaponPartsPowerUpPanelV4:SetModLevelInfo(tmpGunWeaponModData)
  CS.GunWeaponModData.SetModLevelText(self.ui.mText_NumNow_Info, tmpGunWeaponModData, self.ui.mText_Max_Info)
  CS.GunWeaponModData.SetModPolarityText(self.ui.mText_State_Info, self.ui.mImg_PolarityIcon_Info, tmpGunWeaponModData, self.ui.mCanvasGroup_Lv_Info)
end

function UIChrWeaponPartsPowerUpPanelV4:SetBtnText()
  if self.gunWeaponModData.PolarityId == 0 then
    local text1 = TableData.GetHintById(250014)
    self.btnPolarityText.text = text1
    self.btnPolarity1Text.text = text1
    self.btnIncreaseText.text = TableData.GetHintById(310060)
  else
    local text1 = TableData.GetHintById(251044)
    self.btnPolarityText.text = text1
    self.btnPolarity1Text.text = text1
    self.btnIncreaseText.text = TableData.GetHintById(251045)
  end
end

function UIChrWeaponPartsPowerUpPanelV4:OnClickLevelUp()
  self:ChangeContent(UIWeaponGlobal.WeaponPartPanelTab.Enhance)
  self:CheckResetTargetContentType2Info()
end

function UIChrWeaponPartsPowerUpPanelV4:OnClickPolarity()
  self:OnClickLevelUp()
  local animator = self.weaponPartInfoUI.mTrans_Arrow.parent:GetComponent(typeof(CS.UnityEngine.Animator))
  if animator then
    animator:SetTrigger("FadeOut")
  end
end

function UIChrWeaponPartsPowerUpPanelV4:OnClickWeaponPartInfoLock(isOn)
  if isOn == self.gunWeaponModData.IsLocked then
    return
  end
  NetCmdWeaponPartsData:ReqWeaponPartLockUnlock(self.gunWeaponModData.id, function(ret)
    if ret == ErrorCodeSuc then
      self:UpdateWeaponPartInfoLockStatue()
    end
  end)
end

function UIChrWeaponPartsPowerUpPanelV4:OnBtnCalibrationClick()
  local callback = function()
    self.gunWeaponModData = NetCmdWeaponPartsData:GetWeaponModById(self.gunWeaponModData.id)
    self:SetWeaponPartData()
  end
  local param = {
    gunWeaponModData = self.gunWeaponModData,
    callback = callback
  }
  UIManager.OpenUIByParam(UIDef.UIChrWeaponPartsCalibrationDialog, param)
end

function UIChrWeaponPartsPowerUpPanelV4:OnQuickChooseClick()
  if self.isPolarityType then
    self:AutoSelectPolarity()
  else
    self:AutoSelect()
  end
end

function UIChrWeaponPartsPowerUpPanelV4:OnStageUpClick()
  if self.gunWeaponModData.level >= self.gunWeaponModData.maxLevel then
    UIUtils.PopupHintMessage(40020)
    return
  end
  if not self.isCoinEnough then
    local item = TableData.listItemDatas:GetDataById(2)
    TipsPanelHelper.OpenUITipsPanel(item, GlobalData.cash, true)
    return
  end
  if not self.canLevelUp then
    UIUtils.PopupHintMessage(40019)
    return
  end
  local itemList, partList = self:GetMaterialList()
  self.recordLv = self.gunWeaponModData.level
  self.recordExp = self.gunWeaponModData.exp
  self:UpdateLvUpInteractable(false)
  self:SetCurItem()
  self:UpdateCompareDetail()
  NetCmdWeaponPartsData:ReqWeaponPartLvUp(self.gunWeaponModData.id, partList, itemList, function(ret)
    if ret == ErrorCodeSuc then
      self:SetInputActive(false)
      local start = self.recordLv + self.curImgFillAmount
      local endLv = self.targetLevel + self.curBgImgFillAmount
      CS.ProgressBarAnimationHelper.PlayProgress(self.ui.mImg_ProgressBarBefore, self.ui.mImg_ProgressBarAfter, start, endLv, 0.5, nil, function()
        self.gunWeaponModData = NetCmdWeaponPartsData:GetWeaponModById(self.gunWeaponModData.id)
        self.isMaxLevel = self.maxLevel == self.gunWeaponModData.level
        self:OpenLevelUpPanel()
        self:SetInputActive(true)
      end)
    end
  end)
end

function UIChrWeaponPartsPowerUpPanelV4:GetMaterialList()
  local itemList = {}
  local partList = {}
  for _, item in pairs(self.selectMaterial) do
    if item.itemData ~= nil then
      itemList[item.itemData.id] = item.selectCount
    elseif item.gunWeaponModData ~= nil then
      table.insert(partList, item.gunWeaponModData.id)
    end
  end
  return itemList, partList
end

function UIChrWeaponPartsPowerUpPanelV4:OnClickReduce(item)
  if item.itemData == nil then
    return
  end
  item.selectCount = item.selectCount - 1
  if item.selectCount == 0 then
    self.selectMaterial[self.itemId] = nil
  end
  self:SetCurItem(item)
  self:UpdateSelectListData()
end

function UIChrWeaponPartsPowerUpPanelV4:OnClickItem(item)
  if self.isPolarityType then
    self:OnClickItemPolarity(item)
  else
    self:OnClickItemLvUp(item)
  end
  self:SetCurItem(item)
  self:UpdateCompareDetail()
  self:UpdateSelectListData()
end

function UIChrWeaponPartsPowerUpPanelV4:OnClickItemLvUp(item)
  local maxLevelExp = self:GetPartTotalExpByLevel(self.gunWeaponModData.maxLevel)
  local needExp = maxLevelExp - self.totalExp
  if item.gunWeaponModData ~= nil then
    if item.gunWeaponModData.IsLocked then
      local hint = TableData.GetHintById(102239)
      CS.PopupMessageManager.PopupString(hint)
    elseif item.selectCount > 0 then
      item.UICommonItem:SetMaterialSelect(false)
      self.selectMaterial[item.gunWeaponModData.id].selectCount = 0
      self.curSelectCount = self.curSelectCount - 1
      self.selectMaterial[item.gunWeaponModData.id] = nil
    else
      if self.targetLevel >= self.gunWeaponModData.maxLevel then
        UIUtils.PopupHintMessage(40020)
        return
      end
      if self:GetSelectMaterialCount() >= UIWeaponGlobal.MaxMaterialCount then
        UIUtils.PopupHintMessage(40010)
        return
      elseif needExp <= 0 then
        local hint = TableData.GetHintById(40020)
        CS.PopupMessageManager.PopupString(hint)
        return
      else
        item.selectCount = 1
        item.UICommonItem:SetMaterialSelect(true)
        self.selectMaterial[item.gunWeaponModData.id] = item
        self.curSelectCount = self.curSelectCount + 1
        needExp = needExp - item.gunWeaponModData:GetWeaponOfferExp()
      end
    end
  elseif needExp <= 0 then
    local hint = TableData.GetHintById(40020)
    CS.PopupMessageManager.PopupString(hint)
  else
    if self.targetLevel >= self.gunWeaponModData.maxLevel then
      UIUtils.PopupHintMessage(40020)
      return
    end
    local itemOwn = NetCmdItemData:GetItemCountById(self.itemId)
    if item.selectCount == nil then
      item.selectCount = 0
    end
    if itemOwn < item.selectCount + 1 then
      return
    end
    item.selectCount = item.selectCount + 1
    item.UICommonItem:SetMaterialSelect(true, true)
    self:SetCurItem(item)
    needExp = needExp - item.itemData.args[0]
    self.curSelectCount = self.curSelectCount + 1
    self.selectMaterial[self.itemId] = item
  end
end

function UIChrWeaponPartsPowerUpPanelV4:OnClickItemPolarity(item)
  local maxLevelExp = self.gunWeaponModData.PolarityExpData.exp
  local needExp = maxLevelExp - self.totalExp
  if item.gunWeaponModData ~= nil then
    if item.gunWeaponModData.IsLocked then
      local hint = TableData.GetHintById(102239)
      CS.PopupMessageManager.PopupString(hint)
    elseif item.selectCount > 0 then
      item.UICommonItem:SetMaterialSelect(false)
      self.selectMaterial[item.gunWeaponModData.id].selectCount = 0
      self.curSelectCount = self.curSelectCount - 1
      self.selectMaterial[item.gunWeaponModData.id] = nil
    elseif self:GetSelectMaterialCount() >= UIWeaponGlobal.MaxMaterialCount then
      UIUtils.PopupHintMessage(40010)
      return
    elseif needExp <= 0 then
      local hint = TableData.GetHintById(40020)
      CS.PopupMessageManager.PopupString(hint)
      return
    else
      item.selectCount = 1
      item.UICommonItem:SetMaterialSelect(true)
      self.selectMaterial[item.gunWeaponModData.id] = item
      self.curSelectCount = self.curSelectCount + 1
      needExp = needExp - item.gunWeaponModData:GetWeaponOfferExp()
    end
  elseif needExp <= 0 then
    local hint = TableData.GetHintById(40020)
    CS.PopupMessageManager.PopupString(hint)
  else
    local itemOwn = NetCmdItemData:GetItemCountById(self.itemId)
    if item.selectCount == nil then
      item.selectCount = 0
    end
    if itemOwn < item.selectCount + 1 then
      return
    end
    item.selectCount = item.selectCount + 1
    item.UICommonItem:SetMaterialSelect(true, true)
    self:SetCurItem(item)
    needExp = needExp - item.itemData.args[0]
    self.curSelectCount = self.curSelectCount + 1
    self.selectMaterial[self.itemId] = item
  end
  self:SetCurItem(item)
  self:UpdateCompareDetail()
  self:UpdateSelectListData()
end

function UIChrWeaponPartsPowerUpPanelV4:SetCurItem(item)
  local refreshIndex1 = 0
  local refreshIndex2 = 0
  if self.curItem then
    if self.curItem.itemData ~= nil and self.curPropsDetailsId ~= self.curItem.itemData.id then
      if self.ui.mTrans_WeaponPartsInfo.gameObject.activeSelf then
        self:ShowOrHideComPropsDetails(false)
      end
    elseif self.curItem.gunWeaponModData ~= nil and self.curPropsDetailsId ~= self.curItem.gunWeaponModData.id and self.ui.mTrans_WeaponPartsInfo.gameObject.activeSelf then
      self:ShowOrHideComPropsDetails(false)
    end
    refreshIndex1 = self.curItem.index
  end
  if item then
    self.curItem = item
    refreshIndex2 = self.curItem.index
  else
    self.curItem = nil
  end
  self.ui.mVirtualListExNew_WeaponPartsList:RefreshItemByIndex(refreshIndex1)
  self.ui.mVirtualListExNew_WeaponPartsList:RefreshItemByIndex(refreshIndex2)
end

function UIChrWeaponPartsPowerUpPanelV4:BeginMinusLongPress(item)
  if item.itemData == nil or item.selectCount == 0 then
    return
  end
  item.selectCount = 0
  self.selectMaterial[self.itemId] = nil
  self:SetCurItem(item)
  self:UpdateSelectListData()
end

function UIChrWeaponPartsPowerUpPanelV4:BeginLongPress(item, num)
  if 0 < num and (self.targetLevel >= self.gunWeaponModData.maxLevel or item.itemData == nil) then
    return
  end
  local maxLevelExp = self:GetPartTotalExpByLevel(self.gunWeaponModData.maxLevel)
  local needExp = maxLevelExp - self.totalExp
  local itemOwn = NetCmdItemData:GetItemCountById(self.itemId)
  local itemExp = item.itemData.args[0]
  local needNum = math.ceil(needExp / itemExp)
  if self.selectMaterial[self.itemId] == nil then
    self.selectMaterial[self.itemId] = item
  end
  local targetAddNum = num
  local targetSelectCount = item.selectCount + targetAddNum
  if 0 < num then
    if targetAddNum < 0 then
      targetAddNum = 0
    end
    if num > needNum then
      targetAddNum = needNum
    end
  elseif targetSelectCount < 0 then
    targetSelectCount = 0
  end
  if itemOwn < targetSelectCount then
    item.selectCount = itemOwn
  else
    item.selectCount = targetSelectCount
  end
  self:SetCurItem(item)
  self:UpdateSelectListData()
end

function UIChrWeaponPartsPowerUpPanelV4:OnClickLock(isOn)
  if isOn == self.gunWeaponModData.IsLocked then
    return
  end
  NetCmdWeaponPartsData:ReqWeaponPartLockUnlock(self.gunWeaponModData.id, function(ret)
    if ret == ErrorCodeSuc then
      self:UpdateLockStatue()
    end
  end)
end

function UIChrWeaponPartsPowerUpPanelV4:OnClickLockCallback(gunWeaponModData, needRefreshListItem)
  if needRefreshListItem == nil then
    needRefreshListItem = false
  end
  if self.curItem ~= nil and needRefreshListItem then
    self.curItem.selectCount = 0
    self.curItem.UICommonItem:SetMaterialSelect(false)
    self.ui.mVirtualListExNew_WeaponPartsList:RefreshItemByIndex(self.curItem.index)
  end
  if gunWeaponModData.IsLocked then
    self.selectMaterial[gunWeaponModData.id] = nil
    self.curSelectCount = self.curSelectCount - 1
  end
  self:UpdateSelectListData()
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateLockStatue()
  self.lockItem:SetLock(self.gunWeaponModData.IsLocked)
end

function UIChrWeaponPartsPowerUpPanelV4:OpenLevelUpPanel()
  self.isLvUpBack = true
  local param = {
    title = TableData.GetHintById(250026)
  }
  UIManager.OpenUIByParam(UIDef.UIChrWeaponLevelUpDialog, param)
end

function UIChrWeaponPartsPowerUpPanelV4:OnSendPolarity()
  if not self.isCoinEnough then
    local item = TableData.listItemDatas:GetDataById(2)
    TipsPanelHelper.OpenUITipsPanel(item, GlobalData.cash, true)
    return
  end
  local costNum = CS.GunWeaponModProperty.DecomposeUpItemNum * self.curSelectIncreaseItemNum
  local itemOwn = NetCmdItemData:GetItemCountById(CS.GunWeaponModProperty.DecomposeUpItemId)
  local isItemEnough = costNum <= itemOwn
  local item = TableData.listItemDatas:GetDataById(CS.GunWeaponModProperty.DecomposeUpItemId)
  if not isItemEnough and self.curSelectIncreaseItemNum ~= 0 then
    TipsPanelHelper.OpenUITipsPanel(item, itemOwn, true)
    return
  end
  local reqWeaponPartPolarization = function()
    setactive(self.ui.mTrans_Mask, true)
    local itemList, partList = self:GetMaterialList()
    self:UpdatePolarityInteractable(false)
    self:SetCurItem()
    self:UpdateCompareDetail()
    NetCmdWeaponPartsData:ReqWeaponPartPolarization(self.gunWeaponModData.id, partList, itemList, self.curSelectIncreaseItemNum, function(ret)
      if ret == ErrorCodeSuc then
        self:SetInputActive(false)
        local start = self.curImgFillAmount
        local endLv = self.curBgImgFillAmount
        setactive(self.ui.mTrans_Full.gameObject, false)
        CS.ProgressBarAnimationHelper.PlayProgress(self.ui.mImg_ProgressBarBefore1, self.ui.mImg_ProgressBarAfter1, start, endLv, 0.5, nil, function()
          self.gunWeaponModData = NetCmdWeaponPartsData:GetWeaponModById(self.gunWeaponModData.id)
          if self.gunWeaponModData.PolarityId ~= 0 then
            self:OpenPolarityDialog()
          end
          setactive(self.ui.mTrans_Full.gameObject, true)
          self:SetInputActive(true)
        end)
      else
        setactive(self.ui.mTrans_Mask, false)
        self:UpdateSelectListData()
      end
    end)
  end
  if self.curSelectIncreaseItemNum ~= 0 then
    local content = TableData.GetHintById(310053)
    if self.curSelectIncreaseItemNum == self.gunWeaponModData.ModDecomposeUpTimes then
      content = TableData.GetHintById(310089)
    end
    content = string_format(content, item.name.str, costNum, self.curSelectIncreaseItemNum)
    local title = TableData.GetHintById(310061)
    MessageBoxPanel.ShowDoubleType(content, function()
      reqWeaponPartPolarization()
    end, nil, title)
  else
    reqWeaponPartPolarization()
  end
end

function UIChrWeaponPartsPowerUpPanelV4:OpenPolarityDialog()
  local callback = function()
    self.isPolarityBack = true
  end
  local param = {
    title = TableData.GetHintById(250034),
    callback = callback
  }
  UIManager.OpenUIByParam(UIDef.UIChrWeaponLevelUpDialog, param)
end

function UIChrWeaponPartsPowerUpPanelV4:OpenChrWeaponPartsPolaritySuccessDialog()
  local callback = function()
    self:SetWeaponPartData()
  end
  local title = ""
  local curType = 1
  if self.curSelectIncreaseItemNum == 0 then
    title = TableData.GetHintById(250034)
  else
    title = TableData.GetHintById(310062)
    curType = 3
  end
  local param = {
    title = title,
    gunWeaponModData = self.gunWeaponModData,
    curType = curType,
    callback = callback,
    isPolarityAgain = self.polarityId ~= 0
  }
  UIManager.OpenUIByParam(UIDef.UIChrWeaponPartsPolaritySuccessDialog, param)
  self.curSelectIncreaseItemNum = 0
end

function UIChrWeaponPartsPowerUpPanelV4:OpenItemDialog()
  local itemData = TableData.GetItemData(2)
  TipsPanelHelper.OpenUITipsPanel(itemData, 0, true)
end

function UIChrWeaponPartsPowerUpPanelV4:CheckCashEnough(addExp)
  local hasCash = GlobalData.cash
  self:CalculateCurCostCoin()
  hasCash = hasCash - self.curCostCoin
  local totalExp = self.gunWeaponModData.exp + addExp + self:GetPartTotalExpByLevel(self.gunWeaponModData.level)
  local costCoin = self.gunWeaponModData:GetChipCash(totalExp)
  return hasCash >= costCoin and hasCash ~= 0
end

function UIChrWeaponPartsPowerUpPanelV4:CheckCashEnoughPolarity(addExp)
  local hasCash = GlobalData.cash
  self:CalculateCurPolarityCostCoin()
  hasCash = hasCash - self.curCostCoin
  local totalExp = self.gunWeaponModData.PolarizationExp + addExp
  local costCoin = self.gunWeaponModData:GetPolarityChipCash(totalExp)
  return hasCash >= costCoin and hasCash ~= 0
end

function UIChrWeaponPartsPowerUpPanelV4:PopupNotEnoughHint(selectMaterialTableIsNil)
  if not selectMaterialTableIsNil then
    UIUtils.PopupPositiveHintMessage(40067)
  else
    local hasItem = NetCmdItemData:GetItemCountById(self.itemId) ~= 0
    local hasPart = self:CheckWeaponPartsListCanUse()
    if hasPart or hasItem then
      UIUtils.PopupPositiveHintMessage(102286)
    else
      UIUtils.PopupHintMessage(102238)
    end
  end
end

function UIChrWeaponPartsPowerUpPanelV4:CheckWeaponPartsListCanUse()
  local hasCanUsePart = false
  local curFilter = self.curAutoSelectRank
  for i = 0, self.weaponPartsList.Count - 1 do
    local gunWeaponModData = self.weaponPartsList[i]
    if gunWeaponModData:CanBeAutoSelect() and curFilter >= gunWeaponModData.rank then
      hasCanUsePart = true
      break
    end
  end
  return hasCanUsePart
end

function UIChrWeaponPartsPowerUpPanelV4:SetItemLongPressBtn(item, itemOrWeaponPartData)
  item:SetLongPressIntervalEvent(function(go, data, num)
    self:BeginLongPress(itemOrWeaponPartData, num)
  end)
  item:SetAccelerationCallback(function()
    self.AccelerationCount = self.AccelerationCount + 1
    if self.AccelerationCount < 1 then
      return
    end
    item:SetIntervalCount(0)
    item:SetLongPressValue(5 * self.AccelerationCount)
  end)
  item:SetLongPressEvent(function()
    self:InitLongPress(item)
  end, function()
    self:InitLongPress(item)
  end)
  item:SetMinusLongPressIntervalEvent(function(go, data, num)
    self:BeginLongPress(itemOrWeaponPartData, num * -1)
  end)
  item:SetMinusAccelerationCallback(function()
    self.AccelerationCount = self.AccelerationCount + 1
    if self.AccelerationCount < 1 then
      return
    end
    item:SetMinusIntervalCount(0)
    item:SetMinusLongPressValue(5 * self.AccelerationCount)
  end)
  item:SetMinusLongPressEvent(function()
    self:InitMinusLongPress(item)
  end, function()
    self:InitMinusLongPress(item)
  end)
end

function UIChrWeaponPartsPowerUpPanelV4:InitLongPress(item)
  item:SetAcceleration(5)
  item:SetLongPressValue(5)
  item:SetIntervalCount(3)
  self.AccelerationCount = 0
end

function UIChrWeaponPartsPowerUpPanelV4:InitMinusLongPress(item)
  item:SetMinusAcceleration(5)
  item:SetMinusLongPressValue(5)
  item:SetMinusIntervalCount(3)
  self.AccelerationCount = 0
end

function UIChrWeaponPartsPowerUpPanelV4:OnBtnIncreaseDetailsClick()
  local param = {
    gunWeaponModData = self.gunWeaponModData
  }
  UIManager.OpenUIByParam(UIDef.UIChrWeaponPartsIncreaseDetailDialog, param)
end

function UIChrWeaponPartsPowerUpPanelV4:OnBtnIncreaseClick()
  if self.curSelectIncreaseItemNum == 0 then
    self:OnBtnIncreaseAddClick()
  else
    self.curSelectIncreaseItemNum = 0
    self:UpdateCostItem()
    self.ui.mAnimator_Increase:SetBool("Start", false)
    local hint = TableData.GetHintById(310087)
    CS.PopupMessageManager.PopupPositiveString(hint)
    local btnHint = TableData.GetHintById(310073)
    self.ui.mText_Increase.text = btnHint
  end
end

function UIChrWeaponPartsPowerUpPanelV4:OnBtnIncreaseAddClick()
  local callback = function(num)
    local hint = TableData.GetHintById(310077)
    hint = string_format(hint, num)
    CS.PopupMessageManager.PopupPositiveString(hint)
    self.curSelectIncreaseItemNum = num
    self:UpdateCostItem()
  end
  local param = {
    gunWeaponModData = self.gunWeaponModData,
    callback = callback,
    num = self.curSelectIncreaseItemNum
  }
  UIManager.OpenUIByParam(UIDef.UIChrWeaponPartsIncreaseDoubleCheckDialog, param)
end

function UIChrWeaponPartsPowerUpPanelV4:UpdateCostItem()
  local setTextColorByItemId = function(text, itemId, costNum)
    local itemOwn = NetCmdItemData:GetItemCountById(itemId)
    local maxValue = self.gunWeaponModData.ModDecomposeUpTimes
    local isItemEnough = costNum <= itemOwn
    if not isItemEnough then
      text.text = "<color=#FF5E41>" .. costNum .. "</color>/" .. maxValue
    else
      text.text = costNum .. "/" .. maxValue
    end
    return isItemEnough
  end
  setactive(self.ui.mTrans_AdditionTab4.gameObject, self.curSelectIncreaseItemNum > 0)
  setactive(self.ui.mBtn_Add.gameObject, self.curSelectIncreaseItemNum > 0)
  setactive(self.ui.mBtn_BtnPolarity1.transform.parent.gameObject, self.curSelectIncreaseItemNum == 0)
  setactive(self.ui.mBtn_BtnIncrease.transform.parent.gameObject, self.curSelectIncreaseItemNum > 0)
  self.ui.mAnimator_Increase:SetBool("Start", self.curSelectIncreaseItemNum > 0)
  local btnHint
  if self.curSelectIncreaseItemNum == 0 then
    btnHint = TableData.GetHintById(310073)
  else
    btnHint = TableData.GetHintById(310074)
  end
  self.ui.mText_Increase.text = btnHint
  local hint = TableData.GetHintById(310059)
  if self.curSelectIncreaseItemNum == self.gunWeaponModData.ModDecomposeUpTimes then
    hint = TableData.GetHintById(310088)
    self.ui.mImg_Tab4Bg.color = self.IncreaseBgColorTable.Max
  else
    self.ui.mImg_Tab4Bg.color = self.IncreaseBgColorTable.Default
  end
  self.ui.mText_Tab4.text = string_format(hint, self.curSelectIncreaseItemNum)
  local costNum = CS.GunWeaponModProperty.DecomposeUpItemNum * self.curSelectIncreaseItemNum
  setTextColorByItemId(self.ui.mText_IncreaseNum, CS.GunWeaponModProperty.DecomposeUpItemId, costNum)
  self:UpdateSelectListDataPolarity()
end

function UIChrWeaponPartsPowerUpPanelV4:CheckAndActiveCalibrationBtn()
  setactive(self.ui.mBtn_Calibration.gameObject, self.gunWeaponModData:CanCalibration())
  setactive(self.ui.mBtn_Calibration1.gameObject, self.gunWeaponModData:CanCalibration())
end

function UIChrWeaponPartsPowerUpPanelV4:ReLoginSuccess()
  setactive(self.ui.mTrans_Mask, false)
  self:UpdateSelectListData()
end

function UIChrWeaponPartsPowerUpPanelV4:AddListener()
  function self.reLoginSuccess(message)
    self:ReLoginSuccess(message.Sender)
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.ReLoginSuccess, self.reLoginSuccess)
end

function UIChrWeaponPartsPowerUpPanelV4:RemoveListener()
  if self.reLoginSuccess ~= nil then
    MessageSys:RemoveListener(CS.GF2.Message.UIEvent.ReLoginSuccess, self.reLoginSuccess)
    self.reLoginSuccess = nil
  end
end

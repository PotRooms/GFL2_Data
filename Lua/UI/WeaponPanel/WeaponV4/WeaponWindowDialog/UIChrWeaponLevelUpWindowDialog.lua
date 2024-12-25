require("UI.WeaponPanel.WeaponV4.Item.ChrWeaponLvUpAttributeDetailItemV4")
require("UI.WeaponPanel.WeaponV4.Item.ChrWeaponLevelUpAimLevelItem")
UIChrWeaponLevelUpWindowDialog = class("UIChrWeaponLevelUpWindowDialog", UIBasePanel)
UIChrWeaponLevelUpWindowDialog.__index = UIChrWeaponLevelUpWindowDialog

function UIChrWeaponLevelUpWindowDialog:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIChrWeaponLevelUpWindowDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.mUIRoot = root
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.slotTable = {}
  self.gunCmdData = nil
  self.weaponCmdData = nil
  self.lockItem = nil
  self.weaponReplaceList = nil
  self.curCostItemData = nil
  self.targetLevel = 0
  self.haveCount = 0
  self.costCount = 0
  self.targetIndex = 0
  self.lvUpAttributeItems = {}
  self.levelUpBtnRedPoint = nil
  self.isFirstUpdateAction = false
  self.hasItemCompose = false
  self.moveToCenterEndCallback = nil
  self.uiChrWeaponPanelV4ExpTable = nil
end

function UIChrWeaponLevelUpWindowDialog:OnInit(root, param)
  self.weaponCmdData = param[1]
  self.gunCmdData = param[2]
  self.uiChrWeaponPanelV4ExpTable = param[3]
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIChrWeaponLevelUpWindowDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Close1.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIChrWeaponLevelUpWindowDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpLevelUpConsume.gameObject).onClick = function()
    self:OnClickLevelUpConsume()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnLevelUp.gameObject).onClick = function()
    self:OnClickLevelUp()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_ImgArrowA.gameObject).onClick = function()
    self:OnClickNextLevel(false)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_ImgArrowB.gameObject).onClick = function()
    self:OnClickNextLevel(true)
  end
  local levelUpBtnRedPoint = self.ui.mBtn_BtnLevelUp.transform:Find("Root/Trans_RedPoint").gameObject:GetComponent(typeof(CS.UICommonContainer))
  self.levelUpBtnRedPoint = levelUpBtnRedPoint.transform
  self:UpdateWeaponLevelUpItem()
end

function UIChrWeaponLevelUpWindowDialog:OnShowStart()
  self.ui.mScrollRectWrap_List.verticalNormalizedPosition = 1
  self:InitScrollRectWrap()
  self:UpdateWeaponLevelUpItem()
  self:SetWeaponData()
end

function UIChrWeaponLevelUpWindowDialog:OnRecover()
end

function UIChrWeaponLevelUpWindowDialog:OnBackFrom()
  self:UpdateAction(0, self.targetRefreshIndex)
end

function UIChrWeaponLevelUpWindowDialog:OnTop()
  self:UpdateAction(0, self.targetRefreshIndex)
  if self.hasItemCompose then
    self:FirstUpdateAction()
    self.hasItemCompose = false
  end
end

function UIChrWeaponLevelUpWindowDialog:OnShowFinish()
  setactive(self.uiChrWeaponPanelV4ExpTable.mTrans_ExpBar.gameObject, true)
end

function UIChrWeaponLevelUpWindowDialog:OnHide()
end

function UIChrWeaponLevelUpWindowDialog:OnHideFinish()
end

function UIChrWeaponLevelUpWindowDialog:OnClose()
  self.ui.mScrollRectWrap_List:OnIndexChanged("-", self.onIndexChangedCallback)
  self.targetLevel = 0
  self.haveCount = 0
  self.costCount = 0
  self.targetRefreshIndex = 0
  setactive(self.uiChrWeaponPanelV4ExpTable.mTrans_ExpBar.gameObject, false)
end

function UIChrWeaponLevelUpWindowDialog:OnRelease()
  self.super.OnRelease(self)
end

function UIChrWeaponLevelUpWindowDialog:InitScrollRectWrap()
  self.ui.mScrollRectWrap_List:Init()
  
  function self.onIndexChangedCallback(index)
    self:OnIndexChanged(index)
  end
  
  self.ui.mScrollRectWrap_List:OnIndexChanged("+", self.onIndexChangedCallback)
end

function UIChrWeaponLevelUpWindowDialog:OnIndexChanged(targetIndex)
  targetIndex = targetIndex + 1
  if targetIndex < 1 or targetIndex > #self.slotTable then
    return
  end
  local focusedSlot = self:GetFirstFocusedTargetLevelSlot()
  local preIndex = -1
  if focusedSlot then
    preIndex = focusedSlot:GetIndex()
    if targetIndex == preIndex then
      local targetSlot = self.slotTable[targetIndex]
      targetSlot:Focus()
      return
    end
    focusedSlot:LoseFocus()
  end
  local targetSlot = self.slotTable[targetIndex]
  if targetSlot then
    targetSlot:Focus()
    self:UpdateAction(preIndex, targetSlot:GetIndex())
  end
  self.targetIndex = targetIndex
end

function UIChrWeaponLevelUpWindowDialog:SetWeaponData(isFirst)
  if isFirst == nil then
    isFirst = true
  end
  setactive(self.ui.mTrans_Right.gameObject, true)
  local costItemStcId = self.weaponCmdData:GetLevelUpCostItemStcId(self.weaponCmdData.Level + 1)
  self.curCostItemData = TableData.listItemDatas:GetDataById(costItemStcId)
  if isFirst then
    self:UpdateAttribute()
    self:FirstResetAttribute()
    self:FirstUpdateAction()
  end
  self:UpdateCurExpProgress()
  self.curImgFillAmount = self.uiChrWeaponPanelV4ExpTable.mImg_ProgressBarBefore.fillAmount
  self.curBgImgFillAmount = self.uiChrWeaponPanelV4ExpTable.mImg_ProgressBarAfter.fillAmount
  self.ui.mBtn_BtnLevelUp.enabled = true
end

function UIChrWeaponLevelUpWindowDialog:UpdateWeaponLevelUpItem()
  local weaponLevel = self.weaponCmdData.Level
  local maxLevel = self.weaponCmdData.WeaponLevelMax
  if weaponLevel == self.weaponCmdData.DefaultMaxLevel then
    return
  end
  local tmpParent = self.ui.mScrollListChild_Content1.transform
  for i = 0, tmpParent.childCount - 1 do
    setactive(tmpParent:GetChild(i).gameObject, false)
  end
  local tmpObj
  self.slotTable = {}
  local index = 0
  for i = weaponLevel + 1, maxLevel do
    index = index + 1
    local chrWeaponLevelUpAimLevelItem = ChrWeaponLevelUpAimLevelItem.New()
    if index <= tmpParent.childCount then
      tmpObj = tmpParent:GetChild(index - 1)
      setactive(tmpObj.gameObject, true)
    else
      tmpObj = nil
    end
    chrWeaponLevelUpAimLevelItem:InitCtrl(tmpParent.gameObject, tmpObj)
    chrWeaponLevelUpAimLevelItem:SetData(index, i)
    table.insert(self.slotTable, chrWeaponLevelUpAimLevelItem)
  end
  CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(tmpParent)
  self.ui.mScrollRectWrap_List.verticalNormalizedPosition = 1
end

function UIChrWeaponLevelUpWindowDialog:UpdateAttribute()
  local attrList = {}
  local expandList = TableData.GetPropertyExpandList()
  for i = 0, expandList.Count - 1 do
    local lanData = expandList[i]
    local value = self.weaponCmdData:GetPropertyByLevelAndSysNameWithPercent(lanData.sys_name, self.weaponCmdData.Level, self.weaponCmdData.BreakTimes, false)
    local defaultMaxValue = self.weaponCmdData:GetPropertyByLevelAndSysNameWithPercent(lanData.sys_name, self.weaponCmdData.DefaultMaxLevel, 0, false)
    if 0 < value then
      local attr = {}
      attr.propData = lanData
      attr.value = value
      attr.defaultMaxValue = defaultMaxValue
      table.insert(attrList, attr)
    end
  end
  table.sort(attrList, function(a, b)
    return a.propData.order < b.propData.order
  end)
  local tmpAttrParent = self.ui.mScrollListChild_Content.transform
  setactive(tmpAttrParent.gameObject, false)
  setactive(tmpAttrParent.gameObject, true)
  for i = 0, tmpAttrParent.childCount - 1 do
    setactive(tmpAttrParent:GetChild(i).gameObject, false)
  end
  self.lvUpAttributeItems = {}
  for i = 1, #attrList do
    local item
    item = ChrWeaponLvUpAttributeDetailItemV4.New()
    if i <= tmpAttrParent.childCount then
      item:InitCtrl(tmpAttrParent.gameObject, tmpAttrParent:GetChild(i - 1))
    else
      item:InitCtrl(tmpAttrParent.gameObject)
    end
    if i <= #attrList then
      item:SetData(attrList[i].propData, attrList[i].value, attrList[i].defaultMaxValue)
    else
      item:SetData(nil)
    end
    table.insert(self.lvUpAttributeItems, item)
  end
end

function UIChrWeaponLevelUpWindowDialog:GetFirstFocusedTargetLevelSlot()
  for i, slot in ipairs(self.slotTable) do
    if slot:IsFocused() then
      return slot
    end
  end
  return nil
end

function UIChrWeaponLevelUpWindowDialog:FirstUpdateAction()
  local weaponLevel = self.weaponCmdData.Level + 1
  local maxLevel = math.min(self.weaponCmdData.MaxLevel, self.weaponCmdData.WeaponLevelMax)
  local costItemStcId = self.weaponCmdData:GetLevelUpCostItemStcId(weaponLevel)
  local haveCount = NetCmdItemData:GetItemCount(costItemStcId)
  local costCount
  local index = 0
  local curIndex = 0
  for i = weaponLevel, maxLevel do
    costCount = self.weaponCmdData:GetTargetLevelCostItemCount(i)
    if haveCount >= costCount then
      curIndex = index
    end
    index = index + 1
  end
  LayoutRebuilder.ForceRebuildLayoutImmediate(self.ui.mScrollRectWrap_List.content.transform)
  self.ui.mScrollRectWrap_List:MoveToCenter(curIndex, false)
  self.isFirstUpdateAction = false
  if self.moveToCenterEndCallback ~= nil then
    self.moveToCenterEndCallback()
    self.moveToCenterEndCallback = nil
  end
  self:UpdateAction(0, curIndex + 1)
  self:RefreshLevelItem(self.weaponCmdData.Level + curIndex + 1)
  self.targetIndex = curIndex + 1
end

function UIChrWeaponLevelUpWindowDialog:UpdateAction(preIndex, curIndex)
  local targetIndex = self.weaponCmdData.Level + curIndex
  if targetIndex >= self.weaponCmdData.DefaultMaxLevel then
    targetIndex = self.weaponCmdData.DefaultMaxLevel
  end
  self:RefreshItemCount(targetIndex)
  self:RefreshBtnState(targetIndex)
  self:RefreshAttribute(targetIndex)
  self:RefreshLevelProgress(targetIndex)
  self:RefreshArrow(targetIndex)
  self.targetRefreshIndex = curIndex
end

function UIChrWeaponLevelUpWindowDialog:RefreshBtnState(targetLv)
  local canLevelUp = targetLv <= self.weaponCmdData.MaxLevel
  if self.weaponCmdData.IsReachMaxLv then
    setactive(self.ui.mTrans_AimLevelWindow.gameObject, false)
    setactive(self.ui.mTrans_MaxLevel.gameObject, true)
    setactive(self.ui.mTrans_Mismatch.gameObject, false)
    setactive(self.ui.mBtn_BtnLevelUp.transform.parent.gameObject, false)
  else
    setactive(self.ui.mTrans_AimLevelWindow.gameObject, true)
    setactive(self.ui.mTrans_MaxLevel.gameObject, false)
    setactive(self.ui.mTrans_Mismatch.gameObject, not canLevelUp)
    setactive(self.ui.mBtn_BtnLevelUp.transform.parent.gameObject, canLevelUp)
  end
end

function UIChrWeaponLevelUpWindowDialog:RefreshItemCount(targetLevel)
  local targetMaxLevel = self.weaponCmdData.DefaultMaxLevel
  local costItemStcId = self.curCostItemData.Id
  local haveCount = NetCmdItemData:GetItemCount(costItemStcId)
  local costCount = self.weaponCmdData:GetTargetLevelCostItemCount(targetLevel, false)
  self.ui.mImg_Item.sprite = IconUtils.GetItemIconSprite(costItemStcId)
  local haveDigit = CS.LuaUIUtils.GetMaxNumberText(haveCount)
  local costDigit = CS.LuaUIUtils.GetMaxNumberText(costCount)
  if haveCount < costCount then
    self.ui.mText_Num.text = "<color=#FF5E41>" .. haveDigit .. "</color>/" .. costDigit
  else
    self.ui.mText_Num.text = haveDigit .. "/" .. costDigit
  end
  self.targetLevel = targetLevel
  self.haveCount = haveCount
  self.costCount = costCount
  setactive(self.levelUpBtnRedPoint.gameObject, false)
end

function UIChrWeaponLevelUpWindowDialog:FirstResetAttribute()
  self.isFirstUpdateAction = true
  local attrs = self.lvUpAttributeItems
  for i = 1, #attrs do
    local attributeItem = attrs[i]
    attributeItem:ResetAfterFillAmount()
  end
end

function UIChrWeaponLevelUpWindowDialog:RefreshAttribute(targetLevel, recordLv, needTween)
  if recordLv == nil then
    recordLv = self.weaponCmdData.Level
  end
  local attrs = self.lvUpAttributeItems
  for i = 1, #attrs do
    local attributeItem = attrs[i]
    local sysName = attributeItem.mLanguagePropertyData.sys_name
    local curValue = self.weaponCmdData:GetWeaponTargetPropertyValueByName(sysName, recordLv)
    local targetValue = self.weaponCmdData:GetWeaponTargetPropertyValueByName(sysName, targetLevel)
    if curValue ~= targetValue then
      if self.isFirstUpdateAction then
        attributeItem:SetPreValueAnim(curValue, targetValue)
      else
        attributeItem:ShowDiff(attributeItem.mLanguagePropertyData, curValue, targetValue, needTween)
      end
    end
    attributeItem:ShowOrHideDiff(curValue ~= targetValue)
  end
end

function UIChrWeaponLevelUpWindowDialog:PlayLevelUpAnimator(targetLevel, recordLv)
  if recordLv == nil then
    recordLv = self.weaponCmdData.Level
  end
  local attrs = self.lvUpAttributeItems
  for i = 1, #attrs do
    local attributeItem = attrs[i]
    local sysName = attributeItem.mLanguagePropertyData.sys_name
    local curValue = self.weaponCmdData:GetWeaponTargetPropertyValueByName(sysName, recordLv)
    local targetValue = self.weaponCmdData:GetWeaponTargetPropertyValueByName(sysName, targetLevel)
    if curValue ~= targetValue then
      attributeItem:PlayNumAddTween(curValue, targetValue)
    end
    attributeItem:ShowOrHideDiff(curValue ~= targetValue)
  end
  TimerSys:DelayCall(0.8, function()
    UIManager.CloseUI(UIDef.UIChrWeaponLevelUpWindowDialog)
    self:OpenLevelUpPanel()
  end)
end

function UIChrWeaponLevelUpWindowDialog:RefreshLevelProgress(targetLevel)
  local costCount = self.weaponCmdData:GetTargetLevelCostItemCount(targetLevel)
  local addExp = costCount * self.curCostItemData.args[0]
  local curExp = self.weaponCmdData:GetWeaponCurExp()
  local targetExp = curExp + addExp
  local tableDataTargetLevelExp = self.weaponCmdData:GetWeaponNeedExpByLv(targetLevel)
  local offset = targetExp - tableDataTargetLevelExp
  if targetLevel >= self.weaponCmdData.MaxLevel then
    self.curBgImgFillAmount = 1
  else
    local nextTargetLevelExp = self.weaponCmdData:GetWeaponNeedExpByLvNotTotal(targetLevel + 1)
    local fillAmount
    if offset == 0 then
      fillAmount = 1
    else
      fillAmount = offset / nextTargetLevelExp
    end
    self.curBgImgFillAmount = fillAmount
  end
end

function UIChrWeaponLevelUpWindowDialog:RefreshLevelItem(targetLevel)
  for i, slot in ipairs(self.slotTable) do
    slot:SetCanSelect(i <= targetLevel)
  end
end

function UIChrWeaponLevelUpWindowDialog:RefreshArrow(targetLevel)
  if #self.slotTable == 0 then
    return
  end
  self.ui.mAnimator_ImgArrowA:SetBool("CanvasGroup", self.slotTable[1].level ~= targetLevel)
  self.ui.mAnimator_ImgArrowB:SetBool("CanvasGroup", self.slotTable[#self.slotTable].level ~= targetLevel)
end

function UIChrWeaponLevelUpWindowDialog:UpdateCurExpProgress()
  if self.weaponCmdData.Level == self.weaponCmdData.DefaultMaxLevel then
    setactive(self.uiChrWeaponPanelV4ExpTable.mTrans_ExpBar.gameObject, false)
    return
  end
  setactive(self.uiChrWeaponPanelV4ExpTable.mTrans_ExpBar.gameObject, true)
  local nextLevelNeedExp = self.weaponCmdData:GetWeaponNeedExpByLvNotTotal(self.weaponCmdData.Level + 1)
  local curExp = self.weaponCmdData.Exp
  local fillAmount = curExp / nextLevelNeedExp
  self.uiChrWeaponPanelV4ExpTable.mImg_ProgressBarBefore.fillAmount = fillAmount
  self.uiChrWeaponPanelV4ExpTable.mImg_ProgressBarAfter.fillAmount = fillAmount
end

function UIChrWeaponLevelUpWindowDialog:OnClickLevelUpConsume()
  TipsPanelHelper.OpenUITipsPanel(self.curCostItemData, 0, true)
end

function UIChrWeaponLevelUpWindowDialog:OnClickLevelUp()
  if self.haveCount < self.costCount then
    self:OnClickLevelUpConsume()
  else
    self.recordLv = self.weaponCmdData.Level
    self:SetInputActive(false)
    self.ui.mBtn_BtnLevelUp.enabled = false
    NetCmdWeaponData:SendGunWeaponLvUp(self.weaponCmdData.id, self.targetLevel, function(ret)
      if ret == ErrorCodeSuc then
        UIWeaponGlobal.SetIsReadyToStartTutorial(false)
        local start = self.recordLv + self.curImgFillAmount
        local endLv = self.targetLevel + self.curBgImgFillAmount
        self:PlayLevelUpAnimator(self.targetLevel, self.recordLv)
      else
        self:SetInputActive(true)
      end
    end)
  end
end

function UIChrWeaponLevelUpWindowDialog:OpenLevelUpPanel()
  local levelUpDialogCallback = function()
  end
  local beforeCloseCallback = function()
    UIWeaponGlobal.SetIsReadyToStartTutorial(true)
    self:SetInputActive(true)
  end
  local hideCallback = function()
    UIWeaponGlobal.SetIsReadyToStartTutorial(true)
    self:SetInputActive(true)
  end
  CS.PopupMessageManager.PopupPositiveString(TableData.GetHintById(220020))
end

function UIChrWeaponLevelUpWindowDialog:OnClickNextLevel(isNext)
  local targetIndex
  if isNext then
    targetIndex = self.targetIndex + 1
  else
    targetIndex = self.targetIndex - 1
  end
  local weaponLevel = self.weaponCmdData.Level
  local maxLevel = self.weaponCmdData.WeaponLevelMax
  if targetIndex > maxLevel - weaponLevel then
    return
  end
  if targetIndex < 1 then
    return
  end
  self.targetIndex = targetIndex
  self.ui.mScrollRectWrap_List:MoveToCenter(self.targetIndex - 1, true, 0.3)
end

function UIChrWeaponLevelUpWindowDialog:SetInputActive(boolean)
end

function UIChrWeaponLevelUpWindowDialog:OnItemCompose(message)
  local itemData = message.Sender
  self.hasItemCompose = true
end

function UIChrWeaponLevelUpWindowDialog:AddListener()
  function self.onItemCompose(message)
    self:OnItemCompose(message)
  end
  
  MessageSys:AddListener(CS.GF2.Message.CommonEvent.ItemCompose, self.onItemCompose)
end

function UIChrWeaponLevelUpWindowDialog:RemoveListener()
  MessageSys:RemoveListener(CS.GF2.Message.CommonEvent.ItemCompose, self.onItemCompose)
end

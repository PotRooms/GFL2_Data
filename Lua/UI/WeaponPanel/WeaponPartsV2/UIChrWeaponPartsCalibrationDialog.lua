require("UI.WeaponPanel.Item.ChrWeaponPartsCalibrationItem")
UIChrWeaponPartsCalibrationDialog = class("UIChrWeaponPartsCalibrationDialog", UIBasePanel)
UIChrWeaponPartsCalibrationDialog.__index = UIChrWeaponPartsCalibrationDialog

function UIChrWeaponPartsCalibrationDialog:ctor(csPanel)
  UIChrWeaponPartsCalibrationDialog.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIChrWeaponPartsCalibrationDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.gunWeaponModData = nil
  self.curCalibrationTable = {}
  self.isItemEnough = false
  self.isCoinEnough = false
  self.chrWeaponPartsCalibrationItemTable = {}
  local hint = TableData.GetHintById(310069)
  self.ui.mText_TextTips.text = string_format(hint, math.floor(CS.GunWeaponModProperty.CalibrationMin / 10), math.floor(CS.GunWeaponModProperty.CalibrationMax / 10))
end

function UIChrWeaponPartsCalibrationDialog:OnInit(root, param)
  self.gunWeaponModData = param.gunWeaponModData
  self.callback = param.callback
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIChrWeaponPartsCalibrationDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnCancel.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIChrWeaponPartsCalibrationDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpClose.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIChrWeaponPartsCalibrationDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnConfirm.gameObject).onClick = function()
    self:OnBtnConfirmClick()
  end
end

function UIChrWeaponPartsCalibrationDialog:OnShowStart()
  self:SetData()
end

function UIChrWeaponPartsCalibrationDialog:OnRecover()
end

function UIChrWeaponPartsCalibrationDialog:OnBackFrom()
end

function UIChrWeaponPartsCalibrationDialog:OnTop()
end

function UIChrWeaponPartsCalibrationDialog:OnShowFinish()
end

function UIChrWeaponPartsCalibrationDialog:OnHide()
end

function UIChrWeaponPartsCalibrationDialog:OnHideFinish()
end

function UIChrWeaponPartsCalibrationDialog:OnClose()
end

function UIChrWeaponPartsCalibrationDialog:OnRelease()
  self.super.OnRelease(self)
end

function UIChrWeaponPartsCalibrationDialog:SetData()
  setactive(self.ui.mTrans_Num.gameObject, CS.GunWeaponModProperty.ModCalibrationPropertyNumSwitch)
  local parent = self.ui.mScrollListChild_Content
  for i = 0, parent.transform.childCount - 1 do
    local child = parent.transform:GetChild(i)
    setactive(child.gameObject, false)
  end
  local gunWeaponModPropertyList = self.gunWeaponModData.GunWeaponModPropertyList
  self.curCalibrationTable = {}
  self.chrWeaponPartsCalibrationItemTable = {}
  for i = 0, gunWeaponModPropertyList.Count - 1 do
    local item
    item = ChrWeaponPartsCalibrationItem.New()
    if i < parent.transform.childCount then
      item:InitCtrl(parent, parent.transform:GetChild(i))
    else
      item:InitCtrl(parent, nil)
    end
    setactive(item.mUIRoot.gameObject, true)
    item:SetData(gunWeaponModPropertyList[i], function(index, isOn)
      self:OnItemSelected(index, isOn)
    end)
    self.chrWeaponPartsCalibrationItemTable[i + 1] = item
  end
  IconUtils.GetItemIconSpriteAsync(CS.GunWeaponModProperty.CalibrationItemId, self.ui.mImg_Icon)
  IconUtils.GetItemIconSpriteAsync(CS.GunWeaponModProperty.CalibrationCoinId, self.ui.mImg_Icon1)
end

function UIChrWeaponPartsCalibrationDialog:SetCostData()
  local curNum = 0
  for i = 0, #self.curCalibrationTable + 1 do
    if self.curCalibrationTable[i] == 1 then
      curNum = curNum + 1
    end
  end
  local setTextColorByItemId = function(text, itemId, costNum)
    local itemOwn = NetCmdItemData:GetItemCountById(itemId)
    local isItemEnough = costNum <= itemOwn
    if not isItemEnough then
      text.text = "<color=#FF5E41>" .. costNum .. "</color>"
    else
      text.text = costNum
    end
    return isItemEnough
  end
  setactive(self.ui.mTrans_GoldConsume.gameObject, 0 < curNum)
  local costNum = CS.GunWeaponModProperty.CalibrationItemNum * curNum
  self.isItemEnough = setTextColorByItemId(self.ui.mText_CostNum, CS.GunWeaponModProperty.CalibrationItemId, costNum)
  local costNum1 = CS.GunWeaponModProperty.CalibrationCoinNum * curNum
  self.isCoinEnough = setTextColorByItemId(self.ui.mText_CostNum1, CS.GunWeaponModProperty.CalibrationCoinId, costNum1)
end

function UIChrWeaponPartsCalibrationDialog:OnBtnConfirmClick()
  if not self.isItemEnough then
    local itemData = TableData.GetItemData(CS.GunWeaponModProperty.CalibrationItemId)
    local itemOwn = NetCmdItemData:GetItemCountById(CS.GunWeaponModProperty.CalibrationItemId)
    TipsPanelHelper.OpenUITipsPanel(itemData, itemOwn, true)
    return
  end
  if not self.isCoinEnough then
    local coinData = TableData.GetItemData(CS.GunWeaponModProperty.CalibrationCoinId)
    local itemOwn = NetCmdItemData:GetItemCountById(CS.GunWeaponModProperty.CalibrationCoinId)
    TipsPanelHelper.OpenUITipsPanel(coinData, itemOwn, true)
    return
  end
  local calibrationIdx = {}
  for i = 0, #self.curCalibrationTable + 1 do
    if self.curCalibrationTable[i] == 1 then
      table.insert(calibrationIdx, i)
    end
  end
  if #calibrationIdx == 0 then
    local hint = TableData.GetHintById(310092)
    CS.PopupMessageManager.PopupString(hint)
    return
  end
  NetCmdWeaponPartsData:ReqGunWeaponModCalibration(self.gunWeaponModData.id, calibrationIdx, function(ret)
    if ret == ErrorCodeSuc then
      self.gunWeaponModData = NetCmdWeaponPartsData:GetWeaponModById(self.gunWeaponModData.id)
      self:OpenChrWeaponPartsCalibrationSuccessDialog()
      if self.callback ~= nil then
        self.callback()
      end
    end
  end)
end

function UIChrWeaponPartsCalibrationDialog:OnItemSelected(index, isOn)
  if isOn then
    self.curCalibrationTable[index] = 1
  else
    self.curCalibrationTable[index] = 0
  end
  self:SetCostData()
end

function UIChrWeaponPartsCalibrationDialog:OpenChrWeaponPartsCalibrationSuccessDialog()
  local callback = function()
    self:SetCostData()
    for i = 1, #self.chrWeaponPartsCalibrationItemTable do
      local item = self.chrWeaponPartsCalibrationItemTable[i]
      local gunWeaponModPropertyList = self.gunWeaponModData.GunWeaponModPropertyList
      item:ResetData(gunWeaponModPropertyList[i - 1])
      if item:IsCalibrationMaxNum() or item.gunWeaponModProperty.IsMaxCalibrationValue then
        self:OnItemSelected(item.gunWeaponModProperty.AffixIndex, false)
      end
    end
    if not self.gunWeaponModData:CanCalibration() then
      UIManager.CloseUI(UIDef.UIChrWeaponPartsCalibrationDialog)
    end
  end
  local param = {
    title = TableData.GetHintById(310072),
    gunWeaponModData = self.gunWeaponModData,
    callback = callback,
    curType = 2
  }
  UIManager.OpenUIByParam(UIDef.UIChrWeaponPartsPolaritySuccessDialog, param)
end

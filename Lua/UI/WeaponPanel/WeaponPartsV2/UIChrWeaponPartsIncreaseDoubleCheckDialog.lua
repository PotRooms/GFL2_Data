require("UI.WeaponPanel.Item.ChrWeaponPartsIncreaseDetailItem")
UIChrWeaponPartsIncreaseDoubleCheckDialog = class("UIChrWeaponPartsIncreaseDoubleCheckDialog", UIBasePanel)
UIChrWeaponPartsIncreaseDoubleCheckDialog.__index = UIChrWeaponPartsIncreaseDoubleCheckDialog

function UIChrWeaponPartsIncreaseDoubleCheckDialog:ctor(csPanel)
  UIChrWeaponPartsIncreaseDoubleCheckDialog.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.ui.mSlider_Slider.onValueChanged:AddListener(function(value)
    self.curSelectIncreaseItemNum = math.floor(value)
    self:UpdateNumAndData()
  end)
  self.itemData = TableData.GetItemData(CS.GunWeaponModProperty.DecomposeUpItemId)
  self.curSelectIncreaseItemNum = 1
  self.curMinNum = 1
  self.curMaxNum = 1
  self.itemOwn = 0
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:OnInit(root, param)
  self.gunWeaponModData = param.gunWeaponModData
  self.callback = param.callback
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIChrWeaponPartsIncreaseDoubleCheckDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpClose.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIChrWeaponPartsIncreaseDoubleCheckDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnCancel.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIChrWeaponPartsIncreaseDoubleCheckDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_IncreaseDetail.gameObject).onClick = function()
    local param1 = {
      gunWeaponModData = self.gunWeaponModData
    }
    UIManager.OpenUIByParam(UIDef.UIChrWeaponPartsIncreaseDetailDialog, param1)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpBtnReduce.gameObject).onClick = function()
    self:ChangeSelectNum(-1)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpBtnIncrease.gameObject).onClick = function()
    self:ChangeSelectNum(1)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnConfirm.gameObject).onClick = function()
    self:OnBtnConfirmClick()
  end
  if param.num == nil or param.num == 0 then
    self.curSelectIncreaseItemNum = 1
  else
    self.curSelectIncreaseItemNum = param.num
  end
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:OnShowStart()
  self:SetData()
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:OnRecover()
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:OnBackFrom()
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:OnTop()
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:OnShowFinish()
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:OnHide()
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:OnHideFinish()
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:OnClose()
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:OnRelease()
  self.super.OnRelease(self)
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:SetData()
  self.itemOwn = NetCmdItemData:GetItemCountById(CS.GunWeaponModProperty.DecomposeUpItemId)
  self.curMinNum = 1
  local curMaxNum = self.gunWeaponModData.ModDecomposeUpTimes
  local itemMinNum = math.min(curMaxNum, self.itemOwn)
  if itemMinNum <= 0 then
    itemMinNum = 1
  end
  self.curMaxNum = math.floor(itemMinNum)
  self.ui.mText_MinNum.text = self.curMinNum
  self.ui.mText_MaxNum.text = self.curMaxNum
  self.ui.mSlider_Slider.minValue = self.curMinNum
  if self.curMinNum == 1 and self.curMaxNum == 1 then
    self.ui.mSlider_Slider.minValue = 0
  end
  self.ui.mSlider_Slider.maxValue = self.curMaxNum
  IconUtils.GetItemIconSpriteAsync(CS.GunWeaponModProperty.DecomposeUpItemId, self.ui.mImg_IncreaseIcon)
  if self.commonItem == nil then
    local commonItem = UICommonItem.New()
    commonItem:InitCtrl(self.ui.mScrollListChild_GrpItem)
    commonItem:SetItemData(CS.GunWeaponModProperty.DecomposeUpItemId, 0, true, true)
    self.commonItem = commonItem
    setactive(commonItem.ui.mTrans_Num.gameObject, true)
    local isItemEnough = self.itemOwn >= self.curSelectIncreaseItemNum
    if not isItemEnough then
      commonItem.ui.mText_Num.text = "<color=#FF5E41>" .. self.curSelectIncreaseItemNum .. "</color>/" .. self.curMaxNum
    else
      commonItem.ui.mText_Num.text = self.curSelectIncreaseItemNum .. "/" .. self.curMaxNum
    end
  end
  self:UpdateData()
  self:UpdateNumAndData()
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:UpdateData()
  local setTextColorByItemId = function(text, costNum)
    local isItemEnough = costNum <= self.itemOwn
    if not isItemEnough then
      self.commonItem.ui.mText_Num.text = "<color=#FF5E41>" .. costNum .. "</color>/" .. self.curMaxNum
      text.text = "<color=#FF5E41>" .. costNum .. "</color>"
    else
      self.commonItem.ui.mText_Num.text = costNum .. "/" .. self.curMaxNum
      text.text = costNum
    end
    return isItemEnough
  end
  local costNum = CS.GunWeaponModProperty.DecomposeUpItemNum * self.curSelectIncreaseItemNum
  setTextColorByItemId(self.ui.mText_CostNum, costNum)
  self.ui.mSlider_Slider.value = costNum
  local hintText
  if self.curSelectIncreaseItemNum == self.gunWeaponModData.ModDecomposeUpTimes then
    hintText = TableData.GetHintById(310089)
  else
    hintText = TableData.GetHintById(310053)
  end
  self.ui.mText_Tip.text = string_format(hintText, self.itemData.name.str, costNum, self.curSelectIncreaseItemNum)
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:ChangeSelectNum(num)
  self.curSelectIncreaseItemNum = self.curSelectIncreaseItemNum + num
  self:UpdateNumAndData()
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:UpdateNumAndData()
  self.ui.mBtn_GrpBtnReduce.interactable = self.curSelectIncreaseItemNum > self.curMinNum
  self.ui.mBtn_GrpBtnIncrease.interactable = self.curSelectIncreaseItemNum < self.curMaxNum
  if self.curSelectIncreaseItemNum < self.curMinNum then
    self.curSelectIncreaseItemNum = self.curMinNum
  end
  if self.curSelectIncreaseItemNum > self.curMaxNum then
    self.curSelectIncreaseItemNum = self.curMaxNum
  end
  self:UpdateData()
end

function UIChrWeaponPartsIncreaseDoubleCheckDialog:OnBtnConfirmClick()
  if self.itemOwn == 0 then
    local item = TableData.listItemDatas:GetDataById(CS.GunWeaponModProperty.DecomposeUpItemId)
    local itemOwn = NetCmdItemData:GetItemCountById(CS.GunWeaponModProperty.DecomposeUpItemId)
    TipsPanelHelper.OpenUITipsPanel(item, itemOwn, true)
    return
  end
  if self.callback ~= nil then
    self.callback(self.curSelectIncreaseItemNum)
  end
  UIManager.CloseUI(UIDef.UIChrWeaponPartsIncreaseDoubleCheckDialog)
end

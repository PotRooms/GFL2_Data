require("UI.UIBasePanel")
require("UI.ActivityStore.UIActivityStoreOptionalGiftItem")
UIActivityStoreOptionalGiftDialog = class("UIActivityStoreOptionalGiftDialog", UIBasePanel)
UIActivityStoreOptionalGiftDialog.__index = UIActivityStoreOptionalGiftDialog

function UIActivityStoreOptionalGiftDialog:ctor(csPanel)
  self.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIActivityStoreOptionalGiftDialog:OnInit(root, data)
  self.super.SetRoot(UIActivityStoreOptionalGiftDialog, root)
  self.data = data
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:RegisterEvent()
  self.selectId = 0
  self:OnSliderChange(1)
  self:UpdateInfo()
end

function UIActivityStoreOptionalGiftDialog:RegisterEvent()
  UIUtils.GetButtonListener(self.ui.mBtn_BgClose.gameObject).onClick = function()
    self.CloseSelf()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    self.CloseSelf()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Cancel.gameObject).onClick = function()
    self.CloseSelf()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Comfirm.gameObject).onClick = function()
    self:OnClickClaim()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Add.gameObject).onClick = function()
    self:OnAddSlider()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Reduce.gameObject).onClick = function()
    self:OnReduceSlider()
  end
end

function UIActivityStoreOptionalGiftDialog:OnSelectItem(id)
  if not self.data.canClaim then
    return
  end
  if self.selectId == id then
    self.selectId = 0
  else
    self.selectId = id
  end
  self:RefreshClaimState()
end

function UIActivityStoreOptionalGiftDialog:UpdateInfo()
  self.ui.mText_Title.text = self.data.boxData.name
  if self.data.canClaim then
    if self.data.boxData.id == 1001 then
      self.ui.mText_Title.text = TableData.GetHintById(260148)
    else
      self.ui.mText_Title.text = TableData.GetHintById(260149)
    end
  else
    self.ui.mText_Title.text = TableData.GetHintById(260111)
  end
  self.maxNum = NetCmdActivityStoreData:GetUnboxBoxCount(self.data.boxData.id)
  setactive(self.ui.mTrans_GrpHave, self.data.boxData.args_1.Count > 0)
  setactive(self.ui.mBtn_Cancel.transform.parent, self.data.canClaim)
  setactive(self.ui.mTrans_Num, false)
  local templateCompose = self.ui.mBtn_Comfirm.transform:GetComponent(typeof(CS.UITemplate))
  if self.data.canClaim then
    templateCompose.Texts[0].text = TableData.GetHintById(260157)
    self.selectNum = 1
    self.ui.mText_MaxNum.text = tostring(self.maxNum)
    self.ui.mSlider_Num.minValue = 1
    self.ui.mSlider_Num.maxValue = self.maxNum
    self.ui.mSlider_Num.onValueChanged:AddListener(function(value)
      self:OnSliderChange(value)
    end)
    self:RefreshSlider()
  else
    templateCompose.Texts[0].text = TableData.GetHintById(320002)
  end
  self.itemViewTable = {}
  for id, num in pairs(self.data.boxData.args_1) do
    local go = instantiate(self.ui.mScrollList_Have.childItem, self.ui.mScrollList_Have.transform)
    local item = UIActivityStoreOptionalGiftItem.New(go)
    item:SetData(id, num, false, self.data.canClaim)
    table.insert(self.itemViewTable, item)
  end
  for id, num in pairs(self.data.boxData.args) do
    local go = instantiate(self.ui.mScrollList_Sel.childItem, self.ui.mScrollList_Sel.transform)
    local item = UIActivityStoreOptionalGiftItem.New(go)
    item:SetData(id, num, true, self.data.canClaim, function()
      self:OnSelectItem(id)
    end)
    table.insert(self.itemViewTable, item)
  end
  self:RefreshClaimState()
end

function UIActivityStoreOptionalGiftDialog:OnAddSlider()
  if self.selectNum >= self.maxNum then
    return
  end
  self:OnSliderChange(self.selectNum + 1)
end

function UIActivityStoreOptionalGiftDialog:OnReduceSlider()
  if self.selectNum <= 1 then
    return
  end
  self:OnSliderChange(self.selectNum - 1)
end

function UIActivityStoreOptionalGiftDialog:OnSliderChange(value)
  self.selectNum = value
  self:RefreshSlider()
end

function UIActivityStoreOptionalGiftDialog:RefreshSlider()
  self.ui.mBtn_Reduce.interactable = self.selectNum > 1
  self.ui.mBtn_Add.interactable = self.selectNum ~= self.maxNum and self.selectNum ~= 0
  self.ui.mSlider_Num.value = self.selectNum
  self.ui.mText_Num.text = math.floor(self.selectNum)
end

function UIActivityStoreOptionalGiftDialog:RefreshClaimState()
  local count = 0
  if self.selectId ~= 0 then
    count = 1
  end
  for _, item in pairs(self.itemViewTable) do
    item:SetSelect(item.id == self.selectId)
  end
  setactive(self.ui.mTrans_Num, self.selectId ~= 0 and self.data.canClaim and 1 < self.maxNum)
  self.ui.mBtn_Comfirm.interactable = count == 1 or not self.data.canClaim
  setactive(self.ui.mText_Sel, self.data.canClaim)
  self.ui.mText_Sel.text = string_format(TableData.GetHintById(260155), count, "1")
end

function UIActivityStoreOptionalGiftDialog:OnClickClaim()
  if self.data.canClaim then
    if self.selectId ~= 0 then
      self.ui.mBtn_Comfirm.interactable = false
      NetCmdActivityStoreData:SendCollectionGetReward(self.data.boxData.id, self.selectId, self.selectNum, function(ret)
        if ret == ErrorCodeSuc then
          UIManager.CloseUI(UIDef.UIActivityStoreOptionalGiftDialog)
          UISystem:OpenCommonReceivePanel()
        end
        self.ui.mBtn_Comfirm.interactable = true
      end)
    end
  else
    self.CloseSelf()
  end
end

function UIActivityStoreOptionalGiftDialog.CloseSelf()
  UIManager.CloseUI(UIDef.UIActivityStoreOptionalGiftDialog)
end

function UIActivityStoreOptionalGiftDialog:OnClose()
  self:ReleaseCtrlTable(self.itemViewTable, true)
end

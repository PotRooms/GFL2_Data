require("UI.Common.UICommonDutyItem")
require("UI.UIBaseCtrl")
BpPassRewardBoxItem = class("BpPassRewardBoxItem", UIBaseCtrl)

function BpPassRewardBoxItem:ctor(parent)
  local go = self:Instantiate("BattlePass/Btn_BattlePassRewardBoxItem.prefab", parent)
  self:SetRoot(go.transform)
  self.ui = UIUtils.GetUIBindTable(go)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Root.gameObject, function()
    self:OnClickSelf()
  end)
end

function BpPassRewardBoxItem:SetData(index, itemId, num)
  self.mIndex = index
  self.mItemId = itemId
  self.mIsSelect = false
  self.mItemData = TableData.GetItemData(itemId)
  self.ui.mText_Name.text = self.mItemData.name.str
  self.mItemView = UICommonItem.New()
  self.mItemView:InitCtrl(self.ui.mSListChild_GrpItem, true)
  self.mItemView:SetItemData(itemId, num)
  self:Refresh()
end

function BpPassRewardBoxItem:AddBtnClickListener(callback)
  self.callback = callback
end

function BpPassRewardBoxItem:Refresh()
  setactive(self.ui.mTrans_Sel, self.mIsSelect)
end

function BpPassRewardBoxItem:OnRelease()
  if self.mItemView ~= nil then
    gfdestroy(self.mItemView:GetRoot())
  end
  self.callback = nil
  self.ui = nil
  self.super.OnRelease(self)
end

function BpPassRewardBoxItem:OnClickSelf()
  if self.callback ~= nil then
    self.callback()
  end
end

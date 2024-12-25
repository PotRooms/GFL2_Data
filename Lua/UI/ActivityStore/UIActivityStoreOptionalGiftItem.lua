require("UI.Common.UICommonItem")
UIActivityStoreOptionalGiftItem = class("UIActivityStoreOptionalGiftItem", UIBaseCtrl)

function UIActivityStoreOptionalGiftItem:ctor(go)
  self.ui = UIUtils.GetUIBindTable(go)
  self:SetRoot(go.transform)
end

function UIActivityStoreOptionalGiftItem:SetData(id, count, canSelect, canClaim, callBack)
  self.id = id
  self.count = count
  self.canSelect = canSelect
  self.canClaim = canClaim
  self:UpdateInfo()
  if not self.canClaim then
    local itemData = TableData.GetItemData(self.id)
    TipsManager.Add(self.ui.mBtn_Root.gameObject, itemData)
  elseif self.canSelect and callBack ~= nil then
    UIUtils.GetButtonListener(self.ui.mBtn_Root.gameObject).onClick = callBack
  end
end

function UIActivityStoreOptionalGiftItem:UpdateInfo()
  local itemData = TableData.GetItemData(self.id)
  self.ui.mText_Name.text = itemData.name.str
  local item = UICommonItem.New()
  setactive(self.ui.mTrans_Select, false)
  item:InitObj(self.ui.mTrans_InstantObj.gameObject)
  item:SetItemByStcData(itemData, self.count)
  item:SetEscortScore(self.count)
end

function UIActivityStoreOptionalGiftItem:SetSelect(isSelect)
  if self.canClaim then
    setactive(self.ui.mTrans_Select, not self.canSelect or isSelect)
  else
    setactive(self.ui.mTrans_Select, false)
  end
end

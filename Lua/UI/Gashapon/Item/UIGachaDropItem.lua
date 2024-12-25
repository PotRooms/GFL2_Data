UIGachaDropItem = class("UIGachaDropItem", UIBaseCtrl)

function UIGachaDropItem:ctor()
end

function UIGachaDropItem:InitCtrl(root, prefab, data)
  local instObj = instantiate(prefab)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  UIUtils.AddListItem(instObj.gameObject, root)
  self:SetRoot(instObj.transform)
  setactive(self.mUIRoot.gameObject, true)
  local itemData = TableData.GetItemData(data.id)
  if itemData ~= nil then
    self.ui.mImg_Icon.sprite = IconUtils.GetItemIconSprite(data.id)
  end
  self.ui.mText_Name.text = itemData.name.str
  self.ui.mText_Num.text = data.count
end

function UIGachaDropItem:OnRelease()
  gfdestroy(self.mUIRoot)
  self.ui = nil
end

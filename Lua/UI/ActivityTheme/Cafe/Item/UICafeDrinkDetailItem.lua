UICafeDrinkDetailItem = class("UICafeDrinkDetailItem", UIBaseCtrl)

function UICafeDrinkDetailItem:ctor()
end

function UICafeDrinkDetailItem:InitCtrl(root, data)
  local instObj = instantiate(UIUtils.GetGizmosPrefab("ActivityCafe/Btn_ActivityCafeDrinksDetailsItem.prefab", self), root.transform)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  UIUtils.AddListItem(instObj.gameObject, root)
  self:SetRoot(instObj.transform)
  self.data = data
  UIUtils.GetButtonListener(self.ui.mBtn_Self.gameObject).onClick = function()
    local params = CS.GF2.UI.UIActivityCafeItemDetailParam(self.data.id, CS.GF2.UI.DetailDialogShowType.Item, nil, false, CS.GF2.Data.SubmoduleType.ActivitySimCafe, self.data.configId)
    UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIActivityCafeItemDetailDialog, params)
  end
  self:UpdateInfo()
end

function UICafeDrinkDetailItem:UpdateInfo()
  local itemData = TableData.GetItemData(self.data.id)
  self.ui.mImg_Icon.sprite = IconUtils.GetItemIcon(itemData.icon)
  self.ui.mText_Num.text = CS.LuaUIUtils.GetMaxNumberText(self.data.count)
  setactive(self.ui.mTrans_Fall, self.data.isFall)
end

function UICafeDrinkDetailItem:OnRelease()
  gfdestroy(self.mUIRoot)
  self.ui = nil
end

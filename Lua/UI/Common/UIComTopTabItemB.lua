require("UI.UIBaseCtrl")
UIComTopTabItemB = class("UIComTopTabItemB", UIBaseCtrl)
UIComTopTabItemB.__index = UIComTopTabItemB

function UIComTopTabItemB:ctor()
end

function UIComTopTabItemB:InitCtrl(parent, data)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:SetRoot(instObj.transform)
  self.ui.mText_Name.text = data.name
  self.clickAction = nil
  UIUtils.GetButtonListener(self.ui.mBtn_Self.gameObject).onClick = function()
    if self.clickAction then
      self.clickAction()
    end
  end
end

function UIComTopTabItemB:AddClickListener(callback)
  self.clickAction = callback
end

function UIComTopTabItemB:SetBtnInteractable(interactable)
  self.ui.mBtn_Self.interactable = interactable
end

function UIComTopTabItemB:SetRedPointVisible(visible)
  setactive(self.ui.mTrans_RedPoint, visible)
end

function UIComTopTabItemB:OnRelease()
  UIUtils.GetButtonListener(self.ui.mBtn_Self.gameObject).onClick = nil
  self.ui = nil
  self.clickAction = nil
  gfdestroy(self.mUIRoot)
end

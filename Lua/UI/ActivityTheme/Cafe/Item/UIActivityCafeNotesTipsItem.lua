UIActivityCafeNotesTipsItem = class("UIActivityCafeNotesTipsItem", UIBaseCtrl)

function UIActivityCafeNotesTipsItem:ctor()
end

function UIActivityCafeNotesTipsItem:InitCtrl(root, data)
  local instObj = instantiate(UIUtils.GetGizmosPrefab("ActivityCafe/ActivityCafeNotesTipsItem.prefab", self))
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  UIUtils.AddListItem(instObj.gameObject, root)
  self:SetRoot(instObj.transform)
  setactive(instObj.gameObject, false)
  self.isActive = false
end

function UIActivityCafeNotesTipsItem:UpdateInfo(id, count)
  local itemData = TableData.GetItemData(id)
  self.ui.mImg_Icon.sprite = IconUtils.GetItemIcon(itemData.icon)
  self.ui.mText_Name.text = itemData.Name.str
  self.ui.mText_Num.text = "\195\151" .. count
  setactive(self.mUIRoot, true)
  self.isActive = true
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  self.timer = TimerSys:DelayCall(2, function()
    setactive(self.mUIRoot, false)
    self.isActive = false
  end)
end

function UIActivityCafeNotesTipsItem:UpdateCount()
end

function UIActivityCafeNotesTipsItem:OnRelease()
  gfdestroy(self.mUIRoot)
  self.ui = nil
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
end

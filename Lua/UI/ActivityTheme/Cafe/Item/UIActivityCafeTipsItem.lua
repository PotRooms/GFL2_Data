UIActivityCafeTipsItem = class("UIActivityCafeTipsItem", UIBaseCtrl)

function UIActivityCafeTipsItem:ctor()
end

function UIActivityCafeTipsItem:InitCtrl(root)
  local instObj = instantiate(UIUtils.GetGizmosPrefab("ActivityCafe/ActivityCafeMainTipsItem.prefab", self))
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  UIUtils.AddListItem(instObj.gameObject, root)
  self:SetRoot(instObj.transform)
  setactive(instObj.gameObject, false)
  self.isActive = false
end

function UIActivityCafeTipsItem:UpdateInfo(str)
  self.ui.mText_Info.text = str
  setactive(self.mUIRoot, true)
  self.isActive = true
  self.mUIRoot:SetAsLastSibling()
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  self.timer = TimerSys:DelayCall(2, function()
    self:RecycleItem()
  end)
end

function UIActivityCafeTipsItem:RecycleItem()
  self.isActive = false
  setactive(self.mUIRoot, false)
end

function UIActivityCafeTipsItem:OnRelease()
  gfdestroy(self.mUIRoot)
  self.ui = nil
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
end

require("UI.ActivityTheme.Module.Bingo.ActivityBingoItem")
UILennaBingoItem = class("UILennaBingoItem", ActivityBingoItem)
UILennaBingoItem.__index = UILennaBingoItem

function UILennaBingoItem:ctor()
end

function UILennaBingoItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:InitCtrlWithNoInstantiate(instObj, false)
end

function UILennaBingoItem:InitCtrlWithNoInstantiate(obj, setToZero)
  self:SetRoot(obj.transform)
  obj.transform.localPosition = vectorzero
  if setToZero == nil or setToZero then
    obj.transform.anchoredPosition = vector2zero
  else
    obj.transform.anchoredPosition = vector2one * 1000000
  end
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
end

function UILennaBingoItem:SetData(key, index, status)
  self.key = key
  self.index = index
  self.status = status == true
  self:GetRoot().name = key .. "-" .. index
  self:SetStatus(false)
end

function UILennaBingoItem:UpdateStatus(status, withAnim)
  if self.status == status then
    return
  end
  self.status = status
  self:SetStatus(withAnim)
end

function UILennaBingoItem:SetStatus(withAnim)
  if withAnim then
    if self.status then
      self.ui.mAnim_Root:SetTrigger("Flip")
    end
  elseif self.status then
    self.ui.mAnim_Root:SetTrigger("Base")
  end
end

function UILennaBingoItem:OnReward()
  self.ui.mAnim_Root:SetTrigger("WhiteMask")
end

require("UI.ActivityTheme.Module.Bingo.ActivityBingoRewardItem")
UILennaBingoRewardItem = class("UILennaBingoRewardItem", ActivityBingoRewardItem)
UILennaBingoRewardItem.__index = UILennaBingoRewardItem

function UILennaBingoRewardItem:ctor()
end

function UILennaBingoRewardItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:InitCtrlWithNoInstantiate(instObj, false)
end

function UILennaBingoRewardItem:InitCtrlWithNoInstantiate(obj, setToZero)
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

function UILennaBingoRewardItem:SetData(key, index, config, status, dir)
  self.key = key
  self.index = index
  self.status = status
  self.rewardCondition = config.RewardCondition
  self:GetRoot().name = key .. "-" .. index
  for id, count in pairs(config.ItemId) do
    if dir == 1 then
      IconUtils.GetItemIconSpriteAsync(id, self.ui.mImg_Icon_H)
      self.ui.mText_Num_H.text = "\195\151" .. count
      setactivewithcheck(self.ui.mRoot_H, true)
      setactivewithcheck(self.ui.mRoot_V, false)
    else
      IconUtils.GetItemIconSpriteAsync(id, self.ui.mImg_Icon_V)
      self.ui.mText_Num_V.text = "\195\151" .. count
      setactivewithcheck(self.ui.mRoot_H, false)
      setactivewithcheck(self.ui.mRoot_V, true)
    end
  end
  self:SetStatus()
end

function UILennaBingoRewardItem:UpdateStatus(status)
  if status == self.status then
    return
  end
  self.status = status
  self:SetStatus()
end

function UILennaBingoRewardItem:SetStatus()
  setactivewithcheck(self.ui.mTrans_Finished, self.status == true)
end

function UILennaBingoRewardItem:OnReward()
  self.status = true
  self.ui.mAnimator_Root:SetTrigger("WhiteMask")
  self:SetStatus()
end

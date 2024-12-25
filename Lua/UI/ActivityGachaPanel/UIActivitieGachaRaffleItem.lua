require("UI.UIBaseCtrl")
UIActivitieGachaRaffleItem = class("UIActivitieGachaRaffleItem", UIBaseCtrl)
UIActivitieGachaRaffleItem.__index = UIActivitieGachaRaffleItem
UIActivitieGachaRaffleItem.ui = nil
UIActivitieGachaRaffleItem.mData = nil

function UIActivitieGachaRaffleItem:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function UIActivitieGachaRaffleItem:InitCtrl(obj)
  self:SetRoot(obj.transform)
  self.ui = {}
  self.mData = nil
  self:LuaUIBindTable(obj, self.ui)
  self.count = 1
  UIUtils.GetButtonListener(self.ui.mBtn_ActivitieGachaRaffleItem.gameObject).onClick = function()
    self:OnBtnClick()
  end
end

function UIActivitieGachaRaffleItem:SetData(count, clickCallBack)
  self.clickCallBack = clickCallBack
  self.count = count
  self:RefreshDefault()
end

function UIActivitieGachaRaffleItem:RefreshDefault()
  self.ui.mText_Num.text = string_format(TableData.GetHintById(270122), self.count)
end

function UIActivitieGachaRaffleItem:OnBtnClick()
  if not self.clickCallBack then
    return
  end
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  self.ui.mBtn_ActivitieGachaRaffleItem.interactable = false
  self.timer = TimerSys:DelayCall(0.5, function()
    self.ui.mBtn_ActivitieGachaRaffleItem.interactable = true
  end)
  self.clickCallBack()
end

function UIActivitieGachaRaffleItem:SetDefault(clickCallBack)
  self:RefreshDefault()
  self.clickCallBack = clickCallBack
end

function UIActivitieGachaRaffleItem:SetCanOpen(clickCallBack)
  self.ui.mText_Num.text = TableData.GetHintById(270108)
  self.clickCallBack = clickCallBack
end

function UIActivitieGachaRaffleItem:SetReset(clickCallBack)
  self.ui.mText_Num.text = TableData.GetHintById(270109)
  self.clickCallBack = clickCallBack
end

function UIActivitieGachaRaffleItem:OnRelease()
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
    self.ui.mBtn_ActivitieGachaRaffleItem.interactable = true
  end
end

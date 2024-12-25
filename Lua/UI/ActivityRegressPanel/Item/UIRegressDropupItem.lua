require("UI.UIBaseCtrl")
UIRegressDropupItem = class("UIRegressDropupItem", UIBaseCtrl)
UIRegressDropupItem.__index = UIRegressDropupItem

function UIRegressDropupItem:__InitCtrl()
end

function UIRegressDropupItem:InitCtrl(parent, child)
  local instObj = instantiate(child)
  CS.LuaUIUtils.SetParent(instObj.gameObject, parent.gameObject)
  self:SetRoot(instObj.transform)
  self.ui = {}
  self:LuaUIBindTable(self.mUIRoot, self.ui)
  self:__InitCtrl()
end

function UIRegressDropupItem:SetData(data)
  if data.regress then
    self:SetRegress(data)
  else
    self:SetOther(data)
  end
end

function UIRegressDropupItem:SetRegress(data)
  self.ui.mText_Des.text = NetCmdActivityRegressData:GetActivityDesc()
  self:SetTimes(data)
end

function UIRegressDropupItem:SetOther(data)
  self.ui.mText_Des.text = TableData.listUpActivityDatas:GetDataById(data.id).activity_text.str
  if NetCmdActivityDropUpData:IsCycleType(data.id) then
    self:SetCycle(data)
  else
    self:SetTimes(data)
  end
end

function UIRegressDropupItem:SetTimes(data)
  self.ui.mText_Num.text = data.max > 0 and data.current .. "/" .. data.max or ""
  self.ui.mAnimator:SetBool("Bool", 0 >= data.current and data.max > 0)
end

function UIRegressDropupItem:SetCycle(data)
  self.ui.mUICountdown_Text_Num:StartCountdown(data.closeTime)
  self.ui.mUICountdown_Text_Num:AddFinishCallback(function(suc)
    self.ui.mAnimator:SetBool("Bool", true)
  end)
  local now = CGameTime:GetTimestamp()
  self.ui.mAnimator:SetBool("Bool", now > data.closeTime)
end

function UIRegressDropupItem:OnRelease()
  self.ui.mUICountdown_Text_Num:CleanFinishCallback()
  gfdestroy(self.mUIRoot.gameObject)
  self.super.OnRelease(self)
end

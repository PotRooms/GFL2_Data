require("UI.UIBaseCtrl")
LennaPreWarmAnimItem = class("LennaPreWarmAnimItem", UIBaseCtrl)
LennaPreWarmAnimItem.__index = LennaPreWarmAnimItem

function LennaPreWarmAnimItem:ctor()
end

function LennaPreWarmAnimItem:InitCtrl(parent)
  local prefab = UIUtils.GetGizmosPrefab("ActivityTheme/Lenna/LennaPreheatTransitionDialog.prefab", self)
  local instObj = instantiate(prefab.gameObject, parent.transform)
  self:InitCtrlWithNoInstantiate(instObj)
end

function LennaPreWarmAnimItem:InitCtrlWithNoInstantiate(obj, setToZero)
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

function LennaPreWarmAnimItem:SetData(data)
  self:DelayCall(1, function()
    self.ui.mAnimator_Root:SetTrigger("FadeOut")
    self:DelayCall(1, function()
      setactivewithcheck(self:GetRoot(), false)
    end)
  end)
end

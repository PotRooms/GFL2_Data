require("UI.UIBaseCtrl")
UIGuideIndicatorItemV2 = class("UIGuideIndicatorItemV2", UIBaseCtrl)
UIGuideIndicatorItemV2.__index = UIGuideIndicatorItemV2

function UIGuideIndicatorItemV2:ctor()
end

function UIGuideIndicatorItemV2:__InitCtrl()
  self.mTrans_On = self:GetRectTransform("GrpState/Trans_On")
end

function UIGuideIndicatorItemV2:InitCtrl(parent)
  local obj = instantiate(UIUtils.GetGizmosPrefab("UICommonFramework/ComGuideIndicatorItemV2.prefab", self))
  if parent then
    CS.LuaUIUtils.SetParent(obj.gameObject, parent.gameObject, false)
  end
  self:SetRoot(obj.transform)
  self:__InitCtrl()
end

function UIGuideIndicatorItemV2:SetOn(enabled)
  setactive(self.mTrans_On, enabled)
end

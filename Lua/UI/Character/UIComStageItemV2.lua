require("UI.UIBaseCtrl")
UIComStageItemV2 = class("UIComStageItemV2", UIBaseCtrl)
UIComStageItemV2.__index = UIComStageItemV2

function UIComStageItemV2:ctor()
  UIComStageItemV2.super.ctor(self)
end

function UIComStageItemV2:InitCtrl(parent, useScrollListChild)
  if useScrollListChild then
    local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
    self.prefab = instantiate(itemPrefab.childItem)
  else
    self.prefab = ResSys:GetUIGizmos("UICommonFramework/ComStage2ItemV2.prefab")
  end
  if parent then
    CS.LuaUIUtils.SetParent(self.prefab.gameObject, parent.gameObject, true)
  end
  self:SetRoot(self.prefab.transform)
  self.m_StageOnList = {}
  for i = 1, 6 do
    self.m_StageOnList[i] = self:GetRectTransform("GrpStage" .. i .. "/Trans_On")
  end
end

function UIComStageItemV2:SetData(stage)
  for i = 1, 6 do
    setactive(self.m_StageOnList[i], i <= stage)
  end
end

function UIComStageItemV2:Release()
  ResourceManager:DestroyInstance(self.prefab.gameObject)
end

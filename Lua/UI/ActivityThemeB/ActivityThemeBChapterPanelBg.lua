require("UI.UIBaseCtrl")
ActivityThemeBChapterPanelBg = class("ActivityThemeBChapterPanelBg", UIBaseCtrl)
ActivityThemeBChapterPanelBg.__index = ActivityThemeBChapterPanelBg

function ActivityThemeBChapterPanelBg:ctor()
end

function ActivityThemeBChapterPanelBg:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
    CS.LuaUIUtils.SetParent(instObj.gameObject, parent.gameObject, true)
  end
  self:SetRoot(instObj.transform)
end

function ActivityThemeBChapterPanelBg:InitCtrl(root)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
end

function ActivityThemeBChapterPanelBg:SetData(data)
  if data then
    self:SetLevelDiff(data.diffLevel)
  else
    self:SetLevelDiff(1)
  end
end

function ActivityThemeBChapterPanelBg:GetAspectRatioFitter()
  return self.ui.mAspectRatioFitter
end

function ActivityThemeBChapterPanelBg:SetLevelDiff(diff)
  setactive(self.ui.mTrans_Hard.gameObject, diff == 2)
  setactive(self.ui.mTrans_Normal.gameObject, diff == 1)
end

function ActivityThemeBChapterPanelBg:SetTrigger(name)
  self.ui.mAnimator:SetTrigger(name)
end

require("UI.UIBaseCtrl")
GashaponChrUpItemV2 = class("GashaponChrUpItemV2", UIBaseCtrl)
GashaponChrUpItemV2.__Index = GashaponChrUpItemV2

function GashaponChrUpItemV2:__InitCtrl()
  self.mText_Name = self:GetText("GrpDetails/Content/Text_Name")
  self.mTrans_star1 = self:GetRectTransform("GrpDetails/Content/GrpStar/Trans_Star1")
  self.mTrans_star2 = self:GetRectTransform("GrpDetails/Content/GrpStar/Trans_Star2")
  self.mTrans_star3 = self:GetRectTransform("GrpDetails/Content/GrpStar/Trans_Star3")
  self.mTrans_star4 = self:GetRectTransform("GrpDetails/Content/GrpStar/Trans_Star4")
  self.mTrans_star5 = self:GetRectTransform("GrpDetails/Content/GrpStar/Trans_Star5")
  self.mTrans_GrpAvatar = self:GetRectTransform("GrpAvatar")
end

function GashaponChrUpItemV2:InitCtrl(parent)
  local obj = instantiate(UIUtils.GetGizmosPrefab("Gashapon/GashaponChrUpItemV2.prefab", self))
  if parent then
    CS.LuaUIUtils.SetParent(obj.gameObject, parent.gameObject, false)
  end
  self:SetRoot(obj.transform)
  self:__InitCtrl()
end

function GashaponChrUpItemV2:SetData(data)
end

function GashaponChrUpItemV2:SetSelect(isSelect)
end

function GashaponChrUpItemV2:SetStars(starNum)
  local Stars = {}
  table.insert(Stars, self.mTrans_star1)
  table.insert(Stars, self.mTrans_star2)
  table.insert(Stars, self.mTrans_star3)
  table.insert(Stars, self.mTrans_star4)
  table.insert(Stars, self.mTrans_star5)
  for i = 1, #Stars do
    setactive(Stars[i].gameObject, false)
  end
  for i = 1, starNum do
    setactive(Stars[i].gameObject, true)
  end
end

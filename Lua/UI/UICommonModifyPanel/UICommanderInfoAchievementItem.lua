UICommanderInfoAchievementItem = class("UICommanderInfoAchievementItem", UIBaseCtrl)
UICommanderInfoAchievementItem.__index = UICommanderInfoAchievementItem
UICommanderInfoAchievementItem.RankType = {
  Gold = LuaUtils.EnumToInt(CS.ProtoObject.AchieveRank.Gold),
  Silver = LuaUtils.EnumToInt(CS.ProtoObject.AchieveRank.Silver),
  Copper = LuaUtils.EnumToInt(CS.ProtoObject.AchieveRank.Copper),
  Iron = LuaUtils.EnumToInt(CS.ProtoObject.AchieveRank.Iron),
  Plastics = LuaUtils.EnumToInt(CS.ProtoObject.AchieveRank.Plastics)
}

function UICommanderInfoAchievementItem:ctor()
end

function UICommanderInfoAchievementItem:InitCtrl(prefab, parent)
  local obj = instantiate(prefab, parent)
  self:SetRoot(obj.transform)
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
  self.mData = nil
end

function UICommanderInfoAchievementItem:SetData(achieveNum, icon)
  self.ui.mImg_Icon.sprite = IconUtils.GetAchievementIcon(icon, true)
  self.ui.mText_Num.text = achieveNum
end

function UICommanderInfoAchievementItem:OnRelease()
  gfdestroy(self:GetRoot())
end

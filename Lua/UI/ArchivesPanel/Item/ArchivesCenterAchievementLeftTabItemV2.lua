require("UI.UIBaseCtrl")
ArchivesCenterAchievementLeftTabItemV2 = class("ArchivesCenterAchievementLeftTabItemV2", UIBaseCtrl)
ArchivesCenterAchievementLeftTabItemV2.__index = ArchivesCenterAchievementLeftTabItemV2

function ArchivesCenterAchievementLeftTabItemV2:ctor()
end

function ArchivesCenterAchievementLeftTabItemV2:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:SetRoot(instObj.transform)
end

function ArchivesCenterAchievementLeftTabItemV2:SetData(data)
  self.tagId = data.id
  self.mData = data
  self.ui.mText_Name.text = data.tag_name.str
  self.ui.mImg_Icon.sprite = IconUtils.GetAchievementIconW(data.icon)
  self.total = NetCmdAchieveData:GetTotalCountByTagId(self.mData.id)
  self:RefreshData()
end

function ArchivesCenterAchievementLeftTabItemV2:RefreshData()
  local count = NetCmdAchieveData:GetDataProcessByTag(self.mData.id)
  self.ui.mText_Num.text = count
  self.ui.mText_TotalNum.text = "/" .. self.total
  self.isShowRedPoint = NetCmdAchieveData:TagRewardCanReceive(self.mData.id) or NetCmdAchieveData:CanReceiveByTagId(self.mData.id)
  setactive(self.ui.mTrans_RedPoint, self.isShowRedPoint)
end

function ArchivesCenterAchievementLeftTabItemV2:UpdateRedData()
  self.isShowRedPoint = NetCmdAchieveData:TagRewardCanReceive(self.mData.id) or NetCmdAchieveData:CanReceiveByTagId(self.mData.id)
end

function ArchivesCenterAchievementLeftTabItemV2:SetItemState(isChoose)
  self.ui.mBtn_Root.interactable = not isChoose
  local count = NetCmdAchieveData:GetDataProcessByTag(self.mData.id)
  if isChoose then
    self.ui.mText_Num.text = count
    self.ui.mText_TotalNum.text = "/" .. self.total
  else
    self.ui.mText_Num.text = count
    self.ui.mText_TotalNum.text = "/" .. self.total
  end
end

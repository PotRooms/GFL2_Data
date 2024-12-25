require("UI.UIBaseCtrl")
DarkZoneMachineryLevelInfoItem = class("DarkZoneMachineryLevelInfoItem", UIBaseCtrl)
DarkZoneMachineryLevelInfoItem.__index = DarkZoneMachineryLevelInfoItem

function DarkZoneMachineryLevelInfoItem:__InitCtrl()
end

function DarkZoneMachineryLevelInfoItem:InitCtrl(root)
  if root == nil then
    return
  end
  local obj = instantiate(root.childItem, root.transform)
  self.ui = {}
  self.mData = {}
  self:LuaUIBindTable(obj, self.ui)
  self:SetRoot(obj.transform)
end

function DarkZoneMachineryLevelInfoItem:SetData(tableID)
  local tableData = TableData.listActivityCarTalentDatas:GetDataById(tableID)
  if tableData == nil then
    return
  end
  setactivewithcheck(self.ui.mTrans_CafeIcon, tableData.unit_type == 2)
  self.ui.mImg_Icon.sprite = IconUtils.GetIconV2("Buff", tableData.talent_icon)
  self.ui.mText_Name.text = tableData.talent_name.str
  self.ui.mText_Detail.text = tableData.talent_des.str
end

function DarkZoneMachineryLevelInfoItem:PlayAnim()
end

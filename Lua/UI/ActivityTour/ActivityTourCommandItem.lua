require("UI.UIBaseCtrl")
ActivityTourCommandItem = class("ActivityTourCommandItem", UIBaseCtrl)
ActivityTourCommandItem.__index = ActivityTourCommandItem

function ActivityTourCommandItem:ctor()
end

function ActivityTourCommandItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
    CS.LuaUIUtils.SetParent(instObj.gameObject, parent.gameObject, true)
  end
  self:InitCtrlWithNoInstantiate(obj)
end

function ActivityTourCommandItem:InitCtrlWithNoInstantiate(obj)
  self:SetRoot(obj.transform)
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
end

function ActivityTourCommandItem:SetData(data)
  self.ui.mImg_Icon.sprite = IconUtils.GetActivityTourIcon(data.order_icon)
  self.ui.mImg_QualityLine.color = TableData.GetActivityTourCommand_Quality_Color(data.level)
  self.ui.mText_Name.text = data.class_name.str
  self.ui.mTextFit_Describe.text = data.order_desc.str
  local useCount = NetCmdThemeData:GetOrderCount(data.id)
  if 0 <= useCount then
    setactive(self.ui.mTrans_Locked.gameObject, false)
    setactive(self.ui.mTrans_UsesNum.gameObject, true)
    self.ui.mText_Num.text = useCount
  else
    setactive(self.ui.mTrans_Locked.gameObject, true)
    setactive(self.ui.mTrans_UsesNum.gameObject, false)
  end
end

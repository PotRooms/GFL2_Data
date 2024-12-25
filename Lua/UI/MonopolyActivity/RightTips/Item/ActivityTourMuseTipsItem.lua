require("UI.UIBaseCtrl")
require("UI.MonopolyActivity.ActivityTourGlobal")
ActivityTourMuseTipsItem = class("ActivityTourMuseTipsItem", UIBaseCtrl)
ActivityTourMuseTipsItem.__index = ActivityTourMuseTipsItem
ActivityTourMuseTipsItem.ui = nil
ActivityTourMuseTipsItem.mData = nil
ActivityTourMuseTipsItem.showType = ActivityTourGlobal.InspirationTip

function ActivityTourMuseTipsItem:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function ActivityTourMuseTipsItem:InitCtrl(com, parent)
  local obj = instantiate(com.childItem, parent)
  self:SetRoot(obj.transform)
  self.ui = {}
  self.mData = nil
  self:LuaUIBindTable(obj, self.ui)
  MonopolyUtil:SetMonopolyActivityUIHint(self.mUIRoot.transform)
  ActivityTourGlobal.ReplaceAllColor(self.mUIRoot)
end

function ActivityTourMuseTipsItem:Refresh(data, showType)
  if showType == ActivityTourGlobal.InspirationTip then
    self.ui.mText_Title.text = MonopolyUtil:GetMonopolyActivityHint(270050)
    self.ui.mText_Name.text = UIUtils.GetItemName(data.Id)
    self.ui.mImg_Icon.sprite = UIUtils.GetItemIcon(data.Id)
    setactive(self.ui.mTrans_Desc, true)
    return
  end
  self.ui.mText_Title.text = MonopolyUtil:GetMonopolyActivityHint(270413)
  local commandData = TableData.listMonopolyOrderDatas:GetDataById(data)
  self.ui.mText_Name.text = commandData.name.str
  self.ui.mImg_Icon.sprite = ActivityTourGlobal.GetActivityTourSprite(commandData.order_icon)
  setactive(self.ui.mTrans_Desc, false)
end

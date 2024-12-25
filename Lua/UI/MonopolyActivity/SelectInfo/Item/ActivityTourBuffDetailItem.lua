require("UI.UIBaseCtrl")
ActivityTourBuffDetailItem = class("ActivityTourBuffDetailItem", UIBaseCtrl)
ActivityTourBuffDetailItem.__index = ActivityTourBuffDetailItem
ActivityTourBuffDetailItem.ui = nil
ActivityTourBuffDetailItem.mData = nil

function ActivityTourBuffDetailItem:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function ActivityTourBuffDetailItem:InitCtrl(itemPrefab, parent)
  local obj = instantiate(itemPrefab, parent)
  self:SetRoot(obj.transform)
  self.ui = {}
  self.mData = nil
  self:LuaUIBindTable(obj, self.ui)
  MonopolyUtil:SetMonopolyActivityUIHint(self.mUIRoot.transform)
end

function ActivityTourBuffDetailItem:Refresh(buffInfo, showLine)
  local buffData = TableData.listMonopolyEffectDatas:GetDataById(buffInfo.Id)
  if not buffData then
    return
  end
  self.ui.mImg_Icon.sprite = IconUtils.GetBuffIcon(buffData.icon)
  self.ui.mText_Title.text = buffData.name.str
  local round = buffInfo.RestTurn
  self.ui.mText_Round.text = string_format(MonopolyUtil:GetMonopolyActivityHint(270160), round)
  if buffData.turn >= 99 then
    self.ui.mText_Round.text = MonopolyUtil:GetMonopolyActivityHint(23002007)
  end
  self.ui.mText_Tip.text = round
  self.ui.mText_Des.text = buffData.desc.str
  setactive(self.ui.mTrans_Line.gameObject, showLine)
end

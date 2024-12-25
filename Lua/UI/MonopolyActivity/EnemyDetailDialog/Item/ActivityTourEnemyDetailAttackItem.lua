require("UI.UIBaseCtrl")
require("UI.MonopolyActivity.ActivityTourGlobal")
ActivityTourEnemyDetailAttackItem = class("ActivityTourEnemyDetailAttackItem", UIBaseCtrl)
ActivityTourEnemyDetailAttackItem.__index = ActivityTourEnemyDetailAttackItem

function ActivityTourEnemyDetailAttackItem:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function ActivityTourEnemyDetailAttackItem:InitCtrl(parent)
  local com = parent:GetComponent(typeof(CS.ScrollListChild))
  local obj = instantiate(com.childItem, parent)
  self:SetRoot(obj.transform)
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
end

function ActivityTourEnemyDetailAttackItem:SetData(title, des)
  self.ui.mText_Title.text = title
  self.ui.mText_Des.text = des
  self:ShowLine(false)
end

function ActivityTourEnemyDetailAttackItem:ShowLine(isShow)
  setactive(self.ui.mTrans_Line, isShow)
end

function ActivityTourEnemyDetailAttackItem:OnRelease()
  self.super.OnRelease(self, true)
end

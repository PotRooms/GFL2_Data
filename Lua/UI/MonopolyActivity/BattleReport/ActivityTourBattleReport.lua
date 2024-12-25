require("UI.UIBaseCtrl")
require("UI.MonopolyActivity.ActivityTourGlobal")
require("UI.MonopolyActivity.BattleReport.ActivityTourBroadcastItem")
ActivityTourBattleReport = class("ActivityTourBattleReport", UIBaseCtrl)
ActivityTourBattleReport.__index = ActivityTourBattleReport

function ActivityTourBattleReport:ctor()
  self.super.ctor(self)
end

function ActivityTourBattleReport:InitCtrl(parentUI, parentPanel)
  self.ui = parentUI
  self.parentPanel = parentPanel
  self.mUseItem = {}
  self.mPoolItem = {}
  self.mShow = false
end

function ActivityTourBattleReport:ResetHeight()
  for i = 1, #self.mUseItem do
    local item = self.mUseItem[i]
    if item then
      item:ResetHeight()
    end
  end
end

function ActivityTourBattleReport:ShowInfo(info)
  if not self.mShow then
    self.mShow = true
    UIUtils.AnimatorFadeIn(self.ui.mAnim_Broadcast)
    for i = 1, #self.mPoolItem do
      local item = self.mPoolItem[i]
      item:Hide(false)
    end
  end
  if #self.mUseItem >= ActivityTourGlobal.MaxBattleReportShowCount then
    self:FadeItem(self.mUseItem[1], true)
    table.remove(self.mUseItem, 1)
  end
  local showItem
  if #self.mPoolItem > 0 then
    showItem = self.mPoolItem[1]
    table.remove(self.mPoolItem, 1)
  else
    showItem = ActivityTourBroadcastItem.New()
    showItem:InitCtrl(self.ui.mSLC_Broadcast.childItem, self.ui.mSLC_Broadcast.transform)
  end
  showItem:SetData(info)
  showItem.mUIRoot:SetAsLastSibling()
  table.insert(self.mUseItem, showItem)
end

function ActivityTourBattleReport:FadeAll()
  self.mShow = false
  UIUtils.AnimatorFadeOut(self.ui.mAnim_Broadcast)
  for i = 1, #self.mUseItem do
    local item = self.mUseItem[i]
    table.insert(self.mPoolItem, item)
  end
  self.mUseItem = {}
end

function ActivityTourBattleReport:FadeItem(item, isAnim)
  if not item then
    return
  end
  item:Hide(isAnim, function(hideItem)
    table.insert(self.mPoolItem, hideItem)
  end)
end

function ActivityTourBattleReport:Release()
  self:ReleaseCtrlTable(self.mUseItem, true)
  self:ReleaseCtrlTable(self.mPoolItem, true)
  self:OnRelease(true)
end

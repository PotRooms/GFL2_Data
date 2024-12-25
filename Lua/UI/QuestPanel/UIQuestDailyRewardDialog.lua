require("UI.QuestPanel.UIQuestDailyRewardElement")
require("UI.CommonLevelUpPanel.UICommonLevelUpPanel")
UIQuestDailyRewardDialog = class("UIQuestDailyRewardDialog", UIBasePanel)

function UIQuestDailyRewardDialog:ctor(basePanelUI)
  self.super.ctor(self, basePanelUI)
  basePanelUI.Type = UIBasePanelType.Dialog
end

function UIQuestDailyRewardDialog:OnAwake(root, havePoint)
  self.ui = UIUtils.GetUIBindTable(root)
  self:SetRoot(root)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BgClose.gameObject, function()
    self:onClickClose()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_GrpClose.gameObject, function()
    self:onClickClose()
  end)
  self.itemViewTable = {}
end

function UIQuestDailyRewardDialog:OnInit(root, havePoint)
  self.ui = UIUtils.GetUIBindTable(root)
  self.havePoint = havePoint
  self:initAllElement()
  
  function self.onPlayerCounterReset()
    UIManager.CloseUI(UIDef.UIQuestDailyRewardDialog)
  end
  
  MessageSys:AddListener(CS.GF2.Message.QuestEvent.OnPlayerCounterReset, self.onPlayerCounterReset)
end

function UIQuestDailyRewardDialog:OnShowStart()
  self:Refresh()
end

function UIQuestDailyRewardDialog:OnClose()
  self:ReleaseCtrlTable(self.itemViewTable, true)
end

function UIQuestDailyRewardDialog:OnRelease()
  MessageSys:RemoveListener(CS.GF2.Message.QuestEvent.OnPlayerCounterReset, self.onPlayerCounterReset)
  self.havePoint = nil
  self.ui = nil
end

function UIQuestDailyRewardDialog:Refresh()
  for i, itemView in ipairs(self.itemViewTable) do
    itemView:Refresh()
  end
end

function UIQuestDailyRewardDialog:initAllElement()
  local dailyRewardDataList = NetCmdQuestData:GetDailyRewardDataList()
  local template = self.ui.mScrollItem_Element.childItem
  local index = 0
  for i, dailyRewardData in pairs(dailyRewardDataList) do
    local go = instantiate(template, self.ui.mScrollItem_Element.transform)
    local item = UIQuestDailyRewardElement.New(go)
    item:SetData(index, dailyRewardData, self.havePoint, function()
      self:onElementReceived()
    end)
    index = index + 1
    table.insert(self.itemViewTable, item)
  end
end

function UIQuestDailyRewardDialog:onClickClose()
  UIManager.CloseUI(UIDef.UIQuestDailyRewardDialog)
end

function UIQuestDailyRewardDialog:onElementReceived()
  self:Refresh()
end

require("UI.UIBasePanel")
require("UI.MonopolyActivity.Settlement.Item.ActivityTourSettlementTaskItem")
require("UI.MonopolyActivity.Settlement.ActivityTourSettlementBase")
ActivityTourFailDialog = class("ActivityTourFailDialog", ActivityTourSettlementBase)
ActivityTourFailDialog.__index = ActivityTourFailDialog

function ActivityTourFailDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function ActivityTourFailDialog:RefreshReason()
  local config
  if 0 == NetCmdMonopolyData.LoseReason then
    config = TableDataBase.listMonopolyLoseHintDatas:GetDataByIndex(0)
    print_error("\229\164\177\232\180\165\229\142\159\229\155\160\230\156\170\228\184\139\229\143\145")
  else
    config = TableDataBase.listMonopolyLoseHintDatas:GetDataById(NetCmdMonopolyData.LoseReason)
  end
  if config then
    self.ui.mText_FailReason.text = config.des.str
  end
end

function ActivityTourFailDialog:RefreshRewardInfo()
  local listItem = {}
  for k, v in pairs(NetCmdMonopolyData.BonusItems) do
    table.insert(listItem, {itemId = k, itemNum = v})
  end
  UIUtils.SortItemTable(listItem)
  self:RefreshRewardInfoInternal(listItem, self.listReward, self.ui.mTrans_RewardContent)
  setactive(self.ui.mTrans_RewardRoot, 0 < #listItem)
end

function ActivityTourFailDialog:RefreshTaskInfo()
  self.super.RefreshTaskInfo(self)
end

function ActivityTourFailDialog:CloseSelf()
  if SceneSys.CurrentAdditiveSceneType == CS.EnumSceneType.Monopoly then
    NetCmdMonopolyData:ReturnToMainPanel()
  else
    UIManager.CloseUI(UIDef.ActivityTourFailDialog)
  end
end

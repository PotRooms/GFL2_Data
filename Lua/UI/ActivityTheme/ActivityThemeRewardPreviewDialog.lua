require("UI.UIBasePanel")
require("UI.ActivityTheme.ActivityThemeRewardItem")
ActivityThemeRewardPreviewDialog = class("ActivityThemeRewardPreviewDialog", UIBasePanel)
ActivityThemeRewardPreviewDialog.__index = ActivityThemeRewardPreviewDialog

function ActivityThemeRewardPreviewDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function ActivityThemeRewardPreviewDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.rewardUIList = {}
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.ActivityThemeRewardPreviewDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpClose.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.ActivityThemeRewardPreviewDialog)
  end
end

function ActivityThemeRewardPreviewDialog:OnInit(root, data)
  self.processIdList = NetCmdThemeData:GetRewardIdList(data.groupId)
  self.themeId = data.themeId
  for i = 1, self.processIdList.Count do
    local info = TableData.listWarmUpRewardDatas:GetDataById(self.processIdList[i - 1])
    local item = self.rewardUIList[i]
    if item == nil then
      item = ActivityThemeRewardItem.New()
      item:InitCtrl(self.ui.mTrans_Content)
      table.insert(self.rewardUIList, item)
    end
    item:SetData(info, self.themeId)
  end
end

function ActivityThemeRewardPreviewDialog:OnShowStart()
end

function ActivityThemeRewardPreviewDialog:OnShowFinish()
end

function ActivityThemeRewardPreviewDialog:OnTop()
end

function ActivityThemeRewardPreviewDialog:OnBackFrom()
end

function ActivityThemeRewardPreviewDialog:OnClose()
end

function ActivityThemeRewardPreviewDialog:OnHide()
end

function ActivityThemeRewardPreviewDialog:OnHideFinish()
end

function ActivityThemeRewardPreviewDialog:OnRelease()
end

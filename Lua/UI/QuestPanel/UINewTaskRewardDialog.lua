require("UI.UIBasePanel")
require("UI.QuestPanel.NewTaskRewardItem")
UINewTaskRewardDialog = class("UINewTaskRewardDialog", UIBasePanel)
UINewTaskRewardDialog.__index = UINewTaskRewardDialog

function UINewTaskRewardDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UINewTaskRewardDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListener()
  self.phaseTable = {}
  self:InitContent()
end

function UINewTaskRewardDialog:OnInit(root, data)
  local maxPhaseId = self:GetMaxPhaseId()
  self.ui.mVirtualListEx_List.numItems = maxPhaseId
  self.ui.mVirtualListEx_List:Refresh()
end

function UINewTaskRewardDialog:AddBtnListener()
  UIUtils.GetButtonListener(self.ui.mBtn_BgClose.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UINewTaskRewardDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpClose.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UINewTaskRewardDialog)
  end
end

function UINewTaskRewardDialog:ItemProvider(renderData)
  local itemView = NewTaskRewardItem.New(renderData)
  renderData.data = itemView
end

function UINewTaskRewardDialog:ItemRenderer(index, renderData)
  local item = renderData.data
  item:SetData(index + 1)
end

function UINewTaskRewardDialog:InitContent()
  local maxPhaseId = self:GetMaxPhaseId()
  
  function self.ui.mVirtualListEx_List.itemCreated(renderData)
    local item = self:ItemProvider(renderData)
    return item
  end
  
  function self.ui.mVirtualListEx_List.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
  
  self.ui.mVirtualListEx_List.numItems = maxPhaseId
  self.ui.mVirtualListEx_List:Refresh()
end

function UINewTaskRewardDialog:OnClose()
  self.ui.mVirtualListEx_List.numItems = 0
  if self.phaseTable then
    self:ReleaseCtrlTable(self.phaseTable, true)
    self.phaseTable = nil
  end
end

function UINewTaskRewardDialog:OnRelease()
end

function UINewTaskRewardDialog:GetMaxPhaseId()
  local dataList = TableData.listGuideQuestPhaseDatas:GetList()
  return dataList[dataList.Count - 1].id
end

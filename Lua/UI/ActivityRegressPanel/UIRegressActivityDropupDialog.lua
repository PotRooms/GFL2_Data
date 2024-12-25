require("UI.ActivityRegressPanel.Item.UIRegressDropupItem")
UIRegressActivityDropupDialog = class("UIRegressActivityDropupDialog", UIBasePanel)
UIRegressActivityDropupDialog.__index = UIRegressActivityDropupDialog

function UIRegressActivityDropupDialog:ctor(csPanel)
  self.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIRegressActivityDropupDialog:OnInit(root, data)
  self.super.SetRoot(UIRegressActivityDropupDialog, root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:RegisterEvent()
  self.stageType = data.stageType
end

function UIRegressActivityDropupDialog:OnShowStart()
  self:Refresh()
end

function UIRegressActivityDropupDialog:RegisterEvent()
  UIUtils.AddBtnClickListener(self.ui.mBtn_close, function()
    UIManager.CloseUI(UIDef.UIComDropUpDialog)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_GrpClose, function()
    UIManager.CloseUI(UIDef.UIComDropUpDialog)
  end)
end

function UIRegressActivityDropupDialog:Refresh()
  self:ReleaseItemTable()
  self.itemTable = {}
  local regressMax = NetCmdActivityRegressData:GetActivityUpCountMaxByStageType(self.stageType)
  if 0 < regressMax then
    local current = NetCmdActivityRegressData:GetActivityUpCountCurrent()
    local regressItem = UIRegressDropupItem.New()
    regressItem:InitCtrl(self.ui.mScrollListChild.transform, self.ui.mScrollListChild.childItem)
    regressItem:SetData({
      regress = true,
      max = regressMax,
      current = current
    })
    table.insert(self.itemTable, regressItem)
  end
  local dropUpActivities = NetCmdActivityDropUpData:GetAllDropUpActivities()
  for i = 0, dropUpActivities.Count - 1 do
    local activityId = dropUpActivities[i]
    local enable, max = NetCmdActivityDropUpData:GetActivityUpMaxByStageAndActivity(self.stageType, activityId)
    if enable then
      local current = NetCmdActivityDropUpData:GetActivityUpCurrentByStageAndActivity(self.stageType, activityId)
      local regressItem = UIRegressDropupItem.New()
      local closeTime = NetCmdActivityDropUpData:GetCloseTime(activityId)
      regressItem:InitCtrl(self.ui.mScrollListChild.transform, self.ui.mScrollListChild.childItem)
      regressItem:SetData({
        id = activityId,
        max = max,
        current = current,
        closeTime = closeTime
      })
      table.insert(self.itemTable, regressItem)
    end
  end
end

function UIRegressActivityDropupDialog:ReleaseItemTable()
  if self.itemTable == nil then
    return
  end
  for i = #self.itemTable, 1, -1 do
    local item = self.itemTable[i]
    item:OnRelease()
    table.remove(self.itemTable, i)
  end
  self.itemTable = nil
end

function UIRegressActivityDropupDialog:OnClose()
  self:ReleaseItemTable()
end

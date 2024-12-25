require("UI.ArchivesPanel.ArchivesUtils")
require("UI.ArchivesPanel.Item.ArchivesCenterEnterItemV2")
require("UI.UIBasePanel")
ArchivesCenterEnterPanelV2 = class("ArchivesCenterEnterPanelV2", UIBasePanel)
ArchivesCenterEnterPanelV2.__index = ArchivesCenterEnterPanelV2

function ArchivesCenterEnterPanelV2:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
end

function ArchivesCenterEnterPanelV2:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.itemlist = {}
  self:InitDataAndAddListener()
end

function ArchivesCenterEnterPanelV2:OnInit(root, data)
  NetCmdArchivesData:SendClientReachCount(1, function(ret)
    if ret == ErrorCodeSuc then
    end
  end)
end

function ArchivesCenterEnterPanelV2:OnShowStart()
  self:UpdateFunctionEntrance()
  self:RefreshLockState()
  self:RefreshRedPoint()
end

function ArchivesCenterEnterPanelV2:RefreshLockState()
end

function ArchivesCenterEnterPanelV2:RefreshRedPoint()
end

function ArchivesCenterEnterPanelV2:InitDataAndAddListener()
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.ArchivesCenterEnterPanelV2)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    UISystem:JumpToMainPanel()
  end
end

function ArchivesCenterEnterPanelV2:IsFuncOpen(systemId)
  if AccountNetCmdHandler:CheckSystemIsUnLock(systemId) then
    return true
  end
  local unlockData = TableDataBase.listUnlockDatas:GetDataById(systemId)
  if unlockData then
    local str = UIUtils.CheckUnlockPopupStr(unlockData)
    PopupMessageManager.PopupString(str)
  end
  return false
end

function ArchivesCenterEnterPanelV2:UpdateFunctionEntrance()
  local recoreRoomList = NetCmdArchivesData:GetRecoreRoom()
  for i = 1, recoreRoomList.Count do
    local data = recoreRoomList[i - 1]
    if i > #self.itemlist then
      local item = ArchivesCenterEnterItemV2.New()
      item:InitCtrl(self.ui.mTrans_Content)
      item:SetData(data)
      table.insert(self.itemlist, item)
    else
      self.itemlist[i]:SetData(data)
    end
  end
end

function ArchivesCenterEnterPanelV2:OnTop()
end

function ArchivesCenterEnterPanelV2:OnBackFrom()
  self:UpdateFunctionEntrance()
  self:RefreshLockState()
  self:RefreshRedPoint()
  self.ui.mMonoFindChildFadeManager_Content.enabled = false
  self.ui.mMonoFindChildFadeManager_Content.enabled = true
end

function ArchivesCenterEnterPanelV2:Hide()
end

function ArchivesCenterEnterPanelV2:OnRelease()
  self:ReleaseCtrlTable(self.itemlist)
end

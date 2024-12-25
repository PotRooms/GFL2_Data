CommandBottomBtn = class("CommandBottomBtn", UIBaseCtrl)
local self = CommandBottomBtn

function CommandBottomBtn:ctor()
  self.systemId = nil
  self.iconName = nil
end

function CommandBottomBtn:InitCtrl(gameObject, systemId, iconName)
  self.ui = {}
  self:LuaUIBindTable(gameObject, self.ui)
  if parent then
    UIUtils.AddListItem(gameObject, parent.gameObject)
  end
  self:SetRoot(gameObject.transform)
  self.systemId = systemId
  self.iconName = iconName
  self:InitCommandCenterTopBtn()
end

function CommandBottomBtn:InitCommandCenterTopBtn()
  local parent = self.mUIRoot
  if parent then
    self.systemId = self.systemId
    self.parent = parent
    self.transRedPoint = self.ui.mObj_RedPoint.transform
    self.btn = self.ui.mBtn_CommandCenterTab3ItemV2
  end
end

function CommandBottomBtn:CheckUnLock()
  local unlock = AccountNetCmdHandler:CheckSystemIsUnLock(self.systemId)
  if unlock then
    self.ui.mImg_CommandCenterTabIcon.sprite = IconUtils.GetCommandCenterIcon("Icon_CommandCenter_" .. self.iconName)
  else
    self.ui.mImg_CommandCenterTabIcon.sprite = IconUtils.GetCommandCenterIcon("Icon_CommandCenter_" .. self.iconName .. "_Lock")
  end
end

function CommandBottomBtn:SetData()
end

function CommandBottomBtn:OnRelease()
  self:DestroySelf()
end

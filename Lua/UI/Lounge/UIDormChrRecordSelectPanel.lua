require("UI.UIBasePanel")
require("UI.Lounge.Item.UIDormChrRecordSelectItem")
require("UI.Lounge.DormGlobal")
UIDormChrRecordSelectPanel = class("UIDormChrRecordSelectPanel", UIBasePanel)
UIDormChrRecordSelectPanel.__index = UIDormChrRecordSelectPanel

function UIDormChrRecordSelectPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
  csPanel.Is3DPanel = true
end

function UIDormChrRecordSelectPanel:OnAwake(root, data)
  self:SetRoot(root)
end

function UIDormChrRecordSelectPanel:OnInit(root, data)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:SetBaseData()
  self:AddBtnLister()
end

function UIDormChrRecordSelectPanel:RefreshItem()
  local listCount = self.allDataList.Count
  for i = 0, listCount - 1 do
    local index = 1 + i
    local id = self.allDataList[i]
    local item = self.rightBtnList[index]
    if item == nil then
      item = UIDormChrRecordSelectItem.New()
      item:InitCtrl(self.ui.mScrollListChild_Content)
      table.insert(self.rightBtnList, item)
    end
    item:SetClickFunction(function(item)
      self:RightBtnClickFunction(item)
      NetCmdLoungeData.IsDormMute = true
    end)
    item:SetData(id, index)
  end
end

function UIDormChrRecordSelectPanel:OnShowStart()
  self:RefreshItem()
end

function UIDormChrRecordSelectPanel:OnShowFinish()
  LoungeHelper.CameraCtrl.isDebug = false
end

function UIDormChrRecordSelectPanel:OnTop()
end

function UIDormChrRecordSelectPanel:OnBackFrom()
  self:RefreshItem()
end

function UIDormChrRecordSelectPanel:OnClose()
  self.isShowUI = true
  self:ReleaseCtrlTable(self.rightBtnList, true)
  self.rightBtnList = nil
  self.allDataList = nil
  self.gunData = nil
  self.ui = nil
  if DormGlobal.jumptomainpanel then
    SceneSys:GetHallScene():ChangeBackground(NetCmdCommandCenterData.Background)
  end
end

function UIDormChrRecordSelectPanel:OnHide()
end

function UIDormChrRecordSelectPanel:OnHideFinish()
end

function UIDormChrRecordSelectPanel:OnRelease()
end

function UIDormChrRecordSelectPanel:SetBaseData()
  self.rightBtnList = {}
  local gunCmdData = NetCmdLoungeData:GetCurrGunCmdData()
  local gunID = gunCmdData.gunData.character_id
  self.gunData = TableData.listGunCharacterDatas:GetDataById(gunID)
  local gunModelID = self.gunData.unit_id[0]
  self.allDataList = TableData.listCharacterDailyByGunIdDatas:GetDataById(gunModelID).Id
  self.closeTime = 0.01
end

function UIDormChrRecordSelectPanel:AddBtnLister()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    self:OnClickClose()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    DormGlobal.jumptomainpanel = true
    self.closeTime = 0
    UISystem:JumpToMainPanel()
  end
end

function UIDormChrRecordSelectPanel:RightBtnClickFunction(item)
  item:StartPlayBehavior()
end

function UIDormChrRecordSelectPanel:OnClickClose()
  UIManager.CloseUI(UIDef.UIDormChrRecordSelectPanel)
end

function UIDormChrRecordSelectPanel:OnCameraStart()
  return self.closeTime or 0.01
end

function UIDormChrRecordSelectPanel:OnCameraBack()
  return self.closeTime
end

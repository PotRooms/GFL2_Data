require("UI.UIBasePanel")
require("UI.ArchivesPanel.Item.UIArchivesCenterChrRecordSelectItem")
UIArchivesCenterChrRecordSelectDialog = class("UIArchivesCenterChrRecordSelectDialog", UIBasePanel)
UIArchivesCenterChrRecordSelectDialog.__index = UIArchivesCenterChrRecordSelectDialog

function UIArchivesCenterChrRecordSelectDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIArchivesCenterChrRecordSelectDialog:OnAwake(root, data)
  self:SetRoot(root)
end

function UIArchivesCenterChrRecordSelectDialog:OnInit(root, data)
  self.ui = {}
  self.gunData = data[0]
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnLister()
  self:SetBaseData()
  self.item = nil
  self.isPlayItem = false
  
  function self.AvgSceneClose()
    self:PlayDialog()
  end
  
  CS.GF2.Message.MessageSys.Instance:AddListener(CS.GF2.Message.UIEvent.AvgSceneClose, self.AvgSceneClose)
end

function UIArchivesCenterChrRecordSelectDialog:OnShowStart()
  local listCount = self.allDataList.Count
  for i = 0, listCount - 1 do
    local index = 1 + i
    local id = self.allDataList[i]
    if self.rightBtnList[index] == nil then
      self.rightBtnList[index] = UIArchivesCenterChrRecordSelectItem.New()
      self.rightBtnList[index]:InitCtrl(self.ui.mScrollListChild_Content)
      self.rightBtnList[index]:SetClickFunction(function(item)
        self:RightBtnClickFunction(item)
      end)
    end
    local item = self.rightBtnList[index]
    item:SetData(id, index, self.gunData)
  end
end

function UIArchivesCenterChrRecordSelectDialog:OnShowFinish()
end

function UIArchivesCenterChrRecordSelectDialog:OnTop()
end

function UIArchivesCenterChrRecordSelectDialog:OnBackFrom()
end

function UIArchivesCenterChrRecordSelectDialog:OnClose()
  self.isShowUI = true
  self:ReleaseCtrlTable(self.rightBtnList, true)
  self.rightBtnList = nil
  self.allDataList = nil
  self.gunData = nil
  self.ui = nil
end

function UIArchivesCenterChrRecordSelectDialog:OnHide()
end

function UIArchivesCenterChrRecordSelectDialog:OnHideFinish()
end

function UIArchivesCenterChrRecordSelectDialog:OnRelease()
  CS.GF2.Message.MessageSys.Instance:RemoveListener(CS.GF2.Message.UIEvent.AvgSceneClose, self.AvgSceneClose)
end

function UIArchivesCenterChrRecordSelectDialog:SetBaseData()
  self.rightBtnList = {}
  local gunModelID = self.gunData.unit_id[0]
  self.allDataList = TableData.listCharacterDailyByGunIdDatas:GetDataById(gunModelID).Id
end

function UIArchivesCenterChrRecordSelectDialog:AddBtnLister()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    self:OnClickClose()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    self:OnClickClose()
  end
end

function UIArchivesCenterChrRecordSelectDialog:RightBtnClickFunction(item)
  self.item = item
  item:StartPlayBehavior()
end

function UIArchivesCenterChrRecordSelectDialog:PlayDialog()
  if self.item and not self.isPlayItem then
    self.isPlayItem = true
    self.item:PlayDialog()
    self.item = nil
  end
end

function UIArchivesCenterChrRecordSelectDialog:OnClickClose()
  UIManager.CloseUI(UIDef.UIArchivesCenterChrRecordSelectDialog)
end

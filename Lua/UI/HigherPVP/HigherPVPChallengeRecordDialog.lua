require("UI.UIBasePanel")
require("UI.HigherPVP.HigherPVPChallengeItem")
HigherPVPChallengeRecordDialog = class("HigherPVPChallengeRecordDialog", UIBasePanel)
HigherPVPChallengeRecordDialog.__index = HigherPVPChallengeRecordDialog

function HigherPVPChallengeRecordDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function HigherPVPChallengeRecordDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:OnBtnClick()
end

function HigherPVPChallengeRecordDialog:OnBtnClick()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.HigherPVPChallengeRecordDialog)
  end
end

function HigherPVPChallengeRecordDialog:UpdateInfo()
  self.higherPVPList = NetCmdHigherPVPData:GetHighPvpHistory()
  if self.higherPVPList.Count == 0 then
    self.ui.mTrans_Empty.gameObject:SetActive(true)
    self.ui.mTrans_Info.gameObject:SetActive(false)
    AudioUtils.PlayCommonAudio(1020005)
  else
    self.ui.mLoopGridView_List.numItems = self.higherPVPList.Count
    self.ui.mLoopGridView_List:Refresh()
    self.ui.mTrans_Empty.gameObject:SetActive(false)
    self.ui.mTrans_Info.gameObject:SetActive(true)
    AudioUtils.PlayCommonAudio(1020048)
  end
end

function HigherPVPChallengeRecordDialog:OnInit(root, data)
  function self.ItemProvider(renderData)
    self:ItemProviderData(renderData)
  end
  
  function self.ItemRenderer(index, renderData)
    self:ItemRendererData(index, renderData)
  end
  
  self.ui.mLoopGridView_List.itemCreated = self.ItemProvider
  self.ui.mLoopGridView_List.itemRenderer = self.ItemRenderer
  self:UpdateInfo()
end

function HigherPVPChallengeRecordDialog:ItemProviderData(renderData)
  local itemView = HigherPVPChallengeItem.New()
  itemView:InitCtrlWithoutInstantiate(renderData.gameObject)
  renderData.data = itemView
end

function HigherPVPChallengeRecordDialog:ItemRendererData(index, renderData)
  local item = renderData.data
  local data = self.higherPVPList[index]
  item:SetData(data)
end

function HigherPVPChallengeRecordDialog:OnShowStart()
end

function HigherPVPChallengeRecordDialog:OnShowFinish()
end

function HigherPVPChallengeRecordDialog:OnTop()
end

function HigherPVPChallengeRecordDialog:OnBackFrom()
end

function HigherPVPChallengeRecordDialog:OnClose()
end

function HigherPVPChallengeRecordDialog:OnHide()
end

function HigherPVPChallengeRecordDialog:OnHideFinish()
end

function HigherPVPChallengeRecordDialog:OnRelease()
end

require("UI.UIBasePanel")
require("UI.ActivityStore.UIActivityStoreRecordItem")
UIActivityStoreRecordDialog = class("UIActivityStoreRecordDialog", UIBasePanel)
UIActivityStoreRecordDialog.__index = UIActivityStoreRecordDialog

function UIActivityStoreRecordDialog:ctor(csPanel)
  self.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIActivityStoreRecordDialog:OnInit(root, data)
  self.super.SetRoot(UIActivityStoreRecordDialog, root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.virtualList = self.ui.mList
  
  function self.virtualList.itemCreated(renderData)
    local item = self:ItemProvider(renderData)
    return item
  end
  
  function self.virtualList.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
  
  self:RegisterEvent()
  self:UpdateInfo()
end

function UIActivityStoreRecordDialog:RegisterEvent()
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    self.CloseSelf()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpClose.gameObject).onClick = function()
    self.CloseSelf()
  end
end

function UIActivityStoreRecordDialog:ItemProvider(renderData)
  local itemView = UIActivityStoreRecordItem.New()
  self.mRecordListItems = self.mRecordListItems or {}
  table.insert(self.mRecordListItems, itemView)
  itemView:InitCtrl(renderData.gameObject.transform)
  renderData.data = itemView
end

function UIActivityStoreRecordDialog:ItemRenderer(index, renderData)
  local item = renderData.data
  local data = self.history[index]
  item:InitData(data)
end

function UIActivityStoreRecordDialog:UpdateInfo()
  self.history = NetCmdActivityStoreData:GetCollectionHistory()
  setactive(self.ui.mTrans_None, self.history.Count == 0)
  setactive(self.ui.mTrans_GrpTitle, self.history.Count > 0)
  setactive(self.ui.mTrans_GrpList, self.history.Count > 0)
  if self.history.Count > 0 then
    self.virtualList.numItems = self.history.Count
    self.virtualList:Refresh()
  end
end

function UIActivityStoreRecordDialog.CloseSelf()
  UIManager.CloseUI(UIDef.UIActivityStoreRecordDialog)
end

function UIActivityStoreRecordDialog:OnClose()
end

function UIActivityStoreRecordDialog:OnRelease()
  self.virtualList = nil
  self.mRecordListItems = nil
end

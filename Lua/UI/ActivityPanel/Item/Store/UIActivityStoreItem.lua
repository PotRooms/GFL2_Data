require("UI.UIBaseCtrl")
require("UI.Common.UICommonItem")
require("UI.ActivityPanel.Item.UIActivityItemBase")
UIActivityStoreItem = class("UIActivityStoreItem", UIActivityItemBase)
UIActivityStoreItem.__index = UIActivityStoreItem

function UIActivityStoreItem:OnInit()
end

function UIActivityStoreItem:OnShow()
  self.ui.mText_Name.text = self.mActivityTableData.name.str
  self.ui.mText_Info.text = self.mActivityTableData.desc.str
  self.ui.mText_Time:StartCountdown(self.mCloseTime)
  if self.UICommonItems ~= nil then
    self:ReleaseCtrlTable(self.UICommonItems, true)
  end
  self.UICommonItems = {}
  local rewards = NetCmdOperationActivityData:GetRewarShow(self.mActivityID)
  for i = 0, rewards.Length - 1 do
    local item = UICommonItem.New()
    item:InitCtrl(self.ui.mTrans_Content)
    table.insert(self.UICommonItems, item)
    local itemData = TableData.GetItemData(rewards[i])
    item:SetItemByStcData(itemData, 0)
  end
  local redPoint = self.ui.mBtn_Goto.transform:Find("Root/Trans_RedPoint")
  if redPoint then
    setactive(redPoint, 0 < NetCmdActivityStoreData:CheckHasRedPoint(self.mActivityID))
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Goto.gameObject).onClick = function()
    if self.mActivityTableData.close_time < CGameTime:GetTimestamp() then
      UIUtils.PopupHintMessage(260044)
      return
    end
    if NetCmdActivityStoreData.Collection == nil then
      NetCmdActivityStoreData:SendGetCollectionInfo(function(ret)
        if ret ~= ErrorCodeSuc then
          return
        end
        UIManager.OpenUIByParam(UIDef.UIActivityStorePanel, self.mActivityTableData)
      end)
    else
      UIManager.OpenUIByParam(UIDef.UIActivityStorePanel, self.mActivityTableData)
    end
  end
end

function UIActivityStoreItem:OnHide()
end

function UIActivityStoreItem:OnTop()
  self:OnShow()
end

function UIActivityStoreItem:OnClose()
  self:ReleaseCtrlTable(self.UICommonItems, true)
end

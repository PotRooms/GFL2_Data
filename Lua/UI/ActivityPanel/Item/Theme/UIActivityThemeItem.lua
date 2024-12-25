require("UI.UIBaseCtrl")
require("UI.ActivityPanel.Item.UIActivityItemBase")
UIActivityThemeItem = class("UIActivityThemeItem", UIActivityItemBase)
UIActivityThemeItem.__index = UIActivityThemeItem

function UIActivityThemeItem:OnInit()
end

function UIActivityThemeItem:OnShow()
  self.ui.mText_Name.text = self.mActivityTableData.name.str
  self.ui.mText_Time:StartCountdown(self.mCloseTime)
  self.ui.mTextFit_Info.text = self.mActivityTableData.desc.str
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
  setactive(self.ui.mBtn_Goto, self.mActivityTableData.other_param ~= "")
  if self.mActivityTableData.other_param ~= "" then
    UIUtils.GetButtonListener(self.ui.mBtn_Goto).onClick = function()
      if CS.UIUtils.GetTouchClicked() then
        return
      end
      CS.UIUtils.SetTouchClicked()
      UISystem:JumpByID(tonumber(self.mActivityTableData.other_param))
    end
  end
end

function UIActivityThemeItem:OnHide()
  self.ui.mTrans_Content.transform.localPosition = vectorzero
end

function UIActivityThemeItem:OnTop()
  self:OnShow()
end

function UIActivityThemeItem:OnClose()
  self:ReleaseCtrlTable(self.UICommonItems, true)
end

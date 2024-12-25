require("UI.UIBaseCtrl")
require("UI.ActivityPanel.Item.UIActivityItemBase")
UIActivityDropUpItem = class("UIActivityDropUpItem", UIActivityItemBase)
UIActivityDropUpItem.__index = UIActivityDropUpItem

function UIActivityDropUpItem:OnShow()
  self.ui.mText_Name.text = self.mActivityTableData.name.str
  self.ui.mText_Desc.text = self.mActivityTableData.desc.str
  self.ui.mText_Time:StartCountdown(self.mCloseTime)
  UIUtils.GetButtonListener(self.ui.mBtn_Detail).onClick = function()
    self:ClickDetail()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Goto).onClick = function()
    self:ClickGoto()
  end
end

function UIActivityDropUpItem:ClickDetail()
  local desc = TableDataBase.listActivityListDatas:GetDataById(self.mActivityID).Help.str
  SimpleMessageBoxPanel.ShowByParam(TableData.GetHintById(260220), desc)
end

function UIActivityDropUpItem:ClickGoto()
  if self.mActivityTableData.other_param ~= "" then
    UISystem:JumpByID(tonumber(self.mActivityTableData.other_param))
  end
end

function UIActivityDropUpItem:OnTop()
  self:OnShow()
end

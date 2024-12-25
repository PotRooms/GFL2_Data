require("UI.UIBaseCtrl")
require("UI.ActivityPanel.Item.UIActivityItemBase")
UIActivityShowSkinItem = class("UIActivityShowSkinItem", UIActivityItemBase)
UIActivityShowSkinItem.__index = UIActivityShowSkinItem

function UIActivityShowSkinItem:OnInit()
end

function UIActivityShowSkinItem:OnShow()
  self.ui.mText_Name.text = self.mActivityTableData.name.str
  self.ui.mText_Time:StartCountdown(self.mCloseTime)
  UIUtils.GetButtonListener(self.ui.mBtn_Goto).onClick = function()
    if self.mActivityTableData.other_param ~= "" then
      UISystem:JumpByID(tonumber(self.mActivityTableData.other_param))
    end
  end
end

function UIActivityShowSkinItem:OnHide()
end

function UIActivityShowSkinItem:OnTop()
  self:OnShow()
end

function UIActivityShowSkinItem:OnClose()
end

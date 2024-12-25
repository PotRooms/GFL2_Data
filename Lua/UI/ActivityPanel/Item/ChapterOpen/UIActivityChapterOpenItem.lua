require("UI.UIBaseCtrl")
require("UI.ActivityPanel.Item.UIActivityItemBase")
UIActivityChapterOpenItem = class("UIActivityChapterOpenItem", UIActivityItemBase)
UIActivityChapterOpenItem.__index = UIActivityChapterOpenItem

function UIActivityChapterOpenItem:OnInit()
end

function UIActivityChapterOpenItem:OnShow()
  self.ui.mText_Name.text = self.mActivityTableData.name.str
  self.ui.mTextFit_Info.text = self.mActivityTableData.desc.str
  UIUtils.GetButtonListener(self.ui.mBtn_Goto).onClick = function()
    if self.mActivityTableData.other_param ~= "" then
      UISystem:JumpByID(tonumber(self.mActivityTableData.other_param))
    end
  end
end

function UIActivityChapterOpenItem:OnHide()
end

function UIActivityChapterOpenItem:OnTop()
  self:OnShow()
end

function UIActivityChapterOpenItem:OnClose()
end

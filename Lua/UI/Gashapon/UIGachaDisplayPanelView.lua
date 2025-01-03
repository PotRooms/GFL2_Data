require("UI.UIBaseView")
UIGachaDisplayPanelView = class("UIGachaDisplayPanelView", UIBaseView)
UIGachaDisplayPanelView.__index = UIGachaDisplayPanelView
UIGachaDisplayPanelView.mImage_Icon = nil
UIGachaDisplayPanelView.mText_Nun = nil

function UIGachaDisplayPanelView:__InitCtrl()
  self.mImage_Icon = self:GetImage("Root/ExtraGet/Image_Icon")
  self.mText_Nun = self:GetText("Root/ExtraGet/Text_Nun")
end

function UIGachaDisplayPanelView:InitCtrl(root)
  self:SetRoot(root)
  self:__InitCtrl()
end

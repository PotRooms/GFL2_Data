require("UI.UIBasePanel")
UINewChapterShowDialog = class("UINewChapterShowDialog", UIBasePanel)
UINewChapterShowDialog.__index = UINewChapterShowDialog

function UINewChapterShowDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
  self.mCSPanel = csPanel
end

function UINewChapterShowDialog:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.chapterID = data.NewChapterID
  self.chapterData = TableData.listChapterDatas:GetDataById(self.chapterID)
  self.timer = nil
  self:InitShow()
end

function UINewChapterShowDialog:InitShow()
  local id = self.chapterData.Id % 100
  self.ui.mText_Tittle.text = string.format(string_format(TableData.GetHintById(611), "%02d"), id)
  self.ui.mText_InfoB.text = self.chapterData.name.str
  self.ui.mText_InfoR.text = self.chapterData.name.str
  self.ui.mText_Info.text = self.chapterData.name.str
  self.ui.mText_Line.text = string.format(string_format(TableData.GetHintById(614), "%02d"), id)
  if self.timer then
    self.timer:Stop()
    self.timer = nil
  end
  self.timer = TimerSys:DelayCall(4.5, function()
    NetCmdDungeonData.HasNewChapterUnlocked = false
    NetCmdDungeonData.NewChapterID = -1
    UIManager.CloseUI(UIDef.UINewChapterShowDialog)
    if UIManager.IsPanelOpen(enumUIPanel.UIBattleIndexPanel) then
      UIManager.CloseUI(UIDef.UIChapterPanel)
    end
    MessageSys:SendMessage(UIEvent.UINewChapterItemFinish, nil)
  end)
end

function UINewChapterShowDialog:OnHide()
end

function UINewChapterShowDialog:OnClose()
  if self.timer then
    self.timer:Stop()
    self.timer = nil
  end
end

require("UI.UIBasePanel")
HigherPVPNewSeasonOpenDialog = class("HigherPVPNewSeasonOpenDialog", UIBasePanel)
HigherPVPNewSeasonOpenDialog.__index = HigherPVPNewSeasonOpenDialog

function HigherPVPNewSeasonOpenDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function HigherPVPNewSeasonOpenDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
end

function HigherPVPNewSeasonOpenDialog:CleanCloseTimer()
  if self.closeTimer ~= nil then
    self.closeTimer:Stop()
    self.closeTimer = nil
  end
end

function HigherPVPNewSeasonOpenDialog:OnInit(root, data)
  self.ui.mBtn_Close.enabled = false
  self:CleanCloseTimer()
  self.closeTimer = TimerSys:DelayCall(2.5, function()
    self.ui.mBtn_Close.enabled = true
    UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
      UIManager.CloseUI(UIDef.HigherPVPNewSeasonOpenDialog)
    end
  end)
  local seasonData = NetCmdHigherPVPData:GetHigherPVPSeasonData()
  if seasonData then
    local seasonTblData = NetCmdHigherPVPData:GetHigherPVPSeasonTblData(seasonData.SeasonId)
    if seasonTblData then
      self.ui.mText_Tittle.text = seasonTblData.season_name
    end
  end
  NetCmdHigherPVPData:SetHighPvpNewSeasonOpen()
end

function HigherPVPNewSeasonOpenDialog:OnShowStart()
end

function HigherPVPNewSeasonOpenDialog:OnShowFinish()
end

function HigherPVPNewSeasonOpenDialog:OnTop()
end

function HigherPVPNewSeasonOpenDialog:OnBackFrom()
end

function HigherPVPNewSeasonOpenDialog:OnClose()
  self:CleanCloseTimer()
end

function HigherPVPNewSeasonOpenDialog:OnHide()
end

function HigherPVPNewSeasonOpenDialog:OnHideFinish()
end

function HigherPVPNewSeasonOpenDialog:OnRelease()
end

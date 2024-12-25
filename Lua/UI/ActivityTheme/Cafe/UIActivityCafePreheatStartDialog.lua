require("UI.UIBasePanel")
require("UI.ActivityTheme.Cafe.ActivityCafeGlobal")
UIActivityCafePreheatStartDialog = class("UIActivityCafePreheatStartDialog", UIBasePanel)
UIActivityCafePreheatStartDialog.__index = UIActivityCafePreheatStartDialog

function UIActivityCafePreheatStartDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function UIActivityCafePreheatStartDialog:OnAwake(root, data)
end

function UIActivityCafePreheatStartDialog:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self.entranceData = data.activityEntranceData
  self.activityConfigData = data.activityConfigData
  self.activityModuleData = data.activityModuleData
  self:LuaUIBindTable(root, self.ui)
  self.ui.mBtn_Close.interactable = false
  self.intableTimer = nil
  self:AddBtnListener()
  self:InitContent()
end

function UIActivityCafePreheatStartDialog:InitContent()
  self.ui.mText_Info.text = self.entranceData.banner_information.str
  self.ui.mText_Title.text = TableData.GetActivityHint(271101, self.activityConfigData.Id, 1, self.activityModuleData.type)
end

function UIActivityCafePreheatStartDialog:AddBtnListener()
  self.intableTimer = TimerSys:DelayCall(2.84, function()
    self.ui.mBtn_Close.interactable = true
  end)
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIActivityCafePreheatStartDialog)
  end
end

function UIActivityCafePreheatStartDialog:OnClose()
  if self.intableTimer then
    self.intableTimer:Stop()
    self.intableTimer = nil
  end
  ActivityCafeGlobal.IsReadyStartTutorial = true
end

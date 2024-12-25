require("UI.UIBasePanel")
require("UI.UITweenCamera")
require("UI.Gashapon.UIGachaSkipPanelView")
UIGachaSkipPanel = class("UIGachaSkipPanel", UIBasePanel)
UIGachaSkipPanel.__index = UIGachaSkipPanel
UIGachaSkipPanel.mView = nil

function UIGachaSkipPanel.Close()
  UISystem:CloseUIForce(UIDef.UIGashaponSkipPanel, UIGroupType.BattleUI)
end

function UIGachaSkipPanel:ctor(csPanel)
  self.tmpBtnSkip = nil
  UIGachaSkipPanel.super.ctor(UIGachaSkipPanel, csPanel)
  if csPanel.UIParam.UserData.isDialog then
    csPanel.Type = UIBasePanelType.Dialog
  end
  csPanel.UsePool = false
  csPanel.Is3DPanel = true
end

function UIGachaSkipPanel:OnCameraStart()
  return 0.01
end

function UIGachaSkipPanel:OnCameraBack()
  return 0.01
end

function UIGachaSkipPanel:OnInit(root, data)
  self.mView = UIGachaSkipPanelView.New()
  UIGachaSkipPanel.super.SetRoot(UIGachaSkipPanel, root)
  self.ui = {}
  self.mView:LuaUIBindTable(root, self.ui)
  self.mView:InitCtrl(root)
  self:RefreshView(data)
  if self.mData.onInitFinished ~= nil then
    self.mData.onInitFinished(self)
  end
end

function UIGachaSkipPanel:InitTouchPad()
  setactive(self.ui.mTrans_TouchPad, true)
  setactive(self.ui.mTrans_Drag, true)
  InputSys:InitTouchPad()
end

function UIGachaSkipPanel:HideTouchPad()
  setactive(self.ui.mTrans_TouchPad, false)
  setactive(self.ui.mTrans_Drag, false)
  InputSys:HideTouchPad()
end

function UIGachaSkipPanel:SetDragActive(isActive)
  setactive(self.ui.mTrans_Drag, isActive)
end

function UIGachaSkipPanel:RefreshView(data)
  if data ~= nil then
    self.mData = data
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BgSkip.gameObject).onClick = function()
    if self.mData.bgSkip ~= nil then
      self.mData.bgSkip(self)
    end
  end
  UIUtils.GetButtonListener(self.ui.mBtn_IconSkip.gameObject).onClick = function()
    if self.mData.btnSkip ~= nil then
      self.mData.btnSkip(self)
      self.ui.mBtn_IconSkip.interactable = false
      if self.clickTimer ~= nil then
        self.clickTimer:Stop()
        self.clickTimer = nil
      end
      self.clickTimer = TimerSys:DelayCall(1, function()
        self.ui.mBtn_IconSkip.interactable = true
      end)
    end
  end
end

function UIGachaSkipPanel:OnClose()
  UIGachaSkipPanel.mView = nil
  setactive(self.ui.mTrans_TouchPad, false)
  if self.clickTimer ~= nil then
    self.clickTimer:Stop()
    self.clickTimer = nil
    self.ui.mBtn_IconSkip.interactable = true
  end
end

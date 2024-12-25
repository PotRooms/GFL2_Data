require("UI.PostPanelV2.UIPostBrowserPanelView")
require("UI.UIBasePanel")
require("UI.UITweenCamera")
UIPostBrowserPanel = class("UIPostBrowserPanel", UIBasePanel)
UIPostBrowserPanel.__index = UIPostBrowserPanel
UIPostBrowserPanel.mView = nil
UIPostBrowserPanel.__Opened = false
UIPostBrowserPanel.mBgmVolume = 0

function UIPostBrowserPanel.Close()
  UIManager.CloseUI(UIDef.UIPostPanelV2)
end

function UIPostBrowserPanel:OnClose()
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.PostJump, self.updateJumpFunc)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.UnmuteBrowserVolume, self.unmuteBrowserVolume)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.MuteBrowserVolume, self.muteBrowserVolume)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.BrowserUrlUpdate, UIPostBrowserPanel.browserUrlUpdateFunc)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.InternalBrowserOpen, self.internalBrowserOpen)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.InternalBrowserClose, self.internalBrowserClose)
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  if self.mLoadingTimer ~= nil then
    self.mLoadingTimer:Stop()
    self.mLoadingTimer = nil
  end
  if self.__Opened == true then
    self.ui.mBrowser:Close()
    PostInfoConfig.RecordReadPostList()
    self.__Opened = false
  end
  if self.callback then
    self.callback()
  end
end

function UIPostBrowserPanel.Open(callback)
  if not UIPostBrowserPanel.__Opened and not PostInfoConfig.PostIsNull then
    UIManager.OpenUIByParam(UIDef.UIPostPanelV2, callback)
  elseif callback then
    callback()
  end
end

function UIPostBrowserPanel:ctor(csPanel)
  UIPostBrowserPanel.super.ctor(UIPostBrowserPanel, csPanel)
  if csPanel then
    csPanel.Type = UIBasePanelType.Dialog
  end
end

function UIPostBrowserPanel:OnInit(root, data)
  UIPostBrowserPanel.__Opened = true
  self.mView = UIPostBrowserPanelView.New()
  self.ui = {}
  self.cachedUrl = {}
  self.mView:LuaUIBindTable(root, self.ui)
  self.mView:InitCtrl(root)
  
  function self.browserUrlUpdateFunc(msg)
    local url = tostring(msg.Sender)
    table.insert(self.cachedUrl, url)
    self.ui.mBrowser:Show(url)
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.BrowserUrlUpdate, self.browserUrlUpdateFunc)
  
  function self.internalBrowserOpen(msg)
    setactive(self.ui.mPanelRoot.gameObject, false)
  end
  
  function self.internalBrowserClose(msg)
    setactive(self.ui.mPanelRoot.gameObject, true)
  end
  
  function self.muteBrowserVolume()
  end
  
  function self.unmuteBrowserVolume()
  end
  
  function self.updateJumpFunc()
    self.callback = nil
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.PostJump, self.updateJumpFunc)
  MessageSys:AddListener(CS.GF2.Message.UIEvent.UnmuteBrowserVolume, self.unmuteBrowserVolume)
  MessageSys:AddListener(CS.GF2.Message.UIEvent.MuteBrowserVolume, self.muteBrowserVolume)
  MessageSys:AddListener(CS.GF2.Message.UIEvent.InternalBrowserOpen, self.internalBrowserOpen)
  MessageSys:AddListener(CS.GF2.Message.UIEvent.InternalBrowserClose, self.internalBrowserClose)
  self:RefreshView(data)
end

function UIPostBrowserPanel:RefreshView(data)
  setactive(self.ui.mPanelRoot.gameObject, true)
  if data ~= nil then
    self.callback = data
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BgClose.gameObject).onClick = function()
    if #self.cachedUrl > 1 then
      local url = self.cachedUrl[#self.cachedUrl - 1]
      table.remove(self.cachedUrl, #self.cachedUrl)
      UIPostBrowserPanel.ui.mBrowser:Show(url)
    else
      UIPostBrowserPanel.Close()
    end
  end
  local uid = AccountNetCmdHandler:GetUID()
  local soundVolume = CS.BattlePerformSetting.VolumeValue
  local postUrl = CS.ClientConfig.PostWebUrl .. "&uid=" .. tostring(uid) .. "&version=" .. tostring(PostInfoConfig.PostVersion) .. "&volume=" .. tostring(soundVolume) .. "&language=" .. AccountNetCmdHandler.langStrDic[CS.GameRoot.Instance.LanguageType]
  table.insert(self.cachedUrl, postUrl)
  self.mLoaded = false
  self.ui.mBrowser:Show(postUrl, CS.GF2.ExternalTools.Browsers.BrowserShowType.Normal, function()
    if self.mLoadingTimer == nil then
      self:ShowBrowserNode(true)
    end
    self.mLoaded = true
    if UISystem:GetTopPanelUI().UIDefine.UIType ~= UIDef.UICommandCenterPanel and UISystem:GetTopPanelUI().UIDefine.UIType ~= LuaUtils.EnumToInt(enumUIPanel.UICommandCenterHudPanel) then
      UIManager.CloseUI(UIDef.UIPostPanelV2)
    end
  end)
  self:ShowBrowserNode(false)
  if self.mLoadingTimer ~= nil then
    self.mLoadingTimer:Stop()
    self.mLoadingTimer = nil
  end
  self.mLoadingTimer = TimerSys:DelayCall(0.5, function()
    if self.mLoaded then
      self:ShowBrowserNode(true)
    end
    self.mLoadingTimer = nil
  end)
end

function UIPostBrowserPanel:ShowBrowserNode(isShow)
  if self.ui.mBrowser ~= nil then
    self.ui.mBrowser:EnableBrowserNode(isShow)
  end
  setactive(self.ui.mTrans_Loading, not isShow)
end

function UIPostBrowserPanel:OnRelease()
  UIPostBrowserPanel.mView = nil
end

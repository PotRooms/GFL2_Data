require("UI.UIBasePanel")
UIComTVBannerDialog = class("UIComTVBannerDialog", UIBasePanel)
UIComTVBannerDialog.__index = UIComTVBannerDialog

function UIComTVBannerDialog:ctor(csPanel)
  self.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIComTVBannerDialog:OnInit(root, data)
  self.super.SetRoot(UIComTVBannerDialog, root)
  self.data = data
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:RegisterEvent()
end

function UIComTVBannerDialog:RegisterEvent()
  UIUtils.GetButtonListener(self.ui.mBtn_BgClose.gameObject).onClick = function()
    self.CloseSelf()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    self.CloseSelf()
  end
  setactive(self.ui.mImg_Banner, false)
  CS.LuaUtils.DownloadTextureFromUrl(self.data.url, function(tex)
    if not CS.LuaUtils.IsNullOrDestroyed(self.ui.mImg_Banner) then
      local sprite = CS.UIUtils.TextureToSprite(tex)
      self.ui.mImg_Banner.sprite = sprite
      setactive(self.ui.mImg_Banner, true)
    end
  end)
end

function UIComTVBannerDialog.CloseSelf()
  UIManager.CloseUI(UIDef.UIComTVBannerDialog)
end

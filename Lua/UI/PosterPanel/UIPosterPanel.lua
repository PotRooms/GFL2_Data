require("UI.UIBasePanel")
require("UI.PosterPanel.UIPosterPanelView")
UIPosterPanel = class("UIPosterPanel", UIBasePanel)
UIPosterPanel.__index = UIPosterPanel
UIPosterPanel.mView = nil
UIPosterPanel.mCanvas = nil
UIPosterPanel.__Opened = false
UIPosterPanel.callback = nil

function UIPosterPanel:ctor(csPanel)
  UIPosterPanel.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIPosterPanel.Open(callback)
  if not UIPosterPanel.__Opened then
    if PostInfoConfig.PosterDataList == nil or PostInfoConfig.PosterDataList.Count <= 0 then
      print("\230\178\161\230\156\137\230\137\190\229\136\176\230\181\183\230\138\165\230\149\176\230\141\174\239\188\129\232\175\183\230\163\128\230\159\165\232\175\183\230\177\130\230\149\176\230\141\174\230\152\175\229\144\166\232\191\148\229\155\158\239\188\129")
      if callback then
        callback()
      end
      return
    end
    UIPosterPanel.callback = callback
    UIManager.OpenUI(UIDef.UIPosterPanel)
  else
    if callback then
      callback()
    end
    return
  end
end

function UIPosterPanel.Close()
  UIPosterPanel.__Opened = false
  UIManager.CloseUI(UIDef.UIPosterPanel)
  if UIPosterPanel.callback then
    UIPosterPanel.callback()
  end
end

function UIPosterPanel.Init(root, data)
  UIPosterPanel.__Opened = true
  UIPosterPanel.super.SetRoot(UIPosterPanel, root)
  self = UIPosterPanel
  self.mView = UIPosterPanelView
  self.mView:InitCtrl(root)
  UIUtils.GetButtonListener(self.mView.mBtn_Back.gameObject).onClick = self.OnReturnClick
  UIUtils.GetButtonListener(self.mView.mBtn_GotoActivity.gameObject).onClick = self.OnGotoActivityClick
  self.InitContent(PostInfoConfig.PosterDataList)
  self.mCanvas = CS.UnityEngine.GameObject.Find("Canvas")
end

function UIPosterPanel.InitContent(posterInfo)
  for i = 0, posterInfo.Count - 1 do
    local posterData = posterInfo[i]
    if string.find(posterData.Image, "https://") == 1 or string.find(posterData.Image, "http://") == 1 then
      setactive(UIPosterPanel.mView.mImage_Background.gameObject, false)
      CS.LuaUtils.DownloadTextureFromUrl(posterData.Image, function(tex)
        if not UIPosterPanel.__Opened then
          return
        end
        setactive(UIPosterPanel.mView.mImage_Background.gameObject, true)
        UIPosterPanel.mView.mImage_Background.sprite = CS.UIUtils.TextureToSprite(tex)
      end)
    end
  end
end

function UIPosterPanel.OnGotoActivityClick(gameObj)
  self = UIPosterPanel
end

function UIPosterPanel.OnReturnClick(gameObj)
  self = UIPosterPanel
  self.Close()
end

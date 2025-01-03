require("UI.UIBasePanel")
require("UI.TopBannerPanel.UITopBannerPanelView")
require("UI.TopBannerPanel.Item.UIBannerTextItem")
UITopBannerPanel = class("UITopBannerPanel", UIBasePanel)
UITopBannerPanel.__index = UITopBannerPanel
UITopBannerPanel.mView = nil
UITopBannerPanel.mCurDisplayItem = nil
UITopBannerPanel.mIsScrolling = false
UITopBannerPanel.mCurCloseItemData = nil
UITopBannerPanel.canvasPath = "UICommonFramework/CommonHintCanvas.prefab"

function UITopBannerPanel:ctor(csPanel)
  UITopBannerPanel.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UITopBannerPanel.Open()
  self = UITopBannerPanel
  UITopBannerPanel:InitShow()
end

function UITopBannerPanel.Close()
  UIManager.CloseUIByChangeScene(UIDef.UITopBannerPanel)
end

function UITopBannerPanel.Hide()
  self = UITopBannerPanel
  self:Show(false)
end

function UITopBannerPanel.Init(root, data)
  self = UITopBannerPanel
  self.mIsDontDestroyOnLoad = true
  UITopBannerPanel.mView = UITopBannerPanelView
  UITopBannerPanel.mView:InitCtrl(root)
  TimerSys:DelayCall(0.1, function(obj)
    UITopBannerPanel:SetRootToParent(root, UIUtils.GetUIRes(this.canvasPath).canvas.transform)
    CS.UnityEngine.GameObject.DontDestroyOnLoad(root)
  end)
  UIUtils.GetButtonListener(self.mView.mBtn_ClosePanel_Cancel.gameObject).onClick = self.OnCancelClicked
  UIUtils.GetButtonListener(self.mView.mBtn_ClosePanel_Close.gameObject).onClick = self.OnItemCloseClicked
  CS.GF2.Message.MessageSys.Instance:AddListener(CS.GF2.Message.CommonEvent.Broadcast, self.OnReceiveMsg)
end

function UITopBannerPanel.OnInit()
  self = UITopBannerPanel
end

function UITopBannerPanel.OnShow()
  self = UITopBannerPanel
end

function UITopBannerPanel.OnReceiveMsg(msg)
  self = UITopBannerPanel
  if self.mIsScrolling == true then
    return
  end
  self.UpdateItem()
end

function UITopBannerPanel.UpdateItem()
  self = UITopBannerPanel
  if self.mCurDisplayItem == nil then
    self.mCurDisplayItem = UIBannerTextItem.New()
    self.mCurDisplayItem:InitCtrl(self.mView.mTrans_BannerScrollBarList)
    UIUtils.GetButtonListener(self.mView.mTrans_BannerScrollBar.gameObject).onClick = self.OnItemClicked
  end
  local nextMsg = NetCmdBannerData:GetNextDisplayItem()
  if nextMsg == nil then
    self:Show(false)
    self.mIsScrolling = false
    return
  else
    self:Show(true)
  end
  self.mCurDisplayItem:SetData(nextMsg)
  self.OnScrolling(string.len(nextMsg.content))
end

function UITopBannerPanel.OnScrolling(count)
  self = UITopBannerPanel
  if self.mCurDisplayItem == nil then
    return
  end
  if self.mIsScrolling == true then
    return
  end
  self = UITopBannerPanel
  local from = vectorzero + Vector3(1000, 0, 0)
  local to = vectorzero + Vector3(-2400 - count * 26, 0, 0)
  local t = (count * 0.1 + 10) * NetCmdBannerData.BannerSpeed / 20
  CS.UITweenManager.PlayLocalPositionTween(self.mCurDisplayItem:GetRoot().transform, from, to, t, self.OnScrollEndCallback)
  self.mIsScrolling = true
end

function UITopBannerPanel.OnScrollEndCallback()
  self = UITopBannerPanel
  self.mIsScrolling = false
  self.UpdateItem()
end

function UITopBannerPanel.OnItemClicked(gameObj)
  self = UITopBannerPanel
  self.mCurCloseItemData = self.mCurDisplayItem.mData
  setactive(self.mView.mTrans_ClosePanel, true)
  self.mView.mText_ClosePanel_MainText.text = self.mCurCloseItemData.content
end

function UITopBannerPanel.OnCancelClicked(gameObj)
  self = UITopBannerPanel
  setactive(self.mView.mTrans_ClosePanel, false)
end

function UITopBannerPanel.OnItemCloseClicked(gameObj)
  self = UITopBannerPanel
  NetCmdBannerData:CloseDisplayItem(self.mCurCloseItemData.id)
  setactive(self.mView.mTrans_ClosePanel, false)
  if self.mCurCloseItemData.id == self.mCurDisplayItem.mData.id then
    self.mIsScrolling = false
    CS.UITweenManager.KillTween(self.mCurDisplayItem:GetRoot().transform)
    self.UpdateItem()
  end
end

function UITopBannerPanel.OnRelease()
  self = UITopBannerPanel
  self.mCurDisplayItem = nil
  self.mIsScrolling = false
  CS.GF2.Message.MessageSys.Instance:RemoveListener(CS.GF2.Message.CommonEvent.Broadcast, self.OnReceiveMsg)
  gfdebug("UITopBannerPanel.OnRelease")
end

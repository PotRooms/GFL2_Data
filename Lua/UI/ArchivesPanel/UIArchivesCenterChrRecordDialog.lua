require("UI.UIBasePanel")
UIArchivesCenterChrRecordDialog = class("UIArchivesCenterChrRecordDialog", UIBasePanel)
UIArchivesCenterChrRecordDialog.__index = UIArchivesCenterChrRecordDialog

function UIArchivesCenterChrRecordDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
end

function UIArchivesCenterChrRecordDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListen()
end

function UIArchivesCenterChrRecordDialog:OnInit(root, data)
  self.mData = data[2]
  self.Callback = data[1]
  self:InitInfoData()
end

function UIArchivesCenterChrRecordDialog:OnShowStart()
  self.canClose = self.mData.voice == 0
  if self.mData.voice > 0 then
    self:DelayCall(0.5, function()
      self.isPlayAudio = true
      AudioUtils.PlayByID(self.mData.voice)
      self.ui.mUIEffectNoiseSpectrum_Effect:SetSignalIntensityByComplete(1)
      self.ui.mTweenText_Details:OutputTextByLua(self.mData.text.str, function()
        self.canClose = true
      end)
    end)
  else
    self.ui.mTweenText_Details:OutputTextByLua(self.mData.text.str)
    self.ui.mTweenText_Details:CompleteOutput()
  end
end

function UIArchivesCenterChrRecordDialog:OnShowFinish()
end

function UIArchivesCenterChrRecordDialog:OnHide()
end

function UIArchivesCenterChrRecordDialog:OnClickClose()
  if self.canClose == true then
  else
    self.ui.mTweenText_Details:CompleteOutput()
    self.canClose = true
  end
  UIManager.CloseUI(UIDef.UIArchivesCenterChrRecordDialog)
  if self.Callback then
    self.Callback()
  end
end

function UIArchivesCenterChrRecordDialog:OnClose()
  if self.isPlayAudio == true then
    AudioUtils.StopAudioByID(self.mData.voice)
  end
  self.isPlayAudio = nil
  self.mData = nil
  self.canClose = nil
  self.super.OnClose(self)
end

function UIArchivesCenterChrRecordDialog:OnRelease()
end

function UIArchivesCenterChrRecordDialog:InitInfoData()
  self.ui.mTrans_Content.anchoredPosition = vector2zero
  self.ui.mText_Name.text = self.mData.title.str
  self.ui.mText_Detail.text = content
  self.ui.mText_Num.text = string.format("%02d", self.mData.sort)
  setactive(self.ui.mTrans_Audio, self.mData.voice > 0)
  setactive(self.ui.mTrans_ImgLine, not (self.mData.voice > 0))
end

function UIArchivesCenterChrRecordDialog:AddBtnListen()
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    self:OnClickClose()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BGClose.gameObject).onClick = function()
    if self.canClose == false then
      self.ui.mTweenText_Details:CompleteOutput()
    end
  end
end

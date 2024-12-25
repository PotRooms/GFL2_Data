require("UI.UIBasePanel")
require("UI.MonopolyActivity.Command.Btn_ActivityTourEventSelectItem")
ActivityTourCommandRefreshDialog = class("ActivityTourCommandRefreshDialog", UIBasePanel)
ActivityTourCommandRefreshDialog.__index = ActivityTourCommandRefreshDialog

function ActivityTourCommandRefreshDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function ActivityTourCommandRefreshDialog:OnInit(root, data)
  self.super.SetRoot(self, root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.mCommandID = data.commandID
  self.mCallBack = data.callBack
  self.mIsNew = data.isNew
  self.mIsReplaceMode = false
  self.mSlotIndex = nil
  self.mIsRemove = false
  MonopolyUtil:SetMonopolyActivityUIHint(self.mUIRoot.transform)
  self:RegisterEvent()
  self.ui.mAnim_Root.keepAnimatorControllerStateOnDisable = true
end

function ActivityTourCommandRefreshDialog:OnShowStart()
  if MonopolyWorld.MpData.commandList.Count >= ActivityTourGlobal.MaxCommandNum then
    self:ShowReplace()
  else
    self:ShowGet()
  end
end

function ActivityTourCommandRefreshDialog:CloseSelf(isRemove)
  self.mIsRemove = isRemove
  if isRemove == nil then
    self.mIsRemove = false
  end
  self:ShowFadeOut()
  self:DelayCall(0.5, function()
    UIManager.CloseUI(UIDef.ActivityTourCommandRefreshDialog)
    if self.mCallBack ~= nil then
      if self.mIsRemove then
        self.mCallBack(-1, CS.GF2.Monopoly.GetCommandType.Delete)
      else
        self.mCallBack(self.mSlotIndex, CS.GF2.Monopoly.GetCommandType.Replace)
      end
      self.mCallBack = nil
    end
  end)
end

function ActivityTourCommandRefreshDialog:RegisterEvent()
  UIUtils.GetButtonListener(self.ui.mBtn_Confirm.gameObject).onClick = function()
    self:ConfirmCommand()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Replace.gameObject).onClick = function()
    self:ShowReplaceDialog()
  end
end

function ActivityTourCommandRefreshDialog:ConfirmCommand()
  if self.mIsReplaceMode then
    if self.mSlotIndex then
      self:CloseSelf()
    end
  else
    self:CloseSelf()
  end
end

function ActivityTourCommandRefreshDialog:ShowReplaceDialog()
  local param = {
    selectCommandIndex = self.mSlotIndex,
    onSelectCallBack = function(slotIndex, data)
      self.mSlotIndex = slotIndex
      self:ShowReplaceData(data)
    end
  }
  UIManager.OpenUIByParam(UIDef.ActivityTourCommandSelectDialog, param)
end

function ActivityTourCommandRefreshDialog:ShowReplaceData(data)
  if not self.mUIReplaceCommandItem then
    self.mUIReplaceCommandItem = Btn_ActivityTourEventSelectItem.New()
    self.mUIReplaceCommandItem:InitCtrl(self.ui.mSLC_Replace.childItem, self.ui.mSLC_Replace.transform)
  end
  self.mUIReplaceCommandItem:SetCommandData(data.id)
  self.mUIReplaceCommandItem:ShowReplaceBtn(function()
    self:ShowReplaceDialog()
  end)
  self.mUIReplaceCommandItem:EnableBtn(false)
  setactive(self.ui.mBtn_Confirm, true)
end

function ActivityTourCommandRefreshDialog:ShowGet()
  self.ui.mText_Title.text = MonopolyUtil:GetMonopolyActivityHint(270162)
  self.ui.mText_Name.text = UIUtils.GetHintStr(18)
  self:ShowFadeIn(false)
  setactive(self.ui.mBtn_Confirm, true)
  UIUtils.EnableBtn(self.ui.mBtn_Replace, false)
  self:ShowGetCommand()
end

function ActivityTourCommandRefreshDialog:ShowReplace()
  self.mIsReplaceMode = true
  self.ui.mText_Title.text = MonopolyUtil:GetMonopolyActivityHint(270161)
  self.ui.mText_Name.text = MonopolyUtil:GetMonopolyActivityHint(270163)
  self:ShowFadeIn(true)
  setactive(self.ui.mBtn_Confirm, false)
  UIUtils.EnableBtn(self.ui.mBtn_Replace, true)
  self:ShowGetCommand()
end

function ActivityTourCommandRefreshDialog:ShowGetCommand()
  if not self.mUICommandItem then
    self.mUICommandItem = Btn_ActivityTourEventSelectItem.New()
    self.mUICommandItem:InitCtrl(self.ui.mSLC_Command.childItem, self.ui.mSLC_Command.transform)
  end
  self.mUICommandItem:SetCommandData(self.mCommandID)
  if MonopolyWorld.MpData.commandList.Count > 0 then
    self.mUICommandItem:ShowDeleteBtn(function()
      self:OnDeleteBtnClick()
    end)
  end
  self.mUICommandItem:ShowNew(self.mIsNew)
  self.mUICommandItem:EnableBtn(false)
end

function ActivityTourCommandRefreshDialog:OnDeleteBtnClick()
  if not self.mUICommandItem then
    return
  end
  local content = UIUtils.StringFormat(MonopolyUtil:GetMonopolyActivityHint(270167), self.mUICommandItem.mData.sold)
  MessageBox.Show(TableData.GetHintById(208), content, nil, function()
    self:CloseSelf(true)
  end)
end

function ActivityTourCommandRefreshDialog:ShowFadeIn(isReplace)
  self.mIsReplace = isReplace
  if isReplace then
    self.ui.mAnim_Root:ResetTrigger("FadeIn_02")
    self.ui.mAnim_Root:SetTrigger("FadeIn_02")
  else
    self.ui.mAnim_Root:ResetTrigger("FadeIn_01")
    self.ui.mAnim_Root:SetTrigger("FadeIn_01")
  end
end

function ActivityTourCommandRefreshDialog:ShowFadeOut()
  if self.mIsReplace then
    self.ui.mAnim_Root:SetTrigger("FadeOut_02")
  else
    self.ui.mAnim_Root:SetTrigger("FadeOut_01")
  end
end

function ActivityTourCommandRefreshDialog:OnRelease()
end

function ActivityTourCommandRefreshDialog:OnClose()
  if self.mUICommandItem then
    self.mUICommandItem:OnRelease(true)
  end
  self.mUICommandItem = nil
  self.mSlotIndex = nil
  if self.mUIReplaceCommandItem then
    self.mUIReplaceCommandItem:OnRelease(true)
  end
  self.mUIReplaceCommandItem = nil
  self:ReleaseTimers()
  self.mCallBack = nil
end

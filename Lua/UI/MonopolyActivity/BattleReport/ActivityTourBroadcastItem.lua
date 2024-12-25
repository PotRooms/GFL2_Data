require("UI.UIBaseCtrl")
require("UI.MonopolyActivity.ActivityTourGlobal")
ActivityTourBroadcastItem = class("ActivityTourBroadcastItem", UIBaseCtrl)
ActivityTourBroadcastItem.__index = ActivityTourBroadcastItem

function ActivityTourBroadcastItem:ctor()
  self.super.ctor(self)
end

function ActivityTourBroadcastItem:InitCtrl(itemPrefab, parent)
  local instObj = instantiate(itemPrefab, parent)
  self:SetRoot(instObj.transform)
  self.ui = {}
  self:LuaUIBindTable(instObj.transform, self.ui)
  self.ui.mAnim_Root.keepAnimatorControllerStateOnDisable = true
  self.mUiHeight = nil
  self.mIsShow = false
end

function ActivityTourBroadcastItem:SetData(data)
  self.mIsShow = true
  self.ui.mText_Info.text = data
  setactive(self.mUIRoot, true)
  self.ui.mLayoutElement_Root.minHeight = 0
  self.ui.mCG_Root.alpha = 0
  if self.mDelayTimer ~= nil then
    self.mDelayTimer:Stop()
    self.mDelayTimer = nil
  end
  self.mDelayTimer = TimerSys:DelayFrameCall(1, function()
    self.ui.mCG_Root.alpha = 1
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.ui.mTrans_Root)
    UIUtils.AnimatorFadeIn(self.ui.mAnim_Root)
    self.mUiHeight = self.ui.mTrans_Root.sizeDelta.y
    if self.mUiHeight == 0 then
      gfwarning("BattleReport UIHeight Is 0\239\188\154" .. self.ui.mText_Info.text .. ", Use Default Height")
      self.mUiHeight = ActivityTourGlobal.MinBattleReportHeight
    end
    self:TweenHeight(0, self.mUiHeight, ActivityTourGlobal.MaxBattleReportItemFadeTime, function()
      self.ui.mLayoutElement_Root.minHeight = self.mUiHeight
    end)
    self.mDelayTimer = nil
  end)
end

function ActivityTourBroadcastItem:ResetHeight()
  self:ReallyResetHeight(false)
  if self.mUiHeight > 0 then
    return
  end
  self.mDelayTimer = TimerSys:DelayFrameCall(1, function()
    self:ReallyResetHeight(true)
  end)
end

function ActivityTourBroadcastItem:ReallyResetHeight(isLog)
  if not self.mIsShow then
    return
  end
  self:ResetAllAnim()
  self.mUiHeight = self.ui.mTrans_Root.sizeDelta.y
  if self.mUiHeight == 0 then
    self.mUiHeight = ActivityTourGlobal.MinBattleReportHeight
    if isLog == true then
      gfwarning("BattleReport UIHeight Is 0\239\188\154" .. self.ui.mText_Info.text .. ", Use Default Height")
    end
  end
  self.ui.mLayoutElement_Root.minHeight = self.mUiHeight
end

function ActivityTourBroadcastItem:Hide(isAnim, onFinish)
  self.mIsShow = false
  if isAnim then
    UIUtils.AnimatorFadeOut(self.ui.mAnim_Root)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.ui.mTrans_Root)
    self:TweenHeight(self.mUiHeight, 0, ActivityTourGlobal.MaxBattleReportItemFadeTime, function()
      setactive(self.mUIRoot, false)
      if onFinish ~= nil then
        onFinish(self)
      end
    end)
    return
  end
  setactive(self.mUIRoot, false)
  if onFinish ~= nil then
    onFinish(self)
  end
end

function ActivityTourBroadcastItem:TweenHeight(currentHeight, maxHeight, fadeTime, callBack)
  self:ResetAllAnim()
  self.ui.mLayoutElement_Root.minHeight = currentHeight
  local getter = function(tempSelf)
    return tempSelf.ui.mLayoutElement_Root.minHeight
  end
  local setter = function(tempSelf, value)
    tempSelf.ui.mLayoutElement_Root.minHeight = value
  end
  self.mFadeTween = LuaDOTweenUtils.ToOfFloat(self, getter, setter, maxHeight, fadeTime, callBack, CS.DG.Tweening.Ease.OutQuad)
end

function ActivityTourBroadcastItem:ResetAllAnim()
  if self.mFadeTween ~= nil then
    LuaDOTweenUtils.Kill(self.mFadeTween, false)
    self.mFadeTween = nil
  end
  if self.mDelayTimer ~= nil then
    self.mDelayTimer:Stop()
    self.mDelayTimer = nil
  end
end

function ActivityTourBroadcastItem:OnRelease()
  self:ResetAllAnim()
  self.super.OnRelease(self, true)
end

require("UI.UIBaseCtrl")
UIActivityMultiSignInRewardItem = class("UIActivityMultiSignInRewardItem", UIBaseCtrl)
UIActivityMultiSignInRewardItem.__index = UIActivityMultiSignInRewardItem

function UIActivityMultiSignInRewardItem:ctor()
  self.UICommonItems = {}
  self.super.ctor(self)
end

function UIActivityMultiSignInRewardItem:InitCtrl(signInItem, itemPrefab, parent, onClick)
  local instObj = instantiate(itemPrefab, parent)
  self:SetRoot(instObj.transform)
  self.mOnClick = onClick
  self.ui = {}
  self:LuaUIBindTable(instObj.transform, self.ui)
  self.signInItem = signInItem
  UIUtils.GetButtonListener(self.ui.mBtn_SignIn.gameObject).onClick = function()
    if not NetCmdOperationActivityData:IsActivityOpen(self.mActivityId) then
      UIManager.CloseUI(UIDef.UIActivityDialog)
      UIUtils.PopupErrorWithHint(260007)
      return
    end
    if not self.mIsCanSign then
      TipsPanelHelper.OpenUITipsPanel(self.itemData)
      return
    end
    self.mOnClick(self.mDayIndex)
  end
end

function UIActivityMultiSignInRewardItem:SetData(activityId, rewardData, todayIsCheck, alreadyCheckDays)
  self.mActivityId = activityId
  self.mDayIndex = rewardData.days
  self.ui.mText_Day.text = UIUtils.StringFormat("{0:D2}", self.mDayIndex)
  local isAlreadySignIn = alreadyCheckDays >= self.mDayIndex
  self.mIsCanSign = not todayIsCheck and alreadyCheckDays + 1 == self.mDayIndex
  local isShowTomorrowCanGet = todayIsCheck and alreadyCheckDays + 1 == self.mDayIndex
  setactive(self.ui.mTrans_Normal, not isAlreadySignIn and not self.mIsCanSign and not isShowTomorrowCanGet)
  setactive(self.ui.mTrans_CompleteMask, isAlreadySignIn)
  setactive(self.ui.mTrans_AlreadySignIn, isAlreadySignIn)
  setactive(self.ui.mTrans_CanSignIn, self.mIsCanSign)
  setactive(self.ui.mTrans_TomorrowCanGet, isShowTomorrowCanGet)
  local isFirst = #self.UICommonItems == 0
  for i = 0, rewardData.rewards.Key.Count - 1 do
    local id = rewardData.rewards.Key[i]
    local count = rewardData.rewards.Value[i]
    local item
    if isFirst then
      item = UICommonItem.New()
      item:InitCtrl(self.ui.mTrans_Content)
      self.UICommonItems[i + 1] = item
    else
      item = self.UICommonItems[i + 1]
    end
    local itemData = TableData.GetItemData(id)
    item:SetItemByStcData(itemData, count)
    item:SetReceivedIcon(isAlreadySignIn)
    setactive(item.mUIRoot, not self.signInItem.firstInit)
  end
  if isFirst then
    if self.timer ~= nil then
      self.timer:Stop()
      self.timer = nil
    end
    if self.signInItem.firstInit then
      self.timer = TimerSys:DelayCall(0.5, function()
        for _, item in pairs(self.UICommonItems) do
          setactive(item.mUIRoot, true)
        end
        self.signInItem.firstInit = false
      end)
    else
      self.timer = TimerSys:DelayFrameCall(1, function()
        self.ui.mTrans_Content.transform.localPosition = Vector3(0, self.ui.mTrans_Content.transform.localPosition.y, self.ui.mTrans_Content.transform.localPosition.z)
      end)
    end
  end
end

function UIActivityMultiSignInRewardItem:ReleaseReward()
  self:ReleaseCtrlTable(self.UICommonItems, true)
  self.UICommonItems = {}
end

function UIActivityMultiSignInRewardItem:OnRelease()
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  self:ReleaseReward()
end

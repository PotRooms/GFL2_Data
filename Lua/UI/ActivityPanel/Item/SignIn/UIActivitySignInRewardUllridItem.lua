require("UI.UIBaseCtrl")
UIActivitySignInRewardUllridItem = class("UIActivitySignInRewardUllridItem", UIBaseCtrl)
UIActivitySignInRewardUllridItem.__index = UIActivitySignInRewardUllridItem

function UIActivitySignInRewardUllridItem:ctor()
  self.super.ctor(self)
end

function UIActivitySignInRewardUllridItem:InitCtrl(itemPrefab, parent, onClick)
  local instObj = instantiate(itemPrefab, parent)
  self:SetRoot(instObj.transform)
  self.mOnClick = onClick
  self.ui = {}
  self:LuaUIBindTable(instObj.transform, self.ui)
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

function UIActivitySignInRewardUllridItem:SetData(activityId, rewardData, todayIsCheck, alreadyCheckDays)
  self.mActivityId = activityId
  self.mDayIndex = rewardData.days
  local isAlreadySignIn = alreadyCheckDays >= self.mDayIndex
  self.mIsCanSign = not todayIsCheck and alreadyCheckDays + 1 == self.mDayIndex
  local isShowTomorrowCanGet = todayIsCheck and alreadyCheckDays + 1 == self.mDayIndex
  if self.mIsCanSign then
    self.ui.mAnimator_Root:SetInteger("Switch", 1)
  elseif isAlreadySignIn then
    self.ui.mAnimator_Root:SetInteger("Switch", 2)
  else
    self.ui.mAnimator_Root:SetInteger("Switch", 0)
  end
  setactive(self.ui.mTrans_TomorrowCanGet, isShowTomorrowCanGet)
  setactive(self.ui.mTrans_RedPoint, self.mIsCanSign)
  self.ui.mText_Day.text = self.mDayIndex
  local itemId, itemCount
  for i = 0, rewardData.rewards.Key.Count - 1 do
    itemId = rewardData.rewards.Key[i]
    itemCount = rewardData.rewards.Value[i]
    self.itemData = TableData.GetItemData(itemId)
  end
  if not itemId then
    print_cyan("SignIn Activity Reward CanNot Is NUll")
    return
  end
  self.ui.mImage_ItemIcon.sprite = UIUtils.GetItemIcon(itemId)
  self.ui.mText_ItemName.text = UIUtils.GetItemName(itemId)
  self.ui.mText_RewardCount.text = UIUtils.StringFormatWithHintId(260005, itemCount)
end

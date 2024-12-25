require("UI.UIBaseCtrl")
require("UI.ActivityPanel.Item.UIActivityItemBase")
require("UI.ActivityPanel.Item.CafeSignIn.UIActivityCafeSignInRewardItem")
UIActivityCafeSignInItem = class("UIActivityCafeSignInItem", UIActivityItemBase)
UIActivityCafeSignInItem.__index = UIActivityCafeSignInItem

function UIActivityCafeSignInItem:OnInit()
  self.mUIRewardList = {}
end

function UIActivityCafeSignInItem:OnShow()
  self.ui.mText_Name.text = self.mActivityTableData.name.str
  self.ui.mText_Time:StartCountdown(self.mCloseTime)
  self:RefreshList()
end

function UIActivityCafeSignInItem:RefreshList()
  local todayIsCheck, alreadyCheckDays = NetCmdOperationActivity_SignInData:GetSignData(self.mActivityID)
  local rewards = TableDataBase.listEventSigninRewardByActivityIdDatas:GetDataById(self.mActivityID).Id
  local currentDay = math.min(rewards.Count, alreadyCheckDays + 1)
  for i = 1, rewards.Count do
    local rewardId = rewards[i - 1]
    local rewardData = TableDataBase.listEventSigninRewardDatas:GetDataById(rewardId)
    local rewardItem = self.mUIRewardList[i]
    if not rewardItem then
      rewardItem = UIActivityCafeSignInRewardItem.New()
      rewardItem:InitCtrl(self.ui.mTrans_RewardList.childItem, self.ui.mTrans_RewardList.transform, function(dayIndex)
        self:OnClickSignIn()
      end)
      table.insert(self.mUIRewardList, rewardItem)
    end
    rewardItem:SetData(self.mActivityID, rewardData, todayIsCheck, alreadyCheckDays)
  end
  local gridLayoutGroup = self.ui.mTrans_RewardList.transform:GetComponent(typeof(CS.UnityEngine.UI.GridLayoutGroup))
  local offset = gridLayoutGroup.spacing.y + gridLayoutGroup.cellSize.y
  local moveY = math.min(offset * rewards.Count - self.ui.mTrans_RewardList.transform.parent.rect.height, offset * (currentDay - 1))
  LuaDOTweenUtils.DOAnchorPosY(self.ui.mTrans_RewardList.transform, moveY, 0.75)
end

function UIActivityCafeSignInItem:OnClickSignIn()
  NetCmdOperationActivity_SignInData:SignIn(self.mActivityID, function(ret)
    if ret == ErrorCodeSuc then
      UISystem:OpenCommonReceivePanel()
      TimerSys:DelayCall(0.5, function()
        self:RefreshList()
      end)
    end
  end)
end

function UIActivityCafeSignInItem:OnHide()
end

function UIActivityCafeSignInItem:OnTop()
end

function UIActivityCafeSignInItem:OnClose()
end

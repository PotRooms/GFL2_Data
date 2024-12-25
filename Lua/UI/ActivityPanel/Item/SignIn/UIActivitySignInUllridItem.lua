require("UI.UIBaseCtrl")
require("UI.ActivityPanel.Item.UIActivityItemBase")
require("UI.ActivityPanel.Item.SignIn.UIActivitySignInRewardUllridItem")
UIActivitySignInUllridItem = class("UIActivitySignInUllridItem", UIActivityItemBase)
UIActivitySignInUllridItem.__index = UIActivitySignInUllridItem

function UIActivitySignInUllridItem:OnInit()
  self.mUIRewardList = {}
end

function UIActivitySignInUllridItem:OnShow()
  self.ui.mText_Name.text = self.mActivityTableData.name.str
  self.ui.mText_Time:StartCountdown(self.mCloseTime)
  self:RefreshList()
end

function UIActivitySignInUllridItem:OnHide()
end

function UIActivitySignInUllridItem:RefreshList()
  local todayIsCheck, alreadyCheckDays = NetCmdOperationActivity_SignInData:GetSignData(self.mActivityID)
  local rewards = TableDataBase.listEventSigninRewardByActivityIdDatas:GetDataById(self.mActivityID).Id
  for i = 1, rewards.Count do
    local rewardId = rewards[i - 1]
    local rewardData = TableDataBase.listEventSigninRewardDatas:GetDataById(rewardId)
    local rewardItem = self.mUIRewardList[i]
    if not rewardItem then
      rewardItem = UIActivitySignInRewardUllridItem.New()
      rewardItem:InitCtrl(self.ui.mTrans_RewardList.childItem, self.ui.mTrans_RewardList.transform, function(dayIndex)
        self:OnClickSignIn()
      end)
      table.insert(self.mUIRewardList, rewardItem)
    end
    rewardItem:SetData(self.mActivityID, rewardData, todayIsCheck, alreadyCheckDays)
  end
  table.sort(self.mUIRewardList, function(a, b)
    return a.mDayIndex < b.mDayIndex
  end)
  for i = 1, #self.mUIRewardList do
    local item = self.mUIRewardList[i]
    if item and item.mUIRoot then
      item.mUIRoot:SetAsLastSibling()
    end
  end
end

function UIActivitySignInUllridItem:OnClickSignIn()
  NetCmdOperationActivity_SignInData:SignIn(self.mActivityID, function(ret)
    if ret == ErrorCodeSuc then
      UISystem:OpenCommonReceivePanel({
        nil,
        function()
          self:RefreshList()
        end
      })
    end
  end)
end

function UIActivitySignInUllridItem:OnTop()
end

function UIActivitySignInUllridItem:OnClose()
  self.resetScroll = true
end

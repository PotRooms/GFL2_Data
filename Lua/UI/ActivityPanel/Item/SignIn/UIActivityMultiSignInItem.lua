require("UI.UIBaseCtrl")
require("UI.ActivityPanel.Item.UIActivityItemBase")
require("UI.ActivityPanel.Item.SignIn.UIActivityMultiSignInRewardItem")
UIActivityMultiSignInItem = class("UIActivityMultiSignInItem", UIActivityItemBase)
UIActivityMultiSignInItem.__index = UIActivityMultiSignInItem

function UIActivityMultiSignInItem:OnInit()
  self.firstInit = true
  self.mUIRewardList = {}
end

function UIActivityMultiSignInItem:OnShow()
  self.ui.mText_Name.text = self.mActivityTableData.name.str
  self.ui.mText_Time:StartCountdown(self.mCloseTime)
  local signInData = TableData.listEventSigninDatas:GetDataById(self.mActivityID)
  if signInData ~= nil and signInData.activity_type == 0 and signInData.image ~= "" then
    self.ui.mImg_Bg.sprite = IconUtils.GetAtlasSprite("Activity/SignIn/" .. signInData.image)
  end
  self:RefreshList()
end

function UIActivityMultiSignInItem:RefreshList()
  local todayIsCheck, alreadyCheckDays = NetCmdOperationActivity_SignInData:GetSignData(self.mActivityID)
  local rewards = TableDataBase.listEventSigninRewardByActivityIdDatas:GetDataById(self.mActivityID).Id
  local currentDay = math.min(rewards.Count, alreadyCheckDays + 1)
  for i = 1, rewards.Count do
    local rewardId = rewards[i - 1]
    local rewardData = TableDataBase.listEventSigninRewardDatas:GetDataById(rewardId)
    local rewardItem = self.mUIRewardList[i]
    if not rewardItem then
      rewardItem = UIActivityMultiSignInRewardItem.New()
      rewardItem:InitCtrl(self, self.ui.mTrans_RewardList.childItem, self.ui.mTrans_RewardList.transform, function(dayIndex)
        self:OnClickSignIn()
      end)
      table.insert(self.mUIRewardList, rewardItem)
    end
    rewardItem:SetData(self.mActivityID, rewardData, todayIsCheck, alreadyCheckDays)
  end
  if self.moved == nil or not self.moved then
    local gridLayoutGroup = self.ui.mTrans_RewardList.transform:GetComponent(typeof(CS.UnityEngine.UI.GridLayoutGroup))
    local offset = gridLayoutGroup.spacing.y + gridLayoutGroup.cellSize.y
    local parentSize = LuaUtils.GetRectTransformSize(self.ui.mTrans_RewardList.transform.parent.gameObject)
    if offset * rewards.Count > parentSize.y then
      local moveY = math.min(offset * rewards.Count - parentSize.y, offset * (currentDay - 1))
      LuaDOTweenUtils.DOAnchorPosY(self.ui.mTrans_RewardList.transform, moveY, 0.75)
    end
    self.moved = true
  end
end

function UIActivityMultiSignInItem:OnClickSignIn()
  if self.blockClick then
    return
  end
  self.blockClick = true
  NetCmdOperationActivity_SignInData:SignIn(self.mActivityID, function(ret)
    self.blockClick = false
    if ret == ErrorCodeSuc then
      UISystem:OpenCommonReceivePanel()
      self.timer = TimerSys:DelayCall(0.5, function()
        self:RefreshList()
      end)
    end
  end)
end

function UIActivityMultiSignInItem:OnHide()
  self.blockClick = nil
  self.moved = nil
  for _, reward in pairs(self.mUIRewardList) do
    reward:ReleaseReward()
  end
end

function UIActivityMultiSignInItem:OnTop()
end

function UIActivityMultiSignInItem:OnClose()
  self.blockClick = nil
  self.moved = nil
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
end

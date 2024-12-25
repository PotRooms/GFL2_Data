require("UI.UIBaseCtrl")
local unavailable = 0
local available = 1
local claimed = 2
local pathAvailable = "Assets/_UI/UIRes/Atlas/Activity/Regress/Img_RegressActivityReward_IconBg_Sel"
local pathCommon = "Assets/_UI/UIRes/Atlas/Activity/Regress/Img_RegressActivityReward_IconBg_Now"
UIRegressActivityRewardItem = class("UIRegressActivityRewardItem", UIBaseCtrl)
UIRegressActivityRewardItem.__index = UIRegressActivityRewardItem

function UIRegressActivityRewardItem:__InitCtrl()
end

function UIRegressActivityRewardItem:InitCtrl(parent, child)
  local instObj = instantiate(child)
  CS.LuaUIUtils.SetParent(instObj.gameObject, parent.gameObject)
  self:SetRoot(instObj.transform)
  self.ui = {}
  self:LuaUIBindTable(self.mUIRoot, self.ui)
  self:__InitCtrl()
end

function UIRegressActivityRewardItem:SetData(itemData, count, day)
  self.itemData = itemData
  self.day = day
  self.ui.mText_Day.text = "D" .. day
  self.ui.mText_Num.text = count
  self.ui.mImg_Icon.sprite = IconUtils.GetItemIconSprite(itemData.id)
  self.ui.mImg_Quality.color = TableData.GetGlobalGun_Quality_Color2(itemData.rank)
end

function UIRegressActivityRewardItem:SetStatus()
  local click = UIUtils.GetButtonListener(self.ui.mBtn.gameObject)
  click.onClick = nil
  self.status = NetCmdActivityRegressData:GetDayStatus(self.day)
  if self.status == unavailable then
    UIUtils.GetButtonListener(self.ui.mBtn).onClick = function()
      local today = NetCmdActivityRegressData:GetActivityBackInfo().CheckinDays
      CS.PopupMessageManager.PopupString(string_format(TableData.GetHintById(260169), self.day - today))
    end
  else
    TipsManager.Add(self.ui.mBtn.gameObject, self.itemData)
  end
  TimerSys:DelayFrameCall(1, function()
    if self.status == available then
      self.ui.mAnim_Root:SetInteger("FinishState", 0)
    elseif self.status == unavailable then
      self.ui.mAnim_Root:SetInteger("FinishState", 3)
    elseif self.status == claimed then
      self.ui.mAnim_Root:SetInteger("FinishState", 2)
    end
  end)
  return self.status == available
end

function UIRegressActivityRewardItem:SendBackCheckIn()
  self.ui.mAnim_Root:SetInteger("FinishState", 1)
end

function UIRegressActivityRewardItem:OnRelease(isDestroy)
  self.itemData = nil
  self.super.OnRelease(self, isDestroy)
end

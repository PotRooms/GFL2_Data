require("UI.UIBaseCtrl")
require("UI.Common.UICommonItem")
local unavailable = 0
local available = 1
local finished = 2
UIRegressQuestItem = class("UIRegressQuestItem", UIBaseCtrl)
UIRegressQuestItem.__index = UIRegressQuestItem

function UIRegressQuestItem:__InitCtrl()
end

function UIRegressQuestItem:InitCtrl(parent, child)
  local instObj = instantiate(child)
  CS.LuaUIUtils.SetParent(instObj.gameObject, parent.gameObject)
  self:SetRoot(instObj.transform)
  self.ui = {}
  self:LuaUIBindTable(self.mUIRoot, self.ui)
  self:__InitCtrl()
  UIUtils.AddBtnClickListener(self.ui.mBtn_Goto.gameObject, function()
    if self.data.link ~= "" then
      UIActivityRegressItem.openQuest = true
      UISystem:JumpByID(tonumber(self.data.link))
    end
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Receive.gameObject, function()
    if self.data == nil then
      return
    end
    self:SendGetRegressReward()
  end)
end

function UIRegressQuestItem:SendGetRegressReward()
  NetCmdActivityRegressData:SendGetRegressReward(self.data.id, function(code)
  end)
end

function UIRegressQuestItem:SetData(data)
  self.data = data
  self.ui.mText_Title.text = data.name.str
  self.state = NetCmdActivityRegressData:GetTaskState(self.data.id)
  self:ClearRewards()
  self:SetRewards()
end

function UIRegressQuestItem:UpdateStateAndProgress()
  local progress = NetCmdActivityRegressData:GetTaskProgress(self.data.id)
  progress = math.min(progress, self.data.ConditionNum)
  self.ui.mText_Percent.text = progress .. "/" .. self.data.ConditionNum
  if self.state == unavailable then
    self.ui.mText_Percent.color = ColorUtils.StringToColor("1A2C33")
  else
    self.ui.mText_Percent.color = ColorUtils.StringToColor("F26C1C")
  end
  self.ui.mImg_ProgressBar.FillAmount = progress / self.data.ConditionNum
  self:SetState(self.state)
end

function UIRegressQuestItem:ClearRewards()
  if self.rewards == nil then
    return
  end
  for i = #self.rewards, 1, -1 do
    local item = self.rewards[i]
    item:OnRelease(true)
    table.remove(self.rewards, i)
  end
  self.rewards = nil
end

function UIRegressQuestItem:SetRewards()
  self.rewards = {}
  local rewards = self.data.reward
  local index = 1
  for id, count in pairs(rewards) do
    local item = UICommonItem.New()
    local itemContent = self.ui.mTrans_Item:Find("Trans_Empty" .. index)
    item:InitCtrl(itemContent)
    item:SetItemData(id, count)
    index = index + 1
    table.insert(self.rewards, item)
  end
end

function UIRegressQuestItem:SetState(state)
  self.state = state
  setactive(self.ui.mBtn_Receive, state == available)
  setactive(self.ui.mBtn_Goto, state == unavailable)
  setactive(self.ui.mTrans_Finished, state == finished)
  for _, item in ipairs(self.rewards) do
    item:SetReceivedIcon(state == finished)
  end
end

function UIRegressQuestItem:OnRelease()
  self:ClearRewards()
  gfdestroy(self.mUIRoot)
end

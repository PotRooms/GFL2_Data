require("UI.UIBaseCtrl")
require("UI.Common.UICommonItem")
UIActivityTreasureBpMissionItem = class("UIActivityTreasureBpMissionItem", UIBaseCtrl)
UIActivityTreasureBpMissionItem.__index = UIActivityTreasureBpMissionItem
local locked = 0
local available = 1
local received = 2

function UIActivityTreasureBpMissionItem:ctor()
end

function UIActivityTreasureBpMissionItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:InitCtrlWithNoInstantiate(instObj, false)
end

function UIActivityTreasureBpMissionItem:InitCtrlWithNoInstantiate(obj, setToZero)
  self:SetRoot(obj.transform)
  obj.transform.localPosition = vectorzero
  if setToZero == nil or setToZero then
    obj.transform.anchoredPosition = vector2zero
  else
    obj.transform.anchoredPosition = vector2one * 1000000
  end
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Receive, function()
    self:ClickReceive()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Goto, function()
    self:Goto()
  end)
end

function UIActivityTreasureBpMissionItem:ClickReceive()
  if CS.UIUtils.GetTouchClicked() then
    return
  end
  CS.UIUtils.SetTouchClicked()
  NetCmdActivityTreasureData:SendReceiveSingleMission(self.missionId, function(ret)
    if ret == ErrorCodeSuc then
      if self.hasReward then
        UISystem:OpenCommonReceivePanel({
          function()
            MessageSys:SendMessage(UIEvent.OnTreasureMissionComplete, nil)
          end
        })
        return
      end
      UIUtils.PopupPositiveHintMessage(260180)
      MessageSys:SendMessage(UIEvent.OnTreasureMissionComplete, nil)
    end
  end)
end

function UIActivityTreasureBpMissionItem:Goto()
  if CS.UIUtils.GetTouchClicked() then
    return
  end
  CS.UIUtils.SetTouchClicked()
  local data = TableData.listTreasureTaskDatas:GetDataById(self.missionId)
  if data and data.link ~= "" then
    UISystem:JumpByID(tonumber(data.link))
  end
end

function UIActivityTreasureBpMissionItem:SetData(missionId)
  self.missionId = missionId
  self:ClearRewards()
  local status = NetCmdActivityTreasureData:GetMissionStatus(self.missionId)
  local data = TableData.listTreasureTaskDatas:GetDataById(self.missionId)
  local counter = NetCmdActivityTreasureData:GetMissionProgress(self.missionId)
  self.rewardItems = {}
  local max = data.ConditionNum
  self.ui.mImg_Progress.fillAmount = status == received and 1 or counter / max
  self.ui.mText_Num.text = (status == received and max or counter) .. "/" .. max
  self.ui.mTex_Title.text = data.Name
  self.ui.mText_Content.text = data.Des
  self.ui.mText_Exp.text = string_format(TableData.GetHintById(260130), data.RewardExp)
  setactivewithcheck(self.ui.mBtn_Receive.gameObject, status == available)
  setactivewithcheck(self.ui.mBtn_Goto.gameObject, status == locked)
  setactivewithcheck(self.ui.mTrans_Finished.gameObject, status == received)
  if status == received then
    self.ui.mAnim_Finished.enabled = false
    self.ui.mCanvas_Finished.alpha = 1
  else
    self.ui.mAnim_Finished.enabled = true
    self.ui.mCanvas_Finished.alpha = 0
  end
  local rewards = data.RewardItem
  self.hasReward = false
  for id, count in pairs(rewards) do
    local item = UICommonItem.New()
    item:InitCtrl(self.ui.mTrans_Com)
    local itemData = TableData.GetItemData(id)
    item:SetItemByStcData(itemData, count)
    item:SetReceivedIcon(received == status)
    table.insert(self.rewardItems, item)
    self.hasReward = true
  end
  setactivewithcheck(self.ui.mTrans_Daily, data.type == 1)
end

function UIActivityTreasureBpMissionItem:ClearRewards()
  if self.rewardItems == nil then
    return
  end
  for i = #self.rewardItems, 1, -1 do
    local item = self.rewardItems[i]
    item:OnRelease(true)
    table.remove(self.rewardItems, i)
  end
  self.rewardItems = nil
end

function UIActivityTreasureBpMissionItem:OnRelease()
  self:ClearRewards()
  self.super.OnRelease(self, true)
end

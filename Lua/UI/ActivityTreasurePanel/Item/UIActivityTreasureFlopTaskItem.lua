require("UI.UIBaseCtrl")
UIActivityTreasureFlopTaskItem = class("UIActivityTreasureFlopTaskItem", UIBaseCtrl)
UIActivityTreasureFlopTaskItem.__index = UIActivityTreasureFlopTaskItem
local locked = 0
local available = 1
local received = 2

function UIActivityTreasureFlopTaskItem:ctor()
end

function UIActivityTreasureFlopTaskItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:InitCtrlWithNoInstantiate(instObj, false)
end

function UIActivityTreasureFlopTaskItem:InitCtrlWithNoInstantiate(obj, setToZero)
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
    self:Receive()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Goto, function()
    self:Goto()
  end)
end

function UIActivityTreasureFlopTaskItem:Receive()
  if CS.UIUtils.GetTouchClicked() then
    return
  end
  CS.UIUtils.SetTouchClicked()
  NetCmdActivityTreasureData:SendReceiveBingoMission(self.data.id, function(ret)
    if ret == ErrorCodeSuc and self.callback then
      self.callback()
    end
  end)
end

function UIActivityTreasureFlopTaskItem:Goto()
  if CS.UIUtils.GetTouchClicked() then
    return
  end
  CS.UIUtils.SetTouchClicked()
  if self.data.link ~= "" then
    UIActivityTreasureFlopItem.openDialog = true
    UISystem:JumpByID(tonumber(self.data.link))
  end
end

function UIActivityTreasureFlopTaskItem:SetData(data)
  self.data = data
  local status = NetCmdActivityTreasureData:GetBingoMissionStatus(self.data.id)
  local count = NetCmdActivityTreasureData:GetBingoMissionProgress(self.data.id)
  local totalCount = data.ConditionNum
  count = math.min(count, totalCount)
  self.ui.mText_Num.text = count .. "/" .. totalCount
  self.ui.mImg_Progress.FillAmount = count / totalCount
  self.ui.mText_Name.text = data.name.str
  setactivewithcheck(self.ui.mTrans_Daily, self.data.type == 1)
  self:InitRewards(status)
  self:InitStatus(status)
end

function UIActivityTreasureFlopTaskItem:SetCallback(callback)
  self.callback = callback
end

function UIActivityTreasureFlopTaskItem:InitRewards(status)
  self.rewardItem = {}
  local showData = UIUtils.GetKVSortItemTable(self.data.RewardItemSort)
  for _, data in pairs(showData) do
    local item = UICommonItem.New()
    item:InitCtrl(self.ui.mTrans_Com)
    item:SetItemData(data.id, data.num)
    item:SetReceivedIcon(received == status)
    table.insert(self.rewardItem, item)
  end
end

function UIActivityTreasureFlopTaskItem:InitStatus(status)
  setactivewithcheck(self.ui.mBtn_Receive, status == available)
  setactivewithcheck(self.ui.mTrans_Finished, status == received)
  setactivewithcheck(self.ui.mBtn_Goto, status == locked and self.data.link ~= "")
  setactivewithcheck(self.ui.mTrans_Unfinish, status == locked and self.data.link == "")
end

function UIActivityTreasureFlopTaskItem:ReleaseRewards()
  self:ReleaseCtrlTable(self.rewardItem, true)
end

function UIActivityTreasureFlopTaskItem:OnRelease(isDestroy)
  self.callback = nil
  self:ReleaseRewards()
  self.super.OnRelease(self, isDestroy)
end

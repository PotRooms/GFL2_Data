require("UI.ActivityTheme.Module.Bingo.ActivityBingoTaskItem")
UILennaBingoTaskItem = class("UILennaBingoTaskItem", ActivityBingoTaskItem)
UILennaBingoTaskItem.__index = UILennaBingoTaskItem
local unfinished = 0
local receive = 1
local finished = 2

function UILennaBingoTaskItem:ctor()
end

function UILennaBingoTaskItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:InitCtrlWithNoInstantiate(instObj, false)
end

function UILennaBingoTaskItem:InitCtrlWithNoInstantiate(obj, setToZero)
  self:SetRoot(obj.transform)
  obj.transform.localPosition = vectorzero
  if setToZero == nil or setToZero then
    obj.transform.anchoredPosition = vector2zero
  else
    obj.transform.anchoredPosition = vector2one * 1000000
  end
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Goto, function()
    self:Jump()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Receive, function()
    self:Receive()
  end)
end

function UILennaBingoTaskItem:SetData(data, activityId, bingoId)
  self.data = data
  setactivewithcheck(self:GetRoot(), true)
  for i = 0, data.RewardList.Length - 1 do
    local config = string.split(data.RewardList[i], ":")
    IconUtils.GetItemIconSpriteAsync(tonumber(config[1]), self.ui.mImg_Icon)
    self.ui.mText_Num.text = "\195\151" .. config[2]
    break
  end
  self.ui.mText_Goto.text = TableData.GetActivityHint(21011003, activityId, 2, 1011, bingoId)
  self.ui.mText_Receive.text = TableData.GetActivityHint(21011002, activityId, 2, 1011, bingoId)
  self.ui.mText_Finished.text = TableData.GetActivityHint(21011010, activityId, 2, 1011, bingoId)
  self:Refresh()
end

function UILennaBingoTaskItem:Refresh()
  self:RefreshProgress()
  self:RefreshStatus()
end

function UILennaBingoTaskItem:RefreshProgress()
  local name = self.data.Name
  local count = self.data.ConditionNum
  local progress = NetCmdActivityBingoData:GetBingoTaskProgress(self.data.id)
  self.ui.mText_Name.text = name .. "(" .. progress .. "/" .. count .. ")"
end

function UILennaBingoTaskItem:RefreshStatus()
  local status = NetCmdActivityBingoData:GetBingoTaskStatus(self.data.id)
  setactivewithcheck(self.ui.mTrans_Finished, status == finished)
  setactivewithcheck(self.ui.mBtn_Goto, status == unfinished)
  setactivewithcheck(self.ui.mBtn_Receive, status == receive)
end

function UILennaBingoTaskItem:Receive()
  NetCmdActivityBingoData:SendReceiveBingoTask(self.data.id, function(ret)
    if ret == ErrorCodeSuc then
      self:Refresh()
      UISystem:OpenCommonReceivePanel()
    end
  end)
end

function UILennaBingoTaskItem:Refresh()
  self:RefreshStatus()
  self:RefreshProgress()
end

function UILennaBingoTaskItem:Jump()
  if self.data.link ~= "" then
    UISystem:JumpByID(tonumber(self.data.link))
  end
end

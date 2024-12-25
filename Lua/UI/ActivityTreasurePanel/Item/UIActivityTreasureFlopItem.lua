require("UI.UIBaseCtrl")
UIActivityTreasureFlopItem = class("UIActivityTreasureFlopItem", UIBaseCtrl)
UIActivityTreasureFlopItem.__index = UIActivityTreasureFlopItem

function UIActivityTreasureFlopItem:ctor()
end

function UIActivityTreasureFlopItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:InitCtrlWithNoInstantiate(instObj, false)
end

function UIActivityTreasureFlopItem:InitCtrlWithNoInstantiate(obj, setToZero)
  self:SetRoot(obj.transform)
  obj.transform.localPosition = vectorzero
  if setToZero == nil or setToZero then
    obj.transform.anchoredPosition = vector2zero
  else
    obj.transform.anchoredPosition = vector2one * 1000000
  end
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
end

function UIActivityTreasureFlopItem:SetData(data)
  self.index = data.index
  self.gridX = data.x
  self.gridY = data.y
  local rewardId = NetCmdActivityTreasureData:GetBingoRewardStatus(UIActivityTreasureItem.id, self.index)
  if 0 < rewardId then
    local config = TableDataBase.listBingoRewardDatas:GetDataById(rewardId)
    for id, count in pairs(config.RewardItem) do
      self.id = id
      self.count = count
      self.ui.mImg_Icon.sprite = UIUtils.GetItemIcon(self.id)
      self.ui.mText_Num.text = "\195\151" .. self.count
      break
    end
    self.ui.mAnim_Root:SetInteger("Switch", 2)
  else
    self.ui.mAnim_Root:SetInteger("Switch", 0)
  end
  self:UpdateStatus(0 < rewardId, self.id)
end

function UIActivityTreasureFlopItem:UpdateStatus(received, rewardId)
  if received then
    local itemData = TableData.GetItemData(rewardId)
    UIUtils.GetButtonListener(self.ui.mBtn.gameObject).onClick = nil
    TipsManager.Add(self.ui.mBtn.gameObject, itemData)
  else
    UIUtils.AddBtnClickListener(self.ui.mBtn.gameObject, function()
      self:OnClick()
    end)
  end
end

function UIActivityTreasureFlopItem:OnClick()
  if CS.UIUtils.GetTouchClicked() then
    return
  end
  CS.UIUtils.SetTouchClicked()
  local enough = NetCmdActivityTreasureData:EnoughToGetBingoReward(UIActivityTreasureItem.id)
  if enough then
    NetCmdActivityTreasureData:SendReceiveReward(self.index, function(ret)
      if ret == ErrorCodeSuc then
        local rewardId = NetCmdActivityTreasureData:GetBingoRewardStatus(UIActivityTreasureItem.id, self.index)
        local config = TableDataBase.listBingoRewardDatas:GetDataById(rewardId)
        for id, count in pairs(config.RewardItem) do
          self.id = id
          self.count = count
          self.ui.mImg_Icon.sprite = UIUtils.GetItemIcon(self.id)
          self.ui.mText_Num.text = "\195\151" .. self.count
          break
        end
        MessageSys:SendMessage(UIEvent.OnTreasureRewardReceive, nil, {
          start = true,
          x = self.gridX,
          y = self.gridY
        })
        self.ui.mAnim_Root:SetInteger("Switch", 1)
        self:UpdateStatus(0 < rewardId, self.id)
        self.timer = TimerSys:DelayCall(1, function()
          UISystem:OpenCommonReceivePanel({
            function()
              MessageSys:SendMessage(UIEvent.OnTreasureRewardReceive, nil, {
                start = false,
                x = self.gridX,
                y = self.gridY
              })
            end
          })
        end)
      end
    end)
  else
    CS.PopupMessageManager.PopupString(TableData.GetHintById(260131))
  end
end

function UIActivityTreasureFlopItem:PlayLineEffect()
  self.ui.mAnim_Root:SetTrigger("Line")
end

function UIActivityTreasureFlopItem:GetReceiveStatus()
  return NetCmdActivityTreasureData:GetBingoRewardStatus(UIActivityTreasureItem.id, self.index) > 0
end

function UIActivityTreasureFlopItem:OnRelease()
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  self.super.OnRelease(self, true)
end

require("UI.UIBaseCtrl")
UIActivityTreasureFlopRewardItem = class("UIActivityTreasureFlopRewardItem", UIBaseCtrl)
UIActivityTreasureFlopRewardItem.__index = UIActivityTreasureFlopRewardItem
local horizontal = 1
local vertical = 2
local locked = 0
local available = 1
local received = 2

function UIActivityTreasureFlopRewardItem:ctor()
end

function UIActivityTreasureFlopRewardItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self:InitCtrlWithNoInstantiate(instObj, false)
end

function UIActivityTreasureFlopRewardItem:InitCtrlWithNoInstantiate(obj, setToZero)
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

function UIActivityTreasureFlopRewardItem:SetData(data)
  self.dir = data.dir
  self.index = data.index
  self.id = tonumber(data.id)
  self.count = data.count
  self.ui.mImg_Icon.sprite = UIUtils.GetItemIcon(self.id)
  self.ui.mImg_IconGlow.sprite = UIUtils.GetItemIcon(self.id)
  self.ui.mText_Num.text = "\195\151" .. self.count
  self:CheckReceived()
end

function UIActivityTreasureFlopRewardItem:CheckReceived(final)
  self.status = locked
  local isReceived = false
  if final then
    isReceived = NetCmdActivityTreasureData:GetFinalExtraRewardStatus(UIActivityTreasureItem.id)
  else
    isReceived = NetCmdActivityTreasureData:GetExtraRewardStatus(UIActivityTreasureItem.id, self.dir, self.index)
  end
  self.status = isReceived == true and received or locked
  setactivewithcheck(self.ui.mTrans_RedPoint.gameObject, false)
  if isReceived then
    self.ui.mAnim_Root:SetInteger("Switch", 4)
  else
    self.ui.mAnim_Root:SetInteger("Switch", 0)
  end
  local itemData = TableData.GetItemData(self.id)
  TipsManager.Add(self.ui.mBtn.gameObject, itemData)
end

function UIActivityTreasureFlopRewardItem:UpdateAvailable(isAvailable, trigger)
  if not isAvailable then
    return
  end
  self.status = available
  self.ui.mAnim_Root:SetInteger("Switch", trigger)
  setactivewithcheck(self.ui.mTrans_RedPoint.gameObject, isAvailable)
  UIUtils.GetButtonListener(self.ui.mBtn.gameObject).onClick = function()
    if CS.UIUtils.GetTouchClicked() then
      return
    end
    CS.UIUtils.SetTouchClicked()
    if self.clicking then
      return
    end
    NetCmdActivityTreasureData:SendReceiveExtraReward(self.dir, self.index, function(ret)
      if ret == ErrorCodeSuc then
        self.clicking = true
        NetCmdActivityTreasureData:DirtyRedPoint()
        NetCmdActivityTreasureData:UpdateExtraRewardState(UIActivityTreasureItem.id, self.dir, self.index)
        self.ui.mAnim_Root:SetInteger("Switch", 3)
        MessageSys:SendMessage(UIEvent.OnTreasureLineRewardReceive, nil, {start = true})
        self.timer = TimerSys:DelayCall(0.5, function()
          UISystem:OpenCommonReceivePanel({
            nil,
            function()
              MessageSys:SendMessage(UIEvent.OnTreasureLineRewardReceive, nil, {start = false})
              self.status = received
              setactivewithcheck(self.ui.mTrans_RedPoint.gameObject, self.status == available)
              local itemData = TableData.GetItemData(self.id)
              TipsManager.Add(self.ui.mBtn.gameObject, itemData)
              self.clicking = false
            end
          })
        end)
      end
    end)
  end
end

function UIActivityTreasureFlopRewardItem:SetFinalRewardData(id)
  local bingoId = TableDataBase.listTreasureMainDatas:GetDataById(id).BingoId
  local finalReward = TableDataBase.listBingoConfigDatas:GetDataById(bingoId).FullItem
  for itemId, itemCount in pairs(finalReward) do
    self.id = itemId
    self.count = itemCount
    self.dir = 3
    self.index = 0
    self.ui.mImg_Icon.sprite = UIUtils.GetItemIcon(self.id)
    self.ui.mImg_IconGlow.sprite = UIUtils.GetItemIcon(self.id)
    self.ui.mText_Num.text = "\195\151" .. self.count
    break
  end
  self:CheckReceived(true)
end

function UIActivityTreasureFlopRewardItem:Unlock(withAnim)
  if self.status == received then
    return
  end
  local trigger = withAnim and 1 or 2
  self:UpdateAvailable(true, trigger)
end

function UIActivityTreasureFlopRewardItem:OnRelease(isDestroy)
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  self.super.OnRelease(self, isDestroy)
end

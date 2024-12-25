require("UI.UIBaseCtrl")
require("UI.ActivityPanel.Item.UIActivityItemBase")
UIActivityReceiveStaminaItem = class("UIActivityReceiveStaminaItem", UIActivityItemBase)
UIActivityReceiveStaminaItem.__index = UIActivityReceiveStaminaItem

function UIActivityReceiveStaminaItem:OnInit()
end

function UIActivityReceiveStaminaItem:OnShow()
  self.ui.mText_Name.text = self.mActivityTableData.name.str
  self.ui.mText_Info.text = self.mActivityTableData.desc.str
  setactive(self.ui.mText_Time.transform.parent, self.mActivityTableData.permanent ~= 1)
  self.ui.mText_Time:StartCountdown(self.mCloseTime)
  self.scrollList = {
    self.ui.mScrollList_Stamina1,
    self.ui.mScrollList_Stamina2
  }
  self.itemList = self.itemList or {}
  if #self.itemList == 0 then
    if self.timer_1 ~= nil then
      self.timer_1:Stop()
      self.timer_1 = nil
    end
    if self.timer_2 ~= nil then
      self.timer_2:Stop()
      self.timer_2 = nil
    end
    self.timer_1 = TimerSys:DelayFrameCall(10, function()
      self:CreateStaminaItem(1)
    end)
    self.timer_2 = TimerSys:DelayFrameCall(13, function()
      self:CreateStaminaItem(2)
      if self.refreshTimer ~= nil then
        self.refreshTimer:Stop()
        self.refreshTimer = nil
      end
      self:OnRefreshText()
      self.refreshTimer = TimerSys:DelayCall(1, function()
        self:OnRefreshText()
      end, nil, -1)
    end)
  end
end

function UIActivityReceiveStaminaItem:CreateStaminaItem(index)
  local scrollList = self.scrollList[index]
  local obj = instantiate(scrollList.childItem, scrollList.transform)
  self.itemList[index] = obj
  self:RefreshItem(index)
end

function UIActivityReceiveStaminaItem:RefreshItem(index)
  local obj = self.itemList[index]
  if obj == nil then
    return
  end
  local isReceived = NetCmdActivityReceiveStaminaData:GetStaminaIsReceived(index)
  local currentTime = CGameTime:GetTimestamp()
  local receiveTime = NetCmdActivityReceiveStaminaData:GetStaminaReceiveStamp(index)
  local imgNormal = obj.transform:Find("Btn_Item/ImgNormal")
  local imgCan = obj.transform:Find("Btn_Item/ImgCan")
  local transMask = obj.transform:Find("Btn_Item/Trans_Mask")
  local transReceived = obj.transform:Find("Btn_Item/Trans_Received")
  local aniReceive = obj.transform:Find("Btn_Item/Trans_Received"):GetComponent(typeof(CS.UnityEngine.Animation))
  local txtLeftTime = obj.transform:Find("GrpState/Trans_LeftTime"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  local txtReceived = obj.transform:Find("GrpState/Trans_Received"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  local btnReceive = obj.transform:Find("GrpState/BtnReceive/Btn_Receive"):GetComponent(typeof(CS.UnityEngine.UI.GFButton))
  local txtTitle = obj.transform:Find("GrpTimeTip/Text_TimeTip"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  local txtNum = obj.transform:Find("Btn_Item/GrpNum/Text_Num"):GetComponent(typeof(CS.UnityEngine.UI.Text))
  local btnItem = obj.transform:Find("Btn_Item")
  UIUtils.GetButtonListener(btnReceive.gameObject).onClick = function()
    local staminaCount = NetCmdItemData:GetItemCountById(101)
    local maxStaminaLimit = TableData.listItemLimitDatas:GetDataById(101).max_limit
    local rewardNum = NetCmdActivityReceiveStaminaData:GetRewardCount(self.mActivityTableData.id, index)
    if rewardNum > maxStaminaLimit - staminaCount then
      local limitmsg = TableData.GetHintById(207)
      CS.PopupMessageManager.PopupString(limitmsg)
    else
      NetCmdActivityReceiveStaminaData:CSTakeActivityDailyFood(index, function(ret)
        if ret == ErrorCodeSuc then
          UISystem:OpenCommonReceivePanel({
            function()
              aniReceive:Play()
            end
          })
          if self.claimTimer ~= nil then
            self.claimTimer:Stop()
            self.claimTimer = nil
          end
          self.claimTimer = TimerSys:DelayCall(0.5, function()
            self:RefreshItem(index)
          end)
        end
      end)
    end
  end
  local itemData = TableData.GetItemData(101)
  TipsManager.Add(btnItem.gameObject, itemData)
  txtTitle.text = string_format(TableData.GetHintById(260166), NetCmdActivityReceiveStaminaData:GetReceiveTimeStr(self.mActivityTableData.id, index))
  txtNum.text = NetCmdActivityReceiveStaminaData:GetRewardCount(self.mActivityTableData.id, index)
  setactive(imgNormal, false)
  setactive(imgCan, false)
  setactive(transMask, false)
  setactive(transReceived, false)
  setactive(txtLeftTime, false)
  setactive(txtReceived, false)
  setactive(btnReceive.transform.parent, false)
  self.refreshData = self.refreshData or {}
  self.refreshData[index] = nil
  if currentTime < receiveTime then
    self.refreshData[index] = {txt = txtLeftTime, receiveTime = receiveTime}
    setactive(imgNormal, true)
    setactive(transMask, true)
    setactive(txtLeftTime, true)
  elseif isReceived then
    setactive(transReceived, true)
    setactive(txtReceived, true)
    setactive(transMask, true)
    setactive(imgNormal, true)
  else
    setactive(imgCan, true)
    setactive(btnReceive.transform.parent, true)
  end
  self:OnRefreshText()
end

function UIActivityReceiveStaminaItem:OnRefreshText()
  for index, data in pairs(self.refreshData) do
    if data ~= nil then
      local currentTime = CGameTime:GetTimestamp()
      local receiveTime = data.receiveTime
      if currentTime > receiveTime then
        self:RefreshItem(index)
      else
        data.txt.text = string_format(TableData.GetHintById(260164), CS.TimeUtils.GetLeftTimeHHMMSS(receiveTime))
      end
    end
  end
end

function UIActivityReceiveStaminaItem:OnHide()
  for _, obj in pairs(self.itemList) do
    gfdestroy(obj)
  end
  self.itemList = {}
  if self.refreshTimer ~= nil then
    self.refreshTimer:Stop()
    self.refreshTimer = nil
    self.refreshData = {}
  end
  if self.timer_1 ~= nil then
    self.timer_1:Stop()
    self.timer_1 = nil
  end
  if self.timer_2 ~= nil then
    self.timer_2:Stop()
    self.timer_2 = nil
  end
  if self.claimTimer ~= nil then
    self.claimTimer:Stop()
    self.claimTimer = nil
  end
end

function UIActivityReceiveStaminaItem:OnTop()
end

function UIActivityReceiveStaminaItem:OnClose()
  for _, obj in pairs(self.itemList) do
    gfdestroy(obj)
  end
  self.itemList = {}
  if self.refreshTimer ~= nil then
    self.refreshTimer:Stop()
    self.refreshTimer = nil
  end
end

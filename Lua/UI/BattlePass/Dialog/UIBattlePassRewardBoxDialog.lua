require("UI.MessageBox.MessageBoxPanel")
require("UI.BattlePass.UIBattlePassGlobal")
require("UI.BattlePass.Item.BpPassRewardBoxItem")
require("UI.Common.UICommonItem")
UIBattlePassRewardBoxDialog = class("UIBattlePassRewardBoxDialog", UIBasePanel)
UIBattlePassRewardBoxDialog.__index = UIBattlePassRewardBoxDialog

function UIBattlePassRewardBoxDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
  csPanel.UsePool = false
end

function UIBattlePassRewardBoxDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListen()
end

function UIBattlePassRewardBoxDialog:OnInit(root, data)
  self.mData = data
  self.mCurRewardTab = data[1]
  self.mCurSelectIndex = 1
  self.mShowItemsTab = {}
  self.mSelectPageIds = {}
  self.mSelectIds = {}
  self:ShowReceivedItems()
end

function UIBattlePassRewardBoxDialog:OnShowStart()
end

function UIBattlePassRewardBoxDialog:OnShowFinish()
end

function UIBattlePassRewardBoxDialog:OnClose()
  for _, item in pairs(self.mShowItemsTab) do
    item:OnRelease()
  end
end

function UIBattlePassRewardBoxDialog:OnRelease()
  self.ui = nil
  self.mData = nil
end

function UIBattlePassRewardBoxDialog:AddBtnListen()
  UIUtils.GetButtonListener(self.ui.mBtn_GrpClose.transform).onClick = function()
    UIManager.CloseUI(UIDef.UIBattlePassRewardBoxDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnCancel.transform).onClick = function()
    UIManager.CloseUI(UIDef.UIBattlePassRewardBoxDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnNext.transform).onClick = function()
    self:OnClickNext()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnConfirm.transform).onClick = function()
    self:OnClickConfirm()
  end
end

function UIBattlePassRewardBoxDialog:ShowReceivedItems()
  self.mCurIsBase = self.mCurRewardTab[2]
  self.mCurLevel = self.mCurRewardTab[3]
  self.mItemData = TableData.GetItemData(self.mCurRewardTab[1])
  if self.mItemData == nil then
    return
  end
  self.ui.mText_TitleText.text = self.mItemData.name.str
  local splitData = string.split(self.mItemData.ArgsStr, ";")
  self.mTotalNum = tonumber(splitData[1])
  local numText = "<color=#F0AF14>" .. self.mCurSelectIndex .. "</color>/" .. #self.mData
  self.ui.mText_Num.text = numText
  setactive(self.ui.mText_Num, 1 < #self.mData)
  self.ui.mText_Hint.text = string_format(TableData.GetHintById(192115), self.mTotalNum)
  local itemAndNumList = TableData.SpliteStrToItemAndNumList(splitData[2])
  for i = 1, #self.mShowItemsTab do
    setactive(self.mShowItemsTab[i].mUIRoot, false)
  end
  for i = 0, itemAndNumList.Count - 1 do
    local item = itemAndNumList[i]
    local boxItem = self.mShowItemsTab[i + 1]
    if boxItem == nil then
      boxItem = BpPassRewardBoxItem.New(self.ui.mSListChild_Content.transform)
      table.insert(self.mShowItemsTab, boxItem)
    end
    setactive(boxItem.mUIRoot, true)
    boxItem:SetData(i + 1, item.itemid, item.num)
    boxItem:AddBtnClickListener(function()
      self:OnClickItem(boxItem, self.mShowItemsTab)
    end)
  end
  local isLastSelectIndex = self.mCurSelectIndex == #self.mData
  setactive(self.ui.mBtn_BtnNext.transform.parent, not isLastSelectIndex)
  setactive(self.ui.mBtn_BtnConfirm.transform.parent, isLastSelectIndex)
end

function UIBattlePassRewardBoxDialog:OnClickItem(boxItem, allBoxItem)
  if boxItem.mIsSelect == true then
    boxItem.mIsSelect = not boxItem.mIsSelect
    self:RemoveSelect(boxItem.mItemId)
    boxItem:Refresh()
  elseif self.mTotalNum == 1 then
    self.mSelectIds = {}
    for i, v in pairs(allBoxItem) do
      v.mIsSelect = false
      v:Refresh()
    end
    table.insert(self.mSelectIds, boxItem.mItemId)
    boxItem.mIsSelect = true
    boxItem:Refresh()
  elseif #self.mSelectIds >= self.mTotalNum then
    CS.PopupMessageManager.PopupString(string_format(TableData.GetHintById(192115), self.mTotalNum))
    return
  else
    boxItem.mIsSelect = not boxItem.mIsSelect
    table.insert(self.mSelectIds, boxItem.mItemId)
    boxItem:Refresh()
  end
  local numText = "<color=#F0AF14>" .. self.mCurSelectIndex .. "</color>/" .. #self.mData
  self.ui.mText_Num.text = numText
end

function UIBattlePassRewardBoxDialog:RemoveSelect(index)
  for k, v in pairs(self.mSelectIds) do
    if v == index then
      table.remove(self.mSelectIds, k)
    end
  end
end

function UIBattlePassRewardBoxDialog:OnClickNext()
  if #self.mSelectIds < self.mTotalNum then
    local hint = TableData.GetHintById(192116)
    hint = string_format(hint, self.mTotalNum)
    CS.PopupMessageManager.PopupString(hint)
    return
  end
  local insertItem = {
    curLevel = self.mCurLevel,
    isBase = self.mCurIsBase,
    itemId = self.mItemData.id,
    selectIds = self.mSelectIds
  }
  table.insert(self.mSelectPageIds, insertItem)
  self.mSelectIds = {}
  self.mCurSelectIndex = self.mCurSelectIndex + 1
  self.mCurRewardTab = self.mData[self.mCurSelectIndex]
  self:ShowReceivedItems()
end

function UIBattlePassRewardBoxDialog:OnClickConfirm()
  if #self.mSelectIds < self.mTotalNum then
    local hint = TableData.GetHintById(192116)
    hint = string_format(hint, self.mTotalNum)
    CS.PopupMessageManager.PopupString(hint)
    return
  end
  if UIBattlePassGlobal.CurSelectType == UIBattlePassGlobal.SelectType.BpSingle or CS.UIBattlePassGlobal.CurSelectType == CS.EBpSelectType.BpSingle then
    self:BpConfirm()
  elseif UIBattlePassGlobal.CurSelectType == UIBattlePassGlobal.SelectType.BpOneKey or CS.UIBattlePassGlobal.CurSelectType == CS.EBpSelectType.BpOneKey then
    self:BpOneKeyConfirm()
  elseif UIBattlePassGlobal.CurSelectType == UIBattlePassGlobal.SelectType.MailSingle then
    self:MailConfirm()
  elseif UIBattlePassGlobal.CurSelectType == UIBattlePassGlobal.SelectType.MailReceiveAll then
    self:MailReceiveAllConfirm()
  end
end

function UIBattlePassRewardBoxDialog:BpConfirm()
  local otherTable = self:GetRewardsTab(self.mSelectIds)
  if TipsManager.CheckItemIsOverflowAndStopByList(otherTable) then
    return
  end
  local cmd = NetCmdBattlePassData:GetBattlepassRewardCmd()
  cmd.RewardLevel = self.mCurLevel
  if self.mCurIsBase == true then
    cmd.Type = CS.ProtoObject.BattlepassType.Base
    local giftPack = NetCmdBattlePassData:GetGiftPack()
    for k, v in pairs(self.mSelectIds) do
      giftPack.Selected:Add(v)
    end
    cmd.BaseOptional:Add(self.mCurLevel, giftPack)
  else
    cmd.Type = CS.ProtoObject.BattlepassType.AdvanceOne
    local giftPack = NetCmdBattlePassData:GetGiftPack()
    for k, v in pairs(self.mSelectIds) do
      giftPack.Selected:Add(v)
    end
    cmd.AdvanceOptional:Add(self.mCurLevel, giftPack)
  end
  NetCmdBattlePassData:SendGetBattlepassGiftReward(cmd, function(ret)
    if ret == ErrorCodeSuc then
      UISystem:OpenCommonReceivePanel({
        nil,
        function()
          MessageSys:SendMessage(UIEvent.BpGetReward, nil)
        end
      })
    end
  end)
  UIManager.CloseUI(UIDef.UIBattlePassRewardBoxDialog)
end

function UIBattlePassRewardBoxDialog:BpOneKeyConfirm()
  local insertItem = {
    curLevel = self.mCurLevel,
    isBase = self.mCurIsBase,
    itemId = self.mItemData.id,
    selectIds = self.mSelectIds
  }
  table.insert(self.mSelectPageIds, insertItem)
  local otherTable = self:GetRageRewardsTab(self.mSelectPageIds)
  if TipsManager.CheckItemIsOverflowAndStopByList(otherTable) then
    return
  end
  local cmd = NetCmdBattlePassData:GetBattlepassRewardCmd()
  cmd.Type = NetCmdBattlePassData.BattlePassStatus
  cmd.RewardType = CS.ProtoCsmsg.BpRewardGetType.GetTypeAll
  for i, v in pairs(self.mSelectPageIds) do
    if v.isBase == true then
      local giftPack = NetCmdBattlePassData:GetGiftPack()
      for k, j in pairs(v.selectIds) do
        giftPack.Selected:Add(j)
      end
      cmd.BaseOptional:Add(v.curLevel, giftPack)
    else
      local giftPack = NetCmdBattlePassData:GetGiftPack()
      for k, j in pairs(v.selectIds) do
        giftPack.Selected:Add(j)
      end
      cmd.AdvanceOptional:Add(v.curLevel, giftPack)
    end
  end
  NetCmdBattlePassData:SendGetBattlepassGiftReward(cmd, function(ret)
    if ret == ErrorCodeSuc then
      UISystem:OpenCommonReceivePanel({
        nil,
        function()
          MessageSys:SendMessage(UIEvent.BpGetReward, nil)
        end
      })
    end
  end)
  UIManager.CloseUI(UIDef.UIBattlePassRewardBoxDialog)
end

function UIBattlePassRewardBoxDialog:MailConfirm()
  local insertItem = {
    curLevel = self.mCurLevel,
    isBase = self.mCurIsBase,
    itemId = self.mItemData.id,
    selectIds = self.mSelectIds
  }
  table.insert(self.mSelectPageIds, insertItem)
  local otherTable = self:GetRageRewardsTab(self.mSelectPageIds)
  if TipsManager.CheckItemIsOverflowAndStopByList(otherTable) then
    return
  end
  local mailGiftPickMp = CS.ProtoObject.MailGiftPickMp()
  for i, v in pairs(self.mSelectPageIds) do
    local giftPack = NetCmdBattlePassData:GetGiftPack()
    for k, j in pairs(v.selectIds) do
      giftPack.Selected:Add(j)
    end
    if mailGiftPickMp.MailPick:TryGetValue(v.itemId) then
      mailGiftPickMp.MailPick[v.itemId].Pick:Add(giftPack)
    else
      local mailGiftPick = CS.ProtoObject.MailGiftPick()
      mailGiftPick.Pick:Add(giftPack)
      mailGiftPickMp.MailPick:Add(v.itemId, mailGiftPick)
    end
  end
  NetCmdMailData:SendReqRoleMailGetAttachmentCmd(UIBattlePassGlobal.MailId, mailGiftPickMp, function(ret)
    if UIBattlePassGlobal.FinishCallback ~= nil then
      UIBattlePassGlobal.FinishCallback(ret)
      UIBattlePassGlobal.FinishCallback = nil
    end
  end)
  UIManager.CloseUI(UIDef.UIBattlePassRewardBoxDialog)
end

function UIBattlePassRewardBoxDialog:GetRewardsTab(selectIds)
  local otherTable = {}
  for _, itemId in pairs(selectIds) do
    if otherTable[itemId] == nil then
      otherTable[itemId] = 1
    else
      otherTable[itemId] = otherTable[itemId] + 1
    end
  end
  return otherTable
end

function UIBattlePassRewardBoxDialog:GetRageRewardsTab(pages)
  local otherTable = {}
  for _, page in pairs(pages) do
    for _, itemId in pairs(page.selectIds) do
      if otherTable[itemId] == nil then
        otherTable[itemId] = 1
      else
        otherTable[itemId] = otherTable[itemId] + 1
      end
    end
  end
  return otherTable
end

function UIBattlePassRewardBoxDialog:MailReceiveAllConfirm()
end

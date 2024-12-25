require("UI.BattlePass.UIBattlePassGlobal")
UIBattlePassReceiveDialog = class("UIBattlePassReceiveDialog", UIBasePanel)
UIBattlePassReceiveDialog.__index = UIBattlePassReceiveDialog

function UIBattlePassReceiveDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIBattlePassReceiveDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListen()
end

function UIBattlePassReceiveDialog:OnInit(root, data)
  self.mBaseRewardItemsTab = {}
  self.mAdvanceRewardItemsTab = {}
  self.mBaseRewardTab = {}
  self.mAdvanceRewardTab = {}
  self.mExpRewardTab = {}
  self.ui.mText_Tip.text = string_format(TableData.GetHintById(192034), NetCmdBattlePassData.BattlePassLevel)
  self:GetRewardItems()
  self:ShowRewardGet()
end

function UIBattlePassReceiveDialog:OnShowStart()
end

function UIBattlePassReceiveDialog:OnShowFinish()
end

function UIBattlePassReceiveDialog:GetRewardItems()
  local status = NetCmdBattlePassData.BattlePassStatus
  self.mIsBase = status == CS.ProtoObject.BattlepassType.Base
  for level = NetCmdBattlePassData.BattlePassLevel, 1, -1 do
    if NetCmdBattlePassData:CheckHasReward(true, level) == false then
      local levelReward = TableData.listBpRewardDescDatas:GetDataById(NetCmdBattlePassData.CurSeason.reward_id * 1000 + level, true)
      if levelReward ~= nil then
        for k, v in pairs(levelReward.base_reward) do
          self:RewardItemTabHasContain(self.mBaseRewardTab, k, v)
        end
      end
    end
    if NetCmdBattlePassData:CheckHasReward(false, level) == false then
      local levelReward = TableData.listBpRewardDescDatas:GetDataById(NetCmdBattlePassData.CurSeason.reward_id * 1000 + level, true)
      if levelReward ~= nil then
        for k, v in pairs(levelReward.advanced_reward) do
          self:RewardItemTabHasContain(self.mAdvanceRewardTab, k, v)
        end
      end
    end
  end
  local specailRewardNum = math.floor(NetCmdBattlePassData.BattlePassOverflowExp / NetCmdBattlePassData.CurSeason.upgrade_exp)
  if 1 <= specailRewardNum then
    for item_id, item_num in pairs(NetCmdBattlePassData.CurSeason.extra_reward) do
      self:RewardItemTabHasContain(self.mExpRewardTab, item_id, item_num * specailRewardNum)
    end
    self.ui.mText_Tip.text = string_format(TableData.GetHintById(192079), NetCmdBattlePassData.BattlePassOverflowExp)
  end
  setactive(self.ui.mTrans_PaidRewardRoot, self.mIsBase == true)
end

function UIBattlePassReceiveDialog:ShowRewardGet()
  local index = 1
  for k, v in pairs(self.mExpRewardTab) do
    local rewardItem = self.mBaseRewardItemsTab[k]
    if rewardItem == nil then
      rewardItem = UICommonItem.New()
      rewardItem:InitCtrl(self.ui.mSListChild_Content, true)
      table.insert(self.mBaseRewardItemsTab, rewardItem)
    end
    index = index + 1
    rewardItem:SetItemData(v.itemId, v.itemNum)
    local itemTabData = TableData.GetItemData(v.itemId)
    local isShowEffect = itemTabData.type == GlobalConfig.ItemType.GiftPick
    rewardItem:SetRewardEffect(isShowEffect)
  end
  for k, v in pairs(self.mBaseRewardTab) do
    local rewardItem = self.mBaseRewardItemsTab[k + index]
    if rewardItem == nil then
      rewardItem = UICommonItem.New()
      rewardItem:InitCtrl(self.ui.mSListChild_Content, true)
      table.insert(self.mBaseRewardItemsTab, rewardItem)
    end
    index = index + 1
    rewardItem:SetItemData(v.itemId, v.itemNum)
    local itemTabData = TableData.GetItemData(v.itemId)
    local isShowEffect = itemTabData.type == GlobalConfig.ItemType.GiftPick
    rewardItem:SetRewardEffect(isShowEffect)
  end
  for k, v in pairs(self.mAdvanceRewardTab) do
    local rewardItem = self.mAdvanceRewardItemsTab[k]
    if rewardItem == nil then
      rewardItem = UICommonItem.New()
      if self.mIsBase == true then
        rewardItem:InitCtrl(self.ui.mSListChild_Content1, true)
        table.insert(self.mAdvanceRewardItemsTab, rewardItem)
      else
        rewardItem:InitCtrl(self.ui.mSListChild_Content, true)
        table.insert(self.mAdvanceRewardItemsTab, rewardItem)
      end
      rewardItem:SetItemData(v.itemId, v.itemNum)
      local itemTabData = TableData.GetItemData(v.itemId)
      local isShowEffect = itemTabData.type == GlobalConfig.ItemType.GiftPick
      rewardItem:SetRewardEffect(isShowEffect)
    end
  end
end

function UIBattlePassReceiveDialog:RewardItemTabHasContain(rewardItemTab, itemId, itemNum)
  local tempValue = 0
  for key, value in pairs(rewardItemTab) do
    if value.itemId == itemId then
      tempValue = value.itemNum
      value.itemNum = tempValue + itemNum
      rewardItemTab[key] = value
    end
  end
  if tempValue == 0 then
    local insertItem = {itemId = itemId, itemNum = itemNum}
    table.insert(rewardItemTab, insertItem)
  end
end

function UIBattlePassReceiveDialog:MoveAsset()
end

function UIBattlePassReceiveDialog:OnConfirm()
  self.mSelectBaseReward = {}
  self.mSelectAdvanceReward = {}
  UIBattlePassGlobal.CheckSelectReward(self.mSelectBaseReward, self.mSelectAdvanceReward)
  if Length(self.mSelectBaseReward) > 0 then
    local paramData = {}
    UIBattlePassGlobal.CurSelectType = UIBattlePassGlobal.SelectType.BpOneKey
    for i, v in pairs(self.mSelectBaseReward) do
      local tabData = {
        v,
        true,
        i
      }
      table.insert(paramData, tabData)
    end
    UIManager.CloseUI(UIDef.UIBattlePassReceiveDialog)
    UIManager.OpenUIByParam(UIDef.UIBattlePassRewardBoxDialog, paramData)
    return
  end
  NetCmdBattlePassData:SendGetBattlepassReward(NetCmdBattlePassData.BattlePassStatus, 0, CS.ProtoCsmsg.BpRewardGetType.GetTypeAll, function()
    UISystem:OpenCommonReceivePanel({
      nil,
      function()
        MessageSys:SendMessage(UIEvent.BpGetReward, nil)
      end
    })
  end)
  UIManager.CloseUI(UIDef.UIBattlePassReceiveDialog)
  MessageSys:SendMessage(UIEvent.BpGetReward, nil)
end

function UIBattlePassReceiveDialog:OnClose()
  for _, item in pairs(self.mBaseRewardItemsTab) do
    gfdestroy(item:GetRoot())
  end
  for _, item in pairs(self.mAdvanceRewardItemsTab) do
    gfdestroy(item:GetRoot())
  end
end

function UIBattlePassReceiveDialog:OnRelease()
  self.ui = nil
  self.mData = nil
end

function UIBattlePassReceiveDialog:AddBtnListen()
  UIUtils.GetButtonListener(self.ui.mBtn_Close.transform).onClick = function()
    UIManager.CloseUI(UIDef.UIBattlePassReceiveDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnCancel.transform).onClick = function()
    UIManager.CloseUI(UIDef.UIBattlePassReceiveDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpClose.transform).onClick = function()
    UIManager.CloseUI(UIDef.UIBattlePassReceiveDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnConfirm.transform).onClick = function()
    self:OnConfirm()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Unlock.transform).onClick = function()
    UIManager.OpenUI(UIDef.UIBattlePassUnlockPanel)
    self:MoveAsset()
  end
end

require("UI.Common.UICommonItem")
require("UI.Common.UIBpItem")
require("UI.UIBaseCtrl")
require("UI.BattlePass.UIBattlePassGlobal")
BpMainRewardListItem = class("BpMainRewardListItem", UIBaseCtrl)
BpMainRewardListItem.__index = BpMainRewardListItem

function BpMainRewardListItem:ctor(prefab, parent)
  self.obj = prefab
  self:Init()
end

function BpMainRewardListItem:__InitCtrl()
end

function BpMainRewardListItem:InitCtrl(parent)
  self.obj = instantiate(UIUtils.GetGizmosPrefab("BattlePass/BpMainRewardListItemV3.prefab", self))
  if parent then
    CS.LuaUIUtils.SetParent(self.obj.gameObject, parent.gameObject, false)
  end
  self:Init()
end

function BpMainRewardListItem:Init()
  self.ui = {}
  self:LuaUIBindTable(self.obj, self.ui)
  self:SetRoot(self.obj.transform)
  self:__InitCtrl()
  
  function self.OnBpGetReward()
    if not CS.LuaUtils.IsNullOrDestroyed(self.obj) then
      self:SetData(self.mCurLevel - 1, 0)
    end
  end
  
  function self.OnBPScrollRefresh()
    if not CS.LuaUtils.IsNullOrDestroyed(self.obj) then
      self:SetData(self.mCurLevel - 1, 0)
    end
  end
  
  function self.OnBpPromt2()
    if self.mCurLevel <= NetCmdBattlePassData.CurSeason.max_level then
      TimerSys:DelayCall((self.mCurLevel - (UIBattlePassGlobal.CurMaxItemIndex - 10)) * 0.05, function()
        if not CS.LuaUtils.IsNullOrDestroyed(self.mPaidItemView:GetRoot()) then
          self.mPaidItemView:SetAniFadein()
        end
      end)
    end
  end
  
  function self.OnRefreshAddExp()
    if not CS.LuaUtils.IsNullOrDestroyed(self.ui.mText_Consume) and self.mCurLevel > NetCmdBattlePassData.CurSeason.max_level then
      self:ExtraGroup()
    end
  end
  
  MessageSys:AddListener(UIEvent.BPScrollRefresh, self.OnBPScrollRefresh)
  MessageSys:AddListener(UIEvent.BpGetReward, self.OnBpGetReward)
  MessageSys:AddListener(UIEvent.BpExpRefreah, self.OnRefreshAddExp)
  MessageSys:AddListener(UIEvent.BpPromt2, self.OnBpPromt2)
end

function BpMainRewardListItem:SetData(index, level)
  self.mCurLevel = index + 1
  local seasonId = NetCmdBattlePassData.BattlePassId
  local seasonData = TableData.listBpSeasonDatas:GetDataById(seasonId)
  if seasonData == nil then
    return
  end
  self.mSeasonData = seasonData
  if self.mIsLoadItem == nil or self.mIsLoadItem == false then
    if self.mNormalItemView == nil then
      TimerSys:DelayFrameCall(UIBattlePassGlobal.TempItemIndex - 2, function()
        if self.ui ~= nil and LuaUtils.IsNullOrDestroyed(self.ui.mSListChild_GrpItem) == false then
          self.mNormalItemView = UIBpItem.New()
          self.mNormalItemView:InitCtrl(self.ui.mSListChild_GrpItem, true)
          self.mNormalItemView:SetRedPointAni(false)
          self:RefreshItem(self.mSeasonData)
        end
      end)
    end
    if self.mPaidItemView == nil then
      TimerSys:DelayFrameCall(UIBattlePassGlobal.TempItemIndex - 2, function()
        if self.ui ~= nil and LuaUtils.IsNullOrDestroyed(self.ui.mSListChild_GrpItem1) == false then
          self.mPaidItemView = UIBpItem.New()
          self.mPaidItemView:InitCtrl(self.ui.mSListChild_GrpItem1, true)
          self.mPaidItemView:SetRedPointAni(false)
          self:RefreshItem(self.mSeasonData)
        end
      end)
    end
    UIBattlePassGlobal.TempItemIndex = UIBattlePassGlobal.TempItemIndex + 1
    self.mIsLoadItem = true
  end
  setactive(self.ui.Trans_NormalRoot, true)
  self:RefreshItem(seasonData)
end

function BpMainRewardListItem:RefreshItem(seasonData)
  if seasonData ~= nil then
    if self.mCurLevel <= seasonData.max_level then
      self:NormalGroup()
    else
      self:ExtraGroup()
    end
  end
end

function BpMainRewardListItem:NormalGroup()
  local seasonId = NetCmdBattlePassData.BattlePassId
  local seasonData = TableData.listBpSeasonDatas:GetDataById(seasonId)
  if seasonData == nil then
    return
  end
  local curSeasonRewardId = seasonData.reward_id
  local bpRewardData = TableData.listBpRewardDescDatas:GetDataById(curSeasonRewardId * 1000 + self.mCurLevel)
  if bpRewardData == nil then
    return
  end
  self.ui.mAni_Root:SetBool("CurrentLevel", NetCmdBattlePassData.Reward.Count == self.mCurLevel)
  self.ui.mText_Num.text = string.format("%02d", tostring(self.mCurLevel))
  local hasRewardLevelInfo = NetCmdBattlePassData.Reward:TryGetValue(self.mCurLevel)
  if self.mNormalItemView ~= nil then
    for item_id, item_num in pairs(bpRewardData.base_reward) do
      local isGet = NetCmdBattlePassData:CheckHasReward(true, self.mCurLevel)
      self.mNormalItemView:SetItemData(item_id, item_num, false, false, item_num, nil, nil, function(tempItem)
        self:OnClickItem(tempItem, true, hasRewardLevelInfo, isGet)
      end, nil, true)
      local itemData = TableData.GetItemData(item_id)
      local isShowEffect = itemData.type == GlobalConfig.ItemType.GiftPick
      self.mNormalItemView:SetRewardEffect(isShowEffect)
      self.mNormalItemView:SetRedPoint(false)
      if hasRewardLevelInfo == true then
        self.mNormalItemView:SetRedPoint(isGet == false)
      else
        self.mNormalItemView:SetLock(true)
        self.mNormalItemView:SetLockColor()
      end
      self.mNormalItemView:SetRedPointAni(false)
      self.mNormalItemView:SetReceivedIcon(isGet)
    end
  end
  local status = NetCmdBattlePassData.BattlePassStatus
  if self.mPaidItemView ~= nil then
    for item_id, item_num in pairs(bpRewardData.advanced_reward) do
      local isGet = NetCmdBattlePassData:CheckHasReward(false, self.mCurLevel)
      local hasPaidRewardLevelInfo = hasRewardLevelInfo == true and status ~= CS.ProtoObject.BattlepassType.Base
      self.mPaidItemView:SetItemData(item_id, item_num, false, false, item_num, nil, nil, function(tempItem)
        self:OnClickItem(tempItem, false, hasPaidRewardLevelInfo, isGet)
      end, nil, true)
      local itemData = TableData.GetItemData(item_id)
      local isShowEffect = itemData.type == GlobalConfig.ItemType.GiftPick
      self.mPaidItemView:SetRedPoint(false)
      self.mPaidItemView:SetRewardEffect(isShowEffect)
      if hasPaidRewardLevelInfo then
        self.mPaidItemView:SetRedPoint(isGet == false)
      else
        self.mPaidItemView:SetLock(true)
        self.mPaidItemView:SetLockColor()
      end
      self.mPaidItemView:SetRedPointAni(false)
      self.mPaidItemView:SetReceivedIcon(isGet)
    end
  end
  setactive(self.ui.mTrans_Empty, bpRewardData.base_reward.Count == 0)
  if self.mNormalItemView ~= nil then
    setactive(self.mNormalItemView:GetRoot(), bpRewardData.base_reward.Count ~= 0)
  end
  setactive(self.ui.mTrans_ConsumeExp, false)
end

function BpMainRewardListItem:ExtraGroup()
  local seasonId = NetCmdBattlePassData.BattlePassId
  local seasonData = TableData.listBpSeasonDatas:GetDataById(seasonId)
  if seasonData == nil then
    return
  end
  setactive(self.ui.mTrans_ConsumeExp, NetCmdBattlePassData.CurSeason.max_level == NetCmdBattlePassData.BattlePassLevel)
  setactive(self.ui.Trans_NormalRoot, false)
  self.ui.mText_Consume.text = NetCmdBattlePassData.BattlePassOverflowExp .. "/" .. NetCmdBattlePassData.CurSeason.upgrade_exp
  self.ui.mText_Num.text = TableData.GetHintById(192004)
  if self.mPaidItemView ~= nil then
    for item_id, item_num in pairs(seasonData.extra_reward) do
      local itemNum = NetCmdBattlePassData.BattlePassOverflowExp / NetCmdBattlePassData.CurSeason.upgrade_exp
      itemNum = math.floor(itemNum)
      itemNum = itemNum ~= 0 and itemNum or nil
      self.mPaidItemView:SetItemData(item_id, itemNum, false, false, itemNum, nil, nil, function(tempItem)
        self:OnClickExtraItem(tempItem, item_id)
      end, nil, true)
      self.mPaidItemView:SetLock(NetCmdBattlePassData.BattlePassLevel < seasonData.max_level)
      self.mPaidItemView:SetLockColor()
      self.mPaidItemView:SetReceivedIcon(false)
      self.mPaidItemView:SetRedPoint(NetCmdBattlePassData.BattlePassOverflowExp / seasonData.upgrade_exp >= 1)
      self.mPaidItemView:SetRewardEffect(false)
    end
  end
end

function BpMainRewardListItem:SetInteractable(interactable)
end

function BpMainRewardListItem:OnClickItem(tempItem, isBase, isUnLock, isGet)
  local itemData = TableData.GetItemData(tempItem.itemId)
  if isUnLock == false or isGet == true then
    TipsPanelHelper.OpenUITipsPanel(itemData)
    return
  end
  if itemData.type == GlobalConfig.ItemType.GiftPick then
    local tabData = {
      tempItem.itemId,
      isBase,
      self.mCurLevel
    }
    UIBattlePassGlobal.CurSelectType = UIBattlePassGlobal.SelectType.BpSingle
    local paramData = {tabData}
    UIManager.OpenUIByParam(UIDef.UIBattlePassRewardBoxDialog, paramData)
    return
  end
  if isBase == true then
    NetCmdBattlePassData:SendGetBattlepassReward(CS.ProtoObject.BattlepassType.Base, self.mCurLevel, CS.ProtoCsmsg.BpRewardGetType.GetTypeNone, function(ret)
      if ret == ErrorCodeSuc then
        UISystem:OpenCommonReceivePanel()
        TimerSys:DelayCall(0.5, function()
          MessageSys:SendMessage(UIEvent.BpGetReward, nil)
        end)
      end
    end)
  else
    NetCmdBattlePassData:SendGetBattlepassReward(NetCmdBattlePassData.BattlePassStatus, self.mCurLevel, CS.ProtoCsmsg.BpRewardGetType.GetTypeNone, function(ret)
      if ret == ErrorCodeSuc then
        UISystem:OpenCommonReceivePanel()
        TimerSys:DelayCall(0.5, function()
          MessageSys:SendMessage(UIEvent.BpGetReward, nil)
        end)
      end
    end)
  end
end

function BpMainRewardListItem:OnClickExtraItem(tempItem, item_id)
  local seasonId = NetCmdBattlePassData.BattlePassId
  local seasonData = TableData.listBpSeasonDatas:GetDataById(seasonId)
  if seasonData == nil then
    return
  end
  if NetCmdBattlePassData.BattlePassOverflowExp / seasonData.upgrade_exp >= 1 then
    NetCmdBattlePassData:SendGetBattlepassReward(NetCmdBattlePassData.BattlePassStatus, self.mCurLevel, CS.ProtoCsmsg.BpRewardGetType.GetTypeExtra, function()
      UISystem:OpenCommonReceivePanel()
      MessageSys:SendMessage(UIEvent.BpGetReward, nil)
      MessageSys:SendMessage(UIEvent.BpResfresh, nil)
    end)
  else
    local stcData = TableData.GetItemData(item_id)
    TipsPanelHelper.OpenUITipsPanel(stcData)
  end
end

function BpMainRewardListItem:OnRelease()
  self.super.OnRelease(self, true)
  MessageSys:RemoveListener(UIEvent.BpGetReward, self.OnBpGetReward)
  MessageSys:RemoveListener(UIEvent.BPScrollRefresh, self.OnBPScrollRefresh)
  MessageSys:RemoveListener(UIEvent.BpPromt2, self.OnBpPromt2)
  MessageSys:RemoveListener(UIEvent.BpExpRefreah, self.OnRefreshAddExp)
end

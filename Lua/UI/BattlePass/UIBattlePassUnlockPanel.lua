require("UI.BattlePass.Item.BpUnlockRewardItem")
require("UI.BattlePass.UIBattlePassGlobal")
require("UI.UIBasePanel")
UIBattlePassUnlockPanel = class("UIBattlePassUnlockPanel", UIBasePanel)
UIBattlePassUnlockPanel.__index = UIBattlePassUnlockPanel

function UIBattlePassUnlockPanel:ctor(csPanel)
  UIBattlePassUnlockPanel.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
  self.mCSPanel = csPanel
  csPanel.Is3DPanel = true
end

function UIBattlePassUnlockPanel:OnAwake(root, data)
  self:SetRoot(root)
end

function UIBattlePassUnlockPanel:OnInit(root, data)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  UIUtils.GetButtonListener(self.ui.mBtn_BtnBack.transform).onClick = function()
    self:Close()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnHome.gameObject).onClick = function()
    self:OnCommanderCenter()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnCostBuy.gameObject).onClick = function()
    NetCmdBattlePassData:SendBattlePassExpStoreBuy(CS.ProtoObject.BattlepassType.AdvanceOne, function(ret)
      if CS.UnityEngine.Application.isEditor and ret ~= ErrorCodeSuc then
        return
      end
      if CS.UnityEngine.Application.isEditor == false and ret ~= 0 then
        return
      end
      local topUI = UISystem:GetTopUI(UIGroupType.Default)
      if topUI ~= nil and topUI.UIDefine.UIType ~= UIDef.UIBattlePassUnlockPanel then
        return
      end
      if self.ui == nil then
        return
      end
      TimerSys:DelayCall(0.7, function()
        local hint = TableData.GetHintById(106013)
        CS.PopupMessageManager.PopupPositiveString(hint)
      end)
      self:RefreshBuyBtnStatus()
      self:Close()
      MessageSys:SendMessage(UIEvent.BpGetReward, nil)
      MessageSys:SendMessage(UIEvent.BPScrollRefresh, nil)
      UIBattlePassGlobal.BpBuyPromote2 = true
    end)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnCostBuy1.gameObject).onClick = function()
    local beforeType = NetCmdBattlePassData.BattlePassStatus
    NetCmdBattlePassData:SendBattlePassExpStoreBuy(CS.ProtoObject.BattlepassType.AdvanceTwo, function(ret)
      if CS.UnityEngine.Application.isEditor and ret ~= ErrorCodeSuc then
        return
      end
      if CS.UnityEngine.Application.isEditor == false and ret ~= 0 then
        return
      end
      local topUI = UISystem:GetTopUI(UIGroupType.Default)
      if topUI ~= nil and topUI.UIDefine.UIType ~= UIDef.UIBattlePassUnlockPanel then
        return
      end
      if self.ui == nil then
        return
      end
      TimerSys:DelayCall(0.7, function()
        local hint = TableData.GetHintById(106013)
        CS.PopupMessageManager.PopupPositiveString(hint)
      end)
      self:RefreshBuyBtnStatus()
      UISystem:OpenCommonReceivePanel({
        function()
          MessageSys:SendMessage(UIEvent.BpResfresh, nil)
          MessageSys:SendMessage(UIEvent.BpGetReward, nil)
          MessageSys:SendMessage(UIEvent.BPScrollRefresh, nil)
          if beforeType ~= CS.ProtoObject.BattlepassType.AdvanceOne then
            UIBattlePassGlobal.BpBuyPromote2 = true
          end
          self:Close()
        end
      })
    end)
  end
  self:RegistrationKeyboard(KeyCode.Escape, self.ui.mBtn_BtnBack)
end

function UIBattlePassUnlockPanel:OnShowStart()
  UIBattlePassGlobal.BpMainPanelBlackTime = 0
  self:ShowInfo()
end

function UIBattlePassUnlockPanel:OnCameraStart()
  UISystem:SetMainCamera(false)
  return 0
end

function UIBattlePassUnlockPanel:OnCameraBack()
  return 0
end

function UIBattlePassUnlockPanel:OnShowFinish()
  if UIBattlePassGlobal.EffectNumObj ~= nil then
    setactive(UIBattlePassGlobal.EffectNumObj, true)
  end
  if UIBattlePassGlobal.ShowModel ~= nil then
    UIBattlePassGlobal.ShowModel:Show(true)
  end
  UIBattlePassGlobal.UnlockPanelBlackTime = 0.1
  UIBattlePassGlobal.BpShowSourceType = UIBattlePassGlobal.BpShowSource.UnlockPanel
  SceneSys:SwitchVisible(EnumSceneType.BattlePass)
  setactive(self.ui.mSListChild_Content, true)
  setactive(self.ui.mSListChild_Content1, true)
end

function UIBattlePassUnlockPanel:ShowInfo()
  self.mNormalUnlockBpReward = {}
  self.mPlusUnlockBpReward = {}
  self.mNormalUnlockBpRewardItems = {}
  self.mNormalUnlockBpRewardGrpItems = {}
  self.mPlusUnlockBpRewardItems = {}
  local seasonId = NetCmdBattlePassData.BattlePassId
  local seasonData = TableData.listBpSeasonDatas:GetDataById(seasonId)
  if seasonData == nil then
    return
  end
  local battlePassPlan = NetCmdSimulateBattleData:GetPlanByType(CS.GF2.Data.PlanType.PlanFunctionBattlepass)
  if battlePassPlan == nil then
    return
  end
  self.ui.mText_Name.text = seasonData.advanced1_name
  local status = NetCmdBattlePassData.BattlePassStatus
  if status == CS.ProtoObject.BattlepassType.AdvanceOne then
    self.ui.mText_PlusName.text = seasonData.levelup_advanced2_name
  else
    self.ui.mText_PlusName.text = seasonData.advanced2_name
  end
  local openTime = CS.CGameTime.ConvertLongToDateTime(battlePassPlan.OpenTime):ToString("yyyy/MM/dd")
  local closeTime = CS.CGameTime.ConvertLongToDateTime(battlePassPlan.CloseTime):ToString("yyyy/MM/dd")
  self.ui.mText_Time.text = string_format(TableData.GetHintById(192036), openTime, closeTime)
  self:ShowReward()
  self:RefreshBuyBtnStatus()
end

function UIBattlePassUnlockPanel:RefreshBuyBtnStatus()
  local status = NetCmdBattlePassData.BattlePassStatus
  setactive(self.ui.mTrans_Unlocked, status == CS.ProtoObject.BattlepassType.AdvanceOne or status == CS.ProtoObject.BattlepassType.AdvanceTwo)
  setactive(self.ui.mTrans_Unlocked1, status == CS.ProtoObject.BattlepassType.AdvanceTwo)
  setactive(self.ui.mTrans_BtnCostBuy, status == CS.ProtoObject.BattlepassType.Base or status == CS.ProtoObject.BattlepassType.None)
  setactive(self.ui.mTrans_BtnCostBuy1, status ~= CS.ProtoObject.BattlepassType.AdvanceTwo)
end

function UIBattlePassUnlockPanel:ShowReward()
  local baseStoreGoodData = TableData.listStoreGoodDatas:GetDataById(TableData.GlobalConfigData.BattlepassBase)
  if baseStoreGoodData ~= nil then
    self.ui.mText_CostNum.text = TableData.GetHintById(192037) .. string.format("%.2f", baseStoreGoodData.price)
  end
  local status = NetCmdBattlePassData.BattlePassStatus
  if status == CS.ProtoObject.BattlepassType.AdvanceOne then
    local plusStoreGoodData = TableData.listStoreGoodDatas:GetDataById(TableData.GlobalConfigData.BattlepassUpgradation)
    if plusStoreGoodData ~= nil then
      self.ui.mText_CostNum1.text = TableData.GetHintById(192037) .. string.format("%.2f", plusStoreGoodData.price)
    end
  else
    local plusStoreGoodData = TableData.listStoreGoodDatas:GetDataById(TableData.GlobalConfigData.BattlepassSenior)
    if plusStoreGoodData ~= nil then
      self.ui.mText_CostNum1.text = TableData.GetHintById(192037) .. string.format("%.2f", plusStoreGoodData.price)
    end
  end
  local bpUnlockRewardDatas = TableData.GetBpUnlockRewardByGroupId(NetCmdBattlePassData.CurSeason.Id)
  for i = 0, bpUnlockRewardDatas.Count - 1 do
    local bpUnlockRewardData = bpUnlockRewardDatas[i]
    if bpUnlockRewardData.reward_id == UIBattlePassGlobal.BpUnlockType.Normal then
      table.insert(self.mNormalUnlockBpReward, bpUnlockRewardData)
    else
      table.insert(self.mPlusUnlockBpReward, bpUnlockRewardData)
    end
  end
  setactive(self.ui.mSListChild_Content, false)
  setactive(self.ui.mSListChild_Content1, false)
  self.mAdvanceRewardTab = {}
  for i = NetCmdBattlePassData.CurSeason.max_level, 1, -1 do
    local levelReward = TableData.listBpRewardDescDatas:GetDataById(NetCmdBattlePassData.CurSeason.reward_id * 1000 + i, true)
    if levelReward ~= nil then
      for k, v in pairs(levelReward.advanced_reward) do
        UIBattlePassGlobal.RewardItemTabHasContain(self.mAdvanceRewardTab, k, v)
      end
    end
  end
  for i, item in pairs(self.mAdvanceRewardTab) do
    local bpUnlockRewardItem = UICommonItem.New()
    bpUnlockRewardItem:InitCtrl(self.ui.mSListChild_Content)
    bpUnlockRewardItem:SetItemData(item.itemId, item.itemNum)
    local itemTabData = TableData.GetItemData(item.itemId)
    local isShowEffect = itemTabData.type == GlobalConfig.ItemType.GiftPick
    bpUnlockRewardItem:SetRewardEffect(isShowEffect)
    table.insert(self.mNormalUnlockBpRewardItems, bpUnlockRewardItem)
  end
  for i, item in pairs(self.mPlusUnlockBpReward) do
    local bpUnlockRewardData = self.mPlusUnlockBpReward[i]
    if bpUnlockRewardData.item_display ~= 0 then
      local bpUnlockRewardItem = UICommonItem.New()
      bpUnlockRewardItem:InitCtrl(self.ui.mSListChild_Content1)
      for k, v in pairs(bpUnlockRewardData.item_id) do
        bpUnlockRewardItem:SetItemData(k, v)
      end
      table.insert(self.mPlusUnlockBpRewardItems, bpUnlockRewardItem)
    end
  end
  setactive(self.ui.mTrans_instItem, false)
end

function UIBattlePassUnlockPanel:OnUpdate()
end

function UIBattlePassUnlockPanel:Close()
  UIManager.CloseUISelf(self)
end

function UIBattlePassUnlockPanel:OnClose()
  self.ui = nil
  for _, item in pairs(self.mNormalUnlockBpRewardItems) do
    gfdestroy(item:GetRoot())
  end
  for _, item in pairs(self.mPlusUnlockBpRewardItems) do
    gfdestroy(item:GetRoot())
  end
  for _, item in pairs(self.mNormalUnlockBpRewardGrpItems) do
    gfdestroy(item)
  end
  MessageSys:SendMessage(UIEvent.BpResfresh, nil)
  self:UnRegistrationAllKeyboard()
  if UIBattlePassGlobal.EffectNumObj ~= nil then
    setactive(UIBattlePassGlobal.EffectNumObj, false)
  end
  if UIBattlePassGlobal.ShowModel ~= nil and UIBattlePassGlobal.IsBpOutSide == UIBattlePassGlobal.BpOutSideType.bpOutSide then
    UIBattlePassGlobal.ShowModel:Show(false)
  end
end

function UIBattlePassUnlockPanel:OnCommanderCenter()
  UISystem:JumpToMainPanel()
end

function UIBattlePassUnlockPanel:TempFun(temp1, temp2)
end

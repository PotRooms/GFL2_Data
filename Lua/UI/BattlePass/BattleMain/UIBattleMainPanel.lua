require("UI.BattlePass.UIBattlePassGlobal")
require("UI.BattlePass.Item.BpMainRewardListItem")
UIBattleMainPanel = class("UIBattleMainPanel", UIBaseCtrl)
UIBattleMainPanel.__index = UIBattleMainPanel

function UIBattleMainPanel:ctor()
  self.itemList = {}
end

function UIBattleMainPanel:__InitCtrl()
end

function UIBattleMainPanel:InitCtrl(prefab, parent)
  self.obj = instantiate(prefab, parent)
  self:SetRoot(self.obj.transform)
  self.ui = {}
  self:LuaUIBindTable(self.obj, self.ui)
  self:__InitCtrl()
  setactive(self.obj, false)
  UIUtils.GetButtonListener(self.ui.mBtn_Unlock.transform).onClick = function()
    UIManager.OpenUI(UIDef.UIBattlePassUnlockPanel)
    self:MoveAsset()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Promote.transform).onClick = function()
    UIManager.OpenUI(UIDef.UIBattlePassUnlockPanel)
    self:MoveAsset()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Add.transform).onClick = function()
    UIManager.OpenUI(UIDef.UIBattlePassBoughtDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GetAll.transform).onClick = function()
    self.mSelectBaseReward = {}
    self.mSelectAdvanceReward = {}
    UIBattlePassGlobal.CheckSelectReward(self.mSelectBaseReward, self.mSelectAdvanceReward)
    if NetCmdBattlePassData.BattlePassStatus == CS.ProtoObject.BattlepassType.Base then
      UIManager.OpenUI(UIDef.UIBattlePassReceiveDialog)
    else
      if Length(self.mSelectBaseReward) > 0 or Length(self.mSelectAdvanceReward) > 0 then
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
        for i, v in pairs(self.mSelectAdvanceReward) do
          local tabData = {
            v,
            false,
            i
          }
          table.insert(paramData, tabData)
        end
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
    end
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Paid.transform).onClick = function()
    UIManager.OpenUI(UIDef.UIBattlePassUnlockPanel)
    self:MoveAsset()
  end
  self.virtualList = self.ui.mVList_GrpRightList
  
  function self.virtualList.itemCreated(renderData)
    local item = self:ItemProvider(renderData)
    return item
  end
  
  function self.virtualList.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
  
  function self.OnLayoutDone(gos)
    UIBattlePassGlobal.TempItemIndex = 0
  end
  
  self.virtualList:onLayoutDone("+", self.OnLayoutDone)
  self.mOldIndex = 0
  self.mNewIndex = 0
  self.mIsRise = true
  self.mMaxIndex = 0
  
  function self.OnBattlePassLevelUp()
    setactive(self.ui.mBtn_GetAll.gameObject, NetCmdBattlePassData.CanOneKeyReceive)
    self:RefreshExp()
  end
  
  function self.OnBpGetReward()
    self:RefreshSpecial(self.mIndex)
    setactive(self.ui.mBtn_GetAll.gameObject, NetCmdBattlePassData.CanOneKeyReceive)
    if NetCmdBattlePassData.CurSeason.max_level ~= NetCmdBattlePassData.BattlePassLevel then
      if NetCmdBattlePassData.BattlePassOldExp < NetCmdBattlePassData.CurSeason.upgrade_exp then
        CS.UITweenManager.PlayImageFillAmount(self.ui.mImg_ExpBar, NetCmdBattlePassData.BattlePassOldExp / NetCmdBattlePassData.CurSeason.upgrade_exp, NetCmdBattlePassData.BattlePassOverflowExp / NetCmdBattlePassData.CurSeason.upgrade_exp, 0.5, 1, function()
          NetCmdBattlePassData.BattlePassOldExp = NetCmdBattlePassData.BattlePassOverflowExp
        end)
      else
        self:RefreshExp()
      end
    else
      self:RefreshExp()
    end
  end
  
  function self.OnBPScrollRefresh()
    if self.virtualList == nil then
      return
    end
    self.virtualList.numItems = NetCmdBattlePassData.CurSeason.max_level + 1
    self:RefreshSpecial(self.mIndex)
    self:RefreshExp()
    self.virtualList:ScrollTo(NetCmdBattlePassData.BattlePassLevel - 3, true)
  end
  
  MessageSys:AddListener(UIEvent.BattlePassLevelUp, self.OnBattlePassLevelUp)
  MessageSys:AddListener(UIEvent.BpGetReward, self.OnBpGetReward)
  MessageSys:AddListener(UIEvent.BPScrollRefresh, self.OnBPScrollRefresh)
end

function UIBattleMainPanel:SetData(data)
end

function UIBattleMainPanel:Show()
  local battlePassPlan = NetCmdSimulateBattleData:GetPlanByType(CS.GF2.Data.PlanType.PlanFunctionBattlepass)
  if battlePassPlan == nil then
    return
  end
  local seasonId = NetCmdBattlePassData.BattlePassId
  local seasonData = TableData.listBpSeasonDatas:GetDataById(seasonId)
  if seasonData == nil then
    return
  end
  RedPointSystem:GetInstance():UpdateRedPointByType(RedPointConst.BattlePass)
  RedPointSystem:GetInstance():UpdateRedPointByType(RedPointConst.BattlePassMain)
  self.mCurPlanOverTime = battlePassPlan.CloseTime
  self:RefreshExp()
  self.ui.mText_Name.text = seasonData.name.str
  if UIBattlePassGlobal.BpMainpanelRefreshType.FristShow == UIBattlePassGlobal.CurBpMainpanelRefreshType then
    self.virtualList.numItems = seasonData.max_level + 1
  end
  local toNum = NetCmdBattlePassData.BattlePassLevel == seasonData.max_level and NetCmdBattlePassData.BattlePassLevel or NetCmdBattlePassData.BattlePassLevel - 3
  if NetCmdBattlePassData.BattlePassLevel == seasonData.max_level then
    local isGetBase = NetCmdBattlePassData:CheckHasReward(false, NetCmdBattlePassData.BattlePassLevel)
    local isGetPlus = NetCmdBattlePassData:CheckHasReward(true, NetCmdBattlePassData.BattlePassLevel)
    if isGetBase == true and isGetPlus == true then
      toNum = NetCmdBattlePassData.BattlePassLevel + 1
    end
  end
  toNum = math.max(toNum, 0)
  toNum = math.min(NetCmdBattlePassData.CurSeason.max_level, toNum)
  toNum = FormatNum(toNum)
  if UIBattlePassGlobal.BpMainpanelRefreshType.FristShow == UIBattlePassGlobal.CurBpMainpanelRefreshType or UIBattlePassGlobal.BpMainpanelRefreshType.ClickTab == UIBattlePassGlobal.CurBpMainpanelRefreshType or UIBattlePassGlobal.BpMainpanelRefreshType.OnTop == UIBattlePassGlobal.CurBpMainpanelRefreshType then
    self.virtualList:ScrollTo(toNum, false)
    if UIBattlePassGlobal.CurBpMainpanelRefreshType == UIBattlePassGlobal.BpMainpanelRefreshType.FristShow then
      UIBattlePassGlobal.CurBpMainpanelRefreshType = UIBattlePassGlobal.BpMainpanelRefreshType.None
    end
  end
  local status = NetCmdBattlePassData.BattlePassStatus
  setactive(self.ui.mTrans_GrpLocked, status == CS.ProtoObject.BattlepassType.Base)
  setactive(self.ui.mBtn_Promote.gameObject, status == CS.ProtoObject.BattlepassType.AdvanceOne)
  setactive(self.ui.mBtn_Unlock.gameObject, status == CS.ProtoObject.BattlepassType.Base)
  setactive(self.ui.mBtn_GetAll.gameObject, NetCmdBattlePassData.CanOneKeyReceive)
  self.ui.mBtn_Paid.interactable = status == CS.ProtoObject.BattlepassType.Base
end

function UIBattleMainPanel:OnRefresh()
  self:Show(false)
end

function UIBattleMainPanel:OnBackFrom()
  self:Show(false)
  setactive(self.ui.mSListChild_Content, false)
  setactive(self.ui.mSListChild_Content, true)
end

function UIBattleMainPanel:OnUpdate()
  if self.ui ~= nil and self.ui.mText_LastTime ~= nil and CS.LuaUtils.IsNullOrDestroyed(self.ui.mText_LastTime) == false then
    local timeStr = CS.TimeUtils.GetLeftTime(self.mCurPlanOverTime)
    if timeStr == "" then
      self.ui.mText_LastTime.text = TableData.GetHintById(192120)
    else
      self.ui.mText_LastTime.text = string_format(TableData.GetHintById(192026), timeStr)
    end
  end
end

function UIBattleMainPanel:EnterPanelRefreshScroll()
end

function UIBattleMainPanel:RefreshExp()
  self.ui.mText_ExpHint.text = TableData.GetHintById(192087)
  setactive(self.ui.mText_Exp, true)
  local expText = "<color=#F0AF14>" .. NetCmdBattlePassData.BattlePassOverflowExp .. "</color>/" .. NetCmdBattlePassData.CurSeason.upgrade_exp
  self.ui.mText_Exp.text = expText
  self.ui.mImg_ExpBar.fillAmount = NetCmdBattlePassData.BattlePassOverflowExp / NetCmdBattlePassData.CurSeason.upgrade_exp
  if NetCmdBattlePassData.BattlePassLevel == NetCmdBattlePassData.CurSeason.max_level then
    self.ui.mText_ExpHint.text = TableData.GetHintById(102224)
    setactive(self.ui.mText_Exp, false)
    self.ui.mImg_ExpBar.fillAmount = 1
  end
  if NetCmdBattlePassData.BattlePassLevel > 0 then
    self.ui.mText_Lv.text = TableData.GetHintById(192088) .. string.format("%02d", tostring(NetCmdBattlePassData.BattlePassLevel))
  else
    self.ui.mText_Lv.text = TableData.GetHintById(192088) .. NetCmdBattlePassData.BattlePassLevel
  end
  NetCmdBattlePassData.BattlePassOldExp = NetCmdBattlePassData.BattlePassOverflowExp
end

function UIBattleMainPanel:ItemProvider(renderData)
  local itemView = BpMainRewardListItem.New(renderData)
  renderData.data = itemView
end

function UIBattleMainPanel:ItemRenderer(index, renderData)
  local item = renderData.data
  item:SetData(index, 1)
  self.mNewIndex = tonumber(index)
  self.mIsRise = self.mNewIndex > self.mOldIndex and true or false
  self:SetSpecialReward(index)
  self.mOldIndex = tonumber(index)
end

function UIBattleMainPanel:SetSpecialReward(index)
  local showMaxLevel = 0
  if self.mIsRise then
    showMaxLevel = self.mNewIndex
  else
    showMaxLevel = self.mNewIndex + self.ui.mSListChild_Content.transform.childCount - 1
  end
  UIBattlePassGlobal.CurMaxItemIndex = showMaxLevel
  self.mSpecialRewardData = TableData.listBpRewardDescDatas:GetDataById(NetCmdBattlePassData.CurSeason.reward_id * 1000 + showMaxLevel, true)
  while (self.mSpecialRewardData == nil or self.mSpecialRewardData ~= nil and self.mSpecialRewardData.type_reward == 1) and showMaxLevel <= NetCmdBattlePassData.CurSeason.max_level do
    showMaxLevel = showMaxLevel + 1
    self.mSpecialRewardData = TableData.listBpRewardDescDatas:GetDataById(NetCmdBattlePassData.CurSeason.reward_id * 1000 + showMaxLevel)
  end
  self.mShowMaxLevel = showMaxLevel
  if self.mShowMaxLevel > NetCmdBattlePassData.CurSeason.max_level then
    self.mShowMaxLevel = NetCmdBattlePassData.CurSeason.max_level
    self.mSpecialRewardData = TableData.listBpRewardDescDatas:GetDataById(NetCmdBattlePassData.CurSeason.reward_id * 1000 + self.mShowMaxLevel, true)
  end
  setactive(self.ui.mTrans_SpecailRewardRoot, true)
  self:RefreshSpecial(index)
end

function UIBattleMainPanel:RefreshSpecial(index)
  if index == nil then
    return
  end
  self.mIndex = index
  local showMaxLevel = self.mShowMaxLevel
  if index >= NetCmdBattlePassData.CurSeason.max_level - 2 then
    setactive(self.ui.mTrans_SpecailRewardRoot, false)
  end
  local bpRewardData = TableData.listBpRewardDescDatas:GetDataById(NetCmdBattlePassData.CurSeason.reward_id * 1000 + showMaxLevel)
  if bpRewardData == nil then
    return
  end
  local isShowEffect = bpRewardData.special_effects_reward == "1"
  self.ui.mText_Num.text = string_format(TableData.GetHintById(80057), string.format("%02d", tostring(showMaxLevel)))
  local SetRewardItem = function(parent, itemView, reward, isBase)
    if itemView == nil then
      itemView = UIBpItem.New()
      itemView:InitCtrl(parent, true)
    end
    local status = NetCmdBattlePassData.BattlePassStatus
    local hasRewardLevelInfo = NetCmdBattlePassData.Reward:TryGetValue(showMaxLevel)
    local isGet = NetCmdBattlePassData:CheckHasReward(isBase, showMaxLevel)
    for item_id, item_num in pairs(reward) do
      if isBase == false then
        hasRewardLevelInfo = hasRewardLevelInfo == true and status ~= CS.ProtoObject.BattlepassType.Base
      end
      itemView:SetItemData(item_id, item_num, false, false, item_num, nil, nil, function(tempItem)
        self:OnClickItem(tempItem, isBase, hasRewardLevelInfo, isGet)
      end, nil, true)
      itemView:SetRedPoint(false)
      if hasRewardLevelInfo == true then
        itemView:SetRedPoint(isGet == false)
      else
        itemView:SetLock(true)
        itemView:SetLockColor()
      end
      itemView:SetRewardEffect(isShowEffect)
      itemView:SetReceivedIcon(isGet)
      itemView:SetRedPointAni(false)
    end
    return itemView
  end
  if self.mSpecialRewardData ~= nil then
    self.mNormalItemView = SetRewardItem(self.ui.mSListChild_GrpItem, self.mNormalItemView, self.mSpecialRewardData.base_reward, true)
    self.mPaidItemView = SetRewardItem(self.ui.mSListChild_GrpItem1, self.mPaidItemView, self.mSpecialRewardData.advanced_reward, false)
  end
end

function UIBattleMainPanel:OnClickItem(tempItem, isBase, isUnLock, isGet)
  local itemData = TableData.GetItemData(tempItem.itemId)
  if isUnLock == false or isGet == true then
    TipsPanelHelper.OpenUITipsPanel(itemData)
    return
  end
  if itemData.type == GlobalConfig.ItemType.GiftPick then
    local tabData = {
      tempItem.itemId,
      isBase,
      self.mShowMaxLevel
    }
    UIBattlePassGlobal.CurSelectType = UIBattlePassGlobal.SelectType.BpSingle
    local paramData = {tabData}
    UIManager.OpenUIByParam(UIDef.UIBattlePassRewardBoxDialog, paramData)
    return
  end
  if isBase == true then
    NetCmdBattlePassData:SendGetBattlepassReward(CS.ProtoObject.BattlepassType.Base, self.mShowMaxLevel, CS.ProtoCsmsg.BpRewardGetType.GetTypeNone, function()
      TimerSys:DelayCall(0.5, function()
        MessageSys:SendMessage(UIEvent.BpGetReward, nil)
      end)
      UISystem:OpenCommonReceivePanel()
    end)
  else
    NetCmdBattlePassData:SendGetBattlepassReward(NetCmdBattlePassData.BattlePassStatus, self.mShowMaxLevel, CS.ProtoCsmsg.BpRewardGetType.GetTypeNone, function()
      UISystem:OpenCommonReceivePanel()
      TimerSys:DelayCall(0.5, function()
        MessageSys:SendMessage(UIEvent.BpGetReward, nil)
      end)
    end)
  end
end

function UIBattleMainPanel:MoveAsset()
end

function UIBattleMainPanel:Hide()
end

function UIBattleMainPanel:Release()
  self.virtualList:onLayoutDone("-", self.OnLayoutDone)
  gfdestroy(self.obj)
  MessageSys:RemoveListener(UIEvent.BpGetReward, self.OnBpGetReward)
  MessageSys:RemoveListener(UIEvent.BattlePassLevelUp, self.OnBattlePassLevelUp)
  MessageSys:RemoveListener(UIEvent.BPScrollRefresh, self.OnBPScrollRefresh)
end

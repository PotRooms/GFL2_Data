require("UI.UIBasePanel")
require("UI.Common.UIComTabBtn1ItemV2")
require("UI.MonopolyActivity.CharInfo.Btn_ActivityTourChrInfoListItem")
require("UI.MonopolyActivity.Store.Item.ActivityTourStoreItem")
require("UI.MonopolyActivity.EnemyDetailDialog.Item.ActivityTourEnemyDetailAttackItem")
require("UI.MonopolyActivity.SelectInfo.Item.ActivityTourBuffDetailItem")
UIActivityTourEnemyDetailDialog = class("UIActivityTourEnemyDetailDialog", UIBasePanel)
UIActivityTourEnemyDetailDialog.__index = UIActivityTourEnemyDetailDialog

function UIActivityTourEnemyDetailDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIActivityTourEnemyDetailDialog:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListener()
  MonopolyUtil:SetMonopolyActivityUIHint(self.mUIRoot.transform)
end

function UIActivityTourEnemyDetailDialog:OnInit(root, data)
  self.mRoleID = data[1]
  self.mEnemyInfoType = data[2]
  self.mShowRound = 0
  local actorData = MonopolyWorld.MpData:GetActorData(self.mRoleID)
  if not actorData then
    return
  end
  self.mIsMonster = actorData.actorType == ActivityTourGlobal.ActorType.Monster
  if self.mIsMonster then
    self:InitMonster()
  else
    self:InitPlayer()
  end
  ActivityTourGlobal.ReplaceAllColor(self.mUIRoot)
end

function UIActivityTourEnemyDetailDialog:InitMonster()
  self.ui.mText_TitleHint.text = MonopolyUtil:GetMonopolyActivityHint(270356)
  local topHintTab = {
    270351,
    270352,
    270353
  }
  self.mTopTabTable = {}
  for index = 1, 3 do
    local tabItem = UIComTabBtn1ItemV2.New()
    self.mTopTabTable[index] = tabItem
    local topTabData = {
      index = index,
      name = MonopolyUtil:GetMonopolyActivityHint(topHintTab[index])
    }
    tabItem:InitCtrl(self.ui.mSListChild_GrpTabList.transform.gameObject, topTabData)
    tabItem:AddClickListener(function()
      self:RefreshTopTab(index, tabItem)
    end)
  end
  self.mSelectCommandIndex = 0
  
  function self.ui.mVList_Command.itemCreated(renderData)
    local item = self:ItemProviderCommand(renderData)
    return item
  end
  
  function self.ui.mVList_Command.itemRenderer(index, renderData)
    self:ItemRendererCommand(index, renderData)
  end
  
  self.mAttackItem = {}
  self.mBuffPrefabItem = {}
  setactive(self.ui.mSListChild_GrpTabList, true)
end

function UIActivityTourEnemyDetailDialog:InitPlayer()
  self.ui.mText_TitleHint.text = MonopolyUtil:GetMonopolyActivityHint(23002009)
  self.mBuffPrefabItem = {}
  self:InitCommon()
  self:ShowMonsterBuffState()
  setactive(self.ui.mSListChild_GrpTabList, false)
end

function UIActivityTourEnemyDetailDialog:InitCommon()
  setactive(self.ui.mTrans_GrpCommand, false)
  setactive(self.ui.mTrans_GrpAttack, false)
  setactive(self.ui.mTrans_GrpState, false)
  setactive(self.ui.mTrans_Not, false)
  self.ui.mVList_Command.numItems = 0
  self.ui.mVList_Command:Refresh()
end

function UIActivityTourEnemyDetailDialog:RefreshTopTab(index, tabItem)
  for i, v in pairs(self.mTopTabTable) do
    v:SetBtnInteractable(true)
  end
  tabItem:SetBtnInteractable(false)
  self:InitCommon()
  if index == ActivityTourGlobal.EnemyInfoType.CommandInfo then
    if self.mShowRound == 0 then
      self.mShowRound = NetCmdMonopolyData.currentRound
    end
    self:ShowMonsterCommand(self.mShowRound)
  elseif index == ActivityTourGlobal.EnemyInfoType.AttackInfo then
    self:ShowMonsterAttack()
  elseif index == ActivityTourGlobal.EnemyInfoType.BuffStateInfo then
    self:ShowMonsterBuffState()
  end
  self.ui.mAni_Root:SetTrigger("Tab_FadeIn")
end

function UIActivityTourEnemyDetailDialog:ShowMonsterCommand(round)
  self.ui.mText_Name.text = string_format(MonopolyUtil:GetMonopolyActivityHint(270357), round)
  self.mMonsterCanUseOrders = CS.GF2.Monopoly.MonopolyDefine.GetMonsterCanUseOrder(self.mRoleID, round)
  local useOrdersCount = self.mMonsterCanUseOrders.Count
  setactive(self.ui.mTrans_GrpCommand, true)
  setactive(self.ui.mTrans_Not, useOrdersCount == 0)
  setactive(self.ui.mTrans_GrpRight, useOrdersCount ~= 0)
  self.ui.mVList_Command.numItems = useOrdersCount
  self.ui.mVList_Command:Refresh()
  self.ui.mText_Not.text = MonopolyUtil:GetMonopolyActivityHint(270361)
  setactive(self.ui.mBtn_Before, round ~= 1)
  setactive(self.ui.mBtn_Next, round ~= NetCmdMonopolyData.levelData.max_round)
end

function UIActivityTourEnemyDetailDialog:ItemProviderCommand(renderData)
  local itemView = ActivityTourStoreItem.New()
  itemView:InitCtrl(renderData.gameObject, function(id, index)
    self.mSelectCommandIndex = index
    self:ShowRightCommandInfo(index)
    for i = 0, self.mMonsterCanUseOrders.Count - 1 do
      self.ui.mVList_Command:RefreshItemByIndex(i)
    end
  end)
  renderData.data = itemView
end

function UIActivityTourEnemyDetailDialog:ItemRendererCommand(index, renderData)
  local item = renderData.data
  if index >= self.mMonsterCanUseOrders.Count then
    return
  end
  for i, commandID in pairs(self.mMonsterCanUseOrders) do
    if i == index then
      item:SetData(commandID, commandID, index)
      item:ShowSteal(self.mRoleID, commandID, self.mShowRound)
      item:RefreshSelect(self.mSelectCommandIndex == index)
    end
    if index == self.mSelectCommandIndex then
      self:ShowRightCommandInfo(index)
    end
  end
end

function UIActivityTourEnemyDetailDialog:ShowRightCommandInfo(index)
  for i, commandID in pairs(self.mMonsterCanUseOrders) do
    if i == index then
      self:ShowCommandInfo(commandID)
    end
  end
end

function UIActivityTourEnemyDetailDialog:ShowCommandInfo(commandID)
  local monopolyOrderData = TableData.listMonopolyOrderDatas:GetDataById(commandID)
  if monopolyOrderData == nil then
    return
  end
  self.ui.mText_Title.text = monopolyOrderData.name.str
  self.ui.mImage_CommandQuality.color = ActivityTourGlobal.GetCommandItemQualityColor(monopolyOrderData.level)
  self.ui.mText_Content.text = monopolyOrderData.order_desc.str
  local minMove, maxMove = ActivityTourGlobal.GetOrderMoveRange(monopolyOrderData)
  local moveHintTxt = MonopolyUtil:GetMonopolyActivityHint(270165)
  if minMove == maxMove then
    self.ui.mText_Num.text = UIUtils.StringFormat(moveHintTxt, minMove)
  else
    self.ui.mText_Num.text = UIUtils.StringFormat(moveHintTxt, UIUtils.StringFormat(MonopolyUtil:GetMonopolyActivityHint(270164), minMove, maxMove))
  end
end

function UIActivityTourEnemyDetailDialog:ShowMonsterAttack()
  setactive(self.ui.mTrans_GrpAttack, true)
  local patrolItem = self.mAttackItem[1]
  if patrolItem == nil then
    patrolItem = ActivityTourEnemyDetailAttackItem.New()
    patrolItem:InitCtrl(self.ui.mSListChild_Content1.transform)
    table.insert(self.mAttackItem, patrolItem)
  end
  self:ShowPatrolAttackItemInfo(patrolItem)
  local monitorItem = self.mAttackItem[2]
  if monitorItem == nil then
    monitorItem = ActivityTourEnemyDetailAttackItem.New()
    monitorItem:InitCtrl(self.ui.mSListChild_Content1.transform)
    table.insert(self.mAttackItem, monitorItem)
  end
  self:ShowMonitorAttackItemInfo(monitorItem)
  local showEmpty = monitorItem:GetRoot().gameObject.activeSelf == false and patrolItem:GetRoot().gameObject.activeSelf == false
  local reverseAttackItems = TableTools.ReverseList(self.mAttackItem)
  local isLast = true
  for i, item in pairs(reverseAttackItems) do
    if item:GetRoot().gameObject.activeSelf == true then
      if isLast == false then
        item:ShowLine(true)
      end
      isLast = false
    end
  end
  setactive(self.ui.mTrans_Not, showEmpty)
  self.ui.mText_Not.text = MonopolyUtil:GetMonopolyActivityHint(270364)
end

function UIActivityTourEnemyDetailDialog:ShowPatrolAttackItemInfo(item)
  local skillDes
  local monsterActor = MonopolyWorld:GetMonsterActor(self.mRoleID)
  local skillCount = 0
  if monsterActor ~= nil then
    local mpEnemyData = TableData.listMonopolyEnemyDatas:GetDataById(monsterActor.Data.Id)
    if mpEnemyData then
      for i, value in pairs(mpEnemyData.skill_id) do
        local monopolySkillData = TableData.listMonopolySkillDatas:GetDataById(value)
        if monopolySkillData then
          skillDes = monopolySkillData.skill_desc.str
        end
      end
      skillCount = mpEnemyData.skill_id.Count
    end
  end
  item:SetData(MonopolyUtil:GetMonopolyActivityHint(270362), skillDes)
  setactive(item:GetRoot(), 0 < skillCount)
end

function UIActivityTourEnemyDetailDialog:ShowMonitorAttackItemInfo(item)
  local skillDes
  local skillCount = 0
  local monsterActor = MonopolyWorld:GetMonsterActor(self.mRoleID)
  if monsterActor ~= nil then
    local mpEnemyData = TableData.listMonopolyEnemyDatas:GetDataById(monsterActor.Data.Id)
    if mpEnemyData then
      for i, value in pairs(mpEnemyData.lock_skill) do
        local monopolySkillData = TableData.listMonopolySkillDatas:GetDataById(value)
        if monopolySkillData then
          skillDes = monopolySkillData.skill_desc.str
        end
      end
      skillCount = mpEnemyData.lock_skill.Count
    end
  end
  item:SetData(MonopolyUtil:GetMonopolyActivityHint(270363), skillDes)
  setactive(item:GetRoot(), 0 < skillCount)
end

function UIActivityTourEnemyDetailDialog:ShowMonsterBuffState()
  local monsterActor = MonopolyWorld.MpData:GetActorData(self.mRoleID)
  if not monsterActor then
    return
  end
  local buffs = monsterActor.buffs
  setactive(self.ui.mTrans_Not, buffs.Count == 0)
  setactive(self.ui.mTrans_GrpState, buffs.Count > 0)
  local nobuffHintId = self.mIsMonster and 270365 or 23002010
  self.ui.mText_Not.text = MonopolyUtil:GetMonopolyActivityHint(nobuffHintId)
  for i = 0, buffs.Count - 1 do
    local buff = buffs[i]
    local buffDetailItem = self.mBuffPrefabItem[i + 1]
    if buffDetailItem == nil then
      buffDetailItem = ActivityTourBuffDetailItem.New()
      local com = self.ui.mSListChild_Content2.transform:GetComponent(typeof(CS.ScrollListChild))
      buffDetailItem:InitCtrl(com.childItem, self.ui.mSListChild_Content2.transform)
      table.insert(self.mBuffPrefabItem, buffDetailItem)
    end
    buffDetailItem:Refresh(buff, i ~= buffs.Count - 1)
  end
end

function UIActivityTourEnemyDetailDialog:OnShowStart()
  if self.mIsMonster then
    self:RefreshTopTab(self.mEnemyInfoType, self.mTopTabTable[self.mEnemyInfoType])
  end
end

function UIActivityTourEnemyDetailDialog:OnShowFinish()
end

function UIActivityTourEnemyDetailDialog:OnClose()
  self:ReleaseCtrlTable(self.mTopTabTable, true)
  self:ReleaseCtrlTable(self.mAttackItem, true)
  self:ReleaseCtrlTable(self.mBuffPrefabItem, true)
end

function UIActivityTourEnemyDetailDialog:OnRelease()
  self.ui = nil
end

function UIActivityTourEnemyDetailDialog:AddBtnListener()
  UIUtils.GetButtonListener(self.ui.mBtn_GrpClose.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIActivityTourEnemyDetailDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIActivityTourEnemyDetailDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Before.gameObject).onClick = function()
    self.mShowRound = self.mShowRound - 1
    self:ShowMonsterCommand(self.mShowRound)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Next.gameObject).onClick = function()
    self.mShowRound = self.mShowRound + 1
    self:ShowMonsterCommand(self.mShowRound)
  end
end

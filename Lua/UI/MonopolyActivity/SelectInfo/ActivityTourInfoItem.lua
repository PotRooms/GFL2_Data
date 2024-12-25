require("UI.UIBaseCtrl")
require("UI.MonopolyActivity.ActivityTourGlobal")
require("UI.MonopolyActivity.SelectInfo.Item.ActivityTourBuffDetailItem")
require("UI.CombatLauncherPanel.Item.UICommonEnemyItem")
ActivityTourInfoItem = class("ActivityTourInfoItem", UIBaseCtrl)
ActivityTourInfoItem.__index = ActivityTourInfoItem
ActivityTourInfoItem.ui = nil
ActivityTourInfoItem.mData = nil

function ActivityTourInfoItem:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function ActivityTourInfoItem:InitCtrl(parent)
  local com = parent:GetComponent(typeof(CS.ScrollListChild))
  local obj = instantiate(com.childItem, parent.transform)
  self:SetRoot(obj.transform)
  self.ui = {}
  self.mData = nil
  self:LuaUIBindTable(obj, self.ui)
  MonopolyUtil:SetMonopolyActivityUIHint(self.mUIRoot.transform)
  self.roleId = 0
  self.buffList = {}
  self.enemyHeadList = {}
  if not self.oriColor then
    self.oriColor = self.ui.mImg_AvatarBg.color
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Command.gameObject).onClick = function()
    UIManager.OpenUIByParam(UIDef.UIActivityTourEnemyDetailDialog, {
      self.roleId,
      ActivityTourGlobal.EnemyInfoType.CommandInfo
    })
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Attack.gameObject).onClick = function()
    UIManager.OpenUIByParam(UIDef.UIActivityTourEnemyDetailDialog, {
      self.roleId,
      ActivityTourGlobal.EnemyInfoType.AttackInfo
    })
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BuffDetails.gameObject).onClick = function()
    UIManager.OpenUIByParam(UIDef.UIActivityTourEnemyDetailDialog, {
      self.roleId,
      ActivityTourGlobal.EnemyInfoType.BuffStateInfo
    })
  end
  setactive(self.ui.mTrans_EnemyItem.gameObject, false)
end

function ActivityTourInfoItem:Refresh(roleId)
  local actorData = MonopolyWorld.MpData:GetActorData(roleId)
  if not actorData then
    return
  end
  self.roleId = roleId
  local isMonster = actorData.actorType == ActivityTourGlobal.ActorType.Monster
  self.mIsMonster = isMonster
  setactive(self.ui.mTrans_EnemyInfo, isMonster)
  setactive(self.ui.mTrans_HP, isMonster)
  setactive(self.ui.mTrans_EnemyItem, isMonster)
  setactive(self.ui.mTrans_BtnInfo, isMonster)
  setactive(self.ui.mTrans_Description, isMonster)
  setactive(self.ui.mTrans_Rank, false)
  if not isMonster then
    self:RefreshPlayer(actorData)
  else
    self:RefreshMonster(actorData)
  end
  self:RefreshBuff(actorData)
end

function ActivityTourInfoItem:RefreshPlayer(actorData)
  local gunId = actorData.configId
  local gunData = TableData.listGunDatas:GetDataById(gunId)
  self.ui.mImg_Avatar.sprite = IconUtils.GetCharacterHeadSprite(gunData.code)
  self.ui.mText_AvatarName.text = AccountNetCmdHandler:GetName()
  self.ui.mImg_AvatarBg.color = ColorUtils.BlueColor2
  self.ui.mText_AvatarTeamNum.text = MonopolyUtil:GetMonopolyActivityHint(270300)
end

function ActivityTourInfoItem:RefreshMonster(actorData)
  local monsterActor = MonopolyWorld:GetMonsterActor(self.roleId)
  if monsterActor == nil then
    return
  end
  local mpEnemyData = TableData.listMonopolyEnemyDatas:GetDataById(monsterActor.Data.Id)
  if mpEnemyData == nil then
    return
  end
  local robotId = actorData.configId
  local enemyCfg = TableData.listMonopolyEnemyDatas:GetDataById(robotId)
  self.ui.mImg_Avatar.sprite = IconUtils.GetTourCharacterSprite(enemyCfg.chess_icon)
  self.ui.mText_AvatarName.text = mpEnemyData.name.str
  self.ui.mImg_AvatarBg.color = ColorUtils.RedColor4
  self.ui.mText_AvatarTeamNum.text = MonopolyUtil:GetMonopolyActivityHint(270299)
  self.ui.mText_Description.text = enemyCfg.des.str
  setactive(self.ui.mTrans_Rank, false)
  if enemyCfg.monster_type == LuaUtils.EnumToInt(CS.GF2.Monopoly.MonsterType.Elite) then
    self.ui.mText_Rank.text = MonopolyUtil:GetMonopolyActivityHint(23002003)
    setactive(self.ui.mTrans_Rank, true)
    self.ui.mImg_RankBg.color = ColorUtils.OrangeColor2
  elseif enemyCfg.monster_type == LuaUtils.EnumToInt(CS.GF2.Monopoly.MonsterType.Boss) then
    self.ui.mText_Rank.text = MonopolyUtil:GetMonopolyActivityHint(23002004)
    setactive(self.ui.mTrans_Rank, true)
    self.ui.mImg_RankBg.color = CS.GF2.UI.UITool.StringToColor("cd5537")
  end
  local monsterData = MonopolyWorld.MpData:GetMonsterData(self.roleId)
  if monsterData ~= nil then
    self.ui.mText_HP.text = UIUtils.StringFormat(MonopolyUtil:GetMonopolyActivityHint(270341), monsterData.HpPercent)
  end
  setactive(self.ui.mTrans_Unoccupy, false)
  setactive(self.ui.mTrans_Canoccupy, false)
  local stageData = TableData.listStageDatas:GetDataById(mpEnemyData.region)
  if stageData == nil then
    return
  end
  local stageConfig = TableData.listStageConfigDatas:GetDataById(stageData.stage_config)
  if stageConfig == nil then
    return
  end
  for i = 1, stageConfig.enemies.Count do
    local item = self.enemyHeadList[i]
    if item == nil then
      item = UICommonEnemyItem.New()
      item:InitCtrl(self.ui.mTrans_EnemyItem.gameObject)
      self.enemyHeadList[i] = item
    end
    local enemyId = stageConfig.enemies[i - 1]
    local enemyData = TableData.GetEnemyData(enemyId)
    item:SetData(enemyData, stageData.stage_class)
    item:EnableLv(true)
    UIUtils.GetButtonListener(item.mBtn_OpenDetail.gameObject).onClick = function()
      CS.RoleInfoCtrlHelper.Instance:InitSysEnemyDataByStage(enemyId, stageData.stage_class, stageData.id)
    end
  end
  for i = stageConfig.enemies.Count + 1, #self.enemyHeadList do
    setactive(self.enemyHeadList[i]:GetRoot(), false)
  end
end

function ActivityTourInfoItem:RefreshBuff(actorData)
  setactive(self.ui.mTrans_BuffItem, false)
  local buffs = actorData.buffs
  local haveBuff = buffs.Count > 0
  local bufNum = buffs.Count
  for i = 1, bufNum do
    if not self.buffList[i] then
      self.buffList[i] = instantiate(self.ui.mTrans_BuffItem.gameObject, self.ui.mTrans_BuffContent)
    end
    setactive(self.buffList[i], true)
    self:SetBuff(buffs[i - 1], self.buffList[i])
  end
  for i = bufNum + 1, #self.buffList do
    setactive(self.buffList[i], false)
  end
  setactive(self.ui.mTrans_Empty, not haveBuff)
  setactive(self.ui.mTrans_BuffContent, haveBuff)
end

function ActivityTourInfoItem:SetBuff(buffInfo, item)
  local buffData = TableData.listMonopolyEffectDatas:GetDataById(buffInfo.Id)
  if not buffData then
    return
  end
  local itemLua = {}
  self:LuaUIBindTable(item, itemLua)
  itemLua.mImg_Icon.sprite = IconUtils.GetBuffIcon(buffData.icon)
end

function ActivityTourInfoItem:OnRelease()
  self.ui = nil
  self.mData = nil
  for i = 1, #self.buffList do
    gfdestroy(self.buffList[i])
  end
  for i = 1, #self.enemyHeadList do
    self.enemyHeadList[i]:OnRelease()
  end
  self.buffList = nil
  self.enemyHeadList = nil
  self.super.OnRelease(self, true)
end

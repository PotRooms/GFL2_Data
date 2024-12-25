require("UI.SimCombatPanel.ResourcesCombat.UISimCombatResourcePanelBase")
UISimCombatWeaponModPanel = class("UISimCombatWeaponModPanel", UISimCombatResourcePanelBase)

function UISimCombatWeaponModPanel:OnInit(root, data, behaviourId)
  self.simEntranceId = LuaUtils.EnumToInt(StageType.WeaponModStage)
  self.super.OnInit(self, root, data, behaviourId)
end

function UISimCombatWeaponModPanel:OnAwake(root, data)
  self.super.OnAwake(self, root, data)
  self.limitCount = 20
  UIUtils.AddBtnClickListener(self.stageDesc.ui.mBtn_Raid.gameObject, function()
    self:onClickRaid()
  end)
  UIUtils.AddBtnClickListener(self.stageDesc.ui.mBtn_BtnStart.gameObject, function()
    self:onClickBattle()
  end)
end

function UISimCombatWeaponModPanel:onClickRaid()
  if not TipsManager.CheckCanRaid(self.stageDesc.stageData) then
    return
  end
  if self.stageDesc.simEntranceData.ItemId > 0 and not TipsManager.CheckTicketIsEnough(1, self.stageDesc.simEntranceData.ItemId) then
    return
  end
  if not TipsManager.CheckStaminaIsEnoughOnly(self.stageDesc.stageData.stamina_cost) then
    TipsManager.ShowBuyStamina()
    return
  end
  if self:CheckItemIsOverflow() then
    return
  end
  local totalNum = CS.GF2.Data.GlobalData.weaponPart_capacity
  local itemCount = NetCmdWeaponPartsData:GetAllMods().Count
  local raidNum = math.floor((totalNum - itemCount) / self.limitCount)
  local tbLimitNum = TableData.GlobalSystemData.RaidOnetimeLimit
  raidNum = math.min(tbLimitNum, raidNum)
  if self.stageDesc.simResourceData.mod_suit_drop_on == 1 then
    local d = self.stageList:getCurSlot():GetSimCombatResourceData()
    local dropTable = {}
    for i, v in pairs(self.stageDesc.stageData.normal_drop_view_list) do
      local t = {}
      t.id = i
      t.num = v
      table.insert(dropTable, t)
    end
    local t = {}
    t.simCombatID = d.id
    t.costItemId = GlobalConfig.StaminaId
    t.costItemNum = self.stageDesc.stageData.stamina_cost
    t.maxSweepsNum = raidNum
    t.rewardItemList = dropTable
    t.SimTypeId = self.stageDesc.simResourceData.sim_type
    t.WeaponModData = {
      reward = self:GetRewardList(),
      defaultLimit = self.limitCount,
      stageType = StageType.WeaponModStage
    }
    UIManager.OpenUIByParam(UIDef.UISimCombatWeaponModWishRaidDialog, t)
  else
    self.stageDesc:onClickRaid()
  end
end

function UISimCombatWeaponModPanel:onClickBattle()
  if self:CheckItemIsOverflow() then
    return
  end
  if self.stageDesc.simResourceData.mod_suit_drop_on == 1 then
    local t = {}
    t[0] = self.stageList:getCurSlot():GetSimCombatResourceData().id
    t[1] = function()
      self.stageDesc:onClickBattle()
    end
    UIManager.OpenUIByParam(UIDef.UISimCombatWeaponModWishDialog, t)
  else
    self.stageDesc:onClickBattle()
  end
end

function UISimCombatWeaponModPanel:GetRewardList()
  local rewardList = {}
  local isFirst = self.stageDesc:isFirstOfStageBattle()
  if isFirst then
    for itemId, count in pairs(self.stageDesc.stageData.first_reward) do
      if rewardList[itemId] == nil then
        rewardList[itemId] = 0
      end
      rewardList[itemId] = rewardList[itemId] + count
    end
  end
  local normalDropList = self.stageDesc.stageData.normal_drop_view_list
  if 0 < normalDropList.Count then
    for itemId, count in pairs(normalDropList) do
      if rewardList[itemId] == nil then
        rewardList[itemId] = 0
      end
      rewardList[itemId] = rewardList[itemId] + count
    end
  end
  return rewardList
end

function UISimCombatWeaponModPanel:CheckItemIsOverflow()
  local rewardList = self:GetRewardList()
  local limitCount = self.limitCount
  local upInfo = NetCmdActivityDropUpData:GetOneDropUpTimes(LuaUtils.EnumToInt(StageType.WeaponModStage))
  if upInfo.Count > 0 then
    local up = upInfo[0]
    limitCount = limitCount + math.ceil(up * limitCount)
  end
  if TipsManager.CheckItemIsOverflowAndStopByList(rewardList, limitCount) then
    return true
  end
  return false
end

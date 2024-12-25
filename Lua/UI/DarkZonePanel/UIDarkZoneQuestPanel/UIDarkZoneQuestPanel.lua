require("UI.UIDarkZoneMapSelectPanel.MapSelectUtils")
require("UI.DarkZonePanel.UIDarkZoneQuestPanel.UIDarkZoneQuestPanelView")
require("UI.UIBasePanel")
require("UI.Common.UICommonItem")
require("UI.CombatLauncherPanel.Item.UICommonEnemyItem")
require("UI.SimpleMessageBox.SimpleMessageBoxPanel")
require("UI.DarkZonePanel.UIDarkZoneModePanel.DarkZoneGlobal")
UIDarkZoneQuestPanel = class("UIDarkZoneQuestPanel", UIBasePanel)
UIDarkZoneQuestPanel.__index = UIDarkZoneQuestPanel

function UIDarkZoneQuestPanel:ctor(csPanel)
  UIDarkZoneQuestPanel.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
  csPanel.Is3DPanel = false
end

function UIDarkZoneQuestPanel:OnAwake(root, data)
end

function UIDarkZoneQuestPanel:OnSave()
  self.hasCache = false
end

function UIDarkZoneQuestPanel:OnInit(root, data, behaviourId)
  self:SetRoot(root)
  self.mView = UIDarkZoneQuestPanelView.New()
  self.ui = {}
  self.mView:InitCtrl(root, self.ui)
  self.mData = {}
  self.darkZoneMode = data[0]
  NetCmdActivitySimData.IsCarQuestOpen = false
  if self.darkZoneMode == 1 then
    self.mData.id = data[1]
  elseif self.darkZoneMode == 2 then
    self.mData.endlessId = data[1]
    self.mData.rewardId = data[2]
  elseif self.darkZoneMode == 4 then
    self.mData.id = data[1]
    NetCmdActivitySimData.IsCarQuestOpen = true
  end
  self.isJumpIn = behaviourId ~= 0
  self.EventGroup = {}
  for i = DarkZoneGlobal.EventType.Start, DarkZoneGlobal.EventType.End do
    self.EventGroup[i] = false
  end
  self.chestPrefab = nil
  self.chestUI = {}
  self.rewardConditionList = {}
  self:InitBaseData()
  self.ui.mAnimator_RaidBtn = self.ui.mBtn_Raid.transform:GetComponent(typeof(CS.UnityEngine.Animator))
  setactive(self.ui.mTrans_TextNum, false)
  self:AddEventListener()
  self:AddBtnListen()
  self.outTimer = DarkNetCmdStoreData:CreateDarkzoneOutTimer(self.CloseSelfUI)
end

function UIDarkZoneQuestPanel:CloseSelfUI()
  UIManager.CloseUI(UIDef.UIDarkZoneQuestPanel)
end

function UIDarkZoneQuestPanel:OnShowStart()
  if GFUtils.IsOverseaServer() then
    UIManager.CloseUI(UIDef.UIDarkZoneQuestPanel)
  end
  if self.darkZoneMode == 1 then
    if self.mData.id and self.mData.id > 0 then
      self.questData = TableData.listDarkzoneSystemQuestDatas:GetDataById(self.mData.id)
    elseif self.mData[0] == 1 then
      self.questData = TableData.listDarkzoneSystemQuestDatas:GetDataById(self.mData[1])
    end
    self:ReFreshChestNum()
    self:FreshQuestDetail()
    self:SetBtnState()
    self:ShowUnlockReward()
  end
  if self.darkZoneMode == 2 then
    self.endlessData = TableData.listDarkzoneSystemEndlessDatas:GetDataById(self.mData.endlessId)
    self.endLessRewardData = TableData.listDarkzoneSystemEndlessRewardDatas:GetDataById(self.mData.rewardId)
    self:FreshQuestDetailByEndLessData()
  end
  if self.darkZoneMode == 4 then
    self.questData = TableData.listDzActivityQuestDatas:GetDataById(self.mData.id)
    for i, v in pairs(self.questData.SweepCost) do
      local itemData = TableData.listItemDatas:GetDataById(i)
      TipsManager.Add(self.ui.mTrans_Consume.gameObject, itemData)
    end
    self:FreshActiveCarrierDetail()
  end
  setactive(self.ui.mTrans_QuestText, self.darkZoneMode == 1 or self.darkZoneMode == 4)
  setactive(self.ui.mTrans_Reward1, self.darkZoneMode == 1)
  setactive(self.ui.mTrans_Explore, false)
  if self.minimap_id ~= 0 then
    self.MinimapOutsideGame = CS.DarkSpace.MinimapOutsideGame(self.mUIRoot, self.minimap_id, self.questData.id, self.questData.quest_mapmark)
  end
end

function UIDarkZoneQuestPanel:ShowChest()
  self.chestPrefab = instantiate(self.ui.mTrans_Chest, self.ui.mTrasn_Content)
  self:LuaUIBindTable(self.chestPrefab, self.chestUI)
  setactive(self.chestPrefab, true)
  setactive(self.chestUI.mTrans_Explore.gameObject, true)
  setactive(self.chestUI.mTrans_Item.gameObject, false)
  self.chestUI.mText_ChestTitle.text = TableData.GetHintById(903385)
  local hasNum = DarkNetCmdStoreData:GetDZQuestReceivedChest(self.mData.id)
  local totalNum = DarkNetCmdStoreData:GetDZQuestTotalChest(self.mData.id)
  local state = NetCmdDarkZoneSeasonData:IsQuestFinish(self.mData.id)
  if state and hasNum == totalNum then
    setactive(self.chestUI.mTrans_Finish, true)
  else
    setactive(self.chestUI.mTrans_Finish, false)
  end
  self.chestUI.mText_Chest.text = string_format(TableData.GetHintById(240139), hasNum, totalNum)
  setactive(self.chestUI.mTrans_Icon, true)
  setactive(self.chestUI.mTrans_lock, false)
  self.chestPrefab:SetSiblingIndex(1)
end

function UIDarkZoneQuestPanel:OnShowFinish()
  self:EventAnimator()
end

function UIDarkZoneQuestPanel:OnBackFrom()
end

function UIDarkZoneQuestPanel:OnHide()
end

function UIDarkZoneQuestPanel:OnUpdate(deltatime)
end

function UIDarkZoneQuestPanel:OnClose()
  self.ui.mAnimator_begin:SetBool("Bool", false)
  self.ui.mAnimator_Time:SetBool("Bool", false)
  self.ui.mAnimator_Random:SetBool("Bool", false)
  self.ui.mAnimator_End:SetBool("Bool", false)
  self:OpenBtn()
  self.ui = nil
  self.mView = nil
  self.mData = nil
  self.questData = nil
  self.endlessData = nil
  self.costItemNumIsEnough = nil
  self.costItem = nil
  self.formatStr = nil
  if self.outTimer ~= nil then
    self.outTimer:Stop()
    self.outTimer = nil
  end
  NetCmdActivitySimData.IsCarQuestOpen = false
  for i = 1, #self.costItemList do
    gfdestroy(self.costItemList[i].mUIRoot.gameObject)
  end
  if self.endLessItemList then
    for i = 1, #self.endLessItemList do
      gfdestroy(self.endLessItemList[i].obj)
    end
  end
  if self.rewardConditionList then
    for i = 1, #self.rewardConditionList do
      gfdestroy(self.rewardConditionList[i].gameObject)
    end
  end
  self.costItemList = nil
  self.endLessItemList = nil
  self:ReleaseCtrlTable(self.rewardItemList, true)
  self.rewardItemList = nil
  self.eventItemList = nil
  self:ReleaseCtrlTable(self.enemyItemList, true)
  self.enemyItemList = nil
  self.MinimapOutsideGame:Release()
  self.MinimapOutsideGame = nil
  MapSelectUtils.currentQuestGroupID = nil
  MapSelectUtils.currentQuestID = nil
  gfdestroy(self.chestPrefab)
  self.chestUI = nil
  self.isJumpIn = nil
end

function UIDarkZoneQuestPanel:OnRecover()
  self:OnShowStart()
  local data = NetCmdActivityDarkZone:GetEscortExchangeList()
  if data.Count > 0 then
    UIManager.OpenUIByParam(UIDef.UIDarkzoneCarrierRewardExchangeDialog, data)
  elseif ActivityCafeGlobal.IsNeedOpenMessageBox then
    ActivityCafeGlobal.IsNeedOpenMessageBox = false
    ActivityCafeGlobal.ShowToMainBox()
  end
end

function UIDarkZoneQuestPanel:OnRelease()
  self.hasCache = false
end

function UIDarkZoneQuestPanel:InitBaseData()
  self.costItemList = {}
  self.rewardItemList = {}
  self.eventItemList = {}
  self.enemyItemList = {}
  self.mapIconItemList = {}
  self.formatStr = "{0}/{1}"
end

function UIDarkZoneQuestPanel:ResetQuestShow()
  setactive(self.ui.mTrans_Seat, false)
  setactive(self.ui.mTrans_GrpQuest, false)
  setactive(self.ui.mTrans_BtnQuery, false)
  setactive(self.ui.mTrans_EndlessText, false)
  setactive(self.ui.mTrans_EndlessInfo, false)
  setactive(self.ui.mTrans_Reward, false)
  setactive(self.ui.mTrans_GrpRewardDescription, false)
  setactive(self.ui.mTrans_GrpText, false)
  setactive(self.ui.mBtn_Raid, false)
  setactive(self.ui.mTrans_ItemRoot, true)
end

function UIDarkZoneQuestPanel:FreshQuestDetail()
  setactive(self.ui.mTrans_EndlessType, false)
  setactive(self.ui.mTrans_EndlessInfo, false)
  setactive(self.ui.mBtn_Raid, false)
  self.ui.mText_TaskName.text = self.questData.quest_name.str
  self.ui.mText_TaskLevelNum.text = string_format(TableData.GetHintById(200002), self.questData.quest_level)
  self.ui.mText_TaskTarget.text = self.questData.quest_target.str
  self.ui.mText_TodayFinishTime.text = string_format(TableData.GetHintById(240067), NetCmdItemData:GetNetItemCount(DarkZoneGlobal.TimeLimitID), TableDataBase.listItemLimitDatas:GetDataById(DarkZoneGlobal.TimeLimitID).max_limit)
  self:ResetQuestShow()
  setactive(self.ui.mTrans_Reward, true)
  local questType = TableData.listDarkzoneSeriesQuestTypeDatas:GetDataById(self.questData.quest_type)
  local mapdata = TableData.listDarkzoneMapV2Datas:GetDataById(self.questData.quest_struct_scene_id)
  self.minimap_id = mapdata.minimap_id
  self.ui.mText_TaskTypeName.text = questType.name.str
  self.ui.mImg_TaskType.sprite = IconUtils.GetDarkZoneModelIcon(questType.icon)
  self.ui.mText_TaskDesc.text = self.questData.quest_desc.str
  self.ui.mText_TargetText.text = TableData.GetHintById(240142)
  setactive(self.ui.mTrans_Seat, false)
  if self.questData.dz_mode == DarkZoneGlobal.PanelType.Quest then
    setactive(self.ui.mTrans_GrpQuest, true)
    self.ui.mText_MapName.text = mapdata.name.str
  end
  local useItem = self.questData.quest_cost
  self.costItem = useItem
  self:RefreshCostItem(useItem)
  local dataList = {}
  local kvSortList = self.questData.quest_rewarddetailshow
  local count = kvSortList.Key.Count
  for i = 0, count - 1 do
    local t = {}
    t.id = kvSortList.Key[i]
    t.num = kvSortList.Value[i]
    table.insert(dataList, t)
  end
  self:SetRewardItem(dataList)
  self:SetEnemyList(mapdata)
  self:SetEventData(self.questData.result_show)
end

function UIDarkZoneQuestPanel:FreshActiveCarrierDetail()
  self.activeID = NetCmdActivityDarkZone:GetCurrActivityID(SubmoduleType.ActivityDarkzone, NetCmdActivitySimData.offcialConfigId)
  self.state = NetCmdActivityDarkZone:GetCurrActivityState(NetCmdActivitySimData.offcialConfigId)
  self.activityEntranceData = NetCmdActivityDarkZone:GetActivityEntranceData(NetCmdActivitySimData.offcialConfigId, self.state)
  self.activityTKey = LuaUtils.EnumToInt(SubmoduleType.ActivityDarkzone)
  if self.state ~= ActivitySimState.Official then
    self:BanBtn()
    self.state = ActivitySimState.Official
    self.activityEntranceData = TableData.listActivityEntranceDatas:GetDataById(99905)
    local ModuleData = TableData.listActivityModuleDatas:GetDataById(self.activityEntranceData.module_id)
    if ModuleData.ActivitySubmodule:TryGetValue(self.activityTKey) then
      self.activeID = ModuleData.ActivitySubmodule[self.activityTKey]
    end
  end
  self.activityConfigData = NetCmdThemeData:GetActivityDataByEntranceId(self.activityEntranceData.id)
  self:ResetQuestShow()
  setactive(self.ui.mTrans_EndlessType, false)
  setactive(self.ui.mTrans_EndlessInfo, false)
  setactive(self.ui.mBtn_Raid, false)
  setactive(self.ui.mTrans_GrpText, self.questData.sweep_control)
  local stageInfo = NetCmdActivityDarkZone:GetDarkZoneStageInfo(self.questData.QuestId)
  local score = 0
  if stageInfo then
    score = stageInfo.Score
  end
  self.ui.mTextScore_Num.text = score
  self.ui.mText_TaskName.text = self.questData.quest_name.str
  self.ui.mText_TaskLevelNum.text = string_format(TableData.GetHintById(200002), self.questData.quest_level)
  self.ui.mText_TaskTarget.text = self.questData.quest_aim.str
  setactive(self.ui.mTrans_GrpRewardDescription, true)
  setactive(self.ui.mBtn_Raid, self.questData.sweep_control)
  self.raidPopupStr = string_format(TableData.GetActivityHint(271083, self.activityConfigData.Id, 2, self.activityTKey, self.activeID), self.questData.sweep_unlock)
  self.canRaid = score >= self.questData.sweep_unlock
  self.ui.mAnimator_Raid:SetBool("Lock", score < self.questData.sweep_unlock)
  local activeID = self.activeID
  local active = TableData.listActivityDarkzoneDatas:GetDataById(activeID)
  local activeGamePlay = TableData.listDzActivityGameplayDatas:GetDataById(active.gameplay_id)
  local questType = TableData.listDarkzoneSeriesQuestTypeDatas:GetDataById(activeGamePlay.dz_mode)
  local mapdata = TableData.listDarkzoneMapV2Datas:GetDataById(self.questData.quest_struct_scene_id)
  self.minimap_id = mapdata.minimap_id
  self.ui.mText_TaskTypeName.text = questType.name.str
  self.ui.mImg_TaskType.sprite = IconUtils.GetDarkZoneModelIcon(questType.icon)
  self.ui.mText_TaskDesc.text = self.questData.quest_desc.str
  self.ui.mText_TargetText.text = TableData.GetHintById(240142)
  setactive(self.ui.mTrans_Seat, false)
  if self.darkZoneMode == 4 then
    setactive(self.ui.mTrans_GrpQuest, true)
    self.ui.mText_MapName.text = mapdata.name.str
  end
  local useItem = self.questData.quest_cost
  self.costItem = useItem
  self:RefreshCostItem(useItem)
  local dataList = {}
  local kvSortList = self.questData.quest_reward_show
  local count = kvSortList.Count
  for i = 0, count - 1 do
    local t = {}
    t.id = kvSortList[i]
    t.num = 1
    table.insert(dataList, t)
  end
  self:SetRewardItem(dataList)
  self:SetEnemyList(mapdata)
  self:SetEventData(self.questData.result_show)
end

function UIDarkZoneQuestPanel:InitMapIcons()
  self.MinimapOutsideGame:InitMapIcons()
end

function UIDarkZoneQuestPanel:ShowUnlockReward()
  local questunlock = self.questData.quest_unlock.str
  if questunlock ~= "" then
    questunlock = string.split(questunlock, ";")
    for i = 1, #questunlock do
      local item = self.rewardConditionList[i]
      if item == nil then
        item = instantiate(self.ui.mTrans_Explore, self.ui.mTrans_Reward)
        item:SetSiblingIndex(1)
        setactive(item, true)
        table.insert(self.rewardConditionList, item)
      end
      local textCom = item.transform:Find("GrpText/Text_Explore"):GetComponent(typeof(CS.UnityEngine.UI.Text))
      textCom.text = questunlock[i]
    end
  end
end

function UIDarkZoneQuestPanel:SetEventData(eventData)
  local eventQuest = {}
  if eventData ~= nil then
    for i = 0, eventData.Count - 1 do
      local questGroup = eventData[i]
      eventQuest = string.split(questGroup, ":")
      for j = 2, #eventQuest do
        self.EventGroup[tonumber(eventQuest[1])] = true
        local eventTable = {
          stcDataId = tonumber(eventQuest[j]),
          type = tonumber(eventQuest[1])
        }
        table.insert(self.eventItemList, eventTable)
      end
    end
  end
end

function UIDarkZoneQuestPanel:SetBtnState()
  setactive(self.ui.mTrans_Complete, false)
  setactive(self.ui.mTrans_Quest, false)
  setactive(self.ui.mTrans_Lv, false)
  setactive(self.ui.mTrans_Action, false)
  local state = NetCmdDarkZoneSeasonData:IsQuestFinish(self.mData.id)
  setactive(self.ui.mTrans_Action, true)
  if state then
    setactive(self.ui.mTrans_Chest, false)
  else
    setactive(self.ui.mTrans_Chest, true)
  end
end

function UIDarkZoneQuestPanel:EventAnimator()
  local showNoText = true
  for i = DarkZoneGlobal.EventType.Start, DarkZoneGlobal.EventType.End do
    showNoText = showNoText and not self.EventGroup[i]
  end
  setactive(self.ui.mTrans_Text, showNoText)
  if showNoText then
    for i = DarkZoneGlobal.EventType.Start, DarkZoneGlobal.EventType.End do
      setactive(self.ui["mEventText" .. i], false)
    end
    setactive(self.ui.mQuestBtn_Query, false)
  else
    for i = DarkZoneGlobal.EventType.Start, DarkZoneGlobal.EventType.End do
      setactive(self.ui["mEventText" .. i], true)
    end
    setactive(self.ui.mQuestBtn_Query, true)
  end
  for i = DarkZoneGlobal.EventType.Start, DarkZoneGlobal.EventType.End do
    self.ui["mBtn_Event" .. i].interactable = self.EventGroup[i]
  end
  self.ui.mAnimator_begin:SetBool("Bool", self.EventGroup[DarkZoneGlobal.EventType.Start])
  self.ui.mAnimator_Time:SetBool("Bool", self.EventGroup[DarkZoneGlobal.EventType.Time])
  self.ui.mAnimator_Random:SetBool("Bool", self.EventGroup[DarkZoneGlobal.EventType.Random])
  self.ui.mAnimator_End:SetBool("Bool", self.EventGroup[DarkZoneGlobal.EventType.End])
end

function UIDarkZoneQuestPanel:FreshQuestDetailByEndLessData()
  self:ResetQuestShow()
  setactive(self.ui.mTrans_BtnQuery, true)
  setactive(self.ui.mTrans_Lv, false)
  setactive(self.ui.mTrans_GrpQuest, false)
  setactive(self.ui.mTrans_EndlessType, true)
  setactive(self.ui.mTrans_EndlessInfo, true)
  setactive(self.ui.mBtn_Raid, true)
  self.ui.mText_TaskName.text = self.endlessData.quest.str
  self.ui.mText_TaskLevelNum.text = string_format(TableData.GetHintById(200002), self.endlessData.level)
  setactive(self.ui.mText_TaskTarget, false)
  self.ui.mText_TargetText.text = TableData.GetHintById(240085)
  self.raidPopupStr = CS.LuaUIUtils.CheckUnlockPopupStrByRepeatedList(self.endlessData.raid_unlock)
  self.canRaid = string.len(self.raidPopupStr) == 0
  self.ui.mAnimator_RaidBtn:SetBool("Lock", self.canRaid == false)
  local mapdata = TableData.listDarkzoneMapV2Datas:GetDataById(self.endlessData.map)
  self.minimap_id = mapdata.minimap_id
  self.ui.mText_TaskDesc.text = self.endlessData.quest_des.str
  self.ui.mText_MapName.text = mapdata.name.str
  local useItem = self.endlessData.use_item
  self.costItem = useItem
  self:RefreshCostItem(useItem)
  local endLessPlayData = TableData.listDzEndlessModeDatas:GetDataById(self.endlessData.map)
  self.endLessItemList = {}
  for i = 1, 3 do
    if self.endLessItemList[i] == nil then
      local parent = self.ui.mTrans_EndlessText.parent
      local obj = instantiate(self.ui.mTrans_EndlessText.gameObject, parent)
      local item = {}
      item.obj = obj
      setactive(obj, true)
      item.ui = {}
      UIUtils.OutUIBindTable(obj, item.ui)
      self.endLessItemList[i] = item
    end
    local item = self.endLessItemList[i]
    local nameStr, numStr
    if i == 1 then
      nameStr = TableData.GetHintById(240029)
      for i, v in pairs(endLessPlayData.default_val) do
        numStr = v
      end
    elseif i == 2 then
      nameStr = TableData.GetHintById(240030)
      numStr = endLessPlayData.oxygen_down_show
    elseif i == 3 then
      nameStr = TableData.GetHintById(240031)
      local count = endLessPlayData.result_divide_num.Count
      numStr = endLessPlayData.result_divide_num[count - 2]
    end
    item.ui.mText_Name.text = nameStr
    item.ui.mText_Num.text = numStr
  end
  local dataList = {}
  for i = 0, self.endLessRewardData.reward.Count - 1 do
    local t = {}
    t.id = self.endLessRewardData.reward[i]
    t.num = 1
    table.insert(dataList, t)
  end
  self:SetRewardItem(dataList)
  setactive(self.ui.mTrans_ItemRoot, false)
  self:SetEnemyList(mapdata)
  self:SetEventData(self.endlessData.result_show)
end

function UIDarkZoneQuestPanel:RefreshCostItem(useItem)
  self.costItemNumIsEnough = true
  setactive(self.ui.mTrans_CostItem, useItem.Count > 0)
  for k, v in pairs(useItem) do
    local itemOwn = NetCmdItemData:GetItemCountById(k)
    if v > itemOwn then
      self.costItemNumIsEnough = false
      self.ui.mText_CostNum.color = ColorUtils.RedColor
    else
      self.ui.mText_CostNum.color = ColorUtils.GrayColor
    end
    self.ui.mImg_CostItem.sprite = IconUtils.GetItemIconSprite(k)
    self.ui.mText_CostNum.text = CS.LuaUIUtils.GetMaxNumberText(v)
  end
end

function UIDarkZoneQuestPanel:IsShowTarget(listString, enemy)
  local enemyList = string.split(listString, ",")
  for i = 1, #enemyList do
    if enemyList[i] == enemy then
      return true
    elseif enemyList[i] == enemy .. ";" then
      return true
    end
  end
  return false
end

function UIDarkZoneQuestPanel:SetRewardItem(dataList)
  for i, v in ipairs(dataList) do
    if self.rewardItemList[i] == nil then
      local item = UICommonItem.New()
      item:InitCtrl(self.ui.mTrans_ItemRoot)
      self.rewardItemList[i] = item
    end
    local item = self.rewardItemList[i]
    local num = v.num > 1 and v.num or nil
    item:SetItemData(v.id, num)
  end
end

function UIDarkZoneQuestPanel:SetEnemyList(mapData)
  local enemyList = mapData.darkzone_enemies
  local modificationGroup = mapData.modification_list
  local listCount = modificationGroup.Count
  local count = enemyList.Count
  for i = 0, count - 1 do
    local data = string.split(enemyList[i], ":")
    local enemyID = tonumber(data[1])
    local Tabdata = TableData.GetEnemyData(enemyID)
    if self.enemyItemList[i + 1] == nil then
      local item = UICommonEnemyItem.New()
      item:InitCtrl(self.ui.mTrans_EnemyInfoRoot)
      self.enemyItemList[i + 1] = item
    end
    local item = self.enemyItemList[i + 1]
    local level = tonumber(data[2])
    item:SetData(Tabdata, level)
    if self.darkZoneMode == 1 then
      item:SetDarkzoneTargetIcon(self:IsShowTarget(self.questData.targetenemy_show, data[1]))
    end
    local modificationID = 0
    if i < listCount then
      modificationID = modificationGroup[i]
    end
    UIUtils.GetButtonListener(item.mBtn_OpenDetail.gameObject).onClick = function()
      CS.RoleInfoCtrlHelper.Instance:InitSysEnemyData(enemyID, level, CS.UISystem.UIGroupType.Default, CS.GF2.Data.StageType.DarkzoneStage, modificationID)
    end
  end
end

function UIDarkZoneQuestPanel:AddBtnListen()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.UIDarkZoneQuestPanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Next.gameObject).onClick = function()
    local time = NetCmdItemData:GetNetItemCount(DarkZoneGlobal.TimeLimitID)
    if self.costItemNumIsEnough == false then
      TipsManager.ShowBuyStamina()
    else
      local rewardList = {}
      for _, v in ipairs(self.rewardItemList) do
        rewardList[v.itemId] = v.itemNum == nil and 1 or v.itemNum
      end
      if TipsManager.CheckItemIsOverflowAndStopByList(rewardList) then
        return
      end
      local data = {}
      data.enterType = self.darkZoneMode
      if self.darkZoneMode == 1 then
        data.MapId = self.questData.quest_struct_scene_id
        data.QuestID = self.questData.id
        MapSelectUtils.currentQuestGroupID = NetCmdDarkZoneSeasonData:GetQuestGroupID(self.questData.id)
        data.TeleportId = self.MinimapOutsideGame.SelectedTeleportId
      elseif self.darkZoneMode == 2 then
        data.QuestID = self.endLessRewardData.id
        data.MapId = self.endlessData.map
      elseif self.darkZoneMode == 4 then
        self:ShowCafeMessageBox(data, self.OnClickCarrier)
        return
      end
      DarkZoneNetRepoCmdData:SendCS_DarkZoneStorage(self:CheckNeedAutoToBattle(data))
    end
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    if not pcall(function()
      DarkNetCmdStoreData.questCacheGroupId = 0
    end) then
      gfwarning("UIDarkZoneQuestInfoPanelItem\228\189\141\231\189\174\231\188\147\229\173\152\229\135\186\231\142\176\229\188\130\229\184\184")
    end
    UISystem:JumpToMainPanel()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Detail.gameObject).onClick = function()
    UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIDarkzoneModePointInfoDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Guide.gameObject).onClick = function()
    local showData = CS.ShowGuideDialogPPTData()
    showData.GroupId = 9001
    if NetCmdTeachPPTData:GetGroupIdsByType(CS.EPPTGroupType.All):IndexOf(showData.GroupId) ~= -1 then
      local showTeachData = CS.ShowTeachPPTData()
      showTeachData.GroupId = 9001
      UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIGuidePPTDialog, showTeachData)
    else
      UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIComGuideDialogV2PPT, showData)
    end
  end
  UIUtils.GetButtonListener(self.ui.mQuestBtn_Query.gameObject).onClick = function()
    local data = {}
    data[0] = true
    data[1] = self.eventItemList
    UIManager.OpenUIByParam(UIDef.UIDarkZoneEventDetailDialog, data)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnQuery.gameObject).onClick = function()
    local data = {}
    data.endlessId = self.endlessData.id
    UIManager.OpenUIByParam(UIDef.UIDarkZoneAirValueDialog, data)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Raid.gameObject).onClick = function()
    if self.costItemNumIsEnough == false then
      UISystem:JumpByID(2)
      return
    end
    if self.darkZoneMode ~= 4 then
      if self.canRaid == true then
        local rewardList = {}
        for _, v in ipairs(self.rewardItemList) do
          rewardList[v.itemId] = v.itemNum == nil and 1 or v.itemNum
        end
        if TipsManager.CheckItemIsOverflowAndStopByList(rewardList) then
          return
        end
        local wishItemIsEnough = false
        local wishItemList = TableData.listDarkzoneWishDatas:GetList()
        for i = 0, wishItemList.Count - 1 do
          local id = wishItemList[i].id
          local num = DarkZoneNetRepositoryData:GetItemNum(id)
          if 0 < num then
            wishItemIsEnough = true
            break
          end
        end
        local func
        if self.endlessData.wish == true and wishItemIsEnough == true then
          function func()
            local t = {}
            
            t[0] = self.endlessData.id
            t[1] = true
            t[2] = true
            t[3] = false
            t[6] = self.endLessRewardData.id
            UIManager.OpenUIByParam(UIDef.UIDarkZoneWishDialog, t)
          end
        else
          function func()
            local param = {
              OnDuringEndCallback = function()
                if self.endlessData.wish == true and wishItemIsEnough == true then
                  UIManager.CloseUI(UIDef.UIDarkZoneWishDialog)
                end
                UISystem:OpenCommonReceivePanel()
              end
            }
            local list = CS.LuaUtils.CreateArrayInstance(typeof(CS.System.UInt32), 4)
            DarkNetCmdStoreData:SendCS_DarkZoneEndLessRaid(self.endlessData.id, self.endLessRewardData.id, list, function()
              UIManager.OpenUIByParam(UIDef.UIRaidDuringPanel, param)
            end)
          end
        end
        MessageBox.Show(TableData.GetHintById(103081), TableData.GetHintById(240127), nil, func)
      else
        PopupMessageManager.PopupString(self.raidPopupStr)
      end
    elseif self.darkZoneMode == 4 then
      self:ShowCafeMessageBox(nil, self.CarrierRaid)
    end
  end
  for i = DarkZoneGlobal.EventType.Start, DarkZoneGlobal.EventType.End do
    UIUtils.GetButtonListener(self.ui["mBtn_Event" .. i].gameObject).onClick = function()
      local data = {}
      data[0] = true
      data[1] = self.eventItemList
      data[2] = i
      UIManager.OpenUIByParam(UIDef.UIDarkZoneEventDetailDialog, data)
    end
  end
  UIUtils.GetButtonListener(self.ui.mTrans_Query.gameObject).onClick = function()
    UIManager.OpenUIByParam(UIDef.UIDarkzoneMapCarrierRewardDialog, self.mData.id)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpDescription.gameObject).onClick = function()
    UIManager.OpenUIByParam(UIDef.UIDarkzoneMapCarrierRewardDialog, self.mData.id)
  end
end

function UIDarkZoneQuestPanel:AddEventListener()
  function self.OnUpdateItem()
    if self.costItem then
      self:RefreshCostItem(self.costItem)
    end
  end
  
  MessageSys:AddListener(CS.GF2.Message.CommonEvent.ItemUpdate, self.OnUpdateItem)
  MessageSys:AddListener(CS.GF2.Message.ModelDataEvent.StaminaUpdate, self.OnUpdateItem)
  MessageSys:AddListener(CS.GF2.Message.CampaignEvent.ResInfoUpdate, self.OnUpdateItem)
end

function UIDarkZoneQuestPanel:RemoveEventListener()
  MessageSys:RemoveListener(CS.GF2.Message.CommonEvent.ItemUpdate, self.OnUpdateItem)
  MessageSys:RemoveListener(CS.GF2.Message.ModelDataEvent.StaminaUpdate, self.OnUpdateItem)
  MessageSys:RemoveListener(CS.GF2.Message.CampaignEvent.ResInfoUpdate, self.OnUpdateItem)
end

function UIDarkZoneQuestPanel:ReFreshChestNum()
  for i = 1, 3 do
    local index = 4 - i
    local canvasGroup = self.ui["mCanvasGroup_Box" .. index]
    local numText = self.ui["mText_ChestNum" .. index]
    local totalNum = DarkNetCmdStoreData:GetDZQuestTotalChestByType(self.mData.id, i)
    setactive(canvasGroup, 0 < totalNum)
    local curNum = DarkNetCmdStoreData:GetDZQuestReceivedChest(self.mData.id, i)
    local a = totalNum <= curNum and 0.2 or 1
    canvasGroup.alpha = a
    numText.text = string_format(self.formatStr, curNum, totalNum)
  end
end

function UIDarkZoneQuestPanel:CarrierRaid()
  local itemData = self.questData
  if self.canRaid == true then
    local rewardList = {}
    for _, v in ipairs(self.rewardItemList) do
      rewardList[v.itemId] = v.itemNum == nil and 1 or v.itemNum
    end
    if TipsManager.CheckItemIsOverflowAndStopByList(rewardList) then
      return
    end
    local data = {}
    local maxNum = 999999999
    for i, v in pairs(itemData.SweepCost) do
      data.costItemId = i
      data.costItemNum = v
      local nowNum = NetCmdItemData:GetItemCountById(i)
      local maxNumTmp = nowNum // v
      maxNum = math.min(maxNum, maxNumTmp)
    end
    if maxNum <= 0 then
      local hint = TableData.GetHintById(193023)
      CS.PopupMessageManager.PopupString(hint)
      return
    end
    data.chapterId = itemData.id
    data.maxSweepsNum = maxNum
    local raidData = self:GetRaidLevel()
    if raidData == nil then
      return
    end
    local sweep_reward = raidData.sweep_reward
    local showData = UIUtils.GetKVSortItemTable(sweep_reward)
    data.rewardItemList = showData
    data.hintID = 193010
    data.textStr = string_format(TableData.GetHintById(271302), raidData.evaluate_level)
    
    function data.raidCallBack(raidTime, callBack)
      local activityID = NetCmdActivityDarkZone:GetCurrActivityID(SubmoduleType.ActivityDarkzone, NetCmdActivitySimData.offcialConfigId)
      NetCmdItemData:ClearUserDropCache()
      NetCmdActivityDarkZone:SendCS_DarkZoneRaid(self.darkZoneMode, self.questData.quest_id, activityID, raidTime, function(ret)
        local param = {
          OnDuringEndCallback = function()
            if ret ~= ErrorCodeSuc then
              return
            end
            self:onDuringEnd()
          end
        }
        UIManager.CloseUI(UIDef.UIRaidDialogV2)
        if ret ~= ErrorCodeSuc then
          return
        end
        UIManager.OpenUIByParam(UIDef.UIRaidDuringPanel, param)
      end)
    end
    
    if not TipsManager.CheckStaminaIsEnoughOnly(data.costItemNum) then
      TipsManager.ShowBuyStamina()
      return
    end
    UIManager.OpenUIByParam(UIDef.UIRaidDialogV2, data)
  else
    PopupMessageManager.PopupString(self.raidPopupStr)
  end
end

function UIDarkZoneQuestPanel:onDuringEnd()
  UISystem:OpenCommonReceivePanel({
    function()
      local data = NetCmdActivityDarkZone:GetEscortExchangeList()
      UIManager.OpenUIByParam(UIDef.UIDarkzoneCarrierRewardExchangeDialog, data)
    end
  })
end

function UIDarkZoneQuestPanel:GetRaidLevel()
  local stageInfo = NetCmdActivityDarkZone:GetDarkZoneStageInfo(self.questData.QuestId)
  local curScore = 0
  if stageInfo then
    curScore = stageInfo.Score
  end
  local raidIdList = TableData.listActivitySweepRewardBySweepPlanDatas:GetDataById(self.questData.sweep_plan).Id
  for i = 0, raidIdList.Count - 1 do
    local raidData = TableData.listActivitySweepRewardDatas:GetDataById(raidIdList[i])
    if raidData.point.Count == 1 then
      if curScore >= raidData.point[0] then
        return raidData
      end
    elseif raidData.point.Count == 2 and curScore >= raidData.point[0] and curScore <= raidData.point[1] then
      return raidData
    end
  end
  gferror("\232\135\170\229\190\139\229\135\186\231\142\176\229\188\130\229\184\184")
  return nil
end

function UIDarkZoneQuestPanel:BanBtn()
  self.ui.mBtn_Back.interactable = false
  self.ui.mBtn_Next.interactable = false
  self.ui.mBtn_Raid.interactable = false
end

function UIDarkZoneQuestPanel:OpenBtn()
  self.ui.mBtn_Back.interactable = true
  self.ui.mBtn_Next.interactable = true
  self.ui.mBtn_Raid.interactable = true
end

function UIDarkZoneQuestPanel:ShowCafeMessageBox(data, func)
  if self.darkZoneMode ~= 4 then
    return
  end
  local cafeTaskId = 0
  cafeTaskId = self.questData.TaskCheck
  if self:CheckCafeQuestFinish(cafeTaskId) then
    MessageBox.Show(TableData.GetHintById(64), TableData.GetHintById(self.questData.CheckHint), nil, function()
      func(self, data)
    end)
  else
    func(self, data)
  end
end

function UIDarkZoneQuestPanel:OnClickCarrier(data)
  data.MapId = self.questData.quest_struct_scene_id
  data.QuestID = self.mData.id
  data.activeID = NetCmdActivityDarkZone:GetCurrActivityID(SubmoduleType.ActivityDarkzone, NetCmdActivitySimData.offcialConfigId)
  gfdebug("ActivityCafeGlobal.LoadFinish:" .. tostring(ActivityCafeGlobal.LoadFinish))
  DarkZoneNetRepoCmdData:SendCS_DarkZoneStorage(self:CheckNeedAutoToBattle(data))
end

function UIDarkZoneQuestPanel:CheckCafeQuestFinish(cafeTaskId)
  return NetCmdActivityDarkZone:CheckCafeQuestFinish(cafeTaskId)
end

function UIDarkZoneQuestPanel:HasEnterReadyOk()
  local teamData = DarkNetCmdTeamData.Teams[0]
  if nil == teamData or 0 >= teamData.Guns.Count then
    gfdebug("\231\188\150\233\152\159\230\149\176\230\141\174\228\184\186\231\169\186\230\136\150\232\128\133\230\156\137\232\175\175")
    return false
  end
  local realCount = 0
  local gunCount = teamData.Guns.Count
  if teamData ~= nil and 0 < gunCount then
    for i = 0, gunCount - 1 do
      local gunID = teamData.Guns[i]
      if 0 < gunID then
        realCount = realCount + 1
      end
    end
  end
  return 4 <= realCount and 0 < teamData.Leader
end

function UIDarkZoneQuestPanel:CheckNeedAutoToBattle(UIData)
  local teamData = DarkNetCmdTeamData.Teams[0]
  local isReadyOk = self:HasEnterReadyOk()
  if true == isReadyOk then
    UIManager.OpenUIByParam(UIDef.UIDarkZoneTeamPanelV2, UIData)
    return
  end
  if isReadyOk == false then
    local list = DarkNetCmdTeamData:AutoToBattle()
    local listCount = list.Count - 1
    local gunlist = DarkNetCmdTeamData:ConstructData()
    local gunsCount = teamData.Guns.Count
    for i = 0, listCount do
      local id = list[i].GunId
      gunlist:Add(id)
      if i < gunsCount then
        teamData.Guns[i] = id
      else
        teamData.Guns:Add(id)
      end
    end
    local data = DarkZoneTeamData(0, gunlist, gunlist[0])
    teamData.Leader = gunlist[0]
    DarkNetCmdTeamData:SetTeamInfo(data, function()
      UIManager.OpenUIByParam(UIDef.UIDarkZoneTeamPanelV2, UIData)
    end)
  end
end

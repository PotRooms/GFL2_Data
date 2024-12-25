UIBattlePassGlobal = {}
UIBattlePassGlobal.ButtonType = {
  MainPanel = 1,
  Mission = 2,
  Collection = 3,
  Shop = 4
}
UIBattlePassGlobal.ButtonTypeHintText = {
  [1] = 192000,
  [2] = 192001,
  [3] = 192002,
  [4] = 192003
}
UIBattlePassGlobal.BpUnlockType = {Normal = 1, Plus = 2}
UIBattlePassGlobal.BpCollectionTabId = {Gun = 1, Weapon = 2}
UIBattlePassGlobal.BpTaskTypeShow = {
  Daily = 1,
  Weekly = 2,
  TaskNew = 3,
  TaskCooperation = 4
}
UIBattlePassGlobal.BpTaskDialogType = {
  RefreshDaily = 1,
  AddDaily = 2,
  AddShare = 3,
  RefreshWeek = 4
}
UIBattlePassGlobal.BpTaskGetType = {Extra = 1, Share = 2}
UIBattlePassGlobal.ShowModel = nil
UIBattlePassGlobal.BpShowSource = {MainPanel = 1, UnlockPanel = 2}
UIBattlePassGlobal.BpMainpanelRefreshType = {
  None = 0,
  FristShow = 1,
  ClickTab = 2,
  OnTop = 3,
  LevelUp = 4
}
UIBattlePassGlobal.BpBuyPromote2 = false
UIBattlePassGlobal.CurMaxItemIndex = 0
UIBattlePassGlobal.TempItemIndex = 0
UIBattlePassGlobal.CurBpMainpanelRefreshType = UIBattlePassGlobal.BpMainpanelRefreshType.FristShow
UIBattlePassGlobal.BpShowSourceType = UIBattlePassGlobal.BpShowSource.MainPanel
UIBattlePassGlobal.BpOutSideType = {bp = 1, bpOutSide = 2}
UIBattlePassGlobal.IsBpOutSide = UIBattlePassGlobal.BpOutSideType.bp
UIBattlePassGlobal.UnlockPanelBlackTime = 0.1
UIBattlePassGlobal.BpMainPanelBlackTime = 0
UIBattlePassGlobal.ModelList = {}
UIBattlePassGlobal.TabIndx = 0
UIBattlePassGlobal.IsVideoPlay = false
UIBattlePassGlobal.IsRefresh = false
UIBattlePassGlobal.RefreshKey = "BPRefreshTime"

function UIBattlePassGlobal.OpenBattlePassRewardBoxDialogInMail(mailId, fun)
  UIBattlePassGlobal.CurSelectType = UIBattlePassGlobal.SelectType.MailSingle
  UIBattlePassGlobal.MailId = mailId
  
  function UIBattlePassGlobal.FinishCallback(ret)
    fun(ret)
  end
end

function UIBattlePassGlobal.InitEffectNum(fun)
  local effectNumObjName = "ChrPowerUpPanelV3_Visual_Mesh"
  local modelCachePoolObj = UIBattlePassGlobal.ShowModel
  if modelCachePoolObj ~= nil then
    UIBattlePassGlobal.EffectNumObj = ResSys:GetUICharacter(effectNumObjName)
    UIBattlePassGlobal.EffectNumObj.transform:SetParent(modelCachePoolObj.transform)
    UIBattlePassGlobal.MoveAssetObj = ResSys:GetBpEffect("P_BattlePassTargetMover")
    UIBattlePassGlobal.MoveAssetObj.transform:SetParent(modelCachePoolObj.transform)
    UIBattlePassGlobal.EffectNumObjRoot = UIBattlePassGlobal.EffectNumObj.transform:Find("GrpEffectNum/Root").gameObject
    UIBattlePassGlobal.EffectNumAnimator = UIBattlePassGlobal.EffectNumObjRoot:GetComponent(typeof(CS.UnityEngine.Animator))
    UIBattlePassGlobal.EffectNumCollider = UIBattlePassGlobal.EffectNumObjRoot:GetComponent(typeof(CS.UnityEngine.Collider))
    UIBattlePassGlobal.EffectNumGFButton = UIBattlePassGlobal.EffectNumObjRoot:GetComponent(typeof(CS.UnityEngine.UI.GFButton))
    setrotation(UIBattlePassGlobal.EffectNumObj.transform, CS.UnityEngine.Quaternion.Euler(0, -180, 0))
    setactive(UIBattlePassGlobal.EffectNumObjRoot, not UIBattlePassGlobal.IsVideoPlay)
    setactive(UIBattlePassGlobal.EffectNumObj, true)
    UIUtils.GetButtonListener(UIBattlePassGlobal.EffectNumGFButton.gameObject).onClick = fun
  end
end

UIBattlePassGlobal.IsVideoPlay = false
UIBattlePassGlobal.CurSelectType = nil
UIBattlePassGlobal.SelectType = {
  BpSingle = 1,
  BpOneKey = 2,
  MailSingle = 3,
  MailReceiveAll = 4
}
UIBattlePassGlobal.FinishCallback = nil
UIBattlePassGlobal.MailId = 0

function UIBattlePassGlobal.RewardItemTabHasContain(rewardItemTab, itemId, itemNum)
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
  UIBattlePassGlobal.SortItemTable(rewardItemTab)
end

function UIBattlePassGlobal.SortItemTable(rewardItemTab)
  table.sort(rewardItemTab, function(a, b)
    local id1 = a.itemId or a.ItemId or a.itemID
    local id2 = b.itemId or b.ItemId or b.itemID
    local data1 = TableData.GetItemData(id1)
    local data2 = TableData.GetItemData(id2)
    local typeData1 = TableData.listItemTypeDescDatas:GetDataById(data1.type)
    local typeData2 = TableData.listItemTypeDescDatas:GetDataById(data2.type)
    if data1.type ~= data2.type and data1.type == GlobalConfig.ItemType.GiftPick then
      return true
    end
    if typeData1.rank ~= typeData2.rank then
      return typeData2.rank > typeData1.rank
    end
    if data1.type ~= data2.type then
      return data2.type > data1.type
    end
    if data1.rank ~= data2.rank then
      return data2.rank < data1.rank
    end
    return data1.Id > data2.Id
  end)
end

function UIBattlePassGlobal.CheckSelectReward(selectBaseReward, selectAdvanceReward)
  for level = NetCmdBattlePassData.BattlePassLevel, 1, -1 do
    local levelReward = TableData.listBpRewardDescDatas:GetDataById(NetCmdBattlePassData.CurSeason.reward_id * 1000 + level, true)
    if levelReward ~= nil then
      if NetCmdBattlePassData:CheckHasReward(true, level) == false then
        for k, v in pairs(levelReward.base_reward) do
          local itemData = TableData.GetItemData(k)
          if itemData.type == GlobalConfig.ItemType.GiftPick then
            selectBaseReward[level] = k
          end
        end
      end
      if NetCmdBattlePassData:CheckHasReward(false, level) == false then
        for k, v in pairs(levelReward.advanced_reward) do
          local itemData = TableData.GetItemData(k)
          if itemData.type == GlobalConfig.ItemType.GiftPick then
            selectAdvanceReward[level] = k
          end
        end
      end
    end
  end
end

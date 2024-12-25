FacilityBarrackGlobal = {}
FacilityBarrackGlobal.CommonPrefabPath = {
  ComPropsDetailsItem = "UICommonFramework/ComPropsDetailsItem.prefab"
}
FacilityBarrackGlobal.UnLockRichText = "{0}<size=32>/{1}</size>"
FacilityBarrackGlobal.ItemCountRichText = "<color=#333333>{0}</color>/{1}"
FacilityBarrackGlobal.ItemCountNotEnoughText = "<color=#FF5E41>{0}</color>/{1}"
FacilityBarrackGlobal.E3DModelType = gfenum({
  "eUnkown",
  "eGun",
  "eWeapon",
  "eEffect",
  "eVechicle"
}, -1)
FacilityBarrackGlobal.UIModel = nil
FacilityBarrackGlobal.SortTypeName = "SortType"
FacilityBarrackGlobal.GunDataDirty = false
FacilityBarrackGlobal.needUpdate = true
FacilityBarrackGlobal.CharacterDetailPanel = nil
FacilityBarrackGlobal.ContentType = {
  UIChrOverviewPanel = 1,
  UIChrStageUpPanel = 5,
  UIChrTalentPanel = 7
}
FacilityBarrackGlobal.ShowContentType = {
  UIChrOverview = 1,
  UIChrBattlePass = 2,
  UIChrBattlePassCollection = 3,
  UIGachaPreview = 4,
  UIBpClothes = 5,
  UIShopClothes = 6,
  UIClothesPreview = 7
}
FacilityBarrackGlobal.IsBattlePassMaxLevel = false
FacilityBarrackGlobal.CurShowContentType = nil
FacilityBarrackGlobal.CurSkinShowContentType = nil
FacilityBarrackGlobal.TargetContentType = nil
FacilityBarrackGlobal.EffectNumObj = nil
FacilityBarrackGlobal.EffectNumTMP = nil
FacilityBarrackGlobal.EffectNumAnimator = nil
FacilityBarrackGlobal.EffectNumCollider = nil
FacilityBarrackGlobal.EffectNumGFButton = nil
FacilityBarrackGlobal.ChangeGunEffect = nil
FacilityBarrackGlobal.ScreenPanelGunId = 0
FacilityBarrackGlobal.UIChrStageUpCoreId = 0
FacilityBarrackGlobal.GunSortType = {
  Level = 1,
  Rank = 2,
  Time = 3,
  Fight = 4
}
FacilityBarrackGlobal.GunSortCfg = {
  {
    "level",
    "rank",
    "id"
  },
  {
    "rank",
    "level",
    "id"
  },
  {
    "getTime",
    "uuid",
    "id"
  },
  {
    "fightingCapacity",
    "rank",
    "level",
    "id"
  }
}
FacilityBarrackGlobal.PowerUpName = {
  "LevelUp",
  "Equip",
  "Weapon",
  "Upgrade"
}
FacilityBarrackGlobal.CameraType = {
  Base = "Base",
  Shot = "Shot",
  Weapon = "Weapon",
  WeaponToucher = "WeaponToucher"
}
FacilityBarrackGlobal.PowerUpType = {
  LevelUp = 1,
  Equip = 3,
  Weapon = 4,
  Upgrade = 5,
  GunTalent = 6
}
FacilityBarrackGlobal.ShowAttributeLength = 5
FacilityBarrackGlobal.ShowAttribute = {
  "pow",
  "max_hp",
  "shield_armor",
  "crit_mult",
  "max_will_value"
}
FacilityBarrackGlobal.ShowAttributeOnPc = {"crit", "crit_mult"}
FacilityBarrackGlobal.ShowSKillAttr = {
  "potential_total_value",
  "cd_time",
  "potential_cost",
  "skill_points"
}
FacilityBarrackGlobal.SkillAttrNameHintIds = {102062, 102064}
FacilityBarrackGlobal.PressType = {Plus = 1, Minus = 2}
FacilityBarrackGlobal.SortHint = {
  101001,
  101002,
  101003,
  101007
}
FacilityBarrackGlobal.SortType = {
  sortType = FacilityBarrackGlobal.GunSortType.Time,
  isAscend = true
}
FacilityBarrackGlobal.AttributeShowType = {
  Gun = 1,
  Weapon = 2,
  Robot = 3
}
FacilityBarrackGlobal.CurBattleSkillDataList = {}
FacilityBarrackGlobal.ChrAnimTriggerType = {
  Entrance = "BarrackEntrance",
  BarrackIdle = "BarrackIdle",
  BattleIdle = "battleIdle",
  Reload = "reload",
  BarrackUpgradeEnding = "BarrackUpgradeEnding"
}
FacilityBarrackGlobal.ShowingGunId = nil

function FacilityBarrackGlobal:GetLockGunData(id)
  local gun = {}
  local gunData = NetCmdTeamData:GetLockGunData(id)
  gun.id = id
  gun.uuid = GFUtils.GetLongMaxValue()
  gun.level = 0
  gun.getTime = 0
  gun.rank = gunData.rank
  gun.fightingCapacity = gunData.fightingCapacity
  gun.duty = gunData.TabGunData.Duty
  return gun
end

function FacilityBarrackGlobal:GetPressParam()
  local data = string.split(TableData.GlobalConfigData.GunLevelUpItemAddSpeed, ":")
  return tonumber(data[1]), tonumber(data[2])
end

function FacilityBarrackGlobal:IsMainProp(str)
  for _, prop in ipairs(FacilityBarrackGlobal.ShowAttribute) do
    if prop == str then
      return true
    end
  end
  return false
end

function FacilityBarrackGlobal:GetSystemIsUnlock(data, index)
  if data then
    local pram = data & index
    return pram ~= 0
  end
end

function FacilityBarrackGlobal:SetSortType(sortType)
  if sortType then
    FacilityBarrackGlobal.SortType.sortType = sortType.sortType
    FacilityBarrackGlobal.SortType.isAscend = sortType.isAscend
  end
end

function FacilityBarrackGlobal:SaveSortType()
  local sortType = tostring(FacilityBarrackGlobal.SortType.sortType)
  local isAscend = tostring(FacilityBarrackGlobal.SortType.isAscend and 1 or 0)
  local str = sortType .. "," .. isAscend
  CS.GameSettingConfig.SetString(FacilityBarrackGlobal.SortTypeName, str)
end

function FacilityBarrackGlobal:ParseSortType()
  local str = CS.GameSettingConfig.GetString(FacilityBarrackGlobal.SortTypeName)
  if str ~= "" then
    local strArr = string.split(str, ",")
    FacilityBarrackGlobal.SortType.sortType = tonumber(strArr[1])
    FacilityBarrackGlobal.SortType.isAscend = tonumber(strArr[2]) == 1 and true or false
  end
end

function FacilityBarrackGlobal:GetSortFunc(startIndex, sortCfg, isAscend)
  isAscend = isAscend ~= false and true or false
  local tArrRefer = sortCfg
  local tLength = #tArrRefer
  if tLength == 0 or startIndex < 1 or startIndex > tLength then
    return nil
  end
  
  local function compareFunction(a1, a2, index)
    if index <= tLength then
      local attrName = tArrRefer[index]
      if index <= tLength then
        if a1[attrName] < a2[attrName] then
          return isAscend
        elseif a1[attrName] > a2[attrName] then
          return not isAscend
        else
          return compareFunction(a1, a2, index + 1)
        end
      else
        return false
      end
    end
    return false
  end
  
  return function(a1, a2)
    return compareFunction(a1, a2, startIndex)
  end
end

function FacilityBarrackGlobal:GetFirstDutyGunData(duty)
  local stcGunDataTable = {}
  for i = 0, TableData.listGunDatas.Count - 1 do
    local gunData = TableData.listGunDatas[i]
    if stcGunDataTable[gunData.duty] == nil then
      stcGunDataTable[gunData.duty] = {}
    end
    table.insert(stcGunDataTable[gunData.duty], gunData.id)
  end
  local tempGunList = {}
  for _, stcGunDataTableByDuty in pairs(stcGunDataTable) do
    if stcGunDataTableByDuty then
      for _, gunId in ipairs(stcGunDataTableByDuty) do
        local data = NetCmdTeamData:GetGunByID(gunId)
        if data == nil then
          data = FacilityBarrackGlobal:GetLockGunData(gunId)
        end
        table.insert(tempGunList, data)
      end
    end
  end
  local sortFunc = FacilityBarrackGlobal:GetSortFunc(1, FacilityBarrackGlobal.GunSortCfg[1], false)
  table.sort(tempGunList, sortFunc)
  for _, data in pairs(tempGunList) do
    if type(data) == "table" then
      if data.duty == duty then
        return gunCmdData.id
      end
    elseif data.TabGunData.Duty == duty then
      return data.TabGunData.Id
    end
  end
  NetCmdTeamData:GetGun(0)
end

function FacilityBarrackGlobal:SwitchCameraPos(barrackCameraStandType, needBlending)
  local cameraCtrl = UISystem.BarrackCharacterCameraCtrl
  if not cameraCtrl then
    gferror("\230\178\161\230\156\137\230\137\190\229\136\176cameraCtrl")
    return
  end
  if needBlending == nil then
    needBlending = true
  end
  if barrackCameraStandType == BarrackCameraStand.Base then
    cameraCtrl:ChangeCameraStand(BarrackCameraStand.Base, needBlending)
  elseif barrackCameraStandType == BarrackCameraStand.Shot then
    self:ChangeChrAnim(FacilityBarrackGlobal.ChrAnimTriggerType.BattleIdle)
    cameraCtrl:ChangeCameraStand(BarrackCameraStand.Shot, needBlending)
    local model = CS.UIBarrackModelManager.Instance.curModel
    if not model or CS.LuaUtils.IsNullOrDestroyed(model) or CS.LuaUtils.IsNullOrDestroyed(model.transform) then
      gferror("\229\189\147\229\137\141\230\168\161\229\158\139\228\184\186\231\169\186!")
      return
    end
    local target
    local modelBonesGroup = model.gameObject:GetComponent(typeof(CS.UI._3DModel.FacilityBarrack.ModelBonesGroup))
    if modelBonesGroup ~= nil then
      target = modelBonesGroup.Head
    end
    if target == nil then
      target = model.transform:Find("Bip001/Bip001 Pelvis/Bip001 Spine/Bip001 Spine1/Bip001 Spine2/Bip001 Neck/Bip001 Head")
    end
    cameraCtrl:SetCurVcamFollow(target)
    cameraCtrl:SetCurVcamLookAt(target)
  elseif barrackCameraStandType == BarrackCameraStand.Weapon then
    cameraCtrl:ChangeCameraStand(BarrackCameraStand.Weapon, needBlending)
  elseif barrackCameraStandType == BarrackCameraStand.WeaponToucher then
    cameraCtrl:ChangeCameraStand(BarrackCameraStand.WeaponToucher, needBlending)
  elseif barrackCameraStandType == BarrackCameraStand.StageUp then
    cameraCtrl:ChangeCameraStand(BarrackCameraStand.StageUp, needBlending)
  elseif barrackCameraStandType == BarrackCameraStand.LookAt then
    cameraCtrl:ChangeCameraStand(BarrackCameraStand.LookAt, needBlending)
  end
end

function FacilityBarrackGlobal:GetVirtualCameraByCameraStand(barrackCameraStandType)
  local cameraCtrl = UISystem.BarrackCharacterCameraCtrl
  local virtualCamera = cameraCtrl:GetVirtualCameraByCameraStand(barrackCameraStandType)
  return virtualCamera
end

function FacilityBarrackGlobal:ChangeChrAnim(animName)
  CS.UIBarrackModelManager.Instance:ChangeChrAnim(animName)
end

function FacilityBarrackGlobal.GetCurCameraStand()
  local cameraCtrl = UISystem.BarrackCharacterCameraCtrl
  if not cameraCtrl then
    gferror("\230\178\161\230\156\137\230\137\190\229\136\176cameraCtrl")
    return
  end
  return cameraCtrl.CurCameraStand
end

function FacilityBarrackGlobal.SetNeedBarrackEntrance(enable)
  CS.UIBarrackModelManager.Instance.needBarrackEntrance = enable
end

function FacilityBarrackGlobal.GetNeedBarrackEntrance()
  return CS.UIBarrackModelManager.Instance.needBarrackEntrance
end

function FacilityBarrackGlobal.GetCharacterDetailPanel()
  return FacilityBarrackGlobal.CharacterDetailPanel
end

function FacilityBarrackGlobal.SetTargetContentType(contentType)
  FacilityBarrackGlobal.TargetContentType = contentType
end

function FacilityBarrackGlobal.GetTargetContentType()
  return FacilityBarrackGlobal.TargetContentType
end

function FacilityBarrackGlobal.IsFirstWatchingLevelUpTimeline(gunId)
  local uid = AccountNetCmdHandler.Uid
  local key = uid .. "WatchedLevelUpTimeline" .. gunId
  return PlayerPrefs.GetInt(key) ~= 1
end

function FacilityBarrackGlobal.WatchedLevelUpTimeline(gunId)
  local uid = AccountNetCmdHandler.Uid
  local key = uid .. "WatchedLevelUpTimeline" .. gunId
  PlayerPrefs.SetInt(key, 1)
  FacilityBarrackGlobal.TodayWatchedLevelUpTimeline(gunId)
end

function FacilityBarrackGlobal.IsFirstWatchingBreakTimeline(gunId)
  local uid = AccountNetCmdHandler.Uid
  local key = uid .. "WatchedBreakTimeline" .. gunId
  return PlayerPrefs.GetInt(key) ~= 1
end

function FacilityBarrackGlobal.WatchedBreakTimeline(gunId)
  local uid = AccountNetCmdHandler.Uid
  local key = uid .. "WatchedBreakTimeline" .. gunId
  PlayerPrefs.SetInt(key, 1)
  FacilityBarrackGlobal.TodayWatchedBreakTimeline(gunId)
end

function FacilityBarrackGlobal.IsTodayFirstWatchLevelUpTimeline(gunId)
  local uid = AccountNetCmdHandler.Uid
  local key = uid .. "TodayWatchedLevelUpTimeline" .. gunId .. CS.TimeUtils.GetTodayStr()
  return PlayerPrefs.GetInt(key) ~= 1
end

function FacilityBarrackGlobal.TodayWatchedLevelUpTimeline(gunId)
  local uid = AccountNetCmdHandler.Uid
  local key = uid .. "TodayWatchedLevelUpTimeline" .. gunId .. CS.TimeUtils.GetTodayStr()
  PlayerPrefs.SetInt(key, 1)
end

function FacilityBarrackGlobal.IsTodayFirstWatchBreakTimeline(gunId)
  local uid = AccountNetCmdHandler.Uid
  local key = uid .. "TodayWatchedBreakTimeline" .. gunId .. CS.TimeUtils.GetTodayStr()
  return PlayerPrefs.GetInt(key) ~= 1
end

function FacilityBarrackGlobal.TodayWatchedBreakTimeline(gunId)
  local uid = AccountNetCmdHandler.Uid
  local key = uid .. "TodayWatchedBreakTimeline" .. gunId .. CS.TimeUtils.GetTodayStr()
  PlayerPrefs.SetInt(key, 1)
end

function FacilityBarrackGlobal.GetBarrackModelCachePoolObj()
  return CS.UIBarrackModelManager.Instance.barrackModelCachePoolObj
end

FacilityBarrackGlobal.IsFirstLoadEffect = false

function FacilityBarrackGlobal.GetIsEffectNumObjLoad()
  return CS.UIBarrackModelManager.Instance.IsEffectNumObjLoad
end

function FacilityBarrackGlobal.SetIsEffectNumObjLoad(boolean)
  CS.UIBarrackModelManager.Instance.IsEffectNumObjLoad = boolean
end

function FacilityBarrackGlobal.HideEffectNum(boolean)
  local hideEffectNum = function()
    if boolean == nil then
      boolean = false
    end
    if boolean and not FacilityBarrackGlobal.EffectNumObj.activeSelf then
      setactive(FacilityBarrackGlobal.EffectNumObj, true)
    end
    if boolean then
      FacilityBarrackGlobal.EffectNumAnimator:ResetTrigger("FadeOut")
      FacilityBarrackGlobal.EffectNumAnimator:SetTrigger("FadeIn")
    else
      FacilityBarrackGlobal.EffectNumAnimator:ResetTrigger("FadeIn")
      FacilityBarrackGlobal.EffectNumAnimator:SetTrigger("FadeOut")
    end
    FacilityBarrackGlobal.EffectNumCollider.enabled = boolean
    FacilityBarrackGlobal.EffectNumGFButton.interactable = boolean
    FacilityBarrackGlobal.SetEffectNumRedPoint()
  end
  if FacilityBarrackGlobal.IsEffectNumObjNull() then
    FacilityBarrackGlobal.InitEffectNum(function()
      hideEffectNum()
    end)
    return
  else
    hideEffectNum()
  end
end

function FacilityBarrackGlobal.ActiveEffectNum(boolean)
  if not FacilityBarrackGlobal.IsEffectNumObjNull() then
    setactive(FacilityBarrackGlobal.EffectNumObj, boolean)
  end
end

function FacilityBarrackGlobal.SetEffectNum(num)
  if FacilityBarrackGlobal.IsEffectNumObjNull() then
    FacilityBarrackGlobal.InitEffectNum()
  else
    FacilityBarrackGlobal.HideEffectNum(true)
  end
end

function FacilityBarrackGlobal.InitEffectNum(func)
  if FacilityBarrackGlobal.GetIsEffectNumObjLoad() then
    return
  end
  local effectNumObjName = "ChrPowerUpPanelV3_Visual_Mesh"
  local barrackModelCachePoolObj = FacilityBarrackGlobal.GetBarrackModelCachePoolObj()
  if barrackModelCachePoolObj ~= nil then
    FacilityBarrackGlobal.SetIsEffectNumObjLoad(true)
    ResSys:GetUICharacterAsyn(effectNumObjName, function(str, o, userData)
      FacilityBarrackGlobal.EffectNumObj = o
      FacilityBarrackGlobal.IsFirstLoadEffect = true
      FacilityBarrackGlobal.EffectNumObj.transform:SetParent(barrackModelCachePoolObj.transform)
      local tmpObj = FacilityBarrackGlobal.EffectNumObj.transform:Find("GrpEffectNum/Root").gameObject
      FacilityBarrackGlobal.EffectNumAnimator = tmpObj:GetComponent(typeof(CS.UnityEngine.Animator))
      FacilityBarrackGlobal.EffectNumCollider = tmpObj:GetComponent(typeof(CS.UnityEngine.Collider))
      FacilityBarrackGlobal.EffectNumGFButton = tmpObj:GetComponent(typeof(CS.UnityEngine.UI.GFButton))
      FacilityBarrackGlobal.EffectNumRedPoint = tmpObj.transform:Find("RedPoint").gameObject
      FacilityBarrackGlobal.ActiveEffectNum(false)
      if func ~= nil then
        func()
      end
    end)
  end
end

function FacilityBarrackGlobal.SetEffectNumPosition(offsetY)
  if FacilityBarrackGlobal.IsEffectNumObjNull() then
    FacilityBarrackGlobal.InitEffectNum()
  else
    local tmpPos = FacilityBarrackGlobal.EffectNumObj.transform.position
    tmpPos = Vector3(tmpPos.x, offsetY, tmpPos.z)
    FacilityBarrackGlobal.EffectNumObj.transform.position = tmpPos
  end
end

function FacilityBarrackGlobal.SetVisualOnClick(func)
  if FacilityBarrackGlobal.IsEffectNumObjNull() then
    FacilityBarrackGlobal.InitEffectNum(function()
      UIUtils.GetButtonListener(FacilityBarrackGlobal.EffectNumAnimator.gameObject).onClick = func
    end)
  else
    UIUtils.GetButtonListener(FacilityBarrackGlobal.EffectNumAnimator.gameObject).onClick = func
  end
end

function FacilityBarrackGlobal.IsEffectNumObjNull()
  local hasNotObj = FacilityBarrackGlobal.EffectNumObj == nil or CS.LuaUtils.IsNullOrDestroyed(FacilityBarrackGlobal.EffectNumObj)
  return hasNotObj
end

function FacilityBarrackGlobal.ReleaseEffectNumObj()
  ResourceManager:DestroyInstance(FacilityBarrackGlobal.EffectNumObj)
  FacilityBarrackGlobal.IsFirstLoadEffect = false
  FacilityBarrackGlobal.SetIsEffectNumObjLoad(false)
end

FacilityBarrackGlobal.EffectNumRedPoint = nil

function FacilityBarrackGlobal.SetEffectNumRedPoint()
  if FacilityBarrackGlobal.IsEffectNumObjNull() then
    return
  end
  if FacilityBarrackGlobal.EffectNumRedPoint == nil or CS.LuaUtils.IsNullOrDestroyed(FacilityBarrackGlobal.EffectNumRedPoint) then
    return
  end
  if FacilityBarrackGlobal.EffectNumRedPoint ~= nil then
    local showRedPoint = CS.NetCmdBarrackCameraData.Instance:CheckRedPoint()
    local topUI = UISystem:GetTopUI(UIGroupType.Default)
    local boolean1 = topUI ~= nil and topUI.UIDefine.UIType == UIDef.UIChrPowerUpPanel
    local boolean2 = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrOverview
    setactive(FacilityBarrackGlobal.EffectNumRedPoint, showRedPoint and boolean1 and boolean2)
  end
end

function FacilityBarrackGlobal.ShowChangeGunEffect()
  if FacilityBarrackGlobal.ChangeGunEffect == nil then
    FacilityBarrackGlobal.InitChangeGunEffect()
  end
  setactive(FacilityBarrackGlobal.ChangeGunEffect, false)
  setactive(FacilityBarrackGlobal.ChangeGunEffect, true)
end

function FacilityBarrackGlobal.InitChangeGunEffect()
  if FacilityBarrackGlobal.ChangeGunEffect == nil or CS.LuaUtils.IsNullOrDestroyed(FacilityBarrackGlobal.ChangeGunEffect) then
    local barrackModelCachePoolObj = FacilityBarrackGlobal.GetBarrackModelCachePoolObj()
    if barrackModelCachePoolObj ~= nil then
      FacilityBarrackGlobal.ChangeGunEffect = ResSys:GetUICharacter(effectNumObjName)
      FacilityBarrackGlobal.ChangeGunEffect.transform:SetParent(barrackModelCachePoolObj.transform)
    end
  else
    return
  end
end

function FacilityBarrackGlobal.PercentValue(value, decimalNum)
  if decimalNum == nil then
    decimalNum = 1
  end
  return CS.LuaUIUtils.GetPercentValue(value, decimalNum)
end

FacilityBarrackGlobal.GunMaxGrade = 0

function FacilityBarrackGlobal.GetGunMaxGrade()
  if FacilityBarrackGlobal.GunMaxGrade == 0 then
    FacilityBarrackGlobal.GunMaxGrade = TableData.GlobalSystemData.GunMaxGrade
  end
  return FacilityBarrackGlobal.GunMaxGrade
end

FacilityBarrackGlobal.WeaponPartReplaceSlotIndex = 0

function FacilityBarrackGlobal.SetWeaponPartReplaceSlotIndex(value)
  FacilityBarrackGlobal.WeaponPartReplaceSlotIndex = value
end

function FacilityBarrackGlobal.GetWeaponPartReplaceSlotIndex()
  return FacilityBarrackGlobal.WeaponPartReplaceSlotIndex
end

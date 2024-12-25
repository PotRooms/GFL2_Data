UITalentGlobal = {}
UITalentGlobal.TalentState = {
  Lock = 0,
  PrevConditionLock = 1,
  Unauthorized = 2,
  Authorized = 3
}
UITalentGlobal.TalentType = {
  NormalAttribute = 1,
  AdvancedAttribute = 2,
  PrivateTalentKey = 3
}

function UITalentGlobal.GetTalentType(groupId)
  local groupData = TableData.listSquadTalentGroupDatas:GetDataById(groupId)
  if not groupData then
    gferror("\230\173\164\229\164\169\232\181\139\231\177\187\229\158\139\230\156\170\229\174\154\228\185\137!!!")
    return
  end
  return groupData.PointType
end

function UITalentGlobal.GetGunTalentState(talentId, groupId)
  return NetCmdTalentData:GetGunTalentState(talentId, groupId)
end

function UITalentGlobal.IsUnlockedGunTalentFeature(gunId)
  return NetCmdTalentData:IsUnlockedGunTalentFeature(gunId)
end

function UITalentGlobal.GetTargetGeneData(groupId, level)
  return NetCmdTalentData:GetTargetGeneData(groupId, level)
end

function UITalentGlobal.GetTargetGeneDataByGroupData(groupData, level)
  return UITalentGlobal.GetTargetGeneData(groupData.PointId, level)
end

function UITalentGlobal.GetTargetGunDutyData(dutyId)
  local gunDutyDataList = TableData.listGunDutyDatas:GetList()
  for i = 0, gunDutyDataList.Count - 1 do
    local gunDutyData = gunDutyDataList[i]
    if gunDutyData.Id == dutyId then
      return gunDutyData
    end
  end
end

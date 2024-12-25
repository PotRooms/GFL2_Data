require("UI.DarkZonePanel.UIDarkZoneQuestInfoPanel.UIDarkZoneQuestInfoPanel")
require("UI.DarkZonePanel.UIDarkZoneNPCSelectPanel.UIDarkZoneStorePanel.DZStoreUtils")
require("UI.DarkZonePanel.UIDarkZoneMainPanel.item.DZMainEnterFunctionItem")
require("UI.DarkZonePanel.UIDarkZoneMainPanel.UIDarkZoneMainPanelView")
require("UI.DarkZonePanel.UIDarkZoneModePanel.DarkZoneGlobal")
require("UI.DarkZonePanel.UIDarkZoneModePanel.UIDarkZoneModePanel")
require("UI.ActivityTheme.Cafe.ActivityCafeGlobal")
require("UI.UIBasePanel")
UIDarkZoneMainPanel = class("UIDarkZoneMainPanel", UIBasePanel)
UIDarkZoneMainPanel.__index = UIDarkZoneMainPanel

function UIDarkZoneMainPanel:ctor(csPanel)
  UIDarkZoneMainPanel.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
  csPanel.Is3DPanel = true
  self.mCSPanel = csPanel
end

function UIDarkZoneMainPanel:OnAwake(root, data)
end

function UIDarkZoneMainPanel:OnSave()
  self.hasCache = false
end

function UIDarkZoneMainPanel:OnInit(root, data)
  self:SetRoot(root)
  self.mview = UIDarkZoneMainPanelView.New()
  self.ui = {}
  self.mview:InitCtrl(root, self.ui)
  self.exploreItem = nil
  self.modeScheduleList = {}
  self.modeScheduleListTimer = {}
  setactive(self.ui.mBtn_Season, false)
  self:AddBtnListen()
  self:InitBaseData()
  self:AutoToBattle()
  self:AddEventListener()
  self:CountDownDarkzone()
  self:SendNetData()
  self.closeTime = 0
  UIManager.EnableDarkZoneTeam(true)
  self.DarkZoneTeamCameraCtrl = CS.DarkZoneTeamCameraCtrl.Instance
  self:UpdateTeamList()
  if self.isFirstIn == true then
    self.isFirstIn = false
  end
  RedPointSystem:GetInstance():UpdateRedPointByType(RedPointConst.DarkZoneQuest)
  self:UpdateQuestRedPoint()
end

function UIDarkZoneMainPanel:OnCameraStart()
  return self.closeTime
end

function UIDarkZoneMainPanel:OnCameraBack()
  return self.closeTime
end

function UIDarkZoneMainPanel:AutoToBattle()
  DarkNetCmdTeamData:CopyTeamList()
  local teamData = DarkNetCmdTeamData.Teams[0]
  local realCount = 0
  local gunCount = DarkNetCmdTeamData.Teams[0].Guns.Count
  for i = 0, gunCount - 1 do
    local gunID = teamData.Guns[i]
    if 0 < gunID then
      realCount = realCount + 1
    end
  end
  if teamData.Leader == 0 or realCount ~= 4 then
    local list = DarkNetCmdTeamData:AutoToBattle()
    local listCount = list.Count - 1
    local gunlist = DarkNetCmdTeamData:ConstructData()
    local gunsCount = teamData.Guns.Count
    for i = 0, listCount do
      local id = list[i].GunId
      gunlist:Add(id)
      if i < gunsCount then
        DarkNetCmdTeamData.Teams[0].Guns[i] = id
      else
        DarkNetCmdTeamData.Teams[0].Guns:Add(id)
      end
    end
    local data = DarkZoneTeamData(0, gunlist, gunlist[0])
    DarkNetCmdTeamData.Teams[0].Leader = gunlist[0]
    DarkNetCmdTeamData:SetTeamInfo(data)
  end
end

function UIDarkZoneMainPanel:InitDarkZoneGlobalLevel()
end

function UIDarkZoneMainPanel:SendNetData()
  DarkZoneNetRepositoryData:SendCS_DarkZoneStorage()
end

function UIDarkZoneMainPanel:OnBackFrom()
  DarkNetCmdTeamData:CopyTeamList()
  UIDarkZoneTeamModelManager:HideOrShowModel(false)
  self:UpdateTeamList()
  self:UpdateAllModel()
  self:ResSysLoadAsyncIsAllFinish(false)
  self:ResetCameraPos()
  self:RefreshSeasonData()
end

function UIDarkZoneMainPanel:OnAdditiveSceneLoaded(loadedScene, isOpen)
  self.mScene = loadedScene
end

function UIDarkZoneMainPanel:OnShowStart()
  self:UpdateAllModel()
  self:RefreshSeasonData()
  if GFUtils.IsOverseaServer() then
    self:CloseBtnClick()
  end
end

function UIDarkZoneMainPanel:OnShowFinish()
  RedPointSystem:GetInstance():UpdateRedPointByType(RedPointConst.DarkZoneQuest)
  self:UpdateQuestRedPoint()
  if self.carrierPanel and self.carrierPanel.mIsUnLock then
    self.carrierPanel:RefreshRedDot(NetCmdActivityDarkZone:GetDarkZoneCarrierRedPoint(NetCmdActivitySimData.offcialConfigId) > 0 and self.carrierPanel.mIsUnLock)
  end
  for i = 1, #self.itemList do
    if self.itemList[i].isQuestType then
      self.itemList[i]:SetQuestState()
    elseif self.itemList[i].modeType == nil then
      self.itemList[i]:RefreshLockState()
    else
      self.itemList[i]:SetActivityState()
    end
  end
  self:UpdateModeSchedule()
  NetCmdRecentActivityData:RecordEnterRecentActivityDarkZonePanel()
end

function UIDarkZoneMainPanel:CountDownDarkzone()
  local modeData = TableData.listDarkzoneModeScheduleDatas:GetDataById(1001)
  if modeData then
    self.ui.mCountTime:StartCountdown(modeData.EndTime)
  end
  self.ui.mCountTime:AddFinishCallback(function(succ)
    self:CloseBtnClick()
  end)
end

function UIDarkZoneMainPanel:OnHide()
end

function UIDarkZoneMainPanel:OnUpdate(deltatime)
end

function UIDarkZoneMainPanel:OnRecover()
  self:OnShowStart()
end

function UIDarkZoneMainPanel:OnClose()
  self:ClearModeTimer()
  self:ReleaseTimers()
  self.starttimeArr = nil
  self.endtimeArr = nil
  self.IsInEditor = nil
  self.NpcStoreItemDic = nil
  self.IsJudgeRedPointByItemLimit = nil
  self.craftHasUnlock = nil
  self.unLockTips = nil
  self.questItem = nil
  self.exploreItem = nil
  self.TeamDataDic = nil
  self.carrierPanel = nil
  for i = 0, self.maxEffectNum do
    local obj = self.changeGunEffect[i]
    ResourceDestroy(obj)
  end
  self.changeGunEffect = nil
  self.maxEffectNum = nil
  self.loadEffectNum = nil
  MessageSys:RemoveListener(UIEvent.OnDarkZonePlanUpdate, self.InitDarkZoneGlobalLevel)
  self.favorChangeFunc = nil
  self.ui = nil
  self.mview = nil
  self.super.OnRelease(self)
  for i = 1, #self.itemList do
    self.itemList[i]:OnClose()
  end
  for i = 1, #self.modeScheduleList do
    self.modeScheduleList[i]:OnClose()
  end
  self.itemList = nil
  self.modeScheduleList = nil
  self.formatStr = nil
  self.isFirstIn = nil
  UIManager.EnableDarkZoneTeam(false)
  UIDarkZoneTeamModelManager:Release()
  DarkNetCmdTeamData:UnloadTeamAssets()
  self.DarkZoneTeamCameraCtrl = nil
end

function UIDarkZoneMainPanel:OnRelease()
  self.hasCache = false
end

function UIDarkZoneMainPanel:IsReadyToStartTutorial()
  if NetCmdDarkZoneSeasonData.FinishPlanID > 0 then
    return false
  end
  return true
end

function UIDarkZoneMainPanel:InitBaseData()
  self.NpcStoreItemDic = {}
  self.IsJudgeRedPointByItemLimit = false
  local unlockData = TableData.listUnlockDatas:GetDataById(28001)
  local str = UIUtils.CheckUnlockPopupStr(unlockData)
  self.unLockTips = str
  self.formatStr = TableData.GetHintById(240010)
  self.TeamDataDic = {}
  self.ui.mUICountdown_LeftTime:AddFinishCallback(function(succ)
    if succ == true then
      self:DelayCall(0.5, function()
        NetCmdRecentActivityData:ReqPlanActivityData(PlanType.PlanFunctionDarkzone, function(ret)
        end)
      end)
    end
  end)
  self.isFirstIn = true
  self.changeGunEffect = {}
  self.maxEffectNum = 3
  self.loadEffectNum = 0
  for i = 0, self.maxEffectNum do
    ResSys:GetEffectAsync("Effect_sum/Other/EFF_Command_Character_Switch", function(path, go, data)
      if go ~= nil then
        if self.changeGunEffect ~= nil then
          self.changeGunEffect[i] = go
          self.changeGunEffect[i]:SetActive(false)
          self.loadEffectNum = self.loadEffectNum + 1
          self:ResSysLoadAsyncIsAllFinish()
        else
          ResourceDestroy(go)
        end
      end
    end)
  end
  self.cacheIndex = 0
  self.maxCacheIndex = 0
end

function UIDarkZoneMainPanel:SetItemList()
  self.itemList = {}
  local item
  item = DZMainEnterFunctionItem.New()
  item:InitCtrl(self.ui.mTrans_Bottom)
  item:SetData(240131, nil, function()
    self:EnterTeam()
    self.closeTime = 0.01
  end, 28003)
  item:SetImage("Icon_DarkzoneEnter_Fleet")
  table.insert(self.itemList, item)
  self:UpdateModeSchedule()
end

function UIDarkZoneMainPanel:ShowModeSchedule(isShow)
  for i = 1, #self.modeScheduleList do
    self.modeScheduleList[i]:SetVisible(isShow)
  end
end

function UIDarkZoneMainPanel:UpdateModeSchedule()
  self:ShowModeSchedule(false)
  self:ClearModeTimer()
  local CurTime = CGameTime:GetTimestamp()
  local modeScheduleList = TableData.listDarkzoneModeScheduleDatas:GetList()
  for i = 0, modeScheduleList.Count - 1 do
    local modeScheduleData = TableData.listDarkzoneModeScheduleDatas:GetDataById(modeScheduleList[i].Id)
    if CurTime >= modeScheduleData.StartTime and CurTime <= modeScheduleData.EndTime or modeScheduleData.StartTime == 0 and modeScheduleData.EndTime == 0 then
      do
        local item = self.modeScheduleList[i + 1]
        if item == nil then
          item = DZMainEnterFunctionItem.New()
          item:InitCtrl(self.ui.mTrans_ModeList)
        end
        item:SetVisible(true)
        item:SetModeScheduleData(modeScheduleData.name.str, nil, function()
          local CurTimeNow = CGameTime:GetTimestamp()
          if modeScheduleData.StartTime ~= 0 and modeScheduleData.EndTime ~= 0 and (CurTimeNow < modeScheduleData.StartTime or CurTimeNow > modeScheduleData.EndTime) then
            self:UpdateModeSchedule()
            return
          end
          if modeScheduleData.Function == 1 then
            UIManager.OpenUIByParam(UIDef.UIDarkzoneQuestChapterPanel, modeScheduleData.Id)
          else
            UIManager.OpenUIByParam(UIDef.UIDarkZoneModePanel, {
              panelType = DarkZoneGlobal.PanelType.Quest,
              modeScheduleID = modeScheduleData.Id
            })
          end
        end, modeScheduleData.un, nil, modeScheduleData)
        item:SetTimeLimit(true)
        local time = modeScheduleData.EndTime - CurTime
        local timer = TimerSys:DelayCall(1, function()
          local currentTime = CGameTime:GetTimestamp()
          if currentTime > modeScheduleData.EndTime then
            self:UpdateModeSchedule()
          end
        end, nil, time)
        table.insert(self.modeScheduleList, item)
        table.insert(self.modeScheduleListTimer, timer)
      end
    end
  end
end

function UIDarkZoneMainPanel:ClearModeTimer()
  for i = 1, #self.modeScheduleListTimer do
    if self.modeScheduleListTimer[i] then
      self.modeScheduleListTimer[i]:Stop()
      self.modeScheduleListTimer[i] = nil
    end
  end
  self.modeScheduleListTimer = {}
end

function UIDarkZoneMainPanel:AddBtnListen()
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    self:CloseBtnClick()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Season.gameObject).onClick = function()
    UIManager.OpenUI(UIDef.UIDarkZoneSeasonQuestPanel)
  end
  self:SetItemList()
end

function UIDarkZoneMainPanel:CloseBtnClick()
  self.closeTime = 0
  UISystem:SetMainCamera(false)
  self:CallWithAniDelay(function()
  end)
  UIManager.CloseUI(UIDef.UIDarkZoneMainPanel)
end

function UIDarkZoneMainPanel:AddEventListener()
  MessageSys:AddListener(UIEvent.OnDarkZonePlanUpdate, self.InitDarkZoneGlobalLevel)
end

function UIDarkZoneMainPanel:EnterStorage()
  DarkZoneNetRepoCmdData:SendCS_DarkZoneStorage(function()
    UIManager.OpenUI(UIDef.UIDarkZoneRepositoryPanel)
  end)
end

function UIDarkZoneMainPanel:EnterMakeTable()
  DarkNetCmdMakeTableData:SendCS_DarkZoneWishExp(function()
    UIManager.OpenUI(UIDef.UIDarkZoneMakeTablePanel)
  end)
end

function UIDarkZoneMainPanel:EnterTeam()
  local TeamIndex = DarkNetCmdTeamData.CurTeamIndex
  local TeamData = self.TeamDataDic[TeamIndex + 1]
  if 0 < TeamData.guns[0] then
    self.DarkZoneTeamCameraCtrl.cameraBlendFinished:AddListener(function(c)
      self.DarkZoneTeamCameraCtrl:SetCharacterColor(0)
    end)
    local model = UIDarkZoneTeamModelManager:GetCaCheModel(TeamData.guns[0])
    self.DarkZoneTeamCameraCtrl:ChangeCameraStand(model.tableId, CS.DarkZoneTeamCameraPosType.Position1, model.gameObject)
  end
  UIManager.OpenUI(UIDef.UIDarkZoneTeamPanelV2)
end

function UIDarkZoneMainPanel:RefreshSeasonData()
  NetCmdRecentActivityData:ReqPlanActivityData(PlanType.PlanFunctionDarkzone, function(ret)
  end)
end

function UIDarkZoneMainPanel:RefreshSeasonUI()
  RedPointSystem:GetInstance():UpdateRedPointByType(RedPointConst.DarkZoneQuest)
  if self.carrierPanel and self.carrierPanel.mIsUnLock then
    self.carrierPanel:RefreshRedDot(NetCmdActivityDarkZone:GetDarkZoneCarrierRedPoint(NetCmdActivitySimData.offcialConfigId) > 0 and self.carrierPanel.mIsUnLock)
  end
end

function UIDarkZoneMainPanel:EnterDarkZone()
  if not self.IsInEditor then
    local nowtime = CS.CGameTime.ConvertUintToDateTime(CGameTime:GetTimestamp())
    local StartDatetime = DateTime(nowtime.Year, nowtime.Month, nowtime.Day, System.Int32.Parse(self.starttimeArr[1]), System.Int32.Parse(self.starttimeArr[2]), nowtime.Second)
    local EndDatetime = DateTime(nowtime.Year, nowtime.Month, nowtime.Day, System.Int32.Parse(self.endtimeArr[1]), System.Int32.Parse(self.endtimeArr[2]), 0)
    if 0 <= DateTime.Compare(nowtime, StartDatetime) and 0 > DateTime.Compare(nowtime, EndDatetime) then
      DarkZoneNetRepoCmdData:SendCS_DarkZoneStorage(function()
        UIManager.OpenUI(UIDef.UIDarkZoneMapSelectPanel)
      end)
    else
      UIUtils.PopupPositiveHintMessage(903001)
    end
  else
    DarkZoneNetRepoCmdData:SendCS_DarkZoneStorage(function()
      UIManager.OpenUI(UIDef.UIDarkZoneMapSelectPanel)
    end)
  end
end

function UIDarkZoneMainPanel:Instruction()
end

function UIDarkZoneMainPanel:UpdateQuestRedPoint()
  for i = 1, #self.modeScheduleList do
    if self.modeScheduleList[i].modeScheduleData.Function == 0 then
      local modeScheduleID = self.modeScheduleList[i].modeScheduleData.Id
      local count = NetCmdDarkZoneSeasonData:UpdateQuestRedPointByModeScheduleId(modeScheduleID)
      self.modeScheduleList[i]:RefreshRedDot(0 < count)
    end
  end
end

function UIDarkZoneMainPanel:UpdateEndlessRedPoint()
  return NetCmdDarkZoneSeasonData:UpdateEndlessRedPoint() > 0
end

function UIDarkZoneMainPanel:UpdateMakeTableRedPoint()
  return NetCmdDarkZoneSeasonData:UpdateMakeTableRedPoint() > 0
end

function UIDarkZoneMainPanel:UpdateExploreRedPoint()
  return NetCmdDarkZoneSeasonData:UpdateExploreRedPoint() > 0
end

function UIDarkZoneMainPanel:UpdateNpcRedPoint()
  local needShow = self:UpdateNpcRedPointByStore()
  self.itemList[2]:RefreshRedDot(needShow)
end

function UIDarkZoneMainPanel:UpdateNpcRedPointByStore()
  local result = false
  self.NpcStoreItemDic = {}
  DZStoreUtils.NpcStoreStateDic = {}
  local NPCDatas = TableData.listDarkzoneNpcDatas:GetList()
  for j = 0, NPCDatas.Count - 1 do
    local NPCId = NPCDatas[j].id
    local list = DarkNetCmdStoreData:GetStoreDataByTag(NPCId)
    for i = 0, list.Count - 1 do
      local data = list[i]
      if self.NpcStoreItemDic[NPCId] == nil then
        self.NpcStoreItemDic[NPCId] = {}
      end
      table.insert(self.NpcStoreItemDic[NPCId], data)
    end
  end
  for NpcId, NpcStoreList in pairs(self.NpcStoreItemDic) do
    self.IsJudgeRedPointByItemLimit = true
    local NpcFavorData = DarkNetCmdStoreData:GetNpcDataById(NpcId)
    local NpcFavor = 0
    if NpcFavorData ~= nil then
      NpcFavor = NpcFavorData.Favor
    end
    local data = {}
    data.UnlockList = {}
    data.LockList = {}
    DZStoreUtils.NpcStoreStateDic[NpcId] = data
    for i = 1, #NpcStoreList do
      local unlockNum = tonumber(NpcStoreList[i].spec_args) or 0
      if NpcFavor >= unlockNum then
        if 0 < NpcStoreList[i].refresh_type then
          local refreshTime = NetCmdStoreData:GetGoodsRefreshById(NpcStoreList[i].id)
          local uid = AccountNetCmdHandler.Uid
          local key = uid .. NpcStoreList[i].id .. "LatestFreshTime"
          local value = tonumber(PlayerPrefs.GetString(key)) or 0
          if value ~= 0 and refreshTime > value then
            DZStoreUtils.redDotList[NpcId] = 1
            result = true
          end
        end
        table.insert(DZStoreUtils.NpcStoreStateDic[NpcId].UnlockList, NpcStoreList[i])
      elseif NpcFavor < unlockNum then
        table.insert(DZStoreUtils.NpcStoreStateDic[NpcId].LockList, NpcStoreList[i])
      end
    end
  end
  return result
end

function UIDarkZoneMainPanel:UpdateTeamList()
  local Data = DarkNetCmdTeamData.Teams
  self.TeamDataDic = {}
  for i = 0, Data.Count - 1 do
    local data = {}
    data.name = Data[i].Name
    data.guns = Data[i].Guns
    data.leader = Data[i].Leader
    for j = data.guns.Count, 3 do
      data.guns:Add(0)
    end
    if #self.TeamDataDic >= i + 1 then
      self.TeamDataDic[i + 1] = data
    else
      table.insert(self.TeamDataDic, data)
    end
  end
end

function UIDarkZoneMainPanel:UpdateAllModel()
  local TeamIndex = DarkNetCmdTeamData.CurTeamIndex
  local TeamData = self.TeamDataDic[TeamIndex + 1]
  self.needWait = true
  self.gunModelCacheList = {}
  self.maxCacheIndex = 0
  for i = 0, 3 do
    if TeamData.guns[i] ~= 0 then
      self.maxCacheIndex = self.maxCacheIndex + 1
    end
  end
  for i = 0, 3 do
    if TeamData.guns[i] ~= 0 then
      self:UpdateModel(TeamData.guns[i], i)
    end
  end
end

function UIDarkZoneMainPanel:UpdateModel(GunId, Index)
  local Tabledata = TableData.listGunDatas:GetDataById(GunId)
  local GunCmdData = NetCmdTeamData:GetGunByID(GunId)
  local modelId = GunId
  local weaponModelId = GunCmdData.WeaponData ~= nil and GunCmdData.WeaponData.stc_id or Tabledata.weapon_default or Tabledata.weapon_default
  if UIDarkZoneTeamModelManager:IsCacheLoadedContains(modelId) >= 0 then
    local model = UIDarkZoneTeamModelManager:GetCaCheModel(modelId)
    model.Index = Index
    self.gunModelCacheList[Index] = model
    self:SetGunModel(model, Index)
    return
  end
  UIUtils.GetDarkZoneTeamUIModelAsyn(modelId, weaponModelId, Index, function(go)
    self:UpdateModelCallback(go, Index)
  end)
end

function UIDarkZoneMainPanel:UpdateModelCallback(obj, index)
  obj.transform.parent = nil
  if obj ~= nil and obj.gameObject ~= nil then
    self:SetGunModel(obj, index)
    if self.needWait then
      self.cacheIndex = self.cacheIndex + 1
      self.gunModelCacheList[index] = obj
      self:ResSysLoadAsyncIsAllFinish()
    end
  end
end

function UIDarkZoneMainPanel:ShowAllGunModelByIndex(index, isDelay)
  if index >= self.maxCacheIndex then
    return
  end
  local model = self.gunModelCacheList[index]
  if model then
    model.gameObject:SetActive(true)
    self.changeGunEffect[index].transform.position = model.gameObject.transform.position
    setactive(self.changeGunEffect[index], true)
    if isDelay then
      self:DelayCall(0.1, function()
        self:ShowAllGunModelByIndex(index + 1, isDelay)
      end)
    else
      self:ShowAllGunModelByIndex(index + 1, isDelay)
    end
  else
    self:ShowAllGunModelByIndex(index + 1, isDelay)
  end
end

function UIDarkZoneMainPanel:SetGunModel(model, index)
  model:Show(self.needWait ~= true)
  model:SetLoveVowRingEnable(true)
  local num = index + 1
  local str1 = string.format("unit_character_%d_position", num)
  local str2 = string.format("unit_character_%d_rotation", num)
  local data1 = TableData.listGunGlobalConfigDatas:GetDataById(model.tableId)
  local data2 = TableData.listDarkzoneUnitCameraDatas:GetDataById(data1.darkzone_unit_camera)
  local positionList = data2[str1]
  local rotationList = data2[str2]
  model.transform.localScale = Vector3.one
  model.transform.position = Vector3(positionList[0], positionList[1], positionList[2])
  model.transform.localEulerAngles = Vector3(rotationList[0], rotationList[1], rotationList[2])
  GFUtils.MoveToLayer(model.transform, CS.UnityEngine.LayerMask.NameToLayer("Friend"))
  if index == 0 then
    self.DarkZoneTeamCameraCtrl:ChangeCameraStand(model.tableId, CS.DarkZoneTeamCameraPosType.Captain, model.gameObject)
  end
  self.DarkZoneTeamCameraCtrl:UpdateMateriaList(model.gameObject, index)
  self.DarkZoneTeamCameraCtrl:SetBaseColorByBool(index, true)
  local LODNum = 0
  if not CS.LuaUtils.IsPc() then
    LODNum = (index == 0 or index == 3) and 0 or 1
  end
  model:SetModelLODLevel(LODNum)
end

function UIDarkZoneMainPanel:ResetCameraPos()
  local TeamIndex = DarkNetCmdTeamData.CurTeamIndex
  local TeamData = self.TeamDataDic[TeamIndex + 1]
  local id = TeamData.guns[0]
  if 0 < id then
    local model = UIDarkZoneTeamModelManager:GetCaCheModel(id)
    self.DarkZoneTeamCameraCtrl:ChangeCameraStand(model.tableId, CS.DarkZoneTeamCameraPosType.Captain, model.gameObject)
  end
end

function UIDarkZoneMainPanel:ResSysLoadAsyncIsAllFinish(isDelay)
  if isDelay == nil then
    isDelay = true
  end
  if not (self.loadEffectNum >= self.maxEffectNum) then
    return
  end
  if not (self.cacheIndex >= self.maxCacheIndex) then
    return
  end
  self:ShowAllGunModelByIndex(0, isDelay)
end

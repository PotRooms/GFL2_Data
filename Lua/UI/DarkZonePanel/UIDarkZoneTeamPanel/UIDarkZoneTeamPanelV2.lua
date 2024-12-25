require("UI.DarkZonePanel.UIDarkZoneTeamPanel.DarkZoneTeamItemV2")
require("UI.DarkZonePanel.UIDarkZoneTeamPanel.UIDarkZoneTeamPanelView")
require("UI.DarkZonePanel.UIDarkZoneTeamPanel.UIDarkZoneFleetAvatarItem")
require("UI.UIBasePanel")
UIDarkZoneTeamPanelV2 = class("UIDarkZoneTeamPanelV2", UIBasePanel)
UIDarkZoneTeamPanelV2.__index = UIDarkZoneTeamPanelV2

function UIDarkZoneTeamPanelV2:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
  csPanel.Is3DPanel = true
  self.mCSPanel = csPanel
end

function UIDarkZoneTeamPanelV2:OnInit(root, data)
  self:SetRoot(root)
  self.mData = data
  self.questId = 0
  self.UpdateModelCount = 0
  if self.mData ~= nil then
    self.questId = self.mData.QuestID
  end
  self:InitBaseData()
  self:AddBtnListen()
  self:AddEventListener()
  self.outTimer = DarkNetCmdStoreData:CreateDarkzoneOutTimer(self.CloseSelfUI)
  self.closeTime = self.mData == nil and 0.01 or 0
  self.DarkZoneTeamCameraCtrl = CS.DarkZoneTeamCameraCtrl.Instance
  if self.DarkZoneTeamCameraCtrl == nil then
    self.needUnloadTeam = true
    UIManager.EnableDarkZoneTeam(true)
    self.DarkZoneTeamCameraCtrl = CS.DarkZoneTeamCameraCtrl.Instance
    self:UpdateTeamList(self.curTeam)
  end
  self.Camera = UISystem.CharacterCamera
  self.Camera.transform.position = Vector3(0, 0, 0)
  self:UpdateTeamList(self.curTeam)
  setactive(self.gunListItem.mTrans_BtnChange.transform.parent, true)
  
  function self.gunListItem.GunList.itemCreated(renderDataItem)
    self:GunItemProvider(renderDataItem)
  end
  
  function self.gunListItem.GunList.itemRenderer(index, renderData)
    self:GunItemRenderer(index, renderData)
  end
  
  function self.gunListItem.mRefreshAction(dutyID)
    self:ReFreshListByDutyID(dutyID)
  end
  
  self.gunListItem:SetParent(self.ui.mTrans_Chrchange)
  self.gunListItem:InitDarkTeamGunDataList()
  self.gunListItem.mTxt_Tittle.text = TableData.GetHintById(903009)
  
  function self.gunListItem.mConfirmCallBack()
    self:GoWar()
  end
  
  function self.gunListItem.mChangeCallBack()
    self:RePlace()
  end
  
  setactive(self.gunListItem.mTrans_BtnConfirm.transform.parent, false)
  self.gunListItem:SetFadeEnable(true)
  setactive(self.ui.mBtn_Confirm, self.mData ~= nil)
  self.roleDetailItem = CS.RoleDetailPanel(self.ui.mTrans_ChrInfo)
  ResSys:GetEffectAsync("Effect_sum/Other/EFF_Command_Character_Switch", function(path, go, data)
    if go ~= nil then
      if self.ui ~= nil then
        self.changeGunEffect = go
        self.changeGunEffect:SetActive(false)
      else
        ResourceDestroy(go)
      end
    end
  end)
  self.gunListItem:SetActive(false)
end

function UIDarkZoneTeamPanelV2:CloseSelfUI()
  UIManager.CloseUI(UIDef.UIDarkZoneTeamPanelV2)
end

function UIDarkZoneTeamPanelV2:OnCameraStart()
  return 0.01
end

function UIDarkZoneTeamPanelV2:OnCameraBack()
  return self.closeTime
end

function UIDarkZoneTeamPanelV2:OnShowStart()
  if GFUtils.IsOverseaServer() then
    UIManager.CloseUI(UIDef.UIDarkZoneTeamPanelV2)
  end
  if self.mData then
    self:UpdateTeamCamera()
  end
  self.ui.mText_MachineryName.text = TableData.GetHintById(271049)
  self.ui.mText_MachineryLvName.text = TableData.GetHintById(271048)
  self.ui.mText_MachineryLv.text = NetCmdActivityDarkZone.mCarLevel
  setactive(self.gunListItem.mTrans_Action, false)
  setactive(self.gunListItem.mTrans_None, false)
  setactive(self.gunListItem.mTrans_Screen, self.mData ~= nil)
  self:ShowCurTeamGunList()
  self:ShowGunList()
  if self.mData == nil then
    self.gunListItem:Show(true)
    setactive(self.gunListItem.mTrans_Screen, true)
    self.fleetAvatarItemList[1]:OnClickGunCard()
  end
end

function UIDarkZoneTeamPanelV2:OnShowFinish()
  setactive(self.ui.mBtn_DarkzoneMachinery, self.mData ~= nil and self.mData.enterType == 4)
  if self.mData == nil and #self.fleetAvatarItemList > 0 then
    self.needChangeCameraPos = true
  end
  self:SetAllModelWhite()
  self:ResetAllModelLOD()
end

function UIDarkZoneTeamPanelV2:OnHide()
end

function UIDarkZoneTeamPanelV2:OnBackFrom()
  self:UpdateTeamCamera()
  self.ui.mText_MachineryLv.text = NetCmdActivityDarkZone.mCarLevel
end

function UIDarkZoneTeamPanelV2:OnAdditiveSceneLoaded(loadedScene, isOpen)
  self.mScene = loadedScene
end

function UIDarkZoneTeamPanelV2:OnReconnectSuc()
  if self.isSendProto then
    self.mCSPanel:SetUIInteractable(true)
    self.isSendProto = false
  end
end

function UIDarkZoneTeamPanelV2:OnRecover()
  self:OnShowStart()
end

function UIDarkZoneTeamPanelV2:CloseFunction()
  if self.mData and self.isShowGunList == true then
    self.DarkZoneTeamCameraCtrl.cameraBlendFinished:RemoveAllListeners()
    self.DarkZoneTeamCameraCtrl:StopAllMaterialTweeners()
    self:ExitChangeTeamMember()
  else
    if self.mData == nil then
      self:SetAllModelWhite()
      self:ResetAllModelLOD()
    end
    local TeamIndex = DarkNetCmdTeamData.CurTeamIndex
    local TeamData = self.TeamDataDic[TeamIndex + 1]
    if 0 < TeamData.guns[0] then
      local GunCmdData = DarkNetCmdTeamData:GetGunById(self.questId, TeamData.guns[0], 0)
      local modelID = TeamData.guns[0]
      if GunCmdData.IsDarkPreset then
        modelID = GunCmdData.DarkGunPresetID
      end
      local model = UIDarkZoneTeamModelManager:GetCaCheModel(modelID)
      self.DarkZoneTeamCameraCtrl:ChangeCameraStand(model.tableId, CS.DarkZoneTeamCameraPosType.Captain, model.gameObject)
    end
    UIManager.CloseUI(UIDef.UIDarkZoneTeamPanelV2)
    self.gunListItem:Hide()
    setactive(self.gunListItem.mTrans_Action, false)
  end
end

function UIDarkZoneTeamPanelV2:UpdateTeamInfo()
  local i = self.curTeam + 1
  local data = DarkZoneTeamData(i - 1, self.TeamDataDic[i].guns, self.TeamDataDic[i].Leader)
  DarkNetCmdTeamData.Teams[i - 1].Leader = self.TeamDataDic[i].Leader
  DarkNetCmdTeamData:SetTeamInfo(data, nil, self.questId)
end

function UIDarkZoneTeamPanelV2:OnClose()
  DarkNetCmdTeamData:CopyTeamList()
  self:ReleaseTimers()
  self.mCSPanel.FadeOutTime = self.FadeOutTime
  self.DarkZoneTeamCameraCtrl.cameraBlendFinished:RemoveAllListeners()
  self.DarkZoneTeamCameraCtrl = nil
  self.ui = nil
  self.mView = nil
  self.mData = nil
  self.isShowGunList = nil
  self.curTeam = nil
  self.Camera = nil
  self.uiCamera = nil
  self.TeamDataDic = nil
  self.closeTime = nil
  self.ItemDataList = nil
  self:ReleaseCtrlTable(self.fleetAvatarItemList, true)
  self.fleetAvatarItemList = nil
  self.curGunItem = nil
  if self.outTimer ~= nil then
    self.outTimer:Stop()
    self.outTimer = nil
  end
  self.isFocusModel = nil
  self.focusModel = nil
  self.selectGunItemIndex = nil
  self:UnRegistrationKeyboard(nil)
  self.comScreenItem:OnRelease()
  self.comScreenItem = nil
  self.gunListItem:OnRelease()
  self.gunListItem = nil
  self.hasChange = nil
  self.roleDetailItem:OnRelease()
  self.roleDetailItem = nil
  if self.changeGunEffect then
    ResourceDestroy(self.changeGunEffect)
  end
  self.changeGunEffect = nil
  self.isShowChrList = nil
  self.sortList = nil
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnClickDetailEvent, self.roleDetailEventFunc)
  self.roleDetailEventFunc = nil
  if self.needUnloadTeam == true then
    UIManager.EnableDarkZoneTeam(false)
    UIDarkZoneTeamModelManager:Release()
    DarkNetCmdTeamData:UnloadTeamAssets()
    self.DarkZoneTeamCameraCtrl = nil
  end
  self.needUnloadTeam = nil
  if self.isSendProto then
    self.mCSPanel:SetUIInteractable(true)
  end
  self.isSendProto = nil
end

function UIDarkZoneTeamPanelV2:InitBaseData()
  self.mView = UIDarkZoneTeamPanelView.New()
  self.ui = {}
  self.curTeam = 0
  self.TeamDataDic = {}
  self.ItemDataList = {}
  self.fleetAvatarItemList = {}
  self.isFocusModel = false
  self.CurBtn = nil
  self.isShowGunList = false
  self.selectGunItemIndex = nil
  self.isShowChrList = true
  self.needChangeCameraPos = true
  self.needUnloadTeam = false
  self.needWait = false
  self.hasPreset = false
  self.mView:InitCtrl(self.mUIRoot, self.ui)
  self:AutoToBattle()
end

function UIDarkZoneTeamPanelV2:UpdateTeamDic()
  local Data = DarkNetCmdTeamData.Teams
  for i = 0, Data.Count - 1 do
    local data = {}
    data.name = Data[i].Name
    data.guns = Data[i].Guns
    data.Leader = Data[i].Leader
    for j = data.guns.Count, 3 do
      data.guns:Add(0)
    end
    table.insert(self.TeamDataDic, data)
  end
end

function UIDarkZoneTeamPanelV2:InitData()
  self:UpdateTeamDic()
  self.ItemDataList = DarkNetCmdTeamData:CopyGunList(self.questId)
  local itemPrefab = self.ui.mTrans_Chrchange:GetComponent(typeof(CS.ScrollListChild))
  local prefab = instantiate(itemPrefab.childItem)
  if self.gunListItem == nil then
    self.gunListItem = CS.UICommonEmbattleChrItem(prefab.transform)
  end
  if self.comScreenItem == nil then
    self.comScreenItem = ComScreenItemHelper:InitGun(self.gunListItem.mCommonGunScreenItem, self.ItemDataList, function()
      self:UpdateGunList()
    end, nil, true)
  end
  self.comScreenItem:ResetSort()
end

function UIDarkZoneTeamPanelV2:GetGunCount()
  local teamData = DarkNetCmdTeamData.Teams[0]
  local realCount = 0
  local gunCount = DarkNetCmdTeamData.Teams[0].Guns.Count
  for i = 0, gunCount - 1 do
    local gunID = teamData.Guns[i]
    if 0 < gunID then
      realCount = realCount + 1
    end
  end
  return realCount
end

function UIDarkZoneTeamPanelV2:AutoToBattle()
  local teamData = DarkNetCmdTeamData.Teams[0]
  local realCount = self:GetGunCount()
  if self.mData ~= nil then
    self.hasPreset = DarkNetCmdTeamData:UpdateHasPreset(self.mData.QuestID)
    if self.hasPreset then
      DarkNetCmdTeamData:UpdateGunPresetTeam(self.mData.QuestID)
      self:UpdateTeamDic()
    else
      DarkNetCmdTeamData:CopyTeamList()
      self:UpdateTeamDic()
    end
  end
  if teamData.Leader == 0 or realCount ~= 4 then
    self.needWait = true
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
    DarkNetCmdTeamData:SetTeamInfo(data, function()
      self.needWait = false
      self:InitData()
      self:UpdateTeamList(self.curTeam)
      self:OnShowStart()
    end)
  else
    self:InitData()
  end
end

function UIDarkZoneTeamPanelV2:UpdateTeamList(TeamIndex)
  if self.needWait == true then
    return
  end
  DarkNetCmdTeamData.CurTeamIndex = TeamIndex
  local TeamData = self.TeamDataDic[TeamIndex + 1]
  UIDarkZoneTeamModelManager.gunlist = TeamData.guns
  DarkNetCmdTeamData.QuicklyTeamList:Clear()
  for i = 0, 3 do
    DarkNetCmdTeamData.QuicklyTeamList:Add(TeamData.guns[i])
  end
  UIDarkZoneTeamModelManager:HideOrShowModel(false)
  local TeamIndex = DarkNetCmdTeamData.CurTeamIndex
  local TeamData = self.TeamDataDic[TeamIndex + 1]
  for i = 0, 3 do
    if TeamData.guns[i] ~= 0 then
      self:UpdateModel(TeamData.guns[i], i)
    end
  end
end

function UIDarkZoneTeamPanelV2:ShowGunList()
  self.gunListItem:ClickTabCallBack(0)
end

function UIDarkZoneTeamPanelV2:ShowCurTeamGunList()
  local gunList = self.TeamDataDic[self.curTeam + 1].guns
  for i = 0, gunList.Count - 1 do
    if 0 < gunList[i] then
      local index = i + 1
      if self.fleetAvatarItemList[index] == nil then
        self.fleetAvatarItemList[index] = UIDarkZoneFleetAvatarItem.New()
        self.fleetAvatarItemList[index]:InitCtrl(self.ui.mTrans_ChrList)
        self.fleetAvatarItemList[index]:SetClickFunction(function(item)
          if item.mData.IsDarkPreset then
            PopupMessageManager.PopupString(TableData.GetHintById(903727))
            return
          end
          self:OnClickGunAvatarItem(item)
          setactive(self.ui.mBtn_DarkzoneMachinery, false)
        end)
      end
      local item = self.fleetAvatarItemList[index]
      local cmdData = DarkNetCmdTeamData:GetGunById(self.questId, gunList[i], i)
      item:SetData(cmdData, index)
    end
  end
  setactive(self.ui.mTrans_ChrList, self.isShowChrList)
end

function UIDarkZoneTeamPanelV2:AddBtnListen()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    self:CloseFunction()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Confirm.gameObject).onClick = function()
    for i = 0, self.TeamDataDic[self.curTeam + 1].guns.Count - 1 do
      if self.TeamDataDic[self.curTeam + 1].guns[i] == 0 then
        UIUtils.PopupHintMessage(903108)
        return
      end
    end
    self.mCurMapId = self.mData.MapId
    if SupplyHelper:CheckSupplyRepeated(self.TeamDataDic[self.curTeam + 1].guns) == true then
      self:EnterDarkZone()
    end
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    if not pcall(function()
      DarkNetCmdStoreData.questCacheGroupId = 0
    end) then
      gfwarning("UIDarkZoneQuestInfoPanelItem\228\189\141\231\189\174\231\188\147\229\173\152\229\135\186\231\142\176\229\188\130\229\184\184")
    end
    if self.mData == nil then
      self:SetAllModelWhite()
      self:ResetAllModelLOD()
    end
    self.gunListItem:Hide()
    setactive(self.gunListItem.mTrans_Action, false)
    if self.mData ~= nil and self.mData.enterType == 4 then
      MessageSys:SendMessage(UIEvent.DzTeamUnload, nil)
    end
    UISystem:JumpToMainPanel()
  end
  setactive(self.ui.mBtn_DarkzoneMachinery, self.mData ~= nil and self.mData.enterType == 4)
  UIUtils.GetButtonListener(self.ui.mBtn_DarkzoneMachinery.gameObject).onClick = function()
    self.closeTime = 0
    UISystem:SetMainCamera(false)
    self.closeTime = self.mData == nil and 0.01 or 0
    UIManager.OpenUI(UIDef.UIDarkZoneMachineryPanel)
  end
end

function UIDarkZoneTeamPanelV2:AddEventListener()
  function self.roleDetailEventFunc(msg)
    self.isShowChrList = msg.Sender == false
    
    setactive(self.ui.mTrans_ChrList, self.isShowChrList)
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnClickDetailEvent, self.roleDetailEventFunc)
end

function UIDarkZoneTeamPanelV2:GunItemProvider(renderDataItem)
  local itemView = DarkZoneTeamItemV2.New()
  itemView:InitCtrlWithoutInstantiate(renderDataItem.gameObject, false)
  itemView:SetTable(self)
  itemView:SetClickFunction(function()
    local lastIndex = self.curItemIndex
    self:RefreshCurGunDetail(itemView.mData.id, itemView.mIndex)
    self.gunListItem.GunList:RefreshItemByIndex(itemView.mIndex)
    if lastIndex then
      self.gunListItem.GunList:RefreshItemByIndex(lastIndex)
    end
  end)
  renderDataItem.data = itemView
end

function UIDarkZoneTeamPanelV2:GunItemRenderer(index, renderData)
  local data = self.showItemDataList[index + 1]
  local item = renderData.data
  item:SetData(data, index)
  item:SetIsSelect(self.CurGunId)
  local id = 0
  if self.curGunItem then
    id = self.curGunItem.mData.id
  end
  item:SetIsSelectTeamGun(id)
  if self.IsDefaultChose == true and data.id == self.tempId then
    item:OnClickGunCard()
    self.IsDefaultChose = false
  end
end

function UIDarkZoneTeamPanelV2:ReFreshListByDutyID(dutyID)
  if self.sortList == nil then
    self.sortList = new_list(typeof(CS.GunCmdData))
  end
  self.sortList:Clear()
  for _, v in pairs(self.ItemDataList) do
    local tData = v.TabGunData
    if dutyID == 0 or tData.duty == dutyID then
      self.sortList:Add(v)
    end
  end
  self.comScreenItem:SetList(self.sortList)
  self.comScreenItem:DoFilter()
end

function UIDarkZoneTeamPanelV2:RefreshGunList()
  local count = #self.showItemDataList
  setactive(self.gunListItem.GunList, 0 < count)
  setactive(self.gunListItem.mTrans_ChrNone, count <= 0)
  setactive(self.gunListItem.mTrans_None, count <= 0)
  setactive(self.gunListItem.mTrans_Action, 0 < count)
  self:ClickCurGun()
  self.gunListItem.GunList.numItems = count
  self.gunListItem.GunList:Refresh()
end

function UIDarkZoneTeamPanelV2:UpdateGunList()
  self:GunItemCancelSelect()
  self.gunListItem:SetDutyTabListActive(self.comScreenItem.FilterId == 0)
  self:SortGunResultList()
  self:RefreshGunList()
end

function UIDarkZoneTeamPanelV2:SortGunResultList()
  local tmpResultList = self.comScreenItem:GetResultList()
  self.showItemDataList = {}
  for i = 0, tmpResultList.Count - 1 do
    local d = tmpResultList[i]
    table.insert(self.showItemDataList, d)
  end
  local r = {}
  local r2 = {}
  for i, v in ipairs(self.showItemDataList) do
    local teamIndex = self:CheckInTeam(v.id)
    if teamIndex == nil then
      table.insert(r, v)
    else
      local t = {}
      t.index = teamIndex
      t.data = v
      table.insert(r2, t)
    end
  end
  table.sort(r2, function(a, b)
    return a.index < b.index
  end)
  for i = #r2, 1, -1 do
    local v = r2[i].data
    table.insert(r, 1, v)
  end
  self.showItemDataList = r
end

function UIDarkZoneTeamPanelV2:CheckInTeam(GunId)
  if self.TeamDataDic[self.curTeam + 1] == nil then
    return nil
  end
  local guns = self.TeamDataDic[self.curTeam + 1].guns
  for i = 0, guns.Count - 1 do
    if GunId == guns[i] then
      return i + 1
    end
  end
  return nil
end

function UIDarkZoneTeamPanelV2:UpdateTeamCamera()
  local TeamIndex = DarkNetCmdTeamData.CurTeamIndex
  local TeamData = self.TeamDataDic[TeamIndex + 1]
  if 0 < TeamData.guns[0] then
    local model = UIDarkZoneTeamModelManager:GetCaCheModel(TeamData.guns[0])
    if model == nil then
      return
    end
    self.DarkZoneTeamCameraCtrl:ChangeCameraStand(model.tableId, CS.DarkZoneTeamCameraPosType.TeamPanel, model.gameObject)
  end
end

function UIDarkZoneTeamPanelV2:UpdateModel(GunId, Index)
  local GunCmdData = DarkNetCmdTeamData:GetGunById(self.questId, GunId, Index)
  local TableData = GunCmdData.TabGunData
  local modelId = GunId
  local weaponModelId = GunCmdData.WeaponData ~= nil and GunCmdData.WeaponData.stc_id or TableData.weapon_default or TableData.weapon_default
  local PresetID = 0
  if GunCmdData.IsDarkPreset then
    PresetID = GunCmdData.DarkGunPresetID
  end
  if 0 <= UIDarkZoneTeamModelManager:IsCacheLoadedContains(modelId) and not GunCmdData.IsDarkPreset then
    local model = UIDarkZoneTeamModelManager:GetCaCheModel(modelId)
    model.Index = Index
    self.focusModel = model
    self:SetGunModel(model, Index)
    return
  elseif 0 <= UIDarkZoneTeamModelManager:IsCacheLoadedContains(PresetID) and GunCmdData.IsDarkPreset then
    local model = UIDarkZoneTeamModelManager:GetCaCheModel(PresetID)
    model.Index = Index
    self.focusModel = model
    self:SetGunModel(model, Index)
    return
  end
  UIUtils.GetDarkZoneTeamUIModelAsyn(modelId, weaponModelId, Index, function(go)
    self:UpdateModelCallback(go, Index)
  end, self.questId)
end

function UIDarkZoneTeamPanelV2:UpdateModelCallback(obj, index)
  self.focusModel = obj
  obj.transform.parent = nil
  if obj ~= nil and obj.gameObject ~= nil then
    self.UpdateModelCount = self.UpdateModelCount + 1
    self:SetGunModel(obj, index)
    local realCount = self:GetGunCount()
    if self.UpdateModelCount == realCount then
      self:SetAllModelWhite()
    end
  end
end

function UIDarkZoneTeamPanelV2:GetDarkZoneUnitCameraDataByID(id)
  local data1 = TableData.listGunGlobalConfigDatas:GetDataById(id)
  local data2 = TableData.listDarkzoneUnitCameraDatas:GetDataById(data1.darkzone_unit_camera)
  return data2
end

function UIDarkZoneTeamPanelV2:SetGunModel(model, index)
  model:Show(true)
  local num = index + 1
  local str1 = string.format("unit_character_%d_position", num)
  local str2 = string.format("unit_character_%d_rotation", num)
  local data2 = self:GetDarkZoneUnitCameraDataByID(model.tableId)
  local positionList = data2[str1]
  local rotationList = data2[str2]
  local pos = Vector3(positionList[0], positionList[1], positionList[2])
  model.transform.localScale = Vector3.one
  model.transform.position = pos
  model.transform.localEulerAngles = Vector3(rotationList[0], rotationList[1], rotationList[2])
  GFUtils.MoveToLayer(model.transform, CS.UnityEngine.LayerMask.NameToLayer("Friend"))
  self.DarkZoneTeamCameraCtrl:UpdateMateriaList(model.gameObject, index)
  local isChange = self.isShowGunList and index + 1 == self.CurBtn
  if isChange then
    str1 = string.format("Position%d", num)
    self.DarkZoneTeamCameraCtrl:ChangeCameraStand(model.tableId, CS.DarkZoneTeamCameraPosType[str1], model.gameObject)
    if self.changeGunEffect then
      self.changeGunEffect.transform.position = pos
      setactive(self.changeGunEffect, false)
      setactive(self.changeGunEffect, true)
    end
  end
  self.DarkZoneTeamCameraCtrl:SetBaseColorByBool(index, isChange == true or self.needUnloadTeam == true)
end

function UIDarkZoneTeamPanelV2:GoWar()
  if self.CurGunId == nil then
    UIUtils.PopupHintMessage(903011)
    return
  end
  if self:CheckGunIDHasInTeam(self.CurGunId) then
    UIUtils.PopupHintMessage(903136)
    return
  end
  local temp = self.TeamDataDic[self.curTeam + 1].guns
  local setleader
  for i = 0, temp.Count - 1 do
    if temp[i] ~= 0 then
      setleader = 1
    end
  end
  if setleader == nil then
    self.TeamDataDic[self.curTeam + 1].guns[0] = self.CurGunId
    self.TeamDataDic[self.curTeam + 1].Leader = self.CurGunId
  else
    local index = self:CheckInTeam(self.CurGunId)
    if index ~= nil then
      if self.TeamDataDic[self.curTeam + 1].Leader == self.TeamDataDic[self.curTeam + 1].guns[index - 1] then
        self.TeamDataDic[self.curTeam + 1].Leader = self.CurGunId
      end
      self.TeamDataDic[self.curTeam + 1].guns[index - 1] = 0
      self.TeamDataDic[self.curTeam + 1].guns[self.CurBtn - 1] = self.CurGunId
    else
      self.TeamDataDic[self.curTeam + 1].guns[self.CurBtn - 1] = self.CurGunId
    end
  end
  self.TeamDataDic[self.curTeam + 1].Leader = self.TeamDataDic[self.curTeam + 1].guns[0]
  self.hasChange = true
  self:UpdateTeamList(self.curTeam)
  if self.isShowChrList == false then
    self.roleDetailItem:OnClickOpenRoleDetail()
  end
  self:ShowCurTeamGunList()
  self:SortGunResultList()
  self:ClickCurGun()
  self:SetCurModelLOD(self.CurBtn)
  self.gunListItem.GunList:Refresh()
  UIUtils.PopupPositiveHintMessage(903012)
end

function UIDarkZoneTeamPanelV2:RePlace()
  if self.CurGunId == nil then
    UIUtils.PopupHintMessage(903011)
    return
  end
  if self.CurBtn == nil then
    UIUtils.PopupHintMessage(903011)
    return
  end
  local index = self:CheckInTeam(self.CurGunId)
  if index ~= nil then
    local temp = self.TeamDataDic[self.curTeam + 1].guns[self.CurBtn - 1]
    self.TeamDataDic[self.curTeam + 1].guns[self.CurBtn - 1] = self.CurGunId
    self.TeamDataDic[self.curTeam + 1].guns[index - 1] = temp
    self.TeamDataDic[self.curTeam + 1].Leader = self.TeamDataDic[self.curTeam + 1].guns[0]
  else
    if self.hasPreset then
      DarkNetCmdTeamData:UpdateTeamProto(self.CurGunId, self.CurBtn - 1)
    end
    if self:CheckGunIDHasInTeam(self.CurGunId) then
      UIUtils.PopupHintMessage(903136)
      return
    end
    self.TeamDataDic[self.curTeam + 1].guns[self.CurBtn - 1] = self.CurGunId
    self.TeamDataDic[self.curTeam + 1].Leader = self.TeamDataDic[self.curTeam + 1].guns[0]
  end
  self.hasChange = true
  self:UpdateTeamList(self.curTeam)
  if self.isShowChrList == false then
    self.roleDetailItem:OnClickOpenRoleDetail()
  end
  self:ShowCurTeamGunList()
  self:SortGunResultList()
  self:ClickCurGun()
  if index ~= nil then
    self:SetCurModelLOD(self.CurBtn)
  end
  self.gunListItem.GunList:Refresh()
  UIUtils.PopupPositiveHintMessage(903013)
  self:UpdateTeamInfo()
end

function UIDarkZoneTeamPanelV2:EnterDarkZone()
  self.isSendProto = true
  self.mCSPanel:SetUIInteractable(false)
  if self.mData and self.mData.enterExplore then
    CS.DzMatchUtils.RequireDarkMatchExplore()
  elseif self.mData and self.mData.enterType == 2 then
    local questId = TableData.listDarkzoneSystemEndlessRewardDatas:GetDataById(self.mData.QuestID).group
    DarkNetCmdStoreData.currentEndLessRewardID = self.mData.QuestID
    CS.DzMatchUtils.RequireDarkMatchEndless(questId, self.mData.MapId, self.mData.QuestID)
  elseif self.mData and self.mData.enterType == 1 then
    CS.DzMatchUtils.RequireDarkMatchQuest(self.mData.QuestID, self.mCurMapId, MapSelectUtils.currentQuestGroupID, self.mData.TeleportId)
  elseif self.mData and self.mData.enterType == 4 then
    CS.DzMatchUtils.RequireDarkCarMatchQuest(self.mData.QuestID, self.mCurMapId, self.mData.activeID)
  else
    CS.DzMatchUtils.RequireDarkMatchDefault(self.mCurMapId)
  end
  self:DelayCall(2, function()
    self.isSendProto = false
    self.mCSPanel:SetUIInteractable(true)
  end)
end

function UIDarkZoneTeamPanelV2:OnClickGunAvatarItem(item)
  if self.isShowGunList == false then
    self.gunListItem:Show(true)
    if self.mData ~= nil then
      setactive(self.ui.mBtn_Confirm, false)
    end
  end
  self.isFocusModel = true
  self.isShowGunList = true
  self.CurGunId = nil
  if self.curGunItem then
    self.curGunItem.ui.mBtn_Self.interactable = true
  end
  self.curGunItem = item
  self.curGunItem.ui.mBtn_Self.interactable = false
  self.CurBtn = item.mIndex
  self.focusModel = UIDarkZoneTeamModelManager:GetCaCheModel(item.mData.stc_gun_id)
  if self.needChangeCameraPos == true then
    self.DarkZoneTeamCameraCtrl.cameraBlendFinished:RemoveAllListeners()
    local str1 = string.format("Position%d", item.mIndex)
    self.DarkZoneTeamCameraCtrl:ChangeCameraStand(self.focusModel.tableId, CS.DarkZoneTeamCameraPosType[str1], self.focusModel.gameObject)
    self.DarkZoneTeamCameraCtrl.cameraBlendFinished:AddListener(function(c)
      self.DarkZoneTeamCameraCtrl:SetCharacterColor(item.mIndex - 1)
    end)
  end
  self:SetCurModelLOD(self.CurBtn)
  self:ClickCurGun()
  self.gunListItem.GunList:Refresh()
end

function UIDarkZoneTeamPanelV2:SetDarkenDoTween(startValue, endValue)
  if self.progressTween then
    LuaDOTweenUtils.Kill(self.progressTween, false)
    self.progressTween = nil
  end
  local getter = function(tempSelf)
    return tempSelf.darkenComponent.lerp
  end
  local setter = function(tempSelf, value)
    tempSelf.darkenComponent.lerp = value
  end
  self.progressTween = LuaDOTweenUtils.ToOfFloat(self, getter, setter, endValue, 0.7, nil)
end

function UIDarkZoneTeamPanelV2:SetAllModelWhite()
  self.DarkZoneTeamCameraCtrl:SetAllChapterHighLight()
  if self.roleDetailItem.m_RolePanelState ~= CS.RolePanelState.Info then
    self.roleDetailItem:OnClickOpenRoleDetail()
  end
  self.roleDetailItem:SetActive(false)
end

function UIDarkZoneTeamPanelV2:SetModelLOD(listIndex, lodNum)
  local item = self.fleetAvatarItemList[listIndex]
  if item and item.mData then
    local FocusModel = UIDarkZoneTeamModelManager:GetCaCheModel(item.mData.stc_gun_id)
    if FocusModel then
      FocusModel:SetModelLODLevel(lodNum)
    end
  end
end

function UIDarkZoneTeamPanelV2:SetCurModelLOD(curIndex)
  for _, v in ipairs(self.fleetAvatarItemList) do
    local item = v
    local index = item.mIndex
    local LODNum = 0
    if not CS.LuaUtils.IsPc() then
      LODNum = index == curIndex and 0 or 1
    end
    self:SetModelLOD(index, LODNum)
  end
end

function UIDarkZoneTeamPanelV2:ResetAllModelLOD()
  for _, v in ipairs(self.fleetAvatarItemList) do
    local item = v
    local index = item.mIndex
    local LODNum = 0
    if not CS.LuaUtils.IsPc() then
      LODNum = (index == 1 or index == 4) and 0 or 1
    end
    self:SetModelLOD(index, LODNum)
  end
end

function UIDarkZoneTeamPanelV2:ClickCurGun()
  self:GunItemCancelSelect()
  local isSelect = false
  if self.curGunItem then
    for i = 1, #self.showItemDataList do
      local d = self.showItemDataList[i]
      if d.id == self.curGunItem.mData.id then
        isSelect = true
        self:RefreshCurGunDetail(self.curGunItem.mData.id, i - 1)
      end
    end
  end
  if self.isShowGunList and isSelect == false and #self.showItemDataList > 0 then
    self:RefreshCurGunDetail(self.showItemDataList[1].id, 0)
  end
end

function UIDarkZoneTeamPanelV2:ExitChangeTeamMember()
  setactive(self.ui.mBtn_DarkzoneMachinery, self.mData ~= nil and self.mData.enterType == 4)
  if self.isShowGunList == true then
    if self.curGunItem then
      self.curGunItem.ui.mBtn_Self.interactable = true
      self.curGunItem = nil
    end
    self.gunListItem:Hide()
    setactive(self.gunListItem.mTrans_Action, false)
    if self.mData ~= nil then
      setactive(self.ui.mBtn_Confirm, true)
    end
    self:UpdateTeamCamera()
  end
  if self.isShowChrList == false then
    self.isShowChrList = true
  end
  self:ShowCurTeamGunList()
  self:SetAllModelWhite()
  self:ResetAllModelLOD()
  self.CurBtn = nil
  self.isShowGunList = false
end

function UIDarkZoneTeamPanelV2:RefreshCurGunDetail(gunID, itemIndex)
  self.CurGunId = gunID
  self.curItemIndex = itemIndex
  local isSameGun = false
  if self.curGunItem then
    isSameGun = self.curGunItem.mData.id == self.CurGunId
  end
  local canNotClick = self:CheckGunIDHasInTeam(gunID, true) or isSameGun
  setactive(self.gunListItem.mTrans_None, canNotClick)
  setactive(self.gunListItem.mTrans_Action, canNotClick == false)
  local showStr = ""
  if canNotClick then
    showStr = TableData.GetHintById(903136)
  elseif isSameGun then
    showStr = TableData.GetHintById(903136)
  end
  self.gunListItem.mTxt_Tips.text = showStr
  local cmdData = NetCmdTeamData:GetGunByID(gunID)
  self.roleDetailItem:SetRoleDetailDataByGunCmdData(cmdData)
  self.roleDetailItem:SetActive(true)
end

function UIDarkZoneTeamPanelV2:GunItemCancelSelect()
  self.CurGunId = nil
  setactive(self.gunListItem.mTrans_None, true)
  setactive(self.gunListItem.mTrans_Action, false)
  self.gunListItem.mTxt_Tips.text = TableData.GetHintById(80086)
  self.curItemIndex = nil
end

function UIDarkZoneTeamPanelV2:CheckGunIDHasInTeam(gunID, needExceptID)
  local exceptID = -1
  if needExceptID then
    exceptID = self.tempId
  end
  local twoCharId = TableData.listGunDatas:GetDataById(gunID).character_id
  for i = 0, DarkNetCmdTeamData.QuicklyTeamList.Count - 1 do
    local gunId = DarkNetCmdTeamData.QuicklyTeamList[i]
    if gunId ~= 0 and gunId ~= exceptID then
      local charId = TableData.listGunDatas:GetDataById(gunId).character_id
      if charId == twoCharId and DarkNetCmdTeamData.QuicklyTeamList[i] ~= gunID then
        return true
      end
    end
  end
  return false
end

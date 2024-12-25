require("UI.UIBasePanel")
require("UI.Lounge.UIDormChangeSkinSlot")
require("UI.Lounge.DormGlobal")
require("UI.Common.UICommonArrowBtnItem")
UIDormSkinChangePanel = class("UIDormSkinChangePanel", UIBasePanel)
UIDormSkinChangePanel.__index = UIDormSkinChangePanel

function UIDormSkinChangePanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Is3DPanel = true
end

function UIDormSkinChangePanel:OnAwake(root, data)
end

function UIDormSkinChangePanel:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.slotTable = nil
  self.curSlotIndex = 0
  local id = data
  self.bpClothes = nil
  self.closeTime = 0.01
  if data and type(data) == "userdata" then
    id = data[0]
    if data.Length > 1 then
      self.bpClothes = data[1]
    end
  end
  self.gunCmdData = NetCmdLoungeData:GetCurrGunCmdData()
  self.currIndex = 1
  self:InitContent()
  NetCmdLoungeData:SetChangeClothAniId()
  self.timeList = {}
  self.ui.mBtn_Back.interactable = true
  self.maxIndex = #self.slotTable
  self.arrowBtn = UICommonArrowBtnItem.New()
  self.arrowBtn:InitObj(self.ui.mObj_SwitchArrow)
  self.arrowBtn:RefreshArrowActive()
  self:AddBtnListener()
  self:RefreshBtnState()
  
  function UIDormSkinChangePanel.ConnectSuccess()
    self:refresh(false, true)
    self.ui.mBtn_Change.interactable = true
    self.ui.mBtn_TakeOff.interactable = true
    self.ui.mBtn_Back.interactable = true
    self.ui.mBtn_Home.interactable = true
    setactive(self.ui.mObj_SwitchArrow.gameObject, true)
    self:RefreshBtnState()
    NetCmdLoungeData:SetChangeClothState(2)
    LoungeHelper.InteractManager:PlayChangeCloth("Idle")
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnReconnectSuc, UIDormSkinChangePanel.ConnectSuccess)
end

function UIDormSkinChangePanel:InitContent()
  function self.ui.mVirtualList.itemProvider(renderData)
    return self:slotProvider(renderData)
  end
  
  function self.ui.mVirtualList.itemRenderer(index, renderData)
    self:slotRenderer(index, renderData)
  end
  
  function self.onContentValueChanged()
    gfdebug(self.ui.mRect_Content.anchoredPosition.x .. " " .. self.ui.mRect_Content.anchoredPosition.x)
  end
  
  self.isShow = false
  self.ui.mText_Name.text = TableData.GetHintById(280009)
  self.ui.mText_Name0.text = TableData.GetHintById(280008)
  self.ui.mBtn_Change.interactable = true
  self.ui.mBtn_TakeOff.interactable = true
  self.ui.mBtn_Back.interactable = true
  self.ui.mBtn_Home.interactable = true
  self.slotTable = self:initAllSlot()
  if #self.slotTable <= 0 then
    self:SetNoneState()
    return
  end
  setactive(self.ui.mTrans_None, false)
  setactive(self.ui.mVirtualList.transform, true)
  setactive(self.ui.mObj_SwitchArrow.gameObject, #self.slotTable > 1)
  self.curSlotIndex = self:getEquippedSkinSlotIndex()
  if self.curSlotIndex == -1 then
    self.curSlotIndex = 1
  end
  self.currIndex = self.curSlotIndex
end

function UIDormSkinChangePanel:SetNoneState()
  setactive(self.ui.mTrans_None, true)
  setactive(self.ui.mVirtualList.transform, false)
end

function UIDormSkinChangePanel:initAllSlot()
  local tempSlotTable = {}
  local gunData = TableDataBase.listGunDatas:GetDataById(self.gunCmdData.id)
  local tempTable = CSList2LuaTable(gunData.costume_replace)
  table.sort(tempTable, function(l, r)
    local clothesDataL = TableDataBase.listClothesDatas:GetDataById(l)
    local clothesDataR = TableDataBase.listClothesDatas:GetDataById(r)
    if clothesDataL == nil then
      return false
    elseif clothesDataR == nil then
      return true
    end
    return clothesDataL.order < clothesDataR.order
  end)
  local curBPId = NetCmdBattlePassData:GetCurOrRecentBpId()
  local index = 1
  for i, clothesId in ipairs(tempTable) do
    local d = TableDataBase.listClothesDatas:GetDataById(clothesId)
    local isUnlock = NetCmdGunClothesData:IsUnlock(clothesId)
    if (d ~= nil and d.display_config > 0 or d ~= nil and d.display_config == 0 and isUnlock) and isUnlock and d.clothes_type == 2 then
      local slot = UIDormChangeSkinSlot.New()
      slot:SetData(self.gunCmdData, d, index)
      slot:AddBtnClickListener(function(tempIndex)
        self:onClickSlot(tempIndex)
      end)
      index = index + 1
      table.insert(tempSlotTable, slot)
    end
  end
  return tempSlotTable
end

function UIDormSkinChangePanel:getEquippedSkinSlotIndex()
  for i, slot in ipairs(self.slotTable) do
    if slot:GetClothesId() == self.gunCmdData.dormCostume then
      return slot:GetIndex()
    end
  end
  return -1
end

function UIDormSkinChangePanel:RefreshBtnState()
  setactive(self.ui.mBtn_PreGun.gameObject, self.currIndex > 1)
  setactive(self.ui.mBtn_NextGun.gameObject, self.currIndex < self.maxIndex)
end

function UIDormSkinChangePanel:OnClickArrow(changeNum)
  self.currIndex = self.currIndex + changeNum
  if self.currIndex < 1 then
    self.currIndex = 1
  end
  if self.currIndex > self.maxIndex then
    self.currIndex = self.maxIndex
  end
  self:onClickSlot(self.currIndex)
end

function UIDormSkinChangePanel:OnShowStart()
  DormGlobal.jumptomainpanel = false
  self:refresh(false, true)
  NetCmdLoungeData:SetChangeClothState(2)
  LoungeHelper.InteractManager:PlayChangeCloth("Idle")
end

function UIDormSkinChangePanel:OnShowFinish()
  LoungeHelper.CameraCtrl.isDebug = false
  self:scrollToCurSlotIndex(false)
end

function UIDormSkinChangePanel:refresh(needGunClothesAnim, isRefresh)
  self.ui.mVirtualList.numItems = #self.slotTable
  self.ui.mVirtualList:Refresh()
  self:refreshModel(needGunClothesAnim)
  self:refreshGrpBtn()
end

function UIDormSkinChangePanel:OnBackFrom()
  self:refresh(false)
end

function UIDormSkinChangePanel:slotProvider(renderData)
  local skinCardTemplate = self.ui.mScrollListChild_SkinCard.childItem
  local slotTrans = UIUtils.InstantiateByTemplate(skinCardTemplate, self.ui.mScrollListChild_SkinCard.transform)
  slotTrans.position = vectorone * 1000
  local renderDataItem = RenderDataItem()
  renderDataItem.renderItem = slotTrans.gameObject
  renderDataItem.data = nil
  return renderDataItem
end

function UIDormSkinChangePanel:slotRenderer(index, renderData)
  local slot = self.slotTable[index + 1]
  local go = renderData.renderItem
  slot:SetRoot(go.transform)
  if slot:GetIndex() == self.curSlotIndex then
    slot:Select()
  else
    slot:Deselect()
  end
  slot:Refresh()
end

function UIDormSkinChangePanel:scrollToCurSlotIndex(isSmooth)
  self:scrollTo(self.curSlotIndex, isSmooth)
end

function UIDormSkinChangePanel:scrollTo(index, isSmooth)
  if not index then
    return
  end
  local targetIndex = index - 1
  if targetIndex < 0 then
    targetIndex = 0
  end
  if self.listTween then
    LuaDOTweenUtils.Kill(self.listTween, false)
  end
  local getter = function(tempSelf)
    return Vector2(tempSelf.ui.mRect_Content.offsetMin.x, tempSelf.ui.mRect_Content.offsetMax.x)
  end
  local setter = function(tempSelf, value)
    if value.x + value.y > -self.ui.mLoopGrid_List.ItemSize.y or value.x > 0 or value.y > 0 then
      return
    end
    tempSelf.ui.mRect_Content.offsetMin = Vector2(value.x, tempSelf.ui.mRect_Content.offsetMin.y)
    tempSelf.ui.mRect_Content.offsetMax = Vector2(value.y, tempSelf.ui.mRect_Content.offsetMax.y)
  end
  self.ui.mVirtualList:ScrollTo(targetIndex, isSmooth, nil, ScrollAlign.Start)
end

function UIDormSkinChangePanel:OnHideFinish()
  if DormGlobal.jumptomainpanel then
    LoungeHelper.CameraCtrl.CameraPreObj:ExitLookAt()
    SceneSys:GetHallScene():ChangeBackground(NetCmdCommandCenterData.Background)
  end
end

function UIDormSkinChangePanel:AddBtnListener()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    if not self.ui.mBtn_Back.interactable then
      return
    end
    self.ui.mBtn_Back.interactable = false
    UIManager.CloseUI(UIDef.UIDormSkinChangePanel)
    NetCmdLoungeData:SetChangeClothState(-1)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    self.closeTime = 0
    DormGlobal.jumptomainpanel = true
    UISystem:JumpToMainPanel()
    NetCmdLoungeData:SetChangeClothState(-1)
  end
  UIUtils.AddBtnClickListener(self.ui.mBtn_Change.gameObject, function()
    self:onClickChangeClothes()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_TakeOff.gameObject, function()
    self:onClickTakeOff()
  end)
  
  function self.onEndDrag(eventData)
    local value = self.ui.mVirtualList.horizontalNormalizedPosition
    if value < 0 then
      value = 0
    elseif 1 < value then
      value = 1
    end
    local index = math.floor(value * self.ui.mVirtualList.content.sizeDelta.x / (self.ui.mLayoutGroup.spacing.x + self.ui.mVirtualList.paddingWidth) + 0.5) + 1
    self:onClickSlot(index)
    self:RefreshBtnState()
  end
  
  self.ui.mVirtualList:AddOnEndDrag(self.onEndDrag)
  UIUtils.GetButtonListener(self.ui.mBtn_PreGun.gameObject).onClick = function()
    self:OnClickArrow(-1)
    self:RefreshBtnState()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_NextGun.gameObject).onClick = function()
    self:OnClickArrow(1)
    self:RefreshBtnState()
  end
  self.arrowBtn:SetLeftArrowActiveFunction(function()
    return self.currIndex > 0
  end)
  self.arrowBtn:SetRightArrowActiveFunction(function()
    return self.currIndex < self.maxIndex - 1
  end)
  self:RegistrationKeyboard(KeyCode.Escape, self.ui.mBtn_Back)
end

function UIDormSkinChangePanel:onClickTakeOff()
  local curSlot = self:getCurSlot()
  if curSlot == nil then
    return
  end
  if self.gunCmdData.id == NetCmdLoungeData:GetMainWindGunId() and NetCmdLoungeData:IsBeloneCloth() then
    CS.PopupMessageManager.PopupString(TableData.GetHintById(902061))
    return
  end
  local clothesData = curSlot:GetClothesData()
  self.ui.mBtn_Change.interactable = false
  self.ui.mBtn_TakeOff.interactable = false
  self.ui.mBtn_Back.interactable = false
  self.ui.mBtn_Home.interactable = false
  self:ChangeSkinFunction(0)
end

function UIDormSkinChangePanel:onClickChangeClothes()
  local curSlot = self:getCurSlot()
  local clothesData = curSlot:GetClothesData()
  NetCmdGunClothesData:SetDormPreviewedRecord(clothesData.id)
  self.ui.mBtn_Change.interactable = false
  self.ui.mBtn_TakeOff.interactable = false
  self.ui.mBtn_Back.interactable = false
  self.ui.mBtn_Home.interactable = false
  self:ChangeSkinFunction(clothesData.id)
end

function UIDormSkinChangePanel:ChangeSkinFunction(clothID)
  self:RootAnimatorPlayAnimByTrigger("FadeOut")
  setactive(self.ui.mObj_SwitchArrow.gameObject, false)
  NetCmdLoungeData:SetChangeClothState(1)
  LoungeHelper.InteractManager:PlayChangeCloth("Before", function()
  end)
  self:CleanTimeIndex(1)
  self:CleanTimeIndex(2)
  self:CleanTimeIndex(3)
  self.timeList[1] = TimerSys:DelayCall(2.6, function()
    UISystem.UISystemBlackCanvas:PlayFadeOutEnhanceBlack(0.5, function()
      NetCmdLoungeData:SendChangeCostumeCmd(self.gunCmdData.id, clothID, function(ret)
        if ret == ErrorCodeSuc then
          NetCmdLoungeData:CleanCurrAnimId()
          self.gunCmdData:SetDormCostume(clothID)
          self:refresh(false)
          CS.LoungeModelManager.Instance:SwitchGunModel(self.gunCmdData.id, function()
            NetCmdLoungeData:SetChangeClothState(3)
            LoungeHelper.InteractManager:PlayChangeCloth("After", function()
              local text = TableData.GetHintById(230009)
              PopupMessageManager.PopupPositiveString(text)
              self.ui.mBtn_Change.interactable = true
              self.ui.mBtn_TakeOff.interactable = true
              self.ui.mBtn_Back.interactable = true
              self.ui.mBtn_Home.interactable = true
              setactive(self.ui.mObj_SwitchArrow.gameObject, true)
              self:RefreshBtnState()
              LoungeHelper.InteractManager:PlayChangeCloth("Idle")
            end)
          end)
        end
      end)
      self.timeList[2] = TimerSys:DelayCall(0.5, function()
        UISystem.UISystemBlackCanvas:PlayFadeInEnhanceBlack(0.5, function()
        end, CS.DG.Tweening.Ease.InOutSine)
        self:CleanTimeIndex(2)
      end)
    end, CS.DG.Tweening.Ease.InOutSine)
    self.timeList[3] = TimerSys:DelayCall(2, function()
      self:RootAnimatorPlayAnimByTrigger("FadeIn")
      NetCmdLoungeData:SetChangeClothState(2)
      self:CleanTimeIndex(3)
    end)
    self:CleanTimeIndex(1)
  end)
end

function UIDormSkinChangePanel:CleanTimeIndex(index)
  if self.timeList[index] then
    self.timeList[index]:Stop()
    self.timeList[index] = nil
  end
end

function UIDormSkinChangePanel:onClickVisual()
  self.isShow = not self.isShow
  if self.isShow then
    setactive(self.ui.mTrans_Icon1, false)
    setactive(self.ui.mTrans_Icon2, true)
    setactive(self.ui.mTrans_Right, true)
  else
    setactive(self.ui.mTrans_Icon1, true)
    setactive(self.ui.mTrans_Icon2, false)
    setactive(self.ui.mTrans_Right, false)
  end
end

function UIDormSkinChangePanel:refreshModel(needGunClothesAnim)
end

function UIDormSkinChangePanel:refreshGrpBtn()
  setactivewithcheck(self.ui.mBtn_Change, false)
  setactivewithcheck(self.ui.mBtn_TakeOff, false)
  if #self.slotTable <= 0 then
    return
  end
  local curSlot = self:getCurSlot()
  if curSlot == nil then
    setactivewithcheck(self.ui.mBtn_Change, true)
    return
  end
  local clothesData = curSlot:GetClothesData()
  local isFocusEquipped = curSlot:GetClothesId() == self.gunCmdData.dormCostume
  if isFocusEquipped then
    setactivewithcheck(self.ui.mBtn_TakeOff, true)
    return
  end
  if clothesData.unlock_type == 1 then
    setactivewithcheck(self.ui.mBtn_Change, true)
  elseif clothesData.unlock_type == 2 then
    local isUnlock = curSlot:IsUnlock()
    if isUnlock then
      setactivewithcheck(self.ui.mBtn_Change, true)
    end
  elseif clothesData.unlock_type == 3 then
    local isUnlock = curSlot:IsUnlock()
    if isUnlock then
      setactivewithcheck(self.ui.mBtn_Change, true)
    end
  elseif clothesData.unlock_type == 4 then
    local isUnlock = curSlot:IsUnlock()
    if isUnlock then
      setactivewithcheck(self.ui.mBtn_Change, true)
    end
  end
end

function UIDormSkinChangePanel:playChangeClothesAnim(clothesData)
end

function UIDormSkinChangePanel:onClickSlot(slotIndex)
  if not slotIndex then
    return
  end
  if self.curSlotIndex == slotIndex then
    self:scrollToCurSlotIndex(true)
    return
  end
  if slotIndex <= 0 or slotIndex > #self.slotTable then
    return
  end
  self.currIndex = slotIndex
  local prevSlotIndex = self.curSlotIndex
  self.curSlotIndex = slotIndex
  self:onSwitchedSelectSlotAfter(prevSlotIndex, self.curSlotIndex)
end

function UIDormSkinChangePanel:onSwitchedSelectSlotAfter(prevSlotIndex, curSlotIndex)
  self:refresh(true)
  self:scrollToCurSlotIndex(true)
  local curSlot = self:getCurSlot()
  if curSlot == nil then
    return
  end
  local clothesData = curSlot:GetClothesData()
  if curSlot:IsUnlock() then
    NetCmdGunClothesData:SetDormPreviewedRecord(clothesData.id)
  end
end

function UIDormSkinChangePanel:getCurSlot()
  return self.slotTable[self.curSlotIndex]
end

function UIDormSkinChangePanel:refreshGunDesc()
end

function UIDormSkinChangePanel:OnClose()
  self:UnRegistrationKeyboard(KeyCode.Escape)
  LoungeHelper.CameraCtrl.isDebug = true
  self.ui.mBtn_Change.interactable = true
  self.ui.mBtn_TakeOff.interactable = true
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnReconnectSuc, UIDormSkinChangePanel.ConnectSuccess)
  for k, v in pairs(self.timeList) do
    self:CleanTimeIndex(k)
  end
  if DormGlobal.jumptomainpanel then
  else
    LoungeHelper.InteractManager:CheckAddPlayInteract(nil, true)
    if NetCmdLoungeData:GetChangeClothAniId() == NetCmdLoungeData:GetRandomAnimId() then
      LoungeHelper.CameraCtrl.CameraPreObj:TransitionLookAtToChangeCloth()
    else
      NetCmdLoungeData:SetCameraReserve(false)
      NetCmdLoungeData:CleanCameraPos()
      LoungeHelper.CameraCtrl.CameraPreObj:ExitLookAt()
    end
  end
end

function UIDormSkinChangePanel:OnCameraStart()
  return self.closeTime or 0.01
end

function UIDormSkinChangePanel:OnCameraBack()
  return self.closeTime
end

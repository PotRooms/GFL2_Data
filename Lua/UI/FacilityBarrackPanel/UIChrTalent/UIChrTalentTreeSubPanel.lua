require("UI.FacilityBarrackPanel.UIChrTalent.UITalentGlobal")
require("UI.FacilityBarrackPanel.UIChrTalent.UIChrTalentGroup")
require("UI.FacilityBarrackPanel.UIChrTalent.UIChrTalentKeySlot")
UIChrTalentTreeSubPanel = class("UIChrTalentTreeSubPanel", UIBaseCtrl)

function UIChrTalentTreeSubPanel:ctor(root, uiChrTalentPanel)
  self.ui = UIUtils.GetUIBindTable(root)
  self:SetRoot(root.transform)
  self.uiChrTalentPanel = uiChrTalentPanel
  self.inbornTalentKeySlot = UIChrTalentKeySlot.New(self.ui.mBtn_CommonSkill)
  self.inbornTalentKeySlot:AddFocusListener(function()
    self:onFocusInbornSkill()
  end)
  self.shareTalentItemSlot = UIChrTalentKeySlot.New(self.ui.mBtn_ShareSkill)
  self.shareTalentItemSlot:AddFocusListener(function()
    self:onFocusShareSkillItem()
  end)
  self.poolingCo = coroutine.create(function()
    gfdebug("UIChrTalentTreeSubPanel poolingCo  Start")
    self.talentGroupTable = self:poolingAllGroup(true)
    self.poolingCo = nil
    gfdebug("UIChrTalentTreeSubPanel poolingCo  End")
  end)
end

function UIChrTalentTreeSubPanel:Init(gunId)
  self.gunId = gunId
  self.talentGunData = TableData.listSquadTalentGunDatas:GetDataById(self.gunId)
  if not self.talentGunData then
    gferror("gunTalentData is nil!!!")
    return
  end
  self.inbornTalentKeySlot:Init(self.gunId, self.talentGunData.InitialTalentKeyId)
  local talentKeyData = TableDataBase.listTalentKeyDatas:GetDataById(self.talentGunData.InitialTalentKeyId)
  if talentKeyData.talent_key_type == 0 then
    IconUtils.GetSkillIconAsync(talentKeyData.BattleSkillId, self.ui.mImage_InbornIcon)
  end
  self.shareTalentItemSlot:Init(self.gunId, self.talentGunData.FullyActiveItemId)
  IconUtils.GetItemIconSpriteAsync(self.talentGunData.FullyActiveItemId, self.ui.mImage_ShareIcon)
  local gunCmdData = NetCmdTeamData:GetGunByID(self.gunId)
  self.prevIsReceivedShareTalentItem = gunCmdData ~= nil and gunCmdData.IsReceivedShareTalentItem or false
  self.prevIsUnlockedOfShareTalentItem = NetCmdTalentData:IsUnlockedShareTalentItem(self.gunId)
  self.initCo = coroutine.create(function()
    gfdebug("UIChrTalentTreeSubPanel initCo  Start")
    self:initAllGroup()
    self.initCo = nil
    gfdebug("UIChrTalentTreeSubPanel initCo  End")
  end)
end

function UIChrTalentTreeSubPanel:OnShowStart()
  self.co = coroutine.create(function()
    gfdebug("UIChrTalentTreeSubPanel  OnShowStart")
    self.inbornTalentKeySlot:SetAnimTrigger("FadeIn")
    self.uiChrTalentPanel.ui.mAnimator_Root:SetTrigger("FadeIn")
    self.shareTalentItemSlot:SetAnimInteger("State", 0)
    gfdebug("UIChrTalentTreeSubPanel  SetAnimInteger")
    self:showAllVisibleGroup()
    gfdebug("UIChrTalentTreeSubPanel  showAllVisibleGroup")
    self:refreshAllGroupWithCoroutine()
    gfdebug("UIChrTalentTreeSubPanel  refreshAllGroupWithCoroutine")
    self:refreshShareTalentItemSlot()
    gfdebug("UIChrTalentTreeSubPanel  refreshShareTalentItemSlot")
    self.curGroupIndex = nil
    self.curSlotIndex = nil
    self:focusTalentSlotByEnter()
    gfdebug("UIChrTalentTreeSubPanel  focusTalentSlotByEnter")
    if self.curSlotIndex == nil then
      self:onFocusInbornSkill()
    end
    gfdebug("UIChrTalentTreeSubPanel  onFocusInbornSkill")
    self.co = nil
    if self.onShowFinishCallback then
      self.onShowFinishCallback()
    end
    gfdebug("UIChrTalentTreeSubPanel  onShowFinishCallback")
  end)
end

function UIChrTalentTreeSubPanel:OnRecover()
  self.poolingCo = nil
  self.talentGroupTable = self:poolingAllGroup(false)
  self.initCo = nil
  self:initAllGroup()
end

function UIChrTalentTreeSubPanel:OnUpdate()
  if self.poolingCo then
    coroutine.resume(self.poolingCo)
    return
  end
  if self.initCo then
    coroutine.resume(self.initCo)
    return
  end
  if self.co then
    coroutine.resume(self.co)
  end
end

function UIChrTalentTreeSubPanel:OnHide()
  self:onClickSlot(-1, -1)
  self.uiChrTalentPanel.ui.mAnimator_Root:SetTrigger("FadeOut")
  self.initCo = nil
  self.co = nil
end

function UIChrTalentTreeSubPanel:OnHideFinish()
  self.initCo = nil
  self.co = nil
end

function UIChrTalentTreeSubPanel:OnRelease()
  self.gunId = nil
  self.uiChrTalentPanel = nil
  self.curGroupIndex = nil
  self.curSlotIndex = nil
  self.talentGunData = nil
  self.inbornTalentKeySlot:OnRelease()
  self.inbornTalentKeySlot = nil
  self.shareTalentItemSlot:OnRelease()
  self.shareTalentItemSlot = nil
  self:ReleaseCtrlTable(self.talentGroupTable, true)
  self.talentGroupTable = nil
  if self.tween then
    LuaDOTweenUtils.Kill(self.tween, false)
  end
  self.poolingCo = nil
  self.initCo = nil
  self.co = nil
  self.tween = nil
  self.super.OnRelease(self)
end

function UIChrTalentTreeSubPanel:Refresh()
  self:refreshAllGroup()
  self:refreshShareTalentItemSlot()
end

function UIChrTalentTreeSubPanel:refreshShareTalentItemSlot()
  local gunCmdData = NetCmdTeamData:GetGunByID(self.gunId)
  local isUnlocked = NetCmdTalentData:IsUnlockedShareTalentItem(self.gunId)
  if isUnlocked then
    local talentKeyData = TableDataBase.listTalentKeyDatas:GetDataById(self.talentGunData.FullyActiveItemId)
    local itemData = TableDataBase.listItemDatas:GetDataById(self.talentGunData.FullyActiveItemId)
    if itemData.Rank <= 4 then
      self.shareTalentItemSlot:SetAnimInteger("State", 2)
      if self.prevIsUnlockedShareTalentItem == false then
        self.uiChrTalentPanel:EnableInputMask(true)
        local animLen = LuaUtils.GetAnimationClipLength(self.shareTalentItemSlot.mAnimator, "State_2")
        TimerSys:DelayCall(animLen, function()
          self.uiChrTalentPanel:EnableInputMask(false)
        end)
      end
    elseif itemData.Rank == 5 then
      self.shareTalentItemSlot:SetAnimInteger("State", 1)
      if self.prevIsUnlockedShareTalentItem == false then
        self.uiChrTalentPanel:EnableInputMask(true)
        local animLen = LuaUtils.GetAnimationClipLength(self.shareTalentItemSlot.mAnimator, "State_1")
        TimerSys:DelayCall(animLen, function()
          self.uiChrTalentPanel:EnableInputMask(false)
        end)
      end
    end
    self.shareTalentItemSlot:SetRedPointVisible(not gunCmdData.IsReceivedShareTalentItem)
    if self.prevIsReceivedShareTalentItem == false and gunCmdData.IsReceivedShareTalentItem then
      self.shareTalentItemSlot:SetAnimTrigger("Active_Fx")
      self.uiChrTalentPanel:EnableInputMask(true)
      local animLen = LuaUtils.GetAnimationClipLength(self.shareTalentItemSlot.mAnimator, "Active_Fx")
      TimerSys:DelayCall(animLen, function()
        self.uiChrTalentPanel:EnableInputMask(false)
        local onCloseCallback = function()
        end
        UISystem:OpenCommonReceivePanel({onCloseCallback})
      end)
    end
  else
    self.shareTalentItemSlot:SetAnimInteger("State", 0)
    self.shareTalentItemSlot:SetRedPointVisible(false)
    if self.talentGunData.unlock_sheet == 1 then
      local achievementDetailData = TableDataBase.listAchievementDetailDatas:GetDataById(self.talentGunData.unlock_id)
      if achievementDetailData == nil then
        return
      end
      self.ui.mText_ShareUnlockTips.text = achievementDetailData.des.str
    elseif self.talentGunData.unlock_sheet == 2 then
      local unlockDetailData = TableDataBase.listUnlockDetailDatas:GetDataById(self.talentGunData.unlock_id)
      if not unlockDetailData then
        return
      end
      self.ui.mText_ShareUnlockTips.text = unlockDetailData.des.str
    else
      gferror("SquadTalentGun\232\161\168unlock_sheet\229\173\151\230\174\181\228\184\173\229\173\152\229\156\168\230\156\170\229\174\154\228\185\137\231\154\132\232\167\163\233\148\129\231\177\187\229\158\139\239\188\154" .. self.talentGunData.unlock_sheet)
    end
  end
  setactive(self.ui.mTrans_Received, gunCmdData.IsReceivedShareTalentItem)
  self.prevIsUnlockedShareTalentItem = isUnlocked
end

function UIChrTalentTreeSubPanel:AddSlotClickListener(callback)
  self.onSelectSlotCallback = callback
end

function UIChrTalentTreeSubPanel:AddInbornTalentKeyClickListener(callback)
  self.onClickInbornTalentKeyCallback = callback
end

function UIChrTalentTreeSubPanel:AddShareSkillItemClickListener(callback)
  self.onClickShareSkillItemCallback = callback
end

function UIChrTalentTreeSubPanel:AddOnShowFinishCallback(callback)
  self.onShowFinishCallback = callback
end

function UIChrTalentTreeSubPanel:poolingAllGroup(isWithCo)
  local talentGroupTable = {
    nil,
    nil,
    nil,
    nil,
    nil,
    nil
  }
  for i = 1, 6 do
    local slotGoTable = {
      nil,
      nil,
      nil
    }
    for j = 1, 3 do
      local slotLineRoot = self.ui["mScrollListChild_GrpTalentLine" .. tostring(j)]
      local slot = UIUtils.InstantiateByTemplate(slotLineRoot.childItem, slotLineRoot.transform)
      table.insert(slotGoTable, slot)
    end
    local talentGroup = UIChrTalentGroup.New(slotGoTable)
    talentGroup:AddSlotClickListener(function(newGroupIndex, newSlotIndex)
      self:onClickSlot(newGroupIndex, newSlotIndex)
    end)
    table.insert(talentGroupTable, talentGroup)
    if i % 3 == 0 and isWithCo then
      coroutine.yield()
    end
  end
  return talentGroupTable
end

function UIChrTalentTreeSubPanel:onClickSlot(newGroupIndex, newSlotIndex)
  if self.curGroupIndex == newGroupIndex and self.curSlotIndex == newSlotIndex then
    return
  end
  if not self.talentGroupTable then
    return
  end
  if self.curSlotIndex and self.curGroupIndex > 0 and self.curSlotIndex > 0 then
    self.talentGroupTable[self.curGroupIndex]:GetSlotByIndex(self.curSlotIndex):LoseFocus()
  end
  self.curGroupIndex = newGroupIndex
  self.curSlotIndex = newSlotIndex
  if self.curSlotIndex and self.curGroupIndex > 0 and self.curSlotIndex > 0 then
    local slot = self.talentGroupTable[self.curGroupIndex]:GetSlotByIndex(self.curSlotIndex)
    slot:Focus()
    self:onSlotSelected(slot)
  end
end

function UIChrTalentTreeSubPanel:focusTalentSlotByEnter()
  local isAllAuthorized = NetCmdTalentData:IsAllFirstPointAuthorized(self.gunId)
  if isAllAuthorized then
    self:showStartFocusShareSkillItem()
  else
    local content = self.ui.mScrollRect.content
    content.anchoredPosition = Vector2(0, content.anchoredPosition.y)
    local suc = self:focusLastUnauthorizedTalentPointInGroupFirst()
    if not suc then
      self:focusFirstLockTalentPointInGroupFirst()
    end
  end
end

function UIChrTalentTreeSubPanel:focusLastUnauthorizedTalentPointInGroupFirst()
  if not self.talentGroupTable then
    return
  end
  for i = #self.talentGroupTable, 1, -1 do
    local group = self.talentGroupTable[i]
    local slotTable = group:GetAllSlotTable()
    for j = 1, #slotTable do
      local groupId = slotTable[j]:GetGroupId()
      local isFirstPoint = NetCmdTalentData:IsFirstPoint(self.gunId, groupId)
      local state = slotTable[j]:GetState()
      if state ~= nil and state == UITalentGlobal.TalentState.Unauthorized and isFirstPoint then
        self:onClickSlot(i, j)
        return true
      end
    end
  end
  return false
end

function UIChrTalentTreeSubPanel:focusFirstLockTalentPointInGroupFirst()
  if not self.talentGroupTable then
    return
  end
  for i = 1, #self.talentGroupTable do
    local group = self.talentGroupTable[i]
    local slotTable = group:GetAllSlotTable()
    for j = 1, #slotTable do
      local groupId = slotTable[j]:GetGroupId()
      local isFirstPoint = NetCmdTalentData:IsFirstPoint(self.gunId, groupId)
      local state = slotTable[j]:GetState()
      if state ~= nil and state <= UITalentGlobal.TalentState.Unauthorized and isFirstPoint then
        self:onClickSlot(i, j)
        return true
      end
    end
  end
  return false
end

function UIChrTalentTreeSubPanel:FocusNextTalent()
  local curSlot = self:getCurSlot()
  local groupId = curSlot:GetGroupId()
  if curSlot:GetType() == UITalentGlobal.TalentType.NormalAttribute or curSlot:GetType() == UITalentGlobal.TalentType.AdvancedAttribute then
    local isAllAuthorized = NetCmdTalentData:IsAllFirstPointAuthorized(self.gunId)
    if isAllAuthorized then
      self:FocusShareSkillItem()
    else
      local groupData = TableDataBase.listSquadTalentGroupDatas:GetDataById(groupId)
      self:tryFocusNextTalent(groupData)
    end
  else
    local groupData = TableDataBase.listSquadTalentGroupDatas:GetDataById(groupId)
    self:tryFocusNextTalent(groupData)
  end
end

function UIChrTalentTreeSubPanel:tryFocusNextTalent(groupData)
  if groupData and groupData.per_point.Count > 0 then
    local slot = self:getSlotByGroupId(groupData.per_point[0])
    if not slot then
      gferror("slot not found!")
      return
    end
    local groupIndex = slot:GetGroupIndex()
    local slotIndex = slot:GetSlotIndex()
    self:onClickSlot(groupIndex, slotIndex)
    return true
  end
  return false
end

function UIChrTalentTreeSubPanel:getSlotByGroupId(groupId)
  if not self.talentGroupTable then
    return
  end
  for i = #self.talentGroupTable, 1, -1 do
    local group = self.talentGroupTable[i]
    local slotTable = group:GetAllSlotTable()
    for j = 1, #slotTable do
      local tempGroupId = slotTable[j]:GetGroupId()
      if tempGroupId == groupId then
        return slotTable[j]
      end
    end
  end
  return nil
end

function UIChrTalentTreeSubPanel:autoSelectLastUnauthorizedSlotInAllGroup()
  if not self.talentGroupTable then
    return
  end
  for i = #self.talentGroupTable, 1, -1 do
    local group = self.talentGroupTable[i]
    local slotTable = group:GetAllSlotTable()
    for j = 1, #slotTable do
      local state = slotTable[j]:GetState()
      if state == UITalentGlobal.TalentState.Unauthorized then
        self:onClickSlot(i, j)
        return
      end
    end
  end
end

function UIChrTalentTreeSubPanel:autoSelectLastUnlockedSlotInAllGroup()
  for i = #self.talentGroupTable, 1, -1 do
    local group = self.talentGroupTable[i]
    local slotTable = group:GetAllSlotTable()
    for j = 1, #slotTable do
      local state = slotTable[j]:GetState()
      if state ~= nil and state > UITalentGlobal.TalentState.Unauthorized then
        self:onClickSlot(i, j)
        self:autoSelectNextTalentInCurrentLine()
        return
      end
    end
  end
end

function UIChrTalentTreeSubPanel:autoSelectNextTalentInCurrentLine()
  local slot = self:getCurSlot()
  if not slot then
    return false
  end
  local talentId = slot:GetTalentId()
  local groupId = slot:GetGroupId()
  local groupIndex = slot:GetGroupIndex()
  local nextGroupIdList = NetCmdTalentData:GetGunNextTreeGroupIdList(talentId, groupId)
  if not nextGroupIdList or nextGroupIdList.Count == 0 then
    if NetCmdTalentData:IsAllAuthorized(self.gunId) then
      self:onFocusShareSkillItem()
    else
      self:onSlotSelected(slot)
    end
    return true
  end
  if not self.talentGroupTable then
    return
  end
  local firstNextGroupId = nextGroupIdList[0]
  for i = groupIndex, #self.talentGroupTable do
    local group = self.talentGroupTable[i]
    local slotTable = group:GetAllSlotTable()
    for j = 1, #slotTable do
      local tempSlot = slotTable[j]
      if tempSlot:GetGroupId() == firstNextGroupId then
        if tempSlot:GetState() > UITalentGlobal.TalentState.Unauthorized then
          self:autoSelectLastUnauthorizedSlotInAllGroup()
        else
          self:onClickSlot(i, j)
        end
        return true
      end
    end
  end
  return false
end

function UIChrTalentTreeSubPanel:autoSelectNextSlotInAllLine()
  local slot = self:getCurSlot()
  if not slot then
    return
  end
  local isLastPoint = NetCmdTalentData:IsLastPoint(self.gunId, slot:GetGroupId())
  if isLastPoint then
    local isAllAuthorized = NetCmdTalentData:IsAllAuthorized(self.gunId)
    if isAllAuthorized then
      self:onFocusShareSkillItem()
    else
      self:autoSelectLastUnauthorizedSlotInAllGroup()
    end
  else
    self:autoSelectNextTalentInCurrentLine()
  end
end

function UIChrTalentTreeSubPanel:initAllGroup()
  if not self.talentGroupTable then
    return
  end
  local treeIdList = self.talentGunData.traverse_squad_talent_tree_id
  for i, talentGroup in ipairs(self.talentGroupTable) do
    if i - 1 < treeIdList.Count then
      talentGroup:Init(self.gunId, treeIdList[i - 1], i)
      talentGroup:SetVisible(true)
    else
      talentGroup:SetVisible(false)
    end
  end
end

function UIChrTalentTreeSubPanel:setAllGroupAlpha(value)
  if not self.talentGroupTable then
    return
  end
  for i, talentGroup in ipairs(self.talentGroupTable) do
    talentGroup:SetAllSlotAlpha(value)
  end
end

function UIChrTalentTreeSubPanel:showAllVisibleGroup()
  if not self.talentGroupTable then
    return
  end
  for i, talentGroup in ipairs(self.talentGroupTable) do
    if talentGroup:IsVisible() then
      talentGroup:OnShow()
    end
  end
end

function UIChrTalentTreeSubPanel:refreshAllGroupWithCoroutine()
  if not self.talentGroupTable then
    return
  end
  for i, talentGroup in ipairs(self.talentGroupTable) do
    if i % 6 == 0 then
      coroutine.yield()
    end
    if talentGroup:IsVisible() then
      talentGroup:Refresh()
    end
  end
end

function UIChrTalentTreeSubPanel:refreshAllGroup()
  if not self.talentGroupTable then
    return
  end
  for i, talentGroup in ipairs(self.talentGroupTable) do
    if talentGroup:IsVisible() then
      talentGroup:Refresh()
    end
  end
end

function UIChrTalentTreeSubPanel:refreshCurGroup()
  local curGroup = self:getCurGroup()
  if not curGroup then
    return
  end
  curGroup:Refresh()
end

function UIChrTalentTreeSubPanel:refreshCurSlot()
  local curSlot = self:getCurSlot()
  if not curSlot then
    return
  end
  curSlot:Refresh()
end

function UIChrTalentTreeSubPanel:getLastActivatedSlot()
  if not self.talentGroupTable then
    return
  end
  for i = #self.talentGroupTable, 1, -1 do
    local lastLineSlotTable = self.talentGroupTable[i]:GetAllSlotTable()
    for j = #lastLineSlotTable, 1, -1 do
      local state = lastLineSlotTable[j]:GetState()
      if state >= UITalentGlobal.TalentState.Authorized then
        return lastLineSlotTable[j]
      end
    end
  end
  return nil
end

function UIChrTalentTreeSubPanel:getCurSlot()
  if not self.curGroupIndex or not self.curSlotIndex then
    return
  end
  return self.talentGroupTable[self.curGroupIndex]:GetSlotByIndex(self.curSlotIndex)
end

function UIChrTalentTreeSubPanel:getCurGroup()
  if not self.curGroupIndex then
    return
  end
  return self.talentGroupTable[self.curGroupIndex]
end

function UIChrTalentTreeSubPanel:onFocusInbornSkill()
  self:onClickSlot(-1, -1)
  self.shareTalentItemSlot:LoseFocus()
  self.inbornTalentKeySlot:Focus()
  self:adjustScrollRect(0)
  if self.onClickInbornTalentKeyCallback then
    self.onClickInbornTalentKeyCallback()
  end
end

function UIChrTalentTreeSubPanel:showStartFocusShareSkillItem()
  local content = self.ui.mScrollRect.content
  content.anchoredPosition = Vector2(0, content.anchoredPosition.y)
  self:FocusShareSkillItem()
end

function UIChrTalentTreeSubPanel:FocusShareSkillItem()
  self:onFocusShareSkillItem(0)
end

function UIChrTalentTreeSubPanel:showStartAutoSelectLastUnlockedSlotInAllGroup()
  local content = self.ui.mScrollRect.content
  content.anchoredPosition = Vector2(0, content.anchoredPosition.y)
  self:autoSelectLastUnauthorizedSlotInAllGroup()
  if self.curSlotIndex == nil or self.curSlotIndex == -1 then
    self:autoSelectLastUnlockedSlotInAllGroup()
  end
end

function UIChrTalentTreeSubPanel:onFocusShareSkillItem(duration)
  self:onClickSlot(-1, -1)
  self.inbornTalentKeySlot:LoseFocus()
  self.shareTalentItemSlot:Focus()
  self:adjustScrollRect(-self.ui.mScrollRect.content.transform.sizeDelta.x, duration)
  if self.onClickShareSkillItemCallback then
    self.onClickShareSkillItemCallback()
  end
end

function UIChrTalentTreeSubPanel:onSlotSelected(slot)
  self.inbornTalentKeySlot:LoseFocus()
  self.shareTalentItemSlot:LoseFocus()
  self:adjustSlotScrollRect()
  if self.onSelectSlotCallback then
    self.onSelectSlotCallback(slot)
  end
end

function UIChrTalentTreeSubPanel:adjustSlotScrollRect()
  local elementDis = 280
  local startPosX = 0
  local middleStartPosX = elementDis * 0.5
  local panelWidth = UISystem.UICanvas.transform.sizeDelta.x
  local defaultRatio = panelWidth / 1600
  if CS.PlatformSetting.PlatformType.PC == CS.GameRoot.Instance.AdapterPlatform then
    startPosX = 0
  elseif CS.PlatformSetting.PlatformType.Mobile == CS.GameRoot.Instance.AdapterPlatform then
    startPosX = 200 * (1 + (1 - defaultRatio ^ 10))
  end
  local anchoredPosX = 0
  if self.curSlotIndex == 2 then
    anchoredPosX = startPosX + (self.curGroupIndex - 1) * elementDis - middleStartPosX
  else
    anchoredPosX = startPosX + (self.curGroupIndex - 1) * elementDis
  end
  self:adjustScrollRect(-anchoredPosX)
end

function UIChrTalentTreeSubPanel:adjustScrollRect(endValue, duration)
  if self.tween then
    LuaDOTweenUtils.Kill(self.tween, false)
  end
  if duration == nil then
    duration = 0.4
  end
  endValue = CS.UnityEngine.Mathf.Clamp(endValue, -self.ui.mScrollRect.content.sizeDelta.x, 0)
  self.tween = LuaDOTweenUtils.SmoothMoveX(self.ui.mScrollRect.content, endValue, duration, nil, Ease.OutCubic)
end

function UIChrTalentTreeSubPanel:getCurSlotAnimLen(animName)
  local slot = self:getCurSlot()
  if not slot then
    return
  end
  return slot:GetAnimLength(animName)
end

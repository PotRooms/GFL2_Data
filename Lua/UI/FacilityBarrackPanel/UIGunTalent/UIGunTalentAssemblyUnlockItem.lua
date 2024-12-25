UIGunTalentAssemblyUnlockItem = class("UIGunTalentAssemblyUnlockItem", UIBaseCtrl)

function UIGunTalentAssemblyUnlockItem:ctor()
end

function UIGunTalentAssemblyUnlockItem:InitCtrl(transform, obj)
  local itemPrefab = transform:GetComponent(typeof(CS.ScrollListChild))
  local instObj
  if obj == nil then
    instObj = instantiate(itemPrefab.childItem, transform, false)
  else
    instObj = obj
  end
  if instObj == nil then
    instObj = instantiate(UIUtils.GetGizmosPrefab("Character/Btn_ChrPowerUpSetTalentItem.prefab", self), transform)
  end
  self:SetRoot(instObj.transform)
  self.ui = {}
  self:LuaUIBindTable(self.mUIRoot, self.ui)
  UIUtils.GetButtonListener(self:GetRoot()).onClick = function()
    self:OnClickTalentButton()
  end
  local notNeedLock = AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.SquadTalent)
  setactivewithcheck(self.ui.mTrans_Lock.gameObject, not notNeedLock)
  setactivewithcheck(self.ui.mTrans_PrivateSlot.gameObject, notNeedLock)
  setactivewithcheck(self.ui.mTrans_PublicSlot.gameObject, notNeedLock)
  setactivewithcheck(self.ui.mTrans_TalentRedPoint.gameObject, false)
end

function UIGunTalentAssemblyUnlockItem:SetData(gunId)
  self.mGunId = gunId
  self.mGunCmdData = NetCmdTeamData:GetGunByID(self.mGunId)
  if self.mGunCmdData == nil then
    return
  end
  if AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.SquadTalent) then
    local privateSlotList = self.mGunCmdData.mGun.PrivateTalentSkillItems
    local publicSlotList = self.mGunCmdData.mGun.PublicTalentSkillItemsUid
    local spSlotList = self.mGunCmdData.mGun.SpecialTalentSkillItems
    local privateTalentSlotCount = NetCmdTalentData:PrivateTalentSlotCount(self.mGunId)
    if privateTalentSlotCount == 0 then
      setactivewithcheck(self.ui.mPrivateSlotOff1.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotOff2.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotOff3.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotOn1.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotOn2.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotOn3.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotNone1.gameObject, true)
      setactivewithcheck(self.ui.mPrivateSlotNone2.gameObject, true)
      setactivewithcheck(self.ui.mPrivateSlotNone3.gameObject, true)
    elseif privateTalentSlotCount == 1 then
      local hasTalentKey1 = 0 < privateSlotList[0]
      setactivewithcheck(self.ui.mPrivateSlotOff1.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotOff2.gameObject, not hasTalentKey1)
      setactivewithcheck(self.ui.mPrivateSlotOff3.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotOn1.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotOn2.gameObject, hasTalentKey1)
      setactivewithcheck(self.ui.mPrivateSlotOn3.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotNone1.gameObject, true)
      setactivewithcheck(self.ui.mPrivateSlotNone2.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotNone3.gameObject, true)
    elseif privateTalentSlotCount == 2 then
      local hasTalentKey1 = 0 < privateSlotList[0]
      local hasTalentKey2 = 0 < privateSlotList[1]
      setactivewithcheck(self.ui.mPrivateSlotOff1.gameObject, not hasTalentKey1)
      setactivewithcheck(self.ui.mPrivateSlotOff2.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotOff3.gameObject, not hasTalentKey2)
      setactivewithcheck(self.ui.mPrivateSlotOn1.gameObject, hasTalentKey1)
      setactivewithcheck(self.ui.mPrivateSlotOn2.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotOn3.gameObject, hasTalentKey2)
      setactivewithcheck(self.ui.mPrivateSlotNone1.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotNone2.gameObject, true)
      setactivewithcheck(self.ui.mPrivateSlotNone3.gameObject, false)
    elseif privateTalentSlotCount == 3 then
      local hasTalentKey1 = 0 < privateSlotList[0]
      local hasTalentKey2 = 0 < privateSlotList[1]
      local hasTalentKey3 = 0 < privateSlotList[2]
      setactivewithcheck(self.ui.mPrivateSlotOff1.gameObject, not hasTalentKey1)
      setactivewithcheck(self.ui.mPrivateSlotOff2.gameObject, not hasTalentKey2)
      setactivewithcheck(self.ui.mPrivateSlotOff3.gameObject, not hasTalentKey3)
      setactivewithcheck(self.ui.mPrivateSlotOn1.gameObject, hasTalentKey1)
      setactivewithcheck(self.ui.mPrivateSlotOn2.gameObject, hasTalentKey2)
      setactivewithcheck(self.ui.mPrivateSlotOn3.gameObject, hasTalentKey3)
      setactivewithcheck(self.ui.mPrivateSlotNone1.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotNone2.gameObject, false)
      setactivewithcheck(self.ui.mPrivateSlotNone3.gameObject, false)
    end
    if privateSlotList.Count ~= 0 then
      if 0 < privateSlotList[0] then
        local itemData = TableData.listItemDatas:GetDataById(privateSlotList[0])
        self.ui.mPrivateSlotImage1.color = TableData.GetGlobalGun_Quality_Color2(itemData.rank, self.ui.mPrivateSlotImage1.color.a)
      end
      if 0 < privateSlotList[1] then
        local itemData = TableData.listItemDatas:GetDataById(privateSlotList[1])
        self.ui.mPrivateSlotImage2.color = TableData.GetGlobalGun_Quality_Color2(itemData.rank, self.ui.mPrivateSlotImage2.color.a)
      end
      if 0 < privateSlotList[2] then
        local itemData = TableData.listItemDatas:GetDataById(privateSlotList[2])
        self.ui.mPrivateSlotImage3.color = TableData.GetGlobalGun_Quality_Color2(itemData.rank, self.ui.mPrivateSlotImage3.color.a)
      end
    end
    local publicTalentSlotCount = NetCmdTalentData:PublicTalentSlotCount(self.mGunId)
    if publicTalentSlotCount == 0 then
      setactivewithcheck(self.ui.mPublicSlotOff1.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotOff2.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotOff3.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotOn1.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotOn2.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotOn3.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotNone1.gameObject, true)
      setactivewithcheck(self.ui.mPublicSlotNone2.gameObject, true)
      setactivewithcheck(self.ui.mPublicSlotNone3.gameObject, true)
    elseif publicTalentSlotCount == 1 then
      local hasTalentKey1 = 0 < publicSlotList[0]
      setactivewithcheck(self.ui.mPublicSlotOff1.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotOff2.gameObject, not hasTalentKey1)
      setactivewithcheck(self.ui.mPublicSlotOff3.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotOn1.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotOn2.gameObject, hasTalentKey1)
      setactivewithcheck(self.ui.mPublicSlotOn3.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotNone1.gameObject, true)
      setactivewithcheck(self.ui.mPublicSlotNone2.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotNone3.gameObject, true)
    elseif publicTalentSlotCount == 2 then
      local hasTalentKey1 = 0 < publicSlotList[0]
      local hasTalentKey2 = 0 < publicSlotList[1]
      setactivewithcheck(self.ui.mPublicSlotOff1.gameObject, not hasTalentKey1)
      setactivewithcheck(self.ui.mPublicSlotOff2.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotOff3.gameObject, not hasTalentKey2)
      setactivewithcheck(self.ui.mPublicSlotOn1.gameObject, hasTalentKey1)
      setactivewithcheck(self.ui.mPublicSlotOn2.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotOn3.gameObject, hasTalentKey2)
      setactivewithcheck(self.ui.mPublicSlotNone1.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotNone2.gameObject, true)
      setactivewithcheck(self.ui.mPublicSlotNone3.gameObject, false)
    elseif publicTalentSlotCount == 3 then
      local hasTalentKey1 = 0 < publicSlotList[0]
      local hasTalentKey2 = 0 < publicSlotList[1]
      local hasTalentKey3 = 0 < publicSlotList[2]
      setactivewithcheck(self.ui.mPublicSlotOff1.gameObject, not hasTalentKey1)
      setactivewithcheck(self.ui.mPublicSlotOff2.gameObject, not hasTalentKey2)
      setactivewithcheck(self.ui.mPublicSlotOff3.gameObject, not hasTalentKey3)
      setactivewithcheck(self.ui.mPublicSlotOn1.gameObject, hasTalentKey1)
      setactivewithcheck(self.ui.mPublicSlotOn2.gameObject, hasTalentKey2)
      setactivewithcheck(self.ui.mPublicSlotOn3.gameObject, hasTalentKey3)
      setactivewithcheck(self.ui.mPublicSlotNone1.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotNone2.gameObject, false)
      setactivewithcheck(self.ui.mPublicSlotNone3.gameObject, false)
    end
    if publicSlotList.Count ~= 0 then
      if 0 < publicSlotList[0] then
        local itemId = NetCmdTalentData:GetPublicSkillItemByUid(publicSlotList[0]).itemId
        local itemData = TableData.listItemDatas:GetDataById(itemId)
        self.ui.mPublicSlotImage1.color = TableData.GetGlobalGun_Quality_Color2(itemData.rank, self.ui.mPublicSlotImage1.color.a)
      end
      if 0 < publicSlotList[1] then
        local itemId = NetCmdTalentData:GetPublicSkillItemByUid(publicSlotList[1]).itemId
        local itemData = TableData.listItemDatas:GetDataById(itemId)
        self.ui.mPublicSlotImage2.color = TableData.GetGlobalGun_Quality_Color2(itemData.rank, self.ui.mPublicSlotImage2.color.a)
      end
      if 0 < publicSlotList[2] then
        local itemId = NetCmdTalentData:GetPublicSkillItemByUid(publicSlotList[2]).itemId
        local itemData = TableData.listItemDatas:GetDataById(itemId)
        self.ui.mPublicSlotImage3.color = TableData.GetGlobalGun_Quality_Color2(itemData.rank, self.ui.mPublicSlotImage3.color.a)
      end
    end
    local spGroupId = NetCmdTalentData:GetGunSpGroupId(self.mGunId)
    if spGroupId ~= 0 then
      setactivewithcheck(self.ui.mTrans_ExtraSlot.gameObject, true)
      setactivewithcheck(self.ui.mTrans_ImgLineLocked.gameObject, false)
      setactivewithcheck(self.ui.mExtraSlotNone.gameObject, false)
      if spSlotList.Count ~= 0 then
        if 0 < spSlotList[0] then
          local spItemData = TableData.listItemDatas:GetDataById(spSlotList[0])
          self.ui.mExtraSlotImage.color = TableData.GetGlobalGun_Quality_Color2(spItemData.rank, self.ui.mExtraSlotImage.color.a)
        end
        setactivewithcheck(self.ui.mExtraSlotOff.gameObject, spSlotList[0] <= 0)
        setactivewithcheck(self.ui.mExtraSlotOn.gameObject, 0 < spSlotList[0])
      else
        setactivewithcheck(self.ui.mExtraSlotOff.gameObject, true)
        setactivewithcheck(self.ui.mExtraSlotOn.gameObject, false)
      end
    else
      setactivewithcheck(self.ui.mTrans_ExtraSlot.gameObject, false)
      setactivewithcheck(self.ui.mTrans_ImgLineLocked.gameObject, true)
    end
    local needRedPoint = NetCmdTalentData:TalentSkillItemRedPoint(self.mGunId)
    if 0 < needRedPoint then
      setactivewithcheck(self.ui.mTrans_TalentRedPoint.gameObject, true)
    else
      setactivewithcheck(self.ui.mTrans_TalentRedPoint.gameObject, false)
    end
  end
  local notNeedLock = AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.SquadTalent)
  setactivewithcheck(self.ui.mTrans_Lock.gameObject, not notNeedLock)
  setactivewithcheck(self.ui.mTrans_PrivateSlot.gameObject, notNeedLock)
  setactivewithcheck(self.ui.mTrans_PublicSlot.gameObject, notNeedLock)
end

function UIGunTalentAssemblyUnlockItem:OnClickTalentButton()
  if self.onClickCallback then
    self.onClickCallback()
  end
end

function UIGunTalentAssemblyUnlockItem:SetRedPointVisible(visible)
  setactivewithcheck(self.ui.mTrans_TalentRedPoint.gameObject, visible)
end

function UIGunTalentAssemblyUnlockItem:AddClickListener(callback)
  self.onClickCallback = callback
end

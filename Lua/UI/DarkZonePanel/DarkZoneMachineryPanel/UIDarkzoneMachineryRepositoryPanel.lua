require("UI.DarkZonePanel.UIDarkZoneModePanel.DarkZoneGlobal")
require("UI.Repository.UIRepositoryGlobal")
require("UI.DarkZonePanel.UIDarkZoneRepositoryPanel.UIDarkZoneRepositoryGlobal")
require("UI.DarkZonePanel.DarkZoneMachineryPanel.item.UIDarkzoneMachineryRepositoryTab")
UIDarkzoneMachineryRepositoryPanel = class("UIDarkzoneMachineryRepositoryPanel", UIBasePanel)
UIDarkzoneMachineryRepositoryPanel.__index = UIDarkzoneMachineryRepositoryPanel

function UIDarkzoneMachineryRepositoryPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
  csPanel.Is3DPanel = true
end

function UIDarkzoneMachineryRepositoryPanel:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self.itemList = {}
  self.tabList = {}
  self.detailUI = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListener()
  local uiBasePanel = UISystem:GetUIBasePanel(UIDef.UIDarkzonePanel)
  if uiBasePanel then
    local parentObj = uiBasePanel.GameObject
    if parentObj then
      setactive(parentObj, false)
    end
  end
  self.activeID = NetCmdActivityDarkZone:GetCurrActivityID(SubmoduleType.ActivityDarkzone, NetCmdActivitySimData.offcialConfigId)
  self.activityConfigId = NetCmdActivitySimData.offcialConfigId
  self.activitySubmodeleId = LuaUtils.EnumToInt(SubmoduleType.ActivityDarkzone)
  self.canSendNet = true
  if self.detailInfo == nil then
    self.detailInfo = instantiate(self.ui.mScrollListChild_GrpItemInfo.childItem, self.ui.mScrollListChild_GrpItemInfo.transform)
  end
  self:LuaUIBindTable(self.detailInfo, self.detailUI)
  self.ui.mAnimator_Info.keepAnimatorControllerStateOnDisable = true
  setactive(self.ui.mTrans_GrpInfo, false)
  self.temperatureList = {}
  self.selectIndexTable = {}
  self.contentItem = {}
  self.bagDataList = {}
  self.sliderMaxNum = 0
  self.selectFrameIndex = -1
  self.index = 0
  self.curTabIndex = 1
  self.BagMgr = CS.LuaPlayerDataHandler.DarkPlayerBag
  self.maxNum = CS.LuaPlayerDataHandler.Chequer:ToString()
  self.curClickTabId = -1
  self.isEmpty = true
  self.isDiscardMode = false
  setactive(self.ui.mBtn_BtnHome, false)
  self.ui.mText_Tip.text = TableData.GetActivityHint(271043, self.activityConfigId, 2, self.activitySubmodeleId, self.activeID)
  self.cacheIndex = 0
  
  function self.ui.mAnimator_RootKeyFrame.onAnimationEvent()
    if self.tabList[self.curTabIndex] then
      self.tabList[self.curTabIndex]:SwitchItemList(self.cacheIndex)
    end
    if self.tabList[self.cacheIndex] then
      self.tabList[self.cacheIndex]:SwitchItemList(self.cacheIndex)
    end
    self.curTabIndex = self.cacheIndex
    self:ResetInit()
    setactive(self.ui.mTrans_Goods, self.cacheIndex == DarkZoneGlobal.MachineryType.Carrier)
    setactive(self.ui.mTrans_OtherText, self.cacheIndex == DarkZoneGlobal.MachineryType.Other)
    setactive(self.ui.mBtn_Discard, self.cacheIndex == DarkZoneGlobal.MachineryType.Carrier and TableData.GlobalDarkzoneData.ChestLimitShow == 1)
    if self.cacheIndex == DarkZoneGlobal.MachineryType.Carrier then
      self.ui.mAnimation_Discard:Play("Ani_Com_CanvasGroup")
    end
    self.cacheIndex = 0
  end
  
  self:InitContent()
  self:ResetInit()
  self:SwitchRepositoryTab(1)
  self.isLastFrom = false
  self.showFog = false
end

function UIDarkzoneMachineryRepositoryPanel:AddBtnListener()
  UIUtils.GetButtonListener(self.ui.mBtn_BtnBack.gameObject).onClick = function()
    self.ui.mAnimator_Info:ResetTrigger("GrpItemInfo_FadeIn")
    self.ui.mAnimator_Info:SetTrigger("GrpItemInfo_FadeOut")
    UIManager.CloseUI(UIDef.UIDarkzoneMachineryRepositoryPanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Discard.gameObject).onClick = function()
    self:OnDiscardClick()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Cancel.gameObject).onClick = function()
    self:OnCancelClick()
  end
  setactive(self.ui.mBtn_white, true)
  UIUtils.GetButtonListener(self.ui.mBtn_white.gameObject).onClick = function()
    self:OnClickWhite()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_DiscardConfirm.gameObject).onClick = function()
    self:OnDiscardConfirmClick()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Attribute.gameObject).onClick = function()
    UIManager.OpenUIByParam(UIDef.UIDarkZoneMachineryAttributeDialog)
  end
end

function UIDarkzoneMachineryRepositoryPanel:OnDiscardClick()
  self.isDiscardMode = true
  setactive(self.ui.mTrans_Discard, true)
  setactive(self.ui.mTrans_TipRoot, false)
  if self.selectFrameIndex ~= -1 then
    local item = self.contentItem[self.selectFrameIndex]
    local itemIndex = item.bagIndex
    if self.bagDataList[self.selectFrameIndex].itemdata.type == 21 then
      local weaponPartsData = item.mWeaponPartsData
      self:OnClickUnstackItem(itemIndex, item, weaponPartsData.IsLocked)
    else
      self:OnClickStackItem(itemIndex, item)
    end
  end
  self:SetDetailShow()
  self.ui.mAnimator_Root:ResetTrigger("GrpRight_FadeIn")
  self.ui.mAnimator_Root:SetTrigger("GrpRight_FadeOut")
  self.ui.mBtn_Attribute.interactable = false
  self.ui.mImg_Attribute.blocksRaycasts = false
  setactive(self.ui.mBtn_Discard.transform.parent, false)
  for i = 1, #self.tabList do
    self.tabList[i]:OnDiscardClick(self.curTabIndex)
  end
end

function UIDarkzoneMachineryRepositoryPanel:OnDiscardConfirmClick()
  gfdebug("\231\161\174\232\174\164\228\184\162\229\188\131\228\186\134")
  if not self.canSendNet then
    return
  end
  self.canSendNet = false
  local gamePlayId = NetCmdActivityDarkZone:GetCurrGamePlayID(SubmoduleType.ActivityDarkzone, NetCmdActivitySimData.offcialConfigId)
  local gamePlayData = TableData.listDzActivityGameplayDatas:GetDataById(gamePlayId)
  if self.curTabIndex == 1 then
    local tempList = self:GetDiscardList()
    local chquer, point = self:GetCarrierTabScoreLua(tempList)
    if chquer < gamePlayData.lost_carrynum and self.curTabIndex == 1 then
      PopupMessageManager.PopupString(string_format(TableData.GetActivityHint(271036, self.activityConfigId, 2, self.activitySubmodeleId, self.activeID), gamePlayData.lost_carrynum))
      self.canSendNet = true
      return
    end
  end
  for i = 1, #self.selectIndexTable do
    self.BagMgr:PickDown(self.bagDataList[self.selectIndexTable[i].Index])
  end
  self.netTimer = TimerSys:DelayCall(5, function()
    self.canSendNet = true
    self.netTimer = nil
  end)
  self.BagMgr:SendPickDown(function(ret)
    self.canSendNet = true
    if self.netTimer then
      self.netTimer:Stop()
      self.netTimer = nil
    end
    if ret == ErrorCodeSuc then
      gfdebug("\228\184\162\229\188\131\230\136\144\229\138\159")
      MessageSys:SendMessage(CS.GF2.Message.DarkMsg.OnDarkPickDown, nil)
      for i = 1, #self.selectIndexTable do
        self.contentItem[self.selectIndexTable[i].Index].isDestoryFlag = true
      end
    else
      PopupMessageManager.PopupString(TableData.GetActivityHint(271037, self.activityConfigId, 2, self.activitySubmodeleId, self.activeID))
    end
    self.curClickTabId = -1
    self:ResetInit()
    setactive(self.ui.mTrans_Discard, false)
    self:UpdateCarrierInfo()
    self:UpdateCarrierEscortScore()
    if self.curTabIndex == 1 then
      self.tabList[self.curTabIndex].itemDataList = self.BagMgr:GetBagCarrierItem(0, 1)
    elseif self.curTabIndex == 2 then
      self.tabList[self.curTabIndex].itemDataList = self.BagMgr:GetBagCarrierItem(1, 2)
    end
    self.cacheIndex = self.curTabIndex
    self.ui.mAnimator_Root:SetTrigger("Tab_FadeIn")
    self.ui.mAnimator_Root:SetTrigger("GrpRight_FadeIn")
    self.ui.mBtn_Attribute.interactable = true
    self.ui.mImg_Attribute.blocksRaycasts = true
  end)
  self.isDiscardMode = false
end

function UIDarkzoneMachineryRepositoryPanel:GetDiscardList()
  local selectTable = {}
  local itemDataList = {}
  for i = 1, #self.selectIndexTable do
    local index = self.selectIndexTable[i].Index
    local itemData = self.bagDataList[index]
    local sTable = {
      itemID = itemData.itemID,
      num = itemData.num
    }
    table.insert(selectTable, sTable)
  end
  for i = 0, self.tabList[self.curTabIndex].itemDataList.Count - 1 do
    local itemData = self.tabList[self.curTabIndex].itemDataList[i]
    local sTable = {
      itemID = itemData.itemID,
      num = itemData.num
    }
    table.insert(itemDataList, sTable)
  end
  for i = #itemDataList, 1, -1 do
    local itemData = itemDataList[i]
    local flag = false
    for j = #selectTable, 1, -1 do
      if itemData.itemID == selectTable[j].itemID and itemData.num == selectTable[j].num then
        table.remove(selectTable, j)
        flag = true
        break
      end
    end
    if flag then
      table.remove(itemDataList, i)
    end
  end
  return itemDataList
end

function UIDarkzoneMachineryRepositoryPanel:OnCancelClick()
  setactive(self.ui.mTrans_Discard, false)
  self.curClickTabId = -1
  self:ResetInit()
  self.ui.mAnimator_Root:ResetTrigger("GrpRight_FadeOut")
  self.ui.mAnimator_Root:SetTrigger("GrpRight_FadeIn")
  self.ui.mBtn_Attribute.interactable = true
  self.ui.mImg_Attribute.blocksRaycasts = true
  self.isDiscardMode = false
end

function UIDarkzoneMachineryRepositoryPanel:InitContent()
  setactive(self.ui.mTrans_Discard, false)
  self:UpdateItemList()
  self:UpdateCarrierInfo()
end

function UIDarkzoneMachineryRepositoryPanel:UpdateItemList()
  self:InitItemTabList()
  for index, tag in ipairs(self.tabList) do
    self:UpdateDarkZoneItemList(index, tag)
  end
end

function UIDarkzoneMachineryRepositoryPanel:ResetInit()
  setactive(self.ui.mTrans_Empty.gameObject, self.isEmpty)
  setactive(self.ui.mBtn_Discard.transform.parent, not self.isEmpty)
  self.ui.mBtn_DiscardConfirm.interactable = #self.selectIndexTable > 0
  self.curClickTabId = -1
  self:SetDetailShow()
  if 0 <= self.selectFrameIndex then
    self.contentItem[self.selectFrameIndex]:SetSelectShow(false)
  end
  self.selectFrameIndex = -1
  for i = 1, #self.tabList do
    self.tabList[i]:OnDiscardClick(self.tabList[i].index)
  end
  for i = 1, #self.selectIndexTable do
    local index = self.selectIndexTable[i].Index
    local item = self.contentItem[index]
    local itemIndex = item.bagIndex
    item:SetSelect(false)
    item:SetSelectShow(false)
  end
  self.selectIndexTable = {}
end

function UIDarkzoneMachineryRepositoryPanel:InitItemTabList()
  local parentRoot = self.ui.mScrollListChild_GrpTabBtn.transform
  local typeList = {
    [1] = {
      title = TableData.GetActivityHint(271041, self.activityConfigId, 2, self.activitySubmodeleId, self.activeID)
    },
    [2] = {
      title = TableData.GetActivityHint(271042, self.activityConfigId, 2, self.activitySubmodeleId, self.activeID)
    }
  }
  for i = 1, #typeList do
    local item = self.tabList[i]
    if item == nil then
      item = UIDarkzoneMachineryRepositoryTab.New()
      table.insert(self.tabList, item)
      item:InitCtrl(self.ui.mScrollListChild_GrpTabBtn.childItem, parentRoot)
    end
    item:SetData(typeList[i], function()
      self:SwitchRepositoryTab(i)
    end, i)
  end
end

function UIDarkzoneMachineryRepositoryPanel:UpdateDarkZoneItemList(indexItem, tag)
  local index = self.index
  local tagEmpty = true
  if tag.mData then
    for i = 1, #tag.itemList do
      setactive(tag.itemList[i]:GetRoot(), false)
    end
    local ItemType = tag.mData.item_type
    local itemDataList = self.BagMgr:GetBagCarrierItem(index, indexItem)
    if indexItem == 1 then
      self:UpdateCarrierTabScore(itemDataList)
    end
    tag.itemDataList = itemDataList
    for i = 0, itemDataList.Count - 1 do
      self.isEmpty = false
      tagEmpty = false
      local itemData = itemDataList[i]
      if 0 < itemData.num then
        local itemTableData = TableData.listItemDatas:GetDataById(itemData.itemID)
        local timeLimit = itemTableData.time_limit
        if timeLimit == 0 or timeLimit ~= 0 and timeLimit > CGameTime:GetTimestamp() then
          local item
          if i + 1 > #tag.itemList then
            item = UICommonItem.New()
            item:InitCtrl(self.ui.mScrollListChild_Content.transform)
            table.insert(tag.itemList, item)
          else
            item = tag.itemList[i + 1]
          end
          index = self.index
          self.contentItem[index] = item
          self.bagDataList[index] = itemData
          if itemData.itemdata.Type == 21 then
            item:SetWeaponPartsData(itemData.gunweaponModData, function(tempItem)
              self:OnClickWeaponPartItem(tempItem)
            end)
          elseif indexItem == 1 then
            local escort_goodData = TableData.listActivityEscortExchangeDatas:GetDataById(itemData.itemID, true)
            local fakeItemData = CS.UICommonItem.GetFakeItemData(escort_goodData, itemData.num)
            item:SetFakeItem(fakeItemData, function(tempItem)
              self:ShowCommonItem(tempItem)
            end)
            item:SetEscortScore(string_format(TableData.GetHintById(271313), escort_goodData.reward_point))
          else
            item:SetItemData(itemData.itemID, itemData.num, false, false, itemData.num, nil, nil, function(tempItem)
              self:ShowCommonItem(tempItem)
            end, nil, true)
          end
          item.isDestoryFlag = false
          item:SetActive(self.curTabIndex == indexItem)
          item:SetBagIndex(index)
          self.index = self.index + 1
        end
      end
    end
  end
end

function UIDarkzoneMachineryRepositoryPanel:SwitchRepositoryTab(index)
  self.ui.mCanvasGroup_Content.alpha = 0
  self.ui.mCanvasGroup_Scrollbar.alpha = 0
  self.ui.mCanvasGroup_GrpDes.alpha = 0
  self.ui.mCanvasGroup_TextEmpty.alpha = 0
  self.cacheIndex = index
  self.ui.mAnimator_Root:SetTrigger("Tab_FadeIn")
end

function UIDarkzoneMachineryRepositoryPanel:ShowCommonItem(item)
  if self.selectFrameIndex >= 0 then
    self.contentItem[self.selectFrameIndex]:SetSelectShow(false)
  end
  local index = item.bagIndex
  self.selectFrameIndex = index
  self:InitSlider(item.itemNum)
  self:OnClickStackItem(index, item)
  local itemTabData
  local escort_goodData = TableData.listActivityEscortExchangeDatas:GetDataById(item.itemId, true)
  if escort_goodData then
    itemTabData = CS.UICommonItem.GetFakeItemData(escort_goodData, item.itemNum)
    if itemTabData ~= nil then
      self.curDecomposeId = itemTabData.itemData.Id
      self.detailUI.mText_Title.text = itemTabData.itemData.name.str
      self.detailUI.mImg_QualityLine.color = TableData.GetGlobalGun_Quality_Color2(itemTabData.itemData.rank)
      self.detailUI.mTxt_DetailInfo.text = itemTabData.itemData.introduction.str
      self.detailUI.mTxt_ItemName.text = TableData.listItemTypeDescDatas:GetDataById(itemTabData.itemData.type).name.str
    end
  else
    itemTabData = TableData.GetItemData(item.itemId)
    if itemTabData ~= nil then
      self.curDecomposeId = item.itemId
      self.detailUI.mText_Title.text = itemTabData.name.str
      self.detailUI.mImg_QualityLine.color = TableData.GetGlobalGun_Quality_Color2(itemTabData.rank)
      self.detailUI.mTxt_DetailInfo.text = itemTabData.introduction.str
      self.detailUI.mTxt_ItemName.text = TableData.listItemTypeDescDatas:GetDataById(itemTabData.type).name.str
    end
  end
  setactive(self.detailUI.mTrans_TopInfo, itemTabData ~= nil)
  self.curClickTabId = UIRepositoryGlobal.PanelType.ItemPanel
  self:SetDetailShow()
end

function UIDarkzoneMachineryRepositoryPanel:OnClickWeaponPartItem(item)
  if self.selectFrameIndex >= 0 then
    self.contentItem[self.selectFrameIndex]:SetSelectShow(false)
  end
  local index = item.bagIndex
  local weaponPartsData = item.mWeaponPartsData
  self:OnClickUnstackItem(index, item, weaponPartsData.IsLocked)
  self.selectFrameIndex = index
  self.detailUI.mText_Title.text = weaponPartsData.name
  self.detailUI.mTxt_DetailInfo.text = ""
  self.detailUI.mImg_QualityLine.color = TableData.GetGlobalGun_Quality_Color2(weaponPartsData.rank)
  self.curDecomposeId = weaponPartsData.stcId
  self.curWeaponPartDecomposeId = weaponPartsData.id
  setactive(self.detailUI.mTrans_Capacity, false)
  self.detailUI.mText_Capacity.text = tostring(weaponPartsData.Capacity)
  setactive(self.detailUI.mImg_PartType, true)
  self.detailUI.mImg_PartType.sprite = IconUtils.GetWeaponPartIconSprite(weaponPartsData.ModEffectTypeData.Icon, false)
  setactive(self.detailUI.mText_Flaw, true)
  self.detailUI.mText_Flaw.text = ""
  setactive(self.detailUI.mScrollListChild_BtnLock, true)
  local color = ColorUtils.OrangeColor
  local atrributeListColor
  setactive(self.detailUI.mScrollChild_Attribute, true)
  atrributeListColor = CS.GunWeaponModData.SetWeaponPartAttr(weaponPartsData, self.detailUI.mScrollChild_Attribute.transform, self.detailUI.mTrans_MainAttribute.transform, 0)
  local flag = false
  if weaponPartsData.ModEffectTypeData.EffectId == UIWeaponGlobal.ModEffectType.Cover then
    CS.GunWeaponModData.SetModPowerDataNameWithGroupNum(self.detailUI.mText_MakeUpName, self.detailUI.mText_MakeUpLv, weaponPartsData.ModPowerData, weaponPartsData)
    self.detailUI.mImg_MakeUp.sprite = IconUtils.GetWeaponPartIconSprite(weaponPartsData.ModPowerData.image, false)
    if 0 < weaponPartsData.BasicValue.Length + weaponPartsData.GunWeaponModPropertyListWithAddValue.Count or weaponPartsData.GroupSkillData ~= nil then
      setactive(self.detailUI.mTrans_MakeUp, true)
      setactive(self.detailUI.mTrans_Special, true)
      flag = true
    else
      setactive(self.detailUI.mTrans_MakeUp, false)
    end
    if weaponPartsData and self.detailUI.mTrans_MakeUpItem then
      self.detailUI.mTrans_MakeUpItem:GetComponent(typeof(CS.TextFit)).text = weaponPartsData:GetModGroupSkillShowText()
    end
  end
  local preficAttList = CS.GunWeaponModData.SetWeaponPartProficiencySkill(weaponPartsData, self.detailUI.mTrans_GrpPolarity.transform)
  self:SetModLevel(weaponPartsData)
  if weaponPartsData.ModEffectTypeData.EffectId == UIWeaponGlobal.ModEffectType.Ambush or weaponPartsData.ModEffectTypeData.EffectId == UIWeaponGlobal.ModEffectType.Armor then
    if weaponPartsData.ExtraCapacity ~= 0 or 0 < weaponPartsData.GunWeaponModPropertyListWithAddValue.Count then
      setactive(self.detailUI.mTrans_GrpPolarity, true)
      flag = true
    else
      setactive(self.detailUI.mTrans_GrpPolarity, false)
    end
  end
  setactive(self.detailUI.mTrans_Special, flag)
  setactive(self.detailUI.mTrans_MakeUp, weaponPartsData.GroupSkillData ~= nil)
  local slotData = TableData.listWeaponModTypeDatas:GetDataById(weaponPartsData.fatherType)
  if slotData ~= nil then
    self.detailUI.mTxt_ItemName.text = slotData.name.str
  end
  setactive(self.detailUI.mTrans_TopInfo, slotData ~= nil)
  self.curClickTabId = UIRepositoryGlobal.PanelType.WeaponParts
  UIDarkzoneMachineryRepositoryPanel:SetDetailShow()
end

function UIDarkzoneMachineryRepositoryPanel:SetModLevel(tmpGunWeaponModData)
  setactive(self.detailUI.mTrans_PolarityIcon, tmpGunWeaponModData.stcDataCanPolarity)
  CS.GunWeaponModData.SetModLevelText(self.detailUI.mText_Lv, tmpGunWeaponModData, self.detailUI.mText_LvMax)
  CS.GunWeaponModData.SetModPolarityText(self.detailUI.mText_State, self.detailUI.mImg_Polarity, tmpGunWeaponModData, self.detailUI.mCanvasGroup_Lv)
end

function UIDarkzoneMachineryRepositoryPanel:InitSlider(max)
  max = math.min(max, 999)
  self.sliderMaxNum = max
end

function UIDarkzoneMachineryRepositoryPanel:OnClickStackItem(index, item)
  local isSelected = true
  if self.isDiscardMode then
    for i = 1, #self.selectIndexTable do
      if self.selectIndexTable[i].Index == index then
        isSelected = false
        self:OnSliderChange(0)
        item:SetSelect(false)
        break
      end
    end
    if isSelected then
      self:OnSliderChange(self.sliderMaxNum)
      item:SetSelect(true)
    end
  end
  item:SetSelectShow(true)
end

function UIDarkzoneMachineryRepositoryPanel:OnClickUnstackItem(index, item, isLocked)
  local isSelected = true
  if self.isDiscardMode then
    for i = 1, #self.selectIndexTable do
      if self.selectIndexTable[i].Index == index then
        table.remove(self.selectIndexTable, i)
        isSelected = false
        item:SetSelect(false)
        break
      end
    end
    if isSelected and not isLocked then
      if #self.selectIndexTable >= CS.LuaPlayerDataHandler.Chequer then
        UIUtils.PopupHintMessage(1106)
        isSelected = false
        item:SetSelect(false)
      else
        table.insert(self.selectIndexTable, {Index = index, Count = 1})
        item:SetSelect(true)
      end
    end
  end
  item:SetSelectShow(true)
end

function UIDarkzoneMachineryRepositoryPanel:OnSliderChange(value)
  self.curDecomposeNum = value
  if value == 0 then
    for i = 1, #self.selectIndexTable do
      if self.selectIndexTable[i].Index == self.selectFrameIndex then
        table.remove(self.selectIndexTable, i)
        break
      end
    end
  else
    local isSelected = false
    for i = 1, #self.selectIndexTable do
      if self.selectIndexTable[i].Index == self.selectFrameIndex then
        self.selectIndexTable[i].Count = value
        isSelected = true
        break
      end
    end
    if not isSelected then
      table.insert(self.selectIndexTable, {
        Index = self.selectFrameIndex,
        Count = value
      })
    end
  end
end

function UIDarkzoneMachineryRepositoryPanel:OnShowFinish()
  if not self.isLastFrom then
    self.showFog = CS.FogOfWarRenderer.FOWRenderer.Instance.sceneFogOfWarEnabled
    CS.FogOfWarRenderer.FOWRenderer.Instance.sceneFogOfWarEnabled = false
  end
  self.isLastFrom = true
end

function UIDarkzoneMachineryRepositoryPanel:SetDetailShow()
  setactive(self.detailUI.mTrans_GrpWeaponPart, self.curClickTabId == UIRepositoryGlobal.PanelType.WeaponParts)
  setactive(self.detailUI.mTrans_GrpInfo, self.curClickTabId == UIRepositoryGlobal.PanelType.ItemPanel)
  self:UpdateRightAnimation()
  setactive(self.detailUI.mTrans_TexpEmpty, self.curClickTabId == -1)
  setactive(self.detailUI.mTrans_TopInfo, self.curClickTabId ~= -1)
  setactive(self.detailUI.mText_Flaw, self.curClickTabId == UIRepositoryGlobal.PanelType.WeaponParts)
  setactive(self.detailUI.mTrans_Capacity, false)
  setactive(self.ui.mBtn_Discard.transform.parent, not self.isEmpty)
  self.ui.mBtn_DiscardConfirm.interactable = #self.selectIndexTable > 0
end

function UIDarkzoneMachineryRepositoryPanel:UpdateCarrierInfo()
  local nowTemp = DarkHelper.GetCarTemp()
  local maxTemp = DarkHelper.GetCarMaxTemp()
  local temperature = nowTemp / maxTemp
  self.curCarLevel = NetCmdActivityDarkZone.mCarLevel
  self.levelFormatStr = TableData.GetHintById(901061)
  local nowHp = DarkHelper.GetCarHp()
  local maxHp = DarkHelper.GetCarMaxHp()
  self.ui.mText_Name.text = TableData.GetActivityHint(271040, self.activityConfigId, 2, self.activitySubmodeleId, self.activeID)
  self.ui.mText_Lv.text = string_format(self.levelFormatStr, self.curCarLevel)
  self.ui.mText_HPNum.text = string_format(TableData.GetHintById(271301), nowHp, maxHp)
  setactive(self.ui.mTrans_GrpOverLoad.gameObject, false)
  for i = 1, 4 do
    local item = self.temperatureList[i]
    if item == nil then
      item = instantiate(self.ui.mTrans_GrpOverLoad.gameObject, self.ui.mTrans_loadBar)
      table.insert(self.temperatureList, item)
    end
    local itemUI = {}
    self:LuaUIBindTable(item, itemUI)
    setactive(item, true)
    setactive(itemUI.mImg_Overload, true)
    local index = 5 - i
    if temperature >= index / 4 then
      if 0.75 < temperature then
        itemUI.mImg_Overload.color = ColorUtils.YellowColor
      else
        itemUI.mImg_Overload.color = ColorUtils.YellowColor
      end
    elseif 0 < temperature and index == 1 then
      itemUI.mImg_Overload.color = ColorUtils.YellowColor
    else
      setactive(itemUI.mImg_Overload, false)
      itemUI.mImg_Overload.color = ColorUtils.GrayColor
    end
    if DarkHelper.CarIsOverLoad() then
      setactive(item, true)
      setactive(itemUI.mImg_Overload, true)
      itemUI.mImg_Overload.color = ColorUtils.RedColor
    end
  end
end

function UIDarkzoneMachineryRepositoryPanel:UpdateCarrierEscortScore()
  local itemDataList = self.BagMgr:GetBagCarrierItem(1, 1)
  self:UpdateCarrierTabScore(itemDataList)
end

function UIDarkzoneMachineryRepositoryPanel:UpdateCarrierTabScore(itemDataList)
  local chequer, point = self:GetCarrierTabScore(itemDataList)
  local gamePlayId = NetCmdActivityDarkZone:GetCurrGamePlayID(SubmoduleType.ActivityDarkzone, NetCmdActivitySimData.offcialConfigId)
  local gamePlayData = TableData.listDzActivityGameplayDatas:GetDataById(gamePlayId)
  if gamePlayData == nil then
    gferror("\230\142\168\232\189\166\230\180\187\229\138\168\230\156\170\229\188\128\229\144\175\239\188\140\229\188\186\232\161\140\232\191\155\229\133\165\228\188\154\230\138\165\230\173\164\233\148\153\232\175\175")
    return
  end
  if chequer <= gamePlayData.warning_carrynum and self.curTabIndex == 1 then
    setactive(self.ui.mTrans_TipRoot, true)
  else
    setactive(self.ui.mTrans_TipRoot, false)
  end
  self.ui.mText_LeftNum.text = tostring(chequer) .. "/" .. self.maxNum
  self.ui.mText_RightNum.text = tostring(point)
end

function UIDarkzoneMachineryRepositoryPanel:GetCarrierTabScore(itemDataList)
  local chequer = 0
  local point = 0
  for i = 0, itemDataList.Count - 1 do
    local escoreData = TableData.listActivityEscortExchangeDatas:GetDataById(itemDataList[i].itemID, true)
    chequer = chequer + escoreData.reward_bagnum * itemDataList[i].num
    point = point + escoreData.reward_point * itemDataList[i].num
  end
  local questData = TableData.listDzActivityQuestDatas:GetDataById(CS.SysMgr.dzMatchGameMgr.questId)
  if questData then
    if point >= questData.max_point then
      point = questData.max_point
    end
  else
    gferror("\228\187\187\229\138\161\230\149\176\230\141\174\232\142\183\229\143\150\228\184\186\231\169\186\239\188\140\228\189\134\230\152\175\231\130\185\229\188\128\228\186\134\232\131\140\229\140\133")
  end
  return chequer, point
end

function UIDarkzoneMachineryRepositoryPanel:GetCarrierTabScoreLua(itemDataList)
  local chequer = 0
  local point = 0
  for i = 1, #itemDataList do
    local escoreData = TableData.listActivityEscortExchangeDatas:GetDataById(itemDataList[i].itemID, true)
    chequer = chequer + escoreData.reward_bagnum * itemDataList[i].num
    point = point + escoreData.reward_point * itemDataList[i].num
  end
  local questData = TableData.listDzActivityQuestDatas:GetDataById(CS.SysMgr.dzMatchGameMgr.questId)
  if questData then
    if point >= questData.max_point then
      point = questData.max_point
    end
  else
    gferror("\228\187\187\229\138\161\230\149\176\230\141\174\232\142\183\229\143\150\228\184\186\231\169\186\239\188\140\228\189\134\230\152\175\231\130\185\229\188\128\228\186\134\232\131\140\229\140\133")
  end
  return chequer, point
end

function UIDarkzoneMachineryRepositoryPanel:UpdateRightAnimation()
  if self.curClickTabId ~= -1 then
    if not self.ui.mTrans_GrpInfo.gameObject.activeInHierarchy then
      setactive(self.ui.mTrans_GrpInfo, true)
    end
    self.ui.mAnimator_Info:ResetTrigger("GrpItemInfo_FadeOut")
    self.ui.mAnimator_Info:SetTrigger("GrpItemInfo_FadeIn")
    self.ui.mAnimator_Root:ResetTrigger("GrpRight_FadeIn")
    self.ui.mAnimator_Root:SetTrigger("GrpRight_FadeOut")
  elseif self.curClickTabId == -1 then
    self.ui.mAnimator_Info:ResetTrigger("GrpItemInfo_FadeIn")
    self.ui.mAnimator_Info:SetTrigger("GrpItemInfo_FadeOut")
    self.ui.mAnimator_Root:ResetTrigger("GrpRight_FadeOut")
    self.ui.mAnimator_Root:SetTrigger("GrpRight_FadeIn")
  end
end

function UIDarkzoneMachineryRepositoryPanel:OnHideFinish()
end

function UIDarkzoneMachineryRepositoryPanel:OnClose()
  if self.netTimer then
    self.netTimer:Stop()
    self.netTimer = nil
  end
  CS.FogOfWarRenderer.FOWRenderer.Instance.sceneFogOfWarEnabled = self.showFog
  self.selectIndex = -1
  self.selectIndexTable = {}
  self.selectFrameIndex = -1
  self.contentItem = {}
  setactive(self.detailUI.mTrans_Capacity, false)
  setactive(self.detailUI.mImg_PartType, false)
  setactive(self.detailUI.mText_Flaw, false)
  setactive(self.detailUI.mScrollChild_Attribute, false)
  setactive(self.detailUI.mTrans_Special, false)
  setactive(self.detailUI.mTrans_MakeUp, false)
  setactive(self.detailUI.mTrans_GrpPolarity, false)
  setactive(self.detailUI.mTrans_TopInfo, false)
  gfdestroy(self.detailInfo.gameObject)
  self.detailInfo = nil
  if self.tabList then
    for i = 1, #self.tabList do
      self.tabList[i]:OnRelease()
    end
  end
  if self.temperatureList then
    for i = 1, #self.temperatureList do
      gfdestroy(self.temperatureList[i])
    end
  end
  local uiBasePanel = UISystem:GetUIBasePanel(UIDef.UIDarkzonePanel)
  if uiBasePanel then
    local parentObj = uiBasePanel.GameObject
    if parentObj then
      setactive(parentObj, true)
    end
  end
end

function UIDarkzoneMachineryRepositoryPanel:OnClickWhite()
  if self.selectFrameIndex >= 0 then
    self.contentItem[self.selectFrameIndex]:SetSelectShow(false)
  end
  self:OnCancelClick()
end

function UIDarkzoneMachineryRepositoryPanel:OnBackFrom()
  self.isLastFrom = true
end

function UIDarkzoneMachineryRepositoryPanel:OnTop()
  self.isLastFrom = true
end

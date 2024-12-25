require("UI.Common.UICommonSimpleView")
require("UI.UIBasePanel")
require("UI.Repository.Item.UIRepositoryUnitePartWeaponTypeItem")
require("UI.Repository.Item.UIRepositoryUnitePartModPowerItem")
require("UI.SimCombatPanel.WeaponModWish.Item.UISimCombatWeaponModWishDescItem")
require("UI.Repository.Item.RepositoryUnitePartTypeGlobal")
UIRepositoryUnitePartBoxDialog = class("UIRepositoryUnitePartBoxDialog", UIBasePanel)
UIRepositoryUnitePartBoxDialog.__index = UIRepositoryUnitePartBoxDialog
local WishStateType = {selectItem = 1, selectRaidTime = 2}

function UIRepositoryUnitePartBoxDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function UIRepositoryUnitePartBoxDialog:OnAwake(root, data)
  self.btnText1 = TableData.GetHintById(310096)
  self.btnText2 = TableData.GetHintById(310097)
end

function UIRepositoryUnitePartBoxDialog:OnInit(root, data)
  self:SetRoot(root)
  self:InitBaseData()
  self.mview:InitCtrl(root, self.ui)
  self:AddBtnListen()
  self.mData = data
  self.weaponPackageData = TableData.listWeaponModPackageDatas:GetDataById(data.id)
  self.packageType = self.weaponPackageData.type
  self:SwitchDialogType()
  self:InitRaid()
  
  function self.ui.mLoopGridView_ItemList.itemCreated(renderData)
    self:ItemProvider(renderData)
  end
  
  function self.ui.mLoopGridView_ItemList.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
  
  function self.ui.mLoopGridView_PartSkillList.itemCreated(renderData)
    self:PartItemProvider(renderData)
  end
  
  function self.ui.mLoopGridView_PartSkillList.itemRenderer(index, renderData)
    self:PartItemRenderer(index, renderData)
  end
  
  self.ui.mLoopGridView_PartSkillList.numItems = self.partDataList.Count
  local dataCount = #self.weaponTypeDataList
  self.ui.mLoopGridView_ItemList.numItems = dataCount
  setactive(self.ui.mTrans_DescriptionList, false)
  setactive(self.ui.mTrans_DescTextEmpty, true)
end

function UIRepositoryUnitePartBoxDialog:SwitchDialogType()
  if self.packageType == RepositoryUnitePartTypeGlobal.PackageType.All then
    self.partDataList = self.weaponPackageData.skill_type
    local d = self.weaponPackageData.weapon_type
    for i, v in pairs(d) do
      table.insert(self.weaponTypeDataList, i)
    end
  elseif self.packageType == RepositoryUnitePartTypeGlobal.PackageType.OnlyWeapon then
    self.partDataList = LuaUtils.GetListInt()
    local modDatas = TableData.listModPowerEffectDatas:GetList()
    for i = 0, modDatas.Count - 1 do
      local modSuitData = TableData.listModPowerDatas:GetDataById(modDatas[i].Id)
      if modSuitData then
        self.partDataList:Add(modSuitData.id)
      end
    end
    local d = self.weaponPackageData.weapon_type
    for i, v in pairs(d) do
      table.insert(self.weaponTypeDataList, i)
    end
    self.curSelectModPowerItem = 0
  elseif self.packageType == RepositoryUnitePartTypeGlobal.PackageType.OnlySkill then
    self.partDataList = self.weaponPackageData.skill_type
    local weaponDatas = TableData.listGunWeaponTypeDatas:GetList()
    for i = 0, weaponDatas.Count - 1 do
      table.insert(self.weaponTypeDataList, weaponDatas[i].type_id)
    end
    self.curSelectItem = 0
  end
  table.sort(self.weaponTypeDataList)
end

function UIRepositoryUnitePartBoxDialog:OnShowStart()
  self.ui.mLoopGridView_ItemList:Refresh()
  self.ui.mLoopGridView_PartSkillList:Refresh()
  setactive(self.ui.mLoopGridView_PartSkillList, self.partDataList.Count > 0)
  setactive(self.ui.mTrans_PartSkillTextEmpty, self.partDataList.Count == 0)
  self:ChangeWishState(WishStateType.selectItem)
end

function UIRepositoryUnitePartBoxDialog:OnShowFinish()
  self.currentCostItemCount = NetCmdItemData:GetNetItemCount(self.mData.id)
end

function UIRepositoryUnitePartBoxDialog:OnTop()
  self:RefreshTabItem()
end

function UIRepositoryUnitePartBoxDialog:OnBackForm()
  self:RefreshTabItem()
end

function UIRepositoryUnitePartBoxDialog:CloseFunction()
  UIManager.CloseUI(UIDef.UIRepositoryUnitePartBoxDialog)
end

function UIRepositoryUnitePartBoxDialog:OnClose()
  for i, v in ipairs(self.iconList) do
    gfdestroy(v.obj)
  end
  self.iconList = nil
  self.ui.mSlider.onValueChanged:RemoveListener(self.onSliderValueChangedCallback)
  self.ui.mLoopGridView_ItemList.numItems = 0
  self.ui.mLoopGridView_PartSkillList.numItems = 0
  self.onSliderValueChangedCallback = nil
  self:ReleaseCtrlTable(self.descItemList, true)
  self.descItemList = nil
  self.ui = nil
  self.mview = nil
  self.originalColor = nil
  self.simCombatData = nil
  self.simEntranceData = nil
  self.curSelectItem = nil
  self.curSelectModPowerItem = nil
  self.selectSuitID = nil
  self.selectSuitName = nil
  self.selectSuitIDList = nil
  self.curSelectItemIndex = nil
  self.curSelectModPowerItemIndex = nil
  self.isFirstIn = nil
  self.super.OnClose(self)
end

function UIRepositoryUnitePartBoxDialog:OnRelease()
  self.btnText1 = nil
  self.btnText2 = nil
  self.super.OnRelease(self)
end

function UIRepositoryUnitePartBoxDialog:InitBaseData()
  self.mview = UICommonSimpleView.New()
  self.ui = {}
  self.iconList = {}
  self.curSelectItem = nil
  self.curSelectItemIndex = 0
  self.isFirstIn = true
  self.descItemList = {}
  self.curModPowerName = nil
  self.selectSuitName = nil
  self.weaponTypeDataList = {}
end

function UIRepositoryUnitePartBoxDialog:AddBtnListen()
  local f = function()
    self:CloseFunction()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = f
  UIUtils.GetButtonListener(self.ui.mBtn_BGClose.gameObject).onClick = f
  UIUtils.GetButtonListener(self.ui.mBtn_Cancel.gameObject).onClick = f
  UIUtils.GetButtonListener(self.ui.mBtn_Confirm.gameObject).onClick = function()
    self:StartRaid()
  end
  UIUtils.AddBtnClickListener(self.ui.mBtn_Reduce.gameObject, function()
    self:onClickReduce()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Increase.gameObject, function()
    self:onClickIncrease()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Back.gameObject, function()
    self:ChangeWishState(WishStateType.selectItem)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Goto.gameObject, function()
    self:OnClickGotoBtn()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_MinBtn.gameObject, function()
    local num = self.minValue - self.curRaidTimes
    self:changeRaidTimes(num)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_MaxBtn.gameObject, function()
    local num = self.maxValue - self.curRaidTimes
    self:changeRaidTimes(num)
  end)
end

function UIRepositoryUnitePartBoxDialog:InitScroll()
  self.allList = self.weaponPackageData
end

function UIRepositoryUnitePartBoxDialog:InitRaid()
  local itemCount = NetCmdItemData:GetNetItemCount(self.mData.id)
  self.maxValue = math.min(itemCount, self.weaponPackageData.open_count)
  self.minValue = self.maxValue >= 1 and 1 or 0
  self.ui.mBtn_Confirm.interactable = true
  self.ui.mSlider.minValue = self.minValue
  self.ui.mSlider.maxValue = self.maxValue
  self.ui.mSlider.value = self.minValue
  self.ui.mText_MinNum.text = tostring(self.minValue)
  self.ui.mText_MaxNum.text = tostring(self.maxValue)
  self.curRaidTimes = self.minValue
  self.currentCostItemCount = 1
  self.itemList = {}
  
  function self.onSliderValueChangedCallback(num)
    self:onSliderValueChanged(num)
  end
  
  self.ui.mSlider.onValueChanged:AddListener(self.onSliderValueChangedCallback)
  self:changeRaidTimes(0)
  self.ui.mText_Title.text = self.mData.name.str
end

function UIRepositoryUnitePartBoxDialog:refreshCostIcon()
  local valid = self.mData.costItemId > 0 and 0 < self.mData.costItemNum
  setactive(self.ui.mImg_Icon.transform.parent, valid)
  if valid then
    self.ui.mImg_Icon.sprite = IconUtils.GetItemIconSprite(self.mData.costItemId)
  end
end

function UIRepositoryUnitePartBoxDialog:RefreshTabItem()
end

function UIRepositoryUnitePartBoxDialog:StartRaid()
  local list = TableData.listItemByTypeDatas:GetDataById(GlobalConfig.ItemType.WeaponPart)
  if list then
    local firstID = list.Id[0]
    if TipsManager.CheckItemIsOverflowAndStop(firstID, self.curRaidTimes) then
      return
    end
  end
  self.ui.mBtn_Confirm.interactable = false
  NetCmdItemData:SendUseCustomizedGift(self.mData.id, self.curSelectItem, self.curSelectModPowerItem, self.curRaidTimes, function()
    self:CloseFunction()
    UISystem:OpenCommonReceivePanel()
  end)
end

function UIRepositoryUnitePartBoxDialog:onClickIncrease()
  self:changeRaidTimes(1)
end

function UIRepositoryUnitePartBoxDialog:onClickReduce()
  self:changeRaidTimes(-1)
end

function UIRepositoryUnitePartBoxDialog:refreshCurValueText()
  self.ui.mText_CompoundNum.text = self.curRaidTimes
end

function UIRepositoryUnitePartBoxDialog:refreshSliderValue()
  self.ui.mSlider.value = self.curRaidTimes
end

function UIRepositoryUnitePartBoxDialog:refreshSliderBtn()
  self.ui.mBtn_Reduce.interactable = self.curRaidTimes ~= self.minValue
  self.ui.mBtn_MinBtn.interactable = self.curRaidTimes ~= self.minValue
  self.ui.mBtn_Increase.interactable = self.curRaidTimes ~= self.maxValue
  self.ui.mBtn_MaxBtn.interactable = self.curRaidTimes ~= self.maxValue
end

function UIRepositoryUnitePartBoxDialog:refreshCostText()
  self.ui.mText_CostNum.text = self.mData.costItemNum * self.curRaidTimes
  if self.currentCostItemCount >= self.mData.costItemNum * self.curRaidTimes then
    self.ui.mText_CostNum.color = self.originalColor
  else
    self.ui.mText_CostNum.color = ColorUtils.RedColor
  end
end

function UIRepositoryUnitePartBoxDialog:RefreshRewardList()
  self.itemDataTable = {}
  for _, v in ipairs(self.mData.rewardItemList) do
    local itemID = v.id
    local itemNum = v.num
    local rewardNum = itemNum * self.curRaidTimes
    if self.itemDataTable[itemID] == nil then
      self.itemDataTable[itemID] = 0
    end
    self.itemDataTable[itemID] = self.itemDataTable[itemID] + rewardNum
  end
end

function UIRepositoryUnitePartBoxDialog:onSliderValueChanged()
  local delta = math.ceil(self.ui.mSlider.value) - self.curRaidTimes
  self:changeRaidTimes(delta)
end

function UIRepositoryUnitePartBoxDialog:changeRaidTimes(delta)
  local targetValue = self.curRaidTimes + delta
  if targetValue > self.maxValue then
    targetValue = self.maxValue
  elseif targetValue < self.minValue then
    targetValue = self.minValue
  end
  self.curRaidTimes = targetValue
  self:onRiadTimesChanged()
end

function UIRepositoryUnitePartBoxDialog:onRiadTimesChanged()
  self:refreshCurValueText()
  self:refreshSliderValue()
  self:refreshSliderBtn()
end

function UIRepositoryUnitePartBoxDialog:checkNormalDropIsOverflow()
  for itemId, num in pairs(self.itemDataTable) do
    if TipsManager.CheckItemIsOverflow(itemId, num, true) then
      return true
    end
  end
  return false
end

function UIRepositoryUnitePartBoxDialog:OnClickGotoBtn()
  if self.curSelectItem == nil then
    CS.PopupMessageManager.PopupString(self.btnText1)
  elseif self.curSelectModPowerItem == nil then
    CS.PopupMessageManager.PopupString(self.btnText2)
  else
    self:ChangeWishState(WishStateType.selectRaidTime)
  end
end

function UIRepositoryUnitePartBoxDialog:ChangeWishState(state)
  setactive(self.ui.mTrans_Info, state == WishStateType.selectItem)
  setactive(self.ui.mTrans_Consume, state == WishStateType.selectRaidTime)
  setactive(self.ui.mBtn_Back.transform.parent, state == WishStateType.selectRaidTime)
  setactive(self.ui.mBtn_Goto.transform.parent, state == WishStateType.selectItem)
  setactive(self.ui.mBtn_Cancel.transform.parent, state == WishStateType.selectItem)
  setactive(self.ui.mBtn_Confirm.transform.parent, state == WishStateType.selectRaidTime)
  local switchNum = state == WishStateType.selectItem and 0 or 1
  self.ui.mAnimator_Title:SetInteger("Switch", switchNum)
  if state == WishStateType.selectRaidTime then
    self:RefreshTitleIcon()
  end
  if state == WishStateType.selectItem then
    self.ui.mAnimation_Info:Play()
    self.ui.mLoopGridView_ItemList:SetLayoutDoneDirty()
    self.ui.mLoopGridView_PartSkillList:SetLayoutDoneDirty()
  end
end

function UIRepositoryUnitePartBoxDialog:RefreshTitleIcon()
  for i, v in ipairs(self.iconList) do
    setactive(v.obj, false)
  end
  if self.curSelectItem == nil or self.curSelectModPowerItem == nil then
    return
  end
  if self.selectSuitName == nil then
    self.ui.mText_SelectSuitName.text = self.curModPowerName
    self:UpadeteIcon()
  elseif self.curModPowerName == nil then
    self.ui.mText_SelectSuitName.text = self.selectSuitName
  else
    self.ui.mText_SelectSuitName.text = self.selectSuitName .. "/" .. self.curModPowerName
    self:UpadeteIcon()
  end
end

function UIRepositoryUnitePartBoxDialog:UpadeteIcon()
  local modSuitPlanIDList = self.modSuitPlanIDList
  local listCount = modSuitPlanIDList.Count - 1
  local index = 1
  for i = 0, listCount do
    local suitID = modSuitPlanIDList[i]
    local tbData = TableData.listModPowerDatas:GetDataById(suitID, true)
    local modData = TableData.listModPowerEffectDatas:GetDataById(tbData.power_id)
    index = i + 1
    if self.iconList[index] == nil then
      local obj = instantiate(self.ui.mTrans_WeaponPart, self.ui.mTrans_WeaponPart.parent)
      local t = {}
      t.obj = obj
      t.mImg_Icon = obj:GetComponent(typeof(CS.UnityEngine.UI.Image))
      self.iconList[index] = t
    end
    local item = self.iconList[index]
    item.mImg_Icon.sprite = IconUtils.GetIconV2("WeaponPart", modData.image)
    setactive(item.obj, true)
  end
end

function UIRepositoryUnitePartBoxDialog:OnUpdateCost()
  self.currentCostItemCount = NetCmdItemData:GetNetItemCount(self.mData.costItemId)
end

function UIRepositoryUnitePartBoxDialog:ItemProvider(renderData)
  local itemView = UIRepositoryUnitePartWeaponTypeItem.New()
  itemView:InitCtrlWithoutInstantiate(renderData.gameObject, false)
  itemView:SetClickFunction(function(itemView)
    self:ClickLeftTabFunction(itemView)
  end)
  renderData.data = itemView
end

function UIRepositoryUnitePartBoxDialog:ItemRenderer(index, renderData)
  local data = self.weaponTypeDataList[index + 1]
  local item = renderData.data
  item:SetData(data, index)
  item:SetSelectState(self.curSelectItem)
  item:SetInteractable(self.packageType ~= RepositoryUnitePartTypeGlobal.PackageType.OnlySkill)
end

function UIRepositoryUnitePartBoxDialog:ClickLeftTabFunction(item)
  local lastIndex = self.curSelectItemIndex
  self:SetCurSelectItem(item)
  local itemObj
  if self.curSelectItemIndex then
    local view1 = self.ui.mLoopGridView_ItemList:GetViewItemByIndex(self.curSelectItemIndex)
    if view1 ~= nil then
      itemObj = view1.data
      itemObj:SetSelectState(self.curSelectItem)
    end
  end
  if lastIndex then
    local view1 = self.ui.mLoopGridView_ItemList:GetViewItemByIndex(lastIndex)
    if view1 ~= nil then
      itemObj = view1.data
      itemObj:SetSelectState(self.curSelectItem)
    end
  end
end

function UIRepositoryUnitePartBoxDialog:SetCurSelectItem(item)
  if self.curSelectItem and self.curSelectItem == item.weaponTypeID then
    self.curSelectItem = nil
    self.selectSuitName = nil
    self.curSelectItemIndex = nil
  else
    self.curSelectItem = item.weaponTypeID
    self.selectSuitName = item.suitName
    self.curSelectItemIndex = item.itemIndex
  end
end

function UIRepositoryUnitePartBoxDialog:ClickModPowerFunction(item)
  local lastIndex = self.curSelectModPowerItemIndex
  self:SetCurSelectModPowerItem(item)
  self:RefreshRightList(self.modSuitPlanIDList)
  local itemObj
  if self.curSelectModPowerItemIndex then
    local view1 = self.ui.mLoopGridView_PartSkillList:GetViewItemByIndex(self.curSelectModPowerItemIndex)
    if view1 ~= nil then
      itemObj = view1.data
      itemObj:SetSelectState(self.curSelectModPowerItem)
    end
  end
  if lastIndex then
    local view1 = self.ui.mLoopGridView_PartSkillList:GetViewItemByIndex(lastIndex)
    if view1 ~= nil then
      itemObj = view1.data
      itemObj:SetSelectState(self.curSelectModPowerItem)
    end
  end
end

function UIRepositoryUnitePartBoxDialog:SetCurSelectModPowerItem(item)
  if self.curSelectModPowerItem and self.curSelectModPowerItem == item.suitID then
    self.curSelectModPowerItemIndex = nil
    self.curSelectModPowerItem = nil
    self.curModPowerName = nil
    self.modSuitPlanIDList = nil
  else
    self.curSelectModPowerItemIndex = item.itemIndex
    self.curSelectModPowerItem = item.suitID
    self.modSuitPlanIDList = item.modSuitPlanIDList
    self.curModPowerName = item.selectSuitName
  end
end

function UIRepositoryUnitePartBoxDialog:RefreshRightList(idList)
  local listCount = 0
  if idList ~= nil then
    listCount = idList.Count
    local suitID = 0
    for i = 0, listCount - 1 do
      suitID = idList[i]
    end
    local tbData = TableData.listModPowerDatas:GetDataById(suitID)
    local modData = TableData.listModPowerEffectDatas:GetDataById(tbData.power_id)
    self.ui.mText_SkillName.text = modData.name.str
    self.ui.mImg_WeponPart.sprite = IconUtils.GetIconV2("WeaponPart", modData.image)
    local maxValue = {}
    local minValue = {}
    local skillDescStr
    local formatStr = "{0}-{1}"
    for _, v in pairs(modData.power_skill) do
      local valueDataList = TableData.listPowerSkillCsByPowerSkillDatas:GetDataById(v).Id
      local valueListCount = valueDataList.Count
      for i = 0, valueListCount - 1 do
        local skillID = valueDataList[i]
        local skillValueData = TableData.listPowerSkillCsDatas:GetDataById(skillID)
        local basicValue = skillValueData.basic_value[0]
        if maxValue[v] == nil then
          maxValue[v] = basicValue
        else
          maxValue[v] = math.max(maxValue[v], basicValue)
        end
        if minValue[v] == nil then
          minValue[v] = basicValue
        else
          minValue[v] = math.min(minValue[v], basicValue)
        end
      end
      local battleSkillData = TableData.listBattleSkillDisplayDatas:GetDataById(v)
      local str = battleSkillData.description.str
      if minValue[v] ~= maxValue[v] then
        local str1 = string_format(formatStr, minValue[v], maxValue[v])
        skillDescStr = string_format(str, str1)
      else
        skillDescStr = string_format(str, minValue[v])
      end
    end
    self.ui.mText_Description.text = skillDescStr
  end
  setactive(self.ui.mTrans_DescriptionList, 0 < listCount)
  setactive(self.ui.mTrans_DescTextEmpty, listCount == 0)
end

function UIRepositoryUnitePartBoxDialog:PartItemProvider(renderData)
  local itemView = UIRepositoryUnitePartModPowerItem.New()
  itemView:InitCtrlWithoutInstantiate(renderData.gameObject, false)
  itemView:SetClickFunction(function(itemView)
    self:ClickModPowerFunction(itemView)
  end)
  renderData.data = itemView
end

function UIRepositoryUnitePartBoxDialog:PartItemRenderer(index, renderData)
  local data = self.partDataList[index]
  local item = renderData.data
  item:SetData(data, index, self.packageType)
  item:SetSelectState(self.curSelectModPowerItem)
  item:SetInteractable(self.packageType ~= RepositoryUnitePartTypeGlobal.PackageType.OnlyWeapon)
end

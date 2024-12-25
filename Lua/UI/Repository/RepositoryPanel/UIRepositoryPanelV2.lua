require("UI.Common.UICommonLeftTabItemV2")
require("UI.Repository.RepositoryPanel.SubPanel.UIRepositoryPublicSkillPanel")
require("UI.Repository.RepositoryPanel.SubPanel.WeaponParts.UIRepositoryWeaponPartsPanel")
require("UI.Repository.RepositoryPanel.SubPanel.Common.UIRepositoryCommonPanel")
require("UI.Repository.RepositoryPanel.SubPanel.UIRepositoryGunCorePanel")
require("UI.Repository.RepositoryPanel.SubPanel.UIRepositoryWeaponPanel")
require("UI.Repository.RepositoryPanel.SubPanel.UIRepositoryItemPanel")
require("UI.Repository.RepositoryPanel.SubSheet.UIItemComposeSheet")
require("UI.Repository.UIRepositoryGlobal")
require("UI.Repository.RepositoryPanel.UIRepositoryPanelV2View")
require("UI.Repository.RepositoryPanel.SubPanel.UIRepositoryBasePanel")
require("UI.Common.UIComTopTabItemB")
UIRepositoryPanelV2 = class("UIRepositoryPanelV2", UIBasePanel)
UIRepositoryPanelV2.RedPointType = {
  RedPointConst.RepositoryPiece,
  RedPointConst.RepositoryGunPiece,
  RedPointConst.RepositoryBox
}

function UIRepositoryPanelV2:OnAwake(root, tabId)
  self:SetRoot(root)
  self.mView = UIRepositoryPanelV2View.New()
  self.ui = {}
  self.mView:InitCtrl(root, self.ui)
  self.leftTabTable = {}
  self.subPanelTable = {}
  self.sortItemTable = {}
  self.DropdownItemTable = {}
  self.isAscend = false
  self.isSortDropDownActive = false
  self.sheetItemTable = {}
  self.SubSheetUITable = {}
  self.SheetCanvasGroupTable = {}
  self.SheetCanvasGroupTable[UIRepositoryGlobal.SheetType.RepositorySheet] = self.ui.mCanvasGroup_GrpRepository
  self.SheetCanvasGroupTable[UIRepositoryGlobal.SheetType.ComposeSheet] = self.ui.mCanvasGroup_GrpCompose
  self.SheetTransTable = {}
  self.SheetTransTable[UIRepositoryGlobal.SheetType.RepositorySheet] = self.ui.mTrans_GrpRepository
  self.SheetTransTable[UIRepositoryGlobal.SheetType.ComposeSheet] = self.ui.mTrans_GrpCompose
  UIUtils.GetButtonListener(self.ui.mBtn_Decompose.gameObject).onClick = function()
    self:OnClickDecompose()
  end
  setactive(self.ui.mTrans_Bottom, false)
  self:SetDecomposeVisible(false)
  self:SetOwnAndLimitNumVisible(false)
  self:InitSubSheet()
  self:InitAllSubPanel()
  setactive(self.ui.mTrans_PartsTypeRoot, false)
  setactive(self.ui.mTrans_WeaponPartsSuit, false)
  setactive(self.ui.mTrans_ChrTalentList, false)
  setactive(self.ui.mTrans_TalentImgLine, false)
end

function UIRepositoryPanelV2:OnInit(root, tabId)
  UIRepositoryGlobal.sheetType = UIRepositoryGlobal.sheetType or 1
  self.curTabId = 0
  self.curPanelId = 0
  self.curSort = 0
  self.delayTime = 1
  local defaultTabId = 1
  if TableData.listRepositoryTagDatas.Count ~= 0 then
    defaultTabId = TableData.listRepositoryTagDatas:GetDataByIndex(0).id
  end
  self.targetTabId = tabId or defaultTabId
  if tabId and type(tabId) == "userdata" then
    self.targetTabId = tabId[0]
  elseif tabId then
    self.targetTabId = tabId
  end
  self:InitSheetButton()
  self:InitTabButton()
  UIUtils.GetButtonListener(self.ui.mBtn_BackItem.gameObject).onClick = function()
    self:ClearSubSheet()
    self:OnReturnClick()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_HomeItem.gameObject).onClick = function()
    self:ClearSubSheet()
    SceneSys:SwitchVisible(EnumSceneType.HallScene)
    UISystem:JumpToMainPanel()
  end
  self:SwitchSubSheet(UIRepositoryGlobal.sheetType)
end

function UIRepositoryPanelV2:OnShowStart()
end

function UIRepositoryPanelV2:OnBackFrom()
  self.subPanelTable[self.curPanelId]:OnPanelBack()
end

function UIRepositoryPanelV2:OnTop()
  self.subPanelTable[self.curPanelId]:OnPanelBack()
end

function UIRepositoryPanelV2:OnFadeInFinish()
end

function UIRepositoryPanelV2:OnClose()
  if self.CallTimer1 ~= nil then
    self.CallTimer1:Stop()
  end
  if self.CallTimer2 ~= nil then
    self.CallTimer2:Stop()
  end
  if self.CallTimerSheetItem1 ~= nil then
    self.CallTimerSheetItem1:Stop()
  end
  for i, tab in pairs(self.leftTabTable) do
    tab:SetItemState(false)
  end
  local subPanel = self.subPanelTable[self.curPanelId]
  if subPanel then
    subPanel:Close()
  end
  local curTab = self:GetSubSheetByTagId(UIRepositoryGlobal.sheetType)
  if curTab ~= nil then
    curTab:SetBtnInteractable(true)
  end
  self.curTabId = nil
  self.curPanelId = nil
  self.curSort = nil
end

function UIRepositoryPanelV2:OnRelease()
  RedPointSystem:GetInstance():RemoveRedPointListener(RedPointConst.RepositoryPiece)
  RedPointSystem:GetInstance():RemoveRedPointListener(RedPointConst.RepositoryBox)
  self:ReleaseCtrlTable(self.leftTabTable, true)
  self:ReleaseCtrlTable(self.sortItemTable, true)
  self:ReleaseCtrlTable(self.sheetItemTable, true)
  for _, panel in pairs(self.subPanelTable) do
    panel:OnRelease()
  end
  self.subPanelTable = nil
  self.sheetItemTable = nil
  self.SheetCanvasGroupTable = nil
  self.SheetTransTable = nil
  for _, sheetObj in pairs(self.SubSheetUITable) do
    sheetObj:OnRelease()
  end
  self.SubSheetUITable = nil
  self.mView:OnRelease()
  self.mView = nil
end

function UIRepositoryPanelV2:OnClickDecompose()
  UIManager.OpenUIByParam(UIDef.UIRepositoryDecomposePanelV3, self.curPanelId)
end

function UIRepositoryPanelV2:InitSubSheet()
  local subSheetId = UIRepositoryGlobal.SheetType.ComposeSheet
  local subSheet = UIItemComposeSheet.New(self, subSheetId, self.SheetCanvasGroupTable[subSheetId])
  self.SubSheetUITable[subSheetId] = subSheet
end

function UIRepositoryPanelV2:InitSheetButton()
  local sheetIdList = TableData.listRepositoryTitleDatas:GetList()
  for index = sheetIdList.Count - 1, 0, -1 do
    if index > #self.sheetItemTable - 1 then
      local item = UIComTopTabItemB.New()
      self.CallTimerSheetItem1 = TimerSys:DelayFrameCall(self.delayTime, function()
        item:InitCtrl(self.ui.mTrans_SheetItemContent, {
          name = sheetIdList[index].Title.str
        })
        item:AddClickListener(function()
          self:OnClickSheet(sheetIdList[index].Id)
        end)
        item:SetActive(true)
        self.sheetItemTable[sheetIdList[index].Id] = item
        if self.sheetItemTable[UIRepositoryGlobal.sheetType] then
          self.sheetItemTable[UIRepositoryGlobal.sheetType]:SetBtnInteractable(false)
        end
      end)
    end
  end
  if self.sheetItemTable[UIRepositoryGlobal.sheetType] then
    self.sheetItemTable[UIRepositoryGlobal.sheetType]:SetBtnInteractable(false)
  end
  setactive(self.ui.mTrans_TabModeList, true)
end

function UIRepositoryPanelV2:OnClickSheet(subSheetId)
  if UIRepositoryGlobal.sheetType == subSheetId or subSheetId == nil or subSheetId <= 0 then
    return
  end
  local tagData = TableData.listRepositoryTitleDatas:GetDataById(subSheetId)
  if tagData == nil then
    return
  end
  self.ui.mVirtualListEx_List:StopMovement()
  self.ui.mVirtualListEx_List:ResetPos()
  if UIRepositoryGlobal.sheetType > 0 then
    local lastSubSheet = self:GetSubSheetByTagId(UIRepositoryGlobal.sheetType)
    lastSubSheet:SetBtnInteractable(true)
  end
  local curTab = self:GetSubSheetByTagId(subSheetId)
  if curTab ~= nil then
    curTab:SetBtnInteractable(false)
    self:SwitchSubSheet(subSheetId)
    UIRepositoryGlobal.sheetType = subSheetId
  end
end

function UIRepositoryPanelV2:GetSubSheetByTagId(subSheetId)
  for subSheetItemId, subSheetItem in pairs(self.sheetItemTable) do
    if subSheetItemId == subSheetId then
      return subSheetItem
    end
  end
  return nil
end

function UIRepositoryPanelV2:SwitchSubSheet(subSheetId)
  for id, sheetTrans in pairs(self.SheetTransTable) do
    if id == subSheetId then
      setactive(sheetTrans, true)
      sheetTrans.localPosition = vectorzero
    else
      sheetTrans.localPosition = Vector3(0, 3000, 0)
    end
  end
  if subSheetId == UIRepositoryGlobal.SheetType.ComposeSheet then
    local subSheet = self.SubSheetUITable[subSheetId]
    if subSheet then
      subSheet:Show()
      subSheet:Refresh()
    end
  end
end

function UIRepositoryPanelV2:ClearSubSheet()
  UIRepositoryGlobal.sheetType = UIRepositoryGlobal.SheetType.RepositorySheet
  local targetSubSheetTrans = self.SheetTransTable[UIRepositoryGlobal.SheetType.ComposeSheet]
  if targetSubSheetTrans then
    setactive(targetSubSheetTrans, false)
  end
  for _, sheet in pairs(self.sheetItemTable) do
    sheet:SetBtnInteractable(true)
  end
end

function UIRepositoryPanelV2:InitAllSubPanel()
  local allPanelTagDataList = TableData.listRepositoryTagDatas
  for i = 0, allPanelTagDataList.Count - 1 do
    self:InitSubPanel(allPanelTagDataList[i].Id)
  end
end

function UIRepositoryPanelV2:InitSubPanel(panelId)
  local subPanel
  if panelId == UIRepositoryGlobal.PanelType.ItemPanel then
    subPanel = UIRepositoryItemPanel.New(self, panelId, self.ui.mCanvasGroup_Item)
  elseif panelId == UIRepositoryGlobal.PanelType.WeaponPanel then
    subPanel = UIRepositoryWeaponPanel.New(self, panelId, self.ui.mCanvasGroup_Other)
  elseif panelId == UIRepositoryGlobal.PanelType.GunCore then
    subPanel = UIRepositoryGunCorePanel.New(self, panelId, self.ui.mCanvasGroup_Other)
  elseif panelId == UIRepositoryGlobal.PanelType.WeaponParts then
    subPanel = UIRepositoryWeaponPartsPanel.New(self, panelId, self.ui.mCanvasGroup_Other)
  elseif panelId == UIRepositoryGlobal.PanelType.UAVMaterial then
    subPanel = UIRepositoryCommonPanel.New(self, panelId, self.ui.mCanvasGroup_Other)
  elseif panelId == UIRepositoryGlobal.PanelType.PublicSkill then
    subPanel = UIRepositoryPublicSkillPanel.New(self, panelId, self.ui.mCanvasGroup_Other)
  end
  self.subPanelTable[panelId] = subPanel
end

function UIRepositoryPanelV2:InitTabButton()
  local childItem = self.ui.mContent_Tab.transform:GetComponent(typeof(CS.ScrollListChild))
  local leftTabMobilePrefab = childItem.childItem
  local leftTabPCPrefab = childItem.childItem
  local typeList = TableData.listRepositoryTagDatas:GetList()
  local list = {}
  for i = 0, typeList.Count - 1 do
    local type = typeList[i]
    list[type.sequence] = type
  end
  self.typeListNum = #list
  self:InitSingleTabItem(1, list, leftTabPCPrefab)
  setactive(self.ui.mTrans_LeftMobile, true)
end

function UIRepositoryPanelV2:InitSingleTabItem(index, list, prefab)
  local data = list[index]
  if data ~= nil then
    local item = UICommonLeftTabItemV2.New()
    self.CallTimer1 = TimerSys:DelayFrameCall(self.delayTime, function()
      if index > #self.leftTabTable then
        local obj = instantiate(prefab, self.ui.mContent_Tab.transform)
        item:InitCtrl(obj.transform)
        item:SetName(data.id, data.title.str)
        item:SetUnlock(data.unlock)
        UIUtils.GetButtonListener(item.ui.mBtn_Self.gameObject).onClick = function()
          self:OnClickTab(item.tagId)
        end
        table.insert(self.leftTabTable, item)
      end
      if index == #list then
        self:OnClickTab(self.targetTabId)
        self.CallTimer2 = TimerSys:DelayFrameCall(1, function()
          self:RefreshRedPoint()
        end)
      else
        self:InitSingleTabItem(index + 1, list, prefab)
      end
    end)
  end
end

function UIRepositoryPanelV2:InitSortButton()
  local sortOptionPrefab = UIUtils.GetGizmosPrefab("Character/ChrEquipSuitDropDownItemV2.prefab", self)
  for _, id in pairs(UIRepositoryGlobal.SortType) do
    local item = ChrEquipSuitDropdownItemV2.New()
    local obj = instantiate(sortOptionPrefab, self.ui.mContent_Screen.transform)
    item:InitCtrl(obj.transform)
    item.sortId = id
    item.mText_SuitName.text = TableData.GetHintById(53 + id)
    item.mText_SuitNum.text = ""
    UIUtils.GetButtonListener(item.mBtn_Select.gameObject).onClick = function()
      self:OnClickSort(item.sortId)
    end
    self.textcolor = obj.transform:GetComponent("TextImgColor")
    self.beforecolor = self.textcolor.BeforeSelected
    self.aftercolor = self.textcolor.AfterSelected
    if id == UIRepositoryGlobal.SortType.Level then
      item.mText_SuitName.color = self.textcolor.AfterSelected
      setactive(item.mTrans_GrpSet, true)
    else
      item.mText_SuitName.color = self.textcolor.BeforeSelected
      setactive(item.mTrans_GrpSet, false)
    end
    table.insert(self.sortItemTable, item)
  end
end

function UIRepositoryPanelV2:RefreshRedPoint()
  for _, item in pairs(self.leftTabTable) do
    item:SetRedPoint(item.tagId == 4 and NetCmdItemData:UpdateWeaponPieceRedPoint() > 0 or item.tagId == 9 and 0 < NetCmdItemData:UpdateGiftPickRedPoint())
  end
end

function UIRepositoryPanelV2:OnClickTab(tabId)
  if self.curTabId == tabId or tabId == nil or tabId <= 0 then
    return
  end
  local tagData = TableData.listRepositoryTagDatas:GetDataById(tabId)
  if tagData == nil then
    return
  end
  local unlockId = UIRepositoryGlobal.SystemIdList[tabId]
  if tagData ~= nil and 0 < tagData.unlock then
    unlockId = tagData.unlock
  end
  if TipsManager.NeedLockTips(unlockId) then
    return
  end
  self.ui.mVirtualListEx_List:StopMovement()
  self.ui.mVirtualListEx_List:ResetPos()
  if self.curTabId > 0 then
    local lastTab = self:GetLeftTabByTagId(self.curTabId)
    lastTab:SetItemState(false)
  end
  local curTab = self:GetLeftTabByTagId(tabId)
  if curTab ~= nil then
    curTab:SetItemState(true)
    self.curTabId = tabId
    self:SwitchPanel(tabId)
  end
end

function UIRepositoryPanelV2:GetLeftTabByTagId(tagId)
  for i, tab in pairs(self.leftTabTable) do
    if tab.tagId == tagId then
      return tab
    end
  end
  return nil
end

function UIRepositoryPanelV2:SwitchPanel(panelId)
  local curPanel = self.subPanelTable[self.curPanelId]
  if curPanel then
    curPanel:Close()
  end
  self.curPanelId = panelId
  local subPanel = self.subPanelTable[panelId]
  if subPanel then
    subPanel:Show()
    subPanel:Refresh()
  end
end

function UIRepositoryPanelV2:ResetItemListSort()
  local defaultSort = UIRepositoryGlobal.SortType.Level
  if self.curSort == defaultSort then
    self.curSort = 0
  end
  self:OnClickSort(defaultSort)
end

function UIRepositoryPanelV2:OnClickSort(id)
  self.curSort = id
  for i = 1, #self.sortItemTable do
    if self.sortItemTable[i].sortId == id then
      self.sortItemTable[i].mText_SuitName.color = self.textcolor.AfterSelected
      setactive(self.sortItemTable[i].mTrans_GrpSet, true)
    else
      self.sortItemTable[i].mText_SuitName.color = self.textcolor.BeforeSelected
      setactive(self.sortItemTable[i].mTrans_GrpSet, false)
    end
  end
  self.uiComScreenItemV2:SetSuitName(TableData.GetHintById(53 + id))
  self.isSortDropDownActive = false
  self:UpdateSortList(self.curSort)
end

function UIRepositoryPanelV2:UpdateSortList(sortType)
  local sortFunc
  local subPanel = self.subPanelTable[self.curPanelId]
  if self.curPanelId == UIRepositoryGlobal.PanelType.ItemPanel then
    sortFunc = UIRepositoryGlobal:GetSortFunction(sortType, 1, self.isAscend)
    subPanel:SortItemList(sortFunc)
  else
    subPanel:RefreshItemList()
  end
end

function UIRepositoryPanelV2:SortItemList()
  if self.curSort == 0 then
    self.curSort = UIRepositoryGlobal.SortType.Level
  end
  self:OnClickSort(self.curSort)
end

function UIRepositoryPanelV2:GetSelectItemList()
  local subPanel = self.subPanelTable[self.curPanelId]
  return subPanel:GetSelectItemList()
end

function UIRepositoryPanelV2:OnClickBtnSuit()
  setactive(self.ui.suitDropdownItemList, true)
  setactive(self.ui.sortTypeDropdownItemList, false)
  setactive(self.ui.mTrans_Screen, not self.ui.mTrans_Screen.gameObject.activeSelf)
end

function UIRepositoryPanelV2:OnClickBtnSortType()
  setactive(self.ui.suitDropdownItemList, false)
  setactive(self.ui.sortTypeDropdownItemList, true)
  setactive(self.ui.mTrans_Screen, not self.ui.mTrans_Screen.gameObject.activeSelf)
end

function UIRepositoryPanelV2:OnClickBtnReverseSort()
  self.isAscend = not self.isAscend
  self:UpdateSortList(self.curSort)
end

function UIRepositoryPanelV2:ShowSelectedSuitTips(suitId)
  local data = TableData.listModPowerDatas:GetDataById(suitId)
  if not data then
    return
  end
  self.ui.mText_SuitSelectedName.text = data.name.str
  setactive(self.ui.mTrans_SuitSelectedTips, true)
end

function UIRepositoryPanelV2:HideSelectedSuitTips()
  setactive(self.ui.mTrans_SuitSelectedTips, false)
end

function UIRepositoryPanelV2:OnClickSuitTipsClose()
  local subPanel = self.subPanelTable[self.curPanelId]
  subPanel:SelectAllType()
  setactive(self.ui.mTrans_SuitSelectedTips, false)
end

function UIRepositoryPanelV2:OnScreenClose()
  setactive(self.ui.suitDropdownItemList, false)
  setactive(self.ui.sortTypeDropdownItemList, false)
  setactive(self.ui.mTrans_Screen, false)
end

function UIRepositoryPanelV2:SetTypeScreenVisible(visible)
  self.uiComScreenItemV2:SetBtnSuitVisible(visible)
end

function UIRepositoryPanelV2:SetDecomposeText(text)
  self.uiComBtn3ItemR:SetName(text)
end

function UIRepositoryPanelV2:SetDecomposeVisible(visible)
  setactive(self.ui.mTrans_DecomposeRoot, visible)
end

function UIRepositoryPanelV2:SetOwnAndLimitNumVisible(visible)
  setactive(self.ui.mTrans_OwnNumRoot, visible)
end

function UIRepositoryPanelV2:SetOwnAndLimitNum(haveNum, LimitNum)
  self.ui.mText_Num.text = haveNum
  self.ui.mText_Total.text = LimitNum
end

function UIRepositoryPanelV2:UpdateConfirmBtn()
  local selectList = self:GetSelectItemList()
  setactive(self.ui.mTrans_CanNotDismantle, #selectList <= 0)
end

function UIRepositoryPanelV2:CheckPlatform(PlatformType)
  return PlatformType == CS.GameRoot.Instance.AdapterPlatform
end

function UIRepositoryPanelV2:OnReturnClick(go)
  SceneSys:SwitchVisible(EnumSceneType.HallScene)
  UIManager.CloseUI(UIDef.UIRepositoryPanelV2)
end

function UIRepositoryPanelV2:ResetEscapeBtn(boolean, action)
  if boolean then
    self:UnRegistrationKeyboard(KeyCode.Escape)
    self:RegistrationKeyboardAction(KeyCode.Escape, function()
      if action ~= nil then
        action()
      end
    end)
  else
    self:UnRegistrationKeyboard(KeyCode.Escape)
    self:RegistrationKeyboard(KeyCode.Escape, self.ui.mBtn_BackItem)
  end
end

require("UI.UIBasePanel")
UIMemoryChipPanel = class("UIMemoryChipPanel", UIBasePanel)
UIMemoryChipPanel.__index = UIMemoryChipPanel
UIMemoryChipPanel.mView = nil
UIMemoryChipPanel.mData = nil
UIMemoryChipPanel.mPanelType = 1
UIMemoryChipPanel.mCurChipItem = nil
UIMemoryChipPanel.mSelectedComsumeItemsList = nil
UIMemoryChipPanel.TheCanvas = nil
UIMemoryChipPanel.mPrefabChipConsumeItemPath = "Repository/UIChipConsumeItem.prefab"

function UIMemoryChipPanel:ctor()
  UIMemoryChipPanel.super.ctor(self)
end

function UIMemoryChipPanel.Close()
  UIManager.CloseUI(UIDef.UIMemoryChipPanel)
end

function UIMemoryChipPanel.Init(root, data)
  self = UIMemoryChipPanel
  self.mData = data[1]
  self.mPanelType = data[2]
  UIMemoryChipPanel.mCurChipItem = data[3]
  self:SetRoot(root)
  self.mSelectedComsumeItemsList = List:New()
end

function UIMemoryChipPanel.OnRelease()
  self = UIMemoryChipPanel
  UIMemoryChipPanel.mCurChipItem = nil
  UIMemoryChipPanel.TheCanvas = nil
end

function UIMemoryChipPanel.OnInit()
  self = UIMemoryChipPanel
  local parent = UIUtils.FindTransform(FacilityBarrackData.m3DCanvasRootPath)
  UIMemoryChipPanel.super.SetRootToParent(UIMemoryChipPanel, self.mUIRoot, parent)
  self.mView = UIMemoryChipPanelView
  self.mView:InitCtrl(self.mUIRoot)
  self.mView:InitView(self.mData, self.mPanelType)
  UIUtils.GetListener(self.mView.mBtn_ChipInformation_LevelUp.gameObject).onClick = self.OnLevelUpClicked
  UIUtils.GetListener(self.mView.mBtn_ChipInformation_lock.gameObject).onClick = self.OnLockClicked
  UIUtils.GetListener(self.mView.mBtn_LevelUp_Consume.gameObject).onClick = self.OnAddConsumeItemClicked
  UIUtils.GetListener(self.mView.mTrans_LevelUp_EmptyPlus.gameObject).onClick = self.OnAddConsumeItemClicked
  UIUtils.GetListener(self.mView.mBtn_LevelUp_LevelUpConfirm.gameObject).onClick = self.OnLevelUpConfirmClicked
  UIUtils.GetListener(self.mView.mBtn_TopInformation_Exit.gameObject).onClick = self.OnCloseClick
  UIUtils.GetListener(self.mView.mBtn_ChipInformation_Unload.gameObject).onClick = self.OnUnloadChipClicked
  UIUtils.GetListener(self.mView.mBtn_ChipInformation_Replace.gameObject).onClick = self.OnReplaceChipClicked
  UIUtils.GetListener(self.mView.mBtn_ChipInformation_Equip.gameObject).onClick = self.OnEquipChipClicked
  UIMemoryChipPanel.SetCanvas(false)
  self.mView:UpdateResource(0)
  self:CheckConfirmButton(0)
end

function UIMemoryChipPanel.OnShow()
  self = UIMemoryChipPanel
end

function UIMemoryChipPanel.SetCanvas(active)
  if UIMemoryChipPanel.TheCanvas == nil then
    UIMemoryChipPanel.TheCanvas = UIUtils.FindTransform("Canvas")
  end
  setactive(UIMemoryChipPanel.TheCanvas, active)
end

function UIMemoryChipPanel.OnLevelUpClicked(gameObject)
  self = UIMemoryChipPanel
  self.mView:SetLevelUpInfo(0, self.mData.CurLv, 0)
  setactive(self.mView.mTrans_LevelUp.gameObject, true)
  setactive(self.mView.mTrans_ChipInformation.gameObject, false)
  setactive(self.mView.mTrans_TopInformation_resPanel.gameObject, true)
end

function UIMemoryChipPanel.OnLockClicked(gameObject)
  self = UIMemoryChipPanel
  NetCmdChipData:SendReqChipLockUnlockCmd(self.mData.id, self.OnLockCallback)
end

function UIMemoryChipPanel.OnAddConsumeItemClicked(gameObject)
  self = UIMemoryChipPanel
  if self.mData.IsReachMaxLv then
    return
  end
  UIMemoryChipPanel.SetCanvas(true)
  local list = List:New()
  local params = {
    self.mSelectedComsumeItemsList,
    self.mData.id
  }
  UIRepositoryListPanel.Open(3, UIDef.UIMemoryChipPanel, params)
end

function UIMemoryChipPanel.OnLevelUpConfirmClicked(gameObject)
  self = UIMemoryChipPanel
  local cost = NetCmdChipData:GetChipCashPrice(self.mSelectedComsumeItemsList)
  if cost > GlobalData.cash then
    return
  end
  NetCmdChipData:SendReqChipLevelUpCmd(self.mData.id, self.mSelectedComsumeItemsList, self.OnLevelUpCallback)
end

function UIMemoryChipPanel.OnEquipChipClicked(gameObject)
  self = UIMemoryChipPanel
  local gun_id = FacilityBarrackData.CurrentTrainGun.id
  NetCmdChipData:SendReqGunSetChip(gun_id, self.mData.id, self.OnEquipChipCallback)
end

function UIMemoryChipPanel.OnReplaceChipClicked(gameObject)
  self = UIMemoryChipPanel
  UIMemoryChipPanel.SetCanvas(true)
  UIRepositoryPanel.Open(3, UIDef.UICharacterDetailPanel)
end

function UIMemoryChipPanel.OnUnloadChipClicked(gameObject)
  self = UIMemoryChipPanel
  local gun_id = self.mData.gun_id
  NetCmdChipData:SendReqGunSetChip(gun_id, 0, self.OnUnloadChipCallback)
end

function UIMemoryChipPanel.OnCloseClick()
  self = UIMemoryChipPanel
  self:RemoveConsumeItems()
  if self.mPanelType == 2 then
    if self.mView.mTrans_LevelUp.gameObject.activeSelf == true then
      setactive(self.mView.mTrans_LevelUp.gameObject, false)
      setactive(self.mView.mTrans_ChipInformation.gameObject, true)
      setactive(self.mView.mTrans_TopInformation_resPanel.gameObject, false)
    else
      UIMemoryChipPanel.SetCanvas(true)
      UIMemoryChipPanel.Close()
    end
    return
  end
  if self.mView.mTrans_LevelUp.gameObject.activeSelf == true then
    setactive(self.mView.mTrans_LevelUp.gameObject, false)
    setactive(self.mView.mTrans_ChipInformation.gameObject, true)
    setactive(self.mView.mTrans_TopInformation_resPanel.gameObject, false)
  else
    UIMemoryChipPanel.SetCanvas(true)
    if UIMemoryChipPanel.mCurChipItem ~= nil then
      UIMemoryChipPanel.mCurChipItem:SetData(self.mData)
    end
    UIMemoryChipPanel.Close()
  end
end

function UIMemoryChipPanel.UpdateConsumeItem(selectedItems)
  self = UIMemoryChipPanel
  local tempList = NetCmdChipData:SortConsumeChips(selectedItems, self.mData.stc_id)
  self.mSelectedComsumeItemsList:Clear()
  for i = 0, tempList.Length - 1 do
    self.mSelectedComsumeItemsList:Add(tempList[i])
  end
  UIMemoryChipPanel.SetCanvas(false)
  local count = self.mView.mTrans_LevelUp_FoodList.transform.childCount
  local tr = self.mView.mTrans_LevelUp_FoodList.transform
  for i = count - 1, 1, -1 do
    gfdestroy(tr:GetChild(i).gameObject)
  end
  local prefab = UIUtils.GetGizmosPrefab(self.mPrefabChipConsumeItemPath, self)
  for i = 1, self.mSelectedComsumeItemsList:Count() do
    local uiRepoItem = UIChipConsumeItem.New()
    local instItem = instantiate(prefab)
    uiRepoItem:InitCtrl(instItem.transform)
    uiRepoItem:InitData(self.mSelectedComsumeItemsList[i])
    UIUtils.AddListItem(instItem, self.mView.mTrans_LevelUp_FoodList.gameObject)
  end
  if 0 < selectedItems:Count() then
    setactive(self.mView.mTrans_LevelUp_EmptyPlus.gameObject, false)
  else
    setactive(self.mView.mTrans_LevelUp_EmptyPlus.gameObject, true)
  end
  self.mView:UpdateAmount(self.mSelectedComsumeItemsList:Count())
  self.UpdateExpBar()
end

function UIMemoryChipPanel.UpdateExpBar()
  self = UIMemoryChipPanel
  local exp = NetCmdChipData:GetExpOffered(self.mSelectedComsumeItemsList)
  local afterLv = self.mData:GetLevelByOfferedExp(exp)
  local breakTimes = NetCmdChipData:GetBreakTimes(self.mData.id, self.mSelectedComsumeItemsList)
  self.mView:SetLevelUpInfo(exp, afterLv, breakTimes)
  local cash = NetCmdChipData:GetChipCashPrice(self.mSelectedComsumeItemsList)
  self.mView:UpdateResource(cash)
  self:CheckConfirmButton(cash)
end

function UIMemoryChipPanel.OnLockCallback(ret)
  self = UIMemoryChipPanel
  self.mView:InitView(self.mData, self.mPanelType)
  if UIMemoryChipPanel.mCurChipItem ~= nil and UIMemoryChipPanel.mCurChipItem.mTrans_locked ~= nil then
    setactive(UIMemoryChipPanel.mCurChipItem.mTrans_locked.gameObject, self.mData.IsLocked)
  end
end

function UIMemoryChipPanel.OnEquipChipCallback(ret)
  self = UIMemoryChipPanel
  if ret == ErrorCodeSuc then
    gfdebug("\232\163\133\229\164\135\232\138\175\231\137\135\230\136\144\229\138\159")
    UICharacterDetailPanel.SetChipSlotState()
    UIMemoryChipPanel.SetCanvas(true)
    UIMemoryChipPanel.Close()
    UIRepositoryPanel.Close()
  else
    gfdebug("\232\163\133\229\164\135\232\138\175\231\137\135\229\164\177\232\180\165")
    MessageBox.Show("\229\135\186\233\148\153\228\186\134", "\232\163\133\229\164\135\232\138\175\231\137\135\229\164\177\232\180\165!", MessageBox.ShowFlag.eMidBtn, nil, nil, nil)
  end
end

function UIMemoryChipPanel.OnUnloadChipCallback(ret)
  self = UIMemoryChipPanel
  if ret == ErrorCodeSuc then
    gfdebug("\229\141\184\228\184\139\232\138\175\231\137\135\230\136\144\229\138\159")
    if self.mPanelType == 2 then
      UICharacterDetailPanel.SetChipSlotState()
      UIMemoryChipPanel.SetCanvas(true)
      UIMemoryChipPanel.Close()
      UIRepositoryPanel.Close()
    else
      self.mView:InitView(self.mData, self.mPanelType)
    end
  else
    gfdebug("\229\141\184\228\184\139\232\138\175\231\137\135\229\164\177\232\180\165")
    MessageBox.Show("\229\135\186\233\148\153\228\186\134", "\229\141\184\228\184\139\232\138\175\231\137\135\229\164\177\232\180\165!", MessageBox.ShowFlag.eMidBtn, nil, nil, nil)
  end
end

function UIMemoryChipPanel.OnLevelUpCallback(ret)
  self = UIMemoryChipPanel
  if ret == ErrorCodeSuc then
    gfdebug("\229\188\186\229\140\150\232\138\175\231\137\135\230\136\144\229\138\159")
    if self.mPanelType == 2 then
      UICharacterDetailPanel.SetChipSlotState()
    end
    self.mView:InitView(self.mData, self.mPanelType)
    self.mView:SetLevelUpInfo(0, self.mData.CurLv, 0)
    self.mView:UpdateResource(0)
    self:RemoveConsumeItems()
  else
    gfdebug("\229\188\186\229\140\150\232\138\175\231\137\135\229\164\177\232\180\165")
    MessageBox.Show("\229\135\186\233\148\153\228\186\134", "\229\188\186\229\140\150\232\138\175\231\137\135\229\164\177\232\180\165!", MessageBox.ShowFlag.eMidBtn, nil, nil, nil)
    self.mView:InitView(self.mData, self.mPanelType)
    self.mView:SetLevelUpInfo(0, self.mData.CurLv, 0)
  end
  self:CheckConfirmButton(0)
end

function UIMemoryChipPanel:CheckConfirmButton(cost)
  local isEnable = true
  if self.mSelectedComsumeItemsList:Count() <= 0 then
    isEnable = false
  end
  if cost > GlobalData.cash then
    isEnable = false
  end
  self.mView.mBtn_LevelUp_LevelUpConfirm.interactable = isEnable
end

function UIMemoryChipPanel:RemoveConsumeItems()
  local count = self.mView.mTrans_LevelUp_FoodList.transform.childCount
  local tr = self.mView.mTrans_LevelUp_FoodList.transform
  for i = count - 1, 1, -1 do
    gfdestroy(tr:GetChild(i).gameObject)
  end
  self.mSelectedComsumeItemsList:Clear()
  setactive(self.mView.mTrans_LevelUp_EmptyPlus.gameObject, true)
  self.mView:UpdateAmount(self.mSelectedComsumeItemsList:Count())
  self.mView:UpdateResource(0)
  self:CheckConfirmButton(0)
end

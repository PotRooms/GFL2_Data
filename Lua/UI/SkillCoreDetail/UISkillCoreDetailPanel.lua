require("UI.UIBasePanel")
require("UI.SkillCoreDetail.UISkillCoreDetailView")
require("UI.SkillCoreDetail.item.SkillPUmatItem")
UISkillCoreDetailPanel = class("UISkillCoreDetailPanel", UIBasePanel)
UISkillCoreDetailPanel.__index = UISkillCoreDetailPanel
UISkillCoreDetailPanel.mView = nil
UISkillCoreDetailPanel.mTweenEase = CS.DG.Tweening.Ease.InOutSine
UISkillCoreDetailPanel.mTweenExpo = CS.DG.Tweening.Ease.InOutCirc
UISkillCoreDetailPanel.mSkillCoreMaterialList = nil
UISkillCoreDetailPanel.mMaterialItemList = nil
UISkillCoreDetailPanel.mPlayerSkillCoreDict = nil
UISkillCoreDetailPanel.mBeforeBarScale = nil
UISkillCoreDetailPanel.mBeforeCoreLevel = 0

function UISkillCoreDetailPanel:ctor()
  UISkillCoreDetailPanel.super.ctor(self)
end

function UISkillCoreDetailPanel.Open()
  UISkillCoreDetailPanel.OpenUI(UIDef.UISkillCoreDetailPanel)
end

function UISkillCoreDetailPanel.Close()
  UIManager.CloseUI(UIDef.UISkillCoreDetailPanel)
end

function UISkillCoreDetailPanel.Init(root, data)
  UISkillCoreDetailPanel.super.SetRoot(UISkillCoreDetailPanel, root)
  self = UISkillCoreDetailPanel
  self.mData = data
  self.mSkillCoreMaterialList = List:New()
  self.mMaterialItemList = List:New()
  self.mPlayerSkillCoreDict = Dictionary:New()
  self.mView = UISkillCoreDetailView
  self.mView:InitCtrl(root)
  self.mView:InitData(data)
  UIUtils.GetListener(self.mView.mBtn_powerUp.gameObject).onClick = self.OpenPowerupPanel
  UIUtils.GetListener(self.mView.mBtn_Return.gameObject).onClick = self.OnReturnClick
  UIUtils.GetListener(self.mView.mBtn_PowerUpButton.gameObject).onClick = self.OnPowerUpClicked
  UIUtils.GetButtonListener(self.mView.mBtn_AddMaterial.gameObject).onClick = self.OnAddMaterialClicked
  UIUtils.GetListener(self.mView.mBtn_PUReturn.gameObject).onClick = self.OnPowerUpReturnClicked
  MessageSys:AddListener(CS.GF2.Message.SkillCoreDataEvent.SkillCorePowerUpMaterialUpdate, self.OnAddSkillCoreMaterials)
  MessageSys:AddListener(CS.GF2.Message.CampaignEvent.ResInfoUpdate, self.OnUpdateResource)
  self:InitPlaySkillCoreDict()
  self:UpdatePowerUpView(false)
  self.mView.mPowerUpButtonOnClick = self.OnPowerUpClicked
end

function UISkillCoreDetailPanel:InitPlaySkillCoreDict()
  local itemDataList = NetCmdCoreData:GetSkillCoreList()
  for i = 0, itemDataList.Count - 1 do
    self.mPlayerSkillCoreDict:Add(itemDataList[i].id, itemDataList[i])
  end
end

function UISkillCoreDetailPanel.OpenPowerupPanel(gameobj)
  self = UISkillCoreDetailPanel
  self:UpdateView()
  setactive(self.mView.mTrans_PowerUpPanel.gameObject, true)
end

function UISkillCoreDetailPanel.OnPowerUpClicked(gameObj)
  self = UISkillCoreDetailPanel
  for i = 1, self.mSkillCoreMaterialList:Count() do
    local coreData = self.mPlayerSkillCoreDict[self.mSkillCoreMaterialList[i]]
    local level = coreData.level
    if 3 < level then
      MessageBox.Show("\230\179\168\230\132\143", "\229\173\152\229\156\168\227\128\144\233\171\152\229\188\186\229\140\150\227\128\145\231\154\132\230\138\128\232\131\189\230\160\184\229\191\131\228\189\156\228\184\186\229\188\186\229\140\150\230\157\144\230\150\153\239\188\140\230\152\175\229\144\166\231\187\167\231\187\173\239\188\159", MessageBox.ShowFlag.eNone, nil, self.SendPowerupReq, nil)
      return
    end
  end
  self.SendPowerupReq()
end

function UISkillCoreDetailPanel.SendPowerupReq()
  self = UISkillCoreDetailPanel
  self.mBeforeCoreLevel = self.mData.level
  self.mBeforeBarScale = self.mView.mBeforeScale
  NetCmdCoreData:SendReqSkillCoreFeed(self.mData.id, self.mSkillCoreMaterialList, self.PowerUpCallback)
end

function UISkillCoreDetailPanel.OnAddMaterialClicked(gameobj)
  self = UISkillCoreDetailPanel
  local data = {}
  local excludedList = List:New()
  local selectedList = List:New()
  for i = 1, self.mSkillCoreMaterialList:Count() do
    selectedList:Add(self.mSkillCoreMaterialList[i])
  end
  excludedList:Add(self.mData.id)
  data[1] = self
  data[2] = selectedList
  data[3] = excludedList
  UIManager.OpenUIByParam(UIDef.UISkillCoreSelectionPanel, data)
end

function UISkillCoreDetailPanel.OnPowerUpReturnClicked(gameObj)
  self = UISkillCoreDetailPanel
  self:ClearMaterialItems()
  setactive(self.mView.mTrans_PowerUpPanel.gameObject, false)
end

function UISkillCoreDetailPanel.OnReturnClick(gameobj)
  self = UISkillCoreDetailPanel
  self:ClearMaterialItems()
  MessageSys:RemoveListener(CS.GF2.Message.SkillCoreDataEvent.SkillCorePowerUpMaterialUpdate, self.OnAddSkillCoreMaterials)
  MessageSys:RemoveListener(CS.GF2.Message.CampaignEvent.ResInfoUpdate, self.OnUpdateResource)
  self.Close()
end

function UISkillCoreDetailPanel.OnAddSkillCoreMaterials(msg)
  local tempSelf = msg.Sender
  local list = msg.Content
  tempSelf.mSkillCoreMaterialList:Clear()
  for i = 1, list:Count() do
    local coreId = list[i]
    tempSelf.mSkillCoreMaterialList:Add(coreId)
  end
  tempSelf:UpdateView()
end

function UISkillCoreDetailPanel.OnUpdateResource(msg)
  self = UISkillCoreDetailPanel
  self.mView:UpdateResource()
end

function UISkillCoreDetailPanel.PowerUpCallback(ret)
  self = UISkillCoreDetailPanel
  if ret == ErrorCodeSuc then
    gfdebug("\230\160\184\229\191\131\229\188\186\229\140\150\230\136\144\229\138\159")
    self:ClearMaterialItems()
    NetCmdCoreData:SendReqSkillCoreCmd(self.OnGetSkillCoreInfo)
  else
    gfdebug("\230\160\184\229\191\131\229\188\186\229\140\150\229\164\177\232\180\165")
  end
end

function UISkillCoreDetailPanel.OnGetSkillCoreInfo(ret)
  self = UISkillCoreDetailPanel
  self.mData = NetCmdCoreData.CoreData[self.mData.id]
  self:UpdatePowerUpView(true)
  MessageSys:SendMessage(CS.GF2.Message.SkillCoreDataEvent.SkillCoreRepositoryPanelRefresh, nil)
end

function UISkillCoreDetailPanel:UpdateView()
  self:UpdateMaterialView()
  self:UpdatePowerUpView(false)
end

function UISkillCoreDetailPanel:UpdateMaterialView()
  for i = 1, self.mMaterialItemList:Count() do
    self.mMaterialItemList[i]:SetData(nil)
  end
  for i = 1, self.mSkillCoreMaterialList:Count() do
    local coreData = self.mPlayerSkillCoreDict[self.mSkillCoreMaterialList[i]]
    if i < self.mMaterialItemList:Count() then
      self.mMaterialItemList[i]:SetData(coreData)
    else
      local uiRepoItem = SkillPUmatItem:New()
      uiRepoItem:InitCtrl(self.mView.mTrans_MaterialList)
      uiRepoItem:SetData(coreData)
      self.mMaterialItemList:Add(uiRepoItem)
    end
  end
end

function UISkillCoreDetailPanel:UpdatePowerUpView(isUpgraded)
  local matSkillCores = {}
  for i = 1, self.mSkillCoreMaterialList:Count() do
    local coreData = self.mPlayerSkillCoreDict[self.mSkillCoreMaterialList[i]]
    matSkillCores[i] = coreData
  end
  local addExp = NetCmdCoreData:GetSkillCoreMaterialExp(matSkillCores, self.mData.stc_id)
  self.mView:InitPowerUpView(self.mData, addExp)
  if isUpgraded == true then
    self.mView:ShowUpgradeAnim(self.mBeforeCoreLevel, self.mBeforeBarScale)
  end
end

function UISkillCoreDetailPanel:ClearMaterialItems()
  self.mSkillCoreMaterialList:Clear()
  for i = 1, self.mMaterialItemList:Count() do
    gfdestroy(self.mMaterialItemList[i]:GetRoot())
  end
  self.mMaterialItemList:Clear()
end

function UISkillCoreDetailPanel.OnShow()
  self = UISkillCoreDetailPanel
end

function UISkillCoreDetailPanel.OnRelease()
  self = UISkillCoreDetailPanel
end

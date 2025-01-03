require("UI.FacilityBarrackPanel.Item.ChrStageUpItemV3")
require("UI.FacilityBarrackPanel.FacilityBarrackGlobal")
UIChrStageUpPanel = class("UIChrStageUpPanel", UIBasePanel)
UIChrStageUpPanel.__index = UIChrStageUpPanel

function UIChrStageUpPanel:ctor(root, uiChrPowerUpPanel)
  UIChrStageUpPanel.super.ctor(self, uiChrPowerUpPanel)
  self.mUIRoot = root
  self.isInit = false
  self.uiChrPowerUpPanel = uiChrPowerUpPanel
  self.ui = {}
  self:LuaUIBindTable(self.mUIRoot, self.ui)
end

function UIChrStageUpPanel:InitUI()
  if self.isInit then
    return
  end
  self.isInit = true
  self.mGunCmdData = nil
  self.rankList = {}
  self.curRank = nil
  self.canUpgrade = false
  self.isItemEnough = false
  self.extraDescriptionList = {}
  self.skilldata = nil
  self.itemData = nil
  self.itemOwn = 0
  self.stageUpBones = nil
  self.needModel = false
  self.cdTimer = nil
  self.isUpgradeBack = false
  self.curItemIndex = -1
  self:InitRank()
  self:OnInit(self.uiChrPowerUpPanel.mGunCmdData)
end

function UIChrStageUpPanel:OnInit(data)
  self.mGunCmdData = data
  self.animator = UIUtils.GetAnimator(self.mUIRoot, "Root")
  UIUtils.GetButtonListener(self.ui.mBtn_OK.gameObject).onClick = function()
    self:OnUpgradeClick()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Skill.gameObject).onClick = function()
    UIManager.OpenUIByParam(UIDef.UIChrSkillInfoDialog, {
      skillData = self.skilldata,
      gunCmdData = self.mGunCmdData,
      isGunLock = self.mGunCmdData == nil,
      curGunGradeId = self.curItemIndex,
      showBottomBtn = false,
      showTag = 2
    })
  end
  UIUtils.GetButtonListener(self.ui.mBtn_ConsumeItem.gameObject).onClick = function()
    if self.itemData ~= nil then
      FacilityBarrackGlobal.UIChrStageUpCoreId = self.itemData.Id
      FacilityBarrackGlobal.SetTargetContentType(FacilityBarrackGlobal.ContentType.UIChrStageUpPanel)
      TipsPanelHelper.OpenUITipsPanel(self.itemData, 0, true, false, 0, function()
        self:UITipsPanelCloseCallback()
      end)
    end
  end
  local tmpContainner = self.ui.mBtn_OK.transform:Find("Root/Trans_RedPoint").gameObject:GetComponent(typeof(CS.UICommonContainer))
  self.OkBtnRedPoint = tmpContainner:InstantiateObj().transform.parent
  setactive(self.OkBtnRedPoint.gameObject, false)
end

function UIChrStageUpPanel:OnShowStart()
  if not self.isInit then
    self:InitUI()
  end
  self:CheckStageUpBonesNull()
  setinteractable(self.ui.mCanvasGroup_Root.gameObject, true)
end

function UIChrStageUpPanel:SetData(needRefreshBonus, needRefreshRankItem)
  self:GetCurGun()
  self.itemData = TableData.GetItemData(self.mGunCmdData.TabGunData.core_item_id)
  self.ui.mImg_Item.sprite = IconUtils.GetItemIconSprite(self.mGunCmdData.TabGunData.core_item_id)
  self.ui.mImg_ChrHead.sprite = IconUtils.GetCharacterHeadSpriteWithClothByGunId(IconUtils.cCharacterAvatarType_Avatar, self.mGunCmdData.TabGunData.id)
  self.ui.mText_AvatarName.text = self.mGunCmdData.TabGunData.Name.str
  self.itemOwn = NetCmdItemData:GetItemCountById(self.mGunCmdData.TabGunData.core_item_id)
  self.isMaxUpgrade = self.mGunCmdData.maxUpgrade == self.mGunCmdData.upgrade
  self.ui.mAnimator_Icon:SetBool("Locked", self.isMaxUpgrade)
  needRefreshBonus = needRefreshBonus == nil and true or needRefreshBonus
  needRefreshRankItem = needRefreshRankItem == nil and true or needRefreshRankItem
  for i, rank in ipairs(self.rankList) do
    rank:SetData(self.mGunCmdData.upgrade)
    if self.isMaxUpgrade then
      if needRefreshRankItem and rank.index == self.mGunCmdData.maxUpgrade then
        self:OnClickRank(rank)
      end
    elseif needRefreshRankItem and rank.index == self.mGunCmdData.upgrade + 1 then
      self:OnClickRank(rank)
    end
  end
  self:InitRankItemCost()
  if needRefreshBonus then
    self.stageUpBones:SetDefaultStars(self.mGunCmdData.upgrade)
    self:UpdateRankData()
  end
end

function UIChrStageUpPanel:OnRecover()
  self:ResetData()
  BarrackHelper.InteractManager:RemoveListener()
  BarrackHelper.InteractManager:ResetAll()
  if FacilityBarrackGlobal.UIChrStageUpCoreId ~= nil and FacilityBarrackGlobal.UIChrStageUpCoreId ~= 0 then
    self.itemData = TableData.GetItemData(FacilityBarrackGlobal.UIChrStageUpCoreId)
    TipsPanelHelper.OpenUITipsPanel(self.itemData, 0, true, false, 0, function()
      self:UITipsPanelCloseCallback()
    end, false, false, false, true)
    FacilityBarrackGlobal.UIChrStageUpCoreId = 0
  end
end

function UIChrStageUpPanel:OnBackFrom()
  self:ResetData()
end

function UIChrStageUpPanel:OnTop()
  self:SetData(false, self.isUpgradeBack)
  self.isUpgradeBack = false
end

function UIChrStageUpPanel:OnShowFinish()
end

function UIChrStageUpPanel:OnUpdate(deltaTime)
end

function UIChrStageUpPanel:OnHideFinish()
end

function UIChrStageUpPanel:OnClose()
  setinteractable(self.ui.mCanvasGroup_Root.gameObject, false)
  self.stageUpBones = nil
  if self.cdTimer then
    self.cdTimer:Stop()
    self.cdTimer = nil
  end
end

function UIChrStageUpPanel:OnRelease()
  self.stageUpBones = nil
  self.super.OnRelease(self)
end

function UIChrStageUpPanel:OnHide()
  if self.cdTimer then
    self.cdTimer:Stop()
    self.cdTimer = nil
  end
  self:ResetCurRankNormal()
  self.curRank = nil
  if self.stageUpBones ~= nil and not self.stageUpBones:CheckIsNull() then
    self.stageUpBones:SetActive(false)
  end
end

function UIChrStageUpPanel:ShowUI()
  self.ui.mAnimator_Root:SetTrigger("FadeIn")
  setinteractable(self.ui.mCanvasGroup_Root.gameObject, true)
end

function UIChrStageUpPanel:SwitchGun(isNext)
  CS.UIBarrackModelManager.Instance:PlayChangeGunEffect()
  self.stageUpBones:SetAllBonesInteractable(false, false)
  if self.curRank ~= nil then
    self.curRank:SetSelect(true)
  end
  self.curRank = nil
  if self.cdTimer then
    self.cdTimer:Stop()
    self.cdTimer = nil
  end
end

function UIChrStageUpPanel:GetCurGun()
  local gunId = BarrackHelper.ModelMgr.GunStcDataId
  self.isLockGun = NetCmdTeamData:GetGunByStcId(gunId) == nil
  if self.isLockGun then
    if FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview then
      self.mGunCmdData = NetCmdTeamData:GetGachaPreviewGunData(gunId)
    else
      self.mGunCmdData = NetCmdTeamData:GetLockGunByStcId(gunId)
    end
  else
    self.mGunCmdData = NetCmdTeamData:GetGunByStcId(gunId)
  end
  self.mGunData = self.mGunCmdData.TabGunData
end

function UIChrStageUpPanel:InitRank()
  local tmpTabParent = self.ui.mScrollListChild_Content.transform
  for i = 1, FacilityBarrackGlobal.GetGunMaxGrade() do
    local tabItem = ChrStageUpItemV3.New()
    local callback = function()
      self:OnClickRank(tabItem)
    end
    if i <= tmpTabParent.childCount then
      tabItem:InitCtrl(tmpTabParent.gameObject, i, callback, tmpTabParent:GetChild(i - 1))
    else
      tabItem:InitCtrl(tmpTabParent.gameObject, i, callback)
    end
    table.insert(self.rankList, tabItem)
  end
end

function UIChrStageUpPanel:UpdateRankData()
  self:InitRankItemCost()
  local clothesData = TableDataBase.listClothesDatas:GetDataById(self.mGunCmdData.costume)
  if not clothesData then
    return
  end
  local gunGlobalConfigData = TableDataBase.listGunGlobalConfigDatas:GetDataById(clothesData.model_id)
  local position = UIUtils.SplitStrToVector(gunGlobalConfigData.gun_grade_camera)
  UIModelToucher.SetStageUpVirtualCameraPosition(position)
  local pos = self.stageUpBones:GetStageUpBonesObjPos()
  pos.y = tonumber(gunGlobalConfigData.gun_grade_position)
  self.stageUpBones:SetStageUpBonesObjPos(pos)
  BarrackHelper.CameraMgr:SetAnimTimelinePos()
end

function UIChrStageUpPanel:InitRankItemCost()
  self.itemOwn = NetCmdItemData:GetItemCountById(self.mGunCmdData.TabGunData.core_item_id)
  for i = 1, FacilityBarrackGlobal.GetGunMaxGrade() do
    local isGachaPreview = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview
    local showRedPoint = self.mGunCmdData:GetStageUpItemEnoughRedPoint() > 0 and not isGachaPreview
    self.rankList[i]:SetItemEnough(showRedPoint)
  end
end

function UIChrStageUpPanel:OnClickRank(item)
  if not self.curRank or self.curRank.index == item.index then
  else
    self:ResetCurRankNormal()
  end
  local setItemPressed = function()
    self.stageUpBones:SetAllBonesInteractable(true, false)
    item:SetSelect(false)
    self.stageUpBones:ResetBoneTrigger(item.index - 1, "Normal")
    self.stageUpBones:SetBoneTrigger(item.index - 1, "Pressed")
    self.stageUpBones:SetBoneButtonInteractable(item.index - 1, false)
  end
  if self.curRank == nil then
    if self.cdTimer then
      self.cdTimer:Stop()
      self.cdTimer = nil
    end
    self.stageUpBones:SetAllBonesInteractable(false, false)
    self.cdTimer = TimerSys:DelayCall(1, function()
      setItemPressed()
    end)
  else
    if self.cdTimer then
      self.cdTimer:Stop()
      self.cdTimer = nil
    end
    setItemPressed()
  end
  self.curRank = item
  self:UpdateRankInfo(item)
end

function UIChrStageUpPanel:ResetCurRankNormal()
  if self.curRank == nil then
    return
  end
  self.curRank:SetSelect(true)
  self.stageUpBones:ResetBoneTrigger(self.curRank.index - 1, "Pressed")
  self.stageUpBones:SetBoneTrigger(self.curRank.index - 1, "Normal")
  self.stageUpBones:SetBoneButtonInteractable(self.curRank.index - 1, true)
end

function UIChrStageUpPanel:UpdateRankInfo(item)
  if item then
    self.curItemIndex = item.index
    local gun_grade_id = self.mGunCmdData.grade * 100 + item.index + 1
    local gunGradeData = TableData.listGunGradeDatas:GetDataById(gun_grade_id)
    if item.index > 0 then
      local num = gunGradeData.CostPiece
      local itemOwn = self.itemOwn
      self.isItemEnough = num <= itemOwn
      itemOwn = CS.LuaUIUtils.GetMaxNumberText(itemOwn)
      if not self.isItemEnough then
        self.ui.mText_Num1.text = "<color=#FF5E41>" .. itemOwn .. "</color>/" .. CS.LuaUIUtils.GetMaxNumberText(num)
      else
        self.ui.mText_Num1.text = itemOwn .. "/" .. CS.LuaUIUtils.GetMaxNumberText(num)
      end
    end
    self.ui.mText_Num.text = item.index
    self.ui.mText_Num2.text = TableData.GetHintById(170000 + item.index)
    local skillId = self.mGunCmdData:GetHasReplaceSkill(gunGradeData.abbr[0])
    local skilldata = TableData.listBattleSkillDatas:GetDataById(skillId)
    self.skilldata = skilldata
    self.ui.mText_Name.text = skilldata.name.str
    local skillDetialInfo = self.mGunCmdData:GetPreviewGunUpGradeSkillDetialInfo(item.index)
    local tmpDesc = self.mGunCmdData:FormatSkillDesc(self.skilldata.id, skilldata.upgrade_description.str, skillDetialInfo)
    self.ui.mTextFit_Description.text = tmpDesc
    local elementTag = CS.GF2.Battle.SkillUtils.GetDisplaySkillElement(skilldata.id)
    if elementTag < 0 then
      elementTag = CS.GF2.Battle.SkillUtils.GetSkillElement(skilldata.id)
    end
    setactive(self.ui.mTrans_Element, 0 < elementTag)
    if 0 < elementTag then
      local elementData = TableData.listLanguageElementDatas:GetDataById(elementTag)
      self.ui.mImg_Element.sprite = IconUtils.GetElementIcon(elementData.icon .. "_Weakpoint")
    end
    setactive(self.ui.mTrans_ImgFrame, skilldata.IsPassiveSkill == false)
    if item.index > self.mGunCmdData.upgrade then
      setactive(self.ui.mTrans_ImgArrow.gameObject, true)
      setactive(self.ui.mText_LvAfter.gameObject, true)
      local curSkillId = self.mGunCmdData:GetCurSameSkill(skilldata.id)
      local curSkillData = TableData.listBattleSkillDatas:GetDataById(curSkillId)
      local curSkillLevel = curSkillData.level
      self.ui.mText_LvAfter.text = GlobalConfig.SetLvText(skilldata.Level)
      self.ui.mText_Lv.text = GlobalConfig.SetLvText(curSkillLevel)
    else
      self.ui.mText_Lv.text = GlobalConfig.SetLvText(skilldata.Level)
      setactive(self.ui.mTrans_ImgArrow.gameObject, false)
      setactive(self.ui.mText_LvAfter.gameObject, false)
    end
    self.ui.mTrans_Icon.sprite = IconUtils.GetSkillIconByAttr(skilldata.icon, skilldata.icon_attr_type, self.mGunCmdData == nil and self.mGunCmdData.WeaponDefaultId or self.mGunCmdData.WeaponStcId)
    self:UpdateWeak(skillId)
    if item.index > self.mGunCmdData.upgrade then
      self.ui.mText_Name1.text = string_format(TableData.GetHintById(102106), item.index - 1)
    end
    local isGachaPreview = FacilityBarrackGlobal.CurShowContentType == FacilityBarrackGlobal.ShowContentType.UIGachaPreview
    setactive(self.ui.mTrans_Action.gameObject, not isGachaPreview)
    setactive(self.ui.mTrans_LevelUpConsume, not isGachaPreview)
    if not isGachaPreview then
      setactive(self.ui.mTrans_UnLocked, item.isActivate)
      setactive(self.ui.mTrans_Locked, item.isLock)
      setactive(self.ui.mBtn_OK.gameObject, item.isCanUpgrade)
      setactive(self.ui.mTrans_LevelUpConsume, item.index > self.mGunCmdData.mGun.Grade or item.index == 1 and self.mGunCmdData.mGun.Grade == 0)
      local showRedPoint = 0 < self.mGunCmdData:GetStageUpItemEnoughRedPoint()
      self.canUpgrade = self.isItemEnough and item.isCanUpgrade and not self.isMaxUpgrade
      setactive(self.OkBtnRedPoint.gameObject, self.canUpgrade and showRedPoint)
    end
  end
end

function UIChrStageUpPanel:CheckStageUpBonesNull()
  if CS.UIBarrackModelManager.Instance.IsStageUpBonesNull then
    function CS.UIBarrackModelManager.Instance.StageUpBonesLoadCallback()
      self:InitStageUpBones()
    end
    
    CS.UIBarrackModelManager.Instance:CreateNewStageUpBones()
  else
    self:InitStageUpBones()
  end
end

function UIChrStageUpPanel:InitStageUpBones()
  self.stageUpBones = CS.UIBarrackModelManager.Instance.StageUpBones
  for i, tabItem in ipairs(self.rankList) do
    self.stageUpBones:SetOnClickEvent(i - 1, function()
      self:OnClickRank(tabItem)
    end)
  end
  self.stageUpBones:SetDefaultStars(self.mGunCmdData.upgrade)
  self:SetData()
end

function UIChrStageUpPanel:OnUpgradeClick()
  if self.curRank then
    if self.canUpgrade then
      CS.GF2.Message.MessageSys.Instance:SendMessage(CS.GF2.Message.FacilityBarrackEvent.ShowOrHideMask, true)
      NetCmdTrainGunData:SendCmdUpgradeGun(self.mGunCmdData.id, function(ret)
        if ret == ErrorCodeSuc then
          self:UpgradeCallback()
        else
          CS.GF2.Message.MessageSys.Instance:SendMessage(CS.GF2.Message.FacilityBarrackEvent.ShowOrHideMask, false)
        end
      end)
    elseif not self.isItemEnough then
      FacilityBarrackGlobal.UIChrStageUpCoreId = self.itemData.id
      FacilityBarrackGlobal.SetTargetContentType(self.curContentType)
      TipsPanelHelper.OpenUITipsPanel(self.itemData, 0, true, false, 0, function()
        self:UITipsPanelCloseCallback()
      end)
    end
  end
end

function UIChrStageUpPanel:UITipsPanelCloseCallback()
  FacilityBarrackGlobal.UIChrStageUpCoreId = 0
end

function UIChrStageUpPanel:UpgradeCallback()
  local delayTime = 1.0
  if self.mGunCmdData.maxUpgrade == self.mGunCmdData.upgrade then
    delayTime = 2.0
  end
  local UpgradeEnd = function()
    self.stageUpBones:SetStarState(self.mGunCmdData.upgrade - 1, 2)
    TimerSys:DelayCall(delayTime, function()
      self.isUpgradeBack = true
      UIManager.OpenUIByParam(UIDef.UIChrStageUpDialog, {
        gunCmdData = self.mGunCmdData
      })
      CS.GF2.Message.MessageSys.Instance:SendMessage(CS.GF2.Message.FacilityBarrackEvent.ShowOrHideMask, false)
    end)
    if self.curRank then
      CS.GF2.Message.MessageSys.Instance:SendMessage(CS.GF2.Message.FacilityBarrackEvent.RefreshGun, nil)
    end
  end
  UpgradeEnd()
end

function UIChrStageUpPanel:ResetData()
  self.stageUpBones:SetAllBonesInteractable(false, false)
  self:GetCurGun()
  self:CheckStageUpBonesNull()
  if self.curRank ~= nil then
    self.curRank:SetSelect(true)
  end
  self.curRank = nil
  if self.cdTimer then
    self.cdTimer:Stop()
    self.cdTimer = nil
  end
  self:SetData(true)
end

function UIChrStageUpPanel:UpdateWeak(skillId)
  local parentTrans = self.ui.mTrans_WeaponElement
  local weaponStcId = self.mGunCmdData.WeaponStcId
  local weak = CS.WeakUIUtils.SetSkillWeakWeapon(weaponStcId, skillId, parentTrans, false, 0)
  setactive(parentTrans, weak ~= nil and 0 < weak.Count)
end

function UIChrStageUpPanel:ReLoginSuccess()
  CS.GF2.Message.MessageSys.Instance:SendMessage(CS.GF2.Message.FacilityBarrackEvent.ShowOrHideMask, false)
end

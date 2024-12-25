require("UI.FacilityBarrackPanel.Content.UIChangeSkin.UIBarrackChangeSkinSlot")
require("UI.FacilityBarrackPanel.FacilityBarrackGlobal")
UIBarrackChangeSkinPanel = class("UIBarrackChangeSkinPanel", UIBasePanel)

function UIBarrackChangeSkinPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Is3DPanel = true
  csPanel.UsePool = false
end

function UIBarrackChangeSkinPanel:OnInit(root, data, behaviorId)
  self.ui = UIUtils.GetUIBindTable(root)
  self:SetRoot(root)
  self.isOnclickBack = false
  self.ui.arrow = UIUtils.GetUIBindTable(self.ui.mUIContainer_Arrow)
  setactivewithcheck(self.ui.mBtn_BtnBuy.transform.parent, true)
  setactivewithcheck(self.ui.mBtn_BtnGotoGet.transform.parent, true)
  setactivewithcheck(self.ui.mBtn_BtnChange.transform.parent, true)
  setactive(self.ui.mTrans_TextTips_Top.gameObject, true)
  setactive(self.ui.mTrans_TextTips_Bottom.gameObject, false)
  
  function self.ui.mVirtualList.itemProvider()
    return self:slotProvider()
  end
  
  function self.ui.mVirtualList.itemRenderer(index, renderData)
    self:slotRenderer(index, renderData)
  end
  
  self.ui.mVirtualList:SetConstraintCount(1)
  
  function self.onEndDrag(eventData)
    local value = self.ui.mVirtualList.horizontalNormalizedPosition
    if value < 0 then
      value = 0
    elseif 1 < value then
      value = 1
    end
    local index = math.floor(value * self.ui.mVirtualList.content.sizeDelta.x / (self.ui.mLayoutGroup.spacing.x + self.ui.mVirtualList.paddingWidth) + 0.5) + 1
    self:onClickSlot(index)
  end
  
  self.ui.mVirtualList:AddOnEndDrag(self.onEndDrag)
  setactivewithcheck(self.ui.mAnimator_ViewingMode, false)
  self.ui.mCanvasGroup_GrpRight.blocksRaycasts = true
  local id
  self.mShowClothes = nil
  self.mStoreId = nil
  self.isJumpUI = nil
  FacilityBarrackGlobal.CurSkinShowContentType = FacilityBarrackGlobal.ShowContentType.UIChrOverview
  if data and behaviorId ~= 0 then
    id = data[0]
    if data.Length > 1 then
      FacilityBarrackGlobal.CurSkinShowContentType = data[1]
    end
    if data.Length > 2 then
      self.mShowClothes = data[2]
    end
    if data.Length > 3 then
      self.mStoreId = data[3]
    end
    self.isJumpUI = true
  else
    id = data
  end
  self.addedListener = false
  self.gunCmdData = NetCmdTeamData:GetGunByID(id)
  if FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIBpClothes then
    self.slotTable = self:initBpSlot()
    self.curSlotIndex = 1
    self.gunCmdData = NetCmdTeamData:GetLockGunData(id, true)
  elseif FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIClothesPreview then
    self.gunCmdData = NetCmdTeamData:GetLockGunData(id, true)
    self.slotTable = self:initAllSlot()
    self.curSlotIndex = 1
  else
    if FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIShopClothes and self.gunCmdData == nil then
      self.gunCmdData = NetCmdTeamData:GetLockGunData(id, true)
    end
    self.slotTable = self:initAllSlot()
    if self.mShowClothes ~= nil then
      self.curSlotIndex = self:getSkinSlotIndex()
    else
      self.curSlotIndex = self:getEquippedSkinSlotIndex()
    end
  end
  if 0 >= self.curSlotIndex then
    self.curSlotIndex = 1
  end
  setactive(self.ui.mTrans_Currency, true)
  self.isClickedHome = false
  
  function self.OnBuyCreditCoin()
    self:UpdatePayTypeButton(self.storeData)
  end
  
  function self.OnCloseCommonReceivePanel()
    local toppanel = UISystem:GetTopPanelUI()
    if toppanel ~= nil and toppanel.UIDefine.UIType == UIDef.UIBarrackChangeSkinPanel and self.ui ~= nil and self.mTempClothesData ~= nil then
      self:playChangeClothesAnim(self.mTempClothesData)
      self:refreshGrpBtn()
      self:refreshGunDesc()
      if FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIShopClothes then
        self:UpdateShopShowClothes()
      else
        self.mTempSlot:PlayUnlockingAnim()
      end
    end
  end
  
  MessageSys:AddListener(UIEvent.OnCloseCommonReceivePanel, self.OnCloseCommonReceivePanel)
  MessageSys:AddListener(UIEvent.OnBuyCreditCoin, self.OnBuyCreditCoin)
  FacilityBarrackGlobal.SetVisualOnClick(function()
    self:OnClickVisual(true)
  end)
  FacilityBarrackGlobal.HideEffectNum(false)
  self:AddBtnClickListener()
end

function UIBarrackChangeSkinPanel:AddBtnClickListener()
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnBack.gameObject, function()
    self:onClickBack()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnHome.gameObject, function()
    self:onClickHome()
  end)
  UIUtils.AddBtnClickListener(self.ui.arrow.mBtn_PreGun.gameObject, function()
    self:onClickLeftSkinArrow()
  end)
  UIUtils.AddBtnClickListener(self.ui.arrow.mBtn_NextGun.gameObject, function()
    self:onClickRightSkinArrow()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Item.gameObject, function()
    self:onClickItem()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_GrpConsume.gameObject, function()
    self:onClickConsume()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnGotoGet.gameObject, function()
    self:onClickGotoGet()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnChange.gameObject, function()
    self:onClickChangeClothes()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_SkinInfo.gameObject, function()
    local curSlot = self:getCurSlot()
    local clothesData = curSlot:GetClothesData()
    UIManager.OpenUIByParam(UIDef.UIChrSkinDescriptionDialog, clothesData)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_BtnBuy.gameObject, function()
    self:onClickBuy()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_ExitVisual_TL.gameObject, function()
    self:OnClickVisual(false)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_ExitVisual_TR.gameObject, function()
    self:OnClickVisual(false)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_ExitVisual_BL.gameObject, function()
    self:OnClickVisual(false)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_ExitVisual_BR.gameObject, function()
    self:OnClickVisual(false)
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Appearance.gameObject, function()
    self:onClickAppearance()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Money.gameObject, function()
    self:onClickCostSwitch()
  end)
  UIUtils.AddBtnClickListener(self.ui.mBtn_Cost.gameObject, function()
    self:onClickCostSwitch()
  end)
end

function UIBarrackChangeSkinPanel:OnShowStart()
  local isPlayAnim = FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIShopClothes
  self:refresh(isPlayAnim)
  self:scrollToCurSlotIndex(false)
end

function UIBarrackChangeSkinPanel:OnShowFinish()
  self.isOnclickBack = false
  if self.addedListener then
    return
  end
  self.addedListener = true
  UISystem.BarrackCharacterCameraCtrl:SetEnterLookAtFinishedCallback(function()
    self:EnterVisual()
    gfdebug("UIBarrackChangeSkinPanel EnterVisual")
  end)
  UISystem.BarrackCharacterCameraCtrl:SetExitLookAtFinishedCallback(function()
    self:ExitVisual()
    gfdebug("UIBarrackChangeSkinPanel ExitVisual")
  end)
  
  function self.updateOrient(message)
    self:UpdateOrient(message)
  end
  
  MessageSys:AddListener(CS.GF2.Message.FacilityBarrackModelEvent.CameraOrient, self.updateOrient)
  BarrackHelper.InteractManager:AddListener()
end

function UIBarrackChangeSkinPanel:OnBackFrom()
  SceneSys:SwitchVisible(EnumSceneType.Barrack)
  self:refreshGrpBtn()
  self:refresh(false)
  self:refreshGunDesc()
  self:refreshSwitchArrow()
  self:refreshSwitchSkinArrow()
end

function UIBarrackChangeSkinPanel:OnTop()
  if FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIBpClothes then
    return
  end
  if FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIShopClothes then
    return
  end
end

function UIBarrackChangeSkinPanel:OnHide()
  if self.updateOrient ~= nil then
    MessageSys:RemoveListener(CS.GF2.Message.FacilityBarrackModelEvent.CameraOrient, self.updateOrient)
    self.updateOrient = nil
  end
  BarrackHelper.InteractManager:RemoveListener()
end

function UIBarrackChangeSkinPanel:OnRecover()
  local gunId = BarrackHelper.ModelMgr.GunStcDataId
  self:OnInit(nil, gunId)
end

function UIBarrackChangeSkinPanel:OnClose()
  BarrackHelper.ModelMgr:RevertClothes(self.gunCmdData.id)
  BarrackHelper.ModelMgr:DestroyChangeClothesEffect()
  if FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIClothesPreview then
    SceneSys:SwitchVisible(EnumSceneType.HallScene)
  end
  if FacilityBarrackGlobal.CurSkinShowContentType ~= FacilityBarrackGlobal.ShowContentType.UIChrOverview then
    BarrackHelper.ModelMgr:RevertClothes()
    gfdebug("[Barrack] \233\157\158\230\149\180\229\164\135\229\174\164\232\191\155\229\133\165\231\154\132\232\175\149\231\169\191  \229\133\179\233\151\173\231\149\140\233\157\162\230\151\182\232\166\129\229\133\168\233\131\168\232\191\152\229\142\159\229\155\158\229\142\187 RevertClothes")
    local isOpen = UISystem:PanelIsOpen(UIDef.UIChrPowerUpPanel)
    if not isOpen then
      CS.UIBarrackModelManager.Instance:ResetGunStcDataId()
      gfdebug("[Barrack] \233\157\158\230\149\180\229\164\135\229\174\164\232\191\155\229\133\165\231\154\132\232\175\149\231\169\191  \229\133\179\233\151\173\231\149\140\233\157\162\230\151\182\232\166\129\229\133\168\233\131\168\232\191\152\229\142\159\229\155\158\229\142\187 ResetGunStcDataId")
    end
  else
    BarrackHelper.ModelMgr:RevertGunModel()
    gfdebug("[Barrack] \230\149\180\229\164\135\229\174\164\232\191\155\229\133\165\231\154\132\232\175\149\231\169\191  \232\191\152\229\142\159\229\136\176\229\189\147\229\137\141\228\186\186\229\189\162\231\154\132\233\187\152\232\174\164\231\154\174\232\130\164")
  end
  MessageSys:RemoveListener(UIEvent.OnCloseCommonReceivePanel, self.OnCloseCommonReceivePanel)
  MessageSys:RemoveListener(UIEvent.OnBuyCreditCoin, self.OnBuyCreditCoin)
  self.gunCmdData = nil
  self.isClickedHome = nil
  self.curSlotIndex = nil
  self.payType = nil
  self:ReleaseCtrlTable(self.slotTable, false)
  self.slotTable = nil
  self.isJumpUI = nil
  UISystem.BarrackCharacterCameraCtrl:SetEnterLookAtFinishedCallback(nil)
  UISystem.BarrackCharacterCameraCtrl:SetExitLookAtFinishedCallback(nil)
end

function UIBarrackChangeSkinPanel:OnRelease()
  self.ui.mVirtualList:RemoveOnEndDrag(self.onEndDrag)
  self.gunCmdData = nil
  self.ui = nil
  self.super.OnRelease(self)
end

function UIBarrackChangeSkinPanel:OnCameraStart()
  if FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrOverview then
    return 0.01
  end
  return 0
end

function UIBarrackChangeSkinPanel:OnCameraBack()
  if self.isOnclickBack then
    return 0.01
  else
    return 0
  end
end

function UIBarrackChangeSkinPanel:refresh(needGunClothesAnim)
  self.ui.mVirtualList.numItems = #self.slotTable
  self.ui.mVirtualList:Refresh()
  self:refreshModel(needGunClothesAnim)
  self:refreshGrpBtn()
  self:refreshGunDesc()
  self:refreshSwitchArrow()
  self:refreshSwitchSkinArrow()
  if FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIShopClothes then
    self.ui.mText_Title.text = TableData.GetHintById(260039)
  elseif FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIClothesPreview then
    self.ui.mText_Title.text = TableData.GetHintById(260039)
    self:UpdateClothesPreview()
  else
    self.ui.mText_Title.text = TableData.GetHintById(230006)
  end
  if FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIBpClothes then
    self:UpdateBpClothes()
    self.ui.mText_Title.text = TableData.GetHintById(260039)
  end
end

function UIBarrackChangeSkinPanel:initAllSlot()
  local tempSlotTable = {}
  local gunData = TableDataBase.listGunDatas:GetDataById(self.gunCmdData.id)
  local tempTable = CSList2LuaTable(gunData.costume_replace)
  table.sort(tempTable, function(l, r)
    local skinCountL = NetCmdIllustrationData:GetCountByTypeAndItemId(tonumber(GlobalConfig.ItemType.Costume), l)
    local skinCountR = NetCmdIllustrationData:GetCountByTypeAndItemId(tonumber(GlobalConfig.ItemType.Costume), r)
    local clothesDataL = TableDataBase.listClothesDatas:GetDataById(l)
    local clothesDataR = TableDataBase.listClothesDatas:GetDataById(r)
    if skinCountL ~= skinCountR then
      return skinCountL > skinCountR
    else
      return clothesDataL.order < clothesDataR.order
    end
  end)
  local curBPId = NetCmdBattlePassData:GetCurOrRecentBpId()
  if FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIClothesPreview then
    local d = TableDataBase.listClothesDatas:GetDataById(self.mShowClothes)
    local skinCount = NetCmdIllustrationData:GetCountByTypeAndItemId(tonumber(GlobalConfig.ItemType.Costume), tonumber(self.mShowClothes))
    local isExistStore = false
    if d.unlock_type == 3 then
      local storeId = tonumber(d.unlock_arg)
      local storeData = NetCmdStoreData:GetStoreGoodsById(storeId)
      if storeData ~= nil then
        isExistStore = storeData.IsShowTime
      end
    end
    if d.display_config > 0 or d.display_config == 0 and (isExistStore or 0 < skinCount) then
      local bpID
      if d.display_config == 2 then
        bpID = curBPId
      end
      if bpID == nil or bpID >= d.display_arg then
        local slot = UIBarrackChangeSkinSlot.New()
        slot:SetData(self.gunCmdData, d, 1)
        slot:AddBtnClickListener(function(tempIndex)
          self:onClickSlot(tempIndex)
        end)
        table.insert(tempSlotTable, slot)
      end
    end
  else
    local index = 1
    for i, clothesId in ipairs(tempTable) do
      local d = TableDataBase.listClothesDatas:GetDataById(clothesId)
      local skinCount = NetCmdIllustrationData:GetCountByTypeAndItemId(tonumber(GlobalConfig.ItemType.Costume), tonumber(clothesId))
      local isExistStore = false
      if d.unlock_type == 3 then
        local storeId = tonumber(d.unlock_arg)
        local storeData = NetCmdStoreData:GetStoreGoodsById(storeId)
        if storeData ~= nil then
          isExistStore = storeData.IsShowTime
        end
      end
      if d.display_config > 0 or d.display_config == 0 and (isExistStore or 0 < skinCount) then
        local bpID
        if d.display_config == 2 then
          bpID = curBPId
        end
        if bpID == nil or bpID >= d.display_arg then
          local slot = UIBarrackChangeSkinSlot.New()
          slot:SetData(self.gunCmdData, d, index)
          slot:AddBtnClickListener(function(tempIndex)
            self:onClickSlot(tempIndex)
          end)
          table.insert(tempSlotTable, slot)
          index = index + 1
        end
      end
    end
  end
  return tempSlotTable
end

function UIBarrackChangeSkinPanel:initBpSlot()
  local tempSlotTable = {}
  if self.mShowClothes == nil then
    return
  end
  local d = TableDataBase.listClothesDatas:GetDataById(self.mShowClothes)
  local skinCount = NetCmdIllustrationData:GetCountByTypeAndItemId(tonumber(GlobalConfig.ItemType.Costume), tonumber(self.mShowClothes))
  local isExistStore = false
  if d.unlock_type == 3 then
    local storeId = tonumber(d.unlock_arg)
    local storeData = NetCmdStoreData:GetStoreGoodsById(storeId)
    if storeData ~= nil then
      isExistStore = storeData.IsShowTime
    end
  end
  if d.display_config > 0 or d.display_config == 0 and (isExistStore or 0 < skinCount) then
    local bpID
    if bpID == nil or bpID >= d.display_arg then
      local slot = UIBarrackChangeSkinSlot.New()
      slot:SetData(self.gunCmdData, d, 1)
      table.insert(tempSlotTable, slot)
    end
  end
  return tempSlotTable
end

function UIBarrackChangeSkinPanel:initShopShowSlot()
  local tempSlotTable = {}
  if self.mShowClothes == nil then
    return
  end
  local d = TableDataBase.listClothesDatas:GetDataById(self.mShowClothes)
  local skinCount = NetCmdIllustrationData:GetCountByTypeAndItemId(tonumber(GlobalConfig.ItemType.Costume), tonumber(self.mShowClothes))
  local isExistStore = false
  if d.unlock_type == 3 then
    local storeId = tonumber(d.unlock_arg)
    local storeData = NetCmdStoreData:GetStoreGoodsById(storeId)
    if storeData ~= nil then
      isExistStore = storeData.IsShowTime
    end
  end
  if d.display_config > 0 or d.display_config == 0 and (isExistStore or 0 < skinCount) then
    local bpID
    if bpID == nil or bpID >= d.display_arg then
      local slot = UIBarrackChangeSkinSlot.New()
      slot:SetData(self.gunCmdData, d, 1)
      table.insert(tempSlotTable, slot)
    end
  end
  return tempSlotTable
end

function UIBarrackChangeSkinPanel:UpdateBpClothes()
  setactive(self.ui.mTrans_BPToGet, false)
  setactive(self.ui.mTrans_BpLocked.transform, false)
  setactive(self.ui.mTrans_BPHasReceied, false)
  setactive(self.ui.mBtn_Receive.transform.parent, false)
  setactive(self.ui.mTrans_Buy, false)
  setactive(self.ui.mTrans_Switch, false)
  setactivewithcheck(self.ui.mBtn_BtnChange, false)
  if FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIBpClothes then
    setactivewithcheck(self.ui.mTrans_Bp, true)
    setactivewithcheck(self.ui.mTrans_Skin, false)
    setactive(self.ui.mTrans_RedText, false)
    setactive(self.ui.mTrans_Currency, false)
    local status = NetCmdBattlePassData.BattlePassStatus
    local isBuyBp = status == CS.ProtoObject.BattlepassType.AdvanceTwo or status == CS.ProtoObject.BattlepassType.AdvanceOne
    local isFullBpLevel = NetCmdBattlePassData.BattlePassLevel == NetCmdBattlePassData.CurSeason.max_level
    setactive(self.ui.mTrans_BPToGet, isBuyBp and not isFullBpLevel)
    setactive(self.ui.mTrans_BpLocked.transform, not isBuyBp)
    local isMaxRewardGet = NetCmdBattlePassData.IsMaxRewardGet
    setactive(self.ui.mTrans_BPHasReceied, isFullBpLevel and isMaxRewardGet)
    setactive(self.ui.mBtn_Receive.transform.parent, isFullBpLevel and not isMaxRewardGet and isBuyBp)
    setactive(self.ui.mBtn_Receive, isFullBpLevel and not isMaxRewardGet and isBuyBp)
    UIUtils.GetButtonListener(self.ui.mBtn_Receive.gameObject).onClick = function()
      NetCmdBattlePassData:SendGetBattlepassReward(NetCmdBattlePassData.BattlePassStatus, NetCmdBattlePassData.CurSeason.MaxLevel, CS.ProtoCsmsg.BpRewardGetType.GetTypeNone, function(ret)
        if ret == ErrorCodeSuc then
          MessageSys:SendMessage(UIEvent.BpGetReward, nil)
          UISystem:OpenCommonReceivePanel()
          self:UpdateBpClothes()
        end
      end)
    end
  end
end

function UIBarrackChangeSkinPanel:UpdateClothesPreview()
  if FacilityBarrackGlobal.CurSkinShowContentType ~= FacilityBarrackGlobal.ShowContentType.UIClothesPreview then
    return
  end
  setactivewithcheck(self.ui.mTrans_Buy, false)
  setactivewithcheck(self.ui.mTrans_Switch, false)
  setactivewithcheck(self.ui.mTrans_GreenText, false)
  setactivewithcheck(self.ui.mTrans_Have, NetCmdIllustrationData:CheckIndexDetailUnlock(13, self.mShowClothes))
  setactivewithcheck(self.ui.mTrans_RedText, not NetCmdIllustrationData:CheckIndexDetailUnlock(13, self.mShowClothes))
  setactivewithcheck(self.ui.mBtn_BtnGotoGet, false)
  setactivewithcheck(self.ui.mBtn_BtnChange, false)
  local curSlot = self:getCurSlot()
  local clothesData = curSlot:GetClothesData()
  self.ui.mText_RedText.text = clothesData.unlock_description.str
end

function UIBarrackChangeSkinPanel:UpdateShopShowClothes()
  if FacilityBarrackGlobal.CurSkinShowContentType ~= FacilityBarrackGlobal.ShowContentType.UIShopClothes then
    return
  end
  setactivewithcheck(self.ui.mTrans_Bp, false)
  setactivewithcheck(self.ui.mTrans_Skin, true)
  setactive(self.ui.mTrans_RedText, false)
  setactive(self.ui.mTrans_Buy, true)
  setactivewithcheck(self.ui.mTrans_Switch, true)
  local curSlot = self:getCurSlot()
  local clothesData = curSlot:GetClothesData()
  local storeId = tonumber(clothesData.unlock_arg)
  local storeData = NetCmdStoreData:GetStoreGoodsById(storeId)
  if storeData == nil then
    return
  end
  local itemId = storeData.ItemNumList[0].itemid
  local itemData = TableData.GetItemData(itemId)
  if itemData == nil then
    return
  end
  local clothesData = TableDataBase.listClothesDatas:GetDataById(itemData.args[0])
  setactive(self.ui.mBtn_Appearance.transform.parent.parent, 0 < clothesData.clothes_duty.Count)
  self.mSkinCount = NetCmdIllustrationData:GetCountByTypeAndItemId(tonumber(GlobalConfig.ItemType.Costume), tonumber(itemData.args[0]))
  self.ui.mText_Cost.text = storeData.show_price
  self.ui.mText_Money.text = storeData:GetStoreGoodData().currency_symbol .. " " .. storeData.show_price_2
  if storeData.IsDiscount then
    self.ui.mText_Cost.color = CS.UIStoreGlobal.DiscountPriceColor
  else
    self.ui.mText_Cost.color = ColorUtils.WhiteColor
  end
  if storeData.IsDiscount_2 then
    self.ui.mText_Money.color = CS.UIStoreGlobal.DiscountPriceColor
  else
    self.ui.mText_Money.color = ColorUtils.WhiteColor
  end
  local payByMoney = storeData.price_type_2 == 0 and 0 < storeData.price_2
  setactive(self.ui.mBtn_Money, payByMoney)
  if payByMoney then
    self.payType = self.payType or 0
  else
    self.payType = self.payType or storeData.price_type
  end
  self:UpdatePayTypeButton(storeData)
  IconUtils.GetItemIconSpriteAsync(storeData.price_type, self.ui.mImage_Item)
  local haveCount = NetCmdItemData:GetItemCount(storeData.price_type)
  local n1, n2 = math.modf(storeData.price)
  setactive(self.ui.mText_BeforeText, false)
  if storeData.IsDiscount and storeData.price ~= storeData.base_price then
    setactive(self.ui.mText_BeforeText, true)
    self.ui.mText_BeforeText.text = FormatNum(storeData.base_price)
  end
  setactivewithcheck(self.ui.mBtn_Item, true)
  setactivewithcheck(self.ui.mTrans_Buy, self.mSkinCount == 0)
  setactivewithcheck(self.ui.mTrans_Switch, self.mSkinCount == 0)
  setactivewithcheck(self.ui.mTrans_Have, self.mSkinCount ~= 0)
end

function UIBarrackChangeSkinPanel:UpdatePayTypeButton(storeData)
  if self.payType == nil or storeData == nil then
    return
  end
  self.storeData = storeData
  self.ui.mBtn_Money.interactable = self.payType ~= 0
  self.ui.mBtn_Cost.interactable = self.payType == 0
  setactive(self.ui.mTrans_Credit, self.payType ~= 0)
  if self.payType == 0 then
    self.ui.mAnimator_Money:SetTrigger("Disabled")
    self.ui.mAnimator_Cost:SetTrigger("Normal")
    setactive(self.ui.mText_BasePrice, storeData.IsDiscount_2)
    self.ui.mText_Price.text = storeData:GetStoreGoodData().currency_symbol .. " " .. storeData.show_price_2
    self.ui.mText_BasePrice.text = storeData.show_base_price_2
    self.ui.mText_Price.color = ColorUtils.BlackColor
  else
    self.ui.mAnimator_Money:SetTrigger("Normal")
    self.ui.mAnimator_Cost:SetTrigger("Disabled")
    setactive(self.ui.mText_BasePrice, storeData.IsDiscount)
    self.ui.mText_Price.text = storeData.price
    self.ui.mText_BasePrice.text = storeData.base_price
    if NetCmdItemData:GetItemCount(storeData.price_type) < storeData.price then
      self.ui.mText_Price.color = ColorUtils.RedColor
    else
      self.ui.mText_Price.color = ColorUtils.BlackColor
    end
  end
end

function UIBarrackChangeSkinPanel:onClickSlot(slotIndex)
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
  local prevSlotIndex = self.curSlotIndex
  self.curSlotIndex = slotIndex
  self:onSwitchedSelectSlotAfter(prevSlotIndex, self.curSlotIndex)
end

function UIBarrackChangeSkinPanel:onSwitchedSelectSlotAfter(prevSlotIndex, curSlotIndex)
  self:refresh(true)
  self:scrollToCurSlotIndex(true)
  local curSlot = self:getCurSlot()
  local clothesData = curSlot:GetClothesData()
  if curSlot:IsUnlock() then
    NetCmdGunClothesData:SetPreviewedRecord(clothesData.id)
  end
end

function UIBarrackChangeSkinPanel:scrollToCurSlotIndex(isSmooth)
  self:scrollTo(self.curSlotIndex, isSmooth)
end

function UIBarrackChangeSkinPanel:scrollTo(index, isSmooth)
  if not index then
    return
  end
  local targetIndex = index - 1
  if targetIndex < 0 then
    targetIndex = 0
  end
  self.ui.mVirtualList:ScrollTo(targetIndex, isSmooth, nil, ScrollAlign.Start)
end

function UIBarrackChangeSkinPanel:getCurSlot()
  return self.slotTable[self.curSlotIndex]
end

function UIBarrackChangeSkinPanel:refreshModel(needGunClothesAnim)
  local curSlot = self:getCurSlot()
  local clothesData = curSlot:GetClothesData()
  FacilityBarrackGlobal.HideEffectNum(false)
  BarrackHelper.ModelMgr:ChangeClothes(self.gunCmdData, clothesData.id, function()
    BarrackHelper.ModelMgr.curModel:Show(true)
    FacilityBarrackGlobal.HideEffectNum(true)
    if not needGunClothesAnim then
      return
    end
    self:playChangeClothesAnim(clothesData)
    BarrackHelper.ModelMgr:PlayChangeClothesEffect()
  end)
end

function UIBarrackChangeSkinPanel:refreshGrpBtn()
  setactivewithcheck(self.ui.mBtn_Item, false)
  setactivewithcheck(self.ui.mBtn_BtnReceive, false)
  setactivewithcheck(self.ui.mTrans_Buy, false)
  setactivewithcheck(self.ui.mTrans_Switch, false)
  setactivewithcheck(self.ui.mBtn_BtnGotoGet, false)
  setactivewithcheck(self.ui.mBtn_BtnChange, false)
  setactivewithcheck(self.ui.mTrans_RedText, false)
  setactivewithcheck(self.ui.mTrans_GreenText, false)
  setactivewithcheck(self.ui.mTrans_Have, false)
  local curSlot = self:getCurSlot()
  local clothesData = curSlot:GetClothesData()
  setactivewithcheck(self.ui.mBtn_Appearance.transform.parent.parent, clothesData.clothes_duty.Count > 0)
  local isFocusEquipped = curSlot:GetClothesId() == self.gunCmdData.OriginCostume
  if isFocusEquipped then
    setactivewithcheck(self.ui.mTrans_GreenText, true)
    return
  end
  local cmdData = NetCmdTeamData:GetGunByID(self.gunCmdData.id)
  if clothesData.unlock_type == 1 then
    setactivewithcheck(self.ui.mBtn_BtnChange, cmdData ~= nil)
    setactivewithcheck(self.ui.mTrans_Have, cmdData == nil)
  elseif clothesData.unlock_type == 2 then
    local isUnlock = curSlot:IsUnlock()
    if isUnlock then
      setactivewithcheck(self.ui.mBtn_BtnChange, cmdData ~= nil)
      setactivewithcheck(self.ui.mTrans_Have, cmdData == nil)
    else
      self.ui.mText_RedText.text = clothesData.unlock_description.str
      setactivewithcheck(self.ui.mTrans_RedText, true)
    end
  elseif clothesData.unlock_type == 3 then
    local isUnlock = curSlot:IsUnlock()
    if isUnlock then
      setactivewithcheck(self.ui.mBtn_BtnChange, cmdData ~= nil)
      setactivewithcheck(self.ui.mTrans_Have, cmdData == nil)
    else
      local storeId = tonumber(clothesData.unlock_arg)
      local storeData = NetCmdStoreData:GetStoreGoodsById(storeId)
      if not storeData then
        return
      end
      IconUtils.GetItemIconSpriteAsync(storeData.price_type, self.ui.mImage_Item)
      local haveCount = NetCmdItemData:GetItemCount(storeData.price_type)
      local n1, n2 = math.modf(tonumber(storeData.price))
      self.ui.mText_Cost.text = storeData.show_price
      self.ui.mText_Money.text = storeData:GetStoreGoodData().currency_symbol .. " " .. storeData.show_price_2
      if storeData.IsDiscount then
        self.ui.mText_Cost.color = CS.UIStoreGlobal.DiscountPriceColor
      else
        self.ui.mText_Cost.color = ColorUtils.WhiteColor
      end
      if storeData.IsDiscount_2 then
        self.ui.mText_Money.color = CS.UIStoreGlobal.DiscountPriceColor
      else
        self.ui.mText_Money.color = ColorUtils.WhiteColor
      end
      local payByMoney = storeData.price_type_2 == 0 and 0 < storeData.price_2
      setactive(self.ui.mBtn_Money, payByMoney)
      if payByMoney then
        self.payType = self.payType or 0
      else
        self.payType = self.payType or storeData.price_type
      end
      self:UpdatePayTypeButton(storeData)
      setactive(self.ui.mText_BeforeText, false)
      if storeData.IsDiscount and storeData.price ~= storeData.base_price then
        setactive(self.ui.mText_BeforeText, true)
        self.ui.mText_BeforeText.text = FormatNum(storeData.base_price)
      end
      setactivewithcheck(self.ui.mBtn_Item, true)
      setactivewithcheck(self.ui.mTrans_Buy, true)
      setactivewithcheck(self.ui.mTrans_Switch, true)
    end
  elseif clothesData.unlock_type == 4 then
    local isUnlock = curSlot:IsUnlock()
    if isUnlock then
      setactivewithcheck(self.ui.mBtn_BtnChange, cmdData ~= nil)
      setactivewithcheck(self.ui.mTrans_Have, cmdData == nil)
    else
      setactivewithcheck(self.ui.mBtn_BtnGotoGet, true)
    end
  elseif clothesData.unlock_type == 5 then
    self.ui.mText_RedText.text = clothesData.unlock_description.str
    setactivewithcheck(self.ui.mTrans_RedText, true)
  end
end

function UIBarrackChangeSkinPanel:refreshGunDesc()
  if not self.gunCmdData then
    return
  end
  local curSlot = self:getCurSlot()
  if not curSlot then
    return
  end
  local clothesData = curSlot:GetClothesData()
  if not clothesData then
    return
  end
  self.ui.mText_ChrName.text = self.gunCmdData.gunData.name.str
  self.ui.mText_SkinName.text = clothesData.name.str
  self.ui.mImage_QualityLine.color = TableData.GetGlobalGun_Quality_Color2(clothesData.rare)
  self.ui.mText_SkinDesc.text = clothesData.description.str
  setactive(self.ui.mTrans_Several, clothesData.clothes_type == 1)
  setactive(self.ui.mTrans_All, clothesData.clothes_type == 2)
end

function UIBarrackChangeSkinPanel:playChangeClothesAnim(clothesData)
  local gunGlobalConfigData = TableDataBase.listGunGlobalConfigDatas:GetDataById(clothesData.model_id)
  local barrackFormationData
  if self.gunCmdData:IsPrivateWeapon() then
    barrackFormationData = TableDataBase.listBarrackFormationDatas:GetDataById(gunGlobalConfigData.barrack_formation_exclusive)
  else
    local isEqualToPrivateWeaponModelType = self.gunCmdData:IsPrivateSameWeapon()
    if not isEqualToPrivateWeaponModelType then
      barrackFormationData = TableDataBase.listBarrackFormationDatas:GetDataById(gunGlobalConfigData.barrack_formation_normal01)
    else
      barrackFormationData = TableDataBase.listBarrackFormationDatas:GetDataById(gunGlobalConfigData.barrack_formation_normal02)
    end
  end
  if not barrackFormationData then
    return
  end
  BarrackHelper.InteractManager:StopTimeline(false)
  if #barrackFormationData.changeclothes > 0 then
    BarrackHelper.ModelMgr:ChangeChrAnim(CS.ChrAnimTriggerType.BarrackChangeClothes)
    BarrackHelper.ModelMgr.curModel:ShowEffect(false)
    BarrackHelper.ModelMgr.curModel:ShowEffect(true)
  else
    BarrackHelper.TimelineMgr:PlayTimeline(barrackFormationData.changeclothes_timeline)
  end
end

function UIBarrackChangeSkinPanel:refreshSwitchArrow()
  local gunCmdData = self:getValidGunCmdData(self.gunCmdData.id, true, 1, NetCmdTeamData.GunCount)
  setactivewithcheck(self.ui.mBtn_RightArrow, gunCmdData ~= nil)
  setactivewithcheck(self.ui.mBtn_LeftArrow, gunCmdData ~= nil)
end

function UIBarrackChangeSkinPanel:refreshSwitchSkinArrow()
  setactivewithcheck(self.ui.arrow.mBtn_PreGun, self.curSlotIndex > 1)
  setactivewithcheck(self.ui.arrow.mBtn_NextGun, self.curSlotIndex < #self.slotTable)
end

function UIBarrackChangeSkinPanel:onClickLeftSkinArrow()
  local targetSlotIndex = self.curSlotIndex - 1
  self:onClickSlot(targetSlotIndex)
end

function UIBarrackChangeSkinPanel:onClickRightSkinArrow()
  local targetSlotIndex = self.curSlotIndex + 1
  self:onClickSlot(targetSlotIndex)
end

function UIBarrackChangeSkinPanel:onClickLeftArrow()
  if NetCmdTeamData.GunCount <= 1 then
    return
  end
  local gunCmdData = self:getValidGunCmdData(self.gunCmdData.id, false, 1, NetCmdTeamData.GunCount)
  if not gunCmdData or gunCmdData.GunId == self.gunCmdData.id then
    return
  end
  self.ui.mAnimator:SetTrigger("Previous")
  FacilityBarrackGlobal.SetNeedBarrackEntrance(false)
  BarrackHelper.ModelMgr:SwitchGunModel(gunCmdData, function()
    self:onSwitchedModel()
  end)
  self.ui.mVirtualList.numItems = 0
  self:OnInit(nil, gunCmdData.GunId)
  self:refresh(false)
  self:scrollToCurSlotIndex(false)
end

function UIBarrackChangeSkinPanel:onClickRightArrow()
  if NetCmdTeamData.GunCount <= 1 then
    return
  end
  local gunCmdData = self:getValidGunCmdData(self.gunCmdData.id, true, 1, NetCmdTeamData.GunCount)
  if not gunCmdData or gunCmdData.GunId == self.gunCmdData.id then
    return
  end
  self.ui.mAnimator:SetTrigger("Next")
  FacilityBarrackGlobal.SetNeedBarrackEntrance(false)
  BarrackHelper.ModelMgr:SwitchGunModel(gunCmdData, function()
    self:onSwitchedModel()
  end)
  self.ui.mVirtualList.numItems = 0
  self:OnInit(nil, gunCmdData.GunId)
  self:refresh(false)
  self:scrollToCurSlotIndex(false)
end

function UIBarrackChangeSkinPanel:onSwitchedModel()
  BarrackHelper.ModelMgr.curModel:Show(true)
  BarrackHelper.ModelMgr:ChangeChrAnim("BarrackIdle")
  BarrackHelper.ModelMgr:PlayChangeGunEffect()
end

function UIBarrackChangeSkinPanel:getValidGunCmdData(gunId, isNext, itorCount, allGunCount)
  if allGunCount < itorCount then
    return nil
  end
  local gunCmdData = NetCmdTeamData:GetOtherGunById(gunId, isNext)
  if gunCmdData.id == gunId then
    return nil
  end
  return gunCmdData
end

function UIBarrackChangeSkinPanel:EnterVisual()
  self.isEnterVisual = true
  UISystem.BarrackCharacterCameraCtrl:AttachChrTouchCtrlEvents()
  setactivewithcheck(UISystem.UITouchPad, true)
end

function UIBarrackChangeSkinPanel:ExitVisual()
  self.isEnterVisual = false
  UISystem.BarrackCharacterCameraCtrl:DetachChrTouchCtrlEvents()
  setactivewithcheck(UISystem.UITouchPad, false)
  BarrackHelper.InteractManager:OnVisualCameraChanged(false)
  self.ui.mCanvasGroup_GrpRight.blocksRaycasts = true
  FacilityBarrackGlobal.HideEffectNum(true)
end

function UIBarrackChangeSkinPanel:OnClickVisual(enable)
  if enable == self.isViewingMode then
    return
  end
  if not enable and BarrackHelper.InteractManager:IsPlaying() or not UISystem.BarrackCharacterCameraCtrl:IsInteractiveCameraBlendFinished() then
    local str = TableData.GetHintById(102274)
    CS.PopupMessageManager.PopupString(str)
    return
  end
  self.isViewingMode = enable
  BarrackHelper.InteractManager:SetVisualState(enable)
  local touchPad = UISystem.UITouchPad
  if enable then
    function touchPad.PointerDownHandler(eventData)
      BarrackHelper.InteractManager:PlayTouchEffect(eventData)
    end
    
    FacilityBarrackGlobal.HideEffectNum()
    UISystem.BarrackCharacterCameraCtrl:EnterLookAt()
    BarrackHelper.InteractManager:OnVisualCameraChanged(true)
    self.ui.mCanvasGroup_GrpRight.blocksRaycasts = false
  else
    touchPad.PointerDownHandler = nil
    UISystem.BarrackCharacterCameraCtrl:ExitLookAt()
  end
  setactivewithcheck(self.ui.mAnimator_ViewingMode, self.isViewingMode)
  setactivewithcheck(self.ui.mTrans_TextTips_Top.gameObject, true)
  if self.isViewingMode then
    self.ui.mAnimator:SetTrigger("FadeOut")
    self.ui.mAnimator_ViewingMode:SetTrigger("FadeIn")
  else
    self.ui.mAnimator:SetTrigger("FadeIn")
    self.ui.mAnimator_ViewingMode:SetTrigger("FadeOut")
  end
end

function UIBarrackChangeSkinPanel:onClickAppearance()
  local storeData
  local curSlot = self:getCurSlot()
  local clothesData = curSlot:GetClothesData()
  local storeId = tonumber(clothesData.unlock_arg)
  storeData = NetCmdStoreData:GetStoreGoodsById(storeId)
  if storeData == nil then
    return
  end
  CS.UIStoreGlobal.OpenSkinAppearance(storeData)
end

function UIBarrackChangeSkinPanel:onClickCostSwitch()
  if self.payType == nil then
    return
  end
  local storeData
  local curSlot = self:getCurSlot()
  local clothesData = curSlot:GetClothesData()
  local storeId = tonumber(clothesData.unlock_arg)
  storeData = NetCmdStoreData:GetStoreGoodsById(storeId)
  if storeData == nil then
    return
  end
  if self.payType == 0 then
    self.payType = storeData.price_type
  else
    self.payType = 0
  end
  self:UpdatePayTypeButton(storeData)
end

function UIBarrackChangeSkinPanel:OnEscClick()
  self:onClickBack()
end

function UIBarrackChangeSkinPanel:slotProvider()
  local skinCardTemplate = self.ui.mScrollListChild_SkinCard.childItem
  local slotTrans = UIUtils.InstantiateByTemplate(skinCardTemplate, self.ui.mScrollListChild_SkinCard.transform)
  slotTrans.position = vectorone * 1000
  local renderDataItem = RenderDataItem()
  renderDataItem.renderItem = slotTrans.gameObject
  renderDataItem.data = nil
  return renderDataItem
end

function UIBarrackChangeSkinPanel:slotRenderer(index, renderData)
  local slot = self.slotTable[index + 1]
  local go = renderData.renderItem
  slot:SetRoot(go.transform)
  slot:SetInteractable(slot:GetIndex() ~= self.curSlotIndex)
  slot:SetSelect(slot:GetClothesId() == self.gunCmdData.costume)
  if FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIBpClothes or FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIShopClothes then
    slot:PlayUnlockingAnim()
    slot:RefreshInfo()
  else
    slot:Refresh()
  end
end

function UIBarrackChangeSkinPanel:getSkinSlotIndex()
  for i, slot in ipairs(self.slotTable) do
    if slot:GetClothesId() == self.mShowClothes then
      return slot:GetIndex()
    end
  end
  return -1
end

function UIBarrackChangeSkinPanel:getEquippedSkinSlotIndex()
  for i, slot in ipairs(self.slotTable) do
    if slot:GetClothesId() == self.gunCmdData.costume then
      return slot:GetIndex()
    end
  end
  return -1
end

function UIBarrackChangeSkinPanel:onClickChangeClothes()
  local curSlot = self:getCurSlot()
  local clothesData = curSlot:GetClothesData()
  NetCmdGunClothesData:SendChangeCostumeCmd(self.gunCmdData.id, clothesData.id, function(ret)
    if ret ~= ErrorCodeSuc then
      return
    end
    local text = TableData.GetHintById(230009)
    PopupMessageManager.PopupPositiveString(text)
    self:refresh(false)
  end)
end

function UIBarrackChangeSkinPanel:onClickGotoGet()
  local curSlot = self:getCurSlot()
  local clothesData = curSlot:GetClothesData()
  local jumpId = tonumber(clothesData.unlock_arg)
  UISystem:JumpByID(jumpId)
end

function UIBarrackChangeSkinPanel:onClickBuy()
  self:ToBuy()
end

function UIBarrackChangeSkinPanel:ToBuy()
  local curSlot = self:getCurSlot()
  self.mTempSlot = curSlot
  local clothesData = curSlot:GetClothesData()
  self.mTempClothesData = clothesData
  local storeId = tonumber(clothesData.unlock_arg)
  local storeData = NetCmdStoreData:GetStoreGoodsById(storeId)
  if not storeData then
    return
  end
  if self.payType == nil then
    return
  end
  if self.payType == 0 then
    NetCmdStoreData:SendStoreOrder(storeData.id, 0, function(ret)
      if ret ~= ErrorCodeSuc then
        return
      end
      UISystem:OpenCommonReceivePanel()
    end)
    return
  end
  local haveNum = NetCmdItemData:GetItemCount(self.payType)
  local title = TableData.GetHintById(230010)
  local gunName = self.gunCmdData.TabGunData.FirstName.str
  local clothesName = clothesData.name.str
  local gunRank = self.gunCmdData.TabGunData.rank
  local clothesRank = clothesData.Rare
  local gunColorHex = "#" .. CS.Utage.ColorUtil.ToColorString(TableData.GetGlobalGun_Quality_Color2(gunRank))
  local clothesColorHex = "#" .. CS.Utage.ColorUtil.ToColorString(TableData.GetGlobalGun_Quality_Color2(clothesRank))
  local clothesTypeStr = clothesData.clothes_type == 1 and TableData.GetHintById(230012) or TableData.GetHintById(230011)
  local clothesTypeNotice = clothesData.clothes_type == 1 and TableData.GetHintById(230015) or TableData.GetHintById(230016)
  local content = TableData.GetHintById(230007, gunColorHex, gunName, clothesColorHex, clothesName, clothesTypeStr, clothesTypeNotice)
  content = CS.LuaUIUtils.String_Replace(content, "\\n", "\n")
  local param = {
    title = title,
    contentText = content,
    customData = TableDataBase.listStoreGoodDatas:GetDataById(storeId),
    isDouble = true,
    dialogType = 3,
    confirmCallback = function()
      if haveNum < tonumber(storeData.price) then
        UIManager.CloseUI(UIDef.UIComDoubleCheckDialog)
        CS.UIStoreGlobal.OpenChargeWithDiff(tonumber(storeData.price) - haveNum)
      else
        UIManager.CloseUI(UIDef.UIComDoubleCheckDialog)
        NetCmdStoreData:SendStoreBuy(storeId, 1, function(ret)
          if ret ~= ErrorCodeSuc then
            return
          end
          UISystem:OpenCommonReceivePanel()
        end)
      end
    end
  }
  UIManager.OpenUIByParam(UIDef.UIComDoubleCheckDialog, param)
end

function UIBarrackChangeSkinPanel:ToShopBuy()
  if not self.mStoreId then
    return
  end
  local curSlot = self:getCurSlot()
  local clothesData = curSlot:GetClothesData()
  self.mTempSlot = curSlot
  local storeId = self.mStoreId
  local storeData = NetCmdStoreData:GetStoreGoodsById(storeId)
  if not storeData then
    return
  end
  if self.payType == nil then
    return
  end
  if self.payType == 0 then
    NetCmdStoreData:SendStoreOrder(storeData.id, 0, function(ret)
      if ret ~= ErrorCodeSuc then
        return
      end
      UISystem:OpenCommonReceivePanel()
      self:UpdateShopShowClothes()
    end)
    return
  end
  local haveNum = NetCmdItemData:GetItemCount(self.payType)
  self.mTempClothesData = clothesData
  local title = TableData.GetHintById(230010)
  local gunName = self.gunCmdData.TabGunData.FirstName.str
  local clothesName = clothesData.name.str
  local gunRank = self.gunCmdData.TabGunData.rank
  local clothesRank = clothesData.Rare
  local gunColorHex = "#" .. CS.Utage.ColorUtil.ToColorString(TableData.GetGlobalGun_Quality_Color2(gunRank))
  local clothesColorHex = "#" .. CS.Utage.ColorUtil.ToColorString(TableData.GetGlobalGun_Quality_Color2(clothesRank))
  local clothesTypeStr = clothesData.clothes_type == 1 and TableData.GetHintById(230012) or TableData.GetHintById(230011)
  local clothesTypeNotice = clothesData.clothes_type == 1 and TableData.GetHintById(230015) or TableData.GetHintById(230016)
  local content = TableData.GetHintById(230007, gunColorHex, gunName, clothesColorHex, clothesName, clothesTypeStr, clothesTypeNotice)
  content = CS.LuaUIUtils.String_Replace(content, "\\n", "\n")
  local param = {
    title = title,
    contentText = content,
    customData = TableDataBase.listStoreGoodDatas:GetDataById(storeId),
    isDouble = true,
    dialogType = 3,
    confirmCallback = function()
      if haveNum < tonumber(storeData.price) then
        UIManager.CloseUI(UIDef.UIComDoubleCheckDialog)
        CS.UIStoreGlobal.OpenChargeWithDiff(tonumber(storeData.price) - haveNum)
      else
        UIManager.CloseUI(UIDef.UIComDoubleCheckDialog)
        NetCmdStoreData:SendStoreBuy(storeId, 1, function(ret)
          if ret ~= ErrorCodeSuc then
            return
          end
          UISystem:OpenCommonReceivePanel()
        end)
      end
    end
  }
  UIManager.OpenUIByParam(UIDef.UIComDoubleCheckDialog, param)
end

function UIBarrackChangeSkinPanel:onClickConsume()
  local curSlot = self:getCurSlot()
  local clothesData = curSlot:GetClothesData()
  local storeId = tonumber(clothesData.unlock_arg)
  local storeHistory = NetCmdStoreData:GetGoodsHistoryById(storeId)
  if not storeHistory then
    local storeData = TableDataBase.listStoreGoodDatas:GetDataById(storeId)
    if not storeData then
      return
    end
    local itemData = TableDataBase.listItemDatas:GetDataById(storeData.price_type)
    TipsPanelHelper.OpenUITipsPanel(itemData, storeData.price, true)
  end
end

function UIBarrackChangeSkinPanel:onClickItem()
  local curSlot = self:getCurSlot()
  local clothesData = curSlot:GetClothesData()
  local storeId = tonumber(clothesData.unlock_arg)
  local storeHistory = NetCmdStoreData:GetGoodsHistoryById(storeId)
  if not storeHistory then
    local storeData = TableDataBase.listStoreGoodDatas:GetDataById(storeId)
    if not storeData then
      return
    end
    local itemData = TableDataBase.listItemDatas:GetDataById(storeData.price_type)
    TipsPanelHelper.OpenUITipsPanel(itemData, storeData.price, true)
  end
end

function UIBarrackChangeSkinPanel:onClickBack()
  if self.isViewingMode then
    self:OnClickVisual(false)
    return
  end
  if self.isEnterVisual then
    gfdebug("\231\155\184\230\156\186\232\191\152\230\178\161\230\156\137\231\167\187\229\138\168\231\187\147\230\157\159, \228\184\141\229\143\175\228\187\165\232\167\166\229\143\145Esc")
    return
  end
  if FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrOverview then
    BarrackHelper.ModelMgr:RevertClothes(self.gunCmdData.id)
  end
  self.isOnclickBack = true
  UIManager.CloseUI(self.mCSPanel)
end

function UIBarrackChangeSkinPanel:onClickHome()
  if FacilityBarrackGlobal.CurSkinShowContentType == FacilityBarrackGlobal.ShowContentType.UIChrOverview then
    BarrackHelper.ModelMgr:RevertClothes()
  end
  self.isClickedHome = true
  UISystem:JumpToMainPanel()
end

function UIBarrackChangeSkinPanel:UpdateOrient(message)
  setactive(self.ui.mBtn_ExitVisual_TL.transform.parent.gameObject, false)
  setactive(self.ui.mBtn_ExitVisual_TR.transform.parent.gameObject, false)
  setactive(self.ui.mBtn_ExitVisual_BL.transform.parent.gameObject, false)
  setactive(self.ui.mBtn_ExitVisual_BR.transform.parent.gameObject, false)
  setactive(self.ui.mTrans_TextTips_Top.gameObject, false)
  setactive(self.ui.mTrans_TextTips_Bottom.gameObject, false)
  local orientation = tonumber(message.Content)
  if orientation == 0 then
    setactive(self.ui.mBtn_ExitVisual_TL.transform.parent.gameObject, true)
    setactive(self.ui.mTrans_TextTips_Top.gameObject, true)
  elseif orientation == -1 then
    setactive(self.ui.mBtn_ExitVisual_BL.transform.parent.gameObject, true)
  elseif orientation == 1 then
    setactive(self.ui.mBtn_ExitVisual_TR.transform.parent.gameObject, true)
  elseif orientation == 2 then
    setactive(self.ui.mBtn_ExitVisual_BR.transform.parent.gameObject, true)
    setactive(self.ui.mTrans_TextTips_Bottom.gameObject, true)
  end
end

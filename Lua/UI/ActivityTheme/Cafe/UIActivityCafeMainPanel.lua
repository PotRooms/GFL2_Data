require("UI.UIBasePanel")
require("UI.ActivityTheme.Cafe.Item.UICafeMachineInfoItem")
require("UI.ActivityTheme.Cafe.Item.UICafeNpcGiftItem")
require("UI.ActivityTheme.Cafe.Item.UIActivityCafeNotesTipsItem")
require("UI.ActivityTheme.Cafe.Item.UIActivityCafeTipsItem")
require("UI.ActivityTheme.Cafe.Item.UIActivityCafeBoardIconItem")
require("UI.ActivityTheme.Cafe.ActivityCafeGlobal")
require("UI.ActivityTheme.Cafe.Item.UIActivityCafeJumpItem")
require("UI.ActivityTheme.Cafe.Item.UIChallengeEntry")
require("UI.ActivityTheme.Cafe.Item.UIChapterEntry")
UIActivityCafeMainPanel = class("UIActivityCafeMainPanel", UIBasePanel)
UIActivityCafeMainPanel.__index = UIActivityCafeMainPanel
UIActivityCafeMainPanel.mBlueFall = nil
UIActivityCafeMainPanel.mPinkFall = nil
UIActivityCafeMainPanel.mYellowFall = nil

function UIActivityCafeMainPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Is3DPanel = true
end

function UIActivityCafeMainPanel:OnAwake(root, data)
end

function UIActivityCafeMainPanel:OnInit(root, data)
  if data.activityEntranceData then
    self.activityConfigData = data.activityConfigData
    self.activityModuleData = data.activityModuleData
  else
    self.activityConfigData = NetCmdThemeData:GetActivityDataByEntranceId(data[0])
  end
  NetCmdActivitySimData.currentConfigId = self.activityConfigData.Id
  self.state = NetCmdActivityDarkZone:GetCurrActivityState(self.activityConfigData.Id)
  self.activityEntranceData = NetCmdActivityDarkZone:GetActivityEntranceData(self.activityConfigData.id, self.state)
  if self.activityEntranceData ~= nil then
    self.activityModuleData = TableData.listActivityModuleDatas:GetDataById(self.activityEntranceData.module_id)
    NetCmdActivitySimData.CurThemeId = self.activityEntranceData.Id
  end
  self:SetRoot(root)
  self.ui = {}
  self.sceneLoaded = false
  self.synthesisTable = {}
  self:LuaUIBindTable(root, self.ui)
  self.animatorActivityMap = nil
  NetCmdActivitySimData:SetActivitySimState(self.activityConfigData.Id)
  self.chapterEntry = UIChapterEntry.New(self.ui.mTrans_ChapterEntry)
  self.challengeEntry = UIChallengeEntry.New(self.ui.mTrans_ChallengeEntry)
  self.tipsItemTable = {}
  self.noteItemTable = {}
  self.boardItemTable = {}
  self.synthesisCountTable = {}
  self.jumpItemTable = {}
  self.hasSynthesis = false
  ActivityCafeGlobal.IsReadyStartTutorial = true
  self:InitContent()
  self:AddBtnListener()
  self:AddEventListener()
  self.needReturn = ActivityCafeGlobal.isOnSave and ActivityCafeGlobal.cacheState ~= self.state
  ActivityCafeGlobal.isOnSave = false
  setactive(self.ui.mTrans_Mask, self.state == ActivitySimState.Official)
  self.maskTimer = TimerSys:DelayCall(5, function()
    self.maskTimer:Stop()
    self.maskTimer = nil
    setactive(self.ui.mTrans_Mask, false)
  end)
  if self.needReturn then
    return
  end
  self:RegisterEvent()
  self.isJumpTo = false
  NetCmdActivitySimData.IsOpenCafeMain = true
  NetCmdActivitySimData:UpdateImitatePool()
end

function UIActivityCafeMainPanel:OnAdditiveSceneLoaded(loadedScene, isOpen)
  if not isOpen then
    return
  end
  local simHelper = self:GetSimHelper()
  if simHelper ~= nil then
    simHelper:Release()
  end
  self:InitScene()
end

function UIActivityCafeMainPanel:AddEventListener()
  function self.loadingEndFunc()
    if self.isReturnOut and not NetCmdActivitySimData.IsOpenDarkzone then
      if ActivityCafeGlobal.cacheState == ActivitySimState.WarmUp then
        MessageBox.Show(TableData.GetHintById(64), TableData.GetHintById(270144), nil, function()
          UIManager.JumpToMainPanel()
        end, UIGroupType.Default)
      elseif not NetCmdActivitySimData.IsOpenDarkzone then
        self:BlackJump()
      end
    end
    self.isReturnOut = false
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnLoadingEnd, self.loadingEndFunc)
end

function UIActivityCafeMainPanel:RegisterEvent()
  self.isRegistedEvent = true
  
  function self.onModelLoadEnd(msg)
    if msg.Sender == 1002 then
      self.popUpTimer = TimerSys:DelayCall(1, function()
        if NetCmdActivitySimData:IsFirstEnterCafe() then
          NetCmdActivitySimData:CSSimCafeGetProductDuringLogOut()
        else
          setactive(self.ui.mTrans_Mask, false)
        end
        if NetCmdActivitySimData:IsFirstEnterCafeToday() then
          self:ShowPopupText(271191)
        end
        if self.loopPopUpTimer ~= nil then
          self.loopPopUpTimer:Stop()
          self.loopPopUpTimer = nil
        end
        self.loopPopUpTimer = TimerSys:DelayCall(8, function()
          self:CheckPopupState()
        end, nil, -1)
      end)
    end
    if NetCmdActivitySimData:GetIdleData(msg.Sender, 1) ~= nil then
      self:OnMachinLoaded(msg.Sender)
    end
    self.updatePosTimer = TimerSys:DelayFrameCall(5, function()
      if self.machineInfoTable then
        for _, item in pairs(self.machineInfoTable) do
          if item.data.id == msg.Sender then
            item:UpdatePos(true)
            item:UpdateProduceTime()
            break
          end
        end
      end
    end)
  end
  
  function self.onSimCafeDropTimeout(msg)
    for _, item in pairs(self.machineInfoTable) do
      if item.data.id == msg.Sender then
        local idleData = NetCmdActivitySimData:GetIdleData(item.data.id, item.data.level)
        self:UpdateSynthesisTable(idleData.synthesis_item, NetCmdActivitySimData:GetMachineSynthesisCount(item.data.id), true)
        item:UpdateState()
        break
      end
    end
  end
  
  function self.onCafeSynthesisCollectOne(msg)
    if self.synthesisCountTable[msg.Sender] ~= nil then
      self.synthesisCountTable[msg.Sender] = self.synthesisCountTable[msg.Sender] - 1
      if NetCmdActivitySimData:GetMachineSynthesisCount(ActivityCafeGlobal.SynthesisMachineMap[msg.Sender]) >= 10 then
        local item = self:GetAvailableBoardItem(msg.Sender)
        if item ~= nil then
          item:UpdateInfo({
            machineId = ActivityCafeGlobal.SynthesisMachineMap[msg.Sender],
            isNew = true
          })
          self.synthesisCountTable[msg.Sender] = self.synthesisCountTable[msg.Sender] + 1
        end
      end
    end
    self:UpdateSynthesisCount(msg.Sender, NetCmdActivitySimData:GetMachineSynthesisCount(ActivityCafeGlobal.SynthesisMachineMap[msg.Sender]))
    local item = self:GetAvailableNoteItem()
    if item ~= nil then
      item:UpdateInfo(msg.Sender, 1)
    end
    NetCmdItemData:ClearUserDropCache()
  end
  
  function self.refreshScoreFunc()
    self:UpdateScoreText()
  end
  
  function self.onDragPanel(sender)
    gfdebug("sender.Sender.value__ " .. tostring(LuaUtils.EnumToInt(sender.Sender)))
    if LuaUtils.EnumToInt(sender.Sender) == 1 and self.btnLeft.gameObject.activeInHierarchy then
      self:MoveVision(-1)
    elseif LuaUtils.EnumToInt(sender.Sender) == 2 and self.btnRight.gameObject.activeInHierarchy then
      self:MoveVision(1)
    end
  end
  
  function self.onSimCafeClaimNpcGift()
    UISystem:OpenCommonReceivePanel()
  end
  
  function self.onCafeSynthesisCollectAll(msg)
    if msg.Content ~= 0 then
      local item = self:GetAvailableNoteItem()
      if item ~= nil then
        item:UpdateInfo(msg.Sender, msg.Content)
      end
    end
  end
  
  function self.onResetCafeSynthesis()
    self:ClearSynthesisOnBoard()
  end
  
  function self.onSimCameraMoveEnd()
    self.visionMoved = false
  end
  
  function self.onGetProductDuringLogOut(msg)
    setactive(self.ui.mTrans_Mask, false)
    if msg.Sender ~= nil then
      for key, value in pairs(msg.Sender.MachineProduct) do
        UIManager.OpenUIByParam(UIDef.UIActivityCafeOfflineRewardsDialog, {
          rewards = msg.Sender
        })
        return
      end
      for key, value in pairs(msg.Sender.RecipeProduce) do
        UIManager.OpenUIByParam(UIDef.UIActivityCafeOfflineRewardsDialog, {
          rewards = msg.Sender
        })
        return
      end
      if msg.Sender.CustomerAdd > 0 then
        UIManager.OpenUIByParam(UIDef.UIActivityCafeOfflineRewardsDialog, {
          rewards = msg.Sender
        })
        return
      end
      if 0 < msg.Sender.TotalSoldAdd then
        UIManager.OpenUIByParam(UIDef.UIActivityCafeOfflineRewardsDialog, {
          rewards = msg.Sender
        })
        return
      end
    end
  end
  
  function self.onInteractArticle(msg)
    if msg.Sender ~= nil then
      for _, item in pairs(self.machineInfoTable) do
        if item.data.id == msg.Sender then
          item:ShowCompleteAnim()
          break
        end
      end
    end
  end
  
  function self.onSimCafeUpgrade(msg)
    if msg.Sender ~= nil then
      for _, item in pairs(self.machineInfoTable) do
        if item.data.id == msg.Sender then
          item:UpdateState()
          break
        end
      end
    end
  end
  
  MessageSys:AddListener(CS.GF2.Message.ActivitySimEvent.SimCafeUpgrade, self.onSimCafeUpgrade)
  MessageSys:AddListener(CS.GF2.Message.ActivitySimEvent.InteractArticle, self.onInteractArticle)
  MessageSys:AddListener(UIEvent.SimCameraMoveEnd, self.onSimCameraMoveEnd)
  MessageSys:AddListener(CS.GF2.Message.ActivitySimEvent.GetProductDuringLogOut, self.onGetProductDuringLogOut)
  MessageSys:AddListener(CS.GF2.Message.ActivitySimEvent.ResetCafeSynthesis, self.onResetCafeSynthesis)
  MessageSys:AddListener(CS.GF2.Message.ActivitySimEvent.CafeSynthesisCollectAll, self.onCafeSynthesisCollectAll)
  MessageSys:AddListener(CS.GF2.Message.ActivitySimEvent.SimCafeClaimNpcGift, self.onSimCafeClaimNpcGift)
  MessageSys:AddListener(CS.GF2.Message.ActivitySimEvent.CafeSynthesisCollectOne, self.onCafeSynthesisCollectOne)
  MessageSys:AddListener(CS.GF2.Message.ActivitySimEvent.SimCafeDropTimeout, self.onSimCafeDropTimeout)
  MessageSys:AddListener(CS.GF2.Message.ActivitySimEvent.ModelLoadEnd, self.onModelLoadEnd)
  MessageSys:AddListener(CS.GF2.Message.ActivitySimEvent.ScoreCustomerRefresh, self.refreshScoreFunc)
  MessageSys:AddListener(CS.GF2.Message.ActivitySimEvent.DragPanel, self.onDragPanel)
end

function UIActivityCafeMainPanel:InitContent()
  self.state = NetCmdActivityDarkZone:GetCurrActivityState(self.activityConfigData.Id)
  gfdebug("self.state: " .. tostring(self.state))
  if self.state == ActivitySimState.NotOpen and not ActivityCafeGlobal.cacheOpenDarkzone then
    self:ShowToMainBox()
    return
  end
  if self.isReturnOut or ActivityCafeGlobal.isOnSave and ActivityCafeGlobal.cacheState ~= self.state then
    return
  end
  setactive(self.ui.mTrans_GrpFormal, self.state == ActivitySimState.OfficialDown or self.state == ActivitySimState.Official or self.state == ActivitySimState.End)
  setactive(self.ui.mTrans_GrpPreheat, self.state == ActivitySimState.WarmUp)
  self:ShowDialog()
  self:ShowMonthStr()
  if NetCmdActivitySimData.SimTaskConfigData then
    self.ui.mText_Name.text = NetCmdActivitySimData.SimTaskConfigData.Name.str
  elseif NetCmdActivitySimData.SimConfigData then
  else
    gferror("error \230\178\161\230\156\137\230\180\187\229\138\168")
  end
  self:ShowBottomCafeText()
  self:ShowBottomCafeIcon()
  self:InitChapterEntry()
  self:InitChallengeEntry()
  local activityConfigId = self.activityConfigData.Id
  local activityId = NetCmdActivityDarkZone:GetCurrActivityID(SubmoduleType.ActivitySimCafe, activityConfigId)
  if self.state == ActivitySimState.Official or self.state == ActivitySimState.OfficialDown then
    self:UpdateScoreText()
    self.ui.mText_soldNumFormal.text = TableData.GetActivityHint(271122, activityConfigId, 2, LuaUtils.EnumToInt(SubmoduleType.ActivitySimCafe), activityId)
    self.ui.mText_ClientFormal.text = TableData.GetActivityHint(271123, activityConfigId, 2, LuaUtils.EnumToInt(SubmoduleType.ActivitySimCafe), activityId)
    self.ui.mTextLevelStr.text = TableData.GetActivityHint(271178, activityConfigId, 2, LuaUtils.EnumToInt(SubmoduleType.ActivitySimCafe), activityId) .. ":"
    setactive(self.ui.mTrans_GrpCurrency, true)
    self:UpdateLock()
  elseif self.state == ActivitySimState.WarmUp then
    setactive(self.ui.mTrans_GrpCurrency, false)
    self.ui.mImg_Pad.sprite = IconUtils.GetActivityCafeSprite("Img_ActivityCafeMain_PadEnter")
    setactive(self.ui.mTrans_Fx, true)
  elseif self.state == ActivitySimState.End then
    self.ui.mText_soldNumFormal.text = TableData.GetActivityHint(271122, activityConfigId, 2, LuaUtils.EnumToInt(SubmoduleType.ActivitySimCafe), activityId)
    self.ui.mText_ClientFormal.text = TableData.GetActivityHint(271123, activityConfigId, 2, LuaUtils.EnumToInt(SubmoduleType.ActivitySimCafe), activityId)
    self.ui.mTextLevelStr.text = TableData.GetActivityHint(271178, activityConfigId, 2, LuaUtils.EnumToInt(SubmoduleType.ActivitySimCafe), activityId) .. ":"
    self:UpdateScoreText()
    setactive(self.ui.mTrans_GrpCurrency, false)
  end
  self:UpdateRedPoint()
end

function UIActivityCafeMainPanel:OnUpdate()
  if self.state == ActivitySimState.NotOpen then
    return
  end
  if self.jumpItemTable then
    for i = 1, #self.jumpItemTable do
      self.jumpItemTable[i]:UpdatePos()
    end
  end
  self:UpdateGiftButton()
  self:UpdateMachineInfoPos()
  self:UpdatePopupTextPos()
end

function UIActivityCafeMainPanel:AddBtnListener()
  self.btnLeft = self.ui.mBtn_Left
  self.btnRight = self.ui.mBtn_Right
  UIUtils.GetButtonListener(self.btnLeft).onClick = function()
    self:MoveVision(-1)
  end
  UIUtils.GetButtonListener(self.btnRight).onClick = function()
    self:MoveVision(1)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnBack.gameObject).onClick = function()
    if NetCmdActivitySimData.IsOpenDarkzone then
      UIManager.CloseUI(UIDef.UIActivityCafeMainPanel)
      return
    end
    UIManager.CloseUI(UIDef.UIActivityCafeMainPanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Reward.gameObject).onClick = function()
    self:OnClickCollectAllSynthesis()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Pad.gameObject).onClick = function()
    gfdebug(tostring(self.state))
    if self.state == ActivitySimState.WarmUp then
      UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UICafeTabletPanel, LuaUtils.GetCafePanelParam(CS.GF2.Data.CafeTabTableData.EMode.Preheat, self.activityConfigData.Id))
    else
      gfdebug("mBtn_Pad 1")
      self:UpdateLock()
      if self.isPlanOpen == false then
        PopupMessageManager.PopupString(self.popStr)
        return
      end
      gfdebug("mBtn_Pad 2")
      if self.state == ActivitySimState.End then
        UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UICafeTabletPanel, LuaUtils.GetCafePanelParam(CS.GF2.Data.CafeTabTableData.EMode.Open, self.activityConfigData.Id))
      else
        NetCmdActivitySimData:CSSimCafeRecipeTimeOut(function()
          gfdebug("mBtn_Pad 3")
          UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UICafeTabletPanel, LuaUtils.GetCafePanelParam(CS.GF2.Data.CafeTabTableData.EMode.Open, self.activityConfigData.Id))
        end)
      end
    end
  end
  setactive(self.ui.mBtn_BtnDescription.transform.parent, true)
  UIUtils.GetButtonListener(self.ui.mBtn_BtnDescription.gameObject).onClick = function()
    if self.state == ActivitySimState.WarmUp then
      local newShowData = CS.ShowGuideDialogPPTData()
      newShowData.GroupId = 3010
      if NetCmdTeachPPTData:GetGroupIdsByType(CS.EPPTGroupType.All):IndexOf(newShowData.GroupId) ~= -1 then
        local showTeachData = new
        CS.ShowTeachPPTData()
        showTeachData.GroupId = 3010
        UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIGuidePPTDialog, showTeachData)
      else
        UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIComGuideDialogV2PPT, newShowData)
      end
    else
      local newShowData = CS.ShowGuideDialogPPTData()
      newShowData.GroupId = 3011
      if NetCmdTeachPPTData:GetGroupIdsByType(EPPTGroupType.All):IndexOf(newShowData.GroupId) ~= -1 then
        local showTeachData = new
        CS.ShowTeachPPTData()
        showTeachData.GroupId = 3011
        UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIGuidePPTDialog, showTeachData)
      else
        UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIComGuideDialogV2PPT, newShowData)
      end
    end
  end
  self.chapterEntry:AddBtnClickListener(function()
    self:OnClickChapterEntry()
  end)
  self.challengeEntry:AddBtnClickListener(function()
    self:OnClickChallengeEntry()
  end)
end

function UIActivityCafeMainPanel:OnShowStart()
  self.visionMoved = false
end

function UIActivityCafeMainPanel:OnShowFinish()
  local simHelper = self:GetSimHelper()
  if simHelper ~= nil then
    simHelper:SetEnabled(true)
  end
end

function UIActivityCafeMainPanel:UpdateLock()
  self.popStr = ""
  self.isPlanOpen, self.popStr = NetCmdActivitySimData:IsCafeOpen(self.activityConfigData.id, self.popStr)
  setactive(self.ui.mTrans_Fx, self.isPlanOpen)
  if not self.isPlanOpen then
    self.popStr = string_format(TableData.GetActivityHint(271122, self.activityConfigData.Id, 1, self.activityModuleData.type), self.popStr)
    self.ui.mImg_Pad.sprite = IconUtils.GetActivityCafeSprite("Img_ActivityCafeMain_PadEnter_Lock")
  else
    self.ui.mImg_Pad.sprite = IconUtils.GetActivityCafeSprite("Img_ActivityCafeMain_PadEnter")
  end
  self.chapterEntry:RefreshIsPlanOpen()
  self.chapterEntry:Refresh()
  self.challengeEntry:RefreshIsPlanOpen()
  self.challengeEntry:Refresh()
end

function UIActivityCafeMainPanel:OnBackFrom()
  if ActivityCafeGlobal.VisionCache ~= 0 then
    self.vision = ActivityCafeGlobal.VisionCache
    ActivityCafeGlobal.VisionCache = 0
  end
  self:UpdateJumpItem(true)
  if self.jumpItemTable then
    for i = 1, #self.jumpItemTable do
      self.jumpItemTable[i]:UpdateVision(self.vision)
    end
  end
  if NetCmdActivitySimData.IsOpenDarkzone then
    NetCmdActivitySimData.IsOpenDarkzone = false
    if self.state ~= ActivitySimState.WarmUp then
      NetCmdActivitySimData:CSSimCafeInfo(function()
        self:UpdateVision()
        self.sceneLoaded = true
        self:InitContent()
        self:CreateStageChangeTimer()
        self:CheckProduceTips()
        if self.loopPopUpTimer ~= nil then
          self.loopPopUpTimer:Stop()
          self.loopPopUpTimer = nil
        end
        self.loopPopUpTimer = TimerSys:DelayCall(5, function()
          self:CheckPopupState()
        end, nil, -1)
      end)
    elseif self.state ~= ActivitySimState.NotOpen then
      self:UpdateVision()
      self.sceneLoaded = true
      self:InitContent()
      self:CreateStageChangeTimer()
    end
  end
  if self.isJumpTo then
    self:ShowMapAnimation(true)
    self.isJumpTo = false
  end
  self:InitContent()
  self:UpdateRedPoint()
  self:PlayAudioByVision(self.vision)
end

function UIActivityCafeMainPanel:OnClose()
  if self.isRegistedEvent then
    MessageSys:RemoveListener(CS.GF2.Message.ActivitySimEvent.SimCafeUpgrade, self.onSimCafeUpgrade)
    MessageSys:RemoveListener(CS.GF2.Message.ActivitySimEvent.InteractArticle, self.onInteractArticle)
    MessageSys:RemoveListener(UIEvent.SimCameraMoveEnd, self.onSimCameraMoveEnd)
    MessageSys:RemoveListener(CS.GF2.Message.ActivitySimEvent.GetProductDuringLogOut, self.onGetProductDuringLogOut)
    MessageSys:RemoveListener(CS.GF2.Message.ActivitySimEvent.ResetCafeSynthesis, self.onResetCafeSynthesis)
    MessageSys:RemoveListener(CS.GF2.Message.ActivitySimEvent.CafeSynthesisCollectAll, self.onCafeSynthesisCollectAll)
    MessageSys:RemoveListener(CS.GF2.Message.ActivitySimEvent.SimCafeClaimNpcGift, self.onSimCafeClaimNpcGift)
    MessageSys:RemoveListener(CS.GF2.Message.ActivitySimEvent.CafeSynthesisCollectOne, self.onCafeSynthesisCollectOne)
    MessageSys:RemoveListener(CS.GF2.Message.ActivitySimEvent.ModelLoadEnd, self.onModelLoadEnd)
    MessageSys:RemoveListener(CS.GF2.Message.ActivitySimEvent.SimCafeDropTimeout, self.onSimCafeDropTimeout)
    MessageSys:RemoveListener(CS.GF2.Message.ActivitySimEvent.ScoreCustomerRefresh, self.refreshScoreFunc)
    MessageSys:RemoveListener(CS.GF2.Message.ActivitySimEvent.DragPanel, self.onDragPanel)
  end
  self.needReturn = false
  self.isRegistedEvent = false
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnLoadingEnd, self.loadingEndFunc)
  NetCmdActivitySimData:ClearPoolTimer()
  NetCmdActivitySimData:ClearProduceMap()
  self.isReturnOut = false
  if self.machineInfoTable ~= nil then
    self:ReleaseCtrlTable(self.machineInfoTable)
    self.machineInfoTable = nil
  end
  if self.npcGiftTable ~= nil then
    for _, gift in pairs(self.npcGiftTable) do
      gift:OnRelease()
    end
    self.npcGiftTable = nil
  end
  if self.noteItemTable ~= nil then
    self:ReleaseCtrlTable(self.noteItemTable)
    self.noteItemTable = nil
  end
  if self.tipsItemTable ~= nil then
    self:ReleaseCtrlTable(self.tipsItemTable)
    self.tipsItemTable = nil
  end
  if self.boardItemTable ~= nil then
    for _, item in pairs(self.boardItemTable) do
      gfdestroy(item.go)
    end
    self:ReleaseCtrlTable(self.boardItemTable)
    self.boardItemTable = nil
  end
  if self.jumpItemTable then
    self:ReleaseCtrlTable(self.jumpItemTable)
    self.jumpItemTable = nil
  end
  if self.machineTimer ~= nil then
    self.machineTimer:Stop()
    self.machineTimer = nil
  end
  if self.cafeDropTimer ~= nil then
    self.cafeDropTimer:Stop()
    self.cafeDropTimer = nil
  end
  if self.updatePosTimer ~= nil then
    self.updatePosTimer:Stop()
    self.updatePosTimer = nil
  end
  if self.popUpTimer ~= nil then
    self.popUpTimer:Stop()
    self.popUpTimer = nil
  end
  if self.maskTimer ~= nil then
    self.maskTimer:Stop()
    self.maskTimer = nil
  end
  if self.produceTipsTimer ~= nil then
    self.produceTipsTimer:Stop()
    self.produceTipsTimer = nil
  end
  if self.loopPopUpTimer ~= nil then
    self.loopPopUpTimer:Stop()
    self.loopPopUpTimer = nil
    self.lastPopupState = 0
    setactive(self.ui.mTrans_BlankTips, false)
  end
  if ActivityCafeGlobal.stateChangeTimer then
    ActivityCafeGlobal.stateChangeTimer:Stop()
    ActivityCafeGlobal.stateChangeTimer = nil
  end
  if self.levelIcon then
    gfdestroy(self.levelIcon)
  end
  self.visionMoved = false
  if NetCmdActivitySimData.IsOpenDarkzone then
    MessageSys:SendMessage(UIEvent.DzTeamUnload, nil)
  end
  NetCmdActivitySimData.IsOpenCafeMain = false
  NetCmdActivitySimData.IsOpenDarkzone = false
  ActivityCafeGlobal.VisionCache = 0
  self:StopAllAudio()
  self.chapterEntry:OnRelease()
  self.chapterEntry = nil
  self.challengeEntry:OnRelease()
  self.challengeEntry = nil
end

function UIActivityCafeMainPanel:UpdatePreUI()
end

function UIActivityCafeMainPanel:OnHideFinish()
  self:SetMachineInfoAudio(false)
  if self.mScene ~= nil and not self.mScene.IsVisible then
    self:StopAllAudio()
  end
end

function UIActivityCafeMainPanel:OnRelease()
end

function UIActivityCafeMainPanel:ShowMonthStr()
  local ConfigData = NetCmdActivityDarkZone:GetCurrActivityConfig(self.activityConfigData.id)
  if not ConfigData then
    return
  end
  local EntranceData = TableData.listActivityEntranceDatas:GetDataById(ConfigData.ActivityEntrance[0])
  local plan = TableData.listPlanDatas:GetDataById(EntranceData.plan_id)
  local openTime = plan.OpenTime
  local closeTime = plan.CloseTime
  if self.state == ActivitySimState.WarmUp then
    self.closeTime = closeTime
    gfdebug("warmup closeTime")
  end
  if self.state == ActivitySimState.OfficialDown then
    EntranceData = TableData.listActivityEntranceDatas:GetDataById(ConfigData.ActivityEntrance[2])
  elseif self.state == ActivitySimState.End then
    EntranceData = TableData.listActivityEntranceDatas:GetDataById(ConfigData.ActivityEntrance[ConfigData.ActivityEntrance.Count - 1])
  elseif self.state == ActivitySimState.Official then
    EntranceData = TableData.listActivityEntranceDatas:GetDataById(ConfigData.ActivityEntrance[1])
  end
  plan = TableData.listPlanDatas:GetDataById(EntranceData.plan_id)
  openTime = plan.OpenTime
  closeTime = plan.CloseTime
  if self.state ~= ActivitySimState.WarmUp then
    self.closeTime = closeTime
    gfdebug("other closeTime")
  end
end

function UIActivityCafeMainPanel:OnSave()
  ActivityCafeGlobal.cacheState = self.state
  ActivityCafeGlobal.isOnSave = true
  gfdebug("ActivityCafeGlobal.closeTime: " .. tostring(CS.CGameTime.ConvertLongToDateTime(ActivityCafeGlobal.closeTime)))
end

function UIActivityCafeMainPanel:OnRecover()
  local tmpstate = NetCmdActivityDarkZone:GetCurrActivityState(self.activityConfigData.Id)
  if tmpstate ~= ActivitySimState.NotOpen and ActivityCafeGlobal.cacheState ~= tmpstate then
    self.isReturnOut = true
  end
end

function UIActivityCafeMainPanel:GetTimeText(openTime, closeTime)
  local currOpenData = CS.CGameTime.ConvertLongToDateTime(openTime)
  local currCloseData = CS.CGameTime.ConvertLongToDateTime(closeTime)
  local currOpenTime, currCloseTime
  if currOpenData.Year == currCloseData.Year then
    currOpenTime = currOpenData:ToString("MM.dd/HH:mm")
    currCloseTime = currCloseData:ToString("MM.dd/HH:mm")
  else
    currOpenTime = currOpenData:ToString("yyyy.MM.dd/HH:mm")
    currCloseTime = currCloseData:ToString("yyyy.MM.dd/HH:mm")
  end
  return currOpenTime .. " - " .. currCloseTime
end

function UIActivityCafeMainPanel:ShowBottomCafeIcon()
  if self.state ~= ActivitySimState.OfficialDown and self.state ~= ActivitySimState.Official and self.state ~= ActivitySimState.End then
    return
  end
  if UIUtils.IsNullOrDestroyed(self.levelIcon) then
    self.levelIcon = instantiate(self.ui.mScrollListChild_GrpIcon.childItem, self.ui.mScrollListChild_GrpIcon.transform)
  end
  self.levelIconUI = {}
  self:LuaUIBindTable(self.levelIcon, self.levelIconUI)
  self.cafeLevel = NetCmdActivitySimData.CoffeeBarLevel
  local grade = (self.cafeLevel - 1) // 2 + 1
  local star = self.cafeLevel - (grade - 1) * 2
  setactive(self.levelIconUI.mImg_Star, self.cafeLevel < 7)
  if star == 1 then
    star = 2
  else
    star = 1
  end
  self.levelIconUI.mImg_Icon.sprite = IconUtils.GetCafeGradeIcon(grade)
  self.levelIconUI.mImg_Star.sprite = IconUtils.GetCafeStarIcon(star)
end

function UIActivityCafeMainPanel:ShowBottomCafeText()
  self.cafeLevel = NetCmdActivitySimData.CoffeeBarLevel
  if self.cafeLevel > 0 then
    self.ui.mText_Info.text = TableData.listSimGradeDatas:GetDataById(self.cafeLevel).grade_name.str
  end
end

function UIActivityCafeMainPanel:InitChapterEntry()
  local chapterIdForStory
  for k, v in pairs(self.activityModuleData.activity_submodule) do
    if k == 2001 then
      chapterIdForStory = v
      break
    end
  end
  if not chapterIdForStory then
    self.chapterEntry:SetVisible(false)
    return
  end
  local chapterData = TableDataBase.listChapterDatas:GetDataById(chapterIdForStory)
  local difficultyId = NetCmdDungeonData:GetRecordedDifficultyIdByGroup(chapterData.difficulty_group)
  local targetChapterData = NetCmdDungeonData:GetStoryCharterDataByDifficultyGroup(chapterData.difficulty_group, difficultyId)
  local activityConfigId = self.activityConfigData.Id
  local activityIdForStory = NetCmdActivityDarkZone:GetCurrActivityID(SubmoduleType.ActivityStory, activityConfigId)
  self.chapterEntry:SetData(self.activityModuleData, self.state, activityConfigId, activityIdForStory, targetChapterData)
  self.chapterEntry:Refresh()
end

function UIActivityCafeMainPanel:InitChallengeEntry()
  local chapterId
  for k, v in pairs(self.activityModuleData.activity_submodule) do
    if k == 2002 then
      chapterId = v
    end
  end
  if not chapterId then
    self.challengeEntry:SetVisible(false)
    return
  end
  local activityConfigId = self.activityConfigData.Id
  local activityIdForChallenge = NetCmdActivityDarkZone:GetCurrActivityID(SubmoduleType.ActivityStoryChallenge, activityConfigId)
  self.challengeEntry:SetData(self.activityModuleData, self.state, activityConfigId, activityIdForChallenge, chapterId)
  self.challengeEntry:Refresh()
end

function UIActivityCafeMainPanel:CheckProduceTips()
  local strList = {}
  local activityConfigId = self.activityConfigData.Id
  local activityId = NetCmdActivityDarkZone:GetCurrActivityID(SubmoduleType.ActivitySimCafe, activityConfigId)
  if NetCmdActivitySimData.MachineProduceMap ~= nil then
    for id, _ in pairs(NetCmdActivitySimData.MachineProduceMap) do
      local machineData = NetCmdActivitySimData:GetMachineDataById(id)
      if machineData.LastProduceTime ~= 0 then
        local machineTable = TableData.listActivitySimArticleDatas:GetDataById(id)
        if machineTable ~= nil then
          local str = string_format(TableData.GetActivityHint(271194, activityConfigId, 2, LuaUtils.EnumToInt(SubmoduleType.ActivitySimCafe), activityId), machineTable.article_name_show.str)
          table.insert(strList, str)
        end
      end
    end
  end
  if NetCmdActivitySimData.RecipeProduceMap ~= nil then
    for id, _ in pairs(NetCmdActivitySimData.RecipeProduceMap) do
      if NetCmdActivitySimData:CheckRecipeIsProduct(id) then
        local itemData = TableData.listSimRecipeDatas:GetDataById(id)
        if itemData ~= nil then
          local str = string_format(TableData.GetActivityHint(271196, activityConfigId, 2, LuaUtils.EnumToInt(SubmoduleType.ActivitySimCafe), activityId), itemData.recipe_name.str)
          table.insert(strList, str)
        end
      end
    end
  end
  NetCmdActivitySimData:ClearProduceMap()
  self.produceTipsIndex = 0
  if 0 < #strList then
    self.produceTipsTimer = TimerSys:DelayCall(1.5, function()
      self.produceTipsTimer:Stop()
      self.produceTipsTimer = nil
      self:StartProduceTipsTimer(strList)
    end)
  end
end

function UIActivityCafeMainPanel:StartProduceTipsTimer(strList)
  if self.state == ActivitySimState.Official then
    self.produceTipsIndex = self.produceTipsIndex + 1
    local tips = self:GetAvailableTipsItem()
    tips:UpdateInfo(strList[self.produceTipsIndex])
    self.produceTipsTimer = TimerSys:DelayCall(0.7, function()
      self.produceTipsTimer:Stop()
      self.produceTipsTimer = nil
      if self.produceTipsIndex < #strList then
        self:StartProduceTipsTimer(strList)
      end
    end)
  end
end

function UIActivityCafeMainPanel:ShowPopupText(hintId)
  if self.state == ActivitySimState.Official then
    local activityConfigId = self.activityConfigData.Id
    local activityId = NetCmdActivityDarkZone:GetCurrActivityID(SubmoduleType.ActivitySimCafe, activityConfigId)
    if hintId ~= 0 then
      setactive(self.ui.mTrans_BlankTips, true)
      local str = TableData.GetActivityHint(hintId, activityConfigId, 2, LuaUtils.EnumToInt(SubmoduleType.ActivitySimCafe), activityId)
      self.ui.mText_PopupText.text = str
    end
  end
end

function UIActivityCafeMainPanel:CheckPopupState()
  local allMachineStop = true
  if self.machineInfoTable ~= nil then
    for _, item in pairs(self.machineInfoTable) do
      local machineData = NetCmdActivitySimData:GetMachineDataById(item.data.id)
      if machineData.LastProduceTime ~= 0 then
        allMachineStop = false
        break
      end
    end
  else
    allMachineStop = false
  end
  local allRecipeStop = true
  local menuData = TableData.listSimRecipeByMenuGroupDatas:GetDataById(NetCmdActivitySimData.SimConfigData.menu_group)
  if menuData ~= nil then
    local list = menuData.RecipeId
    for i = 0, list.Count - 1 do
      local id = list[i]
      if NetCmdActivitySimData:CheckRecipeIsProduct(id) then
        allRecipeStop = false
        break
      end
    end
  end
  if allRecipeStop and not allMachineStop then
    if self.lastPopupState == nil or self.lastPopupState ~= 2 then
      setactive(self.ui.mTrans_BlankTips, false)
      self.lastPopupState = 2
      self:ShowPopupText(271193)
    end
  elseif not allRecipeStop and allMachineStop then
    if self.lastPopupState == nil or self.lastPopupState ~= 1 then
      setactive(self.ui.mTrans_BlankTips, false)
      self.lastPopupState = 1
      self:ShowPopupText(271192)
    end
  elseif allRecipeStop and allMachineStop then
    if self.lastPopupState == nil or self.lastPopupState ~= 1 then
      setactive(self.ui.mTrans_BlankTips, false)
      self.lastPopupState = 1
      self:ShowPopupText(271192)
    else
      setactive(self.ui.mTrans_BlankTips, false)
      self.lastPopupState = 2
      self:ShowPopupText(271193)
    end
  else
    setactive(self.ui.mTrans_BlankTips, false)
  end
end

function UIActivityCafeMainPanel:UpdatePopupTextPos()
  if self.mScene ~= nil and self.sceneLoaded and self.mScene:GetCurrentCamera() ~= nil and self.state == ActivitySimState.Official then
    local simHelper = self:GetSimHelper()
    if simHelper == nil then
      return
    end
    local model = simHelper.ModelManager:GetActivityModelByConfigId(1002)
    if model ~= nil then
      local topPos = self.mScene:GetCurrentCamera():WorldToScreenPoint(model:GetTopPos())
      local screenPos = self.mScene:GetModelLocalposition(topPos, self.ui.mTrans_Enter, UISystem.UICamera)
      self.ui.mTrans_BlankTips.localPosition = Vector3(screenPos.x + 90, screenPos.y, screenPos.z)
    end
  end
end

function UIActivityCafeMainPanel:UpdateGiftButton()
  if self.mScene ~= nil and self.sceneLoaded and self.mScene:GetCurrentCamera() ~= nil and NetCmdActivitySimData.GiftNpc ~= nil and NetCmdActivitySimData.GiftNpc.NpcGifts.Count > 0 and self.state ~= ActivitySimState.End then
    if self.npcGiftTable == nil then
      self.npcGiftTable = {}
    end
    for id, item in pairs(NetCmdActivitySimData.GiftNpc.NpcGifts) do
      if self.npcGiftTable[id] == nil then
        local item = UICafeNpcGiftItem.New()
        self.npcGiftTable[id] = item
        local data = {
          id = id,
          camera = self.mScene:GetCurrentCamera(),
          scene = self.mScene,
          activityEntranceData = self.activityEntranceData,
          activityModuleData = self.activityModuleData,
          activityConfigData = self.activityConfigData
        }
        item:InitCtrl(self.ui.mScrollListChild_NameRoot.gameObject, data)
      end
    end
    for _, gift in pairs(self.npcGiftTable) do
      gift:UpdatePos()
    end
  end
end

function UIActivityCafeMainPanel:UpdateMachineInfoPos()
  if self.sceneLoaded and self.machineInfoTable ~= nil then
    for _, item in pairs(self.machineInfoTable) do
      item:UpdatePos()
    end
  end
end

function UIActivityCafeMainPanel:GetAvailableNoteItem()
  for _, item in pairs(self.noteItemTable) do
    if not item.isActive then
      return item
    end
  end
end

function UIActivityCafeMainPanel:GetAvailableTipsItem()
  for _, item in pairs(self.tipsItemTable) do
    if not item.isActive then
      return item
    end
  end
end

function UIActivityCafeMainPanel:GetAvailableBoardItem(id)
  for _, item in pairs(self.boardItemTable) do
    if not item.isActive and item.fallId == id then
      return item
    end
  end
end

function UIActivityCafeMainPanel:GenerateNoteItemPool()
  for i = 1, 10 do
    local noteItem = UIActivityCafeNotesTipsItem.New()
    table.insert(self.noteItemTable, noteItem)
    noteItem:InitCtrl(self.ui.mScrollListChild_Content.gameObject)
  end
end

function UIActivityCafeMainPanel:GenerateTipsItemPool()
  for i = 1, 4 do
    local tipsItem = UIActivityCafeTipsItem.New()
    table.insert(self.tipsItemTable, tipsItem)
    tipsItem:InitCtrl(self.ui.mTrans_TipsContent.gameObject)
  end
end

function UIActivityCafeMainPanel:GenerateBoardItemPool()
  self:CreateFallAsset(self.mBlueFall, "activity_cafe_bluefall_01", 10, 170027)
  self:CreateFallAsset(self.mPinkFall, "activity_cafe_pinkfall_01", 10, 170032)
  self:CreateFallAsset(self.mYellowFall, "activity_cafe_yellowfall_01", 10, 170037)
end

function UIActivityCafeMainPanel:CreateFallAsset(asset, assetName, count, id)
  local simHelper = self:GetSimHelper()
  if simHelper == nil then
    return
  end
  local levelRoot = simHelper.ModelManager.LevelRoot
  local fallRoot = levelRoot[2]
  if asset == nil then
    ResSys:LoadActivitySimAssetAsync(assetName, function(s, o, arg)
      if o then
        self:AddAsset(o)
        asset = o
        self:InitFallItem(count, asset, fallRoot, id)
      end
    end)
  else
    self:InitFallItem(count, asset, fallRoot, id)
  end
end

function UIActivityCafeMainPanel:InitFallItem(count, obj, parent, id)
  for i = 1, count do
    local instObj = instantiate(obj, parent.transform)
    local item = UIActivityCafeBoardIconItem.New()
    item:InitCtrl(instObj, {
      activityConfigData = self.activityConfigData,
      id = id,
      index = i
    })
    table.insert(self.boardItemTable, item)
  end
end

function UIActivityCafeMainPanel:GenerateJumpUIItem()
  if self.state == ActivitySimState.End then
    return
  end
  local simHelper = self:GetSimHelper()
  if simHelper == nil then
    return
  end
  local allSceneDatas = simHelper.ModelManager:GetAllSceneDatas()
  local index = 0
  for i = 0, allSceneDatas.Count - 1 do
    local data = allSceneDatas[i]
    if data.ArticleId ~= 0 then
      local articleData = TableData.listActivitySimArticleDatas:GetDataById(data.article_id)
      if articleData and articleData.article_type == 2 then
        local item = self.jumpItemTable[index]
        if item == nil then
          item = UIActivityCafeJumpItem.New()
          item:InitCtrl(self.ui.mTrans_Enter, self.ui.mBtn_ActivityEnter, data, function()
            self:OnJumpClick()
          end, self)
          table.insert(self.jumpItemTable, item)
        end
      end
    end
  end
end

function UIActivityCafeMainPanel:InitScene()
  self.mScene = SceneSys:GetActivitySimScene()
  if self.needReturn then
    return
  end
  if self.state == ActivitySimState.NotOpen then
  elseif self.state ~= ActivitySimState.WarmUp then
    NetCmdActivitySimData:CSSimCafeInfo(function()
      self:InitSceneObj()
      self.sceneLoaded = true
      self:InitContent()
      self:CreateStageChangeTimer()
    end)
  elseif self.state ~= ActivitySimState.NotOpen then
    self:InitSceneObj()
    self.sceneLoaded = true
    self:InitContent()
    self:CreateStageChangeTimer()
  end
end

function UIActivityCafeMainPanel:InitSceneObj()
  self:GenerateBoardItemPool()
  self:GenerateNoteItemPool()
  self:GenerateTipsItemPool()
  self:CheckProduceTips()
  local simHelper = self:GetSimHelper()
  if simHelper == nil then
    return
  end
  simHelper:EnterGame()
  self:GenerateJumpUIItem()
  if self.state == CS.Activities.ActivitySim.ActivitySimDefine.ActivitySimState.WarmUp then
    self.vision = 3
  else
    self.vision = 2
  end
  if ActivityCafeGlobal.VisionCache ~= 0 then
    self.vision = ActivityCafeGlobal.VisionCache
    ActivityCafeGlobal.VisionCache = 0
  end
  self:UpdateVision()
end

function UIActivityCafeMainPanel:InitMachineTopUI()
  self.machineInfoTable = {}
  for i = 0, NetCmdActivitySimData.SimCafeData.Machines.Length - 1 do
    local machine = NetCmdActivitySimData.SimCafeData.Machines[i]
    local item = UICafeMachineInfoItem.New()
    self.machineInfoTable[i + 1] = item
    local data = {
      id = machine.MachineId,
      level = machine.Level,
      camera = self.mScene:GetCurrentCamera(),
      scene = self.mScene,
      activityConfigData = self.activityConfigData
    }
    item:InitCtrl(self.ui.mScrollListChild_NameRoot.gameObject, data)
  end
  if self.sceneLoaded and self.machineInfoTable ~= nil then
    for _, item in pairs(self.machineInfoTable) do
      item:UpdatePos(true)
      item:UpdateProduceTime()
    end
  end
  if self.state == CS.Activities.ActivitySim.ActivitySimDefine.ActivitySimState.Official or self.state == CS.Activities.ActivitySim.ActivitySimDefine.ActivitySimState.OfficialDown then
    self.cafeDropTimer = TimerSys:DelayCall(2, function()
      if self.machineInfoTable ~= nil then
        for _, item in pairs(self.machineInfoTable) do
          local machineData = NetCmdActivitySimData:GetMachineDataById(item.data.id)
          if machineData.LastProduceTime ~= 0 then
            local idleData = NetCmdActivitySimData:GetIdleData(item.data.id, item.data.level)
            if idleData ~= nil and CGameTime:GetTimestamp() > machineData.LastProduceTime + idleData.outer_cd then
              NetCmdActivitySimData:CSSimCafeDropTimeout(item.data.id, function(ret)
                if ret == ErrorCodeSuc then
                  local simHelper = self:GetSimHelper()
                  if simHelper == nil then
                    return
                  end
                  simHelper.ModelManager:CreateAvatar(NetCmdActivitySimData:GetRandomAvatarId(idleData))
                end
              end)
            end
          end
        end
      end
    end, nil, -1)
  end
end

function UIActivityCafeMainPanel:OnMachinLoaded(id)
  TimerSys:DelayFrameCall(1, function()
    if self.machineInfoTable then
      for _, item in pairs(self.machineInfoTable) do
        if item.data.id == id then
          local idleData = NetCmdActivitySimData:GetIdleData(item.data.id, item.data.level)
          self:UpdateSynthesisTable(idleData.synthesis_item, NetCmdActivitySimData:GetMachineSynthesisCount(item.data.id))
          break
        end
      end
    end
  end)
end

function UIActivityCafeMainPanel:UpdateSynthesisTable(id, count, isNew)
  if count ~= 0 then
    local boardCount = math.min(10, count)
    local preCount = self.synthesisCountTable[id] or 0
    if boardCount > preCount then
      for i = 1, boardCount - preCount do
        local item = self:GetAvailableBoardItem(id)
        if item ~= nil then
          item:UpdateInfo({
            machineId = ActivityCafeGlobal.SynthesisMachineMap[id],
            isNew = isNew
          })
        else
          self:OnMachinLoaded(ActivityCafeGlobal.SynthesisMachineMap[id])
          return
        end
      end
      self.synthesisCountTable[id] = boardCount
    end
  end
  self:UpdateSynthesisCount(id, count)
end

function UIActivityCafeMainPanel:UpdateSynthesisCount(id, count)
  self.synthesisTable = self.synthesisTable or {}
  self.synthesisTable[id] = count
  self.hasSynthesis = false
  for _, synthesisCount in pairs(self.synthesisTable) do
    if 0 < synthesisCount then
      self.hasSynthesis = true
      break
    end
  end
  setactive(self.ui.mTrans_GrpReward, self.hasSynthesis and (self.state == CS.Activities.ActivitySim.ActivitySimDefine.ActivitySimState.Official or self.state == CS.Activities.ActivitySim.ActivitySimDefine.ActivitySimState.OfficialDown))
end

function UIActivityCafeMainPanel:ClearSynthesisOnBoard()
  for _, item in pairs(self.boardItemTable) do
    item:RecycleItem()
  end
  self.synthesisCountTable = {}
  if self.machineInfoTable ~= nil then
    for _, item in pairs(self.machineInfoTable) do
      local idleData = NetCmdActivitySimData:GetIdleData(item.data.id, item.data.level)
      self:UpdateSynthesisTable(idleData.synthesis_item, NetCmdActivitySimData:GetMachineSynthesisCount(item.data.id))
    end
  end
  setactive(self.ui.mTrans_GrpReward, self.hasSynthesis and (self.state == CS.Activities.ActivitySim.ActivitySimDefine.ActivitySimState.Official or self.state == CS.Activities.ActivitySim.ActivitySimDefine.ActivitySimState.OfficialDown))
end

function UIActivityCafeMainPanel:MoveVision(value)
  if self.visionMoved then
    return
  end
  self.visionMoved = true
  self.vision = self.vision + value
  self:UpdateVision()
end

function UIActivityCafeMainPanel:UpdateVision()
  if self.mScene ~= nil then
    self.mScene:SetVision(self.vision, self.state == CS.Activities.ActivitySim.ActivitySimDefine.ActivitySimState.WarmUp)
  end
  setactive(self.btnLeft, self.vision ~= 1 and self.state ~= CS.Activities.ActivitySim.ActivitySimDefine.ActivitySimState.WarmUp)
  setactive(self.btnRight, self.vision ~= 3)
  setactive(self.ui.mScrollListChild_NameRoot, true)
  setactive(self.ui.mTrans_GrpListTips, true)
  if self.vision == 1 then
    self:ShowMapAnimation(true)
    setactive(self.ui.mTrans_GrpReward, false)
  elseif self.vision == 2 then
    if self.machineInfoTable == nil or #self.machineInfoTable == 0 then
      self:InitMachineTopUI()
    end
    setactive(self.ui.mTrans_GrpReward, self.hasSynthesis and (self.state == CS.Activities.ActivitySim.ActivitySimDefine.ActivitySimState.Official or self.state == CS.Activities.ActivitySim.ActivitySimDefine.ActivitySimState.OfficialDown))
  elseif self.vision == 3 then
    setactive(self.ui.mTrans_GrpReward, false)
  end
  if self.jumpItemTable then
    for i = 1, #self.jumpItemTable do
      self.jumpItemTable[i]:UpdateVision(self.vision)
    end
  end
  if self.vision == 1 then
    MessageSys:SendMessage(GuideEvent.OnCafeMainVisionIsLeft, nil)
  end
  self:PlayAudioByVision(self.vision)
end

function UIActivityCafeMainPanel:ShowMapAnimation(isShow)
  if self.animatorActivityMap == nil or UIUtils.IsNullOrDestroyed(self.animatorActivityMap) then
    local simHelper = self:GetSimHelper()
    if simHelper == nil then
      return
    end
    local articleModel = simHelper.ModelManager:GetActivityArticleModelByConfigId(201)
    if articleModel == nil then
      return
    end
    local obj = articleModel:GetViewObj():GetGameObject()
    if obj then
      local root = obj.transform:Find("activity_cafe_darkzone_entry/ActivityCafeDarkzoneMap/Root")
      if root then
        local map = root.gameObject
        self.animatorActivityMap = map:GetComponent(typeof(CS.UnityEngine.Animator))
        self.animatorActivityMap.keepAnimatorControllerStateOnDisable = true
      else
        gfdebug("map Root\230\154\130\230\156\170\231\148\159\230\136\144")
      end
    else
      gfdebug("map\230\154\130\230\156\170\231\148\159\230\136\144")
    end
  end
  if self.animatorActivityMap == nil or UIUtils.IsNullOrDestroyed(self.animatorActivityMap) then
    return
  end
  if isShow then
    self.animatorActivityMap:ResetTrigger("FadeOut")
    self.animatorActivityMap:SetTrigger("FadeIn")
  else
    self.animatorActivityMap:ResetTrigger("FadeIn")
    self.animatorActivityMap:SetTrigger("FadeOut")
  end
end

function UIActivityCafeMainPanel:OnClickCollectAllSynthesis()
  if self.state == ActivitySimState.End then
    return
  end
  if NetCmdActivitySimData:IsFullPackage() then
    CS.PopupMessageManager.PopupString(TableData.GetActivityHint(23003006, self.activityConfigData.Id, 2, LuaUtils.EnumToInt(SubmoduleType.ActivitySimCafe), 101))
  elseif self.hasSynthesis then
    local getTable = {}
    local countList = {}
    for synthesis, synthesisCount in pairs(self.synthesisTable) do
      if 0 < synthesisCount then
        getTable[synthesis] = synthesisCount
        table.insert(countList, synthesisCount)
      end
    end
    NetCmdActivitySimData:CSSimCafeSynthesisCollectAll(function()
    end)
  end
end

function UIActivityCafeMainPanel:ShowDialog()
  local key = ""
  local isFirstOpen = false
  local entranceData = NetCmdActivityDarkZone:GetActivityEntranceData(self.activityConfigData.id, self.state)
  if not entranceData then
    return
  end
  key = AccountNetCmdHandler:GetUID() .. ActivityCafeGlobal.FormalDialogKey .. entranceData.plan_id
  isFirstOpen = PlayerPrefs.GetInt(key, -1) < 0
  if self.state == ActivitySimState.WarmUp and isFirstOpen then
    PlayerPrefs.SetInt(key, 1)
    ActivityCafeGlobal.IsReadyStartTutorial = false
    UIManager.OpenUIByParam(UIDef.UIActivityCafePreheatStartDialog, {
      activityEntranceData = entranceData,
      activityConfigData = self.activityConfigData,
      activityModuleData = self.activityModuleData
    })
  elseif self.state == ActivitySimState.Official and isFirstOpen then
    PlayerPrefs.SetInt(key, 1)
    ActivityCafeGlobal.IsReadyStartTutorial = false
    UIManager.OpenUIByParam(UIDef.UIActivityCafeStartDialog, {
      activityEntranceData = entranceData,
      activityConfigData = self.activityConfigData,
      activityModuleData = self.activityModuleData
    })
  end
end

function UIActivityCafeMainPanel:UpdateScoreText()
  self.ui.mText_Num1.text = NetCmdActivitySimData:GetCafeTotalCustomer()
  self.ui.mText_Num.text = NetCmdActivitySimData:GetCafeTotalScore()
end

function UIActivityCafeMainPanel:ReleaseTimer()
  if ActivityCafeGlobal.stateChangeTimer then
    ActivityCafeGlobal.stateChangeTimer:Stop()
    ActivityCafeGlobal.stateChangeTimer = nil
  end
end

function UIActivityCafeMainPanel:CreateStageChangeTimer()
  gfdebug("self.closeTime" .. tostring(CS.CGameTime.ConvertLongToDateTime(self.closeTime)))
  if self.closeTime == nil then
    return
  end
  local repeatCount = self.closeTime - CGameTime:GetTimestamp() + 1
  self:ReleaseTimer()
  ActivityCafeGlobal.stateChangeTimer = TimerSys:DelayCall(1, function()
    if CGameTime:GetTimestamp() >= self.closeTime then
      self:ReleaseTimer()
      local ConfigData = NetCmdActivityDarkZone:GetCurrActivityConfig(self.activityConfigData.id)
      if not ConfigData then
        MessageBox.Show(TableData.GetHintById(64), TableData.GetHintById(270144), nil, function()
          UISystem:JumpToMainPanel()
        end, UIGroupType.Default)
        return
      end
      if ConfigData.ActivityEntrance.Count == 3 then
        if self.state == ActivitySimState.WarmUp or self.state == ActivitySimState.End then
          MessageBox.Show(TableData.GetHintById(64), TableData.GetHintById(270144), nil, function()
            UISystem:JumpToMainPanel()
          end, UIGroupType.Default)
        elseif self.state == ActivitySimState.Official then
          self:BlackJump()
        end
      elseif ConfigData.ActivityEntrance.Count == 4 then
        if self.state == ActivitySimState.WarmUp or self.state == ActivitySimState.Official or self.state == ActivitySimState.End then
          MessageBox.Show(TableData.GetHintById(64), TableData.GetHintById(270144), nil, function()
            UISystem:JumpToMainPanel()
          end, UIGroupType.Default)
        elseif self.state == ActivitySimState.OfficialDown then
          self:BlackJump()
        end
      end
    end
  end, nil, repeatCount)
end

function UIActivityCafeMainPanel:BlackJump()
  CS.PopupMessageManager.PopupDZStateChangeString(TableData.GetHintById(271162), function()
    if NetCmdActivitySimData.IsOpenDarkzone then
      if self.blackTimer then
        self.blackTimer:Stop()
        self.blackTimer = nil
      end
      UISystem.UISystemBlackCanvas:PlayFadeOutEnhanceBlack(0.33, function()
        self.blackTimer = TimerSys:DelayCall(1, function()
          UISystem.UISystemBlackCanvas:PlayFadeInEnhanceBlack(0.33, function()
          end)
        end)
      end)
      UISystem:JumpToMainPanel()
    else
      UISystem:JumpToMainPanel()
    end
  end)
end

function UIActivityCafeMainPanel:UpdateRedPoint()
  if (self.state == ActivitySimState.Official or self.state == ActivitySimState.OfficialDown) and self.isPlanOpen == true then
    setactive(self.ui.mTrans_PadRedPoint, NetCmdActivitySimData:GetStoreUpgradeRedDot() or NetCmdActivitySimData:GetMenuUpgradeRedDot() or NetCmdActivitySimData:GetShopTabRedDot() or NetCmdCafeTablet:IsHaveCompletedTaskByCurrCafeLevel() or NetCmdCafeTablet:IsNeedRedPointOnMatchGame())
  elseif self.state == ActivitySimState.WarmUp then
    setactive(self.ui.mTrans_PadRedPoint, NetCmdActivitySimData:GetPreheatMainPanelRedDot() or NetCmdActivitySimData:GetPreheatOrderPanelRedDot())
  else
    setactive(self.ui.mTrans_PadRedPoint, false)
  end
  if self.jumpItemTable then
    for i = 1, #self.jumpItemTable do
      self.jumpItemTable[i]:UpdateRedPoint()
    end
  end
end

function UIActivityCafeMainPanel:OnJumpClick()
  self.isJumpTo = true
  self:UpdateJumpItem(false)
  setactive(self.ui.mTrans_GrpReward, false)
  self:ShowMapAnimation(false)
end

function UIActivityCafeMainPanel:UpdateJumpItem(isShow)
end

function UIActivityCafeMainPanel:OnClickChapterEntry()
  local chapterIdForStory
  for k, v in pairs(self.activityModuleData.activity_submodule) do
    if k == 2001 then
      chapterIdForStory = v
      break
    end
  end
  local chapterData = TableDataBase.listChapterDatas:GetDataById(chapterIdForStory)
  if not chapterData then
    gferror("chapterData is null")
    return
  end
  local difficultyId = NetCmdDungeonData:GetRecordedDifficultyIdByGroup(chapterData.difficulty_group)
  local targetChapterData = NetCmdDungeonData:GetStoryCharterDataByDifficultyGroup(chapterData.difficulty_group, difficultyId)
  if not targetChapterData then
    gferror("targetChapterData is null")
    return
  end
  UIManager.OpenUIByParam(UIDef.UIActivityCafeChapterPanel, {
    ChapterData = targetChapterData,
    ActivityConfigId = self.activityConfigData.Id,
    ActivityModuleData = self.activityModuleData
  })
end

function UIActivityCafeMainPanel:OnClickChallengeEntry()
  local chapterId
  for k, v in pairs(self.activityModuleData.activity_submodule) do
    if k == 2002 then
      chapterId = v
    end
  end
  if not chapterId then
    gferror("ChapterId is nil!")
    return
  end
  local chapterData = TableData.listChapterDatas:GetDataById(chapterId)
  if chapterData == nil then
    return
  end
  local configData = NetCmdActivityDarkZone:GetCurrActivityConfig(self.activityConfigData.id)
  if not configData then
    return
  end
  if not self.activityConfigData then
    return
  end
  local entranceData = NetCmdActivityDarkZone:GetActivityEntranceData(self.activityConfigData.id, self.state)
  if not entranceData then
    return
  end
  UIManager.OpenUIByParam(UIDef.UIActivityCafeChallengePanel, {
    ChapterData = chapterData,
    PlanId = entranceData.plan_id,
    ActivityConfigId = self.activityConfigData.Id
  })
end

function UIActivityCafeMainPanel:SetMachineInfoAudio(isEnable)
  if self.machineInfoTable ~= nil then
    for _, item in pairs(self.machineInfoTable) do
      item:SetMachineInfoAudio(isEnable)
    end
  end
end

function UIActivityCafeMainPanel:PlayAudioByVision(vision)
  if vision == 1 or vision == 2 then
    AudioUtils.PlayBGMById(90)
    AudioUtils.PlayCommonAudio(90093)
    self:SetMachineInfoAudio(true)
  elseif vision == 3 then
    AudioUtils.PlayBGMById(89)
    AudioUtils.PlayCommonAudio(90024)
    self:SetMachineInfoAudio(false)
  end
end

function UIActivityCafeMainPanel:StopAllAudio()
  AudioUtils.StopCommonAudio(90024)
  AudioUtils.StopCommonAudio(90093)
end

function UIActivityCafeMainPanel:ShowToMainBox()
  MessageBox.Show(TableData.GetHintById(64), TableData.GetHintById(272001), nil, function()
    UISystem:JumpToMainPanel()
  end, UIGroupType.Default)
  return
end

function UIActivityCafeMainPanel:GetSimHelper()
  return CS.Activities.ActivitySim.ActivitySimHelper.Instance
end

function UIActivityCafeMainPanel:IsReadyStartTutorial()
  return ActivityCafeGlobal.IsReadyStartTutorial
end

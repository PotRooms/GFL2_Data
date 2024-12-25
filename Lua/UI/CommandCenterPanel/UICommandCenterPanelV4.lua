require("UI.CommandCenterPanel.Item.CommanderLeftTab")
require("UI.CommandCenterPanel.Item.CommandBottomBtn")
require("UI.UIRecentActivityPanel.UIRecentActivityPanel")
require("UI.UniTopbar.UIUniTopBarPanel")
require("UI.PosterPanel.UIPosterPanel")
require("UI.PostPanelV2.UIPostBrowserPanel")
require("UI.UICommonUnlockPanel.UICommonUnlockPanel")
require("UI.CommandCenterPanel.UICommandCenterPanel")
require("UI.UniTopbar.Item.ResourcesCommonItem")
require("UI.SimCombatPanel.ResourcesCombat.UISimCombatGlobal")
UICommandCenterPanelV4 = class("self", UIBasePanel)
UICommandCenterPanelV4.__index = UICommandCenterPanelV4
UICommandCenterPanelV4.HideBlackMask = false

function UICommandCenterPanelV4:ctor(csPanel)
  self.super.ctor(self, csPanel)
  self.csPanel = csPanel
  csPanel.HideSceneBackground = false
  csPanel.Is3DPanel = true
  self.RedPointType = {
    RedPointConst.ChapterReward,
    RedPointConst.SimResourceStageIndex,
    RedPointConst.SimulateBattle,
    RedPointConst.Daily,
    RedPointConst.Notice,
    RedPointConst.Gacha,
    RedPointConst.PlayerCard,
    RedPointConst.Barracks,
    RedPointConst.PVP,
    RedPointConst.CommandCenter,
    RedPointConst.RecentActivity,
    RedPointConst.Store,
    RedPointConst.MainBattlePass,
    RedPointConst.MainPlayerInfo,
    RedPointConst.MainChapters,
    RedPointConst.MainDaily,
    RedPointConst.MainBarracks,
    RedPointConst.MainGacha,
    RedPointConst.MainRecentActivity,
    RedPointConst.NewTask,
    RedPointConst.Social,
    RedPointConst.MainGuild
  }
  self.CheckQueue = {
    None = 0,
    NickName = 1,
    Reconnection = 2,
    Poster = 3,
    Notice = 4,
    CheckIn = 5,
    operateAct = 6,
    Unlock = 7,
    Tutorial = 8,
    CareFestival = 9,
    Finish = 10
  }
  self.checkStep = 0
  self.bCanClick = true
  self.systemList = {}
  self.bottomSystemList = {}
  self.bannerList = {}
  self.leftTabItemList = {}
  self.indicatorList = {}
  self.bannerCache = {}
  self.bottomTabItemList = {}
  self.birthdayItem = nil
  self.festivalItemList = {}
end

function UICommandCenterPanelV4:OnInit(root, data)
  self.super.SetRoot(self, root)
  self.mUIRoot = root
  self.closeTime = 0
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:InitCommandCenterPanelUI()
  self:SetMaskEnable(false)
  self:InitButtonGroup()
  if self:IsShowHudBtn() then
    UIUtils.AnimatorFadeIn(self.ui.mAnim_Hud)
  end
  
  function self.systemUnLock(message)
    self:SystemUnLock(message)
  end
  
  function self.refreshInfo(message)
    self:RefreshInfo(message)
  end
  
  function self.onClickPuppy(message)
    self:OnClickHud()
  end
  
  function self.onClickPuppyCollider(message)
    if self.checkStep == self.CheckQueue.Tutorial then
      return
    end
    self:OnClickHud()
  end
  
  function self.InitFade()
    SceneSys.CurrentSingleScene:SetCameraFadedIn(false)
    SceneSys.CurrentSingleScene:CameraFadeIn()
  end
  
  function self.bannerUpdate()
    if self.skipInitBanner then
      self.skipInitBanner = nil
    else
      self:InitBanner()
    end
  end
  
  function self.onApplicationFocus(isFocus)
    if isFocus.Sender == true then
      self:RequestDeepLink()
    end
  end
  
  function self.redPointUpdate(msg)
    self:UpdatePuppyTips()
  end
  
  function self.onClickPuppyTips(message)
    self:OnClickPuppyTips()
  end
  
  function self.onBattlePassGetNewPlan(msg)
    self:OnSecondCheck()
  end
  
  function self.onUpdateFestivalBanner(msg)
    self:UpdateFestivalBanner()
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnClickPuppyTips, self.onClickPuppyTips)
  MessageSys:AddListener(CS.GF2.Message.RedPointEvent.RedPointUpdate, self.redPointUpdate)
  MessageSys:AddListener(CS.GF2.Message.SystemEvent.ApplicationFocus, self.onApplicationFocus)
  MessageSys:AddListener(CS.GF2.Message.UIEvent.BannerUpdate, self.bannerUpdate)
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnLoadingEnd, self.InitFade)
  MessageSys:AddListener(CS.GF2.Message.CampaignEvent.ResInfoUpdate, self.refreshInfo)
  MessageSys:AddListener(CS.GF2.Message.UIEvent.SystemUnlockEvent, self.systemUnLock)
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnClickPuppy, self.onClickPuppy)
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnClickPuppyCollider, self.onClickPuppyCollider)
  MessageSys:AddListener(CS.GF2.Message.UIEvent.BattlePassGetNewPlan, self.onBattlePassGetNewPlan)
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnFestivalBannerRefresh, self.onUpdateFestivalBanner)
  RedPointSystem:GetInstance():AddRedPointListener(RedPointConst.MainPlayerInfo, self.ui.mTrans_SettingsRedPoint, nil, SystemList.Commander)
  RedPointSystem:GetInstance():AddRedPointListener(RedPointConst.MainBattlePass, self.mItem_BattlePass.transRedPoint, nil, self.mItem_BattlePass.systemId)
  RedPointSystem:GetInstance():AddRedPointListener(RedPointConst.MainChapters, self.mItem_Battle.transRedPoint, nil, self.mItem_Battle.systemId)
  RedPointSystem:GetInstance():AddRedPointListener(RedPointConst.MainDaily, self.mItem_DailyTask.transRedPoint, nil, self.mItem_DailyTask.systemId)
  RedPointSystem:GetInstance():AddRedPointListener(RedPointConst.MainGuild, self.mItem_Guild.transRedPoint, nil, self.mItem_Guild.systemId)
  RedPointSystem:GetInstance():AddRedPointListener(RedPointConst.MainGacha, self.mItem_Gacha.transRedPoint)
  RedPointSystem:GetInstance():AddRedPointListener(RedPointConst.MainRecentActivity, self.mItem_Activity.transRedPoint)
  RedPointSystem:GetInstance():AddRedPointListener(RedPointConst.NewTask, self.ui.mTrans_NewTaskRedPoint)
  RedPointSystem:GetInstance():AddRedPointListener(RedPointConst.Social, self.ui.mTrans_ChatRP)
  RedPointSystem:GetInstance():AddRedPointListener(RedPointConst.Store, self.mItem_Store.transRedPoint, nil, self.mItem_Store.systemId)
  UIRedPointWatcher.BindRedPoint(self.mItem_ActivityEntrance.transRedPoint, NewRedPointConst.Activity, function(path, num)
    self:RefreshActivityEntrance()
  end)
  UIRedPointWatcher.BindRedPoint(self.mItem_Barrack.transRedPoint, NewRedPointConst.Main_Barracks)
  if self.mItem_DormEntrance ~= nil then
    UIRedPointWatcher.BindRedPoint(self.mItem_DormEntrance.transRedPoint, NewRedPointConst.Recreationdeck)
  end
  self:InitGM()
  self:DirtyRedPoint()
  NetCmdLoungeData:SetIsInMainPanel(true)
end

function UICommandCenterPanelV4:DirtyRedPoint()
  RedPointManager:SetDirty(NewRedPointConst.Recreationdeck)
end

function UICommandCenterPanelV4:RefreshActivityEntrance()
  if UIUtils.IsNullOrDestroyed(self.mUIRoot) or UIUtils.IsNullOrDestroyed(self.mItem_Activity.btn) then
    return
  end
  local isShow = NetCmdOperationActivityData:HasShowingActivity() and OpenFunctionsManager:CheckFunctionOpen(LuaUtils.EnumToInt(CS.GF2.Logic.OpenFunctionsManager.OpenFunctionsManager.OpenFunction.Activity)) == 1
  setactive(self.mItem_ActivityEntrance.btn.gameObject, isShow)
end

function UICommandCenterPanelV4:InitGM()
  if CS.DebugCenter.Instance:IsOn(CS.DebugToggleType.ShowCommandGMButton) then
    local GMItem = instantiate(UIUtils.GetGizmosPrefab("GameCommand/Btn_GMCommandEnter.prefab", self), self.mUIRoot.transform)
    GMItem.transform:SetParent(self.ui.mTrans_Root, true)
  end
end

function UICommandCenterPanelV4:HasStoryBattleStage()
  local hasReward = false
  local storyList = TableData.GetNormalChapterList()
  for i = 0, storyList.Count - 1 do
    hasReward = hasReward or 0 < NetCmdDungeonData:UpdateChatperRewardRedPoint(storyList[i].id)
  end
  local isNeedRedPoint = NetCmdSimulateBattleData:CheckTeachingUnlockRedPoint() or NetCmdSimulateBattleData:CheckTeachingRewardRedPoint() or NetCmdSimulateBattleData:CheckTeachingNoteReadRedPoint() or NetCmdSimulateBattleData:CheckTeachingNoteProgressRedPoint()
  if hasReward or isNeedRedPoint then
    return true
  end
  return false
end

function UICommandCenterPanelV4:IsShowChangeRedPoint()
  return NetCmdCommandCenterData:UpdateRedPoint() > 0
end

function UICommandCenterPanelV4:IsShowHudRedPoint()
  if self:HasStoryBattleStage() then
    return true
  elseif NetCmdSimulateBattleData:CheckSimStageIndexRedPoint(4) then
    return true
  elseif NetCmdSimulateBattleData:CheckSimBattleHasRedPoint() then
    return true
  elseif NetCmdMailData:UpdateRedPoint() > 0 then
    return true
  elseif 0 < PostInfoConfig.UpdateRedPoint() then
    return true
  elseif 0 < NetCmdIllustrationData:UpdatePlayerCardRedPoint() then
    return true
  elseif 0 < NetCmdItemData:UpdateWeaponPieceRedPoint() + NetCmdItemData:UpdateGiftPickRedPoint() then
    return true
  elseif 0 < NetCmdTeamData:UpdateBarracksRedPoint() then
    return true
  elseif 0 < NetCmdArchivesData:UpdateArchivesRedPoint() then
    return true
  elseif NetCmdRecentActivityData:CheckRecentActivityRedPoint() then
    return true
  elseif 0 < NetCmdBattlePassData:GetShowCommandSceneRedPoint() then
    return true
  elseif RedPointManager:HasRedPoint(NewRedPointConst.Activity) then
    return true
  elseif NetCmdTeachPPTData:ShowRed_Type(CS.EPPTGroupType.All) then
    return true
  elseif 0 < NetCmdStoreData:GetStoreRedPoint() then
    return true
  elseif 0 < NetCmdGuildGroupData:OnRedPoint_Guild(nil) then
    return true
  elseif 0 < NetCmdSocialData:UpdateChatRedPoint() + NetCmdSocialData:UpdateApplyRedPoint() then
    return true
  elseif 0 < NetCmdRecreationdeckData:OnRedPoint_Recreationdeck() then
    return true
  end
  return false
end

function UICommandCenterPanelV4:CheckBackground()
  local bgData = TableData.listCommandBackgroundDatas:GetDataById(NetCmdCommandCenterData.Background)
  setactive(self.ui.mBtn_Hud.transform.parent, bgData.type ~= 1)
  setactive(self.ui.mBtn_ChrSpeak.gameObject, bgData.type == 3)
  SceneSys.CurrentSingleScene:ChangeBackground()
end

function UICommandCenterPanelV4:IsShowHudBtn()
  local bgData = TableData.listCommandBackgroundDatas:GetDataById(NetCmdCommandCenterData.Background)
  return bgData.type ~= 1
end

function UICommandCenterPanelV4:UpdateTab()
  for _, item in pairs(self.leftTabItemList) do
    item:UpdateUpTips()
  end
end

function UICommandCenterPanelV4:UpdateShopTag()
  local openShop = OpenFunctionsManager:CheckFunctionOpen(16000) == 1
  setactive(self.mItem_Store.btn.gameObject, openShop)
  if self:CheckSystemIsLock(SystemList.Store) then
    setactive(self.ui.mTrans_ShopNew, false)
    setactive(self.ui.mTrans_ShopTime, false)
    return
  end
  local hasLeftTimeTip, hint = NetCmdStoreData:IsShowLeftTimePackageHint()
  if hasLeftTimeTip then
    setactive(self.ui.mTrans_ShopNew, false)
    setactive(self.ui.mTrans_ShopTime, true)
    self.ui.mText_ShopTime.text = hint
  else
    local hasNewTip = NetCmdStoreData:IsShowNewPackageHint()
    setactive(self.ui.mTrans_ShopNew, hasNewTip)
    setactive(self.ui.mTrans_ShopTime, false)
  end
end

function UICommandCenterPanelV4:SetResourceBar()
  local staminaCount = NetCmdItemData:GetItemCountById(101)
  self.ui.mText_StaminaNum.text = CS.LuaUIUtils.GetMaxNumberText(staminaCount, 6) .. "/" .. CS.LuaUIUtils.GetMaxNumberText(GlobalData.GetStaminaResourceMaxNum(101), 6)
  self.ui.mText_GemNum.text = CS.LuaUIUtils.GetMaxNumberText(NetCmdItemData:GetItemCountById(1), 6)
end

function UICommandCenterPanelV4:InitBanner()
  if OpenFunctionsManager:CheckFunctionOpen(LuaUtils.EnumToInt(CS.GF2.Logic.OpenFunctionsManager.OpenFunctionsManager.OpenFunction.Banner)) ~= 1 then
    setactive(self.ui.mSlideShowHelper_BannerList.transform.parent, false)
    return
  end
  self.ui.mSlideShowHelper_BannerList:ClearDelayList()
  local count = PostInfoConfig.BannerDataList.Count
  local dataList = {}
  setactive(self.ui.mSlideShowHelper_BannerList.transform.parent, 0 < count)
  if count == 0 then
    return
  end
  for i = 0, count - 1 do
    local d = PostInfoConfig.BannerDataList[i]
    if (d.jump_id == 13001 and (NetCmdBattlePassData.BattlePassStatus == CS.ProtoObject.BattlepassType.AdvanceOne or NetCmdBattlePassData.BattlePassStatus == CS.ProtoObject.BattlepassType.AdvanceTwo)) == false then
      table.insert(dataList, d)
    end
  end
  local dataListCount = #dataList
  self:OnHideSlideShow()
  table.insert(self.indicatorList, self.ui.mTrans_Dot.gameObject)
  local instantiateIndicatorObj = function()
    return instantiate(self.ui.mTrans_Dot.gameObject, self.ui.mTrans_Indicator.transform)
  end
  if 2 < dataListCount then
    for i = 0, dataListCount - 1 do
      if 0 < i then
        table.insert(self.indicatorList, instantiateIndicatorObj())
      end
      local start = math.floor((dataListCount + 1) / 2)
      local current = start + i
      if dataListCount <= current then
        current = current - dataListCount
      end
      self:InstantiateBanner(dataList[current + 1], function()
        if i == dataListCount - 1 then
          self.ui.mSlideShowHelper_BannerList:SetData(dataListCount)
        end
      end)
    end
    self.ui.mSlideShowHelper_BannerList.startingIndex = math.floor(dataListCount / 2)
  elseif dataListCount == 2 then
    local finished = 0
    for i = 0, dataListCount - 1 do
      if 0 < i then
        table.insert(self.indicatorList, instantiateIndicatorObj())
      end
      self:InstantiateBanner(dataList[i + 1], function()
        finished = finished + 1
        if finished == 2 then
          self:InstantiateBanner(dataList[1])
          self:InstantiateBanner(dataList[2], function()
            self.ui.mSlideShowHelper_BannerList:SetData(2)
          end)
          self.ui.mSlideShowHelper_BannerList.startingIndex = 2
        end
      end)
    end
  else
    for i = 0, dataListCount - 1 do
      if 0 < i then
        table.insert(self.indicatorList, instantiateIndicatorObj())
      end
      self:InstantiateBanner(dataList[i + 1], function()
        self:InstantiateBanner(dataList[1])
        self:InstantiateBanner(dataList[1], function()
          self.ui.mSlideShowHelper_BannerList:SetData(1)
        end)
        self.ui.mSlideShowHelper_BannerList.startingIndex = 1
      end)
    end
  end
  self.ui.mMask_Banner:SetRadius(3)
end

function UICommandCenterPanelV4:InstantiateBanner(data, callback)
  ResSys:LoadUIAssetAsync("CommandCenter/CommandcenterBanneItemV2.prefab", function(s, o, arg)
    if o then
      self:AddAsset(o)
      local bannerObj = instantiate(o)
      self:LoadBannerCallback(bannerObj, data, callback)
    else
      local bannerObj = instantiate(UIUtils.GetGizmosPrefab("CommandCenter/CommandcenterBanneItemV2.prefab", self))
      self:LoadBannerCallback(bannerObj, data, callback)
    end
  end)
end

function UICommandCenterPanelV4:LoadBannerCallback(bannerObj, data, callback)
  local button = bannerObj:GetComponent(typeof(CS.UnityEngine.UI.Button))
  if data.type_id == 0 and data.extra ~= "" then
    UIUtils.GetButtonListener(button.gameObject).onClick = function()
      if string.match(data.extra, "{uid}") then
        local text = string.gsub(data.extra, "{uid}", AccountNetCmdHandler:GetUID())
        local strings = string.split(text, "?")
        CS.GF2.ExternalTools.Browsers.BrowserHandler.Show(strings[1] .. "?token=" .. string.gsub(CS.AesUtils.Encode(strings[2]), "-", ""))
      elseif CS.AesUtils.IsBBS(data.extra) then
        CS.GF2.ExternalTools.Browsers.BrowserHandler.Show(data.extra)
      else
        CS.GF2.ExternalTools.Browsers.BrowserHandler.Show(data.extra, CS.GF2.ExternalTools.Browsers.BrowserShowType.OutSourceURL)
      end
    end
  elseif data.type_id == 3 and data.extra ~= "" then
    UIUtils.GetButtonListener(button.gameObject).onClick = function()
      local containQ = false
      for i = 1, #data.extra do
        if data.extra:sub(i, i) == "?" then
          containQ = true
          break
        end
      end
      local token = CS.GF2.SDK.PlatformLoginManager.Instance.Token
      local urlStr
      if containQ then
        urlStr = data.extra .. "&token=" .. CS.AesUtils.UrlEncode(token)
      else
        urlStr = data.extra .. "?token=" .. CS.AesUtils.UrlEncode(token)
      end
      if CS.AesUtils.IsBBS(urlStr) then
        CS.GF2.ExternalTools.Browsers.BrowserHandler.Show(urlStr)
      else
        CS.GF2.ExternalTools.Browsers.BrowserHandler.Show(urlStr, CS.GF2.ExternalTools.Browsers.BrowserShowType.OutSourceURL)
      end
    end
  elseif data.type_id == 4 and data.extra ~= "" then
    UIUtils.GetButtonListener(button.gameObject).onClick = function()
      UIManager.OpenUIByParam(UIDef.UIComTVBannerDialog, {
        url = data.extra
      })
    end
  elseif data.type_id == 5 and data.extra ~= "" then
    UIUtils.GetButtonListener(button.gameObject).onClick = function()
      CS.GF2.ExternalTools.Browsers.BrowserHandler.Show(CS.AesUtils.GetSurveyLink(data.extra), CS.GF2.ExternalTools.Browsers.BrowserShowType.OutSourceURL)
    end
  elseif data.type_id > 0 and 0 < data.jump_id then
    UIUtils.GetButtonListener(button.gameObject).onClick = function()
      local jumpData = TableData.listJumpListContentnewDatas:GetDataById(tonumber(data.jump_id))
      if jumpData.unlock_id == 0 or AccountNetCmdHandler:CheckSystemIsUnLock(jumpData.unlock_id) then
        local canJump = true
        if jumpData.behavior == 5002 then
          if tonumber(jumpData.args) ~= 0 then
            if not NetCmdOperationActivityData:HasShowingActivity() then
              canJump = false
            end
          elseif not NetCmdOperationActivityData:IsActivityOpen(tonumber(jumpData.args)) then
            canJump = false
          end
        end
        if canJump then
          self:UnRegistrationAllKeyboard()
          self:CallWithAniDelay(function()
            UISystem:JumpByID(data.jump_id)
          end)
        else
          UISystem:JumpByID(data.jump_id)
        end
      else
        local unlockData = TableData.listUnlockDatas:GetDataById(jumpData.unlock_id)
        local str = UIUtils.CheckUnlockPopupStr(unlockData)
        PopupMessageManager.PopupString(str)
      end
    end
  end
  self.ui.mSlideShowHelper_BannerList:PushLayoutElement(bannerObj, data.delay)
  table.insert(self.bannerList, bannerObj)
  local img = bannerObj.transform:Find("Img_Banner"):GetComponent(typeof(CS.UnityEngine.UI.Image))
  if self.bannerCache[data.pic_url] == nil then
    CS.LuaUtils.DownloadTextureFromUrl(data.pic_url, function(tex)
      if not CS.LuaUtils.IsNullOrDestroyed(bannerObj) and img ~= nil then
        local sprite = CS.UIUtils.TextureToSprite(tex)
        self.bannerCache[data.pic_url] = sprite
        img.sprite = sprite
      end
      if callback ~= nil and self.ui ~= nil then
        callback()
      end
    end)
  else
    img.sprite = self.bannerCache[data.pic_url]
    if callback ~= nil and self.ui ~= nil then
      callback()
    end
  end
end

function UICommandCenterPanelV4:InitButtonGroup()
  UIUtils.GetButtonListener(self.mItem_Battle.btn.gameObject).onClick = function()
    self:OnClickBattle()
  end
  UIUtils.GetButtonListener(self.mItem_Gacha.btn.gameObject).onClick = function()
    self:OnClickGacha()
  end
  if self.mItem_DormEntrance ~= nil then
    UIUtils.GetButtonListener(self.mItem_DormEntrance.btn.gameObject).onClick = function()
      self:OnClickDormEntrance()
    end
  end
  UIUtils.GetButtonListener(self.mItem_DailyTask.btn.gameObject).onClick = function()
    self:OnClickDailyQuest()
  end
  UIUtils.GetButtonListener(self.mItem_Guild.btn.gameObject).onClick = function()
    self:OnClickGuild()
  end
  UIUtils.GetButtonListener(self.mItem_Barrack.btn.gameObject).onClick = function()
    self:OnClickBarrack()
  end
  UIUtils.GetButtonListener(self.mItem_Store.btn.gameObject).onClick = function()
    self:OnClickStore()
  end
  UIUtils.GetButtonListener(self.mItem_BattlePass.btn.gameObject).onClick = function()
    self:OnClickBattlePass()
  end
  UIUtils.GetButtonListener(self.mItem_Activity.btn.gameObject).onClick = function()
    self:OnClickRecentActivity()
  end
  UIUtils.GetButtonListener(self.mItem_ActivityEntrance.btn.gameObject).onClick = function()
    self:OnClickActivityEntrance()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Hud.gameObject).onClick = function()
    self:OnClickHud()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BgChange.gameObject).onClick = function()
    self:OnClickChangeBg()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Settings.gameObject).onClick = function()
    self:OnClickSettings()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_NewTask.gameObject).onClick = function()
    self:OnClickNewTask()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Gem.gameObject).onClick = function()
    self.isHide = true
    UISystem:JumpByID(3)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Stamina.gameObject).onClick = function()
    self.isHide = true
    UISystem:JumpByID(2)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_ArchivesCenter.gameObject).onClick = function()
    self:OnClickArchives()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Repository.gameObject).onClick = function()
    self:OnClickRepository()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Post.gameObject).onClick = function()
    self.isHide = true
    self:OnClickPost()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_CheckIn.gameObject).onClick = function()
    self.isHide = true
    self:OnClickCheckIn()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Mail.gameObject).onClick = function()
    self:OnClickMail()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Chat.gameObject).onClick = function()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BgChat.gameObject).onClick = function()
    self:OnClickChat()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_ChrSpeak.gameObject).onClick = function()
    self:OnClickChrSpeak()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_RecentActivity.gameObject).onClick = function()
    self:OnClickThemeActivity()
  end
end

function UICommandCenterPanelV4:InitCommandCenterPanelUI()
  local dataList = TableData.listCommandHomepageDatas:GetList()
  local tabTable = {}
  for i = 0, dataList.Count - 1 do
    local data = dataList[i]
    if data.Type == 2 then
      table.insert(tabTable, data)
    end
  end
  table.sort(tabTable, function(a, b)
    return a.Sort < b.Sort
  end)
  for _, item in pairs(self.leftTabItemList) do
    item:OnRelease()
  end
  self.leftTabItemList = {}
  for _, tab in pairs(tabTable) do
    local item = CommanderLeftTab.New()
    item:InitCtrl(self.ui.mScrollListChild_Tab)
    item:SetData(tab, tab.id)
    table.insert(self.leftTabItemList, item)
    if tab.id == 13000 then
      self.mItem_Gacha = item
      setactive(item.transRedPoint, false)
    elseif tab.id == 15200 then
      self.mItem_DormEntrance = item
    elseif tab.id == 12000 then
      self.mItem_Barrack = item
    elseif tab.id == 16000 then
      self.mItem_Store = item
    elseif tab.id == 29202 then
      self.mItem_Activity = item
    end
    table.insert(self.systemList, item)
  end
  self.mItem_Battle = self:InitBattle(self.ui.mTrans_SimCombat, SystemList.Battle)
  self.mItem_ActivityEntrance = self:InitCommandBottomBtn(self.ui.mBtn_GrpActivity.gameObject, SystemList.Activity, "Activity")
  self.mItem_BattlePass = self:InitCommandBottomBtn(self.ui.mBtn_GrpBp.gameObject, SystemList.Battlepass, "BP")
  self.mItem_DailyTask = self:InitCommandBottomBtn(self.ui.mBtn_GrpQuest.gameObject, SystemList.Quest, "Entrust")
  self.mItem_Guild = self:InitCommandBottomBtn(self.ui.mBtn_GrpGuild.gameObject, SystemList.Guild, "Union")
end

function UICommandCenterPanelV4:InitCommandBottomBtn(go, systemId, iconName)
  local CommandBottomBtn = CommandBottomBtn.New()
  CommandBottomBtn:InitCtrl(go, systemId, iconName)
  table.insert(self.bottomSystemList, CommandBottomBtn)
  CommandBottomBtn:CheckUnLock()
  return CommandBottomBtn
end

function UICommandCenterPanelV4:InitBattle(btn, systemId)
  local parent = btn:GetComponent(typeof(CS.UnityEngine.RectTransform))
  if parent then
    local item = {}
    item.systemId = systemId
    item.parent = parent
    item.btn = self.ui.mBtn_GrpSimCombat
    item.transRedPoint = self.ui.mTrans_BattleRedPoint
    table.insert(self.systemList, item)
    return item
  end
end

function UICommandCenterPanelV4:SystemUnLock()
  self:UpdateSystemUnLockInfo()
end

function UICommandCenterPanelV4:RefreshInfo()
  self:UpdateSystemUnLockInfo()
end

function UICommandCenterPanelV4:UpdateSystemUnLockInfo()
  for i, item in ipairs(self.systemList) do
    self:UpdateSystemUnLockInfoByItem(item)
  end
  for i, item in ipairs(self.bottomSystemList) do
    self:UpdateSystemUnLockInfoByBottomItem(item)
  end
end

function UICommandCenterPanelV4:UpdateSystemUnLockInfoByBottomItem(item)
  if item and item.systemId then
    item:CheckUnLock()
  end
end

function UICommandCenterPanelV4:UpdateSystemUnLockInfoByItem(item)
  if item and item.systemId then
    local isLock = self:CheckSystemIsLock(item.systemId)
    if item.animator then
      item.animator:SetBool("Unlock", not isLock)
    end
  end
end

function UICommandCenterPanelV4:CheckSystemIsLock(type)
  return not AccountNetCmdHandler:CheckSystemIsUnLock(type)
end

function UICommandCenterPanelV4:InitRedPointObj()
  for i, item in ipairs(self.systemList) do
    if item.systemId == SystemList.RecentActivity or item.transRedPoint then
    end
  end
end

function UICommandCenterPanelV4:InitKeyCode()
  self:RegistrationKeyboard(KeyCode.Escape, self.ui.mBtn_Settings)
  self:RegistrationKeyboard(KeyCode.I, self.ui.mBtn_Settings)
  self:RegistrationKeyboard(KeyCode.Tab, self.ui.mBtn_BgChange)
  self:RegistrationKeyboard(KeyCode.U, self.mItem_DailyTask.btn)
  self:RegistrationKeyboard(KeyCode.G, self.mItem_Gacha.btn)
  self:RegistrationKeyboard(KeyCode.C, self.mItem_Barrack.btn)
  self:RegistrationKeyboard(KeyCode.D, self.mItem_Activity.btn)
  self:RegistrationKeyboard(KeyCode.V, self.mItem_BattlePass.btn)
  self:RegistrationKeyboard(KeyCode.F, self.mItem_ActivityEntrance.btn)
  self:RegistrationKeyboard(KeyCode.E, self.mItem_Store.btn)
  self:RegistrationKeyboard(KeyCode.O, self.ui.mBtn_Post)
  self:RegistrationKeyboard(KeyCode.Q, self.ui.mBtn_Hud)
  self:RegistrationKeyboard(KeyCode.M, self.ui.mBtn_Mail)
  self:RegistrationKeyboard(KeyCode.BackQuote, self.ui.mBtn_BgChat)
  self:RegistrationKeyboard(KeyCode.K, self.ui.mBtn_ArchivesCenter)
  self:RegistrationKeyboard(KeyCode.J, self.ui.mBtn_CheckIn)
  self:RegistrationKeyboard(KeyCode.B, self.ui.mBtn_Repository)
  if self.mItem_DormEntrance ~= nil then
    self:RegistrationKeyboard(KeyCode.L, self.mItem_DormEntrance.btn)
  end
  self:RegistrationKeyboard(KeyCode.T, self.mItem_Guild.btn)
end

function UICommandCenterPanelV4.Close()
  UIManager.CloseUI(UIDef.UICommandCenterPanel)
end

local lastUpdateTime = 0

function UICommandCenterPanelV4:OnUpdate()
  self:SetResourceBar()
  self:UpdateTab()
  if Time.time - lastUpdateTime >= 1 then
    lastUpdateTime = Time.time
    self:UpdateShopTag()
  end
end

function UICommandCenterPanelV4:RequestDeepLink()
  if LuaUtils.IsIOS() then
    CS.GF2.SDK.PlatformLoginManager.Instance:GetDeeplinkParam()
    if self.deeplinkTimer ~= nil then
      self.deeplinkTimer:Stop()
      self.deeplinkTimer = nil
    end
    self.deeplinkTimer = TimerSys:DelayCall(1, function()
      if UISystem:GetTopUI(UIGroupType.Default).UIDefine.UIType == UIDef.UICommandCenterPanel then
        self:OnUpdateDeepLinkParam()
      end
    end)
  end
end

function UICommandCenterPanelV4:OnUpdateDeepLinkParam()
  if LuaUtils.IsIOS() and (self.checkStep == self.CheckQueue.None or self.checkStep == self.CheckQueue.Finish) and CS.GF2.SDK.PlatformLoginManager.Instance.DeepLinkParam ~= nil and CS.GF2.SDK.PlatformLoginManager.Instance.DeepLinkParam ~= "" then
    gfwarning("DeepLinkParam " .. CS.GF2.SDK.PlatformLoginManager.Instance.DeepLinkParam)
    local ids = TableData.listDeeplinkByGroupDatas:GetDataById(1).Id
    for i = 0, ids.Count - 1 do
      local id = ids[i]
      local linkData = TableData.listDeeplinkDatas:GetDataById(id)
      if linkData.link == CS.GF2.SDK.PlatformLoginManager.Instance.DeepLinkParam then
        do
          local jumpData = TableData.listJumpListContentnewDatas:GetDataById(linkData.jump)
          if jumpData.unlock_id == 0 or AccountNetCmdHandler:CheckSystemIsUnLock(jumpData.unlock_id) then
            self:UnRegistrationAllKeyboard()
            self:CallWithAniDelay(function()
              UISystem:JumpByID(linkData.jump)
            end)
            break
          end
          gfwarning("DeepLinkParam linkData.jump \230\156\170\232\167\163\233\148\129")
          break
        end
      end
    end
    CS.GF2.SDK.PlatformLoginManager.Instance:DeleteDeeplinkParam()
  end
end

function UICommandCenterPanelV4:OnCameraBack()
  if UISystem:GetTopUI(UIGroupType.Default).UIDefine.UIType == UIDef.UICommandCenterHudPanel or UISystem:GetTopUI(UIGroupType.Default).UIDefine.UIType == UIDef.UICommandCenterBgChangePanel then
    return 0.01
  else
    return 0
  end
end

function UICommandCenterPanelV4:OnClickPuppyTips()
  if UISystem:GetTopUI().UIDefine.UIType ~= UIDef.UICommandCenterPanel then
    return
  end
  if self.ui.mTrans_Mask.gameObject.activeSelf then
    return
  end
  if self.blockTimer ~= nil then
    return
  end
  if self.isHide ~= nil and self.isHide then
    return
  end
  if self.checkStep == self.CheckQueue.Unlock or self.checkStep == self.CheckQueue.Tutorial then
    return
  end
  AudioUtils.PlayCommonAudio(1020107)
  if not self:CheckSystemIsLock(SystemList.Mail) and NetCmdMailData:UpdateRedPoint() > 0 then
    self:UnRegistrationAllKeyboard()
    self:CallWithAniDelay(function()
      NetCmdMailData:SendReqRoleMailsCmd(function()
        UIManager.OpenUI(CS.GF2.UI.enumUIPanel.UIMailPanel)
      end)
    end)
  elseif 0 < NetCmdSocialData:UpdateApplyRedPoint() then
    self:OnClickFriend(2)
  end
end

function UICommandCenterPanelV4:HidePuppyRedPoint()
  local bgData = TableData.listCommandBackgroundDatas:GetDataById(NetCmdCommandCenterData.Background)
  if bgData.type == 1 and self.puppyRedPoint ~= nil then
    local animator = self.puppyRedPoint:Find("Icon"):GetComponent(typeof(CS.UnityEngine.Animator))
    if animator ~= nil then
      animator:SetTrigger("FadeOut")
      TimerSys:DelayCall(0.4, function()
        setactive(self.puppyRedPoint, false)
      end)
    end
  end
end

function UICommandCenterPanelV4:HidePuppyTips()
  local bgData = TableData.listCommandBackgroundDatas:GetDataById(NetCmdCommandCenterData.Background)
  if bgData.type == 1 then
    if self.puppyTipsTrans ~= nil then
      local animator = self.puppyTipsTrans:Find("Dinergate_TipsIcon"):GetComponent(typeof(CS.UnityEngine.Animator))
      if animator ~= nil then
        animator:SetTrigger("FadeOut")
        TimerSys:DelayCall(0.4, function()
          setactive(self.puppyTipsTrans, false)
        end)
      end
    end
  elseif bgData.type == 3 then
  end
end

function UICommandCenterPanelV4:UpdatePuppyTips()
  for _, item in pairs(self.leftTabItemList) do
    item:UpdateData()
  end
  local bgData = TableData.listCommandBackgroundDatas:GetDataById(NetCmdCommandCenterData.Background)
  if bgData.type == 1 then
    if self.puppyTipsTrans ~= nil then
      if not self:CheckSystemIsLock(SystemList.Mail) and NetCmdMailData:UpdateRedPoint() > 0 or 0 < NetCmdSocialData:UpdateApplyRedPoint() then
        local mat = self.puppyTipsTrans:Find("Dinergate_TipsIcon/3Point/GrpImg/Icon"):GetComponent(typeof(CS.UnityEngine.MeshRenderer)).materials[0]
        if not self:CheckSystemIsLock(SystemList.Mail) and NetCmdMailData:UpdateRedPoint() > 0 then
          local sprite = IconUtils.GetCommandCenterIcon("Icon_CommandCenter_LeftMail")
          if mat ~= nil and sprite ~= nil then
            mat:SetTexture("_MainTex", sprite.texture)
          end
        elseif 0 < NetCmdSocialData:UpdateApplyRedPoint() then
          local sprite = IconUtils.GetCommandCenterIcon("Icon_CommandCenter_LeftFriend")
          if mat ~= nil and sprite ~= nil then
            mat:SetTexture("_MainTex", sprite.texture)
          end
        end
        setactive(self.puppyTipsTrans, true)
        return
      end
      setactive(self.puppyTipsTrans, false)
    end
  else
    if not self:CheckSystemIsLock(SystemList.Mail) and NetCmdMailData:UpdateRedPoint() > 0 or 0 < NetCmdSocialData:UpdateApplyRedPoint() then
      setactive(self.ui.mBtn_PuppyTips, true)
      if not self:CheckSystemIsLock(SystemList.Mail) and NetCmdMailData:UpdateRedPoint() > 0 then
        self.ui.mImg_PuppyTipsIcon.sprite = IconUtils.GetCommandCenterIcon("Icon_CommandCenter_LeftMail")
        UIUtils.GetButtonListener(self.ui.mBtn_PuppyTips.gameObject).onClick = function()
          AudioUtils.PlayCommonAudio(1020107)
          self:UnRegistrationAllKeyboard()
          self:CallWithAniDelay(function()
            NetCmdMailData:SendReqRoleMailsCmd(function()
              UIManager.OpenUI(CS.GF2.UI.enumUIPanel.UIMailPanel)
            end)
          end)
        end
      elseif 0 < NetCmdSocialData:UpdateApplyRedPoint() then
        self.ui.mImg_PuppyTipsIcon.sprite = IconUtils.GetCommandCenterIcon("Icon_CommandCenter_LeftFriend")
        UIUtils.GetButtonListener(self.ui.mBtn_PuppyTips.gameObject).onClick = function()
          self:OnClickFriend(2)
        end
      end
      return
    end
    setactive(self.ui.mBtn_PuppyTips, false)
  end
end

function UICommandCenterPanelV4:OnShowFinish()
  CS.NetCmdTimerData.Instance:SetNextDay(false)
  self:UpdateNewTask(true)
  self:OnSecondCheck()
  self:UpdateFestivalBanner()
  CS.ResUpdateSys.Instance:ForceDownloadUpdatePostData()
  if self.checkStep == self.CheckQueue.None or self.checkStep == self.CheckQueue.Finish then
    self:InitKeyCode()
  end
  self:UpdateRedPoint()
  local activityRedState = NetCmdThemeData:GetThemeRedState() == 1 and AccountNetCmdHandler:CheckSystemIsUnLock(self.mItem_Activity.systemId)
  local recentRed = NetCmdRecentActivityData:CheckAllRecentActivityRedPoint()
  local fightRed = NetCmdControlFightData:ControlFightHasRedPoint()
  setactive(self.mItem_Activity.transRedPoint, activityRedState or recentRed or fightRed)
  setactive(self.mItem_Activity.transActivitiesOpen, NetCmdThemeData:GetThemeRedState() ~= 3 and NetCmdThemeData:GetActivityIsOpen())
  self:UpdateSystemUnLockInfo()
  setactive(self.ui.mTrans_ChangeRedPoint, self:IsShowChangeRedPoint())
  local IsOpenFriend = OpenFunctionsManager:CheckFunctionOpen(23000) == 1 and OpenFunctionsManager:CheckFunctionOpen(23001) == 1
  setactive(self.ui.mTrans_Chat, not self:CheckSystemIsLock(SystemList.Friend) and IsOpenFriend)
  self.ui.mText_Lv.text = TableData.GetHintById(160022) .. " " .. AccountNetCmdHandler:GetLevel()
  self.ui.mText_UID.text = "UID " .. AccountNetCmdHandler:GetUID()
  self.puppyTipsTrans = nil
  self.puppyRedPoint = nil
  self:UpdatePuppyTips()
  SceneSys.CurrentSingleScene:ResetBlurTween()
  if SceneSys.CurrentSingleScene.LastPanelID ~= 2100 and SceneSys.CurrentSingleScene.LastPanelID ~= 2400 then
    SceneSys.CurrentSingleScene:CameraFadeIn()
  end
  if self.secondCheckTimer == nil then
    self.secondCheckTimer = TimerSys:DelayCall(1, function()
      if not CS.CriWareAudioController.IsVoicePlaying() then
      end
    end, nil, -1)
  end
  self:DirtyRedPoint()
  NetCmdLoungeData.IsDormMute = false
  SceneSys.CurrentSingleScene:PlayBGM()
  setactive(self.ui.mTrans_HudRedPoint, self:IsShowHudRedPoint())
  if SceneSys.CurrentSingleScene.AnimatorPuppy ~= nil then
    if SceneSys.CurrentSingleScene.AnimatorPuppy.transform:Find("root/Root_M/Dinergate_commendCenter_HUD_Point_Base") ~= nil then
      setactive(SceneSys.CurrentSingleScene.AnimatorPuppy.transform:Find("root/Root_M/Dinergate_commendCenter_HUD_Point_Base"), not self:IsShowHudRedPoint())
    end
    if SceneSys.CurrentSingleScene.AnimatorPuppy.transform:Find("root/Root_M/Dinergate_commendCenter_HUD_Point_RedPoint") ~= nil then
      self.puppyRedPoint = SceneSys.CurrentSingleScene.AnimatorPuppy.transform:Find("root/Root_M/Dinergate_commendCenter_HUD_Point_RedPoint")
      setactive(self.puppyRedPoint, self:IsShowHudRedPoint())
    end
    if SceneSys.CurrentSingleScene.AnimatorPuppy.transform:Find("root/Root_M/Dinergate_commendCenter_HUD_Point_TipsIcon") ~= nil then
      self.puppyTipsTrans = SceneSys.CurrentSingleScene.AnimatorPuppy.transform:Find("root/Root_M/Dinergate_commendCenter_HUD_Point_TipsIcon")
    end
    if self:IsShowHudRedPoint() then
      SceneSys.CurrentSingleScene.AnimatorPuppy:SetTrigger("start_hint")
    else
      SceneSys.CurrentSingleScene.AnimatorPuppy:SetTrigger("fadeIn")
    end
  end
  self:OnPlayFestivalBanner(0)
end

function UICommandCenterPanelV4:OnSecondCheck()
  local isCurBpOpen = NetCmdBattlePassData:CheckCurBpIsOpen() and AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.Battlepass)
  local isActivityShow = NetCmdOperationActivityData:HasShowingActivity() and OpenFunctionsManager:CheckFunctionOpen(LuaUtils.EnumToInt(CS.GF2.Logic.OpenFunctionsManager.OpenFunctionsManager.OpenFunction.Activity)) == 1
  local isQuestShow = AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.Quest)
  local IsOpenGuild = OpenFunctionsManager:CheckFunctionOpen(50000) == 1
  local isGuildShow = AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.Guild) and NetCmdGuildGroupData:IsInOpenTime() and IsOpenGuild
  setactive(self.ui.mTrans_LineActivity, isActivityShow and isCurBpOpen)
  setactive(self.ui.mTrans_LineQuest, isQuestShow and (isActivityShow or isCurBpOpen))
  setactive(self.ui.mTrans_LineGuild, isGuildShow and (isActivityShow or isCurBpOpen or isQuestShow))
  setactive(self.mItem_BattlePass.btn.gameObject, isCurBpOpen)
  setactive(self.mItem_ActivityEntrance.btn.gameObject, isActivityShow)
  setactive(self.mItem_DailyTask.btn.gameObject, isQuestShow)
  setactive(self.mItem_Guild.btn.gameObject, isGuildShow)
end

function UICommandCenterPanelV4:OnRecover(data, behaviorId, isTop)
  if isTop then
    self:StartCommanderCheckQueue()
    self:CheckBackground()
  end
  self.isRecover = true
  self.skipInitBanner = nil
end

function UICommandCenterPanelV4:OnShowStart()
  self:StartCommanderCheckQueue()
  self:CheckBackground()
  self.isHide = false
  self.skipInitBanner = nil
  if LoungeHelper.IsCameraActive() then
    LoungeHelper.CameraCtrl.enabled = false
  end
end

function UICommandCenterPanelV4:OnBackFrom()
  if self.isRecover == true then
    SceneSys.CurrentSingleScene:SetCameraFadedIn(false)
    self.isRecover = nil
  end
  self.isHide = false
  self:StartCommanderCheckQueue()
  self:UpdateNewTask()
  self:UpdateFestivalBanner()
  self:OnSecondCheck()
  self:CheckBackground()
  self:DirtyRedPoint()
  self.skipInitBanner = nil
  MessageSys:SendMessage(UIEvent.OnBackToCommandCenterScene, nil)
end

function UICommandCenterPanelV4:OnHide()
  self.isHide = true
  if self.secondCheckTimer ~= nil then
    self.secondCheckTimer:Stop()
    self.secondCheckTimer = nil
  end
end

function UICommandCenterPanelV4:OnHideFinish()
  self:OnHideSlideShow()
  SceneSys.CurrentSingleScene:StopVoice()
  if self.isHud then
    SceneSys.CurrentSingleScene:SetCameraFadedIn(true)
    self.isHud = false
    return
  end
  SceneSys.CurrentSingleScene:SetCameraFadedIn(false)
  self:OnPlayFestivalBanner(1)
end

function UICommandCenterPanelV4:OnBeCovered()
  SceneSys.CurrentSingleScene:StopVoice()
  NetCmdLoungeData.IsDormMute = true
end

function UICommandCenterPanelV4:OnHideSlideShow()
  self.ui.mSlideShowHelper_BannerList:StopLerping()
  for i = 1, #self.bannerList do
    self.ui.mSlideShowHelper_BannerList:PopLayoutElement()
  end
  self.bannerList = {}
  for i = 2, #self.indicatorList do
    gfdestroy(self.indicatorList[i])
  end
  self.indicatorList = {}
end

function UICommandCenterPanelV4:OnPlayFestivalBanner(param)
  if self.birthdayItem ~= nil then
    self.birthdayItem:PlayFade(param)
  end
  for _, item in pairs(self.festivalItemList) do
    item:PlayFade(param)
  end
end

function UICommandCenterPanelV4:OnClose()
  SceneSys.CurrentSingleScene:StopVoice()
  self:OnHideSlideShow()
  self.ui = nil
  self.checkStep = 0
  for i, sprite in pairs(self.bannerCache) do
    gfdestroy(sprite)
  end
  self.bannerCache = {}
  for _, item in pairs(self.leftTabItemList) do
    item:OnRelease()
  end
  if self.birthdayItem ~= nil then
    self.birthdayItem:OnRelease()
    self.birthdayItem = nil
  end
  for _, item in pairs(self.festivalItemList) do
    item:OnRelease()
  end
  self.festivalItemList = {}
  if self.deeplinkTimer ~= nil then
    CS.GF2.SDK.PlatformLoginManager.Instance:DeleteDeeplinkParam()
    self.deeplinkTimer:Stop()
    self.deeplinkTimer = nil
  end
  if self.secondCheckTimer ~= nil then
    self.secondCheckTimer:Stop()
    self.secondCheckTimer = nil
  end
  if self.blockTimer ~= nil then
    self.blockTimer:Stop()
    self.blockTimer = nil
  end
  self.leftTabItemList = {}
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnClickPuppyTips, self.onClickPuppyTips)
  MessageSys:RemoveListener(CS.GF2.Message.RedPointEvent.RedPointUpdate, self.redPointUpdate)
  MessageSys:RemoveListener(CS.GF2.Message.SystemEvent.ApplicationFocus, self.onApplicationFocus)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.BannerUpdate, self.bannerUpdate)
  MessageSys:RemoveListener(CS.GF2.Message.CampaignEvent.ResInfoUpdate, self.refreshInfo)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.SystemUnlockEvent, self.systemUnLock)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnLoadingEnd, self.InitFade)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnClickPuppy, self.onClickPuppy)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnClickPuppyCollider, self.onClickPuppyCollider)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.BattlePassGetNewPlan, self.onBattlePassGetNewPlan)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnFestivalBannerRefresh, self.onUpdateFestivalBanner)
  RedPointSystem:GetInstance():RemoveRedPointListener(RedPointConst.MainPlayerInfo)
  RedPointSystem:GetInstance():RemoveRedPointListener(RedPointConst.MainBattlePass)
  RedPointSystem:GetInstance():RemoveRedPointListener(RedPointConst.MainChapters)
  RedPointSystem:GetInstance():RemoveRedPointListener(RedPointConst.MainDaily)
  RedPointSystem:GetInstance():RemoveRedPointListener(RedPointConst.MainBarracks)
  RedPointSystem:GetInstance():RemoveRedPointListener(RedPointConst.MainRecentActivity)
  RedPointSystem:GetInstance():RemoveRedPointListener(RedPointConst.MainGacha)
  RedPointSystem:GetInstance():RemoveRedPointListener(RedPointConst.NewTask)
  RedPointSystem:GetInstance():RemoveRedPointListener(RedPointConst.Store)
  RedPointSystem:GetInstance():RemoveRedPointListener(RedPointConst.Social)
  RedPointSystem:GetInstance():RemoveRedPointListener(RedPointConst.MainGuild)
  NetCmdLoungeData:SetIsInMainPanel(false)
end

function UICommandCenterPanelV4:SetMaskEnable(enable)
  setactive(self.ui.mTrans_Mask, enable)
end

function UICommandCenterPanelV4:StartCommanderCheckQueue()
  self:InitKeyCode()
  self:SetMaskEnable(false)
  if self.checkQueueEnd ~= nil and not self.checkQueueEnd then
    return
  end
  if CS.AVGController.IsOnPlayAVG then
    return
  end
  self:SetMaskEnable(true)
  self:UnRegistrationAllKeyboard()
  self.checkStep = self.CheckQueue.None
  self:CommanderCheckQueue()
end

function UICommandCenterPanelV4:CheckReconnectBattle()
  if AccountNetCmdHandler:CheckNeedReconnectBattle(function()
    self:CommanderCheckQueue()
  end) then
  else
    self:CommanderCheckQueue()
  end
end

function UICommandCenterPanelV4:CheckGameReconnect()
  if AccountNetCmdHandler:CheckAndRebuildDzStageAwake() then
    self:CommanderCheckQueue()
  else
    self:CheckReconnectBattle()
  end
end

function UICommandCenterPanelV4:CheckPoster()
  if not self:CheckSystemIsLock(SystemList.Notice) then
    if PostInfoConfig.CanShowPost() then
      UIPosterPanel.Open(function()
        self:CommanderCheckQueue()
      end)
    else
      self:CommanderCheckQueue()
    end
  else
    self:CommanderCheckQueue()
  end
end

function UICommandCenterPanelV4:CheckNotice()
  if not self:CheckSystemIsLock(SystemList.Notice) then
    if PostInfoConfig.CanShowNotice() then
      UIPostBrowserPanel.Open(function()
        self:CommanderCheckQueue()
      end)
    else
      self:CommanderCheckQueue()
    end
  else
    self:CommanderCheckQueue()
  end
end

function UICommandCenterPanelV4:CheckDailyCheckIn()
  if not self:CheckSystemIsLock(SystemList.Checkin) and not NetCmdCheckInData:IsChecked() then
    local SendCheckInCallback = function(ret)
      self:SendCheckInCallback(ret)
    end
    NetCmdCheckInData:SendGetDailyCheckInCmd(SendCheckInCallback)
  else
    self:CommanderCheckQueue()
  end
end

function UICommandCenterPanelV4:CheckOperateAct()
  if not self:CheckSystemIsLock(SystemList.Activity) and NetCmdOperationActivityData:IsCanShowOperationAct() and OpenFunctionsManager:CheckFunctionOpen(LuaUtils.EnumToInt(CS.GF2.Logic.OpenFunctionsManager.OpenFunctionsManager.OpenFunction.Activity)) == 1 then
    if NetCmdOperationActivityData:HasShowingActivity() then
      self:UnRegistrationAllKeyboard()
      SceneSys.CurrentSingleScene:SetSceneGaussianBlur(0)
      self:CallWithAniDelay(function()
        UIManager.OpenUI(UIDef.UIActivityDialog)
      end)
      NetCmdOperationActivityData:SaveperationAct()
      NetCmdOperationActivityData:SetOperationDayOpen()
    end
  else
    self:CommanderCheckQueue()
  end
end

function UICommandCenterPanelV4:CheckCarePupUp()
  if NetCmdCareData:IsUnlock() then
    local birthdayPlan = NetCmdCareData.BirthdayPlan
    local festivalPlan = NetCmdCareData.FestivalPlans
    local festivalCount = NetCmdCareData:GetFestivalPlanCount()
    if birthdayPlan ~= nil and NetCmdCareData:IsFestivalOpen(birthdayPlan) and not NetCmdCareData:IsFestivalWatched(birthdayPlan.Id) and not NetCmdCareData:IsRewardReceived(birthdayPlan.Id) then
      self:CallWithAniDelay(function()
        self:UnRegistrationAllKeyboard()
        local param = CS.UIChrBlessingEnterDialogParam()
        param.FestivalId = birthdayPlan.Id
        UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIChrBlessingEnterDialog, param)
      end)
      return
    end
    if festivalCount ~= 0 then
      for _, item in pairs(festivalPlan) do
        if item ~= nil and NetCmdCareData:IsFestivalOpen(item) and not NetCmdCareData:IsFestivalWatched(item.Id) then
          self:CallWithAniDelay(function()
            self:UnRegistrationAllKeyboard()
            local param = CS.UIChrBlessingEnterDialogParam()
            param.FestivalId = item.Id
            UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIChrBlessingEnterDialog, param)
          end)
          return
        end
      end
    end
    self:CommanderCheckQueue()
  else
    self:CommanderCheckQueue()
  end
end

function UICommandCenterPanelV4:CheckUnlock()
  if not AccountNetCmdHandler:ContainsUnlockId(UIDef.UICommandCenterPanel) then
    if self.blockTimer ~= nil then
      self.blockTimer:Stop()
      self.blockTimer = nil
    end
    self.blockTimer = TimerSys:DelayCall(1, function()
      if self.blockTimer ~= nil then
        self.blockTimer:Stop()
        self.blockTimer = nil
      end
    end)
    self:CommanderCheckQueue()
  else
    if AccountNetCmdHandler.tempUnlockList.Count > 0 then
      for i = 0, AccountNetCmdHandler.tempUnlockList.Count - 1 do
        local unlockData = TableData.listUnlockDatas:GetDataById(AccountNetCmdHandler.tempUnlockList[i])
        if unlockData.interface_id == UIDef.UICommandCenterPanel and (unlockData.id ~= 19000 or not not NetCmdGuildGroupData:IsInOpenTime()) then
          UICommonUnlockPanel.Open(self, unlockData, function()
            self:CheckUnlock()
          end)
          return
        end
      end
    end
    self:CommanderCheckQueue()
  end
end

function UICommandCenterPanelV4:CheckTutorial()
  self:CommanderCheckQueue()
end

function UICommandCenterPanelV4:SendCheckInCallback(ret)
  if NetCmdCheckInData:IsChecked() then
    self:CommanderCheckQueue()
  else
    NetCmdCheckInData:OpenDailyCheckInWnd(function()
      self:CommanderCheckQueue()
    end)
  end
end

function UICommandCenterPanelV4:IsReadyToStartTutorial()
  if not AccountNetCmdHandler:GetRecordFlag(GlobalConfig.RecordFlag.NameModified) then
    return false
  end
  if AccountNetCmdHandler:IsNeedRebuildDzStageAwake() or AccountNetCmdHandler:IsNeedReconnectBattle() then
    return false
  end
  if not self:CheckSystemIsLock(SystemList.Notice) and PostInfoConfig.CanShowPost() then
    return false
  end
  if not self:CheckSystemIsLock(SystemList.Notice) and PostInfoConfig.CanShowNotice() then
    return false
  end
  if not self:CheckSystemIsLock(SystemList.Checkin) and not NetCmdCheckInData:IsChecked() then
    return false
  end
  if AccountNetCmdHandler:ContainsUnlockId(UIDef.UICommandCenterPanel) and AccountNetCmdHandler.tempUnlockList.Count > 0 then
    for i = 0, AccountNetCmdHandler.tempUnlockList.Count - 1 do
      local unlockId = AccountNetCmdHandler.tempUnlockList[i]
      local unlockData = TableData.listUnlockDatas:GetDataById(unlockId)
      if unlockData.interface_id == UIDef.UICommandCenterPanel then
        return false
      end
    end
  end
  if AVGController.IsOnPlayAVG then
    return false
  end
  return true
end

function UICommandCenterPanelV4:CommanderCheckQueue()
  local isLogin = AccountNetCmdHandler:IsLogin()
  if isLogin == false then
    self:InitKeyCode()
    self:SetMaskEnable(false)
    return
  end
  self.checkStep = self.checkStep + 1
  if self.checkStep == self.CheckQueue.None then
    self:InitKeyCode()
    self:SetMaskEnable(false)
    self.checkQueueEnd = true
    return
  elseif self.checkStep == self.CheckQueue.NickName then
    self:CommanderCheckQueue()
  elseif self.checkStep == self.CheckQueue.Reconnection then
    self:CheckGameReconnect()
  elseif self.checkStep == self.CheckQueue.Poster then
    self:CheckPoster()
  elseif self.checkStep == self.CheckQueue.Notice then
    self:CheckNotice()
  elseif self.checkStep == self.CheckQueue.CheckIn then
    self:CheckDailyCheckIn()
  elseif self.checkStep == self.CheckQueue.operateAct then
    self:CheckOperateAct()
  elseif self.checkStep == self.CheckQueue.Unlock then
    self:CheckUnlock()
  elseif self.checkStep == self.CheckQueue.Tutorial then
    self:CheckTutorial()
  elseif self.checkStep == self.CheckQueue.CareFestival then
    self:CheckCarePupUp()
  elseif self.checkStep == self.CheckQueue.Finish then
    self:InitKeyCode()
    self:SetMaskEnable(false)
    self.checkStep = self.CheckQueue.None
    MessageSys:SendMessage(CS.GF2.Message.CommonEvent.PlayDefaultConversation, nil)
    self:RequestDeepLink()
    self.checkQueueEnd = true
  end
end

function UICommandCenterPanelV4:OnTop()
  self.isHide = false
  self.skipInitBanner = true
  self:UpdateNewTask(true)
  MessageSys:SendMessage(UIEvent.OnBackToCommandCenterScene, nil)
end

function UICommandCenterPanelV4:PuppyFadeOut()
  if SceneSys.CurrentSingleScene.AnimatorPuppy ~= nil then
    SceneSys.CurrentSingleScene.AnimatorPuppy:SetTrigger("fadeOut")
  end
end

function UICommandCenterPanelV4:OnClickBattle()
  if TipsManager.NeedLockTips(SystemList.Battle) then
    return
  end
  if not self.bCanClick then
    return
  end
  self:UnRegistrationAllKeyboard()
  self.bCanClick = false
  self:OpenCampaign()
end

function UICommandCenterPanelV4:OnClickGacha()
  if TipsManager.NeedLockTips(SystemList.Gacha) then
    return
  end
  self:UnRegistrationAllKeyboard()
  self:CallWithAniDelay(function()
    UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIGachaMainPanel, true)
  end)
end

function UICommandCenterPanelV4:OnClickDormEntrance()
  if not AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.Recreationdeck) then
    local unlockData = TableData.GetUnLockDetailByType(SystemList.Recreationdeck)
    if unlockData == "" then
      return
    end
    PopupMessageManager.PopupString(unlockData)
    return
  end
  self:UnRegistrationAllKeyboard()
  self:CallWithAniDelay(function()
    UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIDormEnterPanel)
  end)
end

function UICommandCenterPanelV4:OnClickGuild()
  if TipsManager.NeedLockTips(SystemList.Guild) then
    return
  end
  local IsOpenGuild = OpenFunctionsManager:CheckFunctionOpen(50000) == 1
  if not IsOpenGuild then
    return
  end
  if NetCmdGuildGroupData:IsInOpenTime() == false then
    return
  end
  self:UnRegistrationAllKeyboard()
  self:CallWithAniDelay(function()
    NetCmdGuildGroupData:OpenGuildUI()
  end)
end

function UICommandCenterPanelV4:OnClickDailyQuest()
  if TipsManager.NeedLockTips(SystemList.Quest) then
    return
  end
  self:UnRegistrationAllKeyboard()
  self:CallWithAniDelay(function()
    UIManager.OpenUI(UIDef.UIQuestPanel)
  end)
end

function UICommandCenterPanelV4:OnClickBattlePass()
  if TipsManager.NeedLockTips(SystemList.Battlepass) then
    return
  end
  local mIsCurBpOpen = NetCmdBattlePassData:CheckCurBpIsOpen()
  if not mIsCurBpOpen then
    UIUtils.PopupPositiveHintMessage(113047)
    return
  end
  NetCmdBattlePassData:SendGetBattlepassInfo(function(ret)
    if ret == ErrorCodeSuc then
      self:UnRegistrationAllKeyboard()
      SceneSys.CurrentSingleScene:SetSceneGaussianBlur(0)
      self:CallWithAniDelay(function()
        UIManager.OpenUI(CS.GF2.UI.enumUIPanel.UIBattlePassPanelV3)
      end)
    end
  end)
end

function UICommandCenterPanelV4:OnClickActivityEntrance()
  if OpenFunctionsManager:CheckFunctionOpen(LuaUtils.EnumToInt(CS.GF2.Logic.OpenFunctionsManager.OpenFunctionsManager.OpenFunction.Activity)) ~= 1 or TipsManager.NeedLockTips(SystemList.Activity) then
    return
  end
  if NetCmdOperationActivityData:HasShowingActivity() then
    self:UnRegistrationAllKeyboard()
    SceneSys.CurrentSingleScene:SetSceneGaussianBlur(0)
    self:CallWithAniDelay(function()
      UIManager.OpenUI(UIDef.UIActivityDialog)
    end)
  else
    UIUtils.PopupPositiveHintMessage(113048)
  end
end

function UICommandCenterPanelV4:OnClickStore()
  local openShop = OpenFunctionsManager:CheckFunctionOpen(16000) == 1
  if not openShop then
    return
  end
  if TipsManager.NeedLockTips(SystemList.Store) then
    return
  end
  self:UnRegistrationAllKeyboard()
  SceneSys.CurrentSingleScene:SetSceneGaussianBlur(0)
  self:CallWithAniDelay(function()
    local has1, goodsData1 = NetCmdStoreData:IsShowNewPackageHint()
    local has2, hint, goodsData2 = NetCmdStoreData:IsShowLeftTimePackageHint()
    if has1 then
      local sideTag = 0
      if goodsData1 ~= nil then
        sideTag = goodsData1.tag
      end
      UIManager.OpenUIByParam(UIDef.UIStorePanel, CS.UIStorePanel.Param(1, 13, sideTag))
    elseif has2 then
      local sideTag = 0
      if goodsData2 ~= nil then
        sideTag = goodsData2.tag
      end
      UIManager.OpenUIByParam(UIDef.UIStorePanel, CS.UIStorePanel.Param(1, 13, sideTag))
    else
      UIManager.OpenUI(UIDef.UIStorePanel)
    end
  end)
end

function UICommandCenterPanelV4:OnClickBarrack()
  if TipsManager.NeedLockTips(SystemList.Barrack) then
    return
  end
  self:UnRegistrationAllKeyboard()
  self:CallWithAniDelay(function()
    local openAvgTask
    local isWatchedBarrackFirstAvg = AccountNetCmdHandler:IsWatchedChapter(TableDataBase.GlobalSystemData.BarrackFirstAvgId) or SaveUtility.GetInt(SaveUtility.WatchedBarrackFirstAvg) == 1
    gfdebug("\230\149\180\229\164\135\229\174\164\232\167\134\233\162\145\239\188\154" .. TableDataBase.GlobalSystemData.BarrackFirstAvgId .. " \230\152\175\229\144\166\232\167\130\231\156\139\232\191\135\239\188\154" .. tostring(isWatchedBarrackFirstAvg))
    if not isWatchedBarrackFirstAvg then
      openAvgTask = CS.AVGController.PlayAvgByPlotId(TableDataBase.GlobalSystemData.BarrackFirstAvgId, function()
        SaveUtility.SetInt(SaveUtility.WatchedBarrackFirstAvg, 1)
        CS.UIBarrackModelManager.Instance:ResetGunStcDataId()
        UISystem:OpenUI(UIDef.UIChrPowerUpPanel, nil, 0, UIGroupType.Default, true, false, nil, false, function()
          UISystem.UISystemBlackCanvas:SetGlobalBlackMaskEnhanceBlack(0)
        end)
      end, true, true, true, false)
      if openAvgTask ~= nil and openAvgTask.AddFinishCallback ~= nil then
        openAvgTask:AddFinishCallback(function()
          UISystem.UISystemBlackCanvas:SetGlobalBlackMaskEnhanceBlack(1)
        end)
      end
    else
      CS.UIBarrackModelManager.Instance:ResetGunStcDataId()
      UISystem:OpenUI(UIDef.UIChrPowerUpPanel, nil, 0, UIGroupType.Default, false, false, nil, false)
    end
  end)
end

function UICommandCenterPanelV4:OnClickRecentActivity()
  if TipsManager.NeedLockTips(SystemList.RecentActivity) then
    return
  end
  self:UnRegistrationAllKeyboard()
  self:CallWithAniDelay(function()
    UIManager.OpenUI(UIDef.RecentActivitiePanelV2)
  end)
end

function UICommandCenterPanelV4:OnClickHud()
  if UISystem:GetTopUI().UIDefine.UIType ~= UIDef.UICommandCenterPanel then
    return
  end
  if self.ui.mTrans_Mask.gameObject.activeSelf then
    return
  end
  if self.blockTimer ~= nil then
    return
  end
  if self.isHide ~= nil and self.isHide then
    return
  end
  if self.checkStep == self.CheckQueue.Unlock or self.checkStep == self.CheckQueue.operateAct or self.checkStep == self.CheckQueue.CheckIn then
    return
  end
  self:UnRegistrationAllKeyboard()
  self.isHide = true
  self.isHud = true
  if self:IsShowHudRedPoint() and SceneSys.CurrentSingleScene.AnimatorPuppy ~= nil then
    SceneSys.CurrentSingleScene.AnimatorPuppy:SetTrigger("finish_hint")
  end
  self:HidePuppyRedPoint()
  self:HidePuppyTips()
  AudioUtils.PlayCommonAudio(1020282)
  UIManager.OpenUI(CS.GF2.UI.enumUIPanel.UICommandCenterHudPanel)
end

function UICommandCenterPanelV4:OnClickSettings()
  self:UnRegistrationAllKeyboard()
  if not AccountNetCmdHandler.tempUnlockList.Count ~= 0 then
    self:CallWithAniDelay(function()
      local rolePublicCmdData = AccountNetCmdHandler.RoleInfoData
      local uiParams = CS.GF2.UI.UICommanderInfoPanel.UIParams(rolePublicCmdData)
      UISystem:OpenUI(enumUIPanel.UICommanderInfoPanel, uiParams)
    end)
  end
end

function UICommandCenterPanelV4:OnClickChangeBg()
  if self:IsShowHudRedPoint() and SceneSys.CurrentSingleScene.AnimatorPuppy ~= nil then
    SceneSys.CurrentSingleScene.AnimatorPuppy:SetTrigger("finish_hint")
  end
  self:UnRegistrationAllKeyboard()
  self.isHud = true
  self:HidePuppyRedPoint()
  self:HidePuppyTips()
  self:CallWithAniDelay(function()
    UIManager.OpenUI(CS.GF2.UI.enumUIPanel.UICommandCenterBgChangePanel)
  end)
end

function UICommandCenterPanelV4:CallWithAniDelay(callback)
  self.super.CallWithAniDelay(self, callback)
  if self:IsShowHudBtn() then
    UIUtils.AnimatorFadeOut(self.ui.mAnim_Hud)
    UIUtils.AnimatorFadeOut(self.ui.mAnim_HudTips)
  end
end

function UICommandCenterPanelV4:UpdateNewTask(CheckPre)
  local mainIconData = NetCmdRecentActivityData:GetMainIconData()
  setactive(self.ui.mTrans_RecentActivity, mainIconData ~= nil and AccountNetCmdHandler:CheckSystemIsUnLock(SystemList.RecentActivity))
  if mainIconData ~= nil then
    setactive(self.ui.mTrans_RecentActivityRP, NetCmdThemeData:ThemeHaveRedPoint(mainIconData.Id))
    self.ui.mText_RecentActivity.text = mainIconData.Name.str
    if self.ui.mTrans_GrpAvatar.childCount > 0 then
      local preBbj = self.ui.mTrans_GrpAvatar:GetChild(0).gameObject
      local names = string.split(preBbj.name, "(")
      if CheckPre == nil or CheckPre and names[1] ~= mainIconData.MainEnter then
        gfdestroy(preBbj)
        local obj = UIUtils.GetGizmosPrefab("CommandCenter/ActivityAvatar/" .. mainIconData.MainEnter .. ".prefab", self)
        if obj ~= nil then
          instantiate(obj, self.ui.mTrans_GrpAvatar)
        end
      end
    else
      local obj = UIUtils.GetGizmosPrefab("CommandCenter/ActivityAvatar/" .. mainIconData.MainEnter .. ".prefab", self)
      if obj ~= nil then
        instantiate(obj, self.ui.mTrans_GrpAvatar)
      end
    end
  end
  local curPhase = NetCmdQuestData:GetCurPhaseId()
  local guidePhaseData = TableData.listGuideQuestPhaseDatas:GetDataById(curPhase)
  local dataList = TableData.listGuideQuestPhaseDatas:GetList()
  if dataList == nil then
    gferror("GuideQuestPhase\230\150\176\230\137\139\228\187\187\229\138\161\232\161\168\228\184\186\231\169\186\230\136\150\232\128\133\232\175\187\228\184\141\229\136\176\239\188\129\239\188\129")
    return
  end
  local totalPhaseNum = dataList[dataList.Count - 1].id
  local completePhaseNum = NetCmdQuestData:GetCompletedPhaseNum()
  local IsOpen = OpenFunctionsManager:CheckFunctionOpen(LuaUtils.EnumToInt(CS.GF2.Logic.OpenFunctionsManager.OpenFunctionsManager.OpenFunction.QuestGuide)) == 1
  setactive(self.ui.mBtn_NewTask.transform.parent, totalPhaseNum ~= completePhaseNum and IsOpen)
end

function UICommandCenterPanelV4:UpdateFestivalBanner()
  local isUnlock = NetCmdCareData:IsUnlock()
  if not isUnlock then
    return
  end
  local birthdayPlan = NetCmdCareData.BirthdayPlan
  if birthdayPlan ~= nil then
    setactive(self.ui.mTrans_GrpBirthday.gameObject, true)
    if self.birthdayItem == nil then
      local itemTrans = self.ui.mTrans_GrpBirthday:Instantiate()
      self.birthdayItem = CS.UIBtn_CommandCenterFestivalBanner(itemTrans)
    end
    self:SetCommandCenterInfo(self.birthdayItem, birthdayPlan)
  else
    setactive(self.ui.mTrans_GrpBirthday.gameObject, false)
  end
  local festivalPlan = NetCmdCareData.FestivalPlans
  local festivalCount = NetCmdCareData:GetFestivalPlanCount()
  if festivalCount ~= 0 then
    setactive(self.ui.mTrans_GrpFestival.gameObject, true)
    for i = 1, #self.festivalItemList do
      setactive(self.festivalItemList[i].uiRoot.gameObject, false)
    end
    local itemListCount = #self.festivalItemList
    if festivalCount > itemListCount then
      for i = 1, festivalCount - itemListCount do
        local itemTrans = self.ui.mTrans_GrpFestival:Instantiate()
        local festivalItem = CS.UIBtn_CommandCenterFestivalBanner(itemTrans)
        table.insert(self.festivalItemList, festivalItem)
      end
    end
    for i = 1, festivalCount do
      self:SetCommandCenterInfo(self.festivalItemList[i], festivalPlan[i - 1])
      setactive(self.festivalItemList[i].uiRoot.gameObject, true)
    end
  else
    setactive(self.ui.mTrans_GrpFestival.gameObject, false)
  end
end

function UICommandCenterPanelV4:SetCommandCenterInfo(item, data)
  if data ~= nil then
    local tableInfo = TableDataBase.listFestivalCareGlobalGoDatas:GetDataById(data.CareGlobalId)
    local bgImg
    item:SetBgImg(tableInfo.ImageBanner)
    item:SetTitle(tableInfo.Name.str)
    item:SetBtnClick(function()
      local isInTime = NetCmdCareData:IsFestivalOpen(data.Id)
      if not isInTime then
        CS.PopupMessageManager.PopupString(TableData.GetHintById(260007))
        print("~~~~\232\138\130\230\151\165\230\180\187\229\138\168\229\183\178\231\187\143\229\133\179\233\151\173id:", data.Id)
        return
      end
      local param = CS.UIChrBlessingPanelParam()
      param.FestivalId = data.Id
      UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIChrBlessingPanel, param)
    end)
    local isReceived = NetCmdCareData:IsRewardReceived(data.Id)
    item:SetRedPoint(not isReceived)
  end
end

function UICommandCenterPanelV4:OnClickNewTask()
  UIManager.OpenUI(UIDef.UINewTaskPanel)
end

function UICommandCenterPanelV4:OpenCampaign()
  UIUniTopBarPanel:Show(false)
  UIBattleIndexGlobal.CachedTabIndex = -1
  self:UnRegistrationAllKeyboard()
  UIManager.OpenUI(enumUIPanel.UIBattleIndexPanel)
  self.bCanClick = true
end

function UICommandCenterPanelV4:OnReconnectSuc()
  local uiBasePanel = UISystem:GetTopUI()
  if uiBasePanel == nil or uiBasePanel.UIDefine.UIType ~= UIDef.UICommandCenterPanel then
    return
  end
  TimerSys:DelayFrameCall(1, function()
    CS.MessageBox.Close()
    self:StartCommanderCheckQueue()
  end)
end

function UICommandCenterPanelV4:OnClickArchives()
  if TipsManager.NeedLockTips(SystemList.Archives) then
    return
  end
  self:UnRegistrationAllKeyboard()
  SceneSys.CurrentSingleScene:SetSceneGaussianBlur(0)
  self:CallWithAniDelay(function()
    NetCmdArchivesData:OpenArchivesMainWnd()
  end)
end

function UICommandCenterPanelV4:OnClickRepository()
  if TipsManager.NeedLockTips(SystemList.Storage) then
    return
  end
  self:UnRegistrationAllKeyboard()
  SceneSys.CurrentSingleScene:SetSceneGaussianBlur(0)
  self:CallWithAniDelay(function()
    UIManager.OpenUI(CS.GF2.UI.enumUIPanel.UIRepositoryPanelV3)
  end)
end

function UICommandCenterPanelV4:OnClickPost()
  if TipsManager.NeedLockTips(SystemList.Notice) then
    return
  end
  self:UnRegistrationAllKeyboard()
  SceneSys.CurrentSingleScene:SetSceneGaussianBlur(0)
  SceneSys.CurrentSingleScene:ShowProjection(false)
  UIManager.OpenUI(UIDef.UIPostPanelV2)
end

function UICommandCenterPanelV4:OnClickCheckIn()
  if TipsManager.NeedLockTips(SystemList.Checkin) then
    return
  end
  self:UnRegistrationAllKeyboard()
  SceneSys.CurrentSingleScene:SetSceneGaussianBlur(0)
  SceneSys.CurrentSingleScene:ShowProjection(false)
  NetCmdCheckInData:OpenDailyCheckInWnd()
end

function UICommandCenterPanelV4:OnClickMail()
  if TipsManager.NeedLockTips(SystemList.Mail) then
    return
  end
  self:UnRegistrationAllKeyboard()
  SceneSys.CurrentSingleScene:SetSceneGaussianBlur(0)
  self:CallWithAniDelay(function()
    NetCmdMailData:SendReqRoleMailsCmd(function()
      UIManager.OpenUI(CS.GF2.UI.enumUIPanel.UIMailPanel)
    end)
  end)
end

function UICommandCenterPanelV4:OnClickChat()
  local IsOpenFriend = OpenFunctionsManager:CheckFunctionOpen(23000) == 1 and OpenFunctionsManager:CheckFunctionOpen(23001) == 1
  if not IsOpenFriend then
    return
  end
  if TipsManager.NeedLockTips(SystemList.Friend) then
    return
  end
  self:UnRegistrationAllKeyboard()
  SceneSys.CurrentSingleScene:SetSceneGaussianBlur(0)
  local playerList = NetCmdSocialData:GetSortedChatList()
  local defaultUid = 0
  if 0 < playerList.Count then
    defaultUid = playerList[0].UID
  end
  UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIChatDialog, defaultUid)
end

function UICommandCenterPanelV4:OnClickFriend(tab)
  if TipsManager.NeedLockTips(SystemList.Friend) then
    return
  end
  self:UnRegistrationAllKeyboard()
  SceneSys.CurrentSingleScene:SetSceneGaussianBlur(0)
  local tabParam = 0
  if tab ~= nil then
    tabParam = tab
  end
  self:CallWithAniDelay(function()
    UIManager.OpenUIByParam(CS.GF2.UI.enumUIPanel.UIFriendPanel, tab)
  end)
end

function UICommandCenterPanelV4:OnClickChrSpeak()
  SceneSys.CurrentSingleScene:PlayClickVoice()
end

function UICommandCenterPanelV4:OnClickThemeActivity()
  local activityConfigData = NetCmdRecentActivityData:GetMainIconData()
  if activityConfigData == nil then
    PopupMessageManager.PopupString(TableData.GetHintById(272001))
    setactive(self.ui.mTrans_RecentActivity, false)
    return
  end
  NetCmdRecentActivityData:OpenActivityWnd(activityConfigData.Id)
end

require("UI.UIBasePanel")
require("UI.ActivityPanel.UIActivityLeftTabItem")
require("UI.ActivityPanel.Item.SignIn.UIActivitySignInItem")
require("UI.ActivityPanel.Item.SignIn.UIActivitySignInUllridItem")
require("UI.ActivityPanel.Item.SignIn.UIActivityMultiSignInItem")
require("UI.ActivityPanel.Item.AmoWish.UIActivityAmoWishItem")
require("UI.ActivityPanel.Item.SevenQuest.UIActivitySevenQuestItem")
require("UI.ActivityPanel.Item.Guiding.UIActivityGuidingItem")
require("UI.ActivityPanel.Item.Regress.UIActivityRegressItem")
require("UI.ActivityPanel.Item.Treasure.UIActivityTreasureItem")
require("UI.ActivityPanel.Item.ChrTry.UIActivityChrTryItem")
require("UI.ActivityPanel.Item.ChrTry.UIActivityChrChallengeItem")
require("UI.ActivityPanel.Item.ChapterOpen.UIActivityChapterOpenItem")
require("UI.ActivityPanel.Item.Theme.UIActivityThemeItem")
require("UI.ActivityPanel.Item.CafeSignIn.UIActivityCafeSignInItem")
require("UI.ActivityPanel.Item.ReceiveStamina.UIActivityReceiveStaminaItem")
require("UI.ActivityPanel.Item.Store.UIActivityStoreItem")
require("UI.ActivityPanel.Item.DropUp.UIActivityDropUpItem")
require("UI.ActivityPanel.Item.ShowSkin.UIActivityShowSkinItem")
require("UI.ActivityPanel.Item.ShowSkin.UIActivityPreSaleSkinItem")
require("UI.ActivityPanel.UIActivityDefine")
UIActivityDialog = class("UIActivityDialog", UIBasePanel)
UIActivityDialog.__index = UIActivityDialog
UIActivityDialog.param = {}
local tagDefine = {novice = 1, routine = 0}

function UIActivityDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
  csPanel.Is3DPanel = true
end

function UIActivityDialog:OnInit(root, param)
  self.super.SetRoot(UIActivityDialog, root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.mTargetActivityId = nil
  if type(param) == "table" then
    UIActivityDialog.param = param
    if param.targetActivityId ~= nil then
      self.mTargetActivityId = param.targetActivityId
    end
    if param.selectedTag then
      self.selectedTag = param.selectedTag
    end
  else
    UIActivityDialog.param = {}
    self.mCSPanel:SetUIParamUserData(UIActivityDialog.param)
    if type(param) == "userdata" then
      if param.Length >= 1 and param[0] ~= nil then
        self.mTargetActivityId = param[0]
      end
      if self.mTargetActivityId ~= nil then
        local config = TableDataBase.listActivityListDatas:GetDataById(self.mTargetActivityId)
        self.selectedTag = config.Rookie
      end
    end
  end
  
  function self.OnActivityRedPointChange()
    if not self.mUITabItems then
      return
    end
    for i = 1, #self.mUITabItems do
      local item = self.mUITabItems[i]
      if item then
        item:UpdateRedPoint()
      end
    end
    if self.hasNoviceActivity then
      setactivewithcheck(self.ui.mTrans_RedPoint_Routine, NetCmdOperationActivityData:HasRedPointByTag(tagDefine.routine))
      setactivewithcheck(self.ui.mTrans_RedPoint_Novice, NetCmdOperationActivityData:HasRedPointByTag(tagDefine.novice))
    end
  end
  
  function self.OnResetOperationActivity()
    self:CloseSelf()
    UIUtils.PopupErrorWithHint(260010)
  end
  
  function self.OnDayChange()
    local topUI = UISystem:GetTopUI(UIGroupType.Default)
    if topUI ~= nil and topUI.UIDefine.UIType ~= UIDef.UIActivityDialog then
      return
    end
    self:CloseSelf()
    UIUtils.PopupErrorWithHint(260010)
  end
  
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnActivityRedPointChange, self.OnActivityRedPointChange)
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnResetOperationActivity, self.OnResetOperationActivity)
  MessageSys:AddListener(CS.GF2.Message.UIEvent.OnDayChange, self.OnDayChange)
  self.mFirstEnter = true
  self:RegisterEvent()
end

function UIActivityDialog:OnShowFinish()
  if not NetCmdOperationActivityData:HasShowingActivity() then
    UIUtils.PopupErrorWithHint(260044)
    self:CloseSelf()
    return
  end
  self:UpdateAll()
  if NetCmdOperationActivityData:GetOperationDayOpen() then
    NetCmdOperationActivityData:SetOperationDayOpen()
  end
end

function UIActivityDialog:OnHideFinish()
  local item = self:GetCurrentUIDesc()
  if item then
    if type(item) == "table" then
      setactive(item.mUIRoot, false)
    else
      setactive(item:GetRoot(), false)
    end
  end
end

function UIActivityDialog:CloseSelf()
  if self.currentUIItem then
    self.currentUIItem:CloseTrigger()
  end
  self.selectedTag = nil
  UIManager.CloseUI(UIDef.UIActivityDialog)
end

function UIActivityDialog:OnEscClick()
  self:CloseSelf()
end

function UIActivityDialog:OnCameraStart()
  return 0.01
end

function UIActivityDialog:OnCameraBack()
  return 0.01
end

function UIActivityDialog:RegisterEvent()
  UIUtils.GetButtonListener(self.ui.mBtn_BGClose.gameObject).onClick = function()
    self:CloseSelf()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    self:CloseSelf()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Novice).onClick = function()
    self.mTargetActivityId = self.mTargetNoviceActivityId
    self:SetSelect(self.mSelectIndex, false)
    self:ShowActivityWithTag(tagDefine.novice)
    self.mFirstEnter = true
    self:UpdateAll()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Routine).onClick = function()
    self.mTargetActivityId = self.mTargetRoutineActivityId
    self:SetSelect(self.mSelectIndex, false)
    self:ShowActivityWithTag(tagDefine.routine)
    self.mFirstEnter = true
    self:UpdateAll()
  end
  
  function self.ui.mVirtualList_TabList.itemCreated(renderData)
    return self:ItemProvider(renderData)
  end
  
  function self.ui.mVirtualList_TabList.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
end

function UIActivityDialog:ShowActivityWithTag(tag)
  self.ui.mBtn_Novice.interactable = tag == tagDefine.routine
  self.ui.mBtn_Routine.interactable = tag == tagDefine.novice
  self.selectedTag = tag
  UIActivityDialog.param.selectedTag = tag
end

function UIActivityDialog:UpdateAll()
  self:InitData()
  self:RefreshSelectIndex()
  if self.mTargetActivityId ~= nil then
    for i = 1, #self.mActivityList do
      local data = self.mActivityList[i]
      if data ~= nil and data.activityID == self.mTargetActivityId then
        self.mSelectIndex = i
      end
    end
    self.mTargetActivityId = nil
  end
  self:UpdateTabs()
end

function UIActivityDialog:InitData()
  self.mActivityList = {}
  self.hasNoviceActivity = NetCmdOperationActivityData:GetActivityWithTag(tagDefine.novice).Count > 0
  setactivewithcheck(self.ui.mTrans_GrpTab, self.hasNoviceActivity)
  if self.selectedTag == nil then
    self.selectedTag = tagDefine.routine
  end
  self:ShowActivityWithTag(self.selectedTag)
  local serverActivityList = NetCmdOperationActivityData:GetActivityWithTag(self.selectedTag)
  local serverCount = serverActivityList and serverActivityList.Count or 0
  for i = 0, serverCount - 1 do
    local activityPlanData = serverActivityList[i]
    local activityID = activityPlanData.Id
    local tableData = TableDataBase.listActivityListDatas:GetDataById(activityID)
    local activityData = {
      activityPlanData = activityPlanData,
      activityID = activityID,
      closeTime = activityPlanData.CloseTime,
      openTime = activityPlanData.OpenTime,
      tableData = tableData
    }
    table.insert(self.mActivityList, activityData)
  end
end

function UIActivityDialog:UpdateTabs()
  self.ui.mVirtualList_TabList:SetListItemCount(#self.mActivityList)
  self.ui.mVirtualList_TabList:Refresh()
  if self.mFirstEnter == true then
    self.ui.mVirtualList_TabList:SetLayoutDoneDirty()
    self.ui.mVirtualList_TabList:ScrollTo(math.max(self.mSelectIndex - 1, 0))
  end
  self.mFirstEnter = false
  self:SetSelect(self.mSelectIndex, true)
end

function UIActivityDialog:ItemProvider(renderData)
  local itemView = UIActivityLeftTabItem.New()
  itemView:InitCtrl(renderData.gameObject, self.ui.mScrollChild_Content.transform, function(index)
    self:SetSelect(self.mSelectIndex, false)
    self.mSelectIndex = index
    self:SetSelect(self.mSelectIndex, true)
  end)
  renderData.data = itemView
end

function UIActivityDialog:ItemRenderer(index, renderData)
  local luaIndex = index + 1
  local activityData = self.mActivityList[luaIndex]
  local item = renderData.data
  if self.mUITabItems == nil then
    self.mUITabItems = {}
  end
  self.mUITabItems[luaIndex] = item
  item:SetData(activityData, luaIndex, luaIndex == self.mSelectIndex)
end

function UIActivityDialog:SetSelect(index, isSelect)
  local activityData = self.mActivityList[index]
  if isSelect then
    UIActivityDialog.param.targetActivityId = activityData.activityID
    self.mTargetActivityId = activityData.activityID
    if self.selectedTag == tagDefine.routine then
      self.mTargetRoutineActivityId = activityData.activityID
    else
      self.mTargetNoviceActivityId = activityData.activityID
    end
    for _, item in pairs(self.mUITabItems or {}) do
      item:SetSelect(self.mTargetActivityId == item.activityID)
    end
  end
  local uiItem = self:GetUIDesc(activityData)
  if not uiItem then
    return
  end
  if type(uiItem) == "table" then
    setactive(uiItem.mUIRoot, isSelect)
  else
    setactive(uiItem:GetRoot(), isSelect)
  end
  if isSelect then
    if not NetCmdOperationActivityData:IsActivityOpen(activityData.activityID) then
      self:CloseSelf()
      UIUtils.PopupErrorWithHint(260007)
      return
    end
    if not NetCmdOperationActivityData:IsActivityWatch(activityData.activityID) then
      NetCmdOperationActivityData:WatchActivity(activityData.activityID)
      if tabItem then
        tabItem:UpdateRedPoint()
      end
      if self.hasNoviceActivity then
        if self.selectedTag == tagDefine.routine then
          setactivewithcheck(self.ui.mTrans_RedPoint_Routine, NetCmdOperationActivityData:HasRedPointByTag(tagDefine.routine))
        else
          setactivewithcheck(self.ui.mTrans_RedPoint_Novice, NetCmdOperationActivityData:HasRedPointByTag(tagDefine.novice))
        end
      end
    end
    if type(uiItem) == "table" then
      uiItem:SetData(activityData)
    else
      uiItem:SetData(activityData.activityPlanData)
    end
    self.currentUIItem = uiItem
  else
    uiItem:OnHide()
    uiItem:ReleaseTimers()
  end
  if isSelect then
    local info = CS.OssTabSwitchInfo(UIDef.UIActivityDialog, 0, activityData.activityID, 0)
    MessageSys:SendMessage(OssEvent.OnTabSwitched, info)
  end
end

function UIActivityDialog:GetCurrentUIDesc()
  if self.mActivityList == nil then
    return
  end
  local activityData = self.mActivityList[self.mSelectIndex]
  if not activityData then
    return nil
  end
  return self:GetUIDesc(activityData)
end

function UIActivityDialog:GetUIDesc(activityData)
  if not self.mUITabInfoItem then
    self.mUITabInfoItem = {}
  end
  local activityType = activityData.tableData.type
  local activityId = activityData.tableData.id
  local activityItem
  if activityType == LuaUtils.EnumToInt(CS.OperationActivityType.SignIn) then
    activityItem = self.mUITabInfoItem[activityType * 100000 + activityId]
  elseif activityData.tableData.banner_resource ~= nil and activityData.tableData.banner_resource ~= "" then
    activityItem = self.mUITabInfoItem[activityType * 100000 + activityId]
  else
    activityItem = self.mUITabInfoItem[activityType * 100000 + activityId]
  end
  if not activityItem then
    if activityType == LuaUtils.EnumToInt(CS.OperationActivityType.SignIn) then
      if activityData.tableData.banner_resource ~= nil and activityData.tableData.banner_resource ~= "" then
        activityItem = self:CreateNewActivity(activityType, tonumber(activityData.tableData.banner_resource))
      else
        local signInData = TableData.listEventSigninDatas:GetDataById(activityId)
        if signInData == nil then
          return nil
        end
        activityItem = self:CreateNewActivity(activityType, signInData.activity_type)
      end
      self.mUITabInfoItem[activityType * 100000 + activityId] = activityItem
    elseif activityData.tableData.banner_resource ~= nil and activityData.tableData.banner_resource ~= "" then
      activityItem = self:CreateNewActivity(activityType, tonumber(activityData.tableData.banner_resource))
      self.mUITabInfoItem[activityType * 100000 + activityId] = activityItem
    else
      activityItem = self:CreateNewActivity(activityType)
      self.mUITabInfoItem[activityType * 100000 + activityId] = activityItem
    end
  end
  if activityItem == nil then
    local banner = 0
    if activityData.tableData.banner_resource ~= nil and activityData.tableData.banner_resource ~= "" then
      banner = tonumber(activityData.tableData.banner_resource)
    end
    activityItem = self:CSCreateNewActivity(activityType, banner)
    self.mUITabInfoItem[activityType * 100000 + activityId] = activityItem
  end
  if activityItem == nil then
    gferror("\230\178\161\230\156\137\229\156\168UIActivityItemConfig\228\184\173\230\137\190\229\136\176\230\180\187\229\138\168\239\188\154" .. tostring(activityType) .. "\231\154\132\233\133\141\231\189\174")
  end
  return activityItem
end

function UIActivityDialog:CreateNewActivity(activityType, id)
  local uiConfig = UIActivityItemConfig[activityType]
  if id ~= nil and uiConfig ~= nil then
    uiConfig = UIActivityItemConfig[activityType][id]
  end
  if not uiConfig then
    return nil
  end
  local item = uiConfig.itemClass.New()
  item:InitCtrl(self.ui.mTrans_InfoRoot, uiConfig)
  return item
end

function UIActivityDialog:CSCreateNewActivity(activityType, banner)
  local item = UIOperationActivityDefine.CreateCSItem(activityType, self.ui.mTrans_InfoRoot, banner)
  return item
end

function UIActivityDialog:OnRecover()
end

function UIActivityDialog:RefreshSelectIndex()
  self.mSelectIndex = 1
  if self.mTargetActivityId == nil then
    return
  end
  for i = 1, #self.mActivityList do
    local data = self.mActivityList[i]
    if data ~= nil and data.activityID == self.mTargetActivityId then
      self.mSelectIndex = i
      return
    end
  end
  UIUtils.PopupErrorWithHint(260044)
  self:CloseSelf()
end

function UIActivityDialog:OnTop()
  self:RefreshSelectIndex()
  local item = self:GetCurrentUIDesc()
  if item then
    item:OnTop()
  end
end

function UIActivityDialog:OnBackFrom()
  self:OnTop()
end

function UIActivityDialog:OnRelease()
end

function UIActivityDialog:OnClose()
  self.mUITabItems = nil
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnActivityRedPointChange, self.OnActivityRedPointChange)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnResetOperationActivity, self.OnResetOperationActivity)
  MessageSys:RemoveListener(CS.GF2.Message.UIEvent.OnDayChange, self.OnDayChange)
  if self.mUITabInfoItem then
    for i, baseCtrl in pairs(self.mUITabInfoItem) do
      if baseCtrl then
        if type(baseCtrl) == "table" then
          setactive(baseCtrl.mUIRoot, false)
        else
          setactive(baseCtrl:GetRoot(), false)
        end
        baseCtrl:OnHide()
        baseCtrl:OnClose()
      end
    end
  end
  self.mActivityList = nil
  if self.mUITabInfoItem then
    for _, item in pairs(self.mUITabInfoItem) do
      item:ReleaseTimers()
      item:OnRelease(true)
    end
  end
  self.mUITabInfoItem = nil
end

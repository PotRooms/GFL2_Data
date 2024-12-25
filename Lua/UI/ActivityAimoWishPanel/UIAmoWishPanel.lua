require("UI.UIBasePanel")
require("UI.Common.UICommonItem")
require("UI.ActivityAimoWishPanel.Item.AmoWishListItem")
require("UI.ActivityAimoWishPanel.Item.AmoWishAccessListItem")
UIAmoWishPanel = class("UIAmoWishPanel", UIBasePanel)
UIAmoWishPanel.__index = UIAmoWishPanel

function UIAmoWishPanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Panel
end

function UIAmoWishPanel:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:AddBtnListen()
end

function UIAmoWishPanel:OnInit(root, data)
  self.mTabsTable = {}
  self.mRewardTable = {}
  self.mTaskTable = {}
  self.mPlanActivityData = data.plan
  self.mCloseTime = data.close
  self.mIsOpen = true
  self.mIsShowForceCommand = false
  local activityData = TableDataBase.listAmoActivityMainDatas:GetDataById(self.mPlanActivityData.id)
  local subDataIds = activityData.subclass_theme
  self.mDataList = {}
  for i = 0, subDataIds.Count - 1 do
    local id = subDataIds[i]
    local activitySubData = TableDataBase.listAmoActivitySubDatas:GetDataById(id)
    table.insert(self.mDataList, activitySubData)
  end
  
  function self.ui.mVList_GrpList.itemCreated(renderData)
    local item = self:ItemProvider(renderData)
    return item
  end
  
  function self.ui.mVList_GrpList.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
  
  self.ui.mVList_GrpList.numItems = #self.mDataList
  self.ui.mVList_GrpList:Refresh()
  
  function self.RefreshAimoWish(msg)
    self:OnRefreshAimoWish(msg)
  end
  
  MessageSys:AddListener(UIEvent.RefreshAimoWish, self.RefreshAimoWish)
  if 0 > NetCmdActivityAmoData.SelectId then
    self:RefreshAimoWishInfo(self.mDataList[1].id)
  else
    self:RefreshAimoWishInfo(NetCmdActivityAmoData.SelectId)
  end
  
  function self.mAutoRefresh()
    local toppanel = UISystem:GetTopPanelUI()
    if toppanel ~= nil and toppanel.UIDefine.UIType == UIDef.UIActivityAimoWishPanel and self.mAmoActivityData ~= nil then
      self:RefreshAimoWishInfo(self.mAmoActivityData.id, false)
      setactive(self.ui.mTrans_Complished, false)
      setactive(self.ui.mTrans_Complished, true)
      MessageSys:SendMessage(UIEvent.GetAimoWishReward, self)
    end
  end
  
  UIUtils.GetButtonListener(self.ui.mBtn_BtnReceive.transform).onClick = function()
    NetCmdActivityAmoData:SendGetAmoQuestReward(self.mRefreshId, function(ret)
      if ret == ErrorCodeSuc then
        UISystem:OpenCommonReceivePanel({
          nil,
          self.mAutoRefresh
        })
      end
    end)
  end
  UIUtils.GetButtonListener(self.ui.mTrans_Switch.transform).onClick = function()
    self:OnSwitchClick()
  end
  
  function self.UserTapScreen()
    local topUIType = self.mCSPanel.UIGroup:GetTopUI().UIDefine.UIType
    if self.mIsOpen == false and self.mIsShowForceCommand == false and topUIType == UIDef.UIActivityAimoWishPanel then
      self.mIsShowForceCommand = true
      local title = TableData.GetHintById(208)
      MessageBox.ShowMidBtn(title, TableData.GetHintById(260044), nil, nil, function()
        UISystem:JumpToMainPanel()
      end)
    end
  end
  
  MessageSys:AddListener(UIEvent.UserTapScreen, self.UserTapScreen)
end

function UIAmoWishPanel:ItemProvider(renderData)
  local amoWishListItem = AmoWishListItem.New(renderData)
  table.insert(self.mTabsTable, amoWishListItem)
  renderData.data = amoWishListItem
end

function UIAmoWishPanel:ItemRenderer(index, renderData)
  local item = renderData.data
  item:SetData(self.mDataList[index + 1].id, index == #self.mDataList - 1, self.mPlanActivityData)
  item:SetInteractable(self.mRefreshId ~= item.mData.id)
end

function UIAmoWishPanel:OnShowStart()
  self:RefreshAimoWishInfo(self.mAmoActivityData.id)
end

function UIAmoWishPanel:OnShowFinish()
end

function UIAmoWishPanel:OnUpdate()
  self.mIsOpen = self:CheckAmoIsOpen()
end

function UIAmoWishPanel:OnTop()
end

function UIAmoWishPanel:OnBackFrom()
  self:RefreshAimoWishInfo(self.mAmoActivityData.id)
  if self.mIsOpen == false then
    MessageSys:SendMessage(UIEvent.UserTapScreen, nil)
  end
end

function UIAmoWishPanel:OnRefreshAimoWish(msg)
  local refreshId = msg.Sender
  self.ui.mAni_Root:SetTrigger("Switch")
  self:RefreshAimoWishInfo(refreshId)
end

function UIAmoWishPanel:CheckAmoIsOpen()
  if self.mPlanActivityData == nil then
    return true
  end
  if self.mCloseTime < CGameTime:GetTimestamp() then
    return false
  end
  return true
end

function UIAmoWishPanel:RefreshAimoWishInfo(refreshId)
  self.mRefreshId = refreshId
  NetCmdActivityAmoData.SelectId = refreshId
  local amoActivityData = TableData.listAmoActivitySubDatas:GetDataById(refreshId)
  if amoActivityData == nil then
    return
  end
  self.ui.mScrollRect.verticalNormalizedPosition = 1
  self.mAmoActivityData = amoActivityData
  for _, v in pairs(self.mTabsTable) do
    v:SetInteractable(true)
    if v.mData.id == refreshId then
      v:SetInteractable(false)
    end
    v:UpdateRedPoint()
  end
  self.ui.mTextFit_Info.text = amoActivityData.theme_long_description
  self.ui.mText_Title.text = amoActivityData.theme_short_description
  self.ui.mText_Chr.text = amoActivityData.name
  for i = 0, amoActivityData.theme_quests.Count - 1 do
    local amoWishAccessListItem = self.mTaskTable[i + 1]
    if amoWishAccessListItem == nil then
      amoWishAccessListItem = AmoWishAccessListItem.New()
      amoWishAccessListItem:InitCtrl(self.ui.mSListChild_GrpAccessList.transform)
      table.insert(self.mTaskTable, amoWishAccessListItem)
    end
    amoWishAccessListItem:SetData(amoActivityData.theme_quests[i])
  end
  local rewards = TableData.SpliteStrToItemAndNumList(amoActivityData.reward)
  self:ReleaseCtrlTable(self.mRewardTable, true)
  self.mRewardTable = {}
  if rewards ~= nil and 0 < rewards.Count then
    for k, v in pairs(rewards) do
      local item = UICommonItem.New()
      item:InitCtrl(self.ui.mSListChild_Content1)
      table.insert(self.mRewardTable, item)
      local itemData = TableData.GetItemData(v.itemid)
      item:SetItemByStcData(itemData, v.num)
    end
  end
  local IsMainQuestUnlock = NetCmdActivityAmoData:GetMainQuestUnlock(refreshId)
  if NetCmdActivityAmoData:HasMainQuestRewardGet(refreshId) then
    setactive(self.ui.mBtn_BtnReceive.transform.parent, false)
    setactive(self.ui.mTrans_Recived, true)
  else
    setactive(self.ui.mBtn_BtnReceive.transform.parent, IsMainQuestUnlock)
    setactive(self.ui.mTrans_Recived, false)
  end
  setactive(self.ui.mTrans_Complete, not IsMainQuestUnlock)
  self.ui.mImg_Avatar.sprite = IconUtils.GetCharacterWholeSprite(amoActivityData.theme_icon)
  local isMainQuestRewardGet = NetCmdActivityAmoData:HasMainQuestRewardGet(refreshId)
  setactive(self.ui.mTrans_Ongoing, not isMainQuestRewardGet)
  setactive(self.ui.mTrans_Complished, isMainQuestRewardGet)
  setactive(self.ui.mTrans_Switch, isMainQuestRewardGet)
  self:RefreshSwitchBtn()
  self.ui.mTextFit_Info1.text = amoActivityData.theme_reply
  self.ui.mText_Title1.text = amoActivityData.reply_name
  self.ui.mText_Name1.text = amoActivityData.name_gun
  local characterData = TableData.GetGunCharacterData(amoActivityData.theme_bg)
  if characterData ~= nil then
    self.ui.mImage_Bg.color = ColorUtils.StringToColor(characterData.color)
    self.ui.mImage_Bg1.color = ColorUtils.StringToColor(characterData.color)
    self.ui.mImg_Sign.color = ColorUtils.StringToColor(characterData.color)
  end
  local ossWithLog = CS.OssWishLog(amoActivityData.theme_bg, 0, 1)
  MessageSys:SendMessage(OssEvent.WishLog, nil, ossWithLog)
end

function UIAmoWishPanel:OnHide()
end

function UIAmoWishPanel:OnClose()
  for _, v in pairs(self.mTabsTable) do
    gfdestroy(v:OnRelease())
  end
  for _, v in pairs(self.mTaskTable) do
    gfdestroy(v:GetRoot())
  end
  for _, v in pairs(self.mRewardTable) do
    gfdestroy(v:GetRoot())
  end
  MessageSys:RemoveListener(UIEvent.RefreshAimoWish, self.RefreshAimoWish)
  MessageSys:RemoveListener(UIEvent.UserTapScreen, self.UserTapScreen)
end

function UIAmoWishPanel:OnRelease()
  self.ui = nil
  self.mData = nil
end

function UIAmoWishPanel:AddBtnListen()
  UIUtils.GetButtonListener(self.ui.mBtn_BtnBack.transform).onClick = function()
    UIManager.CloseUI(UIDef.UIActivityAimoWishPanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnHome.transform).onClick = function()
    UISystem:JumpToMainPanel()
  end
end

function UIAmoWishPanel:OnSwitchClick()
  setactive(self.ui.mTrans_Ongoing, not self.ui.mTrans_Ongoing.gameObject.activeSelf)
  setactive(self.ui.mTrans_Complished, not self.ui.mTrans_Complished.gameObject.activeSelf)
  self.ui.mAni_Root:SetTrigger("InfoChange")
  self:RefreshSwitchBtn()
end

function UIAmoWishPanel:RefreshSwitchBtn()
  local complished = self.ui.mTrans_Complished.gameObject.activeSelf
  self.ui.mAnimator_Switch:SetBool("Switch", not complished)
end

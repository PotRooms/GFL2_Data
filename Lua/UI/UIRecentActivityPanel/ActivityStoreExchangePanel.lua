require("UI.StoreExchangePanel.Item.UIStoreBuyItem")
require("UI.Common.UICommonLeftTabItemV2")
require("UI.UIBasePanel")
require("UI.Repository.Item.UIRepositoryLeftTab2ItemV3")
ActivityStoreExchangePanel = class("ActivityStoreExchangePanel", UIBasePanel)
ActivityStoreExchangePanel.__index = ActivityStoreExchangePanel

function ActivityStoreExchangePanel:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function ActivityStoreExchangePanel:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self:InitData(data)
  self:InitTabButton()
  self:AddListener()
end

function ActivityStoreExchangePanel:InitData(data)
  self.mLeftTabItemList = {}
  self.mTopTabItemList = {}
  self.mGoodItemList = {}
  self.storeType = CS.GF2.Data.StoreTagType.ActivityExchange:GetHashCode()
  if data and type(data) == "userdata" then
    self.mData = data[0]
    self.mCurTopTagIndex = data[1]
    if data.Length > 2 then
      self.storeType = data[2]
    end
  else
    self.mData = data
  end
end

function ActivityStoreExchangePanel:InitTabButton()
  local list = TableData.listStoreSidetagBySidetagTypeDatas:GetDataById(self.storeType)
  local sortLeftTag = {}
  for i = 0, list.Id.Count - 1 do
    table.insert(sortLeftTag, list.Id[i])
  end
  table.sort(sortLeftTag, function(a, b)
    local storeSidetagA = TableData.listStoreSidetagDatas:GetDataById(a)
    local storeSidetagB = TableData.listStoreSidetagDatas:GetDataById(b)
    return storeSidetagA.Sort < storeSidetagB.Sort
  end)
  for i, v in pairs(sortLeftTag) do
    local id = v
    local data = TableData.listStoreSidetagDatas:GetDataById(id)
    local item = UIRepositoryLeftTab2ItemV3.New()
    item:InitCtrl(self.ui.mTrans_LeftTabContent, true)
    item:SetName(data.id, data.name.str)
    item.ui.mText_Name.text = data.name.str
    local isLock = not AccountNetCmdHandler:CheckSystemIsUnLock(data.unlock)
    item:SetLock(isLock)
    if data.GlobalTab then
      item:SetGlobalTabId(data.GlobalTab)
    end
    UIUtils.GetButtonListener(item.ui.mBtn_ComTab1ItemV2.gameObject).onClick = function()
      if AccountNetCmdHandler:CheckSystemIsUnLock(data.unlock) then
        self:OnClickLeftTab(data)
      else
        local unlockData = TableData.listUnlockDatas:GetDataById(data.unlock)
        local str = UIUtils.CheckUnlockPopupStr(unlockData)
        PopupMessageManager.PopupString(str)
      end
    end
    self.mLeftTabItemList[id] = item
    if i == 1 and self.mData == nil then
      self:OnClickLeftTab(data)
    elseif self.mData == id then
      self:OnClickLeftTab(data)
    end
  end
end

function ActivityStoreExchangePanel:InitTopTabButton(data)
  for i = 1, #self.mTopTabItemList do
    setactive(self.mTopTabItemList[i].mUIRoot, false)
  end
  for i = 0, data.include_tag.Count - 1 do
    local tagId = data.include_tag[i]
    local tagData = TableData.listStoreTagDatas:GetDataById(tagId)
    local item
    if self.mTopTabItemList[i + 1] == nil then
      item = UIComTabBtn1Item.New()
      item:InitCtrl(self.ui.mTrans_TopTabContent, true)
      table.insert(self.mTopTabItemList, item)
    else
      item = self.mTopTabItemList[i + 1]
      setactive(item.mUIRoot, true)
    end
    item.tagData = tagData
    item.ui.mText_Name.text = tagData.name.str
    UIUtils.GetButtonListener(item.ui.mBtn_Item.gameObject).onClick = function()
      self:OnClickTopTab(data.id, tagId, i + 1)
    end
    if i == 0 and self.mCurTopTagIndex == nil then
      self:OnClickTopTab(data.id, tagId, i + 1)
    elseif self.mCurTopTagIndex == tagId then
      self:OnClickTopTab(data.id, tagId, i + 1)
    end
  end
end

function ActivityStoreExchangePanel:OnClickLeftTab(data)
  if self.curLeftTabId == data.id then
    return
  end
  for i = 1, #self.mTopTabItemList do
    setactive(self.mTopTabItemList[i].mUIRoot, false)
  end
  if self.curLeftTabId ~= nil and self.curLeftTabId > 0 then
    local lastTab = self.mLeftTabItemList[self.curLeftTabId]
    lastTab:SetItemState(false)
  end
  local curTab = self.mLeftTabItemList[data.id]
  curTab:SetItemState(true)
  self.curLeftTabId = data.id
  setactive(self.ui.mTrans_MonthlyCardBuy, false)
  setactive(self.ui.mTrans_CreditBuy, false)
  setactive(self.ui.mTrans_ComBuy, true)
  setactive(self.ui.mTrans_GrpSkin, false)
  setactive(self.ui.mTrans_GrpWeaponSkinBuy, false)
  if 1 < data.include_tag.Count then
    setactive(self.ui.mTrans_TopTabContent, true)
    self:InitTopTabButton(data)
  else
    setactive(self.ui.mTrans_TopTabContent, false)
    local tagData = TableData.listStoreTagDatas:GetDataById(data.include_tag[0])
    self.mCurTagData = tagData
    self:RefreshItems(tagData)
  end
  self.mCurTopTagIndex = nil
end

function ActivityStoreExchangePanel:OnClickTopTab(leftTabId, tagId, id)
  if self.mCurTopTab ~= nil and self.mCurTopTab > 0 then
    local lastTab = self.mTopTabItemList[self.mCurTopTab]
    lastTab:SetSelect(false)
  end
  setactive(self.ui.mTrans_GrpSkin, false)
  setactive(self.ui.mTrans_ComBuy, true)
  setactive(self.ui.mTrans_GrpWeaponSkinBuy, false)
  local curTab = self.mTopTabItemList[id]
  curTab:SetSelect(true)
  self.mCurTopTab = id
  self.mCurTagData = curTab.tagData
  self:RefreshItems(curTab.tagData)
  self.mCurTopTagIndex = nil
end

function ActivityStoreExchangePanel:RefreshTagRedPoint()
  for i, v in pairs(self.mLeftTabItemList) do
    local showTagRedPoint = false
    local storeSidetagData = TableData.listStoreSidetagDatas:GetDataById(v.tagId)
    if storeSidetagData ~= nil then
      for i = 0, storeSidetagData.include_tag.Count - 1 do
        showTagRedPoint = NetCmdStoreData:GetGiftRedPoint(storeSidetagData.include_tag[i]) == 1
      end
    end
  end
end

function ActivityStoreExchangePanel:UpdateResourceBar(tagData)
  local currencyParent = CS.TransformUtils.DeepFindChild(self.mUIRoot, "GrpCurrency/TopResourceBarRoot(Clone)")
  if currencyParent == nil then
    TimerSys:DelayCall(0.1, function()
      self:UpdateResourceBar(tagData)
    end, nil)
    return
  end
  if self.topRes ~= nil then
    self.topRes:Release()
  else
    self.topRes = UITopResourceBar.New()
    self.topRes:Init(self.mUIRoot, tagData.trade_item_list, true)
  end
  self.topRes:UpdateCurrencyContent(currencyParent, tagData.trade_item_list)
end

function ActivityStoreExchangePanel:RefreshItems(tagData)
  for i = 1, #self.mGoodItemList do
    setactive(self.mGoodItemList[i]:GetRoot(), false)
  end
  self:UpdateResourceBar(tagData)
  local goods = NetCmdStoreData:GetSortedStoreGoodListByTag(tagData.id)
  local index = 0
  for i = 0, goods.Count - 1 do
    local data = goods[i]
    if data:IsShow() then
      local item
      index = index + 1
      if self.mGoodItemList[index] == nil then
        item = UIStoreBuyItem.New()
        item:InitCtrl(self.ui.mTrans_BuyContent)
        table.insert(self.mGoodItemList, item)
      else
        item = self.mGoodItemList[index]
      end
      setactive(item:GetRoot(), true)
      item:SetData(data, self)
    end
  end
  self.ui.mTrans_BuyContent.transform:GetComponent(typeof(CS.MonoScrollerFadeManager)).enabled = false
  self.ui.mTrans_BuyContent.transform:GetComponent(typeof(CS.MonoScrollerFadeManager)).enabled = true
end

function ActivityStoreExchangePanel:AddListener()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.ActivityStoreExchangePanel)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    UISystem:JumpToMainPanel()
  end
  self:RegistrationKeyboard(KeyCode.Escape, self.ui.mBtn_Back)
  
  function self.OnPayOrderStoreGoodSuccRefresh()
    if UIManager.IsPanelOpen(UIDef.ActivityStoreExchangePanel) then
      self:RefreshCurItem()
    end
  end
  
  function self.OnCommonReceivePanelShowStart()
    if UIManager.IsPanelOpen(UIDef.ActivityStoreExchangePanel) then
      self:RefreshCurItem()
    end
  end
  
  MessageSys:AddListener(UIEvent.OnCommonReceivePanelShowStart, self.OnCommonReceivePanelShowStart)
  MessageSys:AddListener(UIEvent.PayOrderStoreGoodSuccRefresh, self.OnPayOrderStoreGoodSuccRefresh)
end

function ActivityStoreExchangePanel:RefreshCurItem()
  if self.mCurTagData ~= nil then
    self:RefreshItems(self.mCurTagData)
  end
end

function ActivityStoreExchangePanel:OnClose()
  MessageSys:RemoveListener(UIEvent.OnCommonReceivePanelShowStart, self.OnCommonReceivePanelShowStart)
  MessageSys:RemoveListener(UIEvent.PayOrderStoreGoodSuccRefresh, self.OnPayOrderStoreGoodSuccRefresh)
  self:UnRegistrationKeyboard(KeyCode.Escape, self.ui.mBtn_Back)
  self.ui = nil
  self.curLeftTabId = nil
  self.mCurTagData = nil
  self.mCurTopTab = nil
  for _, v in pairs(self.mLeftTabItemList) do
    gfdestroy(v:GetRoot())
  end
  for _, v in pairs(self.mTopTabItemList) do
    gfdestroy(v:GetRoot())
  end
  self.mLeftTabItemList = {}
  self.mTopTabItemList = {}
  for _, v in pairs(self.mGoodItemList) do
    gfdestroy(v:GetRoot())
  end
  self.mGoodItemList = {}
  if self.topRes then
    self.topRes:Release()
    self.topRes = nil
  end
end

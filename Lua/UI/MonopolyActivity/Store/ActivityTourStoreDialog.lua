require("UI.UIBasePanel")
require("UI.MonopolyActivity.ActivityTourGlobal")
require("UI.MonopolyActivity.Store.Item.Btn_ActivityTourStoreTopItem")
require("UI.MonopolyActivity.Store.Item.ActivityTourStoreItem")
require("UI.MonopolyActivity.Store.Item.ActivityTourStoreCommandItem")
require("UI.Common.UIComTabBtn1ItemV2")
ActivityTourStoreDialog = class("ActivityTourStoreDialog", UIBasePanel)
ActivityTourStoreDialog.__index = ActivityTourStoreDialog

function ActivityTourStoreDialog:ctor(csPanel)
  self.super.ctor(self, csPanel)
  csPanel.Type = UIBasePanelType.Dialog
end

function ActivityTourStoreDialog:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self.listTab = {}
  self.listGoods = {}
  self.listCurrentCommandItem = {}
  self.listCostItem = {}
  self:LuaUIBindTable(root, self.ui)
  MonopolyUtil:SetMonopolyActivityUIHint(self.mUIRoot.transform)
  self:AddBtnListener()
  self:InitLeftCommandList()
  self:InitPoints()
  
  function self.ui.mAniEvent_Refresh.onAnimationEvent()
    self:OnClickTabRefresh()
  end
  
  self.oriFirstDelay = self.ui.mAutoScrollFade_GoodsList.FirstDelay
  self.listCanComposeId = {}
  if data ~= nil then
    self.callBack = data.callBack
  end
  self.shopId = MonopolyWorld.MpData.ShopId
  self.shopData = TableDataBase.listMonopolyShopDatas:GetDataById(self.shopId)
  self.selectComposeId = 0
  self.selectComposeIndex = 0
  self.selectBgCommandId = 0
  self.selectBgCommandIndex = 0
  self.tabType = ActivityTourGlobal.StoreTabType_Buy
  self.haveClose = false
  self:InitTab()
  if not self.btnText then
    local uiTemplate = self.ui.mBtn_Buy.transform:GetComponent(typeof(CS.UITemplate))
    if uiTemplate and 0 < uiTemplate.Texts.Length then
      self.btnText = uiTemplate.Texts[0]
    end
  end
  MessageSys:SendMessage(MonopolyEvent.HideActivityTourMainPanel, nil)
  self:AddMessageListener(MonopolyEvent.OnRefreshCommand, self.OnRefreshCommand)
  self:AddMessageListener(MonopolyEvent.RefreshPointsOnly, self.OnRefreshPoints)
  ActivityTourGlobal.ReplaceAllColor(self.mUIRoot)
end

function ActivityTourStoreDialog:OnShowStart()
  self:Refresh()
end

function ActivityTourStoreDialog:OnShowFinish()
  self:SetFirstDelay()
end

function ActivityTourStoreDialog:OnClose()
  self.super.OnClose(self)
  self.btnText = nil
  self.shopData = nil
  MessageSys:SendMessage(MonopolyEvent.ShowActivityTourMainPanel, false)
  self.ui.mAutoScrollFade_GoodsList.FirstDelay = self.oriFirstDelay
  self.ui.mAniEvent_Refresh.onAnimationEvent = nil
  self.ui = nil
  self.curTabItem = nil
  self:ReleaseCtrlTable(self.listTab, true)
  self:ReleaseCtrlTable(self.listCostItem, true)
  self:ReleaseCtrlTable(self.listCurrentCommandItem, true)
end

function ActivityTourStoreDialog:OnRelease()
end

function ActivityTourStoreDialog:AddBtnListener()
  self.ui.mCG_Root.blocksRaycasts = true
  UIUtils.GetButtonListener(self.ui.mBtn_Refresh.gameObject).onClick = function()
    self:OnBtnRefresh()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Buy.gameObject).onClick = function()
    if self.tabType == ActivityTourGlobal.StoreTabType_Buy then
      self:OnBtnBuy()
    else
      self:OnBtnCompose()
    end
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    self:OnBtnClose()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_OutsideClose.gameObject).onClick = function()
    self:OnBtnClose()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Points.gameObject).onClick = function()
    TipsPanelHelper.OpenUITipsPanel(TableData.GetItemData(ActivityTourGlobal.PointsId))
  end
  UIUtils.GetButtonListener(self.ui.mBtn_DeleteCommand.gameObject).onClick = function()
    self:OnBtnDeleteBgCommand()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_TeamState.gameObject).onClick = function()
    UIManager.OpenUI(UIDef.UIActivityTourTeamStateDialog)
  end
end

function ActivityTourStoreDialog:InitTab()
  for i = ActivityTourGlobal.StoreTabType_Buy, ActivityTourGlobal.StoreTabType_Bag do
    local item = self.listTab[i]
    if item == nil then
      item = UIComTabBtn1ItemV2.New()
      local data = {
        index = i,
        name = i == ActivityTourGlobal.StoreTabType_Buy and MonopolyUtil:GetMonopolyActivityHint(270250) or MonopolyUtil:GetMonopolyActivityHint(270251)
      }
      if i == ActivityTourGlobal.StoreTabType_Bag then
        data.name = MonopolyUtil:GetMonopolyActivityHint(270328)
      end
      item:InitCtrl(self.ui.mScrollListChild_TabList.transform, data)
      self.listTab[i] = item
      item:AddClickListener(function()
        self:OnClickTab(item)
      end)
    end
    if i == ActivityTourGlobal.StoreTabType_Buy then
      self:OnClickTab(item)
    end
  end
end

function ActivityTourStoreDialog:OnClickTab(tabItem)
  if tabItem == self.curTabItem then
    return
  end
  if self.curTabItem ~= nil then
    self.curTabItem:SetBtnInteractable(true)
  end
  tabItem:SetBtnInteractable(false)
  self.curTabItem = tabItem
  self.tabType = tabItem.index
  self.ui.mRoot_Ani:SetTrigger("Tab_FadeIn")
  self.detailInfo = nil
  self.isClickTab = true
  self:Refresh()
  self.isClickTab = false
  if self.ui.mAutoScrollFade_ListCommand then
    self.ui.mAutoScrollFade_ListCommand:DoScrollFade()
  end
end

function ActivityTourStoreDialog:Refresh()
  self:RefreshBuy()
  self:RefreshCompose()
  self:RefreshMyCommandList()
  self:RefreshMyBgCommandList()
end

function ActivityTourStoreDialog:RefreshBuy()
  if self.tabType ~= ActivityTourGlobal.StoreTabType_Buy then
    return
  end
  self.listShopGoods = MonopolyWorld.MpData.ShopGoodsList
  self.selectGoodsId = self.listShopGoods.Count > 0 and self.listShopGoods[0].Id or 0
  self:ShowBuyGoodsPart()
  self:RefreshLeftCommandList()
  self:RefreshGoodsInfo()
  self.ui.mVirtualListEx_Command.verticalNormalizedPosition = 1
end

function ActivityTourStoreDialog:RefreshCompose()
  if self.tabType ~= ActivityTourGlobal.StoreTabType_Compose then
    return
  end
  self:GetComposeCommandList()
  self:ShowBuyGoodsPart()
  self:RefreshLeftCommandList()
  self:RefreshComposeInfo()
  self.ui.mVirtualListEx_Command.verticalNormalizedPosition = 1
end

function ActivityTourStoreDialog:OnBtnRefresh()
  local shopRefreshCount = MonopolyWorld.MpData.ShopRefreshCount
  local maxRefreshCount = MonopolyUtil:GetMaxRefreshNum(shopRefreshCount, self.shopData.refresh_cost)
  if shopRefreshCount >= maxRefreshCount and maxRefreshCount ~= 0 then
    CS.PopupMessageManager.PopupString(MonopolyUtil:GetMonopolyActivityHint(270241))
    return
  end
  local cost = MonopolyUtil:GetShopCostNum(shopRefreshCount, self.shopData.refresh_cost)
  local tip = string_format(MonopolyUtil:GetMonopolyActivityHint(270242), cost, shopRefreshCount, maxRefreshCount)
  MessageBoxPanel.ShowDoubleType(tip, function()
    if MonopolyWorld.IsGmMode then
      return
    end
    if MonopolyWorld.MpData.Points < cost then
      CS.PopupMessageManager.PopupString(MonopolyUtil:GetMonopolyActivityHint(270273))
      return
    end
    self.ui.mCG_Root.blocksRaycasts = false
    NetCmdMonopolyData:SendRefreshShop(function(ret)
      self.ui.mCG_Root.blocksRaycasts = true
      if ret == ErrorCodeSuc then
        CS.PopupMessageManager.PopupPositiveString(MonopolyUtil:GetMonopolyActivityHint(270429))
        self:RefreshBuy()
      end
    end)
  end)
end

function ActivityTourStoreDialog:RefreshMyCommandList(slotIndex)
  local listCurrentCommandId = MonopolyWorld.MpData.commandList
  local maxNum = listCurrentCommandId.Count
  maxNum = math.min(maxNum, ActivityTourGlobal.MaxCommandNum)
  for i = 0, maxNum - 1 do
    local commandID = listCurrentCommandId[i]
    local item = self.listCurrentCommandItem[i + 1]
    if item == nil then
      item = ActivityTourStoreCommandItem.New()
      item:InitCtrl(self.ui.mTrans_CommandRoot, self.RefreshAfterBuyCommand)
      self.listCurrentCommandItem[i + 1] = item
      setactive(item:GetRoot(), true)
    end
    item:SetData(commandID, i == slotIndex)
  end
  for i = maxNum + 1, ActivityTourGlobal.MaxCommandNum do
    local item = self.listCurrentCommandItem[i]
    if item == nil then
      item = ActivityTourStoreCommandItem.New()
      item:InitCtrl(self.ui.mTrans_CommandRoot, self.RefreshAfterBuyCommand)
      self.listCurrentCommandItem[i] = item
      setactive(item:GetRoot(), true)
    end
    item:RefreshEmpty()
  end
end

function ActivityTourStoreDialog:RefreshMyBgCommandList()
  if self.tabType ~= ActivityTourGlobal.StoreTabType_Bag then
    return
  end
  self.bgCommandList = MonopolyWorld.MpData.commandList
  local commandCount = self.bgCommandList.Count
  self.selectBgCommandId = 0 < commandCount and MonopolyWorld.MpData.commandList[0] or 0
  self.selectBgCommandIndex = 0 < commandCount and 0 or -1
  self:ShowBuyGoodsPart()
  self:RefreshLeftCommandList()
  self:RefreshBgCommandInfo()
  self.ui.mVirtualListEx_Command.verticalNormalizedPosition = 1
end

function ActivityTourStoreDialog.RefreshAfterBuyCommand()
  self = ActivityTourStoreDialog
  self:RefreshMyCommandList()
end

function ActivityTourStoreDialog:InitLeftCommandList()
  function self.ui.mVirtualListEx_Command.itemCreated(renderData)
    self:ItemProvider(renderData)
  end
  
  function self.ui.mVirtualListEx_Command.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
end

function ActivityTourStoreDialog:RefreshLeftCommandList()
  if self.ui.mTrans_TextNot.gameObject.activeSelf then
    return
  end
  local isBuy = self.tabType == ActivityTourGlobal.StoreTabType_Buy
  local isCompose = self.tabType == ActivityTourGlobal.StoreTabType_Compose
  self.ui.mText_ListTip.text = isBuy and MonopolyUtil:GetMonopolyActivityHint(270244) or isCompose and MonopolyUtil:GetMonopolyActivityHint(270245) or MonopolyUtil:GetMonopolyActivityHint(270329)
  if isBuy then
    self.ui.mVirtualListEx_Command.vertical = self.listShopGoods.Count > 0
    self.ui.mVirtualListEx_Command.numItems = self.listShopGoods.Count
  elseif isCompose then
    self.ui.mVirtualListEx_Command.vertical = 0 < #self.listCanComposeId or 0 < self.bgCommandList.Count
    self.ui.mVirtualListEx_Command.numItems = #self.listCanComposeId or self.bgCommandList.Count
  else
    self.ui.mVirtualListEx_Command.vertical = 0 < self.bgCommandList.Count
    self.ui.mVirtualListEx_Command.numItems = self.bgCommandList.Count
  end
  self.ui.mVirtualListEx_Command:Refresh()
end

function ActivityTourStoreDialog:ItemProvider(renderData)
  local itemView = ActivityTourStoreItem.New()
  itemView:InitCtrl(renderData.gameObject, function(id, index)
    self:OnClickGoods(id, index)
  end)
  renderData.data = itemView
end

function ActivityTourStoreDialog:ItemRenderer(index, renderData)
  local item = renderData.data
  item:SetClick(function(id, index)
    self:OnClickGoods(id, index)
  end)
  local isBuy = self.tabType == ActivityTourGlobal.StoreTabType_Buy
  if isBuy then
    if index + 1 > self.listShopGoods.Count then
      return
    end
    local goodsId = self.listShopGoods[index].Id
    item:SetData(goodsId, self.listShopGoods[index].GoodId, index)
    item:RefreshStoreInfo(self.selectGoodsId == goodsId, isBuy)
  elseif self.tabType == ActivityTourGlobal.StoreTabType_Bag then
    if index + 1 > self.bgCommandList.Count then
      return
    end
    local commandID = self.bgCommandList[index]
    item:SetData(commandID, commandID, index)
    item:RefreshStoreInfo(self.selectBgCommandIndex == index, isBuy)
  else
    if index + 1 > #self.listCanComposeId then
      return
    end
    local composeId = self.listCanComposeId[index + 1]
    item:SetData(composeId, composeId, index)
    item:RefreshStoreInfo(self.selectComposeIndex == index, isBuy)
  end
end

function ActivityTourStoreDialog:OnClickGoods(id, index)
  local isBuy = self.tabType == ActivityTourGlobal.StoreTabType_Buy
  if isBuy then
    local oriSelectId = self.selectGoodsId
    self.selectGoodsId = id
    self:RefreshGoodsInfo()
    for i = 0, self.listShopGoods.Count - 1 do
      if self.listShopGoods[i].Id == id or self.listShopGoods[i].Id == oriSelectId then
        self.ui.mVirtualListEx_Command:RefreshItemByIndex(i)
      end
    end
  elseif self.tabType == ActivityTourGlobal.StoreTabType_Bag then
    local oriSelectId = self.selectBgCommandId
    self.selectBgCommandId = id
    self.selectBgCommandIndex = index
    self:RefreshBgCommandInfo()
    for i = 0, self.bgCommandList.Count - 1 do
      if self.bgCommandList[i] == id or self.bgCommandList[i] == oriSelectId then
        self.ui.mVirtualListEx_Command:RefreshItemByIndex(i)
      end
    end
  else
    local oriSelectId = self.selectComposeId
    self.selectComposeId = id
    self.selectComposeIndex = index
    self:RefreshComposeInfo()
    for i = 1, #self.listCanComposeId do
      if self.listCanComposeId[i] == id or self.listCanComposeId[i] == oriSelectId then
        self.ui.mVirtualListEx_Command:RefreshItemByIndex(i - 1)
      end
    end
  end
end

function ActivityTourStoreDialog:RefreshGoodsInfo()
  local isSoldOut = true
  local commandId = 0
  local totalCount = self.listShopGoods.Count
  if 0 < totalCount then
    for i = 0, self.listShopGoods.Count do
      if self.selectGoodsId == self.listShopGoods[i].Id then
        commandId = self.listShopGoods[i].GoodId
        isSoldOut = 0 >= self.listShopGoods[i].Limit
        break
      end
    end
  end
  local data = TableData.listMonopolyOrderDatas:GetDataById(commandId)
  if data then
    self:RefreshInfoInternal(data)
  end
  local isFull = MonopolyWorld.MpData.IsCommandFull
  setactive(self.ui.mTrans_GrpReplace.gameObject, isFull and not isSoldOut)
  if isFull and not isSoldOut then
    self.ui.mText_ReplaceInfo.text = MonopolyUtil:GetMonopolyActivityHint(270331)
  end
  setactive(self.ui.mTrans_GrpSold.gameObject, isSoldOut)
  setactive(self.ui.mTrans_Buy.gameObject, not isSoldOut)
end

function ActivityTourStoreDialog:RefreshComposeInfo()
  if self.selectComposeId <= 0 then
    return
  end
  local data = TableData.listMonopolyOrderDatas:GetDataById(self.selectComposeId)
  if not data then
    return
  end
  self:RefreshInfoInternal(data)
  setactive(self.ui.mTrans_GrpSold.gameObject, false)
  setactive(self.ui.mTrans_Buy.gameObject, true)
  self:RefreshComposeCost()
end

function ActivityTourStoreDialog:RefreshGoodsDetail()
  if not self.detailInfo then
    return
  end
  self.ui.mText_Title.text = self.detailInfo.name.str
  self.ui.mImg_QualityLine.color = ActivityTourGlobal.GetCommandItemQualityColor(self.detailInfo.level)
  setactive(self.ui.mTrans_Step.gameObject, true)
  self.ui.mText_Step.text = TableData.GetActivityTourStepContent(self.detailInfo)
  self.ui.mText_Desc.text = self.detailInfo.order_desc.str
end

function ActivityTourStoreDialog:RefreshBgCommandInfo()
  if self.selectBgCommandId <= 0 then
    return
  end
  local data = TableData.listMonopolyOrderDatas:GetDataById(self.selectBgCommandId)
  if not data then
    return
  end
  self:RefreshInfoInternal(data)
  local commandCount = self.bgCommandList.Count
  setactive(self.ui.mTrans_DeleteCommand.gameObject, 1 < commandCount)
  setactive(self.ui.mTrans_GrpReplace.gameObject, commandCount <= 1)
  if commandCount <= 1 then
    self.ui.mText_ReplaceInfo.text = MonopolyUtil:GetMonopolyActivityHint(270332)
  end
  local rewardItem = self.listCostItem[1]
  if rewardItem == nil then
    rewardItem = UICommonItem.New()
    rewardItem:InitCtrl(self.ui.mScrollListChild_Cost.transform, true)
    table.insert(self.listCostItem, rewardItem)
  end
  setactive(rewardItem:GetRoot(), true)
  rewardItem:SetByItemData(TableData.GetItemData(ActivityTourGlobal.PointsId), data.sold)
  rewardItem:SetIcon(ActivityTourGlobal.GetPointIcon())
  for i = 2, #self.listCostItem do
    setactive(self.listCostItem[i]:GetRoot(), false)
  end
end

function ActivityTourStoreDialog:RefreshInfoInternal(data)
  self.detailInfo = data
  if not self.isClickTab then
    self:RefreshGoodsDetail()
  end
  local isBuy = self.tabType == ActivityTourGlobal.StoreTabType_Buy
  if self.btnText then
    self.btnText.text = isBuy and MonopolyUtil:GetMonopolyActivityHint(270246) or MonopolyUtil:GetMonopolyActivityHint(270247)
  end
end

function ActivityTourStoreDialog:ShowBuyGoodsPart()
  local isBuy = self.tabType == ActivityTourGlobal.StoreTabType_Buy
  setactive(self.ui.mTrans_ComposeCost.gameObject, not isBuy)
  setactive(self.ui.mTrans_Buy.gameObject, isBuy)
  setactive(self.ui.mTrans_Refresh.gameObject, isBuy)
  setactive(self.ui.mTrans_DeleteCommand.gameObject, false)
  if isBuy then
    setactive(self.ui.mTrans_TextNot.gameObject, false)
    setactive(self.ui.mTrans_Left.gameObject, true)
    setactive(self.ui.mTrans_Right.gameObject, true)
  elseif self.tabType == ActivityTourGlobal.StoreTabType_Bag then
    setactive(self.ui.mTrans_TextNot.gameObject, self.selectBgCommandId <= 0)
    setactive(self.ui.mTrans_NoneDesc.gameObject, false)
    self.ui.mText_NoneTitle.text = MonopolyUtil:GetMonopolyActivityHint(270333)
    self.ui.mText_CostTitle.text = MonopolyUtil:GetMonopolyActivityHint(270334)
    setactive(self.ui.mTrans_Left.gameObject, self.selectBgCommandId > 0)
    setactive(self.ui.mTrans_Right.gameObject, self.selectBgCommandId > 0)
    setactive(self.ui.mTrans_GrpSold.gameObject, false)
  else
    setactive(self.ui.mTrans_TextNot.gameObject, 0 >= self.selectComposeId)
    setactive(self.ui.mTrans_NoneDesc.gameObject, true)
    self.ui.mText_NoneTitle.text = MonopolyUtil:GetMonopolyActivityHint(270061)
    self.ui.mText_CostTitle.text = MonopolyUtil:GetMonopolyActivityHint(270059)
    setactive(self.ui.mTrans_Left.gameObject, 0 < self.selectComposeId)
    setactive(self.ui.mTrans_Right.gameObject, 0 < self.selectComposeId)
    setactive(self.ui.mTrans_GrpReplace.gameObject, false)
  end
end

function ActivityTourStoreDialog:OnBtnBuy()
  if MonopolyWorld.IsGmMode then
    local listCurrentCommandId = MonopolyWorld.MpData.commandList
    local bFind = false
    for i = 0, listCurrentCommandId.Count - 1 do
      if listCurrentCommandId[i] == self.selectGoodsId then
        bFind = true
        break
      end
    end
    if not bFind and 0 < listCurrentCommandId.Count then
      self:RefreshMyCommandList(listCurrentCommandId[0])
    end
  else
    local buyShopItem
    for i = 0, self.listShopGoods.Count - 1 do
      local shopItem = self.listShopGoods[i]
      if self.selectGoodsId == shopItem.Id then
        buyShopItem = shopItem
        if MonopolyWorld.MpData.Points < shopItem.Price then
          CS.PopupMessageManager.PopupString(MonopolyUtil:GetMonopolyActivityHint(270273))
          return
        end
      end
    end
    self.ui.mCG_Root.blocksRaycasts = false
    NetCmdMonopolyData:TryGetCommand(buyShopItem.GoodId, buyShopItem.IsNew, function(replaceIndex, getCommandType)
      NetCmdMonopolyData:SendBuyShopItem(self.selectGoodsId, function(ret)
        self.ui.mCG_Root.blocksRaycasts = true
        if ret == ErrorCodeSuc then
          self:RefreshBuy()
          NetCmdMonopolyData:ShowGetCommandTip(buyShopItem.GoodId, replaceIndex, getCommandType, false)
          CS.PopupMessageManager.PopupPositiveString(MonopolyUtil:GetMonopolyActivityHint(270243))
        end
      end, replaceIndex)
    end)
  end
end

function ActivityTourStoreDialog:OnBtnCompose()
  if MonopolyWorld.IsGmMode then
    return
  end
  self.ui.mCG_Root.blocksRaycasts = false
  NetCmdMonopolyData:SendComposeShopItem(self.selectComposeId, function(ret)
    self.ui.mCG_Root.blocksRaycasts = true
    if ret == ErrorCodeSuc then
      self:RefreshCompose()
      self:RefreshMyCommandList()
      CS.PopupMessageManager.PopupPositiveString(MonopolyUtil:GetMonopolyActivityHint(270272))
    end
  end)
end

function ActivityTourStoreDialog:OnBtnDeleteBgCommand()
  if MonopolyWorld.IsGmMode then
    return
  end
  self.ui.mCG_Root.blocksRaycasts = false
  MonopolyWorld.MpData:DeleteCommand(self.selectBgCommandIndex, function(ret)
    self.ui.mCG_Root.blocksRaycasts = true
    if ret == ErrorCodeSuc then
      CS.PopupMessageManager.PopupPositiveString(MonopolyUtil:GetMonopolyActivityHint(270330))
      self:RefreshMyBgCommandList()
      self:RefreshMyCommandList()
    end
  end)
end

function ActivityTourStoreDialog:OnBtnClose()
  if MonopolyWorld.IsGmMode then
    UIManager.CloseUI(UIDef.ActivityTourStoreDialog)
    if self.callBack then
      self.callBack()
    end
    return
  end
  local tip = MonopolyUtil:GetMonopolyActivityHint(270248)
  MessageBoxPanel.ShowDoubleType(tip, function()
    self.haveClose = true
    NetCmdMonopolyData:RefreshAndResetPoint()
    self.ui.mCG_Root.blocksRaycasts = false
    NetCmdMonopolyData:SendCloseShop(function(ret)
      self.ui.mCG_Root.blocksRaycasts = true
      if ret ~= ErrorCodeSuc then
        print_error("\229\133\179\233\151\173\229\149\134\229\186\151\229\164\177\232\180\165!")
      end
      if self.callBack then
        self.callBack()
      end
      self.callBack = nil
      MonopolyWorld.MpData.ShopRefreshCount = 0
      UIManager.CloseUI(UIDef.ActivityTourStoreDialog)
    end)
  end)
end

function ActivityTourStoreDialog:GetComposeCommandList()
  if not self.listComposeData then
    self.listComposeData = {}
    self:GetComposeCommandListInternal()
  end
  self.listCanComposeId = {}
  local listCurrentCommandId = MonopolyWorld.MpData.commandList
  for k, v in pairs(self.listComposeData) do
    local isEnough = true
    local canMergeCount = 999
    for id, needNum in pairs(v) do
      local curNum = 0
      for i = 0, listCurrentCommandId.Count - 1 do
        if listCurrentCommandId[i] == id then
          curNum = curNum + 1
        end
      end
      if needNum > curNum then
        isEnough = false
        canMergeCount = 0
        break
      else
        canMergeCount = math.min(canMergeCount, math.floor(curNum / needNum))
      end
    end
    if isEnough then
      for i = 1, canMergeCount do
        table.insert(self.listCanComposeId, k)
      end
    end
  end
  table.sort(self.listCanComposeId, function(a, b)
    local dataA = TableDataBase.listMonopolyOrderDatas:GetDataById(a)
    local dataB = TableDataBase.listMonopolyOrderDatas:GetDataById(b)
    if dataA.level ~= dataB.level then
      return dataA.level > dataB.level
    else
      return a < b
    end
  end)
  self.selectComposeId = 0
  self.selectComposeIndex = 0
  for _, v in pairs(self.listCanComposeId) do
    self.selectComposeId = v
    self.selectComposeIndex = math.max(_ - 1, 0)
    break
  end
end

function ActivityTourStoreDialog:GetComposeCommandListInternal()
  TableData.listMonopolyOrderDatas:ForcePreLoadAll()
  local monopolyOrderList = TableDataBase.listMonopolyOrderDatas:GetList()
  if monopolyOrderList == nil then
    return
  end
  for i = 0, monopolyOrderList.Count - 1 do
    local key = monopolyOrderList[i].id
    local data = TableDataBase.listMonopolyOrderDatas:GetDataById(key)
    if data and 0 < data.up_class.Count then
      self.listComposeData[key] = {}
      for k, v in pairs(data.up_class) do
        self.listComposeData[key][k] = v
      end
    end
  end
end

function ActivityTourStoreDialog:RefreshComposeCost()
  if self.selectComposeId <= 0 then
    return
  end
  local data = TableDataBase.listMonopolyOrderDatas:GetDataById(self.selectComposeId)
  if not data then
    return
  end
  local costList = {}
  for k, v in pairs(data.up_class) do
    table.insert(costList, {id = k, num = v})
  end
  local index = 1
  for i = 1, #costList do
    local commandId = costList[i].id
    local commandNum = costList[i].num
    for j = 1, commandNum do
      local rewardItem = self.listCostItem[index]
      if rewardItem == nil then
        rewardItem = UICommonItem.New()
        rewardItem:InitCtrl(self.ui.mScrollListChild_Cost.transform, true)
        table.insert(self.listCostItem, rewardItem)
      end
      setactive(rewardItem:GetRoot(), true)
      rewardItem:SetDaiyanCommandData(commandId)
      index = index + 1
    end
  end
  for i = index, #self.listCostItem do
    setactive(self.listCostItem[i]:GetRoot(), false)
  end
end

function ActivityTourStoreDialog:OnRefreshCommand(msg)
  local slotIndex = msg.Sender
  self:RefreshGoodsInfo()
  self:RefreshMyCommandList(slotIndex)
end

function ActivityTourStoreDialog:InitPoints()
  self.ui.mImg_PointsIcon.sprite = ActivityTourGlobal.GetPointIcon()
  self:OnRefreshPoints()
end

function ActivityTourStoreDialog:OnRefreshPoints()
  if self.haveClose then
    return
  end
  self.ui.mText_Points.text = MonopolyWorld.MpData.Points
end

function ActivityTourStoreDialog:OnClickTabRefresh()
  self:RefreshGoodsDetail()
end

function ActivityTourStoreDialog:SetFirstDelay()
  self.ui.mAutoScrollFade_GoodsList.FirstDelay = 0
end

require("UI.MessageBox.MessageBoxPanel")
require("UI.UIBasePanel")
require("UI.StorePanel.Item.UIStoreExchangePriceInfoItem")
UIComItemExchangeDialog = class("UIComItemExchangeDialog", UIBasePanel)
UIComItemExchangeDialog.__index = UIComItemExchangeDialog
local self = UIComItemExchangeDialog

function UIComItemExchangeDialog:ctor(obj)
  UIComItemExchangeDialog.super.ctor(UIComItemExchangeDialog, obj)
  obj.Type = UIBasePanelType.Dialog
end

function UIComItemExchangeDialog:OnAwake()
  self.selectIndex = 1
  self.itemViewList = {}
end

function UIComItemExchangeDialog:OnInit(root, param)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.param = param
  self.systemType = 0
  setactive(self.ui.mTrans_PriceDetails, false)
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    self:OnCloseUI()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpClose.gameObject).onClick = function()
    self:OnCloseUI()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnConfirm.gameObject).onClick = function()
    self:OnClickConfirmBtn()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnConfirm.gameObject).onClick = function()
    self:OnClickConfirmBtn()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnCancel.gameObject).onClick = function()
    self:OnCloseUI()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnInfo.gameObject).onClick = function()
    self:ShowPriceItem()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_BtnInfo1.gameObject).onClick = function()
    setactive(self.ui.mTrans_PriceDetails, false)
  end
end

function UIComItemExchangeDialog:OnShowStart()
end

function UIComItemExchangeDialog:OnCloseUI()
  if self.ui.mTrans_PriceDetails.gameObject.activeSelf then
    setactive(self.ui.mTrans_PriceDetails, false)
  else
    UIManager.CloseUI(UIDef.UIComItemExchangeDialog)
  end
end

function UIComItemExchangeDialog:OnShowFinish()
  self:RefreshData()
end

function UIComItemExchangeDialog:RefreshData()
  self:SetItemList()
  self:SetUIData()
end

function UIComItemExchangeDialog:SetItemList()
  self.systemType = self.param[0]
  if self.systemType == 1 then
    if self.param[1] and self.param[2] then
      self.storeDataA = TableDataBase.listStoreGoodDatas:GetDataById(self.param[1])
      self.mData = TableDataBase.listStoreGoodDatas:GetDataById(self.param[2])
      self.itemDataA = TableData.listItemDatas:GetDataById(self.storeDataA.price_type)
      self.itemDataB = TableData.listItemDatas:GetDataById(self.mData.price_type)
      self.exchangeItem = TableData.listItemDatas:GetDataById(102)
      local itemArrayA = string.split(self.storeDataA.reward, ":")
      local itemArrayB = string.split(itemArrayA[2], ";")
      self.itemNumA = tonumber(itemArrayB[1])
      self.itemNumB = 1
      self.itemCountA = NetCmdItemData:GetResItemCount(self.storeDataA.price_type)
      self.itemCountB = NetCmdItemData:GetResItemCount(self.mData.price_type)
      self:SetItemData()
    end
  elseif self.systemType == 2 and self.param[1] then
    self.mData = TableDataBase.listStoreGoodDatas:GetDataById(self.param[1])
    self.itemData = TableData.listItemDatas:GetDataById(self.mData.price_type)
    self.itemCount = NetCmdItemData:GetResItemCount(self.mData.price_type)
    self.storeData = NetCmdStoreData:GetCurStaminaStage(self.mData.id)
    local itemArrayA = string.split(self.mData.reward, ":")
    self.buyItemData = TableData.listItemDatas:GetDataById(tonumber(itemArrayA[1]))
    local itemArrayB = string.split(itemArrayA[2], ";")
    self.itemNumA = tonumber(itemArrayB[1])
    local needView
    if self.needItem == nil then
      needView = UICommonItem.New()
      needView:InitCtrl(self.ui.mScrollListChild_Content)
      self.needItem = needView
    else
      needView = self.needItem
    end
    self.needPrice = 0
    if self.mData.price_args_type == 1 then
      self.needPrice = self.mData.price
    elseif self.mData.price_args_type == 2 then
      self.goodsData = NetCmdStoreData:GetStoreGoodsById(self.mData.id)
      if self.goodsData.buy_times >= self.mData.price_args.Count then
        local strList = string.split(self.mData.price_args[self.mData.price_args.Count - 1], ":")
        self.needPrice = tonumber(strList[1])
      else
        for i = 1, self.mData.price_args.Count do
          if i > self.goodsData.buy_times then
            local strList = string.split(self.mData.price_args[i - 1], ":")
            self.needPrice = tonumber(strList[1])
            break
          end
        end
      end
    end
    self.ui.mText_TextName.text = string_format(TableData.GetHintById(120204), self.itemData.name)
    needView:SetPVPChangeData(self.mData.price_type, 1, function()
      if self.goodsData.remain_times > 0 and 0 < self.needPrice then
        local desc = string_format(TableData.GetHintById(290904), self.needPrice, self.itemData.name, self.itemNumA, self.buyItemData.name)
        self.ui.mText_Description.text = desc
      else
        self.ui.mText_Description.text = TableData.GetHintById(120206)
      end
    end)
    local hint = TableData.GetHintReplaceById(808, self.goodsData.remain_times)
    if self.mData.refresh_type == 1 then
      hint = TableData.GetHintReplaceById(106001, self.goodsData.remain_times)
    end
    if self.mData.refresh_type == 2 then
      hint = TableData.GetHintReplaceById(106002, self.goodsData.remain_times)
    end
    if self.mData.refresh_type == 3 then
      hint = TableData.GetHintReplaceById(106003, self.goodsData.remain_times)
    end
    self.ui.mText_ExchangeTimes.text = hint
    if 0 < self.goodsData.remain_times and 0 < self.needPrice then
      local desc = string_format(TableData.GetHintById(290904), self.needPrice, self.itemData.name, self.itemNumA, self.buyItemData.name)
      self.ui.mText_Description.text = desc
    else
      self.ui.mText_Description.text = TableData.GetHintById(120206)
    end
    needView.ui.mText_Num.text = self.needPrice
    needView.ui.mText_Num.color = self.needPrice <= self.itemCount and ColorUtils.WhiteColor or ColorUtils.RedColor
    self.ui.mText_Num.text = self.needPrice
    self.ui.mImg_Icon.sprite = IconUtils.GetItemIcon(self.itemData.icon)
    setactive(self.ui.mBtn_Btn.gameObject, true)
  end
end

function UIComItemExchangeDialog:ShowPriceItem()
  if self.storeData == nil then
    return
  end
  setactive(self.ui.mTrans_PriceDetails, true)
  local priceList = self.storeData.MultiPriceDict
  local buyTime = self.storeData.buy_times
  for i = 0, priceList.Count - 1 do
    local item = self.itemViewList[i + 1]
    if item == nil then
      item = UIStoreExchangePriceInfoItem.New()
      item:InitCtrl(self.ui.mTrans_Content)
      table.insert(self.itemViewList, item)
    end
    item:SetData(priceList[i])
    if 0 < buyTime and buyTime == i + 1 then
      item:SetNow()
    end
  end
end

function UIComItemExchangeDialog:SetItemData()
  local itemview, needView
  local tmpStr = string_format(TableData.GetHintById(120053), self.itemNumB, self.itemDataA.Name.str, self.itemNumA, self.exchangeItem.Name.str)
  if self.uiCommonItem == nil then
    itemview = UICommonItem.New()
    itemview:InitCtrl(self.ui.mScrollListChild_Content)
    self.uiCommonItem = itemview
  else
    itemview = self.uiCommonItem
  end
  itemview:SetPVPChangeData(self.itemDataA.id, self.itemCountA, function()
    itemview:SetSelect(true)
    self.selectIndex = 1
    self.ui.mText_TextName.text = TableData.GetHintById(120052)
    self.ui.mText_Description.text = tmpStr
    setactive(self.ui.mText_ExchangeTimes.gameObject, false)
    if self.needItem then
      self.needItem:SetSelect(false)
    end
  end)
  if self.needItem == nil then
    needView = UICommonItem.New()
    needView:InitCtrl(self.ui.mScrollListChild_Content)
    self.needItem = needView
  else
    needView = self.needItem
  end
  self.needPrice = 0
  if self.mData.price_args_type == 1 then
    self.needPrice = self.mData.price
  elseif self.mData.price_args_type == 2 then
    self.goodsData = NetCmdStoreData:GetStoreGoodsById(self.mData.id)
    for i = 1, self.mData.price_args.Count do
      if i > self.goodsData.buy_times then
        local strList = string.split(self.mData.price_args[i - 1], ":")
        self.needPrice = tonumber(strList[1])
        break
      end
    end
  end
  needView:SetPVPChangeData(self.mData.price_type, self.itemCountB, function()
    needView:SetSelect(true)
    self.selectIndex = 2
    self.ui.mText_TextName.text = TableData.GetHintById(290903)
    if self.goodsData.remain_times > 0 and 0 < self.needPrice then
      local desc = string_format(TableData.GetHintById(120205), self.needPrice, 1, self.itemNumA)
      self.ui.mText_Description.text = desc
    else
      self.ui.mText_Description.text = TableData.GetHintById(120206)
    end
    setactive(self.ui.mText_ExchangeTimes.gameObject, true)
    if self.uiCommonItem then
      self.uiCommonItem:SetSelect(false)
    end
  end)
  local hint = TableData.GetHintReplaceById(808, self.goodsData.remain_times)
  if self.mData.refresh_type == 1 then
    hint = TableData.GetHintReplaceById(106001, self.goodsData.remain_times)
  end
  if self.mData.refresh_type == 2 then
    hint = TableData.GetHintReplaceById(106002, self.goodsData.remain_times)
  end
  if self.mData.refresh_type == 3 then
    hint = TableData.GetHintReplaceById(106003, self.goodsData.remain_times)
  end
  self.ui.mText_ExchangeTimes.text = hint
  if self.selectIndex == 1 then
    itemview:SetSelect(true)
    needView:SetSelect(false)
    self.ui.mText_TextName.text = TableData.GetHintById(120052)
    self.ui.mText_Description.text = tmpStr
    setactive(self.ui.mText_ExchangeTimes.gameObject, false)
    setactive(itemview.ui.mTrans_Num.gameObject, true)
    itemview.ui.mText_Num.text = self.itemCountA
    itemview.ui.mText_Num.color = self.itemNumB <= self.itemCountA and ColorUtils.WhiteColor or ColorUtils.RedColor
  else
    itemview:SetSelect(false)
    needView:SetSelect(true)
    self.ui.mText_TextName.text = TableData.GetHintById(120204)
    needView.ui.mText_Num.text = self.itemCountB
    needView.ui.mText_Num.color = self.needPrice <= self.itemCountB and ColorUtils.WhiteColor or ColorUtils.RedColor
    setactive(needView.ui.mTrans_Num.gameObject, true)
    setactive(self.ui.mText_ExchangeTimes.gameObject, true)
  end
end

function UIComItemExchangeDialog:SetUIData()
  if self.systemType == 1 then
    self.ui.mText_TitleText.text = TableData.GetHintById(120051)
  elseif self.buyItemData.Id == TableData.GuildSettingData.GuildbattleTicketItem then
    self.ui.mText_TitleText.text = TableData.GetHintById(390275)
  else
    self.ui.mText_TitleText.text = TableData.GetHintById(290901)
  end
end

function UIComItemExchangeDialog:OnClickConfirmBtn()
  if self.systemType == 1 then
    if self.selectIndex == 1 then
      if 1 > self.itemCountA then
        local desc = string_format(TableData.GetHintById(108059), self.itemDataA.Name.str)
        CS.PopupMessageManager.PopupPositiveString(desc)
        return
      end
      NetCmdPVPData:ReqNrtPvpTicketExchange(function(ret)
        if ret == ErrorCodeSuc then
          UIManager.CloseUI(UIDef.UIComItemExchangeDialog)
          local hint = TableData.GetHintById(120055)
          CS.PopupMessageManager.PopupPositiveString(hint)
        end
      end)
    elseif 1 > NetCmdItemData:GetNetItemCount(self.storeDataA.price_type) then
      if self.needPrice == 0 then
        CS.PopupMessageManager.PopupPositiveString(TableData.GetHintById(106012))
        return
      end
      if self.itemCountB >= self.needPrice then
        if 0 < self.goodsData.remain_times then
          local callback = function()
            local hint = TableData.GetHintById(106013)
            CS.PopupMessageManager.PopupPositiveString(hint)
            TimerSys:DelayCall(0.3, function()
              self:RefreshData()
            end)
          end
          CS.UIStoreGlobal.OnBuyClick(self.goodsData, nil, 1, callback)
        else
          CS.PopupMessageManager.PopupPositiveString(TableData.GetHintById(106012))
        end
      end
    end
  elseif self.buyItemData.Id == TableData.GuildSettingData.GuildbattleTicketItem then
    self:OnClickGuildCostItem()
  else
    local itemId = TableDataBase.GlobalSystemData.HighPVPTicket
    local currItemCount = NetCmdItemData:GetItemCountById(itemId)
    local maxCount = GlobalData.GetStaminaResourceMaxNum(itemId)
    print("itemId = " .. itemId .. "  \229\189\147\229\137\141\230\149\176\230\141\174 = " .. currItemCount .. " \230\156\128\229\164\167\230\149\176\233\135\143 = " .. maxCount)
    if currItemCount >= maxCount then
      if self.buyItemData then
        local desc = string_format(TableData.GetHintById(290908), self.buyItemData.name)
        CS.PopupMessageManager.PopupPositiveString(desc)
      end
      return
    end
    if 0 >= self.goodsData.remain_times then
      CS.PopupMessageManager.PopupPositiveString(TableData.GetHintById(106012))
      return
    end
    if self.itemCount >= self.needPrice then
      local callback = function()
        local hint = string_format(TableData.GetHintById(290902), self.buyItemData.name)
        CS.PopupMessageManager.PopupPositiveString(hint)
        TimerSys:DelayCall(0.3, function()
          self:RefreshData()
        end)
      end
      CS.UIStoreGlobal.OnBuyClick(self.goodsData, nil, 1, callback)
    else
      MessageBoxPanel.ShowItemNotEnoughMessage(1, function()
        MessageBoxPanel.IsItemNotEnough = false
        UISystem:JumpByID(3)
      end)
    end
  end
end

function UIComItemExchangeDialog:OnClickGuildCostItem()
  local itemId = TableData.GuildSettingData.GuildbattleTicketItem
  local currItemCount = NetCmdItemData:GetItemCountById(itemId)
  local maxLimit = TableData.listItemLimitDatas:GetDataById(itemId)
  local maxCount = maxLimit.MaxLimit
  print("itemId = " .. itemId .. "  \229\189\147\229\137\141\230\149\176\230\141\174 = " .. currItemCount .. " \230\156\128\229\164\167\230\149\176\233\135\143 = " .. maxCount)
  if currItemCount >= maxCount then
    if self.buyItemData then
      local desc = string_format(TableData.GetHintById(290908), self.buyItemData.name)
      CS.PopupMessageManager.PopupPositiveString(desc)
    end
    return
  end
  if self.goodsData.remain_times <= 0 then
    CS.PopupMessageManager.PopupPositiveString(TableData.GetHintById(106012))
    return
  end
  if self.itemCount >= self.needPrice then
    local callback = function()
      local hint = string_format(TableData.GetHintById(290902), self.buyItemData.name)
      CS.PopupMessageManager.PopupPositiveString(hint)
      TimerSys:DelayCall(0.3, function()
        self:RefreshData()
      end)
    end
    CS.UIStoreGlobal.OnBuyClick(self.goodsData, nil, 1, callback)
  else
    MessageBoxPanel.ShowItemNotEnoughMessage(1, function()
      MessageBoxPanel.IsItemNotEnough = false
      UISystem:JumpByID(3)
    end)
  end
end

function UIComItemExchangeDialog:OnClose()
end

function UIComItemExchangeDialog:OnRelease()
  if self.uiCommonItem then
    self.uiCommonItem:OnRelease(true)
  end
  if self.needItem then
    self.needItem:OnRelease(true)
  end
end

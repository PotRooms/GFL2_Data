require("UI.UIBasePanel")
require("UI.MailPanelV2.UIMailPanelV2View")
require("UI.MailPanelV2.Item.UIMailLeftTabItemV2")
require("UI.Common.UICommonItem")
require("UI.BattlePass.UIBattlePassGlobal")
UIMailPanelV2 = class("UIMailPanelV2", UIBasePanel)
UIMailPanelV2.__index = UIMailPanelV2
UIMailPanelV2.mPath_MailListItem = "Mail/MailLeftTabItemV2.prefab"
UIMailPanelV2.mView = nil
UIMailPanelV2.mCurSelMailItem = nil
UIMailPanelV2.mMailListItems = {}
UIMailPanelV2.mAttachmentIds = {}
UIMailPanelV2.mAttachmentItems = {}
UIMailPanelV2.mCachedMailList = nil
UIBasePanel.mIsSyncOn = false
UIMailPanelV2.tipsItem = nil

function UIMailPanelV2:ctor()
  UIMailPanelV2.super.ctor(self)
end

function UIMailPanelV2:OnInit(root)
  UIMailPanelV2.super.SetRoot(UIMailPanelV2, root)
  self.RedPointType = {
    RedPointConst.Mails
  }
  self.mView = UIMailPanelV2View.New()
  self.ui = {}
  self.mView:InitCtrl(root, self.ui)
  self.virtualList = self.ui.mList_Material
  
  function self.virtualList.itemCreated(renderData)
    local item = self:MailItemProvider(renderData)
    return item
  end
  
  function self.virtualList.itemRenderer(index, renderData)
    self:MailItemRenderer(index, renderData)
  end
  
  self.bIsDefaultSet = false
  self.prevSelectIndex = -1
  self:InitMailList()
  UIUtils.GetButtonListener(self.ui.mBtn_BackItem.gameObject).onClick = function(gameObj)
    self:OnReturnClick(gameObj)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_HomeItem.gameObject).onClick = function()
    self:OnCommanderCenter()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Delete.gameObject).onClick = function(gameObj)
    self:OnDeleteBtnClicked(gameObj)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Right3Item.gameObject).onClick = function(gameObj)
    self:OnAllReceive(gameObj)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Left3Item.gameObject).onClick = function(gameObj)
    self:OnDeleteAllBtnClicked(gameObj)
  end
  
  function self.onMailChangedCallBack()
    self:OnMailChangedCallBack()
  end
  
  function self.redPointUpdate(msg)
    if msg.Sender == "Mails" then
      self.bIsDefaultSet = false
      self.prevSelectIndex = -1
      self:ClearSelect()
      self.mCachedMailList:Clear()
      self.mCachedMailList = NetCmdMailData:GetSortedMailList()
      self.virtualList.numItems = self.mCachedMailList.Count
      self.virtualList:Refresh()
      self.ui.mScrollbar_Material.value = 1
      setactive(self.ui.mTrans_MailList.gameObject, self.mCachedMailList.Count > 0)
      setactive(self.ui.mTrans_None.gameObject, self.mCachedMailList.Count <= 0)
      self.ui.mText_Num.text = self.mCachedMailList.Count
      self:UpdateRedPoint()
    end
  end
  
  function self.onMailGetAttachment(msg)
  end
  
  function self.onMailsGetAttachment(_)
  end
  
  function self.onMailUpdate(msg)
    if msg.Sender == self.mCurSelMailItem.mData.id then
      self:RequestMailContent()
    end
  end
  
  function self.onMailDelete(msg)
    self.virtualList:ScrollTo(0, false)
    self.bIsDefaultSet = false
    self.prevSelectIndex = -1
    self:ClearSelect()
    self.mCachedMailList:Clear()
    self.mCurSelMailItem = nil
    self.mCachedMailList = NetCmdMailData:GetSortedMailList()
    self.virtualList.numItems = self.mCachedMailList.Count
    self.virtualList:Refresh()
    self.ui.mScrollbar_Material.value = 1
    setactive(self.ui.mTrans_MailList.gameObject, 0 < self.mCachedMailList.Count)
    setactive(self.ui.mTrans_None.gameObject, 0 >= self.mCachedMailList.Count)
    self.ui.mText_Num.text = self.mCachedMailList.Count
  end
  
  MessageSys:AddListener(CS.GF2.Message.MailEvent.OnMailDelete, self.onMailDelete)
  MessageSys:AddListener(CS.GF2.Message.MailEvent.OnMailUpdate, self.onMailUpdate)
  MessageSys:AddListener(CS.GF2.Message.MailEvent.OnMailsGetAttachment, self.onMailsGetAttachment)
  MessageSys:AddListener(CS.GF2.Message.MailEvent.OnMailGetAttachment, self.onMailGetAttachment)
  MessageSys:AddListener(CS.GF2.Message.RedPointEvent.RedPointUpdate, self.redPointUpdate)
  MessageSys:AddListener(CS.GF2.Message.MailEvent.MailDelete, self.onMailChangedCallBack)
  
  function self.ui.mList_Item.itemProvider()
    return self:GetRenderItem()
  end
  
  function self.ui.mList_Item.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
  
  self.ui.mText_NumAll.text = "/" .. TableData.GlobalConfigData.MailMaxlimit
end

function UIMailPanelV2:OnTop()
end

function UIMailPanelV2:OnShowFinish()
  if self.mCurSelMailItem ~= nil and self.mCurSelMailItem.mData.IsExpired then
    self.onMailDelete()
  else
    self.virtualList:Refresh()
    if not self.skipRefresh then
      self:RefreshMailList()
    else
      self.skipRefresh = nil
    end
  end
end

function UIMailPanelV2:OnClose()
  MessageSys:RemoveListener(CS.GF2.Message.MailEvent.OnMailDelete, self.onMailDelete)
  MessageSys:RemoveListener(CS.GF2.Message.MailEvent.OnMailUpdate, self.onMailUpdate)
  MessageSys:RemoveListener(CS.GF2.Message.MailEvent.OnMailsGetAttachment, self.onMailsGetAttachment)
  MessageSys:RemoveListener(CS.GF2.Message.MailEvent.OnMailGetAttachment, self.onMailGetAttachment)
  MessageSys:RemoveListener(CS.GF2.Message.RedPointEvent.RedPointUpdate, self.redPointUpdate)
  MessageSys:RemoveListener(CS.GF2.Message.MailEvent.MailDelete, self.onMailChangedCallBack)
  self.virtualList:ScrollTo(0, false)
  self:ClearSelect()
  self.mCachedMailList = nil
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  if self.clickTimer ~= nil then
    self.clickTimer:Stop()
    self.clickTimer = nil
  end
  self.canClick = true
end

function UIMailPanelV2:OnRelease()
  self.mCurSelMailItem = nil
  self.virtualList = nil
  self.mMailListItems = nil
  self.mAttachmentIds = {}
  self.mAttachmentItems = {}
  self.mCachedMailList = nil
  self.mIsSyncOn = false
  self.tipsItem = nil
  self.mMailInitialized = nil
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
end

function UIMailPanelV2:GetRenderItem()
  return self:ItemProvider()
end

function UIMailPanelV2:ItemProvider()
  local itemView = UICommonItem.New()
  itemView:InitCtrl(self.ui.mContent_Item.transform)
  local renderDataItem = CS.RenderDataItem()
  renderDataItem.renderItem = itemView.mUIRoot.gameObject
  renderDataItem.data = itemView
  return renderDataItem
end

function UIMailPanelV2:ItemRenderer(index, renderData)
  local itemId = self.mAttachmentIds[index + 1]
  local itemData = self.mAttachmentItems[itemId]
  local itemView = renderData.data
  local itemCount = 0
  local typeData = TableData.listItemTypeDescDatas:GetDataById(itemData.type)
  if self.mCurSelMailItem.mData.attachments:ContainsKey(itemData.id) then
    if typeData.pile == 0 then
      itemCount = 1
    else
      itemCount = self.mCurSelMailItem.mData.attachments[itemData.id]
    end
  end
  if itemData.type == GlobalConfig.ItemType.StaminaType then
    itemView:SetItemData(itemId, itemCount, nil, nil, nil, nil, nil, function()
      TipsPanelHelper.OpenUITipsPanel(itemData, itemCount, false, 1)
    end)
  else
    itemView:SetByItemData(itemData, itemCount, 0 < self.mCurSelMailItem.mData.get_attachment)
  end
end

function UIMailPanelV2:MailItemProvider(renderData)
  local itemView = UIMailLeftTabItemV2.New()
  self.mMailListItems = self.mMailListItems or {}
  table.insert(self.mMailListItems, itemView)
  itemView:InitCtrl(renderData.gameObject.transform)
  renderData.data = itemView
end

function UIMailPanelV2:MailItemRenderer(index, renderData)
  local item = renderData.data
  local data = self.mCachedMailList[index]
  item:InitData(data)
  item.mIndex = index
  local itemBtn = UIUtils.GetButtonListener(item.ui.mAnimator.gameObject)
  itemBtn.param = item
  
  function itemBtn.onClick(gameObj)
    self:OnMailItemClicked(gameObj)
  end
  
  if self.mCachedMailList[index].IsExpired == false and index >= self.prevSelectIndex and self.bIsDefaultSet == false then
    self.bIsDefaultSet = true
    self.prevSelectIndex = index
    self:SelectMail(item)
  end
  if self.prevSelectIndex >= 0 then
    if self.prevSelectIndex == index then
      item:Select()
    else
      item:UnSelect()
    end
  end
end

function UIMailPanelV2:InitMailList()
  if self.mCachedMailList == nil then
    self.mCachedMailList = NetCmdMailData:GetSortedMailList()
  end
  self.virtualList.numItems = self.mCachedMailList.Count
  self.virtualList:Refresh()
  self.bIsDefaultSet = false
  self.prevSelectIndex = -1
  if self.mCurSelMailItem ~= nil then
    self.prevSelectIndex = self.mCurSelMailItem.mIndex
  end
  self:ClearSelect()
  setactive(self.ui.mTrans_MailList.gameObject, self.mCachedMailList.Count > 0)
  setactive(self.ui.mTrans_None.gameObject, self.mCachedMailList.Count <= 0)
  self.ui.mText_Num.text = self.mCachedMailList.Count
end

function UIMailPanelV2:RefreshMailList()
end

function UIMailPanelV2:OnMailItemClicked(gameObj)
  if self.mIsSyncOn == true then
    return
  end
  if self.canClick ~= nil and self.canClick == false then
    return
  end
  local eventTrigger = getcomponent(gameObj, typeof(CS.ButtonEventTriggerListener))
  if eventTrigger ~= nil then
    local item = eventTrigger.param
    local cacheIndex = self.prevSelectIndex
    self.prevSelectIndex = item.mIndex
    self:ClearSelect()
    self:SelectMail(item, cacheIndex)
  end
end

function UIMailPanelV2.OnMailChangedCallBack()
  MessageBox.Show(TableData.GetHintById(60051), TableData.GetHintById(60050), MessageBox.ShowFlag.eMidBtn, nil, function()
    self:UpdateMailList()
  end, nil)
end

function UIMailPanelV2:SelectMail(item, cacheIndex)
  self.mMailId = item.mData.id
  if item.mData.isReq then
    item:Select()
    self.mCurSelMailItem = item
    self:UpdateMailContent(item)
  else
    NetCmdMailData:SendMailDetail(item.mData.id, function(ret)
      if ret == ErrorCodeSuc then
        local data = NetCmdMailData:GetMailDataById(item.mData.id)
        item:SetData(data)
        item:Select()
        self.mCurSelMailItem = item
        self:MailReadCallback(item)
        self:UpdateMailContent(item)
      elseif cacheIndex ~= nil then
        self.prevSelectIndex = cacheIndex
      end
    end)
  end
end

function UIMailPanelV2:MailReadCallback(item)
  item:SetRead(true)
  item:ClearAttachment()
  self:UpdateRedPoint()
end

function UIMailPanelV2:ClearSelect()
  for _, item in pairs(self.mMailListItems) do
    item:UnSelect()
  end
  self.mCurSelMailItem = nil
end

function UIMailPanelV2:UpdateMailList()
  self:InitMailList()
end

function UIMailPanelV2.CheckScroll(pos)
  if pos.y > 0 then
    setactive(UIMailPanelV2.ui.mScrollbar_Material.gameObject, true)
  else
    setactive(UIMailPanelV2.ui.mScrollbar_Material.gameObject, false)
  end
end

function UIMailPanelV2:UpdateMailContent(item, skipAnim)
  if self.mCurSelMailItem ~= item then
    return
  end
  if self.clickTimer ~= nil then
    self.clickTimer:Stop()
    self.clickTimer = nil
  end
  self.canClick = false
  self.clickTimer = TimerSys:DelayCall(0.5, function()
    self.canClick = true
  end)
  self:ClearAttachmentItem()
  self.mCurSelMailData = self.mCurSelMailItem.mData
  self.ui.mText_Title.text = self.mCurSelMailData.title
  self.ui.mText_Description.text = self.mCurSelMailData.content
  self.ui.mText_Time.text = self.mCurSelMailData.mail_date
  self.ui.mText_CountDown.text = self.mCurSelMailData.remain_time
  self.ui.mText_MailName.text = self.mCurSelMailData.addresser
  self.ui.mTextEvent_DescriptionEvent:SetNeedToken(self.mCurSelMailData.need_token)
  self:UpdateTimer()
  local layoutElement = self.ui.mTrans_Reward:GetComponent(typeof(CS.UnityEngine.UI.LayoutElement))
  layoutElement.ignoreLayout = true
  setactive(self.ui.mTrans_Reward, false)
  local attachments = {}
  for k, v in pairs(self.mCurSelMailData.attachments) do
    attachments[k] = v
    layoutElement.ignoreLayout = false
    setactive(self.ui.mTrans_Reward, true)
  end
  local canReceive = false
  local i = 1
  for k, v in pairs(attachments) do
    local itemData = TableData.GetItemData(k)
    local typeData = TableData.listItemTypeDescDatas:GetDataById(itemData.type)
    local count = 1
    if typeData.pile == 0 then
      count = v
    end
    for index = 1, count do
      self.mAttachmentIds[i] = k
      i = i + 1
    end
    self.mAttachmentItems[k] = itemData
    local itemTime = itemData.time_limit
    if itemTime == 0 or 0 < itemTime and UIUtils.CheckIsTimeOut(itemTime) == false then
      canReceive = true
    end
  end
  self.ui.mList_Item.numItems = #self.mAttachmentIds
  self.ui.mList_Item:Refresh()
  if not skipAnim then
    self.ui.mAnimator:SetTrigger("Switch")
  end
  if self.mCurSelMailData.hasLink == true then
    setactive(self.ui.mBtn_PowerUp.gameObject, false)
    setactive(self.ui.mTrans_UnLocked.gameObject, false)
  elseif canReceive == false then
    setactive(self.ui.mTrans_Delete.gameObject, true)
    setactive(self.ui.mTrans_CanReceive.gameObject, false)
  else
    setactive(self.ui.mTrans_UnLocked.gameObject, self.mCurSelMailData.hasAttachment and self.mCurSelMailData.get_attachment == 1)
    if self.mCurSelMailData.get_attachment == 0 and self.mCurSelMailData.hasAttachment then
      setactive(self.ui.mTrans_CanReceive.gameObject, true)
      setactive(self.ui.mTrans_Delete.gameObject, false)
      UIUtils.GetButtonListener(self.ui.mBtn_PowerUp.gameObject).onClick = function(gameObj)
        self:OnReceiveBtnClicked(gameObj)
      end
    else
      setactive(self.ui.mTrans_Delete.gameObject, true)
      setactive(self.ui.mTrans_CanReceive.gameObject, false)
    end
  end
end

function UIMailPanelV2:UpdateTimer()
  if self.timer ~= nil then
    self.timer:Stop()
    self.timer = nil
  end
  self.timer = TimerSys:DelayCall(1, function()
    if self.mCurSelMailItem == nil then
      self.timer:Stop()
      self.timer = nil
    else
      self.ui.mText_CountDown.text = self.mCurSelMailData.remain_time
    end
  end, nil, -1)
end

function UIMailPanelV2:GetAppropriateItem(itemData, itemNum)
  if itemData == nil then
    return nil
  end
  if itemData.type == 8 then
    local weaponInfoItem = UICommonItem.New()
    weaponInfoItem:InitCtrl(self.ui.mContent_Item.gameObject.transform)
    weaponInfoItem:SetData(itemData.args[0], 1)
    if 0 < self.mCurSelMailItem.mData.get_attachment then
      weaponInfoItem:SetReceived(true)
    end
    return weaponInfoItem
  else
    local itemView = UICommonItem.New()
    itemView:InitCtrl(self.ui.mContent_Item.gameObject.transform)
    if itemData.type == 5 then
      local equipData = TableData.listGunEquipDatas:GetDataById(tonumber(itemData.args[0]))
      itemView:SetEquipData(itemData.args[0], 0, nil, equipData.id)
    else
      itemView:SetItemData(itemData.id, itemNum)
    end
    if 0 < self.mCurSelMailItem.mData.get_attachment then
      itemView:SetReceived(true)
    end
    return itemView
  end
end

function UIMailPanelV2:ClearAttachmentItem()
  self.mAttachmentIds = {}
end

function UIMailPanelV2:RequestMailContent()
  NetCmdMailData:SendMailDetail(self.mCurSelMailItem.mData.id, function()
    if ret == ErrorCodeSuc then
      self:MailReadCallback(self.mCurSelMailItem)
      self:UpdateMailContent(self.mCurSelMailItem)
    end
  end)
end

function UIMailPanelV2:OnReceiveBtnClicked(gameObj)
  if self.canClick ~= nil and self.canClick == false then
    return
  end
  if self.clickTimer ~= nil then
    self.clickTimer:Stop()
    self.clickTimer = nil
  end
  self.canClick = false
  self.clickTimer = TimerSys:DelayCall(0.5, function()
    self.canClick = true
  end)
  local canReceive = false
  local giftPackTable = {}
  if self.mCurSelMailItem.mData then
    if self.mMailId ~= self.mCurSelMailItem.mData.id then
      local mailData = NetCmdMailData:GetMailDataById(self.mMailId)
      self.mCurSelMailItem:SetData(mailData)
    end
    if self.mCurSelMailItem.mData.IsExpired == true then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(60052))
      return
    end
    local attachments = self.mCurSelMailItem.mData.attachments
    local equipTable = {}
    local weaponTable = {}
    local otherTable = {}
    for itemId, num in pairs(attachments) do
      local itemData = TableData.GetItemData(itemId)
      local itemTime = itemData.time_limit
      if itemTime == 0 or 0 < itemTime and UIUtils.CheckIsTimeOut(itemTime) == false then
        canReceive = true
      end
      if otherTable[itemId] ~= nil then
        otherTable[itemId] = otherTable[itemId] + num
      else
        otherTable[itemId] = num
      end
      if self.mCurSelMailItem.mData.mail_temp_id == 3001 and itemData.type == GlobalConfig.ItemType.GiftPick then
        for i = 1, num do
          table.insert(giftPackTable, itemId)
        end
      end
    end
    if canReceive == false then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(60052))
      self:UpdateMailContent(self.mCurSelMailItem, true)
      return
    end
    if TipsManager.CheckItemIsOverflowAndStopByList(otherTable, 0, true) then
      return
    end
  end
  local id = self.mCurSelMailItem.mData.id
  if 0 < Length(giftPackTable) then
    local paramData = {}
    UIBattlePassGlobal.CurSelectType = UIBattlePassGlobal.SelectType.MailSingle
    for i, v in pairs(giftPackTable) do
      local tabData = {
        v,
        nil,
        i
      }
      table.insert(paramData, tabData)
    end
    
    function UIBattlePassGlobal.FinishCallback(ret)
      self:OnReceiveAttachmentCallback(ret)
    end
    
    UIBattlePassGlobal.MailId = id
    UIManager.OpenUIByParam(UIDef.UIBattlePassRewardBoxDialog, paramData)
    return
  end
  NetCmdMailData:SendReqRoleMailGetAttachmentCmd(id, nil, function(ret)
    self:OnReceiveAttachmentCallback(ret)
  end)
end

function UIMailPanelV2:OnDeleteBtnClicked(gameObj)
  if self.canClick ~= nil and self.canClick == false then
    return
  end
  if self.clickTimer ~= nil then
    self.clickTimer:Stop()
    self.clickTimer = nil
  end
  self.canClick = false
  self.clickTimer = TimerSys:DelayCall(0.5, function()
    self.canClick = true
  end)
  local id = self.mCurSelMailItem.mData.id
  local mail = NetCmdMailData:GetMailDataById(id)
  if mail.hasAttachment and mail.get_attachment == 0 then
    return
  end
  local ids = {}
  ids[1] = id
  NetCmdMailData:SendReqRoleMailDelCmd(ids, function(ret)
    self:OnMailDeleteCallback(ret)
  end)
  self.mIsSyncOn = true
end

function UIMailPanelV2:OnDeleteAllBtnClicked(gameObj)
  if self:HasCanDelMail() then
    MessageBox.Show(TableData.GetHintById(60003), TableData.GetHintById(60004), MessageBox.ShowFlag.eNone, nil, function(param)
      self:ConfirmMailTips(param)
    end, nil)
  else
    CS.PopupMessageManager.PopupString(TableData.GetHintById(60057))
  end
end

function UIMailPanelV2:OnLinkBtnClicked(gameObj)
  if self.mCurSelMailItem.mData.IsExpired == true then
    MessageBox.Show(TableData.GetHintById(60051), TableData.GetHintById(60052), MessageBox.ShowFlag.eMidBtn, nil, nil, nil)
    return
  end
end

function UIMailPanelV2:OnAllReceive(gameObj)
  NetCmdMailData:SendReqRoleMailGetAttachmentsCmd(function(ret)
    self:GetRewardCallBack(ret)
  end)
end

function UIMailPanelV2:OnReceiveAttachmentCallback(ret)
  if ret == ErrorCodeSuc then
    self.skipRefresh = true
    UISystem:OpenCommonReceivePanel({
      function()
        if self.mCurSelMailItem.mData.IsExpired == true then
          self.bIsDefaultSet = false
          self.prevSelectIndex = -1
          self:ClearSelect()
          self.mCachedMailList = nil
          self:UpdateRedPoint()
          self:UpdateMailList()
        else
          self:UpdateRedPoint()
          if self.mMailId ~= self.mCurSelMailItem.mData.id then
            local mailData = NetCmdMailData:GetMailDataById(self.mMailId)
            self.mCurSelMailItem:SetData(mailData)
          end
          self:UpdateMailContent(self.mCurSelMailItem)
        end
      end
    })
  else
    gfdebug("\233\162\134\229\143\150\229\164\177\232\180\165")
    self.mCachedMailList:Remove(self.mCurSelMailItem.mData)
    if self.mCurSelMailItem.mIndex + 1 > self.mCachedMailList.Count then
      self.mCurSelMailItem = nil
      self.ui.mTrans_MailList.offsetMax = Vector2(self.ui.mTrans_MailList.offsetMax.x, 0)
    end
    self:UpdateMailList()
  end
end

function UIMailPanelV2:OnMailDeleteCallback(ret)
  self.mIsSyncOn = false
  if ret == ErrorCodeSuc then
    gfdebug("\229\136\160\233\153\164\233\130\174\228\187\182\230\136\144\229\138\159")
  else
    gfdebug("\229\136\160\233\153\164\233\130\174\228\187\182\229\164\177\232\180\165")
    MessageBox.Show(TableData.GetHintById(60053), TableData.GetHintById(60054), MessageBox.ShowFlag.eMidBtn, nil, nil, nil)
  end
end

function UIMailPanelV2:OnAllMailDeleteCallback(ret)
  self.mIsSyncOn = false
  if ret == ErrorCodeSuc then
    gfdebug("\229\136\160\233\153\164\233\130\174\228\187\182\230\136\144\229\138\159")
  else
    gfdebug("\229\136\160\233\153\164\233\130\174\228\187\182\229\164\177\232\180\165")
    MessageBox.Show(TableData.GetHintById(60053), TableData.GetHintById(60054), MessageBox.ShowFlag.eMidBtn, nil, nil, nil)
  end
end

function UIMailPanelV2:OnReturnClick(gameObj)
  UIManager.CloseUI(UIDef.UIMailPanelV2)
end

function UIMailPanelV2.OnCommanderCenter()
  UISystem:JumpToMainPanel()
end

function UIMailPanelV2:GetRewardCallBack(ret)
  if ret == ErrorCodeSuc then
    local idList = NetCmdMailData:GetAllReadId()
    if idList.Count == 0 then
      CS.PopupMessageManager.PopupString(TableData.GetHintById(60056))
    else
      UISystem:OpenCommonReceivePanel({
        function()
          self.bIsDefaultSet = false
          self.prevSelectIndex = -1
          self.mCachedMailList:Clear()
          self.mCachedMailList = NetCmdMailData:GetSortedMailList()
          self.virtualList.numItems = self.mCachedMailList.Count
          self.virtualList:Refresh()
          self:UpdateRedPoint()
        end
      })
    end
  else
    printstack("\228\184\128\233\148\174\233\162\134\229\143\150\233\130\174\228\187\182\229\164\177\232\180\165")
  end
end

function UIMailPanelV2:FiltrateMail()
  local mailList = {}
  for _, item in pairs(self.mCachedMailList) do
    if item.read == 1 then
      if item.hasAttachment then
        if item.get_attachment == 1 then
          table.insert(mailList, item.id)
        end
      else
        table.insert(mailList, item.id)
      end
    end
  end
  return mailList
end

function UIMailPanelV2:HasNotGetAttachment()
  for _, item in pairs(self.mCachedMailList) do
    if item.hasAttachment and item.get_attachment == 0 then
      return true
    end
  end
  return false
end

function UIMailPanelV2:CheckAllReceiveItem()
  local otherTable = {}
  local canReceive = false
  for _, item in pairs(self.mCachedMailList) do
    if item.hasAttachment and item.get_attachment == 0 then
      local attachments = item.attachments
      for itemId, num in pairs(attachments) do
        if otherTable[itemId] ~= nil then
          otherTable[itemId] = otherTable[itemId] + num
        else
          otherTable[itemId] = num
        end
        local itemData = TableData.GetItemData(itemId)
        local itemTime = itemData.time_limit
        if itemTime == 0 or 0 < itemTime and UIUtils.CheckIsTimeOut(itemTime) == false then
          canReceive = true
        end
      end
    end
  end
  if canReceive == false then
    CS.PopupMessageManager.PopupString(TableData.GetHintById(60052))
    self:UpdateMailContent(self.mCurSelMailItem, true)
  end
  if TipsManager.CheckItemIsOverflowAndStopByList(otherTable, 0, true) then
    return true
  end
  return false
end

function UIMailPanelV2:HasCanDelMail()
  for _, item in pairs(self.mCachedMailList) do
    if item.read == 1 then
      if item.hasAttachment then
        if item.get_attachment == 1 then
          return true
        end
      else
        return true
      end
    end
  end
  return false
end

function UIMailPanelV2:ConfirmMailTips(param)
  if self.tipsItem then
    self.tipsItem:CloseTips()
  end
  local ids = self:FiltrateMail()
  NetCmdMailData:SendReqRoleMailDelCmd(ids, function(ret)
    self:OnAllMailDeleteCallback(ret)
  end)
end

function UIMailPanelV2:CollectItem(itemList)
  local dicItem = {}
  for id, num in pairs(itemList) do
    local itemData = TableData.GetItemData(id)
    if itemData then
      local maxCount = 0
      local type = itemData.type
      local typeData = TableData.listItemTypeDescDatas:GetDataById(type)
      if typeData.related_item and 0 < typeData.related_item then
        if dicItem[typeData.related_item] == nil then
          dicItem[typeData.related_item] = 0
        end
        dicItem[typeData.related_item] = dicItem[typeData.related_item] + num
      else
        dicItem[id] = num
      end
    end
  end
  return dicItem
end

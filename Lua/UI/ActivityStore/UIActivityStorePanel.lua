require("UI.UIBasePanel")
require("UI.Common.UICommonItem")
require("UI.ActivityStore.UIActivityStoreBoxItem")
UIActivityStorePanel = class("UIActivityStorePanel", UIBasePanel)
UIActivityStorePanel.__index = UIActivityStorePanel

function UISevenQuestPanel:ctor(csPanel)
  self.super:ctor(csPanel)
  csPanel.Type = UIBasePanelType.Panel
end

function UIActivityStorePanel:OnInit(root, data)
  self.super.SetRoot(UIActivityStorePanel, root)
  self.ui = {}
  self.data = data
  self:LuaUIBindTable(root, self.ui)
  self.virtualList = self.ui.mList_Box
  
  function self.virtualList.itemCreated(renderData)
    local item = self:ItemProvider(renderData)
    return item
  end
  
  function self.virtualList.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
  
  self:InitBoxList()
  self:UpdateInfo()
  self:RegisterEvent()
end

function UIActivityStorePanel:UpdateInfo()
  self.ui.mText_Exp.text = tostring(self.curExp)
  self.totalExp = self.mCachedBoxList[self.mCachedBoxList.Count - 1].condition_num
  self.ui.mText_Total.text = "/" .. tostring(self.totalExp)
  self.ui.mImg_Bar.fillAmount = self.curExp / self.totalExp
  self.plusNum = 0
  self.plusQuestId = 0
  self.plusId = 0
  local costId = self.mCachedBoxList[0].condition_arg0
  local itemData = TableData.GetItemData(costId)
  if itemData then
    self.ui.mImg_Cost.sprite = IconUtils.GetItemSprite(itemData.icon)
  end
  for i = 0, self.mCachedBoxList.Count - 1 do
    local boxData = self.mCachedBoxList[i]
    if 0 < boxData.reward_plus.Count then
      self.plusQuestId = boxData.id
      self.plusNum = boxData.condition_num
      for id, num in pairs(boxData.reward_plus) do
        local trans = self.ui.mList_Item:Instantiate()
        self.plusItem = UICommonItem.New()
        self.plusItem:InitObj(trans)
        self.plusItem:SetItemData(id, num)
        self.plusId = id
      end
    end
  end
  if self.plusItem and self.plusQuestId ~= 0 then
    self.plusItem:SetRedPoint(self.plusQuestId ~= 0 and self.curExp >= self.plusNum and not NetCmdActivityStoreData:IsSpecialRewardClaimed(self.plusQuestId))
    if self.curExp < self.plusNum then
      self.plusItem:SetReceivedIcon(false)
      self.plusItem:SetLock(true)
      self.plusItem:SetLockColor()
    elseif NetCmdActivityStoreData:IsSpecialRewardClaimed(self.plusQuestId) then
      self.plusItem:SetReceivedIcon(true)
      self.plusItem:SetLock(false)
    else
      self.plusItem:SetReceivedIcon(false)
      self.plusItem:SetLock(false)
      UIUtils.GetButtonListener(self.plusItem.ui.mBtn_Select.gameObject).onClick = function()
        self:OnClickOpenSpecailBox()
      end
    end
  end
  self.ui.mText_Num.text = tostring(self.plusNum)
  self.ui.mText_Special.text = tostring(self.plusNum)
  TimerSys:DelayFrameCall(1, function()
    local contentSize = LuaUtils.GetRectTransformSize(self.ui.mImg_Bar.transform.gameObject)
    local width = contentSize.x
    local posX = -width / 2 + self.plusNum / self.totalExp * width
    self.ui.mTrans_GrpNum.localPosition = Vector3(posX, self.ui.mTrans_GrpNum.localPosition.y, 0)
  end)
  self:UpdateBoxCount()
end

function UIActivityStorePanel:UpdateBoxCount()
  self.ui.mText_NumOrdinary.text = self:GetUnboxBoxCount(1001)
  self.ui.mText_NumSenior.text = self:GetUnboxBoxCount(1002)
end

function UIActivityStorePanel:GetUnboxBoxCount(boxId)
  local ret = NetCmdActivityStoreData:GetUnboxBoxCount(boxId)
  if boxId == 1001 then
    if 0 < ret then
      self.ui.mText_Ordinary.text = TableData.GetHintById(260151)
    else
      self.ui.mText_Ordinary.text = TableData.GetHintById(260176)
    end
    setactive(self.ui.mTrans_OrdinaryRed, NetCmdActivityStoreData:IsShowBoxRedpoint(boxId))
  elseif boxId == 1002 then
    if 0 < ret then
      self.ui.mText_Senior.text = TableData.GetHintById(260151)
    else
      self.ui.mText_Senior.text = TableData.GetHintById(260176)
    end
    setactive(self.ui.mTrans_SeniorRed, NetCmdActivityStoreData:IsShowBoxRedpoint(boxId))
  end
  return ret
end

function UIActivityStorePanel:InitBoxList()
  if self.mCachedBoxList == nil then
    self.mCachedBoxList = NetCmdActivityStoreData:GetSortedBoxList()
  end
  if self.mCachedBoxList.Count > 0 then
    self.curExp = NetCmdCounterData:GetCounterCount(35, self.mCachedBoxList[0].id)
  else
    self.curExp = 0
  end
  self.curStep = -1
  for i = 0, self.mCachedBoxList.Count - 1 do
    local box = self.mCachedBoxList[i]
    if self.curExp >= box.condition_num and i > self.curStep then
      self.curStep = i
    end
  end
  self.virtualList.numItems = self.mCachedBoxList.Count
  self.virtualList:Refresh()
end

function UIActivityStorePanel:ItemProvider(renderData)
  local itemView = UIActivityStoreBoxItem.New()
  self.mBoxListItems = self.mBoxListItems or {}
  table.insert(self.mBoxListItems, itemView)
  itemView:InitCtrl(renderData.gameObject.transform)
  renderData.data = itemView
end

function UIActivityStorePanel:ItemRenderer(index, renderData)
  local item = renderData.data
  local data = self.mCachedBoxList[index]
  item:InitData(data, index == self.curStep)
  item.mIndex = index
end

function UIActivityStorePanel:OnClickOpenSpecailBox()
  if self.curExp >= self.plusNum then
    if self.plusQuestId ~= 0 and not NetCmdActivityStoreData:IsSpecialRewardClaimed(self.plusQuestId) then
      NetCmdActivityStoreData:SendClaimSpecialReward(self.plusQuestId, function(ret)
        if ret == ErrorCodeSuc then
          UISystem:OpenCommonReceivePanel()
          local itemData = TableData.GetItemData(self.plusId)
          TipsManager.Add(self.plusItem.ui.mBtn_Select.gameObject, itemData)
          TipsManager.Add(self.ui.mBtn_SpecialBox.gameObject, itemData)
          if self.plusItem then
            self.plusItem:SetReceivedIcon(true)
            self.plusItem:SetLock(false)
            self.plusItem:SetRedPoint(false)
          end
          NetCmdActivityStoreData:DirtyRedPoint()
        end
      end)
    end
  else
    local mStcData = TableData.GetItemData(101)
    PopupMessageManager.PopupString(string_format(TableData.GetHintById(260173), mStcData.name.str, self.plusNum))
  end
end

function UIActivityStorePanel:OnClickOpenBox(id)
  if self:GetUnboxBoxCount(id) == 0 then
    local boxData = TableData.listCollectionActivityBoxDatas:GetDataById(id)
    if boxData ~= nil then
      UIManager.OpenUIByParam(UIDef.UIActivityStoreOptionalGiftDialog, {canClaim = false, boxData = boxData})
    else
      gferror(id .. ": \229\174\157\231\174\177\232\161\168\230\156\170\230\137\190\229\136\176\229\175\185\229\186\148\230\149\176\230\141\174!")
    end
    return
  end
  local boxData = TableData.listCollectionActivityBoxDatas:GetDataById(id)
  if boxData ~= nil then
    NetCmdActivityStoreData:RecordBoxCount(id)
    UIManager.OpenUIByParam(UIDef.UIActivityStoreOptionalGiftDialog, {canClaim = true, boxData = boxData})
  else
    gferror(id .. ": \229\174\157\231\174\177\232\161\168\230\156\170\230\137\190\229\136\176\229\175\185\229\186\148\230\149\176\230\141\174!")
  end
end

function UIActivityStorePanel:OnTop()
  self:UpdateBoxCount()
end

function UIActivityStorePanel:OnBackFrom()
  self:UpdateBoxCount()
end

function UIActivityStorePanel.CloseSelf()
  UIManager.CloseUI(UIDef.UIActivityStorePanel)
end

function UIActivityStorePanel:RegisterEvent()
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    self.CloseSelf()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    UISystem:JumpToMainPanel()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Record.gameObject).onClick = function()
    UIManager.OpenUI(UIDef.UIActivityStoreRecordDialog)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Ordinary.gameObject).onClick = function()
    self:OnClickOpenBox(1001)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Senior.gameObject).onClick = function()
    self:OnClickOpenBox(1002)
  end
  if self.plusId ~= 0 and NetCmdActivityStoreData:IsSpecialRewardClaimed(self.plusQuestId) then
    local itemData = TableData.GetItemData(self.plusId)
    TipsManager.Add(self.ui.mBtn_SpecialBox.gameObject, itemData)
  else
    UIUtils.GetButtonListener(self.ui.mBtn_SpecialBox.gameObject).onClick = function()
      self:OnClickOpenSpecailBox()
    end
  end
end

function UIActivityStorePanel:OnClose()
  self.mBoxListItems = nil
  self.mCachedBoxList = nil
  if self.plusItem then
    gfdestroy(self.plusItem:GetRoot())
  end
end

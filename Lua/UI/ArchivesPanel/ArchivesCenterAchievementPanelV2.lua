require("UI.UIBasePanel")
require("UI.ArchivesPanel.Item.ArchivesCenterAchievementLeftTabItemV2")
require("UI.ArchivesPanel.Item.ArchivesCenterAchievementItemV2")
ArchivesCenterAchievementPanelV2 = class("ArchivesCenterAchievementPanelV2", UIBasePanel)
ArchivesCenterAchievementPanelV2.__index = ArchivesCenterAchievementPanelV2

function ArchivesCenterAchievementPanelV2:ctor(root, parentPanel, data)
  self:SetRoot(root.transform)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.mLeftTabViewList = {}
  self.parentPanel = parentPanel
  UIUtils.GetButtonListener(self.ui.mBtn_BtnReceive.gameObject).onClick = function(gameObject)
    self:OnAllReceiveClick(gameObject)
  end
  self.mData = data
  
  function self.ui.mVirtualListEx_AchievementList.itemProvider()
    return self:ItemProvider()
  end
  
  self.delayFrameCall = 0
  self.startTab = nil
  self.length = 0
  self:InitLeftTab()
end

function ArchivesCenterAchievementPanelV2:InitLeftTab()
  local tagDataList = NetCmdAchieveData:GetTagDataList()
  self.length = tagDataList.Count
  for i = 0, tagDataList.Count - 1 do
    local index = i + 1
    local tagData = tagDataList[i]
    if self.mLeftTabViewList[index] then
      self.mLeftTabViewList[index]:SetData(tagData)
    else
      local tagItem = ArchivesCenterAchievementLeftTabItemV2.New()
      tagItem:InitCtrl(self.ui.mTrans_LeftTabList)
      tagItem:SetData(tagData)
      table.insert(self.mLeftTabViewList, tagItem)
    end
    UIUtils.GetButtonListener(self.mLeftTabViewList[index].ui.mBtn_Root.gameObject).onClick = function()
      self:OnClickTag(self.mLeftTabViewList[index])
    end
    if tagData.id == self.mData then
      self:OnClickTag(self.mLeftTabViewList[index])
      self.startTab = self.mLeftTabViewList[index]
    end
  end
end

function ArchivesCenterAchievementPanelV2:ItemProvider()
  local itemView = ArchivesCenterAchievementItemV2.New()
  itemView:InitCtrl(self.ui.mTrans_Content)
  local renderDataItem = CS.RenderDataItem()
  renderDataItem.renderItem = itemView:GetRoot().gameObject
  renderDataItem.data = itemView
  return renderDataItem
end

function ArchivesCenterAchievementPanelV2:ItemRenderer(index, renderData)
  local data = self.list[index]
  if data then
    local item = renderData.data
    item:SetData(data)
    local itemBtn1 = UIUtils.GetButtonListener(item.ui.mBtn_BtnGoOn.gameObject)
    
    function itemBtn1.onClick(gameObject)
      self:OnGotoClick(gameObject)
    end
    
    itemBtn1.param = data
    local itemBtn2 = UIUtils.GetButtonListener(item.ui.mBtn_BtnReceive.gameObject)
    
    function itemBtn2.onClick(gameObject)
      self:OnReceiveClick(gameObject)
    end
    
    itemBtn2.param = data
  end
end

function ArchivesCenterAchievementPanelV2:UpdateAchieveList()
  self.list = NetCmdAchieveData:GetAchieveDataListByTag(self.mCurTagItem.tagId)
  local canReceive = {}
  local allComplete = true
  
  function self.ui.mVirtualListEx_AchievementList.itemRenderer(...)
    self:ItemRenderer(...)
  end
  
  for i = 0, self.list.Count - 1 do
    local data = self.list[i]
    if data.IsCompleted and not data.IsReceived then
      table.insert(canReceive, data.Id)
    end
    allComplete = data.Progress == 1
  end
  self.ui.mMonoScrollerFadeManager_Content.enabled = false
  self.ui.mMonoScrollerFadeManager_Content.enabled = true
  self.ui.mVirtualListEx_AchievementList.content.anchoredPosition = vector2zero
  self.ui.mVirtualListEx_AchievementList:Refresh()
  self.ui.mVirtualListEx_AchievementList.numItems = self.list.Count
  UIUtils.GetButtonListener(self.ui.mBtn_BtnReceive.gameObject).param = canReceive
  self:UpdateAchieveAll(self.mCurTagItem.mData)
end

function ArchivesCenterAchievementPanelV2:UpdateAchieveAll(data)
  local count = NetCmdAchieveData:GetTotalTagProcess()
  local total = NetCmdAchieveData:GetTotalTagCount()
  self.ui.mText_Num.text = "<color=#f26c1c>" .. count .. "</color>/" .. total
  self.ui.mImg_ProgressBar.fillAmount = count / total
  setactive(self.ui.mTrans_Action.gameObject, NetCmdAchieveData:CanReceive())
end

function ArchivesCenterAchievementPanelV2:OnClickTag(item)
  if self.mCurTagItem ~= nil then
    if item.tagId ~= self.mCurTagItem.tagId then
      self.mCurTagItem:SetItemState(false)
    else
      return
    end
  end
  self.allClicked = false
  item:SetItemState(true)
  self.mCurTagItem = item
  self:UpdatePanel()
end

function ArchivesCenterAchievementPanelV2:UpdatePanel()
  for _, item in ipairs(self.mLeftTabViewList) do
    item:RefreshData()
  end
  self.allClicked = false
  self:UpdateAchieveList()
  self:UpdateRedPoint()
end

function ArchivesCenterAchievementPanelV2:OnGotoClick(gameObject)
  local itemBtn = UIUtils.GetButtonListener(gameObject)
  local dailyData = itemBtn.param
  UISystem:JumpByID(dailyData.jumpID)
  self.needRefresh = true
end

function ArchivesCenterAchievementPanelV2:OnAllReceiveClick(gameObject)
  local receiveList = NetCmdAchieveData:GetAllAchievementList()
  if receiveList ~= nil and receiveList.Length > 0 then
    if self.allClicked then
      return
    end
    self.allClicked = true
    NetCmdAchieveData:SendReqTakeAchievementRewardCmd(receiveList, function(ret)
      self:OnReceivedCallback(ret)
    end)
  else
    self.allClicked = false
  end
end

function ArchivesCenterAchievementPanelV2:OnReceiveClick(gameObject)
  local itemBtn = UIUtils.GetButtonListener(gameObject)
  local dailyData = itemBtn.param
  self.mUICommonReceiveItemData = itemBtn.param
  local idList = {}
  table.insert(idList, dailyData.Id)
  NetCmdAchieveData:SendReqTakeAchievementRewardCmd(idList, function(ret)
    self:OnReceivedCallback(ret)
  end)
end

function ArchivesCenterAchievementPanelV2:OnReceivedCallback(ret)
  if ret == ErrorCodeSuc then
    gfdebug("\233\162\134\229\143\150\230\136\144\229\138\159")
    if AccountNetCmdHandler.IsLevelUpdate == true then
      UICommonLevelUpPanel.Open(UICommonLevelUpPanel.ShowType.CommanderLevelUp, nil, true, true, function()
        self:UpdatePanel()
      end)
    else
      UISystem:OpenCommonReceivePanel({
        nil,
        function()
          self:UpdatePanel()
        end,
        true
      })
    end
  else
    gfdebug("\233\162\134\229\143\150\229\164\177\232\180\165")
    self.allClicked = false
  end
end

function ArchivesCenterAchievementPanelV2.CloseTakeQuestRewardCallBack(data)
  if self.mUICommonReceiveItem ~= nil then
    self.mUICommonReceiveItem:SetData(nil)
  end
end

function ArchivesCenterAchievementPanelV2:OnReturnClicked(gameObject)
  self.Close()
end

function ArchivesCenterAchievementPanelV2:OnDialogBack()
end

function ArchivesCenterAchievementPanelV2:OnPanelBack()
  self:UpdatePanel()
end

function ArchivesCenterAchievementPanelV2:Release()
  self.mCurTagItem = nil
  self.mUICommonReceiveItemData = nil
  self.mUICommonReceiveItem = nil
end

function ArchivesCenterAchievementPanelV2:GetTaskTypeId()
  return 4
end

function ArchivesCenterAchievementPanelV2:GetStartTab()
  for i = 1, self.length do
    local item = self.mLeftTabViewList[i]
    if item then
      item:UpdateRedData()
      if self.mLeftTabViewList[i].isShowRedPoint then
        self.startTab = self.mLeftTabViewList[i]
        return
      end
    end
  end
end

function ArchivesCenterAchievementPanelV2:Show()
  self:GetStartTab()
  self:InitLeftTab()
  if self.startTab then
    self:OnClickTag(self.startTab)
  end
  self:SetVisible(true)
  self.ui.mCanvas_AchievementList.blocksRaycasts = true
  self.parentPanel:Refresh()
end

function ArchivesCenterAchievementPanelV2:Hide()
  self:SetVisible(false)
end

function ArchivesCenterAchievementPanelV2:GetAnimPageSwitchInt()
  return 0
end

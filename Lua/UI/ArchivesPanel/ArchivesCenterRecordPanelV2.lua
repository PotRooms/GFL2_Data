require("UI.UIBasePanel")
require("UI.ArchivesPanel.Item.Btn_ArchivesCenterRecordItemV2")
ArchivesCenterRecordPanelV2 = class("ArchivesCenterRecordPanelV2", UIBasePanel)
ArchivesCenterRecordPanelV2.__index = ArchivesCenterRecordPanelV2

function ArchivesCenterRecordPanelV2:ctor(root)
  self.super.ctor(self, root)
  root.Type = UIBasePanelType.Panel
end

function ArchivesCenterRecordPanelV2:OnAwake(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.storyUIList = {}
  self.currSelectData = nil
  UIUtils.GetButtonListener(self.ui.mBtn_Back.gameObject).onClick = function()
    UIManager.CloseUI(UIDef.ArchivesCenterRecordPanelV2)
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Home.gameObject).onClick = function()
    UISystem:JumpToMainPanel()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Item.gameObject).onClick = function()
    if self.itemId then
      local stcData = TableData.GetItemData(self.itemId)
      TipsPanelHelper.OpenUITipsPanel(stcData, 0, true)
    end
  end
end

function ArchivesCenterRecordPanelV2:OnInit(root, data)
  self.selectIndex = data[1]
  self.data = data[2]
  
  function self.ui.mSuperGridScrollerController_DetailsList.itemCreated(renderData)
    self:ItemProvider(renderData)
  end
  
  function self.ui.mSuperGridScrollerController_DetailsList.itemRenderer(index, renderData)
    self:ItemRenderer(index, renderData)
  end
  
  self:RefreshPlotDetail()
  self:RefreshData()
end

function ArchivesCenterRecordPanelV2:ReleaseTimer()
  if self.animTimer then
    self.animTimer:Stop()
    self.animTimer = nil
  end
end

function ArchivesCenterRecordPanelV2:RefreshData()
  if self.selectIndex == 1 then
    setactive(self.ui.mTrans_Hard.gameObject, false)
    self:RefreshStory()
    setactive(self.ui.mTrans_Story.gameObject, true)
  else
    setactive(self.ui.mTrans_Story.gameObject, false)
    self:RefreshHard()
    setactive(self.ui.mTrans_Hard.gameObject, true)
  end
  local currPlotCount = NetCmdArchivesData:GetPlotCurrCount(self.data.id)
  local maxPlotCount = NetCmdArchivesData:GetPlotGroupCount(self.data.id)
  self.ui.mText_UnLockNum.text = string.format("%d/%d", currPlotCount, maxPlotCount)
  self:ReleaseTimer()
  if currPlotCount >= maxPlotCount then
    self.animTimer = TimerSys:DelayCall(0.2, function()
      self.ui.mAnimator_Item:SetBool("Bool", true)
    end)
  else
    self.ui.mAnimator_Item:SetBool("Bool", false)
  end
end

function ArchivesCenterRecordPanelV2:RefreshPlotDetail()
  if self.data == nil then
    return
  end
  self.ui.mText_Title.text = self.data.name.str
  local storyIDList = NetCmdArchivesData:GetGroupPlotListByGroup(self.data.id)
  self.syDataList = {}
  for i = 0, storyIDList.Count - 1 do
    local syData = TableDataBase.listInformationDetailCsDatas:GetDataById(storyIDList[i])
    if i == 0 then
      self.currSelectData = syData
    end
    table.insert(self.syDataList, syData)
  end
  self.ui.mSuperGridScrollerController_DetailsList.numItems = #self.syDataList
  self.ui.mSuperGridScrollerController_DetailsList:Refresh()
end

function ArchivesCenterRecordPanelV2:ItemProvider(renderData)
  local itemView = Btn_ArchivesCenterRecordItemV2.New()
  itemView:InitCtrlWithNoInstantiate(renderData.gameObject)
  renderData.data = itemView
end

function ArchivesCenterRecordPanelV2:ItemRenderer(index, renderData)
  local data = self.syDataList[index + 1]
  if data then
    local item = renderData.data
    item:SetData(data, self.selectIndex, index)
  end
end

function ArchivesCenterRecordPanelV2:RefreshStory()
  self.ui.mText_Code.text = self.data.code.str
  self.ui.mImg_StoryBg.sprite = IconUtils.GetArchivesIcon(self.data.listicon)
  if self.currSelectData then
    for k, v in pairs(self.currSelectData.unlock_item) do
      local itemData = TableData.GetItemData(k)
      if itemData then
        self.ui.mText_Name.text = itemData.name.str
        self.ui.mImg_Icon.sprite = IconUtils.GetItemIconSprite(itemData.id)
        self.ui.mText_Num.text = NetCmdItemData:GetItemCountById(itemData.id)
        self.itemId = itemData.id
        break
      end
    end
  end
end

function ArchivesCenterRecordPanelV2:RefreshHard()
  self.ui.mText_HardNum.text = self.data.code.str
  self.ui.mImg_HardBg.sprite = IconUtils.GetArchivesIcon(self.data.listicon)
  local itemData = TableDataBase.listItemDatas:GetDataById(self.data.item_id)
  if itemData then
    self.ui.mImg_HardIcon.sprite = IconUtils.GetItemIconSprite(itemData.id)
  end
end

function ArchivesCenterRecordPanelV2:OnShowStart()
end

function ArchivesCenterRecordPanelV2:OnShowFinish()
end

function ArchivesCenterRecordPanelV2:OnTop()
  self:RefreshPlotDetail()
  self:RefreshData()
end

function ArchivesCenterRecordPanelV2:OnBackFrom()
  self:RefreshPlotDetail()
  self:RefreshData()
end

function ArchivesCenterRecordPanelV2:OnClose()
  self:ReleaseTimer()
end

function ArchivesCenterRecordPanelV2:OnHide()
end

function ArchivesCenterRecordPanelV2:OnHideFinish()
end

function ArchivesCenterRecordPanelV2:OnRelease()
end

require("UI.UIBaseCtrl")
require("UI.StorePanel.Btn_ActivityThemeBChapterListItem")
ActivityThemeBChapterItem = class("ActivityThemeBChapterItem", UIBaseCtrl)
ActivityThemeBChapterItem.__index = ActivityThemeBChapterItem

function ActivityThemeBChapterItem:ctor()
end

function ActivityThemeBChapterItem:InitCtrl(parent)
  local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
  local instObj = instantiate(itemPrefab.childItem)
  self.ui = {}
  self:LuaUIBindTable(instObj, self.ui)
  if parent then
    UIUtils.AddListItem(instObj.gameObject, parent.gameObject)
  end
  self.index = 0
  self:SetRoot(instObj.transform)
  self.itemViewList = {}
  self.storyDataList = {}
  self.mainItemView = nil
  self.lockLineColor = Color(0.4, 0.4, 0.4, 0.9019607843137255)
  setactive(self.ui.mTrans_Main.gameObject, false)
  setactive(self.ui.mTrans_BranchAbove.gameObject, false)
  setactive(self.ui.mTrans_BranchBlow.gameObject, false)
  setactive(self.ui.mTrans_AboveGO.gameObject, false)
  setactive(self.ui.mTrans_BelowGO.gameObject, false)
  setactive(self.ui.mTrans_ImgLine.gameObject, false)
end

function ActivityThemeBChapterItem:SetMainData(chapterData, data, index)
  self:UpdateCtrl(chapterData, data, self.ui.mTrans_Main, 1)
  self.mainItemView:UpdateBg(1)
  if data.id > 0 and not NetCmdThemeData:LevelIsUnLock(data.id) then
    self.mainItemView:SetPreMidLineColor(self.lockLineColor)
  end
  setactive(self.ui.mTrans_Main.gameObject, true)
  self.mainItemView:SetPreMidLineVisible(index ~= 1)
  setactive(self.ui.mTrans_DaiyanChapterListItem.gameObject, true)
end

function ActivityThemeBChapterItem:SetTopData(chapterData, data)
  self:UpdateCtrl(chapterData, data, self.ui.mTrans_AboveParent, 2)
  self.itemViewList[data.id]:UpdateBg(2)
  if data.id > 0 and not NetCmdThemeData:LevelIsUnLock(data.id) then
    self.itemViewList[data.id]:SetPreTopBranchLineColor(self.lockLineColor)
  end
  self.itemViewList[data.id]:SetPreMidLineVisible(false)
  self.itemViewList[data.id]:SetPreTopBranchLineVisible(true)
  setactive(self.ui.mTrans_DaiyanChapterListItem.gameObject, true)
end

function ActivityThemeBChapterItem:SetBtmData(chapterData, data)
  self:UpdateCtrl(chapterData, data, self.ui.mTrans_BelowParent, 3)
  self.itemViewList[data.id]:UpdateBg(2)
  if data.id > 0 and not NetCmdThemeData:LevelIsUnLock(data.id) then
    self.itemViewList[data.id]:SetPreBottomBranchLineColor(self.lockLineColor)
  end
  self.itemViewList[data.id]:SetPreMidLineVisible(false)
  self.itemViewList[data.id]:SetPreBottomBranchLineVisible(true)
  setactive(self.ui.mTrans_DaiyanChapterListItem.gameObject, true)
end

function ActivityThemeBChapterItem:UpdateCtrl(chapterData, data, trans, flag)
  self.storyDataList[data.id] = data
  if flag == 1 then
    if self.mainItemView == nil then
      self.mainItemView = Btn_ActivityThemeBChapterListItem.New()
      self.mainItemView:InitCtrl(trans)
    end
    self.mainItemView:SetData(chapterData, data)
    self.mainItemView:SetNextLine(false)
    self.mainItemView:SetPreMidLineVisible(false)
  else
    if self.itemViewList[data.id] == nil then
      self.itemViewList[data.id] = Btn_ActivityThemeBChapterListItem.New()
      self.itemViewList[data.id]:InitCtrl(trans)
    end
    self.itemViewList[data.id]:SetData(chapterData, data)
    self.itemViewList[data.id]:SetNextLine(false)
    self.itemViewList[data.id]:SetPreMidLineVisible(false)
  end
  setactive(trans.gameObject, true)
end

function ActivityThemeBChapterItem:SetTopGroupData(chapterData, data, index)
  if self.itemViewList[data.id] == nil then
    local instObj = instantiate(self.ui.mTrans_AboveGO, self.ui.mTrans_BranchAbove)
    local topItem = Btn_ActivityThemeBChapterListItem.New()
    setactive(instObj.gameObject, true)
    topItem:InitCtrl(instObj.transform)
    self.itemViewList[data.id] = topItem
    self.storyDataList[data.id] = data
  end
  setactive(self.ui.mTrans_BranchAbove.gameObject, true)
  self.itemViewList[data.id]:SetData(chapterData, data)
  gfinfo("SetTopGroupData stage_id: " .. data.id .. "  index: " .. index)
  if self.itemViewList[data.id] then
    self.itemViewList[data.id]:SetPreMidLineVisible(true)
    if data.id > 0 and not NetCmdThemeData:LevelIsUnLock(data.id) then
      self.itemViewList[data.id]:SetPreMidLineColor(self.lockLineColor)
    end
  end
  self.itemViewList[data.id]:UpdateBg(2)
end

function ActivityThemeBChapterItem:SetBtmGroupData(chapterData, data, index)
  if self.itemViewList[data.id] == nil then
    self.storyDataList[data.id] = data
    local instObj = instantiate(self.ui.mTrans_BelowGO, self.ui.mTrans_BranchBlow)
    setactive(instObj.gameObject, true)
    local btmItem = Btn_ActivityThemeBChapterListItem.New()
    btmItem:InitCtrl(instObj)
    self.itemViewList[data.id] = btmItem
  end
  setactive(self.ui.mTrans_BranchBlow.gameObject, true)
  gfinfo("SetBtmGroupData stage_id: " .. data.id .. "  index: " .. index)
  self.itemViewList[data.id]:SetData(chapterData, data)
  if self.itemViewList[data.id] then
    self.itemViewList[data.id]:SetPreMidLineVisible(true)
    if data.id > 0 and not NetCmdThemeData:LevelIsUnLock(data.id) then
      self.itemViewList[data.id]:SetPreMidLineColor(self.lockLineColor)
    end
  end
  self.itemViewList[data.id]:UpdateBg(2)
end

function ActivityThemeBChapterItem:UpdateItem(storyData)
  if self.itemViewList[storyData.id] then
    self.itemViewList[storyData.id]:UpdateItem()
  end
  self.mainItemView:UpdateItem()
end

function ActivityThemeBChapterItem:SetSelected(storyData, isSelect, isBranch)
  if isBranch then
    if self.itemViewList[storyData.id] then
      self.itemViewList[storyData.id]:SetSelected(isSelect)
    end
  else
    self.mainItemView:SetSelected(isSelect)
  end
end

function ActivityThemeBChapterItem:CleanAllSelected()
  for k, v in pairs(self.itemViewList) do
    v:SetSelected(false)
  end
  self.mainItemView:SetSelected(false)
end

function ActivityThemeBChapterItem:SetDataFalse()
  setactive(self.ui.mTrans_Main.gameObject, false)
  setactive(self.ui.mTrans_BranchAbove.gameObject, false)
  setactive(self.ui.mTrans_BranchBlow.gameObject, false)
  setactive(self.ui.mTrans_DaiyanChapterListItem.gameObject, false)
end

function ActivityThemeBChapterItem:DownSortingOrder()
end

function ActivityThemeBChapterItem:UpdateSortingOrder()
end

function ActivityThemeBChapterItem:GetBtnItemRoot()
end

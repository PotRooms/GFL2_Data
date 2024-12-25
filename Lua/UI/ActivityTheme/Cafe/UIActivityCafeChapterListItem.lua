require("UI.UIBaseCtrl")
require("UI.ActivityTheme.Cafe.UIActivityCafeBtnItem")
UIActivityCafeChapterListItem = class("UIActivityCafeChapterListItem", UIBaseCtrl)

function UIActivityCafeChapterListItem:ctor()
end

function UIActivityCafeChapterListItem:InitCtrl(parent)
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
  setactive(self.ui.mTrans_Main.gameObject, false)
  setactive(self.ui.mTrans_BranchAbove.gameObject, false)
  setactive(self.ui.mTrans_BranchBlow.gameObject, false)
  setactive(self.ui.mTrans_AboveGO.gameObject, false)
  setactive(self.ui.mTrans_BelowGO.gameObject, false)
end

function UIActivityCafeChapterListItem:SetMainData(chapterData, data, nextData)
  self:UpdateCtrl(chapterData, data, self.ui.mTrans_Main, 1)
  self.mainItemView:UpdateBg(1)
  setactivewithcheck(self.ui.mCanvasGroup_Line, true)
  if nextData then
    if not NetCmdThemeData:LevelIsUnLock(nextData.id) then
      self.ui.mCanvasGroup_Line.alpha = 0.5
    else
      self.ui.mCanvasGroup_Line.alpha = 1
    end
  else
    setactivewithcheck(self.ui.mCanvasGroup_Line, false)
  end
  setactive(self.ui.mTrans_Main.gameObject, true)
  setactive(self.ui.mTrans_UIActivityCafeChapterListItem.gameObject, true)
end

function UIActivityCafeChapterListItem:SetTopData(chapterData, data)
  self:UpdateCtrl(chapterData, data, self.ui.mTrans_AboveParent, 2)
  self.itemViewList[data.id]:UpdateBg(2)
  if not NetCmdThemeData:LevelIsUnLock(data.id) then
    self.ui.mCanvasGroup_Line.alpha = 0.5
  else
    self.ui.mCanvasGroup_Line.alpha = 1
  end
  setactive(self.ui.mTrans_BranchAbove.gameObject, true)
  setactive(self.ui.mTrans_UIActivityCafeChapterListItem.gameObject, true)
end

function UIActivityCafeChapterListItem:SetBtmData(chapterData, data)
  self:UpdateCtrl(chapterData, data, self.ui.mTrans_BelowParent, 3)
  self.itemViewList[data.id]:UpdateBg(2)
  if not NetCmdThemeData:LevelIsUnLock(data.id) then
    self.ui.mCanvasGroup_Line.alpha = 0.5
  else
    self.ui.mCanvasGroup_Line.alpha = 1
  end
  setactive(self.ui.mTrans_BranchBlow.gameObject, true)
  setactive(self.ui.mTrans_UIActivityCafeChapterListItem.gameObject, true)
end

function UIActivityCafeChapterListItem:UpdateCtrl(chapterData, data, trans, flag)
  self.storyDataList[data.id] = data
  if flag == 1 then
    if self.mainItemView == nil then
      self.mainItemView = UIActivityCafeBtnItem.New()
      self.mainItemView:InitCtrl(trans)
    end
    self.mainItemView:SetData(chapterData, data)
    self.mainItemView:SetNextLine(false)
  else
    if self.itemViewList[data.id] == nil then
      self.itemViewList[data.id] = UIActivityCafeBtnItem.New()
      self.itemViewList[data.id]:InitCtrl(trans)
    end
    self.itemViewList[data.id]:SetData(chapterData, data)
    self.itemViewList[data.id]:SetNextLine(false)
  end
  setactive(trans.gameObject, true)
  if data.type == 1 or data.type == 2 then
    setactive(self.ui.mTrans_ImgLine.gameObject, data.next_id.Count > 0)
  end
end

function UIActivityCafeChapterListItem:SetTopGroupData(chapterData, data)
  if self.itemViewList[data.id] == nil then
    local instObj = instantiate(self.ui.mTrans_AboveGO, self.ui.mTrans_BranchAbove)
    local topItem = UIActivityCafeBtnItem.New()
    setactive(instObj.gameObject, true)
    topItem:InitCtrl(instObj.transform)
    self.itemViewList[data.id] = topItem
    self.storyDataList[data.id] = data
  end
  setactive(self.ui.mTrans_BranchAbove.gameObject, true)
  self.itemViewList[data.id]:SetData(chapterData, data)
  if self.itemViewList[data.pre_id[0]] then
    self.itemViewList[data.pre_id[0]]:SetNextLine(true)
  end
  self.itemViewList[data.id]:UpdateBg(2)
end

function UIActivityCafeChapterListItem:SetBtmGroupData(chapterData, data)
  if self.itemViewList[data.id] == nil then
    self.storyDataList[data.id] = data
    local instObj = instantiate(self.ui.mTrans_BelowGO, self.ui.mTrans_BranchBlow)
    setactive(instObj.gameObject, true)
    local btmItem = UIActivityCafeBtnItem.New()
    btmItem:InitCtrl(instObj)
    self.itemViewList[data.id] = btmItem
  end
  setactive(self.ui.mTrans_BranchBlow.gameObject, true)
  self.itemViewList[data.id]:SetData(chapterData, data)
  if self.itemViewList[data.pre_id[0]] then
    self.itemViewList[data.pre_id[0]]:SetNextLine(true)
  end
  self.itemViewList[data.id]:UpdateBg(2)
end

function UIActivityCafeChapterListItem:UpdateItem(storyData)
  if self.itemViewList[storyData.id] then
    self.itemViewList[storyData.id]:UpdateItem()
  end
  self.mainItemView:UpdateItem()
end

function UIActivityCafeChapterListItem:SetSelected(storyData, isSelect)
  if self.itemViewList[storyData.id] then
    self.itemViewList[storyData.id]:SetSelected(isSelect)
  end
  self.mainItemView:SetSelected(isSelect)
end

function UIActivityCafeChapterListItem:CleanAllSelected()
  for k, v in pairs(self.itemViewList) do
    v:SetSelected(false)
  end
  self.mainItemView:SetSelected(false)
end

function UIActivityCafeChapterListItem:SetDataFalse()
  setactive(self.ui.mTrans_Main.gameObject, false)
  setactive(self.ui.mTrans_BranchAbove.gameObject, false)
  setactive(self.ui.mTrans_BranchBlow.gameObject, false)
  setactive(self.ui.mTrans_UIActivityCafeChapterListItem.gameObject, false)
end

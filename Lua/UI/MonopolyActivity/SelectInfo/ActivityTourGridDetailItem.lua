require("UI.UIBaseCtrl")
require("UI.MonopolyActivity.ActivityTourGlobal")
require("UI.MonopolyActivity.SelectInfo.Item.ActivityTourGridEventInfo")
ActivityTourGridDetailItem = class("ActivityTourGridDetailItem", UIBaseCtrl)
ActivityTourGridDetailItem.__index = ActivityTourGridDetailItem

function ActivityTourGridDetailItem:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function ActivityTourGridDetailItem:InitCtrl(parent)
  local com = parent:GetComponent(typeof(CS.ScrollListChild))
  local obj = instantiate(com.childItem, parent)
  self:SetRoot(obj.transform)
  self.ui = {}
  self.mData = nil
  self:LuaUIBindTable(obj, self.ui)
  UIUtils.GetButtonListener(self.ui.mBtn_ControlGrid.gameObject).onClick = function()
    self:OnClickShowControlGrid()
  end
  MonopolyUtil:SetMonopolyActivityUIHint(self.mUIRoot.transform)
  self.gridId = 0
  self.detailList = {}
  if not self.oriColor then
    self.oriColor = self.ui.mImg_TeamBg.color
  end
end

function ActivityTourGridDetailItem:Refresh(gridId)
  local grid = MpGridManager:GetGrid(gridId)
  if not grid then
    return
  end
  local data = grid.Config
  if not data then
    return
  end
  self.gridId = gridId
  self.ui.mText_Name.text = string_format(MonopolyUtil:GetMonopolyActivityHint(270252), gridId)
  self.ui.mImg_PointsIcon.sprite = ActivityTourGlobal.GetPointIcon()
  local cost = MpGridManager:GetOccupyCost(MonopolyWorld.mainPlayer, gridId)
  self.ui.mText_Num.text = 0 < cost and cost or ""
  setactive(self.ui.mTrans_Consume.gameObject, 0 < cost)
  self.ui.mText_GridDesc.text = MpGridManager.BasicGridDesc
  local monsterOccupy = MpGridManager:HaveOccupyGrid(ActivityTourGlobal.MonsterCamp_Int, gridId)
  local playerOccupy = MpGridManager:HaveOccupyGrid(ActivityTourGlobal.PlayerCamp_Int, gridId)
  local haveCampOccupy = MpGridManager:HaveCampOccupyGrid(gridId)
  setactive(self.ui.mTrans_UnOccupy.gameObject, not grid.CanOccupy)
  setactive(self.ui.mTrans_Empty.gameObject, not haveCampOccupy and grid.CanOccupy)
  setactive(self.ui.mTrans_Occupy.gameObject, haveCampOccupy)
  if playerOccupy then
    self.ui.mImg_TeamBg.color = ColorUtils.BlueColor2
    self.ui.mText_Team.text = MonopolyUtil:GetMonopolyActivityHint(270300)
  elseif monsterOccupy then
    self.ui.mImg_TeamBg.color = ColorUtils.RedColor4
    self.ui.mText_Team.text = MonopolyUtil:GetMonopolyActivityHint(270299)
  end
  self:RefreshTerrainOrFunction()
end

function ActivityTourGridDetailItem:OnRelease()
  self.ui = nil
  self.mData = nil
  if self.detailList then
    for i = 1, #self.detailList do
      self.detailList[i]:OnRelease(true)
    end
  end
  self.detailList = nil
  self.super.OnRelease(self, true)
  self.mHighlightGrids = nil
end

function ActivityTourGridDetailItem:RefreshTerrainOrFunction()
  setactive(self.ui.mTrans_EventInfo.gameObject, false)
  local grid = MpGridManager:GetGrid(self.gridId)
  if not grid then
    return
  end
  self.detailNum = 0
  local listFunc = grid:GetAllFuncs()
  self:RefreshGridFunction(listFunc)
  self:RefreshControlBtn()
  for i = self.detailNum + 1, #self.detailList do
    setactive(self.detailList[i]:GetRoot(), false)
  end
  setactive(self.ui.mTrans_Event.gameObject, self.detailNum > 0)
end

function ActivityTourGridDetailItem:RefreshGridFunction(listFunc)
  if listFunc == nil then
    return
  end
  if listFunc.Count <= 0 then
    return
  end
  for i = 0, listFunc.Count - 1 do
    local data = TableData.listMonopolyMapFunctionDatas:GetDataById(listFunc[i].Id)
    self:RefreshInternal(data, listFunc[i].Enable)
  end
end

function ActivityTourGridDetailItem:RefreshControlBtn()
  local controlType, grids = MpGridManager:GetGridControlType(self.gridId)
  local isShow = controlType ~= CS.GF2.Monopoly.GridControlType.None and MonopolySelectManager.IsMultiSelect == false
  self.mControlType = controlType
  self.mHighlightGrids = grids
  setactive(self.ui.mBtn_ControlGrid, isShow)
  if not isShow then
    return
  end
  if controlType == CS.GF2.Monopoly.GridControlType.HasBeControlledGrid then
    self.ui.mText_ControlText.text = MonopolyUtil:GetMonopolyActivityHint(270349)
  else
    self.ui.mText_ControlText.text = MonopolyUtil:GetMonopolyActivityHint(270350)
  end
end

function ActivityTourGridDetailItem:OnClickShowControlGrid()
  if self.mControlType == CS.GF2.Monopoly.GridControlType.None then
    print_error("\229\188\130\229\184\184\239\188\140\229\189\147\229\137\141\230\178\161\230\156\137\230\142\167\229\136\182/\232\162\171\230\142\167\229\136\182\231\154\132\229\156\176\230\160\188")
    return
  end
  local highlightGrids = self.mHighlightGrids
  MessageSys:SendMessage(MonopolyEvent.OnHideSelectDetail, nil)
  MonopolySelectManager:ShowHighlightGrid(highlightGrids)
end

function ActivityTourGridDetailItem:RefreshInternal(data, enable)
  if not data then
    return
  end
  local index = self.detailNum + 1
  if not self.detailList[index] then
    self.detailList[index] = ActivityTourGridEventInfo.New()
    self.detailList[index]:InitCtrl(self.ui.mTrans_EventInfo.gameObject, self.ui.mTrans_EventInfo.transform.parent)
  end
  if not self.detailList[index] then
    return
  end
  self.detailNum = self.detailNum + 1
  setactive(self.detailList[index]:GetRoot(), true)
  self.detailList[index]:Refresh(data, enable)
end

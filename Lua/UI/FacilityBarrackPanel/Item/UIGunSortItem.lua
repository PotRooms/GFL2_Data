require("UI.UIBaseCtrl")
UIGunSortItem = class("UIGunSortItem", UIBaseCtrl)
UIGunSortItem.__index = UIGunSortItem

function UIGunSortItem:ctor()
  self.curSort = nil
  self.sortFunc = nil
  self.curGunId = 0
end

function UIGunSortItem:__InitCtrl()
  self.mBtn_Sort = self:GetButton("Btn_Dropdown")
  self.mBtn_Ascend = self:GetButton("Btn_Screen")
  self.mBtn_TypeScreen = self:GetButton("Btn_TypeScreen")
  self.mText_SortName = self:GetText("Btn_Dropdown/Text_SuitName")
end

function UIGunSortItem:InitCtrl(parent, useScrollListChild)
  local obj
  if useScrollListChild then
    local itemPrefab = parent:GetComponent(typeof(CS.ScrollListChild))
    obj = instantiate(itemPrefab.childItem)
  else
    obj = instantiate(UIUtils.GetGizmosPrefab("UICommonFramework/ComScreenItemV2.prefab", self))
  end
  if parent then
    CS.LuaUIUtils.SetParent(obj.gameObject, parent.gameObject, false)
  end
  self:SetRoot(obj.transform)
  self:__InitCtrl()
end

function UIGunSortItem:SetData(data)
  self.curSort = data
  self.mText_SortName.text = TableData.GetHintById(data.hintID)
  self.sortFunc = FacilityBarrackGlobal:GetSortFunc(1, self.curSort.sortCfg, self.curSort.isAscend)
end

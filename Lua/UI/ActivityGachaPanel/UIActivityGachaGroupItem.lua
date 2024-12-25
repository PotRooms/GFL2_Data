require("UI.UIBaseCtrl")
UIActivityGachaGroupItem = class("UIActivityGachaGroupItem", UIBaseCtrl)
UIActivityGachaGroupItem.__index = UIActivityGachaGroupItem
UIActivityGachaGroupItem.ui = nil
UIActivityGachaGroupItem.mData = nil

function UIActivityGachaGroupItem:ctor(csPanel)
  self.super.ctor(self, csPanel)
end

function UIActivityGachaGroupItem:InitCtrl(parent)
  local obj = instantiate(UIUtils.GetGizmosPrefab(ActivityGachaGlobal.GachaGroupItemPrefabPath, self))
  if parent then
    CS.LuaUIUtils.SetParent(obj.gameObject, parent.gameObject, true)
  end
  self:SetRoot(obj.transform)
  self.ui = {}
  self.mData = nil
  self:LuaUIBindTable(obj, self.ui)
  self.group = 0
  self.selectGroup = 0
  self.gachaId = 0
  UIUtils.GetButtonListener(self.ui.mBtn_ActivitieGachaTurnItem.gameObject).onClick = function()
    self:OnBtnClick()
  end
end

function UIActivityGachaGroupItem:SetData(gachaId, group, data, spritePath, actId, moduleKey, moduleValue, selectCallBack)
  self.gachaId = gachaId
  self.group = group
  self.spritePath = spritePath
  self.selectCallBack = selectCallBack
  if not data then
    return
  end
  local haveSave = NetCmdActivityGachaData:HaveSaveGroupPrefs(gachaId, group)
  setactive(self.ui.mObj_RedPoint.gameObject, data.state == ActivityGachaGlobal.GroupState_Doing and not haveSave)
  setactive(self.ui.mTrans_Doing.gameObject, data.state == ActivityGachaGlobal.GroupState_Doing)
  setactive(self.ui.mTrans_Closed.gameObject, data.state == ActivityGachaGlobal.GroupState_Close)
  setactive(self.ui.mTrans_CanOpen.gameObject, false)
  self.ui.mText_Num.text = TableData.GetActivityHint(270117 + group - 1, actId, 2, moduleKey, moduleValue)
  local bgPath = ActivityGachaGlobal.IconRootPath .. self.spritePath
  local spritePath = ActivityGachaGlobal.IconRootPath .. self.spritePath .. "/"
  self.ui.mImg_Num.sprite = IconUtils.GetAtlasV2(bgPath, ActivityGachaGlobal.SpriteName.GachaGroupIcon .. group)
  self.ui.mImg_Bg.sprite = IconUtils.GetActivityThemeSprite(spritePath .. ActivityGachaGlobal.SpriteName.TurnItemBg)
  self.ui.mImg_Hl.sprite = IconUtils.GetActivityThemeSprite(spritePath .. ActivityGachaGlobal.SpriteName.TurnItemHl)
  self.ui.mImg_Sel.sprite = IconUtils.GetActivityThemeSprite(spritePath .. ActivityGachaGlobal.SpriteName.TurnItemSel)
  self.ui.mImg_FootBg.sprite = IconUtils.GetActivityThemeSprite(spritePath .. ActivityGachaGlobal.SpriteName.FootBg)
  self.ui.mImg_TurnBg.sprite = IconUtils.GetActivityThemeSprite(spritePath .. ActivityGachaGlobal.SpriteName.TurnBg)
end

function UIActivityGachaGroupItem:SetSelect(group)
  self.selectGroup = group
  self.ui.mBtn_ActivitieGachaTurnItem.interactable = self.group ~= group
  if self.group == group then
    self:RefreshRedPoint()
  end
end

function UIActivityGachaGroupItem:OnBtnClick()
  if self.selectGroup == self.group then
    return
  end
  if not self.selectCallBack then
    return
  end
  self.selectCallBack(self.group)
end

function UIActivityGachaGroupItem:RefreshRedPoint()
  if not self.ui.mObj_RedPoint.gameObject.activeSelf then
    return
  end
  setactive(self.ui.mObj_RedPoint.gameObject, false)
  NetCmdActivityGachaData:SetGroupPrefs(self.gachaId, self.group)
end

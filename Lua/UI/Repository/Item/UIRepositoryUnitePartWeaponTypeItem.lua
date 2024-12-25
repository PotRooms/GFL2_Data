require("UI.Repository.Item.RepositoryUnitePartTypeGlobal")
UIRepositoryUnitePartWeaponTypeItem = class("UIRepositoryUnitePartWeaponTypeItem", UIBaseCtrl)
UIRepositoryUnitePartWeaponTypeItem.__index = UIRepositoryUnitePartWeaponTypeItem

function UIRepositoryUnitePartWeaponTypeItem:__InitCtrl()
end

function UIRepositoryUnitePartWeaponTypeItem:InitCtrl(itemPrefab)
  if itemPrefab == nil then
    return
  end
  local obj = instantiate(itemPrefab.childItem, itemPrefab.transform)
  self:InitCtrlWithoutInstantiate(obj)
end

function UIRepositoryUnitePartWeaponTypeItem:InitCtrlWithoutInstantiate(obj, setToZero)
  self:SetRoot(obj.transform)
  self:__InitCtrl()
  self.ui = {}
  self:LuaUIBindTable(self.mUIRoot, self.ui)
  self.iconList = {}
  UIUtils.AddBtnClickListener(self.ui.mBtn_Self.gameObject, function()
    self:ClickFunction()
  end)
end

function UIRepositoryUnitePartWeaponTypeItem:SetData(weaponTypeID, index)
  self.itemIndex = index
  self.weaponTypeID = weaponTypeID
  local tbData = TableData.listGunWeaponTypeDatas:GetDataById(self.weaponTypeID)
  local str
  if tbData then
    str = tbData.name.str
  end
  self.ui.mText_Name.text = str
  self.suitName = str
end

function UIRepositoryUnitePartWeaponTypeItem:SetItemName(str)
  self.ui.mText_Name.text = str
  self.suitName = str
end

function UIRepositoryUnitePartWeaponTypeItem:SetSelectState(selectIndex)
  local isSelect = selectIndex == self.weaponTypeID
  self.isSelect = isSelect
  setactive(self.ui.mTrans_Sel, self.isSelect)
end

function UIRepositoryUnitePartWeaponTypeItem:SetInteractable(isInteractable)
  self.ui.mBtn_Self.interactable = isInteractable
end

function UIRepositoryUnitePartWeaponTypeItem:SetClickFunction(func)
  self.clickFunction = func
end

function UIRepositoryUnitePartWeaponTypeItem:ClickFunction()
  self.clickFunction(self)
end

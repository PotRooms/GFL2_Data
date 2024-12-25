UIRepositoryUnitePartModPowerItem = class("UIRepositoryUnitePartModPowerItem", UIBaseCtrl)
UIRepositoryUnitePartModPowerItem.__index = UIRepositoryUnitePartModPowerItem

function UIRepositoryUnitePartModPowerItem:__InitCtrl()
end

function UIRepositoryUnitePartModPowerItem:InitCtrl(itemPrefab)
  if itemPrefab == nil then
    return
  end
  local obj = instantiate(itemPrefab.childItem, itemPrefab.transform)
  self:InitCtrlWithoutInstantiate(obj)
end

function UIRepositoryUnitePartModPowerItem:InitCtrlWithoutInstantiate(obj, setToZero)
  self:SetRoot(obj.transform)
  self:__InitCtrl()
  self.ui = {}
  self:LuaUIBindTable(self.mUIRoot, self.ui)
  self.iconList = {}
  UIUtils.AddBtnClickListener(self.ui.mBtn_Self.gameObject, function()
    self:ClickFunction()
  end)
end

function UIRepositoryUnitePartModPowerItem:SetData(suitID, index, packageType)
  self.itemIndex = index
  if packageType == RepositoryUnitePartTypeGlobal.PackageType.OnlyWeapon then
    self.mod_suit_plan = suitID
    local modData = TableData.listModPowerEffectDatas:GetDataById(self.mod_suit_plan)
    self.selectSuitName = modData.name.str
    self.ui.mText_Name.text = self.selectSuitName
    return
  end
  self.suitID = suitID
  local tmpStcData = TableData.listModPowerBySuitPlanIdDatas:GetDataById(suitID)
  if tmpStcData == nil then
    return
  end
  local idList = tmpStcData.Id
  if idList == nil then
    return
  end
  self.modSuitPlanIDList = idList
  if idList.Count > 1 then
    gfdebug(suitID .. "\233\133\141\231\189\174\228\186\134\229\164\154\228\184\170\229\165\151\232\163\133\228\191\161\230\129\175\239\188\140\230\137\190\231\173\150\229\136\146\230\163\128\230\159\165")
  end
  local powerID = idList[0]
  self.powerID = powerID
  local tbData = TableData.listModPowerDatas:GetDataById(powerID)
  local modData = TableData.listModPowerEffectDatas:GetDataById(tbData.power_id)
  self.selectSuitName = modData.name.str
  self.ui.mText_Name.text = self.selectSuitName
end

function UIRepositoryUnitePartModPowerItem:SetSelectState(selectIndex)
  local isSelect = selectIndex == self.suitID
  self.isSelect = isSelect
  setactive(self.ui.mTrans_Sel, self.isSelect)
end

function UIRepositoryUnitePartModPowerItem:SetClickFunction(func)
  self.clickFunction = func
end

function UIRepositoryUnitePartModPowerItem:SetInteractable(isInteractable)
  self.ui.mBtn_Self.interactable = isInteractable
end

function UIRepositoryUnitePartModPowerItem:ClickFunction()
  self.clickFunction(self)
end

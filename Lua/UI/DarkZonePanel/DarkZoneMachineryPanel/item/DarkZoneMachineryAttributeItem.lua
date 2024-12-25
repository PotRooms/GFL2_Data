require("UI.UIBaseCtrl")
DarkZoneMachineryAttributeItem = class("DarkZoneMachineryAttributeItem", UIBaseCtrl)
DarkZoneMachineryAttributeItem.__index = DarkZoneMachineryAttributeItem

function DarkZoneMachineryAttributeItem:__InitCtrl()
end

function DarkZoneMachineryAttributeItem:InitCtrl(root)
  if root == nil then
    return
  end
  local obj = root:Instantiate()
  self:InitCtrlWithNoInstantiate(obj)
end

function DarkZoneMachineryAttributeItem:InitCtrlWithNoInstantiate(obj, setToZero)
  self.ui = {}
  self.mData = {}
  self:LuaUIBindTable(obj, self.ui)
  self:SetRoot(obj.transform)
  if not self.oldMaterial then
    self.oldMaterial = self.ui.mImg_Icon.material
  end
  self.clickAction = nil
  UIUtils.GetButtonListener(self.ui.mBtn_Self.gameObject).onClick = function()
    if self.clickAction then
      self.clickAction()
    end
  end
end

function DarkZoneMachineryAttributeItem:SetMaterial(grayMaterial)
  self.grayMaterial = grayMaterial
end

function DarkZoneMachineryAttributeItem:SetData(data, isUnlock, unlockLevel, index)
  self.tableData = data
  if self.tableData == nil then
    return
  end
  self.ui.mImg_Icon.sprite = IconUtils.GetIconV2("Buff", self.tableData.talent_icon)
  self.isUnlock = isUnlock
  self.unlockLevel = unlockLevel
  self.itemIndex = index
  local color = self.ui.mImg_Icon.color
  if not isUnlock then
    color.a = 0.7
    self.ui.mImg_Icon.material = self.grayMaterial
  else
    self.ui.mImg_Icon.material = self.oldMaterial
    color.a = 1
  end
  self.ui.mImg_Icon.color = color
end

function DarkZoneMachineryAttributeItem:AddClickListener(callback)
  self.clickAction = callback
end

function DarkZoneMachineryAttributeItem:SetBtnInteractable(isSelect)
  self.ui.mBtn_Self.interactable = isSelect == false
end

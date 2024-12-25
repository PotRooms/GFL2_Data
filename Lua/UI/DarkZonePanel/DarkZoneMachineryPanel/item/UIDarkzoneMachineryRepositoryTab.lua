UIDarkzoneMachineryRepositoryTab = class("UIDarkzoneMachineryRepositoryTab", UIBaseCtrl)
UIDarkzoneMachineryRepositoryTab.__index = UIDarkzoneMachineryRepositoryTab

function UIDarkzoneMachineryRepositoryTab:ctor()
end

function UIDarkzoneMachineryRepositoryTab:InitCtrl(prefab, parent)
  local obj = instantiate(prefab, parent)
  self:SetRoot(obj.transform)
  self.ui = {}
  self:LuaUIBindTable(obj, self.ui)
  self.index = 0
  self.btnCallBack = nil
  self.mData = nil
  self.itemList = {}
end

function UIDarkzoneMachineryRepositoryTab:SetData(data, btnCallBack, index)
  UIUtils.GetButtonListener(self.ui.mBtn_ComTab1ItemV2.gameObject).onClick = function()
    btnCallBack()
  end
  self.mData = data
  self.index = index
  self.ui.mText_Name.text = data.title
end

function UIDarkzoneMachineryRepositoryTab:SwitchItemList(index)
  for i = 1, #self.itemList do
    setactive(self.itemList[i]:GetRoot(), self.index == index and not self.itemList[i].isDestoryFlag)
  end
  self.ui.mBtn_ComTab1ItemV2.interactable = self.index ~= index
end

function UIDarkzoneMachineryRepositoryTab:OnRelease()
  for i = 1, #self.itemList do
    self.itemList[i]:OnRelease(true)
  end
  gfdestroy(self:GetRoot())
end

function UIDarkzoneMachineryRepositoryTab:OnDiscardClick(index)
  setactive(self:GetRoot(), self.index == index)
end

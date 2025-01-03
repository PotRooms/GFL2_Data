require("UI.UIBasePanel")
UIComExpirationPopDialog = class("UIComExpirationPopDialog", UIBasePanel)
UIComExpirationPopDialog.__index = UIComExpirationPopDialog
local self = UIComExpirationPopDialog

function UIComExpirationPopDialog:ctor(obj)
  UIComExpirationPopDialog.super.ctor(self)
  obj.Type = UIBasePanelType.Dialog
end

function UIComExpirationPopDialog:OnInit(root, data)
  self:SetRoot(root)
  self.ui = {}
  self:LuaUIBindTable(root, self.ui)
  self.mData = data
  UIUtils.GetButtonListener(self.ui.mBtn_Close.gameObject).onClick = function()
    self:ClickToClose()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_GrpClose.gameObject).onClick = function()
    self:ClickToClose()
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Confirm.gameObject).onClick = function()
    self:ClickToClose()
  end
  self.itemList = {}
  for i = 1, #self.mData do
    local itemData = self.mData[i]
    local itemTableData = TableData.listItemDatas:GetDataById(itemData.item_id)
    if itemTableData.ShowType ~= 0 then
      do
        local item
        item = UICommonItem.New()
        item:InitCtrl(self.ui.mScrollListChild_Content)
        table.insert(self.itemList, item)
        local custOnclick
        if itemTableData.type == GlobalConfig.ItemType.GiftPick then
          function custOnclick()
            UIManager.OpenUIByParam(UIDef.UIRepositoryBoxDialog, itemTableData)
          end
        end
        local t = TableData.GlobalSystemData.BackpackJumpSwitch == 1
        item:SetItemData(itemData.item_id, itemData.item_num, false, t, itemData.item_num, nil, nil, custOnclick, nil, true)
      end
    end
  end
end

function UIComExpirationPopDialog:OnShowStart()
end

function UIComExpirationPopDialog:ClickToClose()
  local itemIds = {}
  for i = 1, #self.mData do
    local itemData = self.mData[i]
    table.insert(itemIds, itemData.item_id)
  end
  NetCmdItemData:C2SDeleteTimeLimitItems(itemIds, function()
    UIManager.CloseUI(UIDef.UIComExpirationPopDialog)
  end)
end

function UIComExpirationPopDialog:OnClose()
  for _, item in pairs(self.itemList) do
    gfdestroy(item:GetRoot())
  end
end

function UIComExpirationPopDialog:OnRelease()
end

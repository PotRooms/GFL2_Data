require("UI.UIBaseCtrl")
require("UI.ActivityPanel.Item.UIActivityItemBase")
UIActivityPreSaleSkinItem = class("UIActivityPreSaleSkinItem", UIActivityItemBase)
UIActivityPreSaleSkinItem.__index = UIActivityPreSaleSkinItem

function UIActivityPreSaleSkinItem:OnInit()
end

function UIActivityPreSaleSkinItem:OnShow()
  self.ui.mText_Name.text = self.mActivityTableData.name.str
  self.ui.mText_Time:StartCountdown(self.mCloseTime)
  local storeId = tonumber(self.mActivityTableData.other_param2)
  local storeData = TableDataBase.listStoreGoodDatas:GetDataById(storeId)
  if storeData ~= nil then
    self.ui.mText_GunName.text = storeData.name.str
    self.ui.mText_Before.text = math.floor(storeData.price)
    if storeData.price_args.Count > 0 then
      self.ui.mText_Price.text = storeData.price_args[0]
    end
  end
  UIUtils.GetButtonListener(self.ui.mBtn_Goto).onClick = function()
    if self.mActivityTableData.other_param ~= "" then
      UISystem:JumpByID(tonumber(self.mActivityTableData.other_param))
    end
  end
end

function UIActivityPreSaleSkinItem:OnHide()
end

function UIActivityPreSaleSkinItem:OnTop()
  self:OnShow()
end

function UIActivityPreSaleSkinItem:OnClose()
end
